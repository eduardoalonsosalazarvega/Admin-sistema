# Verificar si se ejecuta como administrador
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Este script debe ejecutarse como Administrador" -ForegroundColor Red
    exit 1
}

Write-Host "Fijando IP estática para Servidor FTP" -ForegroundColor Cyan
New-NetIPAddress -IPAddress "192.168.0.17" -InterfaceAlias "Ethernet 2" -PrefixLength 24

# Instalar IIS y el servicio FTP si no están instalados
Write-Host "Verificando instalación de IIS y FTP..."
$features = Get-WindowsFeature
if (-not ($features | Where-Object { $_.Name -eq "Web-Ftp-Server" -and $_.InstallState -eq "Installed" })) {
    Write-Host "Instalando IIS y FTP..."
    Install-WindowsFeature Web-Server, Web-Ftp-Server -IncludeManagementTools
}

# Crear grupos de usuarios FTP
$groups = @("reprobados", "recursadores", "ftpusers")
foreach ($group in $groups) {
    if (-not (Get-LocalGroup -Name $group -ErrorAction SilentlyContinue)) {
        New-LocalGroup -Name $group
        Write-Host "Grupo $group creado."
    }
}

# Crear estructura de carpetas FTP
$FTP_ROOT = "C:\FTP"
$PUBLIC_DIR = "$FTP_ROOT\publica"
$USERS_DIR = "$FTP_ROOT\users"
$GROUPS_DIR = "$FTP_ROOT\grupos"

$folders = @($FTP_ROOT, $PUBLIC_DIR, $USERS_DIR, "$GROUPS_DIR\reprobados", "$GROUPS_DIR\recursadores")
foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        New-Item -Path $folder -ItemType Directory | Out-Null
        Write-Host "Directorio $folder creado."
    }
}

# Configurar permisos de seguridad
icacls $PUBLIC_DIR /grant "ftpusers:(OI)(CI)M"
icacls "$GROUPS_DIR\reprobados" /grant "reprobados:(OI)(CI)M"
icacls "$GROUPS_DIR\recursadores" /grant "recursadores:(OI)(CI)M"

# Función para agregar un usuario FTP
function Agregar-Usuario {
    param (
        [string]$FTP_USER,
        [string]$FTP_GROUP
    )
    if (-not (Get-LocalUser -Name $FTP_USER -ErrorAction SilentlyContinue)) {
        $password = Read-Host "Ingrese la contraseña para el usuario" -AsSecureString
        New-LocalUser -Name $FTP_USER -Password $password -PasswordNeverExpires -UserMayNotChangePassword
        Add-LocalGroupMember -Group $FTP_GROUP -Member $FTP_USER
        Add-LocalGroupMember -Group "ftpusers" -Member $FTP_USER
        New-Item -Path "$USERS_DIR\$FTP_USER" -ItemType Directory | Out-Null
        icacls "$USERS_DIR\$FTP_USER" /grant "$FTP_USER:(OI)(CI)M"
        Write-Host "Usuario $FTP_USER agregado correctamente."
    } else {
        Write-Host "El usuario $FTP_USER ya existe." -ForegroundColor Red
    }
}

# Función para cambiar de grupo a un usuario FTP
function Cambiar-Grupo {
    param (
        [string]$FTP_USER
    )
    $currentGroups = (Get-LocalGroup | Where-Object { Get-LocalGroupMember -Group $_.Name | Where-Object Name -Like $FTP_USER }).Name
    if ($currentGroups -contains "reprobados") {
        $newGroup = "recursadores"
    } elseif ($currentGroups -contains "recursadores") {
        $newGroup = "reprobados"
    } else {
        Write-Host "El usuario no tiene grupo asignado." -ForegroundColor Red
        return
    }
    Remove-LocalGroupMember -Group $currentGroups -Member $FTP_USER
    Add-LocalGroupMember -Group $newGroup -Member $FTP_USER
    Write-Host "Usuario $FTP_USER ahora pertenece a $newGroup."
}

# Menú de administración
function Mostrar-Menu {
    while ($true) {
        Write-Host "===== MENÚ DE ADMINISTRACIÓN FTP ====="
        Write-Host "1) Agregar un usuario FTP"
        Write-Host "2) Cambiar de grupo a un usuario FTP"
        Write-Host "3) Salir"
        $opcion = Read-Host "Seleccione una opción"
        switch ($opcion) {
            "1" {
                $usuario = Read-Host "Ingrese el nombre del usuario"
                $grupo = Read-Host "Ingrese el grupo (reprobados, recursadores)"
                Agregar-Usuario -FTP_USER $usuario -FTP_GROUP $grupo
            }
            "2" {
                $usuario = Read-Host "Ingrese el nombre del usuario"
                Cambiar-Grupo -FTP_USER $usuario
            }
            "3" {
                Write-Host "Saliendo..."
                exit
            }
            default {
                Write-Host "Opción no válida, intente de nuevo." -ForegroundColor Red
            }
        }
    }
}

# Mostrar menú
Mostrar-Menu
