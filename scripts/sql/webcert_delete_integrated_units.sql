-- This script deletes a list of integrated units identified by unit id.
use webcert;

DELIMITER $$
CREATE PROCEDURE deleteIntegratedUnits()
BEGIN

    DECLARE affectedRowCount BIGINT DEFAULT 0;
    DECLARE errorCode CHAR(5) DEFAULT '00000';
    DECLARE errorMessage TEXT;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            errorCode = RETURNED_SQLSTATE, errorMessage = MESSAGE_TEXT;
    END;

    START TRANSACTION;
        DELETE FROM INTEGRERADE_VARDENHETER WHERE ENHETS_ID in (
            'unit_id_1',
            'unit-id_2'
        );

        IF errorCode = '00000' THEN
            SET affectedRowCount = ROW_COUNT();
            COMMIT;
            SELECT CONCAT('Deleted ', affectedRowCount, ' integrated units from webcert.');
        ELSE
            ROLLBACK;
            SELECT 'Transaction rolled back due to sql exception. No integrated units were deleted.';
            SELECT CONCAT('Stored procedure failed, error = ', errorCode, ', message = ', errorMessage);
        END IF;

END$$
DELIMITER ;

CALL deleteIntegratedUnits;
DROP PROCEDURE deleteIntegratedUnits;
