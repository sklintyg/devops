USE intygstjanst;
DELIMITER $$
CREATE PROCEDURE delete_certificate_in_all_databases()
BEGIN
    DECLARE errorCode CHAR(5) DEFAULT '00000';
    DECLARE errorMessage TEXT;
    DECLARE csCertKey BIGINT;
    DECLARE certIdToDelete VARCHAR(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '<certificate_id>';
    DECLARE certIdToDeleteCS VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT '<certificate_id>';

    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
    GET DIAGNOSTICS CONDITION 1
        errorCode = RETURNED_SQLSTATE, errorMessage = MESSAGE_TEXT;
    END;


    START TRANSACTION;
    SET SQL_SAFE_UPDATES = 0;
    SET FOREIGN_KEY_CHECKS = 0;


    -- ******** DELETING FROM INTYGSTJANST DATABASE ********
    DELETE FROM intygstjanst.RELATION WHERE FROM_INTYG_ID = certIdToDelete;
    DELETE FROM intygstjanst.RELATION WHERE TO_INTYG_ID = certIdToDelete;
    DELETE FROM intygstjanst.ARENDE WHERE INTYGS_ID = certIdToDelete;
    DELETE FROM intygstjanst.APPROVED_RECEIVER WHERE CERTIFICATE_ID = certIdToDelete;
    DELETE FROM intygstjanst.SJUKFALL_CERT WHERE ID = certIdToDelete;
    DELETE FROM intygstjanst.SJUKFALL_CERT_WORK_CAPACITY WHERE CERTIFICATE_ID = certIdToDelete;
    DELETE FROM intygstjanst.CERTIFICATE_METADATA WHERE CERTIFICATE_ID = certIdToDelete;
    DELETE FROM intygstjanst.CERTIFICATE_STATE WHERE CERTIFICATE_ID = certIdToDelete;
    DELETE FROM intygstjanst.ORIGINAL_CERTIFICATE WHERE CERTIFICATE_ID = certIdToDelete;
    DELETE FROM intygstjanst.CERTIFICATE WHERE ID = certIdToDelete;


    -- ******** DELETING FROM INTYGSADMIN DATABASE ********
    DELETE FROM intygsadmin.intyg_info WHERE intyg_id = certIdToDelete;


    -- ******** DELETING FROM STATISTIK DATABASE ********
    -- Create temporary table to store statistik.meddelandehandelse correlationId
    CREATE TEMPORARY TABLE STATISTIK_MESSAGE_KEYS (
                    S_M_KEY BIGINT NOT NULL COLLATE utf8mb3_general_ci,
                    PRIMARY KEY (S_M_KEY));
    INSERT INTO STATISTIK_MESSAGE_KEYS (S_M_KEY) SELECT meddelandeId FROM statistik.messagewideline WHERE intygid = certIdToDelete;

    DELETE FROM statistik.intyghandelse WHERE CORRELATIONID = certIdToDelete;
    DELETE FROM statistik.intygsenthandelse WHERE CORRELATIONID = certIdToDelete;
    DELETE FROM statistik.intygcommon WHERE INTYGID = certIdToDelete;
    DELETE FROM statistik.messagewideline WHERE intygid = certIdToDelete;
    DELETE FROM statistik.wideline WHERE correlationId = certIdToDelete;
    DELETE FROM statistik.meddelandehandelse WHERE correlationId IN (SELECT S_M_KEY FROM STATISTIK_MESSAGE_KEYS);
    DELETE FROM statistik.hsa WHERE id = certIdToDelete;


    -- ******** DELETING FROM WEBCERT DATABASE ********
    -- Create temporary table to store webcert.HANDELSE INTYGS_ID
    CREATE TEMPORARY TABLE WEBCERT_HANDELSE_IDS (
                        H_ID BIGINT NOT NULL COLLATE utf8mb3_general_ci,
                        PRIMARY KEY (H_ID));
    INSERT INTO WEBCERT_HANDELSE_IDS (H_ID) SELECT ID FROM webcert.HANDELSE WHERE INTYGS_ID = certIdToDelete;

    -- Create temporary table to store webcert.ARENDE ARENDE_ID
    CREATE TEMPORARY TABLE WEBCERT_ARENDE_IDS (
                    A_ID BIGINT NOT NULL COLLATE utf8mb3_general_ci,
                    PRIMARY KEY (A_ID));
    INSERT INTO WEBCERT_ARENDE_IDS (A_ID) SELECT ID FROM webcert.ARENDE WHERE INTYGS_ID = certIdToDelete;

    -- Create temporary table to store webcert.FRAGASVAR internReferens
    CREATE TEMPORARY TABLE WEBCERT_FRAGASVAR_REFS (
                    F_REF BIGINT NOT NULL COLLATE utf8mb3_general_ci,
                    PRIMARY KEY (F_REF));
    INSERT INTO WEBCERT_FRAGASVAR_REFS (F_REF) SELECT internReferens FROM webcert.FRAGASVAR WHERE INTYGS_ID = certIdToDelete;



    DELETE FROM webcert.CERTIFICATE_EVENT WHERE CERTIFICATE_ID = certIdToDelete;
    DELETE FROM webcert.NOTIFICATION_REDELIVERY WHERE HANDELSE_ID IN (SELECT H_ID FROM WEBCERT_HANDELSE_IDS);
    DELETE FROM webcert.HANDELSE_METADATA WHERE HANDELSE_ID IN (SELECT H_ID FROM WEBCERT_HANDELSE_IDS);
    DELETE FROM webcert.HANDELSE WHERE INTYGS_ID = certIdToDelete;
    DELETE FROM webcert.SIGNATUR WHERE INTYG_ID = certIdToDelete;
    DELETE FROM webcert.REFERENS WHERE INTYG_ID = certIdToDelete;
    DELETE FROM webcert.PAGAENDE_SIGNERING WHERE INTYG_ID = certIdToDelete;
    DELETE FROM webcert.ARENDE_KONTAKT_INFO WHERE ARENDE_ID IN (SELECT A_ID FROM WEBCERT_ARENDE_IDS);
    DELETE FROM webcert.MEDICINSKT_ARENDE WHERE ARENDE_ID IN (SELECT A_ID FROM WEBCERT_ARENDE_IDS);
    DELETE FROM webcert.ARENDE WHERE INTYGS_ID = certIdToDelete;
    DELETE FROM webcert.ARENDE_UTKAST WHERE INTYGS_ID = certIdToDelete;
    DELETE FROM webcert.CERTIFICATE_EVENT_FAILED_LOAD WHERE CERTIFICATE_ID = certIdToDelete;
    DELETE FROM webcert.CERTIFICATE_EVENT_PROCESSED WHERE CERTIFICATE_ID = certIdToDelete;
    DELETE FROM webcert.KOMPLETTERING WHERE FRAGASVAR_ID IN (SELECT F_REF FROM WEBCERT_FRAGASVAR_REFS);
    DELETE FROM webcert.EXTERNA_KONTAKTER WHERE FRAGASVAR_ID IN (SELECT F_REF FROM WEBCERT_FRAGASVAR_REFS);
    DELETE FROM webcert.FRAGASVAR WHERE INTYGS_ID = certIdToDelete;
    DELETE FROM webcert.INTYG WHERE INTYGS_ID = certIdToDelete;



    -- ******** DELETING FROM CERTIFICATE-SERVICE DATABASE ********
    -- Insert cs certificate key into variable
    SELECT `KEY` INTO csCertKey FROM certificate_service.certificate WHERE CERTIFICATE_ID = certIdToDeleteCS;

    -- Create temporary table to store Certificate-service message keys
    CREATE TEMPORARY TABLE CS_MESSAGE_KEYS (
                    CS_M_KEY BIGINT NOT NULL COLLATE utf8mb4_0900_ai_ci,
                    PRIMARY KEY (CS_M_KEY)
                );
    -- Insert message keys into the temporary table
    INSERT INTO CS_MESSAGE_KEYS (CS_M_KEY) SELECT `KEY` FROM certificate_service.message WHERE certificate_key = csCertKey;

    DELETE FROM certificate_service.message_complement WHERE MESSAGE_KEY IN (SELECT CS_M_KEY FROM CS_MESSAGE_KEYS);
    DELETE FROM certificate_service.message_contact_info WHERE MESSAGE_KEY IN (SELECT CS_M_KEY FROM CS_MESSAGE_KEYS);
    DELETE FROM certificate_service.message_relation WHERE PARENT_MESSAGE_KEY IN (SELECT CS_M_KEY FROM CS_MESSAGE_KEYS);
    DELETE FROM certificate_service.message_relation WHERE CHILD_MESSAGE_KEY IN (SELECT CS_M_KEY FROM CS_MESSAGE_KEYS);
    DELETE FROM certificate_service.message WHERE CERTIFICATE_KEY = csCertKey;

    DELETE FROM certificate_service.certificate_xml WHERE `KEY` = csCertKey;
    DELETE FROM certificate_service.certificate_relation WHERE PARENT_CERTIFICATE_KEY = csCertKey;
    DELETE FROM certificate_service.certificate_relation WHERE CHILD_CERTIFICATE_KEY = csCertKey;
    DELETE FROM certificate_service.certificate_data WHERE `KEY` = csCertKey;
    DELETE FROM certificate_service.external_reference WHERE `KEY` = csCertKey;
    DELETE FROM certificate_service.certificate WHERE CERTIFICATE_ID = certIdToDeleteCS;

    DROP TEMPORARY TABLE CS_MESSAGE_KEYS;
    DROP TEMPORARY TABLE STATISTIK_MESSAGE_KEYS;
    DROP TEMPORARY TABLE WEBCERT_HANDELSE_IDS;
    DROP TEMPORARY TABLE WEBCERT_ARENDE_IDS;
    DROP TEMPORARY TABLE WEBCERT_FRAGASVAR_REFS;

    SET SQL_SAFE_UPDATES = 1;
    SET FOREIGN_KEY_CHECKS = 1;

    IF errorCode = '00000' THEN
        COMMIT;
    SELECT CONCAT('Successfully deleted certificate with id = ', certIdToDelete, ' in all databases.') AS result_message;
    ELSE
        ROLLBACK;
        SELECT CONCAT('Stored procedure failed, no changes were introduced, errorCode = ', errorCode, ', errorMessage = ', errorMessage) AS result_message;
    END IF;
END $$
DELIMITER ;
CALL delete_certificate_in_all_databases;
DROP PROCEDURE delete_certificate_in_all_databases;