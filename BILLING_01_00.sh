#!/bin/ksh

	# Finalidade : Cria SYNONYM para DOC_ALL para processamento do BCH.
        #              Limpa diretorio EDIT FACT do BCH (usuário PROD).
	# Input : 
	# Output : mail, log
	# Autor : Edison Santos
	# Data : 08/10/2003

. /etc/appltab

export ORACLE_HOME="${ENV_DIR_ORAHOME_BSC}"
export NLS_LANG="${ENV_NLSLANG_PDBSC}"
export TWO_TASK="${ENV_TNS_PDBSC}"
export CICLO="$1"
 
#
#  Verifica se a DOC_ALL para a qual foi criado o SYNONYM esta vazia, caso nao esteja, o JOB emite ABEND!!
#  Cria SYSNONYM DOCUMENT_ALL para d DOC_ALL_XX do ciclo que esta em processamento.                            
#
. /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "sysadm/wizardmagic03" "/amb/operator/cfg/cria_syn_doc_ciclo.sql ${CICLO}" prod@unix_mail_fwd  "Cria SYNONYM da DOC_ALL p/ o ciclo ${CICLO}" 0  BILLING 0

ARQCFG=/amb/operator/cfg/bscs_batch.cfg

# Le arquivo de paramentros
. $ARQCFG

echo ".........Limpando Edifact"
echo ".........Limpando Edifact"
echo ".........Limpando Edifact"
echo ".........Limpando Edifact"

date
for i in `ls $BCHEDIFACT`
do  
   rm $BCHEDIFACT$i
done

date

