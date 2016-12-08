#!/bin/ksh 
##  Programa: BSCS_ROAM_02_01.sh - Recebe os arquivos de Roaming Internacional
#
#   Data: 17/05/2000
#   Renato
#
## Mensagens
#M#I-BSCS_ROAM-020 : Arquivo recebido com sucesso
#M#E-BSCS_ROAM-020 : Erro no recebimento do arquivo
#

# Definicao de Variaveis


#DIRWRK=/aplic/apgp_sp/sched/bscs_roaming/files
DIRWRK=/apgp_sp/sched/bscs_roaming/files
##DIRWRK=/aplic/artx/prod/lausanne/tmp_tapout
RCV=/transf/rcv 
TMP=$DIRWRK/bscs_roam_$$.txt

cd $RCV 2>$TMP
if [ $? != 0 ]; then
   ( echo "Erro no cd $RCV" ; cat $TMP ) | msg_api "E-BSCS_ROAM-020"
   rm -f $TMP
   exit 1
fi

for file in ????DBRANC??????????
    do [ ! -f $file ] && continue
       sit_ori=`echo $file | cut -c 1-2`
       arq_new=`echo $file | cut -c 4-20`
       mv $file $DIRWRK/${sit_ori}/${arq_new} 2>$TMP
       if [ $? != 0 ]; then
          ( echo "$file - Erro ao mover arquivo"
            cat $TMP ) | msg_api "E-BSCS_ROAM-020"
          rm -f $TMP
          exit 1
       fi
       chmod 664 $DIRWRK/${sit_ori}/${arq_new}
       echo "$file -  Arquivo recebido com sucesso" | msg_api "I-BSCS_ROAM-020"
    done

rm -f $TMP

exit 0
