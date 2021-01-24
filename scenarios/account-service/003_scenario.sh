#!/bin/bash

auth_service_host=$1
account_service_host=$2

# User 002_scenario tries to get current account without auth 5 times, then she login
# and get the current account successfully

sleep 2
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Accept: application/json" http://$account_service_host:6000/accounts/current
sleep 5
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Accept: application/json" http://$account_service_host:6000/accounts/current
sleep 5
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Accept: application/json" http://$account_service_host:6000/accounts/current
sleep 5
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Accept: application/json" http://$account_service_host:6000/accounts/current
sleep 5
token=$(curl -X POST -H "Accept: application/json" -H "Authorization: Basic YnJvd3Nlcjo=" -d "scope=ui&grant_type=password&username=002_scenario&password=password" http://$auth_service_host:5000/uaa/oauth/token | jq -j .access_token)
sleep 5
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/current