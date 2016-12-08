#!/bin/ksh
# 
# UMH
# BSCS_RUN_UMH.sh
#
# Criado : Marcos de Benedicto 28/04/2004
#

. /etc/appltab

# VARIABLES

DATA="`date`"
ARQTMP="/tmp/.umh_$$"
LOG_ARQTMP="/tmp/.umh_$$.log"
LOG="/tmp/umh_`date +%Y_%m_%d_%H:%M`.log"

# MAIN

EXEC_UMH_COMMAND="umh -t"


clear
echo "BSCS UTX MANIPULATION HANDLER - UMH - ${DATA}"
echo
echo "Comando: ${EXEC_UMH_COMMAND}"
echo "------------------------------------------------------------------"
echo

su - prod -c "(
echo '\n  ------------------------------------------------------------------'
echo '  Executando comando: ${EXEC_UMH_COMMAND}'
echo '   INICIO - `date +%H:%M:%S`'
echo '  ------------------------------------------------------------------\n'

export ORACLE_HOME="${ENV_DIR_ORAHOME_BSC}"
export SHLIB_PATH="${ENV_DIR_ORAHOME_BSC}/lib"
export LD_LIBRARY_PATH="${ENV_DIR_ORAHOME_BSC}/lib"

${EXEC_UMH_COMMAND}

RC=${?}
echo '\n  ------------------------------------------------------------------'
echo '  Termino do comando: ${EXEC_UMH_COMMAND}'
echo '   FIM - `date +%H:%M:%S`'
echo '   Codigo retornado: ${RC}'
echo '  ------------------------------------------------------------------\n'
exit ${RC}
)" > ${ARQTMP}

if [ $? -ne 0 ]
then
    banner ERRO!!
    echo "\n -----------------------------------------------"
    echo "  ERRO na execucao do UMH.\n"
    echo "\n  Vide LOG abaixo."
    echo " -----------------------------------------------\n"
    cat ${ARQTMP}
    exit 43
fi

cp ${ARQTMP} ${LOG}

cat ${ARQTMP}
cat ${ARQTMP} > ${LOG_ARQTMP}
grep "Fatal error" ${LOG_ARQTMP}
if [ $? = 0 ]
   then
       banner ATENCAO!!!
       echo "\n -----------------------------------------------"
       echo "  Encontrada mensagem de ERRO na LOG do UMH!!\n"
       echo "  Mensagem: Fatal error in Aplication"
       echo "\n  Vide LOG acima."
       echo " -----------------------------------------------\n"
       exit 44
fi

su - sched -c "/amb/eventbin/CHECK_UMH.sh"
[ "${?}" -ne 0 ] && exit 1

[ -f ${ARQTMP} ] && rm -f ${ARQTMP} 

exit 0 
