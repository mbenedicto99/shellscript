#!/bin/ksh

	# Finalidade    : Sincronismo de Planos e Servicos entre BSCS e Vantive
	# Input         :
	# Output        : mail, log
	# Autor         : Marcos de Benedicto
	# Data          : 17/09/2004


	. /etc/appltab

	banner $$

	DATA=`date +%Y%m%d%H%M`
	SPOOL="${ENV_DIR_BASE_COR}/sched/corp/LOG/BDC_13_01M_A${DATA}.log"
	SQL0="/tmp/atualiza_BDC.sql"
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

chmod 777 ${SQL0}

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


   . /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL0}" "${DEST}" "${DESC}" 0 BSCSxVANTIVE 0
   
exit 0
