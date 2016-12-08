#!/bin/ksh

	# Finalidade	: Enviar estado de Jobs para monitor COTI.
	# Autor		: Marcos de Benedicto
	# Data		: 27/04/2014
	# Input		: Job de extracao de processos NOTOK.
	# Output	: URL para insert sistema COTI.

set -A EXEC rc parse send

DIR_WRK=${DIR}
FILE_ORI="${DIR_WRK}/FILE"
FILE_SND="${DIR_WRK}/FILE"
URL_COTI="http://xxx"

DIR_WRK=$(pwd)
FILE_ORI="${DIR_WRK}/t.txt"
FILE_SND="${DIR_WRK}/t2.txt"
URL_COTI="http://xxx"

rc()
{
set -x
	RC=$1

	case ${RC} in
		01) MSG="OK - STEP1 preparacao de envio.";;
		02) MSG="OK - STEP2 envio concluido.";;
		1) MSG="ERRO - URL apresentou problema.";;
		2) MSG="ERRO - Parse apresentou problema.";;
		3) MSG="ERRO - Arquivo de entrada nao encontrado.";;
		4) MSG="ERRO - Arquivo de saida nao encontrado.";;
	esac

	echo "
	####################################################
	#
	# ${MSG}
	#
	# $(date)
	#
	####################################################
	"
	[ $(echo ${RC} | cut -c1) -ne 0 ] && exit ${RC}
}

parse()
{
	[ -f ${FILE_ORI} ] || ${EXEC[0]} 3

	awk -F":" '{print $1, $2, $3}' <${FILE_ORI} | while read CP1 CP2 CP3
	do
		[ -z ${CP2} ] && continue
		[ ${CP1} == "TABLE" ] && TABLE=${CP2}
		[ ${CP1} == "JOBNAME" ] && JOBNAME=${CP2} STATUS=${CP3}
		[ -z ${JOBNAME} ] && continue
		echo ${TABLE}:${JOBNAME}:${STATUS}
	done >${FILE_SND}
	
	[ $? -ne 0 ] && ${EXEC[0]} 2 || ${EXEC[0]} 01

	${EXEC[2]}
	
}

send()
{

	[ -f ${FILE_SND} ] || ${EXEC[0]} 4

	awk -F":" '{print $1, $2, $3}' <${FILE_SND} | while read TABLE JOBNAME STATUS
	do
		echo "curl ${URL_COTI}?jobname=${TABLE}-${JOBNAME}?status=${STATUS}"
		curl ${URL_COTI}?tabela=${TABLE}?jobname=${JOBNAME}?status=${STATUS}
		[ $? -ne 0 ] && ${EXEC[0]} 1
	done

	${EXEC[0]} 02
}

${EXEC[1]}
