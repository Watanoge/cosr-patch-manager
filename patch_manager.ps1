# Patch Manager PowerShell Script
# Handles patch creation and application for Catacombs of Solaris Revisited

param(
    [string]$Action,
    [string]$PatchName = "",
    [string]$PatchDesc = "",
    [string]$PatchAuthor = ""
)

# Set up paths
$GamePath = Get-Location
$ExtractedPath = Join-Path $GamePath "extracted_game"
$PatchesPath = Join-Path $GamePath "patches"
$OriginalPak = Join-Path $PatchesPath "data_original.pak"

# Ensure required folders exist
if (-not (Test-Path $PatchesPath)) { New-Item -Path $PatchesPath -ItemType Directory -Force | Out-Null }

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message"
}

function Expand-Pak {
    param([string]$PakFile, [string]$OutputPath)
    
    try {
        Write-Log "Extracting $PakFile to $OutputPath..."
        
        # Remove existing extraction
        if (Test-Path $OutputPath) {
            Remove-Item $OutputPath -Recurse -Force
        }
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        
        # Extract using 7-Zip (if available) or PowerShell with temp rename
        if (Get-Command "7z" -ErrorAction SilentlyContinue) {
            Write-Log "Using 7-Zip for extraction..."
            & 7z x "$PakFile" -o"$OutputPath" -y | Out-Null
        } else {
            Write-Log "Using PowerShell with temporary rename..."
            # PowerShell requires .zip extension, so we copy and rename temporarily
            $tempZip = "$PakFile.temp.zip"
            Copy-Item $PakFile $tempZip
            try {
                Expand-Archive -Path $tempZip -DestinationPath $OutputPath -Force
                Remove-Item $tempZip -Force
            } catch {
                if (Test-Path $tempZip) { Remove-Item $tempZip -Force }
                throw
            }
        }
        
        Write-Log "Extraction completed successfully."
        return $true
    } catch {
        Write-Log "ERROR: Failed to extract PAK file: $($_.Exception.Message)"
        Write-Log "SUGGESTION: Install 7-Zip for better PAK file support"
        return $false
    }
}

function New-Pak {
    param([string]$SourcePath, [string]$OutputPak)
    
    try {
        Write-Log "Creating PAK file: $OutputPak"
        
        # Remove existing PAK
        if (Test-Path $OutputPak) {
            Remove-Item $OutputPak -Force
        }
        
        # Create using 7-Zip (if available) or PowerShell with temp rename
        if (Get-Command "7z" -ErrorAction SilentlyContinue) {
            Write-Log "Using 7-Zip for compression..."
            Push-Location $SourcePath
            & 7z a -tzip "$OutputPak" * | Out-Null
            Pop-Location
        } else {
            Write-Log "Using PowerShell with temporary rename..."
            # PowerShell requires .zip extension, so we create temp and rename
            $tempZip = "$OutputPak.temp.zip"
            Compress-Archive -Path "$SourcePath\*" -DestinationPath $tempZip -Force
            Move-Item $tempZip $OutputPak -Force
        }
        
        Write-Log "PAK file created successfully."
        return $true
    } catch {
        Write-Log "ERROR: Failed to create PAK file: $($_.Exception.Message)"
        Write-Log "SUGGESTION: Install 7-Zip for better PAK file support"
        return $false
    }
}

function Compare-Files {
    param([string]$OriginalPath, [string]$ModifiedPath)
    
    $changes = @()
    
    Write-Log "Comparing files between original and modified versions..."
    
    # Get all files in modified version
    $modifiedFiles = Get-ChildItem -Path $ModifiedPath -Recurse -File
    
    foreach ($file in $modifiedFiles) {
        $relativePath = $file.FullName.Substring($ModifiedPath.Length + 1)
        $originalFile = Join-Path $OriginalPath $relativePath
        
        if (-not (Test-Path $originalFile)) {
            # New file
            $changes += @{
                Type = "Added"
                Path = $relativePath
                Content = [System.IO.File]::ReadAllBytes($file.FullName)
            }
            Write-Log "Found new file: $relativePath"
        } else {
            # Check if file was modified
            $originalHash = Get-FileHash $originalFile -Algorithm MD5
            $modifiedHash = Get-FileHash $file.FullName -Algorithm MD5
            
            if ($originalHash.Hash -ne $modifiedHash.Hash) {
                $changes += @{
                    Type = "Modified"
                    Path = $relativePath
                    Content = [System.IO.File]::ReadAllBytes($file.FullName)
                }
                Write-Log "Found modified file: $relativePath"
            }
        }
    }
    
    # Check for deleted files
    $originalFiles = Get-ChildItem -Path $OriginalPath -Recurse -File
    foreach ($file in $originalFiles) {
        $relativePath = $file.FullName.Substring($OriginalPath.Length + 1)
        $modifiedFile = Join-Path $ModifiedPath $relativePath
        
        if (-not (Test-Path $modifiedFile)) {
            $changes += @{
                Type = "Deleted"
                Path = $relativePath
                Content = $null
            }
            Write-Log "Found deleted file: $relativePath"
        }
    }
    
    return $changes
}

