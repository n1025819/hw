#!/bin/bash

#Variables
TODAY=$(date +"%Y-%m-%d-%H%M")  #date and time
BACKUP_PATH="/tmp/hadoop-app/fsimage" #path to store metadata
RT_DAYS="4"                     #Rentention in days

#Logic
if [ -d ${BACKUP_PATH} ]; then
  cd ${BACKUP_PATH}
else
  mkdir -p ${BACKUP_PATH} && cd ${BACKUP_PATH}
fi

#download fsimage file
hdfs dfsadmin -fetchImage .
if [ $? -eq 0 ]; then
    #compress the fsimage and edits file
    tar -zcf namenode-dev2-${TODAY}.tar.gz fsimage_*
    if [ $? -eq 0 ]; then
      #delete all backup up to days specified in RT_DAYS
      find -atime +${RT_DAYS} -name "namenode*" -exec rm {} \;
      rm fsimage_* #remove downloaded fsimage
    fi
fi
