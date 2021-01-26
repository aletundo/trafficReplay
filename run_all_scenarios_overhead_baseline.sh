#!/bin/bash

runs=$1;

mkdir -p overhead-experiments/baseline

for (( i = 0; i < $runs; i++ )); do
	./run_scenario.sh -s 001_scenario -svc account --latency
	./run_scenario.sh -s 002_scenario -svc account --no-build --no-run --latency
	./run_scenario.sh -s 003_scenario -svc account --no-build --no-run --latency
	./run_scenario.sh -s 004_scenario -svc account --no-build --no-run --latency
	./run_scenario.sh -s 005_scenario -svc account --no-build --no-run --latency
	./run_scenario.sh -s 006_scenario -svc account --no-build --no-run --latency
	./run_scenario.sh -s 007_scenario -svc account --no-build --no-run --latency
	./run_scenario.sh -s 008_scenario -svc account --no-build --no-run --latency

	./run_scenario.sh -s 001_scenario -svc statistics --no-build --no-run --latency
	./run_scenario.sh -s 002_scenario -svc statistics --no-build --no-run --latency
	./run_scenario.sh -s 003_scenario -svc statistics --no-build --no-run --latency
	./run_scenario.sh -s 004_scenario -svc statistics --no-build --no-run --latency

	./run_scenario.sh -s 001_scenario -svc notification --no-build --no-run --latency
	./run_scenario.sh -s 002_scenario -svc notification --no-build --no-run --latency
	./run_scenario.sh -s 003_scenario -svc notification --no-build --no-run --latency
	./run_scenario.sh -s 004_scenario -svc notification --no-build --no-run --latency

	docker-compose -f piggymetrics/docker-compose.custom.yml down

	mkdir overhead-experiments/baseline/run-$i
	cp scenarios/**/.log overhead-experiments/baseline/run-$i
done
