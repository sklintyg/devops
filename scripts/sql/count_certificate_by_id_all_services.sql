USE intygstjanst;
DELIMITER $$
CREATE PROCEDURE count_certificate_by_id_all_services()
BEGIN
    DECLARE errorCode CHAR(5) DEFAULT '00000';
    DECLARE errorMessage TEXT;
    DECLARE csCertKey BIGINT;
    DECLARE certIdToCount VARCHAR(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '<certificate_id>';
    DECLARE certIdToCountCS VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT '<certificate_id>';

    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
    GET DIAGNOSTICS CONDITION 1
        errorCode = RETURNED_SQLSTATE, errorMessage = MESSAGE_TEXT;
    END;


    START TRANSACTION;
    SET SQL_SAFE_UPDATES = 0;
    SET FOREIGN_KEY_CHECKS = 0;


    -- ******** COUNTING FROM INTYGSTJANST DATABASE ********
   SELECT COUNT(*) AS row_count_intygstjanst_RELATION FROM intygstjanst.RELATION WHERE FROM_INTYG_ID = certIdToCount;
   SELECT COUNT(*) AS row_count_intygstjanst_RELATION FROM intygstjanst.RELATION WHERE TO_INTYG_ID = certIdToCount;
   SELECT COUNT(*) AS row_count_intygstjanst_ARENDE FROM intygstjanst.ARENDE WHERE INTYGS_ID = certIdToCount;
   SELECT COUNT(*) AS row_count_intygstjanst_APPROVED_RECEIVER FROM intygstjanst.APPROVED_RECEIVER WHERE CERTIFICATE_ID = certIdToCount;
   SELECT COUNT(*) AS row_count_intygstjanst_SJUKFALL_CERT FROM intygstjanst.SJUKFALL_CERT WHERE ID = certIdToCount;
   SELECT COUNT(*) AS row_count_intygstjanst_SJUKFALL_CERT_WORK_CAPACITY FROM intygstjanst.SJUKFALL_CERT_WORK_CAPACITY WHERE CERTIFICATE_ID = certIdToCount;
   SELECT COUNT(*) AS row_count_intygstjanst_CERTIFICATE_METADATA FROM intygstjanst.CERTIFICATE_METADATA WHERE CERTIFICATE_ID = certIdToCount;
   SELECT COUNT(*) AS row_count_intygstjanst_CERTIFICATE_STATE FROM intygstjanst.CERTIFICATE_STATE WHERE CERTIFICATE_ID = certIdToCount;
   SELECT COUNT(*) AS row_count_intygstjanst_ORIGINAL_CERTIFICATE FROM intygstjanst.ORIGINAL_CERTIFICATE WHERE CERTIFICATE_ID = certIdToCount;
   SELECT COUNT(*) AS row_count_intygstjanst_CERTIFICATE FROM intygstjanst.CERTIFICATE WHERE ID = certIdToCount;


    -- ******** COUNTING FROM INTYGSADMIN DATABASE ********
   SELECT COUNT(*) AS row_count_intygsadmin_intyg_info FROM intygsadmin.intyg_info WHERE intyg_id = certIdToCount;


    -- ******** COUNTING FROM STATISTIK DATABASE ********
    -- Create temporary table to store statistik.meddelandehandelse correlationId
    CREATE TEMPORARY TABLE STATISTIK_MESSAGE_KEYS (
                    S_M_KEY BIGINT NOT NULL COLLATE utf8mb3_general_ci,
                    PRIMARY KEY (S_M_KEY));
    INSERT INTO STATISTIK_MESSAGE_KEYS (S_M_KEY) SELECT meddelandeId FROM statistik.messagewideline WHERE intygid = certIdToCount;

   SELECT COUNT(*) AS row_count_statistik_intyghandelse FROM statistik.intyghandelse WHERE CORRELATIONID = certIdToCount;
   SELECT COUNT(*) AS row_count_statistik_intygsenthandelse FROM statistik.intygsenthandelse WHERE CORRELATIONID = certIdToCount;
   SELECT COUNT(*) AS row_count_statistik_intygcommon FROM statistik.intygcommon WHERE INTYGID = certIdToCount;
   SELECT COUNT(*) AS row_count_statistik_messagewideline FROM statistik.messagewideline WHERE intygid = certIdToCount;
   SELECT COUNT(*) AS row_count_statistik_wideline FROM statistik.wideline WHERE correlationId = certIdToCount;
   SELECT COUNT(*) AS row_count_statistik_meddelandehandelse FROM statistik.meddelandehandelse WHERE correlationId IN (SELECT S_M_KEY FROM STATISTIK_MESSAGE_KEYS);
   SELECT COUNT(*) AS row_count_statistik_hsa FROM statistik.hsa WHERE id = certIdToCount;


    -- ******** COUNTING FROM WEBCERT DATABASE ********
    -- Create temporary table to store webcert.HANDELSE INTYGS_ID
    CREATE TEMPORARY TABLE WEBCERT_HANDELSE_IDS (
                        H_ID BIGINT NOT NULL COLLATE utf8mb3_general_ci,
                        PRIMARY KEY (H_ID));
    INSERT INTO WEBCERT_HANDELSE_IDS (H_ID) SELECT ID FROM webcert.HANDELSE WHERE INTYGS_ID = certIdToCount;

    -- Create temporary table to store webcert.ARENDE ARENDE_ID
    CREATE TEMPORARY TABLE WEBCERT_ARENDE_IDS (
                    A_ID BIGINT NOT NULL COLLATE utf8mb3_general_ci,
                    PRIMARY KEY (A_ID));
    INSERT INTO WEBCERT_ARENDE_IDS (A_ID) SELECT ID FROM webcert.ARENDE WHERE INTYGS_ID = certIdToCount;

    -- Create temporary table to store webcert.FRAGASVAR internReferens
    CREATE TEMPORARY TABLE WEBCERT_FRAGASVAR_REFS (
                    F_REF BIGINT NOT NULL COLLATE utf8mb3_general_ci,
                    PRIMARY KEY (F_REF));
    INSERT INTO WEBCERT_FRAGASVAR_REFS (F_REF) SELECT internReferens FROM webcert.FRAGASVAR WHERE INTYGS_ID = certIdToCount;



    SELECT COUNT(*) AS row_count_webcert_CERTIFICATE_EVENT FROM webcert.CERTIFICATE_EVENT WHERE CERTIFICATE_ID = certIdToCount;
    SELECT COUNT(*) AS row_count_webcert_NOTIFICATION_REDELIVERY FROM webcert.NOTIFICATION_REDELIVERY WHERE HANDELSE_ID IN (SELECT H_ID FROM WEBCERT_HANDELSE_IDS);
    SELECT COUNT(*) AS row_count_webcert_HANDELSE_METADATA FROM webcert.HANDELSE_METADATA WHERE HANDELSE_ID IN (SELECT H_ID FROM WEBCERT_HANDELSE_IDS);
    SELECT COUNT(*) AS row_count_webcert_HANDELSE FROM webcert.HANDELSE WHERE INTYGS_ID = certIdToCount;
    SELECT COUNT(*) AS row_count_webcert_SIGNATUR FROM webcert.SIGNATUR WHERE INTYG_ID = certIdToCount;
    SELECT COUNT(*) AS row_count_webcert_REFERENS FROM webcert.REFERENS WHERE INTYG_ID = certIdToCount;
    SELECT COUNT(*) AS row_count_webcert_PAGAENDE_SIGNERING FROM webcert.PAGAENDE_SIGNERING WHERE INTYG_ID = certIdToCount;
    SELECT COUNT(*) AS row_count_webcert_ARENDE_KONTAKT_INFO FROM webcert.ARENDE_KONTAKT_INFO WHERE ARENDE_ID IN (SELECT A_ID FROM WEBCERT_ARENDE_IDS);
    SELECT COUNT(*) AS row_count_webcert_MEDICINSKT_ARENDE FROM webcert.MEDICINSKT_ARENDE WHERE ARENDE_ID IN (SELECT A_ID FROM WEBCERT_ARENDE_IDS);
    SELECT COUNT(*) AS row_count_webcert_ARENDE FROM webcert.ARENDE WHERE INTYGS_ID = certIdToCount;
    SELECT COUNT(*) AS row_count_webcert_ARENDE_UTKAST FROM webcert.ARENDE_UTKAST WHERE INTYGS_ID = certIdToCount;
    SELECT COUNT(*) AS row_count_webcert_CERTIFICATE_EVENT_FAILED_LOAD FROM webcert.CERTIFICATE_EVENT_FAILED_LOAD WHERE CERTIFICATE_ID = certIdToCount;
    SELECT COUNT(*) AS row_count_webcert_CERTIFICATE_EVENT_PROCESSED FROM webcert.CERTIFICATE_EVENT_PROCESSED WHERE CERTIFICATE_ID = certIdToCount;
    SELECT COUNT(*) AS row_count_webcert_KOMPLETTERING FROM webcert.KOMPLETTERING WHERE FRAGASVAR_ID IN (SELECT F_REF FROM WEBCERT_FRAGASVAR_REFS);
    SELECT COUNT(*) AS row_count_webcert_EXTERNA_KONTAKTER FROM webcert.EXTERNA_KONTAKTER WHERE FRAGASVAR_ID IN (SELECT F_REF FROM WEBCERT_FRAGASVAR_REFS);
    SELECT COUNT(*) AS row_count_webcert_FRAGASVAR FROM webcert.FRAGASVAR WHERE INTYGS_ID = certIdToCount;
    SELECT COUNT(*) AS row_count_webcert_INTYG FROM webcert.INTYG WHERE INTYGS_ID = certIdToCount;



    -- ******** COUNTING FROM CERTIFICATE-SERVICE DATABASE ********
    -- Insert cs certificate key into variable
    SELECT `KEY` INTO csCertKey FROM certificate_service.certificate WHERE CERTIFICATE_ID = certIdToCountCS;

    -- Create temporary table to store Certificate-service message keys
    CREATE TEMPORARY TABLE CS_MESSAGE_KEYS (
                    CS_M_KEY BIGINT NOT NULL COLLATE utf8mb4_0900_ai_ci,
                    PRIMARY KEY (CS_M_KEY)
                );
    -- Insert message keys into the temporary table
    INSERT INTO CS_MESSAGE_KEYS (CS_M_KEY) SELECT `KEY` FROM certificate_service.message WHERE certificate_key = csCertKey;

   SELECT COUNT(*) AS row_count_certificate_service_message_complement FROM certificate_service.message_complement WHERE MESSAGE_KEY IN (SELECT CS_M_KEY FROM CS_MESSAGE_KEYS);
   SELECT COUNT(*) AS row_count_certificate_service_message_contact_info FROM certificate_service.message_contact_info WHERE MESSAGE_KEY IN (SELECT CS_M_KEY FROM CS_MESSAGE_KEYS);
   SELECT COUNT(*) AS row_count_certificate_service_message_relation FROM certificate_service.message_relation WHERE PARENT_MESSAGE_KEY IN (SELECT CS_M_KEY FROM CS_MESSAGE_KEYS);
   SELECT COUNT(*) AS row_count_certificate_service_message_relation FROM certificate_service.message_relation WHERE CHILD_MESSAGE_KEY IN (SELECT CS_M_KEY FROM CS_MESSAGE_KEYS);
   SELECT COUNT(*) AS row_count_certificate_service_message FROM certificate_service.message WHERE CERTIFICATE_KEY = csCertKey;

   SELECT COUNT(*) AS row_count_certificate_service_certificate_xml FROM certificate_service.certificate_xml WHERE `KEY` = csCertKey;
   SELECT COUNT(*) AS row_count_certificate_service_certificate_relation FROM certificate_service.certificate_relation WHERE PARENT_CERTIFICATE_KEY = csCertKey;
   SELECT COUNT(*) AS row_count_certificate_service_certificate_relation FROM certificate_service.certificate_relation WHERE CHILD_CERTIFICATE_KEY = csCertKey;
   SELECT COUNT(*) AS row_count_certificate_service_certificate_data FROM certificate_service.certificate_data WHERE `KEY` = csCertKey;
   SELECT COUNT(*) AS row_count_certificate_service_external_reference FROM certificate_service.external_reference WHERE `KEY` = csCertKey;
   SELECT COUNT(*) AS row_count_certificate_service_certificate FROM certificate_service.certificate WHERE CERTIFICATE_ID = certIdToCountCS;

    DROP TEMPORARY TABLE CS_MESSAGE_KEYS;
    DROP TEMPORARY TABLE STATISTIK_MESSAGE_KEYS;
    DROP TEMPORARY TABLE WEBCERT_HANDELSE_IDS;
    DROP TEMPORARY TABLE WEBCERT_ARENDE_IDS;
    DROP TEMPORARY TABLE WEBCERT_FRAGASVAR_REFS;

    SET SQL_SAFE_UPDATES = 1;
    SET FOREIGN_KEY_CHECKS = 1;

    IF errorCode = '00000' THEN
        COMMIT;
    SELECT CONCAT('Successfully counted certificate with id = ', certIdToCount, ' from all databases.') AS result_message;
    ELSE
        ROLLBACK;
        SELECT CONCAT('Stored procedure failed, no changes were introduced, errorCode = ', errorCode, ', errorMessage = ', errorMessage) AS result_message;
    END IF;
END $$
DELIMITER ;
CALL count_certificate_by_id_all_services;
DROP PROCEDURE count_certificate_by_id_all_services;