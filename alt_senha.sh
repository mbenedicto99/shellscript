#!/usr/bin/ksh
# Script que altera senha - evitando que se altere a senha do user id 0 por engano.
# Elaborado por Leandro - Adm Unix
# em 18/09/2003
# Rev.0
#
#
PASS_COM="/usr/bin/passwd_off_not_remove"
PAR="$*"
USER=`echo "$LOGNAME"`
PASS_FILE="/etc/passwd"

if [ $# -lt 1 ]; then
  echo "\n`tput smso`Changing Password $USER`tput rmso`\n" 
  $PASS_COM $USER
  [ ! $? -eq 0 ] && echo "`tput smso`\nPassword not changed`tput rmso`\n"  && exit 1
  echo "`tput smso`\nPassword for $USER successfully changed`tput rmso`\n"  
else
  [ `cat $PASS_FILE | awk -F: '{ print $1 }' | grep ${PAR} | \
  wc -l` -eq 0 ] && echo "\n`tput smso`User not exist`tput rmso`\n"  && exit 1
  echo ""
  echo "\n`tput smso`Changing Password for $PAR`tput rmso`\n"
  $PASS_COM $PAR
  ret=$?
  [ ! $ret -eq 0 ] && echo "\n`tput smso`Password not changed`tput rmso`\n"  && exit 1
  echo "`tput smso`\nPassword for $PAR changed with Success`tput rmso`\n" 
  exit 0
fi
