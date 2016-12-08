#!/bin/ksh
# Alterado: 14/06/2002
# Alex da Rocha Lima
#


### Alterado em 2003/08/21 - Consolidacao MIBAS/BSCS
### ARQCFG=/amb/eventbin/consolidacao/OK/bscs_batch.cfg
### ARQCFG=/amb/operator/cfg/consolidacao/bscs_batch.cfg
ARQCFG=/amb/operator/cfg/bscs_batch.cfg
SCPFUNC=/amb/operator/cfg/script_functions.cfg

# Le arquivo de paramentros
. $ARQCFG

# VARIABLES

. /etc/appltab

typeset -l -L3 CITY
#UNAME=$1
CITY="${ENV_VAR_CITY}"

ARQTMP=/tmp/.rih_$$
DATA=`date`

# FUNCTIONS

# Carrega arquivo de funcoes utilitarias

. $SCPFUNC         

# MAIN

# Checa se esta rodando na maquina correta
#AUX=`expr "$PRHMAQS" : ".*$UNAME"`
#if [ $AUX != 0 ]
#   then UF=`expr substr $UNAME 1 2`
#   else clear
#      echo "Este programa esta rodando em maquina incorreta"
#      echo "Maquinas validas: $PRHMAQS"
#      exit 1
#   fi 
#
case "${CITY}" in
     spo) PRHCOMM="prh -t -p3501 10.201.11.111" ;; 
     rjo) PRHCOMM="prh -t -p3501 10.201.11.111" ;;
        *) exit 1 ;;
esac

LOG_DATE=`date +%d%m%Y`
LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
LOG_TIME="${ENV_DIR_BASE_RTX}/prod/reports/PRH_${LOG_DATE}.txt"

printf "%s\t%s\t%s\t%s\n" "PRH" "Inicio do processamento." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

clear
echo "BSCS PREPAY RECORD HANDLER - PRH - $DATA"
echo
echo "Comando: $PRHCOMM"
echo "------------------------------------------------------------------"
echo

(
date
echo
echo "------------------------------------------------------------------"
echo "Executando comando: $PRHCOMM"
echo
su - prod -c "$PRHCOMM"
echo
echo "------------------------------------------------------------------"
echo "Processo Terminado em: "`date`
echo "------------------------------------------------------------------"

) > $ARQTMP

LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"

printf "%s\t%s\t%s\t%s\n" "PRH" "Termino do processamento." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

icat $ARQTMP

/amb/bin/msg_api2 "W-RATING-PRH-PROCESSAMENTO" <$ARQTMP
 
cat $ARQTMP

rm -f $ARQTMP $ARQTMP1

[ -f $ARQTMP ] && rm $ARQTMP 

exit 0 
