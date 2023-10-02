<#####################################################################################################################################################################
    Descripcion      : Check List para ejecutar el diagnostico de aplicaciones y ejecuta remediaciones de AppPool y Services.
    Ambiente         : Demo
    Nombre Script PS : DiagWebIIS_Remedia_AP_Services
    Version          : [1] Implementacion del Script
                     : [1.1] Adecuacion de parametros de Sharepoint
#####################################################################################################################################################################>

$dateUpload        =  Get-Date -format dd_MM_yyyy_HH_mm
$Path              =  "C:\IAC\CheckList_Plataforma"
$Path_html         =  "C:\IAC\CheckList_Plataforma\Resultados_CheckList"
$freeSpaceFileName =  "$Path_html\CheckList_Integration_IIS_$dateupload.html" 
$urllist           =  "$Path\Urls_Services.txt"
[String]$string = [System.Environment]::GetEnvironmentVariable("maquinas","Machine")
$string = $string -replace "\s",""
$serverlist = $string.split(",")

$warning  = 20
$critical = 10
$getDate  = (Get-Date).ToString()

New-Item -ItemType file $freeSpaceFileName -Force 

# *********************************************************************************************************************************************
# *********************************************************************************************************************************************

############################################################
############ Function To Send Msg To Teams   #############
############################################################
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
        "themeColor" = '0078D7'
        "title"      = "IaC Platform Message!"
        "text"       = "IaC Recipe Executed check list Succesfully on:" + " " + "$getDate " +$IaCMsg
    }
    
    $TeamMessageBody = ConvertTo-Json $JSONBody -Depth 100
    
    $parameters = @{
        "URI"         = 'https://softwareone.webhook.office.com/webhookb2/5f2f2bc7-8fdb-4d9b-b005-43c5b81c10e7@1dc9b339-fadb-432e-86df-423c38a0fcb8/IncomingWebhook/42f9c64d62f74382b6086928cf06b70f/896a6a7b-aa52-4167-af36-a2770d23b53e'
        "Method"      = 'POST'
        "Body"        = $TeamMessageBody
        "ContentType" = 'application/json'
    }
    Invoke-RestMethod @parameters
}


############################################################
############ 1. Function To Connect Graph  #############
############################################################
	Function Connect-MSGraph
	{
	    #Microsoft Graph Parameters
	    $IaCresponse = $null
	    $IaCToken = $null
	    $IaCSecret = $null
	    $tokenUri = $null
	    
	    #Generate Microsoft Graph Token
	    $IaCClientID = '6bbcb757-510f-46f8-ad56-85b2bf777350' #You can also try "1950a258-227b-4e31-a9cf-717495945fc2" # Well known client ID for PowerShell
	    $IaCTenant = '7fbe498c-e540-4556-b198-7b2e16bff9b0' #Guid-for-your-tennant if the Client ID is set up as below
	    $IaCSecret = 'JYZ7y65VyQQq0NI.t-Da.3-~5bsjq471p3'
	    $tokenUri = 'https://login.microsoft.com/'+$IaCTenant+'/oauth2/v2.0/token'
	
	    if ($IaCTenant) { #if we don't have the tennant we need to display the web UI. If do, we can just prompt for creds
	    #   Write-Output "Getting Token Using IaC App Registration ..."
	        $IaCresponse = Invoke-RestMethod -Method Post -Uri $tokenUri -Body @{
        'grant_type' = 'client_credentials';
	         'client_id' = $IaCClientID;
         'client_secret' = $IaCSecret;
	         'scope' = 'https://graph.microsoft.com/.default'
	        }
	    }
	
	     $IaCToken = $IaCresponse.access_token
	     if (-not $IaCToken) {
	        Write-Output 'Could not get IaC token'
	     }
	
	     else  {
	        #Write-Output 'Token for IaC Platform generated successfully'
	        return ($IaCToken)
	        }
	}


############################################################
############ 2. Function To Upload Graph  #############
############################################################
Function IaCUploadItem
	{
	    Param (
	         [Parameter(Mandatory=$true)]
	         [String] $IaCPath = "$env:TEMP\HTMLTEST.html"
	        )
	
	     $result = $null
	     $OneDriveToken = Connect-MSGraph
         $Path = $IaCPath
	     $AccessToken = $OneDriveToken
	     $uploadItem = Get-Item -Path $Path
        # $uri = 'https://graph.microsoft.com/v1.0/sites/97f4abe2-7112-478d-9189-256ba9d542e8/drive/root:/IaC/Colmedica/WebCollaboration/'+$uploadItem.Name+':/content'
	
	    if (-not $uploadItem) {Write-Warning -Message "Could not find $Path" ; return }
	    if ($uploadItem.Count -gt 1 ) {Write-Warning -Message "$Path returns multiple items." ; return }

        #Byte range and Settings are only needed for "resumable upload"
	
	    $rangeText = "bytes 0-" + ($uploadItem.length -1) + "/" + $uploadItem.Length
	    $settings = @{
	        'item' = [ordered]@{
	        '@microsoft.graph.conflictBehavior'= $ConflictBehavior
            'name' = $uploadItem.Name
	        'fileSystemInfo' = [ordered]@{
	        'lastModifiedDateTime' = $uploadItem.LastWriteTimeUtc.ToString("yyyy-MM-ddTHH:mm:ss'Z'") #'o' might work for ISO format here
	        }
	     }
    }
	
	    #Content type is only needed for "quick upload"
	    if (-not $ContentType) {
        $reg = Get-ItemProperty -Path "HKLM:\SOFTWARE\Classes\$($uploadItem.extension)"
	        if ($reg.'Content Type') {
	            $ContentType= $reg.'Content Type'
	            Write-Verbose -Message "Selected content type of $contentType for a $($UploadItem.Extension) file."
	        }
        else {$ContentType = "application/octet-stream"}
	    }
	
	    #If we don't want to overwrite small files, the easiest way is to a resumable update which will check if the file exists
	     #$resultod = Invoke-RestMethod -Method Put -Headers $GraphHeader -Uri $uri
	
	    $resultod = Invoke-RestMethod -Method Put -headers @{Authorization = "Bearer $OneDriveToken"} -Uri $uri -InFile $uploadItem.FullName -ContentType $ContentType
	    $evidence = $resultod.webUrl
	    $link = "<a href='$evidence'>$evidence</a>"
	    $JSONBody = [PSCustomObject][Ordered]@{
	        "@type" = "MessageCard"
	        "@context" = "http://schema.org/extensions"
        "summary" = "Incoming Alert Test Message!"
        "themeColor" = '0078D7'
	        "title" = "IaC Platform Message!"
	        "text" = 'This is the evidence for the executed recipe: '+$link
	     }
	    $TeamMessageBody = ConvertTo-Json $JSONBody -Depth 100
	    $parameters = @{
	        #"URI" = 'https://outlook.office.com/webhook/69c0e4d0-d5ec-448e-8e3d-7302656b0f92@7fbe498c-e540-4556-b198-7b2e16bff9b0/IncomingWebhook/1985aa4e0251479b8c8734c36c4f21de/b67e5b12-9fcc-4536-8717-4129fcb9b2c5'
            "URI" =  'https://softwareone.webhook.office.com/webhookb2/5f2f2bc7-8fdb-4d9b-b005-43c5b81c10e7@1dc9b339-fadb-432e-86df-423c38a0fcb8/IncomingWebhook/42f9c64d62f74382b6086928cf06b70f/896a6a7b-aa52-4167-af36-a2770d23b53e'
	        "Method" = 'POST'
	        "Body" = $TeamMessageBody
	        "ContentType" = 'application/json'
	    }
	
	     Invoke-RestMethod @parameters
	
	 }



