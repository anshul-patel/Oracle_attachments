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
-- ****************************************************************************************************************


   -- Global PLSQL Types

  TYPE gt_xxaqv_fnd_atts_doc_type IS
    TABLE OF xxaqv.xxaqv_fnd_atts_doc_table_stg%rowtype INDEX BY BINARY_INTEGER;
	
   -- Global Records
   gt_xxaqv_fnd_atts_doc_tab     gt_xxaqv_fnd_atts_doc_type;


  /* Global Variables
  */
   gv_debug_flag                 VARCHAR2(10);
   gv_id                         NUMBER;
   gv_entity_name                VARCHAR2(100);
   gv_attach_type                VARCHAR2(100);
   
--/****************************************************************************************************************
-- * Procedure  : LOAD_STAGING_DATA                                                                               *
-- * Purpose    : This Procedure is used to load the data into staging Table                                      *
-- ****************************************************************************************************************/

   PROCEDURE load_staging_data ( x_retcode       OUT   NUMBER
                               , x_err_msg       OUT   VARCHAR2  )
    IS
   
 -- This Cursor is used to retrieve information about Short Text Attachments. --

      CURSOR cur_short IS
      SELECT fad.seq_num       sequence_num
           , fdt.description   document_description
           , fad.entity_name   entity_name
           , fdst.short_text   text
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
        FROM fnd_documents_short_text@xxaqv_conv_cmn_dblink    fdst
            ,fnd_attached_documents@xxaqv_conv_cmn_dblink      fad
            ,fnd_documents@xxaqv_conv_cmn_dblink               fd
            ,fnd_document_datatypes@xxaqv_conv_cmn_dblink      fdd
            ,fnd_document_categories@xxaqv_conv_cmn_dblink     fdc
            ,fnd_documents_tl@xxaqv_conv_cmn_dblink            fdt
       WHERE fdst.media_id = fd.media_id
         AND fad.document_id = fd.document_id
         AND fdd.datatype_id = fd.datatype_id
         and fad.category_id= fdc.category_id(+)
         AND fdt.document_id = fd.document_id
         AND fdd.name = 'SHORT_TEXT'
         AND fad.entity_name = nvl(gv_entity_name,fad.entity_name);-- passing Entity Name

  -- This Cursor is used to retrieve information about Long Text Attachments ---

      CURSOR cur_long IS
      SELECT fad.seq_num       sequence_num
           , fdt.description   document_description
           , fad.entity_name   entity_name
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
        FROM fnd_documents_long_text@xxaqv_conv_cmn_dblink     fdlt
            ,fnd_attached_documents@xxaqv_conv_cmn_dblink      fad
            ,fnd_documents@xxaqv_conv_cmn_dblink               fd
            ,fnd_document_datatypes@xxaqv_conv_cmn_dblink      fdd
            ,fnd_document_categories@xxaqv_conv_cmn_dblink     fdc
            ,fnd_documents_tl@xxaqv_conv_cmn_dblink            fdt
       WHERE fdlt.media_id = fd.media_id
         AND fad.document_id = fd.document_id
         AND fdd.datatype_id = fd.datatype_id
         AND fad.category_id= fdc.category_id(+)
         AND fdt.document_id = fd.document_id
         AND fdd.name = 'LONG_TEXT'
         AND fad.entity_name = nvl(gv_entity_name,fad.entity_name);-- passing Entity Name
         
 -- This Cursor is used to retrieve information about Web URL Attachments.--

      CURSOR cur_url IS
      SELECT fad.seq_num       sequence_num
           , fdt.description   document_description
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
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink    fdd
           , fnd_attached_documents@xxaqv_conv_cmn_dblink    fad
           , fnd_document_categories@xxaqv_conv_cmn_dblink   fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink          fdt
       WHERE fdd.datatype_id = fd.datatype_id
         AND fad.document_id = fd.document_id
         AND fad.category_id= fdc.category_id(+)
         AND fdt.document_id = fd.document_id
         AND fdd.name = 'WEB_PAGE'
         AND fad.entity_name = nvl(gv_entity_name,fad.entity_name); -- passing Entity Name
         
 -- This Cursor is used to retrieve information about File Attachments. --

      CURSOR cur_file IS
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
         AND fad.entity_name  = p_entity_name;

    
     -- LOCAL VARIABLES
      ln_line_count    BINARY_INTEGER := 0;
      ln_error_count   NUMBER := 0;
      ex_dml_errors EXCEPTION;
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
	
	IF p_attach_type = 'SHORT_TEXT' or gv_attach_type = 'ALL'
	THEN
	FOR i IN cur_short 
	LOOP
	 ln_line_count                                                            := ln_line_count + 1;
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).entity_record_identifier        := i.pk1_value;
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).entity_name                     := i.entity_name;             
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).seq_num                         := i.sequence_num;                
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).title                           := i.title;                   
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).category_name                   := i.category_name;               
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).datatype_name                   := i.datatype_name;           
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).document_description            := i.document_description;    
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).text                            := i.text;                   
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).url                             := i.url;                   
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).file_name                       := i.file_name;              
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).creation_date                   := SYSDATE;        
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).last_update_date                := SYSDATE;       
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).last_update_login               := gn_login_id;      
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).last_updated_by                 := gn_user_id;       
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).created_by                      := gn_user_id;            
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).processed_flag                  := 'LS';
     
	 END LOOP;
	 BEGIN
          FORALL i IN gt_xxaqv_fnd_atts_doc_tab.first..gt_xxaqv_fnd_atts_doc_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_fnd_atts_doc_table_stg VALUES gt_xxaqv_fnd_atts_doc_tab ( i );

            xxaqv_conv_cmn_utility_pkg.print_logs('LODA_DATA: xxaqv_fnd_atts_doc_table_stg: Records loaded sucessfully: ' || SQL%rowcount, 'O' );
            xxaqv_conv_cmn_utility_pkg.print_logs('LODA_DATA: xxaqv_fnd_atts_doc_table_stg: Records loaded sucessfully: ' || SQL%rowcount);
          COMMIT;
		  
         EXCEPTION
            WHEN ex_dml_errors 
			THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_fnd_atts_doc_table_stg: Number of failures: ' || ln_error_count, 'O' );
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_fnd_atts_doc_table_stg: Number of failures: ' || ln_error_count);
               FOR i IN 1..ln_error_count 
			   LOOP 
			   xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_fnd_atts_doc_table_stg: Error: '
                  || i
                  || 'Array Index: '
                  || SQL%bulk_exceptions(i).error_index
                  || 'Message: '
                  || sqlerrm(-SQL%bulk_exceptions(i).error_code) , 'O');
               END LOOP;

            WHEN OTHERS 
			THEN
               x_retcode   := 1;
               x_err_msg   := 'LOAD_DATA: Unexpected error while populating data in xxaqv_fnd_atts_doc_table_stg.'
                            || to_char(sqlcode)
                            || '-'
                            || sqlerrm;
         END;

	END IF;
	
	IF p_attach_type = 'LONG_TEXT' or gv_attach_type = 'ALL'
	THEN
	FOR i IN cur_long 
	LOOP
	 ln_line_count                                                            := ln_line_count + 1;
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).entity_record_identifier        := i.pk1_value;
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).entity_name                     := i.entity_name;             
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).seq_num                         := i.sequence_num;                
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).title                           := i.title;                   
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).category_name                   := i.category_name;               
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).datatype_name                   := i.datatype_name;           
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).document_description            := i.document_description;    
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).text                            := i.text;                   
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).url                             := i.url;                   
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).file_name                       := i.file_name;              
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).creation_date                   := SYSDATE;        
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).last_update_date                := SYSDATE;       
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).last_update_login               := gn_login_id;      
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).last_updated_by                 := gn_user_id;       
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).created_by                      := gn_user_id;            
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).processed_flag                  := 'LS';
     
	 END LOOP;
	 BEGIN
          FORALL i IN gt_xxaqv_fnd_atts_doc_tab.first..gt_xxaqv_fnd_atts_doc_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_fnd_atts_doc_table_stg VALUES gt_xxaqv_fnd_atts_doc_tab ( i );

            xxaqv_conv_cmn_utility_pkg.print_logs('LODA_DATA: xxaqv_fnd_atts_doc_table_stg: Records loaded sucessfully: ' || SQL%rowcount, 'O' );
            xxaqv_conv_cmn_utility_pkg.print_logs('LODA_DATA: xxaqv_fnd_atts_doc_table_stg: Records loaded sucessfully: ' || SQL%rowcount);
          COMMIT;
         EXCEPTION
            WHEN ex_dml_errors 
			THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_fnd_atts_doc_table_stg: Number of failures: ' || ln_error_count, 'O' );
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_fnd_atts_doc_table_stg: Number of failures: ' || ln_error_count);
               FOR i IN 1..ln_error_count 
			   LOOP 
			   xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_fnd_atts_doc_table_stg: Error: '
                  || i
                  || 'Array Index: '
                  || SQL%bulk_exceptions(i).error_index
                  || 'Message: '
                  || sqlerrm(-SQL%bulk_exceptions(i).error_code) , 'O');
               END LOOP;

            WHEN OTHERS 
			THEN
               x_retcode   := 1;
               x_err_msg   := 'LOAD_DATA: Unexpected error while populating data in xxaqv_fnd_atts_doc_table_stg.'
                            || to_char(sqlcode)
                            || '-'
                            || sqlerrm;
         END;
	END IF;
	
	IF p_attach_type = 'WEB_PAGE' or gv_attach_type = 'ALL'
	THEN
	FOR i IN cur_url 
	LOOP
	 ln_line_count                                                            := ln_line_count + 1;
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).entity_record_identifier        := i.pk1_value;
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).entity_name                     := i.entity_name;             
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).seq_num                         := i.sequence_num;                
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).title                           := i.title;                   
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).category_name                   := i.category_name;               
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).datatype_name                   := i.datatype_name;           
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).document_description            := i.document_description;    
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).text                            := i.text;                   
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).url                             := i.url;                   
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).file_name                       := i.file_name;              
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).creation_date                   := SYSDATE;        
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).last_update_date                := SYSDATE;       
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).last_update_login               := gn_login_id;      
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).last_updated_by                 := gn_user_id;       
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).created_by                      := gn_user_id;            
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).processed_flag                  := 'LS';
     
	 END LOOP;
	 BEGIN
          FORALL i IN gt_xxaqv_fnd_atts_doc_tab.first..gt_xxaqv_fnd_atts_doc_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_fnd_atts_doc_table_stg VALUES gt_xxaqv_fnd_atts_doc_tab ( i );

            xxaqv_conv_cmn_utility_pkg.print_logs('LODA_DATA: xxaqv_fnd_atts_doc_table_stg: Records loaded sucessfully: ' || SQL%rowcount, 'O' );
            xxaqv_conv_cmn_utility_pkg.print_logs('LODA_DATA: xxaqv_fnd_atts_doc_table_stg: Records loaded sucessfully: ' || SQL%rowcount);
          COMMIT;
         EXCEPTION
            WHEN ex_dml_errors 
			THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_fnd_atts_doc_table_stg: Number of failures: ' || ln_error_count, 'O' );
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_fnd_atts_doc_table_stg: Number of failures: ' || ln_error_count);
               FOR i IN 1..ln_error_count 
			   LOOP 
			   xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_fnd_atts_doc_table_stg: Error: '
                  || i
                  || 'Array Index: '
                  || SQL%bulk_exceptions(i).error_index
                  || 'Message: '
                  || sqlerrm(-SQL%bulk_exceptions(i).error_code) , 'O');
               END LOOP;

            WHEN OTHERS 
			THEN
               x_retcode   := 1;
               x_err_msg   := 'LOAD_DATA: Unexpected error while populating data in xxaqv_fnd_atts_doc_table_stg.'
                            || to_char(sqlcode)
                            || '-'
                            || sqlerrm;
         END;
	END IF;
	
	IF p_attach_type = 'FILE' or gv_attach_type = 'ALL'
	THEN
	FOR i IN cur_file 
	LOOP
	 ln_line_count                                                            := ln_line_count + 1;
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).entity_record_identifier        := i.pk1_value;
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).entity_name                     := i.entity_name;             
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).seq_num                         := i.sequence_num;                
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).title                           := i.title;                   
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).category_name                   := i.category_name;               
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).datatype_name                   := i.datatype_name;           
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).document_description            := i.document_description;    
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).text                            := i.text;                   
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).url                             := i.url;                   
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).file_name                       := i.file_name;              
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).creation_date                   := SYSDATE;        
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).last_update_date                := SYSDATE;       
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).last_update_login               := gn_login_id;      
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).last_updated_by                 := gn_user_id;       
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).created_by                      := gn_user_id;            
     gt_xxaqv_fnd_atts_doc_tab(ln_line_count).processed_flag                  := 'LS';
     
	 END LOOP;
	 BEGIN
          FORALL i IN gt_xxaqv_fnd_atts_doc_tab.first..gt_xxaqv_fnd_atts_doc_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_fnd_atts_doc_table_stg VALUES gt_xxaqv_fnd_atts_doc_tab ( i );

            xxaqv_conv_cmn_utility_pkg.print_logs('LODA_DATA: xxaqv_fnd_atts_doc_table_stg: Records loaded sucessfully: ' || SQL%rowcount, 'O' );
            xxaqv_conv_cmn_utility_pkg.print_logs('LODA_DATA: xxaqv_fnd_atts_doc_table_stg: Records loaded sucessfully: ' || SQL%rowcount);
          COMMIT;
         EXCEPTION
            WHEN ex_dml_errors 
			THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_fnd_atts_doc_table_stg: Number of failures: ' || ln_error_count, 'O' );
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_fnd_atts_doc_table_stg: Number of failures: ' || ln_error_count);
               FOR i IN 1..ln_error_count 
			   LOOP 
			   xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_fnd_atts_doc_table_stg: Error: '
                  || i
                  || 'Array Index: '
                  || SQL%bulk_exceptions(i).error_index
                  || 'Message: '
                  || sqlerrm(-SQL%bulk_exceptions(i).error_code) , 'O');
               END LOOP;

            WHEN OTHERS 
			THEN
               x_retcode   := 1;
               x_err_msg   := 'LOAD_DATA: Unexpected error while populating data in xxaqv_fnd_atts_doc_table_stg.'
                            || to_char(sqlcode)
                            || '-'
                            || sqlerrm;
         END;
	END IF;
	
	EXCEPTION
      WHEN OTHERS THEN
         x_retcode   := 1;
         x_err_msg   := 'LOAD_DATA: Unexpected error while populating data in xxaqv_fnd_atts_doc_table_stg.'
                      || to_char(sqlcode)
                      || '-'
                      || sqlerrm;
   END load_staging_data;
	
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
	 lv_category_id                   NUMBER;
	 lv_datatype_id                   NUMBER;
	 
	 
	 CURSOR lcu_attach
	 IS
	 SELECT entity_record_identifier   
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
       FROM xxaqv_fnd_atts_doc_table_stg
	  WHERE processed_flag = 'LS'
     	AND entity_name    = nvl(gv_entity_name,entity_name) 
		AND datatype_name  = nvl(gv_attach_type,datatype_name);
	 
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
		 
		 -- category name validation
		  IF gv_debug_flag = 'YES' THEN
            xxaqv_conv_cmn_utility_pkg.print_logs('Validating category id');
         END IF;
		  l_val_status   := validate_category_id(r_lcu_attch.category_name,lv_category_id,lv_error_msg);
		  IF l_val_status = 'E' THEN
            IF gv_debug_flag = 'YES' THEN
               xxaqv_conv_cmn_utility_pkg.print_logs('Validation of category id failed');
            END IF;
            l_val_flag     := 'N';
            ln_error_msg   := ln_error_msg
                            || '~'
                            || lv_error_msg;
         ELSE
            IF gv_debug_flag = 'YES' THEN
               xxaqv_conv_cmn_utility_pkg.print_logs('Validation of category id Suceeded');
            END IF;
         END IF;
		 
		  -- datatype name validation
		  IF gv_debug_flag = 'YES' THEN
            xxaqv_conv_cmn_utility_pkg.print_logs('Validating datatype id');
         END IF;
		  l_val_status   := validate_category_id(r_lcu_attch.datatype_name,lv_datatype_id,lv_error_msg);
		  IF l_val_status = 'E' THEN
            IF gv_debug_flag = 'YES' THEN
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
		 IF l_val_flag = 'N' and ln_mstr_flag ='Y'
            THEN
            ln_mstr_flag := 'N';
            END IF;
		 IF ln_mstr_flag = 'N' 
		 THEN	
		 UPDATE xxaqv_fnd_atts_doc_table_stg
		    SET processed_flag   = 'VE'
			  , error_msg        = ln_error_msg
			  , category_id      = lv_category_id
			  , datatype_id      = lv_datatype_id
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
		 
		 UPDATE xxaqv_fnd_atts_doc_table_stg
		    SET processed_flag   = 'VS'
			  , error_msg        = ln_error_msg
			  , category_id      = lv_category_id
			  , datatype_id      = lv_datatype_id
			  , created_by       = gn_created_by
              , creation_date    = sysdate
              , last_updated_by  = gn_created_by
              , last_update_date = sysdate
		  WHERE rowid            = r_lcu_attch.rowid;
		  
		 COMMIT;
		 IF gv_debug_flag = 'YES' THEN
		  xxaqv_conv_cmn_utility_pkg.print_logs('Staging Table Updated with valid records');
            END IF;
		 END IF;
	  END LOOP;
	  
	  
	  BEGIN
         SELECT COUNT(processed_flag)
           INTO ln_failed_invoice
           FROM xxaqv_fnd_atts_doc_table_stg
          WHERE processed_flag = 'VE';

         SELECT COUNT(processed_flag)
           INTO ln_success_invoice
           FROM xxaqv_fnd_atts_doc_table_stg
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
      WHEN OTHERS THEN
         xxaqv_conv_cmn_utility_pkg.print_logs('validating error for staging table encountered'
                                               || to_char(sqlcode)
                                               || '-'
                                               || sqlerrm);

         x_err_msg   := 'Unexpeected error occured while vaidating staging records';
         x_retcode   := 1;
	 END validate_staging_records;
	 
