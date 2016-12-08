#!/usr/bin/ksh
        # Finalidade    : CHG3631 - Numeros dos portais de voz
        # Input         : ATS_01_01.sh
        # Output        : mail, log
        # Autor         : Marcos de Benedicto
        # Data          : 11/04/2005

set +x
. /etc/appltab

F_Verifica_RC()
{
  typeset -3Z RC
  RC="${1}"
  MSG="${2}"

  if [ "${RC}" -ne "0" ]
  then
      banner ATENCAO!!
      echo "\n\t\t+----------------------------------------------------------------------"
      echo "\t\t\t\tA T E N C A O ! ! !"
      echo "\t\t+----------------------------------------------------------------------"
      echo "\n\t\t\tERRO na execucao do processo!"
      echo "\t\t\tSegue mensagem de ERRO:"
      echo "\n`[ -n \"${MSG}\" ] && echo \"${MSG}\" || cat ${LOG}`"
      echo "\n\t\t+----------------------------------------------------------------------"
      echo "\t\t\tABEND do JOB as `date`"
      echo "\t\t\tRC = ${RC}"
      echo "\t\t+----------------------------------------------------------------------"
      exit ${RC}
  fi
}

#------------------------------------
# Set de variaveis
#------------------------------------
COD="ATS_01_01"
SQL="/amb/scripts/sql/${COD}.sql"
DIR_CCBK="${ENV_DIR_BASE_RTX}/ccbk"
SPOOL="${DIR_CCBK}/BlackListBSCS.txt"
LOG="/tmp/LOG_${COD}_$$.log"
DESC="${COD} - Numeros dos portais de voz."
EMAIL="prodmsol@nextel.com.br"

export USRPASS="/"
export ORACLE_HOME="${ENV_DIR_ORAHOME_BSC}"
export NLS_LANG="${ENV_NLSLANG_PDBSC}"
export TWO_TASK="${ENV_TNS_PDBSC}"
export ORACLE_SID="${ENV_TNS_PDBSC}"


echo "\n\t\t+-------------------------------------------------------------" >>${LOG}
echo "\n\t\t   Inicio do Processamento:\t`date`" >>${LOG}
echo "\n\t\t   Informacoes!" >>${LOG}
echo "\n\t\t   PID = $$" >>${LOG}
echo "\t\t   SCRIPT = ${COD}.sh" >>${LOG}
echo "\t\t   DESCRICAO = ${DESC}" >>${LOG}
echo "\t\t   SQL = ${SQL}" >>${LOG}
echo "\t\t   EMAIL = ${EMAIL}" >>${LOG}
echo "\t\t   LOG = ${LOG}" >>${LOG}
echo "\t\t   ORACLE_HOME = ${ORACLE_HOME}" >>${LOG}
echo "\t\t   TWO_TASK = ${TWO_TASK}" >>${LOG}
echo "\n\t\t+-------------------------------------------------------------\n" >>${LOG}

#------------------------------------
# Verificando variaveis
#------------------------------------
[ -z "${SQL}" -o ! -f "${SQL}" ] && echo "\t\tERRO: SQL nao existe ou vaiavel esta sem conteudo." >>${LOG}
[ -z "${EMAIL}" ] && echo "\t\tERRO: Variavel de e-mail nao configurada." >>${LOG}
[ -z "${DESC}" ] && echo "\t\tERRO: Variavel DESCRICAO do processo nao foi configurada." >>${LOG}
[ -z "${SPOOL}" ] && echo "\t\tERRO: Variavel SPOOL nao configurada." >>${LOG}
[ -z "${ORACLE_HOME}" -o ! -d "${ORACLE_HOME}" ] && echo "\t\tERRO: Diretorio ORACLE_HOME nao existe ou variavel nao configurada." >>${LOG}
[ -z "${TWO_TASK}" ] && echo "\t\tERRO: Variavel TWO_TASK nao configurada." >>${LOG}
[ -z "${USRPASS}" ] && echo "\t\tERRO: Variavel USRPASS nao configurada." >>${LOG}

[ "`grep -c \"ERRO: \" ${LOG}`" -ne 0 ] && F_Verifica_RC 1 || echo "\t\tSUCESSO: Variaveis configuradas com sucesso." >>${LOG}

#------------------------------------
# Executando relatorio
#------------------------------------
[ "${?}" -ne 0 ] && F_Verifica_RC 1 "ERRO: Nao foi possivel acessar o diretorio ${DIR_ORIG}."

. /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL}" "${EMAIL}" "${DESC}" 0 "${DESC}" "${SPOOL}"

[ "`grep -c \"ERRO: \" ${LOG}`" -ne 0 ] && F_Verifica_RC 1 || echo "\t\tSUCESSO: Arquivo gerado com sucesso." >>${LOG}

echo "\n\t\t+-------------------------------------------------------------" >>${LOG}
echo "\t\t   Termino do Processamento:\t`date`" >>${LOG}
echo "\t\t   Informacoes!" >>${LOG}
echo "\n\t\t   SERVIDOR = `uname -n`" >>${LOG}
echo "\t\t   RC = 0" >>${LOG}
echo "\t\t+-------------------------------------------------------------\n" >>${LOG}

cat ${LOG}
[ -f ${LOG} ] && rm ${LOG}

exit 0
