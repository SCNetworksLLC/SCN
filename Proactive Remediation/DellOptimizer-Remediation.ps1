If (-NOT (Test-Path 'HKLM:\SOFTWARE\Dell\DellOptimizer\Features')) {
    New-Item -Path 'HKLM:\SOFTWARE\Dell\DellOptimizer\Features' -Force | Out-Null
  }  
# Now set the value
New-ItemProperty -Path 'HKLM:\SOFTWARE\Dell\DellOptimizer\Features' -Name Network -Value 'false' -PropertyType String -Force
New-ItemProperty -Path 'HKLM:\SOFTWARE\Dell\DellOptimizer\Features' -Name Applications -Value 'false' -PropertyType String -Force 
New-ItemProperty -Path 'HKLM:\SOFTWARE\Dell\DellOptimizer\Features' -Name Audio -Value 'false' -PropertyType String -Force 
New-ItemProperty -Path 'HKLM:\SOFTWARE\Dell\DellOptimizer\Features' -Name Power -Value 'false' -PropertyType String -Force 
New-ItemProperty -Path 'HKLM:\SOFTWARE\Dell\DellOptimizer\Features' -Name PresenceDetection -Value 'false' -PropertyType String -Force 