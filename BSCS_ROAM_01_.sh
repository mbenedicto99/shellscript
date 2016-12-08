#!/bin/ksh
# BSCS_ROAM_01_02.sh
# ------------------
# Tipo: Unix Shell Script para o Roaming Internacional.
# Objetivo: Consistir arquivos formato NATAP2.
#
# Criado por Renato em 26/10/2001.
# Reformulado por Sinclair Iyama em 20/09/2002.
#
# Local: Nextel Brasil - CENESP 6.o Andar.
# Area: Roaming Internacional (TADIG).
#
# Alteracao:
#            26/FEV/2003 - Inclusao de script para relatorio chamadas originadas em Roaming Intl (MOC).
#
# Formato: BSCS_ROAM_01_02.sh (gerenciado diretamente pelo Control-M) 
#
## Mensagens
#M#I-BSCS_ROAM-100 : Arquivo OK
#M#W-BSCS_ROAM-100 : Arquivo Notification file
#M#E-BSCS_ROAM-200 : Arquivo com registros duplicados
#M#I-BSCS_ROAM-200 : Arquivo sem registros duplicados
#M#I-BSCS_ROAM-300 : Arquivo com usage type invalido
#M#E-BSCS_ROAM-100 : Erro de infra-estrutura

. /etc/appltab

# ---------------------
# Variaveis de ambiente:
# ---------------------
# ALterado em 2003/08/26 - Edison Santos (Workmation) - Consolidacao MIBAS - BSCS
#===================================================================================#
### typeset -L2 SITE
### SITE=$1

typeset -l -L2 SITE
SITE="${ENV_VAR_SITE}"
DATA=`date +%d-%m-%Y`
E_DATA=`date +%Y-%m-%d`
# Maq. destino p/ arquivos (RCP) qdo SITE=rj
DESTINO=$2
TS=`date +"%Y%m%d%H%M%S"`

# ------------------------------------------------
# Destinatarios de correio (definidos na spoaxap7):
# ------------------------------------------------
DEST="billing_process@nextel.com.br,roaming@unix_mail_fwd"
DEST2="billing_process@nextel.com.br,roaming3@unix_mail_fwd"
DEST3="billing_process@nextel.com.br,roaming4@unix_mail_fwd"

# --------------------
# Relatorios de TAPOUT:
# --------------------
LOG=/tmp/TapOut_${DATA}.csv
REL=/tmp/TapOut_RPT_${DATA}.csv
REL_MOC=/tmp/rel_moc_${DATA}.csv
TMP=/tmp/bscs_roam_$$.txt

# ------------------------
# Variaveis de Totalizacao:
# ------------------------
tot_arq_proc=0
tot_arq_not=0
tot_arq_dup=0
tot_rec_dup=0
tot_arq_u01=0
tot_arq_u02=0
tot_arq_u03=0
tot_arq_svc01=0
tot_bad=0

# -----------------
# Codigo de retorno:
# -----------------
RC=0

# ----------------------
# Diretorios de trabalho:
# ----------------------
# ALterado em 2003/08/26 - Edison Santos (Workmation) - Consolidacao MIBAS - BSCS
#===================================================================================#
### DIRVERIFICA=/artx_${SITE}/prod/WORK/MP/TRAC/OUT/ARQUIVOS/VERIFICA
### DIRPENDENTES=/artx_${SITE}/prod/WORK/MP/TRAC/OUT/ARQUIVOS/PENDENTES
### DIRBADFILES=/artx_${SITE}/prod/WORK/MP/TRAC/OUT/ARQUIVOS/BADFILES
### DIRENVIADOS=/artx_${SITE}/prod/WORK/MP/TRAC/OUT/ARQUIVOS/ENVIADOS

DIRVERIFICA=${ENV_DIR_BASE_RTX}/prod/WORK/MP/TRAC/OUT/ARQUIVOS/VERIFICA
DIRPENDENTES=${ENV_DIR_BASE_RTX}/prod/WORK/MP/TRAC/OUT/ARQUIVOS/PENDENTES
DIRBADFILES=${ENV_DIR_BASE_RTX}/prod/WORK/MP/TRAC/OUT/ARQUIVOS/BADFILES
DIRENVIADOS=${ENV_DIR_BASE_RTX}/prod/WORK/MP/TRAC/OUT/ARQUIVOS/ENVIADOS

OPERADORAS=/amb/scripts/doh/operadoras_${SITE}.cfg

