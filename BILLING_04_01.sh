#!/bin/ksh
#  Script      : BILLING_04_01.sh
#  Objetivo    : VERIFICA DADOS DE NOTAS NO MAGNUS - ARQ GEL
#  Descricao   : Arquivo GEL no Magnus - Verifica Dados de Notas
#  Data        : 16/11/2000
#  Autor       : Renato
#  Alteracao   : 13/03/02
#
#

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
DIRWRK=/apgs_sp/magnus/bill/VERIFICA
DIRARQ=/apgs_sp/magnus/bill/PROCESSANDO
DIRTMP=/apgs_sp/magnus/bill/TMP
DIRERR=/apgs_sp/magnus/bill/ERROR
DIRPPR=/apgs_sp/magnus/bill/PROCESSADOS
DIRPRO=/apgs_sp/magnus/bill/PRO
DIRREL=/apgs_sp/magnus/bill/REL
DIRCVT=/apgs_sp/magnus/bill/CVT
DIRLOG=/apgs_sp/magnus/bill/LOG
DIREXC=/apgs_sp/magnus/bill/EXC
MSG_I=I-ESBL010-001
MSG_E=E-ESBL010-001
PARAM=$DIRTMP/param_$$.txt
TMP=$DIRTMP/MAGNUS_BIL_02_$$.txt
#DEST1=magnus_bill_1@unix_mail_fwd
DEST1="bill_process_magnus@unix_mail_fwd"
FLAG=0
RC=0

# limpa diretorios de logs e relatorios
find $DIRTMP -type f -ctime +7 -exec rm -f {} \;
find $DIRTMP -type f -mtime +7 -exec rm -f {} \;
find $DIRERR -type f -ctime +7 -exec rm -f {} \;
find $DIRERR -type f -mtime +7 -exec rm -f {} \;
find $DIRREL -type f -ctime +7 -exec rm -f {} \;
find $DIRREL -type f -mtime +7 -exec rm -f {} \;
find $DIRPRO -type f -ctime +7 -exec rm -f {} \;
find $DIRPRO -type f -mtime +7 -exec rm -f {} \;
find $DIRCVT -type f -ctime +7 -exec rm -f {} \;
find $DIRCVT -type f -mtime +7 -exec rm -f {} \;
find $DIREXC -type f -ctime +7 -exec rm -f {} \;
find $DIRPPR -type f -ctime +7 -exec rm -f {} \;
find $DIRPPR -type f -mtime +7 -exec rm -f {} \;

cd $DIRARQ

