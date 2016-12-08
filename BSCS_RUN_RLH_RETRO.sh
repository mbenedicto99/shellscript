#!/bin/ksh
#
# bscs_run_rlh_all
#
# Executa todos os ciclos do Site simultaneamente
#
# Alterado em 22/06/2002 - Alex da Rocha Lima
#
# Alterado em 06/01/2003 - Fabio Cesar
#                          Incluido processo para o Ciclo RJ07
#
#


ARQCFG=/amb/operator/cfg/bscs_batch.cfg
SCPFUNC=/amb/operator/cfg/script_functions.cfg

#-----------------------------
# Le arquivo de paramentros
#-----------------------------
. $ARQCFG

#-----------------------------
# Carrega variaveis
#-----------------------------
. /etc/appltab

if [ ${#} -ne 2 ]
then
    echo "ERRO: Parametros incorretos!!!"
    echo "      USE: ${0} <CICLO> <DATA -1>"
    exit 1
else
    CICLO=${1}
    DATA_RETRO=${2}
fi

if [ -f "${ENV_DIR_BASE_RTX}/prod/WORK/TMP/BILL-CG${CICLO}.flg" ]
then
    echo "INFO: Envontrada FLAG de execucao do CG do CICLO ${CICLO}. Executando BYPASS do RLH."
    exit 0
fi

#DATE_08="`date +%Y%m%d`"
#[ "${CICLO}" -eq 08 -a "${DATE_08}" -eq 20061228 ] && exit 0
#[ "${CICLO}" -eq 08 -a "${DATE_08}" -eq 20061229 ] && exit 0
#[ "${CICLO}" -eq 08 -a "${DATE_08}" -eq 20061230 ] && exit 0
#[ "${CICLO}" -eq 08 -a "${DATE_08}" -eq 20061231 ] && exit 0

ARQTMP=/tmp/.rlh_$$
ARQTMP1=/tmp/.rlh1_$$
DATA=`date`
DIRBASE=${ENV_DIR_BASE_RTX}/prod/WORK
DIRWORK=${DIRBASE}/MP/RTX/HPLMN

#-----------------------------
# Carrega arquivo de funcoes utilitarias
#-----------------------------
. $SCPFUNC         

export TWO_TASK="${ENV_TNS_PDRTX}"
ARQ_PASSWD=${ENV_DIR_BASE_RTX}/prod/batch/bin/bscs.passwd
export ORACLE_HOME="${ENV_DIR_ORAHOME_RTX}"

LD_LIBRARY_PATH=$ORACLE_HOME/lib;  export LD_LIBRARY_PATH
ORACLE_PATH=$ORACLE_HOME/bin; export ORACLE_PATH
ORA_NLS32=$ORACLE_HOME/ocommon/nls/admin/data
export NLS_LANG="${ENV_NLSLANG_PDRTX}"
ARQAUX=/tmp/rlh_$$.sql
ARQTMP_UPD="/tmp/arp_upd$$.txt"

PASSWD=`awk '/^RLH/ {print $2}' ${ARQ_PASSWD}`
CICLO=${1}
DATA_RETROATIVO=${2}
SQL_UPDATE=/tmp/sqlupdate_${CICLO}.sql

#-----------------------------
# Valida se ciclo informado eh valido
#-----------------------------
case ${CICLO}
in
  0[1-9]|1[0-7]) echo "INFO: Ciclo Definido corretamente!! Ciclo: ${CICLO}"
                 ;;
              *) echo "ERRO: Valor de ciclo invalido !!!!! Ciclo: ${CICLO}"
                 echo "ERRO: Valores validos para ciclo: 01-17 "
                 exit 99
                 ;;
esac


#-----------------------------
#  LIMPEZA DA RTXCYTAB
#-----------------------------
echo "
UPDATE RTXCYTAB set rlh_pid=null where BILLCYCLE = '${CICLO}';" >${SQL_UPDATE}

chmod 777 ${SQL_UPDATE}

${ORACLE_HOME}/bin/sqlplus RLH/${PASSWD}@${TWO_TASK} @${SQL_UPDATE} >${ARQTMP_UPD} 2>&1

echo "\n\n===========OUT=============="
cat ${ARQTMP_UPD}
echo "===========OUT==============\n\n"

[ ${?} -ne 0 ] && exit 1

LOG_DATE=`date +%d%m%Y`
LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
LOG_TIME="${ENV_DIR_BASE_RTX}/prod/reports/RLH_${LOG_DATE}.txt"
COUNT_TIME=`find ${ENV_DIR_BASE_RTX}/prod/WORK/MP/RTX/HPLMN/BC${CICLO}* -name RTX* 2>/dev/null | wc -l`

printf "%s\t%s\t%s\t%s\n" "RLH_BC${CICLO}" "Inicio do processamento, ${COUNT_TIME} arquivos RTX." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

clear
echo "RATING LOAD HANDLER - RLH ALL - ${DATA}"
echo "------------------------------------------------------------------"
echo
printf "%-20s - %-30s\n\n" "BILL CYCLE - ${CICLO}" 
echo "------------------------------------------------------------------"
echo


