#!/bin/ksh
        # Finalidade    : Faz backup dos arquivos de DAP
        # Autor         : Marcos de Benedicto
        # Data          : 05/05/2005

#set +x

. /etc/appltab

#--------------
# Set de Funcoes
#--------------
F_Verifica_RC()
{
  typeset -3Z RC
  RC="${1}"

  if [ "${RC}" -ne "0" ]
  then
      echo "\n+-------------------------------------------------------------" >>${LOG}
      echo "\t\t\t\tA T E N C A O ! ! !"
      echo "+----------------------------------------------------------------------" >>${LOG}
      echo "\tINFORMACAO: Termino do Processamento:\t`date`" >>${LOG}
      echo "\tINFORMACAO: RC = ${RC}" >>${LOG}
      echo "+----------------------------------------------------------------------"
      cat ${LOG}
      exit ${RC}
  fi
}

#--------------
# Configuracao de Variaveis
#--------------
COD="BKP_DAP"
PID=$$
LOG="/tmp/LOG_${COD}_${PID}.log"
DIR_DAP=${ENV_DIR_DAP_RTX}
DIR_BKP=${ENV_DIR_BASE_RTX}/sched/bscs/transf/DAP_BKP
DESC="Faz backup dos arquivos originais de DAP."
EMAIL="prodmsol@nextel.com.br"
if [ "${#}" -ne 1 ]
then
    echo "ERRO: Parametros incorretos!"
    echo "      USE: ${COD}.sh <ODATE -1>"
    exit 1
else
    DATA="${1}"
    ARQ_GRA="${ENV_DIR_BASE_RTX}/prod/WORK/TMP/GRADAP_${DATA}.txt"
fi

#--------------
# Print de informacoes
#--------------
echo "\n+-------------------------------------------------------------" >>${LOG}
echo "\tINFORMACAO: Inicio do Processamento:\t`date`" >>${LOG}
echo "\tINFORMACAO: PID = ${PID}" >>${LOG}
echo "\tINFORMACAO: SCRIPT = ${COD}.sh" >>${LOG}
echo "\tINFORMACAO: SERVIDOR = `uname -n`" >>${LOG}
echo "\tINFORMACAO: DESCRICAO = ${DESC}" >>${LOG}
echo "\tINFORMACAO: LOG = ${LOG}" >>${LOG}
echo "\tINFORMACAO: DIR DAP = ${DIR_DAP}" >>${LOG}
echo "\tINFORMACAO: DIR BKP = ${DIR_BKP}" >>${LOG}
echo "\tINFORMACAO: EMAIL = ${EMAIL}" >>${LOG}

#--------------
# Verificacao das Variaveis
#--------------
[ -z "${EMAIL}" ] && echo "\t\tERRO: Variavel de e-mail nao configurada." >>${LOG}
[ -z "${DESC}" ] && echo "\t\tERRO: Variavel DESCRICAO do processo nao foi configurada." >>${LOG}
[ -z "${DIR_DAP}" -o ! -d "${DIR_DAP}" ] && echo "\t\tERRO: Diretorio DIR_DAP nao existe ou variavel nao configurada." >>${LOG}
[ -z "${DIR_BKP}" -o ! -d "${DIR_BKP}" ] && echo "\t\tERRO: Diretorio DIR_BKP nao existe ou variavel nao configurada." >>${LOG}

[ "`grep -c \"ERRO: \" ${LOG}`" -ne 0 ] && F_Verifica_RC 1 || echo "\t\tSUCESSO: Variaveis configuradas com sucesso." >>${LOG}

#--------------
# Inicio da execucao
#--------------
cd ${DIR_DAP}
if [ "${?}" -eq 0 ]
then
    echo "\t\tSUCESSO: Ao acessar diretorio ${DIR_DAP} ." >>${LOG}
else
    echo "\t\tERRO: Ao acessar diretorio ${DIR_DAP} ." >>${LOG}
    F_Verifica_RC 1
fi

echo "\tINFORMACAO: Executando backup dos arquivos." >>${LOG}

ls DAP??????????????? | while read ARQ_DAP
do
    [ ! -f ${ARQ_DAP} ] && continue

    #---------
    # Grava arquivo com informacoes para carga no GRA
    #--------- INICIO ---------
    TAMANHO_DAP="`ls -l ${ARQ_DAP}|awk '{print $5}'`"
    echo "${ARQ_DAP}|${TAMANHO_DAP}" >>${ARQ_GRA}
    #---------
    # Grava arquivo com informacoes para carga no GRA
    #--------- FINAL ---------

    cp ${ARQ_DAP} ${DIR_BKP}
    [ "${?}" -ne 0 ] && echo "\tERRO: Ao efetuar backup do arquivo ${ARQ_DAP} para ${DIR_BKP} " >>${LOG}
    ##gzip -f -9 ${DIR_BKP}/${ARQ_DAP} 
    ##[ "${?}" -ne 0 ] && echo "\tERRO: No gzip do arquivo ${DIR_BKP}/${ARQ_DAP} " >>${LOG}
done

find ${ENV_DIR_BASE_RTX}/prod/WORK/TMP -type f -name GRADAP_\*.gz -mtime +7 -exec rm \-f {} \;

echo "\n+-------------------------------------------------------------" >>${LOG}
echo "\tINFORMACAO: Termino do Processamento:\t`date`" >>${LOG}
echo "\tINFORMACAO: EXIT = 0" >>${LOG}
echo "+-------------------------------------------------------------\n" >>${LOG}

[ -f ${LOG} ] && cat ${LOG}
[ -f ${LOG} ] && rm ${LOG}

exit 0
