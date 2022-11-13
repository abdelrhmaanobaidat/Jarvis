#!/bin/bash

# This creats .tar.gz backup file for the script 
function Backup {
	Backup=./menu-backup_$(date +%Y-%m-%d_%H-%M).tar.gz
	tar -zcvf $Backup ./menu.sh
}

# This is the Jarvis Hello message 
function Jarvis_hello {
	echo "[!] Hello, Jarvis is here to help you"
	echo -e "[!] Today is $(date)"
	echo -e "[!] Developed by: Abed Al-Rahman Obeidat\n"
}

# This is the main menu of the program 
function mainMenu {
	echo -e "\n\e[1;46mM A I N - M E N U\e[0m"
	echo -e "\e[1;36m------\n1-status\n2-who\n3-update\n4-service\n5-storage\n\n0: quit\n------\e[0m"
}

function Status {
	# load average
	echo -e "\e[1;36ma- Load Average \e[0m"
	uptime | awk '{print $6,$7,$8,$9,$10}'
	
	# cpu utilization 
	echo -e "\e[1;36mb- Current CPU utilization and Memory usage\e[0m"
	echo "cpu utilization is: $(expr 100 - $(top -b -n 1 | grep Cpu | awk '{print $8}'| cut -f 1 -d "."))%"
	
	# memory usage 
	echo "memory usage is: $(free -h | grep "Mem" | awk '{print $3}')"
	
	# network bandwidth utilization 
	echo -e "\e[1;36mc- EXTRA | Network bandwidth utilization \e[0m"
	INF=`ip a | grep "state UP" | awk '{print $2}' | cut -f 1 -d ":" # find interface name`
	Rx1=`cat /sys/class/net/$INF/statistics/rx_packets` 
	Tx1=`cat /sys/class/net/$INF/statistics/tx_packets`
	sleep 1
	Rx2=`cat /sys/class/net/$INF/statistics/rx_packets`
	Tx2=`cat /sys/class/net/$INF/statistics/tx_packets`
	TXperSecond=`expr $Tx2 - $Tx1`
        RXperSecond=`expr $Rx2 - $Rx1`
        echo -e "tx $INF: $TXperSecond pkts/s \nrx $INF: $RXperSecond pkts/s"
	
	# disk utilization
	echo -e "\e[1;36md- EXTRA | disk utilization \e[0m"
	echo "disk utilization is: $(df -P | grep /dev/sd | grep -v -E '(tmp|boot)' | awk '{print $5}')"
}

function Who {
	# The current logged in users 
	echo -e "\e[1;36ma- the current logged-in users on the system\e[0m"
	w -h -s | awk '{print $1}' | uniq | awk '{print NR"- "$1}'
	
	# Number of log in to the user account
	echo -e "\e[1;36mb- how many are logged-in to the same user account\e[0m"
	w -h -s | awk '{print "is the number of users logged in as  " $1}' | uniq -c
	
	#the top process for each user account based on CPU RAM Network Disk  
	echo -e "\e[1;36mc- EXTRA | the top process for each user account based on CPU/RAM/Network/Disk  \e[0m"
	w -h -s | awk '{print $1}' | uniq | awk '{print $1}' > users.txt # write users in a txt file 
	cat users.txt | while read user 
	do  
		# CPU and Memory via top command 
		top -b -u $user -n 1 | tail -n +8 > $user.txt
		echo -e "top running process by highest CPU for $user: \e[1;31m \
		$(cat $user.txt | awk 'NR==1 {print $NF}') \e[0m"
		echo -e "top running process by highest Memory for $user: \e[1;31m \
		$(cat $user.txt | awk -v var=$(cat $user.txt | \
		awk '{if ($10 > max) max=$10} END {print max}' ) '{if ($10 == var)  print $NF;}') \e[0m"
		
		# Disk IO via iotop command
		sudo iotop -oabn 5 | grep $user > $user-io.txt
		
		if [ -s $user-io.txt ]; then
        		# The file is not-empty.
			echo -e "top running process by Disk I/O for $user: \e[1;31m \
			$(cat $user-io.txt | sort | uniq | awk -v var=$(cat $user-io.txt | \
			awk '{if ($4+$6 > max) max=$4+$6} END {print max}') '{if ($4+$6 == var) print $9;}') \e[0m"
		else
        		# The file is empty.
        		echo -e "top running process by highest Disk I/O for $user: \e[1;31mNo I/O operations are running\e[0m"
		fi
		rm -f $user.txt 
		rm -f $user-io.txt
	done
	rm -f users.txt
}

