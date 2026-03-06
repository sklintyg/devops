-- ===========================================================
-- Stored Procedure: delete_privatlakare_by_hsaid
-- ===========================================================
-- Purpose: Delete private practitioners and all related data
--          from the privatlakarportal database by HSA ID
--
-- Features:
--   - Transactional: All deletes wrapped in a transaction
--   - Rollback on error: Any failure rolls back all changes
--   - Cascading deletes: Removes data from all related tables
--   - Safe mode handling: Temporarily disables SQL_SAFE_UPDATES
--
-- Usage:
--   1. Replace <HSA_IDS_TO_DELETE> with actual HSA IDs
--      Example: ('SE165565594230-WEBCERT00007'), ('SE165565594230-WEBCERT00009')
--   2. Execute: CALL delete_privatlakare_by_hsaid();
--
-- Note: Run the query_script.sql first to verify no certificates
--       exist for these practitioners before deletion
-- ===========================================================
USE privatlakarportal;

-- Change delimiter to allow semicolons within the procedure body
DELIMITER $$

-- Drop procedure if it already exists
DROP PROCEDURE IF EXISTS delete_privatlakare_by_hsaid$$

CREATE PROCEDURE delete_privatlakare_by_hsaid()
BEGIN
    -- Error handler: Executes if any SQL exception occurs
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            -- Rollback the transaction on error
            ROLLBACK;
            -- Re-enable safe update mode
            SET SQL_SAFE_UPDATES = 1;
            -- Re-signal the error to the caller
            RESIGNAL;
        END;

    -- Disable safe update mode to allow deletes with subqueries
    SET SQL_SAFE_UPDATES = 0;

    -- Start transaction: All following operations are atomic
    START TRANSACTION;

    -- ==========================================
    -- Step 1: Build list of IDs to delete
    -- ==========================================

    -- Create temporary table to hold PRIVATLAKARE_IDs
    DROP TEMPORARY TABLE IF EXISTS temp_privatlakare_ids;
    CREATE TEMPORARY TABLE temp_privatlakare_ids
    (
        id VARCHAR(255) PRIMARY KEY
    );

    -- Populate temporary table with IDs matching the specified HSA IDs
    -- Replace <HSA_IDS_TO_DELETE> with actual values before executing
    INSERT INTO temp_privatlakare_ids (id)
    SELECT PRIVATLAKARE_ID
    FROM privatlakarportal.PRIVATLAKARE
    WHERE HSAID IN
          (<HSA_IDS_TO_DELETE>);

    -- ==========================================
    -- Step 2: Delete from child tables
    -- ==========================================
    -- Must delete from child tables first to maintain referential integrity
    -- All child tables reference PRIVATLAKARE via PRIVATLAKARE_ID foreign key

    DELETE
    FROM privatlakarportal.MEDGIVANDE
    WHERE PRIVATLAKARE_ID IN (SELECT id FROM temp_privatlakare_ids);

    DELETE
    FROM privatlakarportal.LEGITIMERAD_YRKESGRUPP
    WHERE PRIVATLAKARE_ID IN (SELECT id FROM temp_privatlakare_ids);

    DELETE
    FROM privatlakarportal.EPOST
    WHERE PRIVATLAKARE_ID IN (SELECT id FROM temp_privatlakare_ids);

    DELETE
    FROM privatlakarportal.BEFATTNING
    WHERE PRIVATLAKARE_ID IN (SELECT id FROM temp_privatlakare_ids);

    DELETE
    FROM privatlakarportal.RESTRIKTION
    WHERE PRIVATLAKARE_ID IN (SELECT id FROM temp_privatlakare_ids);

    DELETE
    FROM privatlakarportal.SPECIALITET
    WHERE PRIVATLAKARE_ID IN (SELECT id FROM temp_privatlakare_ids);

    DELETE
    FROM privatlakarportal.VARDFORM
    WHERE PRIVATLAKARE_ID IN (SELECT id FROM temp_privatlakare_ids);

    DELETE
    FROM privatlakarportal.VERKSAMHETSTYP
    WHERE PRIVATLAKARE_ID IN (SELECT id FROM temp_privatlakare_ids);

    -- ==========================================
    -- Step 3: Delete from parent table
    -- ==========================================
    -- Delete main private practitioner records last
    DELETE
    FROM privatlakarportal.PRIVATLAKARE
    WHERE PRIVATLAKARE_ID IN (SELECT id FROM temp_privatlakare_ids);

    -- ==========================================
    -- Step 4: Cleanup and finalize
    -- ==========================================

    -- Remove temporary table
    DROP TEMPORARY TABLE IF EXISTS temp_privatlakare_ids;

    -- Commit the transaction if all deletes succeeded
    COMMIT;

    -- Re-enable safe update mode to restore MySQL safety settings
    SET SQL_SAFE_UPDATES = 1;
END$$

-- Restore default delimiter
DELIMITER ;

-- ==========================================
-- Execute the procedure and cleanup
-- ==========================================

-- Call the stored procedure to perform the deletions
CALL delete_privatlakare_by_hsaid;

-- Remove the procedure after execution (one-time use)
DROP PROCEDURE delete_privatlakare_by_hsaid;
