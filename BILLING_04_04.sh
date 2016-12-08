#!/bin/ksh
#  Script      : BILLING_04_04.sh
#  Objetivo    : EXPORTACAO DE BOLETOS BANCARIOS
#  Data        : 08/01/2001
#  Autor       : Renato
#  Alteracao   : Marcos de Benedicto - 15/10/2003
#
## Mensagens
#M#I-MAGNUS_BIL-070 : Sucesso na Geracao do arquivo de parametros
#M#E-MAGNUS_BIL-070 : Erro    na Geracao do arquivo de parametros
#M#I-MAGNUS_BIL-071 : Sucesso na Exportacao de boletos bancarios
#M#E-MAGNUS_BIL-071 : Erro    na Exportacao de boletos bancarios

# Variaveis de ambiente do Progress
export DLC=/opgs_sp/app/dlc
export PATH=$PATH:$DLC/bin
export PROPATH=/apgs_sp/magnus
export PROTERMCAP=$DLC/protermcap
export PROMSGS=$DLC/promsgs
export TERM=vt100
PATH=$PATH:/amb/bin

# Variaveis de trabalho
CICLO="$1"
DIRMAG=/apgs_sp/magnus
DIRWRK=${DIRMAG}/bill
DIRIMP=${DIRWRK}/IMPORTA
DIRPPP=${DIRWRK}/PROCESSADOS
DIRTMP=${DIRWRK}/TMP
DIRERR=${DIRWRK}/ERROR
DIRPRO=${DIRWRK}/PRO
DIRENV=${DIRWRK}/ENVIA
DIRREL=${DIRWRK}/REL
DIREZP=${DIRWRK}/ezpay  
MSG_I=I-ESBL016-001
MSG_E=E-ESBL016-001
PARAM=$DIRTMP/param.txt
TMP=$DIRTMP/MAGNUS_BIL_02_$$.txt
#DEST1=magnus_bill_1@unix_mail_fwd
DEST1="bill_process_magnus@unix_mail_fwd"
#DESTINO=spoax004:/pinvoice/input
DESTINO3=pabgh:/pinvoice/input
FLAG=0
EMAIL=prod@unix_mail_fwd

cd $DIRIMP
# Remove caso ja exista o arquivo de parametros
[ -f esbl017.pf ] && rm esbl017.pf

# Variavel para checagem.
NOME_GEL=`ls GELCRJ${CICLO}* | head -1 | cut -c1-26`

