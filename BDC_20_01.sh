#!/bin/ksh 
##  Programa: BDC_20_01.sh Recebe arquivo de Precos para carga no Vantive
#
#   Data: 09/06/99
#   Renato
#
## Mensagens
#M#I-INTERFACES-PRECOS-RECEBIMENTO : Arquivo de Precos recebido com sucesso
#M#E-INTERFACES-PRECOS-RECEBIMENTO : Erro no recebimento do arquivo de Precos
#M#E-INTERFACES-PRECOS-RECEBIMENTO : Erro de infra-estrutura
#

# Definicao de Variaveis

#=================================================================#
# Alteracao da consolidacao PCORP  - Edison /Workmation - 2004/04
#=================================================================#
. /etc/appltab

DIRWRK=${ENV_DIR_BASE_COR}/sched/corp
### DIRWRK=/acorp_sp/sched/corp

RCV=/transf/rcv 
TMP=$DIRWRK/corp_20_01_$$
FLAG=0
rc=0


cd $RCV 2>$TMP
if [ $? != 0 ]; then
   ( echo "Erro no cd $RCV" ; cat $TMP ) | msg_api2 "E-INTERFACES-PRECOS-RECEBIMENTO"
   rm -f $TMP
   exit 1
fi

for file in PP????????.??????
    do [ ! -f $file ] && continue
       FLAG=1
       mv $file $DIRWRK/$file 2>$TMP
       if [ $? != 0 ]; then
          ( echo "$file - Erro ao mover arquivo"
            cat $TMP ) | msg_api2 "E-INTERFACES-PRECOS-RECEBIMENTO"
          rm -f $TMP
          exit 1
       fi
       echo "$file - Arquivo de Precos recebido com sucesso" | msg_api2 "I-INTERFACES-PRECOS-RECEBIMENTO"
    done

if [ $FLAG = "1" ] ; then
   /amb/eventbin/BDC_20_02.sh > $TMP
   cat $TMP
fi

rm -f $TMP

exit 0
