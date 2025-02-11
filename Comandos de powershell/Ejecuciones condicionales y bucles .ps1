$condicion = $true
if ( $condicion )
{
   Write-Output "La condicion era verdadera"

}
else
{
   Write-Output "La condicion era falsa"
}

$numero = 2
if ( $numero -ge 3)
{
    write-output "El numero [$numero] es mayor o igual que 3"
}
elseif ( $numero -lt 2)
{
    write-output "El numero [$numero] es menor o igual que 2"
}
else 
{
    write-output "El numero [$numero] es igual que 2"
}

$PSVersionTable
$mensaje + (Test-path $path) ? "path existe" : "psth no encontrado"
$mensaje

switch (3)
{
    1 {"[$_] es uno."}
    2 {"[$_] es dos."}
    3 {"[$_] es tres."}
    4 {"[$_] es cuadro."}
}

switch (3)
{
    1 {"[$_] es uno."}
    2 {"[$_] es dos."}
    3 {"[$_] es tres.";break}
    4 {"[$_] es cuadro."}
    3 {"[$_] es tres de nuevo."}

}

switch (1, 5)
{
    1 {"[$_] es uno."}
    2 {"[$_] es dos."}
    3 {"[$_] es tres."}
    4 {"[$_] es cuadro."}
    5 {"[$_] es cinco."}

}
switch ("seis")
{
    1 {"[$_] es uno.";break}
    2 {"[$_] es dos.";break}
    3 {"[$_] es tres.";break}
    4 {"[$_] es cuadro.";break}
    5 {"[$_] es cinco.";break}
    "se*" {"[$_] coincide con se*."}
     Default 
     {
     "no hay coincidencias con [$_]"}
}

switch -Wildcard ("seis")
{
    1 {"[$_] es uno.";break}
    2 {"[$_] es dos.";break}
    3 {"[$_] es tres.";break}
    4 {"[$_] es cuadro.";break}
    5 {"[$_] es cinco.";break}
    "se*" {"[$_] coincide con se*."}
     Default 
     {
     "no hay coincidencias con [$_]"}
}

$email = 'antonio.yanez@udc.es'
$email2 = 'antonio.yanez@usc.gal'
$url = 'https://www.dc.fi.udc.es/~afyanez/Docencia/2023'
switch -Regex ($url, $email, $email2)
{
    '^\w+@(udc|usc|edu)\.es|gal$' {"[$_] es una direccion de correo electronico academica"}
    '^ftp\://.*$' { "[$_] es una direccion ftp"}
    '^(http[s]?)\://.*$' {"[$_] es una direccion web,que utiliza [$($Matches[1])]"}
}


1 -eq "1.0"
"1.0" -eq 1

for (($1 = 0), ($j = 0); $i -lt 5; $i++)
{
   "`$i:$i"
   "`$j:$j"
}

for ($($i = 0;$j = 0); $i -lt 5; $($i++;$j++))
{
    "`$i:$i"
    "`$j:$j"
}

$ssoo = "freeebsd", "openbsd", "solaris", "fedora", "ubuntu", "netbsd"
foreach ($so in $ssoo)
{
    write-host $so
}

foreach ($archivo in Get-ChildItem)
{
    if ($archivo.length -ge 10KB)
    {
        write-host $archivo -> [($archivo.length)]
    }
}

$num = 0
while($num -ne 3)
{
    $num++
    write-host $num

}

$num = 0
while($num -ne 5)
{
   if ($num -eq 1) {$num = $num + 3; continue}
   $num++
    Write-Host $num
}

$valor = 5
$multiplicacion = 1
do
{
    $multiplicacion = $multiplicacion * $valor
    $valor--
}
while ($valor -gt 0)

write-host $multiplicacion

$valor = 5
$multiplicacion = 1 
do
{
    $multiplicacion = $multiplicacion * $valor
    $valor--
}
until ($valor -eq 0)
write-host $multiplicacion

$num = 10 

for($i = 2; $i -lt 10; $i++)
{
    $num = $num+$i
    if ($i -eq 5) {break}
}
write-host $num
write-host $i

$cadena = "hola,buenas tardes"
$cadena2 = "hola, buenas noches"
switch -Wildcard ($cadena, $cadena2)
{
    "hola,buenas*"{"[$_] coincide con [hola, buenas*]"}
    "hola,bue*"{"[$_] coincide con [hola,bue]"}
    "hola,*"{"[$_] coincide con [hola,*]"; break}
    "hola,buenas tardes"{"[$_]coincide con [hola,buenas tardes]"}
}

$num = 10
for ($i = 2; $i -lt 10; $i++)
{
    if ($i -eq 5) { continue}
    $num = $num+$i
}
write-host $num
write-host $i

$cadena = "hola,buenas tardes"
$cadena2 = "hola, buenas noches"
switch -Wildcard ($cadena, $cadena2)
{
    "hola,buenas*"{"[$_] coincide con [hola, buenas*]"}
    "hola,bue*"{"[$_] coincide con [hola,bue*]"; continue}
    "hola,*"{"[$_] coincide con [hola,*]"}
    "hola,buenas tardes"{"[$_]coincide con [hola,buenas tardes]"}
}


