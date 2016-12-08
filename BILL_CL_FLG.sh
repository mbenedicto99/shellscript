#!/bin/ksh

	# Finalidade	: Remove Flag de controle do Rating RLH
	# Autor		: Marcos de Benedicto
	# Data		: 31/10/2004

. /etc/appltab


CICLO=$1

	rm -f ${ENV_DIR_BASE_RTX}/prod/WORK/TMP/BILL-CG${CICLO}.flg

exit 0
