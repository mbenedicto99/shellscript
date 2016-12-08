#!/bin/ksh
#
# Alteracao 14/06/2002
# Alex da Rocha Lima
#

TMP=/tmp/BSCS_DEH$$.tmp
TMP1=/tmp/BSCS_DEH1$$.tmp
TMP2=/tmp/BSCS_DEH2$$.tmp

cd ~prod/WORK/TMP
[ $? != 0 ] && exit 1

# Procura arquivos nao marcados com bit de execucao para other
find . ! -perm -1 -name "DEH*" -print |\
while read file
   do case "$file" in
         *.PRT) MSG=I-RATING-DEH-PROTOCOLO
                FILETYPE="PROTOCOL" ;;
         *.ERR) MSG=E-RATING-DEH-ERRO
                FILETYPE="ERROR" ;;
         *.CTR) MSG=I-RATING-DEH-CONTROLE
                FILETYPE="CONTROL" ;;
             *) MSG=W-RATING-DEH-PROCESSAMENTO
                FILETYPE="UNKNOWN" ;;
      esac
      [ ! -s $file ] && continue
      # Marca arquivo com bit de execucao para other
      chmod o+x $file
      ( echo "$file"
        echo 
        echo "BSCS DATA EXCHANGE HANDLER - \c"
        echo $FILETYPE" FILE"
        echo "                                    "`ll $file | cut -c 46-57` 
        echo "------------------------------------------------"
        echo
        cat -s $file )  | msg_api2 "$MSG"
        cat -s $file
        gzip -9 $file
   done

[ -f $TMP ] && rm $TMP
[ -f $TMP1 ] && rm $TMP1
[ -f $TMP2 ] && rm $TMP2
exit 0
