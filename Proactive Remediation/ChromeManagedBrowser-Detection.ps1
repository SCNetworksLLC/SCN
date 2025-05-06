$Path = "HKLM:\SOFTWARE\Policies\Google\Chrome"
$Name = "CloudManagementEnrollmentToken"
$Value = "9436b9f7-251b-420e-ae14-c0886707b63a"

Try {
    $Registry = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop | Select-Object -ExpandProperty $Name
    If ($Registry -eq $Value){
        Write-Output "Compliant"
        Exit 0
    } 
    Write-Warning "Not Compliant"
    Exit 1
} 
Catch {
    Write-Warning "Not Compliant"
    Exit 1
}