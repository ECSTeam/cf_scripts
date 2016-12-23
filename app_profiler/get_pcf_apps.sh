#!/bin/bash

# This scripts does the following..
#	1. calls the `cf buildpack-usage` plugin in verbose mode and gets list of all apps
#	2. iterates through the apps list and generates messages in the Statsd format
#	3. generated messages are piped to the Statsd port on graphite using the `netcat` utility.
# 
# This script can be ran on-demand or setup as a cron job.
# 
#

# original IFS
OIFS=$IFS;
OOFS=$OFS;

# what is my target
whatsMyTarget() {
	echo "";
	echo "$(cf target)";
}

# login to pcf
login2Pcf() {
	echo "";
	# source cf end-point details
	source "./cf_settings.sh";

	# save the current work dir.
	CWD=$(pwd);

	if [ "${pwd_encrypted}" == "true" ]
	then
		# Encrypted password relies on `gpg2`. The assumption here is that, 
		# the encrypted password and passphrase are in the private location (~/.private)

		# login to pcf with encrypted password
		$( "${cf}" login -a "${cf_target}" -u "${cf_user}" -p "$( ${gpg2} --no-tty --batch --quiet --no-mdc-warning --passphrase-file ~/.private/passphrase.txt --decrypt ~/.private/pwd.gpg)" -o "${cf_org}" -s "${cf_space}" "${skip_ssl}" > /dev/null 1>&2);
	else 
		# login to pcf with encrypted password
		$( "${cf}" login -a "${cf_target}" -u "${cf_user}" -p "${cf_pwd}" -o "${cf_org}" -s "${cf_space}" "${skip_ssl}" > /dev/null 1>&2);

	fi;

	# return back to workdir
	# $(cd "${CWD}");
}

send2Statsd() {
	local filename="${1}";
	local ipAddr="${2}";
	local port="${3}";
	local tag="${4}";
	local environment="${5}";

	echo "	... forwarding file - ${filename}";

	# reset the IFS
	IFS=$OIFS;

	for i in `cat ${filename} | sed 's/ MB//g'`;
	do

		# change the input file separator
		IFS=',';

		# parse the line into an array
		aline=($i);

		echo "";

		if [ ${aline[0]} == 'ORG' ]
		then
			hdrs=("${aline[@]}")
			# iterate the hdrs array and print label
			for ((i=0; i<${#hdrs[@]}; ++i));
			do
				echo "label $i: ${hdrs[$i]}";
			done
		else 
			echo "	app: ${aline[2]}";
			dtm=$(date +%s);
			# echo "${event}:${metric}|c ${dtm}" | nc -u -w0 ${ipAddr} ${port};
			echo "${tag}.${environment}.${aline[0]}.${aline[1]}.${aline[2]}.${hdrs[3]}:${aline[3]}|c" | nc -u -w0 ${ipAddr} ${port};
			echo "${tag}.${environment}.${aline[0]}.${aline[1]}.${aline[2]}.${hdrs[4]}:${aline[4]}|c" | nc -u -w0 ${ipAddr} ${port};
			echo "${tag}.${environment}.${aline[0]}.${aline[1]}.${aline[2]}.${hdrs[5]}:${aline[5]}|c" | nc -u -w0 ${ipAddr} ${port};
			echo "${tag}.${environment}.${aline[0]}.${aline[1]}.${aline[2]}.${hdrs[6]}:${aline[6]}|c" | nc -u -w0 ${ipAddr} ${port};
		fi;
	done;

	# reset back the FS;
	IFS=$OIFS;
	OFS=$OOFS;
}

forward2Splunk() {
	local filename="${1}";
	local fwdloc="${2}";
	local tag="${3}";
	local environment="${4}";
	local rate="${5}";
	
	targetDir="${fwdloc}/${tag}/${environment}";
	echo "";
	echo "	... target location - ${targetDir}";
	
	# create the targetDir if needed
	$(mkdir -p "${targetDir}" );
	
	# cleanup files older than 30 days
	fnm=$(echo ${filename} | sed "s/\.csv//")
	echo "	... deleting any older(>= 30 days) files ['${fnm}*'] ";
	find "${targetDir}" -name "${fnm}*" -mtime +30 -exec rm -f {} \;

	dtm=$(date +%s);
	fnm=$(echo ${filename} | sed "s/\.csv/_${dtm}.csv/" )
	targetFile="${targetDir}/${fnm}";
	
	# location source
	locsrc="$( echo "${tag}-${environment}" | sed 's/\//-/g' | sed 's/,/-/g' | sed 's/ /-/g' )"
	
	# append headers for timestamp and env as 1st and 2nd col
	$( head -n 1 ${filename} | sed "s/^/TIMESTAMP,ORIGIN,/g" > ${targetFile} );
	
	# append timestamp and env as 1st and 2nd col to each row
	$( cat ${filename} | grep -v "ORG,SPACE" | sed "s/^/${dtm},${locsrc},/g" >> ${targetFile} );
	echo "	... generated file forwarded to - ${targetFile}";
}

usage() {
	echo "";
	echo "${1}";
	echo "Usage: $0 [-r <app#>] [-l <splunk|statsd>] [-t <tagName>] [-e <environment>] [ [-f <fwdLoc>] or [-i <ipAddr>] [-p <port>] ] " 1>&2; 
	echo "	where app# are: ";
	echo "		1: Get the list of apps"
	echo "		2: Get the list of buildpacks and apps using them"
	echo "";
	exit 1; 
}



# ----------------
# main block
# ----------------
while getopts ":r:l:t:e:f:i:p:-:" o; do
    case "${o}" in
        r)
            _r=${OPTARG}
			((_r == 1 || $_r == 2 || $_r == 3)) || usage "Invalid profile choice '${_r}}'";
            ;;
        l)
            _l=${OPTARG}
            if [ $_l != "splunk" ] && [ $_l != "statsd" ]; then
				usage "Invalid logger '${_l}'";
			fi
            ;;
        t)
            _t=${OPTARG}
            ;;
        e)
            _e=${OPTARG}
            ;;
        f)
            _f=${OPTARG}
            ;;
        i)
            _i=${OPTARG}
            ;;
        p)
            _p=${OPTARG}
            ;;
        -)    
            _args=${OPTARG}
            ;;
        *)
            usage;
            ;;
    esac
