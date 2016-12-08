#!/bin/ksh 
#   Programa: BDC_14_01.sh
#   Relatorio diario de ocorrencias - acompanhamento
#   Data: 19/05/99
#
## Mensagens
#M#I-BDC-RELATORIO-140 : Nenhum cliente enviado e rejeitado pelo Magnus
#M#W-BDC-RELATORIO-140 : Clientes enviados e rejeitado pelo Magnus
#M#E-BDC-RELATORIO-140 : Erro na geracao do Relatorio de acompanhamento diario
#M#I-BDC-RELATORIO-141 : Sucesso na limpeza de tabelas temporarias
#M#E-BDC-RELATORIO-141 : Erro na limpeza de tabelas temporarias
#M#E-BDC-RELATORIO-142 : Erro de infra-estrutura
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
### WRK=/acorp_sp/sched/corp

LOG=$WRK/LOG
SCR=/amb/scripts/corp

TMP1=$WRK/sql1_$$.sql
TMP2=$WRK/sql2_$$.lst
TMP3=/tmp/sql3_$$.sql

SQL1=$SCR/rel_acompanhamento.sql
SQL2=$SCR/limpa_tabela.sql

ARQLOG=$LOG/BDC_14_$DATA.log
ARQ1=$LOG/BDC_14_1_$DATA.txt
ARQ2=$LOG/BDC_14_2_$DATA.txt

echo "Inicio da geracao do relatorio `date +%d/%m/%Y-%H:%M:%S`" > $ARQLOG

$ORACLE_HOME/bin/sqlplus / @$SQL1 > $ARQ1 2>> $ARQLOG 2>&1
RC=$?

echo "Fim da geracao do relatorio `date +%H:%M:%S`" >> $ARQLOG

if [ $RC != 0 ] ;then
    ( echo `basename $ARQ1` " - Erro na geracao do relatorio"
      cat $ARQLOG $ARQ1) | msg_api "E-BDC-RELATORIO-140" 
    gzip -9 $ARQLOG $ARQ1
    rm -f $TMP1
    exit 1
  else
    grep n?o $ARQ1
    if [ $? = 0 ] ;then
       ( echo "Nenhum cliente enviado e rejeitado pelo Magnus"
       cat $ARQLOG $ARQ1 ) | msg_api "I-BDC-RELATORIO-140"  
       rm -f $ARQ1
       else
        ( echo "Clientes enviados e rejeitados pelo Magnus !"
        cat $ARQLOG $ARQ1) | msg_api "W-BDC-RELATORIO-140"
        gzip -9 $ARQ1 
    fi
      
fi

rm -f $TMP1

echo "Inicio da limpeza das tabelas temporarias `date +%H:%M:%S`" > $ARQLOG

$ORACLE_HOME/bin/sqlplus  / @$SQL2 > $ARQ2 2>> $ARQLOG 2>&1
RC=$?

echo "Fim da limpeza das tabelas temporarias `date +%H:%M:%S`" >> $ARQLOG

if [ $RC != 0 ]; then
   ( echo  "Erro na limpeza das tabelas temporarias !"
     cat $ARQLOG $ARQ2 ) | msg_api "E-BDC-RELATORIO-141"
   gzip -9 $ARQLOG $ARQ2
   rm -f $TMP1 $TMP2
   exit 1
fi

( echo "Sucesso na limpeza das tabelas temporarias"
  cat $ARQLOG $ARQ2 ) | msg_api "I-BDC-RELATORIO-141"
gzip -9 $ARQLOG $ARQ2
rm -f $TMP1 $TMP2 $TMP3

exit 0
