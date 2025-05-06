# PowerShell Script to Inventory Printers, Gather SNMP Data, and Update Hudu

# Define Hudu API Information
$huduAPIKey = "{{huduAPIKey}}" # Hudu API Key
$huduBaseURL = "https://scnetworks.huducloud.com/api/v1"
$huduCompanyName = "{{cf_organization}}" # Hudu Company Name where assets will be stored
$assetLayoutID = "24"  # Name of the asset layout in Hudu

if ([string]::IsNullOrWhiteSpace($huduCompanyName)) {
    Write-Output "Company name not set. Exiting"
    Exit 1
}

# Create API request headers
$headers = @{
    "X-API-KEY" = $HuduAPIKey
}

# Get company information from Hudu
$companyInformation = (Invoke-RestMethod -Uri "$huduBaseURL/companies?page_size=500" -Headers $headers -Method Get).companies

# Find the company ID based on the provided company name
$huduCompanyID = ($companyInformation | Where-Object {$_.name -eq $huduCompanyName}).id

if ([string]::IsNullOrWhiteSpace($huduCompanyID)) {
    Write-Output "Company $huduCompanyName not found in Hudu. Exiting"
    Exit 1
}

# Function to Get Printer SNMP Data using OlePrn.OleSNMP
function Get-SNMPData {
    param (
        [string]$IP,
        [string]$OID
    )
    try {
        $SNMP = New-Object -ComObject "OlePrn.OleSNMP"
        $SNMP.Open($IP, "public", 2, 500)
        $result = $SNMP.Get($OID)
        $SNMP.Close()
        return $result
    }
    catch {
        Write-Warning "Failed to retrieve SNMP data from $IP for OID $OID"
        return "Error"
    }
}

# Get Printer List from Local Print Server
$printers = Get-Printer | Where-Object { $_.PortName -match "\d+\.\d+\.\d+\.\d+" }

#Check to make sure the portname doesn't include other characters
foreach ($item in $printers) {
    if ($item.PortName -match '\d+\.\d+\.\d+\.\d+') {
        $item.PortName = $Matches[0]
    }
}

# Initialize Printer Inventory Array
$printerInventory = @()

# Loop Through Printers and Collect Data
foreach ($item in $printers) {
    $IP = $item.PortName
    Write-Output "Querying printer: $($item.Name) at $IP..."

    # Define SNMP OIDs for Manufacturer, Model, and Serial Number
    $manufacturerOID = ".1.3.6.1.2.1.43.8.2.1.14.1.1"
    $manufacturerOIDSec = ".1.3.6.1.2.1.1.1.0"
    $modelOID = ".1.3.6.1.2.1.25.3.2.1.3.1"
    $serialOID = ".1.3.6.1.2.1.43.5.1.1.17.1"

    # Query SNMP for Manufacturer, Model, and Serial Number
    $manufacturer = Get-SNMPData -IP $IP -OID $manufacturerOID
    if ($manufacturer -eq 'Error' -or [string]::IsNullOrWhiteSpace($manufacturer)) {
        $manufacturer = Get-SNMPData -IP $IP -OID $manufacturerOIDSec
    }
    
    if ($manufacturer -like "*KYOCERA*") {
        $manufacturer = 'KYOCERA'
    }
    $model = Get-SNMPData -IP $IP -OID $modelOID
    $serialNumber = Get-SNMPData -IP $IP -OID $serialOID

    # Add printer details to the inventory array
    $printerInventory += [PSCustomObject]@{
        Name          = $item.Name
        IPAddress     = $IP
        Manufacturer  = $manufacturer
        Model         = ($model -replace [regex]::Escape($manufacturer), "").Trim()
        SerialNumber  = $serialNumber
        DriverName    = $item.DriverName
        Comments      = $item.Comment
        Shared        = $item.Shared
        ShareName     = $item.ShareName
        Location      = $item.Location
    }
}

#Get existing assets in Hudu for the company
$existingAssets = (Invoke-RestMethod -Uri "$huduBaseURL/assets?company_id=$huduCompanyID&asset_layout_id=$assetLayoutID&archived=false&page_size=500" -Headers $headers -Method Get).assets

