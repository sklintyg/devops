#!/bin/bash

clear
echo

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DATE=`date +"%Y-%m-%d_%T"`
BKPDIR=$DIR/sqlbackups/

if [[ ! -e $BKPDIR ]]; then
    mkdir $BKPDIR
fi

read -p 'Which port have you used in the port-forward [3306]?: ' MYSQL_PORT
MYSQL_PORT=${MYSQL_PORT:-3306}

echo

nc -z -w1 localhost $MYSQL_PORT
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Can't connect to mysql on port $MYSQL_PORT, please make sure you have done the oc port-forward thing"
    echo "on the same machine you are running this script from and that you actually used port $MYSQL_PORT locally,"
    echo "and then run this command again. If you have, ask Martin why his POS script doesn't work."
    echo
    echo "To setup the port-forward, open up a new ssh-session to ansible.sm and do the following:"
    echo "1. use the Copy Login Command in Openshift WebGUI"
    echo "2. oc project tintyg or sitintyg"
    echo "3. oc get pods | grep mysql"
    echo "4. oc pport-forward <pod-name> 3306:3306"
    echo "5. when you have run this script and its done, just ctrl-c to kill mysql port-forward"
    exit 0
elif [ $retVal -eq 0 ]; then
    echo "MySQL connection detected..."
else
    echo $retVal
    echo "Error Error Error!"
    exit 0
fi

DO_WEBCERT=0
DO_INTYG=0
DO_STATISTIK=0
DO_PLP=0
DO_IA=0
DO_RS=0
DO_STATISTIK_EJ_REGION=0

echo

read -p 'Which enviroment? [devtest]: ' TEST_ENVIRONMENT
TEST_ENVIRONMENT=${TEST_ENVIRONMENT:-devtest}

echo

PS3='Vilka tjänster vill du tömma? '
options=("webcert+intyg+statistik" "intyg" "statistik" "privatläkarportalen" "intygsadmin" "rehabstod" "alla" "webcert+intyg+statistik EJ regioner i statistik")
select opt in "${options[@]}"
do
    case $opt in
        "webcert+intyg+statistik")
	    DO_WEBCERT=1
	    DO_INTYG=1
	    DO_STATISTIK=1
	    break
            ;;
        "intyg")
	    DO_INTYG=1
	    break
            ;;
        "statistik")
	    DO_STATISTIK=1
	    break
            ;;
        "privatläkarportalen")
	    DO_PLP=1
	    break
            ;;
        "intygsadmin")
	    DO_IA=1
	    break
            ;;
        "rehabstod")
	    DO_RS=1
	    break
            ;;
        "alla")
	    DO_WEBCERT=1
	    DO_INTYG=1
	    DO_STATISTIK=1
	    DO_PLP=1 # knepig?
	    DO_IA=1
	    DO_RS=1
	    break
            ;;
        "webcert+intyg+statistik EJ regioner i statistik")
            DO_WEBCERT=1
            DO_INTYG=1
            DO_STATISTIK_EJ_REGION=1
            break
            ;;
        *) echo "Felaktigt val: $REPLY";;
    esac
done

echo
echo "Rensar $opt i $TEST_ENVIRONMENT"
echo

set +x

DB_FQDN=127.0.0.1

function printName() {
  echo "*****************************************"
  echo "Tömmer databaser för $1."
  echo "*****************************************"
  echo ""
}

function dump_db {
  export MYSQL_PWD=$1_$2; mysqldump -u $1_$2 -h $DB_FQDN $1_$2 > ${BKPDIR}${DATE}_${1}_${2}_dump.sql
}

if [[ $DO_INTYG == "1" ]]
then 
  DB_NAME_PREFIX=intygstjanst
  printName intygstjänsten
  dump_db $DB_NAME_PREFIX $TEST_ENVIRONMENT
  MYSQLVAR="${DB_NAME_PREFIX}_${TEST_ENVIRONMENT}"
  export MYSQL_PWD=$MYSQLVAR; mysql -u $MYSQLVAR -h $DB_FQDN -P 3306 << EOF
use $MYSQLVAR
SET FOREIGN_KEY_CHECKS=0;
TRUNCATE TABLE APPROVED_RECEIVER;
TRUNCATE TABLE ARENDE;
TRUNCATE TABLE CERTIFICATE;
TRUNCATE TABLE CERTIFICATE_STATE;
TRUNCATE TABLE ORIGINAL_CERTIFICATE;
TRUNCATE TABLE RELATION;
TRUNCATE TABLE SJUKFALL_CERT;
TRUNCATE TABLE SJUKFALL_CERT_WORK_CAPACITY;
SET FOREIGN_KEY_CHECKS=1;
EOF

