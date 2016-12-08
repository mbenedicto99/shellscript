#!/bin/ksh

	# Finalidade    : CHG5668 - Acerta interface do MIT (UPDATE do numero da INVOICE (USERLBL))
	# Input         : acerta_ohxact.sh
	# Output        : mail, log
	# Autor         : Rafael Toniete
	# Data          : 17/02/2006


. /etc/appltab

banner ${$}

COD="acerta_ohxact"
SPOOL="0"
SQL="/amb/scripts/sql/${COD}.sql"
EMAIL="prodmsol@nextel.com.br"
if [ "${#}" -ne 1 ]
then
    echo "ERRO: Parametros incorretos!!"
    echo "      USE: ${COD}.sh <BILLCYCLE>"
    exit 1
else
    BILLCYCLE="${1}"
fi
DESC="${COD} - Acerta interface do MIT - CICLO: ${BILLCYCLE}."

export USRPASS="/"
export TWO_TASK=${ENV_TNS_PDBSC}
export ORACLE_SID=${ENV_TNS_PDBSC}
export ORACLE_HOME=${ENV_DIR_ORAHOME_BSC}
export NLS_LANG=${ENV_NLSLANG_PDBSC}

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
        +------------------------------------------------\n"
set -x

[ -z "${SQL}" ] && exit 1
[ -z "${EMAIL}" ] && exit 1
[ -z "${DESC}" ] && exit 1
[ -z "${ORACLE_SID}" ] && exit 1
[ -z "${ORACLE_HOME}" ] && exit 1
[ -z "${USRPASS}" ] && exit 1


. /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL}" "${EMAIL}" "${DESC}" 0 "BILLING_ACERTA_OHXACT" "${SPOOL}"

