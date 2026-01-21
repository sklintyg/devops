USE webcert;

DELIMITER $$
CREATE PROCEDURE updateCareUnitWebcert()

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

    SET updatedCareProviderId = 'SE2321000198-054374';
    SET updatedCareProviderName = 'Region Gävleborg Din Hälsocentral AB';

    -- Start transaction
    START TRANSACTION;

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

    -- Update FRAGASVAR table
    UPDATE FRAGASVAR f
    INNER JOIN organizationProvider i ON f.ENHETS_ID = i.originalId
    SET f.ENHETS_ID = i.updatedId,
        f.ENHETSNAMN = i.updatedName,
        f.VARDGIVAR_ID = updatedCareProviderId,
        f.VARDGIVARNAMN = updatedCareProviderName;

    -- Update HANDELSE table
    UPDATE HANDELSE f
    INNER JOIN organizationProvider i ON f.ENHETS_ID = i.originalId
    SET f.ENHETS_ID = i.updatedId,
        f.VARDGIVAR_ID = updatedCareProviderId;

    -- Update INTEGRERADE_VARDENHETER table
    UPDATE INTEGRERADE_VARDENHETER f
    INNER JOIN organizationProvider i ON f.ENHETS_ID = i.originalId
    SET f.ENHETS_ID = i.updatedId,
        f.ENHETS_NAMN = i.updatedName,
        f.VARDGIVAR_ID = updatedCareProviderId,
        f.VARDGIVAR_NAMN = updatedCareProviderName;

    -- Update INTYG table
    UPDATE INTYG f
    INNER JOIN organizationProvider i ON f.ENHETS_ID = i.originalId
    SET f.ENHETS_ID = i.updatedId,
        f.ENHETS_NAMN = i.updatedName,
        f.VARDGIVAR_ID = updatedCareProviderId,
        f.VARDGIVAR_NAMN = updatedCareProviderName;

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
