#!/bin/ksh

	# Finalidade	: Parar/Iniciar Weblogic.
	# Input		: AMB_JAVA_WEBLOGIC_01.sh {stop|start}
	# Output	: Inicio ou termino do processo e checagem de funcionalidade.
	# Alteracao	: Marcos de Benedicto
	# Data		: 06/11/2003

set -A WEBLOGIC ind_0

typeset -u EXEC
EXEC=$1
WEBLHOME=/aweblogic_sp/home/weblogic/weblogic
WEBLDIR=${WEBLHOME}/bin
LOGDIR=${WEBLHOME}/log
PORT=`awk -F= '/^weblogic.system.listenPort/ {print $2}' ${WEBLHOME}/weblogic.properties`
STOPARM=`awk -F= ' /^weblogic.password.system/ {print $2}' ${WEBLHOME}/weblogic.properties`
TM=`date +%Y%m%d%H%M%S`

[ ! -d /aweblogic_sp/lost+found ] && exit

ind_0()
{

	set -x

	case ${EXEC} in

		START) cd ${WEBLHOME}
		. ${WEBLHOME}/setEnv.sh > /dev/null 2>&1
		su weblogic -c "nohup ./sw.sh > ${LOGDIR}/weblogic.start.${TM} 2>&1 &"
		;;


		STOP) cd ${WEBLHOME}
		. ${WEBLHOME}/setEnv.sh > /dev/null 2>&1
		su weblogic -c "java weblogic.Admin t3://localhost:${PORT} SHUTDOWN \
		system ${STOPARM} 1  > ${LOGDIR}/weblogic.stop.${TM} 2>&1 &"
		ps -ef | grep weblogic | grep -v "grep weblogic" | awk '{ print $2 }' | while read pid
		do
		echo "Matando processos pendentes ${pid}"
		kill ${pid}
		done
		;;

		*) echo "Foram passados parametros incorretos."
		exit 1
		;;

	esac
}

${WEBLOGIC[0]}
