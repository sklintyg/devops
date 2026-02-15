USE statistik;

DELIMITER $$
CREATE PROCEDURE updateCareProviderStatistik()

BEGIN
    -- Declare variables
    DECLARE updatedCareProviderId VARCHAR(50);
    DECLARE errorCode CHAR(5) DEFAULT '00000';
    DECLARE errorMessage TEXT;

    DECLARE originalCareProviderId VARCHAR(50);

    -- Declare handler
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            errorCode = RETURNED_SQLSTATE, errorMessage = MESSAGE_TEXT;
    END;

    SET updatedCareProviderId = 'SE2321000016-A9KJ';
    SET originalCareProviderId = 'SE2321000016-A1A6DT';

    -- Start transaction
    START TRANSACTION;

    -- Inactivate safe-updates as we are updating rows based on other columns than primary keys
    SET SQL_SAFE_UPDATES = 0;
           
    -- Update ENHET table
    UPDATE enhet
    SET vardgivareId = updatedCareProviderId
    WHERE vardgivareId = originalCareProviderId;

    -- Update INTYGCOMMON table
    UPDATE intygcommon
    SET vardgivareid = updatedCareProviderId
    WHERE vardgivareid = originalCareProviderId;

    -- Update LAKARE table
    UPDATE lakare
    SET vardgivareid = updatedCareProviderId
    WHERE vardgivareid = originalCareProviderId;

    -- Update MESSAGEWIDELINE table
    UPDATE messagewideline
    SET vardgivareid = updatedCareProviderId
    WHERE vardgivareid = originalCareProviderId;

    -- Update WIDELINE table
    UPDATE wideline
    SET vardgivareid = updatedCareProviderId
    WHERE vardgivareid = originalCareProviderId;

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
