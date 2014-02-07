#!/bin/bash
# Review the countries accessing to our external FW in real time and highligh those suspicious
# 28/Oct/2013

logPath=/path/to/junos/log/file.log
previousIP="0.0.0.0"
consecutivas=1
pais="none"
#Tail the log file
tail -f $logPath | while read line; do
        #Obtain the source IP and discard the internal addresses and the bad parsed lines
        ip=$(echo "$line" | grep RT_FLOW_SESSION_DENY | awk '{ print $10 }' | cut -d "/" -f1 | grep -v ^10\. | grep -v TCP)
        destino=$(echo "$line" | cut -d ">" -f2 | awk '{ print $1 }' | sed 's/\//:/g')
        pais=$(geoiplookup "$ip" | cut -d "," -f2 | sed -e 's/^[ \t]*//')
        #Sometimes we'll get empty lines, check if the length looks like an IP
        if [ "$(echo -n "$ip" | wc -c )" -ge "7" ]
        then
                if [ "$ip" = "$previousIP" ]
                then
                        consecutivas=$(( consecutivas + 1 ))
                        if [ $consecutivas -gt "3" ]
                        then
                                echo "[$(date +%R)] >>> $consecutivas CONEXIONES CONSECUTIVAS RECHAZADAS DESDE $ip ($pais) [DST $destino] <<<"
                        else
                                echo "[$(date +%R)] $consecutivas conexiones consecutivas rechazadas desde $ip ($pais) [DST $destino]"
                        fi
                else
                        consecutivas=1
                        echo "[$(date +%R)] Conexion rechazada desde $ip ($pais) [DST $destino]"
                fi
                previousIP=$ip
        fi
done
