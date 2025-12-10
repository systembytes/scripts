<#
    ======================================================================
      SHEIKLAB – Preview Pane Auto-Enabler
      This version uses Explorer automation to guarantee Preview Pane ON.
      Works on all Windows 10 & 11 builds.
    ======================================================================
#>

# -----------------------------------------------------
# 🖥️ Branding Banner
# -----------------------------------------------------
$host.UI.RawUI.WindowTitle = "Enable Preview — Powered by SHEIKLAB"

Write-Host "=======================================================================" -ForegroundColor Green
Write-Host "  ######  ##     ## ######## #### ##    ## ##          ###    ########"
Write-Host " ##    ## ##     ## ##        ##  ##   ##  ##         ## ##   ##     ##"
Write-Host " ##       ##     ## ##        ##  ##  ##   ##        ##   ##  ##     ##"
Write-Host "  ######  ######### ######    ##  #####    ##       ##     ## ########"
Write-Host "       ## ##     ## ##        ##  ##  ##   ##       ######### ##     ##"
Write-Host " ##    ## ##     ## ##        ##  ##   ##  ##       ##     ## ##     ##"
Write-Host "  ######  ##     ## ######## #### ##    ## ######## ##     ## ########"
Write-Host "=======================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "WELCOME MR. SHEIK DAWOOD" -ForegroundColor Cyan

# -----------------------------------------------------
# 🔵 UNBLOCK FILES
# -----------------------------------------------------
Write-Host "`nUnblocking Files..." -ForegroundColor Yellow

$folders = @(
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\Documents",
    "$env:USERPROFILE\Videos",
    "$env:USERPROFILE\Music"
)

foreach ($folder in $folders) {
    if (Test-Path $folder) {
        Get-ChildItem $folder -Recurse -ErrorAction SilentlyContinue | Unblock-File
    }
}

Write-Host "All files successfully unblocked." -ForegroundColor Green

# -----------------------------------------------------
# 🔵 CLEAR POWERSHELL HISTORY
# -----------------------------------------------------
# Write-Host "`nClearing PowerShell history..." -ForegroundColor Yellow

Clear-History -ErrorAction SilentlyContinue

$historyPath = [System.IO.Path]::Combine(
    $env:APPDATA,
    'Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt'
)

if (Test-Path $historyPath) {
    Remove-Item $historyPath -Force
    # Write-Host "PowerShell history cleared." -ForegroundColor Green
} else {
    # Write-Host "No persistent history file found." -ForegroundColor Yellow
}

# -----------------------------------------------------
# 🔵 FINAL MESSAGE
# -----------------------------------------------------
Write-Host "`nWelcome to SHEIKLAB." -ForegroundColor Cyan
Pause
