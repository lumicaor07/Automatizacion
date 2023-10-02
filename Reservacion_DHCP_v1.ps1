<#####################################################################################################################################################################
    Descripcion      : Reservación de Mac e ip en el DHCP
    Ambiente         : PRD
    Nombre Script PS : Reservacion_DHCP
    Version          : [1] Implementacion del Script servidores del DHCP
#####################################################################################################################################################################>

$Machine          = "SERDCGTD2"
$dt               = get-date -Format "MM-dd-yyyy-HHmm"
Start-Transcript -Path "C:\LogsDhcp\Log_$dt.txt"

################### Guardar el valor de los variables de sistema en archivos#########################################################
$variable = Get-ItemPropertyValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" -Name "Mac"
$variable | Out-File -FilePath "C:\IaC\Infraestructure\DHCP\Mac.txt"

$variable = Get-ItemPropertyValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" -Name "Descripcion"
$variable | Out-File -FilePath "C:\IaC\Infraestructure\DHCP\Descripcion.txt"

$variable = Get-ItemPropertyValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" -Name "Ip"
$variable | Out-File -FilePath "C:\IaC\Infraestructure\DHCP\Ip.txt"

################## Obtener el contenido de los archivos ##############################################################################
$Mac = Get-Content -Path "C:\IaC\Infraestructure\DHCP\Mac.txt"
$Ip = Get-Content -Path "C:\IaC\Infraestructure\DHCP\Ip.txt"
$Descripcion = Get-Content -Path "C:\IaC\Infraestructure\DHCP\Descripcion.txt"

#######################################################################################################################################
Invoke-Command -ComputerName $Machine -ScriptBlock {
#Expresion regular que valida que se ingrese una ipv4
$validateipv4 = '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
$validateMAC = '^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$'

# Acceder a la variable mediante $using:nombreVariable
$Mac = $using:Mac
$Descripcion = $using:Descripcion
$Ip = $using:Ip

# Hacer algo con la variable
Write-Host $Mac
Write-Host $IP
Write-Host $Descripcion

#Valores
$mac = $Mac
$descripcion = $Descripcion

#Ingreso de ip hasta que sea correcta la sintaxis de la expresion regular
do {
    $iprecibida = $IP
} while ($iprecibida -notmatch $validateipV4)

#Convertir la ipv4 a Scope
$desestrcuturada = $iprecibida.Split(".")

$nuevoscope = $desestrcuturada[0] + "." + $desestrcuturada[1] + "." + $desestrcuturada[2] + ".0"

#Obtener listado de scopes
$ReserVScope = Get-DhcpServerv4Scope
$listadoScopes = $ReserVScope.ScopeId.IPAddressToString

#Comprobar si el scope existe en la lista de scopes del servidor
$compScope = 0
foreach ($scope in $listadoScopes) {
    if ($nuevoscope -eq $scope) {
        $compScope = 1

    }
}

#Si el scope existe se procede a validar los rangos de exclusion
if ($compScope -and ($mac -match $validateMAC)) {
    Write-Output "existe el scope"

    #obtener lista de exclusiones en el scope seleccionado
    $specificScope = Get-DhcpServerv4Scope -ScopeId $nuevoscope

    #obtener lista de inicios y finales de rangos de exclusion
    $startrange = $specificScope.StartRange.IPAddressToString
    $endrange = $specificScope.EndRange.IPAddressToString

    #si la ip esta dentro del rango de ips se puede reservar, por defecto no se podria
    $compexclude = 0
   
    $fininitrange = [int]$startrange.Split(".")[3]
    $finendrange = [int]$endrange.Split(".")[3]

    $finiprecibida = [int]$iprecibida.Split(".")[3]
  
    #Si no se encuentra el rango de exclusion, es posible reservar la ip
    if (($finiprecibida -ge $fininitrange) -and ($finiprecibida -le $finendrange)) {
        $respuestaex = "La ip " + $iprecibida + " Esta disponible en el scope: " + $nuevoscope
        $listadoip = Get-DhcpServerv4Lease -ScopeId $nuevoscope
        Write-Output $respuestaex

        $compip = 0
        $ipexist = 0
        $respuesta = ""

        foreach ($cosas in $listadoip) {
            if ($cosas.IPAddress -eq $iprecibida) {
                if($cosas.ClientId -eq $mac){
                    if($cosas.AddressState -eq "Active"){
                        $compip = 1
                        $ipexist = 1
                        $nombre = $cosas.HostName
                        break
                    }elseif($cosas.AddressState -eq "ActiveReservation"){
                        $ipexist = 1
                        $respuesta = "La ip "+$iprecibida+" y la mac "+$mac+" Ya tienen una reserva Activa"
                        $compip = 0
                        break
                    }else{
                        $respuesta = "La ip "+$iprecibida+" y la mac "+$mac+" Ya tienen una reserva inactiva"
                        $ipexist = 1
                        $compip = 0
                        break
                    }

                }else{
                    $respuesta = "La ip "+$iprecibida+" Tiene otra mac asignada "+$cosas.ClientId+" a la mac ingresada: "+$mac
                    $compip = 0
                    $ipexist = 1
                    break
                }      
            }else{
                $ipexist = 0
                $compip= 0 
            
            }            
        }

        $macexist
        if (!$compip -and !$ipexist){
            foreach ($macs in $listadoip){
                if($macs.ClientId -eq $mac){
                     $respuesta = "La mac: "+$mac+" ya tiene asignada la ip: "+$macs.IpAddress
                     $macexist=1
                     break
                }else{
                    $macexist=0
                }
            }

        }


    
        if (!$ipexist -and !$macexist) {
            $macres = $mac.Replace("-","")
            Add-DhcpServerV4Reservation -ScopeId $nuevoscope -IpAddres $iprecibida  -ClientId $macres -Description  $descripcion -Type DHCP -Verbose
            Write-Output $respuesta
            Write-Output "recuerde que para activar la reserva es necesario reiniciar la interfaz de red"
        }
        elseif ($compip -and $ipexist) {
            Get-DhcpServerv4Lease  -IPAddress $iprecibida | Add-DhcpServerv4Reservation 
            <#Invoke-Command -ComputerName $nombre -ScriptBlock {
                ipconfig /renew
            }
            #>
                      
        }else{
            Write-Output $respuesta
        }

    } #si se encuentra la ip dentro del rango, no se podria reservar.
    else {
        $respuestaex = "La ip "+$iprecibida +" Esta fuera del Rango de distribucion para el scope: "+$nuevoscope+" el cual es: "+$startrange+"-"+$endrange
        Write-Output $respuestaex 
    }
    
}
else { #no existe el scope
    if($mac -notmatch $validateMAC){
        Write-Output "la mac esta en un formato invalido, porfavor revisar"

    }else{
        Write-Output "no existe el scope"
    }
}
}
Stop-Transcript