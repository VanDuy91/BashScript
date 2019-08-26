#!/usr/bin/env bash
curl localhost:9200/_cat/indices?v | grep elastiflow-3.3.0 > indices.txt
input="indices.txt"
isRunning=0
sysTime=""
while IFS=' ' read -r f1 f2 f3 f4 f5 f6 f7 f8 f9 f10
do
    IFS='-' read -r sf1 sf2 sf3 <<< "$f3"
    sysTime=$(date +"%Y.%m.%d")
    if [[ "$sf3" == "$sysTime" ]]; then
        isRunning+=1
    fi
done < "$input"

#sent alert if indice isn't created for today
if [[ $isRunning -lt 1 ]]; then
    printf "**********Logstash**********\nelastiflow-3.3.0-$sysTime is not exist" | mail -s "Logstash Alert" "duynv@kdata.vn"
    tail -100 /var/log/logstash/logstash-plain.log | mail -s "Log of Logstash" "duynv@kdata.vn"
fi

#fixing error: retrying failed action with response code: 403 
isListenning=0
netstat -plntu | grep java > processes.txt
runningProccesses="processes.txt"
while IFS=' ' read -r f1 f2 f3 f4 f5 f6 f7
do
    IFS=':' read -r sf1 sf2 <<< "$f4"
    #if the indice does not exist and logstash is running
    if [[ "$sf2" == "2055" ] && [ $isRunning -lt 1 ]]; then 
        isListenning+=1
    fi
done < "$runningProccesses"
if [[ $isListenning -gt 0 ]]; then
    curl -XPUT -H "Content-Type: application/json" http://localhost:9200/_all/_settings -d '{"index.blocks.read_only_allow_delete": null}'
    systemctl restart logstash
fi