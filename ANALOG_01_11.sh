#!/bin/ksh
## ANALOG_01_11.sh - Carga dos arquivos do LOGs do FIH
#
# Data: 15/12/99
# Renato 
#
## Mensagens
#M#I-ANALOG-110 : Sucesso na carga do arquivo FIH
#M#E-ANALOG-110 : Erro na execucao da procedure
#M#E-ANALOG-111 : Erro de infra-estrutura


DIRWRK=/ageral_sp/analog/FIH
export ORACLE_SID=PNXTL01
export ORACLE_HOME=`grep ^${ORACLE_SID}: /etc/oratab | cut -d: -f2`

# Variaveis de trabalho
TMP=/tmp/analog_$$.txt
TMP1=/tmp/analog_1_$$.txt

# Caso nao exista o filesystem sai com erro de infraestutura
cd $DIRWRK 2>$TMP
if [ $? != 0 ] ; then 
   ( echo "Erro no cd $DIRWRK"; cat $TMP ) | msg_api "E-ANALOG-111"
   rm -f $TMP
   exit 1
fi

# Limpa diretorios de trabalho
find $DIRWRK/PROCESSADOS -type f -ctime +30 -exec rm -f {} \;
find $DIRWRK/REJEITADOS -type f -ctime +30 -exec rm -f {} \;

for DIR in SP RJ
    do [ ! -d $DIRWRK/$DIR ] && continue
      cd $DIR 2>$TMP
      if [ $? != 0 ] ; then
         ( echo "Erro no cd $DIR"; cat $TMP ) | msg_api "E-ANALOG-111"
         rm -f $TMP
         exit 1
      fi
      if [ $DIR = "SP" ] ; then
         SITE=1
         else SITE=2
      fi
      for FILE in ${DIR}FIH*.txt
      do
      [ ! -f $FILE ] && continue
cat << EOF > $TMP1
whenever sqlerror exit failure
whenever oserror exit failure
set echo off
begin
PR_LOG_RATING_FIH('${SITE}','${DIRWRK}/${DIR}','${FILE}');
end;
/
exit
EOF

       $ORACLE_HOME/bin/sqlplus / @$TMP1 > $TMP 
       RC=$?
       if [ $RC != 0 ] ; then
          ( echo "`basename $FILE` - Erro na execucao da procedure"
            cat $TMP ) | msg_api "E-ANALOG-110"
          mv $FILE ../REJEITADOS
          rm -f $TMP $TMP1
          exit 1
       fi 
       ( echo "`basename $FILE` - Sucesso na carga do arquivo FIH"
         cat $TMP ) | msg_api "I-ANALOG-110"

       # Move arquivo p/ diretorio de processados
       mv $FILE $DIRWRK/PROCESSADOS 2>$TMP
       if [ $? != 0 ] ; then
          ( echo "`basename $FILE` - Erro no mv do $FILE"
            cat $TMP ) | msg_api "E-ANALOG-111"
          rm -f $TMP $TMP1
          exit 1
       fi
       /amb/bin/gzip -f $DIRWRK/PROCESSADOS/$FILE
   done
   cd $DIRWRK 2>$TMP
done
#
# Cleaning


rm -f $TMP1 $TMP 
exit 0
