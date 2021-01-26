#!/bin/bash

times=$1;

mkdir -p overhead-experiments/tracing

for (( i = 0; i < $times; i++ )); do
	./run_scenario.sh -s 001_scenario -svc account --trace --latency
	./run_scenario.sh -s 002_scenario -svc account --no-build --no-run --trace --latency
	./run_scenario.sh -s 003_scenario -svc account --no-build --no-run --trace --latency
	./run_scenario.sh -s 004_scenario -svc account --no-build --no-run --trace --latency
	./run_scenario.sh -s 005_scenario -svc account --no-build --no-run --trace --latency
	./run_scenario.sh -s 006_scenario -svc account --no-build --no-run --trace --latency
	./run_scenario.sh -s 007_scenario -svc account --no-build --no-run --trace --latency
	./run_scenario.sh -s 008_scenario -svc account --no-build --no-run --trace --latency

	./run_scenario.sh -s 001_scenario -svc statistics --no-build --no-run --trace --latency
	./run_scenario.sh -s 002_scenario -svc statistics --no-build --no-run --trace --latency
	./run_scenario.sh -s 003_scenario -svc statistics --no-build --no-run --trace --latency
	./run_scenario.sh -s 004_scenario -svc statistics --no-build --no-run --trace --latency

	./run_scenario.sh -s 001_scenario -svc notification --no-build --no-run --trace --latency
	./run_scenario.sh -s 002_scenario -svc notification --no-build --no-run --trace --latency
	./run_scenario.sh -s 003_scenario -svc notification --no-build --no-run --trace --latency
	./run_scenario.sh -s 004_scenario -svc notification --no-build --no-run --trace --latency

	docker-compose -f piggymetrics/docker-compose.custom.yml down

	mkdir overhead-experiments/tracing/run-$i
	cp scenarios/**/.log overhead-experiments/tracing/run-$i
done

