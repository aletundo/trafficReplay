#!/bin/bash

scenario_name=$1
service_name=$2
service_port=$3

# Copy instrumentation source
yes | cp -r "monitor/$service_name-service/filter" "piggymetrics/$service_name-service/src/main/java/com/piggymetrics/account/"
yes | cp "monitor/$service_name-service/config/"*.java "piggymetrics/$service_name-service/src/main/java/com/piggymetrics/account/config/"
yes | cp "monitor/$service_name-service/logback-spring.xml" "piggymetrics/$service_name-service/src/main/resources/logback-spring.xml"

# Package with maven
cd piggymetrics
mvn -DskipTests package
cd ..


yes | cp monitor/docker-compose.custom.yml piggymetrics/

# Build services
docker-compose -f piggymetrics/docker-compose.custom.yml build config registry auth-mongodb auth-service "$service_name-service" "$service_name-mongodb"

# Run services
docker-compose -f piggymetrics/docker-compose.custom.yml up -d config registry
docker-compose -f piggymetrics/docker-compose.custom.yml up -d auth-mongodb "$service_name-mongodb"
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

if [ !-z "$service_ip" ]; then
	printf 'Trying to connect to $service_name-service($service_ip)'
	until [ $(curl -s -o /dev/null -w "%{http_code}" $service_ip:$service_port) != "000" ]; do
	    printf '.'
	    sleep 20
	done
	echo "Connected to $service_name-service"
fi

interface=$(sudo brctl show | awk 'NF>1 && NR>1 {print $1}' | grep br-)

./scenarios/$scenario_name.sh $auth_service_ip $service_ip