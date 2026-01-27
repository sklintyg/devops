USE webcert;

DELIMITER $$
CREATE PROCEDURE updateCareUnitWebcert()

BEGIN
    -- Declare variables
    DECLARE updatedCareProviderId VARCHAR(50);
    DECLARE updatedCareProviderName VARCHAR(100);
    DECLARE schemaVersion1Value TINYINT;
    DECLARE schemaVersion3Value TINYINT;
    DECLARE errorCode CHAR(5) DEFAULT '00000';
    DECLARE errorMessage TEXT;
    DECLARE customError VARCHAR(255) DEFAULT '';
    DECLARE originalCareProviderId VARCHAR(50);

    -- Declare handler
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            errorCode = RETURNED_SQLSTATE, errorMessage = MESSAGE_TEXT;
    END;

    SET originalCareProviderId = 'SE2321000198-016965';
    SET updatedCareProviderId = 'SE2321000198-054374';
    SET updatedCareProviderName = 'Region Gävleborg Din Hälsocentral AB';
    SET schemaVersion1Value = 0;
    SET schemaVersion3Value = 1;

    -- Check if care provider already exist
    SELECT COUNT(*) INTO @existingProviders
    FROM webcert.INTYG
    WHERE ENHETS_ID = updatedCareProviderId;

    IF @existingUnits > 0 THEN
        SET customError = CONCAT('One or more care units already exist, count: ', @existingProviders);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = customError;
    END IF;

    -- Inactivate safe-updates as we are updating rows based on other columns than primary keys
    SET SQL_SAFE_UPDATES = 0;

    DROP TEMPORARY TABLE IF EXISTS organizationProvider;
    CREATE TEMPORARY TABLE organizationProvider(
        originalId VARCHAR(50) NOT NULL COLLATE utf8mb3_general_ci,
        originalName VARCHAR(100) NOT NULL COLLATE utf8mb3_general_ci,
        updatedId VARCHAR(50) NOT NULL COLLATE utf8mb3_general_ci,
        updatedName VARCHAR(100) NOT NULL COLLATE utf8mb3_general_ci
    );

    -- Insert original care unit IDs into the table variable
    INSERT INTO organizationProvider
    VALUES
           ('SE2321000198-019456', 'Alfta Din hälsocentral S',                                  'SE2321000198-054443', 'Alfta Din hälsocentral'),
           ('SE2321000198-021090', 'Barnavårdscentral Alfta Din hälsocentral S',                'SE2321000198-054444', 'Barnavårdscentral Alfta Din hälsocentral'),

           ('SE2321000198-019318', 'Andersberg Din hälsocentral S',                             'SE2321000198-054410', 'Andersberg Din hälsocentral'),
           ('SE2321000198-022588', 'Barnavårdscentral Andersberg Din hälsocentral S',           'SE2321000198-054411', 'Barnavårdscentral Andersberg Din hälsocentral'),

           ('SE2321000198-019460', 'Arbrå Din hälsocentral S',                                  'SE2321000198-054445', 'Arbrå Din hälsocentral'),
           ('SE2321000198-020918', 'Barnavårdscentral Arbrå Din hälsocentral S',                'SE2321000198-054446', 'Barnavårdscentral Arbrå Din hälsocentral'),

           ('SE2321000198-019350', 'Delsbo - Friggesund Din hälsocentral S',                    'SE2321000198-054428', 'Delsbo - Friggesund Din hälsocentral'),
           ('SE2321000198-021006', 'Barnavårdscentral Delsbo Din hälsocentral S',               'SE2321000198-054429', 'Barnavårdscentral Delsbo Din hälsocentral'),

           ('SE2321000198-019457', 'Edsbyn Din hälsocentral S',                                 'SE2321000198-054448', 'Edsbyn Din hälsocentral'),
           ('SE2321000198-021096', 'Barnvårdscentral Edsbyn Din hälsocentral S',                'SE2321000198-054448', 'Barnvårdscentral Edsbyn Din hälsocentral'),

           ('SE2321000198-019370', 'Färila - Los Din hälsocentral S',                           'SE2321000198-054435', 'Barnavårdscentral Färila - Los Din hälsocentral'),
           ('SE2321000198-021163', 'Barnavårdscentral Färila - Los Din hälsocentral S',         'SE2321000198-054434', 'Färila - Los Din hälsocentral'),

           ('SE2321000198-024141', 'Gävle Strand Din hälsocentral S',                           'SE2321000198-054412', 'Gävle Strand Din hälsocentral'),
           ('SE2321000198-043530', 'Barnavårdscentral Gävle Strand Din hälsocentral S',         'SE2321000198-054413', 'Barnavårdscentral Gävle Strand Din hälsocentral'),

           ('SE2321000198-019303', 'Hamrånge Din hälsocentral S',                               'SE2321000198-054414', 'Hamrånge Din hälsocentral'),
           ('SE2321000198-020990', 'Barnavårdscentral Hamrånge Din hälsocentral S',             'SE2321000198-054415', 'Barnavårdscentral Hamrånge Din hälsocentral'),

           ('SE2321000198-039751', 'Badverksamhet Gävle S',                                     'SE2321000198-054927', 'Badverksamhet Gävle'),
           ('SE2321000198-020990', 'Barnavårdscentral Hamrånge Din hälsocentral S',             'SE2321000198-054417', 'Barnavårdscentral Hedesunda Din hälsocentral'),
           ('SE2321000198-048874', 'Distriktssköterskemottagning Färnebo Din hälsocentral S',   'SE2321000198-054418', 'Distriktssköterskemottagning Färnebo Din hälsocentral'),
           ('SE2321000198-019319', 'Hedesunda Färnebo Din hälsocentral S',                      'SE2321000198-054416', 'Hedesunda Färnebo Din hälsocentral'),

           ('SE2321000198-020994', 'Barnavårdscentral Hofors Din hälsocentral S',               'SE2321000198-054461', 'Barnavårdscentral Hofors Din hälsocentral'),
           ('SE2321000198-019476', 'Hofors Din hälsocentral S',                                 'SE2321000198-054460', 'Hofors Din hälsocentral'),

           ('SE2321000198-021015', 'Barnavårdscentral Hudiksvall Din hälsocentral S',           'SE2321000198-054431', 'Barnavårdscentral Hudiksvall Din hälsocentral'),
           ('SE2321000198-019343', 'Hudiksvall din hälsocentral S',                             'SE2321000198-054430', 'Hudiksvall Din hälsocentral'),

           ('SE2321000198-021665', 'Barnavårdscentral Iggesund Din hälsocentral S',             'SE2321000198-054433', 'Barnavårdscentral Iggesund Din hälsocentral'),
           ('SE2321000198-019352', 'Iggesund Din hälsocentral S',                               'SE2321000198-054432', 'Iggesund Din hälsocentral'),

           ('SE2321000198-021657', 'Barnavårdscentral Järvsö Din hälsocentral S',               'SE2321000198-054437', 'Barnavårdscentral Järvsö Din hälsocentral'),
           ('SE2321000198-019371', 'Järvsö Din hälsocentral S',                                 'SE2321000198-054436', 'Järvsö Din hälsocentral'),

           ('SE2321000198-020932', 'Barnavårdscentral Kilafors Din hälsocentral S',             'SE2321000198-054453', 'Barnavårdscentral Kilafors Din hälsocentral'),
           ('SE2321000198-019458', 'Kilafors Din hälsocentral S',                               'SE2321000198-054452', 'Kilafors Din hälsocentral'),

           ('SE2321000198-021212', 'Barnavårdscentral Linden Din hälsocentral S',               'SE2321000198-054451', 'Barnavårdscentral Linden Din hälsocentral'),
           ('SE2321000198-019454', 'Linden Din hälsocentral S',                                 'SE2321000198-054450', 'Linden Din hälsocentral'),

           ('SE2321000198-021170', 'Barnavårdscentral Ljusdal - Ramsjö Din hälsocentral S',     'SE2321000198-054439', 'Barnavårdscentral Ljusdal - Ramsjö Din hälsocentral'),
           ('SE2321000198-019364', 'Ljusdal - Ramsjö Din hälsocentral S',                       'SE2321000198-054438', 'Ljusdal - Ramsjö Din hälsocentral'),

           ('SE2321000198-021083', 'Barnavårdscentral Ockelbo Din hälsocentral S',              'SE2321000198-054463', 'Barnavårdscentral Ockelbo Din hälsocentral'),
           ('SE2321000198-019477', 'Ockelbo Din hälsocentral S',                                'SE2321000198-054462', 'Ockelbo Din hälsocentral'),


           ('SE2321000198-021126', 'Barnavårdscentral Sandviken Norra Din hälsocentral S',      'SE2321000198-054465', 'Barnavårdscentral Sandviken Norra Din hälsocentral'),
           ('SE2321000198-021123', 'Sandviken Norra Din hälsocentral S',                        'SE2321000198-054464', 'Sandviken Norra Din hälsocentral'),

           ('SE2321000198-021107', 'Barnavårdscentral Sandviken Södra Din hälsocentral S',      'SE2321000198-054467', 'Barnavårdscentral Sandviken Södra Din hälsocentral'),
           ('SE2321000198-021103', 'Sandviken Södra Din hälsocentral S',                        'SE2321000198-054466', 'Sandviken Södra Din hälsocentral'),

           ('SE2321000198-021143', 'Barnvårdscentral Storvik Din hälsocentral S',               'SE2321000198-054469', 'Barnvårdscentral Storvik Din hälsocentral'),
           ('SE2321000198-019478', 'Storvik Din hälsocentral S',                                'SE2321000198-054468', 'Storvik Din hälsocentral'),

           ('SE2321000198-020960', 'Barnavårdscentral Strömsbro Din hälsocentral S',            'SE2321000198-054420', 'Barnavårdscentral Strömsbro Din hälsocentral'),
           ('SE2321000198-018729', 'Strömsbro Din hälsocentral S',                              'SE2321000198-054419', 'Strömsbro Din hälsocentral'),

           ('SE2321000198-020952', 'Barnavårdscentral Sätra Din hälsocentral S',                'SE2321000198-054422', 'Barnavårdscentral Sätra Din hälsocentral'),
           ('SE2321000198-019304', 'Sätra Din hälsocentral S',                                  'SE2321000198-054421', 'Sätra Din hälsocentral'),

           ('SE2321000198-021191', 'Barnavårdscentral Söderhamn Din hälsocentral S',            'SE2321000198-054455', 'Barnavårdscentral Söderhamn Din hälsocentral'),
           ('SE2321000198-018728', 'Söderhamn Din hälsocentral S',                              'SE2321000198-054454', 'Söderhamn Din hälsocentral'),

           ('SE2321000198-020946', 'Barnavårdscentral Södertull Din hälsocentral S',            'SE2321000198-054424', 'Barnavårdscentral Södertull Din hälsocentral'),
           ('SE2321000198-019325', 'Södertull Din hälsocentral S',                              'SE2321000198-054423', 'Södertull Din hälsocentral'),

           ('SE2321000198-020940', 'Barnavårdscentral Valbo Din hälsocentral S',                'SE2321000198-054426', 'Barnavårdscentral Valbo Din hälsocentral'),
           ('SE2321000198-048873', 'Handrehabilitering Valbo Din hälsocentral S',               'SE2321000198-054427', 'Handrehabilitering Valbo Din hälsocentral'),
           ('SE2321000198-019317', 'Valbo Din hälsocentral S',                                  'SE2321000198-054425', 'Valbo Din hälsocentral');

    -- List units to update
    SELECT
        op.originalId,
        op.originalName,
        op.updatedId,
        op.updatedName,
        (SELECT COUNT(*) FROM FRAGASVAR f WHERE f.ENHETS_ID = op.originalId) AS fragasvar_count,
        (SELECT COUNT(*) FROM HANDELSE h WHERE h.ENHETS_ID = op.originalId) AS handelse_count,
        (SELECT COUNT(*) FROM INTEGRERADE_VARDENHETER iv WHERE iv.ENHETS_ID = op.originalId) AS integrerade_vardenheter_count,
        (SELECT COUNT(*) FROM INTYG i WHERE i.ENHETS_ID = op.originalId) AS intyg_count
    FROM organizationProvider op
    ORDER BY op.originalName;

    -- Verify all records belong to the original care provider
    SELECT COUNT(*) INTO @invalidFragasvar
    FROM FRAGASVAR f
    WHERE f.ENHETS_ID IN (SELECT originalId FROM organizationProvider)
      AND f.VARDGIVAR_ID != originalCareProviderId;

    IF @invalidFragasvar > 0 THEN
        SET customError = CONCAT('Some FRAGASVAR records do not belong to the expected care provider ', originalCareProviderId, '. Count: ', @invalidFragasvar);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = customError;
    END IF;

    SELECT COUNT(*) INTO @invalidHandelse
    FROM HANDELSE h
    WHERE h.ENHETS_ID IN (SELECT originalId FROM organizationProvider)
      AND h.VARDGIVAR_ID != originalCareProviderId;

    IF @invalidHandelse > 0 THEN
        SET customError = CONCAT('Some HANDELSE records do not belong to the expected care provider ', originalCareProviderId, '. Count: ', @invalidHandelse);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = customError;
    END IF;

    SELECT COUNT(*) INTO @invalidIntegreradeVardenheter
    FROM INTEGRERADE_VARDENHETER iv
    WHERE iv.ENHETS_ID IN (SELECT originalId FROM organizationProvider)
      AND iv.VARDGIVAR_ID != originalCareProviderId;

    IF @invalidIntegreradeVardenheter > 0 THEN
        SET customError = CONCAT('Some INTEGRERADE_VARDENHETER records do not belong to the expected care provider ', originalCareProviderId, '. Count: ', @invalidIntegreradeVardenheter);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = customError;
    END IF;

    SELECT COUNT(*) INTO @invalidIntyg
    FROM INTYG i
    WHERE i.ENHETS_ID IN (SELECT originalId FROM organizationProvider)
      AND i.VARDGIVAR_ID != originalCareProviderId;

    IF @invalidIntyg > 0 THEN
        SET customError = CONCAT('Some INTYG records do not belong to the expected care provider ', originalCareProviderId, '. Count: ', @invalidIntyg);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = customError;
    END IF;

    -- Start transaction
    START TRANSACTION;

    -- Update FRAGASVAR table
    UPDATE FRAGASVAR f
    INNER JOIN organizationProvider i ON f.ENHETS_ID = i.originalId
    SET f.ENHETS_ID = i.updatedId,
        f.ENHETSNAMN = i.updatedName,
        f.VARDGIVAR_ID = updatedCareProviderId,
        f.VARDGIVARNAMN = updatedCareProviderName;
    SELECT ROW_COUNT() INTO @fragasvarUpdated;

    -- Update HANDELSE table
    UPDATE HANDELSE f
    INNER JOIN organizationProvider i ON f.ENHETS_ID = i.originalId
    SET f.ENHETS_ID = i.updatedId,
        f.VARDGIVAR_ID = updatedCareProviderId;
    SELECT ROW_COUNT() INTO @handelseUpdated;

    -- Update INTEGRERADE_VARDENHETER table where ENHETS_ID matches originalId
    UPDATE INTEGRERADE_VARDENHETER f
    INNER JOIN organizationProvider i ON f.ENHETS_ID = i.originalId
    SET f.ENHETS_ID = i.updatedId,
        f.ENHETS_NAMN = i.updatedName,
        f.VARDGIVAR_ID = updatedCareProviderId,
        f.VARDGIVAR_NAMN = updatedCareProviderName;
    SELECT ROW_COUNT() INTO @integreradeVardenheterUpdated;

    -- Insert new records for updatedIds that don't exist yet in INTEGRERADE_VARDENHETER
    INSERT INTO INTEGRERADE_VARDENHETER (ENHETS_ID, ENHETS_NAMN, VARDGIVAR_ID, VARDGIVAR_NAMN, SKAPAD_DATUM, SCHEMA_VERSION_1, SCHEMA_VERSION_3)
    SELECT i.updatedId, i.updatedName, updatedCareProviderId, updatedCareProviderName, NOW(), schemaVersion1Value, schemaVersion3Value
    FROM organizationProvider i
    WHERE NOT EXISTS (
        SELECT 1 FROM INTEGRERADE_VARDENHETER f
        WHERE f.ENHETS_ID = i.updatedId
    );
    SELECT ROW_COUNT() INTO @integreradeVardenheterInserted;

    -- Update INTYG table
    UPDATE INTYG f
    INNER JOIN organizationProvider i ON f.ENHETS_ID = i.originalId
    SET f.ENHETS_ID = i.updatedId,
        f.ENHETS_NAMN = i.updatedName,
        f.VARDGIVAR_ID = updatedCareProviderId,
        f.VARDGIVAR_NAMN = updatedCareProviderName;
    SELECT ROW_COUNT() INTO @intygUpdated;

    -- Summary before commit
    SELECT
        op.originalId,
        op.originalName,
        op.updatedId,
        op.updatedName,
        CASE
            WHEN EXISTS(SELECT 1 FROM INTEGRERADE_VARDENHETER iv WHERE iv.ENHETS_ID = op.updatedId LIMIT 1) THEN 'Updated'
            ELSE 'Not Found'
            END AS update_status,
        (SELECT COUNT(*) FROM FRAGASVAR f WHERE f.ENHETS_ID = op.updatedId) AS fragasvar_count,
        (SELECT COUNT(*) FROM HANDELSE h WHERE h.ENHETS_ID = op.updatedId) AS handelse_count,
        (SELECT COUNT(*) FROM INTEGRERADE_VARDENHETER iv WHERE iv.ENHETS_ID = op.updatedId) AS integrerade_vardenheter_count,
        (SELECT COUNT(*) FROM INTYG i WHERE i.ENHETS_ID = op.updatedId) AS intyg_count
    FROM organizationProvider op
    ORDER BY update_status DESC, op.originalName;

    SELECT
        @fragasvarUpdated AS total_fragasvar_updated,
        @handelseUpdated AS total_handelse_updated,
        @integreradeVardenheterUpdated AS total_integrerade_vardenheter_updated,
        @integreradeVardenheterInserted AS total_integrerade_vardenheter_inserted,
        @intygUpdated AS total_intyg_updated;

    DROP TEMPORARY TABLE IF EXISTS organizationProvider;

    IF errorCode = '00000' THEN
        COMMIT;
        SELECT 'Updated care units successfully.';
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
CALL updateCareUnitWebcert;
DROP PROCEDURE updateCareUnitWebcert;
