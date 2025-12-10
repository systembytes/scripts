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

Start-Sleep -Seconds 2

# -----------------------------------------------------
# ⭐ 100% WORKING PREVIEW PANE ENABLER
# -----------------------------------------------------
# Enable Preview Pane in File Explorer via PowerShell
# This script sets the registry value to show the Preview Pane and refreshes Explorer

try {
    # Registry path for Explorer's Preview Pane setting
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Modules\GlobalSettings\Sizer"

    # Ensure the registry path exists
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }

    # Set the Preview Pane to enabled (1 = enabled, 0 = disabled)
    Set-ItemProperty -Path $regPath -Name "PreviewPaneSizer" -Value ([byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00)) -Force

    # Registry key to remember the pane state
    $statePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Modules\GlobalSettings\DetailsContainer"
    if (-not (Test-Path $statePath)) {
        New-Item -Path $statePath -Force | Out-Null
    }
    Set-ItemProperty -Path $statePath -Name "PreviewPane" -Value 1 -Force

    # Restart Explorer to apply changes
    Stop-Process -Name explorer -Force
    Start-Process explorer

    Write-Host "✅ Preview Pane has been enabled in File Explorer." -ForegroundColor Green
}
catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

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
Write-Host "`nClearing PowerShell history..." -ForegroundColor Yellow

Clear-History -ErrorAction SilentlyContinue

$historyPath = [System.IO.Path]::Combine(
    $env:APPDATA,
    'Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt'
)

if (Test-Path $historyPath) {
    Remove-Item $historyPath -Force
    Write-Host "PowerShell history cleared." -ForegroundColor Green
} else {
    Write-Host "No persistent history file found." -ForegroundColor Yellow
}

# -----------------------------------------------------
# 🔵 FINAL MESSAGE
# -----------------------------------------------------
Write-Host "`nDeployment complete. Welcome to SHEIKLAB." -ForegroundColor Cyan
Pause
