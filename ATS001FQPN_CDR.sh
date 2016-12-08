#!/bin/ksh
        # Finalidade    : CHG3009 - 
        # Input         : ATS001FQPN_CDR.sh 
        # Output        : mail, log
        # Autor         : Rafael Toniete
        # Data          : 05/10/2004

. /etc/appltab

set -A ATS001FQPN_CDR ind_0 ind_1

#---------------------
# Variaveis
#---------------------
DIR_UTL="${ENV_DIR_UTLF_BSC}/sched/GENFL"
DATA="${1}"
HV="`date +%Z`"

COD="${0}"
LOG_TMP="/tmp/${COD}.log"
DEST_ERRO="prodmsol@nextel.com.br"
SQLPATH="/amb/scripts/sql"
SQL="${SQLPATH}/${COD}.sql"

export ORACLE_HOME=${ENV_DIR_ORAHOME_BSC}
export TWO_TASK=${ENV_TNS_PDBSC}
export ORACLE_SID=${ENV_TNS_PDBSC}
export NLS_LANG=${ENV_NLSLANG_PDBSC}
export USERPASS="/"

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
          ERRO na execucao do script: 
          Foi detectado um erro no processamento!!
          Erro no processo de:\n
           ${MSG}

        +-------------------------------------------+
          ABEND do JOB as `date`
          RC = ${RC}
        +-------------------------------------------+" 

      exit ${RC}
  fi
}

#-----------------------
# Funcao para select de arquivos nao processados pelo ATS001FQPN_CDR para processamento
#-----------------------
COD="ATS00AFQPN_BLK"
SPOOL="/tmp/${COD}.txt"
SQL="${SQLPATH}/${COD}.sql"
DESC="SQL ${COD} - Coleta Numero de pre-pago na plataforma ATS"
  
. /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USERPASS}" "${SQL} ${DIR_UTL} ${DATA} ${HV}" "${DEST_ERRO}" "${DESC}" 0 "${DESC}" "${SPOOL}"
${ATS001FQPN_CDR[0]} ${?} "ERRO: ${DESC}"

#-----------------------
# Corpo principal do programa
#-----------------------
exit 0 
