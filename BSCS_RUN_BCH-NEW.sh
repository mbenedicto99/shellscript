#!/bin/ksh
#  Script      : BSCS_RUN_BCH-NEW.sh
#  Objetivo    : PROCESSAMENTO BCH EM COMMIT/CG/TESTE + ANALISE DE LOG
#  Descricao   : 
#  Pre-Requis  : 
#  Criticidade : Alta - Se ocorrer Erro acionar Analista Responsavel 
#  Alteracao   : 19/10/02
#

# Verifica execucao do RLH <ciclo>.

CHK_RLH=`ps -ef | grep "rlh" | grep -c "\-$1"`
CHK_CICLO=$1
CHK_MODO=$2

	if [ "${CHK_RLH}" -ge 1 -a "${CHK_MODO}" = "CG" ]
	then
	echo "
	+---------------------------------------------------------------
	| 
	|   INFORMACAO!
	|   `date`
	|
	|   RLH do mesmo ciclo esta sendo executado, aguardar termino
	|    antes de reiniciar BCH-CG do ciclo ${CHK_CICLO}
	|
	+---------------------------------------------------------------\n"
	exit 1
	else
	[ "${CHK_MODO}" = "CG" ] && echo "Flag de execucao do BILL-CG ${CHK_CICLO}" >/aplic/artx/prod/WORK/TMP/BILL-CG${CHK_CICLO}.flg
	fi

# Display informativo do processo
echo "
  *----------------------------------------------------------*
  |  Data/Hora do START ...: `date`
  |  Processo executado ...: $0
  |  Parametros informados : $*
  *----------------------------------------------------------*\n "

#=======================================================================================#
# Funcao para validacao de STATUS CODE
F_ValidaRc()
{
  CodErro="$1"
  MsgErro="$2"

  if [ "${CodErro}" != "0" ] 
  then
     banner ERRO!!
     echo "
         *================================================*
         * Erro no processo de :
         * ${MsgErro}
         * RC = ${CodErro}
         *================================================*\n"
          
     exit ${CodErro}
  fi
}
#=======================================================================================#

#  Carregamento das Variaveis de ambiente...
. /etc/appltab


# Le arquivo de paramentros de Configuracao.
. /amb/operator/cfg/bscs_batch.cfg

#  Carregamento das Variaveis Locais

#     Diretorio para criacao dos arquivos FLG.
DIR_AUTH="${ENV_DIR_BASE_RTX}/prod/WORK/TMP"

ARQTMP=/tmp/.bch_$$
ARQTMP1=/tmp/.bch1_$$
DATA=`date`
COMMIT=1

#####################
MOUNT=`date +%b`
DAY=`printf "%2s" $(date +%d)`
HOUR=`date +%H`
MIN=`date +%M`
TIME=`echo ${HOUR}:${MIN}` 
####################

typeset -L2 SITE
typeset -u LIMPA_DOC_ALL
SITE="${ENV_VAR_SITE}"
RC=0

#     Variaveis para acesso ORACLE via SQLPLUS
export LOC_LOGIN_PDBSC_BCH2="sysadm/wizardmagic03"
export ORACLE_HOME="${ENV_DIR_ORAHOME_BSC}"
export TWO_TASK="${ENV_TNS_PDBSC}"
export NLS_LANG="${ENV_NLSLANG_PDBSC}"
USUARIO="${ENV_LOGIN_PDBSC}"
USR_BSCS="BCH"
PWD_BSCS="`egrep \"^\${USR_BSCS}\" ${ENV_DIR_BASE_RTX}/prod/batch/bin/bscs.passwd |awk '{print $2}'`"

echo ${PWD_BSCS}
[ -z "${PWD_BSCS}" -o -z "${USR_BSCS}" ] && exit 1

#     Inicializacao da variael de Controle de Erros
MsgErro=""

# MAIN

