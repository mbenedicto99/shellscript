#!/bin/ksh

	# Finalidade : Loader Oracle - Parte 1
	# Input : Arquivo ARPU gerado apos junta_arqs
	# Output : Banco PMIT
	# Autor : Marcos de Benedicto
	# Data : 28/01/2004

set -A LOADER set_var exec_sql

EMAIL="prodmsol@nextel.com.br"
EMAIL2="bill_checkout@unix_mail_fwd"
EMAIL3="RevAssuL@nextel.com.br"
PROCSS="ARPU_CARGA_01"

SPOOL="/tmp/sql1.$$.log"
SITE=R
CICLO=`printf "%02s\n" $2`
SQL="/amb/scripts/sql/arpu_carga_01.sql"

export USRPASS="mitusr/USRMIT10"
export ORACLE_SID=$3
export TWO_TASK=$3
export ORACLE_HOME=`grep ^${ORACLE_SID}: /etc/oratab | cut -d: -f2`
export NLS_LANG="brazilian portuguese_brazil.we8dec"

	if [ -z "${CICLO}" -o -z "${ORACLE_SID}" -o -z "${TWO_TASK}" -o -z "${ORACLE_HOME}" ]
	then
	set +x
	echo"
	+----------------------------------------------------
	|
	|   ERRO!
	|   `date`
	|   Faltam parametros para execucao.
	|
	|   ORACLE_SID=${ORACLE_SID}
	|   TWO_TASK=${TWO_TASK}
	|   ORACLE_HOME=${ORACLE_HOME}
	|   NLS_LANG=${NLS_LANG}
	|   CICLO=${CICLO}
	|
	+----------------------------------------------------\n"
	set -x
	fi



set_var()
{

   ARQ=`ls -rt /pinvoice/ARPU/BGH${SITE}${CICLO}_??????????????.ARPU | tail -1 | awk -F/ '{print $(NF)}'`

   if [ -z "${ARQ}" ]

   then
   ARQ_GZ=`ls -rt /pinvoice/ARPU/BGH${SITE}${CICLO}_??????????????.ARPU.gz | tail -1`
   gunzip ${ARQ_GZ}
   [ $? -ne 0 ] && exit 1

   ARQ=`ls -rt /pinvoice/ARPU/BGH${SITE}${CICLO}_??????????????.ARPU | tail -1 | awk -F/ '{print $(NF)}'`
   fi

	if [ ! -f /pinvoice/ARPU/${ARQ} ]

	then
	set +x
	echo "
	+-----------------------------------------------------------------------------
	|
	|   ERRO! `date`
	|   Nao foi encontrado nenhum arquivo para Loader do Oracle.
	|   Arquivo BGH${SITE}${CICLO}_??????????????.ARPU
	|
	+-----------------------------------------------------------------------------\n" | tee /tmp/arpu_sql_err$$.log
	cat /tmp/arpu_sql_err$$.log
	cat /tmp/arpu_sql_err$$.log | mailx -m -s "ARPU - Nao foi encontrado arquivo para Loader do Oracle. `date`" prod@unix_mail_fwd
	rm -f /tmp/*$$*
	exit 1

	fi

	DATA=`echo ${ARQ} | cut -c8-15`

}

exec_sql()
{


   . /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL} ${SITE} ${CICLO} ${DATA} ${ARQ}" "${EMAIL}" "${DESC}" 0 ARPU_SQL_01 "${SPOOL}"

}

${LOADER[0]}
${LOADER[1]}
