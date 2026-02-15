USE intygstjanst;

DELIMITER $$
CREATE PROCEDURE updateCareProvider()

BEGIN
    -- Declare variables
    DECLARE updatedCareProviderId VARCHAR(50);
    DECLARE errorCode CHAR(5) DEFAULT '00000';
    DECLARE errorMessage TEXT;

    -- Declare handler
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            errorCode = RETURNED_SQLSTATE, errorMessage = MESSAGE_TEXT;
    END;

    SET updatedCareProviderId = 'SE2321000016-A9KJ';

    -- Start transaction
    START TRANSACTION;

    -- Inactivate safe-updates as we are updating rows based on other columns than primary keys
    SET SQL_SAFE_UPDATES = 0;

    -- Update CERTIFICATE table
    UPDATE CERTIFICATE
    SET CARE_GIVER_ID = updatedCareProviderId
    WHERE CARE_GIVER_ID = 'SE2321000016-A1A6DT';

    -- Update REKO table
    UPDATE REKO
    SET CARE_PROVIDER_ID = updatedCareProviderId
    WHERE CARE_PROVIDER_ID = 'SE2321000016-A1A6DT';

    -- Update SJUKFALL_CERT table
    UPDATE SJUKFALL_CERT
    SET CARE_GIVER_ID = updatedCareProviderId
    WHERE CARE_GIVER_ID = 'SE2321000016-A1A6DT';

    DROP TEMPORARY TABLE IF EXISTS originalCareProviderIds;

    IF errorCode = '00000' THEN
        COMMIT;
        SELECT 'Updated care provider successfully.';
    ELSE
        ROLLBACK;
        SELECT 'Transaction rolled back due to sql exception. No changes were introduced.';
        SELECT CONCAT('Stored procedure failed, error = ', errorCode, ', message = ', errorMessage);
    END IF;

    -- Activate safe-updates again
    SET SQL_SAFE_UPDATES = 1;

END$$
DELIMITER ;

-- Call the stored procedure
CALL updateCareProvider;
DROP PROCEDURE updateCareProvider;
