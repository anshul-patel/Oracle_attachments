CREATE OR REPLACE PACKAGE BODY xxaqv_fnd_attachments_pkg AS
--/*------------------------------------------------- Arqiva -----------------------------------------------------*
-- ****************************************************************************************************************
-- * Type               : Package Body                                                                            *
-- * Application Module : Attachments                                                                             *
-- * Packagage Name     : XXAQV_FND_ATTACHMENTS_PKG                                                               *
-- * Script Name        : XXAQV_FND_ATTACHMENTS_PKG.pkb                                                           *
-- * Purpose            : Used for Attachments.                                                                   *
-- * Company            : Cognizant Technology Solutions.                                                         *
-- *                                                                                                              *
-- * Change History                                                                                               *
-- * Version     Created By        Creation Date    Comments                                                      *
-- *--------------------------------------------------------------------------------------------------------------*
-- * 1.0         CTS               07/01/2020     Initial Version                                                 *
-- ****************************************************************************************************************/


   -- Global PLSQL Types

  TYPE gt_xxaqv_attach_docs_type IS
    TABLE OF xxaqv.xxaqv_attach_docs_stg%rowtype INDEX BY BINARY_INTEGER;

   -- Global Records
   gt_xxaqv_attach_docs_tab     gt_xxaqv_attach_docs_type;


  /* Global Variables
  */
   gv_debug_flag                 VARCHAR2(10);
   gv_id                         NUMBER;
   gv_entity_name                VARCHAR2(100);
   gv_pk1_value                  VARCHAR2(100);
   gv_user_id                    NUMBER := apps.fnd_profile.value('USER_ID');
   gv_login_id                   NUMBER := fnd_global.login_id;
   
--/*****************************************************************************************************************
-- * Function  : validate_category_id                                                                              *
-- * Purpose   : This Function will validate category ID                                                           *
-- *****************************************************************************************************************/	

   FUNCTION validate_category_id ( p_category_name    IN    VARCHAR2
                                 , lv_category_id     OUT   VARCHAR2
                                 , p_error_msg        OUT   VARCHAR2
   ) RETURN VARCHAR2 IS
   BEGIN
      IF p_category_name IS NULL THEN
         RETURN 'S';
      ELSE
         BEGIN
            SELECT category_id
              INTO lv_category_id
              FROM fnd_document_categories
             WHERE upper(trim(name)) = upper(trim(p_category_name));
               
         EXCEPTION
            WHEN OTHERS THEN
               p_error_msg := 'Category ID not found in the system; ';
               RETURN 'E';
         END;
      END IF;

      RETURN 'S';
   EXCEPTION
      WHEN OTHERS THEN
         p_error_msg := 'Error retrieving category id';
         RETURN 'E';
   END validate_category_id;
   
   
--/*****************************************************************************************************************
-- * Function  : validate_datatype_id                                                                              *
-- * Purpose   : This Function will validate payement term                                                         *
-- *****************************************************************************************************************/	

   FUNCTION validate_datatype_id ( p_datatype_name  IN    VARCHAR2
                                 , lv_datatype_id   OUT   VARCHAR2
                                 , p_error_msg      OUT   VARCHAR2
   ) RETURN VARCHAR2 IS
   BEGIN
      IF p_datatype_name IS NULL THEN
         p_error_msg := 'Datatype name is NULL ';
         RETURN 'E';
      ELSE
         BEGIN
            SELECT datatype_id
              INTO lv_datatype_id
              FROM fnd_document_datatypes
             WHERE upper(trim(name)) = upper(trim(p_datatype_name));
             
         EXCEPTION
            WHEN OTHERS THEN
               p_error_msg := 'Datatype ID not found in the system; ';
               RETURN 'E';
         END;
      END IF;

      RETURN 'S';
   EXCEPTION
      WHEN OTHERS THEN
         p_error_msg := 'Error retrieving Datatype ID';
         RETURN 'E';
   END validate_datatype_id;
   
--/*****************************************************************************************************************
-- * Function  : validate_supplier_pk                                                                              *
-- * Purpose   : This Function will validate PK1_VALUE for supplier                                                *
-- *****************************************************************************************************************/	

   FUNCTION validate_supplier_pk ( p_vendor_number  IN    VARCHAR2
                                 , p_vendor_name    IN    VARCHAR2
                                 , ln_pk1_value     OUT   VARCHAR2
                                 , p_error_msg      OUT   VARCHAR2
   ) RETURN VARCHAR2 IS
   BEGIN
      IF p_vendor_name IS NULL OR p_vendor_number IS NULL THEN
         p_error_msg := 'vendor details are NULL ';
         RETURN 'E';
      ELSE
         BEGIN
            SELECT vendor_id 
              INTO ln_pk1_value
              FROM ap_suppliers
             WHERE upper(trim(vendor_name)) = upper(trim(p_vendor_name))
               AND segment1 = p_vendor_number;
 
         EXCEPTION
            WHEN OTHERS THEN
               p_error_msg := 'Vendor ID not found in the system; ';
               RETURN 'E';
         END;
      END IF;

      RETURN 'S';
   EXCEPTION
      WHEN OTHERS THEN
         p_error_msg := 'Error retrieving Vendor ID';
         RETURN 'E';
   END validate_supplier_pk;

   
--/*****************************************************************************************************************
-- * Function  : validate_sup_sites_pk                                                                             *
-- * Purpose   : This Function will validate PK1_VALUE for supplier                                                *
-- *****************************************************************************************************************/	

   FUNCTION validate_sup_sites_pk ( p_vendor_number       IN    VARCHAR2
                                  , p_vendor_site_code    IN    VARCHAR2
                                  , ln_pk1_value          OUT   VARCHAR2
                                  , p_error_msg           OUT   VARCHAR2
   ) RETURN VARCHAR2 IS
   BEGIN
      IF p_vendor_site_code IS NULL OR p_vendor_number IS NULL THEN
         p_error_msg := 'vendor site details are NULL ';
         RETURN 'E';
      ELSE
         BEGIN
            SELECT vendor_site_id 
              INTO ln_pk1_value
              FROM ap_suppliers asa
                 , ap_supplier_sites_all assa
             WHERE asa.vendor_id         = assa.vendor_id
               AND asa.segment1          = p_vendor_number
               AND assa.vendor_site_code = p_vendor_site_code;

         EXCEPTION
            WHEN OTHERS THEN
               p_error_msg := 'Vendor site_ID not found in the system; ';
               RETURN 'E';
         END;
      END IF;

      RETURN 'S';
   EXCEPTION
      WHEN OTHERS THEN
         p_error_msg := 'Error retrieving Vendor SITE_ID';
         RETURN 'E';
   END validate_sup_sites_pk;
   
