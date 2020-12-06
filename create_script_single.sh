#!/bin/bash

export CONFIG_SERVICE_PASSWORD="conf_serv"
export NOTIFICATION_SERVICE_PASSWORD="not_serv"
export STATISTICS_SERVICE_PASSWORD="stat_serv"
export ACCOUNT_SERVICE_PASSWORD="acc_serv"
export MONGODB_PASSWORD="mongo"

unset IFS

VERSION_DIR=$1

cd $VERSION_DIR

printf -- "-------------------------------------------------\n"
printf "PWD: $PWD\n"
printf -- "-------------------------------------------------\n"

if [ -z "$( find * -type d -name 'Test*' )" ]; then
	echo "Nessun test per questa cartella"
	exit 1
fi

unset name

sudo chmod 777 Test*

ls -d Test* -v

for name in $( ls -d Test* -v ); do
	printf -- "-------------------------------------------------\n"
	printf "Test name: $name\n"
	printf -- "-------------------------------------------------\n"
	printf "Splitting REST"
	./split.sh $name/interaction.pcap $name/SplitRest
	printf "Splitting MongoDB"
	./split_mongo.sh $name/interaction.pcap $name/SplitMongo
done

printf "Generating REST replay scripts"
./CreateTestPy.sh 1 25
printf "Generating Python complete test script"
./automatic_union.sh 1 25

cd piggymetrics
docker-compose  -f docker-compose.yml -f docker-compose.dev.yml up -d auth-mongodb statistics-mongodb notification-mongodb account-mongodb

sleep 10
cd ..
unset name

printf "Generating MongoDB replay scripts"
for name in  $( ls -d Test* -v ); do
	printf -- "-------------------------------------------------\n"
	printf "Test name: $name\n"
	printf -- "-------------------------------------------------\n"
	./generate_test_replay.sh SplitMongo $name
done

cd piggymetrics
docker-compose down

printf -- "-------------------------------------------------\n"
printf "PWD: $PWD\n"
printf -- "-------------------------------------------------\n"

cd ..
unset name

printf "Generating Auth mock"

#for dirname in $( find * -type d -maxdepth 1 -name 'Test*'  | sort -z  ); do
for name in  $( ls -d Test* -v ); do
	printf -- "-------------------------------------------------\n"
	printf "Test name: $name\n"
	printf -- "-------------------------------------------------\n"
	while read mongo_cont; do
		IFS=';'
		read -ra mongo_info <<< "$mongo_cont"
		if [[ ${mongo_info[0]} == *"piggymetrics_notification-service"* ]]; then
			old_ip_not=${mongo_info[1]}
		fi
		if [[ ${mongo_info[0]} == *"piggymetrics_statistics-service"* ]]; then
			old_ip_stat=${mongo_info[1]}
		fi
		if [[ ${mongo_info[0]} == *"piggymetrics_auth-service"* ]]; then
			old_ip_auth=${mongo_info[1]}
		fi
		if [[ ${mongo_info[0]} == *"piggymetrics_account-service"* ]]; then
			old_ip_acc=${mongo_info[1]}
		fi
	done < "$name/name_ip_mongo.txt"
	echo $old_ip_auth $old_ip_acc
	echo $old_ip_auth $old_ip_stat
	echo $old_ip_auth $old_ip_not
	echo $name
	python3 extract_http_data.py $name/interaction.pcap $old_ip_auth $old_ip_acc auth-mock-response-acc.json
	python3 extract_http_data.py $name/interaction.pcap $old_ip_auth $old_ip_stat auth-mock-response-stat.json
	python3 extract_http_data.py $name/interaction.pcap $old_ip_auth $old_ip_not auth-mock-response-not.json
done

./create_auth_resp.sh auth-mock-response-acc
./create_auth_resp.sh auth-mock-response-stat
./create_auth_resp.sh auth-mock-response-not
chmod +x auth-mock-response-acc.sh
chmod +x auth-mock-response-stat.sh
chmod +x auth-mock-response-not.sh

printf "Generating test suites"

./automatic_copy.sh 1 25 Account
./automatic_copy.sh 1 25 Statistics
./automatic_copy.sh 1 25 Notification

cd ..
unset IFS