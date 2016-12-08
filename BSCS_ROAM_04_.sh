#!/bin/ksh
##
# BSCS_ROAM_04_02.sh
#
# Decriptacao dos arquivos de Roaming Internacional
#
#M#E-RATING-ROAMING-INFRA_ESTRUTURA         : Erro de infra-estrutura
#M#I-RATING-ROAMING-DECRIPTACAO_SUCESSO     : Arquivo decriptado com sucesso
#M#E-RATING-ROAMING-DECRIPTACAO_ERRO        : Erro na decriptacao do arquivo
#M#I-RATING-ROAMING-ENVIO_SUCESSO           : Arquivo enviado com sucesso
#M#E-RATING-ROAMING-ENVIO_ERRO              : Erro no envio do arquivo
#M#E-RATING-ROAMING-INCONSISTENCIA_ERRO     : Arquivo inconsistente
#
# Alex da Rocha Lima - Analista de Implantacao / Control-M
#
# 04/07/2002
#
# Alteracao em 03/FEV/2003,
# por Sinclair Iyama - International Roaming (TADIG):
#
# Adaptacao da rotina, para suporte 'a nova DCH, TSI:
#   - Removida a rotina de renomeacao do arquivo .pgp;
#   - Nova senha para a chave da TSI;
#   - Nova sintaxe para o comando pgpv.
#

# Definicao de variaveis:
#export HOME=/aplic/apgp_sp/sched/bscs_roaming
export HOME=/apgp_sp/sched/bscs_roaming
#export PATH=$PATH/:/aplic/apgp_sp/bin
export PATH=$PATH/:/apgp_sp/bin
export PGPPASSFD=0

typeset -u -L2 SITE
SITE=$1


DESTINO=$2

DIRWRK=/aplic/apgp_sp/sched/bscs_roaming/IN/files/${SITE}
DIRPRO=${DIRWRK}/PROCESSADOS
DIRERR=${DIRWRK}/ERROR
DIRPGP=${DIRWRK}/PGP

PASSWD=`cat /aplic/apgp_sp/sched/bscs_roaming/IN/.pss_tsi`

ANO="`date +%Y_%m`"
DIA="`date +%d%m_%H%M%S`"
TMP=/tmp/roaming_1_$$
DT="`date +%d%m%Y%H%M%S`"
FILES_OK="/tmp/files_ok.$DT"
FILES_ER="/tmp/files_er.$DT"

mkdir -p /sql_rels_`hostname`/roaming/${ANO}
chmod -R 777 /sql_rels_`hostname` 2> /dev/null
RECEBIDOS="/sql_rels_`hostname`/roaming/${ANO}/RECEBIDOS_$DIA.txt"
PENDENCIAS="/sql_rels_`hostname`/roaming/PENDENCIAS.TXT"

MAIL="roaming2@unix_mail_fwd"
MAIL_01="roaming21@unix_mail_fwd"

# Codigo de retorno do script: 0 (no minimo, um arquivo OK) ou 1 (falha em todos os arquivos):
RC=1

LOG_DATE=`date +%d%m%Y`
LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"
LOG_TIME="/aplic/artx/prod/reports/TAPIN_${LOG_DATE}.txt"

printf "%s\t%s\t%s\t%s\n" "TAPIN_04_02" "Inicio do processamento." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}

# ------------------------------------
# Verificacao do arquivo de Pendencias:
# ------------------------------------
if [ -f $PENDENCIAS ]
then
    touch $PENDENCIAS
    chmod 777 $PENDENCIAS
fi

