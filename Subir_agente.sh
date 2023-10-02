#!/bin/bash

function sendToTeams(){
    URI=https://intergrupoig.webhook.office.com/webhookb2/2a3d15a4-c7d1-4cc7-b17d-c5d7bc6d1557@7fbe498c-e540-4556-b198-7b2e16bff9b0/IncomingWebhook/d4178676d2584029aa5e5ba9f6a31ef9/99c32b9c-094b-4879-a564-2e75b3965454

        
    curl -X POST -H "Content-Type: application/json" \
-d '{
    "@type": "MessageCard",
    "@context": "http://schema.org/extensions",
    "themeColor": "009b01",
    "summary": "IaC Platform Notification",
    "sections": [{
        "activityTitle": "IaC Platform Notification [OK]",
        "activitySubtitle": "Oracle",
        "activityImage": "http://52.177.64.154:8088/exitoso.jpg",
        "facts": [{
            "name": "Servidor",
            "value": "'$(hostname)'"
        }, {
            "name": "Fecha",
            "value": "'$(date "+%D")'"
        }, {
            "name": "Estado",
            "value": " Se ha iniciado la Base de datos correctamente"
        }],
        "markdown": true
    }],
    
    
}' $URI
} 

function sendToTeams1(){
    URI=https://intergrupoig.webhook.office.com/webhookb2/2a3d15a4-c7d1-4cc7-b17d-c5d7bc6d1557@7fbe498c-e540-4556-b198-7b2e16bff9b0/IncomingWebhook/d4178676d2584029aa5e5ba9f6a31ef9/99c32b9c-094b-4879-a564-2e75b3965454

        
    curl -X POST -H "Content-Type: application/json" \
-d '{
    "@type": "MessageCard",
    "@context": "http://schema.org/extensions",
    "themeColor": "009b01",
    "summary": "IaC Platform Notification",
    "sections": [{
        "activityTitle": "IaC Platform Notification [ERROR]",
        "activitySubtitle": "Oracle",
        "activityImage": "http://52.177.64.154:8088/error.jpg",
        "facts": [{
            "name": "Servidor",
            "value": "'$(hostname)'"
        }, {
            "name": "Fecha",
            "value": "'$(date "+%D")'"
        }, {
            "name": "Estado",
            "value": "Ejecución fallida por favor revisar"
        }],
        "markdown": true
    }],
    
    
}' $URI
} 
                                   
check_exit_status() {
    if [ $? -eq 0 ]
    then
    	echo
    	echo "La ejecución se ha realizado correctamente"
        echo 
        echo
        sendToTeams
    else
    	echo
    	echo "[ERROR] Ejecución fallida por favor revisar"
        echo 
    	echo
        sendToTeams1
	fi
}

function subiragente  {
        sudo su - oragent /oracle/app/script/subir_agente.sh > /tmp/cap_montar_agente.log
		if [[ $? == 0  ]];
		then
			message="El agente ya subió"
			echo "$message"
			echo	
		else 
			message="El agente no se subio revise por favor"
			echo "$message"
			echo	
		fi
                
        check_exit_status
		tail -100f /tmp/cap_montar_agente.log
}

 
user=$1
host=$2
ssh $user@$host "$(typeset -f); subiragente"