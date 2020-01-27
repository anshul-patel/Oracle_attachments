CREATE OR REPLACE PACKAGE BODY xxaqv_fnd_attachments_pkg AS
--/*------------------------------------------------- Arqiva -----------------------------------------------------*
-- ****************************************************************************************************************
-- * Type               : Package Body                                                                            *
-- * Application Module : Arqiva Custom Application (xxaqv)                                                       *
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

  /* Global Variables
  */

   gv_entity_name         VARCHAR2(100) ;
   gv_pk1_value           VARCHAR2(100);
   gv_module_name         VARCHAR2(80) := 'XXAQV_FND_ATTACHMENTS_PKG';
   gv_staging_table       VARCHAR2(80) := 'XXAQV_ATTACH_DOCS_STG';
   gv_module              VARCHAR2(75) := NULL;
   gv_conv_mode           VARCHAR2(50) := NULL;
   gv_debug_flag          VARCHAR2(10) := NULL;
   gn_commit_cnt          NUMBER;
   gv_legacy_id_from      VARCHAR2(40) := NULL;
   gv_legacy_id_to        VARCHAR2(40) := NULL;
   gv_process_flag        VARCHAR2(5);
   gn_retcode             NUMBER;
   gv_err_msg             VARCHAR2(4000);
   gn_request_id          NUMBER       := fnd_global.conc_request_id;
   gn_user_id             NUMBER       := fnd_global.user_id;
   gn_login_id            NUMBER       := fnd_global.login_id;
   gn_org_id              NUMBER;      
   gd_sys_date            DATE         := sysdate;
   gv_load_success        VARCHAR2(80) := 'Load Success';
   gv_validate_success    VARCHAR2(80) := 'Validate Success';
   gv_validate_error      VARCHAR2(80) := 'Validate Error';
   gv_import_success      VARCHAR2(80) := 'Import Success';
   gv_import_error        VARCHAR2(80) := 'Import Error';
   gn_batch_run           NUMBER;
   gn_debug_level         NUMBER := 3; -- 0-only exceptions -- 1-Info Debugs -- 2-all debugs messages -- 3 No logs -- use wtih p_debug_flag
   gn_log_level           NUMBER := 0;


   -- Global PLSQL Types
  TYPE gt_xxaqv_attach_docs_type IS
    TABLE OF xxaqv.xxaqv_attach_docs_stg%rowtype INDEX BY BINARY_INTEGER;

   -- Global Records
   gt_xxaqv_attach_docs_tab     gt_xxaqv_attach_docs_type;
   
--/****************************************************************************************************************
-- * Procedure : print_debug                                                                                      *
-- * Purpose   : This procedure will print debug messages to program log file                                     *
-- ****************************************************************************************************************/

   PROCEDURE print_debug( p_err_msg     IN   VARCHAR2
                        , p_log_level   IN   NUMBER DEFAULT 3
   ) IS
   BEGIN
      IF p_log_level < gn_debug_level 
      THEN
         xxaqv_conv_cmn_utility_pkg.print_logs(p_err_msg);
      END IF;
   END print_debug;


--/****************************************************************************************************************
-- * Procedure : print_report                                                                                     *
-- * Purpose   : This procedure will print process report to concurrent program output                            *
-- ****************************************************************************************************************/

   PROCEDURE print_report 
   IS
      ln_total_cnt   NUMBER := 0;
      ln_error_cnt   NUMBER := 0;
   BEGIN
      SELECT COUNT(*)
        INTO ln_total_cnt
        FROM xxaqv_attach_docs_stg
       WHERE 1 = 1;

      SELECT COUNT(*)
        INTO ln_error_cnt
        FROM xxaqv_attach_docs_stg
       WHERE 1 = 1
         AND process_flag IN ( 'Validate Error'
                             , 'Import Error'   );

      xxaqv_conv_cmn_utility_pkg.print_logs('**************************** Attachment Import Report *******************************','O' );
      xxaqv_conv_cmn_utility_pkg.print_logs('','O' );
      xxaqv_conv_cmn_utility_pkg.print_logs(rpad('Date:',30)                   || to_char(sysdate,'DD-Mon-RRRR HH24:MI:SS'),'O');
      xxaqv_conv_cmn_utility_pkg.print_logs(rpad('Module:',30)                 || gv_module,'O');
      xxaqv_conv_cmn_utility_pkg.print_logs(rpad('Conversion Mode:' ,30)       || gv_conv_mode,'O');
      xxaqv_conv_cmn_utility_pkg.print_logs(rpad('Legacy Identifier from:',30) || gv_legacy_id_from,'O');
      xxaqv_conv_cmn_utility_pkg.print_logs(rpad('Legacy Identifier to:',30)   || gv_legacy_id_to,'O');
      xxaqv_conv_cmn_utility_pkg.print_logs(rpad('Commit Count:',30)           || gn_commit_cnt,'O');
      xxaqv_conv_cmn_utility_pkg.print_logs(rpad('Debug Flag:',30)             || gv_debug_flag,'O');
      xxaqv_conv_cmn_utility_pkg.print_logs(rpad('Total Records:',30)          || ln_total_cnt,'O');
      xxaqv_conv_cmn_utility_pkg.print_logs(rpad('Successful Records:',30)     || (ln_total_cnt - ln_error_cnt),'O');
      xxaqv_conv_cmn_utility_pkg.print_logs(rpad('Error Records:',30)          || ln_error_cnt,'O');
      xxaqv_conv_cmn_utility_pkg.print_logs(rpad('Load Rate %age:',30)         || (((ln_total_cnt - ln_error_cnt) / ln_total_cnt) * 100),'O');
      xxaqv_conv_cmn_utility_pkg.print_logs('','O');
      xxaqv_conv_cmn_utility_pkg.print_logs('***********************************************************************************','O');
      IF ln_error_cnt > 0 
      THEN
         xxaqv_conv_cmn_utility_pkg.print_output( p_module_name     => gv_module_name
                                                 ,p_batch_run       => gn_batch_run
                                                 ,p_stage           => gv_conv_mode
                                                 ,p_staging_table   => gv_staging_table
         );
         
      ELSIF ln_error_cnt = 0 
      THEN
         xxaqv_conv_cmn_utility_pkg.print_logs('','O');
         xxaqv_conv_cmn_utility_pkg.print_logs('**************************** No Errors To Report *******************************','O');
         xxaqv_conv_cmn_utility_pkg.print_logs('' ,'O');
         xxaqv_conv_cmn_utility_pkg.print_logs('***********************************************************************************','O');
      END IF;

   END print_report;

--/****************************************************************************************************************
-- * Procedure : insert_error_records                                                                             *
-- * Purpose   : This procedure will insert error recrods into common utility error table                         *
-- ****************************************************************************************************************/

   PROCEDURE insert_error_records ( p_batch_id    IN   NUMBER
                                  , p_legacy_id   IN   VARCHAR2
                                  , p_error_col   IN   VARCHAR2
                                  , p_error_msg   IN   VARCHAR2
   ) IS
   BEGIN
      xxaqv_conv_cmn_utility_pkg.insert_err_recs( p_module_name         => gv_module_name
                                                , p_staging_table       => gv_staging_table
                                                , p_batch_run           => p_batch_id
                                                , p_process_stage       => gv_conv_mode
                                                , p_legacy_identifier   => p_legacy_id
                                                , p_error_column        => p_error_col
                                                , p_error_message       => p_error_msg);
   END insert_error_records;     
--/*****************************************************************************************************************
-- * Procedure  : validate_category_id                                                                             *
-- * Purpose    : Procedure to validate category ID                                                                *
-- *****************************************************************************************************************/

   PROCEDURE validate_category_id ( p_category_name   IN    VARCHAR2
                                  , x_category_id     OUT   VARCHAR2
                                  , x_retcode         OUT   NUMBER
                                  , x_err_msg         OUT   VARCHAR2
   )    IS
   BEGIN
      x_retcode   := 0;
      x_err_msg   := NULL;
      SELECT category_id
        INTO x_category_id
        FROM fnd_document_categories_tl
       WHERE upper(trim(user_name)) = upper(trim(p_category_name));

    EXCEPTION
      WHEN no_data_found THEN
         x_retcode   := 1;
         x_err_msg   := 'CATEGORY_ID: No Data Found for CATEGORY NAME: ' || p_category_name;
      WHEN too_many_rows THEN
         x_retcode   := 1;
         x_err_msg   := 'CATEGORY_ID: Multiple records with same CATEGORY NAME: ' || p_category_name;
      WHEN OTHERS THEN
         x_retcode   := 1;
         x_err_msg   := 'CATEGORY_ID: Unexpected error: ' || sqlerrm;
   END validate_category_id;


--/*****************************************************************************************************************
-- * Procedure  : validate_datatype_id                                                                             *
-- * Purpose    : Procedure to validate datatype ID                                                                *
-- *****************************************************************************************************************/

   PROCEDURE validate_datatype_id ( p_datatype_name IN    VARCHAR2
                                  , x_datatype_id   OUT   VARCHAR2
                                  , x_retcode       OUT   NUMBER
                                  , x_err_msg       OUT   VARCHAR2
   )    IS
    BEGIN
      x_retcode   := 0;
      x_err_msg   := NULL;
            SELECT datatype_id
              INTO x_datatype_id
              FROM fnd_document_datatypes
             WHERE upper(trim(name)) = upper(trim(p_datatype_name));

   EXCEPTION
      WHEN no_data_found THEN
         x_retcode   := 1;
         x_err_msg   := 'DATATYPE_ID: No Data Found for Datatype Name : ' || p_datatype_name;
      WHEN too_many_rows THEN
         x_retcode   := 1;
         x_err_msg   := 'DATATYPE_ID: Multiple records with same  Datatype Name : ' || p_datatype_name;
      WHEN OTHERS THEN
         x_retcode   := 1;
         x_err_msg   := 'DATATYPE_ID: Unexpected error: ' || sqlerrm;
   END validate_datatype_id;

--/*****************************************************************************************************************
-- * Procedure : validate_supplier_pk                                                                              *
-- * Purpose   : Procedure to validate PK1_VALUE for supplier                                                      *
-- *****************************************************************************************************************/

   PROCEDURE validate_supplier_pk ( p_vendor_number IN    VARCHAR2
                                 , p_vendor_name    IN    VARCHAR2
                                 , x_pk1_value      OUT   VARCHAR2
                                 , x_retcode        OUT   NUMBER
                                 , x_err_msg        OUT   VARCHAR2
   ) 
   IS
   BEGIN
      x_retcode   := 0;
      x_err_msg   := NULL;
            SELECT vendor_id 
              INTO x_pk1_value
              FROM ap_suppliers
             WHERE upper(trim(vendor_name)) = upper(trim(p_vendor_name))
               AND segment1 = p_vendor_number;

   EXCEPTION
      WHEN no_data_found THEN
         x_retcode   := 1;
         x_err_msg   := 'VENDOR_ID: No Data Found for PK1_VALUE for Supplier Number: ' || p_vendor_number;
      WHEN too_many_rows THEN
         x_retcode   := 1;
         x_err_msg   := 'VENDOR_ID: Multiple records with same PK1_VALUE for Supplier Number: ' || p_vendor_number;
      WHEN OTHERS THEN
         x_retcode   := 1;
         x_err_msg   := 'VENDOR_ID: Unexpected error: ' || sqlerrm;
   END validate_supplier_pk;


--/*****************************************************************************************************************
-- * Procedure  : validate_sup_sites_pk                                                                            *
-- * Purpose   : This Procedure will validate PK1_VALUE for supplier                                               *
-- *****************************************************************************************************************/

   PROCEDURE validate_sup_sites_pk( p_vendor_number    IN    VARCHAR2
                                  , p_vendor_site_code IN    VARCHAR2
                                  , x_pk1_value        OUT   VARCHAR2
                                  , x_retcode          OUT   NUMBER
                                  , x_err_msg          OUT   VARCHAR2
   ) 
   IS
   BEGIN
      x_retcode   := 0;
      x_err_msg   := NULL;
        SELECT vendor_site_id 
          INTO x_pk1_value
          FROM ap_suppliers asa
             , ap_supplier_sites_all assa
         WHERE asa.vendor_id         = assa.vendor_id
           AND asa.segment1          = p_vendor_number
           AND assa.vendor_site_code = p_vendor_site_code;

   EXCEPTION
      WHEN no_data_found THEN
         x_retcode   := 1;
         x_err_msg   := 'VENDOR_SITE: No Data Found for PK1_VALUE for VENDOR_SITE_CODE: ' || p_vendor_site_code  ||'  and vendor number: ' ||p_vendor_number ;
      WHEN too_many_rows THEN
         x_retcode   := 1;
         x_err_msg   := 'VENDOR_SITE: Multiple records with same PK1_VALUE for VENDOR_SITE_CODE: ' || p_vendor_site_code  ||'  and vendor number: ' ||p_vendor_number ;
      WHEN OTHERS THEN
         x_retcode   := 1;
         x_err_msg   := 'VENDOR_SITE: Unexpected error: ' || sqlerrm;
   END validate_sup_sites_pk;


--/*****************************************************************************************************************
-- * Procedure  : validate_ap_invoices_pk                                                                          *
-- * Purpose   : This Procedure will validate PK1_VALUE for AP_INVOICES                                            *
-- *****************************************************************************************************************/

   PROCEDURE validate_ap_invoices_pk( p_vendor_number    IN    VARCHAR2
                                    , p_vendor_site_code IN    VARCHAR2   
                                    , p_vendor_name      IN    VARCHAR2
                                    , p_invoice_number   IN    VARCHAR2
                                    , x_pk1_value        OUT   VARCHAR2
                                    , x_retcode          OUT   NUMBER
                                    , x_err_msg          OUT   VARCHAR2
   ) 
   IS
   BEGIN
      x_retcode   := 0;
      x_err_msg   := NULL;
                                      
            SELECT invoice_id 
              INTO x_pk1_value
              FROM ap_invoices_all aia
                 , ap_suppliers asa
                 , ap_supplier_sites_all assa
             WHERE asa.vendor_id                = assa.vendor_id
               AND aia.vendor_id                = asa.vendor_id
               AND aia.vendor_site_id           = assa.vendor_site_id
               AND upper(trim(asa.vendor_name)) = upper(trim(p_vendor_name)) 
               AND asa.segment1                 = p_vendor_number
               AND assa.vendor_site_code        = p_vendor_site_code
               AND aia.invoice_num              = p_invoice_number;

   EXCEPTION
      WHEN no_data_found THEN
         x_retcode   := 1;
         x_err_msg   := 'AP_INVOICE.INVOICE_ID: No Data Found for pk1_value of invoice number : ' || p_invoice_number || ' and vendor_site_code: '||p_vendor_site_code ;
      WHEN too_many_rows THEN
         x_retcode   := 1;
         x_err_msg   := 'AP_INVOICE.INVOICE_ID: Multiple records with same pk1_value of invoice number : ' || p_invoice_number || ' and vendor_site_code: '||p_vendor_site_code ;
      WHEN OTHERS THEN
         x_retcode   := 1;
         x_err_msg   := 'AP_INVOICE.INVOICE_ID: Unexpected error: ' || sqlerrm;

   END validate_ap_invoices_pk;
 

--/*****************************************************************************************************************
-- * Procedure  : validate_ar_inv_pk                                                                               *
-- * Purpose   : This Procedure will validate ar_invoice pk1_value                                                 *
-- *****************************************************************************************************************/	

   PROCEDURE validate_ar_inv_pk( p_trx_number IN    VARCHAR2                              
                               , x_pk1_value  OUT   VARCHAR2
                               , x_retcode    OUT   NUMBER
                               , x_err_msg    OUT   VARCHAR2
   )
   IS
   BEGIN
      x_retcode   := 0;
      x_err_msg   := NULL;
                                      
            SELECT customer_trx_id
              INTO x_pk1_value
              FROM ra_customer_trx_all
             WHERE trx_number = p_trx_number;

   EXCEPTION
      WHEN no_data_found THEN
         x_retcode   := 1;
         x_err_msg   := 'AR_INVOICE.INVOICE_ID: No Data Found for pk1_value for AR Invoice : ' || p_trx_number;
      WHEN too_many_rows THEN
         x_retcode   := 1;
         x_err_msg   := 'AR_INVOICE.INVOICE_ID: Multiple records with same pk1_value for AR Invoice : ' || p_trx_number;
      WHEN OTHERS THEN
         x_retcode   := 1;
         x_err_msg   := 'AR_INVOICE.INVOICE: Unexpected error: ' || sqlerrm;

   END validate_ar_inv_pk;

--/*****************************************************************************************************************
-- * Procedure  : validate_ar_customers_pk                                                                         *
-- * Purpose   : This Procedure will validate ar_invoice pk1_value                                                 *
-- *****************************************************************************************************************/

   PROCEDURE validate_ar_customers_pk( p_customer_number IN    VARCHAR2
                                     , x_pk1_value       OUT   VARCHAR2
                                     , x_retcode         OUT   NUMBER
                                     , x_err_msg         OUT   VARCHAR2
   )  
   IS
   BEGIN
      x_retcode   := 0;
      x_err_msg   := NULL;
  
            SELECT customer_id
              INTO x_pk1_value
              FROM ar_customers ac
             WHERE customer_number = p_customer_number;

   EXCEPTION
      WHEN no_data_found THEN
         x_retcode   := 1;
         x_err_msg   := 'CUSTOMER_ID: No Data Found for pk1_value for CUSTOMER NUMBER: ' || p_customer_number;
      WHEN too_many_rows THEN
         x_retcode   := 1;
         x_err_msg   := 'CUSTOMER_ID: Multiple records with same pk1_value for  CUSTOMER NUMBER: ' || p_customer_number;
      WHEN OTHERS THEN
         x_retcode   := 1;
         x_err_msg   := 'CUSTOMER_ID: Unexpected error: ' || sqlerrm;
   END validate_ar_customers_pk;

   
