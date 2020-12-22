#usage: ./split_mongo.sh pcapfile.pcap savedir list

if [[ $# -lt 2 ]] ; then
	echo 'missing args ---> ./split_mongo.sh <pcapfile.pcap> <testdir/savedir> [<list_of_containers_ip>]'
	exit 1
fi

if [ ! -d "$2" ];
then
	mkdir -p $2;
fi
count_op=0

#Se ho passato come argomenti i nomi dei container allora effettuo il filtraggio
#Considerare che è già filtrato leggendo solo i pacchetti mongo--- serve solo per specificare quale applicazione ascoltare
if [[ $# -gt 2 ]] ; then
	i=2
	condizione=""
	list=${@:3:$(($#-2))}
	echo "Mongo container IPs: ${list[*]}"
	for container_ip in $list; do
		#passo direttamente gli ip perchè in questo caso non è detto che siano ancora in esecuzione
		echo "Mongo container IP: $container_ip"
		i=$((i+1))
		if [[ $i -eq $# ]] ; then
			condizione="$condizione ip.addr==$container_ip"
		else
			condizione="$condizione ip.addr==$container_ip or"
		fi
	done
	echo "Condition: $condizione"
	elements=$(tshark -r $1 -T fields -e ip.src -e ip.dst -e tcp.port -e mongo.element.name -e mongo.opcode -e mongo.request_id -E separator=';' -Y "$condizione")
else
	echo "No condition"
	elements=$(tshark -r $1  -T fields -e ip.src -e ip.dst -e tcp.port -e mongo.element.name -e mongo.opcode -e mongo.request_id -E separator=';')
fi
#echo $elements
echo "Splitting..."
for element in $elements
do
	IFS=';' # space is set as delimiter
	read -ra ADDR <<< "$element" # str is read into an array as tokens separated by IFS
	operations=${ADDR[3]}
	IFS=','
	read -ra op <<< "$operations"
	codeop=${ADDR[4]}
	ports_union=${ADDR[2]}
	IFS=','
	read -ra ports <<< "$ports_union"
	if [ ! -z "${op[0]}" ] &&  [ ${ports[1]} == "27017" ] && ( [ "$codeop" == "2004" ] || [ "$codeop" == "2013" ] ); then
		ip_mongo=${ADDR[1]}
		echo $ip_mongo > $2/operation-$count_op-${op[0]}.txt
		seqnum=${ADDR[5]}
		#Stiamo considerando solo le operazioni verso il database quindi non vado a prendere in considerazione le risposte
		tshark -r $1 -2 -d tcp.port==27017,mongo -w $2/operation-$count_op-${op[0]}.cap -Y "( mongo.request_id==$seqnum and ip.dst==$ip_mongo ) or ( mongo.response_to==$seqnum and ip.src==$ip_mongo )"
		count_op=$((count_op+1))
	fi
done
echo "Done!"
