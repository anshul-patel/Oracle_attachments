CREATE OR REPLACE PACKAGE xxaqv_fnd_attachments_pkg AS
--/*------------------------------------------------- Arqiva -----------------------------------------------------*
-- ****************************************************************************************************************
-- * Type               : Package Specification                                                                   *
-- * Application Module : Attachments                                                                             *
-- * Packagage Name     : XXAQV_FND_ATTACHMENTS_PKG                                                               *
-- * Script Name        : XXAQV_FND_ATTACHMENTS_PKG.pks                                                           *
-- * Purpose            : This is used to All Attachments related Data.                                           *
-- * Company            : Cognizant Technology Solutions.                                                         *
-- *                                                                                                              *
-- * Change History                                                                                               *
-- * Version     Created By        Creation Date    Comments                                                      *
-- *--------------------------------------------------------------------------------------------------------------*
-- * 1.0         CTS                07/01/2020     Initial Version                                                *
-- ****************************************************************************************************************


--/*****************************************************************************************************************
-- * Function  : validate_category_id                                                                              *
-- * Purpose   : This Function will validate category ID                                                           *
-- ****************************************************************************************************************/	

   FUNCTION validate_category_id ( p_category_name    IN    VARCHAR2
                                 , lv_category_id     OUT   VARCHAR2
                                 , p_error_msg        OUT   VARCHAR2
   ) RETURN VARCHAR2;

--/*****************************************************************************************************************
-- * Function  : validate_datatype_id                                                                              *
-- * Purpose   : This Function will validate payement term                                                         *
-- ****************************************************************************************************************/	

   FUNCTION validate_datatype_id ( p_datatype_name  IN    VARCHAR2
                                 , lv_datatype_id   OUT   VARCHAR2
                                 , p_error_msg      OUT   VARCHAR2
   ) RETURN VARCHAR2;

--/*****************************************************************************************************************
-- * Function  : validate_supplier_pk                                                                              *
-- * Purpose   : This Function will validate PK1_VALUE for supplier                                                *
-- *****************************************************************************************************************/	

   FUNCTION validate_supplier_pk ( p_vendor_name    IN    VARCHAR2
                                 , p_vendor_number  IN    VARCHAR2
                                 , ln_pk1_value     OUT   VARCHAR2
                                 , p_error_msg      OUT   VARCHAR2
   ) RETURN VARCHAR2;

--/*****************************************************************************************************************
-- * Function  : validate_sup_sites_pk                                                                             *
-- * Purpose   : This Function will validate PK1_VALUE for supplier                                                *
-- *****************************************************************************************************************/	

   FUNCTION validate_sup_sites_pk ( p_vendor_number       IN    VARCHAR2
                                  , p_vendor_site_code    IN    VARCHAR2
                                  , ln_pk1_value          OUT   VARCHAR2
                                  , p_error_msg           OUT   VARCHAR2
   ) RETURN VARCHAR2;   
--/****************************************************************************************************************
-- * Procedure  : supplier_load_staging_data                                                                      *
-- * Purpose    : This Procedure is used to load supplier attachment data into staging Table                      *
-- ****************************************************************************************************************/

   PROCEDURE supplier_load_staging_data ( x_retcode       OUT   NUMBER
                                        , x_err_msg       OUT   VARCHAR2  );
                               
--/****************************************************************************************************************
-- * Procedure  : sup_sites_load_staging                                                                *
-- * Purpose    : This Procedure is used to load the supplier site attachment data into staging Table             *
-- ****************************************************************************************************************/

   PROCEDURE sup_sites_load_staging ( x_retcode       OUT   NUMBER
                                    , x_err_msg       OUT   VARCHAR2  );   
--/****************************************************************************************************************
-- * Procedure : validate_staging_records                                                                         *
-- * Purpose   : This Procedure validate the records in the staging table.                                        *
-- ****************************************************************************************************************/	

   PROCEDURE validate_staging_records ( x_retcode       OUT   VARCHAR2
                                      , x_err_msg       OUT   VARCHAR2 )   ;
--/****************************************************************************************************************
-- * Procedure  : IMPORT_STAGING_DATA                                                                             *
-- * Purpose    : This Procedure is used to valdate the data in Staging Table                                     *
-- ****************************************************************************************************************/  

   PROCEDURE import_staging_data ( x_retcode       OUT   NUMBER
                                 , x_err_msg       OUT   VARCHAR2
   );

--/****************************************************************************************************************
-- * Procedure : TIE_BACK_STAGING                                                                                 *
-- * Purpose   : This procedure will tie back base table data to staging table.                                   *
-- ****************************************************************************************************************/

   PROCEDURE tie_back_staging ( x_retcode   OUT   NUMBER
                              , x_err_msg   OUT   VARCHAR2
   );
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
   ) ;
END xxaqv_fnd_attachments_pkg;