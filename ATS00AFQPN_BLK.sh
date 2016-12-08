#!/bin/ksh
        # Finalidade    : CHG2628 - Processamento diario de arquivos de BlackList para a Plataforma de Ligacues a Cobrar.
        # Input         : ATS00AFQPN_BLK.sh
        # Output        : mail, log
        # Autor         : Rafael Toniete
        # Data          : 05/10/2004

. /etc/appltab

set -A ATS ind_0 ind_1 ind_2 ind_3

#---------------------
# Variaveis
#---------------------
DIR_CCBK="${ENV_DIR_BASE_RTX}/ccbk"
ARQ_TXT="${DIR_CCBK}/BlackListAcc.txt"
ARQ_BSCS="${DIR_CCBK}/BlackListBSCS.txt"
ARQ_CTL="${DIR_CCBK}/BlackListAcc.ctl"

##ARQ_TXT="/tmp/BlackListAcc.txt"
##ARQ_CTL="/tmp/BlackListAcc.ctl"

SCRIPT="${0}"
LOG_TMP="/tmp/${SCRIPT}.log"
DEST_ERRO="prodmsol@nextel.com.br"
SQLPATH="/amb/scripts/sql"

export ORACLE_HOME=${ENV_DIR_ORAHOME_ATS}
export TWO_TASK=${ENV_TNS_ATS}
export ORACLE_SID=${ENV_ORA_ATS}
export NLS_LANG=${NLS_NLSLANG_ATS}
export USERPASS="CONSULTABR/CONSULTABR920"

#-----------------------
# Funcao para validar RC
#-----------------------
ind_0()
{
  typeset -3Z RC
  RC="${1}"
  MSG="${2}"

  if [ "${RC}" -ne "0" ]
  then
      banner NOTOK
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
        +-------------------------------------------+" >${LOG_TMP}

      cat ${LOG_TMP} |mailx -s "ERRO de processamento - ${SCRIPT}" ${DEST_ERRO}
      rm -f ${LOG_TMP}

      exit ${RC}
  fi
}

#-----------------------
# Funcao para select de arquivos nao processados pelo ATS para processamento
#-----------------------
ind_1()
{
  COD="ATS00AFQPN_BLK"
  SPOOL1="/tmp/${COD}.txt"
  SQL="${SQLPATH}/${COD}.sql"
  DESC="SQL ${COD} - Coleta Numero de pre-pago na plataforma ATS"
  
  . /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USERPASS}" "${SQL}" "${DEST_ERRO}" "${DESC}" 0 "${DESC}" "${SPOOL1}"
  ${ATS[0]} ${?} "ERRO: ${DESC}"
}

#-----------------------
# Funcao para Atualizar STATUS de arquivos do ATS para processamento.
#-----------------------
ind_2()
{
  COD="ATS00BFQPN_BLK"
  SPOOL2="/tmp/${COD}.txt"
  SQL="${SQLPATH}/${COD}.sql"
  DESC="SQL ${COD} - Quantidade de telefones pre-pago na plataforma ATS."

  . /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USERPASS}" "${SQL}" "${DEST_ERRO}" "${DESC}" 0 "${DESC}" "${SPOOL2}"
  ${ATS[0]} ${?} "ERRO: ${DESC}."
}

#-----------------------
# Funcao para Copiar arquivos para ATS
#-----------------------
ind_3()
{
  if [ ! -s ${SPOOL1} -o ! -s ${ARQ_BSCS} ]
  then
      ${ATS[0]} 2 "ERRO: Arquivo gerado sem conteudo."
  else
      cat ${ARQ_BSCS} ${SPOOL1} > ${ARQ_TXT}
      ##mv ${SPOOL1} ${ARQ_TXT}
      cat ${ARQ_TXT} |wc -l > ${ARQ_CTL}
      rm ${ARQ_BSCS}

      chmod 640 ${ARQ_TXT} ${ARQ_CTL}
      chown ccbkftp:users ${ARQ_TXT} ${ARQ_CTL}
  fi
}

#-----------------------
# Corpo principal do programa
#-----------------------
${ATS[1]}
##${ATS[2]}
${ATS[3]}

exit 0 
