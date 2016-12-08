#!/bin/ksh

# Finalidade : Validar se a data de processamento e >= a data de corte do ciclo
# Input      : DirFilesCtrl
# Output     : 
# Autor      : Edison Santos
# Data       : 18/06/2003

. /etc/appltab

DirFilesCtrl=/tmp/BILL_CONTROL_FILES

# ALterado em 2003/08/20 - Edison Santos (Workmation) - Consolidacao MIBAS - BSCS
#===================================================================================#
### Site="`echo $1 | tr 'a-z' 'A-Z'`"
Site="${ENV_VAR_SITE}"

Ciclo=$2

FileCtrl=${DirFilesCtrl}/BILL-CG-CONTROL-${Site}${Ciclo}

#
#  Executa SQL para SELECT da data de FECHO existente na TAB "mpscftab" para validacao da data de processamento    
#
DataFecho="`cat ${FileCtrl} | grep ^........ | tr -d ' '`"

#
#  Carrega variaveis com as datas atual e de corte para o ciclo CG em processamento.                               
#
DataAtual="`date +'%Y%m%d'`" 

if [ ${DataAtual} -lt ${DataFecho} ]
then
   banner "ALERTA!!"
   echo   ""
   echo   "#==============================================================================================#"
   echo   "# "
   echo   "#   Sr Operador, Este JOB sera reciclado para execucao em data correta, pois esta"
   echo   "#   "
   echo   "#   fase do BILLING CG somente pode executar em data igual ou superior a data de"
   echo   "#   "
   echo   "#   fecho do ciclo $Site$Ciclo!!!   "
   echo   "#   "
   echo   "#   "
   echo   "#   =====> Data Atual: ${DataAtual}   Data Fecho: ${DataFecho}  "
   echo   "# "
   echo   "#   O JOB sera reciclado para proxima execucao pervista para daqui a 24 hs!!!"
   echo   "#   O JOB sera reciclado para proxima execucao pervista para daqui a 24 hs!!!"
   echo   "#   O JOB sera reciclado para proxima execucao pervista para daqui a 24 hs!!!"
   echo   "#   O JOB sera reciclado para proxima execucao pervista para daqui a 24 hs!!!"
   echo   "#   "
   echo   "#   Acompanhar o proximo processamento!!!!!!!"
   echo   "#   Acompanhar o proximo processamento!!!!!!!"
   echo   "#   Acompanhar o proximo processamento!!!!!!!"
   echo   "#   Acompanhar o proximo processamento!!!!!!!"
   echo   "CTM-JOB_RERUN"
   echo   "#   "
   echo   "#==============================================================================================#"
fi