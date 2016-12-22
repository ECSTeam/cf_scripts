# App Profiler

This module contains script that profile apps deployed to the targeted PCF foundation.

The script relies on Rahul Jain's modified [buildpacks-usage](https://github.com/rahul-kj/cf_buildpacks_usage) plugin.

Using the plugin, the script extracts verbose details of running application.

The script takes a switch `-l`. The valid logger destination options are `splunk` or `statsd`.

For `splunk` destination, the script assumes you are the Splunk Forwarder and moves the generated csv to the forwarding location for Splunk to consume.

For `statsd` destination, the script creates events and pipes them using `netcat` utility. 

In both destination formats, the message event is timestamped.

## How to run this script

1. Edit the `cf_settings` and make changes as needed.
	If using encrypted mode please follow [these](encrypt-password-using-GPG.md) instructions on how to encrypt password with `GngPG` utility. 

2. Login to the PCF foundation with a privileged account. The account should atleast have `space-developer` access and it should have `org-manager` grants for the PCF Orgs you wish to profile. 
(Please remember to grant org-manager access to this PCF account, all new orgs created).

2. The script can be ran from command line or schedule as a cron job to profile apps on a periodic basis. 

## Usage

```
	$> ./get_pcf_apps.sh \
			[-r <app#>] \
			[-l <splunk|statsd>] \
			[-t <tagName>] \ 
			[-e <envrionment>] \
			{	[-f <fwdLoc>] or \
				[-i <ipAddr>] [-p <port>] }

	where:
		  app# are:
			1: Get the list of apps
			2: Get the buildpacks and apps using them
			tagName: identifier tag  (e.g. NAM | ecs )
		dataCenter: prod1 or prod2
			fwdLoc: path to folder, read by Splunk Forwarder
			ipAddr: ip address of the Statsd listener 
			  port: port of the Statsd listener
			  
```
