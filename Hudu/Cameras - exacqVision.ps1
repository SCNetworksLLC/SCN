# PowerShell Script to Inventory Cameras from exacqVision and Update Hudu

#region Configuration
# Define Hudu API Information
$huduAPIKey = "{{huduAPIKey}}" # Hudu API Key
$huduBaseURL = "https://scnetworks.huducloud.com/api/v1"
$huduCompanyName = "{{cf_organization}}" # Hudu Company Name where assets will be stored
$assetLayoutID = "17"  # Name of the asset layout in Hudu

# Define the XML folder Path for exacqVision
$exacqVisionXmlFolder = "C:\Program Files\exacqVision\Server"  # Update with your actual file path

# Define the Host Name
$exacqVisionHostName = $($env:COMPUTERNAME)

#endregion Configuration

#region Validate Data
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Ensure the company name is set before proceeding
if ([string]::IsNullOrWhiteSpace($huduCompanyName)) {
    Write-Output "Company name not set. Exiting"
    Exit 1
}
#endregion Validate Data

#region Get Hudu Information
# Create API request headers
$headers = @{
    "X-API-KEY" = $HuduAPIKey
}

# Get company information from Hudu
$companyInformation = (Invoke-RestMethod -Uri "$huduBaseURL/companies?page_size=500" -Headers $headers -Method Get).companies

# Find the company ID based on the provided company name
$huduCompanyID = ($companyInformation | Where-Object {$_.name -eq $huduCompanyName}).id

# Exit if the company isn't found
if ([string]::IsNullOrWhiteSpace($huduCompanyID)) {
    Write-Output "Company $huduCompanyName not found in Hudu. Exiting"
    Exit 1
}
#endregion Get Hudu Information

#region Gather Hudu Assets
# Get existing assets from Hudu for the specified company and layout
$existingAssets = (Invoke-RestMethod -Uri "$huduBaseURL/assets?company_id=$huduCompanyID&asset_layout_id=$assetLayoutID&archived=false&page_size=500" -Headers $headers -Method Get).assets

# Extract relevant custom fields for easy comparison later
foreach ($item in $existingAssets) {
    $item | Add-Member -MemberType NoteProperty -Name "ScriptFields" -Value ([PSCustomObject]@{
        Name = $item.name
        SerialNumber = ($item.fields | Where-Object { $_.label -eq "Serial Number" }).value
        Model = ($item.fields | Where-Object { $_.label -eq "Model" }).value
        IPAddress = ($item.fields | Where-Object { $_.label -eq "IP Address" }).value
        FirmwareVersion = ($item.fields | Where-Object { $_.label -eq "Firmware Version" }).value
        MacAddress = ($item.fields | Where-Object { $_.label -eq "MAC Address" }).value
        Host = ($item.fields | Where-Object { $_.label -eq "Host" }).value
    })
}

#endregion Gather Hudu Assets

#region Gather Camera Information
# Get all XML files in the directory
$xmlFiles = Get-ChildItem -Path $exacqVisionXmlFolder -Filter "*.xml"  # Retrieves all XML files

# Function to load XML with a corrected declaration if needed
function Get-XmlData {
    param ([string]$filePath)

    Try {
        # Try loading the XML normally
        [xml]$xmlData = Get-Content $filePath -ErrorAction Stop
        return $xmlData
    } Catch {
        # Read file lines to check the first line
        $lines = Get-Content $filePath
        if ($lines.Count -gt 0 -and $lines[0] -match '^<\?xml\s*\?>$') {
            # Fix the XML declaration in-memory without modifying the file
            $lines[0] = '<?xml version="1.0" encoding="UTF-8"?>'
            $fixedXml = $lines -join "`r`n"

            Try {
                [xml]$xmlData = $fixedXml
                return $xmlData
            } Catch {
                Write-Host "Failed to parse XML even after in-memory fix. Skipping file..."
                return $null  # Return null to indicate failure for this file
            }
        } Else {
            Write-Host "XML declaration is not the issue for $($filePath). Skipping file..."
            return $null  # Return null to indicate failure for this file
        }
    }
}

# Initialize an empty array to hold the combined device data
$allVMSDevices = @()

# Process each XML file
foreach ($item in $xmlFiles) {
    $xmlData = Get-XmlData -filePath $item.FullName

    # Extract brand from <Devices> element
    $brand = $xmlData.eDVR.Devices.Description

    # Extract devices and add them to the combined list
    $devices = $xmlData.eDVR.Devices.Device | ForEach-Object {
        if ($_.ipAddress -and ($_.Video.Input | Select-Object -First 1).Name) {
            if ($_.Serial) {
                $serialNumber = $_.Serial -replace "[:\-]", "" # Remove colons and dashes from the Serial/MAC
            } else {
                $serialNumber = "$($exacqVisionHostName)-$($_.number)"
            }

            #Removes White Spaces and Consecutive Spaces
            $name = $(($_.Video.Input | Select-Object -First 1).Name).Trim() -replace '\s+', ' '
            
            [PSCustomObject]@{
                Name = $name
                Model = "$brand $($_.Name)"
                IPAddress =  [regex]::Match($_.ipAddress, '\d+\.\d+\.\d+\.\d+').Value #Removed any kind of address such as rtsp: or /upd
                FirmwareVersion = $_.Firmware
                SerialNumber = $serialNumber
                MACAddress = $serialNumber
                Host = $exacqVisionHostName
            }
        }

        if ($name) {Remove-Variable name}
        if ($serialNumber) {Remove-Variable serialNumber}
    }
    
    # Add the extracted devices to the allDevices array
    $allVMSDevices += $devices
}

