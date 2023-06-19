#!/bin/bash

# Author:           Aarti Devikar
# Created Date:     06-05-2023
# Modified Date:    10-05-2023

# Description:      This bash file when executed will perform various functionalies of Module 1.
# Usage:            bash module_1.sh

# Pre-requisite:    hadoop, hivemetastore, hiveserver2 should be running and local directory should be created

#importing the zomato.properties file
PROPERTIES_FILE=/home/talentum/Project/zomato_etl/script/zomato.properties

. "$PROPERTIES_FILE"

#For Unsetting environment variables
source $unset_env

#Creating table zomato_summary_log on beeline
beeline -u jdbc:hive2://localhost:10000/$dbname -n hiveuser -p Hive@123 -f $PROJECT_PATH/hive/ddl/createLogTable.hive --hivevar dbname=$dbname


#Declaring StartTime
declare startTime=$(date +"%F %H:%M:%S")

declare file_name=zomatocsv

mkdir -p $PROJECT_PATH/tmp/module_1_INPROGRESS
if [ $? -eq 0 ];
then
	echo "**********Module 1 is running, tmp folder is being created**********"
else 
	echo "***********tmp folder not created*************"
fi

#declare spark_submit_command="spark-submit --driver-java-options -Dlog4j.configuration='file:///home/talentum/spark/conf/log4j.tmp.properties' --master yarn --deploy-mode cluster $PROJECT_PATH/spark/py/module1.py" 

$spark_submit_command
declare x=$?


count=1
for entry in $PROJECT_PATH/source/csv/$file_name/*.csv
do
	echo "${0} - entry = $entry"
	mv $entry $PROJECT_PATH/source/csv/zomato_$(date +"%Y%m%d")$count.csv
	count=$(( $count + 1 ))
done
rm -rf $PROJECT_PATH/source/csv/$file_name

#Declaring EndTIme
endTime=$(date +"%F %H:%M:%S")

if [ $x -eq 0 ]; then

     echo "$job_id,$job_step1,$spark_submit_command,$startTime,$endTime,'SUCCESS'" >> "${PROJECT_PATH}/logs/log_${log_file_name}.log"

     echo -e "MODULE_1 has completed execution!\nStatus:\t\t'SUCCESS'\nStart-Time:\t$startTime\nEnd-Time:\t$endTime\nFor more details, check zomato_etl/logs folder" | mail -s "module_1 Status Update: ${job_id}" aartidevikar2002@gmail.com

     echo "******* Copying log into HDFS *******" 
     hdfs dfs -put $PROJECT_PATH/logs/log_${log_file_name}.log /user/talentum/zomato_etl/log

     beeline -u jdbc:hive2://localhost:10000/default -n hiveuser -p Hive@123 -f $PROJECT_PATH/hive/dml/zomato_summary_log_dml.hive 
     
     rm -r $PROJECT_PATH/tmp
     echo "************Module 1 run successfully, tmp folder is deleted*************"
else

     echo "$job_id,$job_step1,$spark_submit_command,$startTime,$endTime,'FAILED'" >> "${PROJECT_PATH}/logs/log_${log_file_name}.log"
     
     echo -e "MODULE_1 has completed execution!\nStatus:\t\t'FAILED'\nStart-Time:\t$startTime\nEnd-Time:\t$endTime\nFor more details, check zomato_etl/logs folder" | mail -s "module_1 Status Update: ${job_id}" aartidevikar2002@gmail.com     

     echo "******* Copying log into HDFS *******" 
     hdfs dfs -put $PROJECT_PATH/logs/log_${log_file_name}.log /user/talentum/zomato_etl/log

     beeline -u jdbc:hive2://localhost:10000/default -n hiveuser -p Hive@123 -f $PROJECT_PATH/hive/dml/zomato_summary_log_dml.hive
fi

#Moving json files from source/json to archive folder
mv $PROJECT_PATH/source/json/* $PROJECT_PATH/archive/

echo "****************${0} - module_1.sh ended successfully************"

