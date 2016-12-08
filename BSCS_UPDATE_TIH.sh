#!/bin/ksh

	set -x

	mv /amb/eventbin/BSCS_TIH_GER.sh /amb/eventbin/BSCS_TIH_GER.sh.bkp
	mv /amb/eventbin/BSCS_TIH_GER.sh-novo /amb/eventbin/BSCS_TIH_GER.sh

	chmod 775 /amb/eventbin/BSCS_TIH_GER.sh
	chown root:implant /amb/eventbin/BSCS_TIH_GER.sh