--/****************************************************************************************************************
-- * Procedure  : supplier_load_staging_data                                                                      *
-- * Purpose    : This Procedure is used to load supplier attachment data into staging Table                      *
-- ****************************************************************************************************************/

   PROCEDURE supplier_load_staging_data ( x_retcode       OUT   NUMBER
                                        , x_err_msg       OUT   VARCHAR2  )
    IS
   
 -- This Cursor is used to retrieve information about Short Text Attachments. --

      CURSOR cur_short IS
      SELECT fad.seq_num       sequence_num
           , aps.segment1      vendor_number
           , aps.vendor_name   vendor_name
           , fad.entity_name   entity_name
           , fdt.description   document_description
           , regexp_replace(fdst.short_text
             , '[^[!-~]]*'
             , ' '
                  )	           text
           , NULL              file_name
           , NULL              url
           , NULL              function_name
           , fdd.name          datatype_name
           , fad.pk1_value     pk1_value
           , fad.pk2_value     pk2_value
           , fad.pk3_value     pk3_value
           , fad.pk4_value     pk4_value
           , fad.pk5_value     pk5_value
           , fdc.name          category_name
        FROM fnd_attached_documents@xxaqv_conv_cmn_dblink     fad
           , ap_suppliers@xxaqv_conv_cmn_dblink               aps
           , fnd_document_categories@xxaqv_conv_cmn_dblink    fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink           fdt
           , fnd_documents@xxaqv_conv_cmn_dblink              fd
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink     fdd
           , fnd_documents_short_text@xxaqv_conv_cmn_dblink   fdst
       WHERE fdst.media_id   = fd.media_id
         AND fad.document_id = fd.document_id
         AND fdd.datatype_id = fd.datatype_id
         AND fad.category_id = fdc.category_id (+)
         AND fdt.document_id = fd.document_id
         AND fdd.name        = 'SHORT_TEXT'                     
         AND fad.pk1_value   = nvl(gv_pk1_value,fad.pk1_value)  -- passing PK1_VALUE
         AND aps.vendor_id   = fad.pk1_value
         AND fad.entity_name = 'PO_VENDORS'                     -- entity name
         AND EXISTS ( SELECT 1
                        FROM ap_suppliers apt
                       WHERE apt.segment1    = aps.segment1
                         AND apt.vendor_name = aps.vendor_name    );
               

  -- This Cursor is used to retrieve information about Long Text Attachments ---

      CURSOR cur_long IS
      SELECT fad.seq_num       sequence_num
           , aps.segment1      vendor_number
           , aps.vendor_name   vendor_name
           , fad.entity_name   entity_name
           , fdt.description   document_description
           , fdlt.long_text    text
           , NULL              file_name
           , NULL              url
           , NULL              function_name
           , fdd.name          datatype_name
           , fad.pk1_value     pk1_value
           , fad.pk2_value     pk2_value
           , fad.pk3_value     pk3_value
           , fad.pk4_value     pk4_value
           , fad.pk5_value     pk5_value
           , fdc.name          category_name
        FROM fnd_attached_documents@xxaqv_conv_cmn_dblink   fad
           , ap_suppliers@xxaqv_conv_cmn_dblink             aps
           , fnd_document_categories@xxaqv_conv_cmn_dblink  fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink         fdt
           , fnd_documents@xxaqv_conv_cmn_dblink            fd
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink   fdd
           , fnd_documents_long_text@xxaqv_conv_cmn_dblink  fdlt
       WHERE fdlt.media_id   = fd.media_id
         AND fad.document_id = fd.document_id
         AND fdd.datatype_id = fd.datatype_id
         AND fad.category_id = fdc.category_id(+)
         AND fdt.document_id = fd.document_id
         AND fdd.name        = 'LONG_TEXT'                        
         AND fad.pk1_value   = nvl(gv_pk1_value,fad.pk1_value)    -- passing PK1_VALUE
         AND aps.vendor_id   = fad.pk1_value
         AND fad.entity_name = 'PO_VENDORS'                       -- entity name
         AND EXISTS ( SELECT 1
                        FROM ap_suppliers apt
                       WHERE apt.segment1    = aps.segment1
                         AND apt.vendor_name = aps.vendor_name    );
         
 -- This Cursor is used to retrieve information about Web URL Attachments.--

      CURSOR cur_url IS
      SELECT fad.seq_num       sequence_num
           , fdt.description   document_description
           , aps.segment1      vendor_number
           , aps.vendor_name   vendor_name
           , fad.entity_name   entity_name
           , null              text
           , NULL              file_name
           , fd.url            url
           , NULL              function_name
           , fdd.name          datatype_name
           , fad.pk1_value     pk1_value
           , fad.pk2_value     pk2_value
           , fad.pk3_value     pk3_value
           , fad.pk4_value     pk4_value
           , fad.pk5_value     pk5_value
           , fdc.name          category_name
        FROM fnd_documents@xxaqv_conv_cmn_dblink             fd
           , ap_suppliers@xxaqv_conv_cmn_dblink              aps
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink    fdd
           , fnd_attached_documents@xxaqv_conv_cmn_dblink    fad
           , fnd_document_categories@xxaqv_conv_cmn_dblink   fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink          fdt
       WHERE fdd.datatype_id = fd.datatype_id
         AND aps.vendor_id   = fad.pk1_value
         AND fad.document_id = fd.document_id
         AND fad.category_id = fdc.category_id(+)
         AND fdt.document_id = fd.document_id
         AND fdd.name        = 'WEB_PAGE'
         AND fad.entity_name = 'PO_VENDORS'                        -- entity name
         AND fad.pk1_value   = nvl(gv_pk1_value,fad.pk1_value)     -- passing PK1_VALUE
               AND EXISTS ( SELECT 1
                              FROM ap_suppliers apt
                             WHERE apt.segment1    = aps.segment1
                               AND apt.vendor_name = aps.vendor_name    );
         
 -- This Cursor is used to retrieve information about File Attachments. --

      CURSOR cur_file IS
      SELECT fad.pk1_value          pk1_value
           , fad.entity_name        entity_name
           , fl.file_id             file_id
           , fl.file_name           file_name
           , fad.seq_num            sequence_num
           , aps.segment1           vendor_number
           , aps.vendor_name        vendor_name
           , fdd.name               datatype_name
           , fl.upload_date         upload_date
           , fl.file_content_type   file_content_type
           , fl.expiration_date     expiration_date
           , fl.program_name        program_name
           , fl.language            language
           , fl.oracle_charset      oracle_charset
           , fl.file_format         file_format
           , fdc.name               category_name
           , fdt.description        document_description
        FROM fnd_lobs@xxaqv_conv_cmn_dblink                  fl
           , fnd_documents@xxaqv_conv_cmn_dblink             fd
           , fnd_attached_documents@xxaqv_conv_cmn_dblink    fad
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink    fdd
           , ap_suppliers@xxaqv_conv_cmn_dblink              aps
           , fnd_document_categories@xxaqv_conv_cmn_dblink   fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink          fdt
       WHERE fl.file_id      = fd.media_id
         AND aps.vendor_id   = fad.pk1_value
         AND fad.entity_name = 'PO_VENDORS'                        -- entity name
         AND fdd.name        = 'FILE'
         AND fad.document_id = fd.document_id
         AND fd.datatype_id  = fdd.datatype_id
         AND fad.category_id = fdc.category_id (+)
         AND fdt.document_id = fd.document_id
	     AND fad.pk1_value   = nvl(gv_pk1_value,fad.pk1_value)     -- passing PK1_VALUE
         AND EXISTS ( SELECT 1
                        FROM ap_suppliers apt
                       WHERE apt.segment1 = aps.segment1
                         AND apt.vendor_name = aps.vendor_name    );
        
  
		  CURSOR cur_file_data 
		  IS
		  SELECT file_id
		    FROM xxaqv_attach_docs_stg
		   WHERE datatype_name = 'FILE'
		     AND entity_name   = 'PO_VENDORS'
			 AND pk1_value     = nvl(gv_pk1_value,pk1_value);
    
     -- LOCAL VARIABLES
      ln_line_count    BINARY_INTEGER := 1;
      ln_error_count   NUMBER         := 0;
      ex_dml_errors    EXCEPTION;
      PRAGMA exception_init ( ex_dml_errors, -24381 );
      
  --INSERTING INTO STAGING TABLE
   BEGIN
   --Output
      xxaqv_conv_cmn_utility_pkg.print_logs('********************************** Staging Table Load Report *****************************************','O');
      xxaqv_conv_cmn_utility_pkg.print_logs('','O');
      xxaqv_conv_cmn_utility_pkg.print_logs(rpad('Date:',30)|| rpad(sysdate ,30 ), 'O');
      xxaqv_conv_cmn_utility_pkg.print_logs(         ''         , 'O'      );
      xxaqv_conv_cmn_utility_pkg.print_logs('******************************************************************************************************', 'O');
     
     --LOGS
     IF gv_debug_flag = 'YES' 
     THEN
      xxaqv_conv_cmn_utility_pkg.print_logs('********************************** Staging Table Load Report *****************************************');
      xxaqv_conv_cmn_utility_pkg.print_logs('');
      xxaqv_conv_cmn_utility_pkg.print_logs(rpad( 'Date:' , 30      )|| rpad(  sysdate  , 30      ));
      xxaqv_conv_cmn_utility_pkg.print_logs('');
      xxaqv_conv_cmn_utility_pkg.print_logs('******************************************************************************************************');
     END IF;
    

    gt_xxaqv_attach_docs_tab.delete;
    
    FOR i IN cur_short
    LOOP
     xxaqv_conv_cmn_utility_pkg.print_logs(i.pk1_value|| 'short');	 
     
     gt_xxaqv_attach_docs_tab(ln_line_count).pk1_value                       := i.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name                     := i.entity_name;             
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num                         := i.sequence_num;                
     --gt_xxaqv_attach_docs_tab(ln_line_count).title                           := i.title;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name                   := i.category_name;               
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name                   := i.datatype_name;           
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description            := i.document_description;    
     gt_xxaqv_attach_docs_tab(ln_line_count).text                            := i.text;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).url                             := i.url;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).file_name                       := i.file_name;              
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date                   := SYSDATE;        
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date                := SYSDATE;       
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login               := gv_login_id;      
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by                 := gv_user_id;       
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by                      := gv_user_id;            
     gt_xxaqv_attach_docs_tab(ln_line_count).processed_flag                  := 'LS';
     gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value                       := i.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value                       := i.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value                       := i.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value                       := i.pk5_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_name                     := i.vendor_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_number                   := i.vendor_number;
     ln_line_count                                                            := ln_line_count + 1;
     xxaqv_conv_cmn_utility_pkg.print_logs(i.pk1_value|| 'end_short');
     END LOOP;
     BEGIN
          FORALL i IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( i );

            xxaqv_conv_cmn_utility_pkg.print_logs('LODA_DATA: xxaqv_attach_docs_stg: Records loaded sucessfully: ' || SQL%rowcount, 'O' );
            xxaqv_conv_cmn_utility_pkg.print_logs('LODA_DATA: xxaqv_attach_docs_stg: Records loaded sucessfully: ' || SQL%rowcount);
          COMMIT;
          
         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Number of failures: ' || ln_error_count, 'O' );
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Number of failures: ' || ln_error_count);
               FOR i IN 1..ln_error_count 
               LOOP 
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Error: '
                  || i
                  || 'Array Index: '
                  || SQL%bulk_exceptions(i).error_index
                  || 'Message: '
                  || sqlerrm(-SQL%bulk_exceptions(i).error_code) , 'O');
               END LOOP;
            
            WHEN OTHERS 
            THEN
               x_retcode   := 1;
               x_err_msg   := 'LOAD_DATA: Unexpected error while populating data in xxaqv_attach_docs_stg.'
                            || to_char(sqlcode)
                            || '-'
                            || sqlerrm;
         END;


     gt_xxaqv_attach_docs_tab.delete;

    FOR j IN cur_long
    LOOP
     
         xxaqv_conv_cmn_utility_pkg.print_logs(j.pk1_value|| 'long');


     gt_xxaqv_attach_docs_tab(ln_line_count).pk1_value                       := j.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name                     := j.entity_name;             
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num                         := j.sequence_num;                
     --gt_xxaqv_attach_docs_tab(ln_line_count).title                           := i.title;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name                   := j.category_name;               
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name                   := j.datatype_name;           
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description            := j.document_description;    
     gt_xxaqv_attach_docs_tab(ln_line_count).text                            := j.text;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).url                             := j.url;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).file_name                       := j.file_name;              
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date                   := SYSDATE;        
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date                := SYSDATE;       
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login               := gv_login_id;      
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by                 := gv_user_id;       
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by                      := gv_user_id;            
     gt_xxaqv_attach_docs_tab(ln_line_count).processed_flag                  := 'LS';
     gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value                       := j.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value                       := j.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value                       := j.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value                       := j.pk5_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_name                     := j.vendor_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_number                   := j.vendor_number;
     xxaqv_conv_cmn_utility_pkg.print_logs(j.pk1_value|| 'end_long');
      ln_line_count                                                            := ln_line_count + 1;
     END LOOP;
     BEGIN
    
          FORALL j IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( j );

            xxaqv_conv_cmn_utility_pkg.print_logs('LODA_DATA: xxaqv_attach_docs_stg: Records loaded sucessfully: ' || SQL%rowcount, 'O' );
            xxaqv_conv_cmn_utility_pkg.print_logs('LODA_DATA: xxaqv_attach_docs_stg: Records loaded sucessfully: ' || SQL%rowcount);
          COMMIT;
         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Number of failures: ' || ln_error_count, 'O' );
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Number of failures: ' || ln_error_count);
               FOR i IN 1..ln_error_count 
               LOOP 
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Error: '
                  || i
                  || 'Array Index: '
                  || SQL%bulk_exceptions(i).error_index
                  || 'Message: '
                  || sqlerrm(-SQL%bulk_exceptions(i).error_code) , 'O');
               END LOOP;
        
            WHEN OTHERS 
        	THEN
               x_retcode   := 1;
               x_err_msg   := 'LOAD_DATA: Unexpected error while populating data in xxaqv_attach_docs_stg.'
                            || to_char(sqlcode)
                            || '-'
                            || sqlerrm;
         END;
	

    gt_xxaqv_attach_docs_tab.delete;

    FOR z IN cur_url
    LOOP
    	 xxaqv_conv_cmn_utility_pkg.print_logs(z.pk1_value || 'url');
     
     gt_xxaqv_attach_docs_tab(ln_line_count).pk1_value                       := z.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name                     := z.entity_name;             
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num                         := z.sequence_num;                
    -- gt_xxaqv_attach_docs_tab(ln_line_count).title                           := i.title;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name                   := z.category_name;               
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name                   := z.datatype_name;           
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description            := z.document_description;    
     gt_xxaqv_attach_docs_tab(ln_line_count).text                            := z.text;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).url                             := z.url;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).file_name                       := z.file_name;              
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date                   := SYSDATE;        
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date                := SYSDATE;       
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login               := gv_login_id;      
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by                 := gv_user_id;       
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by                      := gv_user_id;            
     gt_xxaqv_attach_docs_tab(ln_line_count).processed_flag                  := 'LS';
     gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value                       := z.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value                       := z.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value                       := z.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value                       := z.pk5_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_name                     := z.vendor_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_number                   := z.vendor_number;
     ln_line_count                                                            := ln_line_count + 1;
     END LOOP;
     BEGIN
          FORALL z IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( z );

            xxaqv_conv_cmn_utility_pkg.print_logs('LODA_DATA: xxaqv_attach_docs_stg: Records loaded sucessfully: ' || SQL%rowcount, 'O' );
            xxaqv_conv_cmn_utility_pkg.print_logs('LODA_DATA: xxaqv_attach_docs_stg: Records loaded sucessfully: ' || SQL%rowcount);
          COMMIT;
         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Number of failures: ' || ln_error_count, 'O' );
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Number of failures: ' || ln_error_count);
               FOR i IN 1..ln_error_count 
               LOOP 
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Error: '
                  || i
                  || 'Array Index: '
                  || SQL%bulk_exceptions(i).error_index
                  || 'Message: '
                  || sqlerrm(-SQL%bulk_exceptions(i).error_code) , 'O');
               END LOOP;
        
            WHEN OTHERS 
        	THEN
               x_retcode   := 1;
               x_err_msg   := 'LOAD_DATA: Unexpected error while populating data in xxaqv_attach_docs_stg.'
                            || to_char(sqlcode)
                            || '-'
                            || sqlerrm;
         END;
    
    gt_xxaqv_attach_docs_tab.delete;
    
    FOR m IN cur_file 
    LOOP
     ln_line_count                                                            := ln_line_count + 1;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk1_value                       := m.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name                     := m.entity_name;             
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num                         := m.sequence_num;                
     --gt_xxaqv_attach_docs_tab(ln_line_count).title                           := i.title;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name                   := m.category_name;               
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name                   := m.datatype_name;           
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description            := m.document_description;    
     gt_xxaqv_attach_docs_tab(ln_line_count).file_id                         := m.file_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).upload_date                     := m.upload_date;
     gt_xxaqv_attach_docs_tab(ln_line_count).file_name                       := m.file_name;              
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date                   := SYSDATE;        
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date                := SYSDATE;       
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login               := gv_login_id;      
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by                 := gv_user_id;       
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by                      := gv_user_id;            
     gt_xxaqv_attach_docs_tab(ln_line_count).processed_flag                  := 'LS';
    /* gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value                       := m.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value                       := m.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value                       := m.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value                       := m.pk5_value;*/
	 gt_xxaqv_attach_docs_tab(ln_line_count).file_content_type               := m.file_content_type;
	 gt_xxaqv_attach_docs_tab(ln_line_count).expiration_date                 := m.expiration_date;
	 gt_xxaqv_attach_docs_tab(ln_line_count).program_name                    := m.program_name;
	 gt_xxaqv_attach_docs_tab(ln_line_count).language                        := m.language;
	 gt_xxaqv_attach_docs_tab(ln_line_count).oracle_charset                  := m.oracle_charset;
     gt_xxaqv_attach_docs_tab(ln_line_count).file_format                     := m.file_format;
	 gt_xxaqv_attach_docs_tab(ln_line_count).vendor_name                     := m.vendor_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_number                   := m.vendor_number;
	 
     END LOOP;
     BEGIN
          FORALL m IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( m );

            xxaqv_conv_cmn_utility_pkg.print_logs('LODA_DATA: xxaqv_attach_docs_stg: Records loaded sucessfully: ' || SQL%rowcount, 'O' );
            xxaqv_conv_cmn_utility_pkg.print_logs('LODA_DATA: xxaqv_attach_docs_stg: Records loaded sucessfully: ' || SQL%rowcount);
          COMMIT;
		  
		  --inserting lob data
		  BEGIN
		
		   
		   FOR r_cur_file_data IN cur_file_data
		   LOOP
              
			  UPDATE xxaqv_attach_docs_stg xads
                 SET xads.file_data = ( SELECT file_data
                                          FROM fnd_lobs@xxaqv_conv_cmn_dblink fl
                                         WHERE r_cur_file_data.file_id = fl.file_id       )
               WHERE xads.file_id = r_cur_file_data.file_id 
			     AND xads.datatype_name = 'FILE'
				 AND xads.entity_name   = 'PO_VENDORS'; 
				 COMMIT;
		  END LOOP;
		  
		 
		 EXCEPTION 
          WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Number of failures: ' || ln_error_count, 'O' );
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Number of failures: ' || ln_error_count);
               FOR i IN 1..ln_error_count 
               LOOP 
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Error: '
                  || i
                  || 'Array Index: '
                  || SQL%bulk_exceptions(i).error_index
                  || 'Message: '
                  || sqlerrm(-SQL%bulk_exceptions(i).error_code) , 'O');
               END LOOP;		  
		  WHEN OTHERS 
                 THEN
                    x_retcode   := 1;
                    x_err_msg   := 'LOAD_DATA: Unexpected error while populating data in xxaqv_attach_docs_stg.'
                                 || to_char(sqlcode)
                                 || '-'
                                 || sqlerrm;
		  END;
         
		 EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Number of failures: ' || ln_error_count, 'O' );
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Number of failures: ' || ln_error_count);
               FOR i IN 1..ln_error_count 
               LOOP 
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Error: '
                  || i
                  || 'Array Index: '
                  || SQL%bulk_exceptions(i).error_index
                  || 'Message: '
                  || sqlerrm(-SQL%bulk_exceptions(i).error_code) , 'O');
               END LOOP;

            WHEN OTHERS 
            THEN
               x_retcode   := 1;
               x_err_msg   := 'LOAD_DATA: Unexpected error while populating data in xxaqv_attach_docs_stg.'
                            || to_char(sqlcode)
                            || '-'
                            || sqlerrm;
         END;
    
    
    EXCEPTION
      WHEN OTHERS THEN
         x_retcode   := 1;
         x_err_msg   := 'LOAD_DATA: Unexpected error while populating data in xxaqv_attach_docs_stg.'
                      || to_char(sqlcode)
                      || '-'
                      || sqlerrm;
   END supplier_load_staging_data;
	
	
