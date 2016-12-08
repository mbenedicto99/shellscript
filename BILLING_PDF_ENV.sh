#!/bin/ksh
#  Script      : BILLING_PDF_ENV.sh
#  Objetivo    : Compacta e envia os PDF's e envia para Usuarios
#  Criticidade : Alta - Se ocorrer Erro acionar Analista Responsavel
#  Alteracao   : 19/10/02
#
# Display informativo do processo
echo "
  *----------------------------------------------------------*
  |  Data/Hora do START ...: `date`
  |  Processo executado ...: $0
  |  Parametros informados : $*
  *----------------------------------------------------------*\n "

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
         * `printf \" \t %30s  #\n \" \"${MsgErro}\"`
         * RC = ${CodErro}
         *================================================*\n "
     exit ${CodErro}
  fi
}
#=======================================================================================#

#  Carregamento das Variaveis de Chamada
Ciclo="$1"
ModBill="`echo $2 | tr [a-z] [A-Z]`"
let TamVarCiclo="`echo ${Ciclo} | wc -c`"+1-1


[ "${Ciclo}" -lt "0" -o "${Ciclo}" -gt "14" -o "${TamVarCiclo}" -eq "3" ]
RC=$?

#[ "${ModBill}" != "CG" -a "${ModBill}" != "TESTE" ] && (return 10) 
[ "${ModBill}" = "CG" -o "${ModBill}" = "TESTE" ] && (return 0) || (return 10)
RC=`expr $? + $RC`

MsgErro="Parametro(s) de chamada invalido(s)!!!\n Sintaxe: \n\t\tBILLING_PDF_ENV.sh <CICLO - Val Validos 01-14>  <Modalidade (CG ou TESTE)>"
F_ValidaRc $RC "${MsgErro}"


#  Atribuicao de valores logicos de sistema p/ variaveis Locais
RunDate=`date +%Y%m%d`
LogCmds=/tmp/${ModBill}${Ciclo}${RunDate}_err.$$

#  Atribuicao de valores logicos de sistema p/ variaveis Locais
DirVar=`cat /pinvoice/diretorios/CG_RJ | cut -c 1-15`
DirRaiz="/pinvoice/${DirVar}"
DirLoc="/pinvoice/${DirVar}/data/RJ"
DirBkpComp="/pinvoice/BCH_CG_BKP"
DirBkpExt="${DirBkpComp}/ORI"
WrkFile="/tmp/${ModBill}_${DirVar}.attach"

if [ "${ModBill}" = "TESTE" ]
then
EMail="billing@unix_mail_fwd" 
EMail2="prodmsol@nextel.com.br"
fi

[ "${ModBill}" = "CG"    ] && EMail=bill_process@unix_mail_fwd 

# TESTES
## EMail=edison@unix_mail_fwd

#   Check da existencia do diretorio receptor dos arquivos
[ -d ${DirBkpExt} ]
RC=$?

MsgErro="Checagem do Diretorio para recepcao dos PDFs !!! Diretorio nao existe (DirBkpExt: ${DirBkpExt} )!! "
F_ValidaRc $RC "${MsgErro}"

#   Check da existencia do diretorio receptor dos arquivos Comprimidos
[ -d ${DirBkpComp} ]
RC=$?

MsgErro="Checagem do Diretorio para recepcao dos PDFs Comprimidos!!! Diretorio nao existe (DirBkpComp: ${DirBkpComp} )!! "
F_ValidaRc $RC "${MsgErro}"

#   Check da existencia do diretorio de Processamento do BCH (disponibiliza PDF's)
[ -d ${DirLoc} ]
RC=$?

MsgErro="Checagem do Diretorio de criacao dos PDFs !!! Diretorio nao existe (DirLoc: ${DirLoc} )!! "
F_ValidaRc $RC "${MsgErro}"

#  Identifica os arquivos PDFs do CG/Testes e copia para o diretorio BKP
MsgErro="Copia dos arquivos PDF p/ diretorio BKP!!!"
## find /pinvoice/20031111.121026/data/RJ/05  -name *.pdf  | while read arq
find ${DirLoc} -name *.pdf  | while read arq
do 
   cp $arq ${DirBkpExt}
   RC=$?
   F_ValidaRc $RC "${MsgErro}"
done