if ($allVMSDevices) {
    Write-Host "Fetched $($allVMSDevices.count) Devices"
} else {
    Write-Host "Fetched 0 Devices. Exiting script."
    exit 1
}

#endregion Gather Camera Information

#region Process Assets
# Process each camera and compare with existing Hudu data
foreach ($item in $allVMSDevices) {
    #Check to make sure camera name exists
    if ($item.Name) {
        $existingHuduAsset = $existingAssets | Where-Object {$_.ScriptFields.SerialNumber -eq $item.SerialNumber -and $_.ScriptFields.Host -eq $item.Host}

        # Prepare camera data for comparison and update
        $itemData = @{
            name = $item.Name
            serial_number = $item.serialNumber
            model = $item.Model
            ip_address = $item.IpAddress
            mac_address = $item.MacAddress
            firmware_version = $item.FirmwareVersion
            host = $item.Host
        }
    
        # If the camera exists in Hudu, compare and update if data has changed
        if ($existingHuduAsset) {
            $existingHuduData = [PSCustomObject]@{
                name = $existingHuduAsset.Name
                serial_number = $existingHuduAsset.ScriptFields.SerialNumber
                model = $existingHuduAsset.ScriptFields.Model
                ip_address = $existingHuduAsset.ScriptFields.IpAddress
                mac_address = $existingHuduAsset.ScriptFields.MacAddress
                firmware_version = $existingHuduAsset.ScriptFields.FirmwareVersion
                host = $existingHuduAsset.ScriptFields.Host
            }
    
            # Compare data and update Hudu if necessary
            if (Compare-Object ([PSCustomObject]$itemData) $existingHuduData -Property name, serial_number, model, ip_address, mac_address, firmware_version) {
                $itemData.Remove('name')
    
                $asset = [ordered]@{asset = [ordered]@{} }
                $asset.asset.add('name', $item.Name)
                $asset.asset.add('custom_fields', @($itemData))
    
                $body = $asset | ConvertTo-Json -Depth 10
    
                # Perform the update API call
                Invoke-RestMethod -Uri "$huduBaseURL/companies/$huduCompanyID/assets/$($existingHuduAsset.id)" -Headers $headers -Method Put -Body $body -ContentType "application/json"
    
                Write-Host "Updated Camera: $($item.Name)"
            }
        } else {
            $itemData.Remove('name')
    
            $asset = [ordered]@{asset = [ordered]@{} }
            $asset.asset.add('name', $item.Name)
            $asset.asset.add('asset_layout_id', $assetLayoutID)
            $asset.asset.add('custom_fields', @($itemData))
    
            $body = $asset | ConvertTo-Json -Depth 10
    
            # Perform the add API call
            Invoke-RestMethod -Uri "$huduBaseURL/companies/$huduCompanyID/assets" -Headers $headers -Method Post -Body $body -ContentType "application/json"
    
            Write-Host "Added Camera: $($item.Name)"
        }
    }
}



#region Archive Assets
# Fetch all existing assets of the defined layout after everything has been updated
$existingAssets = (Invoke-RestMethod -Uri "$huduBaseURL/assets?company_id=$huduCompanyID&asset_layout_id=$assetLayoutID&archived=false&page_size=500" -Headers $headers -Method Get).assets

# Delete cameras from Hudu if they no longer exist in the VMS
foreach ($item in $existingAssets) {
    $item | Add-Member -MemberType NoteProperty -Name "ScriptFields" -Value ([PSCustomObject]@{
        Name = $item.name
        SerialNumber = ($item.fields | Where-Object { $_.label -eq "Serial Number" }).value
        Model = ($item.fields | Where-Object { $_.label -eq "Model" }).value
        IPAddress = ($item.fields | Where-Object { $_.label -eq "IP Address" }).value
        FirmwareVersion = ($item.fields | Where-Object { $_.label -eq "Firmware Version" }).value
        MacAddress = ($item.fields | Where-Object { $_.label -eq "MAC Address" }).value
        Host = ($item.fields | Where-Object { $_.label -eq "Host" }).value
    })

    if ($item.ScriptFields.SerialNumber -notin $allVMSDevices.SerialNumber -and $item.ScriptFields.host -eq $exacqVisionHostName) {
        Invoke-RestMethod -Uri "$huduBaseURL/companies/$huduCompanyID/assets/$($item.id)/archive" -Headers $headers -Method Put
        Write-Host "Archived Camera: $($item.name) $($item.ScriptFields.serialNumber) $($item.ScriptFields.MacAddress)"
    }
}
#endregion Archive Assets


Write-Host "Sync completed."
#endregion Process Assets