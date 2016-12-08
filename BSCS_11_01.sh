#!/bin/ksh

	# Finalidade    : CHG6195 - RELATORIO SINTETICO DE CONTROLE DE IP
	# Input         : BSCS_11_01.sh
	# Output        : mail, log
	# Autor         : Marcos de Benedicto
	# Data          : 28/04/2006

set -x

. /etc/appltab

banner ${$}

COD="BSCS_11_01"
SPOOL="/tmp/${COD}_$$.txt"
SQL="/amb/scripts/sql/${COD}.sql"
EMAIL="IT_Provisioning_Systems@nextel.com.br"
EMAILREL="IT_Provisioning_Systems@nextel.com.br"
DESC="${COD} - RELATORIO SINTETICO DE CONTROLE DE IP."

export USRPASS="/"
export TWO_TASK=${ENV_TNS_PDBSC}
export ORACLE_SID=${ENV_TNS_PDBSC}
export ORACLE_HOME=${ENV_DIR_ORAHOME_BSC}
export NLS_LANG=${ENV_NLSLANG_PDBSC}

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


. /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL}" "${EMAIL}" "${DESC}" 0 "${DESC}" "${SPOOL}"

DISP_IP_NAO_NAT=$(cat ${SPOOL} |tail -1 |awk '{print $2}')
DISP_IP_NAT_TOTAL=$(cat ${SPOOL} |tail -1 |awk '{print $3}')
DISP_IP_NAO_NAT_TOTAL=$(cat ${SPOOL} |tail -1 |awk '{print $4}')

if [ ${DISP_IP_NAO_NAT} -le 5000 ]
then
    /amb/eventbin/BSCS_12_01.sh
fi

if [ ${DISP_IP_NAT_TOTAL} -le 1000 ]
then
    /amb/eventbin/BSCS_13_01.sh
fi

if [ ${DISP_IP_NAO_NAT_TOTAL} -le 5000 ]
then
    /amb/eventbin/BSCS_14_01.sh
fi

if [ ${DISP_IP_NAO_NAT} -le 5000 -o  ${DISP_IP_NAT_TOTAL} -le 1000 -o ${DISP_IP_NAO_NAT_TOTAL} -le 5000 ]
then
    #uuencode ${SPOOL} ${COD}.txt |mailx -s "${DESC}" ${EMAILREL}
    /amb/eventbin/attach_mail ${SPOOL} ${EMAILREL} "${DESC}"
    if [ "${?}" -ne 0 ]
    then
        echo "ERRO: No envio do relatorio por e-mail."
        exit 1
    fi
fi

[ -f ${SPOOL} ] && rm ${SPOOL}

exit 0

