USE webcert;

DELIMITER $$
CREATE PROCEDURE updateCareProvider()

BEGIN
    -- Declare variables
    DECLARE updatedCareProviderId VARCHAR(50);
    DECLARE updatedCareProviderName VARCHAR(100);
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
    SET updatedCareProviderName = 'Region Stockholm';
    SET originalCareProviderId = 'SE2321000016-A1A6DT'

    -- Start transaction
    START TRANSACTION;

    -- Inactivate safe-updates as we are updating rows based on other columns than primary keys
    SET SQL_SAFE_UPDATES = 0;

    -- Update FRAGASVAR table
    UPDATE FRAGASVAR
    SET VARDGIVAR_ID = updatedCareProviderId, VARDGIVARNAMN = updatedCareProviderName
    WHERE VARDGIVAR_ID = originalCareProviderId;

    -- Update HANDELSE table
    UPDATE HANDELSE
    SET VARDGIVAR_ID = updatedCareProviderId
    WHERE VARDGIVAR_ID = originalCareProviderId;

    -- Update INTEGRERADE_VARDENHETER table
    UPDATE INTEGRERADE_VARDENHETER
    SET VARDGIVAR_ID = updatedCareProviderId, VARDGIVAR_NAMN = updatedCareProviderName
    WHERE VARDGIVAR_ID = originalCareProviderId;

    -- Update INTYG table
    UPDATE INTYG
    SET VARDGIVAR_ID = updatedCareProviderId, VARDGIVAR_NAMN = updatedCareProviderName
    WHERE VARDGIVAR_ID = originalCareProviderId;


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
