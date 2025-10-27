
# 🛠️ SharePoint Recycle Bin Restore Automation

## 📄 Overview

This project contains **three PowerShell scripts** that automate the process of identifying and restoring deleted items from SharePoint Online recycle bins using the **PnP PowerShell module**.

It supports restoring items deleted by the **System Account** from both the **FirstStage** and **SecondStage** recycle bins, and includes logging for traceability.

---

## ⚙️ Prerequisites

### ✅ PowerShell Version
- You must have **PowerShell 7 or above** installed.

### ✅ PnP PowerShell Module
Refer the official guide for using [PnP PowerShell](https://pnp.github.io/powershell/)  
Please follow **all three setup steps** mentioned on the official site:

1. **Install the module**  
   ```powershell
   Install-Module PnP.PowerShell -Scope CurrentUser
   ```

2. **Register an Azure AD App**  
   Follow the [guide](https://pnp.github.io/powershell/articles/registerapplication.html) to register an app with certificate-based authentication.

3. **Connect using certificate authentication**  
   Use `Connect-PnPOnline` with `-ClientId`, `-Thumbprint`, and `-Tenant` parameters.

---

## 📁 Scripts

### 1️⃣ `get-files-deleted-by-SystemAccount.ps1`
- **Purpose**: Connects to a list of SharePoint sites and exports items deleted by `System Account` (You can change it as per you requirement) from both FirstStage and SecondStage recycle bins.
- **Input**: CSV file containing site paths (e.g., `/sites/MidOfficeOperations` or `MidOfficeOperations`).
- **Output**: Two CSVs per site:
  - `_DeletedFiles.csv` – full item details
  - `_deleted_ids.csv` – only item IDs

---

### 2️⃣ `get-site-details-and-runrestore.ps1`
- **Purpose**: Reads the deleted item ID files and calls the restore script for each site.
- **Input**: CSV file with site paths or names.
- **Output**: Logs restoration status to a text file.

> 🔄 This script automatically invokes `Restore-RecycleBinItems_withLogs.ps1` for each site.

---

### 3️⃣ `Restore-RecycleBinItems_withLogs.ps1`
- **Purpose**: Restores individual items using SharePoint REST API and logs each action.
- **Input**: Site URL and path to the deleted IDs CSV.
- **Output**: Timestamped log file with success/failure entries.

---

## 🚀 How to Use

### Step 1: Export Deleted Items
```powershell
.\get-files-deleted-by-SystemAccount.ps1
```

### Step 2: Restore Deleted Items from CSV
```powershell
.\get-site-details-and-runrestore.ps1
```

> This will automatically call `Restore-RecycleBinItems_withLogs.ps1` for each site.

---

## 📝 Notes

- Ensure all paths in the scripts are updated to reflect your environment.
- The scripts handle both `/sites/SiteName` and `SiteName` formats.
- Logs are created for each restore session for traceability.
- You must have appropriate permissions to restore items via PnP PowerShell.