# Gera arquivo de parametros - esbl017.pf
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
                     -o "lp -s > /dev/null" -p ${DIRMAG}/esp/esbl016p.p \
                     -param $PARAM \
                     -b > $TMP

   RC=$?

   if [ $RC != 0 ] ; then 
      # se falta licensa no magnus envia msg 
      grep "Try a larger -n" $TMP
      if [ $? = 0 ] ; then
         ( echo $FILE "- Falta de licensa no magnus "
           cat $TMP $PARAM ) | msg_api "E-MAGNUS_BIL-070"
         mv $FILE $DIRERR
         gzip -9 -f ${DIRERR}/${FILE}
         rm -f $TMP $PARAM $ARQ_PRO $ARQ_MSG_E $ARQ_MSG_I
         MSG1="$ARQ - Billing Erro - Gerando arquivo de parametros "
         SUBJ="Falta de licenca no Magnus - $ARQ" 
         /amb/operator/bin/attach_mail $DEST1 $TMP $SUBJ
         #echo $MSG1 | mailx magnus_bill_page@unix_mail_fwd
         echo $MSG1 | mailx ${DEST1}
         exit 1
      fi
      # demais tipo de erro na geracao do arquivo
      ( echo "$FILE - Erro na geracao do arquivo de parametros"
        cat $TMP $PARAM $ARQ_MSG_E $ARQ_PRO ) | msg_api "E-MAGNUS_BIL-070"
      mv $FILE $DIRERR
      gzip -9 -f ${DIRERR}/${FILE}
      rm -f $TMP $PARAM $ARQ_PRO $ARQ_MSG_E $ARQ_MSG_I
      MSG1="$ARQ - Billing Erro - Geracao do arquivo de parametros - " 
      SUBJ="Erro na na geracao do arquivo de parametros - $ARQ"
      /amb/operator/bin/attach_mail $DEST1 $TMP $SUBJ
      echo $MSG1 | mailx ${DEST1}
      exit 1
   fi

   if [ ! -s $ARQ_PRO ] ; then
     echo "$FILE - arquivo $ARQ_PRO nao encontrado" | msg_api "E-MAGNUS_BIL-070"
     MSG1="$ARQ - Billing Erro - Arquivo .PRO nao encontrado "
     SUBJ="Erro na importacao do GEL - $ARQ"
     mv $FILE $DIRERR
     gzip -9 -f ${DIRERR}/${FILE}
     /amb/operator/bin/attach_mail $DEST1 $TMP $SUBJ
     echo $MSG1 | mailx ${DEST1}
     rm -f $TMP $PARAM $ARQ_PRO $ARQ_MSG_E $ARQ_MSG_I
     exit 1
   fi

   LOG=`head -1 $ARQ_PRO`
   case $LOG in
     *00) SUBJ="$ARQ - Geracao do arquivo de parametros"
          MSG1="I-MAGNUS_BIL-070"
          head - 100 $FILE.rel > $TMP
          FLAG=1
          ;;
     *01) mv $FILE $DIRERR
          gzip -9 -f ${DIRERR}/${FILE}
          SUBJ="$ARQ - Arquivo nao encontrado"
          MSG1="E-MAGNUS_BIL-070"
          ;;
     *02) mv $FILE $DIRERR
          gzip -9 -f ${DIRERR}/${FILE}
          SUBJ="$ARQ - Problemas no arquivo a ser importado"
          MSG1="E-MAGNUS_BIL-070"
          ;;
     *99) mv $FILE $DIRERR
          gzip -9 -f ${DIRERR}/${FILE}
          SUBJ="$ARQ - Nao houve processamento"
          MSG1="E-MAGNUS_BIL-070"
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
   rm -f $TMP $PARAM $ARQ_MSG_E $ARQ_MSG_I

   # Se houve erro sai sem exportar Boletos
   [ $FLAG = 0 ] && exit 1

   if [ ! -f esbl017.pf ] ; then
      MSG="$ARQ - Nao gerado arquivo esbl017.pf"
      ( echo "$MSG" ; cat $TMP ) | msg_api "E-MAGNUS_BIL-071"
      /amb/operator/bin/attach_mail $DEST1 $TMP $MSG
      echo $MSG | mailx magnus_bill_page@unix_mail_fwd
      rm -f $TMP $PARAM $ARQ_PRO
      exit 1
   fi


   ( echo "DiretorioErros=\"${DIRIMP}\""
     echo "NomeArquivo=esbl017.pf"
     echo "DiretorioMapi=\"${DIRIMP}\""
     echo "DiretorioProcess=\"${DIRIMP}\""
     echo "DiretorioLeitura=\"${DIRIMP}\"" ) > $PARAM

   $DLC/bin/_progres -pf ${DIRMAG}/mgadm.pf -U billing -P billing \
                     -pf ${DIRMAG}/mgind.pf -U billing -P billing \
                     -pf ${DIRMAG}/mgcom.pf -U billing -P billing \
                     -pf ${DIRMAG}/mglnk.pf -U billing -P billing \
                     -o "lp -s > /dev/null" -p ${DIRMAG}/esp/esbl017a.p \
                     -b <${DIRIMP}/esbl017.pf >> $TMP    

   RC=$?

   if [ $RC != 0 ] ; then
      MSG="$ARQ - Erro na exportacao de boletos bancarios"
      ( echo "$MSG" ; cat $TMP ) | msg_api "E-MAGNUS_BIL-071"
      /amb/operator/bin/attach_mail $DEST1 $TMP $MSG
      echo $MSG | mailx magnus_bill_page@unix_mail_fwd
      rm -f $TMP $PARAM $ARQ_PRO 
      exit 1
   fi

   MSG="$ARQ - Sucesso na Exportacao de boletos bancarios"
   ( echo "$MSG" ; cat $TMP ) | msg_api "I-MAGNUS_BIL-071"
   /amb/operator/bin/attach_mail $DEST1 $TMP $MSG
   echo $MSG | mailx magnus_bill_page@unix_mail_fwd

   # Envia e-mail de notificacao a WorkImage
   echo "Os arquivo de NF estao sendo enviados" | mailx -s "Envio de arquivos de NF - Nextel" image@spoaxap4

   #Envia relatorios
   for FILE in ????T??????.ERR*
   do [ ! -f $FILE ] && continue
      MSG="Relatorio de Erros na Exportacao de Boletos - Arq. $FILE"
      /amb/operator/bin/attach_mail $DEST1 $FILE $MSG
      mv $FILE $DIRREL
      cp ${FILE} $DIREZP
      gzip -f $DIREZP/${FILE}
      [ -f ${FILE}.gz ] && rm ${FILE}.gz
      gzip -9 ${DIRREL}/${FILE}
      exit 1
   done

done

# Publica resumo do Billing n Magnus
/amb/operator/bin/confere_cvt


# envio dos arquivos ao BSCS
for FILE in ????T??????.?? 
do [ ! -f $FILE ] && continue
   ARQ1="`echo $FILE | cut -c 1-4`T.GEL"
   ciclo="`echo $FILE | cut -c 3-4`"
   cat $FILE >>$ARQ1
   gzip -f $FILE
   mv $FILE.gz $DIRENV
   chmod 776 ${DIRENV}/${FILE}.gz
   cp ${DIRENV}/${FILE}.gz $DIREZP
done

