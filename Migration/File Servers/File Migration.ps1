#Clean Up File Shares that Have been accessed or used as Mac Home Drives in the Past
$users = Get-ChildItem

foreach ($item in $users.Fullname) {
    $childItems = Get-ChildItem $item -Force

    foreach ($childItem in $childItems) {
        if ($childItem.name -eq ".Spotlight-V100") {
            write-host $childItem.name
            Robocopy D:\StudentData\temp $childItem.FullName /mir
            Remove-Item $childItem.FullName -Force -Recurse
        }
        if ($childItem.name -eq "Library") {
            write-host $childItem.name
            Robocopy D:\StudentData\temp $childItem.FullName /mir
            Remove-Item $childItem.FullName -Force -Recurse
        }
        if ($childItem.name -eq "Applications") {
            write-host $childItem.name
            Robocopy D:\StudentData\temp $childItem.FullName /mir
            Remove-Item $childItem.FullName -Force -Recurse
        }
        if ($childItem.name -eq ".Trash") {
            write-host $childItem.name
            Robocopy D:\StudentData\temp $childItem.FullName /mir
            Remove-Item $childItem.FullName -Force -Recurse
        }
        if ($childItem.name -eq ".TemporaryItems") {
            write-host $childItem.name
            Robocopy D:\StudentData\temp $childItem.FullName /mir
            Remove-Item $childItem.FullName -Force -Recurse
        }
        if ($childItem.name -eq "Public") {
            write-host $childItem.name
            Robocopy D:\StudentData\temp $childItem.FullName /mir
            Remove-Item $childItem.FullName -Force -Recurse
        }
        if ($childItem.name -eq "Movies") {
            write-host $childItem.name
            Robocopy D:\StudentData\temp $childItem.FullName /mir
            Remove-Item $childItem.FullName -Force -Recurse
        }
        if ($childItem.name -eq "Favorites") {
            write-host $childItem.name
            Robocopy D:\StudentData\temp $childItem.FullName /mir
            Remove-Item $childItem.FullName -Force -Recurse
        }
        if ($childItem.name -eq ".cups") {
            write-host $childItem.name
            Robocopy D:\StudentData\temp $childItem.FullName /mir
            Remove-Item $childItem.FullName -Force -Recurse
        }
        if ($childItem.name -eq "cal") {
            write-host $childItem.name
            Robocopy D:\StudentData\temp $childItem.FullName /mir
            Remove-Item $childItem.FullName -Force -Recurse
        }
        if ($childItem.name -eq ".mcxlc") {
            write-host $childItem.name
            Remove-Item $childItem.FullName -Force
        }
        #Remove Emtpy Folders
        if ((Get-ChildItem $childItem.FullName | Measure-Object).Count -eq 0){
            write-host $childItem.name
            pause
            Remove-Item $childItem.FullName -Force -Recurse
        }
    }
    if (($childItems | Measure-Object).Count -eq 0){
        write-host $item
        pause
        Remove-Item $item -Force
    } 
}

#Export Users from AD Based on OU with their username and home directory
$OUPath = 'OU=Elem Students,OU=Users,OU=Auburndale,DC=internal,DC=aubschools,DC=com'
Get-ADUser -Filter * -SearchBase $OUPath -Properties * | Select-Object SamAccountName,HomeDirectory | export-csv 'C:\temp\Students.csv' -NoTypeInformation
$OUPath = 'OU=MSHS Students,OU=Users,OU=Auburndale,DC=internal,DC=aubschools,DC=com'
Get-ADUser -Filter * -SearchBase $OUPath -Properties * | Select-Object SamAccountName,HomeDirectory | export-csv 'C:\temp\Students.csv' -Append -NoTypeInformation
$OUPath = 'OU=Staff,OU=Users,OU=Auburndale,DC=internal,DC=aubschools,DC=com'
Get-ADUser -Filter * -SearchScope OneLevel -SearchBase $OUPath -Properties * | Select-Object SamAccountName,HomeDirectory | export-csv 'C:\temp\Staff.csv' -NoTypeInformation

