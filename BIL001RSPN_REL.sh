#!/usr/bin/ksh
        # Finalidade    : CHGXXXX - Gera relatorio com execucoes do BILLING do CICLO X para historico.
        # Input         : BIL001RSPN_REL.sh
        # Output        : mail, log
        # Autor         : Marcos de Benedicto
        # Data          : 04/02/2005

if [ "${#}" -ne 3 ]
then
    banner ERRO!!
    echo "\n\t\tParametros invalidos!!"
    echo "\t\tUSE: ${0} <CICLO> <APLICACAO> <ODATE>."
    exit 1
fi

#---------------
# Set das variaveis 
#---------------
export PASS=`ctmcpt < ${CONTROLM}/../.controlm | grep CONTROLM_PASSWD | cut -d= -f2`
export USR=${CONTROLM_USER}

COD="BIL001RSPN_REL"
DIR_REL_CTM="/aplic/ctm/ctmserv/PROD/ARQS"
EMAIL="rafael.toniete@nextel.com.br,gilliard.delmiro@nextel.com.br"
SPOOL="/tmp/${COD}_$$.spool"
SQL="/amb/scripts/sql/${COD}.sql"
CICLO="${1}"
APLICACAO="${2}"
DATA="${3}"
DESC="${COD} - Gera relatorio com execucoes do BILLING ${MODULO} do CICLO ${CICLO} para historico."

RELATORIO="${DIR_REL_CTM}/Relatorio_${APLICACAO}_Ciclo_${CICLO}_DATA_${DATA}.xls"

. /amb/eventbin/SQL_RUN.PROC3 "${ORACLE_SID}" "${USR}/${PASS}" "${SQL} ${CICLO} ${APLICACAO} ${DATA}" "${EMAIL}" "${DESC}" 0 "${DESC}" ${SPOOL}

cat ${SPOOL} |tr -s ' ' |tr -s ' ' | sed -e 's: |:|:g' -e 's:| :|:g' |egrep -v '^$|rows selected.'  > ${RELATORIO}

rm -f ${SPOOL}

