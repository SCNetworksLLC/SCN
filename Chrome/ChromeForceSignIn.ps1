$Path = "HKLM:\SOFTWARE\Policies\Google\Chrome"
$Name = "BrowserSignin"
$Value = "0x00000002"
$Type = "Dword"

if (Test-Path $Path) {
    Remove-Item -Path $Path -Force -Recurse
    New-Item -Path $Path -Force 
    Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value 
} else {
    New-Item -Path $Path -Force 
    Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value 
}

$Path1 = "HKLM:\SOFTWARE\Policies\Google\Chrome"
$Name1 = "CloudAPAuthEnabled"
$Value1 = "0x00000001"
$Type1 = "Dword"

if (Test-Path $Path1) {
    Set-ItemProperty -Path $Path1 -Name $Name1 -Type $Type1 -Value $Value1
}

$Path2 = "HKLM:\SOFTWARE\Policies\Google\Chrome"
$Name2 = "BackgroundModeEnabled"
$Value2 = "0x00000000"
$Type2 = "Dword"

if (Test-Path $Path1) {
    Set-ItemProperty -Path $Path2 -Name $Name2 -Type $Type2 -Value $Value2
}