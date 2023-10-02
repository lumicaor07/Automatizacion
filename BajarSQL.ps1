$dateUpload        =  Get-Date -format dd_MM_yyyy_HH_mm
Start-Transcript -Path "C:\IaC\BajarSql\Logs\BajarServiciosSql-IaC-$dateUpload.txt"
$archivo1 = Get-Item -Path "C:\IaC\BajarSql\Logs\BajarServiciosSql-IaC-$dateUpload.txt"
[String]$string = [System.Environment]::GetEnvironmentVariable("maquinas","Machine")
$string = $string -replace "\s",""
$Server = $string.split(",")
$var = $Server
for ($i=0;$i -lt $Server.Count; $i++){
        ping $Server[$i] > C:\IaC\BajarSql\ping.txt
        [String]$domincol = "hilanet.local"
        if(Select-string -Path "C:\IaC\BajarSql\ping.txt" -Pattern "$domincol" -Quiet){
        $serv = $Server[$i]
        Write-Host " <<< [INFO] En el server $serv >>>"
        Invoke-Command -ComputerName $Server[$i] -ScriptBlock {
            $ServiceSQL = Get-Service -Name *SQL*  -ErrorAction SilentlyContinue
            foreach($Services in $ServiceSQL){  
                if ($Services.status -eq "Running"){
                    Write-Host " <<< [INFO] vamos a bajar el servicio: $($Services.Name) de SQL Server in DB Server ... >>>" -ForegroundColor Green
                   Stop-Service $Services -Force
                } # IF
                else{
                    echo " <<< [INFO] No vamos a bajar el servicio $($Services.Name) in DB Server... >>>"
                    }
            }

        shutdown /r /f /t 60
        
        Write-Host " " #salto de linea
        }
        $serv = $Server[$i]
        $var[$i] = "Proceso exitoso en el server $serv ///"

    } else {
        $serv = $Server[$i]
        [String]$var[$i] = "Error no se encuentra el server $serv /// "
    }   
    Remove-Item C:\IaC\BajarSql\ping.txt
}



Write-Host "Final"

[Environment]::SetEnvironmentVariable("maquinas", "", "Machine")

$texto = $var | out-string

############################################################


Stop-Transcript
####################################################################