--/****************************************************************************************************************
-- * Procedure  : sup_sites_load_staging                                                                          *
-- * Purpose    : This Procedure is used to load the supplier site attachment data into staging Table             *
-- ****************************************************************************************************************/

   PROCEDURE sup_sites_load_staging ( x_retcode       OUT   NUMBER
                                    , x_err_msg       OUT   VARCHAR2  )
    IS
   
 -- This Cursor is used to retrieve information about Short Text Attachments. --

      CURSOR cur_short IS
      SELECT fad.seq_num             sequence_num
           , aps.segment1            vendor_number
           , assa.vendor_site_code   vendor_site_code
           , fad.entity_name         entity_name
           , fdt.description         document_description
           ,  regexp_replace(fdst.short_text
             , '[^[!-~]]*'
             , ' '
                  )	        text
           , NULL                    file_name
           , NULL                    url
           , NULL                    function_name
           , fdd.name                datatype_name
           , fad.pk1_value           pk1_value
           , fad.pk2_value           pk2_value
           , fad.pk3_value           pk3_value
           , fad.pk4_value           pk4_value
           , fad.pk5_value           pk5_value
           , fdc.name                category_name
        FROM fnd_attached_documents@xxaqv_conv_cmn_dblink     fad
           , ap_supplier_sites_all@xxaqv_conv_cmn_dblink      assa
           , ap_suppliers@xxaqv_conv_cmn_dblink               aps
           , fnd_document_categories@xxaqv_conv_cmn_dblink    fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink           fdt
           , fnd_documents@xxaqv_conv_cmn_dblink              fd
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink     fdd
           , fnd_documents_short_text@xxaqv_conv_cmn_dblink   fdst
       WHERE fdst.media_id         = fd.media_id
         AND assa.vendor_site_id   = fad.pk1_value
         AND aps.vendor_id         =  assa.vendor_id
         AND fad.document_id       = fd.document_id
         AND fdd.datatype_id       = fd.datatype_id
         AND fad.category_id       = fdc.category_id (+)
         AND fdt.document_id       = fd.document_id
         AND fdd.name              = 'SHORT_TEXT'                     
         AND fad.pk1_value         = nvl(gv_pk1_value,fad.pk1_value)       -- passing PK1_VALUE        
         AND fad.entity_name       = 'PO_VENDOR_SITES'                     -- entity name
         AND EXISTS (SELECT 1 
                       FROM ap_suppliers apt
                          , ap_supplier_sites_all asst
                      WHERE apt.vendor_id         = asst.vendor_id
                        AND apt.segment1          = aps.segment1
                        AND assa.vendor_site_code = asst.vendor_site_code  );
                         
               

  -- This Cursor is used to retrieve information about Long Text Attachments ---

      CURSOR cur_long IS
      SELECT fad.seq_num              sequence_num
           , aps.segment1             vendor_number
           , assa.vendor_site_code    vendor_site_code
           , fad.entity_name          entity_name
           , fdt.description          document_description
           , fdlt.long_text           text
           , NULL                     file_name
           , NULL                     url
           , NULL                     function_name
           , fdd.name                 datatype_name
           , fad.pk1_value            pk1_value
           , fad.pk2_value            pk2_value
           , fad.pk3_value            pk3_value
           , fad.pk4_value            pk4_value
           , fad.pk5_value            pk5_value
           , fdc.name                 category_name
        FROM fnd_attached_documents@xxaqv_conv_cmn_dblink   fad
           , ap_supplier_sites_all@xxaqv_conv_cmn_dblink    assa
           , ap_suppliers@xxaqv_conv_cmn_dblink             aps
           , fnd_document_categories@xxaqv_conv_cmn_dblink  fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink         fdt
           , fnd_documents@xxaqv_conv_cmn_dblink            fd
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink   fdd
           , fnd_documents_long_text@xxaqv_conv_cmn_dblink  fdlt
       WHERE fdlt.media_id         = fd.media_id
         AND assa.vendor_site_id   = fad.pk1_value
         AND aps.vendor_id         =  assa.vendor_id
         AND fad.document_id = fd.document_id
         AND fdd.datatype_id = fd.datatype_id
         AND fad.category_id = fdc.category_id(+)
         AND fdt.document_id = fd.document_id
         AND fdd.name        = 'LONG_TEXT'                        
         AND fad.pk1_value   = nvl(gv_pk1_value,fad.pk1_value)         -- passing PK1_VALUE
         AND fad.entity_name = 'PO_VENDOR_SITES'                       -- entity name
         AND EXISTS (SELECT 1 
                       FROM ap_suppliers apt
                          , ap_supplier_sites_all asst
                      WHERE apt.vendor_id         = asst.vendor_id
                        AND apt.segment1          = aps.segment1
                        AND assa.vendor_site_code = asst.vendor_site_code   );
         
 -- This Cursor is used to retrieve information about Web URL Attachments.--

      CURSOR cur_url IS
       SELECT fad.seq_num             sequence_num
           , fdt.description          document_description
           , aps.segment1             vendor_number
           , assa.vendor_site_code    vendor_site_code
           , fad.entity_name          entity_name
           , null                     text
           , NULL                     file_name
           , fd.url                   url
           , NULL                     function_name
           , fdd.name                 datatype_name
           , fad.pk1_value            pk1_value
           , fad.pk2_value            pk2_value
           , fad.pk3_value            pk3_value
           , fad.pk4_value            pk4_value
           , fad.pk5_value            pk5_value
           , fdc.name                 category_name
        FROM fnd_documents@xxaqv_conv_cmn_dblink             fd
           , ap_suppliers@xxaqv_conv_cmn_dblink              aps
           , ap_supplier_sites_all@xxaqv_conv_cmn_dblink     assa
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink    fdd
           , fnd_attached_documents@xxaqv_conv_cmn_dblink    fad
           , fnd_document_categories@xxaqv_conv_cmn_dblink   fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink          fdt
       WHERE fdd.datatype_id     = fd.datatype_id
         AND assa.vendor_site_id = fad.pk1_value
         AND aps.vendor_id       =  assa.vendor_id
         AND fad.document_id     = fd.document_id
         AND fad.category_id     = fdc.category_id(+)
         AND fdt.document_id     = fd.document_id
         AND fdd.name            = 'WEB_PAGE'
         AND fad.entity_name     = 'PO_VENDOR_SITES'                   -- entity name
         AND fad.pk1_value       = nvl(gv_pk1_value,fad.pk1_value)     -- passing PK1_VALUE
         AND EXISTS (SELECT 1 
                       FROM ap_suppliers apt
                          , ap_supplier_sites_all asst
                      WHERE apt.vendor_id         = asst.vendor_id
                        AND apt.segment1          = aps.segment1
                        AND assa.vendor_site_code = asst.vendor_site_code                        );
         
 -- This Cursor is used to retrieve information about File Attachments. --

      /*CURSOR cur_file IS
      SELECT fad.entity_name
           , fad.seq_num
           , fdt.title
           , fdct.user_name   category
           , fdd.user_name    type_data
           , NULL short_text
           , NULL long_text
           , NULL url
           , fl.file_name
        FROM fnd_attached_documents@xxaqv_conv_cmn_dblink       fad
           , fnd_documents@xxaqv_conv_cmn_dblink                fd
           , fnd_documents_tl@xxaqv_conv_cmn_dblink             fdt
           , fnd_lobs@xxaqv_conv_cmn_dblink                     fl
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink       fdd
           , fnd_document_categories_tl@xxaqv_conv_cmn_dblink   fdct
       WHERE fad.document_id  = fd.document_id
         AND fd.media_id      = fl.file_id
         AND fd.document_id   = fdt.document_id
         AND fd.datatype_id   = fdd.datatype_id
         AND fd.category_id   = fdct.category_id
         AND fdd.user_name    = 'File'
         AND fad.entity_name = nvl(gv_entity_name,fad.entity_name); -- passing Entity Name*/

    
     -- LOCAL VARIABLES
      ln_line_count    BINARY_INTEGER := 1;
      ln_error_count   NUMBER         := 0;
    
      ex_dml_errors    EXCEPTION;
      PRAGMA exception_init ( ex_dml_errors, -24381 );
      
      --INSERTING INTO STAGING TABLE
   BEGIN
   --Output
      xxaqv_conv_cmn_utility_pkg.print_logs('********************************** Staging Table Load Report *****************************************','O');
      xxaqv_conv_cmn_utility_pkg.print_logs('','O');
      xxaqv_conv_cmn_utility_pkg.print_logs(rpad('Date:',30)|| rpad(sysdate ,30 ), 'O');
      xxaqv_conv_cmn_utility_pkg.print_logs(         ''         , 'O'      );
      xxaqv_conv_cmn_utility_pkg.print_logs('******************************************************************************************************', 'O');
     
     --LOGS
     IF gv_debug_flag = 'YES' 
     THEN
      xxaqv_conv_cmn_utility_pkg.print_logs('********************************** Staging Table Load Report *****************************************');
      xxaqv_conv_cmn_utility_pkg.print_logs('');
      xxaqv_conv_cmn_utility_pkg.print_logs(rpad( 'Date:' , 30      )|| rpad(  sysdate  , 30      ));
      xxaqv_conv_cmn_utility_pkg.print_logs('');
      xxaqv_conv_cmn_utility_pkg.print_logs('******************************************************************************************************');
     END IF;
    
    

    gt_xxaqv_attach_docs_tab.delete;
	
    FOR i IN cur_short 
    LOOP
     
     gt_xxaqv_attach_docs_tab(ln_line_count).pk1_value                       := i.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name                     := i.entity_name;             
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num                         := i.sequence_num;                
     --gt_xxaqv_attach_docs_tab(ln_line_count).title                           := i.title;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name                   := i.category_name;               
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name                   := i.datatype_name;           
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description            := i.document_description;    
     gt_xxaqv_attach_docs_tab(ln_line_count).text                            := i.text;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).url                             := i.url;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).file_name                       := i.file_name;              
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date                   := SYSDATE;        
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date                := SYSDATE;       
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login               := gv_login_id;      
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by                 := gv_user_id;       
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by                      := gv_user_id;            
     gt_xxaqv_attach_docs_tab(ln_line_count).processed_flag                  := 'LS';
     gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value                       := i.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value                       := i.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value                       := i.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value                       := i.pk5_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_site_code                := i.vendor_site_code;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_number                   := i.vendor_number;
     ln_line_count                                                            := ln_line_count + 1;
     END LOOP;
	 
     BEGIN
            FORALL i IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( i );

            xxaqv_conv_cmn_utility_pkg.print_logs('LODA_DATA: xxaqv_attach_docs_stg: Records loaded sucessfully: ' || SQL%rowcount, 'O' );
            xxaqv_conv_cmn_utility_pkg.print_logs('LODA_DATA: xxaqv_attach_docs_stg: Records loaded sucessfully: ' || SQL%rowcount);
          COMMIT;
          
         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Number of failures: ' || ln_error_count, 'O' );
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Number of failures: ' || ln_error_count);
               FOR i IN 1..ln_error_count 
               LOOP 
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Error: '
                  || i
                  || 'Array Index: '
                  || SQL%bulk_exceptions(i).error_index
                  || 'Message: '
                  || sqlerrm(-SQL%bulk_exceptions(i).error_code) , 'O');
               END LOOP;
        
            WHEN OTHERS 
            THEN
               x_retcode   := 1;
               x_err_msg   := 'LOAD_DATA: Unexpected error while populating data in xxaqv_attach_docs_stg.'
                            || to_char(sqlcode)
                            || '-'
                            || sqlerrm;
         END;

     gt_xxaqv_attach_docs_tab.delete;
	 
    FOR j IN cur_long 
    LOOP
     
     gt_xxaqv_attach_docs_tab(ln_line_count).pk1_value                       := j.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name                     := j.entity_name;             
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num                         := j.sequence_num;                
     --gt_xxaqv_attach_docs_tab(ln_line_count).title                           := i.title;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name                   := j.category_name;               
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name                   := j.datatype_name;           
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description            := j.document_description;    
     gt_xxaqv_attach_docs_tab(ln_line_count).text                            := j.text;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).url                             := j.url;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).file_name                       := j.file_name;              
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date                   := SYSDATE;        
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date                := SYSDATE;       
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login               := gv_login_id;      
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by                 := gv_user_id;       
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by                      := gv_user_id;            
     gt_xxaqv_attach_docs_tab(ln_line_count).processed_flag                  := 'LS';
     gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value                       := j.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value                       := j.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value                       := j.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value                       := j.pk5_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_site_code                := j.vendor_site_code;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_number                   := j.vendor_number;
     ln_line_count                                                            := ln_line_count + 1;
     END LOOP;
     BEGIN
          FORALL j IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( j );
    
            xxaqv_conv_cmn_utility_pkg.print_logs('LODA_DATA: xxaqv_attach_docs_stg: Records loaded sucessfully: ' || SQL%rowcount, 'O' );
            xxaqv_conv_cmn_utility_pkg.print_logs('LODA_DATA: xxaqv_attach_docs_stg: Records loaded sucessfully: ' || SQL%rowcount);
          COMMIT;
         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Number of failures: ' || ln_error_count, 'O' );
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Number of failures: ' || ln_error_count);
               FOR i IN 1..ln_error_count 
               LOOP 
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Error: '
                  || i
                  || 'Array Index: '
                  || SQL%bulk_exceptions(i).error_index
                  || 'Message: '
                  || sqlerrm(-SQL%bulk_exceptions(i).error_code) , 'O');
               END LOOP;
    
            WHEN OTHERS 
            THEN
               x_retcode   := 1;
               x_err_msg   := 'LOAD_DATA: Unexpected error while populating data in xxaqv_attach_docs_stg.'
                            || to_char(sqlcode)
                            || '-'
                            || sqlerrm;
         END;
    

    gt_xxaqv_attach_docs_tab.delete;
	
    FOR k IN cur_url 
    LOOP
     
     gt_xxaqv_attach_docs_tab(ln_line_count).pk1_value                       := k.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name                     := k.entity_name;             
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num                         := k.sequence_num;                
    -- gt_xxaqv_attach_docs_tab(ln_line_count).title                           := i.title;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name                   := k.category_name;               
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name                   := k.datatype_name;           
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description            := k.document_description;    
     gt_xxaqv_attach_docs_tab(ln_line_count).text                            := k.text;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).url                             := k.url;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).file_name                       := k.file_name;              
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date                   := SYSDATE;        
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date                := SYSDATE;       
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login               := gv_login_id;      
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by                 := gv_user_id;       
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by                      := gv_user_id;            
     gt_xxaqv_attach_docs_tab(ln_line_count).processed_flag                  := 'LS';
     gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value                       := k.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value                       := k.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value                       := k.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value                       := k.pk5_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_site_code                := k.vendor_site_code;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_number                   := k.vendor_number;
     ln_line_count                                                            := ln_line_count + 1;
     
     END LOOP;
     BEGIN
          FORALL k IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( k );
    
            xxaqv_conv_cmn_utility_pkg.print_logs('LODA_DATA: xxaqv_attach_docs_stg: Records loaded sucessfully: ' || SQL%rowcount, 'O' );
            xxaqv_conv_cmn_utility_pkg.print_logs('LODA_DATA: xxaqv_attach_docs_stg: Records loaded sucessfully: ' || SQL%rowcount);
          COMMIT;
         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Number of failures: ' || ln_error_count, 'O' );
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Number of failures: ' || ln_error_count);
               FOR i IN 1..ln_error_count 
               LOOP 
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Error: '
                  || i
                  || 'Array Index: '
                  || SQL%bulk_exceptions(i).error_index
                  || 'Message: '
                  || sqlerrm(-SQL%bulk_exceptions(i).error_code) , 'O');
               END LOOP;
    
            WHEN OTHERS 
            THEN
               x_retcode   := 1;
               x_err_msg   := 'LOAD_DATA: Unexpected error while populating data in xxaqv_attach_docs_stg.'
                            || to_char(sqlcode)
                            || '-'
                            || sqlerrm;
         END;
    
    /*
    
    FOR i IN cur_file 
    LOOP
     ln_line_count                                                            := ln_line_count + 1;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk1_value                       := i.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name                     := i.entity_name;             
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num                         := i.sequence_num;                
     gt_xxaqv_attach_docs_tab(ln_line_count).title                           := i.title;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name                   := i.category_name;               
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name                   := i.datatype_name;           
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description            := i.document_description;    
     gt_xxaqv_attach_docs_tab(ln_line_count).text                            := i.text;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).url                             := i.url;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).file_name                       := i.file_name;              
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date                   := SYSDATE;        
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date                := SYSDATE;       
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login               := gv_login_id;      
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by                 := gv_user_id;       
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by                      := gv_user_id;            
     gt_xxaqv_attach_docs_tab(ln_line_count).processed_flag                  := 'LS';
     gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value                       := i.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value                       := i.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value                       := i.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value                       := i.pk5_value;
     
     END LOOP;
     BEGIN
          FORALL i IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( i );
    
            xxaqv_conv_cmn_utility_pkg.print_logs('LODA_DATA: xxaqv_attach_docs_stg: Records loaded sucessfully: ' || SQL%rowcount, 'O' );
            xxaqv_conv_cmn_utility_pkg.print_logs('LODA_DATA: xxaqv_attach_docs_stg: Records loaded sucessfully: ' || SQL%rowcount);
          COMMIT;
         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Number of failures: ' || ln_error_count, 'O' );
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Number of failures: ' || ln_error_count);
               FOR i IN 1..ln_error_count 
               LOOP 
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Error: '
                  || i
                  || 'Array Index: '
                  || SQL%bulk_exceptions(i).error_index
                  || 'Message: '
                  || sqlerrm(-SQL%bulk_exceptions(i).error_code) , 'O');
               END LOOP;

            WHEN OTHERS 
            THEN
               x_retcode   := 1;
               x_err_msg   := 'LOAD_DATA: Unexpected error while populating data in xxaqv_attach_docs_stg.'
                            || to_char(sqlcode)
                            || '-'
                            || sqlerrm;
         END;
    */
    
    EXCEPTION
      WHEN OTHERS THEN
         x_retcode   := 1;
         x_err_msg   := 'LOAD_DATA: Unexpected error while populating data in xxaqv_attach_docs_stg.'
                      || to_char(sqlcode)
                      || '-'
                      || sqlerrm;
   END sup_sites_load_staging;	
   
