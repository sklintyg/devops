USE statistik;

DELIMITER $$
CREATE PROCEDURE updateOrganizationStatistik()

BEGIN
    -- Declare variables
    DECLARE updatedCareProviderId VARCHAR(50);
    DECLARE errorCode CHAR(5) DEFAULT '00000';
    DECLARE effectiveFromDate DATE DEFAULT '2026-02-01';
    DECLARE errorMessage TEXT;

    -- Declare handler
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            errorCode = RETURNED_SQLSTATE, errorMessage = MESSAGE_TEXT;
    END;

    SET updatedCareProviderId = 'SE2321000198-054374';

    -- Start transaction
    START TRANSACTION;

    -- Inactivate safe-updates as we are updating rows based on other columns than primary keys
    SET SQL_SAFE_UPDATES = 0;

    DROP TEMPORARY TABLE IF EXISTS organizationProvider;
    CREATE TEMPORARY TABLE organizationProvider(
        originalCareUnitId VARCHAR(50) NOT NULL COLLATE utf8mb3_general_ci,
        originalCareUnitName VARCHAR(100) NOT NULL COLLATE utf8mb3_general_ci,
        originalSubunitId VARCHAR(50) NOT NULL COLLATE utf8mb3_general_ci,
        originalSubunitName VARCHAR(100) NOT NULL COLLATE utf8mb3_general_ci,
        updatedCareUnitId VARCHAR(50) NOT NULL COLLATE utf8mb3_general_ci,
        updatedCareUnitName VARCHAR(100) NOT NULL COLLATE utf8mb3_general_ci,
        updatedSubunitId VARCHAR(50) NOT NULL COLLATE utf8mb3_general_ci,
        updatedSubunitName VARCHAR(100) NOT NULL COLLATE utf8mb3_general_ci
    );

    -- Insert original care provider IDs into the table variable
    INSERT INTO organizationProvider VALUES
        -- originalCareUnitId     originalCareUnitName               originalSubunitId      originalSubunitName                                         updatedCareUnitId      updatedCareUnitName                             updatedSubunitId       updatedSubunitName
        ('SE2321000198-019448', 'Primärvård Södra Hälsingland',     'SE2321000198-019456', 'Alfta Din hälsocentral S',                                 'SE2321000198-054394', 'VO Alfta Din hälsocentral',                    'SE2321000198-054443', 'Alfta Din hälsocentral'),
        ('SE2321000198-019448', 'Primärvård Södra Hälsingland',     'SE2321000198-021090', 'Barnavårdscentral Alfta Din hälsocentral S',               'SE2321000198-054394', 'VO Alfta Din hälsocentral',                    'SE2321000198-054444', 'Barnavårdscentral Alfta Din hälsocentral'),

        ('SE2321000198-019315', 'Primärvård Gävle',                 'SE2321000198-019318', 'Andersberg Din hälsocentral S',                            'SE2321000198-054377', 'VO Andersberg Din hälsocentral',               'SE2321000198-054410', 'Andersberg Din hälsocentral'),
        ('SE2321000198-019315', 'Primärvård Gävle',                 'SE2321000198-022588', 'Barnavårdscentral Andersberg Din hälsocentral S',          'SE2321000198-054377', 'VO Andersberg Din hälsocentral',               'SE2321000198-054411', 'Barnavårdscentral Andersberg Din hälsocentral'),

        ('SE2321000198-019448', 'Primärvård Södra Hälsingland',     'SE2321000198-019460', 'Arbrå Din hälsocentral S',                                 'SE2321000198-054395', 'VO Arbrå Din hälsocentral',                    'SE2321000198-054445', 'Arbrå Din hälsocentral'),
        ('SE2321000198-019448', 'Primärvård Södra Hälsingland',     'SE2321000198-020918', 'Barnavårdscentral Arbrå Din hälsocentral S',               'SE2321000198-054395', 'VO Arbrå Din hälsocentral',                    'SE2321000198-054446', 'Barnavårdscentral Arbrå Din hälsocentral'),

        ('SE2321000198-019340', 'Primärvård Hudiksvall',            'SE2321000198-019350', 'Delsbo - Friggesund Din hälsocentral S',                   'SE2321000198-054386', 'VO Delsbo - Friggesund Din hälsocentral',      'SE2321000198-054428', 'Delsbo - Friggesund Din hälsocentral'),
        ('SE2321000198-019340', 'Primärvård Hudiksvall',            'SE2321000198-021006', 'Barnavårdscentral Delsbo Din hälsocentral S',              'SE2321000198-054386', 'VO Delsbo - Friggesund Din hälsocentral',      'SE2321000198-054429', 'Barnavårdscentral Delsbo Din hälsocentral'),

        ('SE2321000198-019448', 'Primärvård Södra Hälsingland',     'SE2321000198-019457', 'Edsbyn Din hälsocentral S',                                'SE2321000198-054396', 'VO Edsbyn Din hälsocentral',                   'SE2321000198-054447', 'Edsbyn Din hälsocentral'),
        ('SE2321000198-019448', 'Primärvård Södra Hälsingland',     'SE2321000198-021096', 'Barnvårdscentral Edsbyn Din hälsocentral S',               'SE2321000198-054396', 'VO Edsbyn Din hälsocentral',                   'SE2321000198-054448', 'Barnvårdscentral Edsbyn Din hälsocentral'),

        ('SE2321000198-019363', 'Primärvård Ljusdal',               'SE2321000198-019370', 'Färila - Los Din hälsocentral S',                          'SE2321000198-054390', 'VO Färila - Los Din hälsocentral',             'SE2321000198-054434', 'Färila - Los Din hälsocentral'),
        ('SE2321000198-019363', 'Primärvård Ljusdal',               'SE2321000198-021163', 'Barnavårdscentral Färila - Los Din hälsocentral S',        'SE2321000198-054390', 'VO Färila - Los Din hälsocentral',             'SE2321000198-054435', 'Barnavårdscentral Färila - Los Din hälsocentral'),

        ('SE2321000198-019315', 'Primärvård Gävle',                 'SE2321000198-024141', 'Gävle Strand Din hälsocentral S',                          'SE2321000198-054378', 'VO Gävle Strand Din hälsocentral',             'SE2321000198-054412', 'Gävle Strand Din hälsocentral'),
        ('SE2321000198-019315', 'Primärvård Gävle',                 'SE2321000198-043530', 'Barnavårdscentral Gävle Strand Din hälsocentral S',        'SE2321000198-054378', 'VO Gävle Strand Din hälsocentral',             'SE2321000198-054413', 'Barnavårdscentral Gävle Strand Din hälsocentral'),

        ('SE2321000198-019315', 'Primärvård Gävle',                 'SE2321000198-019303', 'Hamrånge Din hälsocentral S',                              'SE2321000198-054379', 'VO Hamrånge Din hälsocentral',                 'SE2321000198-054414', 'Hamrånge Din hälsocentral'),
        ('SE2321000198-019315', 'Primärvård Gävle',                 'SE2321000198-020990', 'Barnavårdscentral Hamrånge Din hälsocentral S',            'SE2321000198-054379', 'VO Hamrånge Din hälsocentral',                 'SE2321000198-054415', 'Barnavårdscentral Hamrånge Din hälsocentral'),

        ('SE2321000198-019315', 'Primärvård Gävle',                 'SE2321000198-039751', 'Badverksamhet Gävle S',                                    'SE2321000198-054380', 'VO Hedesunda Färnebo Din hälsocentral',        'SE2321000198-054927', 'Badverksamhet Gävle'),
        ('SE2321000198-019315', 'Primärvård Gävle',                 'SE2321000198-020986', 'Barnavårdscentral Hedesunda Din hälsocentral S',           'SE2321000198-054380', 'VO Hedesunda Färnebo Din hälsocentral',        'SE2321000198-054417', 'Barnavårdscentral Hedesunda Din hälsocentral'),
        ('SE2321000198-019315', 'Primärvård Gävle',                 'SE2321000198-048874', 'Distriktssköterskemottagning Färnebo Din hälsocentral S',  'SE2321000198-054380', 'VO Hedesunda Färnebo Din hälsocentral',        'SE2321000198-054418', 'Distriktssköterskemottagning Färnebo Din hälsocentral'),
        ('SE2321000198-019315', 'Primärvård Gävle',                 'SE2321000198-019319', 'Hedesunda Färnebo Din hälsocentral S',                     'SE2321000198-054380', 'VO Hedesunda Färnebo Din hälsocentral',        'SE2321000198-054416', 'Hedesunda Färnebo Din hälsocentral'),

        ('SE2321000198-019471', 'Primärvård Västra Gästrikland',    'SE2321000198-020994', 'Barnavårdscentral Hofors Din hälsocentral S',              'SE2321000198-054401', 'VO Hofors Din hälsocentral',                   'SE2321000198-054461', 'Barnavårdscentral Hofors Din hälsocentral'),
        ('SE2321000198-019471', 'Primärvård Västra Gästrikland',    'SE2321000198-019476', 'Hofors Din hälsocentral S',                                'SE2321000198-054401', 'VO Hofors Din hälsocentral',                   'SE2321000198-054460', 'Hofors Din hälsocentral'),

        ('SE2321000198-019340', 'Primärvård Hudiksvall',            'SE2321000198-021015', 'Barnavårdscentral Hudiksvall Din hälsocentral S',          'SE2321000198-054387', 'VO Hudiksvall din hälsocentral',               'SE2321000198-054431', 'Barnavårdscentral Hudiksvall Din hälsocentral'),
        ('SE2321000198-019340', 'Primärvård Hudiksvall',            'SE2321000198-019343', 'Hudiksvall din hälsocentral S',                            'SE2321000198-054387', 'VO Hudiksvall din hälsocentral',               'SE2321000198-054430', 'Hudiksvall Din hälsocentral'),

        ('SE2321000198-019340', 'Primärvård Hudiksvall',            'SE2321000198-021665', 'Barnavårdscentral Iggesund Din hälsocentral S',            'SE2321000198-054388', 'VO Iggesund Din hälsocentral',                 'SE2321000198-054433', 'Barnavårdscentral Iggesund Din hälsocentral'),
        ('SE2321000198-019340', 'Primärvård Hudiksvall',            'SE2321000198-019352', 'Iggesund Din hälsocentral S',                              'SE2321000198-054388', 'VO Iggesund Din hälsocentral',                 'SE2321000198-054432', 'Iggesund Din hälsocentral'),

        ('SE2321000198-019363', 'Primärvård Ljusdal',               'SE2321000198-021657', 'Barnavårdscentral Järvsö Din hälsocentral S',              'SE2321000198-054391', 'VO Järvsö Din hälsocentral',                   'SE2321000198-054437', 'Barnavårdscentral Järvsö Din hälsocentral'),
        ('SE2321000198-019363', 'Primärvård Ljusdal',               'SE2321000198-019371', 'Järvsö Din hälsocentral S',                                'SE2321000198-054391', 'VO Järvsö Din hälsocentral',                   'SE2321000198-054436', 'Järvsö Din hälsocentral'),

        ('SE2321000198-019448', 'Primärvård Södra Hälsingland',     'SE2321000198-020932', 'Barnavårdscentral Kilafors Din hälsocentral S',            'SE2321000198-054397', 'VO Kilafors Din hälsocentral',                 'SE2321000198-054453', 'Barnavårdscentral Kilafors Din hälsocentral'),
        ('SE2321000198-019448', 'Primärvård Södra Hälsingland',     'SE2321000198-019458', 'Kilafors Din hälsocentral S',                              'SE2321000198-054397', 'VO Kilafors Din hälsocentral',                 'SE2321000198-054452', 'Kilafors Din hälsocentral'),

        ('SE2321000198-019448', 'Primärvård Södra Hälsingland',     'SE2321000198-021212', 'Barnavårdscentral Linden Din hälsocentral S',              'SE2321000198-054398', 'VO Linden Din hälsocentral',                   'SE2321000198-054451', 'Barnavårdscentral Linden Din hälsocentral'),
        ('SE2321000198-019448', 'Primärvård Södra Hälsingland',     'SE2321000198-019454', 'Linden Din hälsocentral S',                                'SE2321000198-054398', 'VO Linden Din hälsocentral',                   'SE2321000198-054450', 'Linden Din hälsocentral'),

        ('SE2321000198-019363', 'Primärvård Ljusdal',               'SE2321000198-021170', 'Barnavårdscentral Ljusdal - Ramsjö Din hälsocentral S',    'SE2321000198-054392', 'VO Ljusdal - Ramsjö Din hälsocentral',         'SE2321000198-054439', 'Barnavårdscentral Ljusdal - Ramsjö Din hälsocentral'),
        ('SE2321000198-019363', 'Primärvård Ljusdal',               'SE2321000198-019364', 'Ljusdal - Ramsjö Din hälsocentral S',                      'SE2321000198-054392', 'VO Ljusdal - Ramsjö Din hälsocentral',         'SE2321000198-054438', 'Ljusdal - Ramsjö Din hälsocentral'),

        ('SE2321000198-019471', 'Primärvård Västra Gästrikland',    'SE2321000198-021083', 'Barnavårdscentral Ockelbo Din hälsocentral S',             'SE2321000198-054402', 'VO Ockelbo Din hälsocentral',                  'SE2321000198-054463', 'Barnavårdscentral Ockelbo Din hälsocentral'),
        ('SE2321000198-019471', 'Primärvård Västra Gästrikland',    'SE2321000198-019477', 'Ockelbo Din hälsocentral S',                               'SE2321000198-054402', 'VO Ockelbo Din hälsocentral',                  'SE2321000198-054462', 'Ockelbo Din hälsocentral'),

        ('SE2321000198-019471', 'Primärvård Västra Gästrikland',    'SE2321000198-021126', 'Barnavårdscentral Sandviken Norra Din hälsocentral S',     'SE2321000198-054403', 'VO Sandviken Norra Din hälsocentral',          'SE2321000198-054465', 'Barnavårdscentral Sandviken Norra Din hälsocentral'),
        ('SE2321000198-019471', 'Primärvård Västra Gästrikland',    'SE2321000198-021123', 'Sandviken Norra Din hälsocentral S',                       'SE2321000198-054403', 'VO Sandviken Norra Din hälsocentral',          'SE2321000198-054464', 'Sandviken Norra Din hälsocentral'),

        ('SE2321000198-019471', 'Primärvård Västra Gästrikland',    'SE2321000198-021107', 'Barnavårdscentral Sandviken Södra Din hälsocentral S',     'SE2321000198-054404', 'VO Sandviken Södra Din hälsocentral',          'SE2321000198-054467', 'Barnavårdscentral Sandviken Södra Din hälsocentral'),
        ('SE2321000198-019471', 'Primärvård Västra Gästrikland',    'SE2321000198-021103', 'Sandviken Södra Din hälsocentral S',                       'SE2321000198-054404', 'VO Sandviken Södra Din hälsocentral',          'SE2321000198-054466', 'Sandviken Södra Din hälsocentral'),

        ('SE2321000198-019471', 'Primärvård Västra Gästrikland',    'SE2321000198-021143', 'Barnvårdscentral Storvik Din hälsocentral S',              'SE2321000198-054405', 'VO Storvik Din hälsocentral',                  'SE2321000198-054469', 'Barnvårdscentral Storvik Din hälsocentral'),
        ('SE2321000198-019471', 'Primärvård Västra Gästrikland',    'SE2321000198-019478', 'Storvik Din hälsocentral S',                               'SE2321000198-054405', 'VO Storvik Din hälsocentral',                  'SE2321000198-054468', 'Storvik Din hälsocentral'),

        ('SE2321000198-019315', 'Primärvård Gävle',                 'SE2321000198-020960', 'Barnavårdscentral Strömsbro Din hälsocentral S',           'SE2321000198-054381', 'VO Strömsbro Din hälsocentral',                'SE2321000198-054420', 'Barnavårdscentral Strömsbro Din hälsocentral'),
        ('SE2321000198-019315', 'Primärvård Gävle',                 'SE2321000198-018729', 'Strömsbro Din hälsocentral S',                             'SE2321000198-054381', 'VO Strömsbro Din hälsocentral',                'SE2321000198-054419', 'Strömsbro Din hälsocentral'),

        ('SE2321000198-019315', 'Primärvård Gävle',                 'SE2321000198-020952', 'Barnavårdscentral Sätra Din hälsocentral S',               'SE2321000198-054382', 'VO Sätra Din hälsocentral',                    'SE2321000198-054422', 'Barnavårdscentral Sätra Din hälsocentral'),
        ('SE2321000198-019315', 'Primärvård Gävle',                 'SE2321000198-019304', 'Sätra Din hälsocentral S',                                 'SE2321000198-054382', 'VO Sätra Din hälsocentral',                    'SE2321000198-054421', 'Sätra Din hälsocentral'),

        ('SE2321000198-019448', 'Primärvård Södra Hälsingland',     'SE2321000198-021191', 'Barnavårdscentral Söderhamn Din hälsocentral S',           'SE2321000198-054399', 'VO Söderhamn Din hälsocentral',                'SE2321000198-054455', 'Barnavårdscentral Söderhamn Din hälsocentral'),
        ('SE2321000198-019448', 'Primärvård Södra Hälsingland',     'SE2321000198-018728', 'Söderhamn Din hälsocentral S',                             'SE2321000198-054399', 'VO Söderhamn Din hälsocentral',                'SE2321000198-054454', 'Söderhamn Din hälsocentral'),

        ('SE2321000198-019315', 'Primärvård Gävle',                 'SE2321000198-020946', 'Barnavårdscentral Södertull Din hälsocentral S',           'SE2321000198-054383', 'VO Södertull Din hälsocentral',                'SE2321000198-054424', 'Barnavårdscentral Södertull Din hälsocentral'),
        ('SE2321000198-019315', 'Primärvård Gävle',                 'SE2321000198-019325', 'Södertull Din hälsocentral S',                             'SE2321000198-054383', 'VO Södertull Din hälsocentral',                'SE2321000198-054423', 'Södertull Din hälsocentral'),

        ('SE2321000198-019315', 'Primärvård Gävle',                 'SE2321000198-020940', 'Barnavårdscentral Valbo Din hälsocentral S',               'SE2321000198-054384', 'VO Valbo Din hälsocentral',                    'SE2321000198-054426', 'Barnavårdscentral Valbo Din hälsocentral'),
        ('SE2321000198-019315', 'Primärvård Gävle',                 'SE2321000198-048873', 'Handrehabilitering Valbo Din hälsocentral S',              'SE2321000198-054384', 'VO Valbo Din hälsocentral',                    'SE2321000198-054427', 'Handrehabilitering Valbo Din hälsocentral'),
        ('SE2321000198-019315', 'Primärvård Gävle',                 'SE2321000198-019317', 'Valbo Din hälsocentral S',                                 'SE2321000198-054384', 'VO Valbo Din hälsocentral',                    'SE2321000198-054425', 'Valbo Din hälsocentral');



    -- Insert new enhet to ENHET table if not exists
    INSERT INTO enhet (enhetId, namn, lansId, kommunId, verksamhetsTyper, vardgivareId, vardenhetId)
    SELECT
        op.updatedSubunitId,
        op.updatedSubunitName,
        '00',
        '00',
        '00',
        updatedCareProviderId,
        op.updatedCareUnitId
    FROM organizationProvider op
    WHERE NOT EXISTS (
        SELECT 1
        FROM enhet e
        WHERE e.enhetId = op.updatedSubunitId
    );

    -- Add new subunit for Badverksamhet Sandviken
    INSERT INTO enhet (enhetId, namn, lansId, kommunId, verksamhetsTyper, vardgivareId, vardenhetId)
    SELECT 'SE2321000198-054928', 'Badverksamhet Sandviken', '00', '00', '00', updatedCareProviderId, 'SE2321000198-054403'
    WHERE NOT EXISTS (
        SELECT 1
        FROM enhet e
        WHERE e.enhetId = 'SE2321000198-054928'
    );

    -- Update INTYGCOMMON table
    UPDATE intygcommon ic
    INNER JOIN organizationProvider op ON ic.enhet = op.originalSubunitId AND ic.signeringsdatum >= effectiveFromDate
    SET ic.enhet =  op.updatedSubunitId,
        ic.vardgivareid = updatedCareProviderId,
        ic.vardenhet = op.updatedCareUnitId;

    -- Update messagewideline table
    UPDATE messagewideline mwl
    INNER JOIN organizationProvider op ON mwl.enhet = op.originalSubunitId AND mwl.intygSigneringsdatum >= effectiveFromDate
    SET mwl.enhet =  op.updatedSubunitId,
        mwl.vardgivareid = updatedCareProviderId,
        mwl.vardenhet = op.updatedCareUnitId;

    -- Update wideline table
    UPDATE wideline wl
    INNER JOIN organizationProvider op ON wl.enhet = op.originalSubunitId
    INNER JOIN intygcommon ic ON wl.correlationId = ic.intygid AND ic.signeringsdatum >= effectiveFromDate
    SET wl.enhet =  op.updatedSubunitId,
        wl.vardgivareid = updatedCareProviderId,
        wl.vardenhet = op.updatedCareUnitId;

    DROP TEMPORARY TABLE IF EXISTS originalCareProviderIds;

    IF errorCode = '00000' THEN
            COMMIT;
            SELECT 'Updated organization successfully.';
    ELSE
        ROLLBACK;
        SELECT 'Transaction rolled back due to sql exception. No changes were introduced.';
        SELECT CONCAT('Stored procedure failed, error = ', errorCode, ', message = ', errorMessage);
    END IF;

    DROP TEMPORARY TABLE IF EXISTS update_report;

    -- Activate safe-updates again
    SET SQL_SAFE_UPDATES = 1;

END$$
DELIMITER ;

-- Call the stored procedure
CALL updateOrganizationStatistik;
DROP PROCEDURE updateOrganizationStatistik;