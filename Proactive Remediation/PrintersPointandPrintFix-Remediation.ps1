$Path = "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
$Name = "RestrictDriverInstallationToAdministrators"
$Type = "DWORD"
$Value = 0

if (Test-Path $Path) {
    Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value 
} else {
    New-Item -Path $Path -Force 
    Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value 
}