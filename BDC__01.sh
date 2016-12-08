#!/bin/ksh
## Script      : BDC_02_01.sh
#  Descricao   : Gera arquivo de Clientes no Magnus para carga no Vantive
#  Data        : 23/03/99
#  Autor       : Renato
#
## Mensagens
#M#I-BDC-GERACAO-021 : Sucesso na geracao de arquivo de Clientes no Magnus
#M#E-BDC-GERACAO-022 : Erro na geracao de arquivo de Clientes no Magnus
#M#W-BDC-GERACAO-022 : Falta de Licensa no Magnus na geracao do arquivo
#M#W-BDC-GERACAO-023 : Nenhuma solicitacao de inclusao de Clientes sel Magnus
#M#E-BDC-GERACAO-023 : Erro de infra-estrutura

# Variaveis de ambiente do Progress
export DLC=/opgs_sp/app/dlc
export PATH=$PATH:$DLC/bin
export PROPATH=/apgs_sp/magnus:
export PROTERMCAP=$DLC/protermcap
export PROMSGS=$DLC/promsgs
export TERM=vt100

# Variaveis de trabalho
HORTIM=`date +%Y%m%d.%H%M%S`
DIRPAR=/apgs_sp/magnus
DIRWRK=/apgs_sp/sched/bdc
DIRLOG=$DIRWRK/LOG
ARQLOG=$DIRLOG/bdc_02_01.$HORTIM.log
ARQOUT=$DIRLOG/bdc_02_01.$HORTIM.out
DIRERR=$DIRWRK/ERROR
DIRMSG=$DIRWRK/MSGS
DIRPRO=$DIRWRK/PROCESSED
DIRTMP=$DIRWRK/TMP
ARQUIVO=CM$HORTIM
TMP=/tmp/bdc_02_01.$$

# Alteracao da consolidacao PCORP em 2004/04 - Edison / Workmation
DESTINO=PACOR
###DESTINO=PCORP_SP

# Caso nao exista o filesystem sai com erro de infraestutura
cd $DIRWRK 2>$TMP
if [ $? != 0 ] ; then 
   ( echo "Erro no cd $DIRWRK"; cat $TMP ) | msg_api2 E-INTERFACES-CLIENTES-GERACAO
   rm -f $TMP
   exit 1
fi

# se nao existir subdiretorios, cria
for dir in $DIRLOG $DIRERR $DIRPRO $DIRMSG $DIRTMP
  do [ -d $dir ] && continue
     mkdir $dir 2>$TMP
     if [ $? != 0 ] ; then
        ( echo "Erro na criacao do $dir "; cat $TMP ) | msg_api2 E-INTERFACES-CLIENTES-GERACAO
        rm -f $TMP
        exit 1
     fi
done
rm -f $TMP

# Apaga arquivos dos diretorios de trabalho 
find $DIRLOG -type f -mtime +3 -exec rm -f {} \;
find $DIRERR -type f -mtime +3 -exec rm -f {} \;
find $DIRPRO -type f -mtime +3 -exec rm -f {} \;
find $DIRMSG -type f -mtime +3 -exec rm -f {} \;
find $DIRTMP -type f -mtime +3  -exec rm -f {} \;

# Gera arquivos de parametros para ser passado para o programa
( echo "DiretorioErros=\"$DIRERR\"" 
  echo "NomeArquivo=\"$ARQUIVO\"" 
  echo "DiretorioMapi=\"$DIRMSG\"" 
  echo "DiretorioProcess=\"$DIRPRO\"" 
  echo "DiretorioLeitura=\"$DIRWRK\"" ) > $DIRTMP/$ARQUIVO.param

  echo "Inicio Processamento `date`" > $ARQLOG

#inicio da procedure

$DLC/bin/_progres -pf $DIRPAR/mgadm.pf -U billing -P billing \
                  -pf $DIRPAR/mgind.pf -U billing -P billing \
                  -pf $DIRPAR/mgcom.pf -U billing -P billing \
                  -pf $DIRPAR/mglnk.pf -U billing -P billing \
                  -o "lp -s > /dev/null" -p $DIRPAR/esp/esnx001b.p \
                  -param $DIRTMP/$ARQUIVO.param \
                  -b > $ARQOUT

RC=$?

echo "Termino `date`" >> $ARQLOG

if [ $RC != 0 ] ; then 
   # se falta licensa no magnus envia msg 
   grep "Try a larger -n" $ARQOUT
   if [ $? = 0 ] ; then
      ( echo "Falta de licensa no magnus para geracao de clientes"
        cat $ARQOUT ) | msg_api2 W-INTERFACES-CLIENTES-GERACAO
      exit 1
   fi

   # demais tipo de erro na geracao do arquivo
   ( echo $ARQUIVO " - Erro na geracao do arquivo de Clientes no Magnus"
     cat $ARQLOG ; echo
     cat $ARQUIVO ; echo
     cat $ARQOUT ) | msg_api2 "E-INTERFACES-CLIENTES-GERACAO"
   exit 1
fi

# Arquivo carregado com sucesso
if [ -s $ARQUIVO ] ; then
     ( echo $ARQUIVO "- Arquivo de Clientes gerado com sucesso no Magnus"
       cat $DIRMSG/$ARQUIVO.I-ESNX001-001 ) | msg_api2 "I-INTERFACES-CLIENTES-GERACAO"
       # Gera solicitacao de transferencia para o Vantive
       /amb/eventbin/TRANS_RQT.sh $DESTINO ${ARQUIVO} >$TMP 2>&1
       if [ $? != 0 ]; then
         ( echo $ARQUIVO "- Erro na solicitacao de transferencia "
           cat $ARQOUT ) | msg_api2 "E-INTERFACES-CLIENTES-GERACAO"
       fi
       mv $ARQUIVO $DIRPRO/$ARQUIVO
       gzip -9 $DIRPRO/$ARQUIVO
   else
    ( echo $ARQUIVO "- Nenhuma solicitacao de inclusao de Clientes selecionada "
      cat $DIRMSG/$ARQUIVO.I-ESNX001-001 ) | msg_api2 "W-INTERFACES-CLIENTES-GERACAO"
      rm $ARQUIVO
fi

# Apaga arquivos temporarios e move arquivo para diretorio de processados
rm -f $DIRTMP/$ARQUIVO.param $TMP

exit 0
