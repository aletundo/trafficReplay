#!/bin/bash
#Devono essere passati almeno un argomento: il nome dell'interfaccia sulla quale ascoltare
#Se viene passato anche il secondo argomento indica la lista lista dei nomi delle applicazioni da monitorare

echo "Caputure script called with ${@}"

#Mancano gli argomenti obbligatori
if [[ $# -lt 3 ]] ; then
	echo 'missing args ---> ./capture_script.sh <test_dir> <name_pcap_file> <interface> [<list_of_container>]'
	exit 1
fi

if [ ! -d "$1" ];
then
	mkdir -p $1;
fi

cd $1

#Se esiste lo rimuovo per evitare di aggiungere righe
if [ -f "name_ip_mongo.txt" ]; then
	rm -f "name_ip_mongo.txt"
fi

if [ -f "list_names_mongo_containers.txt" ]; then
	rm -f "list_names_mongo_containers.txt"
fi

# FIXME: THESE ARE NOT MONGO CONTAINERS ONLY! THEY ARE ALL THE CONTAINERS RUNNING
docker ps --format "{{.Names}}" > "list_names_mongo_containers.txt"

#Salvataggio file con nomi dei container mongo associati a indirizzo ip
#LEggo da un file contenente tutti i nomi dei container mongo che voglio considerare

while read name; do
    name_mongo_cont=$name
	id_mongocontainer=$(docker ps -aqf "name="$name_mongo_cont)
	inspect=$(docker inspect $id_mongocontainer | grep "IPAddress")
	ipdb=${inspect%,*}     # trim everything past the last ,
	ipdb=${ipdb##*,}       # ...then remove everything before the last , remaining
	ipdb=$(grep -oP '(?<=").*?(?=")' <<< "$ipdb")
	ipdb=${ipdb##*:}
	ipdb=${ipdb##* }
	ipdb="$(echo -e "${ipdb}" | tr -d '[:space:]')"
	echo "Container $name_mongo_cont($ipdb)"
	if [ ! -f "name_ip_mongo.txt" ]; then
	    	echo "$name_mongo_cont;$ipdb" > "name_ip_mongo.txt"
	else
		echo "$name_mongo_cont;$ipdb" >> "name_ip_mongo.txt"
	fi
done < "list_names_mongo_containers.txt"

#C'è solo interfaccia quindi catturo tutto il traffico sull'interfaccia specificata
if [[ $# -eq 3 ]] ; then
	echo "Capturing all traffic on interface"
	sudo tcpdump -U -i $3 -w $2
	exit 0
fi

#C'è un solo nome di container quindi catturo pacchetti solo che comprendono questo container negli ip di dst o src
if [[ $# -eq 4 ]] ; then
	echo "Capturing traffic for ${container_name}"
	id_application=$(docker ps -aqf "name="$4)
	inspect=$(docker inspect $id_application | grep "IPAddress")
	ipapp=${inspect%,*}     # trim everything past the last ,
	ipapp=${ipapp##*,}       # ...then remove everything before the last , remaining
	ipapp=$(grep -oP '(?<=").*?(?=")' <<< "$ipapp")
	ipapp=${ipapp##*:}
	ipapp=${ipapp##* }
	ipapp="$(echo -e "${ipapp}" | tr -d '[:space:]')"
	echo "$container_name IP: $ipapp"
	sudo tcpdump -U -i $3 -n "dst host $id_application or src host $id_application" -w $2
	exit 0
#Lista di container --> devo catturare solo interazioni tra questi specificati ed i loro database
#Se voglio catturare anche nterazione con i loro database devo passare anche nome dei loro container (dei db)
else
	echo "Capturing traffic for several containers"
	i=3
	condizione="( "
	list=${@:4:$(($#-3))}
	echo "${list[*]}"
	for container_name in $list; do
		id_application=$(docker ps -aqf "name="$container_name)
		inspect=$(docker inspect $id_application | grep "IPAddress")
		ipapp=${inspect%,*}     # trim everything past the last ,
		ipapp=${ipapp##*,}       # ...then remove everything before the last , remaining
		ipapp=$(grep -oP '(?<=").*?(?=")' <<< "$ipapp")
		ipapp=${ipapp##*:}
		ipapp=${ipapp##* }
		ipapp="$(echo -e "${ipapp}" | tr -d '[:space:]')"
		echo "$container_name IP: $ipapp"
		i=$((i+1))
		if [[ $i -eq $# ]] ; then
			condizione="$condizione host $ipapp )"
		else
			condizione="$condizione host $ipapp or"
		fi
	done
	echo "Capturing with condition: $condizione"
	sudo tcpdump -U -i $3 -n "$condizione" -w $2
	exit 0
fi
cd ..
