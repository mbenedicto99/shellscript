#!/bin/ksh
#
# Script   : BDC_21_01.sh
# Descricao: Interface de Clientes do BSCS x BDC
# Analista : Kilson
# Data     : 09/06/99
#
## Mensagens
#M#I-BDC-ATUALIZACAO-210 : Sucesso na atualizacao de Clientes do BSCS
#M#E-BDC-ATUALIZACAO-210 : Erro na Atualizacao de Clientes do BSCS
#M#E-BDC-ATUALIZACAO-211 : Erro de infra-estrutura
#

# Definicao de Variaveis de Ambiente
export ORACLE_SID=TCORP_SP
export ORACLE_HOME=`grep ^${ORACLE_SID}: /etc/oratab | cut -d: -f2`

# Definicao de Area de trabalho, de scripts e temporaria
WRK=/acorp_sp/sched/corp
SCR=/amb/scripts/corp
TMP=$WRK/TMP
TMP1=$TMP/BDC_21_01_1.$$
TMP2=$TMP/BDC_21_01_2.$$
TMP1=$TMP/BDC_21_01_3.$$
TMP2=$TMP/BDC_21_01_4.$$
NUMPROC=$$

## Verificacao de infra-estrutura
# Diretorio Home do oracle
if [ -z $ORACLE_HOME ] ; then
   echo "Nao encontrado home da instancia $ORACLE_SID" | msg_api "E-BDC-ATUALIZACAO-211"
   exit 1
fi

# Area de trabalho
if [ ! -d $WRK ]; then
   ( echo "Nao encontrado $WRK" ) | msg_api "E-BDC-ATUALIZACAO-211"
   exit 1
fi

# Area de trabalho
cd $WRK 2>$TMP1
if [ $? != 0 ] ; then 
   ( echo "Erro no cd $WRK"; cat $TMP1 ) | msg_api "E-BDC-ATUALIZACAO-211"
   rm -f $TMP1
   exit 1
fi

## Inicio do processo

cat << EOF > $TMP3
set serveroutput on
spool $TMP4
begin
corp.pk_cli_bscs_bdc.pr_cli_bscs_bdc_01($NUMPROC);
end;
/
spool off
set serveroutput off
exit
EOF

   echo "$ARQ - Inicio da atualizacao de clientes do BSCS `date` " >> $TMP2

   $ORACLE_HOME/bin/sqlplus / @$TMP3 > $TMP1 2>&1 

   rc=$?

   echo "$ARQ - Termino da atualizacao de clientes do BSCS `date` " >> $TMP2

   if [ $rc != 0 ] ; then
      ( echo "$ARQ - Erro na atualizacao de Clientes do BSCS"
        cat $TMP2 $TMP1 ) | msg_api "E-BDC-ATUALIZACAO-210"
        rm -f $TMP1 $TMP2
      exit 1
   fi

   grep -q "ERRO" $TMP1
   if [ $? = 0 ] ; then
      ( echo "$ARQ - Erro na execucao da procedure $SQL"
        cat $TMP1 $TMP2 ) | msg_api "E-BDC-ATUALIZACAO-210"
        rm -f $TMP1 $TMP2
      exit 1
   fi

   ( echo "$ARQ - Sucesso na atualizacao de Clientes do BSCS"
      cat $TMP2 $TMP4 ) | msg_api "I-BDC-ATUALIZACAO-210"

done

#
# Cleaning

/amb/bin/gzip -9 $PRO/$ARQ 

rm -f $TMP1 $TMP2 $TMP3 $TMP4

exit 0
