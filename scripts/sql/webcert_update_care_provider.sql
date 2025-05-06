USE webcert;

DELIMITER $$
CREATE PROCEDURE updateCareProvider()

BEGIN
    -- Declare variables
    DECLARE updatedCareProviderId VARCHAR(50);
    DECLARE updatedCareProviderName VARCHAR(100);
    DECLARE errorCode CHAR(5) DEFAULT '00000';
    DECLARE errorMessage TEXT;

    -- Declare handler
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            errorCode = RETURNED_SQLSTATE, errorMessage = MESSAGE_TEXT;
    END;

    SET updatedCareProviderId = 'SE2321000016-39KJ';
    SET updatedCareProviderName = 'Region Stockholm';

    -- Start transaction
    START TRANSACTION;

    DROP TEMPORARY TABLE IF EXISTS originalCareProviderIds;
    CREATE TEMPORARY TABLE originalCareProviderIds(id VARCHAR(50));

    -- Insert original care provider IDs into the table variable
    INSERT INTO originalCareProviderIds
    VALUES ('SE2321000016-1K2W'), ('SE2321000016-11LS'), ('SE2321000016-12B8'), ('SE2321000016-3CLH');

    -- Update FRAGASVAR table
    UPDATE FRAGASVAR
    SET VARDGIVAR_ID = updatedCareProviderId, VARDGIVARNAMN = updatedCareProviderName
    WHERE VARDGIVAR_ID IN (SELECT Id FROM originalCareProviderIds);

    -- Update HANDELSE table
    UPDATE HANDELSE
    SET VARDGIVAR_ID = updatedCareProviderId
    WHERE VARDGIVAR_ID IN (SELECT Id FROM originalCareProviderIds);

    -- Update INTEGRERADE_VARDENHETER table
    UPDATE INTEGRERADE_VARDENHETER
    SET VARDGIVAR_ID = updatedCareProviderId, VARDGIVAR_NAMN = updatedCareProviderName
    WHERE VARDGIVAR_ID IN (SELECT Id FROM originalCareProviderIds);

    -- Update INTYG table
    UPDATE INTYG
    SET VARDGIVAR_ID = updatedCareProviderId, VARDGIVAR_NAMN = updatedCareProviderName
    WHERE VARDGIVAR_ID IN (SELECT Id FROM originalCareProviderIds);

    DROP TEMPORARY TABLE IF EXISTS originalCareProviderIds;

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
