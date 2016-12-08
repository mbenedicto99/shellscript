#!/bin/ksh
# Script   : BDC_03_02.sh
# Descricao: Carga no Vantive de arquivo de Clientes gerado no Magnus
# Analista : Renato
# Data     : 16/06/99
#
## Mensagens
#M#I-BDC-CARGA-032 : Sucesso no loader de Clientes
#M#E-BDC-CARGA-032 : Erro no loader de Clientes
#M#W-BDC-CARGA-032 : Registros rejeitados no loader de Clientes
#M#I-BDC-CARGA-033 : Sucesso na Atualizacao de Clientes
#M#E-BDC-CARGA-033 : Erro no processamento de Clientes
#M#E-BDC-CARGA-034 : Erro de infra-estrutura
#

#=================================================================#
# Alteracao da consolidacao PCORP  - Edison /Workmation - 2004/04
#=================================================================#
. /etc/appltab

export TWO_TASK=${ENV_TNS_PDCOR}
export ORACLE_SID=${ENV_ORASID_PDCOR}
export ORACLE_HOME=${ENV_DIR_ORAHOME_COR}
export NLS_LANG=${ENV_NLSLANG_PDCOR}

# Definicao de Variaveis de Ambiente
## export ORACLE_SID=PCORP_SP
## export ORACLE_HOME=`grep ^${ORACLE_SID}: /etc/oratab | cut -d: -f2`

# Definicao de Area de trabalho, de scripts e temporaria
SIS="corp"   
ANO=`date +'%Y'`
MES=`date +'%m'`
DIA=`date +'%d'`
### WRK=/acorp_sp/sched/$SIS
WRK=${ENV_DIR_BASE_COR}/sched/$SIS

SCR=/amb/scripts/corp
PRO=$WRK/PROCESSED
ERR=$WRK/ERROR
LOG=$WRK/LOG
TMP=$WRK/TMP
TMP1=$TMP/BDC_03_02_1.$$
TMP2=$TMP/BDC_03_02_2.$$
TMP3=$TMP/BDC_03_02_3.$$
TMP4=$TMP/BDC_03_02_4.$$.txt
export TMP4

# Definicao de script oracle, arquivo e extensao
CTL=$SCR/cliente.ctl    
SQL=$SCR/imp_cli.sql       
NUMPROC=$$

## Verificacao de infra-estrutura
# Diretorio Home do oracle
if [ -z $ORACLE_HOME ] ; then
   echo "Nao encontrado home da instancia $ORACLE_SID" | msg_api2 "E-INTERFACES-CLIENTES-CARGA"
   echo "Nao encontrado home da instancia $ORACLE_SID" 
   exit 1
fi

# Area de trabalho
if [ ! -d $WRK ]; then
   ( echo "Nao encontrado $WRK" ) | msg_api2 "E-INTERFACES-CLIENTES-CARGA"
   echo "Nao encontrado $WRK" 
   exit 1
fi

# Area de trabalho
cd $WRK 2>$TMP1
if [ $? != 0 ] ; then 
   ( echo "Erro no cd $WRK"; cat $TMP1 ) | msg_api2 "E-INTERFACES-CLIENTES-CARGA"
   rm -f $TMP
   exit 1
fi

# Limpeza da area de trabalho
find $ERR -type f -mtime +1 -exec rm -f {} \;
find $LOG -type f -mtime +1 -exec rm -f {} \;
find $PRO -type f -mtime +1 -exec rm -f {} \;
find $TMP -type f -mtime +1 -exec rm -f {} \;

## Inicio do processo

# Execucao do loader

