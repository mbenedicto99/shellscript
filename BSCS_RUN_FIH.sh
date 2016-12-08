#!/bin/ksh
# 
# FIH 
# BSCS_RUN_FIH.sh
#
# Alteracao 06/03/02
#

. /etc/appltab

### Alterado em 2003/08/21 - Consolidacao MIBAS/BSCS
### ARQCFG=/amb/eventbin/consolidacao/OK/bscs_batch.cfg
### ARQCFG=/amb/operator/cfg/consolidacao/bscs_batch.cfg
ARQCFG=/amb/operator/cfg/bscs_batch.cfg
SCPFUNC=/amb/operator/cfg/script_functions.cfg

# Le arquivo de paramentros
. $ARQCFG

# VARIABLES

#UNAME=$1
ARQTMP=/tmp/.fih_$$
DATA=`date`
LOG_ARQTMP=/tmp/.fih_$$.log
ANO=`date +'%Y'`
MES=`date +'%m'`
DIA=`date +'%d'`
HORA=`date +%H:%M`
LOG=/tmp/fih_${ANO}_${MES}_${DIA}_${HORA}.log

# FUNCTIONS

# Carrega arquivo de funcoes utilitarias

. $SCPFUNC         

# MAIN


### Alterado em 2003/08/21 - Consolidacao MIBAS/BSCS
#ksh -x BSCS_HOT_01_02.sh $1
###  ksh -x /amb/eventbin/consolidacao/OK/BSCS_HOT_01_02.sh $1  || exit 99

FIHCOMM="fih -t"

######### Coleta de tempo #############
# Marcos de Benedicto 20/10/2003

LOG_DATE=`date +%d%m%Y`
LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
LOG_TIME="${ENV_DIR_BASE_RTX}/prod/reports/FIH_${LOG_DATE}.txt"
US_PS_TIME="${ENV_LOGIN_PDBSC}"
export NLS_LANG="${ENV_NLSLANG_PDRTX}"
export TWO_TASK="${ENV_TNS_PDRTX}"
export ORACLE_HOME="${ENV_DIR_ORAHOME_RTX}"
SQL_TIME=/tmp/fih_sql_time.sql
SQL_DAP="/amb/scripts/sql/VER_REJ_DAP.sql"
SQL_NORTEL="/amb/scripts/sql/VER_REJ_NORTEL.sql"
SPOOL_DAP="/tmp/VER_REJ_DAP_$$.txt"
SPOOL_NORTEL="/tmp/VER_REJ_NORTEL_$$.txt"

echo "
set feedback off
set heading off
SELECT COUNT(*) FROM THUFITAB
WHERE status = 0
AND file_type not in (25,99);" >${SQL_TIME}

chmod 777 ${SQL_TIME}


/amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${US_PS_TIME}" "${SQL_TIME}" prodmsol@nextel.com.br "Contagem de FIH" 0 FIH "/tmp/OUT.$$"

#+++++++++++++++++++++++++++++++++++++++++++++++++++++

[ -f /tmp/OUT_ERR.txt ] && cat /tmp/OUT_ERR.txt

#+++++++++++++++++++++++++++++++++++++++++++++++++++++

printf "%s\n" `cat /tmp/OUT.$$` >/tmp/count_time.$$
printf "%s\t%s\t%s\t%s\n" "FIH" "Inicio do processamento, `cat /tmp/count_time.$$` arquivos." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

######### Coleta de tempo #############

clear
echo "BSCS FILE INPUT HANDLER - FIH - $DATA"
echo
echo "Comando: $FIHCOMM"
echo "------------------------------------------------------------------"
echo

(
  date
  echo
  echo "------------------------------------------------------------------"
  echo "Executando comando: $FIHCOMM"
  INICIO="`date +%H:%M:%S`"
  echo
  su - prod -c "$FIHCOMM"
  echo
) > $ARQTMP


/amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${US_PS_TIME}" "${SQL_DAP}" billing_process@nextel.com.br "Verifica arquivos rejeitados DAP" 0 FIH "${SPOOL_DAP}"
/amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${US_PS_TIME}" "${SQL_NORTEL}" billing_process@nextel.com.br "Verifica arquivos rejeitados NORTEL" 0 FIH "${SPOOL_NORTEL}"

COUNT_DAP=`cat ${SPOOL_DAP}`
COUNT_NORTEL=`cat ${SPOOL_NORTEL}`

if [ ${COUNT_DAP} -ne 0 ]
then
    echo "Foram rejeitados ${COUNT_DAP} arquivos DAP pelo FIH" |mailx -s "Rejeicao FIH - DAP" billing_process@nextel.com.br,551178194649@page.nextel.com.br,551178561064@page.nextel.com.br,551178347386@page.nextel.com.br,551178347200@page.nextel.com.br,551177112663@page.nextel.com.br,551178363860@page.nextel.com.br
fi
if [ ${COUNT_NORTEL} -ne 0 ]
then
    echo "Foram rejeitados ${COUNT_NORTEL} arquivos NORTEL pelo FIH" |mailx -s "Rejeicao FIH - NORTEL" billing_process@nextel.com.br,551178194649@page.nextel.com.br,551178561064@page.nextel.com.br,551178347386@page.nextel.com.br,551178347200@page.nextel.com.br,551177112663@page.nextel.com.br,551178363860@page.nextel.com.br
fi

######### Coleta de tempo #############
LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"

>/tmp/OUT.$$
/amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${US_PS_TIME}" "${SQL_TIME}" marcos@unix_mail_fwd "Contagem de FIH" 0 FIH "/tmp/OUT.$$"

printf "%s\n" `cat /tmp/OUT.$$` >/tmp/count_time.$$
printf "%s\t%s\t%s\t%s\n" "FIH" "Termino do processamento, `cat /tmp/count_time.$$` arquivos." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

######### Coleta de tempo #############

cp $ARQTMP $LOG
#/amb/bin/msg_api "W-BSCS_FIH-001" <$ARQTMP
#/amb/bin/msg_api "W-RATING_FIH-PROCESSAMENTO" <$ARQTMP
/amb/bin/msg_api2 "W-RATING-FIH-PROCESSAMENTO" <$ARQTMP

cat $ARQTMP >> $LOG_ARQTMP
grep "Can not start rih" $LOG_ARQTMP
if [ $? = 0 ]
then
    exit 44
fi


[ -f ${SPOOL_DAP} ] && rm ${SPOOL_DAP}
[ -f ${SPOOL_NORTEL} ] && rm ${SPOOL_NORTEL}
[ -f $ARQTMP ] && rm $ARQTMP 

exit 0 
