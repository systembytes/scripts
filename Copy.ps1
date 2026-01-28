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

# Prompt for source and destination
$Source = Read-Host "Enter SOURCE folder full path"
$Destination = Read-Host "Enter DESTINATION folder full path"

# Validate paths
if (!(Test-Path $Source)) {
    Write-Host "ERROR: Source path does not exist." -ForegroundColor Red
    exit
}

if (!(Test-Path $Destination)) {
    Write-Host "Destination does not exist. Creating destination folder..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $Destination | Out-Null
}

# Log file in destination
$LogFile = Join-Path $Destination "robocopy_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

Write-Host "Log File: $LogFile" -ForegroundColor Green

# High-speed copy arguments
$CopyArgs = @(
    "`"$Source`"",
    "`"$Destination`"",
    "/E",              # Copy all subfolders including empty
    "/Z",              # Restartable mode
    "/B",              # Backup mode
    "/R:3",            # Retry 3 times
    "/W:5",            # Wait 5 sec between retries
    "/MT:32",          # Multithreaded copy (fast)
    "/COPY:DATSOU",    # Copy Data, Attributes, Timestamps, Security, Owner, Auditing
    "/DCOPY:T",        # Copy directory timestamps
    "/NP",             # No progress
    "/TEE",            # Output to console + log
    "/LOG+:`"$LogFile`""  # Append log
)

Write-Host "Starting FAST COPY operation..." -ForegroundColor Cyan

# Execute robocopy
robocopy @CopyArgs
$CopyExitCode = $LASTEXITCODE

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Copy completed. Starting verification phase..." -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Verification using robocopy (no copy, only compare)
$VerifyArgs = @(
    "`"$Source`"",
    "`"$Destination`"",
    "/E",
    "/R:0",
    "/W:0",
    "/MT:32",
    "/COPY:DATSOU",
    "/DCOPY:T",
    "/NFL",           # No file list
    "/NDL",           # No dir list
    "/L",             # List only (no copy)
    "/TEE",
    "/LOG+:`"$LogFile`""
)

Write-Host "Running verification (comparison-only mode)..." -ForegroundColor Yellow
robocopy @VerifyArgs
$VerifyExitCode = $LASTEXITCODE

Write-Host "=============================================" -ForegroundColor Green
Write-Host "Operation completed." -ForegroundColor Green
Write-Host "Copy Exit Code: $CopyExitCode" -ForegroundColor Green
Write-Host "Verify Exit Code: $VerifyExitCode" -ForegroundColor Green
Write-Host "Log file saved to:" -ForegroundColor Green
Write-Host $LogFile -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

Write-Host "Press ENTER to close window..." -ForegroundColor Cyan
Read-Host

# Exit clean
exit
