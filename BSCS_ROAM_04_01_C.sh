#!/bin/ksh 
#   Programa: BSCS_ROAM_04_01_C.sh - Limpa arquivos recebidos via FTP do Connect Enterprise - SPOAXIS1
#
#   Data            : 04/FEV/2003
#   Autor           : Sinclair Iyama - Roaming Internacional (TADIG)
#   Implementado por: Alex da Rocha Lima - Implantacao / Control-M


# ----------------------
# Definicao de Variaveis:
# ----------------------

#
# Connect:Enterprise UNIX environment variables.
#
. /aplic/centerprise/etc/profile

MAQ=`uname -n`

# DIR_LOG: o diretorio de logs:
DIR_LOG="/home/ceuser/LOG_CE"

# ARQ_LOG: o arquivo de log:
ARQ_LOG=${DIR_LOG}/log.BSCS_ROAM_04_01_C.`date +%Y%m%d.%H%M%S`

# CEUSER: o usuario do CE a ser utilizado:
CEUSER="ceuser"
CEGROUP="ce"

# MBX_ID: a mailbox utilizada pelo CE na recepcao de arquivos TAPIN:
MBX_ID="tsi"

# STATUS: a caracteristica dos arquivos a serem apagados da mailbox:
STATUS="CDRMF"

# -----------------------
# Inicio do processamento:
# -----------------------

echo "Lista de Arquivos com Flag : ${STATUS}\n"
cmulist -u${CEUSER} -p${CEUSER} -i${MBX_ID} -F${STATUS} | tee -a ${ARQ_LOG} 
echo "\n"

cmuerase -u${CEUSER} -p${CEUSER} -i${MBX_ID} -F${STATUS} >> ${ARQ_LOG}

# Compactacao do log:
gzip -9vf ${ARQ_LOG}

# Mudanca da propriedade do arquivo para ${CEUSER}:
chown ${CEUSER}:${CEGROUP} ${ARQ_LOG}.gz

exit 0
