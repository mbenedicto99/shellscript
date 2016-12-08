#! /usr/bin/ksh
#
# Script : /amb/eventbin/bdf_coleta.sh
# Feito  : Hertz S.
# OBS    : Script para coletar statistica de Crescimento
#          de File System
#

 HOSTN="`hostname`"
   MES="`date +%m%Y`"
  DATA="`date +%d/%m/%Y`"
  HORA="`date +%H:%M:%S`"
   ANO="`date +%Y`"
KB_TOT_I="Total de KB do File System"
  USED_I="KB Usados"
 AVAIL_I="KB Disponivel"
    FS_I="File System"
  DATA_I="Data"
  HORA_I="Hora"
 DIR="/var/adm/FS/${ANO}/${MES}"

mkdir -p ${DIR}

bdf | grep -v Mounted | grep \% | while read x
do
conf="`echo $x | awk '{print $5}' | grep \% | wc -l`"
conf="`echo $conf`"

if [ "$conf" -eq 1 ]
then
KB_TOT="`echo $x | awk '{print $2}'"
  USED="`echo $x | awk '{print $3}'"
 AVAIL="`echo $x | awk '{print $4}'"
    FS="`echo $x | awk '{print $6}'"
else
KB_TOT="`echo $x | awk '{print $1}'"
  USED="`echo $x | awk '{print $2}'"
 AVAIL="`echo $x | awk '{print $3}'"
    FS="`echo $x | awk '{print $5}'"
fi

FLS="`echo $FS | sed 's:/:_:g'`"
FILE="${HOSTN}_${MES}$FLS.txt"

if [ -f "${DIR}/$FILE" ]
then
echo "$FS;$DATA;$HORA;$KB_TOT;$USED;$AVAIL"             >> ${DIR}/$FILE
else
echo "$FS_I;$DATA_I;$HORA_I;$KB_TOT_I;$USED_I;$AVAIL_I" >> ${DIR}/$FILE
echo "$FS;$DATA;$HORA;$KB_TOT;$USED;$AVAIL"             >> ${DIR}/$FILE
fi

done
