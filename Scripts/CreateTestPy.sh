
for i in $(seq $1 $2); 
do
	./generate_replay_scripts.sh Test$i/SplitRest Notification_Service 8000 
	./generate_replay_scripts.sh Test$i/SplitRest Statistics_Service 7000
	./generate_replay_scripts.sh Test$i/SplitRest Account_Service 6000
done


