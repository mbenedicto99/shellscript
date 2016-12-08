#!/bin/ksh 
#   Programa: BDC_22_01.sh
#   Atualizacao da Extranet com dados da Base Corporativa
#   Data: 14/10/99
#
## Mensagens
#M#I-BDC-ATUALIZACAO-220 : Sucesso na atualizacao da Extranet
#M#E-BDC-ATUALIZACAO-220 : Erro na atualizacao da Extranet
#M#E-BDC-ATUALIZACAO-221 : Erro de infra-estrutura
#

# Variaveis de Ambiente
#=================================================================#
# Alteracao da consolidacao PCORP  - Edison /Workmation - 2004/04
#=================================================================#
. /etc/appltab

export TWO_TASK=${ENV_TNS_PDCOR}
export ORACLE_SID=${ENV_ORASID_PDCOR}
export ORACLE_HOME=${ENV_DIR_ORAHOME_COR}
export NLS_LANG=${ENV_NLSLANG_PDCOR}

## export ORACLE_SID=PCORP_SP
## export ORACLE_HOME=`grep ${ORACLE_SID}: /etc/oratab| cut -d: -f2`

# Variaveis de Trabalho
DATA=`date +%Y%m%d%H%M` 
WRK=${ENV_DIR_BASE_COR}/sched/corp
## WRK=/acorp_sp/sched/corp

LOG=$WRK/LOG/BDC_22_01_$DATA.log
SCR=/amb/scripts/corp
TMP=$WRK/sql1_$$.sql
ARQLOG=/tmp/sql4_$$.txt
SQL=$SCR/atualiza_extranet.sql
export ARQLOG

# Limpeza da area de trabalho
find $WRK/LOG -type f -mtime +5 -exec rm -f {} \;

$ORACLE_HOME/bin/sqlplus / @$SQL > $LOG 2>&1
RC=$?

if [ $RC != 0 ] ;then
   ( echo "Erro na atualizacao da Extranet "
     cat $LOG $ARQLOG ) | msg_api "E-BDC-ATUALIZACAO-220" 
   gzip -9 $LOG
   rm -f $TMP
   exit 1
fi

( echo "Sucesso na atualizacao da Extranet"
  cat $LOG $ARQLOG ) | msg_api "I-BDC-ATUALIZACAO-220"
rm -f $TMP $ARQLOG

exit 0
