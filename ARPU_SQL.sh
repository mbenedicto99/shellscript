#!/bin/ksh

	# Finalidade : Loader Oracle
	# Input : Arquivo ARPU gerado apos junta_arqs
	# Output : Banco PMIT
	# Autor : Marcos de Benedicto
	# Data : 28/05/2003

set -A LOADER set_var crt_sql exec_sql mv_file

EMAIL="prodmsol@nextel.com.br"
EMAIL2="bill_checkout@unix_mail_fwd"
EMAIL3="RevAssuL@nextel.com.br"
PROCSS="ARPU_LOADER"


case $1 in

	R|RJ) SITE="R" ;;
	S|SP) SITE="S" ;;
	   
	   *) set +x   
   	echo "
	+------------------------------------------------
	|
	|   ERRO! `date` 
	|   Informar site como S ou R.
	|
	+------------------------------------------------\n" | tee /tmp/arpu_sql_err$$.log
	cat /tmp/arpu_sql_err$$.log | mailx -m -s "${PROCSS} - Erro na passagem do parametro" ${EMAIL}
	rm -f /tmp/*$$*
	exit 1 ;;

esac

CICLO=`printf "%02s\n" $2`

if [ -z "${CICLO}" ]

	then
	set +x
	echo "
	+----------------------------------------------
	|
	|   ERRO! `date` 
	|   Nao foi informado o ciclo.
	|
	+----------------------------------------------\n" | tee /tmp/arpu_sql_err$$.log
	cat /tmp/arpu_sql_err$$.log | mailx -m -s "${PROCSS} - Erro na passagem do parametro" ${EMAIL}
	rm -f /tmp/*$$*
	exit 1
	fi

export ORACLE_SID=$3

if [ -z "${ORACLE_SID}" ]

	then
	set +x
	echo "
	+----------------------------------------------------
	|
	|   ERRO! `date` 
	|   Nao foi informado o banco.
	|
	+----------------------------------------------------\n" | tee /tmp/arpu_sql_err$$.log
	cat /tmp/arpu_sql_err$$.log | mailx -m -s "${PROCSS} - Erro na passagem do parametro" ${EMAIL}
	rm -f /tmp/*$$*
	exit 1
	fi

export ORACLE_HOME=`grep ^${ORACLE_SID}: /etc/oratab | cut -d: -f2`

if [ -z "$ORACLE_HOME" ] 

	then
	set +x
	echo "
	+----------------------------------------------------
	|
	|   ERRO! `date`
	|   Nao foi localizado o Oracle Home.
	|
	+----------------------------------------------------\n" | tee /tmp/arpu_sql_err$$.log
	cat /tmp/arpu_sql_err$$.log | mailx -m -s "${PROCSS} - Erro na passagem do parametro" ${EMAIL}
	rm -f /tmp/*$$*
	exit 1
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
		N_DATA=`echo "${D_DATA}-${M_DATA}-${Y_DATA}"`
}

crt_sql()
{


>/tmp/sql1.$$
>/tmp/sql2.$$
>/tmp/ctl.$$

echo "
declare

W_RET varchar2(100);
W_LOCAL char(1);
W_CICLO char(2);
W_DATA  varchar2(10);
W_ARQUIVO varchar2(50);
W_ERRO exception;
begin

W_LOCAL   := '${SITE}';
W_CICLO   := '${CICLO}';
W_DATA    := to_char(to_date('${DATA}','ddmmyyyy'),'dd/mm/yyyy');
W_ARQUIVO := '${ARQ}';

 	KMIT_LOAD_FILE.PMIT_FILE_CONTROL(W_LOCAL,
                                         W_CICLO,
                                         W_DATA,
                              		 W_ARQUIVO,
                                         W_RET);
exception when others then raise W_ERRO;
end;
/" >/tmp/sql1.$$

echo "
LOAD DATA
BADFILE 'TRASH.bad'
DISCARDFILE 'DISCARD.DSC'

INSERT 
INTO TABLE tmit_tmp_txt_file_data APPEND FIELDS
(
  cd_location			CONSTANT '${SITE}',
  cd_bill_cycle			CONSTANT '${CICLO}',  
  dt_invoice_text_file          CONSTANT \"${N_DATA}\",
  sq_line_text_file		SEQUENCE(MAX,1),
  txt_line_data			POSITION( 1 : 4000 ) CHAR
)" >/tmp/ctl.$$

echo "
declare
	W_RET varchar2(100);
	W_LOCAL char(1);
	W_CICLO char(2);
	W_DATA  varchar2(10);	
	W_ERRO exception;
begin
	W_LOCAL   := '${SITE}';
	W_CICLO   := '${CICLO}';
	W_DATA    := to_char(to_date('${DATA}','ddmmyyyy'),'dd/mm/yyyy');
	
        begin
	KMIT_LOAD_FILE.PMIT_PROCESS_FILE_DATA(W_LOCAL,
					      W_CICLO,
					      W_DATA,
					      W_RET);end;
exception when others then raise W_ERRO;
end;
/" >/tmp/sql2.$$


}

exec_sql()
{

CTL="/tmp/ctl.$$"

$ORACLE_HOME/bin/sqlplus  mitusr/USRMIT10@${ORACLE_SID} @/tmp/sql1.$$ >/tmp/sql1.$$.log 2>&1

	if [ $? -ne 0 -o `grep -c "ORA-" /tmp/sql1.$$.log` -ne 0 ]

	 then
	 set +x
	 echo "
	 +----------------------------------------------------------------------------------
	 |
	 |   ERRO! `date`
	 |   SQL nao foi executado corretamente, verifique o log em anexo.
	 |
	 +----------------------------------------------------------------------------------\n" | tee -a /tmp/arpu_sql_err$$.log
	 cat /tmp/sql1.$$.log | tee -a /tmp/arpu_sql_err$$.log
	 cat /tmp/arpu_sql_err$$.log | mailx -m -s "ARPU - SQL apresentou erro `date`" ${EMAIL}
	 rm -f /tmp/*$$*
	 exit 1
	 fi

$ORACLE_HOME/bin/sqlldr mitusr/USRMIT10@${ORACLE_SID} ${CTL} data=/pinvoice/ARPU/${ARQ} bad=/tmp/${ARQ}.bad log=/tmp/${ARQ}.log >>/tmp/${ARQ}.out 2>&1

	if [ $? -ne 0 -o `grep -c "ORA-" /tmp/${ARQ}.log` -ne 0 ]

	 then
	 set +x
	 echo "
	 +-------------------------------------------------------------------------------------
	 |
	 |   ERRO! `date`
	 |   SQL nao foi executado corretamente, verifique o log em anexo.
	 |
	 +-------------------------------------------------------------------------------------\n" | tee -a /tmp/arpu_sql_err$$.log
	 cat /tmp/${ARQ}.log | tee -a /tmp/arpu_sql_err$$.log
	 cat /tmp/arpu_sql_err$$.log | mailx -m -s "ARPU - CTL apresentou erro `date`" ${EMAIL}
	 rm -f /tmp/*$$*
	 exit 1
	 fi

$ORACLE_HOME/bin/sqlplus mitusr/USRMIT10@${ORACLE_SID} @/tmp/sql2.$$ >/tmp/sql2.$$.log 2>&1

	if [ $? -ne 0 -o `grep -c "ORA-" /tmp/sql2.$$.log` -ne 0 ]

	 then
	 set +x
	 echo "
	 +------------------------------------------------------
	 |
	 |   ERRO! `date`
	 |   Ocorreu algum problema com o SQL.
	 |
	 +------------------------------------------------------\n" | tee -a /tmp/arpu_sql_err$$.log
	 cat /tmp/sql2.$$.log | tee -a /tmp/arpu_sql_err$$.log
	 cat /tmp/arpu_sql_err$$.log | mailx -m -s "ARPU - SQL apresentou erro `date`" ${EMAIL}
	 rm -f /tmp/*$$*
	 exit 1
	 fi

}

mv_file()
{

	set -x

	gzip -9 /pinvoice/ARPU/${ARQ}

	mv /pinvoice/ARPU/${ARQ}.gz /pinvoice/ARPU/ENVIADOS

	rm -f /tmp/*$$*

}

${LOADER[0]}
${LOADER[1]}
${LOADER[2]}
${LOADER[3]}
