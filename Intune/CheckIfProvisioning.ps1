$details = Get-ComputerInfo

if ($details.CsUserName -match "defaultUser") { 
    Write-Output("Device is pre-provisioning") 
}
else { 
    Write-Output("User is logged on") 
}