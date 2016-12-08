#!/bin/ksh

	# Finalidade    : OFS - GEL ERP ARG
	# Input         : BILLING_OFS_03_01.sh
	# Output        : mail, log
	# Autor         : Marcos de Benedicto
	# Data          : 31/05/2004

. /etc/appltab

##PATH_UTL_ARG="${ENV_DIR_UTLF_BSC}/billing"
DATE=`echo $(date +%d-%m-%y) $(date +%H:%M)`
COD="billing_ofs_03_01"
SQL="/amb/scripts/sql/${COD}.sql"
EMAIL="marcos.benedicto@nextel.com.br"
DESC="BILLING OFS - GEL ERP ARG ${DATE}"
SPOOL="/tmp/spool_${COD}.txt"

echo "
begin
    gel_interface.gel_erp('P',${PATH_UTL_ARG});
end;
 " >${SQL}

 chmod 777 ${SQL}

export USRPASS="${ENV_LOGIN_PDBSC}"
export ORACLE_HOME="${ENV_DIR_ORAHOME_BSC}"
export NLS_LANG="${ENV_NLSLANG_PDBSC}"
export TWO_TASK="${ENV_TNS_PDBSC}"
export ORACLE_SID="${ENV_TNS_PDBSC}"

	set +x
	echo "
	+------------------------------------------------
	|
	|   Informacao
	|
	|   `date`
	|   PID = $$
	|   SQL = ${SQL}
	|   EMAIL = ${EMAIL}
	|   DESCRICAO = ${DESC}
	|   ORACLE_SID = ${ORACLE_SID}
	|   TWO_TASK = ${TWO_TASK}
	|   ORACLE_HOME = ${ORACLE_HOME}
	|
	|   PATH UTL ARG = ${PATH_UTL_ARG}
	|
	+------------------------------------------------\n"
	set -x

	[ -z "${PATH_UTL_ARG}" ] && exit 1
	[ ! -s "${SQL}" ] && exit 1
	[ -z "${EMAIL}" ] && exit 1
	[ -z "${DESC}" ] && exit 1
	[ -z "${TWO_TASK}" -o -z "${ORACLE_SID}" ] && exit 1
	[ -z "${ORACLE_HOME}" ] && exit 1
	[ -z "${USRPASS}" ] && exit 1


   . /amb/eventbin/SQL_RUN_BILL.PROC "${TWO_TASK}" "${USRPASS}" "${SQL}" "${EMAIL}" "${DESC}" 0 "BILLING OFS" 0

