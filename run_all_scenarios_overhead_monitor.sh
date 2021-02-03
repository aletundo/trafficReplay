#!/bin/bash

export CONFIG_SERVICE_PASSWORD="conf_serv"
export NOTIFICATION_SERVICE_PASSWORD="not_serv"
export STATISTICS_SERVICE_PASSWORD="stat_serv"
export ACCOUNT_SERVICE_PASSWORD="acc_serv"
export MONGODB_PASSWORD="mongo"

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

mkdir -p overhead-experiments/monitor

rm -rf piggymetrics
git clone https://github.com/sqshq/piggymetrics.git

copy_monitor_code

./prepare_scenario_run.sh

for (( i = 0; i < $runs; i++ )); do
	if [[ $i > 0 ]]; then
		run_services
	fi

	sudo systemctl start metricbeat.service

	./run_scenario.sh -s 001_scenario -svc account --monitor --latency
	./run_scenario.sh -s 002_scenario -svc account --monitor --latency
	./run_scenario.sh -s 003_scenario -svc account --monitor --latency
	./run_scenario.sh -s 004_scenario -svc account --monitor --latency
	./run_scenario.sh -s 005_scenario -svc account --monitor --latency
	./run_scenario.sh -s 006_scenario -svc account --monitor --latency
	./run_scenario.sh -s 007_scenario -svc account --monitor --latency
	./run_scenario.sh -s 008_scenario -svc account --monitor --latency

	mkdir -p overhead-experiments/monitor/account-service/run-$i
	mv scenarios/account-service/*latency.log overhead-experiments/monitor/account-service/run-$i/

	./run_scenario.sh -s 001_scenario -svc statistics --monitor --latency
	./run_scenario.sh -s 002_scenario -svc statistics --monitor --latency
	./run_scenario.sh -s 003_scenario -svc statistics --monitor --latency
	./run_scenario.sh -s 004_scenario -svc statistics --monitor --latency

	mkdir -p overhead-experiments/monitor/statistics-service/run-$i
	mv scenarios/statistics-service/*latency.log overhead-experiments/monitor/statistics-service/run-$i/

	./run_scenario.sh -s 001_scenario -svc notification --monitor --latency
	./run_scenario.sh -s 002_scenario -svc notification --monitor --latency
	./run_scenario.sh -s 003_scenario -svc notification --monitor --latency
	./run_scenario.sh -s 004_scenario -svc notification --monitor --latency

	mkdir -p overhead-experiments/monitor/notification-service/run-$i
	mv scenarios/notification-service/*latency.log overhead-experiments/monitor/notification-service/run-$i/

	sudo systemctl stop metricbeat.service

	docker-compose -f piggymetrics/docker-compose.custom.yml down
done

docker rmi $(docker images -f "reference=piggymetrics_*" -q)
