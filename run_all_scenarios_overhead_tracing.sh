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
	sleep 60
}

runs=$1;

mkdir -p overhead-experiments/tracing

rm -rf piggymetrics
git clone https://github.com/sqshq/piggymetrics.git

./prepare_scenario_run.sh

for (( i = 0; i < $runs; i++ )); do
	if [[ $i > 0 ]]; then
		run_services
	fi

	sudo systemctl start metricbeat.service

	./run_scenario.sh -s 001_scenario -svc account --trace --latency
	./run_scenario.sh -s 002_scenario -svc account --trace --latency
	./run_scenario.sh -s 003_scenario -svc account --trace --latency
	./run_scenario.sh -s 004_scenario -svc account --trace --latency
	./run_scenario.sh -s 005_scenario -svc account --trace --latency
	./run_scenario.sh -s 006_scenario -svc account --trace --latency
	./run_scenario.sh -s 007_scenario -svc account --trace --latency
	./run_scenario.sh -s 008_scenario -svc account --trace --latency

	mkdir -p overhead-experiments/tracing/account-service/run-$i
	mv scenarios/account-service/*latency.log overhead-experiments/tracing/account-service/run-$i/
	mv scenarios/account-service/*.pcap overhead-experiments/tracing/account-service/run-$i/

	./run_scenario.sh -s 001_scenario -svc statistics --trace --latency
	./run_scenario.sh -s 002_scenario -svc statistics --trace --latency
	./run_scenario.sh -s 003_scenario -svc statistics --trace --latency
	./run_scenario.sh -s 004_scenario -svc statistics --trace --latency

	mkdir -p overhead-experiments/tracing/statistics-service/run-$i
	mv scenarios/statistics-service/*latency.log overhead-experiments/tracing/statistics-service/run-$i/
	mv scenarios/statistics-service/*.pcap overhead-experiments/tracing/statistics-service/run-$i/

	./run_scenario.sh -s 001_scenario -svc notification --trace --latency
	./run_scenario.sh -s 002_scenario -svc notification --trace --latency
	./run_scenario.sh -s 003_scenario -svc notification --trace --latency
	./run_scenario.sh -s 004_scenario -svc notification --trace --latency

	mkdir -p overhead-experiments/tracing/notification-service/run-$i
	mv scenarios/notification-service/*latency.log overhead-experiments/tracing/notification-service/run-$i/
	mv scenarios/notification-service/*.pcap overhead-experiments/tracing/notification-service/run-$i/

	sudo systemctl stop metricbeat.service

	docker-compose -f piggymetrics/docker-compose.custom.yml down
done

docker rmi $(docker images -f "reference=piggymetrics_*" -q)