############################################################
############3 Function To Send Mail  #############
############################################################
Function IacEmail{
$From = 'ColmedicaPruebas@outlook.com'
$Password = "Colmedica_Pruebas"
$To = "juan.roman@softwareone.com"
$Archivo = $freeSpaceFileName
#$Mensaje.Attachments.Add($Archivo)
$Adjunto = New-Object Net.Mail.Attachment($Archivo)
$Result = "[COLMEDICA] - CheckList Servicios Web"
$Message = "
Cordial saludo,

se hace envió de resultado del CheckList plataforma Web
"
[SecureString]$Securepassword = $Password | ConvertTo-SecureString -AsPlainText -Force 
$Credential = New-Object System.Management.Automation.PSCredential -ArgumentList $From, $Securepassword
Send-MailMessage -SmtpServer smtp.office365.com -Port 587 -UseSsl -From $From -To $To -Subject $Result -Body $Message -Attachments $Archivo -Credential $Credential
Write-Output "Email enviado con exito"
 }

# *********************************************************************************************************************************************
# *********************************************************************************************************************************************

Function writeHtmlHeader 
{ 
    param($fileName) 
    $date = ( get-date ).ToString('yyyy/MM/dd') 
    Add-Content $fileName "<html>" 
   # Add-Content $fileName "<br>"
    Add-Content $fileName "<img src='https://i.postimg.cc/jSZFB09N/LogoHead.jpg'>"
    Add-Content $fileName "<head>" 
    Add-Content $fileName "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>" 
    Add-Content $fileName '<title>Reporte estado plataforma - IIS </title>' 
    add-content $fileName '<STYLE TYPE="text/css">' 
    add-content $fileName  "<!--" 
    add-content $fileName  "td {" 
    add-content $fileName  "font-family: Tahoma;" 
    add-content $fileName  "font-size: 11px;" 
    add-content $fileName  "border-top: 1px solid #999999;" 
    add-content $fileName  "border-right: 1px solid #999999;" 
    add-content $fileName  "border-bottom: 1px solid #999999;" 
    add-content $fileName  "border-left: 1px solid #999999;" 
    add-content $fileName  "padding-top: 0px;" 
    add-content $fileName  "padding-right: 0px;" 
    add-content $fileName  "padding-bottom: 0px;" 
    add-content $fileName  "padding-left: 0px;" 
    add-content $fileName  "}" 
    add-content $fileName  "body {" 
    add-content $fileName  "margin-left: 5px;" 
    add-content $fileName  "margin-top: 5px;" 
    add-content $fileName  "margin-right: 0px;" 
    add-content $fileName  "margin-bottom: 10px;" 
    add-content $fileName  "" 
    add-content $fileName  "table {" 
    add-content $fileName  "border-radius: 25px;" 
    #add-content $fileName  "border: thin solid #000000;" 
    add-content $fileName  "}" 
    add-content $fileName  "-->" 
    add-content $fileName  "</style>" 
    Add-Content $fileName "</head>" 
    Add-Content $fileName "<body>" 
 
    add-content $fileName  "<table width='100%'>" 
    #add-content $fileName  "<tr bgcolor='#2a4373'>" 
    add-content $fileName  "<tr bgcolor='#1D3557'>" 
    add-content $fileName  "<td colspan='6' height='25' align='center'>" 
    add-content $fileName  "<font face='tahoma' color='#DFFE00' size='6'><strong>Estado componentes Servicios - $getDate </strong></font>" 
    add-content $fileName  "</td>" 
    add-content $fileName  "</tr>" 
    add-content $fileName  "</table>" 
 
}

#HTML para el estado de las conexiones concurrentes
Function writeTableHeaderconexiones
{ 
    param($fileName) 
 
    Add-Content $fileName "<tr bgcolor=#457B9D>" 
    Add-Content $fileName "<td width='33%' align='center'><font face='tahoma' color='#FFFFFF'><strong>Servidor</strong></td>"
    Add-Content $fileName "<td width='33%' align='center'><font face='tahoma' color='#FFFFFF'><strong>Sitio web</strong></td>" 
    Add-Content $fileName "<td width='33%' align='center'><font face='tahoma' color='#FFFFFF'><strong>Conexiones concurrentes</strong></td>"
    Add-Content $fileName "</tr>" 
}

