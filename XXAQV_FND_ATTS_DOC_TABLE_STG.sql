--/*------------------------------------------------- Arqiva -----------------------------------------------------*
-- ****************************************************************************************************************
-- * Type               : Table                                                                                   *
-- * Application Module : Attachments                                                                             *
-- * Table Name         : XXAQV_FND_ATTS_DOC_TABLE_STG                                                            *
-- * Script Name        : XXAQV_FND_ATTS_DOC_TABLE_STG.sql                                                        *
-- * Purpose            : Create a Table to laod  Attachments Information.                                        *
-- * Company            : Cognizant Technology Solutions.                                                         *
-- *                                                                                                              *
-- * Change History                                                                                               *
-- * Version     Created By        Creation Date    Comments                                                      *
-- *--------------------------------------------------------------------------------------------------------------*
-- * 1.0         CTS               26/11/2019     Initial Version                                                 *
-- ***************************************************************************************************************/
CREATE TABLE xxaqv.xxaqv_fnd_atts_doc_table_stg ( entity_record_identifier   VARCHAR2(500)
                                                , entity_name                VARCHAR2(40)
                                                , seq_num                    NUMBER        -- Seq Number of Attachments
                                                , title                      VARCHAR2(80)  -- Attachment Title
                                                , category                   VARCHAR2(255) -- Category Name
                                                , datatype_id                NUMBER        -- Type of Format
												, datatype_name              VARCHAR2(50)
                                                , document_description       VARCHAR2(1000)-- Description of the document
                                                , text                       LONG          -- It dumps the data that present in Long Text Tables otherwise NUll
                                                , url                        VARCHAR2(4000)-- It dumps the url otherwise Null
                                                , file_name                  VARCHAR2(1000)-- File Name--If File is Present then  dump otherwise we Give Name Based on Entity_name+ext
                                                , record_id                  NUMBER
                                                , creation_date              DATE
                                                , last_update_date           DATE
                                                , last_update_login          NUMBER
                                                , last_updated_by            NUMBER
                                                , created_by                 NUMBER
                                                , processed_flag             VARCHAR2(10)
                                                , error_msg                  VARCHAR2(1000)
                                                , document_id                NUMBER
                                                , media_id                   NUMBER
                                                 );

EXEC ad_zd_table.upgrade('XXAQV','XXAQV_FND_ATTS_DOC_TABLE_STG');