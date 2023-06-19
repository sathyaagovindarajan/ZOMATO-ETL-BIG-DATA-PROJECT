#!/bin/bash

# Author:           Aarti Devikar
# Created Date:     06-05-2023
# Modified Date:    10-05-2023

# Usage:            bash module_2.sh

# # Prerequisit:
# 1) Hadoop services are running
# 2) home folder is there on HDFS, Hive warehouse is set on hdfs to /user/hive/warehouse
# 3) Hive metastore and Hiveserver2 services are running
# 4) A setupEnv.sh runs successfully
# 6) Module 1 run successfully

# Description:
# This script is abstractig module 2 functionality of the project zomato_etl
# It is invoked from wrapper.sh
# 
# Reference - Project SRS doc


#importing the zomato.properties file
. "/home/talentum/Project/zomato_etl/script/zomato.properties"

#declare spark_submit_command2="NA"

declare startTime2=$(date +"%F %H:%M:%S")
$startTime2

#dbname=default

echo "***************${0} - module_2.sh started***************"

if [ -d $PROJECT_PATH/tmp ];
then
	echo "******MOdule 1 is still running*******"
else
	mkdir -p $PROJECT_PATH/tmp/module_2_INPROGRESS
	echo "************tmp folder is empty **********"
	echo "**********Running instance of module 2 is created inside tmp*******"
fi

echo "${0} - Job Start Time is $startTime2"
echo "**********${0} - Hive DB Name is $dbname**********"

beeline -u jdbc:hive2://localhost:10000/default -n hiveuser -p Hive@123 -f $PROJECT_PATH/hive/ddl/createCountry.hive --hivevar dbname=$dbname 
echo "*************${0} - Hive dim_country table created************"

beeline -u jdbc:hive2://localhost:10000/default -n hiveuser -p Hive@123 -f $PROJECT_PATH/hive/ddl/createZomato.hive --hivevar dbname=$dbname
echo "************${0} - Hive raw_zomato and zomato tables created*************"


beeline -u jdbc:hive2://localhost:10000/default -n hiveuser -p Hive@123 -f $PROJECT_PATH/hive/dml/loadIntoCountry.hive --hivevar dbname=$dbname
echo "****************${0} - Hive dim_country table populated***************"

beeline -u jdbc:hive2://localhost:10000/default -n hiveuser -p Hive@123 -f $PROJECT_PATH/hive/dml/loadIntoRaw.hive --hivevar dbname=$dbname
echo "*****************${0} - Hive raw_zomato table populated**************"

beeline -u jdbc:hive2://localhost:10000/default -n hiveuser -p Hive@123 -f $PROJECT_PATH/hive/dml/loadIntoZomato.hive --hivevar dbname=$dbname
echo "*****************${0} - Hive zomato table populated*************"




#7) Functionality - Preparing log message
STATUS=$?
if [ $STATUS == "0" ]; then
	STATUS="SUCCESS"
	echo "${0} - STATUS = $STATUS"
	# Dropping Hive table default.raw_zomato 
	# ToDo 7- Create and invoke a hive script ddl/dropRaw.hive, note you will use beeline command
	beeline -u jdbc:hive2://localhost:10000/default -n hiveuser -p Hive@123 -f $PROJECT_PATH/hive/ddl/dropRaw.hive --hivevar dbname=$dbname
	echo "${0} - Hive default.raw_zomato table dropped"
else
	STATUS="FAILED"
	echo "${0} - STATUS = $STATUS"
	echo "Failed in module 2" | mail -s "Module2" aartidevikar2002@gmail.com
fi

endTime2=$(date +"%F %H:%M:%S")
echo "${0} - Job End Time is $endTime2"

# 8) Functionality - Adding log message into a log file on local file system
#timestamp=$(date +%Y)
echo "$job_id2,$job_step2,$spark_submit_command2,$startTime2,$endTime2,$STATUS" >> "${PROJECT_PATH}/logs/log_${log_file_name}.log"


# 9) Loading the log file from local file system to HDFS and then to Hive table
# Create if not exists temporary/managed table default.zomato_summary_log with location clause /user/talentum/zomato_etl/log

echo "******* Copying log into HDFS *******" 
hdfs dfs -put $PROJECT_PATH/logs/log_${log_file_name}.log /user/talentum/zomato_etl/log

beeline -u jdbc:hive2://localhost:10000/$dbname -n hiveuser -p Hive@123 --hivevar dbname=$dbname -f $PROJECT_PATH/hive/ddl/createLogTable.hive --hivevar dbname=$dbname
echo "${0} - Hive zomato_summary_log table created if not exists"

# Load logfile into table default.zomato_summary_log
beeline -u jdbc:hive2://localhost:10000/$dbname -n hiveuser -p Hive@123 --hivevar dbname=$dbname -f $PROJECT_PATH/hive/dml/zomato_summary_log_dml.hive --hivevar dbname=$dbname
echo "${0} - Hive zomato_summary_log table populated"

# ToDo 8- Create and invoke a hive script dml/loadIntoLog.hive, note you will use beeline command
rm -r $PROJECT_PATH/tmp

echo "***************${0} - removal of the instance of module 2 done**************"

echo "****************${0} - module_2.sh ended successfully************"








