#!/bin/bash

function build_services() {
	echo "Building services..."

	# Package with maven
	cd piggymetrics
	mvn -DskipTests package
	cd ..

	# Build services
	docker-compose -f piggymetrics/docker-compose.custom.yml build

	echo "Done!"
}

function run_services() {
	echo "Running services..."

	# Run services
	docker-compose -f piggymetrics/docker-compose.custom.yml up -d config registry
	docker-compose -f piggymetrics/docker-compose.custom.yml up -d rabbitmq auth-mongodb account-mongodb notification-mongodb statistics-mongodb
	sleep 10
	docker-compose -f piggymetrics/docker-compose.custom.yml up -d auth-service account-service notification-service statistics-service

	echo "Done!"
}

export CONFIG_SERVICE_PASSWORD="conf_serv"
export NOTIFICATION_SERVICE_PASSWORD="not_serv"
export STATISTICS_SERVICE_PASSWORD="stat_serv"
export ACCOUNT_SERVICE_PASSWORD="acc_serv"
export MONGODB_PASSWORD="mongo"

while [[ "$#" -gt 0 ]]; do
    case $1 in
		-nb|--no-build) no_build=1 ;;
        -nr|--no-run) no_run=1;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

rsync --update -raz scenarios/docker-compose.custom.yml piggymetrics/

if [[ -z $no_build ]]; then
	build_services
fi

if [[ -z $no_run ]]; then
	run_services
fi

if [[ -z $no_run ]]; then
	echo "Sleeping for 30s to '''ensure''' warm up of run services"
	sleep 30
fi