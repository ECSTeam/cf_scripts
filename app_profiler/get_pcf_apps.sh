#!/bin/bash

# This scripts does the following..
#	1. calls the `cf buildpack-usage` plugin in verbose mode and gets list of all apps
#	2. iterates through the apps list and generates messages in the Statsd format
#	3. generated messages are piped to the Statsd port on graphite using the `netcat` utility.
# 
# This script would be setup as a cron job.
#
# Statsd format: (identified by running the graphite nozzle in debug mode)  
#	&{ops.rep.CapacityTotalMemory 16048}
#	&{ops.rep.CapacityTotalDisk 48576}
#	&{ops.rep.CapacityTotalContainers 250}
#	&{ops.rep.CapacityRemainingMemory 13464}
#	&{ops.rep.CapacityRemainingDisk 45992}
#	&{ops.rep.CapacityRemainingContainers 199}

#
#
# Splunk format:
#
#

# original IFS
OIFS=$IFS;
OOFS=$OFS;

# filename
filename="apps_lst.csv";

whatsMyTarget() {
	echo "";
	echo "$(cf target)";
}

getDetails() {
	echo "";
	echo "$(cf buildpack-usage --verbose | egrep -v '^Following|^$' > ${filename})";
}

send2Statsd() {
	local filename=$1;
	local ipAddr=$2;
	local port=$3;
	local tag=$4;
	local dataCenter=$5;

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
			echo "${tag}.${dataCenter}.${aline[0]}.${aline[1]}.${aline[2]}.${hdrs[3]}:${aline[3]}|c" | nc -u -w0 ${ipAddr} ${port};
			echo "${tag}.${dataCenter}.${aline[0]}.${aline[1]}.${aline[2]}.${hdrs[4]}:${aline[4]}|c" | nc -u -w0 ${ipAddr} ${port};
			echo "${tag}.${dataCenter}.${aline[0]}.${aline[1]}.${aline[2]}.${hdrs[5]}:${aline[5]}|c" | nc -u -w0 ${ipAddr} ${port};
			echo "${tag}.${dataCenter}.${aline[0]}.${aline[1]}.${aline[2]}.${hdrs[6]}:${aline[6]}|c" | nc -u -w0 ${ipAddr} ${port};
		fi;
	done;

	# reset back the FS;
	IFS=$OIFS;
	OFS=$OOFS;
}

forward2Splunk() {
	local filename=$1;
	local fwdloc=$2;
	local tag=$3;
	local dataCenter=$4;
	local rate=$5;
	
	targetDir="${fwdloc}/${tag}/${dataCenter}";
	$(mkdir -p "${targetDir}" );

	targetFile="${targetDir}/${filename}";
	dtm=$(date +%s);
	#	$( cat ${filename} | sed "s/^/${dtm},/g" | sed "s/$/,${rate}/g" > ${targetFile} );
	$( cat ${filename} | sed "s/^/${dtm},/g" > ${targetFile} );
	echo "";
	echo "	... generated file forwarded to - ${targetFile}";
}

usage() {
	echo "";
	echo "${1}";
	echo "Usage: $0 [-l <splunk|statsd>] [-t <tagName>] [-d <dataCenter>] [ [-f <fwdLoc>] or [-i <ipAddr>] [-p <port>] ] " 1>&2; 
	echo "";
	exit 1; 
}



# ----------------
# main block
# ----------------
while getopts ":l:t:d:f:i:p:" o; do
    case "${o}" in
        l)
            _l=${OPTARG}
            if [ $_l != "splunk" ] && [ $_l != "statsd" ]; then
				usage "Invalid logger '${_l}'";
			fi
            ;;
        t)
            _t=${OPTARG}
            ;;
        d)
            _d=${OPTARG}
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
        *)
            usage;
            ;;
    esac
done
shift $((OPTIND-1))

# evaluate the arguments
if [ -z "${_l}" ] || [ -z "${_t}" ] || [ -z "${_d}" ]; then
    usage
else
	if [ $_l == "splunk" ] && [ -z "${_f}" ]; then
		usage "For Splunk logger, 'forwarder location' is required";
	elif [ $_l == "statsd" ] && [ -z "${_i}" ]; then
		usage "For Statsd logger, 'target ipAddress' is required";
	elif [ $_l == "statsd" ] && [ -z "${_p}" ]; then
		usage "For Statsd logger, 'port' is required";
	fi;

	logger="${_l}";
	tag="${_t}";
	dataCenter="${_d}";
	# echo "logger = ${logger}"
	# echo "tag = ${tag}"
	# echo "dc = ${dataCenter}"

	fwdLoc="${_f}";
	# echo "fwdLoc = ${fwdLoc}"

	ipAddr="${_i}";
	port="${_p}";

	# echo "ipAddr = ${ipAddr}"
	# echo "port = ${port}"
fi


# where am I targeted?
whatsMyTarget;
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

echo "	... get the app details";
getDetails;
echo "	... details file - ${filename}";

if [ $logger == "statsd" ]; then
	send2Statsd "$filename" "$ipAddr" "$port" "$tag" "$dataCenter";
elif [ $logger == "splunk" ]; then
	forward2Splunk "$filename" "$fwdLoc" "$tag" "$dataCenter" "$rate";
else
	echo "Invalid logger, cannot process ...";
fi;	

echo "	Done!!! ";
