#!/bin/ksh
#  Script      : BILLING_02_02.sh
#  Objetivo    : PROCESSAMENTO DE CONTAS ZERADAS  
#                Envia Relatorio de Contas zeradas antes BGH commit
#  Descricao   : CONTAS ZERADAS 2 
#  Pre-Requis  : 
#  Criticidade : Alta - Se ocorrer Erro acionar Analista Responsavel 
#  Criacao     : 27/03/02
#  Alteracao   : Marcos de Benedicto - 25/06/2003
#
# Envia Relatorio de Contas zeradas antes BGH commit
#
# Criacao 27/03/02
#
## Mensagens
#M#I-CONTZER-005: (Sucesso) Atualizacao Contas Zeradas
#M#E-CONTZER-005: (Erro) Atualizacao Contas Zeradas

. /etc/appltab

TMP1=/tmp/sql1_$$.txt
TMP2=/tmp/sql2_$$.sql
DAT=`date "+%Y%m%d%H%M"`
BILLC=$1
#
# Atribuicao de variaveis
#
CICLO=$1

# ALterado em 2003/08/14 - Edison Santos (Workmation) - Consolidacao MIBAS - BSCS
#===================================================================================#
### MAQ=$2
### case "$MAQ" in
  ### spo*) SITE=SP 
        ### site=sp
        ### export TWO_TASK=PBSCS_${SITE} ;;
  ### rjo*) SITE=RJ 
        ### site=rj
        ### export TWO_TASK=PBSCS_${SITE} ;;
     ### *) echo "ERRO: site $MAQ invalido"
        ### exit 1;;
### esac
### export ORACLE_HOME=`grep ^${TWO_TASK}: /etc/oratab | cut -d: -f2`
### export NLS_LANG="brazilian portuguese_brazil.we8dec"
#===================================================================================#

SITE="${ENV_VAR_SITE}"
typeset -l site
site="${ENV_VAR_SITE}"
export TWO_TASK="${ENV_TNS_PDBSC}"
export ORACLE_HOME="${ENV_DIR_ORAHOME_BSC}"
export NLS_LANG="${ENV_NLSLANG_PDBSC}"

DESTERR="sql_erros@unix_mail_fwd"

cat << EOF > $TMP2
whenever sqlerror exit failure
whenever oserror exit failure
set echo off

update customer_all
set csbill_suppress = 'X'
where customer_id in (
select cu.customer_id
from cashreceipts cas,orderhdr_all oh,customer_all cu
where billcycle = '$CICLO'
and cscurbalance <= 0
and PREV_BALANCE  <= 0
and paymntresp = 'X'
and csbill_suppress is null
and oh.customer_id = cu.customer_id
and oh.ohxact = (select max(a.ohxact) from orderhdr_all a where a.customer_id = oh.customer_id) 
and cas.customer_id = oh.customer_id
and cas.caxact = ( select max(b.caxact) from cashreceipts b where b.customer_id = cas.customer_id)
and cas.caentdate < ohentdate - 30
and cu.CSACTIVATED <= ohentdate - 60)
/

commit;

update customer_all set csbill_suppress = 'X' where customer_id in 
(select ca.customer_id from (selecT count(ohxact)quan ,customer_id  from orderhdr_all where ohinvamt <= 0 
and ohentdate >= trunc(sysdate-90) group by customer_id ) tab ,
customer_all ca,prod.saldos sal
where  sal.prev_balance = 0
and  sal.pagtos_efet = 0
and  sal.cscurbalance = 0
and  ca.custcode = sal.custcode
and  ca.csbill_suppress is null
and  ca.billcycle <> '07'
and  ca.CSACTIVATED < trunc(sysdate-90)
and  lbc_date is not null
and  tab.customer_id = ca.customer_id
and  tab.quan >= 2);

commit;

exit
EOF

#
# Execucao de SQL
#
chmod 644 $TMP2
$ORACLE_HOME/bin/sqlplus / @$TMP2 > $TMP1 2>&1
RC=$?
SUBJ="Contas Zeradas - $SITE - $tipo"
#
# Envio de e-mail
#
if [ $RC != 0 ]; then
   ( echo "ERRO: $SUBJ") | /amb/bin/msg_api2  "E-BILLING-BCH-CONTASZERADAS"
   /amb/operator/bin/attach_mail $DESTERR $TMP1 $SUBJ >$TMP1 2>&1
   rm -f $TMP1 $TMP2
   exit 1
fi
  
( echo "Sucesso: Atualizacao Contas Zeradas" 
  cat $TMP1 ) | /amb/bin/msg_api2  "I-BILLING-BCH-CONTASZERADAS"
#
# Cleaning
#
rm -f $TMP1 $TMP2
