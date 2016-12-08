#!/bin/ksh

	# Finalidade    : Atualizao do total de numeros disponiveis.
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

	COD="bsc02auqpc_bsc"
	SQL="/amb/scripts/sql/${COD}.sql"
	EMAIL="marcos.benedicto@nextel.com.br"
	DESC="Atualizao do total de numeros disponiveis."

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


   . /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL}" "${EMAIL}" "${DESC}" 0 BSCS 0

