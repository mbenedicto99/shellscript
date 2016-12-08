#!/bin/ksh

	# Finalidade    : CHG2647 - RELATORIO DE CONTAS ZERADAS ANTES BGH COMMIT
	# Input         : BILLING_02_01.sh <billcycle>
	# Output        : mail, log
	# Autor         : Rafael Toniete
	# Data          : 19/10/2004

. /etc/appltab

BILLCYCLE=$1

	if [ -z "${BILLCYCLE}" ]
        then
	    echo "${0} <billcycle>"
	    exit 1
	fi

FILE_AUTH="${ENV_DIR_BASE_RTX}/prod/WORK/TMP/CYCLE-${BILLCYCLE}.flg"
DT_CORTE=`sed -n '3p' ${FILE_AUTH}`
[ -z ${FILE_AUTH} -o -z ${DT_CORTE} ] && exit 1

DD="`echo ${DT_CORTE} | cut -c7-8`"
MM="`echo ${DT_CORTE} | cut -c5-6`"
YY="`echo ${DT_CORTE} | cut -c1-4`"

FILE_LOG="BILL_SUPRESS_${BILLCYCLE}_*"
PATH_UTL="${ENV_DIR_UTLF_BSC}/GEL"
COD="BILLING_02_01"
SQL="/amb/scripts/sql/${COD}.sql"
EMAIL="roberto.takemoto@nextel.com.br"
DESC="RELATORIO DE CONTAS ZERADAS ANTES BGH COMMIT - `echo $(date +%d-%m-%y) $(date +%H:%M)`"
SPOOL="0"

export USRPASS="/"
export TWO_TASK="${ENV_TNS_PDBSC}"
export ORACLE_HOME="${ENV_DIR_ORAHOME_BSC}"
export NLS_LANG="${ENV_NLSLANG_PDBSC}"

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
	|   BILLCYCLE = ${BILLCYCLE}
	|   DATA DE CORTE = ${DT_CORTE}
	|   PATH UTL = ${PATH_UTL}
	|
	+------------------------------------------------\n"
set -x

[ -z "${BILLCYCLE}" ] && exit 1
[ -z "${DT_CORTE}" ] && exit 1
[ -z "${PATH_UTL}" ] && exit 1
[ ! -s "${SQL}" ] && exit 1
[ -z "${EMAIL}" ] && exit 1
[ -z "${DESC}" ] && exit 1
[ -z "${TWO_TASK}" ] && exit 1
[ -z "${ORACLE_HOME}" ] && exit 1
[ -z "${USRPASS}" ] && exit 1


. /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL} ${PATH_UTL} ${DD}/${MM}/${YY} ${BILLCYCLE}" "${EMAIL}" "${DESC}" 0 "${DESC}" ${SPOOL}

FILE_LOG=`ls -1tr ${PATH_UTL}/${FILE_LOG} | tail -1`

[ `grep -c "ERRO" ${FILE_LOG}` -ne 0 ] && exit 1
exit 0
