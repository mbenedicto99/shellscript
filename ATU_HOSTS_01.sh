#!/usr/bin/ksh
# Script que atualiza o arquivo /etc/hosts com o arquivo /amb/cfg/hosts.padrao
# Leandro - Adm unix
# 10/03/2003

# Variables

file_padrao="/amb/cfg/hosts.padrao"
file_hosts_etc="/etc/hosts"
CP="/usr/bin/cp"

$CP $file_padrao $file_hosts_etc
#$CP /amb/cfg/tztab.padrao /usr/lib/tztab
#$CP /amb/cfg/TIMEZONE.padrao /etc/TIMEZONE
#Ativar somente quando quiser atualizar o horário em todas a máquinas
#/usr/sbin/ntpdate -b PANTP
#[ -f /amb/cfg/.rhosts.padrao ] && cp /amb/cfg/.rhosts.padrao /.rhosts & chmod 664 /.rhosts
#/amb/eventbin/*GETAMB*
#exec /amb/eventbin/coleta_inf_dev.sh
