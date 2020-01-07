 create or replace PACKAGE xxaqv_conv_cmn_utility_pkg
AS
--/*------------------------------------------------- Arqiva -----------------------------------------------------*
-- ****************************************************************************************************************
-- * Type               : Package Specification                                                                   *
-- * Application Module : APPS                                                                                    *
-- * Packagage Name     : XXAQV_CONV_CMN_UTILITY_PKG                                                              *
-- * Script Name        : XXAQV_CONV_CMN_UTILITY_PKG.pks                                                          *
-- * Purpose            : This package is to store all the common validation and utility prcedues and function for*
-- *                      Conversion in R12.2.9                                                                   *
-- * Company            : Cognizant Technology Solutions.                                                         *
-- *                                                                                                              *
-- * Change History                                                                                               *
-- * Version     Created By        Creation Date    Comments                                                      *
-- *--------------------------------------------------------------------------------------------------------------*
-- * 1.0         CTS               28/10/2019     Initial Version                                                 *
-- ****************************************************************************************************************

--/****************************************************************************************************************
-- * Data Type : GV_TYPE_VAR                                                                                      *
-- * Purpose   : This table data type is for varchar2 values                                                      *
-- ****************************************************************************************************************/

 TYPE gv_type_var IS TABLE OF VARCHAR2(500) INDEX BY BINARY_INTEGER;

--/****************************************************************************************************************
-- * Data Type : CONV_UTILITY_REC                                                                                 *
-- * Purpose   : This data type is for  error records in conversion program                                       *
-- ****************************************************************************************************************/
 TYPE gt_conv_cmn_utility_typ IS TABLE OF xxaqv.xxaqv_conv_cmn_utility_stg%ROWTYPE
 INDEX BY BINARY_INTEGER;

--/****************************************************************************************************************
-- * Procedure : PRINT_LOGS                                                                                       *
-- * Purpose   : This Procedure will print log messages in the FND LOG and DBMS LOG.                              *
-- ****************************************************************************************************************/
   PROCEDURE print_logs (p_message     IN VARCHAR2
                        ,p_destination IN VARCHAR2 DEFAULT 'L');

--/****************************************************************************************************************
-- * Procedure : PRINT_OUTPUT                                                                                     *
-- * Purpose   : This Procedure will print output messages in the FND OUTPUT.                                     *
-- ****************************************************************************************************************/
   PROCEDURE print_output (p_module_name    IN VARCHAR2
                          ,p_batch_run      IN NUMBER
                          ,p_stage          IN VARCHAR2
                          ,p_staging_table  IN VARCHAR2  DEFAULT NULL);

--/****************************************************************************************************************
-- * Function  : VALIDATE_OPER_UNIT                                                                               *
-- * Purpose   : This function will validate operating unit and return organization id.                           *
-- ****************************************************************************************************************/
   FUNCTION validate_oper_unit ( p_operating_unit IN  VARCHAR2)
   RETURN NUMBER;

--/****************************************************************************************************************
-- * Procedure : VALIDATE_LEDGER                                                                                  *
-- * Purpose   : This procedure will validate the ledger and return coa_id and ledger_id.                         *
-- ****************************************************************************************************************/
   PROCEDURE validate_ledger (p_gl_ledger             IN VARCHAR2
                             ,p_operating_unit        IN VARCHAR2
                             ,x_chart_of_accounts_id  OUT NUMBER
                             ,x_ledger_id             OUT NUMBER);

--/****************************************************************************************************************
-- * Function  : VALIDATE_INV_ORG                                                                                 *
-- * Purpose   : This function will validate item inventory org and return organization id.                       *
-- ****************************************************************************************************************/
   FUNCTION validate_inv_org (p_inventory_org IN  VARCHAR2)
   RETURN NUMBER;

--/****************************************************************************************************************
-- * Procedure  : VALIDATE_CODE_COMB                                                                               *
-- * Purpose    : This procedure will validate the code combination and return code combination id.                *
-- ****************************************************************************************************************/
   PROCEDURE validate_code_comb (p_coa_id                    IN NUMBER
                                ,p_concatenated_segments     IN VARCHAR2
                                ,x_code_combination_id       OUT NUMBER);

--/****************************************************************************************************************
-- * Function  : VALIDATE_PAY_TERMS                                                                               *
-- * Purpose   : This function will validate payment terms and return term id.                                    *
-- ****************************************************************************************************************/
   FUNCTION validate_pay_terms ( p_terms_name IN  VARCHAR2)
   RETURN NUMBER;

--/****************************************************************************************************************
-- * Function  : VALIDATE_RA_PAY_TERMS                                                                            *
-- * Purpose   : This function will validate AR payment terms and return term id.                                 *
-- ****************************************************************************************************************/
   FUNCTION validate_ra_pay_terms (p_ra_terms_name IN  VARCHAR2)
   RETURN NUMBER;

