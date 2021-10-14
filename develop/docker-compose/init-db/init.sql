CREATE DATABASE intyg;
CREATE USER 'intyg'@'%' IDENTIFIED BY 'intyg';
GRANT ALL PRIVILEGES ON * . * TO 'intyg'@'%' WITH GRANT OPTION;

CREATE DATABASE intygsadmin;
CREATE USER 'intygsadmin'@'%' IDENTIFIED BY 'intygsadmin';
GRANT ALL PRIVILEGES ON * . * TO 'intygsadmin'@'%' WITH GRANT OPTION;

CREATE DATABASE statistik;
CREATE USER 'statistik'@'%' IDENTIFIED BY 'statistik';
GRANT ALL PRIVILEGES ON * . * TO 'statistik'@'%' WITH GRANT OPTION;

CREATE DATABASE intygsbestallning;
CREATE USER 'intygsbestallning'@'%' IDENTIFIED BY 'intygsbestallning';
GRANT ALL PRIVILEGES ON * . * TO 'intygsbestallning'@'%' WITH GRANT OPTION;

CREATE DATABASE privatlakarportal;
CREATE USER 'privatlakarportal'@'%' IDENTIFIED BY 'privatlakarportal';
GRANT ALL PRIVILEGES ON * . * TO 'privatlakarportal'@'%' WITH GRANT OPTION;

CREATE DATABASE webcert;
CREATE USER 'webcert'@'%' IDENTIFIED BY 'webcert';
GRANT ALL PRIVILEGES ON * . * TO 'webcert'@'%' WITH GRANT OPTION;

CREATE DATABASE srs;
CREATE USER 'srs'@'%' IDENTIFIED BY 'srs';
GRANT ALL PRIVILEGES ON * . * TO 'srs'@'%' WITH GRANT OPTION;

CREATE DATABASE rehabstod;
CREATE USER 'rehabstod'@'%' IDENTIFIED BY 'rehabstod';
GRANT ALL PRIVILEGES ON * . * TO 'rehabstod'@'%' WITH GRANT OPTION;

CREATE DATABASE sjut;
CREATE USER 'sjut'@'%' IDENTIFIED BY 'sjut';
GRANT ALL PRIVILEGES ON * . * TO 'sjut'@'%' WITH GRANT OPTION;