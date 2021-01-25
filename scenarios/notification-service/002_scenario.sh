#!/bin/bash

auth_service_host=$1
notification_service_host=$2

# A user tries to get her current notifications without authentication.
# Then she login and get them again.

sleep 2

curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Accept: application/json" \
http://$notification_service_host:8000/notifications/recipients/current

sleep 5

curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Accept: application/json" \
http://$notification_service_host:8000/notifications/recipients/current

sleep 5

curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Accept: application/json" \
http://$notification_service_host:8000/notifications/recipients/current

token=$(curl --silent -X POST -H "Authorization: Basic YnJvd3Nlcjo=" -H "Accept: application/json" \
-d "scope=ui&grant_type=password&username=001_scenario&password=password" http://$auth_service_host:5000/uaa/oauth/token | jq -j .access_token)

sleep 5

curl -w "%{time_total}\n" --silent -o /dev/null -X GET -H "Accept: application/json" \
-H "Authorization: Bearer $token"  http://$notification_service_host:8000/notifications/recipients/current
