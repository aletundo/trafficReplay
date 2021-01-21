#!/bin/bash

auth_service_host=$1
account_service_host=$2

# A user explore the demo, then she sign-up, login and save the current account

sleep 2
curl -X GET http://$account_service_host:6000/accounts/demo
sleep 5
curl -X POST -d '{"username":"001_scenario","password":"password"}' -H "Content-Type: application/json" http://$account_service_host:6000/accounts/
sleep 3
token=$(curl -X POST -H "Authorization: Basic YnJvd3Nlcjo=" -d "scope=ui&grant_type=password&username=Test&password=password" http://$auth_service_host:5000/uaa/oauth/token) | jq -j .access_token)
sleep 5
curl -X PUT -d @001_scenario_data.json -H "Authorization: Bearer $token" -H "Content-Type: application/json" http://$account_service_host:6000/accounts/current