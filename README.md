# TrafficReplay

A simple environment to replay the interaction between microservices that run on docker containers

### Prerequisites

- jdk8
- git
- docker and docker-compose
- tshark
- python3
- pip3
- pyshark, pymongo (see requirements.txt)
- go
- libpcap-dev
- mongoreplay

## Capturing traffic

Open another terminal and run `brctl show`. you should see a bridge interface with 5 docker container running on it ( registry, gateway, gateway database, bank account, bank account database).

now run `tcpdump -i interface -w capture.pcap` where `interface` is the name of the interface where the container are running.

You can now use the application normally (add bank accounts for example) while the traffic between containers is captured in the `capture.pcap` file.


## Replaying traffic

You can use the scripts in this repository to replay the captured traffic in the `capture.pcap` file. The current version can only send traffic to the bank account microservice, which runs on port 8081.

first run the script `split.sh` to split a single capture file in streams:

  `./split.sh capture.pcap streamsDirectory`

in `streamsDirectory` you now have the single-stream capture files.

to generate a python replay script for each capture file use:

  `./generate_replay_scripts.sh streamsDirectory`

This will use `pyshark_test.py` to generate a replay script for each capture file in `streamsDirectory`. However, only the replay scripts for the streams that contain traffic with the microservice which run on 8081 will work.

You can now replay the traffic (if the microservice application is running) by going into `streamsDirectory` and launching:

  `python3 stream-X.cap_replay.py`

## Issues

#TODO
at line `91` in `pyshark_test` the string `packet.http.file_data` sometimes presents escaped unicode characters `\xa` : need to handle this case

