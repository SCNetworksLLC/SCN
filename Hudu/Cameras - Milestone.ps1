# PowerShell Script to Inventory Cameras from Milestone and Update Hudu
# Create HUDU Basic User in Milestone
# Create new role in Milestone Called HUDU with Overall Security -> Cameras -> Allow Read Checked
# Uncheck Allow Smart Client Login from the Role
# Add HUDU user to HUDU Role
# Delete the HUDU View Group
# Set Password in Level for the new Milestone User

#region Configuration
# Define Hudu API Information
$huduAPIKey = "{{huduAPIKey}}" # Hudu API Key
$huduBaseURL = "https://scnetworks.huducloud.com/api/v1"
$huduCompanyName = "{{cf_organization}}" # Hudu Company Name where assets will be stored
$assetLayoutID = "17"  # Name of the asset layout in Hudu
$huduMilestoneCred = "{{cf_xprotectcredentials}}" # Milestone HUDU Password

# Milestone XProtect Configuration
$milestoneFQDN = "$($env:COMPUTERNAME).$((Get-WmiObject Win32_ComputerSystem).Domain)"

#endregion Configuration

#region Validate Data
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

#region Check Milestone Tools
# Define the module name
$moduleName = "MilestonePSTools"

# Check if the module is installed, and attempt installation if missing
if (-not (Get-Module -ListAvailable -Name $moduleName)) {
    Write-Host "$moduleName not found. Attempting to install..."

    try {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop
        Install-Module -Name $moduleName -AllowClobber -Force -ErrorAction Stop
        Write-Host "$moduleName successfully installed."
    }
    catch {
        Write-Host "Failed to install $moduleName. Exiting script."
        $_
        exit 1
    }
}

# Import the module after ensuring it's available
try {
    Import-Module -Name $moduleName -ErrorAction Stop
    Write-Host "$moduleName imported successfully."
}
catch {
    Write-Host "Failed to import $moduleName. Exiting script."
    $_
    exit 1
}

Write-Host "Module check complete. Continuing script..."
#endregion Check Milestone Tools

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
    })
}

#endregion Gather Hudu Assets

#region Gather Camera Information

$username = 'HUDU'
$password = $huduMilestoneCred | ConvertTo-SecureString -AsPlainText -Force
$credential = [PSCredential]::New($username,$password)

$connectionParams = @{ 
    ServerAddress = "https://$milestoneFQDN"
    BasicUser = $true
    Credential = $credential
    AcceptEula = $true 
    ErrorAction = 'Stop' 
}

try {
    Connect-Vms @connectionParams
}
catch {
    Write-Host "Failed to connect to the VMS. Exiting script."
    $_
    exit 1
}

# Define custom properties to extract relevant camera information
$macProperty = @{
    Name       = 'MACAddress'
    Expression = { ($_ | Get-HardwareSetting).MACAddress }
}

$ipProperty = @{
    Name       = 'IPAddress'
    Expression = { [regex]::Match($_.Address, '\d+\.\d+\.\d+\.\d+').Value }
}

$serialProperty = @{
    Name       = 'SerialNumber'
    Expression = { ($_ | Get-HardwareSetting).SerialNumber }
}

$firmwareProperty = @{
    Name       = 'FirmwareVersion'
    Expression = { ($_ | Get-HardwareSetting).FirmwareVersion }
}

# Gather cameras from Milestone VMS
$milestoneCameras = Get-VmsHardware | Where-Object {$_.Enabled} | Select-Object Name, $ipProperty, $macProperty, Model, $serialProperty, $firmwareProperty

# Disconnect from Server
Disconnect-Vms

if ($milestoneCameras) {
    Write-Host "Fetched $($milestoneCameras.count) Devices"
} else {
    Write-Host "Fetched 0 Devices. Exiting script."
    exit 1
}

#endregion Gather Camera Information

#region Process Assets
# Process each camera and compare with existing Hudu data
foreach ($item in $milestoneCameras) {
    $existingHuduAsset = $existingAssets | Where-Object {$_.ScriptFields.SerialNumber -eq $item.SerialNumber}

    # Prepare camera data for comparison and update
    $itemData = @{
        name = $item.Name
        serial_number = $item.serialNumber
        model = $item.Model
        ip_address = $item.IpAddress
        mac_address = $item.MacAddress
        firmware_version = $item.FirmwareVersion
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



#region Archive Assets
# Fetch all existing assets of the defined layout after everything has been updated
$existingAssets = (Invoke-RestMethod -Uri "$huduBaseURL/assets?company_id=$huduCompanyID&asset_layout_id=$assetLayoutID&archived=false&page_size=500" -Headers $headers -Method Get).assets

# Delete cameras from Hudu if they no longer exist in Milestone
foreach ($item in $existingAssets) {
    $item | Add-Member -MemberType NoteProperty -Name "ScriptFields" -Value ([PSCustomObject]@{
        Name = $item.name
        SerialNumber = ($item.fields | Where-Object { $_.label -eq "Serial Number" }).value
        Model = ($item.fields | Where-Object { $_.label -eq "Model" }).value
        IPAddress = ($item.fields | Where-Object { $_.label -eq "IP Address" }).value
        FirmwareVersion = ($item.fields | Where-Object { $_.label -eq "Firmware Version" }).value
        MacAddress = ($item.fields | Where-Object { $_.label -eq "MAC Address" }).value
    })

    if ($item.ScriptFields.SerialNumber -notin $milestoneCameras.SerialNumber) {
        Invoke-RestMethod -Uri "$huduBaseURL/companies/$huduCompanyID/assets/$($item.id)/archive" -Headers $headers -Method Put
        Write-Host "Archived Camera: $($item.name) $($item.ScriptFields.serialNumber) $($item.ScriptFields.MacAddress)"
    }
}
#endregion Archive Assets


Write-Host "Sync completed."
#endregion Process Assets