--/****************************************************************************************************************
-- * Procedure : validate_staging_records                                                                         *
-- * Purpose   : This Procedure validate the records in the staging table.                                        *
-- ****************************************************************************************************************/	

   PROCEDURE validate_staging_records ( x_retcode       OUT   VARCHAR2
                                      , x_err_msg       OUT   VARCHAR2 )
     IS	
     
     --Local Variables
     gn_created_by                    NUMBER         := fnd_global.user_id;
     ln_failed_invoice                NUMBER         := NULL;
     ln_success_invoice               NUMBER         := NULL;
     l_val_status                     VARCHAR2(10)   := NULL;
     l_val_flag                       VARCHAR2(100);
     ln_error_msg                     VARCHAR2(4000) := NULL;
     lv_error_msg                     VARCHAR2(4000) := NULL;
     ln_mstr_flag                     VARCHAR2(10);
     ln_pk1_value                     VARCHAR2(100);
     lv_category_id                   NUMBER;
     lv_datatype_id                   NUMBER;
     
     
     CURSOR lcu_attach
     IS
     SELECT pk1_value   
          , entity_name                
          , seq_num                    
          , title                      
          , category_name              
          , category_id                
          , datatype_id                
          , datatype_name              
          , document_description       
          , text                       
          , url                        
          , file_name                  
          , record_id                  
          , creation_date              
          , last_update_date           
          , last_update_login          
          , last_updated_by            
          , created_by                 
          , processed_flag             
          , error_msg                  
          , document_id                
          , media_id 
          , rowid
          , pk2_value                
          , pk3_value               
          , pk4_value               
          , pk5_value 
          , vendor_name
          , vendor_number
          , vendor_site_code
       FROM xxaqv_attach_docs_stg
      WHERE processed_flag = 'LS'
        AND entity_name    = nvl(gv_entity_name,entity_name) ;
        
     
     BEGIN
      xxaqv_conv_cmn_utility_pkg.print_logs('********************************** Validation Report *************************************************', 'O');
      xxaqv_conv_cmn_utility_pkg.print_logs(   ''   , 'O');      
      xxaqv_conv_cmn_utility_pkg.print_logs(rpad(   'Date:'   , 30)|| rpad(   sysdate   , 30), 'O');
      xxaqv_conv_cmn_utility_pkg.print_logs(   ''   , 'O');
      xxaqv_conv_cmn_utility_pkg.print_logs('******************************************************************************************************', 'O');
      IF gv_debug_flag = 'YES' THEN
         xxaqv_conv_cmn_utility_pkg.print_logs('----------------------------------Starting Validations------------------------------------------------');
         xxaqv_conv_cmn_utility_pkg.print_logs('********************************** Validation Report *************************************************');
         xxaqv_conv_cmn_utility_pkg.print_logs('');
         xxaqv_conv_cmn_utility_pkg.print_logs(rpad(    'Date:'    , 30 )|| rpad(    sysdate    , 30 ));
         xxaqv_conv_cmn_utility_pkg.print_logs('');
         xxaqv_conv_cmn_utility_pkg.print_logs('******************************************************************************************************'
         );
      END IF;
      
      FOR r_lcu_attch IN lcu_attach
      LOOP
         ln_error_msg   := '';   -- Resetting error message after every invoice
         l_val_flag     := 'Y';  -- Resetting Flag Value after every invoice
         ln_pk1_value   := '';   -- Resetting the PK1_VALUE
         
         -- category name validation
          IF gv_debug_flag = 'YES' 
          THEN
            xxaqv_conv_cmn_utility_pkg.print_logs('Validating category id');
         END IF;
          l_val_status   := validate_category_id(r_lcu_attch.category_name,lv_category_id,lv_error_msg);
          IF l_val_status = 'E' 
          THEN
            IF gv_debug_flag = 'YES' 
            THEN
               xxaqv_conv_cmn_utility_pkg.print_logs('Validation of category id failed');
            END IF;
            l_val_flag     := 'N';
            ln_error_msg   := ln_error_msg
                            || '~'
                            || lv_error_msg;
         ELSE
            IF gv_debug_flag = 'YES' 
            THEN
               xxaqv_conv_cmn_utility_pkg.print_logs('Validation of category id Suceeded');
            END IF;
         END IF;
         
          -- datatype name validation
          IF gv_debug_flag = 'YES' 
          THEN
            xxaqv_conv_cmn_utility_pkg.print_logs('Validating datatype id');
         END IF;
          l_val_status   := validate_datatype_id(r_lcu_attch.datatype_name,lv_datatype_id,lv_error_msg);
          IF l_val_status = 'E' 
          THEN
              IF gv_debug_flag = 'YES' 
              THEN
                 xxaqv_conv_cmn_utility_pkg.print_logs('Validation of datatype id failed');
              END IF;
            l_val_flag     := 'N';
            ln_error_msg   := ln_error_msg
                            || '~'
                            || lv_error_msg;
          ELSE
            IF gv_debug_flag = 'YES' 
            THEN
               xxaqv_conv_cmn_utility_pkg.print_logs('Validation of datatype id Suceeded');
            END IF;
         END IF;
         
