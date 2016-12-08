#!/bin/ksh 
#   Programa: BSCS_ROAM_05_01.sh
#   Recebe e carrega os arquivos de Roaming International na THUFITAB
#   Data: 08/04/99
#
## Mensagens
#M#I-BSCS_ROAM-050 : Sucesso no recebimento do arquivo de roaming international
#M#E-BSCS_ROAM-050 : Erro no recebimento do arquivo de Roaming International
#M#E-BSCS_ROAM-051 : Erro de infra-estrutura
#M#I-BSCS_ROAM-052 : Sucesso na carga do arquivo de Roaming International
#M#E-BSCS_ROAM-052 : Erro na carga do arquivo de Roaming International
#M#I-BSCS_ROAM-053 : Sequencia de numeracao correta
#M#W-BSCS_ROAM-053 : Erro na sequencia de numeracao
#

# Definicao de Variaveis

. /etc/appltab

typeset -i NUM_SEQ_ARQ NUM_SEQ_THUFITAB NUM_SEQ_CORRETA
typeset -l SITE

#SITE=$1
#DB_SITE=`echo $1 | tr '[a-z]' '[A-Z]'`
#	case ${DB_SITE} in
#SP) DB=RTX_SP;;
#RJ) DB=PRTX_RJ;;
#esac
#RCV=/artx_${SITE}/prod/WORK/SPLITER_SP
#DIR_WORK=/artx_${SITE}/prod/WORK/MP/TRAC/IN
#ARQ_PASSWD=/artx_${SITE}/prod/batch/bin/bscs.passwd

SITE="${ENV_VAR_SITE}"
DB="${ENV_TNS_PDRTX}"


RCV=${ENV_DIR_BASE_RTX}/prod/WORK/SPLITER
DIR_WORK=${ENV_DIR_BASE_RTX}/prod/WORK/MP/TRAC/IN
ARQ_PASSWD=${ENV_DIR_BASE_RTX}/prod/batch/bin/bscs.passwd
DEST=producao_spo@unix_mail_fwd
CONTADOR=0

### Alteracao para Consolidacao MIBAS/BSCS
###=================================================================================#
### if [ $SITE = "sp" ] ; then export TWO_TASK=PBSCS_SP
   ### else export TWO_TASK=PBSCS_RJ
### fi

export TWO_TASK="${ENV_TNS_PDBSC}"

###=================================================================================#

PASSWORD=`grep RLH $ARQ_PASSWD | cut -d"	" -f2`
PASSWORD=SYSADM
#export ORACLE_HOME=`grep ${DB} /etc/oratab | awk -F: '{print $2}'`
#export ORACLE_HOME=/ortx_${SITE}/app/oracle/product/default
export ORACLE_HOME="${ENV_DIR_ORAHOME_BSC}"
export PATH=$PATH:/${ORACLE_HOME}/bin
TMP=/tmp/roam_int_$$

if [ -z $ORACLE_HOME ] ; then
   echo "Nao encontrado $ORACLE_HOME do $TWO_TASK" | msg_api "E-BSCS_ROAM-051"
   exit 1
fi

if [ ! -f "$ARQ_PASSWD" ]
   then echo "$0: Arquivo de senhas não encontrado" | msg_api "E-BSCS_ROAM-051"
        exit 1
fi

cd $RCV 2>$TMP

if [ $? != 0 ]; then
   ( echo "Erro no cd $RCV" ; cat $TMP ) | msg_api "E-BSCS_ROAM-051"
       rm -f $TMP
     exit 1
fi
LOG_DATE=`date +%d%m%Y`
LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
LOG_TIME="${ENV_DIR_BASE_RTX}/prod/reports/TAPIN_${LOG_DATE}.txt"
COUNT_TIME="`ls CD?????BRANC????? 2>/dev/null | wc -l`" 

