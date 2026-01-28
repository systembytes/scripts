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

# -------- User Input --------
$Source      = Read-Host "Enter SOURCE folder full path"
$Destination = Read-Host "Enter DESTINATION folder full path"

# -------- Validation --------
if (!(Test-Path $Source)) {
    Write-Host "ERROR: Source path does not exist." -ForegroundColor Red
    return
}

if (!(Test-Path $Destination)) {
    Write-Host "Destination does not exist. Creating it..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $Destination | Out-Null
}

# -------- Log File --------
$LogFile = Join-Path $Destination "robocopy_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Write-Host "Log File: $LogFile" -ForegroundColor Green

# ==============================================================
# FAST COPY PHASE
# ==============================================================
Write-Host "\n[1/2] Starting FAST COPY..." -ForegroundColor Cyan

$CopyArgs = @(
    "`"$Source`"",
    "`"$Destination`"",
    "/E",              # All folders (incl empty)
    "/Z",              # Restartable
    "/B",              # Backup mode
    "/MT:32",          # Multithreaded (fast)
    "/R:3",            # Retries
    "/W:5",            # Wait time
    "/COPY:DATSOU",    # Full metadata
    "/DCOPY:T",        # Folder timestamps
    "/TEE",            # Console + log
    "/LOG+:`"$LogFile`""
)

robocopy @CopyArgs
$CopyExitCode = $LASTEXITCODE

# ==============================================================
# VERIFICATION PHASE (COMPARE ONLY)
# ==============================================================
Write-Host "\n[2/2] Starting VERIFICATION (Compare Only)..." -ForegroundColor Yellow

$VerifyArgs = @(
    "`"$Source`"",
    "`"$Destination`"",
    "/E",              # All folders
    "/L",              # List only (NO copy)
    "/V",              # Verbose
    "/BYTES",          # Byte-level compare
    "/TS",             # Timestamps
    "/FP",             # Full paths
    "/MT:32",          # Fast scan
    "/R:0",            # No retries
    "/W:0",            # No wait
    "/TEE",            # Console + log
    "/LOG+:`"$LogFile`""
)

robocopy @VerifyArgs
$VerifyExitCode = $LASTEXITCODE

# ==============================================================
# SUMMARY
# ==============================================================
Write-Host "\n==============================================" -ForegroundColor Green
Write-Host "Operation Completed" -ForegroundColor Green
Write-Host "Copy Exit Code   : $CopyExitCode" -ForegroundColor Green
Write-Host "Verify Exit Code : $VerifyExitCode" -ForegroundColor Green
Write-Host "Log File         : $LogFile" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green

# Keep PowerShell open for more commands
Write-Host "\nPowerShell session remains open. You may run other commands." -ForegroundColor Cyan
return

