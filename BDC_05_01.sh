#!/bin/ksh 
##  Scripts   : BDC_05_01.sh 
#   Descricao : Recebe arquivo de Representantes do Magnus para carga no Vantive
#   Data      : 17/06/99
#   Autor     : Renato
#
## Mensagens
#M#I-INTERFACES-REPRESENTANTES-RECEBIMENTO : Arquivo de Representantes recebido com sucesso
#M#E-INTERFACES-REPRESENTANTES-RECEBIMENTO : Erro no recebimento do arquivo de Representantes
#M#E-INTERFACES-REPRESENTANTES-RECEBIMENTO : Erro de infra-estrutura
#

# Definicao de Variaveis

#=================================================================#
# Alteracao da consolidacao PCORP  - Edison /Workmation - 2004/04
#=================================================================#
. /etc/appltab

DIRWRK=${ENV_DIR_BASE_COR}/sched/corp
### DIRWRK=/acorp_sp/sched/corp

RCV=/transf/rcv 
TMP=$DIRWRK/corp_05_01_$$
FLAG=O
rc=0


cd $RCV 2>$TMP
if [ $? != 0 ]; then
   ( echo "Erro no cd $RCV" ; cat $TMP ) | msg_api2 "E-INTERFACES-REPRESENTANTES-RECEBIMENTO"
   rm -f $TMP
   exit 1
fi

for file in RM????????.??????
    do [ ! -f $file ] && continue
       FLAG=1
       mv $file $DIRWRK/$file 2>$TMP
       if [ $? != 0 ]; then
          ( echo "$file - Erro ao mover arquivo"
            cat $TMP ) | msg_api2 "E-INTERFACES-REPRESENTANTES-RECEBIMENTO"
          rm -f $TMP
          exit 1
       fi
       chmod 755 $DIRWRK/$file
       echo "$file - Arquivo de Representantes recebido com sucesso" | msg_api2 "I-INTERFACES-REPRESENTANTES-RECEBIMENTO"
    done

if [ $FLAG = "1" ] ; then
   /amb/eventbin/BDC_05_02.sh > $TMP
   cat $TMP
fi

rm -f $TMP

exit 0
