#!/bin/ksh

	# Finalidade    : OFS - GEL ATUALIZA BSCS
	# Input         : BILLING_OFS_12_01.sh
	# Output        : mail, log
	# Autor         : Marcos de Benedicto
	# Data          : 31/05/2004

. /etc/appltab

if [ "${#}" -ne 1 ]
then
    echo "Parametros incorretos!!"
    echo "USE: ${0} <ciclo>"
    exit 1
fi

GEL_MASK="*GEL_ATUALIZA_BSCS*"
PATH_UTL="${ENV_DIR_UTLF_BSC}/GEL"
DATE=`echo $(date +%d-%m-%y) $(date +%H:%M)`
CICLO="${1}"
COD="billing_ofs_12_01"
SQL="/tmp/${COD}.sql"
#EMAIL="analise_producao@nextel.com.br"
EMAIL="roberto.takemoto@nextel.com.br"
DESC="BILLING OFS - GEL ATUALIZA BSCS ${DATE}"
SPOOL="/tmp/spool_${COD}.txt"

PREFIX_SMS="5511"
SUFIX_SMS="@page.nextel.com.br"
MENSAGEM_SMS="Termino Oracle Financial - Ciclo ${CICLO}."
EMAIL_BILL="Termino_Oracle@nextel.com.br"
#EMAIL_BILL="cleide.santos@nextel.com.br,angela.jacyntho@nextel.com.br,bill_checkout@nextel.com.br,regiane.liziero@nextel.com.br,noemi.salvador@nextel.com.br,roberto.takemoto@nextel.com.br"

# Lista para envio de SMS
SMS_ANGELA=${PREFIX_SMS}78345967${SUFIX_SMS}

echo "exec gel_interface.gel_atualiza_bscs('${PATH_UTL}');" >${SQL}

 chmod 777 ${SQL}

export USRPASS="oaiusr/bscs523"
export ORACLE_HOME="${ENV_DIR_ORAHOME_BSC}"
export NLS_LANG="${ENV_NLSLANG_PDBSC}"
export TWO_TASK="${ENV_TNS_PDBSC}"
export ORACLE_SID="${ENV_TNS_PDBSC}"

	set +x
	echo "
	+------------------------------------------------
	|
	|   Informacao
	|
	|   `date`
	|   EMAIL = ${EMAIL}
	|   DESCRICAO = ${DESC}
	|   ORACLE_SID = ${ORACLE_SID}
	|   TWO_TASK = ${TWO_TASK}
	|   ORACLE_HOME = ${ORACLE_HOME}
	|
	|   PATH UTL = ${PATH_UTL}
	|
	+------------------------------------------------\n"
	set -x

	[ -z "${PATH_UTL}" ] && exit 1
	[ ! -s "${SQL}" ] && exit 1
	[ -z "${EMAIL}" ] && exit 1
	[ -z "${DESC}" ] && exit 1
	[ -z "${TWO_TASK}" -o -z "${ORACLE_SID}" ] && exit 1
	[ -z "${ORACLE_HOME}" ] && exit 1
	[ -z "${USRPASS}" ] && exit 1


   . /amb/eventbin/SQL_RUN_BILL.PROC "${TWO_TASK}" "${USRPASS}" "${SQL}" "${EMAIL}" "${DESC}" 0 "BILLING_OFS_12" 0

FILE_LOG="`ls -tr ${PATH_UTL}/${GEL_MASK} | tail -1`"

[ "`grep -c \"ERRO\" ${FILE_LOG}`" -ne 0 ] && exit 1

rm ${SQL}

# Enviando SMS e e-mail
if [ "${CICLO}" -ne 07 ]
then
    echo ${MENSAGEM_SMS} | mailx -s "Billing CICLO ${CICLO}." ${SMS_ANGELA}
    sleep 2
    echo ${MENSAGEM_SMS} | mailx -s "Billing CICLO ${CICLO}" "${EMAIL_BILL}"
    sleep 1
fi

exit 0