#HTML para el estado de los servicios Web
Function writeTableHeaderWebApps
{ 
    param($fileName) 
    Add-Content $fileName "<tr bgcolor=#457B9D>" 
    Add-Content $fileName "<td width='12%' align='center'><font face='tahoma' color='#FFFFFF'><strong>Origen</strong></td>" 
    Add-Content $fileName "<td width='10%' align='center'><font face='tahoma' color='#FFFFFF'><strong>Name Applications</strong></td>" 
    Add-Content $fileName "<td width='10%' align='center'><font face='tahoma' color='#FFFFFF'><strong>Name App Pool</strong></td>" 
    Add-Content $fileName "<td width='55%' align='center'><font face='tahoma' color='#FFFFFF'><strong>URL</strong></td>" 
    Add-Content $fileName "<td width='5%'  align='center'><font face='tahoma' color='#FFFFFF'><strong>Loading Time (Seg)</strong></td>" 
    Add-Content $fileName "<td width='15%' align='center'><font face='tahoma' color='#FFFFFF'><strong>Status</strong></td>"
    Add-Content $fileName "</tr>"  
} 

# HTML para el estado de los discos
Function writeTableHeader 
{ 
    param($fileName) 
    Add-Content $fileName "<tr bgcolor=#457B9D>" 
    Add-Content $fileName "<td width='17%' align='center'><font face='tahoma' color='#FFFFFF'>Disco</td>" 
    Add-Content $fileName "<td width='17%' align='center'><font face='tahoma' color='#FFFFFF'>Nombre Disco</td>" 
    Add-Content $fileName "<td width='17%' align='center'><font face='tahoma' color='#FFFFFF'>Capacidad Total(GB)</td>" 
    Add-Content $fileName "<td width='17%' align='center'><font face='tahoma' color='#FFFFFF'>Capacidad Utilizada(GB)</td>" 
    Add-Content $fileName "<td width='17%' align='center'><font face='tahoma' color='#FFFFFF'>Espacio libre(GB)</td>" 
    Add-Content $fileName "<td width='17%' align='center'><font face='tahoma' color='#FFFFFF'>% Espacio libre</td>"
    Add-Content $fileName "</tr>" 
}

#HTML para el estado de de Rendimiento servidores de Aplicaciones
Function writeTableHeaderRendimientoBTS
{ 
    param($fileName) 
    Add-Content $fileName "<tr bgcolor=#457B9D>" 
    Add-Content $fileName "<td width='33%' align='center'><font face='tahoma' color='#FFFFFF'>I/O Discos</td>"
    Add-Content $fileName "<td width='33%' align='center'><font face='tahoma' color='#FFFFFF'>% Uso Memoria RAM</td>" 
    Add-Content $fileName "<td width='33%' align='center'><font face='tahoma' color='#FFFFFF'>% Uso Procesador</td>" 
    Add-Content $fileName "</tr>" 
} 

#HTML para el estado de los servicios Windows
Function writeTableHeaderServicios
{ 
    param($fileName) 
    Add-Content $fileName "<tr bgcolor=#457B9D>" 
    Add-Content $fileName "<td width='50%' align='center'><font face='tahoma' color='#FFFFFF'>Servicio</td>" 
    Add-Content $fileName "<td width='50%' align='center'><font face='tahoma' color='#FFFFFF'>Estado</td>" 
    Add-Content $fileName "</tr>" 
}

#HTML para el estado de los Certificados
Function writeTableHeadercertificados
{
	param($fileName) 


	Add-Content $fileName "<tr bgcolor=#457B9D>" 
	Add-Content $fileName "<td width='17%' align='center'><font face='tahoma' color='#FFFFFF'>Servidor</td>" 
	Add-Content $fileName "<td width='17%' align='center'><font face='tahoma' color='#FFFFFF'>Fecha expedición</td>" 
	Add-Content $fileName "<td width='17%' align='center'><font face='tahoma' color='#FFFFFF'>Fecha de expiración</td>"
	Add-Content $fileName "<td width='17%' align='center'><font face='tahoma' color='#FFFFFF'>Días restantes</td>"
	Add-Content $fileName "<td width='17%' align='center'><font face='tahoma' color='#FFFFFF'>Subject</td>"
	Add-Content $fileName "<td width='17%' align='center'><font face='tahoma' color='#FFFFFF'>Thumbprint</td>"
	Add-Content $fileName "</tr>" 
}

#HTML para el estado de Rendimiento de los servidores de Base de Datos
Function writeTableHeaderRendimiento
{ 
    param($fileName) 
 
    Add-Content $fileName "<tr bgcolor=#457B9D>" 
    Add-Content $fileName "<td width='16%' align='center'><font face='tahoma' color='#FFFFFF'>% Uso Memoria RAM</td>" 
    Add-Content $fileName "<td width='16%' align='center'><font face='tahoma' color='#FFFFFF'>% Uso Procesador</td>"
    Add-Content $fileName "<td width='16%' align='center'><font face='tahoma' color='#FFFFFF'>% Uso Log TempDB</td>"
    Add-Content $fileName "<td width='16%' align='center'><font face='tahoma' color='#FFFFFF'>% Aciertos cache buffer</td>"
    Add-Content $fileName "<td width='16%' align='center'><font face='tahoma' color='#FFFFFF'>DeadLocks (seg)</td>"
    Add-Content $fileName "<td width='16%' align='center'><font face='tahoma' color='#FFFFFF'>Promedio bloqueos en espera (ms)</td>"
    Add-Content $fileName "</tr>" 
}

Function writeHtmlFooter 
{ 
    param($fileName) 
 
    Add-Content $fileName "</body>" 
    Add-Content $fileName "</html>" 
} 

#==============================================================================================================================================
#==============================================================================================================================================


#======================INICIO LOG ================================#
Start-Transcript -Path "C:\IAC\CheckList_Plataforma\Logs\Checklist_IIS_IaC-$dateUpload.txt"

#******** PINTAR ESTADO SITIOS Y SERVICIOS WEB ************************
  