if [ -f "$ARQ1" ] ; then 
   chmod 666 $ARQ1
   #/amb/eventbin/RCP_SEC.sh ${ARQ1} ${DESTINO} ${EMAIL}
   #[ $? != 0 ] && exit 99 || echo "Envio do Arq: ${ARQ1} para o Destino: ${DESTINO} - OK!!!"

   /amb/eventbin/RCP_SEC.sh ${ARQ1} ${DESTINO3} ${EMAIL}
   [ $? != 0 ] && exit 99 || echo "Envio do Arq: ${ARQ1} para o Destino: ${DESTINO3} - OK!!!"

   if [ $? != 0 ]; then
      echo "Erro no envio do arquivo de TELECOMUNICACOES ao BSCS"
      cat $TMP
      rm -f $TMP
      exit 1
   fi
   echo "Arquivo TELECOMUNICACOES enviado com sucesso para BSCS"
   mv $ARQ1 ${DIRENV}
   #gzip -9 ${DIRENV}/${ARQ1}
   else echo "NENHUM ARQUIVO DE TELECOMUNICACOES A SER ENVIADO"
   exit 1
fi

echo `date` > /var/adm/crash/filebilling.txt
ls -lalt >> /var/adm/crash/filebilling.txt
for FILE in ????S??????.??
do [ ! -f $FILE ] && continue
ARQ2="`echo $FILE | cut -c 1-4`S.GEL"
   cat $FILE >> $ARQ2
   gzip -f $FILE
   mv $FILE.gz $DIRENV
   chmod 776 ${DIRENV}/${FILE}.gz
   cp ${DIRENV}/${FILE}.gz $DIREZP
done

  if [ -f "$ARQ2" ] ; then 
     chmod 666 $ARQ2
   #/amb/eventbin/RCP_SEC.sh ${ARQ2} ${DESTINO} ${EMAIL}
   #[ $? != 0 ] && exit 99 || echo "Envio do Arq: ${ARQ2} para o Destino: ${DESTINO} - OK!!!"

   /amb/eventbin/RCP_SEC.sh ${ARQ2} ${DESTINO3} ${EMAIL}
   [ $? != 0 ] && exit 99 || echo "Envio do Arq: ${ARQ2} para o Destino: ${DESTINO3} - OK!!!"

     if [ $? != 0 ]; then
        echo "Erro no envio do arquivo de SERVICOS para o BSCS"
        cat $TMP
        rm -f $TMP
        exit 1
     fi
     echo "Arquivo de SERVICOS enviado com sucesso para BSCS"
     mv $ARQ2 ${DIRENV}
     #gzip -9 ${DIRENV}/${ARQ2}
     else echo "NENHUM ARQUIVO DE SERVICOS A SER ENVIADO"
     exit 1
  fi

>/tmp/GEL_ARQ_NAMES.txt

for FILE in GEL???????????????????????.?????.????????????
do [ ! -f $FILE ] && continue
   mv $FILE $DIRPPP
   echo $FILE >>/tmp/GEL_ARQ_NAMES.txt
done

##################### ALTERACAO PARA CHECAGEM DE BOLETOS PROCESSADOS ######################
##################### Marcos de Benedicto 17/10/2003 ######################################

	[ ! -f ${DIRWRK}/ENVIA/RJ${CICLO}T.GEL ] && exit 1
	[ ! -f ${DIRWRK}/ENVIA/RJ${CICLO}S.GEL ] && exit 1
	COUNT_BOLT=`grep -c "00 0 00" ${DIRWRK}/ENVIA/RJ${CICLO}T.GEL`
	COUNT_BOLS=`grep -c "00 0 00" ${DIRWRK}/ENVIA/RJ${CICLO}S.GEL`
	[ -z "${COUNT_BOLT}" ] && exit 1
	[ -z "${COUNT_BOLS}" ] && exit 1

	let COUNT_BOL_TOT=${COUNT_BOLT}+${COUNT_BOLS}

	COUNT_PROC=`grep "^N" ${DIRWRK}/PROCESSADOS/${NOME_GEL}* | wc -l`
	[ -z "${COUNT_PROC}" ] && exit 1

	let COUNT=${COUNT_BOL_TOT}-${COUNT_PROC}
	[ -z "${COUNT}" ] && exit 1

	if [ ${COUNT} -eq 0 ] 
	then
	gzip -9 ${DIRWRK}/ENVIA/RJ${CICLO}T.GEL
	gzip -9 ${DIRWRK}/ENVIA/RJ${CICLO}S.GEL
	exit 0 

	else
	set +x
	echo "
	+------------------------------------------------------------------------
	|
	|   ERRO!
	|   `date`
	|   Quantidade de Boletos e diferente do numero de Boletos processados. 
	|
	+------------------------------------------------------------------------\n"
	exit 1
	fi

#####################ALTERACAO PARA CHECAGEM DE BOLETOS PROCESSADOS######################

