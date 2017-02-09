#! /bin/bash

cf api --skip-ssl-validation $CF_API_URL 

cf l -u $CF_USER_NAME -p $CF_CREDENTIALS -o $TARGET_ORG -s $TARGET_SPACE

echo "creating mysql service instance"

cf cs p-mysql 100mb fortunes-db

echo "done creating mysql service instance"

echo "creating config server service instance"

cf cs p-config-server standard config-server -c '{"git": { "uri": "https://github.com/ECSTeam/fortune-teller", "searchPaths": "configuration" } }'

until [ `cf service config-server | grep -c "succeeded"` -eq 1  ]
do
  echo -n "."
done
echo "Done creating config server service instance"

echo "creating service registry service instance"

cf cs p-service-registry standard service-registry
until [ `cf service service-registry | grep -c "succeeded"` -eq 1  ]
do
  echo -n "."
done
echo "Done creating service registry service instance"

echo "creating circuit breaker service instance"
cf cs p-circuit-breaker-dashboard standard circuit-breaker-dashboard
until [ `cf service circuit-breaker-dashboard | grep -c "succeeded"` -eq 1  ]
do 
  echo -n "."
done
echo "Done creating circuit breaker service instance"

#push the apps

cf push

#basic status checks

fortunehealth=$(curl http://fortunes.$CF_APPS_DOMAIN/health)

echo ""

echo "$fortunehealth"

echo ""

fortuneuihealth=$(curl http://fortunes-ui.$CF_APPS_DOMAIN/health)

echo "$fortuneuihealth"


fortunestatus=$(curl http://fortunes.$CF_APPS_DOMAIN/health | jq '.status')
fortunedbstatus=$(curl http://fortunes.$CF_APPS_DOMAIN/health | jq '.db.status')
fortuneconfigserverstatus=$(curl http://fortunes.$CF_APPS_DOMAIN/health | jq '.configServer.status')
fortunehystrixstatus=$(curl http://fortunes.$CF_APPS_DOMAIN/health | jq '.hystrix.status')
fortunediscoveryCompositestatus=$(curl http://fortunes.$CF_APPS_DOMAIN/health | jq '.discoveryComposite.status')
fortunediscoveryCompositeEurekastatus=$(curl http://fortunes.$CF_APPS_DOMAIN/health | jq '.discoveryComposite.eureka.status')

#echo "fortune status is $fortunestatus"
#echo "fortune db status is $fortunedbstatus"
#echo "fortune config server status is $fortuneconfigserverstatus"
#echo "fortune hystrix status is $fortunehystrixstatus"
#echo "fortune discovery composite status is $fortunediscoveryCompositestatus"
#echo "fortune discovery composite eureka status is $fortunediscoveryCompositeEurekastatus"

fortunestatus="${fortunestatus%\"}"
fortunestatus="${fortunestatus#\"}"

fortunedbstatus="${fortunedbstatus%\"}"
fortunedbstatus="${fortunedbstatus#\"}"

fortuneconfigserverstatus="${fortuneconfigserverstatus%\"}"
fortuneconfigserverstatus="${fortuneconfigserverstatus#\"}"

fortunehystrixstatus="${fortunehystrixstatus%\"}"
fortunehystrixstatus="${fortunehystrixstatus#\"}"

fortunediscoveryCompositestatus="${fortunediscoveryCompositestatus%\"}"
fortunediscoveryCompositestatus="${fortunediscoveryCompositestatus#\"}"

fortunediscoveryCompositeEurekastatus="${fortunediscoveryCompositeEurekastatus%\"}"
fortunediscoveryCompositeEurekastatus="${fortunediscoveryCompositeEurekastatus#\"}"

fortuneuistatus=$(curl http://fortunes-ui.$CF_APPS_DOMAIN/health | jq '.status')
fortuneuiconfigserverstatus=$(curl http://fortunes-ui.$CF_APPS_DOMAIN/health | jq '.configServer.status')
fortuneuihystrixstatus=$(curl http://fortunes-ui.$CF_APPS_DOMAIN/health | jq '.hystrix.status')
fortuneuidiscoveryCompositestatus=$(curl http://fortunes-ui.$CF_APPS_DOMAIN/health | jq '.discoveryComposite.status')
fortuneuidiscoveryCompositeEurekastatus=$(curl http://fortunes-ui.$CF_APPS_DOMAIN/health | jq '.discoveryComposite.discoveryClient.status')

#echo "fortune ui status is $fortuneuistatus"
#echo "fortune ui config server status is $fortuneuiconfigserverstatus"
#echo "fortune ui hystrix status is $fortuneuihystrixstatus"
#echo "fortune ui discovery composite status is $fortuneuidiscoveryCompositestatus"
#echo "fortune ui discovery composite client status is $fortuneuidiscoveryCompositeEurekastatus"

fortuneuistatus="${fortuneuistatus%\"}"
fortuneuistatus="${fortuneuistatus#\"}"

fortuneuiconfigserverstatus="${fortuneuiconfigserverstatus%\"}"
fortuneuiconfigserverstatus="${fortuneuiconfigserverstatus#\"}"

fortuneuihystrixstatus="${fortuneuihystrixstatus%\"}"
fortuneuihystrixstatus="${fortuneuihystrixstatus#\"}"

fortuneuidiscoveryCompositestatus="${fortuneuidiscoveryCompositestatus%\"}"
fortuneuidiscoveryCompositestatus="${fortuneuidiscoveryCompositestatus#\"}"

fortuneuidiscoveryCompositeEurekastatus="${fortuneuidiscoveryCompositeEurekastatus%\"}"
fortuneuidiscoveryCompositeEurekastatus="${fortuneuidiscoveryCompositeEurekastatus#\"}"

if [ $fortunestatus = "UP" ] && [ $fortunedbstatus = "UP" ] && [ $fortuneconfigserverstatus = "UP" ] && [ $fortunehystrixstatus = "UP" ] && [ $fortunediscoveryCompositestatus = "UP" ] && [ $fortunediscoveryCompositeEurekastatus = "UP" ] && [ $fortuneuistatus = "UP" ] && [ $fortuneuiconfigserverstatus = "UP" ] && [ $fortuneuihystrixstatus = "UP" ] && [ $fortuneuidiscoveryCompositestatus = "UP" ] && [ $fortuneuidiscoveryCompositeEurekastatus = "UP" ]; then
  echo "successful test of application start in SCS tile"
else
  echo "test failure of application start in SCS tile"
fi

# check the service registry

eurekavalue=$(curl fortunes-ui.$CF_APPS_DOMAIN/random | jq '.text')

echo "eureka value is $eurekavalue"

if [[ $eurekavalue == *"deeds speak"* ]]; then
  echo "successful test of eureka in SCS tile"
else
  echo "test failure on eureka in SCS tile"
fi

# test config server and hystrix

cf stop fortune-service

hystrixvalue=$(curl fortunes-ui.$CF_APPS_DOMAIN/random | jq '.text')

echo "hystrix value is $hystrixvalue"

if [[ $hystrixvalue == *"future is bright"* ]]; then
  echo "successful test of hystrix and config server in SCS tile"
else
  echo "test failure on hystrix and config server in SCS tile"
fi

#cleanup apps

cf delete fortune-service -f
cf delete fortune-ui -f

#cleanup services

cf ds circuit-breaker-dashboard -f
cf ds config-server -f
cf ds fortunes-db -f
cf ds service-registry -f

#log out

cf lo
