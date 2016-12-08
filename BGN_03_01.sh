#!/bin/ksh

	# Finalidade    : CHG5614 - Monitora STATUS da execucao da qualificacao de clientes.
	# Input         : BGN_03_01.sh
	# Output        : mail, log
	# Autor         : Marcos de Benedicto
	# Data          : 10/02/2006

set +x

. /etc/appltab

banner ${$}

COD="BGN_03_01"
SPOOL="/tmp/${COD}.spool"
SQL="/amb/scripts/sql/${COD}.sql"
EMAIL="prodmsol@nextel.com.br"
DESC="${COD} - Monitora STATUS da execucao da qualificacao de clientes."

export USRPASS="/"
export ORACLE_HOME="${ENV_DIR_ORAHOME_PNXTL01}"
export NLS_LANG="${NLS_NLSLANG_PNXTL01}"
export TWO_TASK="${ENV_TNS_PNXTL01}"
export ORACLE_SID="${ENV_ORA_PNXTL01}"

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
        |   ORACLE_SID = ${ORACLE_SID}
        |   TWO_TASK = ${TWO_TASK}
        |   ORACLE_HOME = ${ORACLE_HOME}
        |
        +------------------------------------------------\n"

[ -z "${SQL}" ] && exit 1
[ -z "${EMAIL}" ] && exit 1
[ -z "${DESC}" ] && exit 1
[ -z "${ORACLE_SID}" ] && exit 1
[ -z "${ORACLE_HOME}" ] && exit 1
[ -z "${USRPASS}" ] && exit 1

#---------------------
# Executa Select para capturar STATUS da execucao da qualificacao
#---------------------

. /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL}" "${EMAIL}" "${DESC}" 0 "${DESC}" "${SPOOL}"

STATUS="`egrep -c '41' ${SPOOL}`"

while [ ${STATUS} -eq 0 ]
do
    sleep 10
    if [ "`egrep -c '42|43' ${SPOOL}`" -ne 0 ]
    then
        echo "ERRO: Ocorreu algum problema no processamento!!!"
        echo "      Seguir procedimento da documentacao do JOB."
        cat ${SPOOL}
        [ -f ${SPOOL} ] && rm -f ${SPOOL}
        exit 1
    fi

    SPOOL="/tmp/${COD}.spool"

    export USRPASS="/"
    export ORACLE_HOME="${ENV_DIR_ORAHOME_PNXTL01}"
    export NLS_LANG="${NLS_NLSLANG_PNXTL01}"
    export TWO_TASK="${ENV_TNS_PNXTL01}"
    export ORACLE_SID="${ENV_ORA_PNXTL01}"

    . /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USRPASS}" "${SQL}" "${EMAIL}" "${DESC}" 0 "${DESC}" "${SPOOL}"

    STATUS="`egrep -c '41' ${SPOOL}`"
    cat ${SPOOL}
    echo "STATUS = ${STATUS}"
done

[ -f ${SPOOL} ] && rm -f ${SPOOL}

exit 0
