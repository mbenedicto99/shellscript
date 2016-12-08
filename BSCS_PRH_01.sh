#!/bin/ksh
#
# Alteracao 13/06/2002
# Alex da Rocha Lima
#

. /etc/appltab

TMP=/tmp/BSCS_PRH$$.tmp
TMP1=/tmp/BSCS_PRH1$$.tmp
LOG_TMP=$TMP.log
TMP2=/tmp/BSCS_PRH2$$.tmp
MSG=I-BSCS-PRH-001
typeset -L2 SITE
#SITE=`uname -n`

#cd /artx_$SITE/prod/WORK/LOG
cd ${ENV_DIR_BASE_RTX}/prod/WORK/LOG
[ $? != 0 ] && exit 1

# Procura arquivos nao marcados com bit de execucao para other
find . ! -perm -1 -name "PRH*.LOG" -print |\
while read file
   do 
      [ ! -s $file ] && continue
      # Marca arquivo com bit de execucao para other
      chmod o+x $file
      ( echo "$file"
        echo 
        echo "BSCS PREPAY RECORD HANDLER - \c"
        echo "                                    "`ll $file | cut -c 46-57` 
        echo "------------------------------------------------"
        echo
        cat -s $file )  | msg_api2 "$MSG"
        cat -s $file 
        gzip -9 $file
        echo $file >>$LOG_TMP
   done

[ -f $LOG_TMP ] && cat $LOG_TMP

[ -f $TMP ] && rm $TMP
[ -f $TMP1 ] && rm $TMP1
[ -f $TMP2 ] && rm $TMP2
exit 0
