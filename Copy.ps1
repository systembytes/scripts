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

# Ask for Destination
$destination = Read-Host "Enter DESTINATION folder path"
if (-not (Test-Path $destination)) {
    Write-Host "Destination does not exist. Creating it..." -ForegroundColor Yellow
    New-Item -Path $destination -ItemType Directory | Out-Null
}

# Log File
$logFile = Join-Path $destination "FastCopy_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Count total files for progress bar
Write-Host "`nScanning files..." -ForegroundColor Yellow
$files = Get-ChildItem -Path $source -Recurse -File -ErrorAction SilentlyContinue
$total = $files.Count
$counter = 0

Write-Host "Starting FastCopy with progress..." -ForegroundColor Yellow

foreach ($file in $files) {
    $counter++

    $relative = $file.FullName.Substring($source.Length)
    $targetFile = Join-Path $destination $relative
    $targetDir = Split-Path $targetFile

    if (-not (Test-Path $targetDir)) {
        New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
    }

    Copy-Item -Path $file.FullName -Destination $targetFile -Force

    $percent = [math]::Round(($counter / $total) * 100, 2)

    Write-Progress `
        -Activity "Copying Files..." `
        -Status "$percent% complete" `
        -PercentComplete $percent `
        -CurrentOperation $file.Name
}

# Final robocopy pass for accuracy + log
$cmd = "robocopy `"$source`" `"$destination`" /E /ZB /R:1 /W:1 /MT:32 /LOG:`"$logFile`""
Invoke-Expression $cmd

$exitCode = $LASTEXITCODE

if ($exitCode -ge 8) {
    Write-Host "❌ Copy FAILED — Exit Code $exitCode" -ForegroundColor Red
} else {
    Write-Host "✅ Copy SUCCESS — $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green
}

Write-Host "`nLog saved at: $logFile" -ForegroundColor Cyan
Read-Host "Press Enter to exit"
