#!/bin/ksh 
#   Programa: BSCS_ROAM_03_01.sh - Envia os arquivos a Connect Enterprise - SPOAXIS1
#
#   Data: 22/05/2000
#   Renato/Reginaldo
#
#   Alterado e reestruturado por Sinclair Iyama - Roaming Internacional (TADIG)
#                                Alex da Rocha Lima - Implantacao / Control-M
#
#   Alteracao 06/03/02
#             03/FEV/2003 - Adequacao 'a nova DCH : novo parametro (TSI), unificando SP e RJ.
#                           Acerto do codigo de retorno (rc) para 0 (enviado) ou 1 (erro no envio).
#
#   Obs.: Em caso de erro no envio, sera' carregado no Control-M, o job de Reenvio BSCS_ROAM_03_01_R.sh.
#
## Mensagens
#M#I-BSCS_ROAM-030 : Arquivo enviado com sucesso
#M#E-BSCS_ROAM-030 : Erro no envio do arquivo
#M#E-BSCS_ROAM-031 : Erro de infra-estrutura
#

# Definicao de Variaveis

DIRWRK=/tmp
RCV=/transf/rcv 
TMP=$DIRWRK/bscs_roam_$$.txt
rc=0

#
# Connect:Enterprise UNIX environment variables.
#
. /aplic/centerprise/etc/profile

Dir_log="/home/ceuser/LOG_CE"
Dir_reenvio="/home/ceuser/REENVIO_CE"

cd $RCV 2>$TMP

find $Dir_log -type f -mtime +7 -exec rm -f {} \;

#for file in ????DBRANC??????????.pgp 
for file in ????DBRANC??????????
do [ ! -f $file ] && continue

       sit_ori=`echo $file | cut -c 1-2`
       arq_new=`echo $file | cut -c 4-24`
       arq_id=`echo $file | cut -c 4-14`
       arq_log=log.$file.`date +%Y%m%d.%H%M%S`
       case $sit_ori in
           TS ) mbx_id="Stsi";;
	   sp ) mbx_id="bra_s";;
	   rj ) mbx_id="bra_r";;
           ts ) mbx_id="tst_s";;
           tr ) mbx_id="tst_r";;
	   *  ) exit;;
       esac
	
       mv $file ${arq_new} 2>$TMP
       chown ceuser:ce  ${arq_new} 2>$TMP

       cmuadd -i $mbx_id -b ${arq_new} -t /transf/rcv/${arq_new} -uceuser -p ceuser -c b

       contador=0
       while (( "$contador" < 20 ))
        do
	   sleep 10
           envio=`cmulist -uceuser -pceuser -b $arq_new | grep  $mbx_id | awk '{print $6}'`
		
           if [ $envio = "ARTY" ]
                then contador=20
           fi
           contador=`expr $contador + 1`
        done
        if [ $envio = "ARTY" ]
	   then
		echo "ARQUIVO ENVIADO COM SUCESSO " > $Dir_log/$arq_log 
                rm ${arq_new} 
	   else
		echo "ARQUIVO NAO ENVIADO " > $Dir_log/$arq_log 
                rc=`expr $rc + 1`
	fi
        cmuerase -uceuser -pceuser  -i $mbx_id -b $arq_new >> $Dir_log/$arq_log 
        chown ceuser:ce  $Dir_log/$arq_log
        rm -f $TMP
done

exit ${rc}
