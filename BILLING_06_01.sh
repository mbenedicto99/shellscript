#! /usr/bin/ksh
#
# Script     : /amb/eventbin/BILLING_06_01.sh
# Criacao    : 10/02/2003
# Modificado : Nao ha
# Feito      : Alex da Rocha Lima - Analista de Implantacao/Control M
# Descricao  : Efetua o envio de email para a lista endbill@unix_mail_fwd informando
#              o termino dos processo de Billing em execucao.
#              A lista e composta pelos grupos e pessoas abaixo:
#              - Billing_List
#              - Revenue_List
#              - Produção_List
#              - Carlos Tadeu da Cunha
#

#------------------------------------
# Definicao do parametro para o ciclo
#------------------------------------

BILL=$1

#------------------------------
# Rotina para o envio de e-mail
#------------------------------

rot_mail()
{
echo "Subject: Termino do Billing para o Ciclo - ${BILL} - `date +%d/%m/%Y` " >> mail1.$$
echo "From: billing@`hostname`.nextel.com.br" >> mail1.$$
echo "Concluído com sucesso todo o processo de Billing para o ciclo ${BILL} \n" >> mail1.$$
cat mail.$$ >> mail1.$$
mv mail1.$$ mail.$$
cat mail.$$ | sendmail endbill@unix_mail_fwd

#---------------------------------
# Limpeza dos arquivos temporarios
#---------------------------------

rm arq.$$ 2> /dev/null
rm file.$$ 2> /dev/null
rm file_prod.$$ 2> /dev/null
rm mail.$$ 2> /dev/null

exit $?
}

#--------------------------------
# Chama rotina de envio de e-mail
#--------------------------------

rot_mail

exit 0
