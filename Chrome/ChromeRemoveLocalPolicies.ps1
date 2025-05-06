$Path = "HKLM:\SOFTWARE\Policies\Google\Chrome"
$Name = "BrowserSignin"
$Value = "0x00000002"
$Type = "Dword"

if (Test-Path $Path) {
    Remove-Item -Path $Path -Force -Recurse
}