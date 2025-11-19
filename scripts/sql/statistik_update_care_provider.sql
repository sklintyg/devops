USE statistik;

DELIMITER $$
CREATE PROCEDURE updateCareProviderStatistik()

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

    SET updatedCareProviderId = 'SE2321000016-39KJ';

    -- Start transaction
START TRANSACTION;

-- Inactivate safe-updates as we are updating rows based on other columns than primary keys
SET SQL_SAFE_UPDATES = 0;

    DROP TEMPORARY TABLE IF EXISTS originalCareProviderIds;
    CREATE TEMPORARY TABLE originalCareProviderIds(id VARCHAR(50)
       NOT NULL COLLATE utf8mb3_general_ci -- Set the collate to same as the tables otherwise a table-scan will be made.
   );

    -- Insert original care provider IDs into the table variable
INSERT INTO originalCareProviderIds
VALUES ('SE2321000016-1K2W'), ('SE2321000016-11LS'), ('SE2321000016-12B8'), ('SE2321000016-3CLH');

-- Update ENHET table
UPDATE enhet
SET vardgivareId = updatedCareProviderId
WHERE vardgivareId IN (SELECT Id FROM originalCareProviderIds);

-- Update INTYGCOMMON table
UPDATE intygcommon
SET vardgivareid = updatedCareProviderId
WHERE vardgivareid IN (SELECT Id FROM originalCareProviderIds);

-- Update LAKARE table
UPDATE lakare
SET vardgivareid = updatedCareProviderId
WHERE vardgivareid IN (SELECT Id FROM originalCareProviderIds);

-- Update MESSAGEWIDELINE table
UPDATE messagewideline
SET vardgivareid = updatedCareProviderId
WHERE vardgivareid IN (SELECT Id FROM originalCareProviderIds);

-- Update WIDELINE table
UPDATE wideline
SET vardgivareid = updatedCareProviderId
WHERE vardgivareid IN (SELECT Id FROM originalCareProviderIds);

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
CALL updateCareProviderStatistik;
DROP PROCEDURE updateCareProviderStatistik;