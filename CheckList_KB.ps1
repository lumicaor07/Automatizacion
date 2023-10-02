<####################################################################################################################################################################
    Descripcion      : Check List para ejecutar el diagnostico de aplicacion Y2.
    Ambiente         : PRD
    Nombre Script PS : CheckList_AfterReboot
    Version          : [2] Implementacion del Script servidores Bases de datos
#####################################################################################################################################################################>


$dateUpload        =  Get-Date -format dd_MM_yyyy_HH_mm
$Path              =  "C:\IAC\CheckKB"
$Path_html         =  "C:\IAC\CheckKB\Resultados_CheckList"
$freeSpaceFileName =  "$Path_html\CheckList_Server_$dateUpload.html"
$rutahtml          =  $freeSpaceFileName
[String]$string = [System.Environment]::GetEnvironmentVariable("maquinas","Machine")
$string = $string -replace "\s",""
$serverlist = $string.split(",")

$getDate  = (Get-Date).ToString()

New-Item -ItemType file $freeSpaceFileName -Force 
#

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



#====================================================================#

###########################################################
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
         $uri = 'https://graph.microsoft.com/v1.0/sites/97f4abe2-7112-478d-9189-256ba9d542e8/drive/root:/IaC/Colmedica/WEBKB/'+$uploadItem.Name+':/content'
	
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


#======================INICIO LOG ================================#
Start-Transcript -Path "C:\IAC\CheckKB\Logs\Checklist_IIS_IaC-$dateUpload.txt"
################################################################################################################################################

Function writeHtmlHeader 
{ 
    param($fileName) 
    $date = ( get-date ).ToString('yyyy/MM/dd') 
    Add-Content $fileName "<html>" 
   # Add-Content $fileName "<br>"
    Add-Content $fileName "<img src='$Path\LogoHead.jpg'>"
    Add-Content $fileName "<img src='https://i.postimg.cc/jSZFB09N/LogoHead.jpg'>"
    Add-Content $fileName "<head>" 
    Add-Content $fileName "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>" 
    Add-Content $fileName '<title>Reporte estado plataforma - Y2 </title>' 
    add-content $fileName '<style type="text/css">' 
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
    add-content $fileName  "-->" 
    add-content $fileName  "table {" 
    add-content $fileName  "border: 1px solid;" 
    #add-content $fileName  "border: thin solid #000000;" 
    add-content $fileName  "}" 
    add-content $fileName  "</style>" 
    Add-Content $fileName "</head>" 
    Add-Content $fileName "<body>" 
    
    add-content $fileName  "<table width='100%' style='border:2px solid black;'>" 
    #add-content $fileName  "<tr bgcolor='#2a4373'>" 
    add-content $fileName  "<tr bgcolor='#1D3557'>" 
    add-content $fileName  "<td colspan='6' height='25' align='center'>" 
    add-content $fileName  "<font face='tahoma' color='#DFFE00' size='6'><strong> Validacion Reinicio - $getDate </strong></font>" 
    add-content $fileName  "</td>" 
    add-content $fileName  "</tr>" 
    #add-content $fileName  "</table>" 

}

    writeHtmlHeader $freeSpaceFileName

#HTML para el estado de los servicios Web
Function writetitleservers
{ 
    param($fileName) 
     
    #Add-Content $freeSpaceFileName "<tr bgcolor='#1D3557'>" 
    #Add-Content $freeSpaceFileName "<td width='100%' align='center' colSpan=6><font face='tahoma' color='#FFFFFF' size='3'><strong>Estado Web Applications - Web Services - AppPool</strong></font></td>" 
    #Add-Content $freeSpaceFileName "</tr>"
    Add-Content $fileName "<tr bgcolor=#457B9D>"  
    Add-Content $fileName "<td width='25%' align='center'><font face='tahoma' color='#FFFFFF'><strong>Uptime</strong></td>" 
    Add-Content $fileName "<td width='25%' align='center'><font face='tahoma' color='#FFFFFF'><strong>Servicios</strong></td>"
    Add-Content $fileName "<td width='25%' align='center'><font face='tahoma' color='#FFFFFF'><strong>Estado</strong></td>"
    Add-Content $fileName "<td width='25%' align='center'><font face='tahoma' color='#FFFFFF'><strong>KB</strong></td>" 
    Add-Content $fileName "</tr>"  
} 