# ---------------------------------------------
# Cabecalho do Relatorio de Minutagem do TAPOUT:
# ---------------------------------------------
echo "ARQUIVO;DATA_DA_GERAGCO;DATA_DA_1_LIGAGCO;QUANTIDADE_DE_REGISTROS;TOTAL_DE_MOC_EM_SEGUNDOS;TOTAL_DE_MTC_EM_SEGUNDOS;TOTAL_DE_SEGUNDOS_GERAL;VALOR" > $REL

# ----------------------------------------------------------------
# Cabecalho do Relatorio de Chamadas MOC em Roaming Intl do TAPOUT:
# ----------------------------------------------------------------
echo "Arquivo;Total Chamadas LOCAL;Total Minutos Air;Total Minutos Toll;Total Faturado Air (USD);Total Faturado Toll (USD);Total Chamadas INTL;Total Minutos Air;Total Minutos Toll;Total Faturado Air (USD);Total Faturado Toll (USD)" > $REL_MOC

# ------------------------------------------------
# Verificacao do diretorio de trabalho (VERIFICA):
# ------------------------------------------------
cd $DIRVERIFICA 2>$TMP
if [ $? != 0 ]; then
   echo " Erro no cd $DIRVERIFICA"; cat $TMP 
   rm -f $TMP
   exit 1
fi

# --------------------------------------------------------------
# limpa arquivos com mais de 6 meses segundo solicitacao do Alan:
# --------------------------------------------------------------
find $DIRBADFILES -type f -mtime +180 -exec rm -f {} \;
find $DIRENVIADOS -type f -mtime +180 -exec rm -f {} \;

# -----------------------
# Inicio do Processamento:
# -----------------------
for file in CDBRANC?????????? TDBRANC??????????
do [ ! -f $file ] && continue
   echo "$file - Inicio do processamento " >> $LOG
   TIPO=`echo $file | cut -c 1-2`
   tot_arq_proc=`expr $tot_arq_proc + 1`
   operadora=`echo $file | cut -c 8-12`
   sequencia=`echo $file | cut -c 13-17`
   lista=${operadora}${sequencia}.lst
   arqdup=${operadora}${sequencia}.dup

   # Verifica se arquivo eh Notification File pelo tamanho igual a 182 bytes:
   tamanho=`ls -l $file | awk '{print $5}'`
   if [ $tamanho = "182" ] ; then
      # Primeira vez, somente para os Notification Files:
      echo "$file - Notification File "  >> $LOG
      tot_arq_not=`expr $tot_arq_not + 1`

      # Relatorio Minutagem do TAPOUT - Notification file (1.a vez):
      /amb/operator/bin/gera_rel_tapout.sh $file $REL

      # Relatorio de Chamadas MOC em Roaming Intl do TAPOUT - Notification file (1.a vez):
      /amb/operator/bin/gera_rel_moc.sh $file $REL_MOC

      [ $TIPO = "TD" ] && mv $file $DIRPENDENTES/temp || mv $file $DIRPENDENTES
      echo "$file - Arquivo Notification File"
      continue
   fi

   # Verifica e corrige usage type 01:
   /amb/operator/bin/check_utype_01.sh $file $LOG
   if [ $? = 1 ] ; then
      tot_arq_u01=`expr $tot_arq_u01 + 1`
      echo "$file - Arquivo com Usage Type 1 Invalido (MOC)" 
   fi

   # Verifica e corrige usage type 02:
   /amb/operator/bin/check_utype_02.sh $file $LOG
   if [ $? = 1 ] ; then
      tot_arq_u02=`expr $tot_arq_u02 + 1`
      echo "$file - Arquivo com Usage Type 2 Invalido (MOC)" 
   fi

   # Verifica e corrige usage type 03:
   /amb/operator/bin/check_utype_03.sh $file $LOG
   if [ $? = 1 ] ; then
      tot_arq_u03=`expr $tot_arq_u03 + 1`
      echo "$file - Arquivo com Usage Type 3 Invalido (MOC)" 
   fi

   # Verifica e corrige service type & service code, de 1 a 5, em linhas MSS:
   /amb/operator/bin/check_svc_type.sh $file $LOG
   if [ $? = 1 ] ; then
      tot_arq_svc01=`expr $tot_arq_svc01 + 1`
      echo "$file - Arquivo com Service Type 1 Invalido (MSS)"
   fi

   # Verifica e remove registros duplicados no TAP file:
   /amb/operator/bin/check_dup_rec.sh $file $LOG $arqdup $lista
   ### /amb/operator/bin/consolidacao/check_dup_rec.sh $file $LOG $arqdup $lista
   RC=$?
   if [ ${RC} -gt 0 ] ; then # Tem registros duplicados
      tot_rec_dup=`expr $tot_rec_dup + ${RC}`
      tot_arq_dup=`expr $tot_arq_dup + 1`
   fi

   # Acerta no trailer valor total das charges do TAP file:
   /amb/operator/bin/acerta_tot_charge.sh $file $LOG

   # Verifica no trailer total de registros do TAP file:
   /amb/operator/bin/checa_total_reg.sh $file $LOG

   echo "    ************     " >> $LOG
   echo " " >> $LOG

   # Relatorio Minutagem do TAPOUT - Arquivos Corrigidos (2.a vez):
   /amb/operator/bin/gera_rel_tapout.sh $file $REL

   # Relatorio de Chamadas MOC em Roaming Intl do TAPOUT - Arquivos Corrigidos (2.a vez):
   /amb/operator/bin/gera_rel_moc.sh $file $REL_MOC

   chown prod:bscs $file

   # Arquivo de Teste (TD) enviado ao diretorio $DIRPENDENTES/temp:
   [ $TIPO = "TD" ] && mv $file $DIRPENDENTES/temp || mv $file $DIRPENDENTES

   echo "$file - Arquivo Processado" 
