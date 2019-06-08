#!/usr/bin/env sh


for MONGO_URI in $MONGO_URIS; do

	#Extracting dbname from MONGO_URI	
	DBNAME=$(echo ${MONGO_URI} | sed "s/.*[0-9]\///")
	#Name of the compressed backup file
	BACKUP_NAME="${DBNAME}-$(date -u +%Y-%m-%d_%H-%M-%S)_UTC.tar.gz"

	echo "--Starting backup of ${DBNAME}"
	# Run backup
	mongodump --uri=${MONGO_URI} --gzip --excludeCollection UserActivity --excludeCollection courseHtml --excludeCollection GLLogs --excludeCollection UserLogs --excludeCollection UserLogsTOLL --excludeCollection userIdToken -o /backup/${DBNAME}

	echo "--Compressing ${DBNAME} backup"
	# Compress backup
	cd /backup/${DBNAME} && tar -cvzf "${BACKUP_NAME}" ${DBNAME}
	rm -rf /backup/${DBNAME}/${DBNAME}


	if [ "$S3_UPLOAD" = "true" ]; then

		echo "--Uploading ${DBNAME} to s3 bucket ${S3_BUCKET}"
		# Upload backup
		#aws s3 cp "/backup/${DBNAME}/${BACKUP_NAME}" "s3://${S3_BUCKET}/${S3_PATH}/${BACKUP_NAME}"
		aws s3 cp "/backup/${DBNAME}/${BACKUP_NAME}" "s3://${S3_BUCKET}/${BACKUP_NAME}"
		# Delete temp files
		rm -rf /backup/${DBNAME}
		echo --Sending slack Notification for ${DBNAME}
		curl -X POST -H 'Content-type: application/json' \
		--data '{"text":"${DBNAME} backup done and uploaded to S3"}' \
		$SLACK_URL
	fi

	#Slack nontification
	echo --Sending slack Notification for ${DBNAME}
	curl -X POST -H 'Content-type: application/json' \
	--data '{"text":"'${DBNAME}' backup done and saved to lil-utils:/root/backup/'${DBNAME}'/'${BACKUP_NAME}'"}' \
	$SLACK_URL

	# Delete backup files
	if [ -n "${MAX_BACKUPS}" ]; then
	  while [ $(ls /backup/${DBNAME} -w 1 | wc -l) -gt ${MAX_BACKUPS} ];
	  do
	    BACKUP_TO_BE_DELETED=$(ls /backup/${DBNAME} -w 1 | sort | head -n 1)
	    rm -rf /backup/${DBNAME}/${BACKUP_TO_BE_DELETED}
	  done
	else
	  rm -rf /backup/${DBNAME}/${DBNAME}
	fi

done
 
