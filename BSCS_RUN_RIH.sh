#!/bin/ksh
#
# RIH
# BSCS_RUN_RIH
#
# Alteracao 14/06/2002
# Alex da Rocha Lima

### SITE="`hostname | cut -c1-2`"

. /etc/appltab

SITE="${ENV_VAR_SITE}"

# cp -R /artx_$SITE/prod/WORK/MP/RTX/RIH/HPLMN/BC??/* /var/adm/crash
# find /artx_$SITE/prod/WORK/MP/UTX -name "U*" | cpio -pvmud /var/adm/crash

chmod -R 777 /var/adm/crash/*

ARQCFG=/amb/operator/cfg/bscs_batch.cfg
SCPFUNC=/amb/operator/cfg/script_functions.cfg

# Le arquivo de paramentros
. $ARQCFG

# VARIABLES

UNAME=$1
ARQTMP=/tmp/.rih_$$
LOG_ARQTMP=/tmp/.rih_$$.log
DATA=`date`

# FUNCTIONS

# Carrega arquivo de funcoes utilitarias

. $SCPFUNC         

# MAIN



RIHCOMM="rih -e -t"

LOG_DATE=`date +%d%m%Y`
LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
LOG_TIME="${ENV_DIR_BASE_RTX}/prod/reports/RIH_${LOG_DATE}.txt"
COUNT_TIME=`ls ${ENV_DIR_BASE_RTX}/prod/WORK/MP/UTX/UTX* 2>/dev/null | wc -l`

printf "%s\t%s\t%s\t%s\n" "RIH" "Inicio do processamento, ${COUNT_TIME} arquivos UTX." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

clear
echo "BSCS FILE INPUT HANDLER - RIH - $DATA"
echo
echo "Comando: $RIHCOMM"
echo "------------------------------------------------------------------"
echo

(
date
echo
echo "------------------------------------------------------------------"
echo "Executando comando: $RIHCOMM"
echo
su - prod -c "$RIHCOMM"
echo
echo "------------------------------------------------------------------"
echo "Processo Terminado em: "`date`
echo "------------------------------------------------------------------"

) > $ARQTMP

su - sched -c "/amb/eventbin/VER_REJ_RIH.sh"

LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
COUNT_TIME=`ls ${ENV_DIR_BASE_RTX}/prod/WORK/MP/UTX/UTX* 2>/dev/null | wc -l`

printf "%s\t%s\t%s\t%s\n" "RIH" "Termino do processamento, ${COUNT_TIME} arquivos UTX." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

/amb/bin/msg_api2 "W-RATING-RIH-PROCESSAMENTO" <$ARQTMP

cat $ARQTMP >$LOG_ARQTMP
grep "Terminating normally" $LOG_ARQTMP
if [ $? -ne 0 ]
   then 
       echo "ERRO no RIH"
       exit 44
fi

su - sched -c "/amb/eventbin/CHECK_RIH.sh"
[ "${?}" -ne 0 ] && exit 1

rm -f $ARQTMP $ARQTMP1 $LOG_ARQTMP

[ -f $ARQTMP ] && rm $ARQTMP 

exit 0 
