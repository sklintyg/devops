-- This script deletes certificates and related information for a certain certificate ids.
use intygstjanst;
DELIMITER $$
CREATE PROCEDURE delete_certificates_in_intygstjanst()
BEGIN
    DECLARE errorCode CHAR(5) DEFAULT '00000';
    DECLARE errorMessage TEXT;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            GET DIAGNOSTICS CONDITION 1
                errorCode = RETURNED_SQLSTATE, errorMessage = MESSAGE_TEXT;
        END;
    CREATE TEMPORARY TABLE CERTIFICATE_IDS (
       ID VARCHAR(64) NOT NULL COLLATE utf8mb3_general_ci,  -- Set the collate to same as the tables otherwise a table-scan will be made.
       PRIMARY KEY (ID)
    );
    INSERT INTO CERTIFICATE_IDS (ID) VALUES
         ('<certificate id>'),
         ('<certificate id>');
    START TRANSACTION;
    SET SQL_SAFE_UPDATES = 0;
    DELETE FROM intygstjanst.RELATION WHERE FROM_INTYG_ID IN (SELECT ID FROM CERTIFICATE_IDS);
    DELETE FROM intygstjanst.RELATION WHERE TO_INTYG_ID IN (SELECT ID FROM CERTIFICATE_IDS);
    DELETE FROM intygstjanst.CERTIFICATE_METADATA WHERE CERTIFICATE_ID IN (SELECT ID FROM CERTIFICATE_IDS);
    DELETE FROM intygstjanst.CERTIFICATE_STATE WHERE CERTIFICATE_ID IN (SELECT ID FROM CERTIFICATE_IDS);
    DELETE FROM intygstjanst.ORIGINAL_CERTIFICATE WHERE CERTIFICATE_ID IN (SELECT ID FROM CERTIFICATE_IDS);
    DELETE FROM intygstjanst.CERTIFICATE WHERE ID IN (SELECT ID FROM CERTIFICATE_IDS);
    SET SQL_SAFE_UPDATES = 1;
    DROP TEMPORARY TABLE CERTIFICATE_IDS;
    IF errorCode = '00000' THEN
        COMMIT;
        SELECT 'Successfully deleted certificates in intygstjanst.';
    ELSE
        ROLLBACK;
        SELECT CONCAT('Stored procedure failed, no changes were introduced, errorCode = ', errorCode, ', errorMessage = ', errorMessage);
    END IF;
END $$
DELIMITER ;
CALL delete_certificates_in_intygstjanst;
DROP PROCEDURE delete_certificates_in_intygstjanst;