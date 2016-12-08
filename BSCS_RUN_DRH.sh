#!/bin/ksh
#
# DRH BSCS_RUN_DRH.sh
#
# Alteracao 06/03/02
#
### ARQCFG=/amb/eventbin/consolidacao/OK/bscs_batch.cfg
### ARQCFG=/amb/operator/cfg/consolidacao/bscs_batch.cfg

ARQCFG=/amb/operator/cfg/bscs_batch.cfg
SCPFUNC=/amb/operator/cfg/script_functions.cfg

# Le arquivo de paramentros
. $ARQCFG

# VARIABLES

ARQTMP=/tmp/.drh_$$
LOG_ARQTMP=$ARQTMP.log
ARQAUX=/tmp/drh_$$.sql
DATA=`date`
EMAIL_ERRO="prodmsol@nextel.com.br,billing_process@nextel.com.br"

# FUNCTIONS

# Carrega arquivo de funcoes utilitarias

. $SCPFUNC         

# MAIN

. /etc/appltab



ARQ_PASSWD=${ENV_DIR_BASE_RTX}/prod/batch/bin/bscs.passwd
export TWO_TASK="${ENV_TNS_PDBSC}"
export ORACLE_HOME="${ENV_DIR_ORAHOME_BSC}"
 
if [ ! -f "$ARQ_PASSWD" ]; then
   echo "$0: Arquivo de senhas não encontrado" | msg_api2  E-RATING-DRH-UPDATE
   exit 1
fi

DRH_PASSWD=`awk '/^DRH[         ]/ { a=$2; } END { print a }' $ARQ_PASSWD`
if [ -z "$DRH_PASSWD" ]; then
   echo "$0: Senha do usuário DRH não encontrada" | msg_api2 E-RATING-DRH-ERRO
   exit 1
fi

cat <<EOF >$ARQAUX 2>$ARQTMP

SET FEED OFF VERIFY OFF ECHO OFF
WHENEVER OSERROR EXIT SQL.OSCODE ROLLBACK
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
UPDATE MPUFCTAB
   SET FLSTA=2
 WHERE FLSTA=10
 AND FLSRC <> 'NOTEL'
;
COMMIT;
EXIT;
EOF

if [ $? != 0 ]; then
   ( echo "$0: Erro ao criar o SQL $ARQAUX"
     cat $ARQTMP ) | msg_api2 "E-RATING-DRH-ERRO"
   echo "$0: Erro ao criar o SQL $ARQAUX"
     cat $ARQTMP 
   rm -f $ARQTMP $ARQAUX
   exit 8
fi

echo
echo "Executando Update Tabela MPUFCTAB..."
echo

${ORACLE_HOME}/bin/sqlplus DRH/${DRH_PASSWD}@${TWO_TASK} @$ARQAUX >$ARQTMP 2>&1
ret=$?

if [ $ret = 0 ]; then
   ( echo "Sucesso no update da tabela MPUFCTAB"
     cat $ARQTMP ) | msg_api2 "I-RATING-DRH-UPDATE"
else
   ( echo "Erro no update da tabela MPUFCTAB"
     cat $ARQTMP ) | msg_api2 "E-RATING-DRH-ERRO"
   echo "Erro no update da tabela MPUFCTAB"
     cat $ARQTMP 
   exit 8
fi

DRHCOMM="drh -t"

######## Coleta de Tempos de processamento. ###########

LOG_DATE=`date +%d%m%Y`
LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
LOG_TIME="${ENV_DIR_BASE_RTX}/prod/reports/DRH_${LOG_DATE}.txt"
export TWO_TASK="${ENV_TNS_PDBSC}"
export NLS_LANG="${ENV_NLSLANG_PDBSC}"
export ORACLE_HOME="${ENV_DIR_ORAHOME_BSC}"
SQL_TIME="/tmp/drh_time.sql"

echo "
set feedback off
set heading off
SELECT COUNT(*) FROM MPUFCTAB
WHERE flsta in (10,12); " >${SQL_TIME}

chmod 777 ${SQL_TIME}

/amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "DRH/${DRH_PASSWD}" "${SQL_TIME}" marcos@unix_mail_fwd "Contagem de DRH" 0 DRH "/tmp/OUT.$$" 
printf "%s\n" `cat /tmp/OUT.$$` >/tmp/count_time.$$
COUNT_TIME="`cat /tmp/count_time.$$`"

printf "%s\t%s\t%s\t%s\n" "DRH" "Inicio do processamento, ${COUNT_TIME} arquivos." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

######## Coleta de Tempos de processamento. ###########

clear
echo "BSCS DUPLICATE RECORD HANDLER - DRH - $DATA"
echo
echo "Comando: $DRHCOMM"
echo "------------------------------------------------------------------"
echo

(
date
echo
echo "------------------------------------------------------------------"
echo "Executando comando: $DRHCOMM"
echo

#chmod 777 /artx_`hostname | cut -c1-2`/prod/WORK/MP/UTX/UTX*
chmod 777 ${ENV_DIR_BASE_RTX}/prod/WORK/MP/UTX/UTX*

su - prod -c "$DRHCOMM"
echo
echo "------------------------------------------------------------------"
echo "Processo Terminado em: "`date`
echo "------------------------------------------------------------------"

) > $ARQTMP

LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"

/amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "DRH/${DRH_PASSWD}" "${SQL_TIME}" marcos@unix_mail_fwd "Contagem de DRH" 0 DRH "/tmp/OUT.$$" 
printf "%s\n" `cat /tmp/OUT.$$` >/tmp/count_time.$$
COUNT_TIME="`cat /tmp/count_time.$$`"

printf "%s\t%s\t%s\t%s\n" "DRH" "Termino do processamento, ${COUNT_TIME} arquivos." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

/amb/bin/msg_api2 "W-RATING-DRH-PROCESSAMENTO" <$ARQTMP

if [ "${COUNT_TIME}" -ne 0 ]
then
    echo "\n\tArquivos pendentes de processamento no DRH, favor NAO dar continuidade no rating ate que o problema seja resolvido.\n"
    echo "\n\tArquivos pendentes de processamento no DRH, favor NAO dar continuidade no rating ate que o problema seja resolvido.\n" |mailx -s "ERRO DRH - Arquivos pendentes." ${EMAIL_ERRO}
    exit 1
fi

cat $ARQTMP >> $LOG_ARQTMP
grep "Starting RIH" $LOG_ARQTMP
if [ $? -ne 0 ]
   then 
        echo "ERRO no DRH"
	exit 44
fi


icat $ARQTMP

[ -f $ARQTMP ] && rm $ARQTMP 
[ -f $ARQAUX ] && rm $ARQAUX 

exit 0 
