#!/bin/ksh

	# Finalidade : Fazer validacao de Faturas de billing.
	# Input : Arquivos de Fatura.
	# Output : Relatorio via email.
	# Autor : Marcos de Benedicto
	# Data : 13/05/2003


ARQ=$1
DIR="/pinvoice/BGH/tmp"


set -A VALID chk_file chk_val rm_lx


chk_file()
{

      	N_NF=`grep -c "^9023" ${ARQ}`
	N_BT=`grep -c "^9021" ${ARQ}`
	N_BS=`grep -c "^9011" ${ARQ}`

	echo "\n\n"
	printf "\tArquivo ${ARQ}.\n\n"
	printf "\tData Inicio : `date`\n\n"

	N_FAT0=`grep -c "^1000    " ${ARQ}`
	N_FAT1=`grep -c "^99" ${ARQ}`

	if [ ${N_FAT0} = ${N_FAT1} ]

	then
	printf "\tNumero de Faturas :\t%s\n" ${N_FAT0}
	continue

	else
	printf "\tERRO! Existem faturas que nao tem fechamento.\n"
			
	fi
	
	printf "\tNumero de Boletos de Telecom : ${N_BT}\n"
	printf "\tNumero de Boletos de Servico : ${N_BS}\n"
	printf "\tNumero de Notas Fiscais : ${N_NF}\n\n\n"	
	
	printf "\tInicia Validacao :\n\n"
}

