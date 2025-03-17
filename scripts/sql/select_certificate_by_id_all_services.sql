USE intygstjanst_environment;
DELIMITER $$
CREATE PROCEDURE select_certificate_by_id_all_services()
BEGIN
    DECLARE errorCode CHAR(5) DEFAULT '00000';
    DECLARE errorMessage TEXT;
    DECLARE csCertKey BIGINT;
    DECLARE certIdToDelete VARCHAR(255) DEFAULT '<certificate_id>';

    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
    GET DIAGNOSTICS CONDITION 1
        errorCode = RETURNED_SQLSTATE, errorMessage = MESSAGE_TEXT;
    END;


    START TRANSACTION;
    SET SQL_SAFE_UPDATES = 0;
    SET FOREIGN_KEY_CHECKS = 0;


    -- ******** DELETING FROM INTYGSTJANST DATABASE ********
    SELECT * FROM intygstjanst_environment.RELATION WHERE FROM_INTYG_ID = certIdToDelete;
    SELECT * FROM intygstjanst_environment.RELATION WHERE TO_INTYG_ID = certIdToDelete;
    SELECT * FROM intygstjanst_environment.ARENDE WHERE INTYGS_ID = certIdToDelete;
    SELECT * FROM intygstjanst_environment.APPROVED_RECEIVER WHERE CERTIFICATE_ID = certIdToDelete;
    SELECT * FROM intygstjanst_environment.SJUKFALL_CERT WHERE ID = certIdToDelete;
    SELECT * FROM intygstjanst_environment.SJUKFALL_CERT_WORK_CAPACITY WHERE CERTIFICATE_ID = certIdToDelete;
    SELECT * FROM intygstjanst_environment.CERTIFICATE_METADATA WHERE CERTIFICATE_ID = certIdToDelete;
    SELECT * FROM intygstjanst_environment.CERTIFICATE_STATE WHERE CERTIFICATE_ID = certIdToDelete;
    SELECT * FROM intygstjanst_environment.ORIGINAL_CERTIFICATE WHERE CERTIFICATE_ID = certIdToDelete;
    SELECT * FROM intygstjanst_environment.CERTIFICATE WHERE ID = certIdToDelete;


    -- ******** DELETING FROM INTYGSADMIN DATABASE ********
    SELECT * FROM intygsadmin_environment.intyg_info WHERE intyg_id = certIdToDelete;


    -- ******** DELETING FROM STATISTIK DATABASE ********
    -- Create temporary table to store statistik.meddelandehandelse correlationId
    CREATE TEMPORARY TABLE STATISTIK_MESSAGE_KEYS (
                    S_M_KEY BIGINT NOT NULL COLLATE utf8mb3_general_ci,
                    PRIMARY KEY (S_M_KEY));
    INSERT INTO STATISTIK_MESSAGE_KEYS (S_M_KEY) SELECT meddelandeId FROM statistik_environment.messagewideline WHERE intygid = certIdToDelete;

    SELECT * FROM statistik_environment.intyghandelse WHERE CORRELATIONID = certIdToDelete;
    SELECT * FROM statistik_environment.intygcommon WHERE INTYGID = certIdToDelete;
    SELECT * FROM statistik_environment.messagewideline WHERE intygid = certIdToDelete;
    SELECT * FROM statistik_environment.wideline WHERE correlationId = certIdToDelete;
    SELECT * FROM statistik_environment.meddelandehandelse WHERE correlationId IN (SELECT S_M_KEY FROM STATISTIK_MESSAGE_KEYS);
    SELECT * FROM statistik_environment.hsa WHERE id = certIdToDelete;


    -- ******** DELETING FROM WEBCERT DATABASE ********
    -- Create temporary table to store webcert.HANDELSE INTYGS_ID
    CREATE TEMPORARY TABLE WEBCERT_HANDELSE_IDS (
                        H_ID BIGINT NOT NULL COLLATE utf8mb3_general_ci,
                        PRIMARY KEY (H_ID));
    INSERT INTO WEBCERT_HANDELSE_IDS (H_ID) SELECT ID FROM webcert_environment.HANDELSE WHERE INTYGS_ID = certIdToDelete;

    -- Create temporary table to store webcert.ARENDE ARENDE_ID
    CREATE TEMPORARY TABLE WEBCERT_ARENDE_IDS (
                    A_ID BIGINT NOT NULL COLLATE utf8mb3_general_ci,
                    PRIMARY KEY (A_ID));
    INSERT INTO WEBCERT_ARENDE_IDS (A_ID) SELECT ID FROM webcert_environment.ARENDE WHERE INTYGS_ID = certIdToDelete;

    -- Create temporary table to store webcert.FRAGASVAR internReferens
    CREATE TEMPORARY TABLE WEBCERT_FRAGASVAR_REFS (
                    F_REF BIGINT NOT NULL COLLATE utf8mb3_general_ci,
                    PRIMARY KEY (F_REF));
    INSERT INTO WEBCERT_FRAGASVAR_REFS (F_REF) SELECT internReferens FROM webcert_environment.FRAGASVAR WHERE INTYGS_ID = certIdToDelete;



    SELECT * FROM webcert_environment.CERTIFICATE_EVENT WHERE CERTIFICATE_ID = certIdToDelete;
    SELECT * FROM webcert_environment.NOTIFICATION_REDELIVERY WHERE HANDELSE_ID IN (SELECT H_ID FROM WEBCERT_HANDELSE_IDS);
    SELECT * FROM webcert_environment.HANDELSE_METADATA WHERE HANDELSE_ID IN (SELECT H_ID FROM WEBCERT_HANDELSE_IDS);
    SELECT * FROM webcert_environment.HANDELSE WHERE INTYGS_ID = certIdToDelete;
    SELECT * FROM webcert_environment.SIGNATUR WHERE INTYG_ID = certIdToDelete;
    SELECT * FROM webcert_environment.REFERENS WHERE INTYG_ID = certIdToDelete;
    SELECT * FROM webcert_environment.PAGAENDE_SIGNERING WHERE INTYG_ID = certIdToDelete;
    SELECT * FROM webcert_environment.ARENDE_KONTAKT_INFO WHERE ARENDE_ID IN (SELECT A_ID FROM WEBCERT_ARENDE_IDS);
    SELECT * FROM webcert_environment.MEDICINSKT_ARENDE WHERE ARENDE_ID IN (SELECT A_ID FROM WEBCERT_ARENDE_IDS);
    SELECT * FROM webcert_environment.ARENDE WHERE INTYGS_ID = certIdToDelete;
    SELECT * FROM webcert_environment.ARENDE_UTKAST WHERE INTYGS_ID = certIdToDelete;
    SELECT * FROM webcert_environment.CERTIFICATE_EVENT_FAILED_LOAD WHERE CERTIFICATE_ID = certIdToDelete;
    SELECT * FROM webcert_environment.CERTIFICATE_EVENT_PROCESSED WHERE CERTIFICATE_ID = certIdToDelete;
    SELECT * FROM webcert_environment.KOMPLETTERING WHERE FRAGASVAR_ID IN (SELECT F_REF FROM WEBCERT_FRAGASVAR_REFS);
    SELECT * FROM webcert_environment.FRAGASVAR WHERE INTYGS_ID = certIdToDelete;
    SELECT * FROM webcert_environment.INTYG WHERE INTYGS_ID = certIdToDelete;



    -- ******** DELETING FROM CERTIFICATE-SERVICE DATABASE ********
    -- Insert cs certificate key into variable
    SELECT `KEY` INTO csCertKey FROM certificate_service.certificate WHERE CERTIFICATE_ID = certIdToDelete;

    -- Create temporary table to store Certificate-service message keys
    CREATE TEMPORARY TABLE CS_MESSAGE_KEYS (
                    CS_M_KEY BIGINT NOT NULL COLLATE utf8mb3_general_ci,
                    PRIMARY KEY (CS_M_KEY)
                );
    -- Insert message keys into the temporary table
    INSERT INTO CS_MESSAGE_KEYS (CS_M_KEY) SELECT `KEY` FROM certificate_service.message WHERE certificate_key = csCertKey;

    SELECT * FROM certificate_service.message_complement WHERE MESSAGE_KEY IN (SELECT CS_M_KEY FROM CS_MESSAGE_KEYS);
    SELECT * FROM certificate_service.message_contact_info WHERE MESSAGE_KEY IN (SELECT CS_M_KEY FROM CS_MESSAGE_KEYS);
    SELECT * FROM certificate_service.message_relation WHERE PARENT_MESSAGE_KEY IN (SELECT CS_M_KEY FROM CS_MESSAGE_KEYS);
    SELECT * FROM certificate_service.message_relation WHERE CHILD_MESSAGE_KEY IN (SELECT CS_M_KEY FROM CS_MESSAGE_KEYS);
    SELECT * FROM certificate_service.message WHERE CERTIFICATE_KEY = csCertKey;

    SELECT * FROM certificate_service.certificate_xml WHERE `KEY` = csCertKey;
    SELECT * FROM certificate_service.certificate_relation WHERE PARENT_CERTIFICATE_KEY = csCertKey;
    SELECT * FROM certificate_service.certificate_relation WHERE CHILD_CERTIFICATE_KEY = csCertKey;
    SELECT * FROM certificate_service.certificate_data WHERE `KEY` = csCertKey;
    SELECT * FROM certificate_service.certificate WHERE CERTIFICATE_ID = certIdToDelete;

    DROP TEMPORARY TABLE CS_MESSAGE_KEYS;
    DROP TEMPORARY TABLE STATISTIK_MESSAGE_KEYS;
    DROP TEMPORARY TABLE WEBCERT_HANDELSE_IDS;
    DROP TEMPORARY TABLE WEBCERT_ARENDE_IDS;
    DROP TEMPORARY TABLE WEBCERT_FRAGASVAR_REFS;

    SET SQL_SAFE_UPDATES = 1;
    SET FOREIGN_KEY_CHECKS = 1;

    IF errorCode = '00000' THEN
        COMMIT;
    SELECT CONCAT('Successfully selected certificate with id = ', certIdToDelete, ' from all databases.') AS result_message;
    ELSE
        ROLLBACK;
        SELECT CONCAT('Stored procedure failed, no changes were introduced, errorCode = ', errorCode, ', errorMessage = ', errorMessage) AS result_message;
    END IF;
END $$
DELIMITER ;
CALL select_certificate_by_id_all_services;
DROP PROCEDURE select_certificate_by_id_all_services;