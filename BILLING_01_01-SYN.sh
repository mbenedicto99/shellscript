#!/bin/ksh
#  Script      : BILLING_01_01.sh
#  Objetivo    : PROCESSAMENTO BCH EM COMMIT + ANALISE DE LOG
#  Descricao   : 
#  Pre-Requis  : 
#  Criticidade : Alta - Se ocorrer Erro acionar Analista Responsavel 
#  Alteracao   : 19/10/02
#

# ALterado em 2003/08/13 - Edison Santos (Workmation) - Consolidacao MIBAS - BSCS
# Alterado em 2004/01/07 - Marcos de Benedicto (Workmatiom) - Verificacao de data de corte
# Alterado em 2004/03/15 - Marcos de Benedicto (Workmation) - Verificacao de FATAL ERROR, Kill de BCH e Abend do JOB
#                                                	      Identificacao de arquivos de log gerados pelo BCH
#===================================================================================#
export LOC_LOGIN_PDBSC_BCH2="sysadm/wizardmagic03"

. /etc/appltab

ARQCFG=/amb/operator/cfg/bscs_batch.cfg
SCPFUNC=/amb/operator/cfg/script_functions.cfg

# Le arquivo de paramentros
. $ARQCFG

# VARIABLES
### UNAME=`uname -n`

######
MOUNT=`date +%b`
N_MOUNT=`date +%m`
DAY=`printf "%2s" $(date +%d)`
HOUR=`date +%H`
MIN=`date +%M`
TIME=`echo ${HOUR}:${MIN}`
#######

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


DIR_AUTH="${ENV_DIR_BASE_RTX}/prod/WORK/TMP" 


case "$1" in
   0[1234789]|1[01234]) BILLCYCLE=$1
                        ;;
                     *) echo "ERRO: Billcycle [$1] invalido"
                        exit 1
                        ;;
esac

# Verifica se arquivo com data de corte existe

FILE_AUTH=${DIR_AUTH}/"BCH-"${BILLCYCLE}.flg
DC="`sed -n '2p' ${FILE_AUTH} |cut -c 1-6`"

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

case "$2" in
         COMMIT) BILLCG="-"
                 COMMIT=0
                 #---------------------------------#
                 # Verifica se dt sis < dt cort    #
                 #---------------------------------#
                 DS="`date +%y%m%d`"
                 if [ "${DS}" -lt "${DC}" ]
                    then
                       banner "ATENCAO!!!"
                       echo ''
                       echo '+------------------------------------------------------------+'
                       echo '|                                                            |'
                       echo '|  DATA DO SISTEMA EH MENOR QUE DATA DE CORTE!!              |'
                       echo '|  Verificar se eh para executar realmente ciclo em COMMIT.  |'
                       echo '|  Verificar se a solicitacao do analista confere com o      |'
                       echo '|  processo executado.                                       |'
                       echo '|                                                            |'
                       echo '+------------------------------------------------------------+'
                       echo ''
                       exit 1
                    else
                       echo 'Data do SISTEMA confere com a data de CORTE'
                 fi
                 ;;
             CG) BILLCG="CG"
                 ;;
     [ABCDEFGL]) BILLCG="cg $2"
                 ;;
              *) echo "ERRO: Control Group [$2] invalido"
                 exit 1
                 ;;
esac

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

/amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${LOC_LOGIN_PDBSC_BCH2}" "/amb/operator/cfg/check_ciclo_syn_doc.sql ${BILLCYCLE}" prod@unix_mail_fwd  "Verifica se SYSNONYM esta associado a DOCUMENT_ALL do CICLO: ${BILLCYCLE} em processamento" 0  BILLING_BCH 0

RC=$?

