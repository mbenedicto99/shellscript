#!/bin/ksh

	# Finalidade 	: Comprimir diretorios do /pinvoice com arquivos de Billing e enviar conteudo para SPOAXAP6.
	# Input 	: Arquivos ARPU
	# Output 	: SPOAXAP6:/carga_arpu
	# Autor 	: Marcos de Benedicto
	# Data 		: 28/06/2004

set -A PACK env_pack send_file chk_file unpack_file

SITE=RJ
CICLO=${1}
DIR_VAR=${2}

#DIR_VAR=20040805.013218
#
#	if [ -z ${DIR_VAR} ]
#	then
#	[ `echo ${DIR_VAR} | cut -c1-2` -ne 20 ] && exit 0
#	fi
	
SERVER_DEST="pastg"
DIR_LOC="/pinvoice"
#DIR_ARPU="/pinvoice/ARPU"
DIR_ARPU="/tmp/ARPU"
DIR_DEST="/carga_arpu"
DEST="${SERVER_DEST}:${DIR_DEST}"
EMAIL="prodmsol@nextel.com.br"
PROCSS="ARPU_PACK"
HOST=`uname -n`

cd ${DIR_LOC}
[ `pwd` != "${DIR_LOC}" ] && exit 1

[ -z "${CICLO}" ] && exit 1

[ ! -d ${DIR_ARPU} ] && mkdir -p ${DIR_ARPU}

##>/tmp/TS_CICLO.tmp

	#if [ -z "${DIR_VAR}" ]
	#then
		#for i in `ls | grep "2004*"`
		#do
		#set +x
		#CICLO_FILE=`ls $i/data/RJ`
		#TS=$i
		#echo "$i ciclo ${CICLO_FILE}" >>/tmp/TS_CICLO.tmp
		#done

	set -xv
	#STRING="ciclo ${CICLO}"
	#DIR_VAR=`cat /tmp/TS_CICLO.tmp | grep "${STRING}" | tail -1 | awk '{print $1}'`
	#[ $? -ne 0 ] && exit 1 || rm -f /tmp/TS_CICLO.tmp
	#echo "\n TIME STAMP=${DIR_VAR} \n"
	#else
	#echo "\n TIME STAMP=${DIR_VAR} \n"
	#fi

	if [ ${HOST} != sposnap7 -a ${HOST} != sposnap4 -a ${HOST} != sposnap6 ]
	then
	    echo "ERRO: Hostname invalido!!"
	    exit 1
	fi

env_pack()
{

	set -vx

	##CICLO=`ls ${DIR_LOC}/${DIR_VAR}/data`

	mkdir -p ${DIR_ARPU}/${DIR_VAR}/${CICLO}

	find ${DIR_LOC}/${DIR_VAR}/data/${CICLO} -name CUST*xml >${DIR_ARPU}/${DIR_VAR}/list_xml.txt

	for XML_FILES in `cat ${DIR_ARPU}/${DIR_VAR}/list_xml.txt`
	do
	    cp ${XML_FILES} ${DIR_ARPU}/${DIR_VAR}/${CICLO}
	done

	cd ${DIR_ARPU}
	[ `pwd` != "${DIR_ARPU}" ] && exit 1

	tar cf ${DIR_VAR}.tar ./${DIR_VAR} >/tmp/pack_err.$$ 2>&1

	if [ $? -ne 0 -o ! -f ${DIR_ARPU}/${DIR_VAR}.tar ]
	then
	    cat /tmp/pack_err.$$ >/tmp/mail_$$
	    echo "
	        +------------------------------------------------------
	        |
	        |   ERRO! `date` 
	        |   TAR nao executou corretamente!
	        |   Verificar se servidor tem espaco suficiente.
	        |
	        +------------------------------------------------------\n" | tee -a /tmp/mail_$$
	    df -k /aplic/pinvoice | grep "100%" | tee -a /tmp/mail_$$
	    [ `grep -c "100%" /tmp/mail_$$` -eq 1 ] && echo "FILESYSTEM EM 100%!!!!" | tee -a /tmp/mail_$$
	    cat /tmp/mail_$$ | mailx -s "${PROCSS} - Processo de TAR nos arquivos apresentou problema." ${EMAIL}
	    rm -f /tmp/*$$ 
	    exit 1
	fi

}

send_file()
{

	set -x 
	su transf -c "rcp ${DIR_ARPU}/${DIR_VAR}.tar ${DEST}" >/tmp/rcp_err.$$ 2>&1
	RC=$?

	if [ ${RC} -ne 0 ]
	then
	cat /tmp/rcp_err.$$ >/tmp/mail_$$
	echo "
	+----------------------------------------------------------
	|
	|   ERRO! `date` 
	|   Arquivo nao foi transferido corretamente.
	|
	+----------------------------------------------------------\n" | tee -a /tmp/mail_$$
	cat /tmp/mail_$$ | mailx -s "${PROCSS} - RCP nao funcionou corretamente." ${EMAIL}
	rm -f /tmp/*$$
	exit 1
	fi
}

chk_file()
{
	set -vx
	su transf -c "remsh ${SERVER_DEST} ls -la ${DIR_DEST}/${DIR_VAR}.tar" >/tmp/flag_$$ 2>&1

	R_ARQ=`cat /tmp/flag_$$ | awk '{print $5}'`
	L_ARQ=`ls -al ${DIR_ARPU}/${DIR_VAR}.tar | awk '{print $5}'`

	TOT_CHK=`expr ${L_ARQ} - ${R_ARQ}`

	if [ ${TOT_CHK} -eq 0 ]
	then
	set +x
	echo "
	Arquivo local igual a arquivo remoto.
	Limpando arquivo local.\n"
	set -x

	cd ${DIR_ARPU}
	[ -n "${DIR_ARPU}" -a -n "${DIR_VAR}" ] && rm -Rf ${DIR_ARPU}/${DIR_VAR} /tmp/*$$

	else
	cat /tmp/flag_$$ >/tmp/mail_$$
	echo "
	+-------------------------------------------------------------
	|
	|   ERRO! 
	|   `date`
	|   Arquivo local e diferente do arquivo remoto.
	|
	+-------------------------------------------------------------\n" | tee -a /tmp/mail_$$
	cat /tmp/mail_$$ | mailx -s "${PROCSS} - Validacao do RCP apresentou erro." ${EMAIL}
	rm -f /tmp/*$$
	exit 1
	fi
}

unpack_file()
{
	set -vx

	#su transf -c "remsh ${SERVER_DEST} rm -f ${DIR_DEST}/${DIR_VAR}.tar"

	[  -n "${DIR_ARPU}" -a -n "${DIR_VAR}" ] && rm -f ${DIR_ARPU}/${DIR_VAR}.tar

}

${PACK[0]}
${PACK[1]}
${PACK[2]}
${PACK[3]}

#End Shell