--/****************************************************************************************************************
-- * Procedure  : supplier_load_staging_data                                                                      *
-- * Purpose    : This Procedure is used to load supplier attachment data into staging Table                      *
-- ****************************************************************************************************************/

   PROCEDURE supplier_load_staging_data ( x_retcode        OUT   NUMBER
                                        , x_err_msg        OUT   VARCHAR2 )
    IS

 -- This Cursor is used to retrieve information about Short Text Attachments. --

      CURSOR lcu_short 
  IS
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
           , fdc.user_name     category_name
           , fdt.title         title
        FROM fnd_attached_documents@xxaqv_conv_cmn_dblink     fad
           , ap_suppliers@xxaqv_conv_cmn_dblink               aps
           , fnd_document_categories_tl@xxaqv_conv_cmn_dblink fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink           fdt
           , fnd_documents@xxaqv_conv_cmn_dblink              fd
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink     fdd
           , fnd_documents_short_text@xxaqv_conv_cmn_dblink   fdst
       WHERE fdst.media_id   = fd.media_id
         AND fad.document_id = fd.document_id
         AND fdd.datatype_id = fd.datatype_id
         AND fd.category_id  = fdc.category_id
         AND fdt.document_id = fd.document_id
         AND fdd.name        = 'SHORT_TEXT'                     
		 AND fad.pk1_value   between nvl(gv_legacy_id_from,fad.pk1_value) and nvl(gv_legacy_id_to,fad.pk1_value)
         AND aps.vendor_id   = fad.pk1_value
         AND fad.entity_name = 'PO_VENDORS'                    -- entity name
         AND EXISTS ( SELECT 1
                        FROM ap_suppliers apt
                       WHERE apt.segment1    = aps.segment1
                         AND apt.vendor_name = aps.vendor_name    );


  -- This Cursor is used to retrieve information about Long Text Attachments ---

      CURSOR lcu_long IS
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
           , fdc.user_name     category_name
           , fdt.title         title
        FROM fnd_attached_documents@xxaqv_conv_cmn_dblink      fad
           , ap_suppliers@xxaqv_conv_cmn_dblink                aps
           , fnd_document_categories_tl@xxaqv_conv_cmn_dblink  fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink            fdt
           , fnd_documents@xxaqv_conv_cmn_dblink               fd
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink      fdd
           , fnd_documents_long_text@xxaqv_conv_cmn_dblink     fdlt
       WHERE fdlt.media_id   = fd.media_id
         AND fad.document_id = fd.document_id
         AND fdd.datatype_id = fd.datatype_id
         AND fd.category_id  = fdc.category_id
         AND fdt.document_id = fd.document_id
         AND fdd.name        = 'LONG_TEXT'                        
		 AND fad.pk1_value   between nvl(gv_legacy_id_from,fad.pk1_value) and nvl(gv_legacy_id_to,fad.pk1_value)
         AND aps.vendor_id   = fad.pk1_value
         AND fad.entity_name = 'PO_VENDORS'                       -- entity name
         AND EXISTS ( SELECT 1
                        FROM ap_suppliers apt
                       WHERE apt.segment1    = aps.segment1
                         AND apt.vendor_name = aps.vendor_name    );

 -- This Cursor is used to retrieve information about Web URL Attachments.--

      CURSOR lcu_url 
      IS
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
           , fdc.user_name     category_name
           , fdt.title         title
        FROM fnd_documents@xxaqv_conv_cmn_dblink                fd
           , ap_suppliers@xxaqv_conv_cmn_dblink                 aps
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink       fdd
           , fnd_attached_documents@xxaqv_conv_cmn_dblink       fad
           , fnd_document_categories_tl@xxaqv_conv_cmn_dblink   fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink             fdt
       WHERE fdd.datatype_id = fd.datatype_id
         AND aps.vendor_id   = fad.pk1_value
         AND fad.document_id = fd.document_id
         AND fd.category_id  = fdc.category_id
         AND fdt.document_id = fd.document_id
         AND fdd.name        = 'WEB_PAGE'
         AND fad.entity_name = 'PO_VENDORS'                        -- entity name
		 AND fad.pk1_value   between nvl(gv_legacy_id_from,fad.pk1_value) and nvl(gv_legacy_id_to,fad.pk1_value)
               AND EXISTS ( SELECT 1
                              FROM ap_suppliers apt
                             WHERE apt.segment1    = aps.segment1
                               AND apt.vendor_name = aps.vendor_name    );

 -- This Cursor is used to retrieve information about File Attachments. --

      CURSOR lcu_file 
      IS
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
		   , fl.program_tag         program_tag
           , fdc.user_name          category_name
           , fdt.description        document_description
           , fad.pk2_value          pk2_value
           , fad.pk3_value          pk3_value
           , fad.pk4_value          pk4_value
           , fad.pk5_value          pk5_value
        FROM fnd_lobs@xxaqv_conv_cmn_dblink                     fl
           , fnd_documents@xxaqv_conv_cmn_dblink                fd
           , fnd_attached_documents@xxaqv_conv_cmn_dblink       fad
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink       fdd
           , ap_suppliers@xxaqv_conv_cmn_dblink                 aps
           , fnd_document_categories_tl@xxaqv_conv_cmn_dblink   fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink             fdt
       WHERE fl.file_id      = fd.media_id
         AND aps.vendor_id   = fad.pk1_value
         AND fad.entity_name = 'PO_VENDORS'                        -- entity name
         AND fdd.name        = 'FILE'
         AND fad.document_id = fd.document_id
         AND fd.datatype_id  = fdd.datatype_id
         AND fd.category_id  = fdc.category_id
         AND fdt.document_id = fd.document_id
		 AND fad.pk1_value   between nvl(gv_legacy_id_from,fad.pk1_value) and nvl(gv_legacy_id_to,fad.pk1_value)
         AND EXISTS ( SELECT 1
                        FROM ap_suppliers apt
                       WHERE apt.segment1 = aps.segment1
                         AND apt.vendor_name = aps.vendor_name    );


          CURSOR lcu_file_data 
          IS
          SELECT x_file_id
		        , seq_num
            FROM xxaqv_attach_docs_stg
           WHERE datatype_name = 'FILE'
             AND entity_name   = 'PO_VENDORS'
             AND x_pk1_value between nvl(gv_legacy_id_from,x_pk1_value) and nvl(gv_legacy_id_to,x_pk1_value);

     -- LOCAL VARIABLES
      ln_line_count    BINARY_INTEGER := 1;
      ln_error_count   BINARY_INTEGER := 0;
      ex_dml_errors    EXCEPTION;
	  ln_cmt_count     NUMBER   :=0;
      PRAGMA exception_init ( ex_dml_errors, -24381 );

  --INSERTING INTO STAGING TABLE
   BEGIN

     --LOGS

      print_debug('EXTRACT_DATA: START Load data into staging table and mark them LS');
      print_debug('EXTRACT_DATA: pk1_value_from: ' || gv_legacy_id_from);
	  print_debug('EXTRACT_DATA: pk1_value_to: ' || gv_legacy_id_to);
      --
      x_retcode   := 0;
      x_err_msg   := NULL;
      --

    gt_xxaqv_attach_docs_tab.delete;

    FOR i IN lcu_short
    LOOP

     gt_xxaqv_attach_docs_tab(ln_line_count).x_pk1_value          := i.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name          := i.entity_name;  
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num              := i.sequence_num; 
     gt_xxaqv_attach_docs_tab(ln_line_count).title                := i.title;
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name        := i.category_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name        := i.datatype_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description := i.document_description;
     gt_xxaqv_attach_docs_tab(ln_line_count).text                 := i.text;
     gt_xxaqv_attach_docs_tab(ln_line_count).url                  := i.url; 
     gt_xxaqv_attach_docs_tab(ln_line_count).file_name            := i.file_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date        := SYSDATE;
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date     := SYSDATE;
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login    := gn_login_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by      := gn_user_id; 
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by           := gn_user_id; 
     gt_xxaqv_attach_docs_tab(ln_line_count).process_flag         := gv_load_success;
     gt_xxaqv_attach_docs_tab(ln_line_count).request_id           := gn_request_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value            := i.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value            := i.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value            := i.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value            := i.pk5_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_name          := i.vendor_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_number        := i.vendor_number;
     ln_line_count                                                := ln_line_count + 1;

     END LOOP;
     BEGIN
          FORALL i IN gt_xxaqv_attach_docs_tab.FIRST..gt_xxaqv_attach_docs_tab.LAST SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( i );

            print_debug(gv_module
                        ||':'
                        ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:Short Text Records loaded sucessfully: ' 
                        || SQL%rowcount);         
        COMMIT;

         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
              print_debug(gv_module
                         ||':'
                         ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG: Number of failures for Short Text : ' 
                         || ln_error_count,gn_log_level); 
               FOR i IN 1..ln_error_count 
               LOOP 
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:Short Text Error: ' 
                           || i 
                           || 'Array Index: '
                           || SQL%bulk_exceptions(i).error_index 
                           || 'Message: ' 
                           || sqlerrm(-SQL%bulk_exceptions(i).error_code),gn_log_level);
               END LOOP;

            WHEN OTHERS 
            THEN
               print_debug(gv_module||':'
                          ||'EXTRACT_DATA:Short Text Unexpected Error: ' 
                          || sqlerrm, gn_log_level );
               x_retcode   := 1;
               x_err_msg   := gv_module
                              ||':'||'EXTRACT_DATA:Short Text Unexpected Error:' 
                              || to_char(sqlcode) 
                              || '-' 
                              || sqlerrm;
         END;


     gt_xxaqv_attach_docs_tab.delete;

    FOR j IN lcu_long
    LOOP
  
     gt_xxaqv_attach_docs_tab(ln_line_count).x_pk1_value          := j.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name          := j.entity_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num              := j.sequence_num;
     gt_xxaqv_attach_docs_tab(ln_line_count).title                := j.title; 
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name        := j.category_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name        := j.datatype_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description := j.document_description;
     gt_xxaqv_attach_docs_tab(ln_line_count).text                 := j.text;     
     gt_xxaqv_attach_docs_tab(ln_line_count).url                  := j.url;      
     gt_xxaqv_attach_docs_tab(ln_line_count).file_name            := j.file_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date        := SYSDATE;
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date     := SYSDATE;
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login    := gn_login_id; 
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by      := gn_user_id;  
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by           := gn_user_id;  
     gt_xxaqv_attach_docs_tab(ln_line_count).process_flag         := gv_load_success;
     gt_xxaqv_attach_docs_tab(ln_line_count).request_id           := gn_request_id;	 
     gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value            := j.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value            := j.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value            := j.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value            := j.pk5_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_name          := j.vendor_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_number        := j.vendor_number;
     ln_line_count                                                := ln_line_count + 1;
     
     END LOOP;
     BEGIN

          FORALL j IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( j );

            print_debug(gv_module
                       ||':'
                       ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:Long Text Records loaded sucessfully: ' 
                       || SQL%rowcount);         
             COMMIT;

         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
              print_debug(gv_module
                         ||':'
                         ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:Long Text Number of failures: ' 
                         || ln_error_count,gn_log_level); 
               FOR i IN 1..ln_error_count 
               LOOP 
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:Long Text Error: ' 
                           || i 
                           || 'Array Index: '
                           || SQL%bulk_exceptions(i).error_index 
                           || 'Message: ' 
                           || sqlerrm(-SQL%bulk_exceptions(i).error_code),gn_log_level);
               END LOOP;
            
            WHEN OTHERS 
            THEN
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA:Long Text Unexpected Error: ' 
                           || sqlerrm, gn_log_level );
               x_retcode   := 1;
               x_err_msg   := gv_module
                              ||':'
                              ||'EXTRACT_DATA:Long Text Unexpected Error:' 
                              || to_char(sqlcode) 
                              || '-' 
                              || sqlerrm;
         END;


    gt_xxaqv_attach_docs_tab.delete;

    FOR z IN lcu_url
    LOOP
    
     gt_xxaqv_attach_docs_tab(ln_line_count).x_pk1_value          := z.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name          := z.entity_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num              := z.sequence_num;
     gt_xxaqv_attach_docs_tab(ln_line_count).title                := z.title;    
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name        := z.category_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name        := z.datatype_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description := z.document_description;
     gt_xxaqv_attach_docs_tab(ln_line_count).text                 := z.text; 
     gt_xxaqv_attach_docs_tab(ln_line_count).url                  := z.url; 
     gt_xxaqv_attach_docs_tab(ln_line_count).file_name            := z.file_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date        := SYSDATE;
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date     := SYSDATE;
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login    := gn_login_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by      := gn_user_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by           := gn_user_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).process_flag         := gv_load_success;
     gt_xxaqv_attach_docs_tab(ln_line_count).request_id           := gn_request_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value            := z.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value            := z.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value            := z.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value            := z.pk5_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_name          := z.vendor_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_number        := z.vendor_number;
     ln_line_count                                                := ln_line_count + 1;
     
     END LOOP;
     BEGIN
          FORALL z IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( z );

            print_debug(gv_module
                        ||':'
                        ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:URL Records loaded sucessfully: ' 
                        || SQL%rowcount);         
             COMMIT;

         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
              print_debug(gv_module
                         ||':'
                         ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG: Number of failures for URL : ' 
                         || ln_error_count,gn_log_level); 
                FOR i IN 1..ln_error_count 
               LOOP 
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:URL Error: ' 
                           || i 
                           || 'Array Index: '
                           || SQL%bulk_exceptions(i).error_index 
                           || 'Message: ' 
                           || sqlerrm(-SQL%bulk_exceptions(i).error_code),gn_log_level);
                END LOOP;
            
             WHEN OTHERS 
            THEN
                print_debug(gv_module
                          ||':'
                          ||'EXTRACT_DATA:URL Unexpected Error: ' 
                          || sqlerrm, gn_log_level );
                x_retcode   := 1;
                x_err_msg   := gv_module
                              ||':'
                              ||'EXTRACT_DATA:URL Unexpected Error:' 
                              || to_char(sqlcode) 
                              || '-' 
                              || sqlerrm;
         END;

    gt_xxaqv_attach_docs_tab.delete;

    FOR m IN lcu_file 
    LOOP
    
     gt_xxaqv_attach_docs_tab(ln_line_count).x_pk1_value          := m.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name          := m.entity_name;             
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num              := m.sequence_num;                 
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name        := m.category_name;               
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name        := m.datatype_name;           
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description := m.document_description;    
     gt_xxaqv_attach_docs_tab(ln_line_count).x_file_id            := m.file_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).upload_date          := m.upload_date;
     gt_xxaqv_attach_docs_tab(ln_line_count).file_name            := m.file_name;              
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date        := SYSDATE;        
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date     := SYSDATE;       
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login    := gn_login_id;      
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by      := gn_user_id;       
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by           := gn_user_id;            
     gt_xxaqv_attach_docs_tab(ln_line_count).process_flag         := gv_load_success;
     gt_xxaqv_attach_docs_tab(ln_line_count).request_id           := gn_request_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value            := m.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value            := m.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value            := m.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value            := m.pk5_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).file_content_type    := m.file_content_type;
     gt_xxaqv_attach_docs_tab(ln_line_count).expiration_date      := m.expiration_date;
     gt_xxaqv_attach_docs_tab(ln_line_count).program_name         := m.program_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).language             := m.language;
     gt_xxaqv_attach_docs_tab(ln_line_count).oracle_charset       := m.oracle_charset;
     gt_xxaqv_attach_docs_tab(ln_line_count).file_format          := m.file_format;
	 gt_xxaqv_attach_docs_tab(ln_line_count).program_tag          := m.program_tag;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_name          := m.vendor_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_number        := m.vendor_number;
     ln_line_count                                                := ln_line_count + 1;
     
     END LOOP;
     BEGIN
          FORALL m IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( m );
           
            print_debug(gv_module
                        ||':'
                        ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:FILE Records loaded sucessfully: ' 
                        || SQL%rowcount);  
            COMMIT;
        
          --inserting lob data
          BEGIN
        
           FOR r_cur_file_data IN lcu_file_data
           LOOP
              ln_cmt_count := ln_cmt_count + 1;
              UPDATE xxaqv_attach_docs_stg xads
                 SET xads.file_data = ( SELECT file_data
                                          FROM fnd_lobs@xxaqv_conv_cmn_dblink fl
                                         WHERE r_cur_file_data.x_file_id = fl.file_id       )
               WHERE xads.x_file_id     = r_cur_file_data.x_file_id 
			     AND xads.seq_num       = r_cur_file_data.seq_num
                 AND xads.datatype_name = 'FILE'
                 AND xads.entity_name   = 'PO_VENDORS'; 
                 
				 IF ln_cmt_count = gn_commit_cnt
				 THEN
				 COMMIT;
				 ln_cmt_count := 0;
				 END IF;
          END LOOP;
        COMMIT;
         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
              print_debug(gv_module
                         ||':'
                         ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:File Number of failures for FILE DATA: ' 
                         || ln_error_count,gn_log_level); 
               FOR i IN 1..ln_error_count 
               LOOP 
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:FILE DATA Error: ' 
                           || i 
                           || 'Array Index: '
                           || SQL%bulk_exceptions(i).error_index 
                           || 'Message: ' 
                           || sqlerrm(-SQL%bulk_exceptions(i).error_code),gn_log_level);
               END LOOP;
        
            WHEN OTHERS 
            THEN
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA:FILE DATA Unexpected Error: ' 
                           || sqlerrm, gn_log_level );
               x_retcode   := 1;
               x_err_msg   := gv_module
                           ||':'
                           ||'EXTRACT_DATA:FILE DATA Unexpected Error:' 
                           || to_char(sqlcode) 
                           || '-' 
                           || sqlerrm;
         END;

         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:File Number of failures: ' 
                           || ln_error_count,gn_log_level); 
               FOR i IN 1..ln_error_count 
               LOOP 
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:File Error: ' 
                           || i 
                           || 'Array Index: '
                           || SQL%bulk_exceptions(i).error_index 
                           || 'Message: ' 
                           || sqlerrm(-SQL%bulk_exceptions(i).error_code),gn_log_level);
               END LOOP;
            
            WHEN OTHERS 
            THEN
               print_debug('EXTRACT_DATA:File Unexpected Error: ' || sqlerrm, gn_log_level );
               x_retcode   := 1;
               x_err_msg   := gv_module
                           ||':'
                           ||'EXTRACT_DATA:File Unexpected Error:' 
                           || to_char(sqlcode) 
                           || '-' 
                           || sqlerrm;
         END;


    EXCEPTION
      WHEN OTHERS 
      THEN
         print_debug(gv_module
                    ||':'
                    ||'EXTRACT_DATA: Unexpected error:' 
                    || sqlerrm  ,gn_log_level  );
         x_retcode   := 1;
         x_err_msg   := gv_module
                       ||':'
                       ||'EXTRACT_DATA: Unexpected error:' 
                       || to_char(sqlcode) 
                       || '-' 
                       || sqlerrm;
   
   END supplier_load_staging_data;