if [ "$RC" -ne "0" ]
then
    banner ERRO!!
    echo ' '
    echo '#======================================================#'
    echo '#  Erro na identificacao de ciclo ca DOCUMENT_ALL      #'
    echo '#  Ciclo de processamento deve estar incompativel      #'
    echo '#  com o CICLO da DOCUMENT_ALL, ou aconteceu erro      #'
    echo '#  de processamento na QUERY de validacao de CICLO     #'
    echo '#  da DOCUMENT_ALL!!!!                                 #'
    echo '#  Verifique a SYSOUT do SQLPLUS para identificar      #'
    echo '#  o motivo real (ver SYSOUT do JOB via CTM).          #'
    echo '#======================================================#'
    echo ' '
    exit 99
fi
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

## Captura tempo de processamento.
LOG_DATE=`date +%d%m%Y`
LOG_TIME="${ENV_DIR_BASE_RTX}/prod/reports/BCH_${LOG_DATE}.txt"
LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"

printf "%s\t%s\t%s\t%s\n" "BCH_${BILLCYCLE}" "Inicio do processamento." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

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


echo " DATA/HORA antes dos UPDATES de GEOCODE do BILLING: `date`"


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

RC=$?

echo " DATA/HORA apos os UPDATES de GEOCODE do BILLING e antes do BCH: `date`"

#----------------------------------------------------------------------------


  if [ $RC = 0 ]
  then
     echo "------------------------------------------------------------------"
     echo "Executando comando com o cron"
#----------
# Anterado em 13/04/04 por Marcos de Benedicto - CHANGE 2037
# Alteracao devido a um BUG do BCH que calcula uma hora a mais no time zone,
# a alteracao do programa ja foi solicitada, mas para evitar erros enquanto
# novo programa nao chega, deve ser incluido um export do TZ
#----------
     echo "export TZ=EST" > $ARQTMP
     echo "su - prod -c \"${BCHBIN[$BILLIND]}\"" >> $ARQTMP
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

############# VERIFICACAO DE ARQUIVO DE LOG #####################
############# MARCOS DE BENEDICTO 16/03/2004  #####################

#/amb/eventbin/TST_FILE.sh "${DIR}/BCH*.log" ${MOUNT} ${N_MOUNT} ${DAY} ${HOUR} ${MIN} ${TIME}

set +x
ARQ_TESTADO=`ls -ltr ${DIR}/BCH*.log | tail -1`
set -x
TEST_MOUNT=`echo ${ARQ_TESTADO} | awk '{print $6}'`
TEST_DAY=`echo ${ARQ_TESTADO} | awk '{print $7}'`
FLG=33

	if [ "${MOUNT}" = "${TEST_MOUNT}" -a "${DAY}" -eq "${TEST_DAY}" ]
	then
	ARQ_HOUR=`echo ${ARQ_TESTADO} | awk '{print $8}' | cut -d":" -f1`
	ARQ_MIN=`echo ${ARQ_TESTADO} | awk '{print $8}' | cut -d":" -f2`

		if [ "${ARQ_HOUR}" -gt "${HOUR}" ]
		then
		echo "\n Arquivo atual. \n"
		FLG=0
		fi

		if [ "${ARQ_HOUR}" -eq "${HOUR}" -a "${ARQ_MIN}" -ge "${MIN}" ]
		then
		echo "\n Arquivo atual. \n"
		FLG=0
		fi

	else
	echo "\n Arquivo de log ainda nao esta no periodo de monitoracao. \n"
	FLG=33
	fi

