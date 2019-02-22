#!/bin/bash
#set -x

if [ $# -lt 2 ]
then 
  echo "Usage: ./runRemoteCmd.sh Command MachineTag"
  echo "Usage: ./runRemoteCmd.sh Command MachineTag confFile"
  exit 
fi

cmd=$1
tag=$2
if [ 'a'$3'a' == 'aa' ]
then
  
  confFile=/tmp/hadoop-3.0.3-ha/tools/deploy.conf
else 
  confFile=$3
fi

if [ -f $confFile ]
then
    for server in `cat $confFile|grep -v '^#'|grep ','$tag','|awk -F',' '{print $1}'` 
    do
       echo "*******************$server***************************"
       ssh $server "source /etc/profile; $cmd"
    done 
else
  echo "Error: Please assign config file or run deploy.sh command with deploy.conf in same directory"
fi
