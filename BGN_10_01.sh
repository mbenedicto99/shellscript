#!/bin/ksh

	# Finalidade    : CHGXXXX - Seleciona quantidade de execucoes a ser feita.
	# Input         : BGN_10_01.sh
	# Output        : mail, log
	# Autor         : Marcos de Benedicto
	# Data          : 09/08/2006

##set +x

. /etc/appltab

banner ${$}

COD="BGN_10_01"
SQL="/amb/scripts/sql/${COD}.sql"
EMAIL="prodmsol@nextel.com.br"

if [ "${#}" -ne 2 ]
then
    echo "ERRO: Parametros incorretos!!"
    echo "      USE: ${COD}.sh <DIA_ANTERIOR> <ARQ_QTD_EXEC>"
    exit 1
else
    DIA_ANTERIOR="${1}"
    SPOOL="${2}"
fi

DESC="${COD} - Seleciona quantidade de execucoes a ser feita."

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
[ -z "${DIA_ANTERIOR}" ] && exit 1

echo "Inicio do Processamento: ${DESC}"

. /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL} ${DIA_ANTERIOR}" "${EMAIL}" "${DESC}" 0 "${DESC}" "${SPOOL}"