-----------------------------------------------------------------------------------------PK1_VALUE VALIDATION-------------------------------------------------------------------------------------------------------------	 
         
         IF gv_entity_name = 'PO_VENDORS'
         THEN
         -- PK1 value validation for suppliers
          /*IF gv_debug_flag = 'YES' 
          THEN
            xxaqv_conv_cmn_utility_pkg.print_logs('Validating pk1_value for supplier');
         END IF;*/
          l_val_status   := validate_supplier_pk(r_lcu_attch.vendor_number,r_lcu_attch.vendor_name,ln_pk1_value,lv_error_msg);
          IF l_val_status = 'E' 
          THEN
              IF gv_debug_flag = 'YES' 
              THEN
                 xxaqv_conv_cmn_utility_pkg.print_logs('Validation of pk1_value failed for suppliers  ' || r_lcu_attch.vendor_number||'  '||r_lcu_attch.vendor_name);
              END IF;
            l_val_flag     := 'N';
            ln_error_msg   := ln_error_msg
                            || '~'
                            || lv_error_msg;
         /* ELSE
            IF gv_debug_flag = 'YES' 
            THEN
               xxaqv_conv_cmn_utility_pkg.print_logs('Validation of pk1_value Suceeded for suppliers');
            END IF;*/
         END IF;
         END IF;
         
          IF gv_entity_name = 'PO_VENDOR_SITES'
         THEN
         -- PK1 value validation for supplier sites
          /*IF gv_debug_flag = 'YES' 
          THEN
            xxaqv_conv_cmn_utility_pkg.print_logs('Validating pk1_value for supplier sites');
         END IF;*/
          l_val_status   := validate_sup_sites_pk(r_lcu_attch.vendor_number,r_lcu_attch.vendor_site_code,ln_pk1_value,lv_error_msg);
          IF l_val_status = 'E' 
          THEN
              IF gv_debug_flag = 'YES' 
              THEN
                 xxaqv_conv_cmn_utility_pkg.print_logs('Validation of pk1_value failed for supplier sites  '  || r_lcu_attch.vendor_number||'  '||r_lcu_attch.vendor_site_code);
              END IF;
            l_val_flag     := 'N';
            ln_error_msg   := ln_error_msg
                            || '~'
                            || lv_error_msg;
          /*ELSE
            IF gv_debug_flag = 'YES' 
            THEN
               xxaqv_conv_cmn_utility_pkg.print_logs('Validation of pk1_value Suceeded for supplier sites');
            END IF;*/
         END IF;
         END IF;
         
         
