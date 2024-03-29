-- This script deletes certificates and related information for a certain patient.
USE <webcert_database_name>;


DELIMITER $$
CREATE PROCEDURE delete_certificates()
BEGIN

    DECLARE deleteCertificatesForPatientPersonalNumber VARCHAR(20) DEFAULT '<patient_personal_number_with_hyphen>';
    DECLARE deleteCertificatesForPatientPersonalNumberWithoutHyphen VARCHAR(20) DEFAULT REPLACE(deleteCertificatesForPatientPersonalNumber, '-', '');

    DECLARE errorCode CHAR(5) DEFAULT '00000';
    DECLARE errorMessage TEXT;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
    GET DIAGNOSTICS CONDITION 1
        errorCode = RETURNED_SQLSTATE, errorMessage = MESSAGE_TEXT;
    END;


    START TRANSACTION;


    SELECT CONCAT('Delete certificates for ', deleteCertificatesForPatientPersonalNumber, ' and ', deleteCertificatesForPatientPersonalNumberWithoutHyphen, '.');


    -- Create temporary tables
    CREATE TEMPORARY TABLE `TEMP_CERTIFICATES_TO_DELETE` (
		 `ID` varchar(64) NOT NULL,
		 PRIMARY KEY (`ID`)
    );

    CREATE TEMPORARY TABLE `TEMP_ARENDE_TO_DELETE` (
		`ID` bigint(20) NOT NULL,
		PRIMARY KEY (`ID`)
    );

    CREATE TEMPORARY TABLE `TEMP_HANDELSE_TO_DELETE` (
		`ID` bigint(20) NOT NULL,
		PRIMARY KEY (`ID`)
    );

    CREATE TEMPORARY TABLE `TEMP_FRAGASVAR_TO_DELETE` (
		`ID` bigint(20) NOT NULL,
		PRIMARY KEY (`ID`)
    );


    -- Fill temporary tables
    INSERT INTO TEMP_CERTIFICATES_TO_DELETE SELECT INTYGS_ID FROM INTYG WHERE PATIENT_PERSONNUMMER = deleteCertificatesForPatientPersonalNumber;
    INSERT INTO TEMP_ARENDE_TO_DELETE SELECT ID FROM ARENDE WHERE PATIENT_PERSON_ID IN (deleteCertificatesForPatientPersonalNumber, deleteCertificatesForPatientPersonalNumberWithoutHyphen);
    INSERT INTO TEMP_HANDELSE_TO_DELETE SELECT ID FROM HANDELSE WHERE PATIENT_PERSON_ID IN (deleteCertificatesForPatientPersonalNumber, deleteCertificatesForPatientPersonalNumberWithoutHyphen);
    INSERT INTO TEMP_FRAGASVAR_TO_DELETE SELECT internReferens FROM FRAGASVAR WHERE INTYGS_ID IN (SELECT ID FROM TEMP_CERTIFICATES_TO_DELETE);


    -- Delete from relevant tables from temporary tables
    IF (SELECT COUNT(*) FROM TEMP_CERTIFICATES_TO_DELETE) THEN
        SET SQL_SAFE_UPDATES = 0;

        DELETE FROM PAGAENDE_SIGNERING WHERE INTYG_ID IN (SELECT ID FROM TEMP_CERTIFICATES_TO_DELETE);
        DELETE FROM SIGNATUR WHERE INTYG_ID IN (SELECT ID FROM TEMP_CERTIFICATES_TO_DELETE);

        IF (SELECT COUNT(*) FROM TEMP_ARENDE_TO_DELETE) THEN
            DELETE FROM MEDICINSKT_ARENDE WHERE ARENDE_ID IN (SELECT ID FROM TEMP_ARENDE_TO_DELETE);
            DELETE FROM ARENDE_KONTAKT_INFO WHERE ARENDE_ID IN (SELECT ID FROM TEMP_ARENDE_TO_DELETE);
        END IF;
        DELETE FROM ARENDE_UTKAST WHERE INTYGS_ID IN (SELECT ID FROM TEMP_CERTIFICATES_TO_DELETE);
        IF (SELECT COUNT(*) FROM TEMP_ARENDE_TO_DELETE) THEN
            DELETE FROM ARENDE WHERE ID IN (SELECT ID FROM TEMP_ARENDE_TO_DELETE);
        END IF;

        DELETE FROM CERTIFICATE_EVENT WHERE CERTIFICATE_ID IN (SELECT ID FROM TEMP_CERTIFICATES_TO_DELETE);
        DELETE FROM CERTIFICATE_EVENT_FAILED_LOAD WHERE CERTIFICATE_ID IN (SELECT ID FROM TEMP_CERTIFICATES_TO_DELETE);
        DELETE FROM CERTIFICATE_EVENT_PROCESSED WHERE CERTIFICATE_ID IN (SELECT ID FROM TEMP_CERTIFICATES_TO_DELETE);

        IF (SELECT COUNT(*) FROM TEMP_FRAGASVAR_TO_DELETE) THEN
            DELETE FROM EXTERNA_KONTAKTER WHERE FRAGASVAR_ID IN (SELECT ID FROM TEMP_FRAGASVAR_TO_DELETE);
            DELETE FROM KOMPLETTERING WHERE FRAGASVAR_ID IN (SELECT ID FROM TEMP_FRAGASVAR_TO_DELETE);
        END IF;
        DELETE FROM FRAGASVAR WHERE INTYGS_ID IN (SELECT ID FROM TEMP_CERTIFICATES_TO_DELETE);

        IF (SELECT COUNT(*) FROM TEMP_HANDELSE_TO_DELETE) THEN
            DELETE FROM NOTIFICATION_REDELIVERY WHERE HANDELSE_ID IN (SELECT ID FROM TEMP_HANDELSE_TO_DELETE);
            DELETE FROM HANDELSE_METADATA WHERE HANDELSE_ID IN (SELECT ID FROM TEMP_HANDELSE_TO_DELETE);
            DELETE FROM HANDELSE WHERE ID IN (SELECT ID FROM TEMP_HANDELSE_TO_DELETE);
        END IF;

        DELETE FROM REFERENS WHERE INTYG_ID IN (SELECT ID FROM TEMP_CERTIFICATES_TO_DELETE);

        DELETE FROM INTYG WHERE INTYGS_ID IN (SELECT ID FROM TEMP_CERTIFICATES_TO_DELETE);

        SET SQL_SAFE_UPDATES = 1;
    ELSE
        SELECT 'No certificates to delete for patient.';
    END IF;


    DROP TEMPORARY TABLE TEMP_CERTIFICATES_TO_DELETE;
    DROP TEMPORARY TABLE TEMP_ARENDE_TO_DELETE;
    DROP TEMPORARY TABLE TEMP_HANDELSE_TO_DELETE;
    DROP TEMPORARY TABLE TEMP_FRAGASVAR_TO_DELETE;


    IF errorCode = '00000' THEN
        COMMIT;
        SELECT 'Deletion of certificates was successfully.';
    ELSE
        ROLLBACK;
        SELECT 'Transaction rolled back due to sql exception. No changes were introduced.';
        SELECT CONCAT('Stored procedure failed, error = ', errorCode, ', message = ', errorMessage);
    END IF;


END $$
DELIMITER ;


CALL delete_certificates;
DROP PROCEDURE delete_certificates;
