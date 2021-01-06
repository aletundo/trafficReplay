#!/bin/bash

export CONFIG_SERVICE_PASSWORD="conf_serv"
export NOTIFICATION_SERVICE_PASSWORD="not_serv"
export STATISTICS_SERVICE_PASSWORD="stat_serv"
export ACCOUNT_SERVICE_PASSWORD="acc_serv"
export MONGODB_PASSWORD="mongo"

VERSION_DIR=$1

cd $VERSION_DIR

printf -- "-------------------------------------------------\n"
printf "PWD: $PWD\n"
printf -- "-------------------------------------------------\n"

subdir=$(basename $PWD)

echo $subdir

yes | cp -a  ../Scripts/.  .

cd piggymetrics

mvn package -DskipTests

docker-compose  -f docker-compose.yml -f docker-compose.dev.yml build
docker-compose  -f docker-compose.yml -f docker-compose.dev.yml up -d --force-recreate config registry
docker-compose  -f docker-compose.yml -f docker-compose.dev.yml up -d --force-recreate auth-mongodb statistics-mongodb notification-mongodb account-mongodb rabbitmq
docker-compose  -f docker-compose.yml -f docker-compose.dev.yml up -d --force-recreate auth-service
docker-compose  -f docker-compose.yml -f docker-compose.dev.yml up -d --force-recreate statistics-service account-service notification-service

ipstat=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep piggymetrics_statistics-service | awk '{print $1}'))
count=1
while [ -z "$ipstat" ]
do
	count=$((count+1))
	if (( $count > 50 )); then
		ipstat="non_connesso"
	else
		sleep 20
		ipstat=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep piggymetrics_statistics-service | awk '{print $1}'))
		count=$((count+1))
	fi
done


ipnot=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep piggymetrics_notification-service | awk '{print $1}'))
count=1
while [ -z "$ipnot" ]
do
	if (( $count > 50 )); then
		ipnot="non_connesso"
	else
		sleep 20
		ipnot=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep piggymetrics_notification-service | awk '{print $1}'))
		count=$((count+1))
	fi
done


ipacc=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep piggymetrics_account-service | awk '{print $1}'))
count=1
while [ -z "$ipacc" ]
do
	if (( $count > 50 )); then
		ipacc="non_connesso"
	else
		sleep 20
		ipacc=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep piggymetrics_account-service | awk '{print $1}'))
		count=$((count+1))
	fi
done



ipauth=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep piggymetrics_auth-service | awk '{print $1}'))
count=1
while [ -z "$ipauth" ]
do
	if (( $count > 50 )); then
		ipauth="non_connesso"
	else
		sleep 20
		ipauth=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep piggymetrics_auth-service | awk '{print $1}'))
		count=$((count+1))
	fi
done


if [ "$ipstat" != "non_connesso" ]; then
	printf "Trying to connect statistics service ..."
	until [ $(curl -s -o /dev/null -w "%{http_code}" $ipstat:7000) != "000" ]; do
		printf '.'
		sleep 20
	done
	printf "Connected to statistics service \n"
fi


if [ "$ipacc" != "non_connesso" ]; then
	printf "Trying to connect account service ..."
	until [ $(curl -s -o /dev/null -w "%{http_code}" $ipacc:6000) != "000" ]; do
		printf '.'
		sleep 20
	done
	printf "Connected to account service \n"
fi


if [ "$ipnot" != "non_connesso" ]; then
	printf "Trying to connect notification service ..."
	until [ $(curl -s -o /dev/null -w "%{http_code}" $ipnot:8000) != "000" ]; do
		printf '.'
		sleep 20
	done
	printf "Connected to notification service \n"
fi


if [ "$ipauth" != "non_connesso" ]; then
	printf "Trying to connect auth service ..."
	until [ $(curl -s -o /dev/null -w "%{http_code}" $ipauth:5000) != "000" ]; do
		printf '.'
		sleep 20
	done
	printf "Connected to auth service \n"
fi

interfaccia=$(sudo brctl show | awk 'NF>1 && NR>1 {print $1}' | grep br-)

printf "We are going to capture interface: $interfaccia\n\n"

printf -- "-------------------------------------------------\n"
printf "PWD: $PWD\n"
printf -- "-------------------------------------------------\n"

cd ../..

printf -- "-------------------------------------------------\n"
printf "PWD: $PWD\n"
printf -- "-------------------------------------------------\n"

cd Test

sleep 30

sudo ./automatic_capture.sh $interfaccia acc_$ipacc auth_$ipauth stat_$ipstat not_$ipnot $subdir

cd ..

cd $VERSION_DIR

cd piggymetrics

docker-compose down

cd ../..