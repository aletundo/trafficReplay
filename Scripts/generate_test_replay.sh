#!/bin/bash
# generates test report with mongoreplay
# usage: ./generate_test_replay.sh MongoStreamDirectory TestDir
if [[ $# -lt 1 ]] ; then
    echo 'missing directories ----> use ./generate_test_replay.sh <mongo_directory> <test_directory>'
    exit 0
fi


# First execute mong replay for the files in the folder
cd $2/$1

echo "Executing mongoreplay for files in $2/$1"

for filename in $( ls -v *.cap ); do
	name=${filename%%.cap*}
	ip_mongo_cont=$( sed '1q;d' $name.txt )
	echo "Old Mongo container IP: $ip_mongo_cont"
	trovato=0
	while read mongo_cont; do
		IFS=';'
		read -ra mongo_info <<< "$mongo_cont"
		#echo "nome = ${mongo_info[0]}"
		#echo "ip letto da file = $ip_mongo_cont"
		#echo "ip preso da nome del cont ${mongo_info[1]} nel file originale"
		if [ $ip_mongo_cont == ${mongo_info[1]} ]; then
			#echo "nome2 = "${mongo_info[0]}
			all_name=${mongo_info[0]}
			part_of_name="${all_name%_*}"
			echo "Part for name: $part_of_name"
			#id_mongocontainer=$(docker ps | grep $part_of_name | awk '{print $1}')
			#echo $id_mongocontainer
			#echo "id container = "$id_mongocontainer
			ipdb=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep $part_of_name| awk '{print $1}'))
			#inspect=$(docker inspect $id_mongocontainer | grep "IPAddress")
			#ipdb=${inspect%,*}     # trim everything past the last ,
			#ipdb=${ipdb##*,}       # ...then remove everything before the last , remaining
			#ipdb=$(grep -oP '(?<=").*?(?=")' <<< "$ipdb")
			#ipdb=${ipdb##*:}
			#ipdb=${ipdb##* }
			#ipdb="$(echo -e "${ipdb}" | tr -d '[:space:]')"
			echo "Mongo container IP found: $ipdb"
			trovato=1
			break;
		fi
	done < "../name_ip_mongo.txt"
	if [[ $trovato == 1 ]];
	then
		if [ ! -d ${mongo_info[0]} ];
		then
			mkdir ${mongo_info[0]};
		fi
		cd ${mongo_info[0]}
		if [ ! -d "recordings" ];
		then
			mkdir "recordings";
		fi

		if [ ! -d "reports" ];
		then
			mkdir "reports";
		fi

		cd reports

		if [ ! -d "CMDs" ];
		then
			mkdir "CMDs";
		fi

		if [ ! -d "Config" ];
		then
			mkdir "Config";
		fi

		cd ..

		if [ ! -d "monitor" ];
		then
			mkdir "monitor";
		fi
		cd ..
		mongoreplay record -f $filename -p ../$1/${mongo_info[0]}/recordings/test_$name.bson
		# Create a folder with reports of control packets and another one with database packets
		if  ! ([[ $name == *"find"* ]] || [[ $name == *"delete"* ]] || [[ $name == *"update"* ]] || [[ $name == *"insert"* ]] || [[ $name == *"count"* ]]);
		then
			echo "Play of ../$1/${mongo_info[0]}/recordings/test_$name.bson"
			mongoreplay play -p ../$1/${mongo_info[0]}/recordings/test_$name.bson --report ../$1/${mongo_info[0]}/reports/Config/test-$name.json --collect json --host mongodb://user:mongo@$ipdb:27017/piggymetrics
			 # remove file if empty
			if [ ! -s ../$1/${mongo_info[0]}/reports/Config/test-$name.json ];
			then
				echo "Removing test-$name.json"
				rm -f ../$1/${mongo_info[0]}/reports/Config/test-$name.json
			fi
		else
			mongoreplay play -p ../$1/${mongo_info[0]}/recordings/test_$name.bson --report ../$1/${mongo_info[0]}/reports/CMDs/test-$name.json --collect json --host mongodb://user:mongo@$ipdb:27017/piggymetrics
		fi
		echo "Monitor of ../$1/${mongo_info[0]}/recordings/test_$name.bson"
		mongoreplay monitor -p ../$1/${mongo_info[0]}/recordings/test_$name.bson --report ../$1/${mongo_info[0]}/monitor/monitoring-$name.json --collect json
	fi
done
