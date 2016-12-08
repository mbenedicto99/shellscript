#!/bin/ksh 
### BSCS_FIH_03.sh
#
# Alteracao 06/03/02
#
#M#I-BSCS-FIH-301 : Sucesso no recebimento de arquivo de Roaming
#M#E-BSCS-FIH-301 : Erro    no recebimento de arquivo de Roaming
#M#E-BSCS-FIH-300 : Erro de infra-estrutura
#

. /etc/appltab

TMP=/tmp/bscs_fih.$$

#UNAME=$1

typeset -u -L3 SITE

#SITE="$UNAME"

SITE="${ENV_VAR_CITY}"

## case "$SITE" in
##     SPO) DIR_NORTEL="/artx_sp/prod/WORK/MP/NORTEL/IN/AIRLI/"
##          DIR_DAP="/artx_sp/prod/WORK/MP/DAP/IN/AIRLI/"
##          ;;
##     RJO) DIR_NORTEL="/artx_rj/prod/WORK/MP/NORTEL/IN/NT_RJ/"
##          DIR_DAP="/artx_rj/prod/WORK/MP/DAP/IN/NT_RJ/"
##          ;;
##       *) echo "$0: Site desconhecido $SITE ($UNAME)" | msg_api2 "E-RATING-ROAMING-RECEBIMENTO"
##          exit 1
##          ;;
## esac

DIR_NORTEL="${ENV_DIR_NORTEL_RTX}"
DIR_DAP="${ENV_DIR_DAP_RTX}"

if [ -z "$DIR_DAP" ]
   then echo "$0: DIR_DAP não definido" | msg_api2 "E-RATING-ROAMING-RECEBIMENTO"
        exit 1
fi
 
cd /transf/rcv 2>$TMP
if [ $? != 0 ]
   then ( echo "$0: erro no cd /transf/rcv"
          cat $TMP )  | msg_api2 "E-RATING-ROAMING-RECEBIMENTO"
          cat $TMP 
        exit 1
fi

rc=0

# Recebe arquivos de Roaming DAP e NORTEL
for FILE in CU???????????????? DAP???????????????.?.?
    do [ ! -f $FILE ] && continue
       case "$FILE" in
         CU*) mv $FILE ${DIR_NORTEL}/$FILE 2>$TMP
              rc=$?
              chown prod:bscs ${DIR_NORTEL}/$FILE
              chmod 666  ${DIR_NORTEL}/$FILE 
              echo "$FILE `cksum ${DIR_NORTEL}/$FILE` $FILE" | msg_api2 "I-RATING-ROAMING-RECEBIMENTO" ;;
         DA*) mv $FILE ${DIR_DAP}/$FILE 2>$TMP
              rc=$?
              chown prod:bscs ${DIR_DAP}/$FILE
              chmod 666  ${DIR_DAP}/$FILE 
              echo "$FILE `cksum ${DIR_DAP}/$FILE` $FILE" | msg_api2 "I-RATING-ROAMING-RECEBIMENTO" ;;
       esac

       if [ $rc != 0 ]
          then ( echo "$0: $FILE erro no recebimento do arquivo"
                 cat $TMP )  | msg_api2 "E-RATING-ROAMING-RECEBIMENTO"
                 cat $TMP 
          rm -f $TMP
          continue
       fi
    done

rm -f $TMP
exit $rc
