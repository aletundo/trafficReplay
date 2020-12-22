#!/bin/bash

#1: interfaccia
#2: finale ip account
#3: finale ip auth
#4: finale ip statistics
#5: finale ip notification
#6: cartella versione
if [[ $# -lt 3 ]] ; then
	echo 'missing args ---> ./automatic_capture.sh <interface> <name:ip> [<name:ip>] [<name:ip>] <Cartella>'
	exit 1
fi

cartella=''
accip=''
statip=''
notip=''
authip=''

if [[ $# -eq 6 ]] ; then
	IFS='_' read -ra ADDR <<< "$2"

	if [[ ${ADDR[0]} == "acc" ]];then
		accip=${ADDR[1]}
	elif [[ ${ADDR[0]} == "stat" ]];then
		statip=${ADDR[1]}
	elif [[ ${ADDR[0]} == "not" ]];then
		notip=${ADDR[1]}
	else
	    	authip=${ADDR[1]}
	fi

	IFS='_' read -ra ADDR <<< "$3"
	if [[ ${ADDR[0]} == "acc" ]];then
		accip=${ADDR[1]}
	elif [[ ${ADDR[0]} == "stat" ]];then
		statip=${ADDR[1]}
	elif [[ ${ADDR[0]} == "not" ]];then
		notip=${ADDR[1]}
	else
	   	authip=${ADDR[1]}
	fi

	IFS='_' read -ra ADDR <<< "$4"
	if [[ ${ADDR[0]} == "acc" ]];then
		accip=${ADDR[1]}
	elif [[ ${ADDR[0]} == "stat" ]];then
		statip=${ADDR[1]}
	elif [[ ${ADDR[0]} == "not" ]];then
		notip=${ADDR[1]}
	else
	   	authip=${ADDR[1]}
	fi

	IFS='_' read -ra ADDR <<< "$5"
	if [[ ${ADDR[0]} == "acc" ]];then
		accip=${ADDR[1]}
	elif [[ ${ADDR[0]} == "stat" ]];then
		statip=${ADDR[1]}
	elif [[ ${ADDR[0]} == "not" ]];then
		notip=${ADDR[1]}
	else
	   	authip=${ADDR[1]}
	fi
	cartella=$6
fi

echo "Account Service IP: ${accip}"
echo "Statistics Service IP: ${statip}"
echo "Notification Service IP: ${notip}"
echo "Authorization Service IP: ${authip}"


#start a process in the background (it happens to be a TCP HTTP sniffer on  the loopback interface, for my apache server):
function parse_json()
{
    echo $1 | \
    sed -e 's/[{}]/''/g' | \
    sed -e 's/", "/'\",\"'/g' | \
    sed -e 's/" ,"/'\",\"'/g' | \
    sed -e 's/" , "/'\",\"'/g' | \
    sed -e 's/","/'\"---SEPERATOR---\"'/g' | \
    awk -F=':' -v RS='---SEPERATOR---' "\$1~/\"$2\"/ {print}" | \
    sed -e "s/\"$2\"://" | \
    tr -d "\n\t" | \
    sed -e 's/\\"/"/g' | \
    sed -e 's/\\\\/\\/g' | \
    sed -e 's/^[ \t]*//g' | \
    sed -e 's/^"//'  -e 's/"$//'
}

echo "Running scenarios for Account Service"

if [ ! $accip == '' ]; then
	./capture_script.sh ../$cartella/Test1 interaction.pcap $1 &
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -X GET http://$accip:6000/accounts/demo)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d '{"username":"Test","password":"password"}' -H "Content-Type: application/json" -X POST http://$accip:6000/accounts/)
	# echo "Response: $response" & sleep 5
    sleep 5
	token=$(parse_json $(curl -X POST --header "Authorization: Basic YnJvd3Nlcjo=" -d "scope=ui&grant_type=password&username=Test&password=password" http://$authip:5000/uaa/oauth/token) access_token)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest1.json --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	#now interrupt the process.  get its PID:
	pid=$(ps -e | pgrep tcpdump)
	#interrupt it:
	kill -2 $pid


	./capture_script.sh ../$cartella/Test2 interaction.pcap $1 &
	# echo "Response: $response" & sleep 5
    sleep 5
	token1=$(parse_json $(curl -X POST -H "Accept: application/json" -d "grant_type=client_credentials" -u "account-service:acc_serv" http://$authip:5000/uaa/oauth/token) access_token)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -H "Accept: application/json" --header "Authorization: Bearer $token1" -X GET http://$accip:6000/accounts/Test2)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d '{"username":"Test2","password":"password"}' -H "Content-Type: application/json" -X POST http://$accip:6000/accounts/)
	# echo "Response: $response" & sleep 5
    sleep 5
	token2=$(parse_json $(curl -X POST --header "Authorization: Basic YnJvd3Nlcjo=" -d "scope=ui&grant_type=password&username=Test&password=password" http://$authip:5000/uaa/oauth/token) access_token)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest2.json --header "Authorization: Bearer $token2" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest3.json --header "Authorization: Bearer $token2" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl --header "Authorization: Bearer $token2" -X GET  http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	pid=$(ps -e | pgrep tcpdump)
	kill -2 $pid


	./capture_script.sh ../$cartella/Test3 interaction.pcap $1 &
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d '{"username":"Test3","password":"password"}' -H "Content-Type: application/json" -X POST http://$accip:6000/accounts/)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest2.json --header "Authorization: Bearer $token2" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	pid=$(ps -e | pgrep tcpdump)
	kill -2 $pid

	./capture_script.sh ../$cartella/Test4 interaction.pcap $1 &
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d '{"username":"Test","password":"password"}' -H "Content-Type: application/json" -X POST http://$accip:6000/accounts/)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest2.json --header "Authorization: Bearer $token2" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	token1=$(parse_json $(curl -X POST -H "Accept: application/json" -d "grant_type=client_credentials" -u "account-service:acc_serv" http://$authip:5000/uaa/oauth/token) access_token)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -H "Accept: application/json" --header "Authorization: Bearer $token1" -X GET http://$accip:6000/accounts/Test2)
	# echo "Response: $response" & sleep 5
    sleep 5
	pid=$(ps -e | pgrep tcpdump)
	kill -2 $pid

	./capture_script.sh ../$cartella/Test5 interaction.pcap $1 &
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest1.json --header "Authorization: Bearer $token1" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	pid=$(ps -e | pgrep tcpdump)
	kill -2 $pid

	./capture_script.sh ../$cartella/Test6 interaction.pcap $1 &
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -H "Accept: application/json" --header "Authorization: Bearer $token1" -X GET http://$accip:6000/accounts/Test5)
	# echo "Response: $response" & sleep 5
    sleep 5
	pid=$(ps -e | pgrep tcpdump)
	kill -2 $pid

	./capture_script.sh ../$cartella/Test7 interaction.pcap $1 &
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d '{"username":"Te","password":"password"}' -H "Content-Type: application/json" -X POST http://$accip:6000/accounts/)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d '{"username":"ProviamoUtenteConPiuDiVentiCaratteri","password":"password"}' -H "Content-Type: application/json" -X POST http://$accip:6000/accounts/)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d '{"username":"Test","password":"ProviamoConPasswordConPiuDiQuarantaCaratteri"}' -H "Content-Type: application/json" -X POST http://$accip:6000/accounts/)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d '{"username":"Test","password":"prova"}' -H "Content-Type: application/json" -X POST http://$accip:6000/accounts/)
	# echo "Response: $response" & sleep 5
    sleep 5
	pid=$(ps -e | pgrep tcpdump)
	kill -2 $pid

	./capture_script.sh ../$cartella/Test8 interaction.pcap $1 &
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d '{"username":"TestParametri","password":"password"}' -H "Content-Type: application/json" -X POST http://$accip:6000/accounts/)
	token1=$(parse_json $(curl -X POST --header "Authorization: Basic YnJvd3Nlcjo=" -d "scope=ui&grant_type=password&username=TestParametri&password=password" http://$authip:5000/uaa/oauth/token) access_token)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_NoSaving.json --header "Authorization: Bearer $token1" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/curren)
	# echo "Response: $response" & sleep 5
    sleep 5
	pid=$(ps -e | pgrep tcpdump)
	kill -2 $pid

	./capture_script.sh ../$cartella/Test9 interaction.pcap $1 &
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_NoSaving.json --header "Authorization: Bearer $token1" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_NoExpAmount.json --header "Authorization: Bearer $token1" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_NoExpCurrency.json --header "Authorization: Bearer $token1" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_NoExpIcon.json --header "Authorization: Bearer $token1" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_NoExpPeriod.json --header "Authorization: Bearer $token1" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_NoExpTitle.json --header "Authorization: Bearer $token1" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_NoIncAmount.json --header "Authorization: Bearer $token1" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_NoIncCurrency.json --header "Authorization: Bearer $token1" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_NoIncIcon.json --header "Authorization: Bearer $token1" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_NoIncPeriod.json --header "Authorization: Bearer $token1" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_NoIncTitle.json --header "Authorization: Bearer $token1" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_NoteGrandi.json --header "Authorization: Bearer $token1" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	pid=$(ps -e | pgrep tcpdump)
	kill -2 $pid

	./capture_script.sh ../$cartella/Test10 interaction.pcap $1 &
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d '{"username":"Test","password":"password"}' -H "Content-Type: application/json" -X POST http://$accip:6000/accounts)
	token1=$(parse_json $(curl -X POST --header "Authorization: Basic YnJvd3Nlcjo=" -d "scope=ui&grant_type=password&username=Test&password=password" http://$authip:5000/uaa/oauth/token) access_token)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -H "Accept: application/json" --header "Authorization: Bearer $token1" -X GET http://$accip:6000/accounts/Test3)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -H "Accept: application/json" --header "Authorization: Bearer $token1" -X GET http://$accip:6000/accounts/curren)
	# echo "Response: $response" & sleep 5
    sleep 5
	pid=$(ps -e | pgrep tcpdump)
	kill -2 $pid


	./capture_script.sh ../$cartella/Test11 interaction.pcap $1 &
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d '{"username":"Tes","password":"password"}' -H "Content-Type: application/json" -X POST http://$accip:6000/accounts/)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d '{"username":"Test_venti_caratteri","password":"password"}' -H "Content-Type: application/json" -X POST http://$accip:6000/accounts/)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d '{"username":"TestLimite1","password":"pass6c"}' -H "Content-Type: application/json" -X POST http://$accip:6000/accounts/)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d '{"username":"TestLimite2","password":"password_con_quaranta_caratteri_per_test"}' -H "Content-Type: application/json" -X POST http://$accip:6000/accounts/)
	# echo "Response: $response" & sleep 5
    sleep 5
	token1=$(parse_json $(curl -X POST --header "Authorization: Basic YnJvd3Nlcjo=" -d "scope=ui&grant_type=password&username=TestLimite1&password=pass6c" http://$authip:5000/uaa/oauth/token) access_token)
	# echo "Response: $response" & sleep 5
    sleep 5
	token2=$(parse_json $(curl -X POST --header "Authorization: Basic YnJvd3Nlcjo=" -d "scope=ui&grant_type=password&username=TestLimite2&password=password_con_quaranta_caratteri_per_test" http://$authip:5000/uaa/oauth/token) access_token)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_NoteVuote.json --header "Authorization: Bearer $token1" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_NoteVentik.json --header "Authorization: Bearer $token2" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_ExpTitle1.json --header "Authorization: Bearer $token1" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_ExpTitle20.json --header "Authorization: Bearer $token2" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_IncTitle1.json --header "Authorization: Bearer $token1" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_IncTitle20.json --header "Authorization: Bearer $token2" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	pid=$(ps -e | pgrep tcpdump)
	kill -2 $pid


	./capture_script.sh ../$cartella/Test12 interaction.pcap $1 &
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d '{"username":"UtenteCon21_caratteri","password":"password"}' -H "Content-Type: application/json" -X POST http://$accip:6000/accounts/)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d '{"username":"TestLimite3","password":"pass5"}' -H "Content-Type: application/json" -X POST http://$accip:6000/accounts/)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d '{"username":"TestLimite4","password":"password_con_quaranta_caratteri_per_test2"}' -H "Content-Type: application/json" -X POST http://$accip:6000/accounts/)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d '{"username":"TestLimite2","password":"password_con_quaranta_caratteri_per_test"}' -H "Content-Type: application/json" -X POST http://$accip:6000/accounts/)
	# echo "Response: $response" & sleep 5
    sleep 5
	token=$(parse_json $(curl -X POST --header "Authorization: Basic YnJvd3Nlcjo=" -d "scope=ui&grant_type=password&username=TestLimite2&password=password_con_quaranta_caratteri_per_test" http://$authip:5000/uaa/oauth/token) access_token)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_NoteVentike1.json --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_ExpTitle0.json --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_ExpTitle21.json --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_IncTitle0.json --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_IncTitle21.json --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$accip:6000/accounts/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	pid=$(ps -e | pgrep tcpdump)
	kill -2 $pid

fi

echo "Running scenarios for Statistics Service"

if [ ! $statip == '' ]; then

	./capture_script.sh ../$cartella/Test13 interaction.pcap $1 &
	# echo "Response: $response" & sleep 5
    sleep 5
	token1=$(parse_json $(curl -X POST -H "Accept: application/json" -d "grant_type=client_credentials" -u "statistics-service:stat_serv" http://$authip:5000/uaa/oauth/token) access_token)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -H "Accept: application/json" --header "Authorization: Bearer $token1" -X GET http://$statip:7000/statistics/demo)
	token2=$(parse_json $(curl -X POST --header "Authorization: Basic YnJvd3Nlcjo=" -d "scope=ui&grant_type=password&username=Test2&password=password" http://$authip:5000/uaa/oauth/token) access_token)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl --header "Authorization: Bearer $token2" -X GET http://$statip:7000/statistics/current)
	token3=$(parse_json $(curl -X POST -H "Accept: application/json" -d "grant_type=client_credentials" -u "statistics-service:stat_serv" http://$authip:5000/uaa/oauth/token) access_token)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest1.json  --header "Authorization: Bearer $token3" -H "Content-Type: application/json" -X PUT http://$statip:7000/statistics/Test2)
	# echo "Response: $response" & sleep 5
    sleep 5
	pid=$(ps -e | pgrep tcpdump)
	kill -2 $pid


	./capture_script.sh ../$cartella/Test14 interaction.pcap $1 &
	# echo "Response: $response" & sleep 5
    sleep 5
	token=$(parse_json $(curl -X POST -H "Accept: application/json" -d "grant_type=client_credentials" -u "statistics-service:stat_serv" http://$authip:5000/uaa/oauth/token) access_token)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -H "Accept: application/json" --header "Authorization: Bearer $token" -X GET http://$statip:7000/statistics/Test2)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest2.json  --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$statip:7000/statistics/Test2)
	# echo "Response: $response" & sleep 5
    sleep 5
	pid=$(ps -e | pgrep tcpdump)
	kill -2 $pid


	./capture_script.sh ../$cartella/Test15 interaction.pcap $1 &
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -H "Accept: application/json" --header "Authorization: Bearer $token" -X GET http://$statip:7000/statistics/Test5)
	pid=$(ps -e | pgrep tcpdump)
	# echo "Response: $response" & sleep 5
    sleep 5
	kill -2 $pid


	./capture_script.sh ../$cartella/Test16 interaction.pcap $1 &
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest1.json  --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$statip:7000/statistics/Test6)
	# echo "Response: $response" & sleep 5
    sleep 5
	pid=$(ps -e | pgrep tcpdump)
	kill -2 $pid


	./capture_script.sh ../$cartella/Test17 interaction.pcap $1 &
	# echo "Response: $response" & sleep 5
    sleep 5
	token=$(parse_json $(curl -X POST -H "Accept: application/json" -d "grant_type=client_credentials" -u "statistics-service:stat_serv" http://$authip:5000/uaa/oauth/token) access_token)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_NoSaving.json --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$statip:7000/statistics/TestParametri)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_NoExpAmount.json --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$statip:7000/statistics/TestParametri)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_NoExpCurrency.json --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$statip:7000/statistics/TestParametri)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_NoExpPeriod.json --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$statip:7000/statistics/TestParametri)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_NoExpTitle.json --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$statip:7000/statistics/TestParametri)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_NoIncAmount.json --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$statip:7000/statistics/TestParametri)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_NoIncCurrency.json --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$statip:7000/statistics/TestParametri)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_NoIncPeriod.json --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$statip:7000/statistics/TestParametri)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_NoIncTitle.json --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$statip:7000/statistics/TestParametri)
	# echo "Response: $response" & sleep 5
    sleep 5
	pid=$(ps -e | pgrep tcpdump)
	kill -2 $pid


	./capture_script.sh ../$cartella/Test18 interaction.pcap $1 &
	# echo "Response: $response" & sleep 5
    sleep 5
	token=$(parse_json $(curl -X POST --header "Authorization: Basic YnJvd3Nlcjo=" -d "scope=ui&grant_type=password&username=Test&password=password" http://$authip:5000/uaa/oauth/token) access_token)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -H "Accept: application/json" --header "Authorization: Bearer $token" -X GET http://$statip:7000/statistics/TestParametri)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest2.json  --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$statip:7000/statistics/Test6)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest2.json  --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$statip:7000/stistics/Test1)
	# echo "Response: $response" & sleep 5
    sleep 5
	pid=$(ps -e | pgrep tcpdump)
	kill -2 $pid


	./capture_script.sh ../$cartella/Test19 interaction.pcap $1 &
	# echo "Response: $response" & sleep 5
    sleep 5
	token=$(parse_json $(curl -X POST -H "Accept: application/json" -d "grant_type=client_credentials" -u "statistics-service:stat_serv" http://$authip:5000/uaa/oauth/token) access_token)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_ExpTitle1.json --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$statip:7000/statistics/TestLimite1)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_ExpTitle20.json --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$statip:7000/statistics/TestLimite1)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_IncTitle1.json --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$statip:7000/statistics/TestLimite1)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_IncTitle20.json --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$statip:7000/statistics/TestLimite1)
	# echo "Response: $response" & sleep 5
    sleep 5
	pid=$(ps -e | pgrep tcpdump)
	kill -2 $pid


	./capture_script.sh ../$cartella/Test20 interaction.pcap $1 &
	# echo "Response: $response" & sleep 5
    sleep 5
	token=$(parse_json $(curl -X POST -H "Accept: application/json" -d "grant_type=client_credentials" -u "statistics-service:stat_serv" http://$authip:5000/uaa/oauth/token) access_token)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_ExpTitle0.json --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$statip:7000/statistics/TestLimite1)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_ExpTitle21.json --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$statip:7000/statistics/TestLimite1)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_IncTitle0.json --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$statip:7000/statistics/TestLimite1)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d @UtenteTest_IncTitle21.json --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$statip:7000/statistics/TestLimite1)
	# echo "Response: $response" & sleep 5
    sleep 5
	pid=$(ps -e | pgrep tcpdump)
	kill -2 $pid
fi




echo "Running scenarios for Notification Service"

if [ ! $notip == '' ]; then

	./capture_script.sh ../$cartella/Test21 interaction.pcap $1 &
	# echo "Response: $response" & sleep 5
    sleep 5
	token=$(parse_json $(curl -X POST --header "Authorization: Basic YnJvd3Nlcjo=" -d "scope=ui&grant_type=password&username=Test2&password=password" http://$authip:5000/uaa/oauth/token) access_token)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d '{"accountName":"Test2","email":"l.ussi@campus.unimib.com","scheduledNotifications":{"REMIND":{"active":true,"frequency":"MONTHLY","lastNotified":"2019-01-18T15:25:48.545+0000"}}}' --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$notip:8000/notifications/recipients/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -H "Accept: application/json" --header "Authorization: Bearer $token" -X GET http://$notip:8000/notifications/recipients/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	pid=$(ps -e | pgrep tcpdump)
	kill -2 $pid

	./capture_script.sh ../$cartella/Test22 interaction.pcap $1 &
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -H "Accept: application/json" --header "Authorization: Bearer $token" -X GET http://$notip:8000/notifications/recipients/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	pid=$(ps -e | pgrep tcpdump)
	kill -2 $pid

	./capture_script.sh ../$cartella/Test23 interaction.pcap $1 &
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d '{"accountName":"Test2","email":"l.ussi@campus.unimib.com","scheduledNotifications":{"REMIND":{"active":true,"frequency":"MONTHLY","lastNotified":"2019-01-18T15:25:48.545+0000"}}}' --header "Authorization: $token" -H "Content-Type: application/json" -X PUT http://$notip:8000/notifications/recipients/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	pid=$(ps -e | pgrep tcpdump)
	kill -2 $pid

	./capture_script.sh ../$cartella/Test24 interaction.pcap $1 &
	# echo "Response: $response" & sleep 5
    sleep 5
	token=$(parse_json $(curl -X POST --header "Authorization: Basic YnJvd3Nlcjo=" -d "scope=ui&grant_type=password&username=TestParametri&password=password" http://$authip:5000/uaa/oauth/token) access_token)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d '{"accountName":"TestParametri","scheduledNotifications":{"REMIND":{"active":true,"frequency":"MONTHLY","lastNotified":"2019-01-18T15:25:48.545+0000"}}}' --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$notip:8000/notifications/recipients/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d '{"accountName":"TestParametri","email":"l.ussi@campus.unimib.com","scheduledNotifications":{"REMIND":{"frequency":"MONTHLY","lastNotified":"2019-01-18T15:25:48.545+0000"}}}' --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$notip:8000/notifications/recipients/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d '{"accountName":"TestParametri","email":"l.ussi@campus.unimib.com","scheduledNotifications":{"REMIND":{"active":true,"lastNotified":"2019-01-18T15:25:48.545+0000"}}}' --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$notip:8000/notifications/recipients/current)
	# echo "Response: $response" & sleep 5
    sleep 5
	pid=$(ps -e | pgrep tcpdump)
	kill -2 $pid

	./capture_script.sh ../$cartella/Test25 interaction.pcap $1 &
	# echo "Response: $response" & sleep 5
    sleep 5
	token=$(parse_json $(curl -X POST --header "Authorization: Basic YnJvd3Nlcjo=" -d "scope=ui&grant_type=password&username=TestParametri&password=password" http://$authip:5000/uaa/oauth/token) access_token)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -d '{"accountName":"TestParametri","email":"l.ussi@campus.unimib.com","scheduledNotifications":{"REMIND":{"active":true,"frequency":"MONTHLY","lastNotified":"2019-01-18T15:25:48.545+0000"}}}' --header "Authorization: Bearer $token" -H "Content-Type: application/json" -X PUT http://$notip:8000/notifications/recipients/curren)
	# echo "Response: $response" & sleep 5
    sleep 5
	response=$(curl -H "Accept: application/json" --header "Authorization: Bearer $token" -X GET http://$notip:8000/notifications/recipients/curre)
	# echo "Response: $response" & sleep 5
    sleep 5
	pid=$(ps -e | pgrep tcpdump)
	kill -2 $pid
fi
