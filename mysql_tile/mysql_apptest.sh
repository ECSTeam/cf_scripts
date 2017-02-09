#! /bin/bash

cf api --skip-ssl-validation $CF_API_URL 

cf l -u $CF_USER_NAME -p $CF_CREDENTIALS -o $TARGET_ORG -s $TARGET_SPACE

cf cs p-mysql 100mb spring-music-mysql

cf push

upstatus=$(curl spring-music-tile-upgrade-test.$CF_APPS_DOMAIN/health | jq '.db.status')
#echo "upstatus is $upstatus"
upstatus="${upstatus%\"}"
upstatus="${upstatus#\"}"
#echo "upstatus is $upstatus"

if [ $upstatus = "UP" ]; then
  echo "successful test of mysql tile"
else
  echo "test failure on mysql tile"
fi


cf delete spring-music -f

cf ds spring-music-mysql -f

cf lo
