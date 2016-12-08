#!/bin/ksh
#
# Analise de Log do BSCS_RIH_01.sh
#
# Alteracao 13/06/2002
# Alex da Rocha Lima
#

. /etc/appltab

DATA=`date +%Y%m%d%H%M%S`
DESTINO=spoaxap8
DEST=rating@unix_mail_fwd
SUBJ="Erro no RIH - Rate Plan ou Inclusao de Novo Servico"
cd ~prod/WORK/TMP
[ $? != 0 ] && exit 1
MAQ=$1
case "$MAQ" in
   sp*) TMP3=/tmp/SPRIH${DATA}.txt
         #DIRTMP=/artx_sp/prod/WORK/TMP
         DIRTMP=${ENV_DIR_BASE_RTX}/prod/WORK/TMP
         ;;
   rj*) TMP3=/tmp/RJRIH${DATA}.txt
         #DIRTMP=/artx_rj/prod/WORK/TMP
         DIRTMP=${ENV_DIR_BASE_RTX}/prod/WORK/TMP
         ;;
      *) echo "ERRO: $MAQ invalido"
         exit 1;;
esac

TMP=$DIRTMP/BSCS_RIH$$.tmp
TMP1=$DIRTMP/BSCS_RIH1$$.tmp
TMP2=$DIRTMP/BSCS_RIH2$$.tmp
TMP4=$DIRTMP/BSCS_RIH4$$.tmp
ARQCTR=$DIRTMP/ctr.txt
ARQERR=$DIRTMP/err.txt

