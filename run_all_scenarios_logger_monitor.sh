#!/bin/bash

function copy_monitor_code() {
	echo "Copying monitor instrumentation code..."

	rsync --update -raz "monitor/account-service/filter" "piggymetrics/account-service/src/main/java/com/piggymetrics/account/"
	rsync --update -raz "monitor/account-service/config/"*.java "piggymetrics/account-service/src/main/java/com/piggymetrics/account/config/"
	rsync --update -raz "monitor/account-service/logback-spring.xml" "piggymetrics/account-service/src/main/resources/logback-spring.xml"

	rsync --update -raz "monitor/statistics-service/filter" "piggymetrics/statistics-service/src/main/java/com/piggymetrics/statistics/"
	rsync --update -raz "monitor/statistics-service/config/"*.java "piggymetrics/statistics-service/src/main/java/com/piggymetrics/statistics/config/"
	rsync --update -raz "monitor/statistics-service/logback-spring.xml" "piggymetrics/statistics-service/src/main/resources/logback-spring.xml"

	rsync --update -raz "monitor/notification-service/filter" "piggymetrics/notification-service/src/main/java/com/piggymetrics/notification/"
	rsync --update -raz "monitor/notification-service/config/"*.java "piggymetrics/notification-service/src/main/java/com/piggymetrics/notification/config/"
	rsync --update -raz "monitor/notification-service/logback-spring.xml" "piggymetrics/notification-service/src/main/resources/logback-spring.xml"

	echo "Done!"
}

copy_monitor_code
./prepare_scenario_run.sh

./run_scenario.sh -s 001_scenario -svc account --monitor
./run_scenario.sh -s 002_scenario -svc account --monitor
./run_scenario.sh -s 003_scenario -svc account --monitor
./run_scenario.sh -s 004_scenario -svc account --monitor
./run_scenario.sh -s 005_scenario -svc account --monitor
./run_scenario.sh -s 006_scenario -svc account --monitor
./run_scenario.sh -s 007_scenario -svc account --monitor
./run_scenario.sh -s 008_scenario -svc account --monitor

./run_scenario.sh -s 001_scenario -svc statistics --monitor
./run_scenario.sh -s 002_scenario -svc statistics --monitor
./run_scenario.sh -s 003_scenario -svc statistics --monitor
./run_scenario.sh -s 004_scenario -svc statistics --monitor

./run_scenario.sh -s 001_scenario -svc notification --monitor
./run_scenario.sh -s 002_scenario -svc notification --monitor
./run_scenario.sh -s 003_scenario -svc notification --monitor
./run_scenario.sh -s 004_scenario -svc notification --monitor