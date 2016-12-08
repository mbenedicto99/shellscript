#!/bin/ksh
#  Script      : BILLING_01_03.sh
#  Objetivo    : PROCESSAMENTO DE VERIFICACAO FINAL DO BCH 
#  Descricao   : 
#  Pre-Requis  : Base de Dados pbscs_sp no ar  
#  Criticidade : Alta - Se ocorrer Erro acionar Analista Responsavel 
#  Alteracao   : 07/08/2003 - Marcos de Benedicto

. /etc/appltab

EMAIL="prodmsol@nextel.com.br, analise_producao@nextel.com.br"
export TWO_TASK="${ENV_TNS_PDBSC}"
export USRPASS="${ENV_LOGIN_PDBSC_BCH}"
export ORACLE_HOME="${ENV_DIR_ORAHOME_BSC}"
export NLS_LANG="${ENV_NLSLANG_PDBSC}"

if [ "${#}" -ne 2 ]
then
    echo "Parametros incorretos."
    echo "Use: ${0} <CICLO> <MODO>"
    exit 1
fi

BILLCYCLE="${1}"
MODO="${2}"

if [ "${MODO}" = "COMMIT" ]
then
    
    #FILE_AUTH="${ENV_DIR_BASE_RTX}/prod/WORK/TMP/BGH-${BILLCYCLE}.flg"
    FILE_AUTH="${ENV_DIR_BASE_RTX}/prod/WORK/TMP/CYCLE-${BILLCYCLE}.flg"
    [ ! -f ${FILE_AUTH} ] && exit 1
    #DT_INICIO=`sed -n '2p' ${FILE_AUTH}`
    #DT_VENC=`cat /amb/operator/cfg/bill_parm.cfg | grep "^..RJ${BILLCYCLE}........${DT_INICIO}" | awk -F";" '{print $5}'`
    DT_VENC=`sed -n '4p' ${FILE_AUTH}`
    [ -z ${FILE_AUTH} -o -z ${DT_VENC} ] && exit 1

    DD="`echo ${DT_VENC} | cut -c7-8`"
    MM="`echo ${DT_VENC} | cut -c5-6`"
    YY="`echo ${DT_VENC} | cut -c3-4`"

    [ -z "${BILLCYCLE}" ] && exit 1
    [ -z "${DT_VENC}" ] && exit 1
fi

LOG="/tmp/BILLING_01_03_${BILLCYCLE}_$$.log"

set +x
echo "
      +------------------------------------------------
      |
      |   Informacao
      |
      |   `date`
      |   EMAIL = ${EMAIL}
      |   TWO_TASK = ${TWO_TASK}
      |   ORACLE_HOME = ${ORACLE_HOME}
      |
      +------------------------------------------------\n"
set -x

[ -z "${EMAIL}" ] && exit 1
[ -z "${TWO_TASK}" ] && exit 1
[ -z "${ORACLE_HOME}" ] && exit 1
[ -z "${USRPASS}" ] && exit 1

#--------------------------
# Captura tempo de processamento.
#--------------------------
LOG_DATE=`date +%d%m%Y`
LOG_TIME="${ENV_DIR_BASE_RTX}/prod/reports/VER_BCH_${LOG_DATE}.txt"
LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"

printf "%s\t%s\t%s\t%s\n" "VERIFICA_BCH" "Inicio do processamento." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

COD="BILLING_01_03A"
DESC="VERIFICA_BCH - ${COD} - Verifica clientes a processar - RJ${BILLCYCLE}."
SQL="/amb/scripts/sql/${COD}.sql"
SPOOL="/tmp/${COD}_RJ${BILLCYCLE}.tmp"

. /amb/eventbin/SQL_RUN_BILL.PROC "${TWO_TASK}" "${USRPASS}" "${SQL} ${BILLCYCLE}" "${EMAIL}" "${DESC}" 0 "${DESC}" ${SPOOL}

# Remocao de arquivos DBG do BCH.
#rm -f ${ENV_DIR_BASE_RTX}/prod/WORK/LOG/BCH*.dbg
cp ${SPOOL} ${LOG}

if [ `cat ${SPOOL}` -eq 0 ]
then
    COD="BILLING_01_03B"
    DESC="VERIFICA BCH - ${COD} - Check na tabela de Controle CUST_BCH_PROCESS - RJ${BILLCYCLE}."
    SQL="/amb/scripts/sql/${COD}.sql"
    SPOOL="/tmp/${COD}_RJ${BILLCYCLE}.tmp"

    echo "\nExecuta select na tabela CUST_BCH_PROCESS\n"
    . /amb/eventbin/SQL_RUN_BILL.PROC "${TWO_TASK}" "${USRPASS}" "${SQL} ${BILLCYCLE}" "${EMAIL}" "${DESC}" 0 "${DESC}" ${SPOOL}

    if [ `cat ${SPOOL}` -ne 0 ]
    then
	if [ "${MODO}" = "COMMIT" ]
        then
	    ##echo "\nSimula execucao do BCH\n"
	    #echo "BCH nao executara mais neste processo, pois o problema foi corrigido pelo Reginaldo na CHANGE XXXXX."
	    #Comentado por solicitacao do reginaldo - CHANGE XXXX

	    su - prod -c "pbch 18 ${BILLCYCLE} - - ${YY}${MM}${DD} -"
	else
	    COD="BILLING_01_03C"
	    DESC="VERIFICA BCH - ${COD} - Limpa tabela de Controle CUST_BCH_PROCESS - RJ${BILLCYCLE}."
	    SQL="/amb/scripts/sql/${COD}.sql"
	    SPOOL="/tmp/${COD}_RJ${BILLCYCLE}.tmp"

	    ##echo "\nSimula execucao do DELETEnos casos de CG e TESTE\n"
	    . /amb/eventbin/SQL_RUN_BILL.PROC "${TWO_TASK}" "${USRPASS}" "${SQL} ${BILLCYCLE}" "${EMAIL}" "${DESC}" 0 "${DESC}" ${SPOOL}
	fi
    fi
else
    set +x
    >/tmp/MAIL.$$
    echo "
          +--------------------------------------------------------------
          |
          |   ERRO!
          |   `date`
          |   Ainda existem clientes que nao foram processados para o CICLO ${BILLCYCLE} em ${MODO}.
          |   Numero de Clientes pendentes = `cat ${LOG}`
          |
          +--------------------------------------------------------------\n" |tee -a /tmp/MAIL.$$
    cat /tmp/MAIL.$$ | mailx -m -s "BCH CICLO ${BILLCYCLE} - Verifica BCH encontrou clientes nao processados." ${EMAIL}
    exit 1
fi

set +x
echo "
      +--------------------------------------------------------------
      |
      |   Informacao
      |   `date`
      |   Todos os clientes foram processados pelo BCH.
      |
      +--------------------------------------------------------------\n"

#--------------------------
# Captura tempo de processamento.
#--------------------------
LOG_DATE=`date +%d%m%Y`
LOG_TIME="${ENV_DIR_BASE_RTX}/prod/reports/VER_BCH_${LOG_DATE}.txt"
LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"

printf "%s\t%s\t%s\t%s\n" "VERIFICA BCH" "Termino do processamento." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}
rm ${LOG}
exit 0