# Loop Through Printers and Update/Add in Hudu
foreach ($item in $printerInventory) {
    # Define fields to compare to track changes
    $compareFields = @{
        IPAddress = "IP Address"
        DriverName = "Driver Name"
        Comments = "Comments"
        Shared = "Shared"
        ShareName = "Share Name"
        Location = "Location"
    }

    # Create custom fields object for Hudu
    $customFields = @(@{
        "ip_address" = $item.IPAddress
        "driver_name" = $item.DriverName
        "comments" = $item.Comment
        "shared" = ($item.Shared).ToString()
        "share_name" = $item.ShareName
        "location" = $item.Location
    })

    if (-not ($item.manufacturer -eq 'Error' -or [string]::IsNullOrWhiteSpace($item.manufacturer))) {
        $customFields[0]["manufacturer"] = $item.Manufacturer
        $compareFields["Manufacturer"] = "Manufacturer"
    }

    if (-not ($item.model -eq 'Error' -or [string]::IsNullOrWhiteSpace($item.model))) {
        $customFields[0]["model"] = $item.Model
        $compareFields["Model"] = "Model"
    }

    if (-not ($item.serialNumber -eq 'Error' -or [string]::IsNullOrWhiteSpace($item.serialNumber))) {
        $customFields[0]["serial_number"] = $item.SerialNumber
        $compareFields["SerialNumber"] = "Serial Number"
    }

    # Check if the asset already exists in Hudu
    $huduItem = $existingAssets | Where-Object {$_.name -eq $item.name}

    if ($huduItem) {
        $huduItemFields = $huduItem.fields
        $updateItem = $false

        # Compare fields to determine if an update is needed
        foreach ($field in $compareFields.GetEnumerator()) {
            $huduValue = ($huduItemFields | Where-Object { $_.label -eq $field.value }).value
            $localValue = $item.($field.name)
        
            if (-not ([string]::IsNullOrWhiteSpace($huduValue) -and [string]::IsNullOrWhiteSpace($localValue)) -and $huduValue -ne $localValue) {
                $updateItem = $true
            }
        }
        
        # Update the asset in Hudu if changes were found
        if ($updateItem) {
            Write-Output "Updating Asset $($item.name)"

            #Create the body for the request
            $asset = [ordered]@{asset = [ordered]@{} }
            $asset.asset.add('name', $item.Name)
            $asset.asset.add('custom_fields', $customFields)

            #Convert to JSON for the request
            $body = $asset | ConvertTo-Json -Depth 10

            Invoke-RestMethod -Uri "$huduBaseURL/companies/$huduCompanyID/assets/$($huduItem.id)" -Headers $headers -Method Put -Body $body -ContentType "application/json"
        }
    } else {
        # Create a new asset in Hudu if it doesn’t exist
        Write-Output "Creating Asset $($item.name)"

        #Create the body for the request
        $asset = [ordered]@{asset = [ordered]@{} }
        $asset.asset.add('name', $item.Name)
        $asset.asset.add('asset_layout_id', $assetLayoutID)
        #$asset.asset.add('primary_serial', $item.SerialNumber)
        $asset.asset.add('custom_fields', $customFields)

        #Convert to JSON for the request
        $body = $asset | ConvertTo-Json -Depth 10

        Invoke-RestMethod -Uri "$huduBaseURL/companies/$huduCompanyID/assets" -Headers $headers -Method Post -Body $body -ContentType "application/json"
    }
}

# Fetch all existing assets of the defined layout after everything has been updated
$existingAssets = (Invoke-RestMethod -Uri "$huduBaseURL/assets?company_id=$huduCompanyID&asset_layout_id=$assetLayoutID&archived=false&page_size=500" -Headers $headers -Method Get).assets

# Archive Assets in Hudu if they don't exist in the source
if ($printerInventory) {
    foreach ($item in $existingAssets) {
        if ($item.name -notin $printerInventory.name) {
            Write-Output "Archiving Asset $($item.name)"
            Invoke-RestMethod -Uri "$huduBaseURL/companies/$huduCompanyID/assets/$($item.id)/archive" -Headers $headers -Method Put
        }
    }
}

Write-Output "Printer inventory has been updated in Hudu."
