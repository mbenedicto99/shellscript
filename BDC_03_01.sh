#!/bin/ksh 
##  Scripts   : BDC_03_01.sh 
#   Descricao : Recebe arquivo de Clientes do Magnus para carga no Vantive
#   Data      : 16/06/99
#   Autor     : Renato
#
## Mensagens
#M#I-BDC-RECEBE-030 : Arquivo de Clientes recebido com sucesso
#M#E-BDC-RECEBE-030 : Erro no recebimento do arquivo de Clientes
#M#E-BDC-RECEBE-031 : Erro de infra-estrutura
#

# Definicao de Variaveis

#=================================================================#
# Alteracao da consolidacao PCORP  - Edison /Workmation - 2004/04
#=================================================================#
. /etc/appltab

DIRWRK=${ENV_DIR_BASE_COR}/sched/corp
### DIRWRK=/acorp_sp/sched/corp

RCV=/transf/rcv 
TMP=$DIRWRK/corp_03_01_$$.txt
FLAG=0
DEST_MAIL=interface_MagnusXVantive@unix_mail_fwd
rc=0


cd $RCV 2>$TMP
if [ $? != 0 ]; then
   ( echo "Erro no cd $RCV" ; cat $TMP ) | msg_api2 "E-INTERFACES-CLIENTES-RECEBIMENTO"
   rm -f $TMP
   exit 1
fi

for file in CM????????.??????
    do [ ! -f $file ] && continue
       FLAG=1
       mv $file $DIRWRK/$file 2>$TMP
       if [ $? != 0 ]; then
          ( echo "$file - Erro ao mover arquivo"
            cat $TMP ) | msg_api2 "E-INTERFACES-CLIENTES-RECEBIMENTO"
          rm -f $TMP
          exit 1
       fi
       echo "$file - Arquivo de Clientes recebido com sucesso" | msg_api2 "I-INTERFACES-CLIENTES-RECEBIMENTO"
    done

if [ $FLAG = "1" ] ; then
   /amb/eventbin/BDC_03_02.sh > $TMP
   if [ $? = "0" ] ; then
     rm -f $TMP
     exit 0
   fi
   echo "erro na carga do arquivo"
   cat $TMP
   SUB="Erro na interface de clientes Magnus X Vantive"
   /amb/operator/bin/attach_mail $DEST_MAIL $TMP $SUB
   rm -f $TMP
   exit 1
fi
rm -f $TMP
exit 0
