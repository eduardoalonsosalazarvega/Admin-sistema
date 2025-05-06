$Password = "Eduardo123*"

[byte[]]$Logonhours = @(0,0,0,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255)
$SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force


New-ADUser -Name "Eduprueba" -SamAccountName "Eduprueba" -UserPrincipalName "$Eduprueba@eduardoguapo.com" -ChangePasswordAtLogon $false -AccountPassword $SecurePassword -Path "OU=eduardos,DC=EDUARDOGUAPO,DC=COM" -Enabled $true -OtherAttributes @{logonHours = $Logonhours}