try 
{
    Write-Output "Todo bien"
}
catch 
{
    write-Output "Algo lanzo una exepcion"
    Write-Output $_
}
try
{
    Start-Something -ErrorAction Stop
}
catch
{
    Write-Output "algo genero una exepcion o uso Write-Error"
    Write-Output $_
}

$comando = [System.Data.SqlClient.SqlCommand]::New(queryString, connection)
try
{
    $comando.Connection.Open()
    $comando.ExecuteNonQuery()
}
finally
{
    write-error ""Ha sido un problema con la ejecucion de la query. cerrando la conexion
    $comando.Connection.Close()
}

try
{
    Start-something -path -ErrorAction Stop
}
catch [System.IO.DirectoryNotFoundException],[System.IO.FileNotFoundException]
{
    Write-Output "El directorio o fichero ni ha sido encontrado": [$path]
}
cathc [System.IO.IOException]
{
    Write-Output "Error de ID con el archivo [$path]"
}


throw "no se puede encontrar la ruta: [$path]"
throw [System.IO.FileNotFoundException] "no se puede encontrar la ruta: [$path]"
throw [System.IO.FileNotFoundexception]::new()
throw [System.IO.FileNotFoundexception]::new("No se puede encontrar la ruta: [$path]")
throw (new-object -TypeName System.IO.FileNotfoundException)
throw (new-Object -TypeName System.IO.FileNotFoundException -ArgumentList "No se puede encontrar la ruta: [$path]")

trap
{
    Write-Output $PSItem.ToString()
}
throw [System.Exception]::new('primero')
throw [System.Exception]::new('segundo')
throw [System.Exception]::new('tercero')

# Función para realizar un backup del registro del sistema
function Backup-Registry {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$rutaBackup
    )

    # Crear la ruta de destino del backup si no existe
    if (!(Test-Path -Path $rutaBackup)) {
        New-Item -ItemType Directory -Path $rutaBackup | Out-Null
    }

    # Generar un nombre único para el archivo de backup
    $nombreArchivo = "Backup-Registry_" + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss") + ".reg"
    $rutaArchivo = Join-Path -Path $rutaBackup -ChildPath $nombreArchivo

    # Realizar el backup del registro del sistema y guardarlo en el archivo de destino
    try {
        Write-Host "Realizando backup del registro del sistema en $rutaArchivo..."
        reg export HKLM $rutaArchivo
        Write-Host "El backup del registro del sistema se ha realizado con éxito."
    }
    catch {
        Write-Host "Se ha producido un error al realizar el backup del registro del sistema: $_"
    }
}

# Escribir en el archivo de log
$logDirectory = "$env:APPDATA\RegistryBackup"
$logFile = Join-Path $logDirectory "backup-registry_log.txt"
$logEntry = "$(Get-Date) - $env:USERNAME - Backup - $backupPath"

if (!(Test-Path $logDirectory)) {
    New-Item -ItemType Directory -Path $logDirectory | Out-Null
}

Add-Content -Path $logFile -Value $logEntry

# Verificar si hay más de $backupCount backups en el directorio y eliminar los más antiguos si es necesario
$backupCount = 10
$backups = Get-ChildItem $backupDirectory -Filter *.reg | Sort-Object LastWriteTime -Descending

if ($backups.Count -gt $backupCount) {
    $backupsToDelete = $backups[$backupCount..($backups.Count - 1)]
    $backupsToDelete | Remove-Item -Force
}

$env:PSModulePath


@{
    ModuleVersion = '1.0.0'
    PowerShellVersion = '5.1'
    RootModule = 'Backup-Registry.ps1'
    Description = 'Módulo para realizar backups del registro del sistema de Windows'
    Author = 'Alice'
    FunctionsToExport = @('Backup-Registry')
}

c:\program Files\WindowsPowerShell\Modules\BackupRegistry> 1s

Get-Help  Backup-Registry
Name 
    Backup-Registry
SYNTAX 
    Backup-Registry [-rutaBackup] <string> [<commonParameters>]

ALIASES
    None
Remarks
    None

Backup-Registry -rutaBackup 'D:\tmp\Backups\Registro\'
vim .\BackUp-Registry.ps1
import-Module BackupRestry.ps1 -Force
Backup-Registry -rutaBackup 'D:\tmp\Backup\Registro\'

# Configuración de la tarea
$Time = New-ScheduledTaskTrigger -At 02:00 -Daily

# Acción de la tarea
$PS = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument `
    "-Command `"Import-Module BackupRegistry -Force; Backup-Registry -rutaBackup 'D:\tmp\Backups\Registro'`""

# Crear la tarea programada
Register-ScheduledTask -TaskName "Ejecutar Backup del Registro del Sistema" -Trigger $Time -Action $PS


Get-ScheduledTask
Unregister-ScheduledTask
get-ScheduledTask