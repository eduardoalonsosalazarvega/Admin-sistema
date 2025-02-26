function Validar-IP {
    param ([string]$IP)
    
    $pattern = "^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"

    if (-not ($IP -match $pattern)) {
        Write-Host "Error: La dirección IP ingresada no es válida." -ForegroundColor Red
        exit
    }
}