foreach ($server in $serverlist){
    Add-Content $freeSpaceFileName "<table width='100%' style='border:2px solid black;'><tbody>" 
    Add-Content $freeSpaceFileName "<tr bgcolor='#1D3557'>" 
    Add-Content $freeSpaceFileName "<td width='100%' align='center' colSpan=6><font face='tahoma' color='#FFFFFF' size='3'><strong>Servidor - $server</strong></font></td>" 
    Add-Content $freeSpaceFileName "</tr>"
    #llamar funcion de 
    

  
    ######################
    ping $server > C:\IAC\CheckList_Servidores_IaC\ping.txt
    [String]$domincol = "hilanet.local"
    if(Select-string -Path "C:\IAC\CheckList_Servidores_IaC\ping.txt" -Pattern "TTL" -Quiet){
        writetitleservers $freeSpaceFileName
        $ArrayServicios = Get-Service -Name "*SQL*" -ErrorAction SilentlyContinue -ComputerName $server
        $conteo = $ArrayServicios.Count
        if($conteo -eq 0){
            #funcion uptime $uptime
            [string]$uptime = Get-CimInstance -ClassName win32_operatingsystem -ComputerName $server | select lastbootuptime 
            #[string]$uptime = Get-CimInstance -ClassName win32_operatingsystem | select lastbootuptime 
            $uptime = $uptime -replace "@{lastbootuptime=",""
            $uptime = $uptime -replace "}",""
    


            #funcion KB
            #$variable = Get-HotFix -ComputerName $server | select HotFixId 
            $variable =  Invoke-Command -ComputerName $server -ScriptBlock {
                (Get-HotFix | Sort-Object -Property InstalledOn)[-10] | select HotFixId
            }
            #$variable = Get-HotFix | select HotFixId 
            $kb = Out-String -InputObject $variable.HotFixId
            $kb = $kb -replace "HotFixId",""
            $kb = $kb -replace "--------",""

            Add-Content $freeSpaceFileName "<tr>"
            Add-Content $freeSpaceFileName "<td align='center'>$uptime</td>"
            Add-Content $freeSpaceFileName "<td align='center'>No hay servicios SQL</td>"
            Add-Content $freeSpaceFileName "<td align='center'>No hay servicios SQL</td>"
            Add-Content $freeSpaceFileName "<td align='center'>$kb</td>"
            Add-Content $freeSpaceFileName "</tr>"
        } else {
            $sname  = $ArrayServicios[0].DisplayName
            $sstatus = $ArrayServicios[0].Status
    

            #funcion uptime $uptime
            [string]$uptime = Get-CimInstance -ClassName win32_operatingsystem -ComputerName $server | select lastbootuptime 
            #[string]$uptime = Get-CimInstance -ClassName win32_operatingsystem | select lastbootuptime 
            $uptime = $uptime -replace "@{lastbootuptime=",""
            $uptime = $uptime -replace "}",""
    


            #funcion KB
            #$variable = Get-HotFix -ComputerName $server | select HotFixId 
            $variable =  Invoke-Command -ComputerName $server -ScriptBlock {
                (Get-HotFix | Sort-Object -Property InstalledOn)[-10] | select HotFixId
            }
            #$variable = Get-HotFix | select HotFixId 
            $kb = Out-String -InputObject $variable.HotFixId
            $kb = $kb -replace "HotFixId",""
            $kb = $kb -replace "--------",""

            Add-Content $freeSpaceFileName "<tr>"
            Add-Content $freeSpaceFileName "<td align='center' rowspan='$conteo'>$uptime</td>"
            if($sstatus -eq "Running"){
            Add-Content $freeSpaceFileName "<td align=center>$sname</td>"    
            Add-Content $freeSpaceFileName "<td align=center>$sstatus</td>"
            } else {
            Add-Content $freeSpaceFileName "<td align=center>$sname</td>"
            Add-Content $freeSpaceFileName "<td bgcolor='#FBB917' align=center>$sstatus</td>"
            }
            Add-Content $freeSpaceFileName "<td align='center' rowspan='$conteo'>$kb</td>"
            Add-Content $freeSpaceFileName "</tr>"


            $srvdn = $ArrayServicios.DisplayName
            $srvstatus = $ArrayServicios.Status

            for( $i=1; $i -lt $conteo; $i++){
                if($srvstatus[$i] -eq "Running")
                {
                    $name = $srvdn[$i]
                    $estado = $srvstatus[$i]
                    Add-Content $freeSpaceFileName "<tr>"    
                    Add-Content $freeSpaceFileName "<td align=center>$name</td>"    
                    Add-Content $freeSpaceFileName "<td align=center>$estado</td>" 
                    Add-Content $freeSpaceFileName "</tr>"
                 }else
                 {
                    $name = $srvdn[$i]
                    $estado = $srvstatus[$i]
                    Add-Content $freeSpaceFileName "<tr>"
                    Add-Content $freeSpaceFileName "<td align=center>$name</td>"
                    Add-Content $freeSpaceFileName "<td bgcolor='#FBB917' align=center>$estado</td>"
                    Add-Content $freeSpaceFileName "</tr>"
                 }

            }
        }
    } else {
        Add-Content $freeSpaceFileName "<tr>"
        Add-Content $freeSpaceFileName "<td bgcolor='red' align=center>Servidor $server no encontrado</td>"
        Add-Content $freeSpaceFileName "</tr>"
    }   
    Remove-Item C:\IAC\CheckList_Servidores_IaC\ping.txt
    }

#########################################

 $IaCMsg = " Check result in SharePoint"
WriteTeams $IaCMsg

####################### path for upload htm in OneDrive #############
IacUploadItem -IaCPath $freeSpaceFileName


###########################################################

IacEmail
##########################################################


Stop-Transcript
