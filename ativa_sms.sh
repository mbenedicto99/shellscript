#!/usr/bin/ksh

# 

dir_sms="/amb/local/sms"

if [ ! -d ${dir_sms}/contigencia ]; then 
 mkdir -p ${dir_sms}/contigencia
 /amb/boot/S01_alias
else
 /amb/boot/S01_alias
fi
/etc/mail/atualiza
/opt/apache/bin/apachectl start
