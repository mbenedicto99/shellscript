#!/bin/ksh
# 
# Ateracao 22/06/2002
#
# Alex da Rocha Lima
#


TMP=/tmp/BSCS_TEH$$.tmp
TMP1=/tmp/BSCS_TEH1$$.tmp
TMP2=/tmp/BSCS_TEH2$$.tmp
RC=0

cd ~prod/WORK/TMP
[ $? != 0 ] && exit 1

# Procura arquivos nao marcados com bit de execucao para other
find . ! -perm -1 -name "TEH*" -print |\
while read file
   do case "$file" in
         *.PRT) MSG=I-RATING-TEH-PROTOCOLO
                FILETYPE="PROTOCOL" ;;
         *.ERR) MSG=E-RATING-TEH-ERRO
                FILETYPE="ERROR" ;;
             *) MSG=W-RATING-TEH-UNKNOWN
                FILETYPE="UNKNOWN" ;;
      esac
      # CHANGE 6549
      #[ ! -s $file ] && continue
      # Marca arquivo com bit de execucao para other
      chmod o+x $file
      ( echo "$file"
        echo 
        echo "BSCS TABLE EXPORT HANDLER - \c"
        echo $FILETYPE" FILE"
        echo "                                    "`ll $file | cut -c 46-57` 
        echo "------------------------------------------------"
        echo
        cat -s $file )  | msg_api2 "$MSG"
        [ $FILETYPE = "ERROR" ] && cat $file
        gzip -9 $file
        [ $FILETYPE = "ERROR" ] && RC=1
   done

[ -f $TMP ] && rm $TMP
[ -f $TMP1 ] && rm $TMP1
[ -f $TMP2 ] && rm $TMP2
if [ "${RC}" -ne 0 ]
then
    mailx -s "*** URGENTE *** ERRO NO TEH" "prodmsol@nextel.com.br,analise_producao@nextel.com.br,billing_process@nextel.com.br" <<EOF
ATENCAO!!!!!

  Verificar URGENTE o ERRO no TEH.

Atte.,
Control-M
EOF
fi
exit $RC