# ---------------------------------
# Declaracao da funcao "pendencias":
# ---------------------------------
pendencias()
{

#
# Faz verificacao de arquivos OK com o Arquivo de Pendencias
# Caso o arquivo OK esteja na lista de pendencias, ele e' 
# removido
#

if [ -f "$FILES_OK" ]
then
   cat $FILES_OK | while read x
   do
      conf="`grep $x $PENDENCIAS | wc -l`"
      conf="`echo $conf`"
      echo "$x - $conf"

      if [ "$conf" -gt 0 ]
      then
         cat $PENDENCIAS | grep -v $x > atmp.$$
         mv atmp.$$ $PENDENCIAS
      fi
   done
else
   MSG1="Nao foi Gerada Lista de Arquivos com Sucesso na Decriptacao !!!"
   echo "ERRO - $MSG1"
   exit 1
fi

#
# Faz verificacao de Arquivos de ERRO com o Arquivo de Pendencias.
# Caso o arquivo de ERRO nao esteja na lista de PENDENCIAS, ele e'
# automaticamente incluso na mesma, e um e-mail ao final e' enviado
# para os responsaveis
# PS : Caso a lista de PENDENCIAS esteja vazia, e' emitido e-mail
#      para todos da listas e menos para a DCH (TSI).
#

if [ -f "$FILES_ER" ]
then
   cat $FILES_ER | while read x
      do
         conf="`grep $x $PENDENCIAS | wc -l`"
         conf="`echo $conf`"

         if [ "$conf" -gt 0 ]
         then
            echo "Ja esta na lista" > /dev/null
         else
            echo "$x" >> $PENDENCIAS
         fi
      done
fi

sort $PENDENCIAS > atmp.$$
mv atmp.$$ $PENDENCIAS
# cp $PENDENCIAS /amb/local/roaming/${ANO}/PENDENCIAS_$DIA.TXT
cp -p $PENDENCIAS /sql_rels_`hostname`/roaming/${ANO}/PENDENCIAS_$DIA.TXT

conf="`cat $PENDENCIAS | wc -l`"
# conf"`echo $conf`"

if [ "$conf" -ne 0 ]
then

# Mandando E-mail para o Grupo de Roaming:
# Este mail avisa todos, incluindo suporte da Data Clearinghouse,
# sobre as pendencias de arquivos encriptados (PGP) para reenvio.

   echo "Subject: Nextel Brazil - TAPin files with Decription Error !!! - `date +%m/%d/%Y`" > /tmp/mail.$$
   echo "From: i_roam_list@nextel.com.br" >> /tmp/mail.$$
   echo "Dear colleagues:\n" >> /tmp/mail.$$
   echo "Decription errors occurred during TAPIN receive/decript process." >> /tmp/mail.$$
   echo "The files are:\n" >> /tmp/mail.$$
   cat $PENDENCIAS >> /tmp/mail.$$
   echo "\nTo the Data Clearinghouse support team: Please, resend us them as soon as you can. Thanks a lot in advance.\n" >> /tmp/mail.$$
   echo "--" >> /tmp/mail.$$
   echo "Best regards," >> /tmp/mail.$$
   echo "Nextel Brazil Intl Roaming Team" >> /tmp/mail.$$
   echo "i_roam_list@nextel.com.br" >> /tmp/mail.$$

   cat /tmp/mail.$$ | /usr/sbin/sendmail $MAIL

   rm /tmp/mail.$$
fi

}

# --------------------------------------------------------------------------
# Declaracao e codificacao das funcoes utilizadas no tratamento dos arquivos:
# --------------------------------------------------------------------------
checa_header () {
  LENG_HEADER=`head -n 1 $1 | wc -c`
  [ $LENG_HEADER != "102" ] && return 1

  TIPO=`head -n 1 $1 | cut -c 1-2`
  [ $TIPO != "10" ] && return 2

  OPER=`head -n 1 $1 | cut -c 3-7`
  [ $OPER != "$OPERADORA" ] && return 3

  DEST=`head -n 1 $1 | cut -c 8-12`
  [ $DEST != "BRANC" ] && return 4

  return 0
}

checa_trailer () {
  LENG_TRAILER=`tail -n 1 $1 | wc -c`
  [ $LENG_TRAILER != "80" ] && return 1

  TIPO=`tail -n 1 $1 | cut -c 1-2`
  [ $TIPO != "90" ] && return 2

  OPER=`tail -n 1 $1 | cut -c 3-7`
  [ $OPER != "$OPERADORA" ] && return 3

  DEST=`tail -n 1 $1 | cut -c 8-12`
  [ $DEST != "BRANC" ] && return 4

  return 0
}

checa_details_ERR () {
  ERR=`head -n 2 $1 | tail -n 1 | cut -c 1-2 `
  [ "$ERR" != "12" ] && return 1
  LENERR=`head -n 2 $1 | tail -n 1 | wc -c`
  [ "$LENERR" -ne 128 ] && return 2
  return 0
}

checa_details_UTC () {
  UTC=`head -n 3 $1 | tail -n 1 | cut -c 1-2 `
  [ "$UTC" != "14" ] && return 1
  LENUTC=`head -n 3 $1 | tail -n 1 | wc -c`
  [ "$LENUTC" -ne 98 ] && return 2
  return 0
}

