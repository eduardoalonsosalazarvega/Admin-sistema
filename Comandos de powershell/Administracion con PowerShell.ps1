Get-Service
Get-Service -Name Spooler
Get-Service -DisplayName Hora*

Get-Service | Where-Object {$_.Status -eq "Running"}
Get-Service | 
where-object {$_.StartType -eq "Automatic"} |
Select-object Name, StartType

Get-Service -DependentServices Spooler
Get-Service -RequiredServices Fax

Stop-Service -Name Spooler -Confirm -PassThru

Start-Service -Name Spooler -Confirm -PassThru

Suspend-Service -Name Stisvc -Confirm -PassThru

Get-Service | Where-Object CanPauseAndContinue -eq True

Restart-Service -Name WSearch -Confirm -PassThru

Set-Service -Name dcsvc -DisplayName "Servicio de virtualizacion de credenciales de seguridad distribuida"

Set-Services -Name BITS -StartupType Automatic -confirm -PassThru | Select-Object Name, StartType
Set-Services -Name BITS -Description "Transfiere archivos en segundo plano mediante el uso de ancho de banda de red inactivo  "
Get-CimInstance win32_service -Filter 'Name = "BITS"' | Format-List Name, Description
Set-Service -Name Spooler -Status Running -Confirm -PassThru
Set-Service -Name Stisvc -Status Pused -Confirm -PassThru
Set-Service -Name BITS -Status Stopped -Confirm -PassThru