#   Validacao de Varaiveis de Chamada!!
case $#
in 
    3) # Qtde de PARMS OK   
      case $1
      in
        0[12345789]|1[01234567]) # Num. CICLO Correto..........
                              BILLCYCLE=$1
                              ;;
                           *) #  Valor de CICLO Invalido....
                              MsgErro="ERRO: Billcycle [$1] invalido"
                              RC=70
                              ;;
      esac

      DOC_ALL_CYCLE=${BILLCYCLE}

      case "$2" 
      in
         COMMIT) BILLCG="-"
                 COMMIT=0
                 DOC_ALL_CYCLE="${BILLCYCLE}"
                 #---------------------------------#
                 # Verifica se dt sis < dt cort    #
                 #---------------------------------#
                 FILE_AUTH_BCH="${DIR_AUTH}/CYCLE-${BILLCYCLE}.flg"
                 DC="`sed -n '3p' ${FILE_AUTH_BCH} |cut -c 1-8`"
                 DS="`date +%Y%m%d`"
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
                       MsgErro="A Data do Sistema e menor que a Data de Corte!!!!\n\t DATA DO SISTEMA: ${DS}\n\t DATA DE CORTE: ${DC}\n Verificar se solicitacao e para execurar COMMIT"
                       F_ValidaRc "1" "${MsgErro}"
                   else
                       echo 'Data do SISTEMA confere com a data de CORTE'
                 fi
		 echo "Inicio do BCH para o CICLO ${BILLCYCLE} - `date`" |mailx -s "Inicio do BCH para o CICLO ${BILLCYCLE}" renato.silveira@nextel.com.br,rafael.toniete@nextel.com.br
		 MAIL_COMMIT="1"
                 ;;
             CG) BILLCG="CG"
                 DOC_ALL_CYCLE="${BILLCYCLE}"
                 ;;
          [A-R]) BILLCG="cg $2"
                 DOC_ALL_CYCLE="05"
                 ;;
              *) echo "ERRO: Control Group [$2] invalido"
                 exit 1
                 ;;
      esac

      FORCEDATEVENC=$3
      ;;

   *) #  Erro na Qtde de Parametros
      MsgErro="ERRO: Qtde de PARMS de chamada invalida!!"
      RC=90
      ;;
esac

MsgErro="${MsgErro}\n Sintaxe:\n   BSCS_RUN_BCH-NEW.sh <CICLO> <Grupo de CG [A-O]> <Forca data Venc??>"
F_ValidaRc $RC "${MsgErro}"

#  Carrega variaveis com nome dos arquivos de LIBERACAO de CICLO.
FILE_AUTH="${DIR_AUTH}/CYCLE-${BILLCYCLE}.flg"

#  Verifica se os arquivos de liberacao do CICLO (BCH e BGH) estao disponiveis.
[  -f ${FILE_AUTH} ]
RC=$?

MsgErro="Nao existe(m) Arquivo(s) de liberacao de CICLO!!!!!!! \n `ls -ltr ${FILE_AUTH}`"
F_ValidaRc $RC "${MsgErro}"

chmod 666 ${FILE_AUTH}

#  Verifica se o SYNONYM DOCUMENT_ALL esta associado a DOC_ALL_<CICLO> do ciclo em processamento.
/amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${LOC_LOGIN_PDBSC_BCH2}" "/amb/operator/cfg/check_ciclo_syn_doc.sql ${DOC_ALL_CYCLE}" prod@unix_mail_fwd  "Verifica se SYSNONYM esta associado a DOCUMENT_ALL do CICLO: ${BILLCYCLE} em processamento" 0  BILLING_BCH 0
RC=$?

MsgErro="CICLO da Document_ALL do SYNONYM e incompativel com Ciclo de Processamento!!! Verificar LOG!!"
F_ValidaRc $RC "${MsgErro}"

#  Extracao de data Inicio, data Fim e Data de Vencimento do arq. de lib. do BGH
#  no formato DDMMAA.
DI="`sed -n '2p' ${FILE_AUTH}`"
DV="`sed -n '4p' ${FILE_AUTH}`"

#  Extracao de data Vencimento para as Faturas do CICLO no aq. de lib. do BCH
DC="`sed -n '3p' ${FILE_AUTH}`"