Function Validarwebapps
{ 
    param ($filename, $Source,$NameA, $NameP, $Url, $LoadTime, $messageState) 

    Write-Host "$messageState" -f Blue

    $LoadTime = [math]::Round(($LoadTime/1000),2)

   

    if ($messageState -NotLike "*ERROR*") 
     { 
        if($LoadTime -gt 10)
        {
            Add-Content $fileName "<tr>" 
            Add-Content $fileName "<td align='Center'>$Source</td>"
            Add-Content $fileName "<td align='Center'>$NameA</td>" 
            Add-Content $fileName "<td align='Center'>$NameP</td>"
            Add-Content $fileName "<td align='Center'>$url</td>"
            Add-Content $fileName "<td bgcolor='#DFFE00' align='center'>$LoadTime</td>"
            Add-Content $fileName "<td align='center'>$messageState</td>"
            Add-Content $fileName "</tr>"

            #### Begin IaC Remediation TEAMS ####
            $Action       = 'Recycle' 
            $AppPoolNames = $NameP
            $MachineName  = $Source
            $LoadT        = $LoadTime

            #///////////////// Remediacion Automatica //////////////////////////////
            #$Recycle = Invoke-Command -ComputerName $server -ScriptBlock {C:\Windows\System32\inetsrv\appcmd.exe stop apppool "$AppPoolNames"}
            #/////////////////////////////////////////////// 
           # Write-Host $Recycle 

            #==========================================
            #Build Poll TEAMS
            #==========================================
            
            # $TeamsURI = 'https://prod-24.eastus2.logic.azure.com/workflows/b3e73d5af9e7435b9492e76c8479dad4/triggers/manual/paths/invoke/Teams/'+$Action+'/'+$AppPoolNames+'/'+$MachineName+'/'+$result1+'/'+$LoadT+'?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=4LaZaUt8Mu8xBFPG6cFwTUhrKdXyaEs8-LeDjqikjgQ'
            $TeamsURI   = 'https://prod-59.eastus2.logic.azure.com/workflows/f78d5a5f1817499aab16dda632f5c9fc/triggers/manual/paths/invoke/Teams/'+$Action+'/'+$AppPoolNames+'/'+$MachineName+'/'+$result1+'/'+$LoadT+'?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=09fTQYJUBdFgfC1THqE_raUzjaoWGhoQlXk9V5NwfAA'
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $TeamsURI -Verbose
            Write-Output "Application Pool - $AppPoolNames recycle successfully!"
            #### Closed IaC Remediation TEAMS ####
        }
        else
        {
            Add-Content $fileName "<tr>"
            Add-Content $fileName "<td align='center'>$Source</td>" 
            Add-Content $fileName "<td align='center'>$NameA</td>" 
            Add-Content $fileName "<td align='center'>$NameP</td>"
            Add-Content $fileName "<td align='center'>$url</td>"
            Add-Content $fileName "<td align='center'>$LoadTime</td>"
            Add-Content $fileName "<td align='center'>$messageState</td>"
            Add-Content $fileName "</tr>"    
        }
    } 
    else 
    { 
         if($LoadTime -gt 10)
        {
                Add-Content $fileName "<tr>" 
                Add-Content $fileName "<td align='left'>$Source</td>"
                Add-Content $fileName "<td align='left'>$NameA</td>" 
                Add-Content $fileName "<td align='left'>$NameP</td>"
                Add-Content $fileName "<td align='left'>$url</td>"
                Add-Content $fileName "<td bgcolor='#FBB917' center='left'>$LoadTime</td>"
                Add-Content $fileName "<td bgcolor='#FBB917' center='left'>$messageState</td>"
                Add-Content $fileName "</tr>"
        }
        else
        {
                Add-Content $fileName "<tr>"  
                Add-Content $fileName "<td align='left'>$Source</td>"
                Add-Content $fileName "<td align='left'>$NameA</td>" 
                Add-Content $fileName "<td align='left'>$NameP</td>"
                Add-Content $fileName "<td align='left'>$url</td>"
                Add-Content $fileName "<td align='center'>$LoadTime</td>"
                Add-Content $fileName "<td bgcolor='#FBB917'center='left'>$messageState</td>"  
                Add-Content $fileName "</tr>"
        } 
    }
    
     
} #Function Validarwebapps

#************************************************************
#***********VALIDAR WEB APPLICATIONS & AppPool **************
#************************************************************
writeHtmlHeader $freeSpaceFileName
Add-Content $freeSpaceFileName "<br>"
Add-Content $freeSpaceFileName "<table width='100%'><tbody>" 
Add-Content $freeSpaceFileName "<tr bgcolor='#1D3557'>" 
Add-Content $freeSpaceFileName "<td width='100%' align='center' colSpan=6><font face='tahoma' color='#FFFFFF' size='2'><strong>Estado Web Applications - Web Services - AppPool</strong></font></td>" 
Add-Content $freeSpaceFileName "</tr>"
 
writeTableHeaderWebApps $freeSpaceFileName  

$WebClient = New-Object System.Net.WebClient  #Verifica y accede a una página web, El uso de esta clase y sus métodos asociados realmente descargará la página de origen del sitio web#
$WebClient.UseDefaultCredentials = $true  # usará las credenciales del usuario actual para la autenticación

echo $WebClient

foreach ($server in $serverlist) #Entrara a cada uno de los servers

