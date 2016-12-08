#!/bin/ksh
#  Script      : BILLING_01_01.sh
#  Objetivo    : PROCESSAMENTO BCH EM COMMIT + ANALISE DE LOG
#  Descricao   : 
#  Pre-Requis  : 
#  Criticidade : Alta - Se ocorrer Erro acionar Analista Responsavel 
#  Alteracao   : 19/10/02
#

# ALterado em 2003/08/13 - Edison Santos (Workmation) - Consolidacao MIBAS - BSCS
#===================================================================================#
export LOC_LOGIN_PDBSC_BCH2="sysadm/wizardmagic03"

. /etc/appltab

### ARQCFG=/amb/operator/cfg/consolidacao/bscs_batch.cfg
### ARQCFG=/amb/eventbin/consolidacao/OK/bscs_batch.cfg

ARQCFG=/amb/operator/cfg/bscs_batch.cfg
SCPFUNC=/amb/operator/cfg/script_functions.cfg

# Le arquivo de paramentros
. $ARQCFG

# VARIABLES
### UNAME=`uname -n`

ARQTMP=/tmp/.bch_$$
ARQTMP1=/tmp/.bch1_$$
DATA=`date`
COMMIT=1

typeset -L2 SITE
typeset -u LIMPA_DOC_ALL
SITE="${ENV_VAR_SITE}"

# FUNCTIONS

# Carrega arquivo de funcoes utilitarias

. $SCPFUNC         

# MAIN

# Checa se esta rodando na maquina correta

### ALterado em 2003/08/13 - Edison Santos (Workmation) - Consolidacao MIBAS - BSCS
###===================================================================================#
### AUX=`expr "$BCHMAQS" : ".*$UNAME"`
### if [ $AUX = 0 ]
### then
###    echo "ERRO: Maquina $UNAME incorreta"
###    exit 1
### fi 
###
### DIR_AUTH="/artx_${SITE}/prod/WORK/TMP"
###
### case "$1" in
###  0[123456789]) BILLCYCLE=$1
###===================================================================================#

DIR_AUTH="${ENV_DIR_BASE_RTX}/prod/WORK/TMP" 

case "$1" in
   0[1234789]|1[01234]) BILLCYCLE=$1
                        ;;
                     *) echo "ERRO: Billcycle [$1] invalido"
                        exit 1
                        ;;
esac

case "$2" in
         COMMIT) BILLCG="-"
                 COMMIT=0
                 ;;
             CG) BILLCG="CG"
                 ;;
     [ABCDEFGL]) BILLCG="cg $2"
                 ;;
              *) echo "ERRO: Control Group [$2] invalido"
                 exit 1
                 ;;
esac

LIMPA_DOC_ALL=$3

### ALterado em 2003/08/13 - Edison Santos (Workmation) - Consolidacao MIBAS - BSCS
###===================================================================================#
### case "$UNAME" in
###     spo*) BILLIND=`expr $BILLCYCLE \* 100 + 11`
###           USUARIO=rbscs/rbscs
###           # Alterado p/ possibilitar execucao na spoaxap2
###           BILL_INSTANCIA="PBSCS_SP" 
###           export ORACLE_HOME=`grep "^RTX_..:" /etc/oratab | cut -d: -f 2` 
###           ;;
###     rjo*) BILLIND=`expr $BILLCYCLE \* 100 + 21`
###           USUARIO=rbscsrj/rbscsrj
###           # Alterado p/ possibilitar execucao na spoaxap2
###           BILL_INSTANCIA="PBSCS_RJ"
###           export ORACLE_HOME=`grep "^PRTX_..:" /etc/oratab | cut -d: -f 2`
###           ;;
### esac
###===================================================================================#

### ALterado em 2003/08/13 - Edison Santos (Workmation) - Consolidacao MIBAS - BSCS
### [ "${SITE}" = "SP" ] && VAL_NUM_SITE="11"
### [ "${SITE}" = "RJ" ] && VAL_NUM_SITE="21"
### 
### ALterado em 2003/08/13 - Edison Santos (Workmation) - Consolidacao MIBAS - BSCS
### if [ -z "${VAL_NUM_SITE}" ]
### then
###     echo "Erro na atribuicao de valor de indexacao da variavel VAL_NUM_SITE: ${VAL_NUM_SITE}"
###     echo "     Motivo: "
###     echo "            A variavel SITE: ${SITE} difere de SP e RJ "
###     exit 99
### fi
### 
### ALterado em 2003/08/13 - Edison Santos (Workmation) - Consolidacao MIBAS - BSCS
### BILLIND=`expr $BILLCYCLE \* 100 + ${VAL_NUM_SITE}`