printf "%s\t%s\t%s\t%s\n" "TAPIN_05_01" "Inicio do processamento, ${COUNT_TIME} arquivos." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

for file in CD?????BRANC?????
    do [ ! -f $file ] && continue
       OPERADORA=`echo $file | cut -c 3-7`
       NUM_SEQ_ARQ=`echo $file | cut -c 13-17`
       [ ! -d $DIR_WORK/$OPERADORA ] && mkdir $DIR_WORK/$OPERADORA
       chown prod:bscs $DIR_WORK/$OPERADORA
       mv $file $DIR_WORK/$OPERADORA > $TMP

       if [ $? != 0 ]; then
          ( echo "Erro ao mover arquivo $file para $DIR_WORK/$OPERADORA"
            cat $TMP ) | msg_api "E-BSCS_ROAM-051"
            cat $TMP 
          rm -f $TMP
          exit 1
       fi

       chown prod:bscs $DIR_WORK/$OPERADORA/$file
       echo "$SITE - $OPERADORA - Arquivo recebido com sucesso" |\
            msg_api "I-BSCS_ROAM-050"

       #
       # Verifica se sequencia do numero do arquivo esta correta
       #

       NUM_SEQ_THUFITAB=`$ORACLE_HOME/bin/sqlplus -s RLH/${PASSWORD}@${TWO_TASK} << EOF
       set head off;
       set echo off;
       SELECT MAX(FLSQN) FROM MPURHTAB
       WHERE FLSRC='$OPERADORA'
       AND FLDIR = 'I';
       exit;
EOF`
       (( NUM_SEQ_CORRETA=$NUM_SEQ_THUFITAB + 1 ))
       if [ $NUM_SEQ_ARQ = $NUM_SEQ_CORRETA ] ; then
           echo "$SITE - $OPERADORA - Sequencia de numeracao correta" | msg_api "I-BSCS_ROAM-053"
         else 
           echo "$SITE - $OPERADORA - Erro na sequencia de numeracao
                Numero na base de dados:	$NUM_SEQ_THUFITAB
                Numero no arquivo:		$NUM_SEQ_ARQ"	| msg_api "W-BSCS_ROAM-053"
       fi
       FILETYPE=`$ORACLE_HOME/bin/sqlplus -s RLH/${PASSWORD}@${TWO_TASK} << EOF
          set head off;
          set echo off;
          select min(FT_ID) from thsfttab where plmn='$OPERADORA' and IO='I';
          exit
EOF`
       FILETYPE=`echo $FILETYPE | tr -d "\n"`
       NUM_SEQ_ARQ=`$ORACLE_HOME/bin/sqlplus -s RLH/${PASSWORD}@${TWO_TASK} << EOF
          set head off;
          set feedback off;
          set echo off;
          select max(file_id)+1 from thufitab;
EOF`
       $ORACLE_HOME/bin/sqlplus -s RLH/${PASSWORD}@${TWO_TASK} << EOF > $TMP
          set head off;
          set feedback off;
          set echo off;
          insert into thufitab values ($NUM_SEQ_ARQ,0,$FILETYPE,'$file',sysdate,0,null,null,1,null);
          commit;
EOF
       if [ $? = 0 ]
          then ( echo "$SITE - $OPERADORA - Arquivo $file carregado com sucesso na THUFITAB"
                 cat $TMP ) | msg_api "I-BSCS_ROAM-052"
          rm -f $TMP 
          CONTADOR=`expr $CONTADOR + 1`
       fi
    done
    echo "Foram carregados ${CONTADOR} arquivos de TapIn" |\
          mailx -s "Foram carregados ${CONTADOR} arquivos de TapIn" $DEST


LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
COUNT_TIME="`ls CD?????BRANC????? 2>/dev/null | wc -l`" 

printf "%s\t%s\t%s\t%s\n" "TAPIN_05_01" "Termino do processamento, ${COUNT_TIME} arquivos." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

rm -f $TMP

exit 0