--/****************************************************************************************************************
-- * Procedure  : sup_sites_load_staging                                                                          *
-- * Purpose    : This Procedure is used to load the supplier site attachment data into staging Table             *
-- ****************************************************************************************************************/

   PROCEDURE sup_sites_load_staging ( x_retcode        OUT   NUMBER
                                    , x_err_msg        OUT   VARCHAR2)
    IS

 -- This Cursor is used to retrieve information about Short Text Attachments. --

      CURSOR lcu_short 
      IS
      SELECT fad.seq_num             sequence_num
           , aps.segment1            vendor_number
           , assa.vendor_site_code   vendor_site_code
           , fad.entity_name         entity_name
           , fdt.description         document_description
           ,  regexp_replace(fdst.short_text
             , '[^[!-~]]*'
             , ' '
                  )	                 text
           , NULL                    file_name
           , NULL                    url
           , NULL                    function_name
           , fdd.name                datatype_name
           , fad.pk1_value           pk1_value
           , fad.pk2_value           pk2_value
           , fad.pk3_value           pk3_value
           , fad.pk4_value           pk4_value
           , fad.pk5_value           pk5_value
           , fdc.user_name           category_name
           , fdt.title               title
        FROM fnd_attached_documents@xxaqv_conv_cmn_dblink        fad
           , ap_supplier_sites_all@xxaqv_conv_cmn_dblink         assa
           , ap_suppliers@xxaqv_conv_cmn_dblink                  aps
           , fnd_document_categories_tl@xxaqv_conv_cmn_dblink    fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink              fdt
           , fnd_documents@xxaqv_conv_cmn_dblink                 fd
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink        fdd
           , fnd_documents_short_text@xxaqv_conv_cmn_dblink      fdst
       WHERE fdst.media_id         = fd.media_id
         AND assa.vendor_site_id   = fad.pk1_value
         AND aps.vendor_id         =  assa.vendor_id
         AND fad.document_id       = fd.document_id
         AND fdd.datatype_id       = fd.datatype_id
         AND fd.category_id        = fdc.category_id
         AND fdt.document_id       = fd.document_id
         AND fdd.name              = 'SHORT_TEXT'                     
		 AND fad.pk1_value   between nvl(gv_legacy_id_from,fad.pk1_value) and nvl(gv_legacy_id_to,fad.pk1_value)      
         AND fad.entity_name       = 'PO_VENDOR_SITES'                   -- entity name
         AND EXISTS (SELECT 1 
                       FROM ap_suppliers apt
                          , ap_supplier_sites_all asst
                      WHERE apt.vendor_id         = asst.vendor_id
                        AND apt.segment1          = aps.segment1
                        AND assa.vendor_site_code = asst.vendor_site_code  );



  -- This Cursor is used to retrieve information about Long Text Attachments ---

      CURSOR lcu_long 
      IS
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
           , fdc.user_name            category_name
           , fdt.title                title
        FROM fnd_attached_documents@xxaqv_conv_cmn_dblink      fad
           , ap_supplier_sites_all@xxaqv_conv_cmn_dblink       assa
           , ap_suppliers@xxaqv_conv_cmn_dblink                aps
           , fnd_document_categories_tl@xxaqv_conv_cmn_dblink  fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink            fdt
           , fnd_documents@xxaqv_conv_cmn_dblink               fd
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink      fdd
           , fnd_documents_long_text@xxaqv_conv_cmn_dblink     fdlt
       WHERE fdlt.media_id         = fd.media_id
         AND assa.vendor_site_id   = fad.pk1_value
         AND aps.vendor_id         =  assa.vendor_id
         AND fad.document_id       = fd.document_id
         AND fdd.datatype_id       = fd.datatype_id
         AND fd.category_id        = fdc.category_id
         AND fdt.document_id       = fd.document_id
         AND fdd.name              = 'LONG_TEXT'                        
		 AND fad.pk1_value   between nvl(gv_legacy_id_from,fad.pk1_value) and nvl(gv_legacy_id_to,fad.pk1_value)
         AND fad.entity_name       = 'PO_VENDOR_SITES'                     -- entity name
         AND EXISTS (SELECT 1 
                       FROM ap_suppliers apt
                          , ap_supplier_sites_all asst
                      WHERE apt.vendor_id         = asst.vendor_id
                        AND apt.segment1          = aps.segment1
                        AND assa.vendor_site_code = asst.vendor_site_code   );

 -- This Cursor is used to retrieve information about Web URL Attachments.--

      CURSOR lcu_url 
      IS
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
           , fdc.user_name            category_name
           , fdt.title                title
        FROM fnd_documents@xxaqv_conv_cmn_dblink                fd
           , ap_suppliers@xxaqv_conv_cmn_dblink                 aps
           , ap_supplier_sites_all@xxaqv_conv_cmn_dblink        assa
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink       fdd
           , fnd_attached_documents@xxaqv_conv_cmn_dblink       fad
           , fnd_document_categories_tl@xxaqv_conv_cmn_dblink   fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink             fdt
       WHERE fdd.datatype_id     = fd.datatype_id
         AND assa.vendor_site_id = fad.pk1_value
         AND aps.vendor_id       =  assa.vendor_id
         AND fad.document_id     = fd.document_id
         AND fd.category_id      = fdc.category_id
         AND fdt.document_id     = fd.document_id
         AND fdd.name            = 'WEB_PAGE'
         AND fad.entity_name     = 'PO_VENDOR_SITES'                 -- entity name
		 AND fad.pk1_value   between nvl(gv_legacy_id_from,fad.pk1_value) and nvl(gv_legacy_id_to,fad.pk1_value)
         AND EXISTS (SELECT 1 
                       FROM ap_suppliers apt
                          , ap_supplier_sites_all asst
                      WHERE apt.vendor_id         = asst.vendor_id
                        AND apt.segment1          = aps.segment1
                        AND assa.vendor_site_code = asst.vendor_site_code );

 -- This Cursor is used to retrieve information about File Attachments. --

     CURSOR lcu_file 
     IS
     SELECT fad.pk1_value          pk1_value
          , fad.entity_name        entity_name
          , fl.file_id             file_id
          , fl.file_name           file_name
          , fad.seq_num            sequence_num
          , aps.segment1           vendor_number
          , assa.vendor_site_code  vendor_site_code
          , fdd.name               datatype_name
          , fad.pk2_value          pk2_value
          , fad.pk3_value          pk3_value
          , fad.pk4_value          pk4_value
          , fad.pk5_value          pk5_value
          , fl.upload_date         upload_date
          , fl.file_content_type   file_content_type
          , fl.expiration_date     expiration_date
          , fl.program_name        program_name
          , fl.language            language
          , fl.oracle_charset      oracle_charset
          , fl.file_format         file_format
		  , fl.program_tag         program_tag
          , fdc.user_name          category_name
          , fdt.description        document_description
       FROM fnd_lobs@xxaqv_conv_cmn_dblink                  fl
          , fnd_documents@xxaqv_conv_cmn_dblink             fd
          , fnd_attached_documents@xxaqv_conv_cmn_dblink    fad
          , fnd_document_datatypes@xxaqv_conv_cmn_dblink    fdd
          , ap_suppliers@xxaqv_conv_cmn_dblink              aps
          , ap_supplier_sites_all@xxaqv_conv_cmn_dblink     assa
          , fnd_document_categories_tl@xxaqv_conv_cmn_dblink   fdc
          , fnd_documents_tl@xxaqv_conv_cmn_dblink          fdt
      WHERE fl.file_id      = fd.media_id
        AND fd.document_id  = fad.document_id
        AND fad.pk1_value   = assa.vendor_site_id
        AND fd.datatype_id  = fdd.datatype_id
        AND aps.vendor_id   =  assa.vendor_id
        AND fd.category_id     = fdc.category_id
        AND fdt.document_id = fd.document_id
        AND fdd.name        = 'FILE'                        
		AND fad.pk1_value   between nvl(gv_legacy_id_from,fad.pk1_value) and nvl(gv_legacy_id_to,fad.pk1_value)
        AND fad.entity_name = 'PO_VENDOR_SITES'                     -- entity name
        AND EXISTS (SELECT 1 
                      FROM ap_suppliers apt
                         , ap_supplier_sites_all asst
                     WHERE apt.vendor_id         = asst.vendor_id
                       AND apt.segment1          = aps.segment1
                       AND assa.vendor_site_code = asst.vendor_site_code   ); 

          CURSOR lcu_file_data 
          IS
          SELECT x_file_id
		       , seq_num
            FROM xxaqv_attach_docs_stg
           WHERE datatype_name = 'FILE'
             AND entity_name   = 'PO_VENDOR_SITES'
             AND x_pk1_value     between nvl(gv_legacy_id_from,x_pk1_value) and nvl(gv_legacy_id_to,x_pk1_value);
             
             
     -- LOCAL VARIABLES
      ln_line_count    BINARY_INTEGER := 1;
      ln_error_count   BINARY_INTEGER := 0;
	  ln_cmt_count     NUMBER :=0;
      ex_dml_errors    EXCEPTION;
      PRAGMA exception_init ( ex_dml_errors, -24381 );

      --INSERTING INTO STAGING TABLE
   BEGIN
      print_debug('EXTRACT_DATA: START Load data into staging table and mark them LS');
      print_debug('EXTRACT_DATA: pk1_value_from: ' || gv_legacy_id_from);
      print_debug('EXTRACT_DATA: pk1_value_to: ' || gv_legacy_id_to);
          --
      x_retcode   := 0;
      x_err_msg   := NULL;   
      --
    gt_xxaqv_attach_docs_tab.delete;

    FOR i IN lcu_short 
    LOOP

     gt_xxaqv_attach_docs_tab(ln_line_count).x_pk1_value          := i.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name          := i.entity_name;             
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num              := i.sequence_num;                
     gt_xxaqv_attach_docs_tab(ln_line_count).title                := i.title;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name        := i.category_name;               
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name        := i.datatype_name;           
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description := i.document_description;    
     gt_xxaqv_attach_docs_tab(ln_line_count).text                 := i.text;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).url                  := i.url;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).file_name            := i.file_name;              
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date        := SYSDATE;        
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date     := SYSDATE;       
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login    := gn_login_id;      
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by      := gn_user_id;       
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by           := gn_user_id;            
     gt_xxaqv_attach_docs_tab(ln_line_count).process_flag         := gv_load_success;
	 gt_xxaqv_attach_docs_tab(ln_line_count).request_id           := gn_request_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value            := i.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value            := i.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value            := i.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value            := i.pk5_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_site_code     := i.vendor_site_code;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_number        := i.vendor_number;
     ln_line_count                                                := ln_line_count + 1;
     END LOOP;

     BEGIN
            FORALL i IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( i );

            print_debug(gv_module
			            ||':'
						||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:Short Text Records loaded sucessfully: ' 
						|| SQL%rowcount);         
		 COMMIT;

         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
              print_debug(gv_module
			             ||':'
						 ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG: Number of failures for Short Text : ' 
						 || ln_error_count,gn_log_level); 
               FOR i IN 1..ln_error_count 
			   LOOP 
			   print_debug(gv_module
			               ||':'
						   ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:Short Text Error: ' 
			               || i 
			               || 'Array Index: '
			               || SQL%bulk_exceptions(i).error_index 
			               || 'Message: ' 
			               || sqlerrm(-SQL%bulk_exceptions(i).error_code),gn_log_level);
               END LOOP;

            WHEN OTHERS 
			THEN
               print_debug(gv_module||':'
			              ||'EXTRACT_DATA:Short Text Unexpected Error: ' 
			              || sqlerrm, gn_log_level );
               x_retcode   := 1;
               x_err_msg   := gv_module
			                  ||':'||'EXTRACT_DATA:Short Text Unexpected Error:' 
			                  || to_char(sqlcode) 
			                  || '-' 
			                  || sqlerrm;
         END;

     gt_xxaqv_attach_docs_tab.delete;

    FOR j IN lcu_long 
    LOOP

     gt_xxaqv_attach_docs_tab(ln_line_count).x_pk1_value          := j.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name          := j.entity_name;             
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num              := j.sequence_num;                
     gt_xxaqv_attach_docs_tab(ln_line_count).title                := j.title;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name        := j.category_name;               
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name        := j.datatype_name;           
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description := j.document_description;    
     gt_xxaqv_attach_docs_tab(ln_line_count).text                 := j.text;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).url                  := j.url;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).file_name            := j.file_name;              
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date        := SYSDATE;        
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date     := SYSDATE;       
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login    := gn_login_id;      
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by      := gn_user_id;       
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by           := gn_user_id;            
     gt_xxaqv_attach_docs_tab(ln_line_count).process_flag         := gv_load_success;
     gt_xxaqv_attach_docs_tab(ln_line_count).request_id           := gn_request_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value            := j.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value            := j.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value            := j.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value            := j.pk5_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_site_code     := j.vendor_site_code;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_number        := j.vendor_number;
     ln_line_count                                                := ln_line_count + 1;
     END LOOP;
     BEGIN
          FORALL j IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( j );


            print_debug(gv_module
                        ||':'
                        ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:Long Text Records loaded sucessfully: ' 
                        || SQL%rowcount);         
		 COMMIT;

         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
              print_debug(gv_module
                         ||':'
                         ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:Long Text Number of failures: ' 
                         || ln_error_count,gn_log_level); 
               FOR i IN 1..ln_error_count 
               LOOP 
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:Long Text Error: ' 
                           || i 
                           || 'Array Index: '
                           || SQL%bulk_exceptions(i).error_index 
                           || 'Message: ' 
                           || sqlerrm(-SQL%bulk_exceptions(i).error_code),gn_log_level);
               END LOOP;
            
            WHEN OTHERS 
            THEN
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA:Long Text Unexpected Error: ' 
                           || sqlerrm, gn_log_level );
               x_retcode   := 1;
               x_err_msg   := gv_module
                              ||':'
                              ||'EXTRACT_DATA:Long Text Unexpected Error:' 
                              || to_char(sqlcode) 
                              || '-' 
                              || sqlerrm;
         END;

    gt_xxaqv_attach_docs_tab.delete;

    FOR k IN lcu_url 
    LOOP

     gt_xxaqv_attach_docs_tab(ln_line_count).x_pk1_value          := k.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name          := k.entity_name;             
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num              := k.sequence_num;                
     gt_xxaqv_attach_docs_tab(ln_line_count).title                := k.title;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name        := k.category_name;               
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name        := k.datatype_name;           
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description := k.document_description;    
     gt_xxaqv_attach_docs_tab(ln_line_count).text                 := k.text;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).url                  := k.url;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).file_name            := k.file_name;              
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date        := SYSDATE;        
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date     := SYSDATE;       
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login    := gn_login_id;      
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by      := gn_user_id;       
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by           := gn_user_id;            
     gt_xxaqv_attach_docs_tab(ln_line_count).process_flag         := gv_load_success;
     gt_xxaqv_attach_docs_tab(ln_line_count).request_id           := gn_request_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value            := k.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value            := k.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value            := k.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value            := k.pk5_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_site_code     := k.vendor_site_code;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_number        := k.vendor_number;
     ln_line_count                                                := ln_line_count + 1;

     END LOOP;
     BEGIN
          FORALL k IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( k );

            print_debug(gv_module
                        ||':'
                        ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:URL Records loaded sucessfully: ' 
                        || SQL%rowcount);         
         COMMIT;

         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
              print_debug(gv_module
                         ||':'
                         ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG: Number of failures for URL : ' 
                         || ln_error_count,gn_log_level); 
               FOR i IN 1..ln_error_count 
               LOOP 
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:URL Error: ' 
                           || i 
                           || 'Array Index: '
                           || SQL%bulk_exceptions(i).error_index 
                           || 'Message: ' 
                           || sqlerrm(-SQL%bulk_exceptions(i).error_code),gn_log_level);
               END LOOP;
            
            WHEN OTHERS 
            THEN
               print_debug(gv_module
                          ||':'
                          ||'EXTRACT_DATA:URL Unexpected Error: ' 
                          || sqlerrm, gn_log_level );
               x_retcode   := 1;
               x_err_msg   := gv_module
                              ||':'
                              ||'EXTRACT_DATA:URL Unexpected Error:' 
                              || to_char(sqlcode) 
                              || '-' 
                              || sqlerrm;
         END;

    gt_xxaqv_attach_docs_tab.delete;

    FOR m IN lcu_file 
    LOOP

    gt_xxaqv_attach_docs_tab(ln_line_count).x_pk1_value          := m.pk1_value;
    gt_xxaqv_attach_docs_tab(ln_line_count).entity_name          := m.entity_name;
    gt_xxaqv_attach_docs_tab(ln_line_count).seq_num              := m.sequence_num;
    gt_xxaqv_attach_docs_tab(ln_line_count).category_name        := m.category_name;
    gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name        := m.datatype_name;
    gt_xxaqv_attach_docs_tab(ln_line_count).document_description := m.document_description;
    gt_xxaqv_attach_docs_tab(ln_line_count).x_file_id            := m.file_id;
    gt_xxaqv_attach_docs_tab(ln_line_count).upload_date          := m.upload_date;
    gt_xxaqv_attach_docs_tab(ln_line_count).file_name            := m.file_name;
    gt_xxaqv_attach_docs_tab(ln_line_count).creation_date        := SYSDATE;
    gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date     := SYSDATE;
    gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login    := gn_login_id;
    gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by      := gn_user_id;
    gt_xxaqv_attach_docs_tab(ln_line_count).created_by           := gn_user_id;
    gt_xxaqv_attach_docs_tab(ln_line_count).process_flag         := gv_load_success;
    gt_xxaqv_attach_docs_tab(ln_line_count).request_id           := gn_request_id;
    gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value            := m.pk2_value;
    gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value            := m.pk3_value;
    gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value            := m.pk4_value;
    gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value            := m.pk5_value;
    gt_xxaqv_attach_docs_tab(ln_line_count).file_content_type    := m.file_content_type;
    gt_xxaqv_attach_docs_tab(ln_line_count).expiration_date      := m.expiration_date;
    gt_xxaqv_attach_docs_tab(ln_line_count).program_name         := m.program_name;
    gt_xxaqv_attach_docs_tab(ln_line_count).language             := m.language;
    gt_xxaqv_attach_docs_tab(ln_line_count).oracle_charset       := m.oracle_charset;
    gt_xxaqv_attach_docs_tab(ln_line_count).file_format          := m.file_format;
	gt_xxaqv_attach_docs_tab(ln_line_count).program_tag          := m.program_tag;
    gt_xxaqv_attach_docs_tab(ln_line_count).vendor_number        := m.vendor_number;
    gt_xxaqv_attach_docs_tab(ln_line_count).vendor_site_code     := m.vendor_site_code;
    ln_line_count                                                := ln_line_count + 1;

     END LOOP;
     BEGIN
          FORALL m IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( m );

           print_debug(gv_module
                        ||':'
                        ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:FILE Records loaded sucessfully: ' 
                        || SQL%rowcount);  
        COMMIT;
          --inserting lob data
          BEGIN
        
           FOR r_cur_file_data IN lcu_file_data
           LOOP
               ln_cmt_count := ln_cmt_count + 1;
              UPDATE xxaqv_attach_docs_stg xads
			  
                 SET xads.file_data = ( SELECT file_data
                                          FROM fnd_lobs@xxaqv_conv_cmn_dblink fl
                                         WHERE r_cur_file_data.x_file_id = fl.file_id       )
               WHERE xads.x_file_id     = r_cur_file_data.x_file_id 
			     AND xads.seq_num       = r_cur_file_data.seq_num
                 AND xads.datatype_name = 'FILE'
                 AND xads.entity_name   = 'PO_VENDOR_SITES'; 
				 IF ln_cmt_count = gn_commit_cnt
				 THEN
				 COMMIT;
				 ln_cmt_count := 0;
				 END IF;
          END LOOP;
         COMMIT;

         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
              print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:File Number of failures for FILE DATA: ' 
                           || ln_error_count,gn_log_level); 
               FOR i IN 1..ln_error_count 
               LOOP 
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:FILE DATA Error: ' 
                           || i 
                           || 'Array Index: '
                           || SQL%bulk_exceptions(i).error_index 
                           || 'Message: ' 
                           || sqlerrm(-SQL%bulk_exceptions(i).error_code),gn_log_level);
               END LOOP;
            
            WHEN OTHERS 
            THEN
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA:FILE DATA Unexpected Error: ' 
                           || sqlerrm, gn_log_level );
               x_retcode   := 1;
               x_err_msg   := gv_module
                           ||':'
                           ||'EXTRACT_DATA:FILE DATA Unexpected Error:' 
                           || to_char(sqlcode) 
                           || '-' 
                           || sqlerrm;
         END;

         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:File Number of failures: ' 
                           || ln_error_count,gn_log_level); 
               FOR i IN 1..ln_error_count 
               LOOP 
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:File Error: ' 
                           || i 
                           || 'Array Index: '
                           || SQL%bulk_exceptions(i).error_index 
                           || 'Message: ' 
                           || sqlerrm(-SQL%bulk_exceptions(i).error_code),gn_log_level);
               END LOOP;

            WHEN OTHERS 
            THEN
               print_debug('EXTRACT_DATA:File Unexpected Error: ' || sqlerrm, gn_log_level );
               x_retcode   := 1;
               x_err_msg   := gv_module
                           ||':'
                           ||'EXTRACT_DATA:File Unexpected Error:' 
                           || to_char(sqlcode) 
                           || '-' 
                           || sqlerrm;
         END;

    EXCEPTION
      WHEN OTHERS 
      THEN
             print_debug(gv_module
                         ||':'
                         ||'EXTRACT_DATA: Unexpected error:' 
                         || sqlerrm  ,gn_log_level  );
         x_retcode   := 1;
         x_err_msg   := gv_module
                        ||':'
                        ||'EXTRACT_DATA: Unexpected error:' 
                        || to_char(sqlcode) 
                        || '-' 
                        || sqlerrm;
   END sup_sites_load_staging;

