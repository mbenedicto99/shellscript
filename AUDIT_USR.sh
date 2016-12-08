#!/bin/ksh

	# Finalidade	: Auditar ambiente Oracle, relacionando usuarios logados na rede com usuarios de Oracle.
	# Input		: /amb/scripts/sql/audit_usr.sql
	# Output	: Relatorio com divergencias.
	# Autor		: Marcos de Benedicto
	# Data		: 30/05/2005

. /etc/appltab


	export USRPASS="/"
	export ORACLE_HOME="${ENV_DIR_ORAHOME_PNXTL01}"
	export NLS_LANG="${NLS_NLSLANG_PNXTL01}"
	export TWO_TASK="PNXTL04"

DIR_DEP="/aplic/audit"
DATE=`date +%Y%m%d`
DIR_Y=`date +%Y`
DIR_M=`date +%m`
SQL="/amb/scripts/sql/audit_usr.sql"
SPOOL="/tmp/sql_$$.out"
DESC="AUDITORIA, LOGINS GENERICOS"
DEST="analise_producao@nextel.com.br"
LOG_DIVERG="/tmp/logins_genericos_${DATE}.xls"
OUT="/tmp/err_${DATE}.txt"
DB_LINKS="/amb/eventbin/dblinks.txt"
>${LOG_DIVERG}.tmp1



	. /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL}" "${DESC}" "${DEST}" 0 AUDIT "${LOG_DIVERG}.tmp" 2>${OUT}

	# Limpeza de DB_LINKS
	for i in `cat ${DB_LINKS}`
	do
		cat ${LOG_DIVERG}.tmp | grep -v "$i" >>${LOG_DIVERG}.tmp1
		mv ${LOG_DIVERG}.tmp1 ${LOG_DIVERG}.tmp
	done

	sed 's/;/	/g' ${LOG_DIVERG}.tmp | egrep -v "LNK|MSACCESS.EXE|DBL|;C:" | grep "^P" >${LOG_DIVERG}



	/amb/operator/bin/attach_mail bin ${DEST} ${LOG_DIVERG} ${DESC}

		mkdir -p ${DIR_DEP}/${DIR_Y}/${DIR_M}
		mv ${LOG_DIVERG} ${DIR_DEP}/${DIR_Y}/${DIR_M}/
		rm ${LOG_DIVERG}.tmp

