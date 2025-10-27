[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string] $SiteUrl,   # SharePoint site URL to connect to

    [Parameter(Mandatory)]
    [string] $Path       # Path to the CSV file containing recycle bin item IDs
)

# Setup logging
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = "UPDATE_YOUR_PATH\Logs\RestoreLog_$($timestamp).log"  # Update this path to your log directory

# Function to write log entries to both file and console
function Write-Log {
    param (
        [string] $Message,           # Log message
        [string] $Level = "INFO"     # Log level: INFO, SUCCESS, ERROR, WARNING
    )
    $entry = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Add-Content -Path $logFile -Value $entry
    Write-Host $entry
}

# Function to restore a recycle bin item using its ID
function Restore-RecycleBinItem {
    param(
        [Parameter(Mandatory)]
        [String] $Id                 # Recycle bin item ID
    )

    # Get current site URL and construct REST API endpoint
    $siteUrl = (Get-PnPSite).Url
    $apiCall = $siteUrl + "/_api/site/RecycleBin/RestoreByIds"
    $body = "{""ids"":[""$Id""]}"

    Write-Log "Attempting to restore item with ID: $Id" "INFO"
    try {
        # Call SharePoint REST API to restore item
        Invoke-PnPSPRestMethod -Method Post -Url $apiCall -Content $body | Out-Null
        Write-Log "✅ Successfully restored item with ID: $Id" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "❌ Failed to restore item with ID: $Id. Error: $_" "ERROR"
        return $false
    }
}

# Set error and information preferences
$ErrorActionPreference = 'Continue'
$InformationPreference = 'Continue'

# Tenant and authentication details
$tenant = "xxxxx.onmicrosoft.com"
$thumbprint_id = "thumbprint_id"     # Update with your certificate thumbprint
$clientId = "CLIENT_ID"              # Update with your Azure AD App Client ID
$tenantUrl = "https://xxxxx.sharepoint.com"

# Connect to the specified SharePoint site
Write-Log "Connecting to site: $SiteUrl" "INFO"
try {
    Connect-PnPOnline -Tenant $tenant -ClientId $clientId -Thumbprint $thumbprint_id -Url $SiteUrl
    Write-Log "Connected successfully to $SiteUrl" "SUCCESS"
}
catch {
    Write-Log "❌ Failed to connect to $SiteUrl. Error: $_" "ERROR"
    exit
}

# Import the CSV file containing recycle bin item IDs
try {
    $csvItems = Import-Csv -Path:$Path
    Write-Log "Imported CSV file: $Path with $($csvItems.Count) items" "INFO"
}
catch {
    Write-Log "❌ Failed to import CSV file: $Path. Error: $_" "ERROR"
    exit
}

# Loop through each item and attempt to restore it
foreach ($item in $csvItems) {
    $id = $item.Id
    Restore-RecycleBinItem -Id $id
}

# Final log entry after restore process completes
Write-Log "Restore process completed for site: $SiteUrl" "INFO"

# Disconnect the PnP session
try {
    Disconnect-PnPOnline
    Write-Log "Disconnected from $SiteUrl" "INFO"
}
catch {
    Write-Log "⚠️ Failed to disconnect from $SiteUrl. Error: $_" "WARNING"
}