for FILE in GEL???????????????????????.?????.????????????
do [ ! -f $FILE ] && continue
   chown progress:dba $FILE
   chmod 777 $FILE
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
     echo "DiretorioLeitura=\"${DIRARQ}\"" ) > $PARAM
   #inicio da procedure

   $DLC/bin/_progres -pf ${DIRMAG}/mgadm.pf -U billing -P billing \
                     -pf ${DIRMAG}/mgind.pf -U billing -P billing \
                     -pf ${DIRMAG}/mgcom.pf -U billing -P billing \
                     -pf ${DIRMAG}/mglnk.pf -U billing -P billing \
                     -o "lp -s > /dev/null" -p ${DIRMAG}/esp/esbl010p.p \
                     -param $PARAM \
                     -b > $TMP

   RC="`expr $? + $RC`"

   if [ $RC != 0 ] ; then 
      # se falta licensa no magnus envia msg 
      grep "Try a larger -n" $TMP
      if [ $? = 0 ] ; then
         ( echo $FILE "- Falta de licensa no magnus "
           cat $TMP $PARAM ) |\
	       /amb/bin/msg_api2  "E-BILLING-MAGNUS-VERIFICA"
         #mv $FILE $DIRERR
         #gzip -9 -f ${DIRERR}/${FILE}
         rm -f $TMP $PARAM $ARQ_MSG_E $ARQ_MSG_I $ARQ_PRO
         MSG1="Billing Erro - Verificao da Notas Fiscais - $ARQ"
         SUBJ="Falta de licenca no Magnus - $ARQ" 
         /amb/operator/bin/attach_mail $DEST1 $TMP $SUBJ
         #echo $MSG1 | mailx magnus_bill_page@unix_mail_fwd
         echo $MSG1 | mailx ${DEST1}
         cat $TMP
         exit 1
      fi
      # demais tipo de erro na geracao do arquivo
      ( echo "$FILE - Erro na verificacao de Notas Fiscais "
        cat $TMP $PARAM $ARQ_MSG_E $ARQ_PRO ) |\
	    /amb/bin/msg_api2  "E-BILLING-MAGNUS-VERIFICA"
      #mv $FILE $DIRERR
      #gzip -9 -f ${DIRERR}/${FILE}
      MSG1="Billing Erro - Verificacao da Notas Fiscais - $ARQ" 
      SUBJ="Erro na verificacao de NF - $ARQ"
      /amb/operator/bin/attach_mail $DEST1 ${FILE}.rel $SUBJ
      #echo $MSG1 | mailx magnus_bill_page@unix_mail_fwd
      echo $MSG1 | mailx ${DEST1}
      rm -f $TMP $PARAM $ARQ_MSG_E $ARQ_MSG_I $ARQ_PRO
      exit 1
   fi

   if [ ! -s $ARQ_PRO ] ; then
     echo "$FILE - arquivo $ARQ_PRO nao encontrado - $FILE" |\
	/amb/bin/msg_api2  "E-BILLING-MAGNUS-VERIFICA"
     MSG1="Billing Erro - Arquivo .PRO nao encontrado - $ARQ"
     SUBJ="Erro na verificacao de NF - $ARQ"
     #mv $FILE $DIRERR
     #gzip -9 -f ${DIRERR}/${FILE}
     /amb/operator/bin/attach_mail producao_spo@unix_mail_fwd $FILE.rel $SUBJ
     #echo $MSG1 | mailx magnus_bill_page@unix_mail_fwd
     echo $MSG1 | mailx ${DEST1}
     rm -f $TMP $PARAM $ARQ_MSG_E $ARQ_MSG_I $ARQ_PRO
     exit 1
   fi

   LOG=`head -1 $ARQ_PRO`
   case $LOG in
     *00) SUBJ="$ARQ - Verificado Dados de Notas Fiscais - $FILE"
          MSG1="I-MAGNUS_BIL-020"
          head - 100 $FILE.rel > $TMP
          FLAG=1
          ;;
     *01) SUBJ="$ARQ - Arquivo nao encontrado - $FILE"
          MSG1="E-MAGNUS_BIL-020"
	  RC=1
          ;;
     *02) SUBJ="$ARQ - Problemas no arquivo Verificado - $FILE"
          MSG1="E-MAGNUS_BIL-020"
	  RC=1
          ;;
     *99) SUBJ="$ARQ - Nao houve processamento - $FILE"
          MSG1="E-MAGNUS_BIL-020"
	  RC=1
          ;;
   esac
   # Publica na Intranet
   ( echo $SUBJ;cat $ARQ_PRO $ARQ_MSG_E $ARQ_MSG_I ) | msg_api $MSG1
   # Manda e-mail
   /amb/operator/bin/attach_mail $DEST1 ${DIRWRK}/${FILE}.rel $SUBJ
   # Manda page
   echo $SUBJ | mailx magnus_bill_page@unix_mail_fwd
   mv -f $ARQ_PRO $DIRPRO
   mv -f ${DIRWRK}/${FILE}.rel ${DIRREL}/${FILE}nf.rel
   rm -f $ARQ_MSG_I $ARQ_MSG_E 

done

cat $TMP
# Apaga arquivos temporarios 
rm -f $TMP $PARAM $ARQ_MSG_I $ARQ_MSG_E 

exit $RC

