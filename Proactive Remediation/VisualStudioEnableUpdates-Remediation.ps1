$Path = "HKLM:\SOFTWARE\Microsoft\VisualStudio\Setup"
$Name = "AdministratorUpdatesEnabled"
$Type = "DWORD"
$Value = 2

if (Test-Path $Path) {
    Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value 
} else {
    New-Item -Path $Path -Force 
    Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value 
}