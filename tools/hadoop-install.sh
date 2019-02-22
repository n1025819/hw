#!/bin/bash
#set -x

#define variables
base=/tmp/hadoop-app
jdk=jdk-8u144-linux-x64.rpm
hadoop=hadoop-3.0.3
zookeeper=zookeeper-3.4.9
password=1234

#create hadoop app folder
mkdir -p $base

#working directory
cd $base

#get repo
rm -r -f $base/hadoop-3.0.3-ha
git clone https://github.com/orozcohsu/hadoop-3.0.3-ha.git

#hosts
cat /tmp/hadoop-3.0.3-ha/tools/host.conf|grep -v '^#'|grep ','master.mycluster','|awk -F',' '{print $3 " master"}' >> /etc/hosts
cat /tmp/hadoop-3.0.3-ha/tools/host.conf|grep -v '^#'|grep ','slaver1.mycluster','|awk -F',' '{print $3 " slaver1"}' >> /etc/hosts
cat /tmp/hadoop-3.0.3-ha/tools/host.conf|grep -v '^#'|grep ','slaver2.mycluster','|awk -F',' '{print $3 " slaver2"}' >> /etc/hosts
echo 'master' > /etc/hostname

#SSH without password
yes y | ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ''
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
sshpass -p $password ssh-copy-id -i ~/.ssh/id_rsa.pub root@slaver1
sshpass -p $password ssh-copy-id -i ~/.ssh/id_rsa.pub root@slaver2

runRemoteCmd.sh "echo 'slaver1 > /etc/hostname'" slaver1.mycluster /tmp/hadoop-3.0.3-ha/tools/host.conf
runRemoteCmd.sh "echo 'slaver2 > /etc/hostname'" slaver2.mycluster /tmp/hadoop-3.0.3-ha/tools/host.conf

deploy.sh /etc/hosts /etc slave

deploy.sh /root/.ssh/id_rsa /root/.ssh slave
deploy.sh /root/.ssh/id_rsa.pub /root/.ssh slave
deploy.sh /root/.ssh/authorized_keys /root/.ssh slave

hostname master
runRemoteCmd.sh "hostname slaver1" slaver1.mycluster /tmp/hadoop-3.0.3-ha/tools/host.conf
runRemoteCmd.sh "hostname slaver2" slaver2.mycluster /tmp/hadoop-3.0.3-ha/tools/host.conf

echo `date '+%Y-%m-%d %H:%M:%S'` "Hadoop-cluster-nodes are inpass"

#disable security
setenforce 0
sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config 
systemctl disable firewalld
systemctl stop firewalld
echo 'StrictHostKeyChecking no' >> /etc/ssh/ssh_config
systemctl restart sshd 

runRemoteCmd.sh "setenforce 0" slaver1.mycluster /tmp/hadoop-3.0.3-ha/tools/host.conf
runRemoteCmd.sh "sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config" slaver1.mycluster /tmp/hadoop-3.0.3-ha/tools/host.conf
runRemoteCmd.sh "systemctl disable firewalld;systemctl stop firewalld" slaver1.mycluster /tmp/hadoop-3.0.3-ha/tools/host.conf
runRemoteCmd.sh "echo 'StrictHostKeyChecking no' >> /etc/ssh/ssh_config" slaver1.mycluster /tmp/hadoop-3.0.3-ha/tools/host.conf
runRemoteCmd.sh "systemctl restart sshd" slaver1.mycluster /tmp/hadoop-3.0.3-ha/tools/host.conf
runRemoteCmd.sh "setenforce 0" slaver2.mycluster /tmp/hadoop-3.0.3-ha/tools/host.conf
runRemoteCmd.sh "sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config" slaver2.mycluster /tmp/hadoop-3.0.3-ha/tools/host.conf
runRemoteCmd.sh "systemctl disable firewalld;systemctl stop firewalld" slaver2.mycluster /tmp/hadoop-3.0.3-ha/tools/host.conf
runRemoteCmd.sh "echo 'StrictHostKeyChecking no' >> /etc/ssh/ssh_config" slaver2.mycluster /tmp/hadoop-3.0.3-ha/tools/host.conf
runRemoteCmd.sh "systemctl restart sshd" slaver2.mycluster /tmp/hadoop-3.0.3-ha/tools/host.conf

