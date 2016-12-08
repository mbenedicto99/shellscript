#!/bin/ksh

	# Finalidade : Comprimir diretorios BGH com arquivos de Billing e enviar conteudo para SPOAX004.
	# Input : Arquivos de BGH
	# Output : SPOAX004:/pinvoice
	# Autor : Marcos de Benedicto
	# Data : 09/06/2003

set -A PACK env_pack send_file chk_file unpack_file env_flag

SITE=`echo $1 | tr '[a-z]' '[A-Z]'`
CICLO="$2"
ANO=`date +%Y`
MES=`date +%m`
DIR_VAR=`cat /pinvoice/diretorios/${SITE} | cut -c 1-15`
DIR_OUT="/pinvoice/${DIR_VAR}/data/${SITE}/${CICLO}/${ANO}/${MES}"
DIR_LOC="/pinvoice"
DIR_DEST="/pinvoice"
DEST="spoax004:${DIR_DEST}"
EMAIL=prod@unix_mail_fwd

	[ `hostname` = spoax004 ] && exit 0

env_pack()
{

	set -vx
	tar cvf ${DIR_LOC}/${DIR_VAR}.tar ${DIR_LOC}/${DIR_VAR} >/tmp/pack_err.$$

	if [ $? -ne 0 -o ! -f ${DIR_LOC}/${DIR_VAR}.tar ]

	then
	cat /tmp/pack_err.$$ >/tmp/mail_$$
	echo "
	+------------------------------------------------------
	|
	|   ERRO! `date` 
	|   TAR nao executou corretamente!
	|   Verificar se servidor tem espaco suficiente.
	|
	+------------------------------------------------------\n" | tee -a /tmp/mail_$$
	[ `uname` = SunOS ] && df -k | grep "100%" | tee -a /tmp/mail_$$ || bdf | grep "100%" | tee -a /tmp/mail_$$
	[ `grep -c "100%" /tmp/mail_$$` -eq 0 ] || echo "FILESYSTEM EM 100%!!!!" | tee -a /tmp/mail_$$
	cat /tmp/mail_$$ | mailx -s "BGH - Processo de TAR nos arquivos apresentou problema." ${EMAIL}
	rm -f /tmp/*$$ 
	exit 1
	fi

	gzip -9 ${DIR_LOC}/${DIR_VAR}.tar >/tmp/gz_err.$$ 2>&1

	if [ $? -ne 0 -o ! -f ${DIR_LOC}/${DIR_VAR}.tar.gz ]

	then
	cat /tmp/gz_err.$$ >/tmp/mail_$$
	echo "
	+--------------------------------------------------
	|
	|   ERRO! `date` 
	|   Arquivo GZ nao foi criado.
	|   Verificar se servidor tem espaco suficiente.
	|
	+--------------------------------------------------\n" | tee -a /tmp/mail_$$
	[ `uname` = SunOS ] && df -k | grep "100%" | tee -a /tmp/mail_$$ || bdf | grep "100%" | tee -a /tmp/mail_$$
	[ `grep -c "100%" /tmp/mail_$$` -eq 0 ] || echo "FILESYSTEM EM 100%!!!!" | tee -a /tmp/mail_$$
	cat /tmp/mail_$$ | mailx -s "BGH - Processo de GZIP no arquivo apresentou problema." ${EMAIL}
	rm -f /tmp/*$$
	exit 1
	fi
}

send_file()
{

	set -x 

	su transf -c "rcp ${DIR_LOC}/${DIR_VAR}.tar.gz ${DEST}" >/tmp/rcp_err.$$ 2>&1

	if [ $? -ne 0 ]

	then
	cat /tmp/rcp_err.$$ >/tmp/mail_$$
	echo "
	+----------------------------------------------------------
	|
	|   ERRO! `date` 
	|   Arquivo nao foi transferido corretamente.
	|
	+----------------------------------------------------------\n" | tee -a /tmp/mail_$$
	cat /tmp/mail_$$ | mailx -s "BGH - RCP nao funcionou corretamente." ${EMAIL}
	rm -f /tmp/*$$
	exit 1
	fi
}

chk_file()
{
	set -vx
	su transf -c "remsh spoax004 ls -la ${DIR_DEST}/${DIR_VAR}.tar.gz" >/tmp/flag_$$ 2>&1

	R_ARQ=`cat /tmp/flag_$$ | awk '{print $5}'`
	L_ARQ=`ls -al ${DIR_LOC}/${DIR_VAR}.tar.gz | awk '{print $5}'`

	TOT_CHK=`expr ${L_ARQ} - ${R_ARQ}`

	if [ ${TOT_CHK} -eq 0 ]

	then
	echo "\nArquivo local igual a arquivo remoto."
	echo "Limpando arquivo local.\n"
	rm -f ${DIR_LOC}/${DIR_VAR}.tar.gz ${DIR_LOC}/${DIR_VAR}.tar ${DIR_LOC}/${DIR_VAR} /tmp/*$$*

	else
	cat /tmp/flag_$$ >/tmp/mail_$$
	echo "
	+-------------------------------------------------------------
	|
	|   ERRO! 
	|   `date`
	|   Arquivo local e diferente do arquivo remoto.
	|
	+-------------------------------------------------------------\n" | tee -a /tmp/mail_$$
	cat /tmp/mail_$$ | mailx -s "BGH - Validacao do RCP apresentou erro." ${EMAIL}
	rm -f /tmp/*$$
	exit 1
	fi
}

unpack_file()
{
	set -vx
	su transf -c "remsh spoax004 gunzip ${DIR_DEST}/${DIR_VAR}.tar.gz" >/tmp/remsh_err$$ 2>&1

	if [ $? -ne 0 ]

	then
	cat /tmp/remsh_err$$ >/tmp/mail_$$
	echo "
	+-----------------------------------------------------------------
	|
	|   ERRO! 
	|   `date`
	|   Descompressao no arquivo remoto apresentou problema.
	|
	+-----------------------------------------------------------------\n" | tee -a /tmp/mail_$$
	cat /tmp/mail_$$ | mailx -s "BGH - Erro na descompressao do arquivo remoto." ${EMAIL}
	rm -f /tmp/*$$
	exit 1
	fi

	su transf -c "remsh spoax004 tar xvf ${DIR_DEST}/${DIR_VAR}.tar" >/tmp/remsh_err$$ 2>&1

	if [ $? -ne 0 -o `grep -c "^tar:" /tmp/remsh_err$$` -ne 0 ]

	then
	cat /tmp/remsh_err$$ >/tmp/mail_$$
	echo "
	+--------------------------------------------------
	|
	|   ERRO! 
	|   `date`
	|   TAR do arquivo remoto apresentou problema.
	|
	+--------------------------------------------------\n" | tee -a /tmp/mail_$$
	cat /tmp/mail_$$ | mailx -s "BGH - Erro no TAR do arquivo remoto." ${EMAIL}
	rm -f /tmp/remsh_err$$ /tmp/pack_err.$$ /tmp/mail_$$
	exit 1
	fi

        [ `hostname` != spoax004 -a -n "${DIR_VAR}" ] && rm -R /pinvoice/${DIR_VAR}

	su transf -c "remsh spoax004 rm -f ${DIR_DEST}/${DIR_VAR}.tar"

}

env_flag()
{

	set -x

	rcp /pinvoice/diretorios/${SITE} spoax004:/pinvoice/diretorios/${SITE}

	if [ $? -ne 0 ]

	then
	echo "
	+------------------------------------------------------
	|
	|   ERRO!
	|   `date`
	|   Arquivo de FLAG nao foi enviado para SPOAX004.
	|   
	|   Conteudo = ${DIR_VAR}
	|
	+------------------------------------------------------\n" | tee -a /tmp/mail_$$
	cat /tmp/mail_$$ | mailx -s "BGH - Erro no envio do FLAG" ${EMAIL}
	exit 1
	fi

}

${PACK[0]}
${PACK[1]}
${PACK[2]}
${PACK[3]}
${PACK[4]}

#End Shell

