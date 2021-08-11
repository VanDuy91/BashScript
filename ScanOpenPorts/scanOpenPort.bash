#!/usr/bin/env bash
#Scan all open ports of all host in an CIDR

cidr=$1
criticalFile=$2 #saving critical open ports
openingPortFile=$3 #saving open ports
critPorts=$4 #list of critical list

nmap -sL -n $cidr | awk '/Nmap scan report/{print $NF}' > IPs.txt 
ips="IPs.txt"
if [ -s $ips ]; then #check file is not empty
	while IFS='' read -r _ip
	do
		#grep -v to exclude lines contain "closed" like: All 1000 scanned ports on dc39.kdata.vn (103.109.39.39) are closed
		nmap $_ip | egrep 'open|closed|filtered|unfiltered' | grep -v ports | awk '{print $1}' > openingPort.txt 
		ports="openingPort.txt"
		if [ -s $ports ]; then
			echo "-----------------------------------" >> $openingPortFile
			echo "| $_ip | opening ports |" >> $openingPortFile
			echo "-----------------------------------" >> $openingPortFile
			cat $ports >> $openingPortFile
			echo "***********###************" >> $openingPortFile
					
			#check critcal port and add to the file if it's exist
			if [ -s $critPorts ]; then
				printToFile=0
				while IFS='' read -r _isport
				do
					while IFS='' read -r _critPrt
					do 
						_critPrt=`echo -n "${_critPrt//[[:space:]]/}"` #remove all whitespaces
						if [[ $_isport == $_critPrt ]]; then
							((printToFile++))
							echo "$_isport" >> $criticalFile
						fi 
					done < "$critPorts"
				done < "$ports"
				if [[ "$printToFile" -gt 0 ]]; then 
					echo "------------------------------------" >> $criticalFile
					echo "| $_ip | Critical Ports |" >> $criticalFile
					echo "------------------------------------" >> $criticalFile
					echo "***********###************" >> $criticalFile
				fi	
			fi 
		fi
		
	done < "$ips"
   
fi 