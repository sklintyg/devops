-- This script deletes certificates and related information for a certain patient.
USE <intygstjanst_database_name>;


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

    CREATE TEMPORARY TABLE `TEMP_SJUKFALL_CERT_TO_DELETE` (
       `CERTIFICATE_ID` varchar(255) NOT NULL,
       PRIMARY KEY (`CERTIFICATE_ID`)
    );

    -- Fill temporary tables
    INSERT INTO TEMP_CERTIFICATES_TO_DELETE SELECT ID FROM CERTIFICATE WHERE CIVIC_REGISTRATION_NUMBER = deleteCertificatesForPatientPersonalNumber;
    INSERT INTO TEMP_SJUKFALL_CERT_TO_DELETE SELECT ID FROM SJUKFALL_CERT WHERE CIVIC_REGISTRATION_NUMBER IN (deleteCertificatesForPatientPersonalNumber, deleteCertificatesForPatientPersonalNumberWithoutHyphen);


    -- Delete from relevant tables from temporary table
    IF (SELECT COUNT(*) FROM TEMP_CERTIFICATES_TO_DELETE) THEN
        SET SQL_SAFE_UPDATES = 0;

        DELETE FROM APPROVED_RECEIVER WHERE CERTIFICATE_ID IN (SELECT ID FROM TEMP_CERTIFICATES_TO_DELETE);
        DELETE FROM ARENDE WHERE INTYGS_ID IN (SELECT ID FROM TEMP_CERTIFICATES_TO_DELETE);

        DELETE FROM RELATION WHERE FROM_INTYG_ID IN (SELECT ID FROM TEMP_CERTIFICATES_TO_DELETE);
        DELETE FROM RELATION WHERE TO_INTYG_ID IN (SELECT ID FROM TEMP_CERTIFICATES_TO_DELETE);

        IF (SELECT COUNT(*) FROM TEMP_SJUKFALL_CERT_TO_DELETE) THEN
            DELETE FROM SJUKFALL_CERT_WORK_CAPACITY WHERE CERTIFICATE_ID IN (SELECT CERTIFICATE_ID FROM TEMP_SJUKFALL_CERT_TO_DELETE);
            DELETE FROM SJUKFALL_CERT WHERE ID IN (SELECT CERTIFICATE_ID FROM TEMP_SJUKFALL_CERT_TO_DELETE);
        END IF;

        DELETE FROM CERTIFICATE_METADATA WHERE CERTIFICATE_ID IN (SELECT ID FROM TEMP_CERTIFICATES_TO_DELETE);
        DELETE FROM CERTIFICATE_STATE WHERE CERTIFICATE_ID IN (SELECT ID FROM TEMP_CERTIFICATES_TO_DELETE);
        DELETE FROM ORIGINAL_CERTIFICATE WHERE CERTIFICATE_ID IN (SELECT ID FROM TEMP_CERTIFICATES_TO_DELETE);
        DELETE FROM CERTIFICATE WHERE ID IN (SELECT ID FROM TEMP_CERTIFICATES_TO_DELETE);

        SET SQL_SAFE_UPDATES = 1;
    ELSE
        SELECT 'No certificates to delete for patient.';
    END IF;


    -- Drop temporary tables
    DROP TEMPORARY TABLE TEMP_CERTIFICATES_TO_DELETE;
    DROP TEMPORARY TABLE TEMP_SJUKFALL_CERT_TO_DELETE;


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
