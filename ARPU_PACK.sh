#!/bin/ksh

	# Finalidade 	: Transferir arquivo do ARPU para máquina SPOAX004
	# Input 	: Arquivo ARPU
	# Output	: Arquivo ARPU na SPOAX004
	# Autor 	: Marcos de Benedicto
	# Data		: 03/07/2003

set -A ARP_PACK cmp_file rcp_file

	[ `hostname` = spoax004 ] && exit 0

SITE="$1"
CICLO="$2"
EMAIL="$3"
DESTINO="spoax004:/pinvoice/ARPU"
COD_SITE=`echo ${SITE} | cut -c1 | tr [a-z] [A-Z]`
CICLO=`printf "%02s\n" ${CICLO}`
DIR_ARPU="/pinvoice/ARPU"
ARQ_NAME=`ls ${DIR_ARPU}/BGH${COD_SITE}${CICLO}_??????????????.ARPU | tail -1 2>/dev/null` 
ARQ_NAME_GZ=`ls ${DIR_ARPU}/BGH${COD_SITE}${CICLO}_??????????????.ARPU.gz | tail -1 2>/dev/null`


cmp_file()
{
	set -x
	if [ -n "${ARQ_NAME}" ]

		then
		gzip -f ${DIR_ARPU}/BGH${COD_SITE}${CICLO}_??????????????.ARPU
		ARQ_NAME_GZ=`ls ${DIR_ARPU}/BGH${COD_SITE}${CICLO}_??????????????.ARPU.gz`

		fi

	if [ $? -ne 0 ]
		then	
		echo "ERRO! Compressao do arquivo do ARPU apresentou erro."
		exit 1
		fi

	if [ ! -f ${ARQ_NAME_GZ} ]

		then
		set +x
		echo "
	+-----------------------------------------------------------------------------------
	|
	|   ERRO!! `date`
	|   Processo nao criou arquivo BGH${COD_SITE}${CICLO}_??????????????.ARPU.gz
	|
	+-----------------------------------------------------------------------------------\n" | tee -a /tmp/mail_$$
		cat /tmp/mail_$$ | mailx -s "ERRO! Compressao do arquivo ARPU apresentou erro." ${EMAIL}
		exit 1
		fi
		}

rcp_file()
{

		set -x

		. /amb/eventbin/RCP_SEC.sh ${ARQ_NAME_GZ} ${DESTINO} ${EMAIL} 1 >/tmp/mail_$$ 2>&1
	
	if [ $? -ne 0 ] 
		
		then
		set +x
		echo "
	+----------------------------------------------------------------------------
	|
	|   ERRO! `date`
	|   RCP nao funcionou corretamente.
	|
	+----------------------------------------------------------------------------\n" | tee -a /tmp/mail_$$
		cat /tmp/mail_$$ | mailx -s "ERRO! RCP nao funcionou corretamente." ${EMAIL}
		exit 1
		fi

	}

${ARP_PACK[0]}
${ARP_PACK[1]}
