#!/bin/ksh

	# Finalidade    : CHGi5614 - Reprocessamento Qualificao de dados de clientes por LOTE
	# Input         : BGN_01_03.sh <LOTE>
	# Output        : mail, log
	# Autor         : Rafael Toniete
	# Data          : 23/02/2006

set +x

. /etc/appltab

banner ${$}

COD="BGN_01_03"
SPOOL="0"
SQL="/amb/scripts/sql/${COD}.sql"
EMAIL="prodmsol@nextel.com.br"

if [ "${#}" -ne 1 ]
then
    echo "ERRO: Parametros incorretos!!"
    echo "      USE: ${COD}.sh <LOTE>"
    exit 1
else
    LOTE="${1}"
fi

DESC="${COD} - Reprocessamento Qualificao de dados de clientes do LOTE ${LOTE}."

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
[ -z "${LOTE}" ] && exit 1

echo "Inicio do Processamento: ${DESC}"

. /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL} ${LOTE}" "${EMAIL}" "${DESC}" 0 "${DESC}" "${SPOOL}"

echo "Termino do Processamento: ${DESC}"

