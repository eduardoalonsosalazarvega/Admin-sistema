get-service -name "LSM" | Get-member

get-service -name "LSM" | Get-member -memberType property


get-Item C:\Users\salaz\Desktop\edu.txt | Get-Member -MemberType Method

get-Item C:\Users\salaz\Desktop\edu.txt | Select-Object name, Length

get-service | Select-Object -last 5 

get-service | Select-Object -first 5 

Get-Service |Where-Object {$_.Status -eq "Running"}

(Get-Item C:\Users\salaz\Desktop\edu.txt ).IsReadOnly
(Get-Item C:\Users\salaz\Desktop\edu.txt ).IsReadOnly = 1
(Get-Item C:\Users\salaz\Desktop\edu.txt ).IsReadOnly

Get-ChildItem *.txt

$miObjeto = New-object PSObject
$miObjeto | Add-member -MemberType NoteProperty -name Nombre -Value "Miguel"
$miObjeto | Add-member -MemberType NoteProperty -name edad -Value 23
$miObjeto | Add-member -MemberType ScriptMethod -name Saludar -Value {write-host "hola mundo"}

$miObjetol = New-object -TypeName PSObject -Property @{
  Nombre = "miguel"
  Edad = 23
 }

$miObjetol | Add-member -MemberType ScriptMethod -name saludar -value {write-host "Hola mundo"}
$miObjetol | Get-Member

$miObjetol = [PSCustomObject] @{
  Nombre = "miguel"
  Edad = 23
 }

$miObjetol | Add-member -MemberType ScriptMethod -name saludar -value {write-host "Hola mundo"}
$miObjetol | Get-Member

Get-Process -Name Acrobat | Stop-Process

Get-Help -Full Get-Process 
Get-Help -Full Stop-Process

Get-Process

Get-Help -Full Get-ChildItem 
Get-Help -Full Get-Clipboard

Get-ChildItem *.txt | Get-Clipboard

Get-Help -Full Stop-Service 

Get-service
Get-Service Spooler | Stop-Service
Get-Service

Get-service 
"Spooler" | Stop-Service
Get-Service
Get-Service

$miObjeto = [PSCustomObject] @{
Name = "Spooler"
}
$miObjeto | Stop-Service
Get-Service
Get-Service