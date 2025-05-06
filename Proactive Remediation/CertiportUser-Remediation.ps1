$Users = Get-LocalUser

if ($users.name -notcontains "certiport") {
    $password = ConvertTo-SecureString -String "Cert@2020!" -AsPlainText -Force
    New-LocalUser -Name "certiport" -Password $password -PasswordNeverExpires
    Add-LocalGroupMember -Group "Administrators" -Member "certiport"
}