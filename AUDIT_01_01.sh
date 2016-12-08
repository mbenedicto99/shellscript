#!/bin/ksh
	# Finalidade    : CHG4394.b - Relatorio de Acessos Ativos nos sistemas criticos da NEXTEL
	# Input         : AUDIT_01_01.sh
	# Output        : mail, log
	# Autor         : Marcos de Benedicto
	# Data          : 29/07/2005

. /etc/appltab

banner ${$}

COD="AUDIT_01_01"
SPOOL="0"
EMAIL="prodmsol@nextel.com.br"
if [ "${#}" -ne 1 ]
then
    echo "ERRO: Parametros incorretos!!"
    echo "      USE: ${COD}.sh <Sistema>"
    exit 1
else
    SISTEMA="${1}"
    DESC="${COD} - Relatorio de Acessos Ativos no sistema ${SISTEMA}"
fi

case ${SISTEMA} in
               'REDE')
                      SQL="/amb/scripts/sql/AUDIT_01_02.sql"
                      ;;
                    *)
                      SQL="/amb/scripts/sql/${COD}.sql"
                      ;;
esac

export USRPASS="/"
export ORACLE_HOME="${ENV_DIR_ORAHOME_PNXTL01}"
export NLS_LANG="${NLS_NLSLANG_PNXTL01}"
export TWO_TASK="${ENV_TNS_PNXTL01}"
export ORACLE_SID="${ENV_ORA_PNXTL01}"

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
        |   SISTEMA = ${SISTEMA}
        |   ORACLE_SID = ${ORACLE_SID}
        |   TWO_TASK = ${TWO_TASK}
        |   ORACLE_HOME = ${ORACLE_HOME}
        |
        +------------------------------------------------\n"
set -x

[ -z "${SQL}" ] && exit 1
[ -z "${EMAIL}" ] && exit 1
[ -z "${DESC}" ] && exit 1
[ -z "${SISTEMA}" ] && exit 1
[ -z "${ORACLE_SID}" ] && exit 1
[ -z "${ORACLE_HOME}" ] && exit 1
[ -z "${USRPASS}" ] && exit 1

. /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL} ${SISTEMA}" "${EMAIL}" "${DESC}" 0 "${DESC}" "${SPOOL}"


