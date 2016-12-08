#!/bin/ksh
#  Script      : BILLING_05_02.sh
#  Objetivo    : ENVIO DOS ARQS. GERADOS  
#  Descricao   : 
#  Pre-Requis  : 
#  Criticidade : Alta - Se ocorrer Erro acionar Analista Responsavel 
#  Alteracao   : 19/10/02
##


ANO="`date +%Y_%m`"
DIA="`date +%d%m_%H%M%S`"
TMP=/tmp/roaming_1_$$
DT="`date +%d%m%Y%H%M%S`"
FILES_OK="/tmp/files_ok.$DT"
FILES_ER="/tmp/files_er.$DT"
PENDENCIAS="/apgs_sp/magnus/bill/ENVIA/*"
MAIL="reginaldo@unix_mail_fwd"



if [ -f $PENDENCIAS ]
then
touch $PENDENCIAS
chmod 777 $PENDENCIAS
fi

typeset -u -L2 SITE
SITE=SP

#if [ "$SITE" = "SP" ] ; then DESTINO=spoaxap9
#   else DESTINO=rjoaxap3
#fi
# Maquina onde sera executado spliter

DESTINO=spoaxap4

#-------------------------------------------------------------

RC=0
DIRENVIA=/apgs_sp/magnus/bill/ENVIA
DIRENVIADOS=/apgs_sp/magnus/bill/ENVIADOS


# limpeza da area de trabalho
#find $DIRPRO -type f -mtime +2 -exec rm -f {} \;
#find $DIRPRO -type f -ctime +2 -exec rm -f {} \;
#find $DIRERR -type f -mtime +7 -exec rm -f {} \;
#find $DIRERR -type f -ctime +7 -exec rm -f {} \;

# Renomeia todos os arquivos
for file in  
  do [ ! -f $file ] && continue
  newname=`echo $file | cut -d"." -f1,3`
  mv $file $newname
  if [ $? != 0 ]; then
    ( echo "Erro no mv do $file" ; cat $TMP ) | msg_api2 "E-RATING-ROAMING-INFRA_ESTRUTURA"
    echo "Erro no mv do $file" ; cat $TMP 
    rm -f $TMP
    continue
  fi
done

# decripta os arquivos
echo $HOME
echo $PWD
for file in `ls -t CD?????BRANC?????.pgp`
do [ ! -f $file ] && continue
    newfile=`echo $file | cut -c 1-17`
    OPERADORA=`echo $file | cut -c 3-7`
    /amb/eventbin/BSCS_ROAM_04_03.sh $newfile $SITE $OPERADORA

    AUX=${file%.*}  
    [ -f $AUX ] && rm -f $AUX

    export PGPPASSFD=0

