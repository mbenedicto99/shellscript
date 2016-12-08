#! /usr/bin/ksh
#
# Script : /amb/eventbin/rerate.sh
# Feito  : Roberto Pires de Carvalho - 03/07/2002
# OBS    : Esse script chama o script de retarifação dos arquivos CD*, antes de
#          passar ao processo de split. Ele gera os arquivos relatorio.rpt,
#          relatorio.log e os arquivos CD*.new. Estes devem ser passados ao 
#          splitter. Os arquivos de entrada são os CD* do diretório local, o
#          mach_countries.txt e o mach_rates.txt.
#

WORK_PL=/abscs_sp/tmp
LOG=/tmp/rerate.out.$$
LOG_ERR=/tmp/rerate.$$.err
FPERL="/amb/scripts/perl/mach_rerate.pl"
DIRWRK="/transf/rcv"
DIRDEST="$WORK_PL"
DIA="`date +%d%m%Y_%H%M%S`"
mkdir -p $WORK_PL/$DIA

cp $DIRWRK/CD* $WORK_PL/$DIA
gzip -f $WORK_PL/$DIA/*

mkdir -p $WORK_PL

cp /amb/scripts/perl/*.txt $WORK_PL

cd $WORK_PL

/usr/contrib/bin/perl5.6.1 $FPERL $DIRWRK $DIRDEST relatorio 1>$LOG 2>$LOG_ERR

if [ "$?" -eq 0 ]
then
echo "Execucao do Perl foi ok!"
/amb/operator/bin/attach_mail rerating@unix_mail_fwd relatorio.rpt Relatorio_do_rerate
/amb/operator/bin/attach_mail rerating@unix_mail_fwd relatorio.log Log_do_rerate
mv $DIRDEST/CD* $DIRWRK
rm $LOG
exit 0
else
echo "Execucao do Perl nao houve Exito !!!"
cat $LOG_ERR
/amb/operator/bin/attach_mail rpires@unix_mail_fwd $LOG_ERR ERRO
/amb/operator/bin/attach_mail rpires@unix_mail_fwd $LOG LOG_EXECUCAO
/amb/operator/bin/attach_mail rpires@unix_mail_fwd relatorio.log Log_do_rerate
rm $LOG_ERR
rm $LOG
exit 1
fi

# Usage: attach_mail [bin] <Destination> <File> <Subject>
/amb/operator/bin/attach_mail rpires@unix_mail_fwd relatorio.rpt Relatorio_do_rerate
/amb/operator/bin/attach_mail rpires@unix_mail_fwd relatorio.log Log_do_rerate
