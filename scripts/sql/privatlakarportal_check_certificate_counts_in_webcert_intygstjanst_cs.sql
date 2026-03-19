-- ================================================================
-- Query Script: Check Certificate Counts for Private Practitioners
-- ================================================================
-- Purpose: Count certificates across multiple databases
--          for specified private practitioner HSA IDs
-- ================================================================
USE privatlakarportal;

-- Step 1: Create temporary table to hold HSA IDs to check
DROP TEMPORARY TABLE IF EXISTS temp_care_giver_ids;
CREATE TEMPORARY TABLE temp_care_giver_ids
(
    id VARCHAR(255) PRIMARY KEY
);

-- Step 2: Insert HSA IDs to check
-- Replace <HSA_IDS_TO_CHECK> with actual HSA ID values
-- Example: ('SE165565594230-WEBCERT00007'), ('SE165565594230-WEBCERT00009')
INSERT INTO temp_care_giver_ids (id)
VALUES (<HSA_IDS_TO_CHECK>);

-- Step 3: Query intygstjanst database
-- Count certificates by care giver ID in the intygstjanst.CERTIFICATE table
SELECT CARE_GIVER_ID, COUNT(*) as count
FROM intygstjanst.CERTIFICATE
WHERE CARE_GIVER_ID IN (SELECT id FROM temp_care_giver_ids)
GROUP BY CARE_GIVER_ID
ORDER BY CARE_GIVER_ID;

-- Step 4: Query webcert database
-- Count signed certificates by care giver ID in the webcert.INTYG table
-- Note: Only counts certificates with STATUS = 'SIGNED'
SELECT VARDGIVAR_ID, COUNT(*) as count
FROM webcert.INTYG
WHERE VARDGIVAR_ID IN (SELECT id FROM temp_care_giver_ids)
  AND STATUS = 'SIGNED'
GROUP BY VARDGIVAR_ID
ORDER BY VARDGIVAR_ID;

-- Step 5: Query certificate_service database
-- Count signed certificates by unit HSA ID in the certificate_service
-- Joins certificate table with unit table to match HSA IDs
-- Note: Only counts certificates where c.signed = true
SELECT u.hsa_id, COUNT(*) as count
FROM certificate_service.certificate c
         INNER JOIN certificate_service.unit u ON u.`key` = c.care_provider_unit_key
WHERE u.hsa_id IN (SELECT id FROM temp_care_giver_ids)
  AND c.signed
GROUP BY u.hsa_id
ORDER BY u.hsa_id;

-- Step 6: Clean up temporary table
DROP TEMPORARY TABLE IF EXISTS temp_care_giver_ids;