{ #F1 server
   
   if (($server -eq $ServerDB) -or ($server -eq $ServerClusterApp)){ # Para sacar el SRV -DB y los del cluster
    Write-Host "This Server " $server "It´s DataBase or Cluster" -ForegroundColor Yellow
   }Else{
            $WebClient = New-Object System.Net.WebClient #Verifica el origen del sitio web
            $WebClient.UseDefaultCredentials = $true
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; #protocolo de cifrado destinado a mantener los datos seguros cuando se transfieren a través de la red

            Write-Host "This Server " $server  -ForegroundColor Green

             #Iterate through each web application
             Foreach($url in Get-Content $urllist)
             { # F2 URLList.txt
      Write-Host "$url"
                    $TimeStamp = Get-Date #Obtiene Obtiene la fecha y hora actuales.

                    try {
                            $Page = $WebClient.DownloadString($url) # descargar la página web y mostrarla en una consola de PowerShell.
                            $TimeTaken = ((Get-Date) - $TimeStamp).TotalMilliseconds
                            $WebClient.Dispose()
                            $messageState = "OK"
                        }
                    catch [Exception]
                        {
                           $messageState =  "ERROR - El sitio no está disponible!! " + $_.Exception.message 
                        }
                         
              #$webapps = Get-WebApplication
              $webapps = Invoke-Command -ComputerName $server {Import-Module WebAdministration; Get-WebApplication} #Importa los modulos  de webAdministattion done se Obtiene las aplicaciones web asociadas a un sitio específico o a un nombre especificado.

                    foreach($app in $webapps){
                        #$AppName = $url | Select-String $app.path
                         Write-host "$app" -f DarkYellow
                        $vapp = "*" + $app.path + "*"
                         Write-host "$vapp" -f red
                        $vserver = "*" + $server + "*"
                             
                        if ($url -like $vapp)
                           {
                           write-host "$url" -f Green
                        
                             #if($url -like $vserver)
                             #if($url -like "COSABOG13SW9180")
                               #{
                                    $Name_Pool = $app.applicationPool
                                    $Name_App  = $app.path
                                    $URLApp    = $AppName  
                                    
                                    #********************************************************
                                    # Estos parametros son para lanzar en LogicApps la URL 
                                    # Change only name url for start poll TEAMS
                                    $var     = $url
                                    $result1 = $var.Split("/")[$var.Split("/").Count - 1] 
                                    #********************************************************  
                                    #********************************************************                  
                                    Validarwebapps $freeSpaceFileName $server $Name_App $Name_Pool $Url $TimeTaken $messageState        
                              # }                  
                           }
                        else
                        {
                            $URLApp = "No lo Encontro"
                        }
                    }  #F3 App x Server                            
            } #F2 URLList.txt
  } # Else
} # F1 Server.txt

Add-Content $freeSpaceFileName "</table>" 

#==============================================================================================================================================
#==============================================================================================================================================

#***********************************************************
 #********PINTAR CONEXIONES CONCURRENTES WEB SITE************************

Function Validarconexiones
{ 
param($filename,$servidor, $siten, $currentco) 
        Add-Content $fileName "<tr>"
        Add-Content $fileName "<td align=center>$servidor</td>"    
        Add-Content $fileName "<td align=center>$siten</td>"    
        Add-Content $fileName "<td align=center>$currentco</td>"
        Add-Content $fileName "</tr>"
}  

 #***********VALIDAR CONEXIONES CONCURRENTES*************************
 Add-Content $freeSpaceFileName "<br>"
 Add-Content $freeSpaceFileName "<table width='100%'><tbody>" 
 Add-Content $freeSpaceFileName "<tr bgcolor='#1D3557'>" 
 Add-Content $freeSpaceFileName "<td width='100%' align='center' colSpan=3><font face='tahoma' color='#FFFFFF' size='2'><strong>Conexiones Concurrentes</strong></font></td>" 
 Add-Content $freeSpaceFileName "</tr>"
 
writeTableHeaderconexiones $freeSpaceFileName

 
#Iterate through each web application
Foreach($server in $serverlist)
{      
   $websites = Invoke-Command -ComputerName $server {Import-Module WebAdministration; Get-WebSite | select Name} #obtiene información de configuración para un sitio web de Internet Information Services y se mostrara solamente el nombre
   foreach($site in $websites)
     {
         $site = $site.name          
         $currentconn = ((Get-Counter "web service($site)\current connections" -ComputerName $server).CounterSamples).CookedValue
         Validarconexiones $freeSpaceFileName $server $site $currentconn                               
    }
         
}

Add-Content $freeSpaceFileName "</table>" 

#==============================================================================================================================================
#==============================================================================================================================================

#***************************************************************
#********************PINTAR ESTADO DISCOS***********************

Function writeDiskInfo 
{ 
    param($fileName,$devId,$volName,$frSpace,$totSpace) 

    $totSpace=[math]::Round(($totSpace/1073741824),2) 
    $frSpace=[Math]::Round(($frSpace/1073741824),2) 
    $usedSpace = $totSpace - $frspace 
    $usedSpace=[Math]::Round($usedSpace,2) 
    $freePercent = ($frspace/$totSpace)*100 
    $freePercent = [Math]::Round($freePercent,0) 

     if ($freePercent -gt $warning) 
     { 
         Add-Content $fileName "<tr>" 
         Add-Content $fileName "<td align='center'>$devid</td>" 
         Add-Content $fileName "<td align='center'>$volName</td>" 
 
         Add-Content $fileName "<td align='center'>$totSpace</td>" 
         Add-Content $fileName "<td align='center'>$usedSpace</td>" 
         Add-Content $fileName "<td align='center'>$frSpace</td>" 
         Add-Content $fileName "<td align='center'>$freePercent</td>" 
         Add-Content $fileName "</tr>" 
     } 
     elseif ($freePercent -le $critical) 
     { 
         Add-Content $fileName "<tr>" 
         Add-Content $fileName "<td align='center'>$devid</td>" 
         Add-Content $fileName "<td align='center'>$volName</td>" 
         Add-Content $fileName "<td align='center'>$totSpace</td>" 
         Add-Content $fileName "<td align='center'>$usedSpace</td>" 
         Add-Content $fileName "<td align='center'>$frSpace</td>" 
         Add-Content $fileName "<td bgcolor='#FF0000' align=center>$freePercent</td>" 
         Add-Content $fileName "</tr>" 
     } 
     else 
     { 
         Add-Content $fileName "<tr>" 
         Add-Content $fileName "<td align='center'>$devid</td>" 
         Add-Content $fileName "<td align='center'>$volName</td>" 
         Add-Content $fileName "<td align='center'>$totSpace</td>" 
         Add-Content $fileName "<td align='center'>$usedSpace</td>" 
         Add-Content $fileName "<td align='center'>$frSpace</td>" 
         Add-Content $fileName "<td bgcolor='#FBB917' align=center>$freePercent</td>" 
         # #FBB917
         Add-Content $fileName "</tr>" 
     } 
 }

#***************************************************************
#*******************VALIDAR ESTADO DISCOS***********************
#*************************************************************** 