cat  ${RELATORIO} | \
  awk -F\| 'BEGIN{ SEGSDIA=24*60*60
                   MES[01]=0
                   MES[02]=31*SEGSDIA
                   MES[03]=59*SEGSDIA
                   MES[04]=90*SEGSDIA
                   MES[05]=120*SEGSDIA
                   MES[06]=151*SEGSDIA
                   MES[07]=181*SEGSDIA
                   MES[08]=212*SEGSDIA
                   MES[09]=243*SEGSDIA
                   MES[10]=273*SEGSDIA
                   MES[11]=304*SEGSDIA
                   MES[12]=334*SEGSDIA
                   MES[99]=365*SEGSDIA

                   # Cria cabecalho no Arquivo.
                   print "JOB|APLICACAO|GRUPO|DESCRICAO|INICIO DA EXECUCAO|FIM DA EXECUCAO|DURACAO|DATA|HOSTNAME|QTD EXECUCOES|"
                 }
                 {
 
                   JobName=$1
                   JobAplic=$2
                   JobGrupo=$3
                   JobDescr=$4
                   DataStart=$5
                   DataEnded=$6
                   DataOrder=$7
                   JobHost=$8
                   JobExec=$9

                  #
                  # Calculo do elapsed time com base em data/hora-ini e data/hora-fim
                  # Calculo da data Inicial em segundos
                  AADtIni=substr(DataStart,1,4)
                  MMDtIni=substr(DataStart,5,2)
                  DDDtIni=substr(DataStart,7,2)

                  hhDtIni=substr(DataStart,9,2)
                  mmDtIni=substr(DataStart,11,2)
                  ssDtIni=substr(DataStart,13,2)

                  HorCalcIni=hhDtIni * 60 * 60
                  MinCalcIni=mmDtIni * 60

                  AnoCalcIni=AADtIni * MES[99]
                  MesCalcIni=MES[MMDtIni]
                  DiaCalcIni=DDDtIni * SEGSDIA
                  DiaCalcIni=DiaCalcIni - SEGSDIA

                  TotCalcIni=AnoCalcIni+MesCalcIni+DiaCalcIni+HorCalcIni+MinCalcIni+ssDtIni
                  # Calculo da data Final em segundos

                  AADtFim=substr(DataEnded,1,4)
                  MMDtFim=substr(DataEnded,5,2)
                  DDDtFim=substr(DataEnded,7,2)

                  hhDtFim=substr(DataEnded,9,2)
                  mmDtFim=substr(DataEnded,11,2)
                  ssDtFim=substr(DataEnded,13,2)

                  HorCalcFim=hhDtFim * 60 * 60
                  MinCalcFim=mmDtFim * 60

                  AnoCalcFim=AADtFim * MES[99]
                  MesCalcFim=MES[MMDtFim]
                  DiaCalcFim=DDDtFim * SEGSDIA
                  DiaCalcFim=DiaCalcFim - SEGSDIA

                  TotCalcFim=AnoCalcFim+MesCalcFim+DiaCalcFim+HorCalcFim+MinCalcFim+ssDtFim

                  #
                  # Calculo p/ ano bissexto para Data Inicio
                  
                  AbslBsxtAnoCalcIni=AADtIni/4
                  IntgBsxtAnoCalcIni=int(AbslBsxtAnoCalcIni)
                  FlgBissxtIni=AbslBsxtAnoCalcIni - IntgBsxtAnoCalcIni

                                     #
                  # Se o ano for Bissexto, o mes da data de inicio for 2 ou 1 e
                  # o mes da data de Inicio for maior que 2, soma um dia, em
                  # segundos a data de Fim.

                  if (FlgBissxtIni==0 && MMDtIni<3 && MMDtFim>2)
                    {
                      print "Somou um dia ao data fim por ser Bissexto, Mes ini < 2 e Mes FIM > 2 ( Mes INI :" MMDtIni " -  Mes Fim : " MMDtFim " ) "
                      TotCalcFim=TotCalcFim + SEGSDIA
                    }

                  #
                  # Baseado nas datas de inicio e fim, transformadas em segundos,
                  # calcula o DELTA de processamento.

                    DeltIniFim=TotCalcFim - TotCalcIni

                  #
                  # Transforma duracao em segundos para o formato hh:mm:ss.
                    IntgMin=int(DeltIniFim / 60)
                    FracMin=DeltIniFim / 60
                    DeltaSeg=FracMin - IntgMin
                    DeltaSeg=DeltaSeg * 60
                    DeltaSeg=DeltaSeg +1000
                    DuracSeg=substr(DeltaSeg,3,2)

                    IntgHor=int(IntgMin / 60)
                    FracHor=IntgMin / 60
                    DeltaMin=FracHor - IntgHor
                    DeltaMin=DeltaMin   * 60
                    DeltaMin=DeltaMin   + 1000
                    DuracMin=substr(DeltaMin,3,2)

                    DeltaHor=IntgHor + 10000
                    DuracHor=substr(DeltaHor,2,4)

                  #
                  # Gravacao do arquivo de saida.

                    if (AADtIni=="" && MMDtIni=="" && DDDtIni=="")
                       {
                         print JobName "|" JobAplic "|" JobGrupo "|" JobDescr "|" "N/A" "|" "N/A" "|" "N/A" "|" DataOrder "|" JobHost "|" JobExec "|"
                       }
                   else
                       {
                         print JobName "|" JobAplic "|" JobGrupo "|" JobDescr "|" AADtIni "/" MMDtIni "/" DDDtIni " " hhDtIni ":" mmDtIni ":" ssDtIni "|" AADtFim "/" MMDtFim "/" DDDtFim " " hhDtFim ":" mmDtFim ":" ssDtFim "|" DuracHor ":" DuracMin ":" DuracSeg  "|" DataOrder "|" JobHost "|" JobExec "|"
                       }
                 }'  >  ${RELATORIO}V2

mv ${RELATORIO}V2 ${RELATORIO}

gzip ${RELATORIO}

/amb/operator/bin/attach_mail "${EMAIL}" ${RELATORIO}.gz "${DESC}"

exit 0
