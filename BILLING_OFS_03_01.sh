#!/bin/ksh

	# Finalidade    : OFS - GEL ERP ARG
	# Input         : BILLING_OFS_03_01.sh
	# Output        : mail, log
	# Autor         : Marcos de Benedicto
	# Data          : 31/05/2004

. /etc/appltab

####PATH_UTL_ARG="/f11iprod/prodappl/bancos"
####PATH_UTL_ARG="/aplic_erp/applprod/prodappl/bancos"
####PATH_UTL_ARG="/aplic/utl/sched/bscs/log"
PATH_UTL_ARG="/usr/tmp"
DATE=`echo $(date +%d-%m-%y) $(date +%H:%M)`
COD="billing_ofs_03_01"
SQL="/tmp/${COD}.sql"
#EMAIL="analise_producao@nextel.com.br"
EMAIL="roberto.takemoto@nextel.com.br"
DESC="BILLING OFS - GEL ERP ARG ${DATE}"
SPOOL="/tmp/spool_${COD}.txt"

echo "exec cai.gel_ar_interface.gel_erp('P','${PATH_UTL_ARG}');" >${SQL}

 chmod 777 ${SQL}

export USRPASS="oaiusr/bscs523"
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


   . /amb/eventbin/SQL_RUN_BILL.PROC "${TWO_TASK}" "${USRPASS}" "${SQL}" "${EMAIL}" "${DESC}" 0 "BILLING_OFS_03" 0

	rm -f ${SQL}
