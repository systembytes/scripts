<#
    ======================================================================
      SHEIKLAB – Windows Preview Pane Deployment Script
      Author      : Sheik Dawood
      Purpose     : Automatically enable Preview Pane system-wide,
                    unblock files, clear PS history, and present a
                    branded SHEIKLAB console experience.
      Compatibility: Windows 10 / Windows 11
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
# 🔵 FORCE-ENABLE PREVIEW PANE (Works Even If Explorer Is Closed)
# -----------------------------------------------------
Write-Host "`nConfiguring Preview Pane..." -ForegroundColor Yellow

# 1) Registry writes to ensure Preview Pane state is ON globally
$previewRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Modules\GlobalSettings\Sizer"
New-Item -Path $previewRegPath -Force | Out-Null
Set-ItemProperty -Path $previewRegPath -Name "PreviewPaneSizer" -Value ([byte[]](20,00,00,00,01,00,00,00,01,00,00,00,02,00,00,00)) -Force

# 2) Enable “Show Preview Handlers in Preview Pane”
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name "ShowPreviewHandlers" -Value 1 -Force

# 3) Restart Explorer so the Preview Pane becomes active instantly
Write-Host "Restarting Windows Explorer..." -ForegroundColor Yellow
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Process explorer.exe

Write-Host "Preview Pane is now enabled system-wide." -ForegroundColor Green


# -----------------------------------------------------
# 🔵 UNBLOCK FILES IN COMMON USER DIRECTORIES
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