Add-Content $freeSpaceFileName "<br>"
 
foreach ($server in $serverlist) 
{ 
     Add-Content $freeSpaceFileName "<table width='100%'><tbody>" 
     Add-Content $freeSpaceFileName "<tr bgcolor='#1D3557'>" 
     Add-Content $freeSpaceFileName "<td width='100%' align='center' colSpan=6><font face='tahoma' color='#FFFFFF' size='2'><strong>ESTADO DE DISCOS - $server </strong></font></td>" 
     Add-Content $freeSpaceFileName "</tr>"
     writeTableHeader $freeSpaceFileName 
     #$dp = Get-WmiObject win32_logicaldisk -ComputerName $server |  Where-Object {$_.drivetype -eq 3} 
     $dp = Get-WmiObject Win32_Volume -ComputerName $server |  Where-Object {$_.drivetype -eq 3} 
     foreach ($item in $dp) 
     { 
            $DriveLetter = $item.DriveLetter
            writeDiskInfo $freeSpaceFileName $item.DriveLetter $item.Label $item.FreeSpace $item.Capacity
     } 
    Add-Content $freeSpaceFileName "</table>"
}

#==============================================================================================================================================
#==============================================================================================================================================


#******************************************************************************
#********PINTAR ESTADO RENDIMIENTO SERVIDORES ***********************

Function validarrendimientoBTS
{ 
        param($filename,$diskp,$ram,$procesador) 
        Write-host "$dis"
        $procesador
        Add-Content $fileName "<tr>"
      if($diskp -gt "1,6")
      {
     
            Add-Content $fileName "<td bgcolor='#FBB917' align=center>$diskp</td>"

      
            if($ram -gt "89")
                {
                    if($procesador -gt "89")
                    {
                        Add-Content $fileName "<td bgcolor='#FBB917' align=center>$ram</td>"
                        Add-Content $fileName "<td bgcolor='#FBB917' align=center>$procesador</td>"
                    }
                    else
                    {
                        Add-Content $fileName "<td bgcolor='#FBB917' align=center>$ram</td>"
                        Add-Content $fileName "<td align=center>$procesador</td>"
                    }
                }
      
              else
              {
                    if($procesador -gt "89")
                    {
                        Add-Content $fileName "<td align=center>$ram</td>"
                        Add-Content $fileName "<td bgcolor='#FBB917' align=center>$procesador</td>"
                    }
                    else
                    {
                        Add-Content $fileName "<td align=center>$ram</td>"
                        Add-Content $fileName "<td align=center>$procesador</td>"
                    }
              }

      }#If

    else
	    {
		    Add-Content $fileName "<td align=center>$diskp</td>"
		
		    if($ram -gt "89")
		    {
			    if($procesador -gt "89")
			    {
				    Add-Content $fileName "<td bgcolor='#FBB917' align=center>$ram</td>"
				    Add-Content $fileName "<td bgcolor='#FBB917' align=center>$procesador</td>"
			    }
			    else
			    {
				    Add-Content $fileName "<td bgcolor='#FBB917' align=center>$ram</td>"
				    Add-Content $fileName "<td align=center>$procesador</td>"
			    }
	        }
		    else
		    {
			    if($procesador -gt "89")
			    {
				    Add-Content $fileName "<td align=center>$ram</td>"
				    Add-Content $fileName "<td bgcolor='#FBB917' align=center>$procesador</td>"
			    }
			    else
			    {
				    Add-Content $fileName "<td align=center>$ram</td>"
				    Add-Content $fileName "<td align=center>$procesador</td>"
			    }
			}
	    }#Else

  Add-Content $fileName "</tr>"
} 

#***************************************************************************** 
#*******************VALIDAR ESTADO MEMORIA Y PROCESADOR*********************** 
#***************************************************************************** 

 Add-Content $freeSpaceFileName "<br>"

