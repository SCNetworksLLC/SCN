$Path = "HKLM:\SOFTWARE\Policies\Google\Chrome"
$Name = "CloudManagementEnrollmentToken"
$Value = "9436b9f7-251b-420e-ae14-c0886707b63a"
$Type = "STRING"

if (Test-Path $Path) {
    Remove-Item -Path $Path -Force -Recurse
    New-Item -Path $Path -Force 
    Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value 
} else {
    New-Item -Path $Path -Force 
    Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value 
}