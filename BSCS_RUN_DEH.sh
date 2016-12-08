#!/bin/ksh
#
# Alteracao 14/06/2002
# Alex da Rocha Lima
#
# Alteracao 08/04/2003
# Sinclair Iyama - Analista de Sistemas Billing - Nextel Telecomunicacoes Ltda.
#
# - Correcao do tratamento de codigo de retorno do DEH;
# - Implementacao de codigo de retorno do script;
# Alteracao Marcos de Benedicto
# Data: 23/09/2004
# CHANGE 2558
#

#------------------
# Carrega arquivo de funcoes utilitarias
#------------------
ARQCFG=/amb/operator/cfg/bscs_batch.cfg
SCPFUNC=/amb/operator/cfg/script_functions.cfg
. /etc/appltab
. ${ARQCFG}
. ${SCPFUNC}

DIR_RTX="${ENV_DIR_BASE_RTX}/prod/WORK/MP/RTX/VPLMN"
DIR_TMP="${ENV_DIR_BASE_RTX}/prod/WORK/MP/RTX/TMP"
DIR_TRAC="${ENV_DIR_BASE_RTX}/prod/WORK/MP/VPLMN"

#------------------
# Corrige arquivos corrompidos
#------------------
for ARQ in `find ${DIR_TRAC} -name RTX.TRAC -size +13 -print`
do
    NEW_DIR_TRAC="`dirname ${ARQ}`"
    cd ${NEW_DIR_TRAC}
    su - prod -c "prtx ${NEW_DIR_TRAC}/RTX.TRAC > ${NEW_DIR_TRAC}/temp.txt"
    su - prod -c "rdtx ${NEW_DIR_TRAC}/temp.txt ${NEW_DIR_TRAC}/RTX.TRAC"
    rm temp.txt
done

mv ${DIR_RTX}/RTX* ${DIR_TMP}/
[ "${?}" -ne 0 ] && exit 1

LOG_DATE=`date +%d%m%Y`
LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
LOG_TIME="${ENV_DIR_BASE_RTX}/prod/reports/TAPOUT_${LOG_DATE}.txt"
COUNT_TIME=`find ${ENV_DIR_BASE_RTX}/prod/WORK/MP/RTX/VPLMN/ -name RTX* -type f 2>/dev/null | wc -l`

printf "%s\t%s\t%s\t%s\n" "DEH" "Inicio do processamento, ${COUNT_TIME} arquivos RTX." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

LISTA="`ls -1rt ${DIR_TMP}/RTX* 2>/dev/null |head -20`"
while [ -n "${LISTA}" ]
do
    set +x
    for ARQ in `echo ${LISTA}`
    do
	mv ${ARQ} ${DIR_RTX}/
    done

    #------------------
    # Variaveis
    #------------------
    DEHCOMM="deh -t"

    ARQTMP=/tmp/.rih_$$
    DATA=`date`
    CODRET=0
    RC=0

    #---------------
    # Execucao do DEH
    #---------------
    echo "------------------------------------------------------------------"
    echo "BSCS DATA EXCHANGE HANDLER - DEH - $DATA"
    echo "Comando: $DEHCOMM"
    echo "------------------------------------------------------------------"

    date > ${ARQTMP}
    echo "------------------------------------------------------------------" >> ${ARQTMP}
    echo "Executando comando: $DEHCOMM" >> ${ARQTMP}
    su - prod -c "$DEHCOMM" 2>&1 >> ${ARQTMP}
    CODRET=$?
    echo "------------------------------------------------------------------" >> ${ARQTMP}
    echo "Processo Terminado em: "`date` >> ${ARQTMP}
    echo "------------------------------------------------------------------" >> ${ARQTMP}

    # ----------------------------
    # Saida na sysout do Control-M:
    # ----------------------------
    cat ${ARQTMP}

    # ---------------------------------------------------------------------------
    # Verifica o codigo de retorno da execucao do DEH e atribui codigo de retorno:
    # ---------------------------------------------------------------------------
    echo "CODRET=${CODRET}"


    if [ "${CODRET}" -gt 0 ]
    then
        echo "\nHouve erro no Processo DEH !!!"
        echo "Enviar E-Mail ao Analista no Horario Comercial !"
        echo "N A O   E X E C U T A R   D O H   ! ! !\n"
        mv ${DIR_TMP}/RTX* ${DIR_RTX}/
        exit 1
    fi

    # --------------------------------------------------------
    # Verifica erros Oracle no DEH e atribui codigo de retorno:
    # --------------------------------------------------------
    conf="`cat ${ARQTMP} | grep \"ORA-\" | wc -l`"
    conf="`echo ${conf}`"
    
    if [ "${conf}" -gt 0 ]
    then
        echo "\nHouve erro no Processo DEH !!!"
        echo "Enviar E-Mail ao Analista no Horario Comercial !"
        echo "N A O   E X E C U T A R   D O H   ! ! !\n"
        mv ${DIR_TMP}/RTX* ${DIR_RTX}/
        exit 1
    fi

    LISTA="`ls -1rt ${DIR_TMP}/RTX* 2>/dev/null |head -20`"
done
    
LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
COUNT_TIME=`find ${ENV_DIR_BASE_RTX}/prod/WORK/MP/RTX/VPLMN/ -name RTX* -type f 2>/dev/null | wc -l`

printf "%s\t%s\t%s\t%s\n" "DEH" "Termino do processamento, ${COUNT_TIME} arquivos RTX." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

cat ${LOG_TIME}
# -----------------------------
# Limpeza de arquivo temporario:
# -----------------------------
[ -f "${ARQTMP}" ] && rm ${ARQTMP} 

exit 0
