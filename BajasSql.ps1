$getDate = Get-Date
function WriteTeams {
    Param
    (
        [Parameter(Mandatory=$true)]
        [String] $IaCMsg = "IaC Message"
    ) 
    #$IaCMsg = $null
    $JSONBody = [PSCustomObject][Ordered]@{
        "@type"      = "MessageCard"
        "@context"   = "http://schema.org/extensions"
        "summary"    = "Incoming Alert Test Message!"
        "themeColor" = "0078D7"
        "title"      = "IaC Platform Message!"
        "text"       = "IaC Recipe Bajar Servicios SQL se ejecuto el " + " " + "$getDate " + "con mensaje : " +$IaCMsg
    }

    $TeamMessageBody = ConvertTo-Json $JSONBody -Depth 100

    $parameters = @{
        "URI"         = "https://softwareone.webhook.office.com/webhookb2/5f2f2bc7-8fdb-4d9b-b005-43c5b81c10e7@1dc9b339-fadb-432e-86df-423c38a0fcb8/IncomingWebhook/42f9c64d62f74382b6086928cf06b70f/896a6a7b-aa52-4167-af36-a2770d23b53e"
        "Method"      = "POST"
        "Body"        = $TeamMessageBody
        "ContentType" = "application/json"
    }
    Invoke-RestMethod @parameters
}


$dateUpload        =  Get-Date -format dd_MM_yyyy_HH_mm
Start-Transcript -Path "C:\IaC\BajarSql\Logs\BajarServiciosSql-IaC-$dateUpload.txt"
[String]$string = [System.Environment]::GetEnvironmentVariable("maquinas","Machine")
$string = $string -replace "\s",""
$Server = $string.split(",")
$var = $Server
for ($i=0;$i -lt $Server.Count; $i++){
        $serv = $Server[$i]
        Write-Host " <<< [INFO] En el server $serv >>>"
        Invoke-Command -ComputerName $Server[$i] -ScriptBlock {
            $ServiceSQL = Get-Service -Name "*SQL*"  -ErrorAction SilentlyContinue
            foreach($Services in $ServiceSQL){  
                if ($Services.status -eq "Running"){
                    Write-Host " <<< [INFO] vamos a bajar el servicio: $($Services.Name) de SQL Server in DB Server ... >>>" -ForegroundColor Green
                      Stop-Service $Services -Force
                } # IF
                else{
                    echo " <<< [INFO] No vamos a bajar el servicio $($Services.Name) in DB Server... >>>"
                    }
            }
        Write-Host " " #salto de linea
        }
        $serv = $Server[$i]
        $var[$i] = "Proceso exitoso en el server $serv ///"

    } else {
        $serv = $Server[$i]
        [String]$var[$i] = "Error no se encuentra el server $serv /// "
    } 
Write-Host "Final"


 $texto = $var | out-string


$IaCMsg = $texto + "Para mas info vea el ultimo archivo de la ruta C:\IaC\Logs en el server pivote"

WriteTeams $IaCMsg
Stop-Transcript

