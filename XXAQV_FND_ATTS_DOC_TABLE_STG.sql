--/*------------------------------------------------- Arqiva -----------------------------------------------------*
-- ****************************************************************************************************************
-- * Type               : Table                                                                                   *
-- * Application Module : Attachments                                                                             *
-- * Table Name         : XXAQV_ATTACH_DOCS_STG                                                                   *
-- * Script Name        : XXAQV_ATTACH_DOCS_STG.sql                                                               *
-- * Purpose            : Create a Table to laod  Attachments Information.                                        *
-- * Company            : Cognizant Technology Solutions.                                                         *
-- *                                                                                                              *
-- * Change History                                                                                               *
-- * Version     Created By        Creation Date    Comments                                                      *
-- *--------------------------------------------------------------------------------------------------------------*
-- * 1.0         CTS               07/01/2020     Initial Version                                                 *
-- ***************************************************************************************************************/
CREATE TABLE xxaqv.xxaqv_attach_docs_stg ( pk1_value                  VARCHAR2(500)
                                         , entity_name                VARCHAR2(40)
                                         , seq_num                    NUMBER        -- Seq Number of Attachments
                                         , title                      VARCHAR2(1000)  -- Attachment Title
                                         , category_name              VARCHAR2(255) -- Category Name
                                         , category_id                NUMBER        -- Category ID
                                         , datatype_id                NUMBER        -- Type of Format
                                         , datatype_name              VARCHAR2(50)
                                         , document_description       VARCHAR2(4000)-- Description of the document
                                         , text                       CLOB          -- It dumps the data that present in Long Text Tables otherwise NUll
                                         , url                        VARCHAR2(4000)-- It dumps the url otherwise Null
                                         , file_name                  VARCHAR2(4000)-- File Name--If File is Present then  dump otherwise we Give Name Based on Entity_name+ext
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
                                         , pk2_value                  VARCHAR2(500)
                                         , pk3_value                  VARCHAR2(500)
                                         , pk4_value                  VARCHAR2(500)
                                         , pk5_value                  VARCHAR2(500)
                                         , vendor_name                VARCHAR2(500)
                                         , vendor_number              VARCHAR2(100)
                                         , vendor_site_code           VARCHAR2(100)
                                         , invoice_number             VARCHAR2(100)
                                         , file_content_type          VARCHAR2(256)
                                         , file_data                  BLOB
                                         , file_format                VARCHAR2(10)
                                         , program_name               VARCHAR2(40)
                                         , program_tag                VARCHAR2(40)
                                         , oracle_charset             VARCHAR2(40)
                                         , file_id                    NUMBER
                                         , upload_date                DATE
                                         , expiration_date            DATE
                                         , language                   VARCHAR2(50)
										 , trx_number                 VARCHAR2(50)
										 , customer_number            VARCHAR2(50)
                                          );

EXEC ad_zd_table.upgrade('XXAQV','XXAQV_ATTACH_DOCS_STG');