--/****************************************************************************************************************
-- * Procedure  : ap_invoice_load_staging_data                                                                    *
-- * Purpose    : This Procedure is used to load ap_invoice attachment data into staging Table                    *
-- ****************************************************************************************************************/

   PROCEDURE ap_invoice_load_staging_data ( x_retcode        OUT   NUMBER
                                          , x_err_msg        OUT   VARCHAR2 )
    IS

 -- This Cursor is used to retrieve information about Short Text Attachments. --

      CURSOR lcu_short 
      IS
          SELECT fad.seq_num       sequence_num
          , aias.invoice_num       invoice_number
           , aps.segment1          vendor_number
           , aps.vendor_name       vendor_name
           , assa.vendor_site_code vendor_site_code
           , fad.entity_name       entity_name
           , fdt.description       document_description
           , regexp_replace
            (fdst.short_text
             , '[^[!-~]]*'
             , ' '
                  )	               text
           , NULL                  file_name
           , NULL                  url
           , NULL                  function_name
           , fdd.name              datatype_name
           , fad.pk1_value         pk1_value
           , fad.pk2_value         pk2_value
           , fad.pk3_value         pk3_value
           , fad.pk4_value         pk4_value
           , fad.pk5_value         pk5_value
           , fdc.user_name              category_name
           , fdt.title             title
        FROM fnd_attached_documents@xxaqv_conv_cmn_dblink     fad
           , ap_invoices_all@xxaqv_conv_cmn_dblink            aias
           , ap_suppliers@xxaqv_conv_cmn_dblink               aps
           , ap_supplier_sites_all@xxaqv_conv_cmn_dblink      assa
           , fnd_document_categories_tl@xxaqv_conv_cmn_dblink fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink           fdt
           , fnd_documents@xxaqv_conv_cmn_dblink              fd
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink     fdd
           , fnd_documents_short_text@xxaqv_conv_cmn_dblink   fdst
       WHERE aias.invoice_id    = fad.pk1_value
         AND fdst.media_id       = fd.media_id
         AND fad.document_id     = fd.document_id
         AND fdd.datatype_id     = fd.datatype_id
         AND fd.category_id     = fdc.category_id
         AND fdt.document_id     = fd.document_id
         AND fdd.name            = 'SHORT_TEXT'                     
		 AND fad.pk1_value   between nvl(gv_legacy_id_from,fad.pk1_value) and nvl(gv_legacy_id_to,fad.pk1_value)
         and aias.vendor_id      = aps.vendor_id
         AND aias.vendor_site_id = assa.vendor_site_id
         AND fad.entity_name     = 'AP_INVOICES'                  -- entity name
         AND EXISTS ( SELECT 1
                        FROM ap_invoices_all       aiat
                           , ap_suppliers          apt
                           , ap_supplier_sites_all asst
                       WHERE aiat.invoice_num      = aias.invoice_num
                         AND apt.vendor_id         = asst.vendor_id
                         AND apt.vendor_id         = apt.vendor_id
                         and aiat.vendor_site_id   = asst.vendor_site_id
                         and apt.segment1          = aps.segment1
                         and asst.vendor_site_code = assa.vendor_site_code);


  -- This Cursor is used to retrieve information about Long Text Attachments ---

      CURSOR lcu_long 
      IS
      SELECT fad.seq_num            sequence_num
           , aias.invoice_num       invoice_number
           , aps.segment1           vendor_number
           , aps.vendor_name        vendor_name
           , assa.vendor_site_code  vendor_site_code
           , fad.entity_name        entity_name
           , fdt.description        document_description
           , fdlt.long_text         text
           , NULL                   file_name
           , NULL                   url
           , NULL                   function_name
           , fdd.name               datatype_name
           , fad.pk1_value          pk1_value
           , fad.pk2_value          pk2_value
           , fad.pk3_value          pk3_value
           , fad.pk4_value          pk4_value
           , fad.pk5_value          pk5_value
           , fdc.user_name               category_name
           , fdt.title              title
        FROM fnd_attached_documents@xxaqv_conv_cmn_dblink     fad
           , ap_invoices_all@xxaqv_conv_cmn_dblink            aias
           , ap_suppliers@xxaqv_conv_cmn_dblink               aps
           , ap_supplier_sites_all@xxaqv_conv_cmn_dblink      assa
           , fnd_document_categories_tl@xxaqv_conv_cmn_dblink    fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink           fdt
           , fnd_documents@xxaqv_conv_cmn_dblink              fd
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink     fdd
           , fnd_documents_long_text@xxaqv_conv_cmn_dblink    fdlt
       WHERE aias.invoice_id     = fad.pk1_value
         AND fdlt.media_id       = fd.media_id
         AND fad.document_id     = fd.document_id
         AND fdd.datatype_id     = fd.datatype_id
         AND fd.category_id     = fdc.category_id
         AND fdt.document_id     = fd.document_id
         AND fdd.name            = 'LONG_TEXT'                     
		 AND fad.pk1_value   between nvl(gv_legacy_id_from,fad.pk1_value) and nvl(gv_legacy_id_to,fad.pk1_value)
         and aias.vendor_id      = aps.vendor_id
         AND aias.vendor_site_id = assa.vendor_site_id
         AND fad.entity_name     = 'AP_INVOICES'                    -- entity name
         AND EXISTS ( SELECT 1
                        FROM ap_invoices_all       aiat
                           , ap_suppliers          apt
                           , ap_supplier_sites_all asst
                       WHERE aiat.invoice_num      = aias.invoice_num
                         AND apt.vendor_id         = asst.vendor_id
                         AND apt.vendor_id         = apt.vendor_id
                         and aiat.vendor_site_id   = asst.vendor_site_id
                         and apt.segment1          = aps.segment1
                         and asst.vendor_site_code = assa.vendor_site_code);

 -- This Cursor is used to retrieve information about Web URL Attachments.--

      CURSOR lcu_url 
      IS
      SELECT fad.seq_num            sequence_num
           , fdt.description        document_description
           , aias.invoice_num       invoice_number
           , aps.segment1           vendor_number
           , aps.vendor_name        vendor_name
           , assa.vendor_site_code  vendor_site_code
           , fad.entity_name        entity_name
           , null                   text
           , NULL                   file_name
           , fd.url                 url
           , NULL                   function_name
           , fdd.name               datatype_name
           , fad.pk1_value          pk1_value
           , fad.pk2_value          pk2_value
           , fad.pk3_value          pk3_value
           , fad.pk4_value          pk4_value
           , fad.pk5_value          pk5_value
           , fdc.user_name               category_name
           , fdt.title              title
        FROM fnd_documents@xxaqv_conv_cmn_dblink             fd
           , ap_suppliers@xxaqv_conv_cmn_dblink              aps
           , ap_invoices_all@xxaqv_conv_cmn_dblink           aias
            , ap_supplier_sites_all@xxaqv_conv_cmn_dblink    assa
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink    fdd
           , fnd_attached_documents@xxaqv_conv_cmn_dblink    fad
           , fnd_document_categories_tl@xxaqv_conv_cmn_dblink   fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink          fdt
       WHERE fdd.datatype_id     = fd.datatype_id
         AND aias.invoice_id     = fad.pk1_value
         AND fad.document_id     = fd.document_id
         AND fd.category_id      = fdc.category_id
         AND fdt.document_id     = fd.document_id
         AND fdd.name            = 'WEB_PAGE'
         AND fad.entity_name     = 'AP_INVOICES'                     -- entity name
         AND aias.vendor_id      = aps.vendor_id
         AND aias.vendor_site_id = assa.vendor_site_id
		 AND fad.pk1_value   between nvl(gv_legacy_id_from,fad.pk1_value) and nvl(gv_legacy_id_to,fad.pk1_value)
         AND EXISTS ( SELECT 1
                        FROM ap_invoices_all       aiat
                           , ap_suppliers          apt
                           , ap_supplier_sites_all asst
                       WHERE aiat.invoice_num      = aias.invoice_num
                         AND apt.vendor_id         = asst.vendor_id
                         AND apt.vendor_id         = apt.vendor_id
                         and aiat.vendor_site_id   = asst.vendor_site_id
                         and apt.segment1          = aps.segment1
                         and asst.vendor_site_code = assa.vendor_site_code);

 -- This Cursor is used to retrieve information about File Attachments. --

      CURSOR lcu_file 
      IS
      SELECT fad.pk1_value          pk1_value
           , fad.entity_name        entity_name
           , fd.media_id            file_id
           , fad.seq_num            sequence_num
           , aps.segment1           vendor_number
           , aps.vendor_name        vendor_name
           , aias.invoice_num       invoice_number
           , assa.vendor_site_code  vendor_site_code
           , fdd.name               datatype_name
           , fdc.user_name               category_name
           , fdt.description        document_description
           , fad.pk2_value          pk2_value
           , fad.pk3_value          pk3_value
           , fad.pk4_value          pk4_value
           , fad.pk5_value          pk5_value
        FROM fnd_documents@xxaqv_conv_cmn_dblink             fd
           , fnd_attached_documents@xxaqv_conv_cmn_dblink    fad
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink    fdd
           , ap_suppliers@xxaqv_conv_cmn_dblink              aps
           , ap_invoices_all@xxaqv_conv_cmn_dblink           aias
           , ap_supplier_sites_all@xxaqv_conv_cmn_dblink     assa
           , fnd_document_categories_tl@xxaqv_conv_cmn_dblink   fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink          fdt
       WHERE 1=1
         AND aias.invoice_id     = fad.pk1_value
         AND fad.entity_name     = 'AP_INVOICES'                        -- entity name
         AND fdd.name            = 'FILE'
         AND fad.document_id     = fd.document_id
         AND fd.datatype_id      = fdd.datatype_id
         AND fd.category_id      = fdc.category_id
         AND fdt.document_id     = fd.document_id
         AND aias.vendor_id      = aps.vendor_id
         AND aias.vendor_site_id = assa.vendor_site_id
		 AND fad.pk1_value   between nvl(gv_legacy_id_from,fad.pk1_value) and nvl(gv_legacy_id_to,fad.pk1_value)
         AND EXISTS ( SELECT 1
                        FROM ap_invoices_all       aiat
                           , ap_suppliers          apt
                           , ap_supplier_sites_all asst
                       WHERE aiat.invoice_num      = aias.invoice_num
                         AND apt.vendor_id         = asst.vendor_id
                         AND aiat.vendor_id        = apt.vendor_id
                         and aiat.vendor_site_id   = asst.vendor_site_id
                         and apt.segment1          = aps.segment1
                         and asst.vendor_site_code = assa.vendor_site_code);
    
          
          CURSOR lcu_file_details
          IS
          SELECT xads.x_file_id x_file_id
		       , xads.seq_num   seq_num
			   , fl.upload_date          upload_date      
			   , fl.file_content_type    file_content_type
			   , fl.expiration_date      expiration_date  
			   , fl.program_name         program_name     
			   , fl.language             language         
			   , fl.oracle_charset       oracle_charset   
			   , fl.file_format          file_format      
			   , fl.file_name            file_name        
               , fl.program_tag            program_tag
			FROM xxaqv_attach_docs_stg           xads
			    , fnd_lobs@xxaqv_conv_cmn_dblink fl
           WHERE datatype_name = 'FILE'
		     AND xads.x_file_id  = fl.file_id
             AND entity_name   = 'AP_INVOICES'
             AND x_pk1_value     between nvl(gv_legacy_id_from,x_pk1_value) and nvl(gv_legacy_id_to,x_pk1_value);
          
          CURSOR lcu_file_data 
          IS
          SELECT x_file_id
		       , seq_num
            FROM xxaqv_attach_docs_stg
           WHERE datatype_name = 'FILE'
             AND entity_name   = 'AP_INVOICES'
             AND x_pk1_value     between nvl(gv_legacy_id_from,x_pk1_value) and nvl(gv_legacy_id_to,x_pk1_value);
             

		  
     -- LOCAL VARIABLES
      ln_line_count    BINARY_INTEGER := 1;
      ln_error_count   BINARY_INTEGER := 0;
      ex_dml_errors    EXCEPTION;
	  ln_cmt_count     NUMBER   :=0;
      PRAGMA exception_init ( ex_dml_errors, -24381 );

  --INSERTING INTO STAGING TABLE
   BEGIN
      
      print_debug('EXTRACT_DATA: START Load data into staging table and mark them LS');
      print_debug('EXTRACT_DATA: pk1_value_from: ' || gv_legacy_id_from);
      print_debug('EXTRACT_DATA: pk1_value_to: ' || gv_legacy_id_to);
      --
      x_retcode   := 0;
      x_err_msg   := NULL;   
      --

    gt_xxaqv_attach_docs_tab.delete;

    FOR i IN lcu_short
    LOOP

     gt_xxaqv_attach_docs_tab(ln_line_count).x_pk1_value          := i.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name          := i.entity_name;             
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num              := i.sequence_num;                
     gt_xxaqv_attach_docs_tab(ln_line_count).title                := i.title;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name        := i.category_name;               
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name        := i.datatype_name;           
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description := i.document_description;    
     gt_xxaqv_attach_docs_tab(ln_line_count).text                 := i.text;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).url                  := i.url;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).file_name            := i.file_name;              
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date        := SYSDATE;        
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date     := SYSDATE;       
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login    := gn_login_id;      
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by      := gn_user_id;       
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by           := gn_user_id;            
     gt_xxaqv_attach_docs_tab(ln_line_count).process_flag         := gv_load_success;
     gt_xxaqv_attach_docs_tab(ln_line_count).request_id           := gn_request_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value            := i.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value            := i.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value            := i.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value            := i.pk5_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_name          := i.vendor_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).invoice_number       := i.invoice_number;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_site_code     := i.vendor_site_code;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_number        := i.vendor_number;
     ln_line_count                                                := ln_line_count + 1;

     END LOOP;
     BEGIN
          FORALL i IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( i );

             print_debug(gv_module
                        ||':'
                        ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:Short Text Records loaded sucessfully: ' 
                        || SQL%rowcount);         
             COMMIT;

         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
              print_debug(gv_module
                         ||':'
                         ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG: Number of failures for Short Text : ' 
                         || ln_error_count,gn_log_level); 
               FOR i IN 1..ln_error_count 
               LOOP 
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:Short Text Error: ' 
                           || i 
                           || 'Array Index: '
                           || SQL%bulk_exceptions(i).error_index 
                           || 'Message: ' 
                           || sqlerrm(-SQL%bulk_exceptions(i).error_code),gn_log_level);
               END LOOP;
            
            WHEN OTHERS 
            THEN
               print_debug(gv_module||':'
                          ||'EXTRACT_DATA:Short Text Unexpected Error: ' 
                          || sqlerrm, gn_log_level );
               x_retcode   := 1;
               x_err_msg   := gv_module
                              ||':'||'EXTRACT_DATA:Short Text Unexpected Error:' 
                              || to_char(sqlcode) 
                              || '-' 
                              || sqlerrm;
         END;


     gt_xxaqv_attach_docs_tab.delete;

    FOR j IN lcu_long
    LOOP
  
     gt_xxaqv_attach_docs_tab(ln_line_count).x_pk1_value          := j.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name          := j.entity_name;             
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num              := j.sequence_num;                
     gt_xxaqv_attach_docs_tab(ln_line_count).title                := j.title;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name        := j.category_name;               
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name        := j.datatype_name;           
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description := j.document_description;    
     gt_xxaqv_attach_docs_tab(ln_line_count).text                 := j.text;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).url                  := j.url;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).file_name            := j.file_name;              
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date        := SYSDATE;        
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date     := SYSDATE;       
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login    := gn_login_id;      
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by      := gn_user_id;       
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by           := gn_user_id;            
     gt_xxaqv_attach_docs_tab(ln_line_count).process_flag         := gv_load_success;
     gt_xxaqv_attach_docs_tab(ln_line_count).request_id           := gn_request_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value            := j.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value            := j.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value            := j.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value            := j.pk5_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_name          := j.vendor_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).invoice_number       := j.invoice_number;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_site_code     := j.vendor_site_code;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_number        := j.vendor_number;
     ln_line_count                                                := ln_line_count + 1;
     
     END LOOP;
     BEGIN

          FORALL j IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( j );

 
             print_debug(gv_module
                        ||':'
                        ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:Long Text Records loaded sucessfully: ' 
                        || SQL%rowcount);         
         COMMIT;

         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
              print_debug(gv_module
                         ||':'
                         ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:Long Text Number of failures: ' 
                         || ln_error_count,gn_log_level); 
               FOR i IN 1..ln_error_count 
               LOOP 
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:Long Text Error: ' 
                           || i 
                           || 'Array Index: '
                           || SQL%bulk_exceptions(i).error_index 
                           || 'Message: ' 
                           || sqlerrm(-SQL%bulk_exceptions(i).error_code),gn_log_level);
               END LOOP;

            WHEN OTHERS 
            THEN
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA:Long Text Unexpected Error: ' 
                           || sqlerrm, gn_log_level );
               x_retcode   := 1;
               x_err_msg   := gv_module
                              ||':'
                              ||'EXTRACT_DATA:Long Text Unexpected Error:' 
                              || to_char(sqlcode) 
                              || '-' 
                              || sqlerrm;
         END;
    gt_xxaqv_attach_docs_tab.delete;

    FOR z IN lcu_url
    LOOP

     gt_xxaqv_attach_docs_tab(ln_line_count).x_pk1_value          := z.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name          := z.entity_name;             
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num              := z.sequence_num;                
     gt_xxaqv_attach_docs_tab(ln_line_count).title                := z.title;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name        := z.category_name;               
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name        := z.datatype_name;           
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description := z.document_description;    
     gt_xxaqv_attach_docs_tab(ln_line_count).text                 := z.text;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).url                  := z.url;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).file_name            := z.file_name;              
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date        := SYSDATE;        
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date     := SYSDATE;       
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login    := gn_login_id;      
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by      := gn_user_id;       
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by           := gn_user_id;            
     gt_xxaqv_attach_docs_tab(ln_line_count).process_flag         := gv_load_success;
     gt_xxaqv_attach_docs_tab(ln_line_count).request_id           := gn_request_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value            := z.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value            := z.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value            := z.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value            := z.pk5_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_name          := z.vendor_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).invoice_number       := z.invoice_number;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_site_code     := z.vendor_site_code;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_number        := z.vendor_number;
     ln_line_count                                                := ln_line_count + 1;
     
     END LOOP;
     BEGIN
          FORALL z IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( z );

            xxaqv_conv_cmn_utility_pkg.print_logs('LODA_DATA: xxaqv_attach_docs_stg:URL Records loaded sucessfully: ' || SQL%rowcount, 'O' );
            xxaqv_conv_cmn_utility_pkg.print_logs('LODA_DATA: xxaqv_attach_docs_stg:URL Records loaded sucessfully: ' || SQL%rowcount);
          COMMIT;
         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Number of failures for URL: ' || ln_error_count, 'O' );
               xxaqv_conv_cmn_utility_pkg.print_logs('LOAD_DATA: xxaqv_attach_docs_stg: Number of failures for URL: ' || ln_error_count);
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
               x_err_msg   := 'LOAD_DATA: Unexpected error while populating data in xxaqv_attach_docs_stg for URL.'
                            || to_char(sqlcode)
                            || '-'
                            || sqlerrm;
         END;

    gt_xxaqv_attach_docs_tab.delete;

    FOR m IN lcu_file 
    LOOP
    
     gt_xxaqv_attach_docs_tab(ln_line_count).x_pk1_value          := m.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name          := m.entity_name; 
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num              := m.sequence_num; 
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name        := m.category_name; 
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name        := m.datatype_name; 
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description := m.document_description; 
     gt_xxaqv_attach_docs_tab(ln_line_count).x_file_id            := m.file_id; 
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date        := SYSDATE;
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date     := SYSDATE; 
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login    := gn_login_id; 
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by      := gn_user_id; 
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by           := gn_user_id; 
     gt_xxaqv_attach_docs_tab(ln_line_count).process_flag         := gv_load_success;
     gt_xxaqv_attach_docs_tab(ln_line_count).request_id           := gn_request_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value            := m.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value            := m.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value            := m.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value            := m.pk5_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_name          := m.vendor_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).invoice_number       := m.invoice_number;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_site_code     := m.vendor_site_code;
     gt_xxaqv_attach_docs_tab(ln_line_count).vendor_number        := m.vendor_number;
     ln_line_count                                                := ln_line_count + 1;
     
     END LOOP;
     BEGIN
          FORALL m IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( m );

            print_debug(gv_module
                        ||':'
                        ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:File Records loaded sucessfully: ' 
                        || SQL%rowcount);  
        COMMIT;
          --inserting lob data
          BEGIN
           
           FOR r_cur_file_details IN lcu_file_details
           LOOP
                    ln_cmt_count := ln_cmt_count + 1;
              UPDATE xxaqv_attach_docs_stg
                 SET upload_date          = r_cur_file_details.upload_date         
                   , file_content_type    = r_cur_file_details.file_content_type   
                   , expiration_date      = r_cur_file_details.expiration_date     
                   , program_name         = r_cur_file_details.program_name        
                   , language             = r_cur_file_details.language            
                   , oracle_charset       = r_cur_file_details.oracle_charset      
                   , file_format          = r_cur_file_details.file_format         
                   , file_name            = r_cur_file_details.file_name           
                   , program_tag          = r_cur_file_details.program_tag         
               WHERE x_file_id     = r_cur_file_details.x_file_id
			     AND seq_num       = r_cur_file_details.seq_num
                 AND datatype_name = 'FILE'
                 AND entity_name   = 'AP_INVOICES'; 
  			  IF ln_cmt_count = gn_commit_cnt
			  THEN
			  	 COMMIT;
			  	 ln_cmt_count := 0;
			  END IF;
          END LOOP;
         COMMIT;
		   
        ln_cmt_count := 0;
           FOR r_cur_file_data IN lcu_file_data
           LOOP
                ln_cmt_count := ln_cmt_count + 1;
              UPDATE xxaqv_attach_docs_stg xads
                 SET xads.file_data = ( SELECT file_data
                                          FROM fnd_lobs@xxaqv_conv_cmn_dblink fl
                                         WHERE r_cur_file_data.x_file_id = fl.file_id       )
               WHERE xads.x_file_id     = r_cur_file_data.x_file_id 
			     AND xads.seq_num       = r_cur_file_data.seq_num
                 AND xads.datatype_name = 'FILE'
                 AND xads.entity_name   = 'AP_INVOICES'; 
  			IF ln_cmt_count = gn_commit_cnt
			THEN
				 COMMIT;
				 ln_cmt_count := 0;
			END IF;
          END LOOP;
         COMMIT;

         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
              print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:File Number of failures for FILE DATA: ' 
                           || ln_error_count,gn_log_level); 
               FOR i IN 1..ln_error_count 
               LOOP 
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:FILE DATA Error: ' 
                           || i 
                           || 'Array Index: '
                           || SQL%bulk_exceptions(i).error_index 
                           || 'Message: ' 
                           || sqlerrm(-SQL%bulk_exceptions(i).error_code),gn_log_level);
               END LOOP;

            WHEN OTHERS 
            THEN
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA:FILE DATA Unexpected Error: ' 
                           || sqlerrm, gn_log_level );
               x_retcode   := 1;
               x_err_msg   := gv_module
                           ||':'
                           ||'EXTRACT_DATA:FILE DATA Unexpected Error:' 
                           || to_char(sqlcode) 
                           || '-' 
                           || sqlerrm;
         END;

         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:File Number of failures: ' 
                           || ln_error_count,gn_log_level); 
               FOR i IN 1..ln_error_count 
               LOOP 
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:File Error: ' 
                           || i 
                           || 'Array Index: '
                           || SQL%bulk_exceptions(i).error_index 
                           || 'Message: ' 
                           || sqlerrm(-SQL%bulk_exceptions(i).error_code),gn_log_level);
               END LOOP;
            
            WHEN OTHERS 
            THEN
               print_debug('EXTRACT_DATA:File Unexpected Error: ' || sqlerrm, gn_log_level );
               x_retcode   := 1;
               x_err_msg   := gv_module
                           ||':'
                           ||'EXTRACT_DATA:File Unexpected Error:' 
                           || to_char(sqlcode) 
                           || '-' 
                           || sqlerrm;
         END;


    EXCEPTION
      WHEN OTHERS 
      THEN
         print_debug(gv_module
                    ||':'
                    ||'EXTRACT_DATA: Unexpected error:' 
                    || sqlerrm  ,gn_log_level  );
         x_retcode   := 1;
         x_err_msg   := gv_module
                        ||':'
                        ||'EXTRACT_DATA: Unexpected error:' 
                        || to_char(sqlcode) 
                        || '-' 
                        || sqlerrm;
   END ap_invoice_load_staging_data;



