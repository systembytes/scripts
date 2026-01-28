<#
  Copy — Powered by SYSTEMBYTES 
  Author: Sheik Dawood
  Description: Lightweight fast-copy script with branding and logging.
  Last Updated: 2026-01-26
#>

# Admin Rights Check
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

# Banner Branding
$Host.UI.RawUI.WindowTitle = "Backup"
Write-Host "======================================================================" -ForegroundColor Green
Write-Host "  ######  ##     ## ######## #### ##    ## ##          ###    ########"
Write-Host " ##    ## ##     ## ##        ##  ##   ##  ##         ## ##   ##     ##"
Write-Host " ##       ##     ## ##        ##  ##  ##   ##        ##   ##  ##     ##"
Write-Host "  ######  ######### ######    ##  #####    ##       ##     ## ########"
Write-Host "       ## ##     ## ##        ##  ##  ##   ##       ######### ##     ##"
Write-Host " ##    ## ##     ## ##        ##  ##   ##  ##       ##     ## ##     ##"
Write-Host "  ######  ##     ## ######## #### ##    ## ######## ##     ## ########"
Write-Host "======================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "WELCOME TO SHEIKLAB" -ForegroundColor Cyan
Start-Sleep -Seconds 2
Write-Host ""

# -------------------------
# Prompt for Source & Destination
# -------------------------
$source = Read-Host "Enter SOURCE folder path (full path)"
if (-not (Test-Path -Path $source -PathType Container)) {
    Write-Host "❌ Source path does not exist or is not a folder: $source" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 2
}

$destination = Read-Host "Enter DESTINATION folder path (full path)"
if (-not (Test-Path -Path $destination -PathType Container)) {
    Write-Host "Destination does not exist. Creating: $destination" -ForegroundColor Yellow
    try {
        New-Item -Path $destination -ItemType Directory -Force | Out-Null
    } catch {
        Write-Host "❌ Failed to create destination: $_" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 3
    }
}

# -------------------------
# Prepare Log Filenames
# -------------------------
function Sanitize-PathForName {
    param([string]$path)
    # Remove drive colon, replace separators and whitespace with underscore, remove invalid filename chars
    $s = $path -replace "^[A-Za-z]:",""            # remove drive letter
    $s = $s -replace "[\\\/\s]+","_"               # replace slashes and spaces with underscore
    $s = $s -replace "[^A-Za-z0-9_\-\.]",""        # remove other invalid chars
    $s = $s.Trim('_')
    if ($s -eq '') { $s = "root" }
    return $s
}

$today = Get-Date -Format yyyyMMdd
$srcName = Sanitize-PathForName -path $source
$dstName = Sanitize-PathForName -path $destination
$baseName = "${today}_${srcName}_${dstName}"

$robocopyLog = Join-Path $destination ("robocopy_" + $baseName + ".log")
$verifiedCopiedLog = Join-Path $destination ("COPIED_" + $baseName + ".txt")
$verifiedNotCopiedLog = Join-Path $destination ("NOT_COPIED_" + $baseName + ".txt")

# Initialize logs
"Robocopy Log - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath $robocopyLog -Encoding UTF8
"Verification - Copied files - $baseName" | Out-File -FilePath $verifiedCopiedLog -Encoding UTF8
"Verification - Not copied files - $baseName" | Out-File -FilePath $verifiedNotCopiedLog -Encoding UTF8

# -------------------------
# Build file list and totals
# -------------------------
Write-Host "`nScanning source files..." -ForegroundColor Yellow
$files = Get-ChildItem -Path $source -Recurse -File -ErrorAction SilentlyContinue
if ($files.Count -eq 0) {
    Write-Host "No files found in source: $source" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 0
}

$totalFiles = $files.Count
$totalBytes = ($files | Measure-Object -Property Length -Sum).Sum
$bytesCopied = 0L
$startTime = Get-Date

Write-Host " Files to copy : $totalFiles"
Write-Host (" Total size    : {0:N2} MB" -f ($totalBytes / 1MB))
Write-Host ""

