#splits pcap file into tcp streams, saves them in directory
#usage: ./split.sh pcapfile.pcap TestDir/savedir

if [[ $# -lt 2 ]] ; then
	echo 'missing args ---> ./split.sh <pcapfile.pcap> <TestDir/savedir> [<list_of_containers_ip>]'
	exit 1
fi

if [ ! -d "$2" ];
then
	mkdir -p $2;
fi
echo "Splitting..."

#Se viene passati più di 2 argomenti allora viene fatto filtraggio su ip dei container passati come argomenti
if [[ $# -gt 2 ]] ; then
	i=2
	condizione=""
	list=${@:3:$(($#-2))}
	echo "Container IPs: ${list[*]}"
	for container_ip in $list; do
		#passo direttamente gli ip perchè in questo caso non è detto che siano ancora in esecuzione
		echo "Container IP: $container_ip"
		i=$((i+1))
		if [[ $i -eq $# ]] ; then
			condizione="$condizione ip.addr==$container_ip"
		else
			condizione="$condizione ip.addr==$container_ip or"
		fi
	done
	echo "Condition: $condizione"
	for stream in $(tshark -r $1 -T fields -e tcp.stream -Y "$condizione"| sort -n | uniq)
	do
	    tshark -r $1 -2 -w $2/stream-$stream.cap -Y "tcp.stream==$stream"
	done
else
	for stream in $(tshark -r $1 -T fields -e tcp.stream | sort -n | uniq)
	do
	    tshark -r $1 -2 -w $2/stream-$stream.cap -Y "tcp.stream==$stream"
	done
fi
echo "Done!"
