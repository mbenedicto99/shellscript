#!/bin/ksh
	# Finalidade    : CHG
	# Input         : busca_mdr.sh
	# Output        : mail, log
	# Autor         : Rafael Toniete
	# Data          : 02/06/2005


. /etc/appltab

banner ${$}

COD="busca_mdr"
EMAIL="prodmsol@nextel.com.br"
DESC="${COD} - Busca arquivos MDR"
LOG_ERR="/tmp/${COD}_ftp_$$.err"
LOG="/tmp/${COD}_ftp_$$.log"
DATA="`perl -le '@T=localtime(time-86400*2); printf("%04d%02d%02d",($T[5]+1900),$T[4]+1,$T[3]+1)'`"
USER_PASS="niibr niibr"
TARGET="10.103.195.8"
OUT_FILE="hmg*${DATA}*"
DIR_SOURCE="/cdrlog"
DIR_DEST="/aplic/artx/prod/WORK/MP/MDR"

#-----------------------
# Funcao Verifica RC
#-----------------------
F_Verifica_RC()
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
              ${MSG}

	      Abrir chamado para grupo Billing Applications System
            +-------------------------------------------+
              ABEND do JOB as `date`
              RC = ${RC}
            +-------------------------------------------+"

      exit ${RC}
  fi
}

F_Valida_FTP()
{
  if [ -s ${LOG} ]
  then
      if [ `grep -c "Connection refused" "${LOG}"` -ne "0" ]
      then
          F_Verifica_RC 15 "Usuario nao autenticado para FTP."
      fi
      if [ `egrep -c "Connection timed out|Not connected." "${LOG}"` -ne "0" ]
      then
          F_Verifica_RC 15 "Servidor FTP nao esta disponivel."
      fi
  
      if [ `grep -c "Permission denied" "${LOG}"` -ne "0" ]
      then
          F_Verifica_RC 15 "Sem permissao para transferir o arquivo."
      fi
  fi
}

set +x
echo "
        +------------------------------------------------
        |
        |   Informacao
        |
        |   `date`
        |   PID = $$
        |   EMAIL = ${EMAIL}
        |   DESCRICAO = ${DESC}
        |
        +------------------------------------------------\n"
set -x

[ -z "${EMAIL}" ] && exit 1
[ -z "${DESC}" ] && exit 1
[ -z "${USER_PASS}" ] && exit 1


cd ${DIR_DEST}
[ $? -ne 0 ] && exit 1

ftp -inv ${TARGET} <<EOF >${LOG} 2>${LOG_ERR}
user ${USER_PASS}
cd ${DIR_SOURCE}
asc
mget ${OUT_FILE}
by
EOF

F_Valida_FTP

ls -1 ${OUT_FILE} |while read ARQ
do
    [ ! -f ${ARQ} ] && continue
    NEW_ARQ="MDR$(echo ${ARQ} | cut -c 14-33)"
    linhas=$(wc -l ${ARQ} | cut -d " "  -f1)
    if [ ${linhas} -eq 0 ]
    then
        rm ${ARQ}
	RC="${?}"
	MSG="ERRO: Ao remover o arquivo ${ARQ}."
    else
        mv ${ARQ} ${NEW_ARQ}
	RC="${?}"
	MSG="ERRO: Ao renomear o arquivo ${ARQ} para ${NEW_ARQ}."
    fi
    F_Verifica_RC ${RC} "${MSG}"
done

exit 0

