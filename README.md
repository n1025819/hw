# How to get started?

## 1.yum -y update
## 2.yum -y install wget git ntp sshpass
## 3.cd /tmp; git clone https://github.com/orozcohsu/hadoop-3.0.3-ha.git
## 4.config host.conf, workers for your machine
## 5.set tools in ~/.bash_profile => PATH=$PATH:$HOME/bin:/tmp/hadoop-3.0.3-ha/tools
## 6.run the shell => ./hadoop_install.sh 

# How to re-run?

## 1.in master, clean all hosts in /etc/hosts
## 2.make sure all nodes don't have zookeeper thread running, if yes, kill it
## 3.run the shell => ./hadoop_install.sh

# How to change the cluster nodes

## the mininum is 3 nodes
## change the hosts.conf, deploy.conf, workers, zookeeper... 
