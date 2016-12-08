#!/bin/ksh
# Atualiza a Tabela USER_WINDOW do BSCS
# analista:  GEORGE

. /etc/appltab

#Mensagens
#---------
#M#I-BSCS_04-001: (Sucesso) Atualiza tabela USER_WINDOW
#M#E-BSCS_04-001: (Erro) Atualiza tabela USER_WINDOW

# Atribuicao de variaveis
#-------------------------
DESTERR="sql_erros@unix_mail_fwd"
DAT=`date`

# Alterado em 2003/08/13 - Mauricio Sanches (Workmation) - Consolidacao MIBAS - BSCS
#===================================================================================#
#MAQ=`uname -n`
#case "$MAQ" in
#  spo*) export TWO_TASK=PBSCS_SP
#        site=sp
#         ;;
#  rjo*) export TWO_TASK=PBSCS_RJ
#        site=rj
#         ;;
#     *) echo "site invalido"
#        exit 1 ;;
#esac
#site="${ENV_VAR_SITE}"
#===================================================================================#

TMP1=/tmp/sql1_$$
TMP2=/tmp/sql2_$$.sql
### export ORACLE_HOME=`grep ^${TWO_TASK}: /etc/oratab | cut -d: -f2`
### export NLS_LANG="brazilian portuguese_brazil.we8dec"

export TWO_TASK="${ENV_TNS_PDBSC}"
export ORACLE_HOME="${ENV_DIR_ORAHOME_BSC}"
export NLS_LANG="${ENV_NLSLANG_PDBSC}"

DEST="BSCS_04@unix_mail_fwd"
SUBJ="Atualizacao da USER_WINDOW"
TMP3=/tmp/atualiza_user_window.txt 


# Criacao de SQL
#---------------
cat << EOF > $TMP2
whenever sqlerror exit failure
whenever oserror exit failure
spool $TMP3
update USER_WINDOW set win_posx = -3, win_posy = -4 ;
commit ;
spool off
exit
EOF


# Execucao de SQL
#----------------
chmod 644 $TMP2
$ORACLE_HOME/bin/sqlplus / @$TMP2 > $TMP1 2>&1
RC=$?

# Envio de e-mail
#----------------
#if [ $RC != 0 ]; then
#   ( echo "ERRO: $SUBJ"
#     echo "Erro na execucao do $SQL" 
#     cat $TMP1 ) | msg_api "E-BSCS_04-001"
#   /amb/operator/bin/attach_mail $DESTERR $TMP1 "$SUBJ" 
#   else
#      ( echo "Sucesso: $SUBJ"
#        echo "Sucesso na execucao de $SQL" ) | msg_api "I-BSCS_04-001"
#      /amb/operator/bin/attach_mail $DEST $TMP3 "$SUBJ" >$TMP1 2>&1
#      if [ $? != 0 ]; then
#         ( echo "ERRO: $SUBJ"
#           echo "Erro enviando mail"; cat $TMP1) | msg_api "E-BSCS_04-001"
#      fi
#fi
#
#
# Cleaning
#
rm -f $TMP1 $TMP2 $TMP3
exit 0
