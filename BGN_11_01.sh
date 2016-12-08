#!/bin/ksh

	# Finalidade    : CHGXXXX - Executa limpeza BGN QCC.
	# Input         : BGN_11_01.sh
	# Output        : mail, log
	# Autor         : Marcos de Benedicto
	# Data          : 09/08/2006

set +x

. /etc/appltab

banner ${$}

COD="BGN_11_01"
SPOOL="/tmp/${COD}_$$.spool"
SQL="/amb/scripts/sql/${COD}.sql"
EMAIL="prodmsol@nextel.com.br"

if [ "${#}" -ne 5 ]
then
    echo "ERRO: Parametros incorretos!!"
    echo "      USE: ${COD}.sh <NR_DIAS_DADOS> <NR_DIAS_VERDE_BRANCO_UNDEF> <NR_DIAS_AMARELO_VERM_AZUL> <NR_DIAS_CONTINGENCIA> <LIMPA_LOTES_COM_PROBLEMA>"
    exit 1
else
    NR_DIAS_DADOS="${1}"
    NR_DIAS_VERDE_BRANCO_UNDEF="${2}"
    NR_DIAS_AMARELO_VERM_AZUL="${3}"
    NR_DIAS_CONTINGENCIA="${4}"
    LIMPA_LOTES_COM_PROBLEMA="${5}"
fi

DESC="${COD} - Executa limpeza da BASE BGN"

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
[ -z "${NR_DIAS_DADOS}" ] && exit 1
[ -z "${NR_DIAS_VERDE_BRANCO_UNDEF}" ] && exit 1
[ -z "${NR_DIAS_AMARELO_VERM_AZUL}" ] && exit 1
[ -z "${NR_DIAS_CONTINGENCIA}" ] && exit 1
[ -z "${LIMPA_LOTES_COM_PROBLEMA}" ] && exit 1

echo "Inicio do Processamento: ${DESC}"

. /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL} ${NR_DIAS_DADOS} ${NR_DIAS_VERDE_BRANCO_UNDEF} ${NR_DIAS_AMARELO_VERM_AZUL} ${NR_DIAS_CONTINGENCIA} ${LIMPA_LOTES_COM_PROBLEMA}" "${EMAIL}" "${DESC}" 0 "${DESC}" "${SPOOL}"

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