#  Verifica se o arquivo de output da conversao ja existe (remove)
[ -f ${ModBill}${Ciclo}${RunDate}.tar ] && rm ${ModBill}${Ciclo}${RunDate}.tar

#  Compressao dos Arquivos PDF p/ envio via e-mail
tar cvf ${DirBkpComp}/${ModBill}${Ciclo}${RunDate}.tar ${DirBkpExt} > ${LogCmds} 2>&1
RC=$?

MsgErro="Erro na Juncao dos arquivos PDFs!!!!`cat ${LogCmds}`"
F_ValidaRc $RC "${MsgErro}"

# Compressao dos arquivos PDF para envio via e-mail
gzip -9 -f ${DirBkpComp}/${ModBill}${Ciclo}${RunDate}.tar  >>${LogCmds} 2>&1
RC=$?

MsgErro="Erro na Compressao dos arquivos PDFs!!!!\n LOG GZIP: \n  `cat ${LogCmds}`"
F_ValidaRc $RC "${MsgErro}"


#  Formata arquivo TAR em formato ATTACH.
uuencode ${DirBkpComp}/${ModBill}${Ciclo}${RunDate}.tar.gz Faturas_PDF_${ModBill}${Ciclo}${RunDate}.gz > ${WrkFile}
RC=$?

MsgErro="Erro na formatacao do arquivo PDF em formato ATTCH p/ envio de -email"
F_ValidaRc $RC "${MsgErro}"

#-----------------------------
# Envia arquivos para PABSC
#  CHG6469 (Marcos de Benedicto - 05/06/2006)
#-----------------------------
su - transf -c "scp ${DirBkpComp}/${ModBill}${Ciclo}${RunDate}.tar.gz spoaxap9:/aplic/sql_rels_spoaxap9/faturas_bill_checkout/"
RC=${?}
MsgErro="Erro ao enviar Faturas para spoaxap9"
F_ValidaRc $RC "${MsgErro}"

echo "Faturas para o Bill Checkout do Ciclo ${Ciclo} estao disponiveis tambem na \\\\spoaxap9\\sqls\\faturas_bill_checkout " |mailx -s "Faturas para o Bill Checkout do Ciclo ${Ciclo} estao disponiveis tambem na spoaxap9" ${EMail} ${EMail2}

#  Envia os arquivos PDF comprimidos p/ e-mail
#mailx -s "Arquivos PDF do BILLING (${ModBill}) do Ciclo ${Ciclo} em ${RunDate}" ${EMail} < ${WrkFile}
mailx -s "Faturas para o Bill Checkout do Ciclo ${Ciclo} em ${RunDate}" ${EMail} < ${WrkFile}
[ -n "${EMail2}" ] && cat ${WrkFile} | mailx -s "Faturas para o Bill Checkout do Ciclo ${Ciclo} em ${RunDate}" ${EMail2}

MsgErro="Erro ao enviar Faturas para e-mail"
F_ValidaRc $RC "${MsgErro}"

#  Testa diretorio utilizado no processamento do CG/Testes.
[ "${DirLoc}" = "/" -o ! -d ${DirLoc} ] && RC=99

MsgErro="A Variavel DirLoc : (${DirLoc})  tem valor invalido para remocao!!! Verificar!!!"
F_ValidaRc $RC "${MsgErro}"

#  Remove diretorio utilizado no processamento do CG/Testes.
echo  " COMANDO de REMOVE: \n rm -r ${DirRaiz} "
RC=$?

MsgErro="Erro na Remocao do Diretorio processado no Billing (${ModBill}) do Ciclo: ${Ciclo} Run Date: ${RunDate}"
F_ValidaRc $RC "${MsgErro}"

#  Remove Arquivos PDF em formato extendido, copiados do diretorio BGH
rm ${DirBkpExt}/*.pdf
RC=$?

MsgErro="Erro na Remocao dos Arquivos PDF's ja tratados!!! A remoção devera ser feita manualmente!!!!\n  Arquivos: \n`ls -ltr ${DirBkpExt}/*.pdf`"
F_ValidaRc $RC "${MsgErro}"

# Limpa arquivo de Work
rm ${WrkFile} 

echo "
  *----------------------------------------------------------*
  |  Data/Hora do END .....: `date`
  *----------------------------------------------------------* "
