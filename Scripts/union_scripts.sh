#Per unire tutti gli script python di test in un unico test
#./union_scripts TestDir SplitRest

if [[ $# -lt 1 ]] ; then
	echo 'missing args ---> ./union_scripts.sh <TestDir/SplitRest/AppRestDir>'
	exit 1
fi

cd $1

echo "Unifying Python tests in a single test file into: $1"

if [ -f "test_complete.py" ]; then
	rm -f "test_complete.py"
fi

if [ ! -d "TestComplete" ];
then
	mkdir -p "TestComplete";
fi

echo "Found $( ls -v *.py | wc -c ) Python tests to be unified"
if [ $( ls -v *.py | wc -c ) -ne 0 ]; then
  	echo "import requests" > ./TestComplete/test_complete.py
	echo "import json" >> ./TestComplete/test_complete.py
	echo "import time" >> ./TestComplete/test_complete.py
	echo "import re" >> ./TestComplete/test_complete.py
	echo "import sys" >> ./TestComplete/test_complete.py
	echo "from bson.json_util import loads" >> ./TestComplete/test_complete.py
	echo "import os.path" >> ./TestComplete/test_complete.py
	echo "import traceback" >> ./TestComplete/test_complete.py
	echo "import logging" >> ./TestComplete/test_complete.py
	echo "" >> ./TestComplete/test_complete.py
	echo "" >> ./TestComplete/test_complete.py
	echo "LOG_FILENAME = 'log_test_file.out'" >> ./TestComplete/test_complete.py
    	echo "logging.basicConfig(filename=LOG_FILENAME, level=logging.DEBUG)" >> ./TestComplete/test_complete.py
    	echo "logging.debug('File di Log per Test')" >> ./TestComplete/test_complete.py
	echo "codeexit=0" >> ./TestComplete/test_complete.py
	for filename in $( ls -v *.py ); do
		cat $filename >> ./TestComplete/test_complete.py
	done
	echo "if codeexit==1:" >> ./TestComplete/test_complete.py
	echo -e "\texit(1)" >> ./TestComplete/test_complete.py
	echo "else:" >> ./TestComplete/test_complete.py
	echo -e "\texit(0)" >> ./TestComplete/test_complete.py
else
	echo "There are no test scripts"
fi



