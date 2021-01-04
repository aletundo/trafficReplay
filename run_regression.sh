#!/bin/bash

export CONFIG_SERVICE_PASSWORD="conf_serv"
export NOTIFICATION_SERVICE_PASSWORD="not_serv"
export STATISTICS_SERVICE_PASSWORD="stat_serv"
export ACCOUNT_SERVICE_PASSWORD="acc_serv"
export MONGODB_PASSWORD="mongo"

VERSION_NUMBER=$1

cd Versione$VERSION_NUMBER\_*/

new_version=$PWD

echo "Version: ${new_version}"

mkdir NonRegressionTesting

mkdir NonRegressionTesting/Account

mkdir NonRegressionTesting/Statistics

mkdir NonRegressionTesting/Notification

cd ..

old_version=$((VERSION_NUMBER+1))

if [ -z "$( find * -type d -name 'Versione'$old_version'_*' )" ]; then
	echo "No older versions! Exiting..."
	exit 1
fi

cd Versione$old_version\_*/

echo "Old version: ${PWD}"

if ( [ -z "$( find * -type d -name 'TestSuite_Account' )" ] && [ -z "$( find * -type d -name 'TestSuite_Notification' )" ] && [ -z "$( find * -type d -name 'TestSuite_Statistics' )" ] ) ; then
	echo "Nessun Test"