BILLIND="${BILLCYCLE}"

if [ -z "${BCHDATE[$BILLIND]}" ]
then
    echo "Erro na atribuicao de valor para data de Venvimento do Ciclo!!!!!"
    echo "     Motivo: "
    echo "            A variavel BCHDATE[$BILLIND].....: ${BCHDATE[$BILLIND]} Nao tem valor atribuido!!!"
    echo "            Conteudo da variavel BILLIND.....: ${BILLIND}"
    echo "            Conteudo da variavel BILLCYCLE...: ${BILLCYCLE}"
    echo "            Conteudo da variavel VAL_NUM_SITE: ${VAL_NUM_SITE}"
    exit 99
fi

USUARIO="${ENV_LOGIN_PDBSC}"
BILL_INSTANCIA="${ENV_TNS_PDBSC}"
export ORACLE_HOME="${ENV_DIR_ORAHOME_BSC}"

# incluido em 2003/08/13 - Edison Santos (Workmation) - Consolidacao MIBAS - BSCS
export TWO_TASK="${ENV_TNS_PDBSC}"
export NLS_LANG="${ENV_NLSLANG_PDBSC}"
#===================================================================================#


BCHBIN[$BILLIND]="pbch $BCHINSTANCES $BILLCYCLE - - ${BCHDATE[$BILLIND]} $BILLCG"

### ALterado em 2003/08/13 - Edison Santos (Workmation) - Consolidacao MIBAS - BSCS
###  $ORACLE_HOME/bin/sqlplus -s $USUARIO@$BILL_INSTANCIA <<EOF > $ARQTMP

$ORACLE_HOME/bin/sqlplus -s $USUARIO <<EOF > $ARQTMP
  set heading off
  select substr(cfvalue,instr(cfvalue,'-t')+3,6) from mpscftab where cfcode=23;
EOF

clear
echo "BSCS BILLING PROCESS - BCH - $DATA"
echo "------------------------------------------------------------------"
echo
printf "%-20s - %-30s\n" "BILL CYCLE" $BILLCYCLE
printf "%-20s - %-30s\n\n" "DATA DE VENCIMENTO" ${BCHDATE[$BILLIND]}
printf "%-20s - %-30s\n\n" "COMANDO EXECUTADO" "${BCHBIN[$BILLIND]}"
printf "%-20s - %-30s\n\n" "VIRTUAL START" "`grep ^[0-9] $ARQTMP`"
echo "------------------------------------------------------------------"
echo

FILE_AUTH=${DIR_AUTH}/"BCH-"${BILLCYCLE}.flg
if [ ! -f ${FILE_AUTH} ]
then
   echo "\n\t******************** ATENCAO ********************"
   echo "\n\tNao ha' autorizacao para execucao deste processo."
   echo "\tEntrar em contato com o responsavel pelo scheduler.\n"
   echo "\tProcesso abortado.\n"
   # Remove tambem a autorizacao da Documment All, se existir
   FILE_AUTH=${DIR_AUTH}/"LIMPEZA_DOCUMMENT_ALL-"${BILLCYCLE}.flg
   rm -f ${FILE_AUTH}
   exit 1
fi

if [ $? != 0 ]
then
   echo "\n\t******************** ATENCAO ********************"
   echo "\n\tOcorreu erro na remocao da autorizacao do processo."
   echo "\tEntrar em contato com o responsavel pelo scheduler.\n"
   echo "\tProcesso abortado.\n"
   exit 1
fi

