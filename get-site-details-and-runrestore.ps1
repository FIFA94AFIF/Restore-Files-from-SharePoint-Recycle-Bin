# Path to the input CSV containing site names (update this path)
$inputCsv = "YOUR_PATH\affected_sites.csv"

# Tenant and authentication details
$tenant = "xxxxx.onmicrosoft.com"				# Your tenant name
$thumbprint_id = "thumbprint_id"     			# Certificate thumbprint
$clientId = "CLIENT_ID"              			# Azure AD App Client ID
$tenantUrl = "https://xxxxx.sharepoint.com"		# SharePoint Online root URL

# Directory containing the restore CSVs (update this path)
$restoreDir = "YOUR_PATH"

# Path to the log file (update this path)
$logFile = "UPDATE_YOUR_PATH\restore_log.txt"

# Clear previous log file if it exists
if (Test-Path $logFile) {
    Remove-Item $logFile
}

# Import the site list from CSV
$sites = Import-Csv -Path $inputCsv

# Loop through each site entry
foreach ($site in $sites) {
    # Extract raw site path from CSV
    $sitePath = $site.Sites

    # Normalize site path: if it doesn't start with "/sites/", assume it's just the site name
    if ($sitePath -notlike "/sites/*") {
        $sitePath = "/sites/$sitePath"
    }

    # Construct full site URL
    $fullUrl = "$tenantUrl$sitePath"

    # Extract site name for filename sanitization
    $siteName = $sitePath -replace "^/sites/", ""

    # Sanitize site name for filename compatibility (replace hyphens with underscores)
    $sanitizedSiteName = $siteName -replace "-", "_"

    # Construct expected filename for deleted item IDs
    $expectedFile = "_sites_${sanitizedSiteName}_deleted_ids.csv"
    $fullPath = Join-Path -Path $restoreDir -ChildPath $expectedFile

    # Check if the expected file exists
    if (Test-Path $fullPath) {
        Write-Host "✅ Found: $expectedFile"
        
        try {
            # Call the restore script with site URL and path to deleted IDs file
            .\Restore-RecycleBinItems_withLogs.ps1 -SiteUrl $fullUrl -Path $fullPath

            # Log success
            Add-Content -Path $logFile -Value "[$(Get-Date)] ✅ Restored: $sitePath using $expectedFile"
        } catch {
            # Log error with details
            Add-Content -Path $logFile -Value "[$(Get-Date)] ❌ Error restoring: $sitePath using $expectedFile - $_"
        }
    } else {
        # Warn and log if expected file is missing
        Write-Warning "❌ Missing: $expectedFile"
        Add-Content -Path $logFile -Value "[$(Get-Date)] ❌ Missing file for: $sitePath - Expected: $expectedFile"
    }
}