#!/usr/bin/env bash
curl localhost:9200/_cat/indices?v > indices.txt
input="indices.txt"

while IFS=' ' read -r f1 f2 f3 f4 f5 f6 f7 f8 f9 f10
do
    if [[ "$f1" == "red" ]]; then
        curl -XDELETE localhost:9200/$f3
        echo "[$(date)] indice $f3 was deleted" >> logcode.txt
    fi
done < "$input"