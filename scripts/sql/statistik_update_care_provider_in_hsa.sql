USE statistik;

DELIMITER $$
CREATE PROCEDURE updateCareProviderInHSA()

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

    -- Update HSA table
    UPDATE hsa
    SET data = JSON_SET(
            data,
            '$.vardgivare.id', updatedCareProviderId,
            '$.enhet.vgid', updatedCareProviderId,
            '$.huvudenhet.vgid', updatedCareProviderId
           )
    WHERE JSON_EXTRACT(data, '$.vardgivare.id') IN ('SE2321000016-1K2W', 'SE2321000016-11LS', 'SE2321000016-12B8', 'SE2321000016-3CLH')
       OR JSON_EXTRACT(data, '$.enhet.vgid') IN ('SE2321000016-1K2W', 'SE2321000016-11LS', 'SE2321000016-12B8', 'SE2321000016-3CLH')
       OR JSON_EXTRACT(data, '$.huvudenhet.vgid') IN ('SE2321000016-1K2W', 'SE2321000016-11LS', 'SE2321000016-12B8', 'SE2321000016-3CLH');

    IF errorCode = '00000' THEN
        COMMIT;
        SELECT 'Updated care provider in HSA successfully.';
    ELSE
        ROLLBACK;
        SELECT 'Transaction rolled back due to sql exception. No changes were introduced.';
        SELECT CONCAT('Stored procedure failed, error = ', errorCode, ', message = ', errorMessage);
    END IF;

END$$
DELIMITER ;

-- Call the stored procedure
CALL updateCareProviderInHSA;
DROP PROCEDURE updateCareProviderInHSA;

