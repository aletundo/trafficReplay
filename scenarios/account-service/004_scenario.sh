#!/bin/bash

auth_service_host=$1
account_service_host=$2

# Another service access to two accounts for 3 times sequentially

sleep 2
token=$(curl -X POST -H "Accept: application/json" -d "grant_type=client_credentials" -u "account-service:acc_serv" http://$auth_service_host:5000/uaa/oauth/token | jq -j .access_token)
sleep 2
curl -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/Test
sleep 1
curl -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/Test2
sleep 1
curl -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/Test
sleep 1
curl -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/Test2
sleep 1
curl -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/Test
sleep 1
curl -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/Test2