# ----------------------------------------------------------
# Verificacao da estrutura - diretorio de trabalho ${DIRWRK}:
# ----------------------------------------------------------
cd $DIRWRK 2>${TMP}
	
	if [ `pwd` != $DIRWRK ]
	then
	cat ${TMP}
	exit 1
	fi

# -----------------------------------------
# Decriptacao e Tratamento do arquivo TAPin:
# -----------------------------------------

# Limpeza da area de trabalho:
find $DIRPRO -type f -mtime +360 -exec rm -f {} \;
find $DIRPRO -type f -ctime +360 -exec rm -f {} \;
find /tmp -name roaming_1_\* -type f -ctime +3 -exec rm -f {} \;
#find $DIRERR -type f -mtime +7 -exec rm -f {} \;
#find $DIRERR -type f -ctime +7 -exec rm -f {} \;

# Decripta os arquivos:
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

cd $DIRWRK
[ `pwd` != $DIRWRK ] && exit 1

if [ `hostname` = spoaxap8 ]
then
#   pgpv -z "${PASSWD}" -o ${newfile} ${file} > $TMP
    pgpv -o ${newfile} ${file} << % > $TMP
`echo ${PASSWD}`
%
RC_PGP=$?
else
	if [ ! -f "${newfile}" ] 
	then
	#su - userpgp -c "pgp -z\"${PASSWD}\" ${file}"
	pgp -o ${newfile} ${file} << % > $TMP
`echo ${PASSWD}`
%
	RC_PGP=$?
	else
	echo "Arquivo ${file} ja foi decriptado."
	RC_PGP=0
	fi
fi

    if [ ${RC_PGP} -ne 0 ]
    then
       echo "$file" >> $FILES_ER
       echo "$file - ERRO" >> $RECEBIDOS
       continue
    else
       echo "$file" >> $FILES_OK
       echo "$file - OK!!" >> $RECEBIDOS
       mv ${file} ${DIRPGP}/${file}
    fi


#-------------------------------------------------------------
# Inicio do Tratamento do arquivo TAPin decriptado com sucesso:
#-------------------------------------------------------------

# -----------------------------------------------
# Validacao do cabecalho (HEADER - LINHA TIPO 10):
# -----------------------------------------------
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
       echo "$SITE $OPERADORA $newfile - Arquivo com erro - $MSG" 
       mv $newfile $DIRERR/${newfile}.err
# Insere arquivo na lista de erros:
       echo "$file" >> $FILES_ER
#      RC=2
       continue
    fi

# ---------------------------------------------
# Validacao do rodape (TRAILER - LINHA TIPO 90):
# ---------------------------------------------
    RET=0
    checa_trailer $newfile
    RET=$?
    if [ $RET != 0 ] ; then
       case $RET in
          1) MSG="trailer - tamanho diferente de 80 bytes"                ;;
          2) MSG="Trailer - Duas primeiras posicoes diferentes de 90"     ;;
          3) MSG="Trailer - Operadora invalida"                           ;;
          4) MSG="Trailer - Nao contem BRANC nas posicoes 8 a 12 "        ;;
          *) MSG="Codigo de retorno invalido"                             ;;
       esac
       mv $newfile $DIRERR/${newfile}.err
# Insere arquivo na lista de erros:
       echo "$file" >> $FILES_ER
       continue
    fi

# -------------------------------------------------------------------
# Validacao dos valores de conversao (EXCHANGE RATES - LINHA TIPO 12):
# -------------------------------------------------------------------
    RET=0
    total_linhas=`wc -l $newfile | cut -d " " -f 1`
    if [ $total_linhas -gt 2 ] ; then
       checa_details_ERR $newfile
       RET=$?
       if [ $RET != 0 ] ; then
          case $RET in
             1) MSG="Detail ERR  - Duas primeiras posicoes diferente de 12 - $ERR";;
             2) MSG="Detail ERR  - Tamanho diferente de 128 - $LENERR";;
             *) MSG="Codigo de retorno invalido";;
       esac
       mv $newfile $DIRERR/${newfile}.err
# Insere arquivo na lista de erros:
       echo "$file" >> $FILES_ER
       continue
    fi

# ----------------------------------------------------------------------
# Validacao do GMT offset da operadora (UTC Time Offset - LINHA TIPO 14):
# ----------------------------------------------------------------------
    RET=0
    checa_details_UTC $newfile
    RET=$?
    if [ $RET != 0 ] ; then
       case $RET in
          1) MSG="Detail UTC  - Duas primeiras posicoes diferente de 14 - $UTC";;
          2) MSG="Detail UTC  - Tamanho diferente de 128 - $LENUTC";;
          *) MSG="Codigo de retorno invalido";;
       esac
       mv $newfile $DIRERR/${newfile}.err
