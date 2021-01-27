#!/bin/bash

runs=$1;

mkdir -p overhead-experiments/baseline

./prepare_scenario_run.sh
. ./prepare_scenario_run.sh --source-only

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

