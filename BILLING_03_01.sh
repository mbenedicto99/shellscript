#!/bin/ksh
#  Script      : BILLING_03_01.sh
#  Objetivo    : GERACAO E ENVIO DE ARQUIVOS GEL P/ MAGNUS  
#  Criticid.   : Alta - Em caso de problemas acionar Analista Responsavel 
#  Arquivos    : xxxxxx 
#  Pre_Requis  : Base Oracle  xxxxx   no ar 

. /etc/appltab

## ARQCFG=/amb/eventbin/consolidacao/OK/bscs_batch.cfg
## ARQCFG=/amb/operator/cfg/consolidacao/bscs_batch.cfg
ARQCFG=/amb/operator/cfg/bscs_batch.cfg

FLAG=1

DESTINO="spoaxap3:/apgs_sp/magnus/bill/PROCESSANDO"
TIMESTAMP="`date +%Y%m%d%H%M`"

typeset -l CITY SITE
CITY="${ENV_VAR_CITY}"
SITE="${ENV_VAR_SITE}"
SITE2="${ENV_VAR_SITE}"
DIRENVIADOS="${ENV_DIR_BASE_RTX}/prod/WORK/GEL/ENVIADOS"
DIR_AUTH="${ENV_DIR_BASE_RTX}/prod/WORK/TMP"
export TWO_TASK="${ENV_TNS_PDBSC}"
export ORACLE_HOME="${ENV_DIR_ORAHOME_BSC}" 
export NLS_LANG="${ENV_NLSLANG_PDBSC}"

BILLCYCLE=$1

#------------------------------------------------
# Arquivo de Parametro com as datas do GEL
# Verifica autorizacao e pega datas de parametros
#------------------------------------------------

FILE_AUTH=${DIR_AUTH}/"BGH-"${BILLCYCLE}.flg
 if [ ! -f ${FILE_AUTH} ]; then
    echo "\n\t************** ATENCAO SR. OPERADOR ***************"
    echo "\n\tNao ha' autorizacao para execucao deste processo."
    echo "\tEntrar em contato com o responsavel pelo scheduler.\n"
    echo "\tProcesso abortado.\n"
    exit 1
 fi

DI=`sed -n '2p' $FILE_AUTH`
DF=`sed -n '3p' $FILE_AUTH`
DV=`sed -n '4p' $FILE_AUTH`
rm -f $FILE_AUTH

#--------------------------
# Le arquivo de paramentros
#--------------------------
. $ARQCFG

# VARIABLES

####==============================================================#
#### Alterado em 2003/09/11 - Consolidacao Mibas/BSCS             #
####==============================================================#
dir=~prod/WORK/GEL
dir_utlf="${ENV_DIR_UTLF_BSC}/GEL"

function data_corte  {
###  Alterado Consolidacao MIBAS-BSCS
###  $ORACLE_HOME/bin/sqlplus -s bch/sysadm@pbscs_${SITE} << EOF  ----------------> VERIFICAR

$ORACLE_HOME/bin/sqlplus -s ${ENV_LOGIN_PDBSC_BCH} << EOF
alter session set nls_date_format = 'dd-mm-yyyy';
(selecT to_date(substr(cfvalue,(length(cfvalue)-5),7),'yymmdd') from mpscftab where cfcode = 23);
EOF
;
}

a_data_do_corte="$(data_corte|tail -2 | head -1)"

## Captura tempo de processamento.
LOG_DATE=`date +%d%m%Y`
LOG_TIME="${ENV_DIR_BASE_RTX}/prod/reports/RODAGEL_${LOG_DATE}.txt"
LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"

printf "%s\t%s\t%s\t%s\n" "RODAGEL" "Inicio do processamento." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

$ORACLE_HOME/bin/sqlplus -s ${ENV_LOGIN_PDBSC_BCH} << EOF
alter session set sql_trace=true;
execute gel.gel('${dir_utlf}', to_date('$a_data_do_corte','dd-mm-yyyy'));
EOF

RC=$?

if [ $RC != 0 ]; then
   echo "ERRO na geracao dos arquivos GEL.Favor contactar o Analista"
   ( echo "ERRO na geracao dos arquivos GEL" ; cat $ARQTMP ) |\
	/amb/bin/msg_api2  "E-BILLING-GERAGEL-PROCESSAMENTO"
   exit 1
else 
   echo "Processo  de Geracao dos arquivos GEL com sucesso em: `date`"
   ( echo "Sucesso geracao dos arquivos GEL" ; cat $ARQTMP ) |\
	/amb/bin/msg_api2  "I-BILLING-GERAGEL-PROCESSAMENTO"
   /amb/operator/bin/attach_mail reginaldo@unix_mail_fwd $ARQTMP "Log execucao - BGH"
fi

### cd $dir
cd ${dir_utlf}
# Envia arquivo GEL para o MAGNUS

for file in GEL*
 do [ ! -f $file ] && continue
    FLAG=0
    SEQ=`echo $file | cut -d "." -f2`
    ###
    ### NEW_ARQGEL=GELC${SITE2}${BILLCYCLE}${DI}${DF}${DV}.${SEQ}.${TIMESTAMP}
    ###
    NEW_ARQGEL="${dir}/GELC${SITE2}${BILLCYCLE}${DI}${DF}${DV}.${SEQ}.${TIMESTAMP}"
    chmod 666 $file
    cp $file $NEW_ARQGEL
    chmod 666 $NEW_ARQGEL
    su transf -c "rcp -p $NEW_ARQGEL $DESTINO" >$TMP 2>&1
    if [ $? != 0 ]; then
      echo "Erro no envio do arquivo GEL para o Magnus - $NEW_ARQGEL"
      cat $TMP
      rm -f $TMP
      exit 1
    fi
    echo "Arquivo GEL enviado com sucesso para o MAGNUS - $NEW_ARQGEL"
    mv $NEW_ARQGEL $DIRENVIADOS
    gzip -9 ${DIRENVIADOS}/`basename ${NEW_ARQGEL}`
    mv $file $DIRENVIADOS
    gzip -9 ${DIRENVIADOS}/${file}
 done

## Captura tempo de processamento.
LOG_DATE=`date +%d%m%Y`
LOG_TIME="${ENV_DIR_BASE_RTX}/prod/reports/RODAGEL_${LOG_DATE}.txt"
LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"

printf "%s\t%s\t%s\t%s\n" "RODAGEL" "Termino do processamento." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

if [ $FLAG != 0 ] ; then
  echo "NENHUM ARQUIVO GERADO"
  exit 1
fi

exit 0
