#!/bin/ksh

	# Finalidade	: Ordena arquivos para carga do ARPU.
	# Input		: /carga_arpu/TXT
	# Output	: /pinvoice/"TIMESTAMP"
	# Autor		: Marcos de Benedicto
	# Data		: 28/06/2004

DIR_ORI="/carga_arpu/TXT"
DIR_WRK="/carga_arpu"
LST="/tmp/lst.txt"

set -A ORD_FILES ind_0 ind_1

ind_0()
{
RC=$1
DIR_TS=$2

	if [ ${RC} -eq 1 ]
	then
	echo "\n ERRO! Lista de arquivos nao foi gerada. \n"
	exit 1
	fi
	
	if [ ${RC} -eq 2 ]
	then
	echo "\n Move de arquivos XML apresentou erro. \n"
	exit 1
	fi

}

ind_1()
{
set -x
for DIR in `ls -tr ${DIR_ORI}/20* | awk -F"/" '{print $(NF)}' | sed 's/.txt//g' | tail -1`
do

	[ `echo ${DIR} | cut -c1-2` != 20 -o ! -d ${DIR_WRK}/${DIR}/data ] && continue

	find ${DIR_WRK}/${DIR} -type f -name *xml >/tmp/lst_${DIR}.txt
	[ ! -s /tmp/lst_${DIR}.txt ] && ${GERA_FLAG[0]} 1

	cat /tmp/lst_${DIR}.txt | grep "data" >/tmp/lst_${DIR}2.txt
	
	CICLO=`ls ${DIR}/data/RJ`
	
	if [ ! -s /tmp/lst_${DIR}2.txt ] 
	then
	"\n Nao existem arquivos para mover no TIME STAMP ${DIR}. \n"
	#rm -f /tmp/lst_${DIR}2.txt /tmp/lst_${DIR}.txt
	continue
	fi

	mkdir -p ${DIR_WRK}/${DIR}/RJ/${CICLO}
	[ $? -ne 0 ] && exit 1

		cat /tmp/lst_${DIR}2.txt | while read x
		do
		[ -f ${DIR_WRK}/${DIR}/$x ] && echo "Arquivo ja foi movido." || mv $x ${DIR_WRK}/${DIR}/RJ/${CICLO}
		done

	rm -Rf ${DIR_WRK}/${DIR}/data

	set +x
	chmod 755 ${DIR_WRK}/${DIR}/*xml
	chown transf:transf ${DIR_WRK}/${DIR}/*xml
	set -x

done

}

${ORD_FILES[1]}
