#! /bin/ksh

	# Finalidade	: Transferencia de Arquivos Nortel - SDM
	# Input		: CDRs engenharia
	# Data		: 31/07/2003
	# Alteracao	: Marcos de Benedicto
	# Data		: 03/10/2003

. /etc/appltab

# 
# ATENCAO: A variavel SITE e utilizada para identificar o amb BH.   
# ATENCAO: A variavel SITE e utilizada para identificar o amb BH.   

typeset -u -L2 DIR_SITE
typeset -l SDM
typeset -u MSG_SDM
typeset -u -L3 TH
typeset -l -L2 SITE

SITE="$1"
DIR_SITE="$SITE"
SDM="$2"
MSG_SDM="$2"
TH="$3"

DATA2=`date "+%m%Y"`
NUM_SDM=`echo ${TH} | cut -c3`
XLS_NAME=TIH-${SITE}${NUM_SDM}-${DATA2}.txt
TMP2=/tmp/rating_tih$$.txt


case "$SITE" in
     sp) MERC="SPO"
         ;;
     rj) MERC="RJO"
         ;;
     bh) SITE=rj 
         MERC="BHZ"
         ;;
      *) echo "Mercado nao reconhecido ($SITE)."
         exit 1
         ;;
esac

DIR_RATING="${ENV_DIR_BASE_RTX}/prod/backup_rating/CDR_FILTER"


DIR_XLS=${ENV_DIR_BASE_RTX}/sched/xls
ARQ_XLS=${DIR_XLS}/${XLS_NAME}

DT_CP=`date +%d%m%Y`
HR_CP=`date +%H:%M`

DEST_MED="${ENV_DIR_BASE_RTX}/prod/WORK/MP/RTX/MEDIADOR/${DIR_SITE}/${SDM}/${DT_CP}"
DEST_BKP="${ENV_DIR_BASE_RTX}/sched/bscs/transf/${MSG_SDM}_BKP"

#mkdir -p $DEST_MED
mkdir -p $DEST_BKP


#          Area de transferencia
DIR_TRANSF="${ENV_DIR_BASE_RTX}/sched/bscs/transf/TIH"
#          Area de backup
DIR_BACKUP="${ENV_DIR_BASE_RTX}/prod/backup_rating/TIH"
#          Area de trabalho
DIR_TMP="${ENV_DIR_BASE_RTX}/sched/bscs/transf/cdr/${SDM}"
#          Area de HotBilling
DIR_HOTBIL="${ENV_DIR_BASE_RTX}/prod/backup_rating/hotbilling"


if [ -z "$DIR_BACKUP" ]
   then
   echo "Nao foi possivel identificar a area para backup." | msg_api E-TIH-003
   exit 1
fi

[ ! -d "$DIR_BACKUP" ] && /amb/operator/bin/make_dir "$DIR_CPY"
RC=0

#===============TRATAMENTO DE U-FILE==================== 

cd ${DIR_TMP}

	[ `pwd` != ${DIR_TMP} ] && exit 1

for file in U????????????GCDR
do [ ! -f $file ] && continue

   #mkdir -p $DEST_MED
   #cp $file $DEST_MED
   cp $file $DEST_BKP
   #chmod -R 776 $DEST_MED/*
   #chown -R prod:bscs $DEST_MED
   chmod 777 $DEST_BKP/$file
   chown prod:bscs $DEST_BKP/$file
   gzip -9f $DEST_BKP/$file

   NAME=`echo $file | cut -c 2-13`
   NEW_NAME="${TH}${MERC}${NAME}"
   DIA=`echo $NEW_NAME | cut -c 11-12`
   MES=`echo $NEW_NAME | cut -c 9-10`
   ANO=`echo $NEW_NAME | cut -c 7-8`
   DATA=${DIA}${MES}${ANO}

   CONF_NAME="`echo $NEW_NAME | grep CD | wc -l`"
   CONF_NAME="`echo $CONF_NAME`"
   if [ "$CONF_NAME" -eq 0 ]
   then
   NEW_NAME="`echo $NEW_NAME | cut -c1-14,17-18`CD"
   fi

   #-------- INICIO --- Gera informacoes para carga no GRA -------#
   ARQ_GRA="${DIR_TMP}/sdm_logs/GRA${MERC}_${DATA}.txt"
   TAMANHO_GRA="`ls -l ${file} |awk '{print $5}'`"

   echo "${file}|${NEW_NAME}|${TAMANHO_GRA}" >>${ARQ_GRA}
   #-------- FINAL --- Gera informacoes para carga no GRA -------#

   mv $file ${DIR_TRANSF}/${NEW_NAME}

      if [ $? -eq 0 ]
      then
         ( echo "$NEW_NAME total file" ) | msg_api2 "I-RATING-NORTEL_${MSG_SDM}-COBERTURA"
      awk -v data=$DATA -v FILE=$NEW_NAME -v hora=$HR_CP -f /amb/eventbin/tih.awk $TMP2 >> $ARQ_XLS
      chmod 755 $ARQ_XLS
      
      else
         ( echo "$NEW_NAME total file" ) | msg_api "E-RATING-NORTEL_${MSG_SDM}-ERRO"
	 exit 1
      fi
done


