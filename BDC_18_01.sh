#!/bin/ksh 
##  Programa: BDC_18_01.sh Recebe arquivo de Tabela de precos para carga no Vantive
#
#   Data: 09/06/99
#   Renato
#
## Mensagens
#M#I-INTERFACES-TABELA_PRECOS : Arquivo de Tabela de Precos recebido com sucesso
#M#E-INTERFACES-TABELA_PRECOS : Erro no recebimento do arq de Tabela de Precos
#M#E-INTERFACES-TABELA_PRECOS : Erro de infra-estrutura
#

# Definicao de Variaveis

#=================================================================#
# Alteracao da consolidacao PCORP  - Edison /Workmation - 2004/04
#=================================================================#
. /etc/appltab

DIRWRK=${ENV_DIR_BASE_COR}/sched/corp
## DIRWRK=/acorp_sp/sched/corp

RCV=/transf/rcv 
TMP=$DIRWRK/corp_18_01_$$
FLAG=0
rc=0


cd $RCV 2>$TMP
if [ $? != 0 ]; then
   ( echo "Erro no cd $RCV" ; cat $TMP ) | msg_api2 "E-INTERFACES-TABELA_PRECOS-RECEBIMENTO"
   rm -f $TMP
   exit 1
fi

for file in TP????????.??????
    do [ ! -f $file ] && continue
       FLAG=1
       mv $file $DIRWRK/$file 2>$TMP
       if [ $? != 0 ]; then
          ( echo "$file - Erro ao mover arquivo"
            cat $TMP ) | msg_api2 "E-INTERFACES-TABELA_PRECOS-RECEBIMENTO"
          rm -f $TMP
          exit 1
       fi
       echo "$file - Arquivo de Tabela de Precos recebido com sucesso" | msg_api2 "I-INTERFACES-TABELA_PRECOS-RECEBIMENTO"
    done

if [ $FLAG = "1" ] ; then
   /amb/eventbin/BDC_18_02.sh > $TMP
   cat $TMP
fi

rm -f $TMP

exit  0
