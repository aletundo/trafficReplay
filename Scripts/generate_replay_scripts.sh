#!/bin/bash
# generates replay scripts
# usage: ./generate_replay_scripts.sh TestDir/captureStreamsDirectory ip_list password_list
# ip_auth_service -> used to obtain auth token
# port_list -> ports of containers to consider (can be extracted from capture file)

if [[ $# -lt 2 ]]; then
	echo 'missing args ---> ./generate_replay_scripts.sh <testdir/captureStreamsDirectory> <Destination_Dir> <port_list>'
	exit 1
fi


# part of the filtering is performed during the split
# need to specify the ips of the applications under test

cd $1
echo "Generating Python test scripts using .cap files in $1"

if [ ! -d "$2" ]; then
	mkdir -p $2;
fi

for filename in $( ls -v *.cap ); do
    destScript=$2"/"$filename"_replay.py"
    portList="${@:3:$((($#-2)))}"
	portList=$(echo ${portList// /,})
	echo "Trying to generate $destScript filtering on ports ports ${portList[*]}"
    python3 ../../pyshark_test.py $filename $destScript $portList
done

exit 0
