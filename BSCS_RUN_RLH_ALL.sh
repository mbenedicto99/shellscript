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

# Le arquivo de paramentros
. $ARQCFG

# VARIABLES

. /etc/appltab


ARQTMP=/tmp/.rlh_$$
ARQTMP1=/tmp/.rlh1_$$
DATA=`date`
DIRBASE=${ENV_DIR_BASE_RTX}/prod/WORK
DIRWORK=${DIRBASE}/MP/RTX/HPLMN

# FUNCTIONS

# Carrega arquivo de funcoes utilitarias

. $SCPFUNC         

export TWO_TASK="${ENV_TNS_PDRTX}"
ARQ_PASSWD=${ENV_DIR_BASE_RTX}/prod/batch/bin/bscs.passwd
export ORACLE_HOME="${ENV_DIR_ORAHOME_RTX}"

LD_LIBRARY_PATH=$ORACLE_HOME/lib;  export LD_LIBRARY_PATH
ORACLE_PATH=$ORACLE_HOME/bin; export ORACLE_PATH
ORA_NLS32=$ORACLE_HOME/ocommon/nls/admin/data
export NLS_LANG="${ENV_NLSLANG_PDRTX}"
ARQAUX=/tmp/rlh_$$.sql
SQL_UPDATE=/tmp/sqlupdate.sql
ARQTMP_UPD=/tmp/arp_upd$$.txt

PASSWD=`awk '/^RLH/ {print $2}' ${ARQ_PASSWD}`

#====================================================
#  LIMPEZA DA RTXCYTAB
#====================================================
echo "
UPDATE RTXCYTAB set rlh_pid=null;" >${SQL_UPDATE}

chmod 777 ${SQL_UPDATE}

${ORACLE_HOME}/bin/sqlplus RLH/${PASSWD}@${TWO_TASK} @${SQL_UPDATE} >$ARQTMP_UPD 2>&1

echo "===========OUT=============="
cat ${ARQTMP}
echo "===========OUT=============="

	[ $? -ne 0 ] && exit 1

#====================================================
#  LIMPEZA DA RTXCYTAB
#====================================================

LOG_DATE=`date +%d%m%Y`
LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
LOG_TIME="${ENV_DIR_BASE_RTX}/prod/reports/RLH_${LOG_DATE}.txt"
COUNT_TIME=`find ${ENV_DIR_BASE_RTX}/prod/WORK/MP/RTX/HPLMN/BC* -name RTX* 2>/dev/null | wc -l`

printf "%s\t%s\t%s\t%s\n" "RLH_ALL" "Inicio do processamento, ${COUNT_TIME} arquivos RTX." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

clear
echo "RATING LOAD HANDLER - RLH ALL - $DATA"
echo "------------------------------------------------------------------"
echo
printf "%-20s - %-30s\n\n" "BILL CYCLE - TODOS" 
echo "------------------------------------------------------------------"
echo


(
cd $DIRWORK
if [ $? != 0 ] ; then
   echo "erro no cd $DIRWORK !"
   exit 0
fi
date
echo
echo "------------------------------------------------------------------"
echo "Aguarde, contando RTX ."
echo "Inicio da contagem dos RTX : `date`"
echo "Volume em Kb : \c"
du -ks .
echo "Final da contagem dos RTX : `date`"
   
   for bc in 01 02 03 04 05 07 08 10 11 12 13 14 
   do
      su - prod -c "/amb/operator/bin/run_rlh $bc"
      echo "disparado rlh para ciclo $bc"
   done
echo "Aguardando termino dos processos..."
sleep 60
continua=1
while [ $continua -gt 0 ] 
do
  echo "Aguardando termino dos processos..."
     BC1=`ls BC01 | wc -l`;[ $BC1 -eq 0 ] && rm -f ${DIRBASE}/CTRL/*BC01*
     BC2=`ls BC02 | wc -l`;[ $BC2 -eq 0 ] && rm -f ${DIRBASE}/CTRL/*BC02*
     BC3=`ls BC03 | wc -l`;[ $BC3 -eq 0 ] && rm -f ${DIRBASE}/CTRL/*BC03*
     BC4=`ls BC04 | wc -l`;[ $BC4 -eq 0 ] && rm -f ${DIRBASE}/CTRL/*BC04*
     BC5=`ls BC05 | wc -l`;[ $BC5 -eq 0 ] && rm -f ${DIRBASE}/CTRL/*BC05*
     BC7=`ls BC07 | wc -l`;[ $BC7 -eq 0 ] && rm -f ${DIRBASE}/CTRL/*BC07*
     BC8=`ls BC08 | wc -l`;[ $BC8 -eq 0 ] && rm -f ${DIRBASE}/CTRL/*BC08*
     BC10=`ls BC10 | wc -l`;[ $BC10 -eq 0 ] && rm -f ${DIRBASE}/CTRL/*BC10*
     BC11=`ls BC11 | wc -l`;[ $BC11 -eq 0 ] && rm -f ${DIRBASE}/CTRL/*BC11*
     BC12=`ls BC12 | wc -l`;[ $BC12 -eq 0 ] && rm -f ${DIRBASE}/CTRL/*BC12*
     BC13=`ls BC13 | wc -l`;[ $BC13 -eq 0 ] && rm -f ${DIRBASE}/CTRL/*BC13*
     BC14=`ls BC14 | wc -l`;[ $BC14 -eq 0 ] && rm -f ${DIRBASE}/CTRL/*BC14*
     let continua=BC1+BC2+BC3+BC4+BC5+BC7+BC8+BC10+BC11+BC12+BC13+BC14
  sleep 30
done


echo "Termino dos processos do RLH !"
echo "Iniciado o processo de analise dos logs gerados"

) > $ARQTMP1

cat $ARQTMP1

LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
COUNT_TIME=`find ${ENV_DIR_BASE_RTX}/prod/WORK/MP/RTX/HPLMN/BC* -name RTX* 2>/dev/null | wc -l`

printf "%s\t%s\t%s\t%s\n" "RLH_ALL" "Termino do processamento, ${COUNT_TIME} arquivos RTX." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}


/amb/bin/msg_api2 "W-RATING-RLH-PROCESSAMENTO" <$ARQTMP1


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
