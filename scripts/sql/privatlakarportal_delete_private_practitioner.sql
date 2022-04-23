-- This script deletes a single private practitioner defined by personId
-- set in variable privatePractionerPersonId.
use privatlakarportal;

DELIMITER $$
CREATE PROCEDURE deletePrivatePractitioner()
BEGIN

	DECLARE privatePractionerId varchar(255) ;
	DECLARE privatePractionerPersonId varchar(255) ;

    DECLARE errorCode CHAR(5) DEFAULT '00000';
    DECLARE errorMessage TEXT;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            errorCode = RETURNED_SQLSTATE, errorMessage = MESSAGE_TEXT;
    END;

    SET privatePractionerPersonId = 'YYYYMMDDNNNN';
    SELECT PRIVATLAKARE_ID FROM PRIVATLAKARE WHERE PERSONID = privatePractionerPersonId INTO privatePractionerId;

    IF (privatePractionerId IS NULL OR privatePractionerId = '') THEN
        SELECT CONCAT('Private practitioner ', privatePractionerPersonId, ' could not be found in PP database.');

    ELSE
		START TRANSACTION;
            DELETE FROM BEFATTNING WHERE PRIVATLAKARE_ID = privatePractionerId;
            DELETE FROM LEGITIMERAD_YRKESGRUPP WHERE PRIVATLAKARE_ID = privatePractionerId;
            DELETE FROM MEDGIVANDE WHERE PRIVATLAKARE_ID = privatePractionerId;
            DELETE FROM SPECIALITET WHERE PRIVATLAKARE_ID = privatePractionerId;
            DELETE FROM VARDFORM WHERE PRIVATLAKARE_ID = privatePractionerId;
            DELETE FROM VERKSAMHETSTYP WHERE PRIVATLAKARE_ID = privatePractionerId;
            DELETE FROM PRIVATLAKARE WHERE PRIVATLAKARE_ID = privatePractionerId;

            IF errorCode = '00000' THEN
				COMMIT;
                SELECT CONCAT('Private practitioner ', privatePractionerId, ' was deleted from PP.');
            ELSE
				ROLLBACK;
                SELECT 'Transaction rolled back due to sql exception. No private practitioner was deleted.';
                SELECT CONCAT('Stored procedure failed, error = ', errorCode, ', message = ', errorMessage);
            END IF;
    END IF;

END$$
DELIMITER ;

CALL deletePrivatePractitioner;
DROP PROCEDURE deletePrivatePractitioner;