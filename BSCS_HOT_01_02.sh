#!/bin/ksh
#
# Atualiza arquivo de Hotbilling para serem processados pelo rating
# analista: Alessandra
#
## Mensagens
#M#I-BSCS_HOT-001: (Sucesso) Atualiza hotbilling
#M#E-BSCS_HOT-001: (Erro) Atualiza hotbilling
#

#
# Atribuicao de variaveis
#

. /etc/appltab

typeset -l -L2 SITE

#SITE=$1
SITE="${ENV_VAR_SITE}"

TMP=/tmp/hot_$$
#DIR_WORK=/artx_${SITE}/prod/backup_rating/hotbilling
DIR_WORK=${ENV_DIR_BASE_RTX}/prod/backup_rating/hotbilling
DIR_PROC=${DIR_WORK}/processados
DAT=`date`

#MAQ=$1
#case "$MAQ" in
#  sp*) DIR_RATING=/artx_sp/prod/WORK/MP/NORTEL/IN/AIRLI
#       DIR_BIN=/artx_sp/prod/batch/bin
#         ;;
#  rj*) DIR_RATING=/artx_rj/prod/WORK/MP/NORTEL/IN/NT_RJ
#       DIR_BIN=/artx_rj/prod/batch/bin
#         ;;
#     *) echo "site invalido"
#        exit 1 ;;
#esac

DIR_RATING="${ENV_DIR_NORTEL_RTX}"
DIR_BIN=${ENV_DIR_BASE_RTX}/prod/batch/bin

cd $DIR_RATING > $TMP 2>&1

for FILE in TH????????????????
do [ ! -f $FILE ]  && continue
   chown prod:bscs $FILE
   file=$FILE.old
   cp $FILE $file
   chown prod:bscs $file
   ${DIR_BIN}/hotbill_filter ${DIR_RATING}/${file} ${DIR_RATING}/${FILE} > $TMP
   if [ $? != "0" ] ; then
     ( echo "$FILE - erro na execucao do hotbill_filter" ;
       cat $TMP ) | msg_api "E-BSCS_HOT-001"
       cat $TMP 
     rm -f $TMP
     echo "Erro na execucao do hotbill filter" > /dev/tty
     exit 1
   fi
   ( echo "$FILE - Sucesso na execucao do hotbill_filter " ;
     cat $TMP ) | msg_api "I-BSCS_HOT-001"
     cat $TMP 
   echo "Sucesso na execucao do hotbill filter - $FILE"
   rm -f $file
done

rm -f $TMP

exit 0
