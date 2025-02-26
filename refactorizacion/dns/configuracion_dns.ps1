function Configurar-DNS {
    param ([string]$IP, [string]$Dominio)

    $NombreZona = "$Dominio.dns"
    $partes = $IP -split "\."
    $NetworkID = ($partes[2..0] -join ".") + ".in-addr.arpa.dns"

    # Instalar función DNS si no está presente
    if (-not (Get-WindowsFeature -Name DNS -ErrorAction SilentlyContinue).Installed) {
        Install-WindowsFeature -Name DNS -IncludeManagementTools
        Write-Host "Función DNS instalada correctamente." -ForegroundColor Green
    }

    # Configurar zonas DNS
    Add-DnsServerPrimaryZone -Name $Dominio -ZoneFile $NombreZona -DynamicUpdate None -PassThru
    Add-DnsServerPrimaryZone -NetworkID $IPScope -ZoneFile $NetworkID -DynamicUpdate None -PassThru

    # Agregar registros A y PTR
    Add-DnsServerResourceRecordA -Name "@" -ZoneName $Dominio -IPv4Address $IP -CreatePtr -PassThru
    Add-DnsServerResourceRecordA -Name "www" -ZoneName $Dominio -IPv4Address $IP -CreatePtr -PassThru

    # Configurar el cliente DNS
    Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses $IP

    Write-Host "Configuración DNS completada para $Dominio" -ForegroundColor Green
}

function Reiniciar-DNS {
    Restart-Service DNS
    Write-Host "Servicio DNS reiniciado correctamente." -ForegroundColor Green
}
