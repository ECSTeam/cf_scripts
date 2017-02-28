# common functions

# get list of all apps, with allocations, in csv format
profile_apps() {
	local filename="$1";
	echo "";
	echo "$(cf buildpack-usage --verbose | egrep -v '^Following|^$' > ${filename})";
}

# get buildpacks, and list of all apps using it, in csv format
list_apps_by_buildpacks() {
	local filename="$1";
	echo "";
	echo "$(cf buildpack-usage --csv | egrep -v '^Following|^$' > ${filename})";
}

# get list of events for all apps, in csv format
list_of_events() {
	local filename="$1";
	local args="$2";
	echo "";
	echo "$(cf get-events ${args} | egrep -v '^Following|^$' > ${filename})";
}

# get space use deatils, in csv format
space_use_list() {
	local filename="$1";
	local args="$2";
	echo "";
	echo "$(cf usage-report ${args} | egrep -v '^Following|^$' > ${filename})";
}

# get the list of buildpacks, and their status, in csv format
list_buildpacks_status() {
	local filename="$1";
	echo "";
	echo "$(cf buildpacks | egrep -v 'Getting|^$' | tr -s ' ' | sed -e 's/ /,/g' > ${filename})";
}
