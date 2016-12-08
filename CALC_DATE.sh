#!/bin/ksh

	# Finalidade : Calcular datas anteriores e posteriores
	# Input : Numero de dias a retroceder
	# Output : Data - dias informados
	# Autor : Marcos de Benedicto
	# Data : 27/05/2003

N_IN="$1"

if [ ${N_IN} -gt 0 ]

then
	month=`date +%m`
	day=`date +%d`
	year=`date +%Y`
	let month=$month+0
	let day=$day+${N_IN}

	case $month in
		1|3|5|7|8|10|12) 
			if [ $day -le 31 ] 
				then
				continue

				else
				n_month=`expr $day / 31`
				n_day=`expr $n_month \* 31`
				day=`expr $day - $n_day`
				[ $day -eq 0 ] && day=1
				month=`expr $n_month + $month`

			fi
  			;;

    		4|6|9|11) 
			if [ $day -le 30 ]
				then
				continue

				else
				n_month=`expr $day / 30`
				n_day=`expr $n_month \* 30`
				day=`expr $day - $n_day`
				[ $day -eq 0 ] && day=1
				month=`expr $n_month + $month`
  			fi
   			;;

     		2)
  			if [ `expr $year % 4` -eq 0 ]
			then
				if [ $day -le 29 ]
				then 
				continue

				else
				n_month=`expr $day / 29`
				n_day=`expr $n_month \* 29`
				day=`expr $day - $n_day`
				[ $day -eq 0 ] && day=1
				month=`expr $n_month + $month`
				fi

			else
				if [ $day -le 28 ]
				then 
				continue

				else
				n_month=`expr $day / 28`
				n_day=`expr $n_month \* 28`
				day=`expr $day - $n_day`
				[ $day -eq 0 ] && day=1
				month=`expr $n_month + $month`
				fi
			fi
  			;;
  	esac

        if [ ${month} -gt 12 ]
	then
	let n_year=${month}/12
	let n_month=${n_year}\*12
	let month=${month}-${n_month}
	let year=${year}+${n_year}
	fi
                

else

N_IN=`expr ${N_IN} \* -1`

	if [ ${N_IN} -eq 1 -a `date +%m%d` -eq "0301" ]
	then
		if [ `expr $(date +%Y) % 4` -eq 0 ]
		then
		echo "2902`date +%Y`"
		else
		echo "2802`date +%Y`"
		fi
	exit 0
	fi

	if [ $# -ne 1 ]; then
  		echo Error: $0 invalid usage.
  		echo Usage: $0 n
  		exit 1
  		fi

 	n=`expr ${N_IN} + 0 2> /dev/null`
 
	if [ $? -ne 0 ]; then
 		qnbad=0
		elif [ $n -lt 0 ]; then
  		qnbad=0
  		
		else
    		qnbad=1
    		fi
    
	if [ $qnbad -eq 0 ]; then
     		echo Error: n must be a positive integer.
		echo Usage: $0 n
  		exit 1
	  	fi

  month=`date +%m`
  day=`date +%d`
  year=`date +%Y`
  month=`expr $month + 0`
  day=`expr $day - $n`
  
  while [ $day -le 0 ]
  do

  month=`expr $month - 1`
	if [ $month -eq 0 ]; then
    		year=`expr $year - 1`
		month=12
  		fi

	case $month in
    		1|3|5|7|8|10|12) day=`expr $day + 31`;;
		4|6|9|11) day=`expr $day + 30`;;
	    	02)
	  		if [ `expr $year % 4` -eq 0 ]; then
		  		if [ `expr $year % 400` -eq 0 ]; then
		    		day=`expr $day + 29`
	    			elif [ `expr $year % 100` -eq 0 ]; then
	      			day=`expr $day + 28`
		      		
				else
				day=`expr $day + 29`
				fi
	      			
				else
				day=`expr $day + 28`
				fi
				;;
	esac
			done


fi

		day=`printf "%02s" $day`
		month=`printf "%02s" $month`
		year=`printf "%04s" $year`

		echo $day$month$year

		 [ ${N_IN} = 0 ] && echo "\nInformar numero de dias corretamente.\n"

#End Shell!
