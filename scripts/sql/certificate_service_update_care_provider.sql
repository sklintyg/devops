USE certificate_service;

DELIMITER $$
CREATE PROCEDURE updateCareProvider()

BEGIN
    -- Declare variables
    DECLARE newKey VARCHAR(50);
    DECLARE errorCode CHAR(5) DEFAULT '00000';
    DECLARE errorMessage TEXT;

    -- Declare handler
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
BEGIN
GET DIAGNOSTICS CONDITION 1
    errorCode = RETURNED_SQLSTATE, errorMessage = MESSAGE_TEXT;
END;

    -- Set the new key
SELECT `key` INTO newKey FROM unit WHERE hsa_id = 'SE2321000016-39KJ';

-- Start transaction
START TRANSACTION;

-- Update the certificate table
UPDATE certificate
SET care_provider_unit_key = newKey
WHERE care_provider_unit_key IN (
    SELECT `key` FROM unit WHERE hsa_id IN ('SE2321000016-1K2W', 'SE2321000016-11LS', 'SE2321000016-12B8', 'SE2321000016-3CLH')
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