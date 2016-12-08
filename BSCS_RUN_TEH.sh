#!/bin/ksh


### Alterado em 2003/08/25 - Consolidacao MIBAS/BSCS

#. /etc/appltab 


### ARQCFG=/amb/eventbin/consolidacao/OK/bscs_batch.cfg
### ARQCFG=/amb/operator/cfg/consolidacao/bscs_batch.cfg

#ARQCFG=/amb/operator/cfg/bscs_batch.cfg
#SCPFUNC=/amb/operator/cfg/script_functions.cfg

# Le arquivo de paramentros
#. $ARQCFG

# VARIABLES

ARQTMP=/tmp/.teh_$$
DATA=`date`
N_TABELA="$1"

case ${N_TABELA} in

	1) TABELA="ISDEFTAB" ;; 
	2) TABELA="LKDEFTAB" ;; 
	3) TABELA="CODEFTAB" ;;
	4) TABELA="CCDEFTAB CNDEFTAB CSDEFTAB DZLSTTAB ECDEFTAB EGDEFTAB EPDEFTAB EVDEFTAB FFDEFTAB FIDEFTAB GSDEFTAB GZDEFTAB HBDEFTAB HLDEFTAB HODEFTAB HPDEFTAB IADEFTAB INDEFTAB IXDEFTAB MCDEFTAB NEDEFTAB NFDEFTAB PNDEFTAB PPMAPTAB PUDEFTAB RADEFTAB RGDEFTAB RIDEFTAB RMDEFTAB RUDEFTAB SBDEFTAB SGDEFTAB SVDEFTAB TCLSTTAB TKDEFTAB TZDEFTAB URDEFTAB UTDEFTAB XRDEFTAB ZODEFTAB ZPDEFTAB MPPROFIL" ;;
	5) TABELA="TMDEFTAB" ;;
	*) echo "ERRO - Tabela nao foi informada corretamente"
	   exit 1 ;;

esac

	## Tabela "LKDEFTAB" roda apos 15mins.
	## Para que nao haja concorrencia com a ISDEFTAB.
	#[ ${N_TABELA} -eq 2 ] && sleep 900


LOG_DATE=`date +%d%m%Y`
LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
#LOG_TIME="${ENV_DIR_BASE_RTX}/prod/reports/TEH_${LOG_DATE}.txt"
LOG_TIME="/aplic/artx/prod/reports/TEH_${LOG_DATE}.txt"

 if [ ${N_TABELA} -eq 4 ] 
 then
 TABELA_TIME="Tabelas pequenas"
 else
 TABELA_TIME="Tabela `echo ${TABELA}`"
 fi

printf "%s\t%s\t%s\t%s\n" "TEH" "Inicio do processamento - ${TABELA_TIME}" "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

for i in `echo ${TABELA}`
do
TEHCOMM="teh -t -f ${i}"


clear
echo "BSCS TABLE EXTRACT HANDLER - TEH - $DATA"
echo
echo "Comando: $TEHCOMM"
echo "------------------------------------------------------------------"
echo


###(
date
echo
echo "------------------------------------------------------------------"
echo "Executando comando: $TEHCOMM"
echo
echo ${TEHCOMM}
su - prod -c "${TEHCOMM}" >> $ARQTMP
echo
echo "------------------------------------------------------------------"
echo "Processo Terminado em: "`date`
echo "------------------------------------------------------------------"

###) >> $ARQTMP


done

LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"

printf "%s\t%s\t%s\t%s\n" "TEH" "Termino do processamento - ${TABELA_TIME}" "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

/amb/bin/msg_api2 "W-RATING-TEH-PROCESSAMENTO" <$ARQTMP

if grep ".ERR" $ARQTMP
then 
   exit 44
fi

[ -f $ARQTMP ] && rm $ARQTMP 
exit 0
