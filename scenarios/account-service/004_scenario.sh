#!/bin/bash

auth_service_host=$1
account_service_host=$2

# Another service access to two accounts for 3 times sequentially

sleep 2
token=$(curl --silent -X POST -H "Accept: application/json" -d "grant_type=client_credentials" -u "account-service:acc_serv" http://$auth_service_host:5000/uaa/oauth/token | jq -j .access_token)
sleep 2
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/001_scenario
sleep 1
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/002_scenario
sleep 1
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/001_scenario
sleep 1
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/002_scenario
sleep 1
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/001_scenario
sleep 1
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/002_scenario