--/****************************************************************************************************************
-- * Procedure  : ar_inv_load_staging_data                                                                        *
-- * Purpose    : This Procedure is used to load ar_invoice attachment data into staging Table                    *
-- ****************************************************************************************************************/

   PROCEDURE ar_inv_load_staging_data ( x_retcode        OUT   NUMBER
                                      , x_err_msg        OUT   VARCHAR2)
    IS

 -- This Cursor is used to retrieve information about Short Text Attachments. --

      CURSOR lcu_short 
      IS
       SELECT fad.seq_num      sequence_num
           , rcta.trx_number   trx_number
           , fad.entity_name   entity_name
           , fdt.description   document_description
           , regexp_replace
            (fdst.short_text
             , '[^[!-~]]*'
             , ' ' )	       text
           , NULL              file_name
           , NULL              url
           , NULL              function_name
           , fdd.name          datatype_name
           , fad.pk1_value     pk1_value
           , fad.pk2_value     pk2_value
           , fad.pk3_value     pk3_value
           , fad.pk4_value     pk4_value
           , fad.pk5_value     pk5_value
           , fdc.user_name      category_name
           , fdt.title         title
        FROM fnd_attached_documents@xxaqv_conv_cmn_dblink     fad
           , ra_customer_trx_all@xxaqv_conv_cmn_dblink        rcta
           , fnd_document_categories_tl@xxaqv_conv_cmn_dblink    fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink           fdt
           , fnd_documents@xxaqv_conv_cmn_dblink              fd
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink     fdd
           , fnd_documents_short_text@xxaqv_conv_cmn_dblink   fdst
       WHERE fdst.media_id        = fd.media_id
         AND fad.document_id      = fd.document_id
         AND fdd.datatype_id      = fd.datatype_id
         AND fd.category_id     = fdc.category_id
         AND fdt.document_id      = fd.document_id
         AND fdd.name             = 'SHORT_TEXT'                     
		 AND fad.pk1_value   between nvl(gv_legacy_id_from,fad.pk1_value) and nvl(gv_legacy_id_to,fad.pk1_value)
         AND rcta.CUSTOMER_TRX_ID = fad.pk1_value
         AND fad.entity_name      = 'RA_CUSTOMER_TRX'                     -- entity name
         AND EXISTS ( SELECT 1
                        FROM ra_customer_trx_all rcts
                       WHERE rcta.trx_number    = rcts.trx_number );

  -- This Cursor is used to retrieve information about Long Text Attachments ---

      CURSOR lcu_long 
      IS
      SELECT fad.seq_num       sequence_num
           , rcta.trx_number   trx_number
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
           , fdc.user_name          category_name
           , fdt.title         title
        FROM fnd_attached_documents@xxaqv_conv_cmn_dblink   fad
           , ra_customer_trx_all@xxaqv_conv_cmn_dblink      rcta
           , fnd_document_categories_tl@xxaqv_conv_cmn_dblink  fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink         fdt
           , fnd_documents@xxaqv_conv_cmn_dblink            fd
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink   fdd
           , fnd_documents_long_text@xxaqv_conv_cmn_dblink  fdlt
       WHERE fdlt.media_id        = fd.media_id
         AND fad.document_id      = fd.document_id
         AND fdd.datatype_id      = fd.datatype_id
         AND fd.category_id     = fdc.category_id
         AND fdt.document_id      = fd.document_id
         AND fdd.name             = 'LONG_TEXT'                        
		 AND fad.pk1_value   between nvl(gv_legacy_id_from,fad.pk1_value) and nvl(gv_legacy_id_to,fad.pk1_value)
         AND rcta.CUSTOMER_TRX_ID = fad.pk1_value
         AND fad.entity_name      = 'RA_CUSTOMER_TRX'                    -- entity name
         AND EXISTS ( SELECT 1
                        FROM ra_customer_trx_all rcts
                       WHERE rcta.trx_number  = rcts.trx_number );

 -- This Cursor is used to retrieve information about Web URL Attachments.--

      CURSOR lcu_url 
      IS
      SELECT fad.seq_num       sequence_num
           , fdt.description   document_description
           , rcta.trx_number   trx_number
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
           , fdc.user_name          category_name
           , fdt.title         title
        FROM fnd_documents@xxaqv_conv_cmn_dblink             fd
           , ra_customer_trx_all@xxaqv_conv_cmn_dblink       rcta
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink    fdd
           , fnd_attached_documents@xxaqv_conv_cmn_dblink    fad
           , fnd_document_categories_tl@xxaqv_conv_cmn_dblink   fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink          fdt
       WHERE fdd.datatype_id      = fd.datatype_id
         AND fad.document_id      = fd.document_id
         AND fd.category_id     = fdc.category_id
         AND fdt.document_id      = fd.document_id
         AND fdd.name             = 'WEB_PAGE'
		 AND fad.pk1_value   between nvl(gv_legacy_id_from,fad.pk1_value) and nvl(gv_legacy_id_to,fad.pk1_value)
         AND rcta.CUSTOMER_TRX_ID = fad.pk1_value
         AND fad.entity_name      = 'RA_CUSTOMER_TRX'                    -- entity name
         AND EXISTS ( SELECT 1
                        FROM ra_customer_trx_all rcts
                       WHERE rcta.trx_number  = rcts.trx_number );

 -- This Cursor is used to retrieve information about File Attachments. --

      CURSOR lcu_file
       IS
       SELECT fad.pk1_value         pk1_value
           , fad.entity_name        entity_name
           , fl.file_id             file_id
           , fl.file_name           file_name
           , fad.seq_num            sequence_num
           , rcta.trx_number        trx_number
           , fdd.name               datatype_name
           , fl.upload_date         upload_date
           , fl.file_content_type   file_content_type
           , fl.expiration_date     expiration_date
           , fl.program_name        program_name
           , fl.language            language
           , fl.oracle_charset      oracle_charset
           , fl.file_format         file_format
           , fdc.user_name          category_name
           , fdt.description        document_description
           , fad.pk2_value          pk2_value
           , fad.pk3_value          pk3_value
           , fad.pk4_value          pk4_value
           , fad.pk5_value          pk5_value
		   , fl.program_tag         program_tag
        FROM fnd_lobs@xxaqv_conv_cmn_dblink                  fl
           , fnd_documents@xxaqv_conv_cmn_dblink             fd
           , fnd_attached_documents@xxaqv_conv_cmn_dblink    fad
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink    fdd
           , ra_customer_trx_all@xxaqv_conv_cmn_dblink       rcta
           , fnd_document_categories_tl@xxaqv_conv_cmn_dblink   fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink          fdt
       WHERE fl.file_id           = fd.media_id
         AND rcta.CUSTOMER_TRX_ID = fad.pk1_value
         AND fad.entity_name      = 'RA_CUSTOMER_TRX'                    -- entity name
         AND fdd.name             = 'FILE'
         AND fad.document_id      = fd.document_id
         AND fd.datatype_id       = fdd.datatype_id
         AND fd.category_id     = fdc.category_id
         AND fdt.document_id      = fd.document_id
		 AND fad.pk1_value   between nvl(gv_legacy_id_from,fad.pk1_value) and nvl(gv_legacy_id_to,fad.pk1_value)
         AND EXISTS ( SELECT 1
                        FROM ra_customer_trx_all rcts
                       WHERE rcta.trx_number  = rcts.trx_number );


          CURSOR lcu_file_data 
          IS
          SELECT x_file_id
		       , seq_num
            FROM xxaqv_attach_docs_stg
           WHERE datatype_name = 'FILE'
             AND entity_name   = 'RA_CUSTOMER_TRX'
             AND x_pk1_value     = nvl(gv_pk1_value,x_pk1_value);

     -- LOCAL VARIABLES
      ln_line_count    BINARY_INTEGER := 1;
      ln_error_count   BINARY_INTEGER := 0;
      ex_dml_errors    EXCEPTION;
      PRAGMA exception_init ( ex_dml_errors, -24381 );
  	  ln_cmt_count     NUMBER :=0;
			  
   --INSERTING INTO STAGING TABLE
   BEGIN
      
      print_debug('EXTRACT_DATA: START Load data into staging table and mark them LS');
      print_debug('EXTRACT_DATA: pk1_value_from: ' || gv_legacy_id_from);
      print_debug('EXTRACT_DATA: pk1_value_to: ' || gv_legacy_id_to);
      --
      x_retcode   := 0;
      x_err_msg   := NULL;   
      -- 


    gt_xxaqv_attach_docs_tab.delete;

    FOR i IN lcu_short
    LOOP

     gt_xxaqv_attach_docs_tab(ln_line_count).x_pk1_value          := i.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name          := i.entity_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num              := i.sequence_num;
     gt_xxaqv_attach_docs_tab(ln_line_count).title                := i.title;
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name        := i.category_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name        := i.datatype_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description := i.document_description;
     gt_xxaqv_attach_docs_tab(ln_line_count).text                 := i.text;
     gt_xxaqv_attach_docs_tab(ln_line_count).url                  := i.url;
     gt_xxaqv_attach_docs_tab(ln_line_count).file_name            := i.file_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date        := SYSDATE;
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date     := SYSDATE;
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login    := gn_login_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by      := gn_user_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by           := gn_user_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).process_flag         := gv_load_success;
     gt_xxaqv_attach_docs_tab(ln_line_count).request_id           := gn_request_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value            := i.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value            := i.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value            := i.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value            := i.pk5_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).trx_number           := i.trx_number;
     ln_line_count                                                := ln_line_count + 1;

     END LOOP;
     BEGIN
          FORALL i IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( i );

             print_debug(gv_module
                        ||':'
                        ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:Short Text Records loaded sucessfully: ' 
                        || SQL%rowcount);         
         COMMIT;

         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
              print_debug(gv_module
                         ||':'
                         ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG: Number of failures for Short Text : ' 
                         || ln_error_count,gn_log_level); 
               FOR i IN 1..ln_error_count 
               LOOP 
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:Short Text Error: ' 
                           || i 
                           || 'Array Index: '
                           || SQL%bulk_exceptions(i).error_index 
                           || 'Message: ' 
                           || sqlerrm(-SQL%bulk_exceptions(i).error_code),gn_log_level);
               END LOOP;
            
            WHEN OTHERS 
            THEN
               print_debug(gv_module||':'
                          ||'EXTRACT_DATA:Short Text Unexpected Error: ' 
                          || sqlerrm, gn_log_level );
               x_retcode   := 1;
               x_err_msg   := gv_module
                              ||':'||'EXTRACT_DATA:Short Text Unexpected Error:' 
                              || to_char(sqlcode) 
                              || '-' 
                              || sqlerrm;
         END;


     gt_xxaqv_attach_docs_tab.delete;

    FOR j IN lcu_long
    LOOP
  
     gt_xxaqv_attach_docs_tab(ln_line_count).x_pk1_value          := j.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name          := j.entity_name;             
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num              := j.sequence_num;                
     gt_xxaqv_attach_docs_tab(ln_line_count).title                := j.title;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name        := j.category_name;               
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name        := j.datatype_name;           
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description := j.document_description;    
     gt_xxaqv_attach_docs_tab(ln_line_count).text                 := j.text;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).url                  := j.url;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).file_name            := j.file_name;              
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date        := SYSDATE;        
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date     := SYSDATE;       
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login    := gn_login_id;      
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by      := gn_user_id;       
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by           := gn_user_id;            
     gt_xxaqv_attach_docs_tab(ln_line_count).process_flag         := gv_load_success;
     gt_xxaqv_attach_docs_tab(ln_line_count).request_id           := gn_request_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value            := j.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value            := j.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value            := j.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value            := j.pk5_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).trx_number           := j.trx_number;
     ln_line_count                                                := ln_line_count + 1;
     
     END LOOP;
     BEGIN

          FORALL j IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( j );

           print_debug(gv_module
                        ||':'
                        ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:Long Text Records loaded sucessfully: ' 
                        || SQL%rowcount);         
         COMMIT;

         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
              print_debug(gv_module
                         ||':'
                         ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:Long Text Number of failures: ' 
                         || ln_error_count,gn_log_level); 
               FOR i IN 1..ln_error_count 
               LOOP 
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:Long Text Error: ' 
                           || i 
                           || 'Array Index: '
                           || SQL%bulk_exceptions(i).error_index 
                           || 'Message: ' 
                           || sqlerrm(-SQL%bulk_exceptions(i).error_code),gn_log_level);
               END LOOP;
            
            WHEN OTHERS 
            THEN
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA:Long Text Unexpected Error: ' 
                           || sqlerrm, gn_log_level );
               x_retcode   := 1;
               x_err_msg   := gv_module
                              ||':'
                              ||'EXTRACT_DATA:Long Text Unexpected Error:' 
                              || to_char(sqlcode) 
                              || '-' 
                              || sqlerrm;
         END;
         


    gt_xxaqv_attach_docs_tab.delete;

    FOR z IN lcu_url
    LOOP
    
     gt_xxaqv_attach_docs_tab(ln_line_count).x_pk1_value          := z.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name          := z.entity_name;             
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num              := z.sequence_num;                
     gt_xxaqv_attach_docs_tab(ln_line_count).title                := z.title;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name        := z.category_name;               
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name        := z.datatype_name;           
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description := z.document_description;    
     gt_xxaqv_attach_docs_tab(ln_line_count).text                 := z.text;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).url                  := z.url;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).file_name            := z.file_name;              
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date        := SYSDATE;        
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date     := SYSDATE;       
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login    := gn_login_id;      
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by      := gn_user_id;       
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by           := gn_user_id;            
     gt_xxaqv_attach_docs_tab(ln_line_count).process_flag         := gv_load_success;
     gt_xxaqv_attach_docs_tab(ln_line_count).request_id           := gn_request_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value            := z.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value            := z.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value            := z.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value            := z.pk5_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).trx_number           := z.trx_number;
     ln_line_count                                                := ln_line_count + 1;
     
     END LOOP;
     BEGIN
          FORALL z IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( z );
        
          print_debug(gv_module
                        ||':'
                        ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:URL Records loaded sucessfully: ' 
                        || SQL%rowcount);         
         COMMIT;

         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
              print_debug(gv_module
                         ||':'
                         ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG: Number of failures for URL : ' 
                         || ln_error_count,gn_log_level); 
               FOR i IN 1..ln_error_count 
               LOOP 
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:URL Error: ' 
                           || i 
                           || 'Array Index: '
                           || SQL%bulk_exceptions(i).error_index 
                           || 'Message: ' 
                           || sqlerrm(-SQL%bulk_exceptions(i).error_code),gn_log_level);
               END LOOP;
            
            WHEN OTHERS 
            THEN
               print_debug(gv_module
                          ||':'
                          ||'EXTRACT_DATA:URL Unexpected Error: ' 
                          || sqlerrm, gn_log_level );
               x_retcode   := 1;
               x_err_msg   := gv_module
                              ||':'
                              ||'EXTRACT_DATA:URL Unexpected Error:' 
                              || to_char(sqlcode) 
                              || '-' 
                              || sqlerrm;
         END;

    gt_xxaqv_attach_docs_tab.delete;

    FOR m IN lcu_file 
    LOOP
    
     gt_xxaqv_attach_docs_tab(ln_line_count).x_pk1_value          := m.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name          := m.entity_name;             
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num              := m.sequence_num;              
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name        := m.category_name;               
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name        := m.datatype_name;           
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description := m.document_description;    
     gt_xxaqv_attach_docs_tab(ln_line_count).x_file_id            := m.file_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).upload_date          := m.upload_date;
     gt_xxaqv_attach_docs_tab(ln_line_count).file_name            := m.file_name;              
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date        := SYSDATE;        
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date     := SYSDATE;       
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login    := gn_login_id;      
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by      := gn_user_id;       
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by           := gn_user_id;            
     gt_xxaqv_attach_docs_tab(ln_line_count).process_flag         := gv_load_success;
     gt_xxaqv_attach_docs_tab(ln_line_count).request_id           := gn_request_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value            := m.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value            := m.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value            := m.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value            := m.pk5_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).file_content_type    := m.file_content_type;
     gt_xxaqv_attach_docs_tab(ln_line_count).expiration_date      := m.expiration_date;
     gt_xxaqv_attach_docs_tab(ln_line_count).program_name         := m.program_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).language             := m.language;
	 gt_xxaqv_attach_docs_tab(ln_line_count).file_format          := m.file_format;
	 gt_xxaqv_attach_docs_tab(ln_line_count).program_tag          := m.program_tag;
     gt_xxaqv_attach_docs_tab(ln_line_count).oracle_charset       := m.oracle_charset;
     gt_xxaqv_attach_docs_tab(ln_line_count).trx_number           := m.trx_number;
     ln_line_count                                                := ln_line_count + 1;
     
     END LOOP;
     BEGIN
          FORALL m IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( m );



             print_debug(gv_module
                        ||':'
                        ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:FILE Records loaded sucessfully: ' 
                        || SQL%rowcount);  
        COMMIT;
        
          --inserting lob data
          BEGIN
        
           FOR r_cur_file_data IN lcu_file_data
           LOOP
			  	 ln_cmt_count := ln_cmt_count + 1 ;
              UPDATE xxaqv_attach_docs_stg xads
                 SET xads.file_data = ( SELECT file_data
                                          FROM fnd_lobs@xxaqv_conv_cmn_dblink fl
                                         WHERE r_cur_file_data.x_file_id = fl.file_id       )
               WHERE xads.x_file_id     = r_cur_file_data.x_file_id 
			     AND xads.seq_num       = r_cur_file_data.seq_num
                 AND xads.datatype_name = 'FILE'
                 AND xads.entity_name   = 'RA_CUSTOMER_TRX'; 
  			  IF ln_cmt_count = gn_commit_cnt
			  THEN
			  	 COMMIT;
			  	 ln_cmt_count := 0;
			  END IF;
          END LOOP;
         COMMIT;

         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
              print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:File Number of failures for FILE DATA: ' 
                           || ln_error_count,gn_log_level); 
               FOR i IN 1..ln_error_count 
               LOOP 
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:FILE DATA Error: ' 
                           || i 
                           || 'Array Index: '
                           || SQL%bulk_exceptions(i).error_index 
                           || 'Message: ' 
                           || sqlerrm(-SQL%bulk_exceptions(i).error_code),gn_log_level);
               END LOOP;
            
            WHEN OTHERS 
            THEN
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA:FILE DATA Unexpected Error: ' 
                           || sqlerrm, gn_log_level );
               x_retcode   := 1;
               x_err_msg   := gv_module
                           ||':'
                           ||'EXTRACT_DATA:FILE DATA Unexpected Error:' 
                           || to_char(sqlcode) 
                           || '-' 
                           || sqlerrm;
         END;

         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:File Number of failures: ' 
                           || ln_error_count,gn_log_level); 
               FOR i IN 1..ln_error_count 
               LOOP 
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:File Error: ' 
                           || i 
                           || 'Array Index: '
                           || SQL%bulk_exceptions(i).error_index 
                           || 'Message: ' 
                           || sqlerrm(-SQL%bulk_exceptions(i).error_code),gn_log_level);
               END LOOP;
            
            WHEN OTHERS 
            THEN
               print_debug('EXTRACT_DATA:File Unexpected Error: ' || sqlerrm, gn_log_level );
               x_retcode   := 1;
               x_err_msg   := gv_module
                           ||':'
                           ||'EXTRACT_DATA:File Unexpected Error:' 
                           || to_char(sqlcode) 
                           || '-' 
                           || sqlerrm;
         END;

    EXCEPTION
      WHEN OTHERS 
      THEN
         print_debug(gv_module
                    ||':'
                    ||'EXTRACT_DATA: Unexpected error:' 
                    || sqlerrm  ,gn_log_level  );
         x_retcode   := 1;
         x_err_msg   := gv_module
                        ||':'
                        ||'EXTRACT_DATA: Unexpected error:' 
                        || to_char(sqlcode) 
                        || '-' 
                        || sqlerrm;

   END ar_inv_load_staging_data;