#TRUNCATE CONSENT;
fi

if [[ $DO_STATISTIK == "1" ]]
then 
  DB_NAME_PREFIX=statistik
  printName statistiktjänsten
  dump_db $DB_NAME_PREFIX $TEST_ENVIRONMENT
  MYSQLVAR="${DB_NAME_PREFIX}_${TEST_ENVIRONMENT}"
#TRUNCATE TABLE Landsting;
  export MYSQL_PWD=$MYSQLVAR; mysql -u $MYSQLVAR -h $DB_FQDN -P 3306 << EOF
use $MYSQLVAR
SET FOREIGN_KEY_CHECKS=0;
TRUNCATE TABLE CountyPopulation;
TRUNCATE TABLE LandstingEnhet;
TRUNCATE TABLE LandstingEnhetUpdate;
TRUNCATE TABLE enhet;
TRUNCATE TABLE handelsepekare;
TRUNCATE TABLE hsa;
TRUNCATE TABLE intygcommon;
TRUNCATE TABLE intyghandelse;
TRUNCATE TABLE intygsenthandelse;
TRUNCATE TABLE lakare;
TRUNCATE TABLE meddelandehandelse;
TRUNCATE TABLE messagewideline;
TRUNCATE TABLE user_settings;
TRUNCATE TABLE userselection;
TRUNCATE TABLE wideline;
SET FOREIGN_KEY_CHECKS=1;
EOF

fi

if [[ $DO_PLP == "1" ]]
then 
  DB_NAME_PREFIX=privatlakarportal
  printName privatläkarportalen
  dump_db $DB_NAME_PREFIX $TEST_ENVIRONMENT
  MYSQLVAR="${DB_NAME_PREFIX}_${TEST_ENVIRONMENT}"
  export MYSQL_PWD=$MYSQLVAR; mysql -u $MYSQLVAR -h $DB_FQDN -P 3306 << EOF
use $MYSQLVAR
SET FOREIGN_KEY_CHECKS=0;
TRUNCATE TABLE BEFATTNING;
TRUNCATE TABLE HOSP_UPPDATERING;
TRUNCATE TABLE LEGITIMERAD_YRKESGRUPP;
TRUNCATE TABLE MEDGIVANDE;
TRUNCATE TABLE MEDGIVANDETEXT;
TRUNCATE TABLE PRIVATLAKARE;
TRUNCATE TABLE PRIVATLAKARE_ID;
TRUNCATE TABLE SPECIALITET;
TRUNCATE TABLE VARDFORM;
TRUNCATE TABLE VERKSAMHETSTYP;
SET FOREIGN_KEY_CHECKS=1;
EOF
fi

if [[ $DO_IA == "1" ]]
then 
  DB_NAME_PREFIX=intygsadmin
  printName intygsadmin
  dump_db $DB_NAME_PREFIX $TEST_ENVIRONMENT
  MYSQLVAR="${DB_NAME_PREFIX}_${TEST_ENVIRONMENT}"
  export MYSQL_PWD=$MYSQLVAR; mysql -u $MYSQLVAR -h $DB_FQDN -P 3306 << EOF
use $MYSQLVAR
SET FOREIGN_KEY_CHECKS=0;
TRUNCATE TABLE banner;
TRUNCATE TABLE intyg_info;
SET FOREIGN_KEY_CHECKS=1;
EOF
#TRUNCATE TABLE user;
fi

if [[ $DO_RS == "1" ]]
then 
  DB_NAME_PREFIX=rehabstod
  printName rehabstöd
  dump_db $DB_NAME_PREFIX $TEST_ENVIRONMENT
  MYSQLVAR="${DB_NAME_PREFIX}_${TEST_ENVIRONMENT}"
  export MYSQL_PWD=$MYSQLVAR; mysql -u $MYSQLVAR -h $DB_FQDN -P 3306 << EOF
use $MYSQLVAR
SET FOREIGN_KEY_CHECKS=0;
TRUNCATE TABLE ANVANDARE_PREFERENCE;
SET FOREIGN_KEY_CHECKS=1;
EOF
fi

