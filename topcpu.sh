#!/bin/bash
equipo=$(hostname)
user=$1
host=$2
if [[ "$equipo" == "$host" ]];
then  
    sleep 30s 
    echo -e "\nTop 5 CPU Resource  Processes"
    echo -e "$D$D"
    ps -eo pcpu,pmem,pid,ppid,user,stat,args | sort -k 1 -r | head -6|sed 's/$/\n/'
	   
else
    function cpu () {
        echo -e "\nTop 5 CPU Resource  Processes"
        echo -e "$D$D"
        ps -eo pcpu,pmem,pid,ppid,user,stat,args | sort -k 1 -r | head -6|sed 's/$/\n/'
    }
    ssh $user@$host "$(typeset -f); cpu"

fi