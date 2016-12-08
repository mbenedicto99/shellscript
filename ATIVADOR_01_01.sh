#!/bin/ksh

	# Finalidade	: CHG4605 - Enviar pedidos de troca voluntaria para inbox do Ativador Automatico
	# Input		: ATIVADOAR_01_01.sh
	# Output	: 
	# Data		: 26/08/2005
set +x

. /etc/appltab

banner ${$}

COD="ATIVADOR_01_01"
SPOOL="0"
SQL="/amb/scripts/sql/${COD}.sql"
EMAIL="prodmsol@nextel.com.br"
DESC="${COD} -Enviar pedidos de troca voluntaria para inbox do Ativador Automatico."

export USRPASS="/"
export ORACLE_HOME="${ENV_DIR_ORAHOME_PVANT_SP}"
export NLS_LANG="${ENV_NLSLANG_PVANT_SP}"
export TWO_TASK="${ENV_TNS_PVANT_SP}"
export ORACLE_SID="${ENV_TNS_PVANT_SP}"

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

. /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL}" "${EMAIL}" "${DESC}" 0 "${DESC}" "${SPOOL}"

