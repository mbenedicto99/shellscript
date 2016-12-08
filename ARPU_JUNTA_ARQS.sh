#!/bin/ksh

	# Finalidade : Unir arquivos faturas.
	# Input : Arquivos de Fatura de clientes.
	# Output : /pinvoice/BGH/ARPU*
	# Autor : Marcos de Benedicto
	# Data : 21/05/2003

set -A JUNT chk_var lst_file lst_merc jnt_file lmp_file

DIA=`date "+%d%m%Y"`
T_STAMP=`date +%H%M%S`
SUBJ="ARPU - Uniao de faturas ARPU. - `date`"
MASK_FILE="CUST*arpu"
TOT_CLI="0"
DIR_ARPU="/pinvoice/ARPU"

INP_SITE=$1

chk_var()
{

case ${INP_SITE} in
     
     	SP ) SITE="SP"
	    COD_SITE="S"
	    ;;
	
	RJ ) SITE="RJ"
            COD_SITE="R"
	    ;;

	*) echo "\nERRO! Parametro informado incorretamente."
	   echo "Informar o parametro : RJ ou SP\n"
	   exit 1  ;;

	esac

		}

lst_file()
{

	find /pinvoice/$(cat /pinvoice/diretorios/${SITE})/data -name ${MASK_FILE} > /pinvoice/LOG/junta_$$.arpu
	RC=$?
		if [ ${RC} -gt 0 ]

			then
			echo "\nERRO! Nao foram localizados arquivos de Clientes.\n"
			exit 3

			fi
	}


lst_merc()
{

	cat /pinvoice/LOG/junta_$$.arpu | cut -f 1-9 -d"/" | sort -u > /pinvoice/LOG/mercs_$$.arpu
	}


jnt_file()
{

	set -x

	cat /pinvoice/LOG/mercs_$$.arpu | while read dir 
	do
	CICLO=`echo $dir | cut -f 6 -d"/"`
	N_MERC=`echo $dir | cut -f 9 -d"/"`
	#ARQ_NAME="${DIR_ARPU}/BGH${COD_SITE}${CICLO}${N_MERC}_${DIA}${T_STAMP}.ARPU" 
	ARQ_NAME="${DIR_ARPU}/BGH${COD_SITE}${CICLO}_${DIA}${T_STAMP}.ARPU" 

	if [ `uname` = "SunOS" ]
	then
	cat $(/usr/xpg4/bin/grep -e "^1000    " $dir/${MASK_FILE} /dev/null | awk -F: '{print $1}') >>${ARQ_NAME}
	else
	cat $(grep -e "^1000    " $dir/${MASK_FILE} /dev/null | awk -F\: '{print $1}') >>${ARQ_NAME}
	fi

	QUAN_CLI=`grep -c "^1000    " ${ARQ_NAME}`
	TOT_CLI=`expr ${TOT_CLI} + ${QUAN_CLI}`
	
	NOM_LOG="${ARQ_NAME}.LOG"
	
	#echo "O Arquivo ${ARQ_NAME} tem ${QUAN_CLI} clientes para o mercado ${N_MERC}." >>${NOM_LOG}

	echo ${TOT_CLI} >/tmp/count_arpu.${N_MERC}
	
	done
	


	if [ -z "${ARQ_NAME}" ]

		then
		echo "\nERRO! Arquivo ${DIR_ARPU}/{ARQ_NAME} vazio.\n"
		exit 1

		fi


>${NOM_LOG}
echo "

############################################################################################
#                                ESTE EMAIL FAZ PARTE DO ARPU                              #
#           CASO OCORRA ALGUM PROBLEMA ENTRAR EM CONTATO COM REGIANE OU FABIO PARA.        #
############################################################################################


Total de Clientes/Faturas................................: ${QUAN_CLI} Clientes


O Arquivo ${NOM_LOG} serve como protocolo" | tee -a ${NOM_LOG}

cat ${NOM_LOG} | mailx -s "ARPU - ${SITE}${CICLO} `date` " prod@unix_mail_fwd
mv ${NOM_LOG} /pinvoice/ARPU/ENVIADOS/
exit 0
}

lmp_file()
{
	rm -f mercs_$$.arpu
	rm -f junta_$$.arpu
	}

${JUNT[0]}
${JUNT[1]}
${JUNT[2]}
${JUNT[3]}
${JUNT[4]}

