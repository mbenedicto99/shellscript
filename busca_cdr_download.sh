#
# Busca arquivo de varios dias na Zingy	
#
if [ $# -lt 1 ]
then
   echo "Uso : $0 Quantidade de dias  "
	 exit 1
fi
ant=$1
val=0
const="86400"
export PATH=$PATH:/usr/local/bin/
cd /aplic/cdr_download

while [ ${val} -lt ${ant} ] 
do
echo "#!/usr/bin/perl "  > Data
echo "@T=localtime(time-${const});"  >> Data
echo "\$year=\$T[5]+1900;"  >> Data
echo "\$mon=\$T[4]+1;"  >> Data
echo "\$day=\$T[3];"  >> Data
echo "printf(\"%4d%02d%02d\\\\n\",\$year,\$mon,\$day);"  >> Data
chmod 755 Data
dia=$(Data)
wget https://msrv.zingy.com:8019/NextelBR/dwnld/billing_e_${dia}.txt --http-user=nextelbr  --http-passwd=%%logg$

if [ $( wc -l billing_e_${dia}.txt | cut -d" "  -f1 ) -eq 0 ]
then 
rm -f billing_e_${dia}.txt
fi

wget https://msrv.zingy.com:8019/NextelBR/dwnld/billing_c_${dia}.txt --http-user=nextelbr  --http-passwd=%%logg$

if [ $(wc -l billing_c_${dia}.txt | cut -d" " -f1) -eq 0 ]
then 
rm -f billing_c_${dia}.txt
fi

wget https://msrv.zingy.com:8019/NextelBR/dwnld/billing${dia}.log --http-user=nextelbr  --http-passwd=%%logg$

rm -f Data
const=$((${const}+86400))
val=$((${val}+1))
done

