#!/bin/ksh
##
# BSCS_BYPASS_TIH_ACB
#
#M#I-BSCS_TIH-019 : Sucesso na inclusão do registro na tabela THUFITAB
#M#E-BSCS_TIH-020 : Erro    na inclusão do registro na tabela THUFITAB
#M#E-BSCS_TIH-021 : Erro de infra-estrutura

. /etc/appltab

TMP=/tmp/tih_$$
AUX=/tmp/tihsql_$$.sql
#UNAME=$1
typeset -u -L3 SITE

SITE="${ENV_VAR_CITY}"

## case "$SITE" in
##     SPO) DIR_NORTEL=/artx_sp/prod/WORK/MP/NORTEL/IN/AIRLI/
##          ARQ_PASSWD=/artx_sp/prod/batch/bin/bscs.passwd
##          export TWO_TASK=PBSCS_SP
##          export ORACLE_HOME=/ortx_sp/app/oracle/product/default
##          ID_SWITCH=55218345000
##          DIR_DAP=/artx_sp/prod/WORK/MP/DAP/IN/AIRLI/
##          ;;
##     RJO) DIR_NORTEL=/artx_rj/prod/WORK/MP/NORTEL/IN/NT_RJ/
##          ARQ_PASSWD=/artx_rj/prod/batch/bin/bscs.passwd
##          export TWO_TASK=PBSCS_RJ
##          export ORACLE_HOME=`grep PRTX_RJ /etc/oratab | awk -F: '{print $2}'`
##          #export ORACLE_HOME=/ortx_rj/app/oracle/product/default
##          ID_SWITCH=55218340001
##          DIR_DAP=/artx_rj/prod/WORK/MP/DAP/IN/NT_RJ/
##          ;;
##       *) echo "$0: Site $SITE desconhecido para $UNAME" | msg_api2 E-RATING-BYPASS-ERRO
##          exit 1
##          ;;
## esac


DIR_NORTEL="${ENV_DIR_NORTEL_RTX}"
ARQ_PASSWD=${ENV_DIR_BASE_RTX}/prod/batch/bin/bscs.passwd
export TWO_TASK="${ENV_TNS_PDBSC}"
export ORACLE_HOME="${ENV_DIR_ORAHOME_BSC}"
DIR_DAP="${ENV_DIR_DAP_RTX}"

[ "${SITE}" = "SPO" ] && ID_SWITCH=55218345000 || ID_SWITCH=55218340001

export PATH=$PATH:/${ORACLE_HOME}/bin

# Copia do CDR para a area de producao
/amb/operator/bin/cp_cdr_prod_acb NORTEL $SITE
#### /amb/eventbin/consolidacao/OK/copy_cdr_prod_nor NORTEL $SITE
if [ $? != 0 ]; then
  ( echo "Erro na execucao do cp_cdr_prod"
   cat $TMP ) | msg_api2  "E-RATING-BYPASS-ERRO"
   cat $TMP
   rm -f $TMP $AUX
   exit 1
fi

echo "\n** Executando bypass tih...\n"

if [ ! -f "$ARQ_PASSWD" ]; then
   echo "$0: Arquivo de senhas não encontrado" | msg_api2 E-RATING-BYPASS-ERRO
   rm -f $TMP $AUX
   exit 1
fi

TIH_PASSWD=`awk '/^TIH[ 	]/ { a=$2; } END { print a }' $ARQ_PASSWD`
if [ -z "$TIH_PASSWD" ]; then
   echo "$0: Senha do usuário TIH não encontrada" | msg_api2 E-RATING-BYPASS-ERRO
   rm -f $TMP $AUX
   exit 1
fi

if [ -z "$DIR_NORTEL" ]; then
   echo "$0: Variável DIR_NORTEL não definida" | msg_api2 E-RATING-BYPASS-ERRO
   rm -f $TMP $AUX
   exit 1
fi

cat <<EOF >$AUX 2>$TMP
SET FEED OFF VERIFY OFF ECHO OFF 
-- SET FEED OFF VERIFY OFF ECHO OFF TERM OFF
WHENEVER OSERROR EXIT SQL.OSCODE ROLLBACK
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
DECLARE
  V_FILE NUMBER(2):=0;                                                
BEGIN
    SELECT COUNT(*) 
      INTO V_FILE
      FROM THUFITAB
     WHERE FILENAME = '&1' AND STATUS <> 0;
    IF V_FILE > 0 THEN
         RAISE_APPLICATION_ERROR(-20001,'ARQUIVO PROCESSADO ANTERIORMENTE!!!');
    END IF;
END;
/

INSERT INTO THUFITAB
(SELECT MAX(FILE_ID)+1, 0, '&3', '&1', SYSDATE, 
 0, 2048, '&2', 1, null  FROM THUFITAB);

UPDATE RTXCYTAB SET RLH_PID=NULL;

COMMIT;
EXIT;
EOF

if [ $? != 0 ]; then
   ( echo "$0: Erro ao criar o SQL $AUX"
     cat $TMP ) | msg_api2 E-RATING-BYPASS-ERRO
     cat $TMP 
   rm -f $TMP $AUX
   exit 8
fi

rc=0

cd $DIR_NORTEL 2>$TMP
if [ $? != 0 ]; then
   ( echo "$0: Erro no cd para $DIR_NORTEL"
     cat $TMP ) | msg_api2 E-RATING-BYPASS-ERRO
   rm -f $TMP $AUX
   exit 1
fi

LOG_DATE=`date +%d%m%Y`
LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
LOG_TIME="${ENV_DIR_BASE_RTX}/prod/reports/BYPASS_TIH_ACB_${LOG_DATE}.txt"
COUNT_TIME=`ls TH??????????????BA 2>/dev/null | wc -l`

