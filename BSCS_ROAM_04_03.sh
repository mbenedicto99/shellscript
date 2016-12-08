#!/bin/ksh -x
##
# BSCS_ROAM_04_03.sh
#
# Verifica se o arquivo eh retorno
#
#M#W-RATING-ROAMING-ARQUIVO_RETORNO : Arquivo de Retorno
#M#I-RATING-ROAMING-ARQUIVO_NORMAL  : Arquivo Normal
# Alex da Rocha Lima
# 04-07-2002


TMP=/tmp/roaming_1_$$

arq=$1
site=$2
operadora=$3

DIRWRK=/apgp_sp/sched/bscs_roaming/IN/files/${site}
DIRERR=$DIRWRK/ERROR

cd $DIRERR

if [ -f ${arq}.err -o -f ${arq}.pgp.err ] 
then
   ( echo "$site $operadora $arq - Arquivo de Retorno !") | msg_api2 "W-RATING-ROAMING-ARQUIVO_RETORNO"
   echo "$site $operadora $arq - Arquivo de Retorno !" 
   rm -r ${arq}.err ${arq}.pgp.err
else
   ( echo "$site $operadora $arq - Arquivo normal" ) | msg_api2 "I-RATING-ROAMING-ARQUIVO_NORMAL"
   echo "$site $operadora $arq - Arquivo normal" 
fi

exit 0
