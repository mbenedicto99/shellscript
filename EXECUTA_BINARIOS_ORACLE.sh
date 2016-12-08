#!/bin/ksh

#----------- Variaveis -----------

JOB="$(echo $1 | cut -d"|" -f1)"	#CTM PARM1=%%JOBNAME|%%$ODATE
DATE="$(echo $1 | cut -d"|" -f2)"
BIN_DIR="$2"				#CTM PARM2="Diretorio de execucao"
BIN_FILE="$3"				#CTM PARM3=Binario
VAR=$(echo "$4" | sed 's#|# #g')	#CTM PARM4="opcao|var_1|var_2";
					#	====OPCOES====
					#	"null" -> para execucao de binario apenas com user/pass;
					#	"predef" -> para passar variaveis pre-definidas separadas por "|";
					#	"list" ->  para leitura de arquivos do dir "prd", pode ter variaveis adicionais;
RT="$5"					#CTM PARM5=Caso seja necessario retomar indicar neste parametro "retomada".

if [ $# -lt 4 ]
then
	echo "$0 <JOBNAME> <BIN_DIR> <BIN_FILE> <VAR (null|predef|list)> <Opcional:retomada>"
	exit 1
fi

set +x
. /u01/rms/batch/batch.profile
export UP="rms13/rms13@${ORACLE_SID}"
set -x

LOG_FILE="${LOGDIR}/$(date +%b_%d).log"

if [ -z "${ORACLE_SID}" -o -z "${ORACLE_HOME}" ]
then
	echo "ERRO! Variaveis do Oracle nao encontradas."
	exit 1
fi

#----------- Definicao do ARRAY -----------

set -A ARR return_code main chk_status chk_log prep_db exec_mfiles

set +x
echo "
	+--------------------------------------------------------------
	|
	|  Finalidade	: Oracle Retail - Controle de execucao
	|                 e padronizacao para Control-M.
	|
	|  Binario	: ${BIN_FILE}
	|  Parametros	: ${VAR}
	|  Input	: CTM Job
	|  Output	: Oracle Retail
	|  Autor	: Marcos de Benedicto
	|  Data		: 21/01/2011
	|  Alteracao	: 16/10/2011 (BRMB5)
	|
	|  Job		: ${JOB}
	|  PID		: $$
	|  Log EXEC	: ${LOG_FILE}
	|  Log ERRO	: ${ERR_FILE}
	|  Data Exec	: $(date)
	|
	+--------------------------------------------------------------\n"
set -x

#----------- Analise de RETURN CODE -----------

return_code()
{

        STATUS=$1
        MSG=$2

        if [ ${STATUS} -eq "1" ]
        then
        set +x
        echo "
	+---------------------------------------------------
	|
	|  ${MSG}
	|
	|  Binario : ${BIN_FILE}
	|
	|  Variaveis : ${VAR}
	|
	|  Log de Execucao : ${LOG_FILE}
	|
	|  $(date)
	|
	+---------------------------------------------------\n"
	echo "\n\n=====LOG APLICACAO====="
	grep "${BIN_FILE}" ${LOG_FILE} | tail -1
        ERR_FILE=$(ls -tr ${ERROR}/*${BIN_FILE}*$(date +%b_%d))
                if [ -f "${ERR_FILE}" ]
                then
                        echo "\n\n=====LOG ERRO====="
                        cat $(ls -rt ${ERR_FILE}) | tail -1
                fi
        exit 1
        fi

        if [ ${STATUS} -eq "0" ]
        then
        set +x
        echo "
	+---------------------------------------------------
	|
	|  Informacao
	|
	|  ${MSG}
	|
	|  Binario : ${BIN_FILE}
	|
	|  $(date)
	|
	+---------------------------------------------------\n"
	echo "\n\n=====LOG APLICACAO====="
	[ -f "${LOG_FILE}" ] && grep "${BIN_FILE}" ${LOG_FILE} | tail -2
        set -x
	exit 0
        fi

        if [ ${STATUS} -eq "2" ]
        then
        set +x
        echo "
	+---------------------------------------------------
	|
	|  Informacao
	|
	|  `date`
	|
	|  ${MSG}
	|
	+---------------------------------------------------\n"
        set -x
        fi

}

#----------- Vetores -----------

main()
{

	set -x

	#=============================================
	#Verifica estado inicial do binario no Oracle.
	#=============================================
	[ ${BIN_FILE} != "prepost" ] && ${ARR[2]} start

	#=================================================================================================
	#Caso Oracle nao esteja em "ready for start" este update FLAG coloca Oracle em estado de execucao.
	#=================================================================================================

	case ${STT} in

		"aborted"|"started")
		#=================================
		#Coloca FLAG=Y para nova execucao.
		#=================================
		[ "${RT}" == "retomada" ] && ${ARR[4]} RT || ${ARR[0]} 1 "ERRO! Necessario retomada."

		#==============================================
		#Verificando se retomada executou corretamente.
		#==============================================
		${ARR[2]} retomada
		;;

		"completed")
		#===========================================================================================
		#Caso binario esteja em completed eh feito um update para "ready for start" automaticamente.
		#===========================================================================================
		${ARR[4]} UP

		#============================================
		#Verificando se ajuste executou corretamente.
		#============================================
		${ARR[2]} ajustdb
		;;

	esac

	#=================================================
	#Identifica tipo de execucao, com ou sem variavel.
	#=================================================

	VAR_IN=$(echo ${VAR} | awk '{print $1}')
	[ -z "${VAR_IN}" ] && ${ARR[0]} 1 "ERRO! Tipo de processamento nao identificado."

	case ${VAR_IN} in

		#=================================================================
		#Executa binario, sem variaveis e sem arquivos de entrada.
		#=================================================================
		null)

                ${BIN_DIR}/${BIN_FILE} ${UP}
                RC=$?

		[ ${RC} -eq 0 ] && ${ARR[0]} 2 "Processo ${BIN_FILE} executado com sucesso."
		[ ${RC} -eq 1 ] && ${ARR[0]} 2 "Processo executado com RC=1, analisar log."
		[ ${RC} -gt 2 ] && ${ARR[0]} 1 "ERRO! ${BIN_FILE} nao executou corretamente."
		;;

		#============================================
		#Executa binario com variaveis pre-definidas.
		#============================================
		predef)

		#==================================
		#Consome identificador de execucao.
		#==================================
		VAR=$(echo ${VAR} | sed 's#predef##g')

                ${BIN_DIR}/${BIN_FILE} ${UP} ${VAR}
                RC=$?

		[ "${BIN_FILE}" == "prepost" -a ${RC} -eq 0 ] && ${ARR[0]} 0 "Processo \"${BIN_FILE} ${VAR}\" executado com sucesso."
		[ ${RC} -eq 0 ] && ${ARR[0]} 2 "Processo ${BIN_FILE} executado com sucesso."
		[ ${RC} -eq 1 ] && ${ARR[0]} 0 "Nao existem arquivos pendentes para  ${BIN_FILE}."
		[ ${RC} -gt 2 ] && ${ARR[0]} 1 "ERRO! ${BIN_FILE} nao executou corretamente."
		;;

		#==================================================================
		#Identifica binario com variaveis e analise de arquivos de entrada.
		#===========---====================================================
		list)

		#==================================
		#Consome identificador de execucao.
		#==================================
		VAR=$(echo ${VAR} | sed 's#list##g')

		export DIR_WRK="/u01/prd"
		export DIR_INPUT="${DIR_WRK}/in/${BIN_FILE}"
		export DIR_PROC="${DIR_INPUT}/${DATE}/proc"
		export DIR_REPROC="${DIR_INPUT}/${DATE}/reproc"
		export DIR_REJ="${DIR_INPUT}/${DATE}/rej"
		export DIR_OUT="${DIR_WRK}/out/${BIN_FILE}/${DATE}"

		mkdir -p ${DIR_INPUT}
		mkdir -p ${DIR_PROC}
		mkdir -p ${DIR_REPROC}
		mkdir -p ${DIR_REJ}
		mkdir -p ${DIR_OUT}

		#================================================================
		#Executa binario em looping passando variaveis e locais de saida.
		#================================================================
		${ARR[5]}

		[ ${RC} -ne "0" ] && ${ARR[0]} 1 "ERRO! ${BIN_FILE} nao executado corretamente."

		;;

		*) ${ARR[0]} 1 "ERRO! Parametro de execucao nao identificado.";;

	esac

	#===========================================
	#Verifica estado final do binario no Oracle.
	#===========================================
	[ ${BIN_FILE} != "prepost" ] && ${ARR[2]} end

	#==================
	#Imprime log final.
	#==================
	${ARR[3]}

}

chk_status()
{

set -x

EXEC="$1"
EXEC_SQL="/u01/prd/logs/${BIN_FILE}.sql"
EXEC_LOG="/u01/prd/logs/${BIN_FILE}.log"

echo "
set head off
select PROGRAM_STATUS from RESTART_PROGRAM_STATUS where PROGRAM_NAME = '${BIN_FILE}';
exit" >${EXEC_SQL} ; chmod 775 ${EXEC_SQL}

	sqlplus -S ${UP} @${EXEC_SQL} >${EXEC_LOG} 2>&1
	RC=$?

	cat ${EXEC_LOG}

	if [ ${RC} -ne "0" -o `grep -c "ORA" ${EXEC_LOG}` -ne 0 ]
	then
		${ARR[0]} 1 "$(printf "%s " `cat ${EXEC_LOG}`)"
	else
		STT=$(cat ${EXEC_LOG} | grep -v "^$" | awk '{print $1}')
		rm -f ${EXEC_SQL} ${EXEC_LOG}
	fi

	STT=$(echo ${STT} | awk '{print $1}')

	case ${STT} in

		"started")
			case ${EXEC} in

				"start")
				${ARR[0]} 2 "${BIN_FILE} em STARTED, necessario retomada."
				;;

				"end")
				${ARR[0]} 1 "${BIN_FILE} em STARTED, job com problema."
				;;

				"retomada"|"ajustdb")
				${ARR[0]} 1 "Job em STARTED retomada/ajuste nao alterou estado."
				;;
			esac
		;;

		"ready")
			${ARR[0]} 2 "${BIN_FILE} em \"ready for start\"."
			;;

		"aborted")
			case ${EXEC} in

				"end")
				${ARR[0]} 1 "${BIN_FILE} finalizou com erro!"
				;;

				"ajustdb"|"retomada")
				${ARR[0]} 2 "Ajuste de DB ${BIN_FILE}, flag de execucao em Y"
				;;

				"start")
				${ARR[0]} 2 "${BIN_FILE} esta em ABORTED."
				;;
			esac
		;;

 		"completed")
			case ${EXEC} in

				"start")
				${ARR[0]} 2 "${BIN_FILE} sera alterado de \"completed\" para \"ready for start\"."
				;;

				"end")
				${ARR[0]} 2 "${BIN_FILE} em \"completed\"."
				;;

				"ajustdb")
				${ARR[0]} 1 "${BIN_FILE} nao mudou status no Oracle."
				;;
			esac
		;;

		*) ${ARR[0]} 2 "Status nao detectado"
		;;

	esac

}

chk_log()
{
	set -x 

	[ "${BIN_FILE}" == "prepost" ] && NAME_CHK=$(echo ${VAR} | awk '{print $1}') 

	if [ $(grep "${BIN_FILE}" ${LOG_FILE} | tail -1 | egrep -c "Successfully|OK") -eq 1 ]
	then
		${ARR[0]} 0 "Processo executado com sucesso."
	else
		${ARR[0]} 1 "ERRO! Log nao apresentou mensagem de execucao com sucesso."
	fi

}

prep_db()
{


EXEC_PREP=$1
EXEC_SQL_PREP="/u01/prd/logs/${BIN_FILE}prep.sql"
EXEC_LOG_PREP="/u01/prd/logs/${BIN_FILE}prep.log"

	case ${EXEC_PREP} in

		RT)
		echo "update RESTART_PROGRAM_STATUS" >${EXEC_SQL_PREP}
		echo "set RESTART_FLAG = 'Y'" >>${EXEC_SQL_PREP}
		echo "where PROGRAM_NAME = '${BIN_FILE}';" >>${EXEC_SQL_PREP}
		echo "exit" >>${EXEC_SQL_PREP}
		chmod 775 ${EXEC_SQL_PREP}
		;;

		UP)
		echo "update RESTART_PROGRAM_STATUS" >${EXEC_SQL_PREP}
		echo "set PROGRAM_STATUS = 'ready for start'" >>${EXEC_SQL_PREP}
		echo "where PROGRAM_NAME = '${BIN_FILE}';" >>${EXEC_SQL_PREP}
		echo "exit" >>${EXEC_SQL_PREP}
		chmod 775 ${EXEC_SQL_PREP}
		;;

	esac


	sqlplus -S ${UP} @${EXEC_SQL_PREP} >${EXEC_LOG_PREP} 2>&1
	RC=$?

	cat ${EXEC_LOG_PREP}

	if [ ${RC} -ne "0" -o "`grep -c ORA ${EXEC_LOG_PREP}`" -ne 0 ]
	then
		${ARR[0]} 1 "$(printf "%s " `cat ${EXEC_LOG_PREP}`)"
	else
		${ARR[0]} 2 "Update Ok! ${BIN_FILE} pronto para execucao."
		rm -f ${EXEC_SQL_PREP} ${EXEC_LOG_PREP}
	fi

}

exec_mfiles()
{

set -x

	RC=0

	[ ${RT} == "retomada" ] && DIR_EXEC=${DIR_REPROC} || DIR_EXEC=${DIR_INPUT}


	if [ `echo "$(ls ${DIR_EXEC}/*.txt | wc -l) + $(ls ${DIR_EXEC}/*.dat | wc -l)" | bc` -eq "0" ]
	then
		echo "$(date +"%a %b %d %H:%M:%S") Program: ${BIN_FILE}: PID=$$: Nao existem arquivos para processamento." >>${LOG_FILE}
		${ARR[0]} 0 "Nao existem arquivos para processamento."
	else
		[ $(ls ${DIR_EXEC}/*txt | wc -l 2>/dev/null) -ne "0" ] && FILE_MASK="${DIR_EXEC}/*.txt"
		[ $(ls ${DIR_EXEC}/*dat | wc -l 2>/dev/null) -ne "0" ] && FILE_MASK="${DIR_EXEC}/*.dat"
	fi


	for FILE_IN in $(ls ${FILE_MASK})
	do

	HHMM=$(date +%H%M)
	FILE_NAME=$(basename ${FILE_IN})
	FILE_PROC="${DIR_PROC}/${FILE_NAME}.1"
	FILE_REJ="${DIR_REJ}/$(echo ${FILE_NAME} | sed -e 's#.txt#.rej#g' -e 's#.dat#.rej#g')-${HHMM}"
	FILE_OUT=${FILE_NAME}-${HHMM}


	mv ${FILE_IN} ${FILE_PROC}
	${BIN_DIR}/${BIN_FILE} ${UP} ${FILE_PROC} ${FILE_REJ} ${VAR}
	RC_BIN=$?


	if [ ${RC_BIN} -eq "0" ]
	then
		mv ${FILE_PROC} ${DIR_OUT}/${FILE_OUT}
		${ARR[0]} 2 "OK! Arquivo ${FILE_NAME} processado."
		${ARR[4]} UP
	else
		mv ${FILE_PROC} ${DIR_REPROC}/${FILE_OUT}
		${ARR[0]} 2 "ERRO! ${BIN_FILE} falhou, arquivo ${FILE_NAME}."
	fi


	done

}

#----------- Exec Vetores -----------

${ARR[1]}
