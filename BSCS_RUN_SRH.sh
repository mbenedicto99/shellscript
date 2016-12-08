#!/bin/ksh +x
export SRH_BASE_DIR=$(printcfg 17)
dir=${SRH_BASE_DIR}MP/RLH/SUPPRESSED
find $dir -name RTX*TMP -exec rm {} \;
rm -f ${SRH_BASE_DIR}/CTRL/SRHBC*IND
cd $dir

set +x

ls -d BC?? | while read ciclo
do
	rm -f ${SRH_BASE_DIR}/CTRL/SRHBC${cic}.IND

	srh -b ${cic} -t  1>/dev/null  2>/dev/null &
done

LOG_DATE=`date +%d%m%Y`
LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
LOG_TIME="${ENV_DIR_BASE_RTX}/prod/reports/SRH_${LOG_DATE}.txt"
COUNT_TIME=`find ${ENV_DIR_BASE_RTX}/prod/WORK/MP/RLH/SUPPRESSED/* -type f 2>/dev/null | wc -l`

printf "%s\t%s\t%s\t%s\n" "SRH" "Inicio do processamento, ${COUNT_TIME} arquivos." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

while true
do
ls -d BC?? | while read ciclo
do
	cic=$(echo $ciclo | cut -c 3-4)
	quan=$(ls $dir/$ciclo/*SUP 2>/dev/null | wc -l)

	if [ $quan -gt 0 ]
		then 
		
		veri=$(ps -ef | grep "srh -b ${cic} -t" | grep -v grep | wc -l)
		if [ $veri -eq 0 ] 
			then 
			rm -f ${SRH_BASE_DIR}/CTRL/SRHBC${cic}.IND
		
			srh -b ${cic} -t  1>/dev/null  2>/dev/null &
		fi
	fi

        fil=$(ls $dir/BC??/*SUP 2> /dev/null| wc -l)

	if [ $fil -eq 0 ]
		then
	  	ps -ef | grep "srh -b "| grep -v grep| while read a procx c
	  	do
	    		kill $procx
	  	done
  	echo "\nAcabou SRH\n"
	exit 0

        fi

	done
done

LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
COUNT_TIME=`find ${ENV_DIR_BASE_RTX}/prod/WORK/MP/RLH/SUPPRESSED/* -type f 2>/dev/null | wc -l`

printf "%s\t%s\t%s\t%s\n" "SRH" "Termino do processamento, ${COUNT_TIME} arquivos." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

