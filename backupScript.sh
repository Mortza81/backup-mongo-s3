#!/bin/bash

BUCKETPATH="yourbucket/directioninbucket"

DB_URL="your mongodb host"

DBNAME="database name"

DATE=`date +%Y-%m-%d`

OUTDIR=/home/$USER/backups

LOGFILE=$OUTDIR/logs.txt

DOMAIN="service domain"
#Check internet connection
ping -c 1 8.8.8.8 > /dev/null 2>&1
if [ $? -ne 0 ]
then
	echo -e "\nNo internet connection, Backup failed. $DATE" >> $LOGFILE
	exit 1
fi
#Check if awscli is installed
dpkg -l | grep awscli
if [ $? -ne 0 ]
then	
	echo -e "\nawscli is not installed. $DATE" >> $LOGFILE
	exit 1
fi
mkdir -p "$OUTDIR"
mongodump --uri=$DB_URL --db=$DBNAME --gzip --out="$OUTDIR/$DATE" 
#Check if backing up is successful
if [ $? -eq 0 ]
then
	aws s3 cp "$OUTDIR/$DATE" s3://$BUCKETPATH/$DATE --endpoint-url=https://$DOMAIN/ --recursive
	#Trying to send the backup files to object storage
	if [ $? -ne 0 ]
	then
		echo -e "\nUnable to send the backup. $DATE" >> $LOGFILE
		exit 1
	else
		echo -e "\nBackup successfuly sent to the object storage. $DATE " >> $LOGFILE
	fi
else
	echo -e "\nAn issue occurred while backing up the database. $DATE" >> $LOGFILE
	exit 1
fi
#Trying to delete backup files from local computer
rm -r "$OUTDIR/$DATE"
if [ $? -ne 0 ]
then
	echo -e "\nUnable to delete the backup files in local directory. $DATE"
	exit 1
else
	echo -e "\nBackup successfully removed from the local directory. $DATE"
	exit 0
fi