--/****************************************************************************************************************
-- * Procedure  : ar_customers_load_staging_data                                                                  *
-- * Purpose    : This Procedure is used to load ar_customer attachment data into staging Table                   *
-- ****************************************************************************************************************/

   PROCEDURE ar_customers_load_staging_data ( x_retcode        OUT   NUMBER
                                            , x_err_msg        OUT   VARCHAR2 )
    IS

 -- This Cursor is used to retrieve information about Short Text Attachments. --

      CURSOR lcu_short IS
       SELECT fad.seq_num       sequence_num
           , ac.customer_number customer_number
           , fad.entity_name    entity_name
           , fdt.description    document_description
           , regexp_replace(fdst.short_text
             , '[^[!-~]]*'
             , ' '
                  )	            text
           , NULL               file_name
           , NULL               url
           , NULL               function_name
           , fdd.name           datatype_name
           , fad.pk1_value      pk1_value
           , fad.pk2_value      pk2_value
           , fad.pk3_value      pk3_value
           , fad.pk4_value      pk4_value
           , fad.pk5_value      pk5_value
           , fdc.user_name           category_name
           , fdt.title          title
        FROM fnd_attached_documents@xxaqv_conv_cmn_dblink     fad
           , ar_customers@xxaqv_conv_cmn_dblink               ac
           , fnd_document_categories_tl@xxaqv_conv_cmn_dblink    fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink           fdt
           , fnd_documents@xxaqv_conv_cmn_dblink              fd
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink     fdd
           , fnd_documents_short_text@xxaqv_conv_cmn_dblink   fdst
       WHERE fdst.media_id    = fd.media_id
         AND fad.document_id  = fd.document_id
         AND fdd.datatype_id  = fd.datatype_id
         AND fd.category_id     = fdc.category_id
         AND fdt.document_id  = fd.document_id
         AND fdd.name         = 'SHORT_TEXT'                     
		 AND fad.pk1_value   between nvl(gv_legacy_id_from,fad.pk1_value) and nvl(gv_legacy_id_to,fad.pk1_value)
         AND ac.CUSTOMER_ID   = fad.pk1_value
         AND fad.entity_name  = 'AR_CUSTOMERS'                       -- entity name
         AND EXISTS ( SELECT 1
                        FROM ar_customers acs
                       WHERE acs.customer_number    = ac.customer_number );

  -- This Cursor is used to retrieve information about Long Text Attachments ---

      CURSOR lcu_long 
      IS
      SELECT fad.seq_num         sequence_num
           , ac.customer_number  customer_number
           , fad.entity_name     entity_name
           , fdt.description     document_description
           , fdlt.long_text      text
           , NULL                file_name
           , NULL                url
           , NULL                function_name
           , fdd.name            datatype_name
           , fad.pk1_value       pk1_value
           , fad.pk2_value       pk2_value
           , fad.pk3_value       pk3_value
           , fad.pk4_value       pk4_value
           , fad.pk5_value       pk5_value
           , fdc.user_name            category_name
           , fdt.title           title
        FROM fnd_attached_documents@xxaqv_conv_cmn_dblink   fad
           , ar_customers@xxaqv_conv_cmn_dblink             ac
           , fnd_document_categories_tl@xxaqv_conv_cmn_dblink  fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink         fdt
           , fnd_documents@xxaqv_conv_cmn_dblink            fd
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink   fdd
           , fnd_documents_long_text@xxaqv_conv_cmn_dblink  fdlt
       WHERE fdlt.media_id   = fd.media_id
         AND fad.document_id = fd.document_id
         AND fdd.datatype_id = fd.datatype_id
         AND fd.category_id     = fdc.category_id
         AND fdt.document_id = fd.document_id
         AND fdd.name        = 'LONG_TEXT'                        
		 AND fad.pk1_value   between nvl(gv_legacy_id_from,fad.pk1_value) and nvl(gv_legacy_id_to,fad.pk1_value)
          AND ac.CUSTOMER_ID = fad.pk1_value
         AND fad.entity_name = 'AR_CUSTOMERS'                     -- entity name
         AND EXISTS ( SELECT 1
                        FROM ar_customers acs
                       WHERE acs.customer_number    = ac.customer_number );

 -- This Cursor is used to retrieve information about Web URL Attachments.--

      CURSOR lcu_url 
      IS
      SELECT fad.seq_num         sequence_num
           , fdt.description     document_description
           , ac.customer_number  customer_number
           , fad.entity_name     entity_name
           , null                text
           , NULL                file_name
           , fd.url              url
           , NULL                function_name
           , fdd.name            datatype_name
           , fad.pk1_value       pk1_value
           , fad.pk2_value       pk2_value
           , fad.pk3_value       pk3_value
           , fad.pk4_value       pk4_value
           , fad.pk5_value       pk5_value
           , fdc.user_name            category_name
           , fdt.title           title
        FROM fnd_documents@xxaqv_conv_cmn_dblink             fd
           , ar_customers@xxaqv_conv_cmn_dblink              ac
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink    fdd
           , fnd_attached_documents@xxaqv_conv_cmn_dblink    fad
           , fnd_document_categories_tl@xxaqv_conv_cmn_dblink   fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink          fdt
       WHERE fdd.datatype_id = fd.datatype_id
         AND fad.document_id = fd.document_id
         AND fd.category_id     = fdc.category_id
         AND fdt.document_id = fd.document_id
         AND fdd.name        = 'WEB_PAGE'
		 AND fad.pk1_value   between nvl(gv_legacy_id_from,fad.pk1_value) and nvl(gv_legacy_id_to,fad.pk1_value)
         AND ac.CUSTOMER_ID  = fad.pk1_value
         AND fad.entity_name = 'AR_CUSTOMERS'                      -- entity name
         AND EXISTS ( SELECT 1
                        FROM ar_customers acs
                       WHERE acs.customer_number    = ac.customer_number );

 -- This Cursor is used to retrieve information about File Attachments. --

      CURSOR lcu_file 
      IS
       SELECT fad.pk1_value          pk1_value
           , fad.entity_name        entity_name
           , fl.file_id             file_id
           , fl.file_name           file_name
           , fad.seq_num            sequence_num
           , ac.customer_number     customer_number
           , fdd.name               datatype_name
           , fl.upload_date         upload_date
           , fl.file_content_type   file_content_type
           , fl.expiration_date     expiration_date
           , fl.program_name        program_name
           , fl.language            language
           , fl.oracle_charset      oracle_charset
           , fl.file_format         file_format
           , fdc.user_name          category_name
           , fdt.description        document_description
           , fad.pk2_value          pk2_value
           , fad.pk3_value          pk3_value
           , fad.pk4_value          pk4_value
           , fad.pk5_value          pk5_value
		   , fl.program_tag         program_tag
        FROM fnd_lobs@xxaqv_conv_cmn_dblink                  fl
           , fnd_documents@xxaqv_conv_cmn_dblink             fd
           , fnd_attached_documents@xxaqv_conv_cmn_dblink    fad
           , fnd_document_datatypes@xxaqv_conv_cmn_dblink    fdd
           , ar_customers@xxaqv_conv_cmn_dblink              ac
           , fnd_document_categories_tl@xxaqv_conv_cmn_dblink   fdc
           , fnd_documents_tl@xxaqv_conv_cmn_dblink          fdt
       WHERE fl.file_id      = fd.media_id
         AND ac.CUSTOMER_ID  = fad.pk1_value
         AND fad.entity_name = 'AR_CUSTOMERS'                  -- entity name
         AND fdd.name        = 'FILE'
         AND fad.document_id = fd.document_id
         AND fd.datatype_id  = fdd.datatype_id
         AND fd.category_id     = fdc.category_id
         AND fdt.document_id = fd.document_id
		 AND fad.pk1_value   between nvl(gv_legacy_id_from,fad.pk1_value) and nvl(gv_legacy_id_to,fad.pk1_value)
         AND EXISTS ( SELECT 1
                        FROM ar_customers acs
                       WHERE acs.customer_number    = ac.customer_number );


          CURSOR lcu_file_data 
          IS
          SELECT x_file_id
		       , seq_num
            FROM xxaqv_attach_docs_stg
           WHERE datatype_name = 'FILE'
             AND entity_name   = 'RA_CUSTOMER_TRX'
             AND x_pk1_value    between nvl(gv_legacy_id_from,x_pk1_value) and nvl(gv_legacy_id_to,x_pk1_value);

     -- LOCAL VARIABLES
      ln_line_count    BINARY_INTEGER := 1;
      ln_error_count   BINARY_INTEGER := 0;
      ex_dml_errors    EXCEPTION;
      PRAGMA exception_init ( ex_dml_errors, -24381 );
	  ln_cmt_count     NUMBER :=0;


  --INSERTING INTO STAGING TABLE
   BEGIN
      
      print_debug('EXTRACT_DATA: START Load data into staging table and mark them LS');
      print_debug('EXTRACT_DATA: pk1_value_from: ' || gv_legacy_id_from);
      print_debug('EXTRACT_DATA: pk1_value_to: ' || gv_legacy_id_to);
      --
      x_retcode   := 0;
      x_err_msg   := NULL;   
      -- 
 

    gt_xxaqv_attach_docs_tab.delete;

    FOR i IN lcu_short
    LOOP

     gt_xxaqv_attach_docs_tab(ln_line_count).x_pk1_value          := i.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name          := i.entity_name;             
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num              := i.sequence_num;                
     gt_xxaqv_attach_docs_tab(ln_line_count).title                := i.title;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name        := i.category_name;               
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name        := i.datatype_name;           
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description := i.document_description;    
     gt_xxaqv_attach_docs_tab(ln_line_count).text                 := i.text;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).url                  := i.url;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).file_name            := i.file_name;              
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date        := SYSDATE;        
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date     := SYSDATE;       
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login    := gn_login_id;      
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by      := gn_user_id;       
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by           := gn_user_id;            
     gt_xxaqv_attach_docs_tab(ln_line_count).process_flag         := gv_load_success;
	 gt_xxaqv_attach_docs_tab(ln_line_count).request_id           := gn_request_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value            := i.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value            := i.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value            := i.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value            := i.pk5_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).customer_number      := i.customer_number;
     ln_line_count                                                := ln_line_count + 1;

     END LOOP;
     BEGIN
          FORALL i IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( i );

            print_debug(gv_module
                        ||':'
                        ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:Short Text Records loaded sucessfully: ' 
                        || SQL%rowcount);         
         COMMIT;
        
         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
              print_debug(gv_module
                         ||':'
                         ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG: Number of failures for Short Text : ' 
                         || ln_error_count,gn_log_level); 
               FOR i IN 1..ln_error_count 
               LOOP 
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:Short Text Error: ' 
                           || i 
                           || 'Array Index: '
                           || SQL%bulk_exceptions(i).error_index 
                           || 'Message: ' 
                           || sqlerrm(-SQL%bulk_exceptions(i).error_code),gn_log_level);
               END LOOP;
            
            WHEN OTHERS 
            THEN
               print_debug(gv_module||':'
                          ||'EXTRACT_DATA:Short Text Unexpected Error: ' 
                          || sqlerrm, gn_log_level );
               x_retcode   := 1;
               x_err_msg   := gv_module
                              ||':'||'EXTRACT_DATA:Short Text Unexpected Error:' 
                              || to_char(sqlcode) 
                              || '-' 
                              || sqlerrm;
         END;

     gt_xxaqv_attach_docs_tab.delete;

    FOR j IN lcu_long
    LOOP
  
     gt_xxaqv_attach_docs_tab(ln_line_count).x_pk1_value          := j.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name          := j.entity_name;             
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num              := j.sequence_num;                
     gt_xxaqv_attach_docs_tab(ln_line_count).title                := j.title;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name        := j.category_name;               
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name        := j.datatype_name;           
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description := j.document_description;    
     gt_xxaqv_attach_docs_tab(ln_line_count).text                 := j.text;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).url                  := j.url;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).file_name            := j.file_name;              
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date        := SYSDATE;        
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date     := SYSDATE;       
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login    := gn_login_id;      
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by      := gn_user_id;       
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by           := gn_user_id;            
     gt_xxaqv_attach_docs_tab(ln_line_count).process_flag         := gv_load_success;
     gt_xxaqv_attach_docs_tab(ln_line_count).request_id           := gn_request_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value            := j.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value            := j.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value            := j.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value            := j.pk5_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).customer_number      := j.customer_number;
     ln_line_count                                                := ln_line_count + 1;
     
     END LOOP;
     BEGIN

          FORALL j IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( j );
    
           print_debug(gv_module
                        ||':'
                        ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:Long Text Records loaded sucessfully: ' 
                        || SQL%rowcount);         
         COMMIT;
    
         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
              print_debug(gv_module
                         ||':'
                         ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:Long Text Number of failures: ' 
                         || ln_error_count,gn_log_level); 
               FOR i IN 1..ln_error_count 
               LOOP 
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:Long Text Error: ' 
                           || i 
                           || 'Array Index: '
                           || SQL%bulk_exceptions(i).error_index 
                           || 'Message: ' 
                           || sqlerrm(-SQL%bulk_exceptions(i).error_code),gn_log_level);
               END LOOP;
            
            WHEN OTHERS 
            THEN
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA:Long Text Unexpected Error: ' 
                           || sqlerrm, gn_log_level );
               x_retcode   := 1;
               x_err_msg   := gv_module
                              ||':'
                              ||'EXTRACT_DATA:Long Text Unexpected Error:' 
                              || to_char(sqlcode) 
                              || '-' 
                              || sqlerrm;
         END;


    gt_xxaqv_attach_docs_tab.delete;

    FOR z IN lcu_url
    LOOP
    
     gt_xxaqv_attach_docs_tab(ln_line_count).x_pk1_value          := z.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name          := z.entity_name;             
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num              := z.sequence_num;                
     gt_xxaqv_attach_docs_tab(ln_line_count).title                := z.title;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name        := z.category_name;               
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name        := z.datatype_name;           
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description := z.document_description;    
     gt_xxaqv_attach_docs_tab(ln_line_count).text                 := z.text;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).url                  := z.url;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).file_name            := z.file_name;              
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date        := SYSDATE;        
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date     := SYSDATE;       
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login    := gn_login_id;      
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by      := gn_user_id;       
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by           := gn_user_id;            
     gt_xxaqv_attach_docs_tab(ln_line_count).process_flag         := gv_load_success;
     gt_xxaqv_attach_docs_tab(ln_line_count).request_id           := gn_request_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value            := z.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value            := z.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value            := z.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value            := z.pk5_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).customer_number      := z.customer_number;
     ln_line_count                                                := ln_line_count + 1;
     
     END LOOP;
     BEGIN
          FORALL z IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( z );

          print_debug(gv_module
                        ||':'
                        ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:URL Records loaded sucessfully: ' 
                        || SQL%rowcount);         
         COMMIT;

         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
              print_debug(gv_module
                        ||':'
                         ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG: Number of failures for URL : ' 
                         || ln_error_count,gn_log_level); 
               FOR i IN 1..ln_error_count 
               LOOP 
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:URL Error: ' 
                           || i 
                           || 'Array Index: '
                           || SQL%bulk_exceptions(i).error_index 
                           || 'Message: ' 
                           || sqlerrm(-SQL%bulk_exceptions(i).error_code),gn_log_level);
               END LOOP;

            WHEN OTHERS 
            THEN
               print_debug(gv_module
                          ||':'
                          ||'EXTRACT_DATA:URL Unexpected Error: ' 
                          || sqlerrm, gn_log_level );
               x_retcode   := 1;
               x_err_msg   := gv_module
                              ||':'
                              ||'EXTRACT_DATA:URL Unexpected Error:' 
                              || to_char(sqlcode) 
                              || '-' 
                              || sqlerrm;
         END;

    gt_xxaqv_attach_docs_tab.delete;

    FOR m IN lcu_file 
    LOOP
    
     gt_xxaqv_attach_docs_tab(ln_line_count).x_pk1_value          := m.pk1_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).entity_name          := m.entity_name;             
     gt_xxaqv_attach_docs_tab(ln_line_count).seq_num              := m.sequence_num;                
     --gt_xxaqv_attach_docs_tab(ln_line_count).title                := i.title;                   
     gt_xxaqv_attach_docs_tab(ln_line_count).category_name        := m.category_name;               
     gt_xxaqv_attach_docs_tab(ln_line_count).datatype_name        := m.datatype_name;           
     gt_xxaqv_attach_docs_tab(ln_line_count).document_description := m.document_description;    
     gt_xxaqv_attach_docs_tab(ln_line_count).x_file_id              := m.file_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).upload_date          := m.upload_date;
     gt_xxaqv_attach_docs_tab(ln_line_count).file_name            := m.file_name;              
     gt_xxaqv_attach_docs_tab(ln_line_count).creation_date        := SYSDATE;        
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_date     := SYSDATE;       
     gt_xxaqv_attach_docs_tab(ln_line_count).last_update_login    := gn_login_id;      
     gt_xxaqv_attach_docs_tab(ln_line_count).last_updated_by      := gn_user_id;       
     gt_xxaqv_attach_docs_tab(ln_line_count).created_by           := gn_user_id;            
     gt_xxaqv_attach_docs_tab(ln_line_count).process_flag         := gv_load_success;
     gt_xxaqv_attach_docs_tab(ln_line_count).request_id           := gn_request_id;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk2_value            := m.pk2_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk3_value            := m.pk3_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk4_value            := m.pk4_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).pk5_value            := m.pk5_value;
     gt_xxaqv_attach_docs_tab(ln_line_count).file_content_type    := m.file_content_type;
     gt_xxaqv_attach_docs_tab(ln_line_count).expiration_date      := m.expiration_date;
     gt_xxaqv_attach_docs_tab(ln_line_count).program_name         := m.program_name;
     gt_xxaqv_attach_docs_tab(ln_line_count).language             := m.language;
	 gt_xxaqv_attach_docs_tab(ln_line_count).file_format          := m.file_format;
	 gt_xxaqv_attach_docs_tab(ln_line_count).program_tag          := m.program_tag;
     gt_xxaqv_attach_docs_tab(ln_line_count).oracle_charset       := m.oracle_charset;
     gt_xxaqv_attach_docs_tab(ln_line_count).customer_number      := m.customer_number;
     ln_line_count                                                := ln_line_count + 1;
     
     END LOOP;
     BEGIN
          FORALL m IN gt_xxaqv_attach_docs_tab.first..gt_xxaqv_attach_docs_tab.last SAVE EXCEPTIONS
            INSERT INTO xxaqv.xxaqv_attach_docs_stg VALUES gt_xxaqv_attach_docs_tab ( m );

             print_debug(gv_module
                        ||':'
                        ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:FILE Records loaded sucessfully: ' 
                        || SQL%rowcount);  
        COMMIT;
        
          --inserting lob data
          BEGIN
        
           FOR r_cur_file_data IN lcu_file_data
           LOOP

             ln_cmt_count := ln_cmt_count + 1 ;
              UPDATE xxaqv_attach_docs_stg xads
                 SET xads.file_data = ( SELECT file_data
                                          FROM fnd_lobs@xxaqv_conv_cmn_dblink fl
                                         WHERE r_cur_file_data.x_file_id = fl.file_id       )
               WHERE xads.x_file_id     = r_cur_file_data.x_file_id 
			     AND xads.seq_num       = r_cur_file_data.seq_num
                 AND xads.datatype_name = 'FILE'
                 AND xads.entity_name   = 'RA_CUSTOMER_TRX'; 
  			  IF ln_cmt_count = gn_commit_cnt
			  THEN
			  	 COMMIT;
			  	 ln_cmt_count := 0;
			  END IF;
          END LOOP;
         COMMIT;

         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
              print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:File Number of failures for FILE DATA: ' 
                           || ln_error_count,gn_log_level); 
               FOR i IN 1..ln_error_count 
               LOOP 
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:FILE DATA Error: ' 
                           || i 
                           || 'Array Index: '
                           || SQL%bulk_exceptions(i).error_index 
                           || 'Message: ' 
                           || sqlerrm(-SQL%bulk_exceptions(i).error_code),gn_log_level);
               END LOOP;

            WHEN OTHERS 
            THEN
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA:FILE DATA Unexpected Error: ' 
                           || sqlerrm, gn_log_level );
               x_retcode   := 1;
               x_err_msg   := gv_module
                           ||':'
                           ||'EXTRACT_DATA:FILE DATA Unexpected Error:' 
                           || to_char(sqlcode) 
                           || '-' 
                           || sqlerrm;
         END;

         EXCEPTION
            WHEN ex_dml_errors 
            THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:File Number of failures: ' 
                           || ln_error_count,gn_log_level); 
               FOR i IN 1..ln_error_count 
               LOOP 
               print_debug(gv_module
                           ||':'
                           ||'EXTRACT_DATA: XXAQV_ATTACH_DOCS_STG:File Error: ' 
                           || i 
                           || 'Array Index: '
                           || SQL%bulk_exceptions(i).error_index 
                           || 'Message: ' 
                           || sqlerrm(-SQL%bulk_exceptions(i).error_code),gn_log_level);
               END LOOP;

            WHEN OTHERS 
            THEN
               print_debug('EXTRACT_DATA:File Unexpected Error: ' || sqlerrm, gn_log_level );
               x_retcode   := 1;
               x_err_msg   := gv_module
                           ||':'
                           ||'EXTRACT_DATA:File Unexpected Error:' 
                           || to_char(sqlcode) 
                           || '-' 
                           || sqlerrm;
         END;


    EXCEPTION
      WHEN OTHERS 
      THEN
         print_debug(gv_module
                    ||':'
                    ||'EXTRACT_DATA: Unexpected error:' 
                    || sqlerrm  ,gn_log_level  );
         x_retcode   := 1;
         x_err_msg   := gv_module
                        ||':'
                        ||'EXTRACT_DATA: Unexpected error:' 
                        || to_char(sqlcode) 
                        || '-' 
                        || sqlerrm;
   
   END ar_customers_load_staging_data;