echo "
   #=======================================================#
   # Display das datas encontradas no Arq. Flag BCH:       #
   #       Data Corte :  ${DC}                             #
   # Display das datas encontradas no Arq. Flag BGH:       #
   #       Data Inicio: ${DI}                              #
   #       Data Vencto: ${DV}                              #
   #=======================================================#\n"

BILLIND="${BILLCYCLE}"

BchDataVenc="`echo ${DV} | cut -c 3-8`"

#  Verifica se a variavel de Data de Venc. p/ Fatura tem conteudo....
[ ! -z "${BchDataVenc}" ]
RC=$?

MsgErro="Variavel com data de vencimento de Faturas esta com erro!!!\n Motivo:\n     A variavel BchDataVenc...........: ${BchDataVenc} Nao tem valor atribuido!!!\n     Conteudo da variavel BILLCYCLE...: ${BILLCYCLE}"

F_ValidaRc $RC "${MsgErro}"

echo "
   #=======================================================#
   # Display das datas de Vencimento atribuida ao CICLO ${BILLCYCLE} #
   # Apos inversao de campos (de DDMMAA - formato Arq. Flg #
   # para AAMMDD - formato BCH}                            #
   #       Data Vencto: ${BchDataVenc}                             #
   #=======================================================#\n"
   

#  Cria Variavel com Data Atual + Num dias (minimo) p/ comparacao c/ Data Venc
NumDiasMinimo=10
DataVencRef="`/amb/eventbin/CALC_DATE.sh ${NumDiasMinimo} | awk '{print substr($1,7,2) substr($1,3,2) substr($1,1,2)}'`"

echo "
    #=======================================================#
    #       Data Vencto..........: ${BchDataVenc}                  
    #       Data Minima Calculada: ${DataVencRef}       
    #=======================================================#\n"


[ "${BchDataVenc}" -lt "${DataVencRef}" -a "${FORCEDATEVENC}" != "S" ]  && RC=99 || RC=0

MsgErro="Data de Vencimento da Fatura inferior ao limite minimo de dias da data de criacao!!!! Data Venc: ${BchDataVenc} Data de Referencia (Minima): ${DataVencRef} Num de dias minimos para tolerancia : ${NumDiasMinimo}"

F_ValidaRc $RC "${MsgErro}"

# Atualiza Tabela MPSCFTAB
$ORACLE_HOME/bin/sqlplus -s ${USR_BSCS}/${PWD_BSCS} <<EOF > $ARQTMP
UPDATE MPSCFTAB SET CFVALUE='-F -v -W -t $DC' WHERE CFCODE=23;
COMMIT;
EOF
RC=$?
MsgErro="Nao foi possivel atualizar a data de corte na tabela MPSCFTAB: data=${DC}"
F_ValidaRc ${RC} "${MsgErro}"

#------------------------------------
# Executa Update para acertar OHXACT
# Incluido pela CHANGE 5668
# Rafael Toniete - 14/02/2006
#------------------------------------
if [ "${CHK_MODO}" = "COMMIT" ]
then
    echo "\nINFORMACAO: Executando UPDATE do numero da INVOICE (USERLBL) - CICLO: ${BILLCYCLE}\n\n"
    su - sched -c "/amb/eventbin/acerta_ohxact.sh ${BILLCYCLE}"
    RC=$?
    MsgErro="\n\n\nERRO no UPDATE do numero da INVOICE (USERLBL) - CICLO: ${BILLCYCLE}\n\n\n"
    F_ValidaRc ${RC} "${MsgErro}"
fi

#  Monta variavel com comando de execucao do BCH.
BCHBIN[$BILLIND]="pbch $BCHINSTANCES $BILLCYCLE - - ${BchDataVenc} $BILLCG"

