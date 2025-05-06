$Path = "C:\SMSTSLog"


If (Test-Path $Path){
    Write-Output "Not Compliant"
    Exit 1
} else {
    Write-Warning "Compliant"
    Exit 0
}
