# Spring Cloud Services (SCS) Tile Test

This script will perform the following:

1.  login to a foundation/org/space
1.  create instances of Eureka, Config Server and Hystrix services
1.  create a mysql service instance
1.  deploy the fortune-teller and fortune-teller-ui apps and bind them to those services
1.  curl an endpoint that confirms Eureka functionality (service discovery) between fortuner-teller-ui and fortune-teller
1.  stop the fortune-teller application
1.  curl an endpoint on the fortuner-teller-ui service to verify Hystrix and Config Server functionality
1.  delete the apps and services
1.  log out


The attached application comes from a build of the [SCS sample apps] (https://github.com/ECSTeam/fortune-teller).  The jars have been copied here as to provide a stable deployable; if used in a concourse pipeline generating these jars as a part of the pipeline likely makes more sense.  Note that the configuration sued by the config server is pulled from that same fortune-teller github repo.

The following environment variables are required to be set:

CF_API_URL:  the api endpoint of your foundation.

CF_USER_NAME:  the username of the account that will perform the `cf cs` and `cf push` commands.

CF_CREDENTIALS: the password for that user.

TARGET_ORG:  the org in which the service instance will be created and the app pushed.

TARGET_SPACE:  the space in which the service instance will be created and the app pushed.

CF_APPS_DOMAIN:  the apps domain. 

This script should be run after an SCS tile upgrade to verify that the upgrade has no breaking changes to Java apps bound to SCS Services.
