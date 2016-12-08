#!/bin/ksh

	# Finalidade    : Sincronismo de Planos e Servicos entre BSCS e Vantive
	# Input         :
	# Output        : mail, log
	# Autor         : Marcos de Benedicto
	# Data          : 17/09/2004


	. /etc/appltab

	banner $$

	DATA=`date +%Y%m%d%H%M`
	SPOOL="${ENV_DIR_BASE_COR}/sched/corp/LOG/BDC_13_01_A${DATA}.log"
	SPOOL1="${ENV_DIR_BASE_COR}/sched/corp/LOG/BDC_13_01_B${DATA}.log"
	##SQL0="/amb/scripts/corp/atualiza_BDC.sql"
	##SQL1="/amb/scripts/corp/gera_rel.sql"
	SQL0="/tmp/atualiza_BDC.sql"
	SQL1="/tmp/gera_rel.sql"
	DEST="prodmsol@nextel.com.br"
	DESC="Sincronismo de Planos e Servicos entre BSCS e Vantive"

	export USRPASS="/"
	export TWO_TASK=${ENV_TNS_PDCOR}
	export ORACLE_SID=${ENV_ORASID_PDCOR}
	export ORACLE_HOME=${ENV_DIR_ORAHOME_COR}
	export NLS_LANG=${ENV_NLSLANG_PDCOR}

echo "set serveroutput off
spool ${SPOOL}
begin
PK_BSCS_BDC.PR_BSCS_BDC_01;
end;
/
spool off
exit" >${SQL0}

echo "
  whenever sqlerror exit failure
  whenever oserror exit failure
  set pagesize 1000
  set linesize 80
  spool ${SPOOL1}

Select cod_site, ' ' tmcode, ' ' vscode, sncode, tipo_erro, desc_erro
  from corp.tmp_servico_erro
  where trunc(sysdate) = trunc(dt_proc)
  union
  select cod_site, to_char(tmcode) tmcode, to_char(vscode) vscode, sncode, tipo_erro, desc_erro
  from corp.tmp_rate_plan_erro
  where trunc(sysdate) = trunc(dt_proc);
  spool off
  exit " >${SQL1}

chmod 777 ${SQL0} ${SQL1}

	set +x
	echo "
	+------------------------------------------------
	|
	|   Informacao
	|
	|   `date`
	|   PID = $$
	|   SQL = ${SQL}
	|   DEST = ${DEST}
	|   DESCRICAO = ${DESC}
	|   ORACLE_SID = ${ORACLE_SID}
	|   TWO_TASK = ${TWO_TASK}
	|   ORACLE_HOME = ${ORACLE_HOME}
	|
	+------------------------------------------------\n"
	set -x


   . /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL0}" "${DEST}" "${DESC}" 0 BSCSxVANT 0
   
   . /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL1}" "${DEST}" "${DESC}" 0 BSCSxVANT 0


# Limpeza da area de trabalho
find ${ENV_DIR_BASE_COR}/sched/corp/LOG -type f -mtime +2 -exec rm -f {} \;

exit 0
