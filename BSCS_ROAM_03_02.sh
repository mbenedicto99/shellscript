#!/bin/ksh 
##  Programa: BSCS_ROAM_03_02.sh - Reenvia os arquivos a Connect Entherprise
#
#   Data: 12/06/2001
#   Renato
#
# Alteracao 06/03/02
#
## Mensagens
#M#I-BSCS_ROAM-032 : Arquivo reenviado com sucesso
#M#E-BSCS_ROAM-032 : Erro no reenvio do arquivo
#M#E-BSCS_ROAM-033 : Erro de infra-estrutura
#

# Definicao de Variaveis

MAQ=`uname -n`

DIRWRK=/tmp
RCV=/transf/rcv 
TMP=$DIRWRK/bscs_roam_$$.txt
Dir_reenvio="/home/ceuser/REENVIO_CE"

cd $Dir_reenvio 2>$TMP
if [ $? != 0 ]; then
   ( echo "Erro no cd $Dir_reenvio" ; cat $TMP ) | msg_api "E-BSCS_ROAM-033"
   rm -f $TMP
   exit 1
fi

for file in ????DBRANC??????????.pgp 
    do [ ! -f $file ] && continue
    mv $file $RCV 2>$TMP
    if [ $? != 0 ]; then
      ( echo "$file Erro no reenvio" ; cat $TMP ) | msg_api "E-BSCS_ROAM-032"
      rm -f $TMP
      exit 1
    fi
    echo "$file - Sucesso no reenvio " | msg_api "I-BSCS_ROAM-032"
 done

rm -f $TMP
exit 0