foreach ($server in $serverlist) 
{ 

        #******************************************************************** 
        #*****VALIDAR ESTADO MEMORIA Y PROCESADOR SRV APPLICATIONS **********
        #********************************************************************
           
     if(($server -eq "$ServerDB")) #-or ($server -eq "EPMPS12-05"))
       
       {     
         
         Add-Content $freeSpaceFileName "<table width='100%'><tbody>" 
	     Add-Content $freeSpaceFileName "<tr bgcolor='#1D3557'>" 
	     Add-Content $freeSpaceFileName "<td width='100%' align='center' colSpan=6><font face='tahoma' color='#FFFFFF' size='2'><strong>Estado Rendimiento Servidor DB- $server </strong></font></td>" 
	     Add-Content $freeSpaceFileName "</tr>"
	 
	     writeTableHeaderRendimiento $freeSpaceFileName
	 
	     #% Uso Procesador
         $proc =((get-counter -Counter "\\$server\Processor(_Total)\% Processor Time" -SampleInterval 6 -MaxSamples 5).CounterSamples).CookedValue
	     $proc = $proc | Measure-Object -Average
	     $promproc = $proc.Average
	     $promproc = [math]::Round($promproc)
	
         #% Memoria disponible	
	     $memdisp =((get-counter -Counter "\\$server\Memory\Available MBytes" -SampleInterval 6 -MaxSamples 5).CounterSamples).CookedValue
	     $memdisp = $memdisp | Measure-Object -Average
	 
	     $OperatingSystem = Get-WmiObject win32_OperatingSystem -computer $server
	     $FreeMemory = $OperatingSystem.FreePhysicalMemory
	     $TotalMemory = $OperatingSystem.TotalVisibleMemorySize
	     $TotalMemory = $TotalMemory / 1024
	     $PMemoryFree = ($memdisp.Average) * 100
	     $PMemoryFree = $PMemoryFree /$TotalMemory
	     $PMemoryFree = 100 - $PMemoryFree
	     $PMemoryFree = [math]::Round($PMemoryFree)

         #% Uso Log TempDB
         $PDBLogFileSize = (Get-Counter -Counter "\\$server\SQLServer:Databases(tempdb)\Percent log used" -MaxSamples 1).CounterSamples.CookedValue
         $PLogtempdb = $PDBLogFileSize

         #% Aciertos Cache Buffer
         $Cachebuffer = (Get-Counter -Counter "\\$server\SQLServer:Buffer Manager\Buffer cache hit ratio" -MaxSamples 10 -SampleInterval 3).CounterSamples.CookedValue
         $Acachebuffer = $Cachebuffer | Measure-Object -Average
         $Acachebuffer = $Acachebuffer.Average

         #DeadLocks (seg)
         $DeadLocks = (Get-Counter -Counter "\\$server\SQLServer:locks(Database)\Number of deadlocks/sec" -MaxSamples 10 -SampleInterval 3).CounterSamples.CookedValue
         $SDeadLocks = $DeadLocks | Measure-Object -Average
         $SDeadLocks = $SDeadLocks.Average


         #Promedio bloqueos en espera (ms)
         $Bespera = (Get-Counter -Counter "\\$server\SQLServer:locks(Database)\Average Wait Time (ms)" -MaxSamples 10 -SampleInterval 3).CounterSamples.CookedValue
         $PBespera = $Bespera | Measure-Object -Average
         $PBespera = $PBespera.Average

	     validarrendimientoSRVDB $freeSpaceFileName $PMemoryFree $promproc $PLogtempdb $Acachebuffer $SDeadLocks $PBespera

       }#If

        #******************************************************************** 
        #*****VALIDAR ESTADO MEMORIA Y PROCESADOR SRV APPLICATIONS **********
        #******************************************************************** 

    else
      {
       write-host "$DiskCounter"
       
        Add-Content $freeSpaceFileName "<table width='100%'><tbody>" 
        Add-Content $freeSpaceFileName "<tr bgcolor='#1D3557'>" 
        Add-Content $freeSpaceFileName "<td width='100%' align='center' colSpan=3><font face='tahoma' color='#FFFFFF' size='2'><strong> ESTADO RENDIMIENTO  - $server </strong></font></td>" 
        Add-Content $freeSpaceFileName "</tr>"

        writeTableHeaderRendimientoBTS $freeSpaceFileName 

        $DiskCounter = ((Get-Counter "\\$server\PhysicalDisk(*)\Current Disk Queue Length" -SampleInterval 6 -MaxSamples 5).Countersamples | `
                       Select InstanceName,CookedValue | where {$_.InstanceName -like "*Total*"}).CookedValue
        $DiskCounter = $DiskCounter | Measure-Object -Average
        $IO_disk = $DiskCounter.Average

        #% Uso Procesador
        $proc =((get-counter -Counter "\\$server\Processor(_Total)\% Processor Time" -SampleInterval 6 -MaxSamples 5).CounterSamples).CookedValue
        $proc = $proc | Measure-Object -Average
        $promproc = $proc.Average
        $promproc = [math]::Round($promproc)

        #% Memoria disponible	    
        $memdisp =((get-counter -Counter "\\$server\Memory\Available MBytes" -SampleInterval 6 -MaxSamples 5).CounterSamples).CookedValue
        $memdisp = $memdisp | Measure-Object -Average

        $OperatingSystem = Get-WmiObject win32_OperatingSystem -computer $server
        $FreeMemory = $OperatingSystem.FreePhysicalMemory
        $TotalMemory = $OperatingSystem.TotalVisibleMemorySize
        $TotalMemory = $TotalMemory / 1024
        $PMemoryFree = ($memdisp.Average) * 100
        $PMemoryFree = $PMemoryFree /$TotalMemory
        $PMemoryFree = 100 - $PMemoryFree
        $PMemoryFree = [math]::Round($PMemoryFree)

        validarrendimientoBTS $freeSpaceFileName $IO_disk $PMemoryFree $promproc
        
            
      }#else
    

     Add-Content $freeSpaceFileName "</table>"
 
 }

#==============================================================================================================================================
#==============================================================================================================================================

#****************************************************************
#********PINTAR ESTADO SERVICIOS WINDOWS ************************


Function validarservicios 
{ 
param($filename,$ArrayServicios) 
 
 Add-Content $fileName "<tr>"

 foreach($servicio in $ArrayServicios)
 {
    $srvdn     = $servicio.DisplayName
    $srvstatus = $servicio.Status
    $srvn      = $servicio.Name
    $machine   = $server.psobject.BaseObjectbas

    if($servicio.Status -eq "Running")
    {
        Add-Content $fileName "<td><align=center>$srvdn</td>"    
        Add-Content $fileName "<td><align=center>$srvstatus</td>"    

    }
    else
    {
        Add-Content $fileName "<td>$srvdn</td>"
        Add-Content $fileName "<td bgcolor='#FBB917' align=center>$srvstatus</td>"

         #get-Service -Name $ServiceName -ComputerName $computer| set-service -StartupType Automatic
         #get-Service -Name $ServiceName -ComputerName $computer| set-service -Status Running 

        #================================================================
        #Build Poll TEAMS Remedation services
        #================================================================
        write-host $machine -ForegroundColor green
        
        #$TeamsURI  = 'https://prod-06.eastus2.logic.azure.com/workflows/8c90040e7e18478b92e89a50956cd045/triggers/manual/paths/invoke/Teams/'+$machine+'/'+$srvn+'?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=TiUD5yoYtCsGpRR1x-k8v2lLfU6O3IzHBJyZkqewWlo'
        #  Nov 22 2021: $TeamsURI   = 'https://prod-62.eastus2.logic.azure.com/workflows/758f824348364dd882a9945c74aa1c77/triggers/manual/paths/invoke/Teams/'+$machine+'/'+$srvn+'?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=xQCwMpp7lYJu1k0SwC76mXqrvJDyE-T4xh_N38fhMSY'
        $TeamsURI = 'https://prod-45.eastus2.logic.azure.com/workflows/7376c21b6e0040f9bf085b6e64826f82/triggers/manual/paths/invoke/Teams/'+$machine+'/'+$srvn+'?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=unAQaWr8aMw2C90Pr40WaQKkxsgHPZDZy-xGJloxQqo'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        #Invoke-WebRequest -Uri $TeamsURI -Verbose 
    }
     
  Add-Content $fileName "</tr>"
    
 }
 
} 

#***********************************************************
#************ VALIDAR  SERVICIOS WINDOWS *******************
#***********************************************************

 Add-Content $freeSpaceFileName "<br>"

 foreach ($server in $serverlist) 
 {
       
     Add-Content $freeSpaceFileName "<table width='100%'><tbody>" 
     Add-Content $freeSpaceFileName "<tr bgcolor='#1D3557'>" 
     Add-Content $freeSpaceFileName "<td width='100%' align='center' colSpan=2><font face='tahoma' color='#FFFFFF' size='2'><strong>Estado Servicios -  $server </strong></font></td>" 
     Add-Content $freeSpaceFileName "</tr>" 
 
     writeTableHeaderServicios $freeSpaceFileName 
       
     #Si los server son de SQL, traer servicios de SQL      
     if(($server -like "$ServerDB")) #-and ($server -eq "EPMPS12-05"))
     {
        $serviciossp = Get-Service -Name Netlogon,LanmanWorkstation,MSSQLSERVER,SQLSERVERAGENT -ComputerName $server -ErrorAction SilentlyContinue
        
        validarservicios $freeSpaceFileName $serviciossp
      }

     else #Si los server son de App, traer servicios de BTS      
     {
         $SQLAgent = "SQLAgent $DEVOPSINFRA"
         $serviciossp = Get-Service -Name W3SVC,IISADMIN,Netlogon,W32Time,LanmanWorkstation -ComputerName $server -ErrorAction SilentlyContinue
         validarservicios $freeSpaceFileName $serviciossp    
     }
 }
 
   Add-Content $freeSpaceFileName "</table>"

#==============================================================================================================================================
#==============================================================================================================================================

#*****************************************************************
#************* PINTAR ESTADO CERTIFICADOS ************************

Function ValidarCertificados
{  
    param($fileName,$scert,$expecert,$expicert,$rcert,$subcert,$tcert)
        
    if($rcert -lt 31)
    {
        Add-Content $fileName "<tr>"
        Add-Content $fileName "<td align=center>$scert</td>"    
        Add-Content $fileName "<td align=center>$expecert</td>"    
        Add-Content $fileName "<td align=center>$expicert</td>"    
        Add-Content $fileName "<td bgcolor='red' align=center>$rcert</td>"    
        Add-Content $fileName "<td align=center>$subcert</td>"    
        Add-Content $fileName "<td align=center>$tcert</td>"    
        Add-Content $fileName "</tr>"  
    
    }
    elseif ($rcert -lt 61){
        Add-Content $fileName "<tr>"
        Add-Content $fileName "<td align=center>$scert</td>"    
        Add-Content $fileName "<td align=center>$expecert</td>"    
        Add-Content $fileName "<td align=center>$expicert</td>"    
        Add-Content $fileName "<td bgcolor='#FBB917' align=center>$rcert</td>"    
        Add-Content $fileName "<td align=center>$subcert</td>"    
        Add-Content $fileName "<td align=center>$tcert</td>"    
        Add-Content $fileName "</tr>"
    }
    else {
        Add-Content $fileName "<tr>"
        Add-Content $fileName "<td align=center>$scert</td>"    
        Add-Content $fileName "<td align=center>$expecert</td>"    
        Add-Content $fileName "<td align=center>$expicert</td>"    
        Add-Content $fileName "<td align=center>$rcert</td>"    
        Add-Content $fileName "<td align=center>$subcert</td>"    
        Add-Content $fileName "<td align=center>$tcert</td>"    
        Add-Content $fileName "</tr>"  
    }       

}

 
 #*******************************************************************
 #***********VALIDAR CERTIFICADOS SERVIDORES*************************
 #*******************************************************************

Add-Content $freeSpaceFileName "<br>"
Add-Content $freeSpaceFileName "<table width='100%'><tbody>" 
Add-Content $freeSpaceFileName "<tr bgcolor='#1D3557'>" 
Add-Content $freeSpaceFileName "<td width='100%' align='center' colSpan=6><font face='tahoma' color='#FFFFFF' size='2'><strong>Estado Certificados</strong></font></td>" 
Add-Content $freeSpaceFileName "</tr>"
 
writeTableHeadercertificados $freeSpaceFileName
 
$DaysExpired = "60"
$DateLimit = (Get-Date).AddDays(+$DaysExpired) 

$certificados = Foreach ($server in $serverlist)
                {
                    $server.ToString()
                    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("\\$server\My","LocalMachine")
                    $store.Open(“ReadOnly”)
                    $store.Certificates | select @{N='ServerName';E={$server}},@{N='ExpeditionDate';E={Get-Date $_.NotBefore}},@{N='ExpirationDate';E={Get-Date $_.NotAfter}},`
                    @{N='RemainigDays';E={(New-TimeSpan -Start (Get-Date) -End (Get-Date $_.NotAfter)).Days}},Subject,Thumbprint | Sort-Object RemainigDays
                }

$datos = $certificados | where {$_.ExpirationDate}
 
foreach($dato in $datos)
{
    $servercert  = $dato.ServerName
    $subjectcert = $dato.Subject
    $expedicert  = $dato.ExpeditionDate
    $expiracert  = $dato.ExpirationDate
    $remadcert   = $dato.RemainigDays
    $thumbcert   = $dato.Thumbprint
    
    ValidarCertificados $freeSpaceFileName $servercert $expedicert $expiracert $remadcert $subjectcert $thumbcert 

} 

Add-Content $freeSpaceFileName "</table>"

#==============================================================================================================================================
#==============================================================================================================================================

#****************************************************************
writeHtmlFooter $freeSpaceFileName 
$date = ( get-date ).ToString('yyyy/MM/dd') 

start-sleep -seconds 2

####################### Notify in Teams #############################
$IaCMsg = " Check result in SharePoint"
WriteTeams $IaCMsg
#####################################################################

#####################################################################
start-sleep -seconds 5

####################### path for upload htm in OneDrive #############
IacUploadItem -IaCPath $freeSpaceFileName
#======================FINAL LOG ================================#
Stop-Transcript