(
  date
  echo
  echo "------------------------------------------------------------------"

  rm -f $FILE_AUTH
  if [ $? != 0 ]
  then
     echo "\n\t******************** ATENCAO ********************"
     echo "\n\tOcorreu erro na remocao da autorizacao do processo."
     echo "\tEntrar em contato com o responsavel pelo scheduler.\n"
     echo "\tProcesso abortado.\n"
     exit 1
  fi

AUX=0
if [ $LIMPA_DOC_ALL = "S" ] ; then
  echo "Limpando Edifact"
  for i in `ls $BCHEDIFACT`
  do  
     rm $BCHEDIFACT$i
  done
  echo "Limpando tabela Documment_all"

  ### ALterado em 2003/08/13 - Edison Santos (Workmation) - Consolidacao MIBAS - BSCS
  ### su - prod -c "sqlplus sysadm/wizardmagic03@$BILL_INSTANCIA @/amb/operator/cfg/trunc_doc.sql"

  su - prod -c "sqlplus ${LOC_LOGIN_PDBSC_BCH2}@${BILL_INSTANCIA} @/amb/operator/cfg/trunc_doc.sql"
  AUX=$?
fi



#----------------------------------------------------------------------------

### Alterado em 2003/08/15 - Consolidacao MIBAS/BSCS - Conf. Instrucoes do Des. para Consolidacao.
### if [ "$SITE" = "sp" ]
### then
### $ORACLE_HOME/bin/sqlplus -s sysadm/wizardmagic03@$BILL_INSTANCIA << EOF > ~prod/WORK/TMP/log_delecao_retencao.$BILLCYCLE

$ORACLE_HOME/bin/sqlplus -s ${LOC_LOGIN_PDBSC_BCH2} << EOF > ~prod/WORK/TMP/log_delecao_retencao.$BILLCYCLE
update fees cc set geocode = (
select jurdic_code
from   costcenter_jurisdiction cj, customer_all cu
where  cu.customer_id = cc.customer_id
and    cj.cost_id = cu.costcenter_id)
where    geocode = 'BR';

update fees cc set sub_geocode = (
select jurdic_code
from   costcenter_jurisdiction cj, customer_all cu
where  cu.customer_id = cc.customer_id
and    cj.cost_id = cu.costcenter_id)
where    sub_geocode = 'BR';

update fees set tax_status = 'I';
commit;
EOF


### Alterado em 2003/08/15 - Consolidacao MIBAS/BSCS - Conf. Instrucoes do Des. para Consolidacao.
### else
### 
### ALterado em 2003/08/13 - Edison Santos (Workmation) - Consolidacao MIBAS - BSCS
### $ORACLE_HOME/bin/sqlplus -s sysadm/wizardmagic03@$BILL_INSTANCIA << EOF > ~prod/WORK/TMP/log_delecao_retencao
### update fees set tax_status = 'I';
### commit;
### EOF
###
### fi

#----------------------------------------------------------------------------


  if [ $AUX = 0 ]
  then
     echo "------------------------------------------------------------------"
     echo "Executando comando com o cron"
     echo "su - prod -c \"${BCHBIN[$BILLIND]}\"" > $ARQTMP
     cat $ARQTMP
     echo "------------------------------------------------------------------"
     batch < $ARQTMP 2>&1

     sleep 2

     # Aguarda termino do processo

	 EMAIL="billing@unix_mail_fwd"
	 DIR="${ENV_DIR_BASE_RTX}/prod/WORK/LOG"

      while true
	   do AUX=`ps -ef | grep pbch | grep -v grep`
	   [ -z "$AUX" ] && break || sleep 5

   ARQ_BCHLOG=`ls -rt ${DIR}/BCH*.log | tail -1`
   COUNT=`grep -c "FATAL ERROR" ${ARQ_BCHLOG}`

   if [ ${COUNT} -ne 0 ]
  then
   set +x
   >/tmp/mail$$.txt
   echo "
   +----------------------------------------------------
   |
   |   ERRO!
   |   `date`
   |   Foram encontrados erros no log de BCH.
   |   Arquivo de LOG = ${ARQ_BCHLOG}
   |   Msg de ERRO = `grep "FATAL" ${ARQ_BCHLOG}`
   |
   +-----------------------------------------------------\n" | tee -a /tmp/mail$$.txt
   cat /tmp/mail$$.txt | mailx -m -s "BCH - Encontrado FATAL ERROR no log." ${EMAIL}
   exit 1
   fi

	done

  else
     echo "*************** Problema na limpeza da tabela"
  fi
         
  echo
  echo "------------------------------------------------------------------"
  echo "Processo Terminado em: "`date`
  echo "------------------------------------------------------------------"

) > $ARQTMP1

sleep 3
icat   $ARQTMP1

/amb/bin/msg_api2  "W-BILLING-BCH-PROCESSAMENTO" <$ARQTMP1

rm -f $ARQTMP $ARQTMP1

# Executa Analise de log	
### /amb/eventbin/consolidacao/OK/BILLING_01_02.sh $BILLCYCLE
/amb/eventbin/BILLING_01_02.sh $BILLCYCLE


 exit $?


