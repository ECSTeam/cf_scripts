#! /bin/bash

cf api --skip-ssl-validation $CF_API_URL 

cf l -u $CF_USER_NAME -p $CF_CREDENTIALS -o $TARGET_ORG -s $TARGET_SPACE

cf cs p-rabbitmq standard rabbitmq_sv

cf push

upstatus=$(curl rabbitmq-test.$CF_APPS_DOMAIN/tiletest | jq '.result')
#echo "upstatus is $upstatus"
upstatus="${upstatus%\"}"
upstatus="${upstatus#\"}"
#echo "upstatus is $upstatus"

if [ $upstatus = "success" ]; then
  echo "successful test of rabbit tile"
else
  echo "test failure on rabbit tile"
fi


cf delete rabbitmq_test -f

cf ds rabbitmq_sv -f

cf lo
