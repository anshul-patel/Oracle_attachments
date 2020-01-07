create or replace PACKAGE BODY xxaqv_conv_cmn_utility_pkg
AS
--/*------------------------------------------------- Arqiva -----------------------------------------------------*
-- ****************************************************************************************************************
-- * Type               : Package Body                                                                            *
-- * Application Module : APPS                                                                                    *
-- * Packagage Name     : XXAQV_CONV_CMN_UTILITY_PKG                                                              *
-- * Script Name        : XXAQV_CONV_CMN_UTILITY_PKG.pkb                                                          *
-- * Purpose            : This package is to store all the common validation and utility prcedues and function for*
-- *                      Conversion in R12.2.9                                                                   *
-- * Company            : Cognizant Technology Solutions.                                                         *
-- *                                                                                                              *
-- * Change History                                                                                               *
-- * Version     Created By        Creation Date    Comments                                                      *
-- *--------------------------------------------------------------------------------------------------------------*
-- * 1.0         CTS               28/10/2019     Initial Version                                                 *
-- ****************************************************************************************************************

   gv_debug_flag             VARCHAR2(10);
   gn_request_id             NUMBER           := apps.fnd_profile.VALUE ('CONC_REQUEST_ID');
   gn_user_id                NUMBER           := fnd_global.USER_ID;
   gn_login_id               NUMBER           := fnd_global.LOGIN_ID;

--/****************************************************************************************************************
-- * Procedure : print_logs                                                                                        *
-- * Purpose   : This procedure will print log messages in the FND LOG and DBMS LOG.                              *
-- ****************************************************************************************************************/
   PROCEDURE print_logs (p_message IN VARCHAR2
                        ,p_destination IN VARCHAR2 DEFAULT 'L')
   IS
   BEGIN
        IF p_destination = 'L'
           THEN
               IF NVL (fnd_global.conc_request_id, -1) < 1
                 THEN
                     DBMS_OUTPUT.put_line (p_message);
                 ELSE
                     fnd_file.put_line (fnd_file.log, p_message);
               END IF;
           ELSIF p_destination = 'O'
               THEN
                   IF NVL (fnd_global.conc_request_id, -1) < 1
                   THEN
                       DBMS_OUTPUT.put_line (p_message);
                   ELSE
                       fnd_file.put_line (fnd_file.output, p_message);
                   END IF;
        END IF;
   EXCEPTION
   WHEN OTHERS
   THEN
       fnd_file.put_line (fnd_file.LOG, 'Error occured in common utility package XXAQV_CONV_CMN_UTILITY_PKG.PRINT_LOGS');
   END print_logs;

--/****************************************************************************************************************
-- * Procedure : PRINT_OUTPUT                                                                                     *
-- * Purpose   : This procedure will print output messages in the FND OUTPUT.                                     *
-- ****************************************************************************************************************/
   PROCEDURE print_output (p_module_name    IN VARCHAR2
                          ,p_batch_run      IN NUMBER
                          ,p_stage          IN VARCHAR2
                          ,p_staging_table  IN VARCHAR2  DEFAULT NULL)
   IS
     ln_error_count   NUMBER := 0;
     ln_total_count   NUMBER := 0;
     ln_success_count NUMBER := 0;

     CURSOR cur_errors
     IS
       SELECT xccus.*
         FROM xxaqv_conv_cmn_utility_stg      xccus
        WHERE xccus.module_name               = p_module_name
          AND xccus.staging_table             = NVL(p_staging_table, xccus.staging_table)
          AND xccus.process_flag              = 'ERROR'
          AND xccus.process_stage             = p_stage
          AND xccus.batch_run                 = p_batch_run;

   BEGIN
        SELECT COUNT(1)
          INTO ln_error_count
          FROM xxaqv_conv_cmn_utility_stg      xccus
         WHERE xccus.module_name               = p_module_name
          AND xccus.staging_table             = NVL(p_staging_table, xccus.staging_table)
           AND xccus.process_flag              = 'ERROR'
           AND xccus.process_stage             = p_stage
           AND xccus.batch_run                 = p_batch_run;

        print_logs('*************** Error Report ***************', 'O');
        print_logs('', 'O');
        print_logs(RPAD('Date:', 30) || RPAD(sysdate, 30), 'O');
        print_logs(RPAD('Package Name:', 30) || RPAD(p_module_name, 30), 'O');
        print_logs(RPAD('Conversion Stage:', 30) || RPAD(p_stage, 30), 'O');
        print_logs(RPAD('Batch Total Error Count:', 30) || RPAD(ln_error_count, 30), 'O');
        print_logs('', 'O');

        print_logs('***************************************************************************', 'O');
        print_logs('', 'O');
        print_logs(RPAD('MODULE_NAME', 30) || RPAD('STAGING_TABLE', 30) || RPAD('BATCH_RUN', 20) || RPAD('PROCESS_STAGE', 30)  || RPAD('PROCESS_FLAG', 30)
                  || RPAD('ERROR_MESSAGE', 3000), 'O' );

        FOR indx IN cur_errors
        LOOP
            print_logs(RPAD(indx.module_name, 30) || RPAD(indx.staging_table, 30) || RPAD(indx.batch_run, 20) || RPAD(indx.process_stage, 30)
                       || RPAD(indx.process_flag, 30) || RPAD(indx.error_message, 30000), 'O' );
        END LOOP;

   EXCEPTION
   WHEN OTHERS
   THEN
       fnd_file.put_line (fnd_file.LOG, 'Error occured in common utility package XXAQV_CONV_CMN_UTILITY_PKG.PRINT_OUTPUT');
   END print_output;

