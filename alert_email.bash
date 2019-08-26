#!/usr/bin/env bash
curl localhost:9200/_cat/indices?v | grep elastiflow-3.3.0 > indices.txt
input="indices.txt"
existingIndice=0
sysTime=""
while IFS=' ' read -r f1 f2 f3 f4 f5 f6 f7 f8 f9 f10
do
    IFS='-' read -r sf1 sf2 sf3 <<< "$f3"
    sysTime=$(date +"%Y.%m.%d")
    if [[ "$sf3" == "$sysTime" ]]; then
        existingIndice+=1 #the indice is exist.
    fi
done < "$input"

#check log for error 403
isError=0
tail -n 20 /var/log/logstash/logstash-plain.log > logs.txt
logs="logs.txt"
while IFS='' read -r log
do 
    if [[ $log == *"retrying failed action with response code: 403"* ]]; then
        isError+=1 #existing error 403
        break
    fi 
done < "$logs"

if [ $existingIndice -lt 1 ] && [ $isError -gt 0 ]; then
    #sent alert if indice isn't created for today
    printf "**********Logstash**********\nelastiflow-3.3.0-$sysTime is not exist" | mail -s "Logstash Alert" "duynv@kdata.vn"
    tail -100 /var/log/logstash/logstash-plain.log | mail -s "Log of Logstash" "duynv@kdata.vn"
    #fixing error 403
    curl -XPUT -H "Content-Type: application/json" http://localhost:9200/_all/_settings -d '{"index.blocks.read_only_allow_delete": null}'
    systemctl restart logstash
fi