#!/bin/ksh

	# Finalidade : Loader Oracle - Parte 2
	# Input : Arquivo ARPU gerado apos junta_arqs
	# Output : Banco PMIT
	# Autor : Marcos de Benedicto
	# Data : 28/01/2004

set -A LOADER set_var crt_sql exec_sql

EMAIL="prodmsol@nextel.com.br"
EMAIL2="bill_checkout@unix_mail_fwd"
EMAIL3="RevAssuL@nextel.com.br"
PROCSS="ARPU_CARGA_02"

SPOOL="/tmp/sql1.$$.log"
SITE=R
CICLO=`printf "%02s\n" $2`
CTL="/tmp/ctl.$$"

export USRPASS="mitusr/USRMIT10"
export ORACLE_SID=$3
export TWO_TASK=$3
export ORACLE_HOME=`grep ^${ORACLE_SID}: /etc/oratab | cut -d: -f2`
#export NLS_LANG="brazilian portuguese_brazil.we8dec"

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
	D_DATA=`echo ${ARQ} | cut -c8-9`
	M_DATA=`echo ${ARQ} | cut -c10-11`
	Y_DATA=`echo ${ARQ} | cut -c12-15`

	case ${M_DATA} in
			01) M_DATA=JAN;;
			02) M_DATA=FEB;;
			03) M_DATA=MAR;;
			04) M_DATA=APR;;
			05) M_DATA=MAY;;
			06) M_DATA=JUN;;
			07) M_DATA=JUL;;
			08) M_DATA=AUG;;
			09) M_DATA=SEP;;
			10) M_DATA=OCT;;
			11) M_DATA=NOV;;
			12) M_DATA=DEC;;
	esac

	N_DATA="${D_DATA}-${M_DATA}-${Y_DATA}"
}

crt_sql()
{


>${CTL}

echo "
LOAD DATA
BADFILE 'TRASH.bad'
DISCARDFILE 'DISCARD.DSC'

INSERT
INTO TABLE tmit_tmp_txt_file_data APPEND FIELDS
(
  cd_location                   CONSTANT '${SITE}',
  cd_bill_cycle                 CONSTANT '${CICLO}',
  dt_invoice_text_file          CONSTANT \"${N_DATA}\",
  sq_line_text_file             SEQUENCE(MAX,1),
  txt_line_data                 POSITION( 1 : 4000 ) CHAR
)" >>${CTL}

}

exec_sql()
{

${ORACLE_HOME}/bin/sqlldr ${USRPASS}@${ORACLE_SID} ${CTL} data=/pinvoice/ARPU/${ARQ} bad=/tmp/${ARQ}.bad log=/tmp/${ARQ}.log >>/tmp/${ARQ}.out 2>&1

	if [ $? -ne 0 -o `egrep -c "ORA-|LRM-" /tmp/${ARQ}.log` -ne 0 ]

	then
	set +x
	echo "
	+-------------------------------------------------------------------------------------
	|
	|   ERRO! 
	|   `date`
	|   SQL nao foi executado corretamente, verifique o log em anexo.
	|
	+-------------------------------------------------------------------------------------\n" | tee -a /tmp/arpu_sql_err$$.log
	cat /tmp/${ARQ}.log | tee -a /tmp/arpu_sql_err$$.log
	cat /tmp/arpu_sql_err$$.log | mailx -m -s "ARPU - CTL apresentou erro `date`" ${EMAIL}
	rm -f /tmp/*$$*
	exit 1
	fi

}


${LOADER[0]}
${LOADER[1]}
${LOADER[2]}
