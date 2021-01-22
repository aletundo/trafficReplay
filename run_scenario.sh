#!/bin/bash

export CONFIG_SERVICE_PASSWORD="conf_serv"
export NOTIFICATION_SERVICE_PASSWORD="not_serv"
export STATISTICS_SERVICE_PASSWORD="stat_serv"
export ACCOUNT_SERVICE_PASSWORD="acc_serv"
export MONGODB_PASSWORD="mongo"

scenario_name=$1
service_name=$2
service_port=$3

# Copy instrumentation source
rsync --update -raz "monitor/$service_name-service/filter" "piggymetrics/$service_name-service/src/main/java/com/piggymetrics/account/"
rsync --update -raz "monitor/$service_name-service/config/"*.java "piggymetrics/$service_name-service/src/main/java/com/piggymetrics/account/config/"
rsync --update -raz "monitor/$service_name-service/logback-spring.xml" "piggymetrics/$service_name-service/src/main/resources/logback-spring.xml"

# Package with maven
cd piggymetrics
mvn -DskipTests package
cd ..

rsync --update -raz monitor/docker-compose.custom.yml piggymetrics/

# Build services
docker-compose -f piggymetrics/docker-compose.custom.yml build rabbitmq config registry auth-mongodb auth-service "$service_name-service" "$service_name-mongodb"

# Run services
docker-compose -f piggymetrics/docker-compose.custom.yml up -d config registry
docker-compose -f piggymetrics/docker-compose.custom.yml up -d rabbitmq auth-mongodb "$service_name-mongodb"
sleep 5
docker-compose -f piggymetrics/docker-compose.custom.yml up -d auth-service "$service_name-service"

auth_service_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep piggymetrics_auth-service | awk '{print $1}'))
count=1
while [ -z "$auth_service_ip" ]
do
	if (( $count > 50 )); then
		echo "No IP address found for auth-service after 50 retries"
		exit 1
	else
	    sleep 10
		auth_service_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep piggymetrics_auth-service | awk '{print $1}'))
		count=$((count+1))
	fi
done

service_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep piggymetrics_$service_name-service | awk '{print $1}'))
count=1
while [ -z "$service_ip" ]
do
	if (( $count > 50 )); then
		echo "No IP address found for $service_name-service after 50 retries"
		exit 1
	else
	    sleep 10
		service_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep piggymetrics_$service_name-service | awk '{print $1}'))
		count=$((count+1))
	fi
done

if [ -n "$service_ip" ]; then
	printf "Trying to connect to auth-service ($auth_service_ip)"
	until [ $(curl -s -o /dev/null -w "%{http_code}" $auth_service_ip:5000) != "000" ]; do
	    printf '.'
	    sleep 10
	done
	echo "Connected to auth-service"
fi

if [ -n "$service_ip" ]; then
	printf "Trying to connect to $service_name-service ($service_ip)"
	until [ $(curl -s -o /dev/null -w "%{http_code}" $service_ip:$service_port) != "000" ]; do
	    printf '.'
	    sleep 10
	done
	echo "Connected to $service_name-service"
fi

interface=$(sudo brctl show | awk 'NF>1 && NR>1 {print $1}' | grep br-)

echo "Interface: $interface"
echo "auth-service IP: $auth_service_ip"
echo "$service_name-service IP: $service_ip"

sleep 30

sudo tcpdump -U -i $interface -n "dst host $service_ip or src host $service_ip" -w "./scenarios/$service_name-service/$scenario_name.pcap" &

./scenarios/$service_name-service/$scenario_name.sh $auth_service_ip $service_ip

pid=$(ps -e | pgrep tcpdump)
kill -2 $pid

docker cp "$(docker-compose -f piggymetrics/docker-compose.custom.yml ps -q $service_name-service)":/logs/monitor.log "./scenarios/$service_name-service/$scenario_name.log"
docker cp "$(docker-compose -f piggymetrics/docker-compose.custom.yml ps -q $service_name-service)":/logs/monitor-debug.log "./scenarios/$service_name-service/$scenario_name-debug.log"