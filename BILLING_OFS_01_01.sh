#!/bin/ksh

	# Finalidade    : OFS -  RODA GEL
	# Input         : BILLING_OFS_01_01.sh <billcycle>
	# Output        : mail, log
	# Autor         : Marcos de Benedicto
	# Data          : 31/05/2004

. /etc/appltab

BILLCYCLE=$1

	if [ -z "${BILLCYCLE}" ]
        then
	echo "BILLING_OFS_01_01.sh <billcycle>"
	exit 1
	fi

FILE_AUTH="${ENV_DIR_BASE_RTX}/prod/WORK/TMP/CYCLE-${BILLCYCLE}.flg"
[ ! -f ${FILE_AUTH} ] && exit 1
DT_CORTE="`sed -n '3p' ${FILE_AUTH}`"
[ -z ${FILE_AUTH} -o -z ${DT_CORTE} ] && exit 1

DD="`echo ${DT_CORTE} | cut -c7-8`"
MM="`echo ${DT_CORTE} | cut -c5-6`"
YY="`echo ${DT_CORTE} | cut -c1-4`"

GEL_LOG="GEL_INTERFACE.GEL_??????????????.log"
GEL_BILL_CUSTOMERS_LOG="GEL_INTERFACE.GEL_BILL_CUSTOMERS_??????????????.log"
PATH_UTL="${ENV_DIR_UTLF_BSC}/GEL"
DATE=`echo $(date +%d-%m-%y) $(date +%H:%M)`
COD="billing_ofs_01_01"
SQL="/tmp/${COD}.sql"
EMAIL="roberto.takemoto@nextel.com.br"
DESC="BILLING OFS - Roda GEL ${DATE}"
SPOOL="/tmp/spool_${COD}.txt"

echo "exec gel_interface.gel('${BILLCYCLE}','${DD}/${MM}/${YY}','P',2,'${PATH_UTL}');" >${SQL}

 chmod 777 ${SQL}

export USRPASS="oaiusr/bscs523"
export ORACLE_HOME="${ENV_DIR_ORAHOME_BSC}"
export NLS_LANG="${ENV_NLSLANG_PDBSC}"
export TWO_TASK="${ENV_TNS_PDBSC}"
export ORACLE_SID="${ENV_TNS_PDBSC}"
export NLS_NUMERIC_CHARACTERS='., '

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
	|   BILLCYCLE = ${BILLCYCLE}
	|   DATA DE CORTE = ${DT_CORTE}
	|   PATH UTL = ${PATH_UTL}
	|
	+------------------------------------------------\n"
	set -x

	[ -z "${BILLCYCLE}" ] && exit 1
	[ -z "${DT_CORTE}" ] && exit 1
	[ -z "${PATH_UTL}" ] && exit 1
	[ ! -s "${SQL}" ] && exit 1
	[ -z "${EMAIL}" ] && exit 1
	[ -z "${DESC}" ] && exit 1
	[ -z "${TWO_TASK}" -o -z "${ORACLE_SID}" ] && exit 1
	[ -z "${ORACLE_HOME}" ] && exit 1
	[ -z "${USRPASS}" ] && exit 1

echo "Inicio do GEL para o CICLO ${BILLCYCLE} - `date`" |mailx -s "Inicio do GEL para o CICLO ${BILLCYCLE}" renato.silveira@nextel.com.br,rafael.toniete@nextel.com.br

. /amb/eventbin/SQL_RUN_BILL.PROC "${TWO_TASK}" "${USRPASS}" "${SQL}" "${EMAIL}" "${DESC}" 0 "BILLING_OFS_01" 0

FILE_LOG="`ls -tr ${PATH_UTL}/${GEL_LOG} | tail -1`"
FILE_LOG_CUSTOMERS="`ls -tr ${PATH_UTL}/${GEL_BILL_CUSTOMERS_LOG} | tail -1`"

if [ "`grep -c \"ERRO\" ${FILE_LOG}`" -ne 0 -o "`grep -c \"ERRO\" ${FILE_LOG_CUSTOMERS}`" -ne 0 ]
then
    cat ${FILE_LOG}
    cat ${FILE_LOG_CUSTOMERS}
    exit 1
fi

echo "Fim do GEL para o CICLO ${BILLCYCLE} - `date`" |mailx -s "Fim do GEL para o CICLO ${BILLCYCLE}" renato.silveira@nextel.com.br,rafael.toniete@nextel.com.br

##rm ${FILE_AUTH}
rm ${SQL}
exit 0	
