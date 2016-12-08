#!/bin/ksh

	# Finalidade	: Apurar tempos de execucao dos JOBs do Rating.
	# Input 	: Arquivos de log gerados pelos processos no diretorio /aplic/artx/prod/reports.
	# Output	: Relatorio XLS por email.
	# Autor		: Marcos de Benedicto
	# Data		: 17/10/2003

. /etc/appltab

set -A REL_TIME ind_0 ind_1 ind_2

DIR_WRK="${ENV_DIR_BASE_RTX}/prod/reports"
EMAIL="rating_time_control@unix_mail_fwd"
DATA_ANT="`/amb/eventbin/CALC_DATE.sh -1`"
DATA_D="`echo ${DATA_ANT} | cut -c1-2`"
DATA_M="`echo ${DATA_ANT} | cut -c3-4`"
DATA_Y="`echo ${DATA_ANT} | cut -c5-8`"
DATA="`echo ${DATA_D}-${DATA_M}-${DATA_Y}`"
RELATORIO="${DIR_WRK}/Tempos_rating_${DATA_ANT}.xls"

ind_0()
{
	# Montando relatorio.

	>${RELATORIO}
	echo "\n" >>${RELATORIO}
	printf "\t%s\n\n" "PROCESSAMENTO BCH" >>${RELATORIO}
	cat ${DIR_WRK}/BCH_${DATA_ANT}.txt >>${RELATORIO}
	echo "\n" >>${RELATORIO}

	echo "\n" >>${RELATORIO}
	printf "\t%s\n\n" "PROCESSAMENTO VERIFICA BCH" >>${RELATORIO}
	cat ${DIR_WRK}/VER_BCH_${DATA_ANT}.txt >>${RELATORIO}
	echo "\n" >>${RELATORIO}

	printf "\t%s\n\n" "PROCESSAMENTO CONTAS ZERADAS" >>${RELATORIO}
	cat ${DIR_WRK}/CONTAS_ZERADAS_${DATA_ANT}.txt >>${RELATORIO}
	echo "\n" >>${RELATORIO}

	printf "\t%s\n\n" "PROCESSAMENTO REL82_01" >>${RELATORIO}
	cat ${DIR_WRK}/82_01_${DATA_ANT}.txt >>${RELATORIO}
	echo "\n" >>${RELATORIO}

	printf "\t%s\n\n" "PROCESSAMENTO RODAGEL" >>${RELATORIO}
	cat ${DIR_WRK}/RODAGEL_${DATA_ANT}.txt >>${RELATORIO}
	echo "\n" >>${RELATORIO}

}

ind_1()
{
	# Envio de email.

	/amb/operator/bin/attach_mail ${EMAIL} ${RELATORIO} "BILLING SPOAXAP9 - Tempos de processamento - ${DATA}"

	[ $? -eq 0 ] && ${REL_TIME[2]} || exit 1	

}

ind_2()
{
	[ -n "${DIR_WRK}" -a -n "${DATA_ANT}" ] && rm -f ${DIR_WRK}/${DATA_ANT}.txt
	
	find ${DIR_WRK} -type f -mtime +60 -exec rm -f {} \;
}

${REL_TIME[0]}
${REL_TIME[1]}