if [[ $DO_STATISTIK_EJ_REGION == "1" ]]
then 
  DB_NAME_PREFIX=statistik
  printName statistiktjänsten
  dump_db $DB_NAME_PREFIX $TEST_ENVIRONMENT
  MYSQLVAR="${DB_NAME_PREFIX}_${TEST_ENVIRONMENT}"
  export MYSQL_PWD=$MYSQLVAR; mysql -u $MYSQLVAR -h $DB_FQDN -P 3306 << EOF
use $MYSQLVAR
SET FOREIGN_KEY_CHECKS=0;
TRUNCATE TABLE CountyPopulation;
TRUNCATE TABLE LandstingEnhet;
TRUNCATE TABLE LandstingEnhetUpdate;
TRUNCATE TABLE enhet;
TRUNCATE TABLE handelsepekare;
TRUNCATE TABLE hsa;
TRUNCATE TABLE intygcommon;
TRUNCATE TABLE intyghandelse;
TRUNCATE TABLE intygsenthandelse;
TRUNCATE TABLE lakare;
TRUNCATE TABLE meddelandehandelse;
TRUNCATE TABLE messagewideline;
TRUNCATE TABLE user_settings;
TRUNCATE TABLE userselection;
TRUNCATE TABLE wideline;
SET FOREIGN_KEY_CHECKS=1;
EOF
#TRUNCATE TABLE Landsting;
fi

if [[ $DO_WEBCERT == "1" ]]
then
  DB_NAME_PREFIX=webcert
  printName webcert
  dump_db $DB_NAME_PREFIX $TEST_ENVIRONMENT
  MYSQLVAR="${DB_NAME_PREFIX}_${TEST_ENVIRONMENT}"
  export MYSQL_PWD=$MYSQLVAR; mysql -u $MYSQLVAR -h $DB_FQDN -P 3306 << EOF
use $MYSQLVAR
SET FOREIGN_KEY_CHECKS=0;
TRUNCATE TABLE ANVANDARE_PREFERENCE;
TRUNCATE TABLE ARENDE;
TRUNCATE TABLE ARENDE_KONTAKT_INFO;
TRUNCATE TABLE ARENDE_UTKAST;
TRUNCATE TABLE AVTAL_PRIVATLAKARE;
TRUNCATE TABLE EXTERNA_KONTAKTER;
TRUNCATE TABLE FMB;
TRUNCATE TABLE FMB_BESKRIVNING;
TRUNCATE TABLE FMB_DIAGNOS_INFORMATION;
TRUNCATE TABLE FMB_ICD10_KOD;
TRUNCATE TABLE FMB_ICF_KOD;
TRUNCATE TABLE FMB_REFERENS;
TRUNCATE TABLE FMB_TYPFALL;
TRUNCATE TABLE FRAGASVAR;
TRUNCATE TABLE GODKANT_AVTAL_PRIVATLAKARE;
TRUNCATE TABLE HANDELSE;
TRUNCATE TABLE HANDELSE_METADATA;
TRUNCATE TABLE INTEGRERADE_VARDENHETER;
TRUNCATE TABLE INTYG;
TRUNCATE TABLE KOMPLETTERING;
TRUNCATE TABLE MEDICINSKT_ARENDE;
TRUNCATE TABLE MIGRERADE_INTYG_FRAN_MEDCERT;
TRUNCATE TABLE PAGAENDE_SIGNERING;
TRUNCATE TABLE REFERENS;
TRUNCATE TABLE SCHEDULERAT_JOBB;
TRUNCATE TABLE SIGNATUR;
SET FOREIGN_KEY_CHECKS=1;
EOF
echo
echo "*** Don't forget to go to webcert/welcome.html and click Populate FMB button... ***"
echo
echo
fi



#if ! [[ $TESTDATA_STATISTIK_BRANCH =~ "Nej" ]]
#then 
#  curl -G --user marlun:e5b9d8358c61887c6f94fa4124ace9e1 "https://build-inera.nordicmedtest.se/jenkins/view/NMT/job/intyg-auto-testdata-statistik/buildWithParameters" --data-urlencode "token=We4re2eTesterIst516Kan-testdata-statistik" --data-urlencode "ENV="$TEST_ENVIRONMENT --data-urlencode "BRANCH="$TESTDATA_STATISTIK_BRANCH
#
#  echo "*****************************************"
#  echo "Startar bygge för att generera testdata för statistik på $TEST_ENVIRONMENT."
#  echo "Använder grenen $TESTDATA_STATISTIK_BRANCH."
#  echo "*****************************************"
#  echo ""
#
#fi

echo
echo "Don't forget to clear Redis cache for this enviroment, as some data might be lurking there..."
echo