--/****************************************************************************************************************
-- * Procedure : validate_staging_records                                                                         *
-- * Purpose   : This Procedure validate the records in the staging table.                                        *
-- ****************************************************************************************************************/	

   PROCEDURE validate_staging_records ( x_retcode        OUT   NUMBER
                                      , x_err_msg        OUT   VARCHAR2 )
     IS	

     --Local Variables
     gn_created_by                    NUMBER         := fnd_global.user_id;
     ln_failed_invoice                NUMBER         := NULL;
     ln_success_invoice               NUMBER         := NULL;
     l_val_status                     VARCHAR2(10)   := NULL;
     l_val_flag                       VARCHAR2(100);
     ln_error_message                 VARCHAR2(4000) := NULL;
     lv_error_message                 VARCHAR2(4000) := NULL;
     ln_mstr_flag                     VARCHAR2(10);
     ln_pk1_value                     VARCHAR2(100);
     lv_category_id                   NUMBER;
     lv_datatype_id                   NUMBER;


     CURSOR lcu_attach
     IS
     SELECT x_pk1_value   
          , entity_name                
          , seq_num                    
          , title                      
          , category_name              
          , x_category_id                
          , x_datatype_id                
          , datatype_name              
          , document_description       
          , text                       
          , url                        
          , file_name                  
          , record_id                                   
          , process_flag                              
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
          , invoice_number
          , trx_number
          , customer_number
          , request_id
       FROM xxaqv_attach_docs_stg
      WHERE process_flag = gv_load_success
        AND entity_name  = nvl(gv_entity_name,entity_name) ;

      TYPE lcu_attach_type IS
         TABLE OF lcu_attach%rowtype INDEX BY BINARY_INTEGER;
      lcu_attach_tab     lcu_attach_type;
      ln_line_count      BINARY_INTEGER := 0;
      ln_error_count     BINARY_INTEGER := 0;
      ex_dml_errors EXCEPTION;
      PRAGMA exception_init ( ex_dml_errors,-24381 );
   --
   BEGIN
      print_debug('VALIDATE_RECORDS: START Validate staging table records and mark them as VS/VE');
      print_debug('EXTRACT_DATA: pk1_value_from: ' || gv_legacy_id_from);
      print_debug('EXTRACT_DATA: pk1_value_to: ' || gv_legacy_id_to);
      --
      x_retcode   := 0;
      x_err_msg   := NULL;
      --
      OPEN lcu_attach;
      LOOP
         lcu_attach_tab.DELETE;
         FETCH lcu_attach BULK COLLECT INTO lcu_attach_tab LIMIT gn_commit_cnt;
         EXIT WHEN lcu_attach_tab.count = 0;
         --
         FOR i IN lcu_attach_tab.first..lcu_attach_tab.last LOOP
            gn_retcode        := 0;
            gv_err_msg        := NULL;
            gv_process_flag   := 'S';
            gn_batch_run      := lcu_attach_tab(i).request_id;
            
            
             -- category name validation
             
        IF lcu_attach_tab(i).category_name IS NOT NULL 
        THEN
               validate_category_id( p_category_name => lcu_attach_tab(i).category_name
                                   , x_category_id   => lcu_attach_tab(i).x_category_id
                                   , x_retcode       => gn_retcode
                                   , x_err_msg       => gv_err_msg
               );

               IF gn_retcode <> 0 THEN
                  lcu_attach_tab(i).process_flag := gv_validate_error;
                  gv_process_flag                := 'E';
                  insert_error_records( p_batch_id  => gn_batch_run
                                      , p_legacy_id => lcu_attach_tab(i).category_name
                                      , p_error_col => 'CATEGORY_NAME'
                                      , p_error_msg => gv_err_msg
                  );
               END IF;
        END IF; 


              -- datatype name validation
  
               validate_datatype_id( p_datatype_name => lcu_attach_tab(i).datatype_name
                                   , x_datatype_id   => lcu_attach_tab(i).x_datatype_id
                                   , x_retcode       => gn_retcode
                                   , x_err_msg       => gv_err_msg
               );

               IF gn_retcode <> 0 THEN
                  lcu_attach_tab(i).process_flag := gv_validate_error;
                  gv_process_flag                := 'E';
                  insert_error_records( p_batch_id  => gn_batch_run
                                      , p_legacy_id => lcu_attach_tab(i).datatype_name
                                      , p_error_col => 'DATATYPE_NAME'
                                      , p_error_msg => gv_err_msg
                  );
               END IF;
       	  
-----------------------------------------------------------------------------------------PK1_VALUE VALIDATION-------------------------------------------------------------------------------------------------------------	 
        -- PK1 value validation for suppliers
         IF gv_entity_name = 'PO_VENDORS'
         THEN
         
         validate_supplier_pk( p_vendor_number => lcu_attach_tab(i).vendor_number
                             , p_vendor_name   => lcu_attach_tab(i).vendor_name
                             , x_pk1_value     => lcu_attach_tab(i).x_pk1_value
                             , x_retcode       => gn_retcode
                             , x_err_msg       => gv_err_msg
               );

               IF gn_retcode <> 0 THEN
                  lcu_attach_tab(i).process_flag := gv_validate_error;
                  gv_process_flag                := 'E';
                  insert_error_records( p_batch_id  => gn_batch_run
                                      , p_legacy_id => lcu_attach_tab(i).vendor_number
                                      , p_error_col => 'VENDOR_NUMBER'
                                      , p_error_msg => gv_err_msg
                  );
               END IF;
         END IF;
 
 
           -- PK1 value validation for supplier sites
        IF gv_entity_name = 'PO_VENDOR_SITES'
         THEN
                 validate_sup_sites_pk( p_vendor_number    => lcu_attach_tab(i).vendor_number
                                      , p_vendor_site_code => lcu_attach_tab(i).vendor_site_code
                                      , x_pk1_value        => lcu_attach_tab(i).x_pk1_value
                                      , x_retcode          => gn_retcode
                                      , x_err_msg          => gv_err_msg
               );

                IF gn_retcode <> 0 
                THEN
                  lcu_attach_tab(i).process_flag := gv_validate_error;
                  gv_process_flag                := 'E';
                  insert_error_records( p_batch_id  => gn_batch_run
                                      , p_legacy_id => lcu_attach_tab(i).vendor_site_code
                                      , p_error_col => 'VENDOR_SITE_CODE'
                                      , p_error_msg => gv_err_msg
                  );
                END IF;
         END IF;
         
         
        -- PK1 value validation for AP_INVOICES
         IF gv_entity_name = 'AP_INVOICES'
         THEN
        
         
             validate_ap_invoices_pk( p_vendor_number    => lcu_attach_tab(i).vendor_number
                                    , p_vendor_site_code => lcu_attach_tab(i).vendor_site_code
                                    , p_vendor_name      => lcu_attach_tab(i).vendor_name
                                    , p_invoice_number   => lcu_attach_tab(i).invoice_number 
                                    , x_pk1_value        => lcu_attach_tab(i).x_pk1_value
                                    , x_retcode          => gn_retcode
                                    , x_err_msg          => gv_err_msg
               );

                IF gn_retcode <> 0 
                THEN
                  lcu_attach_tab(i).process_flag := gv_validate_error;
                  gv_process_flag                := 'E';
                  insert_error_records( p_batch_id  => gn_batch_run
                                      , p_legacy_id => lcu_attach_tab(i).invoice_number
                                      , p_error_col => 'INVOICE_NUMBER'
                                      , p_error_msg => gv_err_msg
                  );
                END IF;
         END IF;
     
        -- PK1 value validation for AR_INVOICES
           IF gv_entity_name = 'RA_CUSTOMER_TRX'
           THEN
             validate_ar_inv_pk( p_trx_number => lcu_attach_tab(i).trx_number
                               , x_pk1_value  => lcu_attach_tab(i).x_pk1_value
                               , x_retcode    => gn_retcode
                               , x_err_msg    => gv_err_msg
               );

                IF gn_retcode <> 0 
                THEN
                  lcu_attach_tab(i).process_flag := gv_validate_error;
                  gv_process_flag                := 'E';
                  insert_error_records( p_batch_id  => gn_batch_run
                                      , p_legacy_id => lcu_attach_tab(i).trx_number
                                      , p_error_col => 'TRX_NUMBER'
                                      , p_error_msg => gv_err_msg
                  );
                END IF;
         END IF;
         
        -- PK1 value validation for suppliers
         IF gv_entity_name = 'AR_CUSTOMERS'
         THEN
         
       validate_ar_customers_pk( p_customer_number => lcu_attach_tab(i).customer_number  
                               , x_pk1_value       => lcu_attach_tab(i).x_pk1_value
                               , x_retcode         => gn_retcode
                               , x_err_msg         => gv_err_msg
               );

                IF gn_retcode <> 0 
                THEN
                  lcu_attach_tab(i).process_flag := gv_validate_error;
                  gv_process_flag                := 'E';
                  insert_error_records( p_batch_id  => gn_batch_run
                                      , p_legacy_id => lcu_attach_tab(i).customer_number
                                      , p_error_col => 'AR_CUSTOMER'
                                      , p_error_msg => gv_err_msg
                  );
                END IF;
         END IF;
         
         IF gv_process_flag = 'S' THEN
               lcu_attach_tab(i).process_flag := gv_validate_success;
            END IF;
         END LOOP; -- table type loop