--/****************************************************************************************************************
-- * Function  : VALIDATE_OPER_UNIT                                                                               *
-- * Purpose   : This function will validate operating unit and return organization id.                           *
-- ****************************************************************************************************************/
   FUNCTION validate_oper_unit (p_operating_unit IN  VARCHAR2)
   RETURN NUMBER
   IS
     ln_org_id NUMBER;
   BEGIN
        SELECT hou.organization_id
          INTO ln_org_id
          FROM apps.hr_operating_units  hou
         WHERE hou.name                 = p_operating_unit;
         --  AND hou.short_code           = 'AQV';

         RETURN ln_org_id;
   EXCEPTION
   WHEN OTHERS
   THEN
       print_logs ('VALIDATE_OPER_UNIT: Unexpected error while Validating operating unit.  ' || TO_CHAR (SQLCODE) || '-' || SQLERRM);
       ln_org_id := 0;
       RETURN ln_org_id;
   END validate_oper_unit;

--/****************************************************************************************************************
-- * Procedure : VALIDATE_LEDGER                                                                                  *
-- * Purpose   : This procedure will validate the ledger and return coa_id and ledger_id.                         *
-- ****************************************************************************************************************/
   PROCEDURE validate_ledger (p_gl_ledger             IN VARCHAR2
                             ,p_operating_unit        IN VARCHAR2
                             ,x_chart_of_accounts_id  OUT NUMBER
                             ,x_ledger_id             OUT NUMBER)
   IS
   BEGIN
        SELECT gl.ledger_id
             , gl.chart_of_accounts_id
          INTO x_ledger_id
             , x_chart_of_accounts_id
          FROM apps.hr_operating_units   hou
             , apps.gl_ledgers           gl
         WHERE hou.set_of_books_id       = gl.ledger_id
           AND hou.name                  = p_operating_unit;
		   dbms_output.put_line('');
   EXCEPTION
   WHEN OTHERS
   THEN
       print_logs ('VALIDATE_LEDGER: Unexpected error while Validating GL Ledger. ' || TO_CHAR (SQLCODE) || '-' || SQLERRM);
   END validate_ledger;

--/****************************************************************************************************************
-- * Function  : VALIDATE_INV_ORG                                                                                 *
-- * Purpose   : This function will validate item inventory org and return organization id.                       *
-- ****************************************************************************************************************/
   FUNCTION validate_inv_org (p_inventory_org IN  VARCHAR2)
   RETURN NUMBER
   IS
     ln_inv_org_id NUMBER;
   BEGIN
        SELECT ood.organization_id
          INTO ln_inv_org_id
          FROM hr_operating_units hou
             , org_organization_definitions ood
         WHERE hou.organization_id = ood.operating_unit
           AND ood.organization_code = p_inventory_org;

        RETURN ln_inv_org_id;
   EXCEPTION
   WHEN OTHERS
   THEN
       print_logs ('VALIDATE_INV_ORG: Unexpected error while validating inventory operating unit.  ' || TO_CHAR (SQLCODE) || '-' || SQLERRM);
       ln_inv_org_id := 0;
       RETURN ln_inv_org_id;
   END validate_inv_org;