for file in U????????????GHOT
do [ ! -f $file ] && continue

   #mkdir -p $DEST_MED
   #cp $file $DEST_MED
   cp $file $DEST_BKP
   #chmod -R 776 $DEST_MED/*
   #chown -R prod:bscs $DEST_MED
   chmod 777 $DEST_BKP/$file
   chown prod:bscs $DEST_BKP/$file
   gzip -9f $DEST_BKP/$file

   NAME=`echo $file | cut -c 2-13`
   NEW_NAME="${TH}${MERC}${NAME}"
   DIA=`echo $NEW_NAME | cut -c 11-12`
   MES=`echo $NEW_NAME | cut -c 9-10`
   ANO=`echo $NEW_NAME | cut -c 7-8`
   DATA=${DIA}${MES}${ANO}

   CONF_NAME="`echo $NEW_NAME | grep HB | wc -l`"
   CONF_NAME="`echo $CONF_NAME`"
   if [ "$CONF_NAME" -eq 0 ]
   then
   NEW_NAME="`echo $NEW_NAME | cut -c1-14,17-18`HB"
   fi

   #-------- INICIO --- Gera informacoes para carga no GRA -------#
   ARQ_GRA="${DIR_TMP}/sdm_logs/GRA${MERC}_${DATA}.txt"
   TAMANHO_GRA="`ls -l ${file} |awk '{print $5}'`"

   echo "${file}|${NEW_NAME}|${TAMANHO_GRA}" >>${ARQ_GRA}
   #-------- FINAL --- Gera informacoes para carga no GRA -------#

   mv $file ${DIR_TRANSF}/${NEW_NAME}

      if [ $? -eq 0 ] 
      then
         	( echo "$NEW_NAME total file") | msg_api2 "I-RATING-NORTEL_${MSG_SDM}-COBERTURA"
      else
         	( echo "$NEW_NAME total file" ) | msg_api "E-RATING-NORTEL_${MSG_SDM}-ERRO"
		exit 1
      fi


done

#================TRATAMENTO DE THs=====================

cd ${DIR_TRANSF}

	[ `pwd` != ${DIR_TRANSF} ] && exit 1

for file in ${TH}${MERC}??????????CD
do [ ! -f $file ] && continue
   # Verifica se eh arquivo de hotbilling e move para area correta
   for FILE in ${TH}${MERC}??????010[0-2]CD
   do
      [ $FILE = "${TH}${MERC}??????010[0-2]CD" ] && continue
      BLOCO=`ls -s $FILE | awk '{print $1}'`
      TAMANHO=`expr $BLOCO \* 512`
      if [ $TAMANHO -lt 50000 ] ; then
	 FILE="`echo $FILE | cut -c1-16`HB"
	 mv $file $FILE
         cp $FILE $DIR_HOTBIL 2>$TMP
         if [ $? != 0 ]; then
            ( echo "$FILE Erro copia para $DIR_HOTBIL"
              cat $TMP ) |msg_api E-TIH-004
            RC=44
            rm -f $TMP
	    file="$FILE"
            continue
         fi
         echo "$FILE Sucesso envio para area de hotbilling" | msg_api I-TIH-004
         rm -f $TMP
      fi
   done

   if [ $RC != 0 ]
   then
      echo " Erro "
      exit 44
   fi

   #copia para area do rating
   
   cp $file $DIR_RATING 2>$TMP
   if [ $? != 0 ]; then
      ( echo "$file Erro copia para $DIR_RATING"; cat $TMP ) | msg_api E-TIH-001
      rm -f $TMP
      exit 1
   fi
   echo "$file Sucesso copia para a area de Rating" | msg_api I-TIH-001
   chown sched:sched $DIR_RATING/$file
   chmod 644 $DIR_RATING/$file

   # move arquivo para area de backup
   mv $file $DIR_BACKUP 2>$TMP
   if [ $? != 0 ]; then
      ( echo "$file Erro ao mover $DIR_BACKUP" ; cat $TMP ) | msg_api E-TIH-002
      rm -f $TMP
      exit 1
   fi
   chown prod:bscs $DIR_BACKUP/$file
   chmod 644 $DIR_BACKUP/$file
   echo "$file Sucesso ao mover arquivo para area de BACKUP" | msg_api I-TIH-002
   gzip -f -9 $DIR_BACKUP/$file
   rm -f $TMP
done

for file in ${TH}${MERC}??????????HB
do [ ! -f $file ] && continue
         cp $file $DIR_HOTBIL 2>$TMP
         if [ $? != 0 ]; then
            ( echo "$file Erro copia para $DIR_HOTBIL"
              cat $TMP ) |msg_api E-TIH-004
            RC=44
            rm -f $TMP
            continue
         fi
         echo "$file Sucesso envio para area de hotbilling" | msg_api I-TIH-004
         rm -f $TMP

   if [ $RC != 0 ]
   then
      echo " Erro "
      exit 44
   fi

   #copia para area do rating
   
   cp $file $DIR_RATING 2>$TMP
   if [ $? != 0 ]; then
      ( echo "$file Erro copia para $DIR_RATING"; cat $TMP ) | msg_api E-TIH-001
      rm -f $TMP
      exit 1
   fi
   echo "$file Sucesso copia para a area de Rating" | msg_api I-TIH-001
   chown sched:sched $DIR_RATING/$file
   chmod 644 $DIR_RATING/$file

   # move arquivo para area de backup
   mv $file $DIR_BACKUP 2>$TMP
   if [ $? != 0 ]; then
      ( echo "$file Erro ao mover $DIR_BACKUP" ; cat $TMP ) | msg_api E-TIH-002
      rm -f $TMP
      exit 1
   fi
   chown prod:bscs $DIR_BACKUP/$file
   chmod 644 $DIR_BACKUP/$file
   echo "$file Sucesso ao mover arquivo para area de BACKUP" | msg_api I-TIH-002
   gzip -f -9 $DIR_BACKUP/$file
   rm -f $TMP
done

   if [ $? -ne 0 ]
   then
      echo " Erro "
      exit 44
   fi

#echo "Subject:Arquivo de HotBilling do Tortosa" > arq.mail.$$