# Insere arquivo na lista de erros:
       echo "$file" >> $FILES_ER
       continue
    fi

# ------------------------------------------------------------------------------------
# Validacao do detalhamento de chamadas - MOC (TIPO 20), MTC (TIPO 30) e MSS (TIPO 40):
# ------------------------------------------------------------------------------------
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
                     mv $newfile $DIRERR/${newfile}.err
# Insere arquivo na lista de erros:
                     echo "$file" >> $FILES_ER
                     continue 3
                  fi
                  ;;
              30) if [ $TAMANHO != 591 ] ; then
                     MSG="registro MTC com tamanho de $TAMANHO"
                     echo "$SITE $OPERADORA $newfile - "
                       echo $linha  
                     mv $newfile $DIRERR/${newfile}.err
# Insere arquivo na lista de erros:
                     echo "$file" >> $FILES_ER
                     continue 3
                  fi
                  ;;
              40) if [ $TAMANHO != 443 ] ; then
                     MSG="registro MSS com tamanho de $TAMANHO"
                     mv $newfile $DIRERR/${newfile}.err
# Insere arquivo na lista de erros:
                     echo "$file" >> $FILES_ER
                     continue 3
                  fi
                  ;;
               *)
                     mv $newfile $DIRERR/${newfile}.err
# Insere arquivo na lista de erros:
                     echo "$file" >> $FILES_ER
                     continue 3
                  ;;
          esac
          let LINHA_ATUAL="$LINHA_ATUAL + 1"
       done
    done
    fi

# ----------------------
# Modification Indicator:
# ----------------------
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
         cat $TMP 
       mv $newfile $DIRERR/${newfile}.err
# Insere arquivo na lista de erros:
       echo "$file" >> $FILES_ER
       rm -f ${TMP}
       continue
    fi

    mv some.txt $newfile 2>$TMP
    if [ $? != 0 ]; then
         cat ${TMP}
       mv $newfile $DIRERR/${newfile}.err
# Insere arquivo na lista de erros:
       echo "$file" >> $FILES_ER
       rm -r ${TMP}
       continue
    fi

# -------------------------------------------------------------------
# Tratamento especial - Arquivos da GBRCN (02 Inglaterra, ex-CELLNET):
# -------------------------------------------------------------------
    if [ $OPERADORA = "GBRCN" ] ; then
       /amb/bin/cellnet.awk $newfile 2>$TMP
       if [ $? != 0 ]; then
          mv $newfile $DIRERR/${newfile}.err
          rm -r ${TMP}
          continue
       fi
    fi

# -------------------------------------------
# Envio de mensagem de sucesso na decriptacao:
# -------------------------------------------

# ---------------------------------------
# Envia arquivos para o servidor spoaxap9:
# ---------------------------------------
    #/amb/eventbin/TRANS_RQT.sh $DESTINO $newfile > $TMP

    if [ `hostname` = spoaxap2 ]
    then
     su - transf -c "rcp ${DIRWRK}/${newfile} ${DESTINO}:/transf/rcv"
    else
     cp ${DIRWRK}/${newfile} /transf/rcv
     fi

    if [ $? != 0 ]; then
         cat ${TMP}
       rm -f ${TMP}
       continue
    fi
       cat $TMP 
#   mv $newfile $DIRPRO/${newfile}.pro
    gzip -9vf $newfile
    mv ${newfile}.gz $DIRPRO/${newfile}.gz

    # Ao menos um arquivos foi bem sucedido no processo de decriptacao, job continua e passa condicao ao proximo:
    RC=0
done

# ------------------------------------
# Verificacao do arquivo de Pendencias:
# ------------------------------------

# A funcao "pendencias" verifica os arquivos pendentes e  envia um e-mail 'a DCH (TSI), requisitando reenvio dos arquivos com erro.
pendencias

LOC_TIME1="`date +%d/%m/%Y`"
LOC_TIME2="`date +%H:%M:%S`"

printf "%s\t%s\t%s\n" "TAPIN_04_02" "Termino do processamento." "${LOC_TIME1}" "${LOC_TIME2}" >>${LOG_TIME}
 
# --------------------------
# Limpeza da area temporaria:
# --------------------------
rm -f ${TMP}

exit ${RC}
