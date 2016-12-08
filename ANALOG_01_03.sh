#!/bin/ksh 
#   Programa: ANALOG_01_03.sh
#   Recebe arquivo de log do RLH
#   Data: 10/08/2000
#
## Mensagens
#M#I-ANALOG-030 : Sucesso no recebimento de arquivo de log
#M#E-ANALOG-030 : Erro no recebimento do arquivo de log
#M#E-ANALOG-031 : Erro de infra-estrutura
#

# Definicao de Variaveis
RCV=/transf/rcv 
WORK=/ageral_sp/analog/RLH
TMP=/tmp/analog_$$.txt


cd $RCV 2>$TMP
if [ $? != 0 ]; then
   ( echo "Erro no cd $RCV" ; cat $TMP ) | msg_api "E-ANALOG-031"
       rm -f $TMP
     exit 1
fi

for file in ??RLH??????????????.txt 
    do [ ! -f $file ] && continue
       SITE=`echo $file | cut -c 1-2`
       mv $file $WORK/${SITE}/${file} 2>$TMP
       if [ $? != 0 ]; then
          ( echo $file "- Erro no recebimento do arquivo" 
            cat $TMP ) | msg_api "E-ANALOG-031"
          rm -f $TMP
          exit 1
       fi
       ( echo "$SITE - $file - Arquivo recebido com sucesso" 
             cat $WORK/${SITE}/${file} ) | msg_api "I-ANALOG-030"
    done

rm -f $TMP 

exit 0
