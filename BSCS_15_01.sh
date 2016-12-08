#!/bin/ksh

	# Finalidade    : CHG6411 - RELATORIO CONTROLE ATIVACAO - CDW MAESTRO.
	# Input         : BSCS_15_01.sh
	# Output        : mail, log
	# Autor         : Marcos de Benedicto
	# Data          : 01/06/2006


. /etc/appltab

banner ${$}

COD="BSCS_15_01"
SPOOL="/tmp/${COD}_$$.txt"
SQL="/amb/scripts/sql/${COD}.sql"
EMAIL="IT_Provisioning_Systems@nextel.com.br"
EMAILREL="Relatorios_CDW@nextel.com.br"
DESC="${COD} - RELATORIO CONTROLE ATIVACAO - CDW MAESTRO"

export USRPASS="/"
export TWO_TASK=${ENV_TNS_PNXTL01}
export ORACLE_SID=${ENV_ORA_PNXTL01}
export ORACLE_HOME=${ENV_DIR_ORAHOME_PNXTL01}
export NLS_LANG=${NLS_NLSLANG_PNXTL01}

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

/amb/eventbin/attach_mail ${SPOOL} ${EMAILREL} "${DESC}"
if [ "${?}" -ne 0 ]
then
    echo "ERRO: No envio do relatorio por e-mail."
    exit 1
fi

[ -f ${SPOOL} ] && rm ${SPOOL}

exit 0

