# Load required module
Import-Module PnP.PowerShell

# Define constants
$tenant = "xxxxx.onmicrosoft.com"                # Your tenant name
$thumbprint_id = "THUMBPRINT_ID"                 # Certificate thumbprint
$clientId = "CLIENT_ID"                          # Azure AD App Client ID
$tenantUrl = "https://xxxxx.sharepoint.com"      # SharePoint Online root URL
$restorePath = "UPDATE_PATH"                     # Path where output files will be saved

# Create restore folder if it doesn't exist
if (!(Test-Path -Path $restorePath)) {
    New-Item -ItemType Directory -Path $restorePath -Force
}
Set-Location -Path $restorePath

# Import site list from CSV
$csvFile = "UPDATE_PATH"   # Path to CSV containing site URLs or paths
$sites = Import-Csv -Path $csvFile

# Optional: Define date range for filtering deleted items
#$date1 = Get-Date("2025-09-19 09:00")
#$date2 = Get-Date("2025-09-10 08:00")

# Loop through each site in the CSV
foreach ($site in $sites) {
    $sitePath = $site.Sites

    # Normalize site URL: handle both full URLs and relative paths
    if ($sitePath -like "https://*") {
        $fullUrl = $sitePath
    } else {
        $fullUrl = "$tenantUrl$sitePath"
    }

    Write-Host "Processing site: $fullUrl"

    # Connect to SharePoint site using certificate-based authentication
    Connect-PnPOnline -Tenant $tenant -ClientId $clientId -Thumbprint $thumbprint_id -Url $fullUrl

    # Initialize array to store recycle bin items
    $ItemsTest = @()

    # Get FirstStage recycle bin items deleted by 'System Account'
    $ItemsTest += Get-PnPRecycleBinItem -FirstStage -RowLimit 1500000 | Where-Object {
        $_.DeletedByName -eq 'System Account'
    }

    # Get SecondStage recycle bin items deleted by 'System Account'
    $ItemsTest += Get-PnPRecycleBinItem -SecondStage -RowLimit 1500000 | Where-Object {
        $_.DeletedByName -eq 'System Account'
    }

    # Optional: If filtering by date range, uncomment below and comment above
    #$ItemsTest += Get-PnPRecycleBinItem -FirstStage -RowLimit 1500000 | Where-Object {
    #    ($_.DeletedDate -gt $date2 -and $_.DeletedDate -lt $date1) -and ($_.DeletedByName -eq 'System Account')
    #}
    #$ItemsTest += Get-PnPRecycleBinItem -SecondStage -RowLimit 1500000 | Where-Object {
    #    ($_.DeletedDate -gt $date2 -and $_.DeletedDate -lt $date1) -and ($_.DeletedByName -eq 'System Account')
    #}

    Write-Host "Found $($ItemsTest.Count) items in $sitePath"

    # Prepare safe file names by replacing special characters
    $safeSiteName = $sitePath -replace '[^a-zA-Z0-9]', '_'

    # Define export file paths
    $csvPath = Join-Path $restorePath "$safeSiteName`_DeletedFiles.csv"
    $idPath = Join-Path $restorePath "$safeSiteName`_deleted_ids.csv"

    # Export full item details to CSV
    $ItemsTest | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

    # Export only item IDs to separate CSV
    $ItemsTest | Select-Object id | Export-Csv -Path $idPath -NoTypeInformation -Encoding ASCII

    # Disconnect from site
    Disconnect-PnPOnline
}