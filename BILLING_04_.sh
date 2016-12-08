#!/bin/ksh
#  Script      : BILLING_04_02.sh
#  Objetivo    : IMPORTACAO DO ARQUIVO GEL NO MAGNUS
#  Data        : 02/01/2001
#  Autor       : Renato
#  Alteracao   : 13/03/02
#
## Mensagens
#M#I-MAGNUS_BIL-050 : Sucesso na importacao do arquivo GEL
#M#E-MAGNUS_BIL-050 : Erro    na importacao do arquivo GEL
#M#E-MAGNUS_BIL-051 : Erro de infra-estrutura

# Variaveis de ambiente do Progress
export DLC=/opgs_sp/app/dlc
export PATH=$PATH:$DLC/bin
export PROPATH=/apgs_sp/magnus
export PROTERMCAP=$DLC/protermcap
export PROMSGS=$DLC/promsgs
export TERM=vt100
PATH=$PATH:/amb/bin

# Variaveis de trabalho
DIRMAG=/apgs_sp/magnus
DIRWRK=${DIRMAG}/bill/IMPORTA
DIRPPP=${DIRMAG}/bill/PROCESSANDO
DIRPPO=${DIRMAG}/bill/PROCESSADOS
DIRTMP=${DIRMAG}/bill/TMP
DIRERR=${DIRMAG}/bill/ERROR
DIRPRO=${DIRMAG}/bill/PRO
DIRREL=${DIRMAG}/bill/REL
MSG_I=I-ESBL010-001
MSG_E=E-ESBL010-001
PARAM=$DIRTMP/param.txt
TMP=$DIRTMP/MAGNUS_BIL_02_$$.txt
#DEST1=magnus_bill_1@unix_mail_fwd
DEST1=magnus_bill_er@unix_mail_fwd
DEST3="bill_process_magnus@unix_mail_fwd"
#DEST3="bill_checkout@unix_mail_fwd"
FLAG=0

mv ${DIRPPP}/GELC* $DIRWRK

cd $DIRWRK

