#!/bin/ksh
#
# Analise de Log do BSCS_RLH_01.sh
#
# Alteracao 06/03/02
#
#

. /etc/appltab

DATA=`date +%Y%m%d%H%M%S`
TMP=/tmp/BSCS_RLH$$.tmp
TMP1=/tmp/BSCS_RLH1$$.tmp
TMP2=/tmp/BSCS_RLH2$$.tmp
DESTINO=spoaxap8

# Alterado para rodar com eventos
#MAQ=`uname -n`
## case "$MAQ" in
##    spo*) DIR="/artx_sp/prod/WORK/TMP"
##          TMP3=/tmp/SPRLH${DATA}.txt
##          ;;
##   rjo*) DIR="/artx_rj/prod/WORK/TMP"
##         TMP3=/tmp/RJRLH${DATA}.txt
##         ;;
##      *) echo "ERRO: $MAQ invalido"
##         exit 1;;
##esac

SITE="${ENV_VAR_SITE}"
DIR=${ENV_DIR_BASE_RTX}/prod/WORK/TMP

[ "${SITE}" = "SP" ] && TMP3=/tmp/SPRLH${DATA}.txt || TMP3=/tmp/RJRLH${DATA}.txt

cd $DIR
[ $? != 0 ] && exit 1

find . ! -perm -1 -name "RLH*" -print |\
while read file
   do case "$file" in
         *.PRT) MSG=I-RATING-RLH-PROTOCOLO
                FILETYPE="PROTOCOL" ;;  
         *.CTR) MSG=I-RATING-RLH-CONTROLE
                FILETYPE="CONTROL" ;;  
         *.ERR) MSG=E-RATING-RLH-ERRO
                FILETYPE="ERROR" ;;  
             *) MSG=W-RATING-RLH-UNKNOWN
                FILETYPE="UNKNOWN" ;;  
      esac

      # Verifica se o processo relativo ao arquivo ainda esta no ar
      # Este trecho com file_open ou lsof nao funcionava
      AUX=`basename $file | cut -c 18-23`
      PROCID=`expr $AUX + 0`
      #while [ 1 ]
      #   do AUX=`/amb/bin/lsof $file`
      #      if [ -z "$AUX" ] 
      #        then break
      #      fi
      #      sleep 3
      #   done
      chmod o+x $file

      HR=`grep "BSCS MP: RLH Control List" $file | awk '{ print $9 }' | tail -1`

      ( echo "$file"
        echo 
        echo "BSCS RATE LOAD HANDLER - \c"
        echo $FILETYPE" FILE"
        #echo "                                    "`ll $file | cut -c 46-57` 
        echo "                                    "$HR
        echo "------------------------------------------------"
        echo
        case $FILETYPE in
            PROTOCOL ) # Arquivo de CONTROL LIST 
                      if [ ! -s $file ] 
                      then
                         echo "THIS FILE IS ZERO LENGTH"
                      else 
                         cat -s $file |
                         awk -F ":" 'BEGIN {  
                            RTXFILES=0
                            NRECLFRTX=NRECLTLT=NRECLTST=NRECREJ=NRECSUP=0
                            NDETCUS=NDETCDCC=NDETCPCC=0 
   
                            }
   
                            /^Reading all RTX/ { bc=substr($1,65,9) }
                            /Process file/ {RTXFILES+=1}
   
                            /records loaded from/{NRECLFRTX+=$2}
                            /records loaded in table RTX_LT/{NRECLTLT+=$2}
                            /records loaded in table RTX_PREPAY/{NRECLTPP+=$2}
                            /records loaded in table RTX_ST/{NRECLTST+=$2}
                            /Number of rejected records/{NRECREJ+=$2}
                            /Number of suppressed records/{NRECSUP+=$2}
                            /Number of detected customer/{NDETCUS+=$2}
                            /contracts in daily credit check/{NDETCDCC+=$2}
                            /contracts in periodic credit check/{NDETCPCC+=$2}
   
   
                            END { 
                              if (RTXFILES+NRECLFRTX+NRECREJ+NRECSUP+NDETCUS+NDETCDCC+NDETCPCC!=0) {
                                 printf ("%s : %s\n","Bill Cycle",bc)
                                 printf ("%14d - %s",RTXFILES,"Processed files\n\n")
                                 printf ("%14d - %s",NRECLFRTX,"Records loaded from RTX files\n")
                                 printf ("%14d - %s",NRECLTLT,"Records loaded in table RTX_LT\n")
                                 printf ("%14d - %s",NRECLTPP,"Records loaded in table RTX_PREPAY\n")
                                 printf ("%14d - %s",NRECLTST,"Records loaded in table RTX_ST\n")
                                 printf ("%14d - %s",NRECREJ,"Rejected records\n")
                                 printf ("%14d - %s",NRECSUP,"Suppressed records\n")
                                 printf ("%14d - %s",NDETCUS,"Detecteed customers\n")
                                 printf ("%14d - %s",NDETCDCC,"Detected contracts in daily credit check\n")
                                 printf ("%14d - %s",NDETCPCC,"Detected contracts in periodic credit check\n")
                               } else print "THIS FILE DO NOT CONTAINS ANY DATA"
                            }'
                      fi 
           ;;
             CONTROL ) cat -s $file ;;
               ERROR ) cat -s $file ;;
            UNKNOWN  ) cat -s $file ;;
   
        esac ) > $TMP3
        cat $TMP3 | msg_api2 "$MSG"
        #msg_api.mail "$MSG" < $TMP3

        if [ $FILETYPE = "PROTOCOL" ] ; then
          grep -q "THIS FILE IS ZERO LENGTH" $TMP3
          if [ $? != 0 ] 
             then
             grep -q "THIS FILE DO NOT CONTAINS ANY DATA" $TMP3
             if [ $? != 0 ] ; then
              /amb/eventbin/RLH_01_01.sh $file
              ### /amb/eventbin/consolidacao/OK/RLH_01_01.sh $file
             fi
          fi
        fi
        rm $TMP3

   done

exit 0

