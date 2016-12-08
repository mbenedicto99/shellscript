#!/bin/ksh

	# Finalidade    : OFS - GEL TRANSF AR-BR
	# Input         : BILLING_OFS_10_01.sh
	# Output        : mail, log
	# Autor         : Marcos de Benedicto
	# Data          : 31/05/2004

. /etc/appltab

GEL_MASK="*GEL_TRANSFERE_ARG_BRA*"
PATH_UTL="${ENV_DIR_UTLF_BSC}/GEL"
DATE=`echo $(date +%d-%m-%y) $(date +%H:%M)`
COD="billing_ofs_10_01"
SQL="/tmp/${COD}.sql"
#EMAIL="analise_producao@nextel.com.br"
EMAIL="roberto.takemoto@nextel.com.br"
DESC="BILLING OFS - GEL TRANSF AR-BR ${DATE}"
SPOOL="/tmp/spool_${COD}.txt"

echo "exec gel_interface.gel_transfere_arg_bra('${PATH_UTL}');" >${SQL}

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


   . /amb/eventbin/SQL_RUN_BILL.PROC "${TWO_TASK}" "${USRPASS}" "${SQL}" "${EMAIL}" "${DESC}" 0 "BILLING_OFS_10" 0

        FILE_LOG="`ls -tr ${PATH_UTL}/${GEL_MASK} | tail -1`"

        [ "`grep -c \"ERRO\" ${FILE_LOG}`" -ne 0 ] && exit 1

	rm ${SQL}
