#!/bin/ksh

	# Finalidade    : CHG6195 - RELATORIO DE CONTROLE DE IP NAO NAT
	# Input         : BSCS_12_01.sh
	# Output        : mail, log
	# Autor         : Marcos de Benedicto
	# Data          : 28/04/2006


. /etc/appltab

banner ${$}

COD="BSCS_12_01"
SPOOL="/tmp/${COD}_$$.txt"
SQL="/amb/scripts/sql/${COD}.sql"
EMAIL="IT_Provisioning_Systems@nextel.com.br"
EMAILREL="IT_Provisioning_Systems@nextel.com.br"
DESC="${COD} - RELATORIO DE CONTROLE DE IP NAO NAT"

export USRPASS="/"
export TWO_TASK=${ENV_TNS_PDBSC}
export ORACLE_SID=${ENV_TNS_PDBSC}
export ORACLE_HOME=${ENV_DIR_ORAHOME_BSC}
export NLS_LANG=${ENV_NLSLANG_PDBSC}

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

/amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL}" "${EMAIL}" "${DESC}" 0 "${DESC}" "${SPOOL}"

#uuencode ${SPOOL} ${COD}.txt |mailx -s "${DESC}" ${EMAILREL}
/amb/operator/bin/attach_mail ${EMAILREL} ${SPOOL} "${DESC}"
if [ "${?}" -ne 0 ]
then
    echo "ERRO: No envio do relatorio por e-mail."
    exit 1
fi

[ -f ${SPOOL} ] && rm ${SPOOL}

exit 0

