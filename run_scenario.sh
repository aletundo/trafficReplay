#!/bin/bash

# Usage: ./run_scenario.sh -s scenario_name -svc service_name [--monitor] [--trace] [--latency]

function main() {

	while [[ "$#" -gt 0 ]]; do
	    case $1 in
	        -s|--scenario) scenario_name="$2"; shift ;;
			-svc|--service) service_name="$2"; shift ;;
			-m|--monitor) monitor=1;;
			-t|--trace) trace=1 ;;
			-l|--latency) latency=1 ;;
	        *) echo "Unknown parameter passed: $1"; exit 1 ;;
	    esac
	    shift
	done

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

	# Retrieve account-service IP
	account_service_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep piggymetrics_account-service | awk '{print $1}'))
	count=1
	while [ -z "$account_service_ip" ]
	do
		if (( $count > 50 )); then
			echo "No IP address found for account-service after 50 retries"
			exit 1
		else
		    sleep 10
			account_service_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep piggymetrics_account-service | awk '{print $1}'))
			count=$((count+1))
		fi
	done

	# Retrieve statistics-service IP
	statistics_service_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep piggymetrics_statistics-service | awk '{print $1}'))
	count=1
	while [ -z "$statistics_service_ip" ]
	do
		if (( $count > 50 )); then
			echo "No IP address found for statistics-service after 50 retries"
			exit 1
		else
		    sleep 10
			statistics_service_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep piggymetrics_statistics-service | awk '{print $1}'))
			count=$((count+1))
		fi
	done

	# Retrieve notification-service IP
	notification_service_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep piggymetrics_notification-service | awk '{print $1}'))
	count=1
	while [ -z "$notification_service_ip" ]
	do
		if (( $count > 50 )); then
			echo "No IP address found for statistics-service after 50 retries"
			exit 1
		else
		    sleep 10
			notification_service_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep piggymetrics_notification-service | awk '{print $1}'))
			count=$((count+1))
		fi
	done

	echo "auth-service IP: $auth_service_ip"
	echo "account-service IP: $account_service_ip"
	echo "statistics-service IP: $statistics_service_ip"
	echo "notification-service IP: $notification_service_ip"

	# Check services are 'at least' ready to serve
	if [ -n "$auth_service_ip" ]; then
		printf "Trying to connect to auth-service ($auth_service_ip) "
		until [ $(curl -s -o /dev/null -w "%{http_code}" $auth_service_ip:5000) != "000" ]; do
		    printf '.'
		    sleep 10
		done
		echo "Connected to auth-service"
	fi

	if [ -n "$account_service_ip" ]; then
		printf "Trying to connect to account-service ($account_service_ip) "
		until [ $(curl -s -o /dev/null -w "%{http_code}" $account_service_ip:6000) != "000" ]; do
		    printf '.'
		    sleep 10
		done
		echo "Connected to account-service"
	fi

	if [ -n "$statistics_service_ip" ]; then
		printf "Trying to connect to statistics-service ($statistics_service_ip) "
		until [ $(curl -s -o /dev/null -w "%{http_code}" $statistics_service_ip:7000) != "000" ]; do
		    printf '.'
		    sleep 10
		done
		echo "Connected to statistics-service"
	fi

	if [ -n "$notification_service_ip" ]; then
		printf "Trying to connect to notification-service ($notification_service_ip) "
		until [ $(curl -s -o /dev/null -w "%{http_code}" $notification_service_ip:8000) != "000" ]; do
		    printf '.'
		    sleep 10
		done
		echo "Connected to notification-service"
	fi

	if [[ $service_name == "account" ]]; then
		service_ip=$account_service_ip
	elif [[ $service_name == "statistics" ]]; then
		service_ip=$statistics_service_ip
	elif [[ $service_name == "notification" ]]; then
		service_ip=$notification_service_ip
	fi

	if [[ -n $monitor ]]; then
		clean_monitor_logs
	fi


	if [[ -n $trace ]]; then
		start_tracing
	fi

	echo "Running scenario $scenario_name..."
	if [[ -n $latency ]]; then
		echo "Enabled latency log"
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
	fi
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
