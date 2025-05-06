USE certificate_service;

-- Step 1: Retrieve the key for the new hsa_id
SET @new_key = (SELECT `key` FROM unit WHERE hsa_id = 'SE2321000016-39KJ');

-- Step 2: Update the care_provider_unit_key in the certificate table
UPDATE certificate
SET care_provider_unit_key = @new_key
WHERE care_provider_unit_key IN (
    SELECT `key` FROM unit WHERE hsa_id IN ('SE2321000016-1K2W', 'SE2321000016-11LS', 'SE2321000016-12B8', 'SE2321000016-3CLH')
);