#  Confere se a data de corte da tabela mpscftab esta coerente com a data de
#  corte encontrada no arq. de liberacao do ciclo.  
#$ORACLE_HOME/bin/sqlplus -s $USUARIO <<EOF | grep ^[0-9] | tr -d ' ' > $ARQTMP
#  set heading off
#  select substr(cfvalue,instr(cfvalue,'-t')+3,6) from mpscftab where cfcode=23;
#EOF
$ORACLE_HOME/bin/sqlplus -s $USUARIO <<EOF | grep ^[0-9] | tr -d ' ' > $ARQTMP
  set heading off
  select substr(cfvalue,instr(cfvalue,'-t')+3) from mpscftab where cfcode=23;
EOF

DataCorteMpscftab="`cat $ARQTMP | awk '{ print $1 }'`"

echo "BSCS BILLING PROCESS - BCH - $DATA"
echo "------------------------------------------------------------------\n"
printf "%-20s : %-30s\n"   "BILL CYCLE                 " $BILLCYCLE
printf "%-20s : %-30s\n\n" "DATA DE VENCIMENTO         " ${BchDataVenc}
printf "%-20s : %-30s\n\n" "COMANDO EXECUTADO          " "${BCHBIN[$BILLIND]}"
printf "%-20s : %-30s\n\n" "DATA DE FECHO NA MPSCFTAB  " "${DataCorteMpscftab}"
echo "------------------------------------------------------------------\n"

[ "${DC}" != "${DataCorteMpscftab}" ] && RC=98

MsgErro="Data de Corte do Ciclo detectada no Arquivo de liberacao do Billing difere da data de COrte na MPSCFTAB!!\n   Data Liberacao: ${DC} Data da MPSCFTAB: ${DataCorteMpscftab}"
F_ValidaRc $RC "${MsgErro}"

echo " DATA/HORA antes dos UPDATES de GEOCODE do BILLING: `date`"

#
# Correcao do GEOCODE de CLIENTES no BSCS por motivo de anomalia no KV (permite entrada de CEOCODES INCORRETOS).
# (BUG SEMA - KV).

/amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${LOC_LOGIN_PDBSC_BCH2}" "/amb/scripts/sql/sql_bscs_bch_update_geocode.sql" prod@unix_mail_fwd  "UPDATE de GEOCODE no BSCS - CICLO: ${BILLCYCLE}" 0  BILLING_BCH_UPDT_GEOCODE ~prod/WORK/TMP/log_delecao_retencao.$BILLCYCLE

RC=$?

echo " DATA/HORA apos os UPDATES de GEOCODE do BILLING e antes do BCH: `date`"

MsgErro="Processo de UPDATE Correcao do GEOCODE na BASE do BSCS (BUG - KV) \n `cat ~prod/WORK/TMP/log_delecao_retencao.$BILLCYCLE \n STATUS CODE DO SQLPLUS:  $RC "

F_ValidaRc $RC "${MsgErro}"