function New-PatchFile {
    param(
        [array]$Changes,
        [string]$PatchName,
        [string]$Description,
        [string]$Author,
        [string]$OutputPath
    )
    
    $patchData = @{
        metadata = @{
            name = $PatchName
            description = $Description
            author = $Author
            created = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            version = "1.0"
            target_game = "Catacombs of Solaris Revisited"
        }
        changes = @()
    }
    
    foreach ($change in $Changes) {
        $changeData = @{
            type = $change.Type
            path = $change.Path
        }
        
        if ($change.Content) {
            $changeData.content = [System.Convert]::ToBase64String($change.Content)
        }
        
        $patchData.changes += $changeData
    }
    
    $json = $patchData | ConvertTo-Json -Depth 10
    Set-Content -Path $OutputPath -Value $json -Encoding UTF8
}

function Install-Patch {
    param([string]$PatchFile, [string]$TargetPath)
    
    try {
        Write-Log "Loading patch file: $PatchFile"
        $patchContent = Get-Content $PatchFile -Raw | ConvertFrom-Json
        
        Write-Log "Patch Info:"
        Write-Log "  Name: $($patchContent.metadata.name)"
        Write-Log "  Description: $($patchContent.metadata.description)"
        Write-Log "  Author: $($patchContent.metadata.author)"
        Write-Log "  Created: $($patchContent.metadata.created)"
        
        Write-Log "Applying changes..."
        
        foreach ($change in $patchContent.changes) {
            $targetFile = Join-Path $TargetPath $change.path
            $targetDir = Split-Path $targetFile -Parent
            
            switch ($change.type) {
                "Added" {
                    Write-Log "Adding file: $($change.path)"
                    if (-not (Test-Path $targetDir)) {
                        New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
                    }
                    $bytes = [System.Convert]::FromBase64String($change.content)
                    [System.IO.File]::WriteAllBytes($targetFile, $bytes)
                }
                "Modified" {
                    Write-Log "Modifying file: $($change.path)"
                    if (-not (Test-Path $targetDir)) {
                        New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
                    }
                    $bytes = [System.Convert]::FromBase64String($change.content)
                    [System.IO.File]::WriteAllBytes($targetFile, $bytes)
                }
                "Deleted" {
                    Write-Log "Deleting file: $($change.path)"
                    if (Test-Path $targetFile) {
                        Remove-Item $targetFile -Force
                    }
                }
            }
        }
        
        Write-Log "Patch applied successfully!"
        return $true
    } catch {
        Write-Log "ERROR: Failed to apply patch: $($_.Exception.Message)"
        return $false
    }
}

function Build-TempPackage {
    try {
        Write-Log "Building temporary package for testing..."
        
        # Check if extracted_game folder exists
        if (-not (Test-Path $ExtractedPath)) {
            Write-Log "ERROR: extracted_game folder not found. Please extract content first."
            exit 1
        }
        
        # Create temporary package as data.pak
        $tempPakPath = Join-Path $GamePath "data.pak"
        
        Write-Log "Packaging current modifications..."
        
        # Create pak file from extracted_game content
        if (-not (New-Pak -SourcePath $ExtractedPath -OutputPak $tempPakPath)) {
            Write-Log "ERROR: Failed to create temporary package."
            exit 1
        }
        
        Write-Log "Temporary package created successfully at: $tempPakPath"
        Write-Log "Ready for testing!"
        
    } catch {
        Write-Log "ERROR: Failed to build temporary package: $($_.Exception.Message)"
        exit 1
    }
}

