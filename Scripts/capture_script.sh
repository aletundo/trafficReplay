#!/bin/bash
# At least one argument needed, the interface where to listen
# The second argument is the list of names of the applications to monitor
echo $#

# Check for missing arguments
if [[ $# -lt 3 ]] ; then
	echo 'missing args ---> ./capture_script.sh <test_dir> <name_pcap_file> <interface> [<list_of_container>]'
	exit 1
fi

if [ ! -d "$1" ];
then
	mkdir -p $1;
fi

cd $1

# Remove it to avoid extra lines
if [ -f "name_ip_mongo.txt" ]; then
	rm -f "name_ip_mongo.txt"
fi

if [ -f "list_names_mongo_containers.txt" ]; then
	rm -f "list_names_mongo_containers.txt"
fi

docker ps --format "{{.Names}}" > "list_names_mongo_containers.txt"

# Saving files with the names of mongo containers associated to ip address
while read name; do
    name_mongo_cont=$name
	echo "nome del container = $name_mongo_cont"
	id_mongocontainer=$(docker ps -aqf "name="$name_mongo_cont)
	inspect=$(docker inspect $id_mongocontainer | grep "IPAddress")
	ipdb=${inspect%,*}     # trim everything past the last ,
	ipdb=${ipdb##*,}       # ...then remove everything before the last , remaining
	ipdb=$(grep -oP '(?<=").*?(?=")' <<< "$ipdb")
	ipdb=${ipdb##*:}
	ipdb=${ipdb##* }
	ipdb="$(echo -e "${ipdb}" | tr -d '[:space:]')"
	echo "ip container = "$ipdb
	if [ ! -f "name_ip_mongo.txt" ]; then
	    echo "$name_mongo_cont;$ipdb" > "name_ip_mongo.txt"
	else
		echo "$name_mongo_cont;$ipdb" >> "name_ip_mongo.txt"
	fi
done < "list_names_mongo_containers.txt"
# Only one interface, capture all the traffic on the interface
if [[ $# -eq 3 ]] ; then
	echo "c'è solo l'interfaccia quindi catturo tutto"
	sudo tcpdump -U -i $3 -w $2
	exit 0
fi
# Only one container name, capture only packets that have this container as src or dst
if [[ $# -eq 4 ]] ; then
	echo "c'è interfaccia e 1 container"
	id_application=$(docker ps -aqf "name="$4)
	inspect=$(docker inspect $id_application | grep "IPAddress")
	ipapp=${inspect%,*}     # trim everything past the last ,
	ipapp=${ipapp##*,}       # ...then remove everything before the last , remaining
	ipapp=$(grep -oP '(?<=").*?(?=")' <<< "$ipapp")
	ipapp=${ipapp##*:}
	ipapp=${ipapp##* }
	ipapp="$(echo -e "${ipapp}" | tr -d '[:space:]')"
	echo "ip dell'applicazione $container_name : $ipapp"
	sudo tcpdump -U -i $3 -n "dst host $id_application or src host $id_application" -w $2
	exit 0

#Container list, capture interactions between them and their databases
else
	echo "c'è interfaccia e lista di container"
	i=3
	condizione="( "
	list=${@:4:$(($#-3))}
	echo $list
	for container_name in $list; do
		echo $container_name
		id_application=$(docker ps -aqf "name="$container_name)
		inspect=$(docker inspect $id_application | grep "IPAddress")
		ipapp=${inspect%,*}     # trim everything past the last ,
		ipapp=${ipapp##*,}       # ...then remove everything before the last , remaining
		ipapp=$(grep -oP '(?<=").*?(?=")' <<< "$ipapp")
		ipapp=${ipapp##*:}
		ipapp=${ipapp##* }
		ipapp="$(echo -e "${ipapp}" | tr -d '[:space:]')"
		echo "id dell'applicazione $container_name : $ipapp"
		i=$((i+1))
		if [[ $i -eq $# ]] ; then
			condizione="$condizione host $ipapp )"
		else
			condizione="$condizione host $ipapp or"
		fi
	done
	sudo tcpdump -U -i $3 -n "$condizione" -w $2
	echo "condizione finale = $condizione"
	exit 0
fi
cd ..