#install packages
runRemoteCmd.sh "yum -y update" all 
runRemoteCmd.sh "yum -y install wget git ntp" all 

echo `date '+%Y-%m-%d %H:%M:%S'` "All nodes are completed - yum update"
echo `date '+%Y-%m-%d %H:%M:%S'` "All nodes are installed wget, git, ntp"

#check packages
if [ -f "$base/$jdk" ]; then
  echo `date '+%Y-%m-%d %H:%M:%S'` "1.Found $jdk"
else
  echo `date '+%Y-%m-%d %H:%M:%S'` "1. Not found $jdk, start to download"
  wget https://mirror.its.sfu.ca/mirror/CentOS-Third-Party/NSG/common/x86_64/$jdk
  echo `date '+%Y-%m-%d %H:%M:%S'` "1. $jdk downloaded"
fi

if [ -f "$base/$hadoop.tar.gz" ]; then
  echo `date '+%Y-%m-%d %H:%M:%S'` "2.Found $hadoop"
else
  echo `date '+%Y-%m-%d %H:%M:%S'` "2. Not found $hadoop.tar.gz, start to download"
  wget https://archive.apache.org/dist/hadoop/core/hadoop-3.0.3/$hadoop.tar.gz 
  echo `date '+%Y-%m-%d %H:%M:%S'` "2. $hadoop.tar.gz downloaded"
fi

if [ -f "$base/$zookeeper.tar.gz" ]; then
  echo `date '+%Y-%m-%d %H:%M:%S'` "3.Found $hadoop"
else
  echo `date '+%Y-%m-%d %H:%M:%S'` "3. Not found $zookeeper.tar.gz, start to download"
  wget https://archive.apache.org/dist/zookeeper/$zookeeper/$zookeeper.tar.gz
  echo `date '+%Y-%m-%d %H:%M:%S'` "3. $zookeeper.tar.gz downloaded"
fi


#create Hadoop-record-folders
rm -r -f /opt/hadoop/tmp
runRemoteCmd.sh "mkdir -p /opt/hadoop/tmp" all
runRemoteCmd.sh "mkdir -p /opt/hadoop/tmp/name" all
runRemoteCmd.sh "mkdir -p /opt/hadoop/tmp/data" all
runRemoteCmd.sh "mkdir -p /opt/hadoop/tmp/journaldata" all

echo `date '+%Y-%m-%d %H:%M:%S'` "Hadoop-record-folders are created"

#install package
#java
rpm -ivh $base/$jdk
rm -r -f /usr/java/java
ln -s /usr/java/jdk1.8.0_144/ /usr/java/java
echo 'export JAVA_HOME=/usr/java/java' >> /etc/profile
echo 'export JRE_HOME=$JAVA_HOME/jre' >> /etc/profile
echo 'export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:$JRE_HOME/lib/rt.jar' >> /etc/profile
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /etc/profile
deploy.sh $base/$jdk /tmp slave
runRemoteCmd.sh "rpm -ivh /tmp/jdk-8u144-linux-x64.rpm" slave
runRemoteCmd.sh "rm -r -f /usr/java/java" slave
runRemoteCmd.sh "ln -s /usr/java/jdk1.8.0_144/ /usr/java/java" slave
runRemoteCmd.sh "export JAVA_HOME=/usr/java/java" slave
runRemoteCmd.sh "export JRE_HOME=$JAVA_HOME/jre" slave
runRemoteCmd.sh "export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:$JRE_HOME/lib/rt.jar" slave
runRemoteCmd.sh "export PATH=$PATH:$JAVA_HOME/bin" slave

runRemoteCmd.sh "java -version" all
echo `date '+%Y-%m-%d %H:%M:%S'` "$jdk has been installed"

