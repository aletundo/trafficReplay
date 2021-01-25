#!/bin/bash

auth_service_host=$1
notification_service_host=$2

# User 002_scenario login, get current notifications twice then she empty the
# scheduled notifications

sleep 2

token=$(curl --silent -X POST -H "Authorization: Basic YnJvd3Nlcjo=" -H "Accept: application/json" \
-d "scope=ui&grant_type=password&username=002_scenario&password=password" http://$auth_service_host:5000/uaa/oauth/token | jq -j .access_token)

sleep 5

curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Accept: application/json" \
-H "Authorization: Bearer $token"  http://$notification_service_host:8000/notifications/recipients/current

sleep 5

curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Accept: application/json" \
-H "Authorization: Bearer $token"  http://$notification_service_host:8000/notifications/recipients/current

sleep 5

curl -w "%{time_total}\n" --silent -o /dev/null -X PUT \
-d '{"accountName":"002_scenario","email":"002_scenario@example.com", "scheduledNotifications":{}' \
-H "Authorization: Bearer $token" -H "Accept: application/json" -H "Content-Type: application/json" http://$notification_service_host:8000/notifications/recipients/current