# Main action handler
switch ($Action) {
    "extract_original" {
        if (-not (Test-Path "data.pak")) {
            Write-Log "ERROR: data.pak not found in current directory"
            exit 1
        }
        
        if (Expand-Pak "data.pak" $ExtractedPath) {
            Write-Log "Original content extracted to extracted_game\"
            exit 0
        } else {
            exit 1
        }
    }
    
    "extract_current" {
        if (-not (Test-Path "data.pak")) {
            Write-Log "ERROR: data.pak not found in current directory"
            exit 1
        }
        
        if (Expand-Pak "data.pak" $ExtractedPath) {
            Write-Log "Current content extracted to extracted_game\"
            exit 0
        } else {
            exit 1
        }
    }
    
    "create_patch" {
        if (-not (Test-Path $ExtractedPath)) {
            Write-Log "ERROR: No extracted game files found. Run extract first."
            exit 1
        }
        
        if (-not (Test-Path $OriginalPak)) {
            Write-Log "ERROR: No original backup found. Run clean setup first."
            exit 1
        }
        
        # Extract original for comparison
        $tempOriginal = Join-Path $env:TEMP "original_extracted"
        if (-not (Expand-Pak $OriginalPak $tempOriginal)) {
            Write-Log "ERROR: Failed to extract original for comparison"
            exit 1
        }
        
        # Compare and get changes
        $changes = Compare-Files $tempOriginal $ExtractedPath
        
        if ($changes.Count -eq 0) {
            Write-Log "No changes detected between original and current files."
            Remove-Item $tempOriginal -Recurse -Force
            exit 1
        }
        
        Write-Log "Found $($changes.Count) changes"
        
        # Create patch file
        $patchFile = Join-Path $PatchesPath "$PatchName.patch"
        New-PatchFile $changes $PatchName $PatchDesc $PatchAuthor $patchFile
        
        Write-Log "Patch created: $patchFile"
        Write-Log "Changes included: $($changes.Count) files"
        
        # Cleanup
        Remove-Item $tempOriginal -Recurse -Force
        exit 0
    }
    
    "restore_original" {
        if (-not (Test-Path $OriginalPak)) {
            Write-Log "ERROR: No original backup found. Run clean setup first."
            exit 1
        }
        
        Write-Log "Restoring original game files..."
        if (Expand-Pak $OriginalPak $ExtractedPath) {
            if (New-Pak $ExtractedPath "data.pak") {
                Write-Log "Original game files restored successfully!"
            } else {
                Write-Log "ERROR: Failed to repackage game"
                exit 1
            }
        } else {
            Write-Log "ERROR: Failed to restore original files"
            exit 1
        }
    }
    
    "load_patch_by_number" {
        $patchNumber = [int]$PatchName
        if ($patchNumber -lt 1) {
            Write-Log "ERROR: Invalid patch number"
            exit 1
        }
        
        # Get list of patches
        $patches = Get-ChildItem $PatchesPath -Filter "*.patch" | Sort-Object Name
        if ($patchNumber -gt $patches.Count) {
            Write-Log "ERROR: Patch number $patchNumber not found. Available: 1-$($patches.Count)"
            exit 1
        }
        
        $selectedPatch = $patches[$patchNumber - 1].FullName
        Write-Log "Selected patch: $($patches[$patchNumber - 1].Name)"
        
        # Restore original first
        if (-not (Test-Path $OriginalPak)) {
            Write-Log "ERROR: No original backup found. Run clean setup first."
            exit 1
        }
        
        if (-not (Expand-Pak $OriginalPak $ExtractedPath)) {
            Write-Log "ERROR: Failed to restore original files"
            exit 1
        }
        
        # Apply patch
        if (Install-Patch $selectedPatch $ExtractedPath) {
            # Repackage
            if (New-Pak $ExtractedPath "data.pak") {
                Write-Log "Patch applied and game repackaged successfully!"
            } else {
                Write-Log "ERROR: Failed to repackage game"
                exit 1
            }
        } else {
            exit 1
        }
    }
    
    "load_patch" {
        # Show file dialog to select patch
        Add-Type -AssemblyName System.Windows.Forms
        $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openFileDialog.InitialDirectory = $PatchesPath
        $openFileDialog.Filter = "Patch files (*.patch)|*.patch|All files (*.*)|*.*"
        $openFileDialog.Title = "Select patch file to apply"
        
        if ($openFileDialog.ShowDialog() -eq 'OK') {
            $selectedPatch = $openFileDialog.FileName
            Write-Log "Selected patch: $selectedPatch"
            
            # Restore original
            if (-not (Test-Path $OriginalPak)) {
                Write-Log "ERROR: No original backup found. Run clean setup first."
                exit 1
            }
            
            if (-not (Expand-Pak $OriginalPak $ExtractedPath)) {
                Write-Log "ERROR: Failed to restore original files"
                exit 1
            }
            
            # Apply patch
            if (Install-Patch $selectedPatch $ExtractedPath) {
                # Repackage
                if (New-Pak $ExtractedPath "data.pak") {
                    Write-Log "Patch applied and game repackaged successfully!"
                } else {
                    Write-Log "ERROR: Failed to repackage game"
                    exit 1
                }
            } else {
                exit 1
            }
        } else {
            Write-Log "No patch file selected."
            exit 1
        }
    }
    
    "show_patch_list" {
        if (-not (Test-Path $PatchesPath)) {
            Write-Host "No patches folder found."
            exit 0
        }
        
        $patches = Get-ChildItem $PatchesPath -Filter "*.patch" | Sort-Object Name
        if ($patches.Count -eq 0) {
            Write-Host "No patches found."
            exit 0
        }
        
        Write-Host ""
        Write-Host "NUM | NAME              | AUTHOR       | CREATED    | CHANGES | DESCRIPTION"
        Write-Host "----+-------------------+--------------+------------+---------+------------------------"
        
        for ($i = 0; $i -lt $patches.Count; $i++) {
            try {
                $patchContent = Get-Content $patches[$i].FullName -Raw | ConvertFrom-Json
                $num = $i + 1
                $name = $patchContent.metadata.name
                $author = $patchContent.metadata.author
                $desc = $patchContent.metadata.description
                $created = $patchContent.metadata.created
                
                # Count changes by type
                $addedCount = ($patchContent.changes | Where-Object { $_.type -eq "Added" }).Count
                $modifiedCount = ($patchContent.changes | Where-Object { $_.type -eq "Modified" }).Count
                $deletedCount = ($patchContent.changes | Where-Object { $_.type -eq "Deleted" }).Count
                $totalChanges = $patchContent.changes.Count
                
                # Format date (only date part)
                $dateOnly = $created.Split(' ')[0]
                
                # Create changes summary
                $changesSummary = ""
                if ($addedCount -gt 0) { $changesSummary += "+$addedCount " }
                if ($modifiedCount -gt 0) { $changesSummary += "~$modifiedCount " }
                if ($deletedCount -gt 0) { $changesSummary += "-$deletedCount " }
                $changesSummary = $changesSummary.Trim()
                if ($changesSummary -eq "") { $changesSummary = "$totalChanges" }
                
                # Truncate long strings for table formatting
                if ($name.Length -gt 17) { $name = $name.Substring(0, 14) + "..." }
                if ($author.Length -gt 12) { $author = $author.Substring(0, 9) + "..." }
                if ($desc.Length -gt 22) { $desc = $desc.Substring(0, 19) + "..." }
                if ($changesSummary.Length -gt 7) { $changesSummary = $changesSummary.Substring(0, 7) }
                
                Write-Host ("{0,3} | {1,-17} | {2,-12} | {3,-10} | {4,-7} | {5}" -f $num, $name, $author, $dateOnly, $changesSummary, $desc)
            } catch {
                $num = $i + 1
                $name = $patches[$i].BaseName
                Write-Host ("{0,3} | {1,-17} | {2,-12} | {3,-10} | {4,-7} | {5}" -f $num, $name, "Unknown", "Unknown", "Error", "Invalid patch file")
            }
        }
        Write-Host ""
        exit 0
    }
    
    "show_state" {
        Write-Host ""
        Write-Host "SYSTEM STATE INFORMATION"
        Write-Host "========================"
        Write-Host ""
        
        # Check game files
        if (Test-Path "data.pak") {
            $pakInfo = Get-Item "data.pak"
            Write-Host "Game PAK: data.pak ($([math]::Round($pakInfo.Length / 1MB, 2)) MB)"
            Write-Host "Modified: $($pakInfo.LastWriteTime)"
        } else {
            Write-Host "Game PAK: NOT FOUND"
        }
        
        # Check original backup
        if (Test-Path $OriginalPak) {
            $backupInfo = Get-Item $OriginalPak
            Write-Host "Original backup: Available in patches\ ($([math]::Round($backupInfo.Length / 1MB, 2)) MB)"
        } else {
            Write-Host "Original backup: NOT FOUND in patches\"
        }
        
        # Check extracted files
        if (Test-Path $ExtractedPath) {
            $fileCount = (Get-ChildItem $ExtractedPath -Recurse -File).Count
            Write-Host "Extracted files: $fileCount files in extracted_game\"
        } else {
            Write-Host "Extracted files: None"
        }
        
        # Check patches
        if (Test-Path $PatchesPath) {
            $patches = Get-ChildItem $PatchesPath -Filter "*.patch"
            Write-Host "Available patches: $($patches.Count)"
            if ($patches.Count -gt 0) {
                Write-Host ""
                Write-Host "PATCH DETAILS:"
                Write-Host "NUM | NAME              | AUTHOR       | CREATED    | CHANGES | DESCRIPTION"
                Write-Host "----+-------------------+--------------+------------+---------+------------------------"
                
                for ($i = 0; $i -lt $patches.Count; $i++) {
                    try {
                        $patchContent = Get-Content $patches[$i].FullName -Raw | ConvertFrom-Json
                        $num = $i + 1
                        $name = $patchContent.metadata.name
                        $author = $patchContent.metadata.author
                        $desc = $patchContent.metadata.description
                        $created = $patchContent.metadata.created
                        
                        # Count changes by type
                        $addedCount = ($patchContent.changes | Where-Object { $_.type -eq "Added" }).Count
                        $modifiedCount = ($patchContent.changes | Where-Object { $_.type -eq "Modified" }).Count
                        $deletedCount = ($patchContent.changes | Where-Object { $_.type -eq "Deleted" }).Count
                        $totalChanges = $patchContent.changes.Count
                        
                        # Format date (only date part)
                        $dateOnly = $created.Split(' ')[0]
                        
                        # Create changes summary
                        $changesSummary = ""
                        if ($addedCount -gt 0) { $changesSummary += "+$addedCount " }
                        if ($modifiedCount -gt 0) { $changesSummary += "~$modifiedCount " }
                        if ($deletedCount -gt 0) { $changesSummary += "-$deletedCount " }
                        $changesSummary = $changesSummary.Trim()
                        if ($changesSummary -eq "") { $changesSummary = "$totalChanges" }
                        
                        # Truncate long strings for table formatting
                        if ($name.Length -gt 17) { $name = $name.Substring(0, 14) + "..." }
                        if ($author.Length -gt 12) { $author = $author.Substring(0, 9) + "..." }
                        if ($desc.Length -gt 22) { $desc = $desc.Substring(0, 19) + "..." }
                        if ($changesSummary.Length -gt 7) { $changesSummary = $changesSummary.Substring(0, 7) }
                        
                        Write-Host ("{0,3} | {1,-17} | {2,-12} | {3,-10} | {4,-7} | {5}" -f $num, $name, $author, $dateOnly, $changesSummary, $desc)
                    } catch {
                        $num = $i + 1
                        $name = $patches[$i].BaseName
                        Write-Host ("{0,3} | {1,-17} | {2,-12} | {3,-10} | {4,-7} | {5}" -f $num, $name, "Unknown", "Unknown", "Error", "Invalid patch file")
                    }
                }
            }
        } else {
            Write-Host "Available patches: 0"
        }
        
        Write-Host ""
    }
    
    "build_temp_package" {
        Build-TempPackage
    }
    
    default {
        Write-Log "Unknown action: $Action"
        Write-Log "Available actions: extract_original, extract_current, create_patch, load_patch, show_state, build_temp_package"
        exit 1
    }
}
