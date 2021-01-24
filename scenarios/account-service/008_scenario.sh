#!/bin/bash

dirname=`dirname "$0"`
auth_service_host=$1
account_service_host=$2

# User '006_scenario' updates her account failing due to some validations.

sleep 2
token=$(curl --silent -X POST -H "Accept: application/json" -H "Authorization: Basic YnJvd3Nlcjo=" -d "scope=ui&grant_type=password&username=006_scenario&password=password" http://$auth_service_host:5000/uaa/oauth/token | jq -j .access_token)
sleep 2
curl -w "%{time_total}\n" --silent -o /dev/null -X PUT -d @$dirname/008_scenario_no_inc_currency.json -H "Accept: application/json" -H "Authorization: Bearer $token" -H "Content-Type: application/json" http://$account_service_host:6000/accounts/current
sleep 2
curl -w "%{time_total}\n" --silent -o /dev/null -X PUT -d @$dirname/008_scenario_no_inc_currency.json -H "Accept: application/json" -H "Authorization: Bearer $token" -H "Content-Type: application/json" http://$account_service_host:6000/accounts/current
sleep 2
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/current
sleep 2
curl -w "%{time_total}\n" --silent -o /dev/null -X PUT -d @$dirname/008_scenario_empty_note.json -H "Accept: application/json" -H "Authorization: Bearer $token" -H "Content-Type: application/json" http://$account_service_host:6000/accounts/current
sleep 2
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/current
sleep 2
curl -w "%{time_total}\n" --silent -o /dev/null -X PUT -d @$dirname/008_scenario_exp_title.json  -H "Accept: application/json" -H "Authorization: Bearer $token" -H "Content-Type: application/json" http://$account_service_host:6000/accounts/current
sleep 2
curl -w "%{time_total}\n" --silent -o /dev/null -X PUT -d @$dirname/008_scenario_no_inc_amount.json  -H "Accept: application/json" -H "Authorization: Bearer $token" -H "Content-Type: application/json" http://$account_service_host:6000/accounts/current
sleep 2
curl -w "%{time_total}\n" --silent -o /dev/null -X PUT -d @$dirname/008_scenario_data.json  -H "Accept: application/json" -H "Authorization: Bearer $token" -H "Content-Type: application/json" http://$account_service_host:6000/accounts/current
sleep 2
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/current