--/****************************************************************************************************************
-- * Function  : VALIDATE_EMP_DETAILS                                                                             *
-- * Purpose   : This Procedure will validate employee name and return the details.                               *
-- ****************************************************************************************************************/
   PROCEDURE validate_emp_details (p_employee_name     IN VARCHAR2
                                  ,x_employee_id       OUT NUMBER
                                  ,x_full_name         OUT VARCHAR2);

--/****************************************************************************************************************
-- * Procedure : CHECK_GL_PERIOD                                                                                  *
-- * Purpose   : This procedure will check if the GL period is open for a particular module.                      *
-- ****************************************************************************************************************/
   PROCEDURE check_gl_period (p_period_name        IN VARCHAR2
                             ,p_period_set_name    IN VARCHAR2
                             ,p_application_id     IN VARCHAR2
                             ,p_sob_id             IN NUMBER
                             ,x_gl_date            OUT DATE
                             ,x_period_status      OUT VARCHAR2);

--/****************************************************************************************************************
-- * Procedure : GET_LOOKUP_VALUE                                                                                 *
-- * Purpose   : This procedure will derive the lookup value for a lookup type.                                   *
-- ****************************************************************************************************************/
   PROCEDURE get_lookup_value (p_lookup_type     IN VARCHAR2
                              ,p_lookup_code     IN VARCHAR2
                              ,x_lookup_value    OUT VARCHAR2);

--/****************************************************************************************************************
-- * Function  : GET_FND_MSG                                                                                      *
-- * Purpose   : This function will derive fnd messaged with token substitution and return the message.           *
-- ****************************************************************************************************************/
   FUNCTION get_fnd_msg(p_msg_code IN VARCHAR2
                       ,p_token1   IN VARCHAR2
                       ,p_token2   IN VARCHAR2
                       ,p_token3   IN VARCHAR2
                       ,p_token4   IN VARCHAR2
                       ,p_token5   IN VARCHAR2)
   RETURN VARCHAR2;

--/****************************************************************************************************************
-- * Procedure : GET_COLUMN_VALUE                                                                                 *
-- * Purpose   : This function will extract individual fields from a line of a .csv file.                         *
-- ****************************************************************************************************************/
   FUNCTION get_column_value (p_data_row   IN VARCHAR2)
   RETURN gv_type_var;

--/****************************************************************************************************************
-- * Procedure : INSERT_ERROR_RECORDS                                                                             *
-- * Purpose   : This procedure will insert error logs into the error logging table.                              *
-- ****************************************************************************************************************/
   PROCEDURE insert_error_records (p_conv_cmn_var IN gt_conv_cmn_utility_typ);

--/****************************************************************************************************************
-- * Procedure : SUBMIT_CONC_PROG                                                                                 *
-- * Purpose   : This procedure will submit concurrent jobs from PLSQL Packages.                                  *
-- ****************************************************************************************************************/
   PROCEDURE submit_conc_prog (p_application IN VARCHAR2
                              ,p_program     IN VARCHAR2
                              ,p_argument1   IN VARCHAR2 DEFAULT CHR (0)
                              ,p_argument2   IN VARCHAR2 DEFAULT CHR (0)
                              ,p_argument3   IN VARCHAR2 DEFAULT CHR (0)
                              ,p_argument4   IN VARCHAR2 DEFAULT CHR (0)
                              ,p_argument5   IN VARCHAR2 DEFAULT CHR (0)
                              ,p_argument6   IN VARCHAR2 DEFAULT CHR (0)
                              ,p_argument7   IN VARCHAR2 DEFAULT CHR (0)
                              ,p_argument8   IN VARCHAR2 DEFAULT CHR (0)
                              ,p_argument9   IN VARCHAR2 DEFAULT CHR (0)
                              ,p_argument10  IN VARCHAR2 DEFAULT CHR (0)
                              ,p_argument11  IN VARCHAR2 DEFAULT CHR (0)
                              ,p_argument12  IN VARCHAR2 DEFAULT CHR (0)
                              ,p_argument13  IN VARCHAR2 DEFAULT CHR (0)
                              ,x_retcode     OUT NUMBER
                              ,x_err_msg     OUT VARCHAR2);

--/****************************************************************************************************************
-- * Function  : GET_TARGET_VALUE                                                                                 *
-- * Purpose   : This function will return target account based on source account.                                *
-- ****************************************************************************************************************/
   FUNCTION get_target_value (p_module_name  IN  VARCHAR2
                             ,p_field_to_map IN  VARCHAR2
                             ,p_src_value    IN  VARCHAR2
                             ,x_error_msg    OUT VARCHAR2)
   RETURN VARCHAR2;

END xxaqv_conv_cmn_utility_pkg;