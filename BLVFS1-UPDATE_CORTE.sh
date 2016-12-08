#!/bin/ksh

# Finalidade : Seleciona a data de corte na BD do BSCS armazenando-a para Controle do SCRIPT BLVFS2-VERIF_CORTE.sh
# Input      : SQL_BILL_DtCorte.sql
# Output     : 
# Autor      : Edison Santos
# Data       : 18/06/2003

. /etc/appltab

exit 0

DirFilesCtrl=/tmp/BILL_CONTROL_FILES

typeset -u -L2 Site
Site="$1"
Ciclo=$2

export ORACLE_HOME="${ENV_DIR_ORAHOME_BSC}" 
export NLS_LANG="${ENV_NLSLANG_PDBSC}"

FileCtrl=${DirFilesCtrl}/BILL-CG-CONTROL-${Site}${Ciclo}

#
#  Executa SQL para SELECT da data de FECHO existente na TAB "mpscftab" para validacao da data de processamento    
#

# ALterado em 2003/08/19 - Edison Santos (Workmation) - Consolidacao MIBAS - BSCS
#===================================================================================#
### . /amb/eventbin/SQL_RUN.PROC  PBSCS_$Site  "$3"  /amb/scripts/sql/SQL_BILL_DtCorte.sql  edison@unix_mail_fwd  "Selecao de Mes Faturamento BSCS"  0  "Faturamento Site: $Site Ciclo: $Ciclo " 0
#===================================================================================#

. /amb/eventbin/SQL_RUN.PROC2  "${ENV_TNS_PDBSC}" "${ENV_LOGIN_PDBSC}"  /amb/scripts/sql/SQL_BILL_DtCorte.sql  edison@unix_mail_fwd  "Selecao de Mes Faturamento BSCS"  0  "Faturamento Site: $Site Ciclo: $Ciclo " 0

#
#  Carrega a data de corte do ciclo em processamento em arquivo p/ controle do JOB BLVFS2-VERIF_CORTE.sh.          
#
cat /tmp/SQL_BILL_DtCorte.txt | grep ^........ | tr -d ' '  >  ${FileCtrl}

