Get-Verb
function Get-Fecha
{
Get-Date
}
Get-Fecha

Get-ChildItem -Path Function:\Get-*
Get-ChildItem -Path Function:\Get-Fecha | Remove-Item
Get-ChildItem -Path Function:\Get-*

function Get-Resta {
Param ([Int]$num1, [int]$num2)
$resta=$num1-$num2
write-host "La resta de los parametros es $resta"

}

Get-resta 10 5
Get-resta -num2 10 -num1 5 
Get-resta -num2 10

function Get-resta {
param ([parameter (Mandatory)][int]$num1, [int]$num2)
$resta=$num1-$num2
write-host "La resta de los parametros es $resta"
}

Get-resta -num2 10

function Get-Resta {
[CmdletBinding()]
param ([Int]$num1, [int]$num2)
$resta = $num1-$num2
write-host "La resta de los primeros es $resta"
}

(Get-Command -Nmae Get-Resta).Parameters.keys

Function Get-Resta {
[CmdletBinding()]
Param ([Int]$num1, [int]$num2)
$resta=$num1-$num2 #operacion que realiza la resta
Write-Host "La resta de los parametros es $resta"
}

Function Get-Resta {
[CmdletBinding()]
Param ([Int]$num1, [int]$num2)
$resta=$num1-$num2 #operacion que realiza la resta
Write-Verbose -Message "Operacion que va a realizar una resta de $num1 y $num2"
Write-Host "La resta de los parametros es $resta"
}

Get-Resta 10 5 -Verbose 


