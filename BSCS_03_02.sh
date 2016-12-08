#!/bin/ksh
##
# BSCS_03_02.sh : Shutdown dos bancos ORACLE
#
# Bancos: BSCS
#
#Mensagens
#W-ORACLE-004: BSCS shutdown messages

TMP=/tmp/.ora_$$ 

UNAME=`uname -n`

case $UNAME in
       spo* ) SITE=SP;;
       rjo* ) SITE=RJ;;
          * ) exit 1;;
esac

( 
echo "BSCS - shutdown"
# Stop dos processos dos sistemas
  /amb/boot/K09_bscs         

# Stop dos bancos oracle
  /amb/operator/bin/oracle_db shut PBSCS_${SITE}

# Stop dos listeners nao padrao 
if [ -d /pbscs_sp/dat/lost+found ]; then
   export TWO_TASK=PBSCS_SP
   export ORACLE_HOME=`grep ^${TWO_TASK}: /etc/oratab | cut -d: -f2`
   su oracle -c "$ORACLE_HOME/bin/lsnrctl stop"
fi
if [ -d /pbscs_rj/dat/lost+found ]; then
   export TWO_TASK=PBSCS_RJ
   export ORACLE_HOME=`grep ^${TWO_TASK}: /etc/oratab | cut -d: -f2`
   su oracle -c "$ORACLE_HOME/bin/lsnrctl stop LISTENER_02"
   su oracle -c "$ORACLE_HOME/bin/lsnrctl stop"
fi

) </dev/null >$TMP 2>&1

/amb/bin/msg_api "W-ORACLE-004" <$TMP

rm -f $TMP

exit 0

