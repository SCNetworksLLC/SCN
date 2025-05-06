if (!(Test-Path "HKLM:\SOFTWARE\Dell\DellOptimizer\Features")) {
    Write-Warning "Optimizer Not Installed"
    Exit 1
}

If (((Get-ItemProperty -Path "HKLM:\SOFTWARE\Dell\DellOptimizer\Features" -Name "Network").Network) -eq 'false'){
    Write-Output "Compliant"  
} else {
    Write-Warning "Not Compliant"
    Exit 1
}

If (((Get-ItemProperty -Path "HKLM:\SOFTWARE\Dell\DellOptimizer\Features" -Name "Applications").Applications) -eq 'false'){
    Write-Output "Compliant"  
} else {
    Write-Warning "Not Compliant"
    Exit 1
}

If (((Get-ItemProperty -Path "HKLM:\SOFTWARE\Dell\DellOptimizer\Features" -Name "Audio").Audio) -eq 'false'){
    Write-Output "Compliant"  
} else {
    Write-Warning "Not Compliant"
    Exit 1
}

If (((Get-ItemProperty -Path "HKLM:\SOFTWARE\Dell\DellOptimizer\Features" -Name "Power").Power) -eq 'false'){
    Write-Output "Compliant"  
} else {
    Write-Warning "Not Compliant"
    Exit 1
}

If (((Get-ItemProperty -Path "HKLM:\SOFTWARE\Dell\DellOptimizer\Features" -Name "PresenceDetection").PresenceDetection) -eq 'false'){
    Write-Output "Compliant"  
} else {
    Write-Warning "Not Compliant"
    Exit 1
}

Exit 0