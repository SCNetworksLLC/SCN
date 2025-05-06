Get-ADComputer -Filter * -Properties OperatingSystem, LastLogonDate | 
    Where { $_.LastLogonDate -GT (Get-Date).AddDays(-30) }