------------------------------------------------------------------------------------------------UPDATING THE STAGING TABLE WITH VALIDATED DATA-----------------------------------------------------------------------------		 
         --UPDATING THE VALIDATED RECORDS
         IF l_val_flag = 'N' 
         THEN	
         UPDATE xxaqv_attach_docs_stg
            SET processed_flag   = 'VE'
              , error_msg        = ln_error_msg
              , category_id      = lv_category_id
              , datatype_id      = lv_datatype_id
              , pk1_value        = ln_pk1_value
              , created_by       = gn_created_by
              , creation_date    = sysdate
              , last_updated_by  = gn_created_by
              , last_update_date = sysdate
          WHERE rowid            = r_lcu_attch.rowid;
         COMMIT;
         IF gv_debug_flag = 'YES' THEN
               xxaqv_conv_cmn_utility_pkg.print_logs('Staging Table Updating:record is erronous');
            END IF;
         
         ELSE
         
         UPDATE xxaqv_attach_docs_stg
            SET processed_flag   = 'VS'
              , error_msg        = ln_error_msg
              , category_id      = lv_category_id
              , datatype_id      = lv_datatype_id
              , pk1_value        = ln_pk1_value
              , created_by       = gn_created_by
              , creation_date    = sysdate
              , last_updated_by  = gn_created_by
              , last_update_date = sysdate
          WHERE rowid            = r_lcu_attch.rowid;
          
         COMMIT;
         IF gv_debug_flag = 'YES' 
         THEN
          xxaqv_conv_cmn_utility_pkg.print_logs('Staging Table Updated with valid records');
            END IF;
         END IF;
      END LOOP;
      
      
      BEGIN
         SELECT COUNT(processed_flag)
           INTO ln_failed_invoice
           FROM xxaqv_attach_docs_stg
          WHERE processed_flag = 'VE';

         SELECT COUNT(processed_flag)
           INTO ln_success_invoice
           FROM xxaqv_attach_docs_stg
          WHERE processed_flag = 'VS';

         xxaqv_conv_cmn_utility_pkg.print_logs('NUMBER OF RECORDS FAILED IN VALIDATION =' || ln_failed_invoice, 'O' );
         xxaqv_conv_cmn_utility_pkg.print_logs('NUMBER OF RECORDS WITH NO ISSUE IN VALIDATION =' || ln_success_invoice, 'O');
      EXCEPTION
         WHEN OTHERS THEN
            xxaqv_conv_cmn_utility_pkg.print_logs('validating error for staging table encountered'
                                                  || to_char(sqlcode)
                                                  || '-'
                                                  || sqlerrm);

            x_err_msg   := 'Unexpeected error occured while vaidating staging records during validation success ratio count';
            x_retcode   := 1;
      END;
      EXCEPTION
      WHEN OTHERS 
      THEN
         xxaqv_conv_cmn_utility_pkg.print_logs('validating error for staging table encountered'
                                               || to_char(sqlcode)
                                               || '-'
                                               || sqlerrm);

         x_err_msg   := 'Unexpeected error occured while vaidating staging records';
         x_retcode   := 1;
     END validate_staging_records;

