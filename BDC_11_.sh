#!/bin/ksh
## BDC_11_02.sh: Carga de clientes no magnus 
#
# Data: 18/12/98
# Alterado : 02/02/99 Renato / Andrea
# Alterado : 12/03/99 Renato 
#
## Mensagens
#M#I-BDC-CARGA-116 : Sucesso na carga de clientes no magnus
#M#E-BDC-CARGA-117 : Erro na carga de clientes no magnus
#M#W-BDC-CARGA-117 : Inconsistencia na carga de clientes no magnus
#M#W-BDC-CARGA-118 : Carga de clientes nao executada por falta de licensa no magnus
#M#E-BDC-CARGA-119 : Erro de infra-estrutura

# Variaveis de ambiente do Progress
DLC=/opgs_sp/app/dlc;export DLC
export PATH=$PATH:$DLC/bin
PROPATH=/apgs_sp/magnus;export PROPATH
PROMSGS=$DLC/promsgs;export PROMSGS
export PROTERMCAP=$DLC/protermcap
export TERM=vt100

# Variaveis de trabalho
#PAR1=/apgs_sp/magnus/report
DIRPAR=/apgs_sp/magnus
DIRWRK=/apgs_sp/sched/bdc
DIRLOG=$DIRWRK/LOG
DIRERR=$DIRWRK/ERROR
DIRMSG=$DIRWRK/MSGS
DIRPRO=$DIRWRK/PROCESSED
DIRTMP=$DIRWRK/TMP
TMP=/tmp/bdc_11_02_$$.txt
HORTIM=`date +%Y%m%d.%H%M%S`
ARQREJ=$DIRWRK/TMP/clientes_nao_carregados.$HORTIM
USERMAIL="eduardo.sena@nextel.com.br "
SUBJ="Falta de licensas no Magnus para carga de Clientes" 
DEST_MAIL=interface_VantiveXMagnus@unix_mail_fwd

# Caso nao exista o filesystem sai com erro de infraestutura
cd $DIRWRK 2>$TMP
if [ $? != 0 ] ; then 
   ( echo "Erro no cd $DIRWRK"; cat $TMP ) | msg_api2 "E-INTERFACES-CLIENTES-CARGA"
   echo "Erro no cd $DIRWRK"; cat $TMP 
   rm -f $TMP
   exit 1
fi

# se nao existir subdiretorios, cria
for dir in $DIRLOG $DIRERR $DIRPRO $DIRMSG $DIRTMP
  do [ -d $dir ] && continue
     mkdir $dir 2>$TMP
     if [ $? != 0 ] ; then
        ( echo "Erro na criacao do $dir "; cat $TMP ) | msg_api2 "E-INTERFACES-CLIENTES-CARGA"
        echo "Erro na criacao do $dir "; cat $TMP 
        rm -f $TMP
        exit 1
     fi
done

# Apaga arquivos dos diretorios de trabalho 

find $DIRLOG -type f -ctime +3 -exec rm -f {} \;
find $DIRLOG -type f -mtime +3 -exec rm -f {} \;
find $DIRERR -type f -ctime +3 -exec rm -f {} \;
find $DIRERR -type f -mtime +3 -exec rm -f {} \;
find $DIRPRO -type f -ctime +3 -exec rm -f {} \;
find $DIRPRO -type f -mtime +3 -exec rm -f {} \;
find $DIRMSG -type f -ctime +3 -exec rm -f {} \;
find $DIRMSG -type f -mtime +3 -exec rm -f {} \;
find $DIRTMP -type f -ctime +3 -exec rm -f {} \;
find $DIRTMP -type f -mtime +3 -exec rm -f {} \;

