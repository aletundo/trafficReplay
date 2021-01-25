#!/bin/bash

# Usage: ./run-scenario.sh -s scenario_name -svc service_name -p service_port [--no-init] [--no-build] [--no-run] [--monitor] [--trace] [--latency]

function main() {
	export CONFIG_SERVICE_PASSWORD="conf_serv"
	export NOTIFICATION_SERVICE_PASSWORD="not_serv"
	export STATISTICS_SERVICE_PASSWORD="stat_serv"
	export ACCOUNT_SERVICE_PASSWORD="acc_serv"
	export MONGODB_PASSWORD="mongo"

	scenario_name=$1
	service_name=$2
	service_port=$3

	while [[ "$#" -gt 0 ]]; do
	    case $1 in
	        -s|--scenario) scenario_name="$2"; shift ;;
			-svc|--service) service_name="$2"; shift ;;
			-p|--port) service_port="$2"; shift ;;
	        -ni|--no-init) no_init=1 ;;
			-nb|--no-build) no_build=1 ;;
	        -nr|--no-run) no_run=1;;
			-m|--monitor) monitor=1;;
			-t|--trace) trace=1 ;;
			-l|--latency) latency=1 ;;
	        *) echo "Unknown parameter passed: $1"; exit 1 ;;
	    esac
	    shift
	done

	rsync --update -raz monitor/docker-compose.custom.yml piggymetrics/

	if [[ -n $monitor ]]; then
		copy_monitor_code
	fi

	if [[ -z $no_build ]]; then
		build_services
	fi

	if [[ -z $no_run ]]; then
		run_services
	fi

	# Retrieve auth-service IP
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

	# Retrieve service IP
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

	echo "auth-service IP: $auth_service_ip"
	echo "$service_name-service IP: $service_ip"

	# Check services are 'at least' ready to serve
	if [ -n "$auth_service_ip" ]; then
		printf "Trying to connect to auth-service ($auth_service_ip) "
		until [ $(curl -s -o /dev/null -w "%{http_code}" $auth_service_ip:5000) != "000" ]; do
		    printf '.'
		    sleep 10
		done
		echo "Connected to auth-service"
	fi

	if [ -n "$service_ip" ]; then
		printf "Trying to connect to $service_name-service ($service_ip) "
		until [ $(curl -s -o /dev/null -w "%{http_code}" $service_ip:$service_port) != "000" ]; do
		    printf '.'
		    sleep 10
		done
		echo "Connected to $service_name-service"
	fi


	if [[ -z $no_run ]]; then
		echo "Sleeping for 30s to '''ensure''' warm up of run services"
		sleep 30
	fi


	if [[ -n $trace ]]; then
		start_tracing
	fi

	echo "Running scenario $scenario_name..."
	if [[ -n $latency ]]; then
		echo "Enabled latency long"
		./scenarios/$service_name-service/$scenario_name.sh $auth_service_ip $service_ip > ./scenarios/$service_name-service/$scenario_name-latecy.log
	else
		./scenarios/$service_name-service/$scenario_name.sh $auth_service_ip $service_ip
	fi
	echo "Done!"

	if [[ -n $trace ]]; then
		stop_tracing
	fi

	if [[ -n $monitor ]]; then
		get_monitor_logs
		clean_monitor_logs
	fi
}

function copy_monitor_code() {
	echo "Copying monitor instrumentation code..."

	rsync --update -raz "monitor/$service_name-service/filter" "piggymetrics/$service_name-service/src/main/java/com/piggymetrics/account/"
	rsync --update -raz "monitor/$service_name-service/config/"*.java "piggymetrics/$service_name-service/src/main/java/com/piggymetrics/account/config/"
	rsync --update -raz "monitor/$service_name-service/logback-spring.xml" "piggymetrics/$service_name-service/src/main/resources/logback-spring.xml"

	echo "Done!"
}

function build_services() {
	echo "Building services..."

	# Package with maven
	cd piggymetrics
	mvn -DskipTests package
	cd ..

	# Build services
	docker-compose -f piggymetrics/docker-compose.custom.yml build rabbitmq config registry auth-mongodb auth-service "$service_name-service" "$service_name-mongodb"

	echo "Done!"
}

function run_services() {
	echo "Running services..."

	# Run services
	docker-compose -f piggymetrics/docker-compose.custom.yml up -d config registry
	docker-compose -f piggymetrics/docker-compose.custom.yml up -d rabbitmq auth-mongodb "$service_name-mongodb"
	sleep 5
	docker-compose -f piggymetrics/docker-compose.custom.yml up -d auth-service "$service_name-service"

	echo "Done!"
}

function start_tracing() {
	# Get Docker bridge network interface
	interface=$(sudo brctl show | awk 'NF>1 && NR>1 {print $1}' | grep br-)
	echo "Interface $interface selected for tracing"

	# Run tracing in background for the selected service
	sudo tcpdump -U -i $interface -n "dst host $service_ip or src host $service_ip" -w "./scenarios/$service_name-service/$scenario_name.pcap" &
}

function stop_tracing() {
	# Kill background tracing process
	pid=$(ps -e | pgrep tcpdump)
	sudo kill -2 $pid
	echo "Tracing stopped"
}

function get_monitor_logs() {
	echo "Copying monitor logs..."
	docker cp "$(docker-compose -f piggymetrics/docker-compose.custom.yml ps -q $service_name-service)":/logs/monitor.log "./scenarios/$service_name-service/$scenario_name.log"
	docker cp "$(docker-compose -f piggymetrics/docker-compose.custom.yml ps -q $service_name-service)":/logs/monitor-debug.log "./scenarios/$service_name-service/$scenario_name-debug.log"
	echo "Done!"
}

function clean_monitor_logs() {
	echo "Cleaning monitor logs..."
	docker-compose -f piggymetrics/docker-compose.custom.yml exec $service_name-service sh -c "echo > /logs/monitor.log"
	docker-compose -f piggymetrics/docker-compose.custom.yml exec $service_name-service sh -c "echo > /logs/monitor-debug.log"
	echo "Done!"
}

main "$@"; exit
