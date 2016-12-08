#!/bin/ksh
##
# bscs_bypass_tih_dap
#
#M#I-LCDR-021 : Sucesso na inclusão do registro na tabela THUFITAB
#M#E-LCDR-021 : Erro    na inclusão do registro na tabela THUFITAB
#M#E-LCDR-022 : Erro de infra-estrutura
#
# Alteracao 06/03/02
#

. /etc/appltab

TMP=/tmp/tih_$$
AUX=/tmp/tihsql_$$.sql
typeset -u -L3 SITE
typeset -u -R23 file

SITE="${ENV_VAR_CITY}"

DIR_DAP="${ENV_DIR_DAP_RTX}"
ARQ_PASSWD=${ENV_DIR_BASE_RTX}/prod/batch/bin/bscs.passwd
export TWO_TASK="${ENV_TNS_PDBSC}"
export ORACLE_HOME="${ENV_DIR_ORAHOME_BSC}"

export PATH=$PATH:/${ORACLE_HOME}/bin

echo "\n** Executando bypass tih dap...\n"

if [ ! -f "$ARQ_PASSWD" ]; then
   echo "$0: Arquivo de senhas não encontrado" | msg_api E-LCDR-022
   exit 1
fi

TIH_PASSWD=`awk '/^TIH[ 	]/ { a=$2; } END { print a }' $ARQ_PASSWD`
if [ -z "$TIH_PASSWD" ]; then
   echo "$0: Senha do usuário TIH não encontrada" | msg_api E-LCDR-022
   exit 1
fi

if [ -z "$DIR_DAP" ]; then
   echo "$0: Variável DIR_DAP não definida" | msg_api E-LCDR-022
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
     WHERE FILENAME = '&1';
    IF V_FILE > 0 THEN
         RAISE_APPLICATION_ERROR(-20001,'ARQUIVO PROCESSADO ANTERIORMENTE!!!');
    END IF;
END;
/

INSERT INTO THUFITAB
(SELECT MAX(FILE_ID)+1, 0, '&3', '&1', SYSDATE, 
 0, 2048, '&2', 1, null  FROM THUFITAB);

COMMIT;
EXIT;
EOF

if [ $? != 0 ]; then
   ( echo "$0: Erro ao criar o SQL $AUX"
     cat $TMP ) | msg_api E-LCDR-022
     echo "$0: Erro ao criar o SQL $AUX"
     cat $TMP 
   rm -f $TMP $AUX
   exit 8
fi

rc=0

# Carrega arquivos DAP
cd $DIR_DAP 2>$TMP
if [ $? != 0 ]; then
   ( echo "$0: Erro no cd para $DIR_DAP"
     cat $TMP ) | msg_api E-LCDR-022
     cat $TMP 
   rm -f $TMP $AUX
   exit 1
fi

# Verifica QTD DAP
NUM_DAP=1
while [ "${NUM_DAP}" -le 7 ]
do
    TOT_DAP="`ls -1 DAP${NUM_DAP}*.CONV |wc -l`"
    if [ "${TOT_DAP}" -lt 24 ]
    then
        echo "
              +--------------------------------------------------------
                Existem menos de 24 DAP${NUM_DAP} para processamento.
                Segue lista de arquivos encontrados:
                \n`ls -1 DAP${NUM_DAP}*.CONV`
                TOTAL = ${TOT_DAP}
              +--------------------------------------------------------" |mailx -s "Quantidade de arquivos DAP${NUM_DAP}." prodmsol@nextel.com.br,billing_process@nextel.com.br
    fi
    NUM_DAP="`expr ${NUM_DAP} + 1`"
done


# Seleciona os arquivos que nao tenham setado o bit de execucao do "others"
find . ! -perm -1 -name DAP\?\?\?\?\?\?\?\?\?\?\?\?\?\?\?.CONV -print |\
while read ARQUIVO
do file=$ARQUIVO
   [ ! -f $file ] && continue
   TYPE=6
   [ "${SITE}" = "SPO" ] && ID_SWITCH="55110000000" 
   [ "${SITE}" = "RJO" ] && ID_SWITCH="55210000000"

   sqlplus TIH/${TIH_PASSWD}@${TWO_TASK} \
           @$AUX $file $ID_SWITCH $TYPE >$TMP 2>&1
   ret=$?

   if [ $ret = 0 ]; then
      ( echo "$file $TWO_TASK $ID_SWITCH `cksum $file`"
        cat $TMP ) | msg_api "I-LCDR-021"
        cat $TMP 
   else
       if [ "`grep -c \"ARQUIVO PROCESSADO ANTERIORMENTE\" ${TMP}`" -ne 0 ]
       then
	   echo "O arquivo ${file} esta pendente na area de WORK do DAP." |mailx -s "ARQUIVO DAP PENDENTE" billing_process@nextel.com.br
           continue
       fi
       ( echo "$file $TWO_TASK $ID_SWITCH `cksum $file`"
         cat $TMP; echo "RET=$ret" )
       rc=1
  fi
done

# Backup DAP
#echo "\n** Executando copy_tih...\n"
#/amb/operator/bin/copy_tih DAP
### /amb/eventbin/consolidacao/OK/copy_tih DAP
#[ $? != 0 ] && rc=2


if [ $rc != 0 ]; then
   echo "\n\t******************** ATENCAO **********************"
   echo "\n\t\tOcorreram erros durante o processo de bypass. "
   echo "\t\t\tProcesso abortado.\n"
   rm -f $TMP $AUX
   exit $rc
fi


rm -f $TMP $AUX
exit 0