--/****************************************************************************************************************
-- * Procedure  : VALIDATE_CODE_COMB                                                                               *
-- * Purpose    : This procedure will validate the code combination and return code combination id.                *
-- ****************************************************************************************************************/
   PROCEDURE validate_code_comb (p_coa_id                    IN NUMBER
                                ,p_concatenated_segments     IN VARCHAR2
                                ,x_code_combination_id       OUT NUMBER)
   IS
   BEGIN
        x_code_combination_id := fnd_flex_ext.get_ccid ( application_short_name  => 'SQLGL'
                                                       , key_flex_code           => 'GL#'
                                                       , structure_number        => p_coa_id
                                                       , validation_date         => SYSDATE
                                                       , concatenated_segments   => p_concatenated_segments);
   EXCEPTION
   WHEN OTHERS
   THEN
       print_logs ('VALIDATE_CODE_COMB: Unexpected error while validating Code Combinations. ' || TO_CHAR (SQLCODE) || '-' || SQLERRM);
   END validate_code_comb;

--/****************************************************************************************************************
-- * Function  : VALIDATE_PAY_TERMS                                                                               *
-- * Purpose   : This function will validate payment terms and return term id.                                    *
-- ****************************************************************************************************************/
   FUNCTION validate_pay_terms (p_terms_name IN  VARCHAR2)
   RETURN NUMBER
   IS
     ln_term_id NUMBER;
   BEGIN
        SELECT ate.term_id
          INTO ln_term_id
          FROM apps.ap_terms   ate
          WHERE ate.name       = p_terms_name
            AND TRUNC(SYSDATE) BETWEEN NVL(ATE.start_date_active , TRUNC(SYSDATE) - 1)
                                   AND NVL(ATE.end_date_active, TRUNC(SYSDATE) + 1);

         RETURN ln_term_id;
   EXCEPTION
   WHEN OTHERS
   THEN
       print_logs ('VALIDATE_PAY_TERMS: Unexpected error while validating payment terms.  ' || TO_CHAR (SQLCODE) || '-' || SQLERRM);
       ln_term_id := 0;
       RETURN ln_term_id;
   END validate_pay_terms;

--/****************************************************************************************************************
-- * Function  : VALIDATE_RA_PAY_TERMS                                                                               *
-- * Purpose   : This function will validate AR payment terms and return term id.                                    *
-- ****************************************************************************************************************/
   FUNCTION validate_ra_pay_terms (p_ra_terms_name IN  VARCHAR2)
   RETURN NUMBER
   IS
     ln_ra_term_id NUMBER;
   BEGIN
        SELECT ate.term_id
          INTO ln_ra_term_id
          FROM apps.ra_terms   ate
          WHERE ate.name       = p_ra_terms_name
            AND TRUNC(SYSDATE) BETWEEN NVL(ATE.start_date_active , TRUNC(SYSDATE) - 1)
                                   AND NVL(ATE.end_date_active, TRUNC(SYSDATE) + 1);
         RETURN ln_ra_term_id;
   EXCEPTION
   WHEN OTHERS
   THEN
       print_logs ('VALIDATE_PAY_TERMS: Unexpected error while validating payment terms.  ' || TO_CHAR (SQLCODE) || '-' || SQLERRM);
       ln_ra_term_id := 0;
       RETURN ln_ra_term_id;
   END validate_ra_pay_terms;

