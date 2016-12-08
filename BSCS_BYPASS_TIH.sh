#!/bin/ksh
##
# BSCS_BYPASS_TIH_NOR
#
#M#I-BSCS_TIH-019 : Sucesso na inclusão do registro na tabela THUFITAB
#M#E-BSCS_TIH-020 : Erro    na inclusão do registro na tabela THUFITAB
#M#E-BSCS_TIH-021 : Erro de infra-estrutura

. /etc/appltab

TMP=/tmp/tih_$$
LOG=/tmp/tih_$$.log
AUX=/tmp/tihsql_$$.sql

#VARIAVEL NAO USADA - MARCOS
#UNAME=$1

#SETADO SITE PARA CITY POR PRECISAR DE -L3.
typeset -u -L3 SITE

DAP=0
NORTEL=0
SITE="${ENV_VAR_CITY}"

##case "$SITE" in
##    SPO) DIR_NORTEL=/artx_sp/prod/WORK/MP/NORTEL/IN/AIRLI/
##         ARQ_PASSWD=/artx_sp/prod/batch/bin/bscs.passwd
##         export TWO_TASK=PBSCS_SP
##         export ORACLE_HOME=/ortx_sp/app/oracle/product/default
##         ID_SWITCH=55218345000
##         DIR_DAP=/artx_sp/prod/WORK/MP/DAP/IN/AIRLI/
##         DIR_SUSP=/artx_sp/prod/WORK/MP/NORTEL/IN/SUSP/
##         ;;
##    RJO) DIR_NORTEL=/artx_rj/prod/WORK/MP/NORTEL/IN/NT_RJ/
##         ARQ_PASSWD=/artx_rj/prod/batch/bin/bscs.passwd
##         export TWO_TASK=PBSCS_RJ
##        export ORACLE_HOME=`grep PRTX_RJ /etc/oratab | awk -F: '{print $2}'`
##         #export ORACLE_HOME=/ortx_rj/app/oracle/product/default
##         ID_SWITCH=55218340001
##         DIR_DAP=/artx_rj/prod/WORK/MP/DAP/IN/NT_RJ/
##         DIR_SUSP=/artx_rj/prod/WORK/MP/NORTEL/IN/SUSP
##         ;;
##      *) echo "$0: Site $SITE desconhecido para $UNAME" | msg_api2 E-RATING-BYPASS-ERRO
##         exit 1
##         ;;
##esac

DIR_NORTEL="${ENV_DIR_NORTEL_RTX}"
ARQ_PASSWD=${ENV_DIR_BASE_RTX}/prod/batch/bin/bscs.passwd

export TWO_TASK="${ENV_TNS_PDBSC}"
export ORACLE_HOME="${ENV_DIR_ORAHOME_BSC}"

DIR_DAP="${ENV_DIR_DAP_RTX}"
DIR_SUSP=${ENV_DIR_BASE_RTX}/prod/WORK/MP/NORTEL/IN/SUSP/

#SET ID_SWITCH POR SITE
ID_SWITCH=0
[ ${SITE} = SPO ] && ID_SWITCH=55218345000 
[ ${SITE} = RJO ] && ID_SWITCH=55218340001

echo "Validando o ID_SWITCH associado ao SITE !!!! Se ID_SWITCH nao for atribuido, o JOB ira emitir ABEND!!!"
[ $ID_SWITCH = 0 ] && exit 99

export PATH=$PATH:/${ORACLE_HOME}/bin

# Copia do CDR para a area de producao
/amb/operator/bin/copy_cdr_prod_nor NORTEL $SITE
### /amb/eventbin/consolidacao/OK/copy_cdr_prod_nor NORTEL $SITE
RC=$?
if [ $RC = 44 ]; then
   echo "nao existe arquivo a ser processado"
   rm -f $TMP $AUX
   exit 1
fi

