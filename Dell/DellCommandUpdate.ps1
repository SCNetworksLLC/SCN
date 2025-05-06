#############################################################################
#If Powershell is running the 32-bit version on a 64-bit machine, we 
#need to force powershell to run in 64-bit mode .
#############################################################################
if ($env:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    if ($myInvocation.Line) {
        &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
    }else{
        &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file "$($myInvocation.InvocationName)" $args
    }
exit $lastexitcode
}

if (Test-Path "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe") {

    Start-Process "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe" -Wait -ArgumentList '/configure -autoSuspendBitLocker=enable" -silent'

    Start-Process "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe" -Wait -ArgumentList '/configure -scheduleAuto -silent'

    Start-Process "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe" -Wait -ArgumentList '/configure -scheduleAction=DownloadInstallAndNotify -silent'

    Start-Process "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe" -Wait -ArgumentList '/configure -scheduledReboot=60 -silent'

    Start-Process "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe" -Wait -ArgumentList '/configure -lockSettings=enable -silent'

    Start-Process "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe" -Wait -ArgumentList '/scan -silent'
    
}
