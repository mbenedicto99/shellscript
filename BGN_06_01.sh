#!/bin/ksh

	# Finalidade    : CHG5614 - Verifica se Scheduler esta ativo.
	# Input         : BGN_06_01.sh
	# Output        : mail, log
	# Autor         : Rafael Toniete
	# Data          : 10/02/2006

set +x

. /etc/appltab

banner ${$}

COD="BGN_06_01"
SPOOL="/tmp/${COD}.spool"
SQL="/amb/scripts/sql/${COD}.sql"
EMAIL="prodmsol@nextel.com.br"
DESC="${COD} - Verifica se Scheduler esta ativo."

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
# Executa query para pegar status do Scheduler
#---------------------

sleep 60

. /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL}" "${EMAIL}" "${DESC}" 0 "${DESC}" "${SPOOL}"

STATUS="`egrep -c 'P' ${SPOOL}`"

cat ${SPOOL} 

[ -f ${SPOOL} ] && rm -f ${SPOOL}

if [ "${STATUS}" -ne 0 ]
then
    echo "\n\nERRO: O scheduler NAO esta ATIVO."
    echo "      Seguir procedimento da documentacao do JOB.\n\n"
    exit 1
else
    echo "\n\nSUCESSO: O processo do scheduler esta ATIVO.\n\n"
fi

exit 0
