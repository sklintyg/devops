-- MYSQL script for initiation of manual redeliveries of CertificateStatusUpdate(s)ForCare
-- based on a list of certificate ids.
Use webcert;

DELIMITER $$
CREATE PROCEDURE initiateManualRedeliveries()
BEGIN
    DECLARE currentCertificateId VARCHAR(255);
    DECLARE currentEventId BIGINT(20);
    DECLARE certificateTypeInternal VARCHAR(255);
    DECLARE certificateTypeExternal VARCHAR(255);
    DECLARE certificateVersion VARCHAR(255);
    DECLARE certificateIssuer VARCHAR(255);
    DECLARE existingCertificate VARCHAR(255);
    DECLARE existingMetadata VARCHAR(255) ;
	DECLARE existingRedelivery VARCHAR(255);

	-- Create temporary table holding certificate ids for which redelivery of all events should be performed.
    -- When appropriate, the below section with hardcoded certificate id's can be replaced with an sql-query for
    -- collection of id's for redelivery. (Based on, for example, care unit or a certain period in time.
	DROP TEMPORARY TABLE IF EXISTS CERTIFICATE_IDS;
	CREATE TEMPORARY TABLE CERTIFICATE_IDS AS (SELECT DISTINCT(INTYGS_ID) AS certificate_id, 0 AS processed FROM HANDELSE WHERE INTYGS_ID IN (
	    'certificate-id-1',
	    'certificate-id-2'
    ));

    -- Add index certificate_id to table CERTIFICATE_IDS, (or updates to the temp table will not be permitted).
    ALTER TABLE CERTIFICATE_IDS ADD INDEX (certificate_id);

    -- Create accessory table for conversion of internal to external cartificateType.
    DROP TEMPORARY TABLE IF EXISTS CERTIFICATE_TYPES;
    CREATE TEMPORARY TABLE CERTIFICATE_TYPES(internal VARCHAR(255), external VARCHAR(255));
    INSERT INTO CERTIFICATE_TYPES(internal, external) VALUES ('lisjp', 'LISJP'), ('fk7263', 'FK7263'), ('luse', 'LUSE'),
         ('luae_na', 'LUAE_NA'), ('luae_fs', 'LUAE_FS'), ('db', 'DB'), ('doi', 'DOI'), ('af00213', 'AF00213'), ('ag114', 'AG1-14'),
         ('ag7804', 'AG7804'), ('af00251', 'AF00251'), ('tstrk1062', 'TSTRK1062'), ('tstrk1009', 'TSTRK1009'), ('ts-bas', 'TSTRK1007'),
         ('ts-diabetes', 'TSTRK1031');

    -- Create temporary table for holding events of the looped certificate id's.
    -- Add index to event_id to table EVENT_IDS, (or updates to the temp table will not be permitted).
    DROP TEMPORARY TABLE IF EXISTS EVENT_IDS;
	CREATE TEMPORARY TABLE EVENT_IDS(event_id BIGINT(20), processed INT);
    ALTER TABLE EVENT_IDS ADD INDEX (event_id);

    -- Loop through certificate ids (table CERTIFICATE_IDS)
    WHILE (SELECT COUNT(*) FROM CERTIFICATE_IDS WHERE processed = 0) > 0
    DO
        SET existingCertificate = null;
        SET certificateTypeInternal = null;
		SET certificateTypeExternal = null;
		SET certificateVersion = null;
		SET certificateIssuer = null;

        -- Set the current certificate id in variable currentCertificateId
        SELECT certificate_id FROM CERTIFICATE_IDS WHERE processed = 0 LIMIT 1 INTO currentCertificateId;

        -- Fetch certificate if it exists, including data needed for creation of metadata record
        SELECT INTYGS_ID, INTYGS_TYP, INTYG_TYPE_VERSION, SKAPAD_AV_HSAID FROM INTYG WHERE INTYGS_ID = currentCertificateId LIMIT 1
        INTO existingCertificate, certificateTypeInternal, certificateVersion, certificateIssuer;

        -- If certificate exists, translate internal certificateType to external certificateType using
        -- accessory table CERTIFICATE_TYPES
        IF (existingCertificate IS NOT NULL AND existingCertificate != '') THEN
            SELECT external FROM CERTIFICATE_TYPES WHERE internal = certificateTypeInternal LIMIT 1 into certificateTypeExternal;
        END IF;

        -- Clear table EVENT_IDS and insert all available events, sorted in ascending order by event id,
        -- for the certificate id currently being processed.
        TRUNCATE EVENT_IDS;
        INSERT INTO EVENT_IDS(event_id, processed) SELECT ID AS event_id, 0 AS processed FROM HANDELSE WHERE INTYGS_ID = currentCertificateId ORDER BY ID ASC;

        -- Loop events of current certificate id.
        WHILE (SELECT COUNT(*) FROM EVENT_IDS WHERE processed = 0) > 0
		DO
            SET existingRedelivery = null;
            SET existingMetadata = null;

			-- Set currently processed event id in variable currentEventId
            SELECT event_id FROM EVENT_IDS WHERE processed = 0 LIMIT 1 INTO currentEventId;

            -- Fetch redelivery for current event if exists
            SELECT HANDELSE_ID FROM NOTIFICATION_REDELIVERY WHERE HANDELSE_ID = currentEventId LIMIT 1 INTO existingRedelivery;

            -- Consider creating redelivery only if current event not already in NOTIFICATION_REDELIVERY table
            IF (existingRedelivery IS NULL OR existingRedelivery = '') THEN

                -- Fetch metadata for current event if exists.
                SELECT HANDELSE_ID FROM HANDELSE_METADATA WHERE HANDELSE_ID = currentEventId LIMIT 1 INTO existingMetadata;

                -- Create redelivery only if a certificate and/or a metadata record exists for the current event.
                -- This will exclude all events for deleted certificates that were created before release 2021-1.
                IF ((existingCertificate IS NOT NULL AND existingCertificate != '') OR (existingMetadata IS NOT NULL AND existingMetadata != '')) THEN

					-- If there is no metadata record for current event, create one based on the existing certificate.
					IF (existingMetadata IS NULL OR existingMetadata = '') THEN
						INSERT INTO HANDELSE_METADATA(HANDELSE_ID, DELIVERY_STATUS, CERTIFICATE_TYPE, CERTIFICATE_VERSION, CERTIFICATE_ISSUER)
						VALUES (currentEventId, 'RESEND', certificateTypeExternal, certificateVersion, certificateIssuer);
                    END IF;

					-- Create a record in redelivery table for the event being processed.
                    INSERT INTO NOTIFICATION_REDELIVERY (HANDELSE_ID, REDELIVERY_STRATEGY, REDELIVERY_TIME)
                    VALUES(currentEventId, 'STANDARD', now());
                END IF;
            END IF;

			-- Flag current event id as processed.
            UPDATE EVENT_IDS SET processed = 1 WHERE event_id = currentEventId;
        END WHILE;

        -- Flag current certificate id as processed.
        UPDATE CERTIFICATE_IDS SET processed = 1 WHERE certificate_id = currentCertificateId;
    END WHILE;

    -- Clean up by dropping all temporary tables.
    DROP TEMPORARY TABLE IF EXISTS EVENT_IDS;
    DROP TEMPORARY TABLE IF EXISTS CERTIFICATE_IDS;
    DROP TEMPORARY TABLE IF EXISTS CERTIFICATE_TYPES;
END$$
DELIMITER ;

-- Call the stored procedure
CALL initiateManualRedeliveries;
DROP PROCEDURE initiateManualRedeliveries;