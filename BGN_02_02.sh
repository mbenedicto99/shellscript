#!/bin/ksh

	# Finalidade    : CHG5614 - Executa Qualificao de dados de clientes (GoQuality)
	# Input         : BGN_02_02.sh
	# Output        : mail, log
	# Autor         : Rafael Toniete
	# Data          : 30/01/2006

set +x

. /etc/appltab

banner ${$}

COD="BGN_02_01"
SPOOL="0"
ARQ_QTD_EXEC="/tmp/${COD}_$$.spool"
SQL="/amb/scripts/sql/${COD}.sql"
EMAIL="prodmsol@nextel.com.br"
DESC="${COD} - Executa Qualificao de dados de clientes (GoQuality)"

if [ "${#}" -ne 1 ]
then
    echo "ERRO: Parametros incorretos!!"
    echo "      USE: BGN_02_02.sh <DIA_ANTERIOR>"
    exit 1
else
    DIA_ANTERIOR="${1}"
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

[ -z "${SQL}" ] && exit 1
[ -z "${EMAIL}" ] && exit 1
[ -z "${DESC}" ] && exit 1
[ -z "${ORACLE_SID}" ] && exit 1
[ -z "${ORACLE_HOME}" ] && exit 1
[ -z "${USRPASS}" ] && exit 1

#---------------------
# verifica quantidade de execucoes
#---------------------
set -x
/amb/eventbin/BGN_10_01.sh ${DIA_ANTERIOR} ${ARQ_QTD_EXEC}

if [ ! -f ${ARQ_QTD_EXEC} ]
then
    echo "ERRO: Arquivo com Quantidade de execucoes nao foi gerado."
    exit 1
else
    QTD_EXEC=$(cat ${ARQ_QTD_EXEC})
    rm -f ${ARQ_QTD_EXEC}
    echo "Quantidade de processamentos pendentes = ${QTD_EXEC}"
fi

if [ ${QTD_EXEC} -eq 0 ]
then
    echo "NAO PROCESSAR MAIS"
    exit 0
fi
set +x
#---------------------
# Executa NXT_MANAGER
#---------------------

echo "Inicio do Processamento: ${DESC}"

. /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL}" "${EMAIL}" "${DESC}" 0 "${DESC}" "${SPOOL}"

echo "Termino do Processamento: ${DESC}"

