CREATE OR REPLACE PACKAGE xxaqv_fnd_attachments_pkg AS
--/*------------------------------------------------- Arqiva -----------------------------------------------------*
-- ****************************************************************************************************************
-- * Type               : Package Specification                                                                   *
-- * Application Module : Arqiva Custom Application (xxaqv)                                                       *
-- * Packagage Name     : XXAQV_FND_ATTACHMENTS_PKG                                                               *
-- * Script Name        : XXAQV_FND_ATTACHMENTS_PKG.pks                                                           *
-- * Purpose            : Package for All Attachments related Data.                                               *
-- * Company            : Cognizant Technology Solutions.                                                         *
-- *                                                                                                              *
-- * Change History                                                                                               *
-- * Version     Created By        Creation Date    Comments                                                      *
-- *--------------------------------------------------------------------------------------------------------------*
-- * 1.0         CTS                07/01/2020     Initial Version                                                *
-- ****************************************************************************************************************


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
   );
END xxaqv_fnd_attachments_pkg;
/