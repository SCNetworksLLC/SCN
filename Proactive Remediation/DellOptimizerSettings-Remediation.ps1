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

$exe = "C:\Program Files\Dell\DellOptimizer\do-cli.exe"

$arguments1 = '/configure -name=ProximitySensor.WalkAwayLock -value=false'
$runResult1 = (GetProgramOutput $exe $arguments1)

$arguments2 = '/configure -name=Network.State -value=false'
$runResult2 = (GetProgramOutput $exe $arguments2)

$arguments3 = '/configure -name=DellOptimizerConfiguration.Suggestions -value=false'
$runResult3 = (GetProgramOutput $exe $arguments3)

$arguments4 = '/configure -name=BatteryExtender.State -value=false'
$runResult4 = (GetProgramOutput $exe $arguments4)

$arguments5 = '/configure -name=DynamicCharge.State -value=false'
$runResult5 = (GetProgramOutput $exe $arguments5)

$arguments6 = '/configure -name=Audio.State -value=false'
$runResult6 = (GetProgramOutput $exe $arguments6)

$arguments7 = '/configure -name=AppPerformance.State -value=false'
$runResult7 = (GetProgramOutput $exe $arguments7)