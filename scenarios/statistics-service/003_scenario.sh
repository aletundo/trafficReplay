#!/bin/bash

dirname=`dirname "$0"`
auth_service_host=$1
statistics_service_host=$2

sleep 2

token=$(curl --silent -X POST -H "Authorization: Basic YnJvd3Nlcjo=" -H "Accept: application/json" \
-d "scope=ui&grant_type=password&username=002_scenario&password=password" http://$auth_service_host:5000/uaa/oauth/token | jq -j .access_token)

sleep 5

curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Accept: application/json" \
-H "Authorization: Bearer $token" http://$statistics_service_host:7000/statistics/current

sleep 5

curl -w "%{time_total}\n" --silent -o /dev/null -X PUT -H "Accept: application/json" \
-d @$dirname/003_scenario_data.json -H "Content-Type: application/json" \
-H "Authorization: Bearer $token" http://$statistics_service_host:7000/statistics/current

sleep 5

curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Accept: application/json" \
-H "Authorization: Bearer $token" http://$statistics_service_host:7000/statistics/current

sleep 5

curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Accept: application/json" \
-H "Authorization: Bearer $token" http://$statistics_service_host:7000/statistics/current

sleep 5

curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Accept: application/json" \
-H "Authorization: Bearer $token" http://$statistics_service_host:7000/statistics/001_scenario