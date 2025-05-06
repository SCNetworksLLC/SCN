try{
    $MyApp = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -eq "Cisco Jabber"}
    $MyApp.Uninstall()
    Write-Host "Jabber successfully removed"

}
catch{
    Write-Error "Error removing Jabber"
}