#!/bin/ksh

# Finalidade : Executar QUERY para identificar diretorio de PDF de determinado cliente, com base nos 
#              dados de CODIGO BSCS e Data de Emissao da Fatura.
#              Se ocorrer algum erro na execucao, envia e-mail e exibe mensagem para orientacao de
#              possiveis acoes.
# Input      : N/A
# Output     : SPOOL com o diretsrio e PDF a ser recuperado, E-Mail e mensagem para orientacao.
# Autor      : Edison Santos (Workmation).
# Data       : 2004/03
# Modificado : Rafael dos Santos Toniete (Workmation)
# Data       : 2004/03

. /etc/appltab

## Base		PNVFAT    PNVFAT_SP
## Usuario	WFTUSR
## Senha	WFTUSR456

#---------------------------------------------#
#     DEFINICAO DAS VARIAVEIS DE AMBIENTE     #
#---------------------------------------------#
export TWO_TASK=${ENV_TNS_PNVFAT}
export ORACLE_HOME="${ENV_DIR_ORAHOME_PNVFAT}"
export NLS_LANG="${ENV_NLSLANG_PNVFAT}"

DATA="`date +%Y%m%d`"

PID="${$}"

DIR_BASE="/sql_rels_spoaxap9/solicitacao_restore"
DIR_ENTRADA="${DIR_BASE}/entrada"
DIR_PROCESSADOS="${DIR_BASE}/processados"
DIR_TEMP="${DIR_BASE}/temp"
DIR_ERRO="${DIR_BASE}/erro"
DIR_SQL="/amb/scripts/sql"

ARQ_SQL="BSCS_DETECTA_DIR_BGH.sql"
ARQ_SPOOL="${DIR_TEMP}/DIRETORIO_PDF.txt"
ARQ_RESTORE="${DIR_BASE}/saida/ARQUIVOS_RESTORE_${DATA}_${PID}.txt"

EQUIPE="analise_producao@nextel.com.br lausanne@unix_mail_fwd regiane@unix_mail_fwd"
DESCRICAO="Seleciona diretorio para recuparacao de faturas PDF (RESTORE)"
ASSUNTO_EMAIL="ERRO DE EXECUCAO DE SQL"

USR_PWD="WFTUSR/WFTUSR456"


#---------------------------------------------#
#       FUNCAO DE FINALIZACAO DO SCRIPT       #
#---------------------------------------------#

F_Fim()
{
  typeset -3Z RC="${1}"

  echo " #--------------------------------------------------------------------#"
  echo " #                      TERMINO DO PROGRAMA                           #"
  echo " #--------------------------------------------------------------------#"
  echo "  FIM DO PROGRAMA: `date '+%d%m%Y - %H%M%S'`           RETORNO: ${RC}           #"
  echo " #--------------------------------------------------------------------#"
  exit ${RC}
}


#---------------------------------------------#
#          FUNCAO PARA ENVIAR EMAIL           #
#---------------------------------------------#

F_Email()
{
  MSG="${1}"

  mailx -s "RECUPERACAO DE FATURAS - ERRO DE PROCESSAMENTO DE RESTORE" "${EQUIPE}" << EOM
  Srs.,

   ATENCAO!!!!

   Ocorreu um erro na execucao do SQL para gerar arquivos para RESTORE.
   ${MSG}

   Possiveis ERROS:
                   1) Nao foi possivel criar ou acessar um arquivo ou diretorio;
                   2) A Base de Dados nao esta no AR.

   Acionar:
                   1) Mauricio Sanches;
                   2) Analise de Producao;
                   3) Edison Santos.

  Atte.,

  Rotina de Automatizacao do Control-M
  NEXTEL
EOM
}

#---------------------------------------------#
#    FUNCAO PARA ENVIAR E-MAIL P/ USUARIO     #
#---------------------------------------------#

F_Mail_User()
{
  COD_BSCS="${1}"
  DATA_EMISSAO="${2}"
  DATA_VENCIMENTO="${3}"
  VAL_FATURA="${4}"
  EMAIL_USUARIO="${5}"
  PRIORIDADE="${6}"

  mailx -s "ERRO NA SOLICITACAO DE RECUPERACAO DE FATURAS - ${COD_BSCS}" "${EMAIL_USUARIO}@nextel.com.br" << EOM
  Caro solicitante,

   Identificamos que os dados informados para a recuperacao de uma fatura nao esta correto

   Os dados informados nao estao corretos:

       CODIGO BSCS: ${COD_BSCS}
       DATA DA EMISSAO: ${DATA_EMISSAO}
       DATA DE VENCIMENTO: ${DATA_VENCIMENTO}
       VALOR DA FATURA: ${VAL_FATURA}
       PRIORIDADE: ${PRIORIDADE}

   Solicitamos que verifique os dados informados e reenvie a solicitacao.


  Atte.,

  Rotina Automatica de Restore
  NEXTEL
EOM
}