# Procura arquivos nao marcados com bit de execucao para other
find . ! -perm -1 -name "RIH*" -print |\
while read file
   do case "$file" in
         *.CTR) MSG=I-RATING-RIH-CONTROLE
                FILETYPE="CONTROL" ;;        
         *.ERR) MSG=E-RATING-RIH-ERRO
                FILETYPE="ERROR" ;;        
             *) MSG=W-RATING-RIH-PROCESSAMENTO
                FILETYPE="UNKNOWN" ;;        
      esac
      # Verifica se o processo relativo ao arquivo ainda esta no ar
      # Este trecho com file_open ou lsof nao funcionava
      AUX=`basename $file | cut -c 4-9`
      PROCID=`expr $AUX + 0`
      while [ 1 ]
         do AUX=`/amb/bin/lsof $file`  
            [ -z "$AUX" ] && break
            sleep 3
         done
      # Marca arquivo com bit de execucao para other
      chmod o+x $file
      ( echo "$file"
        echo 
        echo "BSCS RATE INPUT HANDLER - \c"
        echo $FILETYPE" FILE"
        echo "                                    "`ll $file | cut -c 46-57` 
        echo "------------------------------------------------"
        echo
        case $FILETYPE in
            CONTROL ) # Arquivo de CONTROL LIST 
                      cat -s $file |
                      awk -F ":" 'BEGIN {  
                         UTXFILES=0
                         FLAGFILE=""
                         TNRCHU=TNRRFCHU=TNRUDC=TNRRA=TNRRI=TNRRE=TNRUEC=0
                         TNRRCHU=TNNRRCHU=TNRTXRW=0
                         TUTXRBC=TRTXRBC=TUTXRDD=TRTXRDD=TUTXRV=TRTXRV=0
                         TUTXRS=TRTXRS=0

                         }

                         /UTX: UTX/ {if (FLAGFILE!=$2) {
                            FLAGFILE=$2
                            UTXFILES+=1
                            }
                         }


                         /No errors in call records/ {NOERRORS+=1}

                         /Numbers of processed Records/{NPROCREC+=$2
                            if ($2==0) FILEPR0+=1 }

                         /Number of RTX records to  Bill Cycle 01/ { bc01+=$2 
                                                                   totreg+=$2}
                         /Number of RTX records to  Bill Cycle 02/ { bc02+=$2
                                                                   totreg+=$2}
                         /Number of RTX records to  Bill Cycle 03/ { bc03+=$2
                                                                   totreg+=$2}
                         /Number of RTX records to  Bill Cycle 04/ { bc04+=$2
                                                                   totreg+=$2}
                         /Number of RTX records to  Bill Cycle 05/ { bc05+=$2
                                                                   totreg+=$2}
                         /Number of RTX records to  Bill Cycle 06/ { bc06+=$2
                                                                   totreg+=$2}
                         /Number of RTX records to  Bill Cycle 07/ { bc07+=$2
                                                                   totreg+=$2}
                         /Number of RTX records to  Bill Cycle 08/ { bc08+=$2
                                                                   totreg+=$2}
                         /Number of RTX records to  Bill Cycle 11/ { bc11+=$2
                                                                   totreg+=$2}
                         /Number of RTX records to  Bill Cycle 12/ { bc12+=$2
                                                                   totreg+=$2}
                         /Number of RTX records to  Bill Cycle 13/ { bc13+=$2
                                                                   totreg+=$2}
                         /Number of RTX records to  Bill Cycle 14/ { bc14+=$2
                                                                   totreg+=$2} 

                         /Number of UTX records for Bill Cycle 01/ { ubc01+=$2 
                                                                   utotreg+=$2}
                         /Number of UTX records for Bill Cycle 02/ { ubc02+=$2
                                                                   utotreg+=$2}
                         /Number of UTX records for Bill Cycle 03/ { ubc03+=$2
                                                                   utotreg+=$2}
                         /Number of UTX records for Bill Cycle 04/ { ubc04+=$2
                                                                   utotreg+=$2}
                         /Number of UTX records for Bill Cycle 05/ { ubc05+=$2
                                                                   utotreg+=$2}
                         /Number of UTX records for Bill Cycle 06/ { ubc06+=$2
                                                                   utotreg+=$2}
                         /Number of UTX records for Bill Cycle 07/ { ubc07+=$2
                                                                   utotreg+=$2}
                         /Number of UTX records for Bill Cycle 08/ { ubc08+=$2
                                                                   utotreg+=$2}
                         /Number of UTX records for Bill Cycle 11/ { ubc11+=$2
                                                                   utotreg+=$2}
                         /Number of UTX records for Bill Cycle 12/ { ubc12+=$2
                                                                   utotreg+=$2}
                         /Number of UTX records for Bill Cycle 13/ { ubc13+=$2
                                                                   utotreg+=$2}
                         /Number of UTX records for Bill Cycle 14/ { ubc14+=$2
                                                                   utotreg+=$2}

                         /Number of RTX records for VPLMN subscribers/ { rv+=$2
                                                                    totreg+=$2}

                         /Number of UTX records for VPLMN subscribers/ { uv+=$2
                                                                   utotreg+=$2}

                         / For such reasons completely unrated/ { fsrcu+=$2}

                         END { 
                           print "FILES"
                           printf ("%14d - %s",UTXFILES,"Input files\n\n")
                           printf ("%14d - %s",NOERRORS,"No errors in call records\n")
                           printf ("%14d - %s",UARLTL,"     LTLs\n\n")

                           printf ("%14d - %s",NRECEO,"Records errored out\n")
                           printf ("%14d - %s",NRECRO,"Records recycled out\n")
                           printf ("%14d - %s",NRECFO,"Records filtered out\n\n")

                           printf ("%14d - %s",bc01,"Number of RTX records to  Bill Cycle 01\n")
                           printf ("%14d - %s",bc02,"Number of RTX records to  Bill Cycle 02\n")
                           printf ("%14d - %s",bc03,"Number of RTX records to  Bill Cycle 03\n")
                           printf ("%14d - %s",bc04,"Number of RTX records to  Bill Cycle 04\n")
                           printf ("%14d - %s",bc05,"Number of RTX records to  Bill Cycle 05\n")
                           printf ("%14d - %s",bc06,"Number of RTX records to  Bill Cycle 06\n")
                           printf ("%14d - %s",bc07,"Number of RTX records to  Bill Cycle 07\n")
                           printf ("%14d - %s",bc08,"Number of RTX records to  Bill Cycle 08\n")
                           printf ("%14d - %s",bc11,"Number of RTX records to  Bill Cycle 11\n")
                           printf ("%14d - %s",bc12,"Number of RTX records to  Bill Cycle 12\n")
                           printf ("%14d - %s",bc13,"Number of RTX records to  Bill Cycle 13\n")
                           printf ("%14d - %s",bc14,"Number of RTX records to  Bill Cycle 14\n")
                           printf ("%14d - %s",rv,"Number of RTX records for VPLMN subscribers\n")
                           printf ("%14d - %s",totreg,"Total de registros RTX gerados\n\n")

                           printf ("%14d - %s",ubc01,"Number of UTX records for  Bill Cycle 01\n")
                           printf ("%14d - %s",ubc02,"Number of UTX records for  Bill Cycle 02\n")
                           printf ("%14d - %s",ubc03,"Number of UTX records for  Bill Cycle 03\n")
                           printf ("%14d - %s",ubc04,"Number of UTX records for  Bill Cycle 04\n")
                           printf ("%14d - %s",ubc05,"Number of UTX records for  Bill Cycle 05\n")
                           printf ("%14d - %s",ubc06,"Number of UTX records for  Bill Cycle 06\n")
                           printf ("%14d - %s",ubc07,"Number of UTX records for  Bill Cycle 07\n")
                           printf ("%14d - %s",ubc08,"Number of UTX records for  Bill Cycle 08\n") 
                           printf ("%14d - %s",ubc11,"Number of UTX records for  Bill Cycle 11\n")
                           printf ("%14d - %s",ubc12,"Number of UTX records for  Bill Cycle 12\n")
                           printf ("%14d - %s",ubc13,"Number of UTX records for  Bill Cycle 13\n")
                           printf ("%14d - %s",ubc14,"Number of UTX records for  Bill Cycle 14\n") 

                           printf ("%14d - %s",uv,"Number of UTX records for VPLMN subscribers\n")
                           printf ("%14d - %s",utotreg,"Total de registros UTX lidos\n\n")

                           printf ("%14d - %s",fsrcu,"For such reasons completely unrated\n\n")
                         }'
       
           ;;
              ERROR ) # Arquivo de erros
                      echo
                      #grep "found in ISDEFTAB but not in CODEFTAB" $file > $TMP4
                      #if [ -s $TMP4 ] ; then
                      #  /amb/operator/bin/attach_mail $DEST $TMP4 $SUBJ
                      #  rm -f $TMP4
                      #fi
                      /amb/operator/bin/bscs_chk_rih $file
                      ### /amb/eventbin/consolidacao/OK/bscs_chk_rih $file
                      RC=2
              ;;
            UNKNOWN ) cat -s $file ;;

        esac ) | tee $TMP3 | msg_api2 "$MSG"
        if [ $FILETYPE = "CONTROL" ] ; then
          mv $TMP3 $ARQCTR
        fi
        if [ $FILETYPE = "ERROR" ] ; then
          mv $TMP3 $ARQERR
        fi
   done

cat $ARQERR >  $TMP3
cat $ARQCTR >> $TMP3

rm -f $TMP $TMP1 $TMP2 $TMP3 $ARQCTR

exit 0
