USE certificate_service;

DELIMITER $$
CREATE PROCEDURE updateCareProvider()

BEGIN
    -- Declare variables
    DECLARE newKey VARCHAR(50);
    DECLARE errorCode CHAR(5) DEFAULT '00000';
    DECLARE errorMessage TEXT;

    DECLARE originalCareProviderId VARCHAR(50);

    -- Declare handler
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            errorCode = RETURNED_SQLSTATE, errorMessage = MESSAGE_TEXT;
    END;

    -- Set the new key
    SELECT `key` INTO newKey FROM unit WHERE hsa_id = 'SE2321000016-A9KJ';

    -- Set the default care provider ID
    SET originalCareProviderId = 'SE2321000016-A1A6DT';

    -- Start transaction
    START TRANSACTION;

    -- Update the certificate table
    UPDATE certificate
    SET care_provider_unit_key = newKey
    WHERE care_provider_unit_key IN (
        SELECT `key` FROM unit WHERE hsa_id = originalCareProviderId
    );

    -- Commit or rollback based on error code
    IF errorCode = '00000' THEN
        COMMIT;
        SELECT 'Updated care provider successfully.';
    ELSE
        ROLLBACK;
        SELECT 'Transaction rolled back due to sql exception. No changes were introduced.';
        SELECT CONCAT('Stored procedure failed, error = ', errorCode, ', message = ', errorMessage);
    END IF;

END$$
DELIMITER ;

-- Call the stored procedure
CALL updateCareProvider;
DROP PROCEDURE updateCareProvider;
