Get-Process
Get-Process -Name Acrobat
Get-Process -Name Search*
Get-Process -Id 13948
Get-Process WINWORD -FileVersionInfo
Get-Process WINWORD -IncludeUserName
Get-Process WINWORD -Module

Stop-Process -Name Acrobat -Confirm -PassThru
Stop-Process -Id 10940 -Confirm -PassThru
Get-Process -Name Acrobat | Stop-Process -Confirm -PassThru

Start-Process -FilePath "C:\Windows\" -PassThru
Start-Process -FilePath "cmd.exe" -ArgumentList "/c mkdir NuevaCarpeta" -QorkingDirectory "d:\Documents\FIC\ASO" -PassThru
Start-Process -FilePath "notepad.exe" -WindowStyle "Maximized" -PassTh
Start-Process -FilePath  "D:\Documents\FIC\ASO\TT\TT.txt" -verb Print  -PassThru
Get-Procees -Name notep*
Wait-Process -Name notepad
Get-Process -Name notep*

Get-Process -Name notepad 
Wait-Process -Id 11568
Get-Process -Name notep*

Get-Process -Name notep*
Get-Process -Name notepad | Wait-Process