--/****************************************************************************************************************
-- * Procedure  : IMPORT_STAGING_DATA                                                                             *
-- * Purpose    : This Procedure is used to valdate the data in Staging Table                                     *
-- ****************************************************************************************************************/  

   PROCEDURE import_staging_data ( x_retcode       OUT   NUMBER
                                 , x_err_msg       OUT   VARCHAR2
   ) IS
-- This Cursor is used to retrieve information from Staging Table --
    
      CURSOR lcu_r_cur_select IS
      SELECT entity_record_identifier   
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
       FROM xxaqv_fnd_atts_doc_table_stg
	  WHERE processed_flag = 'VS'
     	AND entity_name    = nvl(gv_entity_name,entity_name) 
		AND datatype_name  = nvl(gv_attach_type,datatype_name);

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
                                    , pk1_value              => lcu_r_cur_select.entity_record_identifier
                                    , pk2_value              => NULL
                                    , pk3_value              => NULL
                                    , pk4_value              => NULL
                                    , pk5_value              => NULL
                                    , media_id               => NULL
                                    , user_id                => lcu_r_cur_select.user_id
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
      ln_invoice_id       NUMBER;
   BEGIN
      xxaqv_conv_cmn_utility_pkg.print_logs('**************************** Attachment Import Report *******************************','O');
      xxaqv_conv_cmn_utility_pkg.print_logs(         ''         , 'O'      );
      xxaqv_conv_cmn_utility_pkg.print_logs(rpad( 'Date:',30)||rpad(sysdate,30) ,'O');
      xxaqv_conv_cmn_utility_pkg.print_logs(         ''         , 'O'      );
      xxaqv_conv_cmn_utility_pkg.print_logs('***********************************************************************************' ,'O' );
      IF gv_debug_flag = 'YES' 
	  THEN
         xxaqv_conv_cmn_utility_pkg.print_logs('TIE_BACK_STAGING: Update staging tables with success records and tie back oracle data.');
      END IF;
      xxaqv_conv_cmn_utility_pkg.print_logs('TIE_BACK_STAGING: Tie back oracle data for Attachments');
      FOR i IN (
         SELECT invoice_num
                , invoice_id
                , vendor_id
                , vendor_site_id
           FROM xxaqv_ap_inv_header_stg
          WHERE processed_flag = 'IS'
      ) LOOP
         BEGIN
            ln_invoice_id       := NULL;
            SELECT invoice_id
              INTO ln_invoice_id
              FROM ap_invoices_all
             WHERE invoice_num = i.invoice_num
               AND vendor_id      = i.vendor_id
               AND vendor_site_id  = i.vendor_site_id;

            lv_processed_flag   := 'PS';
         EXCEPTION
            WHEN no_data_found THEN
               lv_processed_flag := 'PE';
         END;

         BEGIN
            UPDATE xxaqv_ap_inv_header_stg
               SET
               processed_flag = lv_processed_flag
             WHERE invoice_num = i.invoice_num
               AND vendor_id       = i.vendor_id
               AND vendor_site_id  = i.vendor_site_id
               AND processed_flag  = 'IS';

            UPDATE xxaqv_ap_inv_lines_stg
               SET
               processed_flag = lv_processed_flag
             WHERE invoice_id = i.invoice_id
               AND processed_flag = 'IS';

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
      xxaqv_conv_cmn_utility_pkg.print_logs(
         ''
         , 'O'
      );
      xxaqv_conv_cmn_utility_pkg.print_logs(
         'AP Invoices Information Imported/Updated Successfully.'
         , 'O'
      );
      xxaqv_conv_cmn_utility_pkg.print_logs(
         ''
         , 'O'
      );
      xxaqv_conv_cmn_utility_pkg.print_logs(
         rpad(
            'invoice_id'
            , 30
         )
         || rpad(
            'invoice_amount'
            , 30
         )
         || rpad(
            'invoice_num'
            , 30
         )
         || rpad(
            'VENDOR_SITE_id'
            , 30
         )
         || rpad(
            'source'
            , 30
         )
         || rpad(
            'invoice_type_lookup_code'
            , 30
         )
         , 'O'
      );

      FOR j IN (
         SELECT xaihs.invoice_id
                , xaihs.invoice_num
                , xaihs.invoice_amount
                , xaihs.vendor_site_id
                , xaihs.source
                , xaihs.invoice_type_lookup_code
           FROM xxaqv_ap_inv_header_stg   xaihs
                , xxaqv_ap_inv_lines_stg    xails
          WHERE xaihs.processed_flag = 'PS'
            AND xails.processed_flag  = 'PS'
            AND xaihs.invoice_id      = xails.invoice_id
      ) LOOP 
	  xxaqv_conv_cmn_utility_pkg.print_logs( rpad('invoice_id', 30 ) || rpad( 'invoice_amount' , 30 ) || rpad('invoice_num', 30 ) || rpad('VENDOR_SITE_id', 30 ) || rpad('source', 30 ) || rpad('invoice_type_lookup_code', 30 ) , 'O');
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
              , p_attach_type   IN    VARCHAR2
              , p_debug_flag    IN    VARCHAR2
              , p_entity_name   IN    VARCHAR2
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

   IF p_attach_type IS NULL 
    THEN
         gv_attach_type := 'ALL';
    ELSE
         gv_entity_name := p_entity_name;
    END IF;

    IF p_conv_mode = 'LOAD' 
    THEN
         IF gv_debug_flag = 'YES' 
         THEN
            xxaqv_conv_cmn_utility_pkg.print_logs(' EXTRACTING DATA');
            xxaqv_conv_cmn_utility_pkg.print_logs(' Conversion Mode : ' || p_conv_mode);
            xxaqv_conv_cmn_utility_pkg.print_logs(' Attachment Type : ' || gv_attach_type);
			xxaqv_conv_cmn_utility_pkg.print_logs(' Entity Name : '     || gv_entity_name);
         END IF;

        load_staging_data( x_retcode     => l_retcode
                         , x_err_msg     => lv_err_msg   );
   
	ELSIF p_conv_mode = 'VALIDATE' THEN
         IF gv_debug_flag = 'YES' 
		 THEN
            xxaqv_conv_cmn_utility_pkg.print_logs('VALIDATING RECORDS IN THE STAGING TABLE');
            xxaqv_conv_cmn_utility_pkg.print_logs(' Conversion Mode : ' || p_conv_mode);
            xxaqv_conv_cmn_utility_pkg.print_logs(' Attachment Type : ' || gv_attach_type);
			xxaqv_conv_cmn_utility_pkg.print_logs(' Entity Name : '     || gv_entity_name);
         END IF;

         validate_staging_records( x_retcode       => l_retcode
                                 , x_err_msg       => lv_error_msg );
		
		
		ELSIF p_conv_mode = 'IMPORT' THEN
         IF gv_debug_flag = 'YES' 
		 THEN
            xxaqv_conv_cmn_utility_pkg.print_logs('VALIDATING RECORDS IN THE STAGING TABLE');
            xxaqv_conv_cmn_utility_pkg.print_logs(' Conversion Mode : ' || p_conv_mode);
            xxaqv_conv_cmn_utility_pkg.print_logs(' Attachment Type : ' || gv_attach_type);
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
            xxaqv_conv_cmn_utility_pkg.print_logs(' Attachment Type : ' || gv_attach_type);
			xxaqv_conv_cmn_utility_pkg.print_logs(' Entity Name : '     || gv_entity_name);
         END IF;
		 tie_back_staging ( x_retcode   => l_retcode
                          , x_err_msg   => lv_error_msg );
      END IF;
	  EXCEPTION
      WHEN OTHERS THEN
         xxaqv_conv_cmn_utility_pkg.print_logs('Program Error'
                                               || p_conv_mode
                                               || to_char(sqlcode)
                                               || '-'
                                               || sqlerrm);

         lv_error_msg := lv_error_msg
                         || to_char(sqlcode)
                         || '-'
                         || sqlerrm;
	END main;					 
END xxaqv_fnd_attachments_pkg;


