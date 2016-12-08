#!/bin/ksh 

	# Finalidade	: Encriptar arquivos de CDR.
	# Input		: /aplic/apgp_sp/sched/bscs_roaming/files/rj/??BRANC??????????
	# Output	: SPOAXIS:/transf/rcv
	# Autor		: Marcos de Benedicto 
	# Data		: 05/07/2004

#DIR_WRK="/aplic/apgp_sp/sched/bscs_roaming/files/rj"
DIR_WRK="/apgp_sp/sched/bscs_roaming/files/rj"
##DIR_WRK="/aplic/artx/prod/lausanne/tmp_tapout/rj"
DESTINO="spoaxis1:/transf/rcv"
EMAIL="prod@unix_mail_fwd"

cd ${DIR_WRK}
[ `pwd` != ${DIR_WRK} ] && exit 1

for FILE in `ls ??BRANC??????????`
do

  [ `echo ${FILE} | cut -c1-3` = "TSI" ] && continue

  [ -f ${DIR_WRK}/${FILE}.pgp ] && rm -f ${DIR_WRK}/${FILE}.pgp

  #su - userpgp -c "pgp -e ${DIR_WRK}/${FILE} \"John Morse\""
  #pgp -es ${DIR_WRK}/${FILE} "John Morse" "BRANC & TSI, a new partnership to the future."
  #pgp -c ${DIR_WRK}/${FILE} "BRANC & TSI, a new partnership to the future."

  #if [ $? -ne 0 -o ! -f ${DIR_WRK}/${FILE}.pgp ]
  #then
  #echo "\n\nPGP apresentou erro.\n\n"
  #exit 1
  #else
  #mv ${FILE}.pgp TSI${FILE}.pgp
  mv ${FILE} TSI${FILE}
  [ $? -ne 0 ] && exit 1
  chmod 664 TSI${FILE}
  rm -f ${FILE}
  #fi

done

for TSIFILE in TSI??BRANC??????????
do
  ##. /amb/eventbin/RCP_SEC_TAPOUT.sh ${TSIFILE} ${DESTINO} ${EMAIL} 1 
  . /amb/eventbin/SCP_SEC_TAPOUT.sh ${TSIFILE} ${DESTINO} ${EMAIL} 1 
done

