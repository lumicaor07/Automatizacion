#Para inicio de sesión
$User = "iacadmin@gco.com.co"
$Pwd = [Environment]::GetEnvironmentVariable("Pwd", "Machine")
$PassWord = ConvertTo-SecureString -String $Pwd -AsPlainText -Force
$UserCredential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $User, $PassWord
#Inicio de sesión en Exchange Online
Connect-ExchangeOnline -Credential $UserCredential
#Inicio de sesión en security and compliance
Connect-IPPSSession -Credential $UserCredential

$To = [Environment]::GetEnvironmentVariable("remitente", "Machine")
$CaseNumber = [Environment]::GetEnvironmentVariable("Caso", "Machine")
$Email = [Environment]::GetEnvironmentVariable("Correo", "Machine")
$SearchName = $CaseNumber + "_" + $Email
Write-Output $SearchName

Start-Transcript -Path "C:\Backups_correos\Logs\Log_$SearchName.txt"

$Active = Get-Mailbox $Email
Write-Output $Active

if ($Active -ne $null){
    Write-Output "Mailbox is active"
    New-ComplianceSearch $SearchName -ExchangeLocation $Email -AllowNotFoundExchangeLocationsEnabled $true
    Start-ComplianceSearch -Identity $SearchName
    do
        {
            Start-Sleep -s 5
            Write-Output "The ComplianceSearch is starting... Wait"
            $ComplianceSearch = Get-ComplianceSearch $SearchName
        }
    while ($ComplianceSearch.Status -ne 'Completed')
    New-ComplianceSearchAction -SearchName $SearchName -Export -ExchangeArchiveFormat PerUserPst -Format FxStream -EnableDedupe:$true -Confirm:$false
    $ExportName = $SearchName + "_Export"
    do
        {
            Start-Sleep -s 30
            Write-Output "The Export is starting... Wait"
            $Complete = Get-ComplianceSearchAction -Identity $ExportName
        }
    while ($Complete.Status -ne 'Completed')
    #$Result = $ExportName + " generado con exito"
    $Result = "Fase 1 Exitosa"
    $Message = "Cordial saludo,

El export $ExportName se ha realizado con exito, puede proseguir a realizar la descarga del mismo. 

Cordialmente,
Admin.
"
}
else{
    Write-Output "No mailbox found"
    $Result = "Error con " + $Email
    $Message = "Cordial saludo,

Se ha producido un error al generar el export, por favor valide que los campos fueron ingresados correctamente.

Cordialmente,
Admin.
"
}

#Para cerrar sesión
Disconnect-ExchangeOnline -Confirm:$false


New-Item "\\TERMINALQA\Backups_Correos\$SearchName" -itemType Directory

Stop-Transcript

#$From = "iacadmin@gco.com.co"
#$To = [Environment]::GetEnvironmentVariable("remitente", "Machine")
#$Attachment = “C:\Backups_correos\Logs\Log_$SearchName.txt”
#[SecureString]$Securepassword = $Pwd | ConvertTo-SecureString -AsPlainText -Force 
#$Credential = New-Object System.Management.Automation.PSCredential -ArgumentList $From, $Securepassword
#Send-MailMessage -SmtpServer smtp.office365.com -Port 587 -UseSsl -From $From -To $To -Subject $Result -Body $Message -Attachments $Attachment -Credential $Credential
#Send-MailMessage -SmtpServer smtp.office365.com -Port 587 -UseSsl -From $From -To $To -Subject "Fase 1 Exitosa" -Body "Ejecución exitosa de la fase 1"  -Credential $Credential
#Write-Output "Email enviado con exito"
$LoginParameters = @{
    Uri             = 'https://prod-61.westus.logic.azure.com:443/workflows/c50114693dcc48178f097a1b3857a4c5/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=fjAKnDdGk7tVE59I9luzwPQXV7X3qjYmxWlgGRekIRE'
    Method          = 'POST'
    Body            = @{
        remitente = $To
    } | ConvertTo-Json -Compress
}
$LoginResponse = Invoke-WebRequest @LoginParameters
Write-Output "Metodo post ejecutado exitosamente"

[Environment]::SetEnvironmentVariable("Pwd", "", "Machine")
[Environment]::SetEnvironmentVariable("remitente", "", "Machine")