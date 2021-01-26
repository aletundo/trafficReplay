#!/bin/bash

function copy_monitor_code() {
	echo "Copying monitor instrumentation code..."

	rsync --update -raz "monitor/account-service/filter" "piggymetrics/account-service/src/main/java/com/piggymetrics/account/"
	rsync --update -raz "monitor/account-service/config/"*.java "piggymetrics/account-service/src/main/java/com/piggymetrics/account/config/"
	rsync --update -raz "monitor/account-service/logback-spring.xml" "piggymetrics/account-service/src/main/resources/logback-spring.xml"
	sed -i 's/LOGGER/DEFAULT/' "piggymetrics/account-service/src/main/java/com/piggymetrics/account/config/MonitorFilterConfig.java"

	rsync --update -raz "monitor/statistics-service/filter" "piggymetrics/statistics-service/src/main/java/com/piggymetrics/statistics/"
	rsync --update -raz "monitor/statistics-service/config/"*.java "piggymetrics/statistics-service/src/main/java/com/piggymetrics/statistics/config/"
	rsync --update -raz "monitor/statistics-service/logback-spring.xml" "piggymetrics/statistics-service/src/main/resources/logback-spring.xml"
	sed -i 's/LOGGER/DEFAULT/' "piggymetrics/statistics-service/src/main/java/com/piggymetrics/statistics/config/MonitorFilterConfig.java"

	rsync --update -raz "monitor/notification-service/filter" "piggymetrics/notification-service/src/main/java/com/piggymetrics/notification/"
	rsync --update -raz "monitor/notification-service/config/"*.java "piggymetrics/notification-service/src/main/java/com/piggymetrics/notification/config/"
	rsync --update -raz "monitor/notification-service/logback-spring.xml" "piggymetrics/notification-service/src/main/resources/logback-spring.xml"
	sed -i 's/LOGGER/DEFAULT/' "piggymetrics/notification-service/src/main/java/com/piggymetrics/notification/config/MonitorFilterConfig.java"

	echo "Done!"
}

times=$1;

mkdir -p overhead-experiments/monitor
copy_monitor_code

for (( i = 0; i < $times; i++ )); do

	sudo systemctl start metricbeat.service

	./run_scenario.sh -s 001_scenario -svc account --monitor --latency
	./run_scenario.sh -s 002_scenario -svc account --no-build --no-run --monitor --latency
	./run_scenario.sh -s 003_scenario -svc account --no-build --no-run --monitor --latency
	./run_scenario.sh -s 004_scenario -svc account --no-build --no-run --monitor --latency
	./run_scenario.sh -s 005_scenario -svc account --no-build --no-run --monitor --latency
	./run_scenario.sh -s 006_scenario -svc account --no-build --no-run --monitor --latency
	./run_scenario.sh -s 007_scenario -svc account --no-build --no-run --monitor --latency
	./run_scenario.sh -s 008_scenario -svc account --no-build --no-run --monitor --latency

	mkdir -p overhead-experiments/monitor/account-service/run-$i
	cp scenarios/account-service/*.log overhead-experiments/monitor/account-service/run-$i/

	./run_scenario.sh -s 001_scenario -svc statistics --no-build --no-run --monitor --latency
	./run_scenario.sh -s 002_scenario -svc statistics --no-build --no-run --monitor --latency
	./run_scenario.sh -s 003_scenario -svc statistics --no-build --no-run --monitor --latency
	./run_scenario.sh -s 004_scenario -svc statistics --no-build --no-run --monitor --latency

	mkdir -p overhead-experiments/monitor/statistics-service/run-$i
	cp scenarios/statistics-service/*.log overhead-experiments/monitor/statistics-service/run-$i/

	./run_scenario.sh -s 001_scenario -svc notification --no-build --no-run --monitor --latency
	./run_scenario.sh -s 002_scenario -svc notification --no-build --no-run --monitor --latency
	./run_scenario.sh -s 003_scenario -svc notification --no-build --no-run --monitor --latency
	./run_scenario.sh -s 004_scenario -svc notification --no-build --no-run --monitor --latency

	mkdir -p overhead-experiments/monitor/notification-service/run-$i
	cp scenarios/notification-service/*.log overhead-experiments/monitor/notification-service/run-$i/

	sudo systemctl stop metricbeat.service

	docker-compose -f piggymetrics/docker-compose.custom.yml down
done

