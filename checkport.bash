#!/usr/bin/env bash
port=$1
netstat -ntl | grep $port | awk '{print $4}' > openingPort.txt 
ports="openingPort.txt"
if [ -s $ports ]; then 

    while IFS='' read -r _isport 
    do
        if [[ $_isport == *":$port" ]]; then 
            echo "port $port is opening"
            break
        else
            echo "port $port is not opening"
            break
        fi
        
    done < "$ports"
else 
    echo port $port is not binded to any service
fi 