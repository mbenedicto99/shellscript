#!/bin/ksh

# Finalidade : Envia E-mail com PDF restaurados para usuário e remove PDF com mais de tres dias.
# Input      : N/A
# Output     : E-mail com PDF para o usuario.
# Autor      : Rafael dos Santos Toniete (Workmation).
# Data       : 2004/04


#---------------------------------------------#
#     DEFINICAO DAS VARIAVEIS DE AMBIENTE     #
#---------------------------------------------#
PID="${$}"

DIR_BASE="/home/cesantos/RECUP_PDF/solicitacao"
DIR_PDF="${DIR_BASE}/pdf"
DIR_ENVIADOS="${DIR_BASE}/enviados"
DIR_TEMP="${DIR_BASE}/temp"
DIR_ERRO="${DIR_BASE}/erro"

ARQ_MASK="ARQUIVOS_RESTORE_*.txt"

EQUIPE="prodmsol@nextel.com.br analise_producao@nextel.com.br"



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

  mailx -s "RECUPERACAO DE FATURAS - ERRO DE ENVIO DE PDF PARA USUARIO" "${EQUIPE}" << EOM
  Srs.,

   ATENCAO!!!!

   Ocorreu um erro no envio do PDF para o usuario, por favor verifiquem o ocorrido.
   ${MSG}

   Possiveis ERROS:
                   1) Nao foi possivel criar ou acessar um arquivo ou diretorio;
                   2) ERRO de envio de E-mail.

   Acionar:
                   1) Mauricio Sanches;
                   2) Analise de Producao;
                   3) Edison Santos.

  Atte.,

  Rotina Automatica do Control-M
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
  ARQUIVO_PDF="${7}"

  /amb/operator/bin/attach_mail ${EMAIL_USUARIO} ${ARQUIVO_PDF} "RESTORE - CODIGO BSCS: ${COD_BSCS} - DATA EMISSAO: ${DATA_EMISSAO} - DATA VENCIMENTO: ${DATA_VENCIMENTO} - VALOR FATURA: ${VAL_FATURA} - PRIORIDADE: ${PRIORIDADE}" >$TMP1 2>&1

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

--------------------	-----------	---------------	------------------	---------------	----------------------------	----------
ARQUIVO PARA RESTORE	CODIGO BSCS	DATA DA EMISSAO	DATA DE VENCIMENTO	VALOR DA FATURA	USUARIO PARA ENVIO DE FATURA	PRIORIDADE
--------------------	-----------	---------------	------------------	---------------	----------------------------	----------
`cat ${ARQ_RESTORE} | sort -k 7,1`
--------------------	-----------	---------------	------------------	---------------	----------------------------	----------


TOTAL DE ARQUIVOS
-----------------
      `cat ${ARQ_RESTORE} |wc -l`
-----------------


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
      |                     1) Mauricio Sanches;
      |                     2) Analise de Producao;
      |                     3) Edison Santos.
      |  
      +------------------------------------------------------------------------------------------\n"
     F_Email ${MSG}
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

    PRIORIDADE="`cat ${ARQ} |awk '{print $1}'`"
    COD_BSCS="`cat ${ARQ} |awk '{print $2}'`"
    DATA_EMISSAO="`cat ${ARQ} |awk '{print $3}'`"
    EMISSAO_ANO="`echo ${DATA_EMISSAO} |cut -c 1-4`"
    EMISSAO_MES="`echo ${DATA_EMISSAO} |cut -c 5-6`"
    DATA_VENCIMENTO="`cat ${ARQ} |awk '{print $4}'"
    VAL_FATURA="`cat ${ARQ} |awk '{print $5}'"
    EMAIL_USUARIO="`cat ${ARQ} |awk '{print $6}'`" 


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

    fi

  done

  F_EMAIL_PROVISORIO

  rm ${DIR_TEMP}/*_????????_????????
  F_Valida_RC ${?} "ERRO AO TENTAR REMOVER OS ARQUIVOS DE SOLICITACAO"
}


#---------------------------------------------#
# FUNCAO DE VERIFICACAO DE ARQUIVOS P/ TRANSF.#
#---------------------------------------------#

F_Verifica_Arq()
{
  cd ${DIR_ENTRADA}
  F_Valida_RC ${?} "ERRO AO ACESSAR O DIRETORIO: ${DIR_ENTRADA}"

  NUM_ARQS="`ls -1 |grep *_????????_???????? |wc -l`"

  if [ "${NUM_ARQS}" -eq "0" ]
  then
     echo "SEM ARQUIVOS PARA PROCESSAMENTO"
     F_Valida_RC 33 "NAO EXISTEM ARQUIVOS PARA PROCESSAR, VERIFICAR SE PROCESSO DE TRANSFERENCIA EXECUTOU OK!!!!"
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
