#!/bin/bash
# generates replay scripts
# usage: ./generate_replay_scripts.sh TestDir/captureStreamsDirectory ip_list password_list
# ip_auth_service serve per ottenere token di autenticazione
# port_list porte dei container da tenere in considerazione (posso prenderli dal file di test creato dalla cattura)

if [[ $# -lt 2 ]] ; then 
	echo 'missing args ---> ./generate_replay_scripts.sh <testdir/captureStreamsDirectory> <port_list>'
	exit 1
fi


#una parte del filtraggio è stata fatta durante lo split
#adesso devo specificare gli ip delle applicazioni che voglio considerare

cd $1
for filename in $( ls -v *.cap ); do
    	destScript=$filename"_replay.py"
    	listIP="${@:2:$((($#-1)))}"
	listIP=$(echo ${listIP// /,})
	#echo $listIP
	#echo $listPass
	#Passo come argomento unica stringa e da pyhton creo lista
    	python3 ../../pyshark_test.py $filename $destScript $listIP 
done

exit 0