--/****************************************************************************************************************
-- * Function  : VALIDATE_EMP_DETAILS                                                                             *
-- * Purpose   : This procedure will validate employee name and return the details.                               *
-- ****************************************************************************************************************/
   PROCEDURE validate_emp_details (p_employee_name     IN VARCHAR2
                                  ,x_employee_id       OUT NUMBER
                                  ,x_full_name         OUT VARCHAR2)
   IS
   BEGIN
        SELECT papf.person_id
             , papf.full_name
          INTO x_employee_id
             , x_full_name
          FROM per_all_people_f      papf
         WHERE TRUNC (SYSDATE)       BETWEEN TRUNC (NVL (papf.effective_start_date, SYSDATE))
                                         AND TRUNC (NVL (papf.effective_end_date, SYSDATE))
           AND UPPER(papf.full_name) = UPPER(p_employee_name);
   EXCEPTION
   WHEN OTHERS
   THEN
       print_logs ('VALIDATE_EMP_DETAILS: Unexpected error while validating payment terms.  ' || TO_CHAR (SQLCODE) || '-' || SQLERRM);
   END validate_emp_details;

--/****************************************************************************************************************
-- * Procedure : CHECK_GL_PERIOD                                                                                  *
-- * Purpose   : This procedure will check if the GL period is open for a particular module.                      *
-- ****************************************************************************************************************/
   PROCEDURE check_gl_period (p_period_name        IN VARCHAR2
                             ,p_period_set_name    IN VARCHAR2
                             ,p_application_id     IN VARCHAR2
                             ,p_sob_id             IN NUMBER
                             ,x_gl_date            OUT DATE
                             ,x_period_status      OUT VARCHAR2)
   IS
   BEGIN
        SELECT gp.end_date
          INTO x_gl_date
          FROM apps.gl_periods    gp
         WHERE gp.period_set_name = p_period_set_name
           AND gp.period_name     = (TO_CHAR(TO_DATE(p_period_name, 'MONTH-YYYY'), 'MON-YY'));

        SELECT DECODE (gps.closing_status
                       , 'O', 'Open'
                       , 'C', 'Closed'
                       , 'F', 'Future'
                       , 'N', 'Never'
                       , gps.closing_status) period_status
           INTO x_period_status
           FROM gl_period_statuses      gps
          WHERE gps.application_id      = p_application_id
            AND UPPER (gps.period_name) = UPPER (p_period_name)
            AND gps.set_of_books_id     = p_sob_id;
   EXCEPTION
   WHEN OTHERS
   THEN
       print_logs ('CHECK_GL_PERIOD: Unexpected error while fetching lookup values.  ' || TO_CHAR (SQLCODE) || '-' || SQLERRM);
   END check_gl_period;

--/****************************************************************************************************************
-- * Procedure : GET_LOOKUP_VALUE                                                                                 *
-- * Purpose   : This procedure will derive the lookup value for a lookup type.                                   *
-- ****************************************************************************************************************/
   PROCEDURE get_lookup_value (p_lookup_type     IN VARCHAR2
                              ,p_lookup_code     IN VARCHAR2
                              ,x_lookup_value    OUT VARCHAR2)
   IS
   BEGIN
        SELECT flv.meaning
          INTO x_lookup_value
          FROM fnd_lookup_values   flv
         WHERE flv.lookup_type     = p_lookup_type
           AND flv.lookup_code     = p_lookup_code
           AND TRUNC(SYSDATE)      BETWEEN NVL(TRUNC(flv.start_date_active), TRUNC(SYSDATE))
                                       AND NVL(TRUNC(flv.end_date_active), TRUNC(SYSDATE))
           AND enabled_flag        = 'Y';
   EXCEPTION
   WHEN OTHERS
   THEN
       print_logs ('GET_LOOKUP_VALUE: Unexpected error while fetching lookup values.  ' || TO_CHAR (SQLCODE) || '-' || SQLERRM);
   END get_lookup_value;

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
   RETURN VARCHAR2
   IS
   BEGIN
        fnd_message.clear;
        fnd_message.set_name ('XXAQV', p_msg_code);
        fnd_message.set_token('X_TOKEN1', p_token1);
        fnd_message.set_token('X_TOKEN2', p_token2);
        fnd_message.set_token('X_TOKEN3', p_token3);
        fnd_message.set_token('X_TOKEN4', p_token4);
        fnd_message.set_token('X_TOKEN5', p_token5);

        RETURN fnd_message.get;
   EXCEPTION
   WHEN OTHERS
   THEN
       print_logs ('GET_FND_MSG: Unexpected error while fetching fnd messages.  ' || TO_CHAR (SQLCODE) || '-' || SQLERRM);
       RETURN NULL;
   END get_fnd_msg;

