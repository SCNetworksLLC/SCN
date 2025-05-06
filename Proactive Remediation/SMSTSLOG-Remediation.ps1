$Path = "C:\SMSTSLog"

if (Test-Path $Path) {
    Remove-Item -Path $Path -Force -Recurse
}