if [ $RC != 0 ]; then
  ( echo "Erro na execucao do copy_cdr_prod"
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
WHENEVER OSERROR EXIT SQL.OSCODE ROLLBACK
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
DECLARE
  V_FILE NUMBER(2):=0;
  BEGIN
      SELECT COUNT(*)
    INTO V_FILE
FROM THUFITAB
    WHERE FILENAME = '&1';

IF V_FILE = 0 THEN
       INSERT INTO THUFITAB
      (SELECT MAX(FILE_ID)+1, 0, '&3', '&1', SYSDATE,
      0, 2048, '&2', 1, null  FROM THUFITAB);
      UPDATE RTXCYTAB SET RLH_PID=NULL;
     COMMIT;
 ELSE 
RAISE_APPLICATION_ERROR(-20001,'ARQUIVO PROCESSADO ANTERIORMENTE!!!');
   END IF;
END;
/

EXIT;
EOF

#===================================
#  Comentado 29/09/2003
#===================================
#SET FEED OFF VERIFY OFF ECHO OFF 
#WHENEVER OSERROR EXIT SQL.OSCODE ROLLBACK
#WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
#DECLARE
#  V_FILE NUMBER(2):=0;                                                
#BEGIN
#    SELECT COUNT(*) 
#      INTO V_FILE
#      FROM THUFITAB
#     WHERE FILENAME = '&1' AND STATUS <> 0;
#    IF V_FILE > 0 THEN
#         RAISE_APPLICATION_ERROR(-20001,'ARQUIVO PROCESSADO ANTERIORMENTE!!!');
#    END IF;
#END;
#/
#
#INSERT INTO THUFITAB
#(SELECT MAX(FILE_ID)+1, 0, '&3', '&1', SYSDATE, 
# 0, 2048, '&2', 1, null  FROM THUFITAB);
#
#UPDATE RTXCYTAB SET RLH_PID=NULL;
#
#COMMIT;
#EXIT;
#EOF
#===================================
#  Comentado 29/09/2003
#===================================

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
LOG_TIME="${ENV_DIR_BASE_RTX}/prod/reports/BYPASS_TIH_${LOG_DATE}.txt"
COUNT_TIME=`ls TH??????????????HS TH??????????????HB TH??????????????BS 2>/dev/null | wc -l`

printf "%s\t%s\t%s\t%s\n" "BYPASS_TIH" "Inicio da carga de THs, ${COUNT_TIME} arquivos TH." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

# Alterado para carregar arquivos de Roaming ( Nortel ) 15/02/2001
#for file in TH??????????????HS TH??????????????HB TH??????????????BS CU??????????????BS CU??????????????HB CU??????????????HS
for file in TH??????????????HS TH??????????????HB TH??????????????BS
    do 
       [ ! -f $file ] && continue
       NORTEL=1
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

       grep -q "ARQUIVO PROCESSADO ANTERIORMENTE" $TMP
       if [ $? = 0 ] ; then
          echo "movendo arquivo $file ja processado para area de suspicious"
          mv $file $DIR_SUSP

          gzip -9 -f $DIR_SUSP/$file
          echo "$file" >> $LOG
          #ret=0
       fi

       if [ $ret -eq 0 -a `grep -c "ORA-" $TMP` -eq 0 ]; then
          ( echo "$file $TWO_TASK $ID_SWITCH `cksum $file`"
            cat $TMP ) | msg_api2 "I-RATING-BYPASS-IMPORTACAO"
	    cat $TMP
       else 
          ( echo "$file $TWO_TASK $ID_SWITCH `cksum $file`"
            cat $TMP; echo "RET=$ret" ) | msg_api2 "E-RATING-BYPASS-ERRO"
            cat $TMP
	    cat $TMP | mailx -s "${ORIGEM} - E-RATING-BYPASS-ERRO. `date`" prod@unix_mail_fwd 
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

LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
COUNT_TIME=`ls TH??????????????HS TH??????????????HB TH??????????????BS 2>/dev/null | wc -l`

printf "%s\t%s\t%s\t%s\n" "BYPASS_TIH" "Termino da carga de THs, ${COUNT_TIME} arquivos TH." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

COUNT_TIME=`ls DAP???????????????.?.? 2>/dev/null | wc -l`

printf "%s\t%s\t%s\t%s\n" "BYPASS_TIH" "Inicio da carga de DAPs, ${COUNT_TIME} arquivos DAP." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

# Carrega arquivos DAP
cd $DIR_DAP 2>$TMP
if [ $? != 0 ]; then
   ( echo "$0: Erro no cd para $DIR_DAP"
     cat $TMP ) | msg_ap2  E-RATING-BYPASS-ERRO
   rm -f $TMP $AUX
   exit 1
fi
for file in DAP???????????????.?.?
    do [ ! -f $file ] && continue
       DAP=1
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
#         rc=1
       fi
    done

LOC_TIME="`date +%d/%m/%Y %H:%M:%S`"
COUNT_TIME=`ls DAP???????????????.?.? 2>/dev/null | wc -l`

LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
printf "%s\t%s\t%s\t%s\n" "BYPASS_TIH" "Inicio da carga de DAPs, ${COUNT_TIME} arquivos DAP." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

if [ -s $LOG ] ; then
   /amb/operator/bin/attach_mail producao_spo@unix_mail_fwd \
   $LOG "Relacao de arquivos movidos para area de suspicious `date +%Y%m%d%H%M`"
fi

if [ $NORTEL = 0 -a $DAP = 0 ] ; then
   echo "Nenhum arquivo a ser processado !"
   exit 1
fi

if [ $rc != 0 ]; then
   echo "\n\t******************** ATENCAO **********************"
   echo "\n\t\tOcorreram erros durante o processo de bypass. "
   echo "\t\t\tProcesso abortado.\n"
   rm -f $TMP $AUX
   exit $rc
fi


rm -f $TMP $AUX
exit 0
