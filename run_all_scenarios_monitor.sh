#!/bin/bash

./run_scenario.sh -s 001_scenario -svc account --monitor
./run_scenario.sh -s 002_scenario -svc account --no-build --no-run --monitor
./run_scenario.sh -s 003_scenario -svc account --no-build --no-run --monitor
./run_scenario.sh -s 004_scenario -svc account --no-build --no-run --monitor
./run_scenario.sh -s 005_scenario -svc account --no-build --no-run --monitor
./run_scenario.sh -s 006_scenario -svc account --no-build --no-run --monitor
./run_scenario.sh -s 007_scenario -svc account --no-build --no-run --monitor
./run_scenario.sh -s 008_scenario -svc account --no-build --no-run --monitor

./run_scenario.sh -s 001_scenario -svc statistics --no-build --no-run --monitor
./run_scenario.sh -s 002_scenario -svc statistics --no-build --no-run --monitor
./run_scenario.sh -s 003_scenario -svc statistics --no-build --no-run --monitor
./run_scenario.sh -s 004_scenario -svc statistics --no-build --no-run --monitor

./run_scenario.sh -s 001_scenario -svc notification --no-build --no-run --monitor
./run_scenario.sh -s 002_scenario -svc notification --no-build --no-run --monitor
./run_scenario.sh -s 003_scenario -svc notification --no-build --no-run --monitor
./run_scenario.sh -s 004_scenario -svc notification --no-build --no-run --monitor