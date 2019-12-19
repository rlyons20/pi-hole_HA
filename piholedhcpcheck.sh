#!/bin/bash
#modified script from: https://discourse.pi-hole.net/t/good-solution-to-automatically-revert-to-normal-if-pi-hole-dies/10059/4
#credit to the script that was shared.
#zeit0dn1 simplified/modified to use dhcp config files that are kept in sync from primary DHCP pihole using rsync

#primary Pihole
target=192.168.x.x

#ping command used to determine if host is up
count=$( ping -c 3 -w 3 $target | grep icmp* | wc -l )

#lock file dir
dir=/tmp/
 
#command to check for FTL errors
probe=$(curl -s http://${target}/admin/ | grep offline)
check=$(echo $probe)
 
 
#config for starting DHCP server
dhcpStartRange="192.168.x.x"
dhcpStopRange="192.168.x.x"
dhcpRouter="192.168.x.x"
dhcpLeaseTime="24"
dhcpDomain="domain.local"


#check for reply, if we do not get any ping responses, we are down
if [ $count -eq 0 ]
then
	#do dhcp
    echo "pihole_status=0,Primary PiHole is DOWN. DHCP server is not responding!"
	#check for lockfile
    if [ -e ${dir}dhcp.on ]
    then
		echo "Secondary DHCP server already enabled. No changes or notifications performed."
		exit 0
	else
		echo "Generating lock file"
		#generate lockfile to prevent double notifications
		touch ${dir}dhcp.on
		echo "Done."

		#Enable DHCP A B C D E. A=Range start, B=Range end, C=Gateway D=Lease Time E=Domain
		#        pihole -a enabledhcp "192.168.1.200" "192.168.1.251" "192.168.1.1" "1h" "local"
		#FLTDNS crashes if hour string is specified under D
		#pihole -a enabledhcp 192.168.0.111 192.168.0.219 192.168.1.1 1 timeghost.com
		#the full path is need or crontab cannot find the command
		/usr/local/bin/pihole -a enabledhcp $dhcpStartRange $dhcpStopRange $dhcpRouter $dhcpLeaseTime $dhcpDomain

 
		#restart dns and activate DHCP server
		echo "Restarting DNS."
		/usr/local/bin/pihole restartdns

 	fi
	exit 0
#check for FTLDNS error via web
elif [ $count -eq 3 ] && [[ $check == *"offline"* ]]
then
        echo "pihole_status=1,Primary PiHole is UP, but with FTLDNS error!"
		#check for lockfile
        if [ -e ${dir}dhcp.on ]
        then
        	echo "Secondary DHCP server already enabled. No changes or notifications performed."
        	exit 0
		else
        	echo "Generating lock file"
			#generate lockfile to prevent double notifications
        	touch ${dir}dhcp.on

      	
			#Enable DHCP A B C D E. A=Range start, B=Range end, C=Gateway D=Lease Time E=Domain
			#        pihole -a enabledhcp "192.168.1.200" "192.168.1.251" "192.168.1.1" "1h" "local"
			#FLTDNS crashes if hour string is specified under D
			/usr/local/bin/pihole -a enabledhcp $dhcpStartRange $dhcpStopRange $dhcpRouter $dhcpLeaseTime $dhcpDomain
 
		#restart dns and activate DHCP server
		echo "Restarting DNS."
		/usr/local/bin/pihole restartdns

		exit 0
	fi
else # PiHole-PROD is UP!  we got our ping responses and no FTL error
	if [ -e ${dir}dhcp.on ]
	then
		echo "pihole_status=1,Primary PiHole is UP. Shutdown Secondary DHCP"
		#restart pihole / disable DNS seerver
		echo "Restarting DNS."
		/usr/local/bin/pihole -a disabledhcp
		/usr/local/bin/pihole restartdns
		
		#remove our lock file
		rm -rf ${dir}dhcp.on
     	
		exit 0
	else #nothing to do, everything is fine
		echo "pihole_status=1,Primary PiHole is UP. Nothing to do."
	fi

fi


#END OF SCRIPT
