#!/bin/ksh

	# Finalidade	: Gerar FLAG com numero de CUST para ARPU.
	# Input		: /carga_arpu SPOAXAP6
	# Output	: /carga_arpu/TXT/"TIMESTAMP".txt
	# Autor		: Marcos de Benedicto
	# Data		: 16/06/2004

DIR_ORI="/carga_arpu"
TXT="TXT"
LST="/tmp/lst.txt"

set -A GERA_FLAG ind_0 ind_1 ind_2

ind_0()
{
RC=$1
DIR_TS=$2

	if [ ${RC} -eq 1 ]
	then
	echo "\n ERRO! Nao foram encontrados XML no diretorio. \n"
	exit 1
	fi
	
	if [ ${RC} -eq 2 ]
	then
	echo "\n ERRO! Arquivo ${DIR_TS}.txt nao foi criado. \n"
	exit 1
	fi

}

ind_1()
{

	set -vx

	cd ${DIR_ORI}
	[ `pwd` != "${DIR_ORI}" ] && exit 1

	for DIR_TAR in `ls /carga_arpu/*tar`
	do
	TS=`echo ${DIR_TAR} | sed 's/.tar//g' | awk -F/ '{print $(NF)}'`

	tar xf ${DIR_TAR}
	[ $? -eq 0 ] && rm -f ${DIR_TAR}

	# Verificando numero de XMLs.

	LINE_VAL=`cat /carga_arpu/${TS}/list_xml.txt | wc -l`
	CICLO=`cat /carga_arpu/${TS}/list_xml.txt | head -1 | awk -F/ '{print $5}'`
	FILE_VAL=`ls /carga_arpu/${TS}/${CICLO} | wc -l`

	[ ${LINE_VAL} -eq ${FILE_VAL} ] && echo "Numero de XMLs OK.\n" || exit 1

	done
}

ind_2()
{
set -x

for DIR in `ls ${DIR_ORI} | grep -v "TXT"`
do

	[ -f ${DIR_ORI}/${TXT}/${DIR}.txt -o `echo ${DIR} | cut -c1-2` != 20 ] && continue

	find ${DIR_ORI}/${DIR} -type f -name *xml -exec ls {} \; >${LST}
	[ ! -s /tmp/lst.txt ] && ${GERA_FLAG[0]}

	cat ${LST} | awk -F"/" '{print $(NF)}' | sed -e 's/CUST//g' -e 's/.xml//g' >${DIR_ORI}/${TXT}/${DIR}.txt
	[ ! -f ${DIR_ORI}/${TXT}/${DIR}.txt ] && ${GERA_FLAG[0]} 2 ${DIR} 

	chmod 755 ${DIR_ORI}/${TXT}/${DIR}.txt
	chown transf:transf ${DIR_ORI}/${TXT}/${DIR}.txt

	done

}


${GERA_FLAG[1]}
${GERA_FLAG[2]}