function Update {
	
	# which packages requires updates 
	echo -e "\e[1;36ma- which packages requires updates \e[0m"
	apt list --upgradable 
	
	# check if upgrade is possible 
	echo -e "\e[1;36mb- is there a possibility for upgrade to newer OS release \e[0m"
	do-release-upgrade -c
	
	# version installed vs version running 
	echo -e "\e[1;36mc- EXTRA | check if there is a newer version for the kernel \e[0m"
	Running_kernel=`dpkg --list | grep linux-image | grep $(uname -r) | awk '{print $2}'`
	Most_recent_Installed_version=`dpkg --list | grep linux-image | tail -1 | awk '{print $2}'`
	if [ "$Running_kernel" = "$Most_recent_Installed_version" ] ; then 
		echo -e "You are running the most recent kernel image: \e[1;31m$Running_kernel\e[0m"
	else
		echo -e "there is a newer version of the kernel: \e[1;31m$Most_recent_Installed_version\e[0m"
	fi  
}

function Service {
	echo -e "\e[1;36ma- check a service status based on user input \e[0m"
	
	running=1
	while [ $running = 1 ] ; do 
	# enter a service name
		read -p "Enter service name: " srvs 
		X=`systemctl list-units --full -all | grep "$srvs.service" | awk '{print $1}'`
		Y=$srvs.service
	# check if the service exists
		if [ "$X" = "$Y" ] ; then 
	# print the status
			systemctl status $srvs --no-pager
		else 
			echo -e "\e[1;31mservice not exist\e[0m"
			echo -e "\n\e[1;36m1- try again\n0: back to main menu\e[0m\n"
			read -p "Enter you choice: " running 
			
			while [ $running != 1 ] && [ $running != 0 ] ; do 
				read -p "Enter you choice: " running 
			done 
			
			[ $running = 1 ] && continue || break
		fi 
	# do start/stop/restart based on user input 
		echo -e "\e[1;36mb- ask for operation to be applied on $srvs Start/Stop/Restart/Nothing\n\e[0m"
		echo -e "\e[1;46mS E R V I C E - M E N U\e[0m"
		echo -e "\e[1;36m1-start\n2-stop\n3-restart\n\n0: back to main menu\n\e[0m"
			
		read -p "Enter your choice: " operation 
		while [ $running = 1 ] 
		do 
			Inv=1
			[ $operation = 1 ] && { systemctl start $srvs; echo -e "\e[1;32mDone\e[0m"; Inv=0; }
			[ $operation = 2 ] && { systemctl stop $srvs; echo -e "\e[1;32mDone\e[0m"; Inv=0; }
			[ $operation = 3 ] && { systemctl restart $srvs; echo -e "\e[1;32mDone\e[0m"; Inv=0; }
			[ $operation = 0 ] && { running=0; break; }
			[ $Inv = 1 ] && echo -e "\e[1;31mInvalid input\e[0m"
			read -p "Enter your choice: " operation  
		done 
	done		
}

function Storage {
	
	# list all disks/partitions and mount points via lsblk command
	echo -e "\e[1;36ma- list all disks partitions and mount points \e[0m"
	echo -e "disks:\n$(lsblk -l | grep disk | awk '{print NR"- "$1}')"
	echo -e "partitions and mountpoint:\n$(lsblk -l | grep part | awk '{print NR"- "$1" mounted on: " $7}')"

	# check unmounted entries from from the fstab  
	echo -e "\e[1;36mb- check unmounted entries from the fstab \e[0m"
	blkid | grep -v -E loop | awk '{print $2}' | cut -f 2 -d "\"" > uuid.txt #UUID of installed devices
	cat uuid.txt | while read uuid 
	do
		output=`cat /etc/fstab | grep $uuid | cut -f 2 -d "=" | awk '{print $1}'` 
		if [ "$uuid" = "$output" ] ; then
			echo "device $uuid is mounted"
		else 
			echo "device $uuid is unmounted"
		fi  
	done
	
	# print out uuid
	echo -e "\e[1;36mc- EXTRA | check the UUID for the partitions \e[0m"
	blkid | grep -v -E loop
	
	# how much space the user is consuming 
	echo -e "\e[1;36mc- EXTRA | get how much space the users are using \e[0m"
	ls /home > users.txt
	cat users.txt | while read user
	do 
		consumption=`du /home/aobeidat -d 1 | awk '{s+=$1} END {print s}'`
		echo -e "user $user is consuming $(expr $consumption / 1024 )KB of disk size \n"
	done
	
	rm -f uuid.txt
	rm -f users.txt
}

function main {

	# This is to clear the Screen 
	tput clear 

	# Take backup of the current file
	Backup
	
	# Print the hello message
	Jarvis_hello 
	
	# Dicision making 
	loop=1
	while [ $loop = 1 ] ; do 
	
	# print main menu
	mainMenu 
	
	# take user input
	read -p "Enter your choice: " choice
	
		case $choice in 
			0) loop=0 # exit the program 
			  ;;
			1) Status # system status
			  ;;
			2) Who # who is it now 
			  ;;
			3) Update # do i need update 
			  ;;
			4) Service # service my services 
			  ;;
			5) Storage # list all storage resources 
			  ;;
			*) echo -e "\e[1;31mInvalid input\e[0m" # invalid input
			  ;;
		esac 	
	done 
}

main
