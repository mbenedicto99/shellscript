#!/bin/ksh
#  Script      : BILLING_04_03.sh
#  Objetivo    : ATUALIZACAO DO CONTAS A RECEBER NO MAGNUS
#  Data        : 02/01/2001
#  Autor       : Renato
#  Alteracao   : 13/03/02
#
## Mensagens
#M#I-MAGNUS_BIL-060 : Sucesso na Geracao do arquivo de parametros
#M#E-MAGNUS_BIL-060 : Erro    na Geracao do arquivo de parametros
#M#I-MAGNUS_BIL-061 : Sucesso na Atualizacao do Contas a Receber
#M#E-MAGNUS_BIL-061 : Erro    na Atualizacao do Contas a Receber

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
DIRWRK=${DIRMAG}/bill
DIRIMP=${DIRWRK}/IMPORTA
DIRTMP=${DIRWRK}/TMP
DIRERR=${DIRWRK}/ERROR
DIRPRO=${DIRWRK}/PRO
DIRREL=${DIRWRK}/REL
MSG_I=I-ESBL015-001
MSG_E=E-ESBL015-001
PARAM=$DIRTMP/param.txt
TMP=$DIRTMP/MAGNUS_BIL_02_$$.txt
DEST1=magnus_bill_1
FLAG=0

cd $DIRIMP
# Remove caso ja exista o arquivo de parametros
[ -f ftcr0603.pf ] && rm ftcr0603.pf