--/****************************************************************************************************************
-- * Procedure  : populate_fnd_lobs                                                                               *
-- * Purpose    : This Procedure is used to populate fnd_lobs                                                     *
-- ****************************************************************************************************************/  

   PROCEDURE populate_fnd_lobs ( x_retcode       OUT   NUMBER
                               , x_err_msg       OUT   VARCHAR2
   ) IS
   
   CURSOR pop_fnd_lobs 
   IS
   SELECT file_name
        , file_content_type
        , file_data
        , upload_date
        , expiration_date
        , program_name
        , program_tag
        , language
        , oracle_charset
        , file_format
		, pk1_value
     FROM xxaqv_attach_docs_stg
	WHERE entity_name   = gv_entity_name
      AND datatype_name = 'FILE'
	  FOR UPDATE OF file_id;
   
   BEGIN
   
       FOR r_populate_lobs IN pop_fnd_lobs
	   LOOP 
       INSERT INTO fnd_lobs ( file_id
                            , file_name
                            , file_content_type
                            , file_data
                            , upload_date
                            , expiration_date
                            , program_name
                            , program_tag
                            , language
                            , oracle_charset
                            , file_format    )
                       VALUES (
					        fnd_lobs_s.nextval
						   , r_populate_lobs.file_name	
						   , r_populate_lobs.file_content_type	
						   , r_populate_lobs.file_data	
						   , r_populate_lobs.upload_date	
						   , r_populate_lobs.expiration_date	
						   , r_populate_lobs.program_name	
						   , r_populate_lobs.program_tag	
						   , r_populate_lobs.language	
						   , r_populate_lobs.oracle_charset	
						   , r_populate_lobs.file_format	
					   );
					   
		UPDATE xxaqv_attach_docs_stg
		   SET file_id = fnd_lobs_s.currval
		WHERE current of pop_fnd_lobs;

		  
		  COMMIT;
		  
		END LOOP;
		
    EXCEPTION
      WHEN OTHERS THEN
         x_err_msg := x_err_msg
                      || to_char(sqlcode)
                      || '-'
                      || sqlerrm;
         x_retcode   := 1;
  END populate_fnd_lobs;   
--/****************************************************************************************************************
-- * Procedure  : IMPORT_STAGING_DATA                                                                             *
-- * Purpose    : This Procedure is used to valdate the data in Staging Table                                     *
-- ****************************************************************************************************************/  

   PROCEDURE import_staging_data ( x_retcode       OUT   NUMBER
                                 , x_err_msg       OUT   VARCHAR2
   ) IS
-- This Cursor is used to retrieve information from Staging Table --
    
      CURSOR cur_select IS
      SELECT pk1_value   
          , entity_name                
          , seq_num                    
          , title                      
          , category_name              
          , category_id                
          , datatype_id                
          , datatype_name              
          , document_description       
          , text                       
          , url                        
          , file_name                  
          , record_id                  
          , creation_date              
          , last_update_date           
          , last_update_login          
          , last_updated_by            
          , created_by                 
          , processed_flag             
          , error_msg                  
          , document_id                
          , media_id    
          , pk2_value                
          , pk3_value               
          , pk4_value               
          , pk5_value 
          , file_id
       FROM xxaqv_attach_docs_stg
      WHERE processed_flag = 'VS'
        AND entity_name    = nvl(gv_entity_name,entity_name) ;

   BEGIN
      FOR lcu_r_cur_select IN cur_select 
      LOOP                                                     ----Calling WEB API
         fnd_webattch.add_attachment( seq_num                => lcu_r_cur_select.seq_num
                                    , category_id            => lcu_r_cur_select.category_id          --category_id
                                    , document_description   => lcu_r_cur_select.document_description --description
                                    , datatype_id            => lcu_r_cur_select.datatype_id --datatype_id
                                    , text                   => lcu_r_cur_select.text
                                    , file_name              => lcu_r_cur_select.file_name                       
                                    , url                    => lcu_r_cur_select.url
                                    , function_name          => NULL  --function_name
                                    , entity_name            => lcu_r_cur_select.entity_name
                                    , pk1_value              => lcu_r_cur_select.pk1_value
                                    , pk2_value              => lcu_r_cur_select.pk2_value
                                    , pk3_value              => lcu_r_cur_select.pk3_value
                                    , pk4_value              => lcu_r_cur_select.pk4_value
                                    , pk5_value              => lcu_r_cur_select.pk5_value
                                    , media_id               => lcu_r_cur_select.file_id
                                    , user_id                => gv_user_id
         );
      END LOOP;
   END import_staging_data;

