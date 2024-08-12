USE certificate_service;
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE certificate;
TRUNCATE TABLE certificate_data;
TRUNCATE TABLE certificate_model;
TRUNCATE TABLE certificate_relation;
TRUNCATE TABLE certificate_xml;
TRUNCATE TABLE external_reference;
TRUNCATE TABLE message;
TRUNCATE TABLE message_complement;
TRUNCATE TABLE message_contact_info;
TRUNCATE TABLE message_relation;
TRUNCATE TABLE patient;
TRUNCATE TABLE staff;
TRUNCATE TABLE staff_healthcare_professional_licence;
TRUNCATE TABLE staff_pa_title;
TRUNCATE TABLE staff_speciality;
TRUNCATE TABLE unit;
SET FOREIGN_KEY_CHECKS = 1;