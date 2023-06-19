#!/bin/bash

# Author:           Aarti Devikar
# Created Date:     06-05-2023
# Modified Date:    10-05-2023

# Description:      This bash file when executed will run the zomato_etl Application
# Usage:            bash wrapper.sh

# Pre-requisite:    hadoop, hive metastore and hive server2 services,email configurations should be running

#importing the zomato.properties file
PROPERTIES_FILE=/home/talentum/Project/zomato_etl/script/zomato.properties

. "$PROPERTIES_FILE"

rm -r $PROJECT_PATH/archive/*
echo "****** Archive folder has been cleaned *******"

echo "*******cleaning hive********"
beeline -u jdbc:hive2://localhost:10000/default -n hiveuser -p Hive@123 -f $PROJECT_PATH/hive/ddl/cleanhive.hive --hivevar dbname=$dbname

bash $PROJECT_PATH/script/hdfs_st.sh
echo "******* HDFS structure has been created *******"


bash $PROJECT_PATH/script/copy_3_json.sh
echo "******* First three JSON files has been copied from staging area*******"

echo "******* Module 1 start running *******"
bash $PROJECT_PATH/script/module_1.sh

echo "******* Module 2 start running *******"
bash $PROJECT_PATH/script/module_2.sh

cp -r $PROJECT_PATH/.. ~/shared/backup/
echo "Zomato_etl has been backed up in : /shared/backup/"

echo "*********Execution of Zomato_etl Project done successfully**********"

