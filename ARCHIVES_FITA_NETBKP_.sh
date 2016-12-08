#!/usr/bin/ksh
#SCRIPT: /amb/eventbin/ARCHIVES_FITA_NETBKP.sh
#AUTOR: AMauricio Sanches - 28/08/06
#OBS      : Script para Limpar area de Archives de Banco Oracle
#INPUT: <Politica> <Scheduler> <Config_File>   
#OUTPUT: Validacao do Return Code para CONTROLM
#ALTERADO:

#VARIAVEIS
#---------
HOST=$1
POLITICA=$2
DATA_BKP=$3
PATH=$PATH:/usr/openv/netbackup/bin

#VERIFICA A EXISTENCIA DO EXECUTAVEL
#-----------------------------------
if [ ! -f /usr/openv/netbackup/bin/bplist ]
then
   echo "Nao possui software de backup"
   exit 1
fi

#PROCESSO
#--------
/usr/openv/netbackup/bin/bplist -B -C ${HOST} -S pabkp -t 0 -k ${POLITICA} -R -b -l -s ${DATA_BKP} | awk '{print $8}' | egrep ".gz"
if [ $? -eq 0 ]
	then
		 echo "Sucesso na execucao do comando BPLIST"
		 exit 0
	else
	   echo "ERRO: Na execucao do comando BPLIST"
     exit 2
fi

#FIM
#---
