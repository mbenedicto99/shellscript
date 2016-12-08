#!/bin/ksh
#  Script      : CTM_LOADJOBS-BILL-DES.sh
#  Objetivo    : - SImula a lieberacao de ciclo, fazendo UPDATE da data de CORTE na
#                  mscpftab (cfcode=23) e criando os arquivos BCH e BGH flag, que contem
#                  as datas de Corte, Inicio, FIm de Faturamento e Vencimento de Fatura,
#                  para processamento do CICLO CG de Testes de Desenvolvimento.
#
#  Criticidade : - Media : Em caso de ABEND, comunicar ao analista que solicitou a execucao.
# 
# Parametros de chamada: 
#                        1 - Ciclo
#                        2 - Datas para processamento do TESTE '(AAMMDD,AAMMDD,AAMMDD,AAMMDD)'"
#                        Onde:  
#                            (AAAAMMDD,AAAAMMDD,AAAAMMDD,AAAAMMDD) =  Datas informadas no E-MAIL do solicitante.
#                              1a. data = Data de Corte 
#                              2a. data = Data de Inicio de Periodo Fat.
#                              3a. data = Data de Fim    de Periodo Fat.
#                              4a. data = Data de Vencimento da Fatura. 
#                        3 - "N" ou "S" - Parametro para "forcar" criacao do arq. de liberacao mesmo que o
#                            JOB tenha emitido ABEND informando que nao poderia ser executado
#                            por haver outra liberacao em andamento.
#                            Caso o JOB termine com erro informando que ja existe arquivo de liberacao
#                            e haja certeja de que o processo de liberacao pode executar, alterar o 
#                            parametro $3 para "S". Isto ira forcar a simulacao da liberacao.
#
#=======================================================================================#

# Display informativo do processo
echo "
  *----------------------------------------------------------*
  |  Data/Hora do START ...: `date`
  |  Processo executado ...: $0
  |  Parametros informados : $*
  *----------------------------------------------------------*\n "

#  Carregamento das Variaveis de ambiente...
. /etc/appltab

#  Carregamento das Variaveis Locais

#     Diretorio para criacao dos arquivos FLG.
DIR_AUTH="${ENV_DIR_BASE_RTX}/prod/WORK/TMP"

#     Variaveis para acesso ORACLE via SQLPLUS
export LOC_LOGIN_PDBSC_BCH2="sysadm/wizardmagic03"
export ORACLE_HOME="${ENV_DIR_ORAHOME_BSC}"
export TWO_TASK="${ENV_TNS_PDBSC}"
export NLS_LANG="${ENV_NLSLANG_PDBSC}"
RC=0

#     Inicializacao da variael de Controle de Erros
MsgErro=""

#=======================================================================================#
# Funcao para validacao de STATUS CODE
F_ValidaRc()
{
  CodErro="$1"
  MsgErro="$2"

  if [ "${CodErro}" != "0" ] 
  then
     banner ERRO!!
     echo "
         *================================================*
         * Erro no processo de :
         * ${MsgErro}
         * RC = ${CodErro}
         *================================================*
          "
     exit ${CodErro}
  fi
}
#=======================================================================================#

#   Validacao de Varaiveis de Chamada!!
case $#
in 
   [2-3]) # Qtde de PARMS OK
      case $1
      in
        0[12345789]|1[01234567]) # Num. CICLO Correto..........
                              BILLCYCLE=$1
                              ;;
                           *) #  Valor de CICLO Invalido....
                              MsgErro="ERRO: Billcycle [$1] invalido"
                              RC=70
                              ;;
      esac

      CheckParmData="`echo $2 | awk -F\, '{ print NF }'`"

      if [ "${CheckParmData}" -ne "4" ]
      then
         MsgErro="ERRO: Qtde de PARMS de Data ( PARM 8 Invalido ) CheckParmData = ${CheckParmData} !!"
         RC=80
      else
         FILE_DATE="`echo $2 | tr -d \"() '\"`"
      fi

      if [ "${3}" != "S" ]
      then 
         FORCE="N"
      else
         FORCE="S"
      fi
      ;;
   *) #  Erro na Qtde de Parametros
      MsgErro="ERRO: Qtde de PARMS de chamada invalida!! Qtde de parms.: $# "
      RC=90
      ;;
esac

MsgErro="${MsgErro}\n Sintaxe:\n   BILLING_SIMULA_LIBERA.sh <CICLO> '(AAMMDD,AAMMDD,AAMMDD,AAMMDD)'"
F_ValidaRc $RC "${MsgErro}"

#   Validacao de Varaiveis de Chamada!!

FILE_AUTH="${DIR_AUTH}/CYCLE-${BILLCYCLE}.flg"

if [ -f ${FILE_AUTH} ]
then
   if [ "${FORCE}" = "S"  ]
   then
      echo "Detectada a preexistencia de arquivo de liberacao!!!!!"
      echo "Liberacao do ciclo forcada pela especificacao do parametro 'FORCE=S'"
   else
      MsgErro="Arquivo de parametros ja existe nao pode ser alterado."
      F_ValidaRc 99 "${MsgErro}"
   fi
fi

#  Carrega datas para processamento do BILLING, a partir do parametro $2 informado na execucao.
echo ${FILE_DATE} | awk -F\, '{ print substr($1,5,2) substr($1,3,2) substr($1,1,2)'

###DATA_CORTE_BCH="`echo ${FILE_DATE} | awk -F\, '{ print $1}'`"
###DATA_INICIO="`echo ${FILE_DATE}    | awk -F\, '{ print substr($2,5,2) substr($2,3,2) substr($2,1,2)}'`"
###DATA_TERMINO="`echo ${FILE_DATE}   | awk -F\, '{ print substr($3,5,2) substr($3,3,2) substr($3,1,2)}'`"
###DATA_VENCIMENTO="`echo ${FILE_DATE}| awk -F\, '{ print substr($4,5,2) substr($4,3,2) substr($4,1,2)}'`"
DATA_CORTE_BCH="`echo ${FILE_DATE} | awk -F\, '{ print $1}'`"
DATA_INICIO="`echo ${FILE_DATE}    | awk -F\, '{ print $2}'`"
DATA_TERMINO="`echo ${FILE_DATE}   | awk -F\, '{ print $3}'`"
DATA_VENCIMENTO="`echo ${FILE_DATE}| awk -F\, '{ print $4}'`"

> ${FILE_AUTH}
printf "%s\n" "`date`" "${DATA_INICIO}" "${DATA_CORTE_BCH}" "${DATA_VENCIMENTO}" >>${FILE_AUTH}
RC=$?

MsgErro="Erro na criacao do Arquivo Flag de liberacao de CICLO!!!!!!! \n `ls -ltr ${FILE_AUTH}`"
F_ValidaRc $RC "${MsgErro}"

echo "
  *----------------------------------------------------------*
  |  Data/Hora do END .....: `date`
  *----------------------------------------------------------* "