else

	yes | cp -a  TestSuite_Account  $new_version/NonRegressionTesting/
	yes | cp -a  TestSuite_Notification  $new_version/NonRegressionTesting/
	yes | cp -a  TestSuite_Statistics  $new_version/NonRegressionTesting/

	yes | cp -a  auth-mock-response-acc.sh  $new_version/NonRegressionTesting/Account/
	yes | cp -a  auth-mock-response-acc.json  $new_version/NonRegressionTesting/Account/
	yes | cp -a  auth-mock-response-not.sh  $new_version/NonRegressionTesting/Notification/
	yes | cp -a  auth-mock-response-not.json  $new_version/NonRegressionTesting/Notification/
	yes | cp -a  auth-mock-response-stat.sh  $new_version/NonRegressionTesting/Statistics/
	yes | cp -a  auth-mock-response-stat.json  $new_version/NonRegressionTesting/Statistics/

	cd ..

	echo "Building MongoDB Mockup"

	cd my_docker_db

	docker build -t mockupmongodb .

	cd ..

	echo "Building Auth Mockup"

	cd my_mockup_app_Auth

	docker build -t mockupapp .

	cd ..

	cd Versione$i\_*


	yes | cp -a  piggymetrics/.  NonRegressionTesting/Account/
	yes | cp -a  piggymetrics/.  NonRegressionTesting/Statistics/
	yes | cp -a  piggymetrics/.  NonRegressionTesting/Notification/

	yes | cp -a  ../Microservices_Files/Account/.  NonRegressionTesting/Account/
	yes | cp -a  ../Microservices_Files/Notification/.  NonRegressionTesting/Notification/
	yes | cp -a  ../Microservices_Files/Statistics/.  NonRegressionTesting/Statistics/

	cd NonRegressionTesting/Account/

	# yes | cp -a ../../Files_Config/application.yml account-service/target/test-classes/
	# yes | cp -a ../../Files_Config/application.yml account-service/src/test/resources/
	# yes | cp -a ../../Files_Config/account-service.yml config/target/classes/shared/
	yes | cp -a ../../Files_Config/account-service.yml config/src/main/resources/shared/

	# yes | cp -a /home/luca/Tesi/Test_Microservice/Files_Config/application.yml account-service/target/test-classes/
	# yes | cp -a /home/luca/Tesi/Test_Microservice/Files_Config/application.yml account-service/src/test/resources/
	# yes | cp -a /home/luca/Tesi/Test_Microservice/Files_Config/account-service.yml config/target/classes/shared/
	# yes | cp -a /home/luca/Tesi/Test_Microservice/Files_Config/account-service.yml config/src/main/resources/shared/
	# yes | cp -a /home/luca/Tesi/Test_Microservice/PiggyMetrics/account-service/src/main/java/com/piggymetrics/account/service/AccountServiceImpl.java account-service/src/main/java/com/piggymetrics/account/service/

	mvn package -DskipTests

	docker-compose -f docker-compose.yml -f docker-compose.dev.yml build
	docker-compose  -f docker-compose.yml -f docker-compose.dev.yml up -d --force-recreate

	echo "-------------------------ACCOUNT-SERVICE----------------------------"

	ipacc=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep account_account-service | awk '{print $1}'))
	count=1


	while [ -z "$ipacc" ]
	do
		if (( $count > 50 )); then
			ipacc="non_connesso"
		else
		      	sleep 20
			ipacc=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep account_account-service | awk '{print $1}'))
			count=$((count+1))
		fi
	done

	if [ "$ipacc" != "non_connesso" ]; then
		printf 'try to connect...'
		until [ $(curl -s -o /dev/null -w "%{http_code}" $ipacc:6000) != "000" ]; do
		    printf '.'
		    sleep 20
		done
		printf "connect to account service \n"
	fi

	sleep 10

	chmod +x auth-mock-response-acc.sh

	# docker ps

	ipmockupapp=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep account_auth-service | awk '{print $1}'))

	idmockupmongo=$(docker ps | grep account_account-mongodb | awk '{print $1}')

	./auth-mock-response-acc.sh $ipmockupapp

	cd ..

	echo "id del container: $idmockupmongo"

	./../../Test.sh TestSuite_Account/ $idmockupmongo &> Account/Test_Report.txt

	docker-compose down


	echo "-------------------------NOTIFICATION-SERVICE----------------------------"

	cd Notification

	# yes | cp -a ../../Files_Config/application.yml notification-service/target/test-classes/
	# yes | cp -a ../../Files_Config/application.yml notification-service/src/test/resources/
	# yes | cp -a ../../Files_Config/notification-service.yml config/target/classes/shared/
	yes | cp -a ../../Files_Config/notification-service.yml config/src/main/resources/shared/

	# yes | cp -a /home/luca/Tesi/Test_Microservice/PiggyMetrics/config/target/classes/shared/notification-service.yml config/target/classes/shared/
	# yes | cp -a /home/luca/Tesi/Test_Microservice/PiggyMetrics/config/src/main/resources/shared/notification-service.yml config/src/main/resources/shared/
	# yes | cp -a /home/luca/Tesi/Test_Microservice/PiggyMetrics/notification-service/target/test-classes/application.yml notification-service/target/test-classes/
	# yes | cp -a /home/luca/Tesi/Test_Microservice/PiggyMetrics/notification-service/src/test/resources/application.yml notification-service/src/test/resources/

	cd ../../..

	cd my_docker_db

	docker build -t mockupmongodb .

	cd ..

	cd my_mockup_app_Auth

	docker build -t mockupapp .

	cd ..

	cd Versione$i\_*/NonRegressionTesting/Notification/

	mvn package -DskipTests

	docker-compose -f docker-compose.yml -f docker-compose.dev.yml build
	docker-compose  -f docker-compose.yml -f docker-compose.dev.yml up -d --force-recreate

	ipnot=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep notification_notification-service | awk '{print $1}'))
	count=1


	while [ -z "$ipnot" ]
	do
		if (( $count > 50 )); then
			ipnot="non_connesso"
		else
		      	sleep 20
			ipnot=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep notification_notification-service | awk '{print $1}'))
			count=$((count+1))
		fi
	done

	if [ "$ipnot" != "non_connesso" ]; then
		printf 'try to connect...'
		until [ $(curl -s -o /dev/null -w "%{http_code}" $ipnot:8000) != "000" ]; do
		    printf '.'
		    sleep 20
		done
		printf "connect to notification service \n"
	fi
	sleep 10

	chmod +x auth-mock-response-not.sh

	ipmockupapp=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep notification_auth-service | awk '{print $1}'))

	idmockupmongo=$(docker ps | grep notification_notification-mongodb | awk '{print $1}')

	./auth-mock-response-not.sh $ipmockupapp

	cd ..

	echo "id del container: $idmockupmongo"

	./../../Test.sh TestSuite_Notification/ $idmockupmongo &> Notification/Test_Report.txt

	docker-compose down

	echo "-------------------------STATISTICS-SERVICE----------------------------"

	cd Statistics

	# yes | cp -a /home/luca/Tesi/Test_Microservice/PiggyMetrics/config/target/classes/shared/statistics-service.yml config/target/classes/shared/
	# yes | cp -a /home/luca/Tesi/Test_Microservice/PiggyMetrics/config/src/main/resources/shared/statistics-service.yml config/src/main/resources/shared/
	# yes | cp -a /home/luca/Tesi/Test_Microservice/PiggyMetrics/statistics-service/target/test-classes/application.yml statistics-service/target/test-classes/
	# yes | cp -a /home/luca/Tesi/Test_Microservice/PiggyMetrics/statistics-service/src/test/resources/application.yml statistics-service/src/test/resources/

	# yes | cp -a ../../Files_Config/application.yml statistics-service/target/test-classes/
	# yes | cp -a ../../Files_Config/application.yml statistics-service/src/test/resources/
	# yes | cp -a ../../Files_Config/statistics-service.yml config/target/classes/shared/
	yes | cp -a ../../Files_Config/statistics-service.yml config/src/main/resources/shared/

	# docker rm -f $(docker ps -a -q)

	# docker rmi -f $(docker images -q)

	# yes | docker system prune

	cd ../../..

	cd my_docker_db

	docker build -t mockupmongodb .

	cd ..

	cd my_mockup_app_Auth

	docker build -t mockupapp .

	cd ..

	cd Versione$i\_*/NonRegressionTesting/Statistics/

	mvn package -DskipTests

	docker-compose -f docker-compose.yml -f docker-compose.dev.yml build
	docker-compose  -f docker-compose.yml -f docker-compose.dev.yml up -d --force-recreate

	ipstat=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep statistics_statistics-service | awk '{print $1}'))
	count=1


	while [ -z "$ipstat" ]
	do
		if (( $count > 50 )); then
			ipstat="non_connesso"
		else
		      	sleep 20
			ipstat=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep statistics_statistics-service | awk '{print $1}'))
			count=$((count+1))
		fi
	done

	if [ "$ipstat" != "non_connesso" ]; then
		printf 'try to connect...'
		until [ $(curl -s -o /dev/null -w "%{http_code}" $ipstat:7000) != "000" ]; do
		    printf '.'
		    sleep 20
		done
		printf "connect to statistics service \n"
	fi

	sleep 10

	chmod +x auth-mock-response-stat.sh

	ipmockupapp=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep statistics_auth-service_ | awk '{print $1}'))

	idmockupmongo=$(docker ps | grep statistics_statistics-mongodb | awk '{print $1}')

	./auth-mock-response-stat.sh $ipmockupapp

	cd ..

	echo "id del container: $idmockupmongo"

	./../../Test.sh TestSuite_Statistics/ $idmockupmongo &> Statistics/Test_Report.txt

	docker-compose down

	cd ../..
fi