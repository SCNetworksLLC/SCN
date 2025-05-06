Function GetProgramOutput([string]$exe, [string]$arguments)
{
    $process = New-Object -TypeName System.Diagnostics.Process
    $process.StartInfo.FileName = $exe
    $process.StartInfo.Arguments = $arguments

    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    $process.Start()

    $output = $process.StandardOutput.ReadToEnd()   
    $err = $process.StandardError.ReadToEnd()

    $process.WaitForExit()

    $output
    #$err
}


if (Test-Path "C:\Program Files\Dell\DellOptimizer\do-cli.exe") {
    $exe = "C:\Program Files\Dell\DellOptimizer\do-cli.exe"

    $arguments1 = '/get -name=ProximitySensor.WalkAwayLock'
    $runResult1 = (GetProgramOutput $exe $arguments1)
    if ($runResult1[-1] -like "*Value: True*") {
        Write-Warning "Not Compliant"
        Exit 1
    } else {
        Write-Output "Compliant"
    }

    $arguments2 = '/get -name=Network.State'
    $runResult2 = (GetProgramOutput $exe $arguments2)
    if ($runResult2[-1] -like "*Value: True*") {
        Write-Warning "Not Compliant"
        Exit 1
    } else {
        Write-Output "Compliant"
    }

    $arguments3 = '/get DellOptimizerConfiguration.Suggestions'
    $runResult3 = (GetProgramOutput $exe $arguments3)
    if ($runResult3[-1] -like "*Value: True*") {
        Write-Warning "Not Compliant"
        Exit 1
    } else {
        Write-Output "Compliant"
    }

    $arguments4 = '/get -name=BatteryExtender.State'
    $runResult4 = (GetProgramOutput $exe $arguments4)
    if ($runResult4[-1] -like "*Value: True*") {
        Write-Warning "Not Compliant"
        Exit 1
    } else {
        Write-Output "Compliant"
    }

    $arguments5 = '/get -name=DynamicCharge.State'
    $runResult5 = (GetProgramOutput $exe $arguments5)
    if ($runResult5[-1] -like "*Value: True*") {
        Write-Warning "Not Compliant"
        Exit 1
    } else {
        Write-Output "Compliant"
    }

    $arguments6 = '/get -name=Audio.State'
    $runResult6 = (GetProgramOutput $exe $arguments6)
    if ($runResult6[-1] -like "*Value: True*") {
        Write-Warning "Not Compliant"
        Exit 1
    } else {
        Write-Output "Compliant"
    }

    $arguments7 = '/get -name=AppPerformance.State'
    $runResult7 = (GetProgramOutput $exe $arguments7)
    if ($runResult7[-1] -like "*Value: True*") {
        Write-Warning "Not Compliant"
        Exit 1
    } else {
        Write-Output "Compliant"
    }
} else {
    Write-Output "Compliant - Optimizer not Installed"
}