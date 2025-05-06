$Users = Get-LocalUser

if ($users.name -notcontains "certiport") {
	Write-Host "Certiport User not found"
	exit 1
} Else {
	Write-Host "Certiport User Exists"
	Exit 0
}