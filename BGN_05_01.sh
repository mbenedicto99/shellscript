#!/bin/ksh

	# Finalidade    : CHG5614 - Executa qualificacao e import
	# Input         : BGN_05_01.sh <BILL_CYCLE>
	# Output        : mail, log
	# Autor         : Marcos de Benedicto
	# Data          : 10/02/2006

set +x

. /etc/appltab

banner ${$}

COD="BGN_05_01"
SPOOL="/tmp/${COD}.spool"
SQL="/amb/scripts/sql/${COD}.sql"
EMAIL="prodmsol@nextel.com.br"
DESC="${COD} - Executa qualificacao e import"

if [ "${#}" -ne 1 ]
then
    echo "ERRO: Parametros Incorretos !!! "
    echo "      USE: ${COD}.sh <BILL CYCLE>"
    exit 1
else
    BILL_CYCLE="${1}"
fi

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

[ -z "${BILL_CYCLE}" ] && exit 1
[ -z "${SQL}" ] && exit 1
[ -z "${EMAIL}" ] && exit 1
[ -z "${DESC}" ] && exit 1
[ -z "${ORACLE_SID}" ] && exit 1
[ -z "${ORACLE_HOME}" ] && exit 1
[ -z "${USRPASS}" ] && exit 1

#---------------------
# Executa 
#---------------------

. /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL} ${BILL_CYCLE}" "${EMAIL}" "${DESC}" 0 "${DESC}" "${SPOOL}"

export NUM_PROCESS_QUALI="`cat ${SPOOL} |tr -s ' ' |egrep -v '^$'`"

while [ ${NUM_PROCESS_QUALI} -ne 0 ]
do
    /amb/eventbin/BGN_02_01.sh
    if [ "${?}" -ne 0 ]
    then
	echo "ERRO: Ao Iniciar qualificacao de Clientes BGN."
	exit 1
    fi

    /amb/eventbin/BGN_06_01.sh
    if [ "${?}" -ne 0 ]
    then
	echo "ERRO: Ao executar verificacao do scheduler."
	exit 1
    fi

    /amb/eventbin/BGN_03_01.sh
    if [ "${?}" -ne 0 ]
    then
	echo "ERRO: Ao executar monitoracao da qualificacao de Clientes BGN."
	exit 1
    fi

    /amb/eventbin/BGN_04_01.sh
    if [ "${?}" -ne 0 ]
    then
	echo "ERRO: Ao executar IMPORT da qualificacao de Clientes BGN."
	exit 1
    fi

    export NUM_PROCESS_QUALI="`expr ${NUM_PROCESS_QUALI} - 1`"
done

exit 0