done

# ------------------------------------------------------
# Impressao dos totais e envio dos relatorios por e-mail:
# ------------------------------------------------------
set +x
echo " " >> $LOG
echo "Total de arquivos processados: $tot_arq_proc" >> $LOG
echo "Total de arquivos Notification Files: $tot_arq_not" >>  $LOG
echo "Total de arquivos com Usage type01 corrigido: $tot_arq_u01" >>  $LOG
echo "Total de arquivos com Usage type02 corrigido: $tot_arq_u02" >>  $LOG
echo "Total de arquivos com Usage type03 corrigido: $tot_arq_u03" >>  $LOG
echo "Total de arquivos com Service Type 1 corrigido: $tot_arq_svc01" >>  $LOG
echo "Total de arquivos com registros duplicados: $tot_arq_dup" >>  $LOG
echo "Total de registros duplicados removidos: $tot_rec_dup" >>  $LOG
set -x

# Envio do relatorio do TAPOUT para a Sysout do Control-M:
echo "\nTAPOUT Report $SITE - $DATA"
cat $LOG

# Envio do relatorio de Minutagem para a Sysout do Control-M:
echo "\nMinutagem de Romeiros $SITE - $DATA"
cat $REL

# Envio do relatorio de Chamadas MOC em Roaming Intl para a Sysout do Control-M:
echo "\nChamadas MOC em Roaming Internacional $SITE - $DATA"
cat $REL_MOC

# Envio de e-mail de notificacao de sucesso na execucao do TAPOUT:
/amb/operator/bin/attach_mail "${DEST}" $LOG "TAPOUT Report $SITE - ${E_DATA}"

# Envio de e-mail do relatorio de Minutagem de Romeiros:
/amb/operator/bin/attach_mail "${DEST2}" $REL "Minutagem de Romeiros $SITE - ${E_DATA}"

# Envio de e-mail do Relatorio de Chamadas MOC em Roaming Intl do TAPOUT:
/amb/operator/bin/attach_mail "${DEST3}" $REL_MOC "Chamadas MOC em Roaming Internacional $SITE - ${E_DATA}"

# Copia dos relatorios para geracao de controles do Revenue Assurance:

	case ${SITE} in

		sp) cp $LOG ${ENV_DIR_BASE_BSC}/sched/mach/.
		    cp $REL_MOC ${ENV_DIR_BASE_BSC}/sched/mach/.
		    cp $REL ${ENV_DIR_BASE_BSC}/sched/mach/rel_tapout_${TS}.txt;;

                ##### Verificar alteracao para D0 da Consolidacao!!!!! ##### 
		rj) su - transf -c "rcp ${LOG} ${DESTINO}:/abscs_sp/sched/mach"
		    su - transf -c "rcp ${REL_MOC} ${DESTINO}:/abscs_sp/sched/mach"
		    su - transf -c "rcp ${REL} ${DESTINO}:/abscs_sp/sched/mach/rel_tapout_${TS}.txt";;

		    esac

# Limpeza de arquivos temporarios:
cp $REL ${ENV_DIR_BASE_BSC}/sched/mach
cp $LOG ${ENV_DIR_BASE_BSC}/sched/mach

find ${ENV_DIR_BASE_BSC}/sched/mach -name TapOut_RPT* -type f -mtime +7 -exec rm -f {} \;

rm -f $LOG *.lst *.dup $TMP $REL $REL_MOC

exit 0
