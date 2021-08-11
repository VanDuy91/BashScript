#!/usr/bin/env bash
#Scan all open ports of all cird which getting from a file
cirdFile="rangeIPs.txt"
critPorts="criticalPorts.txt" #e.g. 80/tcp; 53/udp
scanOpenPort="scanOpenPort.bash"

if [ -s $cirdFile ]; then
	while IFS='' read -r _cird
	do
		_cird=`echo -n "${_cird//[[:space:]]/}"` #remove all whitespaces
		
		#Save result to following files
		IFS="/" read -r ip prefix <<< "$_cird"
		filename=$ip-$prefix 
		criticalFile=$filename-criticalPorts.txt
		openingPortFile=$filename-openPort.txt
		
		#start scanning
		. $scanOpenPort $_cird $criticalFile $openingPortFile $critPorts
		
		#notification
		printf "Open ports and Critical ports. Detail in attached files" | mail -a $openingPortFile -a $criticalFile -s "Scan Open Port - $_cird" tech@kdata.vn
		
		#To don't append result of scanning, hence removing the result files. 
		rm -rf $openingPortFile $criticalFile
	done < "$cirdFile"
fi 