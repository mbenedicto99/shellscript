#!/bin/ksh
## BDC_15_01.sh: Gera arquivo de produtos e servicos no Magnus para o Vantive
#
# Data: 21/05/99
#
## Mensagens
#M#I-INTERFACES-PRODUTOS-GERACAO : Sucesso na geracao de arquivo de produtos
#M#E-INTERFACES-PRODUTOS-GERACAO : Erro na geracao de arquivo de produtos
#M#W-INTERFACES-PRODUTOS-GERACAO : Falta de Licensa no Magnus 
#M#W-INTERFACES-PRODUTOS-GERACAO : Nenhum arquivo gerado
#M#E-INTERFACES-PRODUTOS-GERACAO : Erro de infra-estrutura

# Variaveis de ambiente do Progress
export DLC=/opgs_sp/app/dlc
export PATH=$PATH:$DLC/bin
export PROPATH=/apgs_sp/magnus:
export PROTERMCAP=$DLC/protermcap
export PROMSGS=$DLC/promsgs
export TERM=vt100

# Variaveis de trabalho
DIRPAR=/apgs_sp/magnus
DIRWRK=/apgs_sp/sched/bdc
DIRLOG=$DIRWRK/LOG
DIRERR=$DIRWRK/ERROR
DIRMSG=$DIRWRK/MSGS
DIRPRO=$DIRWRK/PROCESSED
DIRTMP=$DIRWRK/TMP
HORTIM=`date +%Y%m%d.%H%M%S`
ARQUIVO=PS$HORTIM
ARQLOG=$DIRLOG/bdc_15_01.$HORTIM.log
ARQOUT=$DIRLOG/bdc_15_01.$HORTIM.out
TMP=/tmp/bdc_12_01.$$

# Alteracao - Consolidacao PCORP - Edison / Workmation / 2004-04
DESTINO=PACOR
## DESTINO=PCORP_SP

# Caso nao exista o filesystem sai com erro de infraestutura
cd $DIRWRK 2>$TMP
if [ $? != 0 ] ; then 
   ( echo "Erro no cd $DIRWRK"; cat $TMP ) | msg_api2 "E-INTERFACES-PRODUTOS-GERACAO"
   rm -f $TMP
   exit 1
fi

# se nao existir subdiretorios, cria
for dir in $DIRLOG $DIRERR $DIRPRO $DIRMSG $DIRTMP
  do [ -d $dir ] && continue
     mkdir $dir 2>$TMP
     if [ $? != 0 ] ; then
        ( echo "Erro na criacao do $dir "; cat $TMP ) | msg_api2 "E-INTERFACES-PRODUTOS-GERACAO"
        rm -f $TMP
        exit 1
     fi
done
rm -f $TMP

# Apaga arquivos dos diretorios de trabalho 
find $DIRLOG -type f -ctime +5 -exec rm -f {} \;
find $DIRERR -type f -ctime +5 -exec rm -f {} \;
find $DIRPRO -type f -ctime +5 -exec rm -f {} \;
find $DIRMSG -type f -ctime +5 -exec rm -f {} \;
find $DIRTMP -type f -ctime +5  -exec rm -f {} \;

# Gera arquivos de parametros para ser passado para o programa
( echo "DiretorioErros=\"$DIRERR\"" 
  echo "NomeArquivo=\"$ARQUIVO\"" 
  echo "DiretorioMapi=\"$DIRMSG\"" 
  echo "DiretorioProcess=\"$DIRPRO\"" 
  echo "DiretorioLeitura=\"$DIRWRK\"" ) > $DIRTMP/$ARQUIVO.param

  echo "Inicio Processamento `date`" > $ARQLOG

#inicio da procedure

$DLC/bin/_progres -pf $DIRPAR/mgadm.pf -U sched -P sched \
                  -pf $DIRPAR/mgind.pf -U sched -P sched \
                  -pf $DIRPAR/mgcom.pf -U sched -P sched \
                  -pf $DIRPAR/mglnk.pf -U sched -P sched \
                  -o "lp -s > /dev/null" -p $DIRPAR/esp/esnx004b.p \
                  -param $DIRTMP/$ARQUIVO.param \
                  -b > $ARQOUT

RC=$?

echo "Termino `date`" >> $ARQLOG

if [ $RC != 0 ] ; then 
   # se falta licensa no magnus envia msg 
   grep "Try a larger -n" $ARQOUT
   if [ $? = 0 ] ; then
      ( echo "Falta de licensa no magnus para geracao do arquivo"
        cat $ARQOUT ) | msg_api2 "W-INTERFACES-PRODUTOS-GERACAO"
      rm -f $DIRTMP/$ARQUIVO.param 
      exit 1
   fi

   # demais tipo de erro na geracao do arquivo
   ( echo $ARQUIVO " - Erro na geracao do arquivo de Produtos e Servicos"
     cat $ARQLOG ; echo
     cat $ARQUIVO ; echo
     cat $ARQOUT ) | msg_api2 "E-INTERFACES-PRODUTOS-GERACAO"
   rm -f $DIRTMP/$ARQUIVO.param
   exit 1
fi

# Arquivo carregado com sucesso
if [ -s $ARQUIVO ]
   then
       ( echo $ARQUIVO "- Arquivo de produtos e servicos gerado com sucesso "
         cat $DIRMSG/$ARQUIVO.I-ESNX004-001 ) | msg_api2 "I-INTERFACES-PRODUTOS-GERACAO"
       # Gera solicitacao de transferencia para o Vantive
       /amb/eventbin/TRANS_RQT.sh $DESTINO ${ARQUIVO} >$TMP 2>&1
       if [ $? != 0 ]; then
          ( echo $ARQUIVO "- Erro na solicitacao de transferencia "
            cat $TMP ) | msg_api2 "E-INTERFACES-PRODUTOS-GERACAO"
       fi
       mv $ARQUIVO $DIRPRO/$ARQUIVO
       gzip -9 $DIRPRO/$ARQUIVO  
    
   else
      ( echo $ARQUIVO "- Nenhuma solicitacao de inclusao de Produtos e Servicos"
      cat $ARQOUT ) | msg_api2 "W-INTERFACES-PRODUTOS-GERACAO"
      rm -f $DIRTMP/$ARQUIVO.param $ARQUIVO $ARQOUT
fi

# Apaga arquivos temporarios e move arquivo para diretorio de processados
rm -f $DIRTMP/$ARQUIVO.param $ARQOUT $TMP
if [ $? != 0 ]
    then
    	echo "- ERRO ao remover arquivos temporarios ou ao mover arquivo para diretorio de processados"
        exit 1
fi
