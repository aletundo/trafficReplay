#!/bin/bash

auth_service_host=$1
account_service_host=$2

# A user register, then tries to get current account without auth.
# Then she login and get current account.

sleep 2
curl -X POST -d '{"username":"002_scenario","password":"password"}' -H "Accept: application/json" -H "Content-Type: application/json" http://$account_service_host:6000/accounts/
sleep 5
curl -X GET -H "Accept: application/json" http://$account_service_host:6000/accounts/current
sleep 5
token=$(curl -X POST -H "Authorization: Basic YnJvd3Nlcjo=" -H "Accept: application/json" -d "scope=ui&grant_type=password&username=002_scenario&password=password" http://$auth_service_host:5000/uaa/oauth/token | jq -j .access_token)
sleep 5
curl -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/current