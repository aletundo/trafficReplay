#!/bin/bash

dirname=`dirname "$0"`
auth_service_host=$1
account_service_host=$2

# A user fails to register due to password validation, at the second attempt she
# complete the registration. Then, she get the current account and start to update
# several times the account. During this process she sometimes fails updates due
# to validation errors and she made some retries before to succeed.

sleep 2
curl -w "%{time_total}\n" --silent -o /dev/null -X POST -d '{"username":"006_scenario","password":"pass"}' -H "Accept: application/json" -H "Content-Type: application/json" http://$account_service_host:6000/accounts/
sleep 5
curl -w "%{time_total}\n" --silent -o /dev/null -X POST -d '{"username":"006_scenario","password":"password"}' -H "Accept: application/json" -H "Content-Type: application/json" http://$account_service_host:6000/accounts/
sleep 2
token=$(curl -X POST -H "Accept: application/json" -H "Authorization: Basic YnJvd3Nlcjo=" -d "scope=ui&grant_type=password&username=006_scenario&password=password" http://$auth_service_host:5000/uaa/oauth/token | jq -j .access_token)
sleep 2
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/current
sleep 2
curl -w "%{time_total}\n" --silent -o /dev/null -X PUT -d @$dirname/006_scenario_no_saving.json -H "Accept: application/json" -H "Authorization: Bearer $token" -H "Content-Type: application/json" http://$account_service_host:6000/accounts/current
sleep 2
curl -w "%{time_total}\n" --silent -o /dev/null -X PUT -d @$dirname/006_scenario_no_saving.json -H "Accept: application/json" -H "Authorization: Bearer $token" -H "Content-Type: application/json" http://$account_service_host:6000/accounts/current
sleep 2
curl -w "%{time_total}\n" --silent -o /dev/null -X PUT -d @$dirname/006_scenario_no_saving.json -H "Accept: application/json" -H "Authorization: Bearer $token" -H "Content-Type: application/json" http://$account_service_host:6000/accounts/current
sleep 2
curl -w "%{time_total}\n" --silent -o /dev/null -X PUT -d @$dirname/006_scenario_no_saving.json -H "Accept: application/json" -H "Authorization: Bearer $token" -H "Content-Type: application/json" http://$account_service_host:6000/accounts/current
sleep 2
curl -w "%{time_total}\n" --silent -o /dev/null -X PUT -d @$dirname/006_scenario_no_exp_amount.json -H "Accept: application/json" -H "Authorization: Bearer $token" -H "Content-Type: application/json" http://$account_service_host:6000/accounts/current
sleep 2
curl -w "%{time_total}\n" --silent -o /dev/null -X PUT -d @$dirname/006_scenario_exp_title.json  -H "Accept: application/json" -H "Authorization: Bearer $token" -H "Content-Type: application/json" http://$account_service_host:6000/accounts/current