#!/bin/bash

auth_service_host=$1
notification_service_host=$2

sleep 2

token=$(curl --silent -X POST -H "Authorization: Basic YnJvd3Nlcjo=" -H "Accept: application/json" \
-d "scope=ui&grant_type=password&username=001_scenario&password=password" http://$auth_service_host:5000/uaa/oauth/token | jq -j .access_token)

sleep 5

curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Accept: application/json" \
-H "Authorization: Bearer $token"  http://$notification_service_host:8000/notifications/recipients/current

sleep 5

curl -w "%{time_total}\n" --silent -o /dev/null -X PUT \
-d '{"accountName":"001_scenario","email":"001_scenario@example.com","scheduledNotifications":{"REMIND":{"active":true,"frequency":"MONTHLY","lastNotified":"2019-01-18T15:25:48.545+0000"}}}' \
-H "Authorization: Bearer $token" -H "Accept: application/json" -H "Content-Type: application/json" http://$notification_service_host:8000/notifications/recipients/current

sleep 2

curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Accept: application/json" \
-H "Authorization: Bearer $token"  http://$notification_service_host:8000/notifications/recipients/current
