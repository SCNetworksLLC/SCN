#Script detects the new Microsoft Teams consumer app on Windows 11.

if (Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -eq "Cisco Jabber"}) {
	Write-Host "Jabber found"
	exit 1
} Else {
	Write-Host "Jabber Not found"
	Exit 0

}