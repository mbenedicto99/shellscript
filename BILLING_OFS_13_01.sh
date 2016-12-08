#!/bin/ksh

	# Finalidade    : SCR20188 - TRANSFERE ARQUIVO GEL PARA ISC
	# Input         : BILLING_OFS_13_01.sh
	# Output        : mail, log
	# Autor         : Marcos de Benedicto
	# Data          : 09/03/2007

. /etc/appltab

if [ "${#}" -ne 2 ]
then
	  echo "Use: ${0} <BILLCYCLO> <DIR_GEL>"
	  exit 1
else
    echo "Parametro existente."
fi

PATH_UTL="${ENV_DIR_UTLF_BSC}/GEL"
COD="billing_ofs_13_01"
BILLCYCLE="${1}"
DIR_GEL="${2}"
LOG_FTP"/tmp/ftp_${COD}.log"
LOG_ERR="/tmp/ftp_${COD}.err"
USER_PASS="bghuser bghuserx"
TARGET="painv"

[ -z "${PATH_UTL}" ] && exit 1

cd ${PATH_UTL}

su - transf -c "remsh ${TARGET} mkdir -p ${DIR_GEL}"
su - transf -c "remsh ${TARGET} chmod 777 ${DIR_GEL}"

for ARQ in `ls -1 RJ${BILLCYCLE}T.GEL`
do
    chmod 777 ${ARQ}
    ftp -inv ${TARGET} <<EOF >${LOG_FTP} 2>${LOG_ERR}
    user ${USER_PASS}
    cd ${DIR_GEL}
    asc
    put ${ARQ}
    by
EOF

    if [ -s ${LOG_ERR} ]
    then
        if [ "`grep -c \"Connection refused\" ${LOG_ERR}`" -ne "0" ]
        then
            echo "\n+-------------------------------------------"
            echo " Usuario nao autenticado para FTP."
            echo "+-------------------------------------------"
            exit 1
        fi
  
        if [ "`grep -c \"Connection timed out\" ${LOG_ERR}`" -ne "0" ]
        then
            echo "\n+-------------------------------------------"
            echo " Servidor FTP nao esta disponivel."
            echo "+-------------------------------------------"
            exit 1
        fi
  
        if [ "`grep -c \"Permission denied\" ${LOG_ERR}`" -ne "0" ]
        then
            echo "\n+-------------------------------------------"
            echo " Sem permissao para transferir o arquivo."
            echo "+-------------------------------------------"
            exit 1
        fi
  
        let CHECK_MSG="`grep -c \"150 Opening ASCII mode data connection for\" ${LOG_FTP}`+`grep -c \"226 Transfer complete\" ${LOG_FTP}`"
        if [ "${CHECK_MSG}" -lt 2 ]
        then
            echo "\n+-------------------------------------------"
            echo " Arquivo ${ARQ} nao foi transferido."
            echo "+-------------------------------------------"
            exit 1
        fi
    fi

done

[ -f ${LOG_FTP} ] && rm -f ${LOG_FTP}
[ -f ${LOG_ERR} ] && rm -f ${LOG_ERR}

exit 0