#---------------------------------------------#
#      FUNCAO PARA ENVIAR EMAIL PROVISORIO    #
#---------------------------------------------#
F_EMAIL_PROVISORIO()
{

  mailx -s "SOLICITACAO DE RECUPERACAO DE FATURAS" "${EQUIPE}" << EOM
  Analise de Producao,

   Segue abaixo dados de arquivos para serem restaurados:

ARQUIVO PARA RESTORE	CODIGO BSCS	DATA DA EMISSAO	DATA DE VENCIMENTO	VALOR DA FATURA	USUARIO PARA ENVIO DE FATURA	PRIORIDADE
____________________	___________	_______________	__________________	_______________	____________________________	__________
`cat ${ARQ_RESTORE} | sort -k 7,1`
____________________	___________	_______________	__________________	_______________	____________________________	__________


TOTAL DE ARQUIVOS
_________________
      `cat ${ARQ_RESTORE} |wc -l`
_________________


  Atte.,

  Rotina Automatica de Restore
  NEXTEL
EOM

}


#---------------------------------------------#
#        FUNCAO DE VALIDACAO DE ERROS         #
#---------------------------------------------#

F_Valida_RC()
{
  RC="${1}"
  MSG="${2}"

  if [ "${RC}" -ne "0" ]
  then
     banner "ERRO!!"
     echo "\n
      +------------------------------------------------------------------------------------------
      |
      |  Srs.,
      |
      |     ATENCAO!!!!
      |
      |     Ocorreu um erro na execucao do SQL para gerar arquivos para RESTORE.
      |     ${MSG}
      |
      |     Possiveis ERROS:
      |                     1) Nao foi possivel criar ou acessar um arquivo ou diretorio;
      |                     2) A Base de Dados nao esta no AR.
      |
      |     Acionar:
      |                     1) Marcos de Benedicto;
      |                     2) Analise de Producao;
      |                     3) Marcos de Benedicto.
      |  
      +------------------------------------------------------------------------------------------\n"
     F_Email "${MSG}"
     F_Fim ${RC}
  fi
}


#---------------------------------------------#
#       FUNCAO PARA PROCESSAR ARQUIVOS        #
#---------------------------------------------#

