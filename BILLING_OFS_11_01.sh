#!/bin/ksh

	# Finalidade    : OFS - GEL GERA BOLETO E TRANSFERE LOG PARA SPOSNAP4
	# Input         : BILLING_OFS_11_01.sh
	# Output        : mail, log
	# Autor         : Marcos de Benedicto
	# Data          : 31/05/2004

. /etc/appltab

[ "${#}" -ne 2 ] && (echo "Use: ${0} <BILLCYCLO> <DIR_GEL>"; exit 1) || (echo "Parametro existente."; exit 0)
[ "${?}" -ne 0 ] &&  exit 1

GEL_MASK="GEL_INTERFACE*"
GEL_MASK="GEL_INTERFACE.GEL_??????????????.log"
LOG_GEL_MASK="*GEL_GERA_BOLETO_*"
PATH_UTL="${ENV_DIR_UTLF_BSC}/GEL"
DATE=`echo $(date +%d-%m-%y) $(date +%H:%M)`
COD="billing_ofs_11_01"
SQL="/tmp/${COD}.sql"
#EMAIL="analise_producao@nextel.com.br"
EMAIL="roberto.takemoto@nextel.com.br"
DESC="BILLING OFS - GEL GERA BOLETO ${DATE}"
SPOOL="/tmp/spool_${COD}.txt"
BILLCYCLE="${1}"
DIR_GEL="${2}"
LOG_FTP"/tmp/ftp_${COD}.log"
LOG_ERR="/tmp/ftp_${COD}.err"
USER_PASS="bghuser bghuserx"
#TARGET="sposnap4"
TARGET="painv"
DIR_SOURCE="/pinvoice/input"

if [ ! -f ${PATH_UTL}/${GEL_MASK} ]
then
    echo "Arquivo do GEL nao encontrado."
    exit 1
fi

DATA_BILLCYCLO=`grep "BILLCYCLE:${BILLCYCLE}" ${PATH_UTL}/${GEL_MASK} | tail -1 | cut -c 34-41`
  DIA_BILLCYCLO="`echo ${DATA_BILLCYCLO} |cut -c 7-8`"
  MES_BILLCYCLO="`echo ${DATA_BILLCYCLO} |cut -c 5-6`"
  ANO_BILLCYCLO="`echo ${DATA_BILLCYCLO} |cut -c 1-4`"


CYCLO_NAME="`echo ${BILLCYCLE}-${DIA_BILLCYCLO}/${MES_BILLCYCLO}/${ANO_BILLCYCLO}`"

echo "exec gel_interface.gel_gera_boleto('${CYCLO_NAME}','${PATH_UTL}');" >${SQL}

 chmod 777 ${SQL}

export USRPASS="oaiusr/bscs523"
export ORACLE_HOME="${ENV_DIR_ORAHOME_BSC}"
export NLS_LANG="${ENV_NLSLANG_PDBSC}"
export TWO_TASK="${ENV_TNS_PDBSC}"
export ORACLE_SID="${ENV_TNS_PDBSC}"

set +x
echo "
       +------------------------------------------------
       |
       |   Informacao
       |
       |   `date`
       |   EMAIL = ${EMAIL}
       |   DESCRICAO = ${DESC}
       |   ORACLE_SID = ${ORACLE_SID}
       |   TWO_TASK = ${TWO_TASK}
       |   ORACLE_HOME = ${ORACLE_HOME}
       |
       |   PATH UTL = ${PATH_UTL}
       |
       +------------------------------------------------\n"
set -x

[ -z "${PATH_UTL}" ] && exit 1
[ ! -s "${SQL}" ] && exit 1
[ -z "${EMAIL}" ] && exit 1
[ -z "${DESC}" ] && exit 1
[ -z "${TWO_TASK}" -o -z "${ORACLE_SID}" ] && exit 1
[ -z "${ORACLE_HOME}" ] && exit 1
[ -z "${USRPASS}" ] && exit 1


. /amb/eventbin/SQL_RUN_BILL.PROC "${TWO_TASK}" "${USRPASS}" "${SQL}" "${EMAIL}" "${DESC}" 0 "BILLING_OFS_11" 0

FILE_LOG="`ls -tr ${PATH_UTL}/${LOG_GEL_MASK} | tail -1`"

if [ "`grep -c \"ERRO\" ${FILE_LOG}`" -ne 0 ]
then
    echo "
    +-------------------------------------------
     Encontrado ERRO na LOG do GERA_BOLETO.
    +-------------------------------------------\n"
    exit 1
fi


#-----------------------
# FTP
#-----------------------
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
            echo " Arquivo ${ARK_MASK} nao foi transferido."
            echo "+-------------------------------------------"
            exit 1
        fi
    fi

done
        
rm ${SQL}
exit 0