done
shift $((OPTIND-1))

# evaluate the arguments
if [ -z "${_r}" ] || [ -z "${_l}" ] || [ -z "${_t}" ] || [ -z "${_e}" ]; then
    usage
else
	if [ $_l == "splunk" ] && [ -z "${_f}" ]; then
		usage "For Splunk logger, 'forwarder location' is required";
	elif [ $_l == "statsd" ] && [ -z "${_i}" ]; then
		usage "For Statsd logger, 'target ipAddress' is required";
	elif [ $_l == "statsd" ] && [ -z "${_p}" ]; then
		usage "For Statsd logger, 'port' is required";
	fi;

	runWhat="${_r}";
	logger="${_l}";
	tag="${_t}";
	environment="${_e}";
	# echo "logger = ${logger}"
	# echo "tag = ${tag}"
	# echo "env = ${environment}"

	fwdLoc="${_f}";
	# echo "fwdLoc = ${fwdLoc}"

	ipAddr="${_i}";
	port="${_p}";

	# echo "ipAddr = ${ipAddr}"
	# echo "port = ${port}"
	# echo " sub args = ${_args}"
fi

# source common functions
source "./commons.sh";


# where am I targeted?
login2Pcf;
if [ $? -eq 0 ]
then
	echo "";
	echo "	... target is set. ";
else
	echo "";
	echo "	CF target is not set, or the login has expired! "
	echo "	Please login with `cf login -a <target> -u admin` ";
	echo "";
	exit 1;
fi;

# filename
filename="dump.csv";
case "$runWhat" in
	1)
		echo "	... get the app details";
		filename="apps_lst.csv";
		profile_apps "${filename}";
		;;
	2)
		echo "	... get buildpacks details";
		filename="buildpacks_lst.csv";
		list_apps_by_buildpacks "${filename}";
		;;
	3)
		echo "	... get events";
		filename="events_lst.csv";
		list_of_events "${filename}" "--${_args}";
		;;
	*)
		echo "invalid type selected! "
		exit 1;
esac;

echo "	... stage file - ${filename}";

if [ $logger == "statsd" ]; then
	send2Statsd "$filename" "$ipAddr" "$port" "$tag" "$environment";
elif [ $logger == "splunk" ]; then
	forward2Splunk "$filename" "$fwdLoc" "$tag" "$environment" "$rate";
else
	echo "Invalid logger, cannot process ...";
fi;	

echo "	Done!!! ";
