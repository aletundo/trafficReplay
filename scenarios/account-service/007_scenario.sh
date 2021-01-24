#!/bin/bash

auth_service_host=$1
account_service_host=$2

# Another service access to several existing and not existings accounts
sleep 2
token=$(curl --silent -X POST -H "Accept: application/json" -d "grant_type=client_credentials" -u "account-service:acc_serv" http://$auth_service_host:5000/uaa/oauth/token | jq -j .access_token)
sleep 2
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/Test1
sleep 1
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/Test1
sleep 1
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/Test3
sleep 1
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/Test1
sleep 1
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/Test3
sleep 1
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/Test2
sleep 1
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/Test2
sleep 1
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/Test2
sleep 1
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/Test4
sleep 1
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/Test4
sleep 1
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/Test5
sleep 1
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/Test5
sleep 1
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/Test6
sleep 1
curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Authorization: Bearer $token" -H "Accept: application/json" http://$account_service_host:6000/accounts/Test6