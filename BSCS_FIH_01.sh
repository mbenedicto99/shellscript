#!/bin/ksh

. /etc/appltab

typeset  -u -L2 SITE
#SITE=`uname -n`
SITE="${ENV_VAR_SITE}"

DATA=`date +%Y%m%d%H%M%S`
#DESTINO=spoaxap8
TMP=/tmp/BSCS_FIH$$.tmp
TMP1=/tmp/BSCS_FIH1$$.tmp
TMP2=/tmp/BSCS_FIH2$$.tmp
TMP3=/tmp/${SITE}FIH${DATA}.txt

cd ~prod/WORK/TMP
[ $? != 0 ] && exit 1

# Procura arquivos nao marcados com bit de execucao para other
find . ! -perm -1 -name "FIH*" -print |\
while read file
   do case "$file" in
         *.PRT) MSG=I-RATING-FIH-PROTOCOLO
                FILETYPE="PROTOCOL" ;;
         *.ERR) MSG=E-RATING-FIH-ERRO
                FILETYPE="ERROR" ;;
             *) MSG=W-RATING-FIH-OUTRO
                FILETYPE="UNKNOWN" ;;
      esac
      # Verifica se o processo relativo ao arquivo ainda esta no ar
      # Este trecho com file_open ou lsof nao funcionava
      AUX=`basename $file | cut -c 4-9`
      #PROCID=`expr $AUX + 0`
      #while [ 1 ]
      #   do ps -p $PROCID > /dev/null
      #      [ $? != 0 ] && break
      #      sleep 1
      #   done
      # Marca arquivo com bit de execucao para other
      chmod o+x $file
      ( echo "$file"
        echo 
        echo "BSCS FILE INPUT HANDLER - \c"
        echo $FILETYPE" FILE"
        echo "                                    "`ll $file | cut -c 46-57` 
        echo "------------------------------------------------"
        echo
        case $FILETYPE in
           PROTOCOL ) # Arquivo de protocol 
                      # Contem totalizacao de records, files e errors
                      # Totaliza Input Files
                      # Totaliza No Errors in call records
                      # Totaliza todos os contadores de records
                      /amb/eventbin/FIH_01_02.sh $file
                      /amb/eventbin/FIH_01_03.sh $file
                      /amb/eventbin/FIH_01_04.sh $file
                      ### /amb/eventbin/consolidacao/OK/FIH_01_02.sh $file
                      ### /amb/eventbin/consolidacao/OK/FIH_01_03.sh $file
                      ### /amb/eventbin/consolidacao/OK/FIH_01_04.sh $file
                      cat -s $file |
                      awk -F ":" 'BEGIN { 
                           INPUTFILE=NOERRORS=FILEPR0=SUSPFILE=REJECTFILE=0
                           NPROCREC=NMOBOC=NMOBTC=0
                           NSMSMOC=NSMSMTC=0
                           NFTOR=NTIMEC=NSR=NIGC=NOGC=NIIP=NOIP=NTC=0
                           NRC=NCEU=0
                           DTC=DPC=DCA=DEC=DMS=0
                           UTXRECGEN=URGMOC=URGMTC=URCRCF=URGLTL=URGEV=0
                           MKURG=0
                           UTXRGO=URGOMOC=URGOMTC=URGORCF=URGOLTL=MKURGO=0
                           UARREC=UARMOC=UARMTC=UARRCF=UARLTL=MKUAR=0
                           NRECEO=NRECRO=NRECFO=0
                         }

                         /Unit from input file/ {INPUTFILE+=1}
                         /No errors in call records/ {NOERRORS+=1}

                         /Numbers of processed Records/{NPROCREC+=$2
                            if ($2==0) FILEPR0+=1 }

                         /Suspicious Input File/ {SUSPFILE+=1}

                         /!!!  INPUT FILE REJECTED   !!!/ {REJECTFILE+=1}

                         /Nortel Mobile Originating Call/{NMOBOC+=$2}
                         /Nortel Mobile Terminating Call/{NMOBTC+=$2}
                         /Nortel Short Message Service Mobile Originated Call/{
                            NSMSMOC+=$2}
                         /Nortel Short Message Service Mobile Terminated Call/{
                            NSMSMTC+=$2}
                         /Nortel File Transfer Out Record/{NFTOR+=$2}
                         /Nortel Time Change/{NTIMEC+=$2}
                         /Nortel Switch Restart/{NSR+=$2}
                         /Nortel Incoming Gateway Call/{NIGC+=$2}
                         /Nortel Outgoing Gateway Call/{NOGC+=$2}
                         /Nortel Incoming Intra-PLMN/{NIIP+=$2}
                         /Nortel Outgoing Intra-PLMN/{NOIP+=$2}
                         /Nortel Transit Call/{NTC+=$2}
                         /Nortel Roaming Call/{NRC+=$2}
                         /Nortel Common Equipment Usage/{NCEU+=$2}
 
                         /DAP - Talkgroup Call/{DTC+=$2}
                         /DAP - Private Call/{DPC+=$2}
                         /DAP - Call ALert/{DCA+=$2}
                         /DAP - Emergency Call/{DEC+=$2}
                         /DAP - MS Status/{DMS+=$2}


                         /Numbers of UTX/{
                            if ($1=="Numbers of UTX Records generated ") {
                               UTXRECGEN+=$2
                               MKURG=1
                               MKURGO=MKUAR=0
                            } 
                            if ($1=="Numbers of UTX Records generated out of Call Forwarding") {
                               UTXRGO+=$2
                               MKURGO=1
                               MKURG=MKUAR=0
                            } 
                         }

                         /Numbers of UAR Records generated for AIH/{
                            UARREC+=$2
                            MKUAR=1
                            MKURG=MKURGO=0
                         } 

                         /MOCs/{ 
                            if (MKURG==1)  { URGMOC+=$2 }
                            if (MKURGO==1) { URGOMOC+=$2 }
                            if (MKUAR==1)  { UARMOC+=$2 }
                         }
                         /MTCs/{ 
                            if (MKURG==1)  { URGMTC+=$2 }
                            if (MKURGO==1) { URGOMTC+=$2 }
                            if (MKUAR==1)  { UARMTC+=$2 }
                         }
                         /RCFs/{ 
                            if (MKURG==1)  { URGRCF+=$2 }
                            if (MKURGO==1) { URGORCF+=$2}
                            if (MKUAR==1)  { UARRCF+=$2 }
                         }
                         /LTLs/{ 
                            if (MKURG==1)  { URGLTL+=$2 }
                            if (MKUAR==1)  { UARLTL+=$2 }
                         }
                         /EVENTs/{ 
                            if (MKURG==1) { URGEV+=$2}}

                         /Numbers of Records errored out/{NRECEO+=$2}
                         /Numbers of Records recycled out/{NRECRO+=$2}
                         /Numbers of Records filtered out/{NRECFO+=$2}

                         END { 
                           print "FILES"
                           printf ("%14d - %s",INPUTFILE,"Input files\n\n")
                           printf ("%14d - %s",NOERRORS,"No errors in call records\n")
                           if ( FILEPR0!=0 ) {
                              printf ("%14d - %s",FILEPR0,"Files with processed records = 0\n\n")
                           } else {print}
                           if ( SUSPFILE!=0 ) {
                              printf ("%14d - %s",SUSPFILE,"Suspicious Input File\n\n")
                           } else {print}
                           if ( REJECTFILE!=0 ) {
                              printf ("%14d - %s",REJECTFILE,"Rejected input files\n\n")
                           } else {print}

                           if (NMOBOC+NMOBTC!=0) {
                              print "NORTEL CALLS"
                              printf ("%14d - %s",NMOBOC,"Nortel Mobile Originating Call\n")
                              printf ("%14d - %s",NMOBTC,"Nortel Mobile Terminating Call\n")
                              printf ("%14d - %s",NSMSMOC,"Nortel Short Message Service Mobile Originated Call\n")
                              printf ("%14d - %s",NSMSMTC,"Nortel Short Message Service Mobile Terminated Call\n")
                              printf ("%14d - %s",NFTOR,"Nortel File Transfer Out Record\n")
                              printf ("%14d - %s",NTIMEC,"Nortel Time Change\n")
                              printf ("%14d - %s",NSR,"Nortel Switch Restart\n")
                              printf ("%14d - %s",NIGC,"Nortel Incoming Gateway Call\n")
                              printf ("%14d - %s",NOGC,"Nortel Outgoing Gateway Call\n")
                              printf ("%14d - %s",NIIP,"Nortel Incoming Intra-PLMN\n")
                              printf ("%14d - %s",NOIP,"Nortel Outgoing Intra-PLMN\n")
                              printf ("%14d - %s",NTC,"Nortel Transit Call\n")
                              printf ("%14d - %s",NRC,"Nortel Roaming Call\n")
                              printf ("%14d - %s",NCEU,"Nortel Common Equipment Usage\n\n")

                           }   
                           
                           if (DTC+DPC!=0) {
                              print "DAP CALLS"
                              printf ("%14d - %s",DTC,"DAP - Talkgroup Call\n")
                              printf ("%14d - %s",DPC,"DAP - Private Call\n")
                              printf ("%14d - %s",DCA,"DAP - Call Alert\n")
                              printf ("%14d - %s",DEC,"DAP - Emergency Call\n")
                              printf ("%14d - %s",DMS,"DAP - MS Status\n\n")

                           }

                           printf ("%14d - %s",NPROCREC,"Numbers of processed Records\n\n")

                           print "TOTAL OF RECORDS"
                           printf ("%14d - %s",UTXRECGEN,"UTX Records generated\n")
                           printf ("%14d - %s",URGMOC,"     MOCs\n")
                           printf ("%14d - %s",URGMTC,"     MTCs\n")
                           printf ("%14d - %s",URGRCF,"     RCFs\n")
                           printf ("%14d - %s",URGLTL,"     LTLs\n")
                           printf ("%14d - %s",URGEV ,"     EVENTs\n\n")

                          #Alterado para exibir "" quando o valor for 0.
                          #printf ("%14d - %s",UTXRGO,"UTX Records generated out of Call Forwarding\n")
                           if (UTXRGO==0) printf ("%14s - %s","","UTX Records generated out of Call Forwarding\n")
                           else printf ("%14d - %s",UTXRGO,"UTX Records generated out of Call Forwarding\n")
                           printf ("%14d - %s",URGOMOC,"     MOCs\n")
                           printf ("%14d - %s",URGOMTC,"     MTCs\n")
                           printf ("%14d - %s",URGORCF,"     RCFs\n")
                           printf ("%14d - %s",URGOLTL,"     LTLs\n\n")

                           printf ("%14d - %s",UARREC,"UAR Records generated for AIH\n")
                           printf ("%14d - %s",UARMOC,"     MOCs\n")
                           printf ("%14d - %s",UARMTC,"     MTCs\n")
                           printf ("%14d - %s",UARRCF,"     RCFs\n")
                           printf ("%14d - %s",UARLTL,"     LTLs\n\n")

                           printf ("%14d - %s",NRECEO,"Records errored out\n")
                           printf ("%14d - %s",NRECRO,"Records recycled out\n")
                           printf ("%14d - %s",NRECFO,"Records filtered out\n")
                         }'
               
                         TMPDAP=/tmp/dapfile.txt.$$
                         TMPNORTEL=/tmp/thrmfile.txt.$$

                         DATAFILE=$file

                         cat $DATAFILE | 
                         awk -v TEMPDAP=$TMPDAP -v TEMPNORTEL=$TMPNORTEL '
                         {
                         if (match ($0, "Chargeable Unit from input"))
                           line=NR+1;
                         if (NR==line) {
                           if (match ($0, "/DAP")) {
                             ARQSAIDA=TEMPDAP
                             SWITCH="DAP";
                           }
                           else {
                             ARQSAIDA=TEMPNORTEL
                             SWITCH="NORTEL";
                           }
                           printf ("Arquivo:%s\n", $0) > ARQSAIDA; 
                         }
                         if (match ($0, "Earliest Call Date from records")) {
                           split ($0, start, ":") 
                           split (start[2], temp, " ") > ARQSAIDA;
                           split (temp[1], sydm, ".") > ARQSAIDA;
                           printf ("Inicio : %s/%s/%s ", sydm[3], sydm[2], sydm[1]) > ARQSAIDA;
                           printf ("%02d:%02d:%02d\n", temp[2], start[3], start[4]) > ARQSAIDA;
                         }
                         if (match ($0, "Latest Call Date from records")) {
                           split ($0, end, ":") 
                           split (end[2], temp, " ");
                           split (temp[1], eymd, ".");
                           printf ("Termino: %s/%s/%s ", eymd[3], eymd[2], eymd[1]) > ARQSAIDA;
                           printf ("%02d:%02d:%02d\n\n", temp[2], end[3], end[4]) > ARQSAIDA;
                         }
                       }' 
                       
                       datafile=`echo $DATAFILE | awk '{print (substr ($0, match ($0, "FIH.............PRT")))}'`
                       
                       (echo $datafile - COBERTURA DE HORARIO DO RATING - DAP
                        echo ==========================================================
                        echo
                        cat $TMPDAP)  | msg_api2 "I-RATING-FIH-DAP"
                        cat $TMPDAP
                       (echo $datafile - COBERTURA DE HORARIO DO RATING - NORTEL 
                        echo =============================================================
                        echo
                        cat $TMPNORTEL) | msg_api2 "I-RATING-FIH-NORTEL"
                        cat $TMPNORTEL
                       
                       rm -f $TMPDAP $TMPNORTEL
                              
                                  ;;
              ERROR ) # Arquivo de erros
                      # Copia mensagens com prefixo FIH: 
                      # Copia mensagens com prefixo Error
                      # Conta mensagens semelhantes 
                      cat -s $file | grep -e FIH: -e Error \
                      -e "already processed" |
                      grep -v "Error List" > $TMP
                      cat $TMP | sort -u > $TMP1
                      cat $TMP1 | while read x 
                      do AUX=`cat $TMP | grep "$x" | wc -l`
                         printf "%-5s - %s" $AUX "$x"
                         echo
                      done
              ;;
            UNKNOWN ) cat -s $file ;;

        esac ) | tee -a $TMP3 | msg_api2 "$MSG"
#      grep "PROTOCOL FILE" $TMP3
#      if [ $? = 0 ] ; then
#        /amb/eventbin/TRANS_RQT.sh $DESTINO $TMP3
#      fi
   done

[ -f $TMP ] && rm $TMP
[ -f $TMP1 ] && rm $TMP1
[ -f $TMP2 ] && rm $TMP2
[ -f $TMP3 ] && rm $TMP3
/amb/eventbin/FIH_01_01.sh
### /amb/eventbin/consolidacao/OK/FIH_01_01.sh
exit 0
