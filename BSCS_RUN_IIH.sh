#!/bin/ksh
#
# Alteracao 06/03/02
#
### Alterado em 2003/08/21 - Consolidacao MIBAS/BSCS
. /etc/appltab 


### ARQCFG=/amb/eventbin/consolidacao/OK/bscs_batch.cfg
### ARQCFG=/amb/operator/cfg/consolidacao/bscs_batch.cfg

ARQCFG=/amb/operator/cfg/bscs_batch.cfg
SCPFUNC=/amb/operator/cfg/script_functions.cfg

# Le arquivo de paramentros
. $ARQCFG

# VARIABLES

#UNAME=$1
ARQTMP=/tmp/.iih_$$
DATA=`date`

# FUNCTIONS

# Carrega arquivo de funcoes utilitarias

. $SCPFUNC         

# MAIN

# Checa se esta rodando na maquina correta
#AUX=`expr "$FIHMAQS" : ".*$UNAME"`
#if [ $AUX != 0 ]
#   then UF=`expr substr $UNAME 1 2`
#   else clear
#      echo "Este programa esta rodando em maquina incorreta"
#      echo "Maquinas validas: $FIHMAQS"
#      exit 1
#fi 

IIHCOMM="iih -t"

clear
echo "BSCS FILE INPUT HANDLER - IIH - $DATA"
echo
echo "Comando: $IIHCOMM"
echo "------------------------------------------------------------------"
echo

(
date
echo
echo "------------------------------------------------------------------"
echo "Executando comando: $IIHCOMM"
echo
su - prod -c "$IIHCOMM"
echo
echo "------------------------------------------------------------------"
echo "Processo Terminado em: "`date`
echo "------------------------------------------------------------------"

) > $ARQTMP

echo $?

cat $ARQTMP

/amb/bin/msg_api "W-BSCS_IIH-001" <$ARQTMP

[ -f $ARQTMP ] && rm $ARQTMP 

exit 0
