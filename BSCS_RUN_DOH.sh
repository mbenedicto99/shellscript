#!/bin/ksh
#
# Script : /amb/eventbin/BSCS_RUN_DOH.sh
# Alteracao 06/03/02
# OBS    : Nao executar este script sem Autorizacao Previa
#

### ARQCFG=/amb/eventbin/consolidacao/OK/bscs_batch.cfg
### ARQCFG=/amb/operator/cfg/consolidacao/bscs_batch.cfg

ARQCFG=/amb/operator/cfg/bscs_batch.cfg
SCPFUNC=/amb/operator/cfg/script_functions.cfg

# Le arquivo de paramentros 

. /etc/appltab

. $ARQCFG

# VARIABLES

typeset -l -L2 SITE

#SITE=$1
#PARAM=$2
#DB=$3

SITE="${ENV_VAR_SITE}"
PARAM=$2
DB="${ENV_TNS_PDBSC}"

ARQTMP=/tmp/.rih_$$
DATA=`date`


# Carrega arquivo de funcoes utilitarias

. $SCPFUNC         


case ${PARAM} in

   report) SCRIPT=DOH_01.sh
           ;;
   output) SCRIPT=DOH_OUT_01.sh
           ;;
        *) echo "Tipo desconhecido ($PARAM)"
           exit 1
           ;;
esac

LOG_DATE=`date +%d%m%Y`
LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
LOG_TIME="${ENV_DIR_BASE_RTX}/prod/reports/TAPOUT_${LOG_DATE}.txt"

printf "%s\t%s\t%s\t%s\n" "DOH" "Inicio do processamento." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

clear
echo "BSCS DEVICE OUTPUT HANDLER - DOH - ${PARAM} - `date`

SCRIPT: ${SCRIPT}
------------------------------------------------------------------\n"

date

echo "\n------------------------------------------------------------------
Executando script: ${SCRIPT}\n"

### su - prod -c "/amb/eventbin/consolidacao/OK/${SCRIPT} ${SITE} ${DB}" >$ARQTMP 2>&1
su - prod -c "${SCRIPT} ${SITE} ${DB}" >$ARQTMP 2>&1
ret=$?


echo "\nReturn code: $ret\n
------------------------------------------------------------------
Processo Terminado em: `date`
------------------------------------------------------------------\n"


if [ $ret = 0 ]
   then
       /amb/bin/msg_api "I-BSCS_DOH-002" <$ARQTMP
   else 
       /amb/bin/msg_api "E-BSCS_DOH-002" <$ARQTMP
fi

LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"

printf "%s\t%s\t%s\t%s\n" "DOH" "Termino do processamento." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

cat $ARQTMP
rm -f $ARQTMP

exit ${ret}

