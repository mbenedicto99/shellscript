#!/bin/ksh 
#   Programa: ANALOG_01_01.sh
#   Recebe arquivo de log do FIH
#   Data: 10/08/2000
#
## Mensagens
#M#I-ANALOG-010 : Sucesso no recebimento de arquivo de log
#M#E-ANALOG-010 : Erro no recebimento do arquivo de log
#M#E-ANALOG-011 : Erro de infra-estrutura
#

# Definicao de Variaveis
RCV=/transf/rcv 
WORK=/ageral_sp/analog/FIH
TMP=/tmp/analog_$$.txt


cd $RCV 2>$TMP
if [ $? != 0 ]; then
   ( echo "Erro no cd $RCV" ; cat $TMP ) | msg_api "E-ANALOG-011"
       rm -f $TMP
     exit 1
fi

for file in ??FIH??????????????.txt 
    do [ ! -f $file ] && continue
       SITE=`echo $file | cut -c 1-2`
       mv $file $WORK/${SITE}/${file} 2>$TMP
       if [ $? != 0 ]; then
          ( echo $file "- Erro no recebimento do arquivo" 
            cat $TMP ) | msg_api "E-ANALOG-011"
          rm -f $TMP
          exit 1
       fi
       ( echo "$SITE - $file - Arquivo recebido com sucesso" 
             cat $WORK/${SITE}/${file} ) | msg_api "I-ANALOG-010"
    done

rm -f $TMP 

exit 0