for FILE in GEL???????????????????????.?????.????????????
do [ ! -f $FILE ] && continue
   SEQ=`echo $FILE | cut -d "." -f2`
   ARQ="`echo $FILE | cut -c 1-8`.${SEQ}"
   ARQ_MSG_E="${DIRWRK}/${FILE}.${MSG_E}"
   ARQ_MSG_I="${DIRWRK}/${FILE}.${MSG_I}"
   ARQ_PRO="${DIRWRK}/${FILE}.pro"
   # Gera arquivos de parametros para ser passado para o programa
   ( echo "DiretorioErros=\"${DIRWRK}\""
     echo "NomeArquivo=\"${FILE}\""
     echo "DiretorioMapi=\"${DIRWRK}\""
     echo "DiretorioProcess=\"${DIRWRK}\""
     echo "DiretorioLeitura=\"${DIRWRK}\"" ) > $PARAM
   #inicio da procedure

   $DLC/bin/_progres -pf ${DIRMAG}/mgadm.pf -U billing -P billing \
                     -pf ${DIRMAG}/mgind.pf -U billing -P billing \
                     -pf ${DIRMAG}/mgcom.pf -U billing -P billing \
                     -pf ${DIRMAG}/mglnk.pf -U billing -P billing \
                     -o "lp -s > /dev/null" -p ${DIRMAG}/esp/esbl010r.p \
                     -param $PARAM \
                     -b > $TMP

   RC=$?

   cat $TMP

   if [ $RC != 0 ] ; then 
      # se falta licensa no magnus envia msg 
      grep "Try a larger -n" $TMP
      if [ $? = 0 ] ; then
         ( echo $FILE "- Falta de licensa no magnus "
           cat $TMP $PARAM ) | msg_api "E-MAGNUS_BIL-050"
         mv $FILE $DIRERR
         gzip -9 -f ${DIRERR}/${FILE}
         rm -f $TMP $PARAM $ARQ_MSG_E $ARQ_MSG_I $ARQ_PRO
         MSG1="Billing Erro - Verificao da Notas Fiscais - $ARQ"
         SUBJ="Falta de licenca no Magnus - $ARQ" 
         /amb/operator/bin/attach_mail $DEST1 $TMP $SUBJ
         echo $MSG1 | mailx magnus_bill_page@unix_mail_fwd
         exit 1
      fi
      # demais tipo de erro na geracao do arquivo
      ( echo "$FILE - Erro na importacao do GEL"
        cat $TMP $PARAM $ARQ_MSG_E $ARQ_PRO ) | msg_api "E-MAGNUS_BIL-050"
      mv $FILE $DIRERR
      gzip -9 -f ${DIRERR}/${FILE}
      rm -f $TMP $PARAM $ARQ_MSG_E $ARQ_MSG_I $ARQ_PRO
      MSG1="Billing Erro - Importacao do GEL - $ARQ" 
      SUBJ="Erro na importacao do GEL - $ARQ"
      /amb/operator/bin/attach_mail $DEST1 $TMP $SUBJ
      echo $MSG1 | mailx magnus_bill_page@unix_mail_fwd
      exit 1
   fi

   if [ ! -s $ARQ_PRO ] ; then
     echo "$FILE - arquivo $ARQ_PRO nao encontrado" | msg_api "E-MAGNUS_BIL-050"
     MSG1="Billing Erro - Arquivo .PRO nao encontrado - $ARQ"
     SUBJ="Erro na importacao do GEL - $ARQ"
     mv $FILE $DIRERR
     gzip -9 -f ${DIRERR}/${FILE}
     /amb/operator/bin/attach_mail $DEST1 $TMP $SUBJ
     echo $MSG1 | mailx magnus_bill_page@unix_mail_fwd
     rm -f $TMP $PARAM $ARQ_MSG_E $ARQ_MSG_I $ARQ_PRO
     exit 1
   fi

   LOG=`head -1 $ARQ_PRO`
   case $LOG in
     *00) SUBJ="$ARQ - Importacao do GEL"
          MSG1="I-MAGNUS_BIL-050"
          FLAG=1
	  RC=0
          ;;
     *01) mv $FILE $DIRERR
          gzip -9 -f ${DIRERR}/${FILE}
          SUBJ="$ARQ - Arquivo nao encontrado"
          MSG1="E-MAGNUS_BIL-050"
	  RC=1
          ;;
     *02) mv $FILE $DIRERR
          gzip -9 -f ${DIRERR}/${FILE}
          SUBJ="$ARQ - Problemas no arquivo a ser importado"
          MSG1="E-MAGNUS_BIL-050"
	  RC=1
          ;;
     *99) mv $FILE $DIRERR
          gzip -9 -f ${DIRERR}/${FILE}
          SUBJ="$ARQ - Nao houve processamento"
          MSG1="E-MAGNUS_BIL-050"
	  RC=1
          ;;
   esac
   # Publica na Intranet
   ( echo $SUBJ;cat $ARQ_PRO $ARQ_MSG_E $ARQ_MSG_I ) | msg_api $MSG1
   # Manda page
   echo $SUBJ | mailx magnus_bill_page@unix_mail_fwd
   mv -f ${DIRWRK}/$ARQ_PRO $DIRPRO
   mv -f ${DIRWRK}/${FILE}.txt  ${DIRREL}
   mv -f ${DIRWRK}/${FILE}.ok  ${DIRREL}
   mv -f ${DIRWRK}/${FILE}.dct ${DIRREL}
   /amb/operator/bin/attach_mail $DEST3 ${DIRREL}/${FILE}.txt \
                                 "Arquivo $FILE importado no Magnus"

done

# Apaga arquivos temporarios 
rm -f $TMP $PARAM $ARQ_MSG_I $ARQ_MSG_E 

exit $RC