#let TESTE_DAY1=`echo ${ARQ_TESTADO} | awk '{print $7}'`-1
#
#	if [ "${MOUNT}" = "${TEST_MOUNT}" -a "${DAY}" -eq "${TEST_DAY1}" ]
#	then
#	echo "\n Arquivo atual. \n"
#	FLG=33
#	fi
#
#case ${TEST_MOUNT} in
#	Jan) TEST_MOUNT1=12;;
#	Feb) TEST_MOUNT1=01;;
#	Mar) TEST_MOUNT1=02;;
#	Apr) TEST_MOUNT1=03;;
#	May) TEST_MOUNT1=04;;
#	Jun) TEST_MOUNT1=05;;
#	Jul) TEST_MOUNT1=06;;
#	Aug) TEST_MOUNT1=07;;
#	Sep) TEST_MOUNT1=08;;
#	Oct) TEST_MOUNT1=09;;
#	Nov) TEST_MOUNT1=10;;
#	Dec) TEST_MOUNT1=11;;
#	esac
#
#	if [ "${MOUNT}" -eq "${TEST_MOUNT1}" ]
#	then
#	echo "\n Arquivo atual. \n"
#	FLG=33
#	else
#	echo "\n Arquivo de log ainda não foi atualizado. \n"
#	FLG=0
#	fi


	if [ "${FLG}" -eq "0" ]
	then

	ARQ_BCHLOG=`ls -rt ${DIR}/BCH*.log | tail -1`
	COUNT=`grep -c "FATAL ERROR" ${ARQ_BCHLOG}`

		if [ `grep -c "Billcycle is \"${BILLCYCLE}\"" ${ARQ_BCHLOG}` -ge 1 -a ${COUNT} -ne 0 ]
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
		#Para processo do BCH.

		for PROC in `ps -ef | egrep "pbch|bch" | grep -v egrep | awk '{print $2}'`
		do
		kill -9 $PROC
		done
		RC=666
		fi

	fi

############# VERIFICACAO DE ARQUIVO DE LOG #####################
############# MARCOS DE BENEDICTO 16/03/2004  #####################

     done

  else
     echo "*************** Problema no UPDATE GEOCODE!!!"
     echo "*************** Problema no UPDATE GEOCODE!!!"
     echo "*************** Problema no UPDATE GEOCODE!!!"
     echo "*************** Problema no UPDATE GEOCODE!!!"
     echo "*************** Problema no UPDATE GEOCODE!!!"
     echo "*************** Problema no UPDATE GEOCODE!!!"
     echo "*************** Problema no UPDATE GEOCODE!!!"
  fi
         
  echo
  echo "------------------------------------------------------------------"
  echo "Processo Terminado em: "`date`
  echo "------------------------------------------------------------------"

) > $ARQTMP1 2>&1

	if [ ${RC} -eq 0 ]
	then
	echo "\nBCH OK!\n"
	else
	echo "\nFoi encontrado FATAL ERROR no BCH, verificar log.\n"
	exit 1
							fi
## Captura tempo de processamento.
LOG_DATE=`date +%d%m%Y`
LOG_TIME="${ENV_DIR_BASE_RTX}/prod/reports/BCH_${LOG_DATE}.txt"
LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"

printf "%s\t%s\t%s\t%s\n" "BCH_${BILLCYCLE}" "Termino do processamento." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

echo " DATA/HORA apos o BCH: `date`"

sleep 3
cat   $ARQTMP1

/amb/bin/msg_api2  "W-BILLING-BCH-PROCESSAMENTO" <$ARQTMP1

rm -f $ARQTMP $ARQTMP1

# Executa Analise de log

########################################
#                                      #
#  VERIFICA FATAL ERROR NO LOG DO BCH  #
#                                      #
########################################

COUNT=0

	for i in `ls -tr BCH*.log | tail -10`
	do
	echo $i
	CALC=`grep -i -c "FATAL ERROR" $i`
	echo ${CALC}
	COUNT=`expr ${CALC} + ${COUNT}`
	done

 echo ${COUNT}

 if [ ${COUNT} -ne 0 ]
 then
 set +x
 echo "
 +--------------------------------------------------
 |
 |   ERRO!
 |   `date`
 |   Foi detectado FATAL ERROR nos log do BCH.
 |
 +--------------------------------------------------\n"
 set -x
 exit 1
 fi

#############################


/amb/eventbin/BILLING_01_02.sh $BILLCYCLE

AUX=`expr $? + $RC`
rm ${ARQ_AUX}
exit $AUX
