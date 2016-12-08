#!/bin/ksh

	# Finalidade	: Chamar BSCS_RUN_RLH_ALL.sh ou BSCS_RUN_RLH_BC.sh
	# Input		: RIH
	# Output	: PRH e SRH
	# Autor		: Marcos de Benedicto
	# Data		: 03/11/2003

set -A CHK_RLH ind_0 ind_1

DIR="/aplic/artx/prod/WORK/MP/RTX/HPLMN"

ind_0()
{

	set -x

	for RUN in 01 02 03 04 06 07 08 10 11 12 13 14
	do

		COUNT_BCH=`ps -ef | grep -i -c "bch"`
		let COUNT=${COUNT_BCH}-1

		if [ ${COUNT} -eq 0 ] 
		then
		. /amb/eventbin/BSCS_RUN_RLH_ALL.sh
		DEFAULT=1

		else
		. /amb/eventbin/BSCS_RUN_RLH_BC.sh ${RUN}

		fi
	done
	
	[ $? -eq 0 ] && ${CHK_RLH[1]} || exit 1

}

ind_1()
{


	. /etc/appltab
	DIR="/aplic/artx/prod/WORK/MP/RTX/HPLMN"
	SQL=/tmp/sql_$$.sql

	set -x
	cd ${DIR}
	[ `pwd` != "${DIR}" ] && exit 1

	COUNT_BC=`ls BC*/RTX* | wc -l`
	
	if [ ${COUNT_BC} -ne 0 ]
	then
	echo "Limpando tabela do BILLCYCLE ${BC} para nova execucao."

	echo "
	UPDATE RTXCYTAB set rlh_pid=null;" >${SQL}

	chmod 777 ${SQL}

	export PASSWD=`awk '/^RLH/ {print $2}' ${ENV_DIR_BASE_RTX}/prod/batch/bin/bscs.passwd`
	export TWO_TASK="${ENV_TNS_PDRTX}"
	export ORACLE_HOME="${ENV_DIR_ORAHOME_RTX}"
	export NLS_LANG="${ENV_NLSLANG_PDRTX}"

	. /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${PASSWD}" "${SQL}" marcos@unix_mail_fwd "Limpeza da tabela RLH para nova execucao." 0 RLH 0


	fi

}

${CHK_RLH[0]}
		

