#!/bin/ksh
#
# Script   : BDC_20_02
# Descricao: Carga de arquivo de Precos
# Analista : Kilson
# Data     : 09/06/99
#
## Mensagens
#M#E-INTERFACES-PRECOS-CARGA : Erro na carga do arquivo Precos
#M#W-INTERFACES-PRECOS-CARGA : Registros rejeitados na carga do arq. de Precos
#M#I-INTERFACES-PRECOS-CARGA : Sucesso na atualizacao do arquivo de Precos
#M#E-INTERFACES-PRECOS-CARGA : Erro na atualizacao do arquivo de de Precos
#M#E-INTERFACES-PRECOS-CARGA : Erro de infra-estrutura
#

# Definicao de Variaveis de Ambiente
#=================================================================#
# Alteracao da consolidacao PCORP  - Edison /Workmation - 2004/04
#=================================================================#
. /etc/appltab

export TWO_TASK=${ENV_TNS_PDCOR}
export ORACLE_SID=${ENV_ORASID_PDCOR}
export ORACLE_HOME=${ENV_DIR_ORAHOME_COR}
export NLS_LANG=${ENV_NLSLANG_PDCOR}

## export ORACLE_SID=PCORP_SP
## export ORACLE_HOME=`grep ^${ORACLE_SID}: /etc/oratab | cut -d: -f2`

# Definicao de Area de trabalho, de scripts e temporaria
WRK=${ENV_DIR_BASE_COR}/sched/corp
## WRK=/acorp_sp/sched/corp

SCR=/amb/scripts/corp
PRO=$WRK/PROCESSED
ERR=$WRK/ERROR
LOG=$WRK/LOG
TMP=$WRK/TMP
TMP1=$TMP/BDC_20_02_1.$$
TMP2=$TMP/BDC_20_02_2.$$
TMP3=$TMP/BDC_20_02_3.$$
TMP4=$TMP/BDC_20_02_4.$$
NUMPROC=$$

# Definicao de script oracle, arquivo e extensao
CTL=$SCR/preco.ctl
SQL=$SCR/

## Verificacao de infra-estrutura
# Diretorio Home do oracle
if [ -z $ORACLE_HOME ] ; then
   echo "Nao encontrado home da instancia $ORACLE_SID" | msg_api2 "E-INTERFACES-PRECOS-CARGA"
   exit 1
fi

# Area de trabalho
if [ ! -d $WRK ]; then
   ( echo "Nao encontrado $WRK" ) | msg_api2 "E-INTERFACES-PRECOS-CARGA"
   exit 1
fi

# Area de trabalho
cd $WRK 2>$TMP1
if [ $? != 0 ] ; then 
   ( echo "Erro no cd $WRK"; cat $TMP1 ) | msg_api2 "E-INTERFACES-PRECOS-CARGA"
   rm -f $TMP1
   exit 1
fi

# Limpeza da area de trabalho
find $ERR -type f -mtime +5 -exec rm -f {} \;
find $LOG -type f -mtime +5 -exec rm -f {} \;
find $PRO -type f -mtime +5 -exec rm -f {} \;
find $TMP -type f -mtime +5 -exec rm -f {} \;

## Inicio do processo

# Execucao do loader

for ARQ in PP????????.??????
do [ ! -f $ARQ ] && continue
       
   echo "$ARQ - Inicio da carga de Precos - `date` " > $TMP2

   $ORACLE_HOME/bin/sqlload / $CTL data=$ARQ bad=$ARQ.bad log=$ARQ.log >> $TMP2 2>&1 
   if [ $? != 0 ] ; then
      ( echo "$ARQ - Erro na carga do arquivo de Precos"
        cat $TMP2 $ARQ.log) | msg_api2 "E-INTERFACES-PRECOS-CARGA"
      rm -f $TMP1 $TMP2
      mv $ARQ $ERR/$ARQ 
      gzip -9 $ERR/$ARQ 
      mv $ARQ.log $LOG/$ARQ.log
      gzip -9     $LOG/$ARQ.log
      exit 1
   fi 

   echo "$ARQ - Termino da carga do arquivo de Precos - `date`" >>$TMP2

   # Verifica arquivo de rejeicoes
   if [ -a $ARQ.bad ] ; then
      ( echo "$ARQ - Registros rejeitados na carga de Precos"
         cat $TMP2 $ARQ.log $ARQ.bad ) | msg_api2 "W-INTERFACES-PRECOS-CARGA"
      mv $ARQ.bad $ERR/$ARQ.bad
      gzip -9     $ERR/$ARQ.bad
   fi

   # Move arquivo p/ diretorio de processados
   mv $ARQ $PRO/$ARQ 2>$TMP1
   if [ $? != 0 ] ; then
      ( echo "$ARQ - Erro movendo $ARQ para $PRO/$ARQ"
        cat $TMP1 $TMP2 ) | msg_api2 "E-INTERFACES-PRECOS-CARGA"
      rm -f $TMP1 $TMP2
   fi
   gzip -9 $PRO/$ARQ 

   # Procedure de distribuicao de dados
cat << EOF > $TMP3
set serveroutput on
spool $TMP4
begin
corp.pk_pre_mag_bdc.pr_pre_mag_bdc_01($NUMPROC);
end;
/
spool off
set serveroutput off
exit
EOF

   echo "$ARQ - Inicio da atualizacao de Precos `date` " >> $TMP2

   $ORACLE_HOME/bin/sqlplus / @$TMP3 > $TMP1 2>&1 

   rc=$?

   echo "$ARQ - Termino da atualizacao de Precos `date` " >> $TMP2

   if [ $rc != 0 ] ; then
      ( echo "$ARQ - Erro na atualizacao da Precos"
        cat $TMP2 $TMP1 ) | msg_api2 "E-INTERFACES-PRECOS-CARGA"
        rm -f $TMP1 $TMP2
      mv $ARQ.log $LOG/$ARQ.log
      gzip -9     $LOG/$ARQ.log
      exit 1
   fi

   grep -q "ERRO" $TMP1
   if [ $? = 0 ] ; then
      ( echo "$ARQ - Erro na execucao da procedure $SQL"
        cat $TMP1 $TMP2 ) | msg_api2 "E-INTERFACES-PRECOS-CARGA"
        rm -f $TMP1 $TMP2
      rm $ARQ.log $LOG/$ARQ.log
      gzip -9 $LOG/$ARQ.log
      exit 1
   fi

   grep "Total logical records read:" $ARQ.log >> $TMP2
   grep "Total logical records rejected:" $ARQ.log >> $TMP2

   ( echo "$ARQ - Sucesso na atualizacao de Precos"
      cat $TMP2 $TMP4 ) | msg_api2 "I-INTERFACES-PRECOS-CARGA"

   mv $ARQ.log $LOG/$ARQ.log
   gzip -9     $LOG/$ARQ.log
   
done

#
# Cleaning

/amb/bin/gzip -9 $PRO/$ARQ 

rm -f $TMP1 $TMP2 $TMP3 $TMP4

exit 0
