#!/bin/ksh -x
##
# BSCS_ROAM_04_01.sh
#
# Transferencia de arquivos de Roaming Internacional
#
# Alteracao em 03/FEV/2002 - Sinclair Iyama - International Roaming (TADIG).
# Entrada da nova DCH (Data ClearingHouse) - TSI:
#   - Nova BOXNAME (servidor arqs PGP): spoaxis1 (mesmo servidor do envio do TAPout);
#   - Novo SOURCEDIR (diretorio de busca): /tsi.
#

# Definicao de variaveis:

 . /etc/appltab

TMP=/tmp/roaming_$$

typeset -u -L2 SITE
SITE=SP

# Definicao de parametros
case "$SITE" in

    sp|SP) PREFIX="SP"
         BOXNAME=spoaxis1
         LOCALDIR="/apgp_sp/sched/bscs_roaming/IN/files/SP"
         SOURCEDIR="/tsi"
         LOGDIR="/apgp_sp/sched/bscs_roaming/IN/logs/SP"
         TOTDIR="/apgp_sp/sched/bscs_roaming/IN/tmp/SP"
         ;;
      *) echo "$0: Site $SITE desconhecido" | msg_api "E-BSCS_ROAM-040"
         exit 1
         ;;
esac

# Executa a transferencia dos arquivos
# Apos a execucao do exec, nao adianta tratar o return code,
# pois este ao ser executado vai sobrescrever este script com o bscs_getdcms.

LOG_DATE=`date +%d%m%Y`
LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
LOG_TIME="${ENV_DIR_BASE_RTX}/prod/reports/TAPIN_${LOG_DATE}.txt"

printf "%s\t%s\t%s\t%s\n" "TAPIN_04_01" "Inicio do processamento." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

#exec /amb/operator/bin/bscs_get_tap_in $PREFIX $BOXNAME $LOCALDIR $SOURCEDIR $LOGDIR $TOTDIR
. /amb/operator/bin/bscs_get_tap_in $PREFIX $BOXNAME $LOCALDIR $SOURCEDIR $LOGDIR $TOTDIR
echo $?

LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"

printf "%s\t%s\t%s\n" "TAPIN_04_01" "Termino do processamento." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

[ -f ${TMP} ] && rm -f ${TMP}

exit 0