pgpv $file << % > $TMP
`echo $PASSWD`
%

    if [ $? != 0 ]
    then
       ( echo "$SITE $OPERADORA $newfile - Erro na decriptacao "
         cat $TMP ) | msg_api2 "E-RATING-ROAMING-DECRIPTACAO_ERRO"
         cat $TMP 
       mv $file $DIRERR/${file}.err
       mv $newfile $DIRERR/${newfile}.err
       RC=2
       echo "$file" >> $FILES_ER
       echo "$file - ERRO" >> $RECEBIDOS
       continue
       else
       echo "$file" >> $FILES_OK
       echo "$file - OK!!" >> $RECEBIDOS
    fi

    rm $file

    # Valida header
    RET=0
    checa_header $newfile
    RET=$?
    if [ $RET != 0 ] ; then
       case $RET in
          1) MSG="Header  - tamanho diferente de 102 bytes"               ;;
          2) MSG="Header  - Duas primeiras posicoes diferente de 10"      ;;
          3) MSG="Header  - Operadora invalida"                           ;;
          4) MSG="Header  - Nao contem BRANC nas posicoes 8 a 12 "        ;;
          *) MSG="Codigo de retorno invalido"                             ;;
       esac
       echo "$SITE $OPERADORA $newfile - Arquivo com erro - $MSG" |\
              msg_api2 "E-RATING-ROAMING-INCONSISTENCIA_ERRO"
       echo "$SITE $OPERADORA $newfile - Arquivo com erro - $MSG" 
       mv $newfile $DIRERR/${newfile}.err
       RC=2
       continue
    fi
    # Valida trailer
    RET=0
    checa_trailer $newfile
    RET=$?
    if [ $RET != 0 ] ; then
       case $RET in
          1) MSG="trailer - tamanho diferente de 80 bytes"                ;;
          2) MSG="Trailer - Duas primeiras posicoes diferente de 90"      ;;
          3) MSG="Trailer - Operadora invalida"                           ;;
          4) MSG="Trailer - Nao contem BRANC nas posicoes 8 a 12 "        ;;
          *) MSG="Codigo de retorno invalido"                             ;;
       esac
       echo "$SITE $OPERADORA $newfile - Arquivo com erro - $MSG" |\
              msg_api2 "E-RATING-ROAMING-INCONSISTENCIA_ERRO"
       mv $newfile $DIRERR/${newfile}.err
       continue
    fi
    total_linhas=`wc -l $newfile | cut -d " " -f 1`
    # Valida Valores de conversao
    RET=0
    if [ $total_linhas -gt 2 ] ; then
      checa_details_ERR $newfile
      RET=$?
      if [ $RET != 0 ] ; then
        case $RET in
           1) MSG="Detail ERR  - Duas primeiras posicoes diferente de 12 - $ERR"
              ;;
           2) MSG="Detail ERR  - Tamanho diferente de 128 - $LENERR"
              ;;
           *) MSG="Codigo de retorno invalido"                             ;;
        esac
        echo "$SITE $OPERADORA $newfile - Arquivo com erro - $MSG" |\
               msg_api2 "E-RATING-ROAMING-INCONSISTENCIA_ERRO"
        mv $newfile $DIRERR/${newfile}.err
        continue
      fi
      # Valida GMT offset da operadora
      RET=0
      checa_details_UTC $newfile
      RET=$?
      if [ $RET != 0 ] ; then
        case $RET in
           1) MSG="Detail UTC  - Duas primeiras posicoes diferente de 14 - $UTC"              ;;
           2) MSG="Detail UTC  - Tamanho diferente de 128 - $LENUTC"
              ;;
           *) MSG="Codigo de retorno invalido"                             ;;
        esac
        echo "$SITE $OPERADORA $newfile - Arquivo com erro - $MSG" |\
               msg_api2 "E-RATING-ROAMING-INCONSISTENCIA_ERRO"
        mv $newfile $DIRERR/${newfile}.err
        continue
      fi
      # Valida detalhamento de chamadas - MOC MTC e MSS
      let LINHA_ATUAL=4
      while (( $LINHA_ATUAL < $total_linhas ))
      do
        sed -n ${LINHA_ATUAL}p $newfile | while read linha
        do
          TIPO=`echo $linha | cut -c 1-2`
          TAMANHO=`sed -n ${LINHA_ATUAL}p $newfile | wc -c`
          case $TIPO in
              20) if [ $TAMANHO != 591 ] ; then
                     MSG="registro MOC com tamanho de $TAMANHO"
                     ( echo "$SITE $OPERADORA $newfile - $MSG "
                       echo $linha ) | msg_api2 "E-RATING-ROAMING-INCONSISTENCIA_ERRO"
                     mv $newfile $DIRERR/${newfile}.err
                     continue 3
                  fi
                  ;;
              30) if [ $TAMANHO != 591 ] ; then
                     MSG="registro MTC com tamanho de $TAMANHO"
                     ( echo "$SITE $OPERADORA $newfile - $MSG "
                       echo $linha ) | msg_api2 "E-RATING-ROAMING-INCONSISTENCIA_ERRO"
                     echo "$SITE $OPERADORA $newfile - "
                       echo $linha  
                     mv $newfile $DIRERR/${newfile}.err
                     continue 3
                  fi
                  ;;
              40) if [ $TAMANHO != 443 ] ; then
                     MSG="registro MSS com tamanho de $TAMANHO"
                     ( echo "$SITE $OPERADORA $newfile - $MSG "
                       echo $linha ) | msg_api2 "E-RATING-ROAMING-INCONSISTENCIA_ERRO"
                     mv $newfile $DIRERR/${newfile}.err
                     continue 3
                  fi
                  ;;
               *) ( echo "$SITE $OPERADORA $newfile - Tipo incorreto : $TIPO"
                    echo $linha ) | msg_api2 "E-RATING-ROAMING-INCONSISTENCIA_ERRO"
                  mv $newfile $DIRERR/${newfile}.err
                  continue 3
            esac
           let LINHA_ATUAL="$LINHA_ATUAL + 1"
         done
       done
    fi
    # Modification Indicator 
    awk '
        {
        tipo=substr($0,1,2)
	if (tipo==20)
	{
		first=substr($0,1,40)
 		modifindfield=sprintf("0")
		last=substr($0,42)
		all=first modifindfield last
		printf("%s\n",all) > "some.txt"
        }
	else
	{
		printf("%s\n",$0) > "some.txt"
	}
	}' $newfile 2>$TMP

    if [ $? != 0 ]; then
       ( echo "$SITE $OPERADORA $newfile - Erro na decriptacao "
         cat $TMP ) | msg_api2 "E-RATING-ROAMING-DECRIPTACAO_ERRO"
         cat $TMP 
       mv $newfile $DIRERR/${newfile}.err
       rm -r $TMP
       continue
    fi
    mv some.txt $newfile 2>$TMP
    if [ $? != 0 ]; then
       ( echo "$SITE $OPERADORA $newfile - Erro ao move arquivo"
         cat $TMP ) | msg_api2 "E-RATING-ROAMING-INFRA_ESTRUTURA"
         cat $TMP 
       mv $newfile $DIRERR/${newfile}.err
       rm -r $TMP
       continue
    fi
    if [ $OPERADORA = "GBRCN" ] ; then
       /amb/bin/cellnet.awk $newfile 2>$TMP
       if [ $? != 0 ]; then
          ( echo "$SITE $OPERADORA $newfile - Erro ao executar cellnet.awk"
            cat $TMP ) | msg_api2 "E-RATING-ROAMING-INFRA_ESTRUTURA"
            cat $TMP 
          mv $newfile $DIRERR/${newfile}.err
          rm -r $TMP
          continue
       fi
    fi
    ( echo "$SITE $OPERADORA $newfile - Sucesso na decriptacao do arquivo "
      cat $TMP ) | msg_api2 "I-RATING-ROAMING-DECRIPTACAO_SUCESSO"

    # Envia arquivos para o servidor spoaxap9 para rodar spliter
    /amb/eventbin/TRANS_RQT.sh $DESTINO $newfile > $TMP
    # su - transf -c  "rcp $newfile $DESTINO:/transf/rcv"

    if [ $? != 0 ]; then
       ( echo "$SITE $OPERADORA $newfile - Erro ao enviar arquivo " 
         cat $TMP ) | msg_api2 "E-RATING-ROAMING-ENVIO_ERRO"
         cat $TMP 
       rm -f $TMP
       continue
    fi
    ( echo "$SITE $OPERADORA $newfile - Sucesso ao enviar arquivo " 
       cat $TMP ) | msg_api2 "I-RATING-ROAMING-ENVIO_SUCESSO"
       cat $TMP 
    mv $newfile $DIRPRO/${newfile}.pro
done

# echo "Entre no Control M e execute o job RUN_IIH_SP!"
# echo "Adicione condicao para que o Job RERA0101 dentro do Grupo TAPIN seja executado!"

if [ $RC != 0 ]
    then
       exit 44
fi 

pendencias
 
rm -f $TMP

exit 0