--/****************************************************************************************************************
-- * Procedure : GET_COLUMN_VALUE                                                                                 *
-- * Purpose   : This procedure will extract individual fields from a line of a .csv file.                         *
-- ****************************************************************************************************************/
   FUNCTION get_column_value (p_data_row         IN VARCHAR2)
   RETURN gv_type_var
   IS
     lv_var gv_type_var;
   BEGIN
        SELECT regexp_substr(p_data_row , '[^,]+', 1, level)  BULK COLLECT into lv_var
          FROM dual
        CONNECT BY LEVEL <= GREATEST(COALESCE(regexp_count(p_data_row , ',') + 1, 0));

        RETURN lv_var;
   EXCEPTION
   WHEN OTHERS
   THEN
       fnd_file.put_line (fnd_file.LOG, 'Error occured in common utility package XXAQV_CONV_CMN_UTILITY_PKG.GET_COLUMN_VALUE');
   END get_column_value;

--/****************************************************************************************************************
-- * Procedure : INSERT_ERROR_RECORDS                                                                             *
-- * Purpose   : This procedure will insert error logs into the error logging table.                              *
-- ****************************************************************************************************************/
   PROCEDURE insert_error_records (p_conv_cmn_var IN gt_conv_cmn_utility_typ)
   IS
   BEGIN
        FOR i IN p_conv_cmn_var.FIRST..p_conv_cmn_var.LAST
        LOOP
        INSERT INTO xxaqv.xxaqv_conv_cmn_utility_stg (record_id
                                                     ,module_name
                                                     ,staging_table
                                                     ,batch_run
                                                     ,error_column
                                                     ,error_message
                                                     ,process_flag
                                                     ,process_stage
                                                     ,creation_date
                                                     ,last_update_date
                                                     ,last_update_login
                                                     ,last_updated_by
                                                     ,created_by) VALUES (xxaqv_conv_cmn_utility_s.NEXTVAL
                                                                         ,p_conv_cmn_var(i).module_name
                                                                         ,p_conv_cmn_var(i).staging_table
                                                                         ,p_conv_cmn_var(i).batch_run
                                                                         ,p_conv_cmn_var(i).error_column
                                                                         ,p_conv_cmn_var(i).error_message
                                                                         ,p_conv_cmn_var(i).process_flag
                                                                         ,p_conv_cmn_var(i).process_stage
                                                                         ,SYSDATE
                                                                         ,SYSDATE
                                                                         ,gn_login_id
                                                                         ,gn_user_id
                                                                         ,gn_user_id);
        END LOOP;
        COMMIT;
   EXCEPTION
   WHEN OTHERS
   THEN
       print_logs ('INSERT_ERROR_RECORDS: Unexpected error while inserting error records.  ' || TO_CHAR (SQLCODE) || '-' || SQLERRM);
   END insert_error_records;

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
                              ,x_err_msg     OUT VARCHAR2)
   IS
     ln_request_id          NUMBER;
     lb_child_request_wait  BOOLEAN;
     lv_phase               VARCHAR2(100);
     lv_status              VARCHAR2(30);
     lv_dev_phase           VARCHAR2(100);
     lv_dev_status          VARCHAR2(100);
     lv_message             VARCHAR2(50);
   BEGIN
        ln_request_id := FND_REQUEST.SUBMIT_REQUEST (application      => p_application
                                                    ,program          => p_program
                                                    ,description      => NULL
                                                    ,start_time       => SYSDATE
                                                    ,sub_request      => FALSE
                                                    ,argument1        => p_argument1
                                                    ,argument2        => p_argument2
                                                    ,argument3        => p_argument3
                                                    ,argument4        => p_argument4
                                                    ,argument5        => p_argument5
                                                    ,argument6        => p_argument6
                                                    ,argument7        => p_argument7
                                                    ,argument8        => p_argument8
                                                    ,argument9        => p_argument9
                                                    ,argument10       => p_argument10
                                                    ,argument11       => p_argument11
                                                    ,argument12       => p_argument12
                                                    ,argument13       => p_argument13);
        COMMIT;
        IF ln_request_id = 0 OR ln_request_id IS NULL
        THEN
            x_retcode := 1;
            x_err_msg := 'Concurrent request failed to submit' || p_program || ' - request failed to launch :' || fnd_message.get;
            print_logs('SUBMIT_CONC_PROG: ' || x_err_msg);
        ELSE
            print_logs ('SUBMIT_CONC_PROG: Successfully Submitted the Concurrent Request: ' || ln_request_id);
        END IF;

        IF ln_request_id > 0
        THEN
            LOOP
                lb_child_request_wait := FND_CONCURRENT.WAIT_FOR_REQUEST (request_id  =>  ln_request_id
                                                                         ,INTERVAL    =>  2
                                                                         ,phase       =>  lv_phase
                                                                         ,status      =>  lv_status
                                                                         ,dev_phase   =>  lv_dev_phase
                                                                         ,dev_status  =>  lv_dev_status
                                                                         ,message     =>  lv_message);

                EXIT WHEN UPPER (lv_phase) = 'COMPLETED' OR UPPER (lv_status) IN ('CANCELLED', 'ERROR', 'TERMINATED');
            END LOOP;

            IF UPPER (lv_phase) = 'COMPLETED' AND UPPER (lv_status) = 'ERROR'
            THEN
                x_retcode := 1;
                x_err_msg := 'SUBMIT_CONC_PROG: Concurrent request completed in error. Oracle request id: '||ln_request_id ||' '||SQLERRM;
            ELSIF UPPER (lv_phase) = 'COMPLETED' AND UPPER (lv_status) = 'NORMAL'
            THEN
                x_retcode := 0;
                x_err_msg := NULL;
            ELSE
                x_retcode := 1;
                x_err_msg := 'SUBMIT_CONC_PROG: Concurrent request completed in error. Oracle request id: '||ln_request_id ||' '||SQLERRM;
            END IF;
        END IF;
        COMMIT;
   EXCEPTION
   WHEN OTHERS
   THEN
       x_retcode := 1;
       x_err_msg := 'SUBMIT_CONC_PROG: Unexpected error while submitting concurrent request ' || TO_CHAR (SQLCODE) || '-' || SQLERRM;
   END submit_conc_prog;

