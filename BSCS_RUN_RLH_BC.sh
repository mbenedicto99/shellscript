#!/bin/ksh

	# Finalidade	: Executar RLH por BILLCYCLE.
	# Input		: BSCS_RUN_RLH.sh
	# Output	: PRH e SRH
	# Alteracao	: Marcos de Benedicto
	# Data		: 03/11/2003


ARQCFG=/amb/operator/cfg/bscs_batch.cfg
SCPFUNC=/amb/operator/cfg/script_functions.cfg

# Le arquivo de paramentros
. $ARQCFG

# VARIABLES

. /etc/appltab


ARQTMP=/tmp/.rlh_$$
ARQTMP1=/tmp/.rlh1_$$
DATA=`date`
#DIRBASE=/artx_${SITE}/prod/WORK
DIRBASE=${ENV_DIR_BASE_RTX}/prod/WORK
DIRWORK=${DIRBASE}/MP/RTX/HPLMN

BILLCYCLE=$1

	if [ -z "${BILLCYCLE}" ]
	then
	set +x
	echo "
	+------------------------------------------------
	|
	|   ERRO!
	|   `date`
	|   Nao foi informado o BILL CICLE.
	|    
	|    BSCS_RUN_RLH_BC.sh 'BILLCICLE'
	|
	+------------------------------------------------\n"
	exit 1
	fi

# FUNCTIONS

# Carrega arquivo de funcoes utilitarias

. $SCPFUNC         

# MAIN



export TWO_TASK="${ENV_TNS_PDRTX}"
ARQ_PASSWD=${ENV_DIR_BASE_RTX}/prod/batch/bin/bscs.passwd
export ORACLE_HOME="${ENV_DIR_ORAHOME_RTX}"

LD_LIBRARY_PATH=$ORACLE_HOME/lib;  export LD_LIBRARY_PATH
ORACLE_PATH=$ORACLE_HOME/bin; export ORACLE_PATH
ORA_NLS32=$ORACLE_HOME/ocommon/nls/admin/data
export NLS_LANG="${ENV_NLSLANG_PDRTX}"
ARQAUX=/tmp/rlh_$$.sql
SQL_UPDATE=/tmp/sqlupdate.sql

PASSWD=`awk '/^RLH/ {print $2}' ${ARQ_PASSWD}`

echo "
UPDATE RTXCYTAB set rlh_pid=null;" >${SQL}

chmod 777 ${SQL_UPDATE}

${ORACLE_HOME}/bin/sqlplus RLH/${PASSWD}@${TWO_TASK} @${SQL_UPDATE} >$ARQTMP 2>&1
ret=$?

	[ ${ret} -ne 0 ] && exit 1


LOG_DATE=`date +%d%m%Y`
LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
LOG_TIME="${ENV_DIR_BASE_RTX}/prod/reports/RLH_${LOG_DATE}.txt"
COUNT_TIME=`find ${ENV_DIR_BASE_RTX}/prod/WORK/MP/RTX/HPLMN/BC* -name RTX* 2>/dev/null | wc -l`

printf "%s\t%s\t%s\t%s\n" "RLH_BC" "Inicio do processamento, ${COUNT_TIME} arquivos RTX." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

clear
echo "RATING LOAD HANDLER - RLH ALL - $DATA"
echo "------------------------------------------------------------------"
echo
printf "%-20s - %-30s\n\n" "BILL CYCLE - TODOS" 
echo "------------------------------------------------------------------"
echo


(

cd $DIRWORK
[ `pwd` != $DIRWORK ] && exit 1

date
echo
echo "------------------------------------------------------------------"
echo "Aguarde, contando RTX ."
echo "Inicio da contagem dos RTX : `date`"
echo "Volume em Kb : \c"
du -ks .
echo "Final da contagem dos RTX : `date`"
 
 #==========================================================
 #             INICIO DO RLH
 #==========================================================

      su - prod -c "/amb/operator/bin/run_rlh ${BILLCYCLE}"
      echo "disparado rlh para ciclo ${BILLCYCLE}"

echo "Aguardando termino dos processos..."
  
  sleep 120 


echo "Termino dos processos do RLH !"
echo "Iniciado o processo de analise dos logs gerados"

) > $ARQTMP1

cat $ARQTMP1

LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
COUNT_TIME=`find ${ENV_DIR_BASE_RTX}/prod/WORK/MP/RTX/HPLMN/BC* -name RTX* 2>/dev/null | wc -l`

printf "%s\t%s\t%s\t%s\n" "RLH_BC" "Termino do processamento, ${COUNT_TIME} arquivos RTX." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}


/amb/bin/msg_api2 "W-RATING-RLH-PROCESSAMENTO" <$ARQTMP1



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

rm -f $ARQTMP $ARQTMP1

