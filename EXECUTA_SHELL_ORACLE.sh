#!/bin/ksh

#----------- Variaveis -----------

JOB="$(echo $1 | cut -d"|" -f1)"	#CTM PARM1=%%JOBNAME|%%$ODATE
DATE="$(echo $1 | cut -d"|" -f2)"
SHELL_DIR="$2"				#CTM PARM2="Diretorio de execucao"
SHELL_NAME="$3"				#CTM PARM3=Shell
VAR=$(echo "$4" | sed 's#|# #g')	#CTM PARM4="var_1|var_2|...";

if [ $# -lt 3 ]
then
	echo "$0 <JOBNAME> <SHELL_DIR> <SHELL_NAME> <Opt:VAR>"
	exit 1
fi

set +x
. /u01/rms/batch/batch.profile
export UP="rms13/rms13@${ORACLE_SID}"
set -x

cd ${SHELL_DIR}

LOG_DIR="/u01/rms/batch/RETLforRPAS/log"
SH_NAME=$(echo ${SHELL_NAME} | sed -e 's#.ksh##g')

LOG_EXEC="/u01/prd/logs/${SHELL_NAME}.log"
>${LOG_EXEC}

if [ -z "$ORACLE_SID" -o -z "$ORACLE_HOME" ]
then
	echo "
	Variaveis do Oracle nao encontradas.
	ORACLE_SID=$ORACLE_SID
	ORACLE_HOME=$ORACLE_HOME"
	exit 1
fi

[ -z "${VAR}" ] && VAR=""

#----------- Definicao do ARRAY -----------

set -A ARR return_code main chk_status chk_log

set +x
echo "
	+--------------------------------------------------------------
	|
	|  Finalidade	: Oracle Retail - Controle de execucao
	|                 e padronizacao para Control-M.
	|
	|  Shell	: ${SHELL_NAME}
	|  Parametros	: $@
	|  Input	: CTM Job
	|  Output	: Oracle Retail
	|  Autor	: Marcos de Benedicto
	|  Data		: 11/04/2011
	|  Alteracao	: 16/10/2011 (BRMB5)
	|
	|  Job		: ${JOB}
	|  Log EXEC	: ${LOG_FILE}
	|  Data Exec	: $(date)
	|
	+--------------------------------------------------------------\n"
set -x

#----------- Analise de RETURN CODE -----------

return_code()
{

        STATUS=$1
        MSG=$2

        if [ ${STATUS} -eq 1 ]
        then
        set +x
        echo "
        +---------------------------------------------------
        |
        |  ERRO!
        |
        |  Processo nao executou corretamente.
        |
        |  Script	: ${SHELL_NAME}
        |
        |  $(date)
        |
        +---------------------------------------------------\n"
        echo "\n\n=====EXEC====="
        cat ${LOG_EXEC}
        echo "\n\n=====LOG====="
        grep "${SH_NAME}" ${LOG_FILE}
	ERR_FILE=$(ls -tr ${ERROR}/*${SH_NAME}*$(date +%b_%d))
        	if [ -f "${ERR_FILE}" ]
        	then
                	echo "\n\n=====ERROR LOG====="
                	cat ${ERR_FILE} | tail -1
        	fi
	exit 1
	fi

        if [ ${STATUS} -eq 0 ]
        then
        set +x
        echo "
        +---------------------------------------------------
        |
        |  Informacao
        |
        |  Processo concluido com sucesso.
        |
        |  Script	: ${SHELL_NAME}
        |
        |  $(date)
        |
        +---------------------------------------------------\n"
        echo "\n\n=====LOG EXEC====="
        cat ${LOG_EXEC}
        echo "\n\n=====LOG====="
        grep "${SH_NAME}" ${LOG_FILE}
        set -x
	exit 0
        fi

}

#----------- Vetores -----------

main()
{

	set -x

	OPT=$(echo ${VAR} | awk '{print $1}')
	VAR=$(echo ${VAR} | sed -e 's#predef##g' -e 's#noup##g')
	LOG_DATE=$(date +"%Y%m%d")

	if [ "${OPT}" != "noup" ]
	then
		/bin/ksh -x ${SHELL_DIR}/${SHELL_NAME} ${UP} ${VAR} >>${LOG_EXEC} 2>> ${LOG_EXEC} &
	else
		/bin/ksh -x ${SHELL_DIR}/${SHELL_NAME} ${VAR} >>${LOG_EXEC} 2>> ${LOG_EXEC} &
	fi

	[ $? -eq 0 ] && ${ARR[2]} || ${ARR[0]} 1 "Execucao apresentou problema."

}

chk_status()
{

	set -x

	ps -ef | grep -v "grep" | awk '$3 ~ '$$' {print $0}' | grep ${SHELL_NAME}

	set +x

	while [ $(ps -ef | grep -v "grep" | awk '$3 ~ '$$' {print $0}' | grep -c ${SHELL_NAME}) -ne 0 ]
	do
		set +x
        	printf "."
        	sleep 1
	done

	set -x

	${ARR[3]}

}

chk_log()
{

	set -x

	if [ $(ls ${LOGDIR}/$(date +%b_%d).$(echo ${SHELL_NAME} | sed 's#.ksh##g').log | wc -l) -ne 0 ]
	then
		LOG_FILE="${LOGDIR}/$(date +%b_%d).$(echo ${SHELL_NAME} | sed 's#.ksh##g').log"
		SQL_LOAD=1
	else
		LOG_FILE="${LOGDIR}/$(date +%b_%d).log"
		SQL_LOAD=0
	fi

	if [ $(egrep -c "Cannot|ORA-[0-9][0-9][0-9][0-9][0-9]" ${LOG_EXEC}) -ne 0 ]
	then
		${ARR[0]} 1 "Log apresentou problema." || ${ARR[0]} 0 "Execucao Ok."
	fi

	PROC=$(echo ${SHELL_NAME} | sed -e 's#.ksh##g')

	[ "${SHELL_NAME}" == "batch_cea_exp_attr_lists.ksh" ] && PROC=$(echo ${SHELL_NAME} | sed -e 's#.ksh##g' -e 's#batch_##g')

	if [ ${SQL_LOAD} -eq 1 ]
	then
		if [ $(grep -ic "ORA-[0-9][0-9][0-9][0-9][0-9]" ${LOG_FILE}) -eq 0 ]
		then
			if [ $(grep -ic "exit.0" ${LOG_EXEC}) -ne 0 ]
			then
				${ARR[0]} 0 "Processo executado com sucesso."
			else
				${ARR[0]} 1 "ERRO! Return Code diferente de 0."
			fi
		else
			${ARR[0]} 1 "ERRO! Erro no Loader."
		fi
	fi


	[ "${OPT}" == "noup" ] && LOG_FILE=${LOG_DIR}/${LOG_DATE}.log

	[ -f "${LOG_FILE}" ] || ${ARR[0]} 1 "ERRO! Log nao encontrado."

	if [ $(grep "${PROC}" ${LOG_FILE} | tail -1 | egrep -ci "Successfully|OK") -eq 1 ]
	then
		${ARR[0]} 0 "Processo executado com sucesso."
	else
		${ARR[0]} 1 "ERRO! Processo nao executou corretamente."
	fi


}


#----------- Exec Vetores -----------

${ARR[1]}
