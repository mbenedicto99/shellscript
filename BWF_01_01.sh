#!/bin/ksh
        # Finalidade    : SCR - Executa função no banco para inserir inicio ou fim de modulo de billing.
        # Input         : BWF_01_01.sh
        # Output        : log
        # Autor         : Marcos de Benedicto
        # Data          : 30/01/2007
set +x

set -A BWF ind_0 ind_1 ind_2
COD="BWF_01_01"

. /etc/appltab

banner ${$}

ind_0()
{
  RC="${1}"
  MSG="${2}"

  if [ "${RC}" -ne 0 ]
  then
      echo "ERRO: ${MSG}"
      exit ${RC}
  else
      echo "SUCESSO: ${MSG}"
  fi
}

#-----------------
# Valida Parametros
#-----------------
if [ ${#} -gt 4 -o ${#} -lt 3 ]
then
    echo "ERRO: Parametros incorretos!!"
    echo "      USE: ${COD}.sh <OPCAO> <CICLO> <SIGLA>"
    exit 1
else
    OPCAO="${1}"
    CICLO="${2}"
    SIGLA="${3}"
    
    FLAG_BCH="/aplic/artx/prod/WORK/TMP/CYCLE-${CICLO}.flg"
    #[ ! -f ${FLAG_BCH} ] && ${BWF[0]} 1 "Arquivo de Liberacao do ciclo nao encontrado." || ${BWF[0]} 0 "Arquivo de Liberacao do ciclo encontrado."

    #DATA_CORTE="`sed -n '3p' ${FLAG_BCH} |cut -c 1-8`"
    DATA_CORTE="20070203"
fi

#-----------------
# Configuracao de Variaveis
#-----------------
export USRPASS="sysadm/sysadm"
#export ORACLE_HOME="${ENV_DIR_ORAHOME_BSC}"
#export NLS_LANG="${ENV_NLSLANG_PDBSC}"
#export TWO_TASK="${ENV_TNS_PDBSC}"
#export ORACLE_SID="${ENV_TNS_PDBSC}"

#--- Para em execucao em aceite

export ORACLE_HOME="/aplic/oracle/app/product/9.2.0.7"
export NLS_LANG="${ENV_NLSLANG_PDBSC}"
export TWO_TASK="DNXTL02"
export ORACLE_SID="DNXTL02"

EMAIL="rafael.toniete@nextel.com.br"
DESC="Executa função no banco para inserir inicio ou fim de modulo de billing."
SPOOL=0


#-----------------
# Corpo Principal
#-----------------
case ${OPCAO} in
	 INICIO|inicio)
	               SQL="/amb/scripts/sql/${COD}_INI.sql"
                       #-----------------
                       # Insere dados no Billing Workflow
                       #-----------------
                       . /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL} ${CICLO} ${DATA_CORTE} ${SIGLA}" "${EMAIL}" "${DESC}" 0 "${DESC}" "${SPOOL}"
	               ;;
	       FIM|fim)
	               SQL="/amb/scripts/sql/${COD}_FIM.sql"
	               COD_ERRO="${4}"
                       #-----------------
                       # Insere dados no Billing Workflow
                       #-----------------
                       . /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL} ${CICLO} ${DATA_CORTE} ${SIGLA} ${COD_ERRO}" "${EMAIL}" "${DESC}" 0 "${DESC}" "${SPOOL}"
	               ;;
	             *)
	               ${BWF[0]} 1 "Opcao nao eh valida."
	               ;;
esac


