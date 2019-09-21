#!/usr/bin/env bash
curl localhost:9200/_cat/indices?v | grep elastiflow-3.3.0 > indices.txt
input="indices.txt"
existingIndice=0
sysTime=""
indiceRedStatus=""
while IFS=' ' read -r f1 f2 f3 f4 f5 f6 f7 f8 f9 f10
do
    IFS='-' read -r sf1 sf2 sf3 <<< "$f3"
    sysTime=$(date +"%Y.%m.%d")
    if [[ "$sf3" == "$sysTime" ]]; then
        existingIndice+=1 #the indice is exist.
    fi
    if [[ "$f1" == "red" ]]; then
        indiceRedStatus=$f3
        echo "[$(date)] red indice: $indiceRedStatus" >> logcode.txt
    fi
    
done < "$input"

#check log for error 403 and 503
isError403=0
isError503=0
isError500=0 #Encountered a retryable error. Will Retry with exponential backoff
tail -n 20 /var/log/logstash/logstash-plain.log > logs.txt
logs="logs.txt"
while IFS='' read -r log
do 
    if [[ $log == *"retrying failed action with response code: 403"* ]]; then
        isError403+=1 #existing error 403
        break
    fi
    if [[ $log == *"retrying failed action with response code: 503"* ]]; then
        isError503+=1 #error 503 is existing
        break 
    fi
    if [[ $log == *"Encountered a retryable error. Will Retry with exponential backoff"* ]]; then
        isError500+=1
    fi
done < "$logs"


if [[ $isError403 -gt 0 ]]; then 
	tail -100 /var/log/logstash/logstash-plain.log | mail -s "Log of Logstash" "duynv@kdata.vn"
	if [[ $existingIndice -gt 0 ]]; then
		/usr/bin/curator --config /root/.curator/curator.yml /root/.curator/action-2-day.yml
		#curl -XDELETE localhost:9200/elastiflow-3.3.0-$sysTime
		curl -XPUT -H "Content-Type: application/json" http://localhost:9200/_all/_settings -d '{"index.blocks.read_only_allow_delete": null}'
	else 
		#fixing error 403
		curl -XPUT -H "Content-Type: application/json" http://localhost:9200/_all/_settings -d '{"index.blocks.read_only_allow_delete": null}'
	fi
	systemctl restart logstash
    echo "[$(date)] logstash restarted" >> logcode.txt
	printf "Error 403 was fixed." | mail -s "Logstash Error" "duynv@kdata.vn"
else
    if [[ $existingIndice -lt 1 ]]; then
        #sent alert if indice isn't created for today
        printf "**********Logstash**********\nelastiflow-3.3.0-$sysTime is not exist" | mail -s "Logstash Alert" "duynv@kdata.vn"  
    fi
fi

if [[ $isError503 -gt 0 ]]; then
    tail -100 /var/log/logstash/logstash-plain.log | mail -s "Log of Logstash" "duynv@kdata.vn"
    if [[ "$indiceRedStatus" != "" ]]; then
        /usr/bin/curator --config /root/.curator/curator.yml /root/.curator/action-2-day.yml 
        curl -XDELETE localhost:9200/$indiceRedStatus
    fi
    . deletingRedIndices.bash
    echo "[$(date)] deleted all red indices and restarting logstash" >> logcode.txt
    systemctl restart logstash
    echo "[$(date)] logstash restarted" >> logcode.txt
	printf "Error 503 was fixed." | mail -s "Logstash Error 503 Just Was Fixed" "duynv@kdata.vn"
fi

if [[ $isError500 -gt 0 ]]; then
    curl -XDELETE localhost:9200/.monitoring-logstash-6-$(date +"%Y.%m.%d")
    curl -XDELETE localhost:9200/.monitoring-es-6-$(date +"%Y.%m.%d")
    curl -XDELETE localhost:9200/.monitoring-kibana-6-$(date +"%Y.%m.%d")
fi