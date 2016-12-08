#!/bin/ksh +vx

        # Finalidade    : Execucao do GERA SALDO
        # Input         : BAIXA_SALDOS.sh
        # Output        : mail, log
        # Autor         : Rafael Toniete
        # Data          : 17/08/2004

exit 0

F_Finaliza()
{
  set +x
  RC="${1}"
  MSG="${2}"

  if [ "${RC}" -ne 0 ]
  then
      banner ERRO
      echo "
      +-------------------------------------------+
                  A T E N C A O ! ! !
      +-------------------------------------------+\n
        ERRO na execucao do script: ${SCRIPT}
        Foi detectado um erro no processamento!!
        Erro no processo de:\n
        `echo ${MSG}`

      +-------------------------------------------+
        ABEND do JOB as `date`
        RC = ${RC}
      +-------------------------------------------+"
      exit ${RC}
  fi
}

. /etc/appltab

banner $$

if [ "${#}" -ne 1 ]
then
    echo "ERRO: Parametros incorretos!!"
    echo "USE: ${0} <CICLO>"
    exit 1
fi

COD="baixa_saldos"
CICLO="${1}"
COD1="${COD}1"
COD2="${COD}2"
COD3="${COD}3"
SQLPATH="${ENV_DIR_BASE_SQL}"
DEST_ERR="prodmsol@nextel.com.br"
DEST="bill_process@unix_mail_fwd,Luana.Bertasi@nextel.com.br"
DESC1="SQL - ${COD1} - Baixa de Saldos para o CICLO ${CICLO}"
DESC2="Baixa de Saldos para o CICLO ${CICLO}"
DESC3="SQL - ${COD3} - Baixa de Saldos para o CICLO ${CICLO}"
DESC="Baixa de Saldos para o CICLO ${CICLO}"
SPOOL1="/tmp/spool_${COD1}_$$.txt"
SPOOL2="/tmp/spool_${COD2}_$$.txt"
SPOOL3="/tmp/spool_${COD3}_$$.txt"
LOG="/tmp/${COD}_$$.txt"
SCRIPT="${0}"

>${LOG}

export USRPASS="OAIUSR/bscs523"
export ORACLE_HOME=${ENV_DIR_ORAHOME_BSC}
export NLS_LANG="${ENV_NLSLANG_PDBSC}"
export TWO_TASK=${ENV_TNS_PDBSC}
export ORACLE_SID=${ENV_TNS_PDBSC}

set +x
echo "
      +------------------------------------------------
      |
      |   Informacao
      |
      |   `date`
      |   PID = $$
      |   DEST_ERR = ${DEST_ERR}
      |   DESCRICAO = ${DESC}
      |   ORACLE_SID = ${ORACLE_SID}
      |   TWO_TASK = ${TWO_TASK}
      |   ORACLE_HOME = ${ORACLE_HOME}
      |
      +------------------------------------------------\n"
set -x

[ -z "${COD1}" ] && F_Finaliza 1 "ERRO: Variavel SQL nao foi configurada."
[ -z "${COD2}" ] && F_Finaliza 1 "ERRO: Variavel SQL1 nao foi configurada."
[ -z "${COD3}" ] && F_Finaliza 1 "ERRO: Variavel SQL2 nao foi configurada."
[ -z "${DEST_ERR}" ] && F_Finaliza 1 "ERRO: Variavel DEST_ERR nao foi configurada."
[ -z "${DESC}" ] && F_Finaliza 1 "ERRO: Variavel DESC nao foi configurada."
[ -z "${ORACLE_SID}" ] && F_Finaliza 1 "ERRO: Variavel ORACLE_SID nao foi configurada."
[ -z "${ORACLE_HOME}" ] && F_Finaliza 1 "ERRO: Variavel ORACLE_HOME nao foi configurada."
[ -z "${USRPASS}" ] && F_Finaliza 1 "ERRO: Variavel USRPASS nao foi configurada."

#----------------------------
# Select ANTES para validacao do insert
#----------------------------
/amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQLPATH}/${COD1}.sql ${CICLO}" "${DEST_ERR}" "BAIXA_SALDOS" 0 "${DESC1}" ${SPOOL1}
if [ "${?}" -ne 0 ]
then
    F_Finaliza 33 "ERRO: Na execucao do SELECT antes do GERA SALDO"
else
    COUNT1="`cat ${SPOOL1} |grep -v ^$ |awk '{print $1}'`"
fi

#----------------------------
# Executando gera dados
#----------------------------
/amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQLPATH}/${COD2}.sql ${CICLO}" "${DEST_ERR}" "BAIXA_SALDOS" 0 "${DESC2}" ${SPOOL2}
if [ "${?}" -ne 0 ]
then
    F_Finaliza 33 "ERRO: Na execucao do INSERT GERA SALDO"
fi

#----------------------------
# Select DEPOIS para validacao do insert
#----------------------------
/amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQLPATH}/${COD3}.sql ${CICLO}" "${DEST_ERR}" "BAIXA_SALDOS" 0 "${DESC3}" ${SPOOL3}
if [ "${?}" -ne 0 ]
then
    F_Finaliza 33 "ERRO: Na execucao do SELECT depois do GERA SALDO"
else
    COUNT3="`cat ${SPOOL3} |grep -v ^$ |awk '{print $1}'`"
fi

if [ "${COUNT1}" -ne"${COUNT3}" ]
then
    F_Finaliza 33 "Houve diferencas nos valores do GERA SALDO: ${COUNT1} != ${COUNT3}"
else
    banner OK
    echo "
          +------------------------------------------------------
            Processo finalizou com sucesso.
            Foram atualizados ${COUNT3} para o CICLO ${CICLO}.
          +------------------------------------------------------\n" |tee -a ${LOG}
    cat ${LOG} |mailx -s "${DESC2}" ${DEST}
fi