--/****************************************************************************************************************
-- * Procedure : TIE_BACK_STAGING                                                                                 *
-- * Purpose   : This procedure will tie back base table data to staging table.                                   *
-- ****************************************************************************************************************/

   PROCEDURE tie_back_staging ( x_retcode   OUT   NUMBER
                              , x_err_msg   OUT   VARCHAR2
   ) IS
     -- Local Variables
      ln_err_count        NUMBER := 0;
      ln_count            NUMBER;
      lv_processed_flag   VARCHAR2(2);
      ln_entity_name      VARCHAR2(100);
      ln_pk1_value        VARCHAR2(100);
      
    BEGIN
      xxaqv_conv_cmn_utility_pkg.print_logs('**************************** Attachment Import Report *******************************','O');
      xxaqv_conv_cmn_utility_pkg.print_logs('' , 'O');
      xxaqv_conv_cmn_utility_pkg.print_logs(rpad( 'Date:',30)||rpad(sysdate,30) ,'O');
      xxaqv_conv_cmn_utility_pkg.print_logs( ''  , 'O');
      xxaqv_conv_cmn_utility_pkg.print_logs('***********************************************************************************' ,'O' );
      IF gv_debug_flag = 'YES' 
      THEN
         xxaqv_conv_cmn_utility_pkg.print_logs('TIE_BACK_STAGING: Update staging tables with success records and tie back oracle data.');
      END IF;
      xxaqv_conv_cmn_utility_pkg.print_logs('TIE_BACK_STAGING: Tie back oracle data for Attachments');
      FOR i IN (
         SELECT entity_name
              , pk1_value
           FROM xxaqv_attach_docs_stg
          WHERE processed_flag = 'IS'
      ) LOOP
         BEGIN
            ln_entity_name       := NULL;
            ln_pk1_value         := NULL;
            SELECT entity_name
                 , pk1_value
              INTO ln_entity_name
                 , ln_pk1_value  
              FROM fnd_attached_documents
             WHERE entity_name = i.entity_name
               AND pk1_value   = i.pk1_value;
               
            lv_processed_flag   := 'PS';
         EXCEPTION
            WHEN no_data_found THEN
               lv_processed_flag := 'PE';
         END;

         BEGIN
            UPDATE xxaqv_attach_docs_stg
               SET processed_flag  = lv_processed_flag
             WHERE entity_name     = i.entity_name
               AND pk1_value       = i.pk1_value
               AND processed_flag  = 'IS';

            COMMIT;
         EXCEPTION
            WHEN OTHERS THEN
               ROLLBACK;
               x_retcode   := 1;
               x_err_msg   := 'TIE_BACK_STAGING: Unexpected error while updating staging tables '
                            || to_char(sqlcode)
                            || '-'
                            || sqlerrm;
         END;

      END LOOP;

      IF gv_debug_flag = 'YES' THEN
         xxaqv_conv_cmn_utility_pkg.print_logs('TIE_BACK_STAGING: Update staging tables with error record details.');
      END IF;
      xxaqv_conv_cmn_utility_pkg.print_logs('' , 'O'      );
      xxaqv_conv_cmn_utility_pkg.print_logs( 'Attachment Imported/Updated Successfully.', 'O' );
      xxaqv_conv_cmn_utility_pkg.print_logs( '' , 'O' );
      xxaqv_conv_cmn_utility_pkg.print_logs(  rpad('entity_name', 30 ) || rpad(   'pk1_value' , 30) , 'O' );

      FOR j IN (
         SELECT xfadts.entity_name
              , xfadts.pk1_value
           FROM xxaqv_attach_docs_stg   xfadts
          WHERE xfadts.processed_flag = 'PS'
      ) LOOP 
      xxaqv_conv_cmn_utility_pkg.print_logs( rpad('entity_name', 30 ) || rpad('pk1_value', 30 ) , 'O');
      END LOOP;

      xxaqv_conv_cmn_utility_pkg.print_logs('', 'O');
      xxaqv_conv_cmn_utility_pkg.print_logs('***********************************************************************************', 'O');
   EXCEPTION
      WHEN OTHERS THEN
         x_retcode   := 1;
         x_err_msg   := 'TIE_BACK_STAGING: Unexpected error in tie_back_staging '
                      || to_char(sqlcode)
                      || '-'
                      || sqlerrm;
         xxaqv_conv_cmn_utility_pkg.print_logs('TIE_BACK_STAGING: Unexpected error in tie_back_staging'
                                               || '-'
                                               || sqlerrm);
   END tie_back_staging;
    
--/****************************************************************************************************************
-- * Procedure  : MAIN                                                                                            *
-- * Purpose    : This Procedure is the main procedure                                                            *
-- ****************************************************************************************************************/     
   
PROCEDURE main( errbuf          OUT   VARCHAR2
              , retcode         OUT   VARCHAR2
              , p_conv_mode     IN    VARCHAR2
              , p_debug_flag    IN    VARCHAR2
              , p_entity_name   IN    VARCHAR2
              , p_pk1_value     IN    VARCHAR2
   ) IS
    
    lv_error_msg    VARCHAR2(4000) := NULL;
    l_retcode       NUMBER;
    
    BEGIN      
    IF p_debug_flag IS NULL 
    THEN
         gv_debug_flag := NULL;
    ELSE
         gv_debug_flag := p_debug_flag;
    END IF;
         
    IF p_entity_name IS NULL 
    THEN
         gv_entity_name := NULL;
    ELSE
         gv_entity_name := p_entity_name;
    END IF;
    
    IF p_pk1_value IS NULL 
    THEN
         gv_pk1_value := NULL;
    ELSE
         gv_pk1_value := p_pk1_value;
    END IF;
    
    IF p_conv_mode = 'LOAD' 
    THEN
       IF gv_debug_flag = 'YES' 
             THEN
                xxaqv_conv_cmn_utility_pkg.print_logs(' EXTRACTING DATA AND LOADING INTO THE STAGING TABLE');
                xxaqv_conv_cmn_utility_pkg.print_logs(' Conversion Mode : ' || p_conv_mode);
                xxaqv_conv_cmn_utility_pkg.print_logs(' Entity Name : '     || gv_entity_name);
             END IF;
        IF gv_entity_name = 'PO_VENDORS'
        THEN
    
            supplier_load_staging_data( x_retcode     => l_retcode
                                      , x_err_msg     => lv_error_msg   );
      
        ELSIF gv_entity_name = 'PO_VENDOR_SITES'
        THEN
    
            sup_sites_load_staging( x_retcode     => l_retcode
                                  , x_err_msg     => lv_error_msg   );
        END IF;
        
        
   
    ELSIF p_conv_mode = 'VALIDATE' THEN
         IF gv_debug_flag = 'YES' 
         THEN
            xxaqv_conv_cmn_utility_pkg.print_logs('VALIDATING RECORDS IN THE STAGING TABLE');
            xxaqv_conv_cmn_utility_pkg.print_logs(' Conversion Mode : ' || p_conv_mode);
            xxaqv_conv_cmn_utility_pkg.print_logs(' Entity Name : '     || gv_entity_name);
         END IF;
        
         validate_staging_records( x_retcode       => l_retcode
                                 , x_err_msg       => lv_error_msg );
        
		
		ELSIF p_conv_mode = 'POPULATE_BLOB' THEN
         IF gv_debug_flag = 'YES' 
         THEN
            xxaqv_conv_cmn_utility_pkg.print_logs('VALIDATING RECORDS IN THE STAGING TABLE');
            xxaqv_conv_cmn_utility_pkg.print_logs(' Conversion Mode : ' || p_conv_mode);
            xxaqv_conv_cmn_utility_pkg.print_logs(' Entity Name : '     || gv_entity_name);
         END IF;
        
         populate_fnd_lobs ( x_retcode       => l_retcode
                           , x_err_msg       => lv_error_msg ); 
							 
        ELSIF p_conv_mode = 'IMPORT' THEN
         IF gv_debug_flag = 'YES' 
         THEN
            xxaqv_conv_cmn_utility_pkg.print_logs('VALIDATING RECORDS IN THE STAGING TABLE');
            xxaqv_conv_cmn_utility_pkg.print_logs(' Conversion Mode : ' || p_conv_mode);
            xxaqv_conv_cmn_utility_pkg.print_logs(' Entity Name : '     || gv_entity_name);
         END IF;
        
         import_staging_data ( x_retcode       => l_retcode
                             , x_err_msg       => lv_error_msg );
        
	
        ELSIF p_conv_mode = 'TIEBACK' 
        THEN
        IF gv_debug_flag = 'YES' 
         THEN
            xxaqv_conv_cmn_utility_pkg.print_logs('VALIDATING RECORDS IN THE STAGING TABLE');
            xxaqv_conv_cmn_utility_pkg.print_logs(' Conversion Mode : ' || p_conv_mode);
            xxaqv_conv_cmn_utility_pkg.print_logs(' Entity Name : '     || gv_entity_name);
         END IF;
         tie_back_staging ( x_retcode   => l_retcode
                          , x_err_msg   => lv_error_msg );
      END IF;
	  
	    errbuf := lv_error_msg;
        retcode := l_retcode;
      EXCEPTION
      WHEN OTHERS THEN
         xxaqv_conv_cmn_utility_pkg.print_logs('Program Error'
                                               || p_conv_mode
                                               || to_char(sqlcode)
                                               || '-'
                                               || sqlerrm);

                 errbuf := lv_error_msg
                         || to_char(sqlcode)
                         || '-'
                         || sqlerrm;
				retcode := 1;		 
    END main;
END xxaqv_fnd_attachments_pkg;


