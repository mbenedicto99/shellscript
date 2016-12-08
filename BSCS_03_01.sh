#!/bin/ksh
##
# BSCS_03_01.sh : Startup dos bancos ORACLE
#
# Bancos: BSCS
#
#Mensagens
#I-ORACLE-004: BSCS startup messages

TMP=/tmp/.ora_$$

UNAME=`uname -n`

case $UNAME in
       spo* ) SITE=SP;;
       rjo* ) SITE=RJ;;
          * ) exit 1;;
esac 

(
echo "BSCS - startup"
# Startup dos Listener
if [ -d /pbscs_sp/dat/lost+found ]; then
   export TWO_TASK=PBSCS_SP
   export ORACLE_HOME=`grep ^${TWO_TASK}: /etc/oratab | cut -d: -f2`
   nice -n -10 su oracle -c "${ORACLE_HOME}/bin/lsnrctl start"
fi
if [ -d /pbscs_rj/dat/lost+found ]; then
   export TWO_TASK=PBSCS_RJ
   export ORACLE_HOME=`grep ^${TWO_TASK}: /etc/oratab | cut -d: -f2`
   nice -n -10 su oracle -c "$ORACLE_HOME/bin/lsnrctl start"
   nice -n -10 su oracle -c "$ORACLE_HOME/bin/lsnrctl start LISTENER_02"
fi
# Startup dos bancos
  /amb/operator/bin/oracle_db start PBSCS_${SITE}

# Startup dos processos das aplicacoes  
  /amb/boot/S91_bscs          

) </dev/null >$TMP 2>&1

/amb/bin/msg_api "I-ORACLE-004" <$TMP

rm -f $TMP

exit 0
