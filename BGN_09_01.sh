#!/bin/ksh

	# Finalidade    : CHGXXXX - Processamento diario (Export de CLIENTES ATIVOS gerando um processo por vez com a quantidade de registros especificada no parametro QTY_REG_PROCESS)
	# Input         : BGN_09_01.sh
	# Output        : mail, log
	# Autor         : Marcos de Benedicto
	# Data          : 09/08/2006

set +x

. /etc/appltab

banner ${$}

COD="BGN_09_01"
SPOOL="/tmp/${COD}_$$.spool"
SQL="/amb/scripts/sql/${COD}.sql"
EMAIL="prodmsol@nextel.com.br"

if [ "${#}" -ne 3 ]
then
    echo "ERRO: Parametros incorretos!!"
    echo "      USE: ${COD}.sh <QTY_REG_PROCESS> <DIA_ANTERIOR> <PLANO_CONTIGENCIA>"
    exit 1
else
    QTY_REG_PROCESS="${1}"
    DIA_ANTERIOR="${2}"
    PLANO_CONTIGENCIA="${3}"
fi

DESC="${COD} - Export diario de CLIENTES ATIVOS (QTY_REG_PROCESS = ${QTY_REG_PROCESS} DIA_ANTERIOR = ${DIA_ANTERIOR} PLANO_CONTIGENCIA = ${PLANO_CONTIGENCIA})"

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
[ -z "${QTY_REG_PROCESS}" ] && exit 1
[ -z "${DIA_ANTERIOR}" ] && exit 1
[ -z "${PLANO_CONTIGENCIA}" ] && exit 1

echo "Inicio do Processamento: ${DESC}"

. /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL} ${QTY_REG_PROCESS} ${DIA_ANTERIOR} ${PLANO_CONTIGENCIA}" "${EMAIL}" "${DESC}" 0 "${DESC}" "${SPOOL}"

VAR_ERRO=$(grep -c "V_MESSAGE = ERRO: " ${SPOOL})

if [ "${VAR_ERRO}" -eq 0 ]
then
    echo "SUCESSO: Termino do Processamento: ${DESC}"
    cat ${SPOOL}
    [ -f ${SPOOL} ] && rm -f ${SPOOL}
    exit 0
else
    echo "ERRO: Termino do Processamento: ${DESC}"
    cat ${SPOOL}
    [ -f ${SPOOL} ] && rm -f ${SPOOL}
    exit 1
fi

