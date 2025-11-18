DELIMITER $$

DROP PROCEDURE IF EXISTS GenerateCertificates$$

CREATE PROCEDURE GenerateCertificates(IN numberOfCertificates INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE newIntygsId VARCHAR(64);
    DECLARE newPatientId VARCHAR(255);
    DECLARE baseDate DATETIME DEFAULT '2024-11-18 00:00:00';

    WHILE i <= numberOfCertificates DO
            -- Generate unique INTYGS_ID (UUID format)
            SET newIntygsId = CONCAT(
                    SUBSTRING(UUID(), 1, 8), '-',
                    SUBSTRING(UUID(), 10, 4), '-',
                    SUBSTRING(UUID(), 15, 4), '-',
                    SUBSTRING(UUID(), 20, 4), '-',
                    SUBSTRING(UUID(), 25, 12)
                              );

            -- Generate varied patient ID (keeping format YYYYMMDD-NNNN)
            SET newPatientId = ELT(
                    FLOOR(1 + RAND() * 5),
                    '19790124-2391',
                    '20021029-2389',
                    '19960628-2391',
                    '19401130-6125',
                    '19931230-2384'
                               );

            INSERT INTO INTYG (
                INTYGS_ID,
                INTYGS_TYP,
                ENHETS_ID,
                ENHETS_NAMN,
                VARDGIVAR_ID,
                VARDGIVAR_NAMN,
                PATIENT_PERSONNUMMER,
                PATIENT_FORNAMN,
                PATIENT_MELLANNAMN,
                PATIENT_EFTERNAMN,
                SENAST_SPARAD_DATUM,
                MODEL,
                STATUS,
                SKAPAD_AV_HSAID,
                SKAPAD_AV_NAMN,
                SENAST_SPARAD_AV_HSAID,
                SENAST_SPARAD_AV_NAMN,
                VIDAREBEFORDRAD,
                VERSION,
                SKICKAD_TILL_MOTTAGARE_DATUM,
                ATERKALLAD_DATUM,
                SKICKAD_TILL_MOTTAGARE,
                RELATION_INTYG_ID,
                RELATION_KOD,
                KLART_FOR_SIGNERING_DATUM,
                SKAPAD,
                INTYG_TYPE_VERSION,
                TEST_INTYG
            ) VALUES (
                         newIntygsId,
                         'luse',
                         'SE4815162344-1A03',
                         'WebCert-Integration Enhet 2',
                         'TSTNMT2321000156-ALFA',
                         'Alfa Regionen',
                         newPatientId,
                         'Athena',
                         'React',
                         'Andersson',
                         DATE_ADD(baseDate, INTERVAL i MINUTE),
                         CONCAT('{"id":"', newIntygsId, '","grundData":{"skapadAv":{"personId":"TSTNMT2321000156-DRAA","fullstandigtNamn":"Ajla Doktor","forskrivarKod":"0000000","befattningar":["204010"],"befattningsKoder":[{"kod":"204010","klartext":"Läkare ej legitimerad, allmäntjänstgöring"}],"specialiteter":[],"vardenhet":{"enhetsid":"TSTNMT2321000156-ALMC","enhetsnamn":"Alfa Medicincentrum","postadress":"Storgatan 1","postnummer":"12345","postort":"Småmåla","telefonnummer":"0101234567890","epost":"AlfaMC@webcert.invalid.se","vardgivare":{"vardgivarid":"TSTNMT2321000156-ALFA","vardgivarnamn":"Alfa Regionen"},"arbetsplatsKod":"1234567890"}},"patient":{"personId":"', newPatientId, '","addressDetailsSourcePU":false,"sekretessmarkering":false,"avliden":false,"testIndicator":false,"samordningsNummer":false},"testIntyg":false},"textVersion":"1.3","undersokningAvPatienten":"2024-11-18","kannedomOmPatient":"2024-10-09","underlagFinns":false,"underlag":[],"sjukdomsforlopp":"asd","diagnoser":[{"diagnosKod":"A00","diagnosKodSystem":"ICD_10_SE","diagnosBeskrivning":"Kolera","diagnosDisplayName":"Kolera"}],"diagnosgrund":"asda","nyBedomningDiagnosgrund":false,"tillaggsfragor":[],"typ":"luse"}'),
                         'DRAFT_INCOMPLETE',
                         'TSTNMT2321000156-DRAA',
                         'Ajla Doktor',
                         'TSTNMT2321000156-DRAA',
                         'Ajla Doktor',
                         0,
                         5,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         NULL,
                         baseDate,
                         '1.3',
                         0
                     );

            SET i = i + 1;
        END WHILE;
END$$

DELIMITER ;

-- To generate 100 certificates, run:
-- CALL GenerateCertificates(100);

