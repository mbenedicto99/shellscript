#!/bin/ksh
## BDC_17_01.sh: Gera arquivo de Tabela de precos no Magnus p/ cargo no Vantive
#
# Data: 09/06/99
#
## Mensagens
#M#I-INTERFACES-TABELA_PRECOS-GERACAO : Sucesso na geracao de arquivo de Tabela de precos no Magnus
#M#E-INTERFACES-TABELA_PRECOS-GERACAO : Erro na geracao de arquivo de Tabela de precos no Magnus
#M#W-INTERFACES-TABELA_PRECOS-GERACAO : Falta de Licensa no Magnus na geracao de arquivo de tab. precos
#M#W-INTERFACES-TABELA_PRECOS-GERACAO : Nenhuma solicitacao de inclusao de Tabela de precos no Magnus
#M#E-INTERFACES-TABELA_PRECOS-GERACAO : Erro de infra-estrutura

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
ARQUIVO=TP$HORTIM
ARQLOG=$DIRLOG/bdc_17_01.$HORTIM.log
ARQOUT=$DIRLOG/bdc_17_01.$HORTIM.out
TMP=/tmp/bdc_17_01.$$

# alteracao em 2004/04 - Edison / Workmation - Consolidacao PCORP
DESTINO=PACOR
## DESTINO=PCORP_SP

# Caso nao exista o filesystem sai com erro de infraestutura
cd $DIRWRK 2>$TMP
if [ $? != 0 ] ; then 
   ( echo "Erro no cd $DIRWRK"; cat $TMP ) | msg_api2 "E-INTERFACES-TABELA_PRECOS-GERACAO"
   rm -f $TMP
   exit 1
fi

# se nao existir subdiretorios, cria
for dir in $DIRLOG $DIRERR $DIRPRO $DIRMSG $DIRTMP
  do [ -d $dir ] && continue
     mkdir $dir 2>$TMP
     if [ $? != 0 ] ; then
        ( echo "Erro na criacao do $dir "; cat $TMP ) | msg_api2 "E-INTERFACES-TABELA_PRECOS-GERACAO"
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
                  -o "lp -s > /dev/null" -p $DIRPAR/esp/esnx005b.p \
                  -param $DIRTMP/$ARQUIVO.param \
                  -b > $ARQOUT

RC=$?

echo "Termino `date`" >> $ARQLOG

if [ $RC != 0 ] ; then 
   # se falta licensa no magnus envia msg 
   grep "Try a larger -n" $ARQOUT
   if [ $? = 0 ] ; then
      ( echo "Falta de licensa no magnus para geracao do arquivo"
        cat $ARQOUT ) | msg_api2 "W-INTERFACES-TABELA_PRECOS-GERACAO"
      rm -f $DIRTMP/$ARQUIVO.param 
      exit 1
   fi

   # demais tipo de erro na geracao do arquivo
   ( echo $ARQUIVO " - Erro na geracao do arquivo de Tabela de Precos"
     cat $ARQLOG ; echo
     cat $ARQUIVO ; echo
     cat $ARQOUT ) | msg_api2 "E-INTERFACES-TABELA_PRECOS-GERACAO"
   rm -f $DIRTMP/$ARQUIVO.param 
   exit 1
fi

# Arquivo carregado com sucesso
if [ -s $ARQUIVO ] ; then
   ( echo $ARQUIVO "- Arquivo de Tabela de precos gerado com sucesso "
     cat $DIRMSG/$ARQUIVO.I-ESNX005-001 ) | msg_api2 "I-INTERFACES-TABELA_PRECOS-GERACAO"
   # Gera solicitacao de transferencia para o Vantive
   /amb/eventbin/TRANS_RQT.sh $DESTINO ${ARQUIVO} >$TMP 2>&1
   if [ $? != 0 ]; then
       ( echo $ARQUIVO "- Erro na solicitacao de transferencia "
          cat $TMP ) | msg_api2 "E-INTERFACES-TABELA_PRECOS-GERACAO"
   fi
   mv $ARQUIVO $DIRPRO/$ARQUIVO
   gzip -9 $DIRPRO/$ARQUIVO

   else
     ( echo $ARQUIVO "- Nenhum arquivo Gerado"
       cat $ARQOUT ) | msg_api2 "W-INTERFACES-TABELA_PRECOS-GERACAO"
     rm -f $DIRTMP/$ARQUIVO.param $ARQUIVO $ARQOUT
fi

# Apaga arquivos temporarios e move arquivo para diretorio de processados
rm -f $DIRTMP/$ARQUIVO.param $TMP

exit 0
