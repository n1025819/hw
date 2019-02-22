#start services
runRemoteCmd.sh "/opt/zookeeper/bin/zkServer.sh start" all
runRemoteCmd.sh "/opt/hadoop/sbin/hadoop-daemon.sh start journalnode" all
runRemoteCmd.sh "jps" all

#format
hdfs namenode -format
hdfs zkfc -formatZK
nohup hdfs namenode &
pid=$!
echo $pid