F_Processa_Arq()
{
  for ARQ in `ls -1 ${DIR_TEMP}/*_????????_????????`
  do
    NEW_ARQ="`echo \"${ARQ}\" |sed 's/ //g'`"
    mv "${ARQ}" "${NEW_ARQ}"
    ARQ="${NEW_ARQ}"
    dos2ux ${ARQ} >${DIR_TEMP}/temporario.tmp
    mv ${DIR_TEMP}/temporario.tmp ${ARQ}

    PRIORIDADE="`cat ${ARQ} |awk '{print $1}'`"
    COD_BSCS="`cat ${ARQ} |awk '{print $2}'`"
    DATA_EMISSAO="`cat ${ARQ} |awk '{print $3}'`"
    EMISSAO_ANO="`echo ${DATA_EMISSAO} |cut -c 1-4`"
    EMISSAO_MES="`echo ${DATA_EMISSAO} |cut -c 5-6`"
    DATA_VENCIMENTO="`cat ${ARQ} |awk '{print $4}'"
    VAL_FATURA="`cat ${ARQ} |awk '{print $5}'"
    EMAIL_USUARIO="`cat ${ARQ} |awk '{print $6}'`" 

    [ -z "${PRIORIDADE}" ] && F_Valida_RC 1 "ERRO: Variavel PRIORIDADE vazia."
    [ -z "${COD_BSCS}" ] && F_Valida_RC 1 "ERRO: Variavel CODIGO BSCS vazia."
    [ -z "${DATA_EMISSAO}" ] && F_Valida_RC 1 "ERRO: Variavel DATA_EMISSAO vazia."
    [ -z "${EMISSAO_ANO}" ] && F_Valida_RC 1 "ERRO: Variavel EMISSAO_ANO vazia."
    [ -z "${EMISSAO_MES}" ] && F_Valida_RC 1 "ERRO: Variavel EMISSAO_MES vazia."
    [ -z "${DATA_VENCIMENTO}" ] && F_Valida_RC 1 "ERRO: Variavel DATA_VENCIMENTO vazia."
    [ -z "${VAL_FATURA}" ] && F_Valida_RC 1 "ERRO: Variavel VAL_FATURA vazia."
    [ -z "${EMAIL_USUARIO}" ] && F_Valida_RC 1 "ERRO: Variavel EMAIL_USUARIO vazia."

    #### . /amb/eventbin/SQL_RUN.PROC3 ${TWO_TASK} WFTUSR/WFTUSR456  "/amb/scripts/sql/BSCS_DETECTA_DIR_BGH.sql  <COD.BSCS> <ANO DATA EMISSAO> <MES DATA EMISSAO>" edison@unix_mail_fwd "Seleciona diretorio para recuparacao de faturas PDF (RESTORE)" 0 DIRETORIO_PDF.txt 0

    /amb/eventbin/SQL_RUN.PROC3 "${TWO_TASK}" "${USR_PWD}"  "${DIR_SQL}/${ARQ_SQL}  ${COD_BSCS} ${EMISSAO_ANO} ${EMISSAO_MES}" "${EQUIPE}" "${DESCRICAO}" "0" "${ASSUNTO_EMAIL}" "${ARQ_SPOOL}"
    F_Valida_RC ${?} "ERRO NA EXECUCAO DO SQL DE PESQUISA DOS ARQUIVOS PARA RESTORE"

    [ ! -f "${ARQ_SPOOL}" ] && F_Valida_RC ${?} "ERRO AO TENTAR CRIAR O ARQUIVO DE SPOOL: ${ARQ_SPOOL}"

    NO_ROWS="`grep 'no rows selected' ${ARQ_SPOOL}`"
    VAR_RESTORE="`grep .pdf ${ARQ_SPOOL} |awk '{print $1}'`"

    rm ${ARQ_SPOOL}
    F_Valida_RC ${?} "ERRO AO TENTAR REMOVER O ARQUIVO DE SPOOL: ${ARQ_SPOOL}"

    if [ -z "${VAR_RESTORE}" -o "${NO_ROWS}" = "no rows selected" ]
    then
       echo " +--------------------------------------------------------+"
       echo "   Os dados informados nao foram encontrados."
       echo "      CODIGO: ${COD_BSCS}"
       echo "      DATA EMISSAO: ${DATA_EMISSAO}"
       echo " +--------------------------------------------------------+"

       F_Mail_User ${COD_BSCS} ${DATA_EMISSAO} ${DATA_VENCIMENTO} ${VAL_FATURA} "${EMAIL_USUARIO}" ${PRIORIDADE}

       mv ${ARQ} ${DIR_ERRO}
       F_Valida_RC ${?} "ERRO AO TENTAR MOVER O ARQUIVO: ${ARQ}"
    else
       echo "${VAR_RESTORE}	${COD_BSCS}	${DATA_EMISSAO}	${DATA_VENCIMENTO}	${VAL_FATURA}	${EMAIL_USUARIO}	${PRIORIDADE}" >>${ARQ_RESTORE}
       F_Valida_RC ${?} "ERRO AO GERAR O AQUIVO COM DADOS PARA REALIZAR RESTORE"
       
       mv ${ARQ} ${DIR_PROCESSADOS}
       F_Valida_RC ${?} "ERRO AO TENTAR REMOVER O ARQUIVO DE SOLICITACAO: ${ARQ}"

    fi

  done
  
  [ -f "${ARQ_RESTORE}" ] && F_EMAIL_PROVISORIO || F_Fim 0

}


#---------------------------------------------#
# FUNCAO DE VERIFICACAO DE ARQUIVOS P/ TRANSF.#
#---------------------------------------------#

F_Verifica_Arq()
{
  cd ${DIR_ENTRADA}
  F_Valida_RC ${?} "ERRO AO ACESSAR O DIRETORIO: ${DIR_ENTRADA}"

  NUM_ARQS="`ls -1 *_????????_???????? |wc -l`"

  if [ "${NUM_ARQS}" -eq "0" ]
  then
     echo "SEM ARQUIVOS PARA PROCESSAMENTO"
     F_Fim 0
  else
     echo " +--------------------------------------------------------+"
     echo "   ARQUIVOS ENCONTRADOS"

     echo "   MOVENDO ARQUIVOS PARA AREA TEMPORARIA"
     mv ${DIR_ENTRADA}/*_????????_???????? ${DIR_TEMP}
     F_Valida_RC ${?} "ERRO AO MOVER OS ARQUIVOS PARA AREA TEMPORARIA"

     echo "   INICIANDO PROCESSAMENTO"
     echo " +--------------------------------------------------------+"

     cd ${DIR_TEMP}
     F_Valida_RC ${?} "ERRO AO ACESSAR O DIRETORIO: ${DIR_TEMP}"

     F_Processa_Arq
  fi
}


#---------------------------------------------#
#     INICIO DO PROCESAMENTO DO PROGRAMA      #
#---------------------------------------------#

echo " #--------------------------------------------------------------------#"
echo " #                       INICIO DO PROGRAMA                           #"
echo " #--------------------------------------------------------------------#"
echo "  INICIO DO PROGRAMA: `date '+%d%m%Y - %H%M%S'`                               #"
echo " #--------------------------------------------------------------------#"

F_Verifica_Arq
