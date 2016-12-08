#!/bin/ksh
#  Programa: BSCS_ROAM_01_01.sh
#  Envia os arquivos de roaming internacional para o servidor do PGP
#  Data: 17/05/2000
#  Renato
#
# Alteracao 06/03/02
#
#
## Mensagens
#M#I-BSCS_ROAM-001 : Sucesso no envio dos arquivos
#M#E-BSCS_ROAM-001 : Erro no envio dos arquivos
#M#E-BSCS_ROAM-002 : Erro de infra-estrutura
#
# Definicao de Variaveis

. /etc/appltab

TMP=/tmp/bscs_roam_$$.txt
TMP2=/tmp/bscs_roam2_$$.txt
typeset -l -L2 SITE

#SITE=$1
SITE="${ENV_VAR_SITE}"

#DIRPENDENTES=/artx_${SITE}/prod/WORK/MP/TRAC/OUT/ARQUIVOS/PENDENTES
#DIRPENTMP=/artx_${SITE}/prod/WORK/MP/TRAC/OUT/ARQUIVOS/PENDENTES/temp
#DIRENVIADOS=/artx_${SITE}/prod/WORK/MP/TRAC/OUT/ARQUIVOS/ENVIADOS

DIRPENDENTES=${ENV_DIR_BASE_RTX}/prod/WORK/MP/TRAC/OUT/ARQUIVOS/PENDENTES
DIRPENTMP=${ENV_DIR_BASE_RTX}/prod/WORK/MP/TRAC/OUT/ARQUIVOS/PENDENTES/temp
DIRENVIADOS=${ENV_DIR_BASE_RTX}/prod/WORK/MP/TRAC/OUT/ARQUIVOS/ENVIADOS

OPERADORAS=/amb/scripts/doh/operadoras_${SITE}.cfg
DESTINO=$2
##DESTINO=spoaxap9

cd $DIRPENDENTES 2>$TMP
if [ $? != 0 ]; then
   ( echo " Erro no cd $DIRPENDENTES"; cat $TMP )| msg_api "E-BSCS_ROAM-002"
   rm -f $TMP
   exit 1
fi
for file in ?DBRANC??????????
  do [ ! -f $file ] && continue
  COUNTRY=`echo $file | cut -c 8-12`
  SUFIXO=`echo $file | cut -c 3-20`
  PREFIXO=`echo $file | cut -c 1-2`
  grep -q $COUNTRY $OPERADORAS
  RET=$?
  if [ $RET != 0 -a $PREFIXO != "TD" ]; then
     mv $file "TD"${SUFIXO}
     mv "TD"${SUFIXO} $DIRPENTMP
     chmod 664 $DIRPENTMP/*
     else mv $file ${SITE}"_"${file}
  fi
done

for file in ${SITE}_?DBRANC?????????? 
  do [ ! -f $file ] && continue
  chmod 664 ${file}
  #/amb/eventbin/TRANS_RQT.sh $DESTINO $file 2>$TMP
 
  if [ ${DESTINO} = "spoaxap2" ]
  then
  su - transf -c  "rcp ${DIRPENDENTES}/$file $DESTINO:/transf/rcv"
  else
  cp ${DIRPENDENTES}/$file /transf/rcv
  fi

  if [ $? != 0 ]; then
     rm -f $TMP
     exit 1
  fi
  ARQ_NEW=`echo $file | cut -c 4-20`
  mv $file $DIRENVIADOS/${ARQ_NEW} 2>$TMP
  if [ $? != 0 ]; then
      echo "$file - Erro no mv"; cat $TMP 
     rm -f $TMP
     exit 1
  fi
  chmod 644 $DIRENVIADOS/${ARQ_NEW}
  gzip -f -9 ${DIRENVIADOS}/${ARQ_NEW}
  rm -f $TMP
done 

 rm -f $TMP $TMP2

exit 0