# Gera arquivo de parametros - ftcr0603.pf
for FILE in GEL???????????????????????.?????.????????????
do [ ! -f $FILE ] && continue
   SEQ=`echo $FILE | cut -d "." -f2`
   ARQ="`echo $FILE | cut -c 1-8`.${SEQ}"
   ARQ_MSG_E="${DIRIMP}/${FILE}.${MSG_E}"
   ARQ_MSG_I="${DIRIMP}/${FILE}.${MSG_I}"
   ARQ_PRO="${DIRIMP}/${FILE}.pro"
   ( echo "DiretorioErros=\"${DIRIMP}\""
     echo "NomeArquivo=\"${FILE}\""
     echo "DiretorioMapi=\"${DIRIMP}\""
     echo "DiretorioProcess=\"${DIRIMP}\""
     echo "DiretorioLeitura=\"${DIRIMP}\"" ) > $PARAM
   #inicio da procedure

   $DLC/bin/_progres -pf ${DIRMAG}/mgadm.pf -U billing -P billing \
                     -pf ${DIRMAG}/mgind.pf -U billing -P billing \
                     -pf ${DIRMAG}/mgcom.pf -U billing -P billing \
                     -pf ${DIRMAG}/mglnk.pf -U billing -P billing \
                     -o "lp -s > /dev/null" -p ${DIRMAG}/esp/esbl015p.p \
                     -param $PARAM \
                     -b > $TMP

   RC=$?

   if [ $RC != 0 ] ; then 
      # se falta licensa no magnus envia msg 
      grep "Try a larger -n" $TMP
      if [ $? = 0 ] ; then
         ( echo $FILE "- Falta de licensa no magnus "
           cat $TMP $PARAM ) | msg_api "E-MAGNUS_BIL-060"
         mv $FILE $DIRERR
         gzip -9 -f ${DIRERR}/${FILE}
         rm -f $TMP $PARAM $ARQ_PRO $ARQ_MSG_E $ARQ_MSG_I
         MSG1="Billing Erro - Gerando arquivo de parametros  - $ARQ"
         SUBJ="$ARQ - Falta de licenca no Magnus " 
         /amb/operator/bin/attach_mail $DEST1 $TMP $SUBJ
         echo $MSG1 | mailx magnus_bill_page@unix_mail_fwd
         exit 1
      fi
      # demais tipo de erro na geracao do arquivo
      ( echo "$ARQ - Erro na geracao do arquivo de parametros"
        cat $TMP $PARAM $ARQ_MSG_E $ARQ_PRO ) | msg_api "E-MAGNUS_BIL-060"
      mv $FILE $DIRERR
      gzip -9 -f ${DIRERR}/${FILE}
      rm -f $TMP $PARAM $ARQ_PRO $ARQ_MSG_E $ARQ_MSG_I
      MSG1="$ARQ - Billing Erro - Geracao do arquivo de parametros " 
      SUBJ="Erro na na geracao do arquivo de parametros - $ARQ"
      /amb/operator/bin/attach_mail $DEST1 $TMP $SUBJ
      echo $MSG1 | mailx magnus_bill_page@unix_mail_fwd
      exit 1
   fi

   if [ ! -s $ARQ_PRO ] ; then
     echo "$ARQ - arquivo $ARQ_PRO nao encontrado" | msg_api "E-MAGNUS_BIL-060"
     MSG1="$ARQ - Billing Erro - Arquivo .PRO nao encontrado "
     SUBJ="Erro na importacao do GEL - $ARQ"
     mv $FILE $DIRERR
     gzip -9 -f ${DIRERR}/${FILE}
     /amb/operator/bin/attach_mail $DEST1 $TMP $SUBJ
     echo $MSG1 | mailx magnus_bill_page@unix_mail_fwd
     rm -f $TMP $PARAM $ARQ_PRO $ARQ_MSG_E $ARQ_MSG_I
     exit 1
   fi

   LOG=`head -1 $ARQ_PRO`
   case $LOG in
     *00) SUBJ="$ARQ - Geracao do arquivo de parametros"
          MSG1="I-MAGNUS_BIL-060"
          head - 100 $FILE.rel > $TMP
          FLAG=1
          ;;
     *01) mv $FILE $DIRERR
          gzip -9 -f ${DIRERR}/${FILE}
          SUBJ="$ARQ - Arquivo nao encontrado"
          MSG1="E-MAGNUS_BIL-060"
          ;;
     *02) mv $FILE $DIRERR
          gzip -9 -f ${DIRERR}/${FILE}
          SUBJ="$ARQ - Problemas no arquivo a ser importado"
          MSG1="E-MAGNUS_BIL-060"
          ;;
     *99) mv $FILE $DIRERR
          gzip -9 -f ${DIRERR}/${FILE}
          SUBJ="$ARQ - Nao houve processamento"
          MSG1="E-MAGNUS_BIL-060"
          ;;
   esac
   # Publica na Intranet
   ( echo $SUBJ;cat $ARQ_PRO $ARQ_MSG_E $ARQ_MSG_I ) | msg_api $MSG1
   # Manda e-mail
   [ $FLAG = 1 ] && /amb/operator/bin/attach_mail $DEST1 ${FILE}.rel $SUBJ
   # Manda page
   echo $SUBJ | mailx magnus_bill_page@unix_mail_fwd
   mv -f $ARQ_PRO $DIRPRO

   # Apaga arquivos temporarios 
   rm -f $TMP $PARAM $ARQ_MSG_I $ARQ_MSG_E

   # Se houve erro sai sem Atualizar o Contas a Receber
   [ $FLAG = 0 ] && exit 1

   if [ ! -f ftcr0603.pf ] ; then
      MSG="$ARQ - Nao gerado arquivo ftcr0603.pf"
      ( echo "$MSG" ; cat $TMP ) | msg_api "E-MAGNUS_BIL-061"
      /amb/operator/bin/attach_mail $DEST1 $TMP $MSG
      echo $MSG | mailx magnus_bill_page@unix_mail_fwd
      rm -f $TMP $PARAM $ARQ_PRO
      exit 1
   fi


   ( echo "DiretorioErros=\"${DIRIMP}\""
     echo "NomeArquivo=ftcr0603.pf"
     echo "DiretorioMapi=\"${DIRIMP}\""
     echo "DiretorioProcess=\"${DIRIMP}\""
     echo "DiretorioLeitura=\"${DIRIMP}\"" ) > $PARAM

   $DLC/bin/_progres -pf ${DIRMAG}/mgadm.pf -U billing -P billing \
                     -pf ${DIRMAG}/mgind.pf -U billing -P billing \
                     -pf ${DIRMAG}/mgcom.pf -U billing -P billing \
                     -pf ${DIRMAG}/mglnk.pf -U billing -P billing \
                     -o "lp -s > /dev/null" -p ${DIRMAG}/ftp/ft0603.p \
                     -param $PARAM \
                     -b <${DIRIMP}/ftcr0603.pf >> $TMP

   RC=$?
   rm -f ${DIRIMP}/ftcr0603.pf

   if [ $RC != 0 ] ; then
      MSG="$ARQ - Erro na Atualizacao do Contas a Receber - $RC"
      ( echo "$MSG" ; cat $TMP ) | msg_api "E-MAGNUS_BIL-061"
      /amb/operator/bin/attach_mail $DEST1 $TMP $MSG
      echo $MSG | mailx magnus_bill_page@unix_mail_fwd
      rm -f $TMP $PARAM $ARQ_PRO 
      for FILE in GEL*
      do [ ! -f $FILE ] && continue
         mv $FILE $DIRERR
         [ -f ${DIRERR}/{FILE}.gz ] && rm ${DIRERR}/{FILE}.gz
         gzip -9 ${DIRERR}/${FILE}
      done
      exit 1
   fi

   MSG="$ARQ - Sucesso na Atualizacao do Contas a Receber"
   ( echo "$MSG" ; cat $TMP ) | msg_api "I-MAGNUS_BIL-061"
   /amb/operator/bin/attach_mail $DEST1 $TMP $MSG
   echo $MSG | mailx magnus_bill_page@unix_mail_fwd


   #Envia relatorios
   for FILE in FC*
   do [ ! -f $FILE ] && continue
      MSG="Relatorio de Atualizacao do Contas a Receber - Arq. $FILE"
      /amb/operator/bin/attach_mail $DEST1 $FILE $MSG
      mv $FILE $DIRREL
      [ -f ${DIRREL}/{FILE}.gz ] && rm ${DIRREL}/{FILE}.gz
      gzip -9 ${DIRREL}/${FILE}
   done

done


exit 0
