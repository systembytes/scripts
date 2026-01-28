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
# Prompt for missing arguments
# -------------------------
if (-not $Source) {
    $Source = Read-Host "Enter SOURCE folder path (full path)"
}
if (-not (Test-Path -Path $Source -PathType Container)) {
    Write-Host "❌ Source path does not exist or is not a folder: $Source" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 2
}

if (-not $Destination) {
    $Destination = Read-Host "Enter DESTINATION folder path (full path)"
}
if (-not (Test-Path -Path $Destination -PathType Container)) {
    Write-Host "Destination does not exist. Creating: $Destination" -ForegroundColor Yellow
    try {
        New-Item -Path $Destination -ItemType Directory -Force | Out-Null
    } catch {
        Write-Host "❌ Failed to create destination: $_" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 3
    }
}

# -------------------------
# Prepare single log filename yyyyMMdd_src_dst.log
# -------------------------
function Sanitize-PathForName {
    param([string]$path)
    $s = $path -replace "^[A-Za-z]:",""
    $s = $s -replace "[\\\/\s]+","_"
    $s = $s -replace "[^A-Za-z0-9_\-\.]",""
    $s = $s.Trim('_')
    if ($s -eq '') { $s = "root" }
    return $s
}

$today = Get-Date -Format yyyyMMdd
$srcName = Sanitize-PathForName -path $Source
$dstName = Sanitize-PathForName -path $Destination
$baseName = "${today}_${srcName}_${dstName}"
$finalLog = Join-Path $Destination ("$baseName.log")

# Temporary robocopy log (keeps detailed copy log while copying)
$tempRobocopyLog = Join-Path $Destination ("robocopy_temp_$baseName.log")
"Robocopy session started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath $tempRobocopyLog -Encoding UTF8

# -------------------------
# Compute totals for progress
# -------------------------
Write-Host "`nScanning source to compute totals..." -ForegroundColor Yellow
$sourceFiles = Get-ChildItem -Path $Source -Recurse -File -ErrorAction SilentlyContinue
if ($sourceFiles.Count -eq 0) {
    Write-Host "No files found in source: $Source" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 0
}
$totalBytes = ($sourceFiles | Measure-Object -Property Length -Sum).Sum
$totalFiles = $sourceFiles.Count

Write-Host (" Files to copy : {0:N0}" -f $totalFiles)
Write-Host (" Total size    : {0:N2} MB" -f ($totalBytes / 1MB))
Write-Host ""

# -------------------------
# Run robocopy bulk copy in background and monitor progress
# -------------------------
# Robocopy copy options: preserve data, attributes, timestamps; copy directory attributes; multithreaded
$copyArgs = @(
    "`"$Source`"",
    "`"$Destination`"",
    "/E",
    "/COPY:DAT",
    "/DCOPY:DA",
    "/ZB",
    "/MT:32",
    "/R:3",
    "/W:5",
    "/V",
    "/FP",
    "/TEE",
    "/LOG:`"$tempRobocopyLog`""
) -join " "

Write-Host "Starting robocopy..." -ForegroundColor Yellow
Write-Host " robocopy $copyArgs" -ForegroundColor DarkGray

$proc = Start-Process -FilePath "robocopy" -ArgumentList $copyArgs -NoNewWindow -PassThru

# Monitor progress by summing destination bytes while robocopy runs
$bytesCopied = 0L
$startTime = Get-Date
while (-not $proc.HasExited) {
    try {
        $destBytes = (Get-ChildItem -Path $Destination -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    } catch {
        $destBytes = $bytesCopied
    }
    $bytesCopied = [math]::Max($bytesCopied, [int64]$destBytes)
    $percent = if ($totalBytes -gt 0) { [math]::Round(($bytesCopied / $totalBytes) * 100, 2) } else { 100 }
    $elapsed = (Get-Date) - $startTime
    $speed = if ($elapsed.TotalSeconds -gt 0) { ($bytesCopied / 1MB) / $elapsed.TotalSeconds } else { 0 }
    $remainingBytes = [math]::Max(0, $totalBytes - $bytesCopied)
    $etaText = if ($speed -gt 0) { ([TimeSpan]::FromSeconds(($remainingBytes / 1MB) / $speed)).ToString("hh\:mm\:ss") } else { "Unknown" }

    $status = "{0:N2} MB copied — {1:N2} MB/s — ETA: {2}" -f ($bytesCopied/1MB), $speed, $etaText
    Write-Progress -Activity "SHEIKLAB Robocopy" -Status $status -PercentComplete $percent -CurrentOperation ("Copying to $Destination")
    Start-Sleep -Seconds 1
}

# Ensure final progress shows 100%
$bytesCopied = (Get-ChildItem -Path $Destination -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
$percent = if ($totalBytes -gt 0) { [math]::Round(($bytesCopied / $totalBytes) * 100, 2) } else { 100 }
Write-Progress -Activity "SHEIKLAB Robocopy" -Status "Completed" -PercentComplete $percent -CurrentOperation "Copy finished"
Write-Host "`nRobocopy finished with exit code $($proc.ExitCode)" -ForegroundColor Cyan

# Append final note to temp log
"Robocopy finished: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ExitCode: $($proc.ExitCode)" | Out-File -FilePath $tempRobocopyLog -Append -Encoding UTF8

# -------------------------
# Verification dry-run exactly as requested
# Example: robocopy D:\ISO E:\ISO /E /L /V /BYTES /TS /FP
# Save output to single log file named yyyyMMdd_src_dst.log in destination
# -------------------------
Write-Host "`nRunning verification dry-run (list-only) and saving to $finalLog" -ForegroundColor Yellow
$dryRunArgs = @(
    "`"$Source`"",
    "`"$Destination`"",
    "/E",
    "/L",
    "/V",
    "/BYTES",
    "/TS",
    "/FP",
    "/LOG:`"$finalLog`""
) -join " "

Write-Host " robocopy $dryRunArgs" -ForegroundColor DarkGray
# Run dry-run and wait
$dryProc = Start-Process -FilePath "robocopy" -ArgumentList $dryRunArgs -NoNewWindow -Wait -PassThru
$dryExit = $dryProc.ExitCode

# -------------------------
# Final summary
# -------------------------
Write-Host "`n==================== SUMMARY ====================" -ForegroundColor Cyan
Write-Host (" Start time        : {0}" -f $startTime)
Write-Host (" End time          : {0}" -f (Get-Date))
Write-Host (" Source            : $Source")
Write-Host (" Destination       : $Destination")
Write-Host (" Total files       : {0:N0}" -f $totalFiles)
Write-Host (" Total size (MB)   : {0:N2}" -f ($totalBytes / 1MB))
Write-Host (" Copy exit code    : {0}" -f $proc.ExitCode)
Write-Host (" Dry-run exit code : {0}" -f $dryExit)
Write-Host (" Verification log  : $finalLog") -ForegroundColor Green
Write-Host " Temp robocopy log : $tempRobocopyLog" -ForegroundColor DarkGray
Write-Host "==================================================" -ForegroundColor Cyan

# Exit
Read-Host "Press Enter to exit"
