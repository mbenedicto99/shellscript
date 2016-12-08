#!/bin/ksh 
#   Programa: BDC_10_01.sh
#   Gera arquivo de solicitacao de inclusao de clientes para o magnus 
#   Data: 18/12/98
#
## Mensagens
#M#I-BDC-GERACAO-101 : Sucesso na geracao de arquivo de clientes para o Magnus
#M#E-BDC-GERACAO-101 : Erro na geracao do arquivo de clientes para o magnus
#M#W-BDC-GERACAO-102 : Nenhuma solicitacao de inclusao de clientes selecionada
#M#E-BDC-GERACAO-103 : Erro na atualizacao de status do magnus para enviado ("E")
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

### export ORACLE_SID=PCORP_SP
### export ORACLE_HOME=`grep ${ORACLE_SID}: /etc/oratab| cut -d: -f2`

# Variaveis de Trabalho
WRK=${ENV_DIR_BASE_COR}/sched/corp
### WRK=/acorp_sp/sched/corp
SCR=/amb/scripts/corp
TMP1=$WRK/sql1_$$.sql
TMP2=$WRK/sql2_$$.sql

OUT=$WRK/OUT
LOG=$WRK/LOG
SQL1=$SCR/exp_cliente.sql
SQL2=$SCR/marca_cliente.sql

DESTINO="PPGS_SP"
HORTIM=`date +%Y%m%d.%H%M%S`
ARQ=$OUT/CV$HORTIM
ARQ2=$OUT/DG$HORTIM
ARQ3=$OUT/GC$HORTIM

# Limpeza da area de trabalho
find $OUT -type f -mtime +3 -exec rm -f {} \;

export ARQ

cat << EOF > $TMP1
  -- Insere TAG para processo
  exec dbms_application_info.set_client_info ('BDC_EXPORTA_CLIENTE');

  -- Insere SQL disponibilizado pelo analista
  `cat $SQL1`
  exit
EOF

echo "Inicio de execucao `date +%d/%m/%Y-%H:%M:%S`" >> $ARQ.log
chmod 755 $TMP1

$ORACLE_HOME/bin/sqlplus / @$TMP1 >> $ARQ.log 2>&1
RC=$?

echo "Termino de execucao `date +%d/%m/%Y-%H:%M:%S`" >> $ARQ.log

if [ $RC != 0 ]
   then ( echo `basename $ARQ` " - Erro na geracao do arquivo de clientes para o magnus"
           cat $ARQ.log ) | msg_api2 "E-INTERFACES-CLIENTES-GERACAO"
           # rm -f $SQL
           rm -f $TMP1 
          exit 1
fi

if [ -s $ARQ ]
   then ( echo `basename $ARQ` " - Sucesso na geracao de arquivo de clientes para o Magnus"
           cat $ARQ 
          echo
           cat $ARQ.log ) | msg_api2 "I-INTERFACES-CLIENTES-GERACAO"
   else ( echo `basename $ARQ` "- Nenhum arquivo gerado"
           cat $ARQ.log ) | msg_api2 "W-INTERFACES-CLIENTES-GERACAO"
        rm -f $ARQ $TMP1
        gzip -9 $ARQ.log
        exit 0
fi

cat << EOF > $TMP2
  whenever sqlerror exit failure
  whenever oserror exit failure
  set pagesize 1000
  set linesize 80

  -- Insere SQL disponibilizado pelo analista
  `cat $SQL2`

  exit
EOF

chmod 644 $TMP2

$ORACLE_HOME/bin/sqlplus  / @$TMP2 >> $ARQ.log 2>&1
RC=$?

if [ $RC != 0 ]
   then ( echo "BDC_10_01 - Erro na atualizacao de status do magnus para enviado \"E\"" 
      cat $ARQ.log ) | msg_api2 "E-INTERFACES-CLIENTES-GERACAO"
     exit 1
fi

/amb/eventbin/TRANS_RQT.sh $DESTINO $ARQ 2>$TMP2
if [ $? != 0 ]; then
     ( echo `basename $ARQ` - Erro na transferencia; cat $TMP2 )| msg_api2 "E-INTERFACES-CLIENTES-GERACAO"
     rm -f $TMP2
     exit 1
  fi
gzip -9 ${ARQ} $ARQ.log

rm -f $SQL
rm -f $TMP1 $TMP2
exit 0
