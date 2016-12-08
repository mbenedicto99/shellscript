#!/bin/ksh 
#   Programa: BDC_11_01.sh
#   Recebe arquivo de solicitacao de inclusao de clientes para o magnus 
#   Data: 19/01/99
#   Data: 12/03/99 - Alterado mascara do arquivo e local de recebimento
#
## Mensagens
#M#I-BDC-RECEBE-111 : Sucesso no recebimento de arquivo de clientes para o Magnus
#M#E-BDC-RECEBE-111 : Erro no recebimento do arquivo de clientes para o magnus
#M#E-BDC-RECEBE-112 : Erro de infra-estrutura
#

# Definicao de Variaveis
RCV=/transf/rcv 
WORK=/apgs_sp/sched/bdc
TMP=$WORK/bdc_11_01_$$
FLAG=0
rc=0


cd $RCV 2>$TMP
if [ $? != 0 ]; then
   ( echo "Erro no cd $RCV" ; cat $TMP ) | msg_api2 "E-INTERFACES-CLIENTES-RECEBIMENTO"
       rm -f $TMP
     exit 1
fi

for file in CV????????.?????? 
    do [ ! -f $file ] && continue
       FLAG=1
       mv $file $WORK/$file 2>$TMP
       if [ $? != 0 ]; then
          ( echo $file "- Erro no recebimento do arquivo" 
            cat $TMP ) | msg_api2 "E-INTERFACES-CLIENTES-RECEBIMENTO"
          rm -f $TMP
          exit 1
       fi
       echo $file "- Arquivo recebido com sucesso" | msg_api2 "I-INTERFACES-CLIENTES-RECEBIMENTO"
    done

if [ $FLAG = "1" ] ; then
   /amb/eventbin/BDC_11_02.sh > $TMP
   cat $TMP
   rc=$?
fi

rm -f $TMP

exit $rc
