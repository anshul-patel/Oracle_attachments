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
-- * 1.0         CTS                21/11/2019     Initial Version                                                *
-- ****************************************************************************************************************

				  
--/****************************************************************************************************************
-- * Procedure  : LOAD_STAGING_DATA                                                                               *
-- * Purpose    : This Procedure is used to load the data into staging Table                                      *
-- ****************************************************************************************************************/

   PROCEDURE load_staging_data ( x_retcode       OUT   NUMBER
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
              , p_attach_type   IN    VARCHAR2
              , p_debug_flag    IN    VARCHAR2
              , p_entity_name   IN    VARCHAR2
   );
END xxaqv_fnd_attachments_pkg;