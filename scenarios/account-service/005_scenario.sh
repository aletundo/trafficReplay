#!/bin/bash

auth_service_host=$1
account_service_host=$2

# A user fails two times to register due to username validation.
# Then, she tries with an already used username. Finally, she complete the registration.

sleep 2
curl -w "%{time_total}\n" --silent -o /dev/null -X POST -d '{"username":"00","password":"password"}' -H "Accept: application/json" -H "Content-Type: application/json" http://$account_service_host:6000/accounts/
sleep 5
curl -w "%{time_total}\n" --silent -o /dev/null -X POST -d '{"username":"005_scenario_00000000","password":"password"}' -H "Accept: application/json" -H "Content-Type: application/json" http://$account_service_host:6000/accounts/
sleep 5
curl -w "%{time_total}\n" --silent -o /dev/null -X POST -d '{"username":"001_scenario","password":"password"}' -H "Accept: application/json" -H "Content-Type: application/json" http://$account_service_host:6000/accounts/
sleep 5
curl -w "%{time_total}\n" --silent -o /dev/null -X POST -d '{"username":"005_scenario","password":"password"}' -H "Accept: application/json" -H "Content-Type: application/json" http://$account_service_host:6000/accounts/