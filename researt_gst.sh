#!/bin/bash
equipo=$(hostname)
user=$(user)
host=$(host)
if [[ "$equipo" == "$host" ]];
then   
    sudo systemctl restart gst
	
else
    function reinciargst () {
       sudo systemctl restart gst
	   message="El servicio gst ya se reincio"
	   echo "$message"
	   echo
    }
    ssh $user@$host "$(typeset -f); reinciargst"

fi