#zookeeper
tar zxvf $zookeeper.tar.gz
rm -r -f /opt/$zookeeper
rm -r -f /opt/zookeeper
mv $zookeeper /opt
if [ -d "/opt/$zookeeper" ]; then
  ln -s /opt/$zookeeper /opt/zookeeper
  cp /opt/zookeeper/conf/zoo_sample.cfg /opt/zookeeper/conf/zoo.cfg
  sed -i '/dataDir/s/tmp/opt/' /opt/zookeeper/conf/zoo.cfg
  echo 'server.1=master:2888:3888' >> /opt/zookeeper/conf/zoo.cfg
  echo 'server.2=slaver1:2888:3888' >> /opt/zookeeper/conf/zoo.cfg
  echo 'server.3=slaver2:2888:3888' >> /opt/zookeeper/conf/zoo.cfg
  echo '1' > /opt/zookeeper/myid
  runRemoteCmd.sh "rm -r -f /opt/zookeeper 2&>1" slave
  deploy.sh /opt/$zookeeper /opt/zookeeper slave
  runRemoteCmd.sh "echo '2' > /opt/zookeeper/myid" slaver1.mycluster /tmp/hadoop-3.0.3-ha/tools/host.conf
  runRemoteCmd.sh "echo '3' > /opt/zookeeper/myid" slaver2.mycluster /tmp/hadoop-3.0.3-ha/tools/host.conf
else
  echo "Not complete zookeeper!"
  exit
fi

#hadoop3
tar zxvf $hadoop.tar.gz
rm -r -f /opt/$hadoop
rm -r -f /opt/hadoop
mv $hadoop /opt
if [ -d "/opt/$hadoop" ]; then
  ln -s /opt/$hadoop /opt/hadoop
  cp /tmp/hadoop-3.0.3-ha/profile /etc/profile
  cp /tmp/hadoop-3.0.3-ha/hadoop-config.sh /opt/$hadoop/libexec
  cp /tmp/hadoop-3.0.3-ha/hadoop-env.sh /opt/$hadoop/etc/hadoop/hadoop-env.sh
  cp /tmp/hadoop-3.0.3-ha/*.xml /opt/$hadoop/etc/hadoop/
  cp /tmp/hadoop-3.0.3-ha/workers /opt/hadoop-3.0.3/etc/hadoop
  deploy.sh /etc/profile /etc/profile slave
  source ~/.bash_profile  
  runRemoteCmd.sh "source ~/.bash_profile" slave
  runRemoteCmd.sh "source /etc/profile" slave
  runRemoteCmd.sh "rm -r -f /opt/hadoop" slave
  runRemoteCmd.sh "rm -r -f /opt/hadoop-3.0.3" slave
  rm -r -f /opt/hadoop/tmp
  mkdir -p /opt/hadoop/tmp
  mkdir -p /opt/hadoop/tmp/name
  mkdir -p /opt/hadoop/tmp/data
  mkdir -p /opt/hadoop/tmp/journaldata
  deploy.sh /opt/hadoop /opt/hadoop slave
  runRemoteCmd.sh "hadoop version" all
  echo `date '+%Y-%m-%d %H:%M:%S'` "hadoop has been deployed"
else
  echo "Not complete hadoop!"
  exit
fi

#start services
runRemoteCmd.sh "/opt/zookeeper/bin/zkServer.sh start" all 
runRemoteCmd.sh "/opt/hadoop/sbin/hadoop-daemon.sh start journalnode" all
runRemoteCmd.sh "jps" all

#format and sync
source /etc/profile
hdfs namenode -format
hdfs zkfc -formatZK
deploy.sh /opt/hadoop/tmp/name /opt/hadoop/tmp slave

#start hdfs and mapreduce
start-all.sh
echo `date '+%Y-%m-%d %H:%M:%S'` "Hadoop services are up!"

#start historyserver
mr-jobhistory-daemon.sh start historyserver

#start timelineserver
yarn-daemon.sh start timelineserver

#test hadoop
hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.0.3.jar teragen 1000 /teragen
hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.0.3.jar terasort /teragen /terasort
hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.0.3.jar teravalidate /terasort /teravalidate

echo `date '+%Y-%m-%d %H:%M:%S'` "Hadoop-3.0.3 HA are done!"
