#!/bin/ksh

	# Finalidade : Validar se a data de processamento e >= a data de corte do ciclo
	# Input      : Flag do CLH
	# Output     : 
	# Autor      : Marcos de Benedicto
	# Data       : 13/09/2006

set +x

#--> CICLO_01 : 22
#--> CICLO_02 : 07
#--> CICLO_03 : 14
#--> CICLO_04 : 30
#--> CICLO_05 : XX
#--> CICLO_06 : XX
#--> CICLO_07 : 01
#--> CICLO_08 : 01
#--> CICLO_09 : 20
#--> CICLO_10 : XX
#--> CICLO_11 : 02
#--> CICLO_12 : 25
#--> CICLO_13 : 18
#--> CICLO_14 : 10
#--> CICLO_15 : 03
#--> CICLO_16 : 15
#--> CICLO_17 : 19

DIR_PAR=$0

CICLO=$2

DTFECHO=$(cat ${DIR_PAR} | grep "^#--> CICLO_${CICLO}" | awk '{print $4}')
DTATUAL=$(date +%d)

	if [ -z "${DTATUAL}" -o -z "${DTFECHO}" -o -z "${CICLO}" ]
	then
		echo "
		Parametros insuficientes
		DTATUAL=${DTATUAL}
		DTFECHO=${DTFECHO}
		CICLO=${CICLO}
		DTATRASO=${DTATRASO}
		DT_CORTE_CLH=${DT_CORTE_CLH}"
		exit 2
	fi


if [ ${DTATUAL} -eq ${DTFECHO} ]
then
echo "
	#==============================================================================================#
	# 
	#  Ciclo ${CICLO} dentro da data de execucao.
	#
	#   =====> Data Atual: ${DTATUAL}/$(date +%m/%Y)   Data Corte: ${DTFECHO}/$(date +%m/%Y)
	#
	#==============================================================================================#\n"
	exit 0

else
	echo "\n\n"
   	banner "ERRO!!"
   	echo   "
	#==============================================================================================#
	# 
	#   Sr Operador, este JOB esta sendo executado fora do periodo.
	#
	#   NAO DE CONTINUIDADE!!! Acinonar o analista.
	# 
	# 
	#   =====> Data Atual: ${DTATUAL}/$(date +%m/%Y)   Data Corte: ${DTFECHO}/$(date +%m/%Y)
	# 
	#
	#==============================================================================================#\n"
	exit 1
fi
