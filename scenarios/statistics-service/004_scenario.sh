#!/bin/bash

dirname=`dirname "$0"`
auth_service_host=$1
statistics_service_host=$2

sleep 2

curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Accept: application/json" \
http://$statistics_service_host:7000/statistics/002_scenario

token=$(curl --silent -X POST -H "Accept: application/json" -d "grant_type=client_credentials" \
-u "statistics-service:stat_serv" http://$auth_service_host:5000/uaa/oauth/token | jq -j .access_token)

curl -w "%{time_total}\n" --silent -o /dev/null -X PUT -H "Accept: application/json" \
-d @$dirname/004_scenario_no_inc_title.json -H "Content-Type: application/json" \
-H "Authorization: Bearer $token" http://$statistics_service_host:7000/statistics/002_scenario

curl -w "%{time_total}\n" --silent -o /dev/null -X PUT -H "Accept: application/json" \
-d @$dirname/004_scenario_no_inc_title.json -H "Content-Type: application/json" \
-H "Authorization: Bearer $token" http://$statistics_service_host:7000/statistics/002_scenario

curl -w "%{time_total}\n" --silent -o /dev/null -X PUT -H "Accept: application/json" \
-d @$dirname/004_scenario_exp_title.json -H "Content-Type: application/json" \
-H "Authorization: Bearer $token" http://$statistics_service_host:7000/statistics/002_scenario

curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Accept: application/json" \
-H "Authorization: Bearer $token" http://$statistics_service_host:7000/statistics/002_scenario