printf "%s\t%s\t%s\t%s\n" "BYPASS_TIH_ACB" "Inicio do processamento, ${COUNT_TIME} arquivos." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

# Alterado para carregar arquivos de Roaming ( Nortel ) 15/02/2001
#for file in TH??????????????BA CU??????????????BA
for file in TH??????????????BA
    do [ ! -f $file ] && continue
       TYPE=1
       ORIGEM=`echo $file | cut -c4-6`
       switch=`echo $file | cut -c3`
       echo "Arquivo $file"
       case $ORIGEM in
            SPO) [ "$switch" = "1" ] && ID_SWITCH="55218345000" 
                 [ "$switch" = "2" ] && ID_SWITCH="55218340622" ;;
            RJO) [ "$switch" = "1" ] && ID_SWITCH="55218340001" 
                 [ "$switch" = "2" ] && ID_SWITCH="55218343232" ;;
            BHZ) [ "$switch" = "1" ] && ID_SWITCH="55218345032" ;;
       esac
      
       sqlplus TIH/${TIH_PASSWD}@${TWO_TASK} \
               @$AUX $file $ID_SWITCH $TYPE >$TMP 2>&1
       ret=$?

       if [ $ret = 0 ]; then
          ( echo "$file $TWO_TASK $ID_SWITCH `cksum $file`"
            cat $TMP ) | msg_api2 "I-RATING-BYPASS-IMPORTACAO"
	    cat $TMP
       else 
          ( echo "$file $TWO_TASK $ID_SWITCH `cksum $file`"
            cat $TMP; echo "RET=$ret" ) | msg_api2 "E-RATING-BYPASS-ERRO"
            cat $TMP
          rc=1
       fi
    done

if [ $rc != 0 ]
   then
      echo "Erro na carga dos Arquivos de Roaming"
      rm -f $TMP $AUX
      exit 8
fi


cat <<EOF >$AUX 2>$TMP
SET FEED OFF VERIFY OFF ECHO OFF 
-- SET FEED OFF VERIFY OFF ECHO OFF TERM OFF
WHENEVER OSERROR EXIT SQL.OSCODE ROLLBACK
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
DECLARE
  V_FILE NUMBER(2):=0;                                                
BEGIN
    SELECT COUNT(*) 
      INTO V_FILE
      FROM THUFITAB
     WHERE FILENAME = '&1' AND STATUS <> 0;
    IF V_FILE > 0 THEN
         RAISE_APPLICATION_ERROR(-20001,'ARQUIVO PROCESSADO ANTERIORMENTE!!!');
    END IF;
END;
/

INSERT INTO THUFITAB
(SELECT MAX(FILE_ID)+1, 0, '&3', '&1', SYSDATE, 
 0, 2048, '&2', 1, null  FROM THUFITAB);

UPDATE RTXCYTAB SET RLH_PID=NULL;

COMMIT;
EXIT;
EOF

if [ $? != 0 ]; then
   ( echo "$0: Erro ao criar o SQL $AUX"
     cat $TMP ) | msg_api2 E-RATING-BYPASS-ERRO
     cat $TMP 
   rm -f $TMP $AUX
   exit 8
fi

rc=0

# Carrega arquivos DAP
cd $DIR_DAP 2>$TMP
if [ $? != 0 ]; then
   ( echo "$0: Erro no cd para $DIR_DAP"
     cat $TMP ) | msg_ap2  E-RATING-BYPASS-ERRO
   rm -f $TMP $AUX
   exit 1
fi

LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
COUNT_TIME=`ls TH??????????????BA 2>/dev/null | wc -l`

printf "%s\t%s\t%s\t%s\n" "BYPASS_TIH_ACB" "Termino do processamento, ${COUNT_TIME} arquivos THs." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

COUNT_TIME=`ls DAP???????????????.?.? 2>/dev/null | wc -l`

printf "%s\t%s\t%s\t%s\n" "BYPASS_TIH_ACB" "Inicio do processamento, ${COUNT_TIME} arquivos DAPs." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

for file in DAP???????????????.?.?
    do [ ! -f $file ] && continue
       switch=`echo $file | cut -c3`
       TYPE=6
       COD=119
       [ "${SITE}" = "SPO" ] && ID_SWITCH="55110000000" 
       [ "${SITE}" = "RJO" ] && ID_SWITCH="55210000000"

       sqlplus TIH/${TIH_PASSWD}@${TWO_TASK} \
               @$AUX $file $ID_SWITCH $TYPE >$TMP 2>&1
       ret=$?

       if [ $ret = 0 ]; then
          ( echo "$file $TWO_TASK $ID_SWITCH `cksum $file`"
            cat $TMP ) | msg_api "I-BSCS_TIH-${COD}"
            cat $TMP 
       else 
          ( echo "$file $TWO_TASK $ID_SWITCH `cksum $file`"
            cat $TMP; echo "RET=$ret" ) | msg_api2 "E-RATING-BYPASS-ERRO"
            cat $TMP; echo "RET=$ret" 
          rc=1
       fi
    done

LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
COUNT_TIME=`ls DAP???????????????.?.? 2>/dev/null | wc -l`

printf "%s\t%s\t%s\t%s\n" "BYPASS_TIH_ACB" "Termino do processamento, ${COUNT_TIME} arquivos DAPs." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

if [ $rc != 0 ]; then
   echo "\n\t******************** ATENCAO **********************"
   echo "\n\t\tOcorreram erros durante o processo de bypass. "
   echo "\t\t\tProcesso abortado.\n"
   rm -f $TMP $AUX
   exit $rc
fi


rm -f $TMP $AUX
exit 0

