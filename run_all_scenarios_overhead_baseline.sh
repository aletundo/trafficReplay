#!/bin/bash

export CONFIG_SERVICE_PASSWORD="conf_serv"
export NOTIFICATION_SERVICE_PASSWORD="not_serv"
export STATISTICS_SERVICE_PASSWORD="stat_serv"
export ACCOUNT_SERVICE_PASSWORD="acc_serv"
export MONGODB_PASSWORD="mongo"

function run_services() {
	echo "Running services..."

	# Run services
	docker-compose -f piggymetrics/docker-compose.custom.yml up -d config registry
	docker-compose -f piggymetrics/docker-compose.custom.yml up -d rabbitmq auth-mongodb account-mongodb notification-mongodb statistics-mongodb
	sleep 10
	docker-compose -f piggymetrics/docker-compose.custom.yml up -d auth-service account-service notification-service statistics-service

	echo "Done!"

	echo "Sleeping for 30s to '''ensure''' warm up of run services"
	sleep 30
}

runs=$1;

mkdir -p overhead-experiments/baseline

./prepare_scenario_run.sh

for (( i = 0; i < $runs; i++ )); do
	if [[ $i > 0 ]]; then
		run_services
	fi

	sudo systemctl start metricbeat.service

	./run_scenario.sh -s 001_scenario -svc account --latency
	./run_scenario.sh -s 002_scenario -svc account --latency
	./run_scenario.sh -s 003_scenario -svc account --latency
	./run_scenario.sh -s 004_scenario -svc account --latency
	./run_scenario.sh -s 005_scenario -svc account --latency
	./run_scenario.sh -s 006_scenario -svc account --latency
	./run_scenario.sh -s 007_scenario -svc account --latency
	./run_scenario.sh -s 008_scenario -svc account --latency

	mkdir -p overhead-experiments/baseline/account-service/run-$i
	cp scenarios/account-service/*.log overhead-experiments/baseline/account-service/run-$i/

	./run_scenario.sh -s 001_scenario -svc statistics --latency
	./run_scenario.sh -s 002_scenario -svc statistics --latency
	./run_scenario.sh -s 003_scenario -svc statistics --latency
	./run_scenario.sh -s 004_scenario -svc statistics --latency

	mkdir -p overhead-experiments/baseline/statistics-service/run-$i
	cp scenarios/statistics-service/*.log overhead-experiments/baseline/statistics-service/run-$i/

	./run_scenario.sh -s 001_scenario -svc notification --latency
	./run_scenario.sh -s 002_scenario -svc notification --latency
	./run_scenario.sh -s 003_scenario -svc notification --latency
	./run_scenario.sh -s 004_scenario -svc notification --latency

	mkdir -p overhead-experiments/baseline/notification-service/run-$i
	cp scenarios/notification-service/*.log overhead-experiments/baseline/notification-service/run-$i/

	sudo systemctl stop metricbeat.service

	docker-compose -f piggymetrics/docker-compose.custom.yml down
done

docker rmi $(docker images -f "reference=piggymetrics_*" -q)

