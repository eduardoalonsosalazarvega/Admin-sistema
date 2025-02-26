function Obtener-IP {
    $pattern = "^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    
    $Ip = Read-Host "Ingrese la dirección IP de la máquina virtual"
    while ($Ip -notmatch $pattern) {
        Write-Host "Error: La dirección IP ingresada no es válida." -ForegroundColor Red
        $Ip = Read-Host "Ingrese una IP válida"
    }
    return $Ip
}

function Obtener-Rango-IP {
    $pattern = "^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"

    $IpInicial = Read-Host "Ingrese la IP de inicio del rango DHCP"
    while ($IpInicial -notmatch $pattern) {
        Write-Host "La IP ingresada no es válida. Inténtelo de nuevo."
        $IpInicial = Read-Host "Ingrese una IP inicial válida"
    }

    $IpFinal = Read-Host "Ingrese la IP de fin del rango DHCP"
    while ($IpFinal -notmatch $pattern -or ([int]($IpFinal -split '\.')[3]) -le ([int]($IpInicial -split '\.')[3])) {
        Write-Host "La IP final debe ser válida y mayor que la IP inicial."
        $IpFinal = Read-Host "Ingrese una IP final válida"
    }

    return $IpInicial, $IpFinal
}
