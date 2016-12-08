HOST=$1
DIR=$2
WORKITEM=$3
PATH=$PATH:/usr/epoch/EB/bin
ebreport history -recent -item ${WORKITEM} -nopartials \
| /usr/xpg4/bin/egrep -e "complete|delta" | awk '{ print $4 }' | while read catalogid
do
ebcatdump ${catalogid} | grep ".gz" | awk '{ print $12 }' 
done 
exit 0
