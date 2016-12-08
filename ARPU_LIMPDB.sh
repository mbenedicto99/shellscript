#!/bin/ksh

	# Finalidade    : Limpeza de registros antigos do ARPU.
	# Input         : ARPU_LIMPDB.sh
	#		  $1 - Caminho da SQL.
	#		  $2 - Email para envio do SPOOL/ERRO.
	#		  $3 - Descrisao do processo.
	#		  $4 - User e Password do banco.
	#		  $5 - ORACLE_SID
	# Output        : mail, log
	# Autor         : Marcos de Benedicto
	# Data          : 04/05/2004


	banner $$

	CICLO=`printf "%02s\n" $1`
	CHK_PROC=`ps -ef | grep "ARPU_CARGA" | grep -v "grep" | wc -l`

	if [ "${CICLO}" -ne "07" ] 
	then
	set +x
	echo "
	Este script deve rodar apenas para o CICLO 07. 
	Saindo da execucao.\n"
	set -x
	exit 0
	fi

	if [ "${CHK_PROC}" -ne 0 ]
	then
	set +x
	echo "
	Existe um processo de Carga do ARPU rodando, este script nao deve executar em paralelo.\n"
	set -x
	exit 1
	fi

	COD="arpu_limpdb"
	SQL="/amb/scripts/sql/${COD}.sql"
	EMAIL="prod@unix_mail_fwd"
	DESC="Limpeza de registros antigos do ARPU."
	
	export USRPASS="/"
	export ORACLE_SID=$2
	export TWO_TASK=$2
	export ORACLE_HOME=`grep ^${ORACLE_SID}: /etc/oratab | cut -d: -f2`
	export NLS_LANG="AMERICAN_AMERICA.WE8ISO8859P9"

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