#for ARQ in CM${ANO}${MES}${DIA}.?????? 
for ARQ in CM${ANO}${MES}??.?????? 
do [ ! -f $ARQ ] && continue
       
   echo "$ARQ - Inicio da carga de Clientes - `date` " > $TMP2
   echo "$ARQ - Inicio da carga de Clientes - `date` " 

   $ORACLE_HOME/bin/sqlload / $CTL data=$ARQ bad=$ARQ.bad log=$ARQ.log >> $TMP2 2>&1 
   if [ $? != 0 ] ; then
      ( echo "$ARQ - Erro na execucao do loader de Clientes"
        cat $TMP2 $ARQ.log ) | msg_api2 "E-INTERFACES-CLIENTES-CARGA"
      echo "$ARQ - Erro na execucao do loader de Clientes"
      cat $TMP2 $ARQ.log 
      rm -f $TMP1 $TMP2
      mv $ARQ $ERR/$ARQ 
      mv $ARQ.log $LOG/$ARQ.log
      gzip -9 $ERR/$ARQ 
      gzip -9 $LOG/$ARQ.log
      exit 1
   fi 

   echo "$ARQ - Termino do loader de Clientes - `date`" >>$TMP2
   echo "$ARQ - Termino do loader de Clientes - `date`" 
   if grep ORA- $TMP2
   then
      ( echo "Erro na execucao da procedure"
        cat $TMP2 ) | msg_api2 "E-INTERFACES-CLIENTES-CARGA"
      echo "Erro na execucao da procedure"
      cat $TMP2
      rm -f $TMP1 $TMP2 $TMP3 $TMP4
      exit 1
   fi

   # Verifica arquivo de rejeicoes
   if [ -a $ARQ.bad ] ; then
      ( echo "$ARQ - Registros rejeitados no loader de Clientes"
         cat $TMP2 $ARQ.log $ARQ.bad ) | msg_api2 "W-INTERFACES-CLIENTES-CARGA"
      echo "$ARQ - Registros rejeitados no loader de Clientes"
      cat $TMP2 $ARQ.log $ARQ.bad 
      mv $ARQ.bad $ERR/$ARQ.bad
      gzip -9 $ERR/$ARQ.bad
   fi

   # Move arquivo p/ diretorio de processados
   mv $ARQ $PRO/$ARQ 2>$TMP1
   if [ $? != 0 ] ; then
      ( echo "$ARQ - Erro movendo $ARQ para $PRO/$ARQ"
        cat $TMP1 $TMP2 ) | msg_api2 "E-INTERFACES-CLIENTES-CARGA"
      echo "$ARQ - Erro movendo $ARQ para $PRO/$ARQ"
      cat $TMP1 $TMP2 
      rm -f $TMP1 $TMP2
   fi
   gzip -9 $PRO/$ARQ 

   # Procedure de distribuicao de dados
cat << EOF > $TMP3
set serveroutput on
set feedback off
spool $TMP4
begin
cli_mag_bdc.pr_cli_mag_bdc($NUMPROC);
end;
/
spool off
exit
EOF

   echo "$ARQ - Inicio da distribuicao de Clientes `date` " >> $TMP2
   echo "$ARQ - Inicio da distribuicao de Clientes `date` "

   #$ORACLE_HOME/bin/sqlplus / @$TMP3 > $TMP1 2>&1 
   $ORACLE_HOME/bin/sqlplus corp/sysadm@${TWO_TASK} @$TMP3 > $TMP1 2>&1 

   rc=$?

   echo "$ARQ - Termino da distribuicao de Clientes`date` " >> $TMP2
   echo "$ARQ - Termino da distribuicao de Clientes`date` "

   if [ $rc != 0 ] ; then
      ( echo "$ARQ - Erro na Atualizacao de Clientes "
        cat $TMP2 $TMP1 ) | msg_api2 "E-INTERFACES-CLIENTES-CARGA"
      echo "$ARQ - Erro na Atualizacao de Clientes "
      cat $TMP2 $TMP1 
        rm -f $TMP1 $TMP2
      mv $ARQ.log $LOG/$ARQ.log
      gzip -9     $LOG/$ARQ.log
      exit 1
   fi

   grep -q "ORA-20000" $TMP1
   if [ $? = 0 ] ; then
      ( echo "$ARQ - Erro na execucao da procedure "
        cat $TMP1 $TMP2 ) | msg_api2 "E-INTERFACES-CLIENTES-CARGA"
      echo "$ARQ - Erro na execucao da procedure "
      cat $TMP1 $TMP2 
        rm -f $TMP1 $TMP2
      rm $ARQ.log $LOG/$ARQ.log  
      gzip -9 $LOG/$ARQ.log
      exit 1
   fi

   grep "Total logical records read:" $ARQ.log >> $TMP2
   grep "Total logical records rejected:" $ARQ.log >> $TMP2

   ( echo "$ARQ - Sucesso na Atualizacao de Clientes "
      cat $TMP4 $TMP2 ) | msg_api2 "I-INTERFACES-CLIENTES-CARGA"
   echo "$ARQ - Sucesso na Atualizacao de Clientes "
   cat $TMP4 $TMP2 

   mv $ARQ.log $LOG/$ARQ.log
   gzip -9     $LOG/$ARQ.log
   
done

#
# Cleaning

rm -f $TMP1 $TMP2 $TMP3 $TMP4

exit 0
