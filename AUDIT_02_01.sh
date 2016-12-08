#!/bin/ksh
	# Finalidade    : CHG4394.b - Relatorio de Acessos Ativos nos sistemas criticos da NEXTEL
	# Input         : AUDIT_02_01.sh
	# Output        : mail, log
	# Autor         : Rafael Toniete
	# Data          : 29/07/2005

. /etc/appltab

banner ${$}

COD="AUDIT_02_01"
SPOOL="/tmp/log_${COD}_$$.spool"
EMAIL_REL="${SPOOL}"
EMAIL="prodmsol@nextel.com.br"
DIR_REL="/aplic/utl/auditoria"

if [ "${#}" -ne 2 ]
then
    echo "ERRO: Parametros incorretos!!"
    echo "      USE: ${COD}.sh <Sistema> <Data>"
    exit 1
else
    SISTEMA="${1}"
    DATA="${2}"
    AAAA="`echo ${DATA} |cut -c 1-4`"
    MM="`echo ${DATA} |cut -c 5-6`"
    DD="`echo ${DATA} |cut -c 7-8`"

    DESC="${COD} - Relatorio de Acessos Ativos no sistema ${SISTEMA}"
    ARQ_REL="audit_${SISTEMA}_${DD}${MM}${AAAA}*.csv"
fi

case ${SISTEMA} in
                'BSC')
                      SQL="/amb/scripts/sql/AUDIT_02_02.sql"
                      ;;
                    *)
                      SQL="/amb/scripts/sql/${COD}.sql"
                      ;;
esac

export USRPASS="/"
export ORACLE_HOME="${ENV_DIR_ORAHOME_PNXTL01}"
export NLS_LANG="${NLS_NLSLANG_PNXTL01}"
export TWO_TASK="${ENV_TNS_PNXTL01}"
export ORACLE_SID="${ENV_ORA_PNXTL01}"

set +x
echo "
        +------------------------------------------------
        |
        |   Informacao
        |
        |   `date`
        |   PID = $$
        |   SQL = ${SQL}
        |   EMAIL = ${EMAIL}
        |   DESCRICAO = ${DESC}
        |   SISTEMA = ${SISTEMA}
        |   ORACLE_SID = ${ORACLE_SID}
        |   TWO_TASK = ${TWO_TASK}
        |   ORACLE_HOME = ${ORACLE_HOME}
        |
        +------------------------------------------------\n"
set -x

[ -z "${SQL}" ] && exit 1
[ -z "${EMAIL}" ] && exit 1
[ -z "${DESC}" ] && exit 1
[ -z "${SISTEMA}" ] && exit 1
[ -z "${ORACLE_SID}" ] && exit 1
[ -z "${ORACLE_HOME}" ] && exit 1
[ -z "${USRPASS}" ] && exit 1

#-----------------------
# Gera lista de e-mail
#-----------------------
. /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL} ${SISTEMA}" "${EMAIL}" "${DESC}" 0 "${DESC}" "${SPOOL}"

COD="AUDIT_02_03"
SPOOL="/tmp/log_${COD}_$$.spool"
LOG_SPOOL="${SPOOL}"
SQL="/amb/scripts/sql/${COD}.sql"

[ -z "${SQL}" ] && exit 1
[ -z "${EMAIL}" ] && exit 1
[ -z "${DESC}" ] && exit 1
[ -z "${SISTEMA}" ] && exit 1
[ -z "${ORACLE_SID}" ] && exit 1
[ -z "${ORACLE_HOME}" ] && exit 1
[ -z "${USRPASS}" ] && exit 1

#-----------------------
# Valida Execucao
#-----------------------
/amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL} ${SISTEMA}" "${EMAIL}" "${DESC}" 0 "${DESC}" "${SPOOL}"

if [ "`grep -c 'Abortou' ${LOG_SPOOL}`" -eq 1 ]
then
    echo "ABORT: Ocorreu um ABORT na geracao do relatorio do sistema ${SISTEMA}."
    echo "INFORMACAO: Encaminhar SYSOUT para informationsecurity@nextel.com.br,access.controlgroup@nextel.com.br"
    exit 1
fi

if [ "`grep -c 'Erro' ${LOG_SPOOL}`" -eq 1 ]
then
    echo "ERRO: Ocorreu um ERRO na geracao do relatorio do sistema ${SISTEMA}."
    echo "INFORMACAO: Encaminhar SYSOUT para informationsecurity@nextel.com.br,access.controlgroup@nextel.com.br"
    exit 1
fi

if [ "`grep -c 'ORA-' ${LOG_SPOOL}`" -ne 0 ]
then
    echo "ERRO: Ocorreu um ERRO ORA- na geracao do relatorio do sistema ${SISTEMA}."
    echo "INFORMACAO: Encaminhar SYSOUT para informationsecurity@nextel.com.br,access.controlgroup@nextel.com.br"
    exit 1
fi

if [ "`grep -c 'Ok' ${LOG_SPOOL}`" -eq 1 ]
then
    echo "SUCESSO: Na geracao do sistema ${SISTEMA}."
fi

cd ${DIR_REL}
if [ "${?}" -ne 0 ]
then
    echo "ERRO: Ao acessar o diretorio ${DIR_REL}."
    exit 1
fi

RELATORIO="`ls -1 ${ARQ_REL} |tail -1`"

if [ -z "${RELATORIO}" ]
then
    echo "ERRO: O Relatorio ${ARQ_REL} nao foi gerado."
    exit 1
fi

if [ ! -f ${RELATORIO} ]
then
    echo "ERRO: O Relatorio ${RELATORIO} nao foi gerado."
    exit 1
else
    gzip ${RELATORIO}
fi

case ${SISTEMA} in
	       SSI)
		   EMAIL_REL="access.controlgroup@nextel.com.br,informationsecurity@nextel.com.br"
		   ;;
                 *)
                   EMAIL_REL="access.controlgroup@nextel.com.br,informationsecurity@nextel.com.br"
		   ;;
esac

echo "${EMAIL_REL}" |grep -v '^$' |while read EMAIL
do
    case ${SISTEMA} in
                   SSI)
                       DESC="Relatorio de Acessos Ativos Cadastrados no sistema ${SISTEMA} - Processado em `date +%Y/%m/%d` `date +%H:%M:%S`"
                       ;;
                     *)
                       DESC="Relatorio de Acessos Ativos no sistema ${SISTEMA} - Processado em `date +%Y/%m/%d` `date +%H:%M:%S`"
                       ;;
    esac
    #uuencode ${RELATORIO}.gz ${RELATORIO}.gz |mailx -s "${DESC}" ${EMAIL}
    #/amb/operator/bin/attach_mail ${EMAIL} ${RELATORIO}.gz "${DESC}"
    /amb/eventbin/attach_mail ${RELATORIO}.gz ${EMAIL} "${DESC}"
done

exit 0
