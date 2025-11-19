-- Script to generate multiple certificate entries with related certificate_xml and certificate_data
-- Usage: Call the procedure with the number of certificates to generate
-- Example: CALL generate_certificates(100);

DELIMITER $$

DROP PROCEDURE IF EXISTS generate_certificates$$

CREATE PROCEDURE generate_certificates(IN num_certificates INT)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE new_certificate_id VARCHAR(64);
    DECLARE new_certificate_key BIGINT;
    DECLARE xml_data MEDIUMBLOB;
    DECLARE cert_data MEDIUMBLOB;

    -- Get the XML and certificate data from key 15 to use as template
    SELECT data INTO xml_data FROM certificate_xml WHERE `key` = 15;
    SELECT data INTO cert_data FROM certificate_data WHERE `key` = 15;

    -- Loop to create certificates
    WHILE i < num_certificates
        DO
            -- Generate a new UUID for certificate_id
            SET new_certificate_id = UUID();

            -- Insert into certificate table (matching the template from key 15)
            INSERT INTO certificate (certificate_id,
                                     certificate_model_key,
                                     certificate_status_key,
                                     patient_key,
                                     created,
                                     created_by_staff_key,
                                     modified,
                                     signed,
                                     sent,
                                     revoked,
                                     locked,
                                     ready_for_sign,
                                     issued_by_staff_key,
                                     sent_by_staff_key,
                                     revoked_by_staff_key,
                                     ready_for_sign_by_staff_key,
                                     issued_on_unit_key,
                                     care_unit_unit_key,
                                     care_provider_unit_key,
                                     revision,
                                     revoked_reason_key,
                                     revoked_message,
                                     forwarded)
            VALUES (new_certificate_id, -- certificate_id (generated UUID)
                    2, -- certificate_model_key
                    1, -- certificate_status_key
                    2, -- patient_key
                    '2024-10-31 08:46:07', -- created
                    2, -- created_by_staff_key
                    '2025-10-31 08:46:07', -- modified
                    NULL, -- signed
                    NULL, -- sent
                    NULL, -- revoked
                    NULL, -- locked
                    NULL, -- ready_for_sign
                    2, -- issued_by_staff_key
                    NULL, -- sent_by_staff_key
                    NULL, -- revoked_by_staff_key
                    NULL, -- ready_for_sign_by_staff_key
                    3, -- issued_on_unit_key
                    3, -- care_unit_unit_key
                    2, -- care_provider_unit_key
                    1, -- revision
                    NULL, -- revoked_reason_key
                    NULL, -- revoked_message
                    0 -- forwarded
                   );

            -- Get the auto-generated key
            SET new_certificate_key = LAST_INSERT_ID();

            -- Insert into certificate_data with the same key
            INSERT INTO certificate_data (`key`, data)
            VALUES (new_certificate_key, cert_data);

            SET i = i + 1;
        END WHILE;

    -- Output summary
    SELECT CONCAT('Successfully created ', num_certificates, ' certificates') AS result;

END$$

DELIMITER ;

-- Example usage (commented out - uncomment to run):
-- CALL generate_certificates(100);

-- To see the generated certificates:
-- SELECT certificate_id, `key`, created FROM certificate ORDER BY `key` DESC LIMIT 10;


