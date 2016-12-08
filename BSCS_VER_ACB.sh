#!/bin/ksh

	# Finalidade	: Verificar arquivos ACOBRAR
	# Input 	: BYPASS
	# Output	: FIH
	# Autor		: Marcos de Benedicto
	# Data		: 13/10/2003

set -A VERIF ind_0 ind_1 ind_2

. /etc/appltab

SQL=/tmp/sql_$$.sql
ARQ_PASSWD=${ENV_DIR_BASE_RTX}/prod/batch/bin/bscs.passwd
TIH_PASSWD=`awk '/^TIH[ 	]/ { a=$2; } END { print a }' $ARQ_PASSWD`
EMAIL="lausanne@unix_mail_fwd"
export TWO_TASK="${ENV_TNS_PDBSC}"
USRPASS="${ENV_LOGIN_PDBSC}"
export ORACLE_HOME="${ENV_DIR_ORAHOME_BSC}"
export NLS_LANG="${ENV_NLSLANG_PDBSC}"

LOG_DATE=`date +%d%m%Y`
LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
LOG_TIME="${ENV_DIR_BASE_RTX}/prod/reports/VER_ACB_${LOG_DATE}.txt"
	DIR="${ENV_DIR_BASE_RTX}/prod/WORK/MP/UTX"
	COUNT=`ls ${DIR}/UTX* 2>/dev/null | wc -l`

printf "%s\t%s\t%s\t%s\n" "VERIFICA_ACB" "Inicio do processamento, ${COUNT} arquivos." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

ind_0()
{

echo "
set feedback off
set heading off
SELECT COUNT (*) FROM THUFITAB 
WHERE STATUS=0
AND FILE_TYPE=1 
AND FILENAME NOT LIKE '%BA';" >${SQL}

	cat ${SQL}

	[ -f ${SQL} ] && chmod 777 ${SQL} || exit 1
	
	${VERIF[1]}
}

ind_1()
{

	set -x

	$ORACLE_HOME/bin/sqlplus -s ${USRPASS} @${SQL}  >/tmp/ARQ.$$ 

	if [ $? -ne 0 -o `grep -c "ORA-" /tmp/ARQ.$$` -ne 0 ]
	then
	set +x
  	echo "
	+---------------------------------------------------------------
	|
	|   ERRO!
	|   `date`
	|   Processamento de Verificacao apresentou erro!
	|
	+---------------------------------------------------------------\n" | tee -a /tmp/mail_$$
	cat /tmp/ARQ.$$ >>/tmp/mail_$$
	cat /tmp/mail_$$ | mailx -m -s "RATING - Processo de verificacao apresentou erro." ${EMAIL}
	cat /tmp/ARQ.$$
  	rm -f /tmp/*$$*
  	exit 1
  	
	fi

	printf "%s\n" `cat tmp/ARQ.$$` >/tmp/OUT.$$

	if [ `cat /tmp/OUT.$$` -eq 0 ]

	then
	LOC_TIME1="`date +%d/%m/%Y`"
	LOC_TIME2="`date +%H:%M:%S`"
  
        printf "%s\t%s\t%s\t%s\n" "VERIFICA_ACB" "Nao foram encontrados arquivos ACB na THUFITAB." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

	${VERIF[2]}

	else
	set +x
	>/tmp/MAIL.$$
	echo "
	+--------------------------------------------------------------
	|
	|   ERRO!
	|   `date`
	|   Verificacao identificou valor diferente de 0.
	|   Arquivos nao ACB encontrados na THUFITAB.
	|
	+--------------------------------------------------------------\n" >>/tmp/MAIL.$$
	cat /tmp/MAIL.$$ | mailx -m -s "RATING - Processo de verificacao identificou erro." ${EMAIL}
	exit 1
	fi

}

ind_2()
{

	DIR="${ENV_DIR_BASE_RTX}/prod/WORK/MP/UTX"
	COUNT=`ls ${DIR}/UTX* 2>/dev/null | wc -l`

  if [ ${COUNT} -eq 0 ]
  then

	LOC_TIME1="`date +%d/%m/%Y`"
	LOC_TIME2="`date +%H:%M:%S`"
  
  printf "%s\t%s\t%s\t%s\n" "VERIFICA_ACB" "Termino do processamento, ${COUNT} arquivos UTX." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}
  
  exit 0

  else
  set +x
  echo "
  +-------------------------------------------------------------------------------------
  |
  |   ERRO!
  |   `date`
  |   Foi encontrado ${COUNT} arquivo(s) nao ACB no diretorio ${DIR}.
  |
  +-------------------------------------------------------------------------------------\n" >>/tmp/MAIL.$$
  cat /tmp/MAIL.$$ | mailx -m -s "RATING - Processo de verificacao identificou erro." ${EMAIL}
  exit 1

  fi

}

${VERIF[0]}
