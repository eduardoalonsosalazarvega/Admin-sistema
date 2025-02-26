function Configurar-Red {
    param ([string]$IP)

    $partes = $IP -split "\."
    $partes[3] = "0"
    $IPScope = ($partes[0..2] -join ".") + ".0/24"

    New-NetIPAddress -IPAddress $IP -InterfaceAlias "Ethernet 2" -PrefixLength 24
}
