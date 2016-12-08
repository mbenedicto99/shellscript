#!/bin/ksh
#
# Alteracao 13/03/02
#

. /etc/appltab

TMP=/tmp/BSCS_BCH$$.tmp
TMP1=/tmp/BSCS_BCH1$$.tmp
TMP2=/tmp/BSCS_BCH2$$.tmp

# ALterado em 2003/08/20 - Edison Santos (Workmation) - Consolidacao MIBAS - BSCS
#===================================================================================#
#### MAQ=`uname -n`
#### case "$MAQ" in
     #### spo*) DIR="/artx_sp/prod/WORK/LOG"
           #### ;;
     #### rjo*) DIR="/artx_rj/prod/WORK/LOG"
           #### ;;
        #### *) echo "ERRO: $MAQ invalido"
           #### exit 1;;
#### esac
#===================================================================================#

DIR="${ENV_DIR_BASE_RTX}/prod/WORK/LOG"

cd $DIR
[ $? != 0 ] && exit 1

find . ! -perm -1 -name "*BCH*" -print | sort |\
while read file
   do case "basename $file" in
       *PBCH*.log) MSG=I-BSCS-BCH-002
                   # Aguardara o termino de todos os pbch
                   PROCID="pbch"
                   FILETYPE="PBCH" 
                   chmod o+x $file
                   ;;  
       *BCH1.*.log) basename $file | awk -F"." '{print $1" "$2}' |
                   read AUX PROCID
                   NBCH=`expr substr $AUX 4 10`
                   if [ $NBCH -lt 10 ]
                      then NUMBCH="00"$NBCH
                      else if [ $NBCH -lt 100 ]
                              then NUMBCH="0"$NBCH
                              else NUMBCH=$NBCH
                           fi
                   fi
                   MSG=I-BSCS-BCH-$NUMBCH
                   FILETYPE="BCH" ;;  
        *BCH*.log) # Ignora outros arquivos de log do BCH que serao
                   # tratados no trecho do BCH1
                   continue 
                   ;;
                *) MSG=W-BSCS-BCH-999
                   PROCID="xYz"
                   FILETYPE="UNKNOWN" 
                   chmod o+x $file
                   ;;  
      esac

      # Verifica se o processo relativo ao arquivo ainda esta no ar
      # Este trecho com file_open ou lsof nao funcionava
      # Alterado para lsof novamente
      #while [ 1 ]
      #   do AUX=`/amb/bin/lsof $file`
      #      [ -z "$AUX" ] && break
      #      sleep 1
      #   done

      ( echo "$file"
        echo 
        echo "BSCS BILL CYCLE HANDLER - \c"
        echo $FILETYPE" LOG FILE"
        echo "                                    "`ll $file | cut -c 46-57` 
        echo "------------------------------------------------"
        echo
        case $FILETYPE in
             PBCH ) # Arquivo de log do controlador do Bill Cycle 
                      if [ ! -s $file ] 
                      then
                         echo "THIS FILE IS ZERO LENGTH"
                      else 
                         cat -s $file |
                         awk -F ":" ' 
   
                            /connected to database/ {print $NF"\n"}
                            /PBCH_FDIST/ {print $NF"\n"}
                            /customer data records loaded/ {print $NF"\n"}
                            /total customers loaded/ {print $NF"\n"}
                            /Started all/ {print $NF"\n";next}
                            /Status/ {
                               printf ("%5s %20s %20s",$5,$6,$7"\n\n")}
                            /Started/ {
                               printf ("%5s %20s %20s",$5,$6,$7"\n")}
                            /has terminated/ {print $NF}
                            /Total run time/ {print "\n"$(NF-1)":"$NF}
   
                            '
                      fi 
                      ;;
            BCH* ) # Arquivo de log especifico do primeiro processo
                    # Baseado neste arquivo e feita uma pesquisa sequencial 
                    # dos outros processo aproveitando o mesmo trecho de codigo
                    # deste programa.

                      FARQ=0
                      FIRSTBCH=0

                      find . ! -perm -1 -name "*BCH*" -print |
                      sort -t "." -k 1,4 |
                      while read arq
                      do  
                         [ $FARQ = 1 -a `expr $arq : ".*BCH1\."` != 0 ] && break
                         [ $arq = $file ] && FARQ=1
                         [ $FARQ = 1 ] && echo $arq
                      done |  
                      while read file
                      do 

                         if [ $FIRSTBCH != 0 ]
                         then
                            basename $file | awk -F"." '{print $1" "$2}' |
                            read AUX PROCID
                            NBCH=`expr substr $AUX 4 10`
                            if [ $NBCH -lt 10 ]
                               then NUMBCH="00"$NBCH
                               else if [ $NBCH -lt 100 ]
                                       then NUMBCH="0"$NBCH
                                       else NUMBCH=$NBCH
                                    fi
                            fi
                            # Verifica se o processo relativo ao arquivo 
                            # ainda esta no ar
                            # Este trecho com file_open ou lsof nao funcionava
                            #while [ 1 ]
                            #   do AUX=`ps -ef | awk '{print $2}' |
                            #      grep -x $PROCID | grep -v grep`
                            #      [ -z "$AUX" ] && break
                            #      sleep 1
                            #   done
                         fi
                         chmod o+x $file

                         if [ ! -s $file ] 
                         then
                            echo "THIS FILE IS ZERO LENGTH"
                         else 
                            if [ $FIRSTBCH = 0 ] 
                            then
                               FIRSTBCH=1

                               cat -s $file |
                               awk 'BEGIN {auxf1=auxf2=0}
                                  /Program version/ {auxf1=1;print;next}
                                  /Billcycle started/ {auxf1=0;print "\n---------------------------------------------------------------\n"}
                                  /Further settling period/ {auxf1=1;print;next}
                                  /Posting-period/ {
                                     auxf1=0
                                     print $0"\n---------------------------------------------------------------"
                                     print "Resumo do arquivo de log - "'"$NUMBCH"'
                                     print "---------------------------------------------------------------\n"
                                  }
                                  /PETTY ERROR/ {auxf2+=1;print;next}
                                  /FATAL ERROR/ {auxf2+=1;print;next}
                                  /TM-code/ {auxf2+=1;print;next}
                                  /SP-code/ {auxf2+=1;print;next}
                                  /SN-code/ {auxf2+=1;print;next}
                                  /seq-no/ {auxf2+=1;print;next}
                                  /VS-code/ {auxf2+=1;print;next}
                                  /Service for/ {auxf2+=1;print;next}
                                  /terminated/ {auxf2=1;print;next}
                                  {  if (auxf1>0 || auxf2>0) print
                                     if (auxf1>0) auxf1+=1 
                                     if (auxf2>0) auxf2+=1 
                                     if (auxf2==4) auxf2=0
                                  }
   
                                  '
                            else
                               # Tratamento para arquivos subsequentes
                               cat -s $file |
                               awk 'BEGIN {auxf1=auxf2=0}
                                  /Posting-period/ {
                                     print "\n---------------------------------------------------------------"
                                     print "Resumo do arquivo de log - "'"$NUMBCH"'
                                     print "---------------------------------------------------------------\n"
                                  }
                                  /PETTY ERROR/ {auxf2=1;print;next}
                                  /FATAL ERROR/ {auxf2=1;print;next}
                                  /TM-code/ {auxf2+=1;print;next}
                                  /SP-code/ {auxf2+=1;print;next}
                                  /SN-code/ {auxf2+=1;print;next}
                                  /seq-no/ {auxf2+=1;print;next}
                                  /VS-code/ {auxf2+=1;print;next}
                                  /Service for/ {auxf2+=1;print;next}
                                  /terminated/ {auxf2=1;print;next}
                                  {  if (auxf1>0 || auxf2>0) print
                                     if (auxf1>0) auxf1+=1 
                                     if (auxf2>0) auxf2+=1 
                                     if (auxf2==4) auxf2=0
                                  }
   
                                  '
                            fi 
                         fi  
                      done
                      ;;
            UNKNOWN  ) cat -s $file ;;
   
        esac )  > $TMP 2>&1
   
        if [ $FILETYPE != "PBCH" -a $FILETYPE != "UNKNOWN" ]  
        then
           cat $TMP | grep -e "callrecords with" -e "Total elapsed time" -e "Number of contracts processed" | 
           awk 'BEGIN {tcall=tclick=ttime=0}
                /callrecords with/{tcall+=$3;tclick+=$6}
                /Total elapsed time/{if (ttime<$4) ttime=$4}
                /Number of contracts processed/{tcproc+=$6}
                END {
                       printf ("%-s","\n---------------------------------------------------------------")
                       printf ("%-30s -> %20d","\nTotal of callrecords",tcall)
                       printf ("%-30s -> %20d","\nTotal of clicks",tclick)
                       printf ("%-30s -> %20d","\nTotal of time (sec)",ttime)
                       printf ("%-30s -> %20d","\nTotal of contracts processed",tcproc)
                       print "\n---------------------------------------------------------------"
                }' > $TMP1
           cat $TMP $TMP1 | msg_api2 "$MSG"
        else
           cat $TMP | msg_api2 "$MSG"
        fi
   
   done

[ -f $TMP ] && rm $TMP
[ -f $TMP1 ] && rm $TMP1

exit 0