# le todos os arquivos transferidos da area transf
for file in CV????????.?????? 
    do [ ! -f $file ] && continue

       # Gera arquivos de parametros para ser passado para o programa
       ( echo "DiretorioErros=\"$DIRERR\"" 
         echo "NomeArquivo=\"$file\"" 
         echo "DiretorioMapi=\"$DIRMSG\"" 
         echo "DiretorioProcess=\"$DIRPRO\"" 
         echo "DiretorioLeitura=\"$DIRWRK\"" ) > $DIRTMP/$file.param

       echo "Inicio Processamento `date`" > $DIRLOG/bdc_11_02.$HORTIM.log
       echo "Inicio Processamento `date`" 

       #cd $DIRPAR #???

       #inicio da procedure
       $DLC/bin/_progres -pf $DIRPAR/mgadm.pf -U billing -P billing \
                         -pf $DIRPAR/mgind.pf -U billing -P billing \
                         -pf $DIRPAR/mgcom.pf -U billing -P billing \
                         -pf $DIRPAR/mglnk.pf -U billing -P billing \
                         -o "lp -s > /dev/null" -p $DIRPAR/esp/esnx002b.p \
                         -param $DIRTMP/$file.param \
                         -b > $DIRLOG/esnx002b_$HORTIM.out

       RC=$?

       echo "Termino `date`" >> $DIRLOG/bdc_11_02.$HORTIM.log
       echo "Termino `date`" 

       if [ $RC != 0 ] ; then 
          # se falta licensa no magnus envia msg e continua com proximo arquivo
          grep "Try a larger -n" $DIRLOG/esnx002b_$HORTIM.out
          if [ $? = 0 ] ; then
	     ( echo Arquivo: $file; cat $file; echo ) >> $ARQREJ
	     continue 
          fi
          # demais tipo de erro na carga do arquivo
	  ( echo $file - Erro na carga do arquivo
            cat $DIRLOG/bdc_11_02.$HORTIM.log ; echo
            cat $file; echo
            cat $DIRLOG/esnx002b_$HORTIM.out ) | msg_api2 "E-INTERFACES-CLIENTES-CARGA"
	   echo $file - Erro na carga do arquivo
           cat $DIRLOG/bdc_11_02.$HORTIM.log ; echo
           SUB="Erro na interface de clientes Vantive X Magnus"
           /amb/operator/bin/attach_mail $DEST_MAIL $TMP $SUB
	   continue
       fi

       # se nao ha arquivo de parametros envia msg de erro e continua processo
       if [ -a $DIRMSG/$file.E-ESNX002-001 ] ; then 
          ( echo $file "- Clientes rejeitados na carga no Magnus"
            cat $DIRMSG/$file.I-ESNX002-001; echo 
            cat $DIRMSG/$file.E-ESNX002-001 ) | msg_api2 "W-INTERFACES-CLIENTES-CARGA"
           echo $file "- Clientes rejeitados na carga no Magnus"
           cat $DIRMSG/$file.I-ESNX002-001
          mv $file $DIRPRO/$file
          gzip -9 $DIRPRO/$file
          continue
       fi

       # Arquivo carregado com sucesso
       if [ -a $DIRMSG/$file.I-ESNX002-001 ] ; then
          ( echo $file "- Arquivo de clientes carregado com sucesso"
            cat $DIRMSG/$file.I-ESNX002-001 ) | msg_api2 "I-INTERFACES-CLIENTES-CARGA"
           echo $file "- Arquivo de clientes carregado com sucesso"
           cat $DIRMSG/$file.I-ESNX002-001 
       fi

       # Apaga arquivos temporarios e move arquivo para diretorio de processados
       if [ -f "$file" ]; then
         mv $file $DIRPRO/$file
         gzip -9 $DIRPRO/$file
       fi
       rm -f $DIRTMP/$file.param
    done

    if [ -s $ARQREJ ]; then
       ( echo "Falta de licensa no magnus para carga de clientes"
         cat $ARQREJ ) | msg_api "W-BDC-CARGA-118"
        echo "Falta de licensa no magnus para carga de clientes"
        cat $ARQREJ 
        /amb/operator/bin/attach_mail "$USERMAIL" $ARQREJ $SUBJ >$TMP 2>&1
        if [ $? != 0 ]; then
           ( echo "Erro enviando mail"; cat $TMP ) | msg_api "E-INTERFACES-CLIENTES-CARGA"
           echo "Erro enviando mail"; cat $TMP 
           rm -f $TMP $ARQREJ
           exit 1
        fi
    fi
rm -f $ARQREJ $TMP
exit 0
