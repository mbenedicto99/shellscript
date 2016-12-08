#!/bin/ksh

	# Finalidade    : CHG5614 - Executa import de dados qualificados para a BGN
	# Input         : BGN_04_01.sh
	# Output        : mail, log
	# Autor         : Marcos de Benedicto
	# Data          : 10/02/2006

set +x

. /etc/appltab

banner ${$}

COD="BGN_04_01"
SPOOL="/tmp/${COD}_$$.spool"
SQL="/amb/scripts/sql/${COD}.sql"
EMAIL="prodmsol@nextel.com.br"
DESC="${COD} - Executa Query para pegar ID do processo para IMPORT."

export USRPASS="/"
export ORACLE_HOME="${ENV_DIR_ORAHOME_PNXTL01}"
export NLS_LANG="${NLS_NLSLANG_PNXTL01}"
export TWO_TASK="${ENV_TNS_PNXTL01}"
export ORACLE_SID="${ENV_ORA_PNXTL01}"

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

[ -z "${SQL}" ] && exit 1
[ -z "${EMAIL}" ] && exit 1
[ -z "${DESC}" ] && exit 1
[ -z "${ORACLE_SID}" ] && exit 1
[ -z "${ORACLE_HOME}" ] && exit 1
[ -z "${USRPASS}" ] && exit 1

#---------------------
# Executa Query para pegar ID do processo para import
#---------------------

. /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL}" "${EMAIL}" "${DESC}" 0 "${DESC}" "${SPOOL}"

V_ID_PROCESS_CONTROL="`cat ${SPOOL} |tr -s ' ' |egrep -v '^$'`"
#V_ID_PROCESS_CONTROL="215"

[ -f ${SPOOL} ] && rm -f ${SPOOL}

COD="BGN_04_02"
SPOOL="0"
SQL="/amb/scripts/sql/${COD}.sql"
DESC="${COD} - Executa import de dados qualificados para a BGN."

export USRPASS="/"
export ORACLE_HOME="${ENV_DIR_ORAHOME_PNXTL01}"
export NLS_LANG="${NLS_NLSLANG_PNXTL01}"
export TWO_TASK="${ENV_TNS_PNXTL01}"
export ORACLE_SID="${ENV_ORA_PNXTL01}"

#---------------------
# Executa IMPORT de dados qualificados para a BGN
#---------------------

. /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL} ${V_ID_PROCESS_CONTROL}" "${EMAIL}" "${DESC}" 0 "${DESC}" "${SPOOL}"

exit 0
