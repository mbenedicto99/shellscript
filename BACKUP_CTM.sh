#!/bin/ksh -x
   # Finalidade    : Executa backup do Control-M, limpa backups com mais de 7 dias.
   # Input         : ODATE
   # Output        : sysout
   # Autor         : Rafael dos Santos Toniete 
   # Data          : 25/02/2004

#========================================#
#  Definicao das variaveis de ambiente   #
#========================================#
Date="${1}"
DirWork="/aplic/control-M/acontrolm_sp/ctm/ctm/backup_ctm"
FileWork="Backup_CTM"
DirLog="${DirWork}/log"
ArqLog="${DirLog}/${FileWork}_$$.log"

exec 2> ${ArqLog}
set -x

F_End()
{
typeset -3Z RC="${1}"

echo " #--------------------------------------------------------------------#"
echo " #                      TERMINO DO PROGRAMA                           #"
echo " #--------------------------------------------------------------------#"
echo "  FIM DO PROGRAMA: `date '+%d%m%Y - %H%M%S'`                    RETORNO: ${RC}  #"
echo " #--------------------------------------------------------------------#"
exit ${RC}
}

#========================================#
#       Funcao para verificar ERRO       #
#========================================#
F_CheckError()
{
	#====================================================================#
	#  Para esta funcao utilize:                                         #
	#                                                                    #
	#     F_CheckError <Return Code> <Mensagem ERRO> <Mensagem de ACAO>  #
	#                                                                    #
	#====================================================================#
RC="${1}"
MSG="${2}"
ACAO="${3}"
if [ "${RC}" -ne "0" ]
   then
      banner ERRO!
      printf "\nERRO na execucao do backup do Control-M!\n\nMensagem de ERRO:\t${MSG}\n"
      printf "\nAcao a ser tomada:\t${ACAO}\n\n"
      printf "\n\n+----------------------------------------------+"
      printf "\t INICIO DA LOG DE EXECUCAO"
      printf "+----------------------------------------------+\n\n"
      cat ${ArqLog}
      printf "\n\n+----------------------------------------------+"
      printf "\t FIM DA LOG DE EXECUCAO"
      printf "+----------------------------------------------+\n\n"
      End ${RC}
fi
}

#========================================#
#  Funcao de limpeza de backups antigos  #
#========================================#
F_CleanBackup()
{
	find ${DirWork} -name ${FileWork}\* -mtime +7 -exec rm {} \;
	F_End $?
}

#========================================#
#     Funcao para compactar backup       #
#========================================#
F_Compacta()
{
	compress ${DirWork}/${FileWork}
	F_CheckError ${?} "ERRO ao compactar arquivo de Backup do Control-M" "Reexecutar processo, caso ocorra novamente, mandar email para analise de producao informando erro"
        mv ${DirWork}/${FileWork}.Z ${DirWork}/${FileWork}_${Date}.Z
        F_CheckError ${?} "ERRO ao renomear o arquivo de export da Base do Control-M" "Nenhuma"
	F_CleanBackup
}

#========================================#
#      Funcao de execucao do backup      #
#========================================#
F_Backup()
{
	ctmdbbck ${DirWork}/${FileWork}
	F_CheckError ${?} "ERRO na execucao do utilitario de Backup do Control-M" "Reexecutar processo, caso ocorra novamente, mandar email para analise de producao informando erro"
	F_Compacta
}

cd ${DirWork}
F_CheckError ${?} "ERRO no cd para o diretorio de backup" "Verificar se o diretorio existe, caso sim, reexecutar"

echo " #--------------------------------------------------------------------#"
echo " #                       INICIO DO PROGRAMA                           #"
echo " #--------------------------------------------------------------------#"
echo "  INICIO DO PROGRAMA: `date '+%d%m%Y - %H%M%S'`                               #"
echo " #--------------------------------------------------------------------#"

F_Backup