(
cd $DIRWORK
if [ $? != 0 ] ; then
   echo "erro no cd $DIRWORK !"
   exit 0
fi
date

TEMPO_ALARME_START=$(date +%H%M)

echo
echo "------------------------------------------------------------------"
echo "Aguarde, contando RTX ."
echo "Inicio da contagem dos RTX do Ciclo ${CICLO} : `date`"
echo "Volume em Kb : \c"
du -ks .
echo "Final da contagem dos RTX : `date`"
   
      su - prod -c "/amb/operator/bin/run_rlh_retro ${CICLO} ${DATA_RETRO}"
      echo "disparado rlh para ciclo ${CICLO}"

echo "Aguardando termino dos processos..."
sleep 60
continua=1
while [ $continua -gt 0 ] 
do
  echo "Aguardando termino dos processos..."
     BC1=`ls BC${CICLO} | wc -l`
     [ ${BC1} -eq 0 ] && rm -f ${DIRBASE}/CTRL/*BC${CICLO}*
     let continua=BC1
     #------------------------
     # Incluido para enviar mensagem de tempo de execucao excedido
     #------------------------
     #PS_RLH=$(ps -ef |grep "rlh -${CICLO} -a -t" |grep -v grep |wc -l)

     TEMPO_ALARME=$(date +%H%M)
     NUM_MAIL=0
     
     if [ ${TEMPO_ALARME} -ge 0900 -a ${TEMPO_ALARME} -le 2359 -a ${NUM_MAIL} -eq 0 ]
     then
         TEMPO_ALARME_DIFF=$(expr ${TEMPO_ALARME} - ${TEMPO_ALARME_START})

         case ${CICLO} in
                         01|02|04|11|12|13|14)
					      if [ ${TEMPO_ALARME_DIFF} -ge 100 ]
					      then
        				          echo "RLHC${CICLO}_C esta executando a mais de 1 hora. Favor acionar Analista responsavel." |mailx -s "RLHC${CICLO}_C esta executando a mais de 1 hora. Favor acionar Analista responsavel." podmsol@nextel.com.br
						  NUM_MAIL=1
                                              fi
                                       	      ;;
                                     09|10|15)
					      if [ ${TEMPO_ALARME_DIFF} -ge 30 ]
					      then
                                                  echo "RLHC${CICLO}_C esta executando a mais de 30 minutos. Favor acionar Analista responsavel." |mailx -s "RLHC${CICLO}_C esta executando a mais de 30 minutos. Favor acionar Analista responsavel." podmsol@nextel.com.br
						  NUM_MAIL=1
                                              fi
                                              ;;
                            03|05|07|08|16|17)
					      if [ ${TEMPO_ALARME_DIFF} -ge 40 ]
					      then
                                                  echo "RLHC${CICLO}_C esta executando a mais de 40 minutos. Favor acionar Analista responsavel." |mailx -s "RLHC${CICLO}_C esta executando a mais de 40 minutos. Favor acionar Analista responsavel." podmsol@nextel.com.br
						  NUM_MAIL=1
                                              fi
                                              ;;
         esac
     fi
  sleep 30
done

echo "Termino dos processos do RLH !"
echo "Iniciado o processo de analise dos logs gerados"

) > $ARQTMP1

cat $ARQTMP1

LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
COUNT_TIME=`find ${ENV_DIR_BASE_RTX}/prod/WORK/MP/RTX/HPLMN/BC${CICLO}* -name RTX* 2>/dev/null | wc -l`

printf "%s\t%s\t%s\t%s\n" "RLH_BC${CICLO}" "Termino do processamento, ${COUNT_TIME} arquivos RTX." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}


/amb/bin/msg_api2 "W-RATING-RLH-PROCESSAMENTO_${CICLO}" <$ARQTMP1


# Executa valor_land_celular


if [ $? != 0 ]; then
   ( echo "$0: Erro ao criar o SQL $ARQAUX"
     cat $ARQTMP ) | msg_api2 "E-RATING-RLH-LAND_CELULAR"
     echo "$0: Erro ao criar o SQL $ARQAUX"
     cat $ARQTMP
   rm -f $ARQTMP $ARQAUX $ARQTMP1
   exit 1
fi

if [ ! -f "$ARQ_PASSWD" ]; then
   echo "$0: Arquivo de senhas não encontrado" | msg_api2 E-RATING-RLH-LAND_CELULAR
   echo "$0: Arquivo de senhas não encontrado" 
   rm -f $ARQTMP $ARQAUX $ARQTMP1
   exit 1
fi

RLH_PASSWD=`awk '/^RLH[         ]/ { a=$2; } END { print a }' $ARQ_PASSWD`
if [ -z "$RLH_PASSWD" ]; then
   echo "$0: Senha do usuário RLH não encontrada" | msg_api2 E-RATING-RLH-LAND_CELULAR
   rm -f $ARQTMP $ARQAUX $ARQTMP1
   exit 1
fi

echo
echo "Executando ... valor_land_celular"
echo

ret=0

if [ $ret = 0 ]; then
   ( echo "Sucesso no valor_land_celular"
     cat $ARQTMP ) | msg_api2 "I-RATING-RLH-LAND_CELULAR"
     echo "Sucesso no valor_land_celular"
     cat $ARQTMP
else
   ( echo "Erro no valor_land_celular"
     cat $ARQTMP ) | msg_api2 "E-RATING-RLH-LAND_CELULAR"
     echo "Erro no valor_land_celular"
     cat $ARQTMP 
     exit 44	
fi

rm -f $ARQTMP $ARQTMP1 $ARQTMP_UPD

exit 0 
