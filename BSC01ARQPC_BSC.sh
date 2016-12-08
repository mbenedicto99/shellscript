#!/bin/ksh

	# Finalidade    : Resumo de Indisponibilidade.
	# Input         : 
	#		  $1 - Caminho da SQL.
	#		  $2 - Email para envio do SPOOL/ERRO.
	#		  $3 - Descrisao do processo.
	#		  $4 - User e Password do banco.
	#		  $5 - ORACLE_SID
	# Output        : mail, log
	# Autor         : Marcos de Benedicto
	# Data          : 26/07/2004


	. /etc/appltab

	banner $$

	COD="bsc01arqpc_bsc"
	SQL="/amb/scripts/sql/${COD}.sql"
	EMAIL="relat_tels_disponiveis@nextel.com.br"
	DESC="Resumo de Indisponibilidade."
	SPOOL="${ENV_DIR_UTLF_BSC}/sched/tmp/${COD}$$.txt"

	export USRPASS="/"
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

	[ ! -s "${SQL}" ] && exit 1
	[ -z "${EMAIL}" ] && exit 1
	[ -z "${DESC}" ] && exit 1
	[ -z "${ORACLE_SID}" ] && exit 1
	[ -z "${ORACLE_HOME}" ] && exit 1
	[ -z "${USRPASS}" ] && exit 1


   #. /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL}" "${EMAIL}" "${DESC}" 0 BSCS ${SPOOL}

	${ORACLE_HOME}/bin/sqlplus / @${SQL} >${SPOOL} 2>&1

	/amb/operator/bin/attach_mail ${EMAIL} ${SPOOL} "${DESC}"

