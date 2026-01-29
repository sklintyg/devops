USE certificate_service;

-- Create temporary tables for original and updated unit IDs
DROP TEMPORARY TABLE IF EXISTS original_units;
CREATE TEMPORARY TABLE original_units (
    o_hsa_id VARCHAR(50) PRIMARY KEY
);

DROP TEMPORARY TABLE IF EXISTS updated_units;
CREATE TEMPORARY TABLE updated_units (
    u_hsa_id VARCHAR(50) PRIMARY KEY
);

-- Insert original unit IDs
INSERT INTO original_units VALUES
                               ('SE2321000198-019456'), ('SE2321000198-021090'),
                               ('SE2321000198-019318'), ('SE2321000198-022588'),
                               ('SE2321000198-019460'), ('SE2321000198-020918'),
                               ('SE2321000198-019350'), ('SE2321000198-021006'),
                               ('SE2321000198-019457'), ('SE2321000198-021096'),
                               ('SE2321000198-019370'), ('SE2321000198-021163'),
                               ('SE2321000198-024141'), ('SE2321000198-043530'),
                               ('SE2321000198-019303'), ('SE2321000198-020990'),
                               ('SE2321000198-039751'), ('SE2321000198-048874'),
                               ('SE2321000198-019319'), ('SE2321000198-020994'),
                               ('SE2321000198-019476'), ('SE2321000198-021015'),
                               ('SE2321000198-019343'), ('SE2321000198-021665'),
                               ('SE2321000198-019352'), ('SE2321000198-021657'),
                               ('SE2321000198-019371'), ('SE2321000198-020932'),
                               ('SE2321000198-019458'), ('SE2321000198-021212'),
                               ('SE2321000198-019454'), ('SE2321000198-021170'),
                               ('SE2321000198-019364'), ('SE2321000198-021083'),
                               ('SE2321000198-019477'), ('SE2321000198-021126'),
                               ('SE2321000198-021123'), ('SE2321000198-021107'),
                               ('SE2321000198-021103'), ('SE2321000198-021143'),
                               ('SE2321000198-019478'), ('SE2321000198-020960'),
                               ('SE2321000198-018729'), ('SE2321000198-020952'),
                               ('SE2321000198-019304'), ('SE2321000198-021191'),
                               ('SE2321000198-018728'), ('SE2321000198-020946'),
                               ('SE2321000198-019325'), ('SE2321000198-020940'),
                               ('SE2321000198-048873'), ('SE2321000198-019317');

-- Insert updated unit IDs
INSERT INTO updated_units VALUES
                              ('SE2321000198-054443'), ('SE2321000198-054444'),
                              ('SE2321000198-054410'), ('SE2321000198-054411'),
                              ('SE2321000198-054445'), ('SE2321000198-054446'),
                              ('SE2321000198-054428'), ('SE2321000198-054429'),
                              ('SE2321000198-054448'), ('SE2321000198-054435'),
                              ('SE2321000198-054434'), ('SE2321000198-054412'),
                              ('SE2321000198-054413'), ('SE2321000198-054414'),
                              ('SE2321000198-054415'), ('SE2321000198-054927'),
                              ('SE2321000198-054417'), ('SE2321000198-054418'),
                              ('SE2321000198-054416'), ('SE2321000198-054461'),
                              ('SE2321000198-054460'), ('SE2321000198-054431'),
                              ('SE2321000198-054430'), ('SE2321000198-054433'),
                              ('SE2321000198-054432'), ('SE2321000198-054437'),
                              ('SE2321000198-054436'), ('SE2321000198-054453'),
                              ('SE2321000198-054452'), ('SE2321000198-054451'),
                              ('SE2321000198-054450'), ('SE2321000198-054439'),
                              ('SE2321000198-054438'), ('SE2321000198-054463'),
                              ('SE2321000198-054462'), ('SE2321000198-054465'),
                              ('SE2321000198-054464'), ('SE2321000198-054467'),
                              ('SE2321000198-054466'), ('SE2321000198-054469'),
                              ('SE2321000198-054468'), ('SE2321000198-054420'),
                              ('SE2321000198-054419'), ('SE2321000198-054422'),
                              ('SE2321000198-054421'), ('SE2321000198-054455'),
                              ('SE2321000198-054454'), ('SE2321000198-054424'),
                              ('SE2321000198-054423'), ('SE2321000198-054426'),
                              ('SE2321000198-054427'), ('SE2321000198-054425');

-- Total certificates that will be updated
SELECT COUNT(c.certificate_id) AS total_certificates_to_update
FROM certificate c
         INNER JOIN unit u ON c.issued_on_unit_key = u.`key`
         INNER JOIN original_units orig ON u.hsa_id = orig.o_hsa_id
WHERE c.created >= '2025-01-14 00:00:00';

-- Original care units with unexpected care provider
SELECT
    u.hsa_id AS original_unit_id,
    u.name AS original_unit_name,
    cp.hsa_id AS current_care_provider_id,
    cp.name AS current_care_provider_name,
    COUNT(c.certificate_id) AS certificate_count
FROM unit u
         INNER JOIN certificate c ON c.issued_on_unit_key = u.`key`
         INNER JOIN unit cp ON c.care_provider_unit_key = cp.`key`
         INNER JOIN original_units orig ON u.hsa_id = orig.o_hsa_id
WHERE cp.hsa_id != 'SE2321000198-016965'
GROUP BY u.hsa_id, u.name, cp.hsa_id, cp.name;

-- Cleanup
DROP TEMPORARY TABLE IF EXISTS original_units;
DROP TEMPORARY TABLE IF EXISTS updated_units;