(
  date
  echo "\n------------------------------------------------------------------"

  echo "------------------------------------------------------------------"
  echo "Executando comando com o cron"
#----------
# Anterado em 13/04/04 por Rafael Toniete - CHANGE 2037
# Alteracao devido a um BUG do BCH que calcula uma hora a mais no time zone,
# a alteracao do programa ja foi solicitada, mas para evitar erros enquanto
# novo programa nao chega, deve ser incluido um export do TZ
#----------
  #echo "export TZ=EST" > $ARQTMP
  #########################################################################
  #echo "su - prod -c \"export TZ=EST; ${BCHBIN[$BILLIND]}\"" >> $ARQTMP
  #
  # Alterado devido ao novo bch recebido no dia 30/11/2006 e colocado
  # em produgco no dia 03/12/2006
  # o parametro BCH_TRACE_CONTRACTS_00280248=1 habilita mais infomagues
  # nos arquivos de log do bch
  #########################################################################
  echo "su - prod -c \"export TZ=EST; export BCH_TRACE_CONTRACTS_00280248=1; ${BCHBIN[$BILLIND]}\"" >> $ARQTMP
  cat $ARQTMP
  echo "------------------------------------------------------------------"
  batch < $ARQTMP 2>&1

  sleep 60

 # Aguarda termino do processo

  EMAIL="billing@unix_mail_fwd"
  DIR="${ENV_DIR_BASE_RTX}/prod/WORK/LOG"

  while true
  do 
    AUX=`ps -ef | grep pbch | grep -v grep`
    [ -z "$AUX" ] && break || sleep 5

    ############# VERIFICACAO DE ARQUIVO DE LOG #####################
    ############# MARCOS DE BENEDICTO 16/03/2004  #####################

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

    if [ "${FLG}" -eq "0" ]
    then
	set +x
	ARQ_BCHLOG=`ls -rt ${DIR}/BCH*.log | tail -1`
	set -x
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
		|   Foram encontrados erros no log de BCH - CICLO ${BILLCYCLE}.
		|   Arquivo de LOG = ${ARQ_BCHLOG}
		|
		|   MSG DE ERRO = `grep "FATAL" ${ARQ_BCHLOG}`
		|
		+-----------------------------------------------------\n" | tee -a /tmp/mail$$.txt
            set -x
            cat /tmp/mail$$.txt | mailx -m -s "BCH - Encontrado FATAL ERROR no log." ${EMAIL}
            cat /tmp/mail$$.txt | mailx -m -s "BCH - Encontrado FATAL ERROR no log." prodmsol@nextel.com.br

          #Para processo do BCH.

            for PROC in `ps -ef | egrep "pbch|bch" | grep -v egrep | awk '{print $2}'`
            do
               kill -9 $PROC
            done

            exit 1
        fi
    fi

  done

  ############# VERIFICACAO DE ARQUIVO DE LOG   #####################
  ############# MARCOS DE BENEDICTO 16/03/2004  #####################
  echo "\n------------------------------------------------------------------"
  echo "Processo Terminado em: "`date`
  echo "------------------------------------------------------------------"
) > $ARQTMP1

RC=$?

echo " DATA/HORA apos o BCH: `date`"

sleep 3
cat   $ARQTMP1

/amb/bin/msg_api2  "W-BILLING-BCH-PROCESSAMENTO" <$ARQTMP1

rm -f $ARQTMP $ARQTMP1

# Executa Analise de log	
/amb/eventbin/BILLING_01_02.sh $BILLCYCLE

RC=`expr $RC + $?`

if [ "$RC" = "0" ] 
then
   echo "Criando BACKUP do arquivo de liberacao...."

   cp ${FILE_AUTH}  /tmp/

   if [ $? -eq 0 ]
   then
      echo "
          Removendo arq. de liberacao....... \n
          Em caso de necessidade de Restart do BCH, apos a remocao
          do arquivo de liberacao,  basta executar o CMD: 
          cp /tmp/`basename ${FILE_AUTH}` ${FILE_AUTH}\n"
   else
      echo "
           \t ******************** ATENCAO ********************\n
           \t Ocorreu erro na Criacao do BKP do Arquivo de LIberacao.
           \t A copia:  cp ${FILE_AUTH}  /tmp/ 
           \t deve ser realizada manualmente!!!
           \t Caso o BCH tenha executado satisfatoriamente, o arq.:
           \t  ${FILE_AUTH} \n
           \t deve ser removido Manualmente. Deve ser dada sequencia
           \t ao processamento do FLUXO e a equipe de implantacao
           \t deve ser comunicada em horario comercial....\n
           \t Caso o BCH tenha executado com sucesso, comunicar analista
           \t responsavel imediatamente!!!!!
           \t Caso o BCH tenha executado com sucesso, comunicar analista
           \t responsavel imediatamente!!!!!
           \t Caso o BCH tenha executado com sucesso, comunicar analista
           \t responsavel imediatamente!!!!!
           "
      RC=99
   fi
fi 

RC=`expr $RC + $?`

[ "${MAIL_COMMIT}" -eq 1 ] && echo "Fim do BCH para o CICLO ${BILLCYCLE} - `date`" |mailx -s "Fim do BCH para o CICLO ${BILLCYCLE}" renato.silveira@nextel.com.br,rafael.toniete@nextel.com.br

echo "
  *----------------------------------------------------------*
  |  Data/Hora do END .....: `date`
  *----------------------------------------------------------* "

exit $RC