--/****************************************************************************************************************
-- * Procedure : GET_TARGET_VALUE                                                                                 *
-- * Purpose   : This function will return target account based on source account.                                 *
-- ****************************************************************************************************************/
   FUNCTION get_target_value (p_module_name  IN  VARCHAR2
                             ,p_field_to_map IN  VARCHAR2
                             ,p_src_value    IN  VARCHAR2
                             ,x_error_msg    OUT VARCHAR2)
   RETURN VARCHAR2
   IS
     lv_trgt_val VARCHAR2 (4000) := NULL;
   BEGIN
        print_logs('Module Name : '|| p_module_name);
        print_logs('Field To Map: '|| p_field_to_map);
        print_logs('Source Value: '|| p_src_value);

        SELECT target_value
          INTO lv_trgt_val
          FROM xxaqv_common_mapping_table
         WHERE 1 = 1
		   AND enabled_flag = 'Y'
		   AND UPPER (module_name)  = UPPER (p_module_name)
           AND UPPER (field_to_map) = UPPER (p_field_to_map)
           AND UPPER (source_value) = UPPER (p_src_value);

        print_logs('Target Value: '|| lv_trgt_val);

        x_error_msg := NULL;
        RETURN lv_trgt_val;
   EXCEPTION
   WHEN NO_DATA_FOUND
   THEN
       x_error_msg := p_field_to_map || '-' || p_src_value || ' :Target value is not mapped';
       RETURN NULL;
   WHEN OTHERS
   THEN
       x_error_msg := 'GET_TARGET_VALUE - Unexpected error: ' || SQLERRM;
       RETURN NULL;
   END get_target_value;
--
END xxaqv_conv_cmn_utility_pkg;