# -------------------------
# Per-file copy using robocopy + progress
# -------------------------
# Robocopy options used per-file:
# /COPY:DAT  - copy data, attributes, timestamps
# /R:1 /W:1   - retry once, wait 1s
# /NFL /NDL   - suppress file/dir lists in console (we log)
# /NP         - no progress in robocopy output (we show our own)
# /LOG+:file  - append to log
$robocopyPerFileArgs = "/COPY:DAT /R:1 /W:1 /NFL /NDL /NP /LOG+:`"$robocopyLog`""

$index = 0
foreach ($file in $files) {
    $index++
    $relativePath = $file.FullName.Substring($source.Length).TrimStart('\','/')
    $targetFile = Join-Path $destination $relativePath
    $targetDir = Split-Path $targetFile -Parent

    if (-not (Test-Path $targetDir)) {
        New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
    }

    # Use robocopy to copy the single file by specifying the filename as a file filter
    $fileNameOnly = Split-Path $relativePath -Leaf
    $fileDirOnly = Split-Path $relativePath -Parent
    if ($fileDirOnly -eq '') { $fileDirOnly = '.' }

    $srcDirForRobocopy = Join-Path $source $fileDirOnly
    $dstDirForRobocopy = Join-Path $destination $fileDirOnly

    $robocopyCmd = "robocopy `"$srcDirForRobocopy`" `"$dstDirForRobocopy`" `"$fileNameOnly`" $robocopyPerFileArgs"
    # Execute robocopy for this file
    Invoke-Expression $robocopyCmd
    $rc = $LASTEXITCODE

    # Update bytes copied estimate (use source file length)
    $bytesCopied += $file.Length

    # Compute progress
    $percent = if ($totalBytes -gt 0) { [math]::Round(($bytesCopied / $totalBytes) * 100, 2) } else { 100 }
    $elapsed = (Get-Date) - $startTime
    $speed = if ($elapsed.TotalSeconds -gt 0) { ($bytesCopied / 1MB) / $elapsed.TotalSeconds } else { 0 } # MB/s
    $remainingBytes = [math]::Max(0, $totalBytes - $bytesCopied)
    $eta = if ($speed -gt 0) { [TimeSpan]::FromSeconds(($remainingBytes / 1MB) / $speed) } else { [TimeSpan]::MaxValue }

    Write-Progress -Activity "SHEIKLAB Robocopy" `
                   -Status "Copying file $index of $totalFiles : $fileNameOnly" `
                   -PercentComplete $percent `
                   -CurrentOperation ("{0:N2} MB copied — {1:N2} MB/s — ETA: {2}" -f ($bytesCopied/1MB), $speed, (if ($eta -eq [TimeSpan]::MaxValue) { "Unknown" } else { $eta.ToString("hh\:mm\:ss") }))

    # Record per-file result into temporary arrays for verification
    if ($rc -lt 8) {
        # success for this file
        Add-Content -Path $verifiedCopiedLog -Value $file.FullName
    } else {
        # failure for this file
        Add-Content -Path $verifiedNotCopiedLog -Value ("ERROR copying: {0} (robocopy exit {1})" -f $file.FullName, $rc)
    }
}

# -------------------------
# Final robocopy pass for accuracy and full log
# -------------------------
Write-Host "`nRunning final robocopy pass to reconcile attributes and capture full log..." -ForegroundColor Yellow
$finalArgs = "/E /ZB /MT:32 /R:3 /W:5 /V /FP /TEE /LOG:`"$robocopyLog`""
$finalCmd = "robocopy `"$source`" `"$destination`" $finalArgs"
Write-Host "Executing: $finalCmd" -ForegroundColor DarkGray
Invoke-Expression $finalCmd
$finalExit = $LASTEXITCODE

# -------------------------
# Parse robocopy log for additional verification entries
# -------------------------
Write-Host "`nParsing robocopy log for verification entries..." -ForegroundColor Yellow
$logLines = Get-Content -Path $robocopyLog -ErrorAction SilentlyContinue

# Conservative patterns for success and failure (English)
$successPatterns = @('New File','Copied','100%','Newer','EXTRA File') 
$failurePatterns = @('ERROR','Access is denied','Access Denied','The system cannot find the file specified','Failed','Unable to copy','Retrying')

# Collect additional entries
$additionalCopied = New-Object System.Collections.Generic.List[string]
$additionalNotCopied = New-Object System.Collections.Generic.List[string]

foreach ($line in $logLines) {
    $t = $line.Trim()
    if ($t -eq '') { continue }
    foreach ($fp in $failurePatterns) {
        if ($t -like "*$fp*") {
            $additionalNotCopied.Add($t)
            continue 2
        }
    }
    foreach ($sp in $successPatterns) {
        if ($t -like "*$sp*") {
            # try to extract path-like substring
            if ($t -match "([A-Za-z]:\\.+)") {
                $additionalCopied.Add($matches[1])
            } else {
                $additionalCopied.Add($t)
            }
            continue 2
        }
    }
}

# Append unique additional entries to verification logs
if ($additionalCopied.Count -gt 0) {
    $additionalCopied | Select-Object -Unique | Out-File -FilePath $verifiedCopiedLog -Append -Encoding UTF8
}
if ($additionalNotCopied.Count -gt 0) {
    $additionalNotCopied | Select-Object -Unique | Out-File -FilePath $verifiedNotCopiedLog -Append -Encoding UTF8
}

# -------------------------
# Final Summary
# -------------------------
Write-Host "`n==================== SUMMARY ====================" -ForegroundColor Cyan
Write-Host (" Start time          : {0}" -f $startTime)
Write-Host (" End time            : {0}" -f (Get-Date))
Write-Host (" Total files scanned : {0}" -f $totalFiles)
Write-Host (" Total size (MB)     : {0:N2}" -f ($totalBytes / 1MB))
Write-Host (" Robocopy final code : {0}" -f $finalExit)
Write-Host " Verification logs   : " -NoNewline
Write-Host "COPIED -> $verifiedCopiedLog" -ForegroundColor Green
Write-Host "                     NOT_COPIED -> $verifiedNotCopiedLog" -ForegroundColor Yellow
Write-Host " Full robocopy log   : $robocopyLog" -ForegroundColor DarkGray
Write-Host "==================================================" -ForegroundColor Cyan

# Append summary to verification logs
"Robocopy Final Exit Code: $finalExit" | Out-File -FilePath $verifiedCopiedLog -Append -Encoding UTF8
"Robocopy Final Exit Code: $finalExit" | Out-File -FilePath $verifiedNotCopiedLog -Append -Encoding UTF8

if ($finalExit -band 8) {
    Write-Host "`n❌ Some files or directories failed to copy. Inspect the NOT_COPIED log and the robocopy log for details." -ForegroundColor Red
} else {
    Write-Host "`n✅ Copy completed. Review verification logs for a file-level audit." -ForegroundColor Green
}

Read-Host "Press Enter to exit"
