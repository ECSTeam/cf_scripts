#! /bin/bash

cf api --skip-ssl-validation $CF_API_URL 

cf l -u $CF_USER_NAME -p $CF_CREDENTIALS -o $TARGET_ORG -s $TARGET_SPACE

cf cs p-redis shared-vm spring-music-redis

cf push

upstatus=$(curl spring-music-tile-upgrade-test.$CF_APPS_DOMAIN/health | jq '.redis.status')
#echo "upstatus is $upstatus"
upstatus="${upstatus%\"}"
upstatus="${upstatus#\"}"
#echo "upstatus is $upstatus"

if [ $upstatus = "UP" ]; then
  echo "successful test of redis tile"
else
  echo "test failure on redis tile"
fi


cf delete spring-music -f

cf ds spring-music-redis -f

cf lo
