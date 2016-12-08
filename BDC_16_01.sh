#!/bin/ksh 
##  Programa: BDC_16_01.sh Recebe arquivo de Produtos e Servicos para carga no Vantive
#
#   Data: 28/05/99
#   Renato
#
## Mensagens
#M#I-INTERFACES-PRODUTOS-RECEBIMENTO : Arquivo de Produtos recebido com sucesso
#M#E-INTERFACES-PRODUTOS-RECEBIMENTO : Erro no recebimento do arquivo de Produto
#M#E-INTERFACES-PRODUTOS-RECEBIMENTO : Erro de infra-estrutura
#

# Definicao de Variaveis

#=================================================================#
# Alteracao da consolidacao PCORP  - Edison /Workmation - 2004/04
#=================================================================#
. /etc/appltab

DIRWRK=${ENV_DIR_BASE_COR}/sched/corp
### DIRWRK=/acorp_sp/sched/corp

RCV=/transf/rcv 
TMP=$DIRWRK/corp_16_01_$$
FLAG=0
rc=0


cd $RCV 2>$TMP
if [ $? != 0 ]; then
   ( echo "Erro no cd $RCV" ; cat $TMP ) | msg_api2 "E-INTERFACES-PRODUTOS-RECEBIMENTO"
   rm -f $TMP
   exit 1
fi

for file in PS????????.??????
    do [ ! -f $file ] && continue
       FLAG=1
       mv $file $DIRWRK/$file 2>$TMP
       if [ $? != 0 ]; then
          ( echo "$file - Erro ao mover arquivo"
            cat $TMP ) | msg_api2 "E-INTERFACES-PRODUTOS-RECEBIMENTO"
          rm -f $TMP
          exit 1
       fi
       chmod 755 $DIRWRK/$file
       echo "$file - Arquivo de Produtos e Servicos recebido com sucesso" | msg_api2 "I-INTERFACES-PRODUTOS-RECEBIMENTO"
    done

if [ $FLAG = "1" ] ; then
   /amb/eventbin/BDC_16_02.sh > $TMP
   cat $TMP
fi

rm -f $TMP

exit 0