chk_val()
{

   >${DIR}/fat_bill_tmp.$$
   #egrep "^(1000    |1100    |9022    |9012    )" ${ARQ} >>${DIR}/fat_bill_tmp.$$

   if [ `uname` = HP-UX ] 
	
	then 
	egrep "^(1000    |1100    |9022    |9012    )" ${ARQ} >>${DIR}/fat_bill_tmp.$$
	csplit -f ${DIR}/SPLIT_BILL.$$ -n 6 ${DIR}/fat_bill_tmp.$$ '/^1000    /' {*} 1>/dev/null
	[ $? -eq 0 ] || exit 1

	else
	/usr/xpg4/bin/grep -E "^(1000    |1100    |9022    |9012    )" ${ARQ} >>${DIR}/fat_bill_tmp.$$
        CL=`grep -c "^1000    " ${DIR}/fat_bill_tmp.$$ | tr -d ' '`
	CL=`expr ${CL} - 1`
	
    if [ ${CL} -le 0 ]

	then
	continue

	else
	[ -n "${CL}" ] || exit 1
	csplit -f ${DIR}/SPLIT_BILL.$$ -n 6 -k ${DIR}/fat_bill_tmp.$$ '/^1000    /' {$CL} 1>/dev/null
	[ $? -eq 0 ] || exit 1
    fi

   fi 


rm -f ${DIR}/SPLIT_BILL.$$000000

ls ${DIR}/SPLIT_BILL.$$* | while read x
do
	CLIENTE=`awk -F\| '/^1000    / {print $8}' ${x} | sed "s/\&//g"`
	COD_BSCS=`awk -F\| '/^1000    / {print $2}' ${x} | sed "s/\&//g"`
	COD_MAGNUS=`awk -F\| '/^1000    / {print $3}' ${x} | sed "s/\&//g"`
	VAL_FATURA=`awk -F\| '/^1100    / {print $(NF-1)}' ${x} | sed -e "s/\&//g"`
	VAL_BOLETOT=`awk -F\| '/^9022    / {print $9}' ${x} | sed "s/\&//g"`
	VAL_BOLETOS=`awk -F\| '/^9012    / {print $9}' ${x} | sed "s/\&//g"`


	#Zera faturas SPY.

	if [ ${COD_BSCS} = 1.10000000 ]

	then
	VAL_FATURA="0"
	VAL_BOLETOT="0"
	continue

	fi

	#Zera Boletos de Telecom para faturas negativas.

	if [ `echo ${VAL_FATURA} | grep -c "("` = 1 ]

	then
	VAL_FATURA="echo ${VAL_FATURA} | sed -e 's/(//g' -e 's/)//g'"
	VAL_BOLETOT="0"
	continue

	fi

	#Verifica se fatura existe.

	if [ -z "${VAL_FATURA}" ]

	then
	VAL_FATURA="0"
	echo "
	+-------------------------------------------------------------------------------------
	|
	|   ERRO! 
	|   `date`
	|   Nao foi localizado o Valor da Fatura.
	|   Cliente : ${CLIENTE}
	|   Codigo BSCS : ${COD_BSCS}
	|   Codigo Magnus : ${COD_MAGNUS}
	|
	+-------------------------------------------------------------------------------------\n"
	continue
		
	fi

	#Trasforma 0,00 em 0 para facilitar calculo.

	if [ ${VAL_FATURA} = 0,00 ] 2>/dev/null

	then
	VAL_FATURA="0"
	VAL_BOLETOT="0"
	continue

	else

	#Verifica se Boleto de Telecom existe.

	if [ -z "${VAL_BOLETOT}" ]

	then
	VAL_BOLETOT="0"
	echo "
	+-------------------------------------------------------------------------------------
	|
	|   ERRO! 
	|   `date`
	|   Nao foi localizado o Valor do Boleto de Telecom.
	|   Cliente : ${CLIENTE}
	|   Valor da Fatura : ${VAL_FATURA}
	|   Codigo BSCS : ${COD_BSCS}
	|   Codigo Magnus : ${COD_MAGNUS}
	|
	+-------------------------------------------------------------------------------------\n"
	VAL_FATURA="0"	
	fi
		
	fi

	#Verifica se Boleto de Servico existe.

	if [ -z "${VAL_BOLETOS}" ]
	
	then 
	VAL_BOLETOS="0"

	fi


	CAL_BT=`echo ${VAL_BOLETOT} | sed -e "s/^0,//g" -e "s/\.//g" -e "s/,//g"` 
	CAL_BS=`echo ${VAL_BOLETOS} | sed -e "s/^0,//g" -e "s/\.//g" -e "s/,//g"`
	CAL_FAT=`echo ${VAL_FATURA} | sed -e "s/^0,//g" -e "s/\.//g" -e "s/,//g"`

	#Transforma valores em inteiros para calculo de EXPR.

	CAL_BT=`expr ${CAL_BT} + 1 - 1`
	CAL_BS=`expr ${CAL_BS} + 1 - 1`
	CAL_FAT=`expr ${CAL_FAT} + 1 - 1`
	
	TOT=`expr ${CAL_BS} + ${CAL_BT}`


	if [ ${VAL_FATURA} = 0 ]

	then
	continue

	else

	#Soma Boleto de Telecom com Boleto de servico e valida se o resultado for o mesmo da fatura.

	if [ ${TOT} = ${CAL_FAT} ]

	then
	#echo "\nOK! Valor da Fatura eh igual a soma dos boletos\n"
	continue

	else
	echo "
	+-------------------------------------------------------------------------------------
	|
	|   ERRO! 
	|   `date`
	|   Valor da Fatura NAO eh igual a soma dos boletos.
	|   Cliente : ${CLIENTE}
	|   Valor da Fatura : ${VAL_FATURA}
	|   Valor do Boleto Telecom : ${VAL_BOLETOT}
	|   Valor do Boleto de Servico : ${VAL_BOLETOS}
	|   Codigo BSCS : ${COD_BSCS}
	|   Codigo Magnus : ${COD_MAGNUS}
	|
	+-------------------------------------------------------------------------------------\n"
	continue

	fi


	fi
	
	echo "\n\n"

	done

	echo "\n"
	printf "\tData Termino : `date`\n\n"	
	printf "\t########################################################################################\n"	
}

rm_lx()
{
	rm -f /tmp/SPLIT_BILL.$$*  
	rm -f /tmp/fat_bill_tmp.$$ 

}

${VALID[0]}
${VALID[1]}
${VALID[2]}

#Fim da Shell