----------------------------------------------------------UPDATING THE STAGING TABLE WITH VALIDATED DATA-----------------------------------------------------------------------------		 
         --UPDATING THE VALIDATED RECORDS

         BEGIN
            FORALL i IN lcu_attach_tab.first..lcu_attach_tab.last SAVE EXCEPTIONS
            UPDATE xxaqv.xxaqv_attach_docs_stg
               SET x_pk1_value                = lcu_attach_tab(i).x_pk1_value
                 , x_datatype_id              = lcu_attach_tab(i).x_datatype_id
                 , x_category_id              = lcu_attach_tab(i).x_category_id
                 , process_flag               = lcu_attach_tab(i).process_flag
            WHERE
                1 = 1
                AND ROWID = lcu_attach_tab(i).rowid;

            print_debug('VALIDATE_RECORDS: xxaqv_attach_docs_stg: Records loaded sucessfully: ' || SQL%rowcount);
            COMMIT;        

           EXCEPTION
            WHEN ex_dml_errors THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
               --
               print_debug( 'VALIDATE_RECORDS: Number of FORALL Update failures: ' || ln_error_count,gn_log_level );
               --
               FOR i IN 1..ln_error_count LOOP print_debug('VALIDATE_RECORDS: FORALL Update Error: ' || i || ' Array Index: ' || SQL%bulk_exceptions(i)
               .error_index || 'Message: ' || sqlerrm(-SQL%bulk_exceptions(i).error_code));
               END LOOP;

            WHEN OTHERS THEN
               print_debug( 'VALIDATE_RECORDS: FORALL Update Unexpected Error: ' || sqlerrm ,gn_log_level);
               x_retcode   := 1;
               x_err_msg   := 'VALIDATE_RECORDS: FORALL Update Unexpected Error:' || to_char(sqlcode) || '-' || sqlerrm;
         END;

      END LOOP; -- open cursor

      CLOSE lcu_attach;
      print_debug('VALIDATE_RECORDS: END Validate staging table records and mark them as VS/VE');
   EXCEPTION
      WHEN OTHERS THEN
         print_debug( 'VALIDATE_RECORDS: Unexpected error:' || sqlerrm ,gn_log_level);
         x_retcode   := 1;
         x_err_msg   := 'VALIDATE_RECORDS: Unexpected error:' || to_char(sqlcode) || '-' || sqlerrm;
            
END validate_staging_records;


--/****************************************************************************************************************
-- * Procedure  : populate_fnd_lobs                                                                               *
-- * Purpose    : This Procedure is used to populate fnd_lobs                                                     *
-- ****************************************************************************************************************/  

   PROCEDURE populate_fnd_lobs ( x_retcode       OUT   NUMBER
                               , x_err_msg       OUT   VARCHAR2
   ) IS


   lv_curr_record  VARCHAR2(255);
   ln_cmt_count    NUMBER :=0;
   
   CURSOR lcu_stg_data 
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
        , x_pk1_value
        , rowid  xadsrowid
     FROM xxaqv_attach_docs_stg
    WHERE entity_name   = gv_entity_name
      AND datatype_name = 'FILE'
      AND process_flag  = gv_validate_success;	  
     -- FOR UPDATE OF file_id;

   BEGIN

       FOR r_populate_lobs IN lcu_stg_data
       LOOP 
	   lv_curr_record := r_populate_lobs.xadsrowid;
	   ln_cmt_count   := ln_cmt_count + 1;
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
       
       UPDATE xxaqv_attach_docs_stg xad
          SET xad.x_file_id = fnd_lobs_s.currval
       --WHERE current of lcu_stg_data;
       WHERE xad.rowid = r_populate_lobs.xadsrowid;
       
  			  IF ln_cmt_count = gn_commit_cnt
			  THEN
			  	 COMMIT;
			  	 ln_cmt_count := 0;
			  END IF;
          END LOOP;
         COMMIT;

    EXCEPTION
      WHEN OTHERS THEN
               print_debug( 'LOAD_INTF: Unexpected Error : ' || sqlerrm,gn_log_level|| ' rowid ' ||lv_curr_record);
               x_retcode   := 1;
               x_err_msg   := 'LOAD_INTF: Unexpected Error:' || to_char(sqlcode) || '-' || sqlerrm;
  END populate_fnd_lobs;   
  
--/****************************************************************************************************************
-- * Procedure  : IMPORT_STAGING_DATA                                                                             *
-- * Purpose    : This Procedure is used to valdate the data in Staging Table                                     *
-- ****************************************************************************************************************/  

   PROCEDURE import_staging_data ( x_retcode        OUT   NUMBER
                                 , x_err_msg        OUT   VARCHAR2)
   IS
-- This Cursor is used to retrieve information from Staging Table --

      CURSOR lcu_select IS
      SELECT x_pk1_value
          , entity_name
          , seq_num
          , title
          , category_name 
          , x_category_id
          , x_datatype_id
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
          , process_flag 
          , error_message
          , document_id  
          , media_id 
          , pk2_value
          , pk3_value
          , pk4_value
          , pk5_value 
          , x_file_id
       FROM xxaqv_attach_docs_stg
      WHERE process_flag = gv_validate_success
        AND entity_name    = nvl(gv_entity_name,entity_name) ;

   BEGIN
          populate_fnd_lobs( x_retcode  
                           , x_err_msg  ); 

      
	  FOR lcu_r_cur_select IN lcu_select 
      LOOP                                                     ----Calling WEB API
         fnd_webattch.add_attachment( seq_num                => lcu_r_cur_select.seq_num
                                    , category_id            => lcu_r_cur_select.x_category_id          --category_id
                                    , document_description   => lcu_r_cur_select.document_description   --description
                                    , datatype_id            => lcu_r_cur_select.x_datatype_id          --datatype_id
                                    , text                   => lcu_r_cur_select.text
                                    , file_name              => lcu_r_cur_select.file_name                       
                                    , url                    => lcu_r_cur_select.url
                                    , function_name          => NULL  --function_name
                                    , entity_name            => lcu_r_cur_select.entity_name
                                    , pk1_value              => lcu_r_cur_select.x_pk1_value
                                    , pk2_value              => lcu_r_cur_select.pk2_value
                                    , pk3_value              => lcu_r_cur_select.pk3_value
                                    , pk4_value              => lcu_r_cur_select.pk4_value
                                    , pk5_value              => lcu_r_cur_select.pk5_value
                                    , media_id               => lcu_r_cur_select.x_file_id
                                    , user_id                => gn_user_id
                                    , title                  => lcu_r_cur_select.title
         );
      END LOOP;
	 EXCEPTION

	  WHEN OTHERS 
      THEN
         print_debug( 'IMPORT: Exception processing Attachments Data:' || sqlerrm, gn_log_level );
         x_retcode   := 1;
		 x_err_msg   := 'GET_WORK_TYPE_ID: Unexpected error: ' || sqlerrm;
   END import_staging_data;

--/****************************************************************************************************************
-- * Procedure : TIE_BACK_STAGING                                                                                 *
-- * Purpose   : This procedure will tie back base table data to staging table.                                   *
-- ****************************************************************************************************************/

   PROCEDURE tie_back_staging ( x_retcode        OUT   NUMBER
                              , x_err_msg        OUT   VARCHAR2 )
   IS
      CURSOR lcu_success IS
      SELECT
          seq_num,
          pk1_value,
          entity_name,
          document_id,
          attached_document_id
      FROM
          fnd_attached_documents;
		  		  
--      CURSOR lcu_error IS


      TYPE lcu_success_typ IS
         TABLE OF lcu_success%rowtype INDEX BY BINARY_INTEGER;
      lcu_success_tab   lcu_success_typ;
    /*  TYPE lcu_error_typ IS
         TABLE OF lcu_error%rowtype INDEX BY BINARY_INTEGER;*/
     -- lcu_error_tab     lcu_error_typ;
      ln_counter        BINARY_INTEGER := 0;
      ln_error_count    BINARY_INTEGER := 0;
      ex_dml_errors EXCEPTION;
      PRAGMA exception_init ( ex_dml_errors,-24381 );
   BEGIN
      print_debug('TIEBACK_STAGING: Start Tieback staging and interface table data');
      print_debug('EXTRACT_DATA: pk1_value_from: ' || gv_legacy_id_from);
      print_debug('EXTRACT_DATA: pk1_value_to: ' || gv_legacy_id_to);
	  --
      x_retcode   := 0;
      x_err_msg   := NULL;
      --
      print_debug('TIEBACK_STAGING: Updating Success Records');
      OPEN lcu_success;
      LOOP
         lcu_success_tab.DELETE;
         ln_counter := 0;
         FETCH lcu_success BULK COLLECT INTO lcu_success_tab LIMIT gn_commit_cnt;
         EXIT WHEN lcu_success_tab.count = 0;
         BEGIN
            FORALL i IN lcu_success_tab.first..lcu_success_tab.last SAVE EXCEPTIONS
               UPDATE xxaqv.xxaqv_attach_docs_stg
                  SET r12_document_id          = lcu_success_tab(i).document_id
				    , r12_attached_document_id = lcu_success_tab(i).attached_document_id
                    , process_flag             = gv_import_success
                WHERE 1 = 1
                  AND process_flag         = gv_validate_success
                  AND x_pk1_value          = lcu_success_tab(i).pk1_value
                  AND entity_name          = lcu_success_tab(i).entity_name
				  AND seq_num              = lcu_success_tab(i).seq_num;

            print_debug('TIEBACK_STAGING: XXAQV_PA_EXPND_INTF_C010_STG: Records Updated: ' || SQL%rowcount);
            COMMIT;
         EXCEPTION
            WHEN ex_dml_errors THEN
               x_retcode        := 1;
               ln_error_count   := SQL%bulk_exceptions.count;
			   --
               print_debug('TIEBACK_STAGING: Number of FORALL Update Success: ' || ln_error_count,gn_log_level );
			   --	  
               FOR i IN 1..ln_error_count LOOP print_debug('TIEBACK_STAGING: FORALL Update Success Error: ' || i || ' Array Index: ' || SQL%bulk_exceptions
               (i).error_index || 'Message: ' || sqlerrm(-SQL%bulk_exceptions(i).error_code));
               END LOOP;

            WHEN OTHERS THEN
               print_debug('TIEBACK_STAGING: FORALL Update Success Unexpected Error: ' || sqlerrm,gn_log_level );
               x_retcode   := 1;
               x_err_msg   := 'TIEBACK_STAGING: FORALL Update Success Unexpected Error:' || to_char(sqlcode) || '-' || sqlerrm;
         END;

      END LOOP;

      CLOSE lcu_success;
      --	
        
         BEGIN
         --gt_xxaqv_attach_docs_tab.delete;
		  print_debug('TIEBACK_STAGING: Update Error Records');          
               UPDATE xxaqv_attach_docs_stg
                  SET process_flag = gv_import_error
                WHERE 1 = 1
                  AND process_flag         = gv_validate_success;

            print_debug('TIEBACK_STAGING: XXAQV_ATTACH_DOCS_STG: Records Updated: ' || SQL%rowcount);
            COMMIT;
	  

           EXCEPTION
            WHEN OTHERS THEN
               print_debug('TIEBACK_STAGING: FORALL Update Success Unexpected Error: ' || sqlerrm,gn_log_level);
               x_retcode   := 1;
               x_err_msg   := 'TIEBACK_STAGING: FORALL Update Success Unexpected Error:' || to_char(sqlcode) || '-' || sqlerrm;
         END;
	
	--inserting into common error table which failed import
	BEGIN

		 FOR i IN ( select request_id,x_pk1_value,entity_name from xxaqv_attach_docs_stg where process_flag=gv_import_error) 
		 LOOP 
		 insert_error_records( p_batch_id    => i.request_id
                             , p_legacy_id   => i.x_pk1_value
                             , p_error_col   => i.entity_name
                             , p_error_msg   => 'Attachment failed to load for the record'
         );
         END LOOP;
		 print_debug('TIEBACK_STAGING: End Tieback staging ');
    END;
   EXCEPTION
      WHEN OTHERS THEN
         print_debug('TIEBACK_STAGING: Unexpected Error: '    || sqlerrm,gn_log_level);
         x_retcode   := 'TIEBACK_STAGING: Unexpected error: ' || to_char(sqlcode) || '-' || sqlerrm;
         x_retcode   := 1;

   END tie_back_staging;

--/****************************************************************************************************************
-- * Procedure  : MAIN                                                                                            *
-- * Purpose    : This Procedure is the main procedure                                                            *
-- ****************************************************************************************************************/     

PROCEDURE main( errbuff         OUT   VARCHAR2
              , retcode         OUT   NUMBER
              , p_module        IN    VARCHAR2
              , p_conv_mode     IN    VARCHAR2
              , p_legacy_from   IN    VARCHAR2
              , p_legacy_to     IN    VARCHAR2
              , p_commit_cnt    IN    NUMBER
              , p_debug_flag    IN    VARCHAR2 
   ) IS

    lv_err_msg   VARCHAR2(4000);
    ln_retcode   NUMBER;
    ex_errors    EXCEPTION;
    
    BEGIN    

        ln_retcode        := 0;
        lv_err_msg        := NULL;
        gv_module         := p_module;
        gv_conv_mode      := p_conv_mode;
        gv_legacy_id_from := p_legacy_from; 
		gv_legacy_id_to   := p_legacy_to; 
        gn_commit_cnt     := p_commit_cnt;  
        gv_debug_flag     := p_debug_flag;
        gv_process_flag   := 'S';
        gn_retcode        := 0;
        gv_err_msg        := NULL;
      --
      IF gv_debug_flag = 'YES' THEN
         gn_log_level := 2;
      ELSIF gv_debug_flag = 'NO' THEN
         gn_log_level := 0;
      END IF;
    
        SELECT description
          INTO gv_entity_name
          FROM fnd_lookup_values
         WHERE lookup_type = 'XXAQV_CMN_CONV_MODULE_LKP'
           AND lookup_code = gv_module;
           
       print_debug( 'MAIN: START Attachments Import Process'
                  , gn_log_level   );       
      
      --Delete Common Error Table messages
      lv_err_msg        := 'Delete Error Records from Common Error Logging Table for conversion mode: ' || p_conv_mode;
      print_debug( lv_err_msg
                 , gn_log_level );
      DELETE xxaqv_conv_cmn_utility_stg
       WHERE 1 = 1
         AND process_stage  = gv_conv_mode
         AND staging_table  = gv_staging_table
         AND module_name    = gv_module_name;

      lv_err_msg   := 'No. of Records deleted from Common Error Logging Table: ' || SQL%rowcount;
      print_debug( lv_err_msg
                 , gn_log_level );
      COMMIT;
      
      
    IF gv_conv_mode = 'EXTRACT' 
    THEN
    
        lv_err_msg := 'Truncate Staging table for extract mode';

         print_debug( lv_err_msg
                    , gn_log_level );
         --
         EXECUTE IMMEDIATE 'TRUNCATE TABLE xxaqv.xxaqv_attach_docs_stg';
         -- 

        IF gv_entity_name = 'PO_VENDORS'
            THEN
                supplier_load_staging_data( x_retcode       => ln_retcode
                                          , x_err_msg       => lv_err_msg);
            IF ln_retcode <> 0 THEN
                RAISE ex_errors;
            END IF;
        
        ELSIF gv_entity_name = 'PO_VENDOR_SITES'
            THEN
                sup_sites_load_staging( x_retcode       => ln_retcode
                                      , x_err_msg       => lv_err_msg);
            IF ln_retcode <> 0 THEN
                RAISE ex_errors;
            END IF;
                                           
        ELSIF gv_entity_name = 'AP_INVOICES'
            THEN
                ap_invoice_load_staging_data( x_retcode       => ln_retcode
                                            , x_err_msg       => lv_err_msg );
            IF ln_retcode <> 0 THEN
                RAISE ex_errors;
            END IF;
            
        ELSIF gv_entity_name = 'RA_CUSTOMER_TRX'
            THEN
                ar_inv_load_staging_data( x_retcode       => ln_retcode
                                        , x_err_msg       => lv_err_msg );
            IF ln_retcode <> 0 THEN
                RAISE ex_errors;
            END IF;
        
        ELSIF gv_entity_name = 'AR_CUSTOMERS'
            THEN
                ar_customers_load_staging_data( x_retcode       => ln_retcode
                                              , x_err_msg       => lv_err_msg );
            IF ln_retcode <> 0
            THEN
                RAISE ex_errors;
            END IF;
        END IF;
    
    END IF;
    
    IF gv_conv_mode = 'MAP' 
    THEN
         validate_staging_records( x_retcode       => ln_retcode
                                 , x_err_msg       => lv_err_msg );
         IF ln_retcode <> 0 
         THEN
            RAISE ex_errors;
         END IF;
    END IF;
    
    
   /* IF gv_conv_mode = 'LOAD' 
    THEN
         populate_fnd_lobs ( x_retcode  => ln_retcode
                           , x_err_msg  => lv_err_msg
                           , p_proj_num => gv_legacy_id); 
         IF ln_retcode <> 0 
         THEN
            RAISE ex_errors;
         END IF;
    END IF;*/
    
    IF gv_conv_mode = 'IMPORT' 
    THEN
         import_staging_data ( x_retcode       => ln_retcode
                             , x_err_msg       => lv_err_msg);
    
         IF ln_retcode <> 0 
         THEN
            RAISE ex_errors;
         END IF;
    END IF;
    
     IF gv_conv_mode = 'TIEBACK' 
        THEN
         tie_back_staging ( x_retcode       => ln_retcode
                          , x_err_msg       => lv_err_msg);
         IF ln_retcode <> 0 
         THEN
            RAISE ex_errors;
         END IF;
      END IF;
    
      --invoke report procedure
    
      print_report;
      --
      errbuff  := lv_err_msg;
      retcode  := ln_retcode;
      print_debug( 'MAIN: END Attachments Import Process'
                 , gn_log_level   );
   EXCEPTION
      WHEN ex_errors 
      THEN
         print_debug( 'MAIN: Exception processing Attachments Data ex_errors:' || lv_err_msg
                    , gn_log_level );
         errbuff   := 'MAIN: Exception processing Attachments Data:' || lv_err_msg;
         retcode   := 2;
      WHEN OTHERS 
      THEN
         print_debug( 'MAIN: Exception processing Attachments Data:' || lv_err_msg
                    , gn_log_level );
         errbuff   := 'MAIN: Unexpected Exception processing Attachments Data:' || to_char(sqlcode) || '-' || sqlerrm;
         retcode   := 2;
   END main;
   --
END xxaqv_fnd_attachments_pkg;
/
