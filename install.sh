#!/bin/bash


IFS=";";

#prepare
cd ${APT_PACKAGE}/agent/
tar -xzvf ${APT_PACKAGE}/agent/agent.tgz
cp ${APT_PACKAGE}/agent/conf.ini.bak ${APT_PACKAGE}/agent/conf.ini -f

#init conf.ini
file="${APT_PACKAGE}/agent/conf.ini"
line=`sed -n '/\[partition\]/=' $file | tail -n1`
#agent_hosts="192.168.1.103;192.168.1.104;192.168.1.105"
#agent_hosts=$(apt_show_app agent)
#agent_hosts=($agent_hosts)
kafka_brokers=$(apt_config_show kafka brokers)
kafka_brokers=($kafka_brokers)
partition=0

#for host in ${agent_hosts[@]}
for broker in ${kafka_brokers[@]}
do
    line=`expr $line + 1`
    insert="${broker} = ${partition}"
    partition=`expr $partition + 1`
    sed -i "${line}s/.*/${insert}&/" $file
done


line=`sed -n '/\[etcd\]/=' $file | tail -n1`
#etcd_hosts="192.168.1.103;192.168.1.104;192.168.1.105"
etcd_hosts=$(apt_show_app etcd)
etcd_hosts=($etcd_hosts)
end_point=0

for host in ${etcd_hosts[@]}
do
    line=`expr $line + 1`
    insert="endPoint${end_point} = ${host}"
    end_point=`expr $end_point + 1`
    sed -i "${line}s/.*/${insert}&/" $file
done

line=`sed -n '/\[hdfs\]/=' $file | tail -n1`
hdfs_namenode=$(apt_config_show hdfs namenode)
line=`expr $line + 1`
insert="nameNode = ${hdfs_namenode}"
sed -i "${line}s/.*/${insert}&/" $file

#exe conf
cd ${APT_PACKAGE}/agent
./conf

#mv exe to init.d/
cp ${APT_PACKAGE}/agent/agent ${APT_HOME}/etc/init.d/ 

#create kafka offline_msg topic
function __readINI() {
 INIFILE=$1; SECTION=$2; ITEM=$3
 _readIni=`awk -F '=' '/\['$SECTION'\]/{a=1}a==1&&$1~/'$ITEM'/{print $2;exit}' $INIFILE`
echo ${_readIni}
}

#namenodes=`__readINI /etc/cdh.conf cdh_config ZooKeeperServer`
#kafka-topics --create --zookeeper ${namenodes%%;*}:2181 --replication-factor 3 --partitions 1 --topic offline_msg 

#webserver host
IFS=";"
line=`sed -n '/\[webServer\]/=' $file | tail -n1`
webserver=$(apt_show_app apt-web-server)
webserver=($webserver)
line=`expr $line + 1`
${webserver[0]}
insert="ip = ${webserver[0]}"
sed -i "${line}s/.*/${insert}&/" $file
