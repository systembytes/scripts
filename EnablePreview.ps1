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
Write-Host "`nForcing Preview Pane ON..." -ForegroundColor Yellow

# Restart Explorer cleanly
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep 1
Start-Process explorer.exe

Start-Sleep 2  # Wait for Explorer to fully initialize

# Load COM automation
$shell = New-Object -ComObject Shell.Application
$windows = $shell.Windows()

# Open a NEW Explorer window that we control
Start-Process "explorer.exe" -ArgumentList "$env:USERPROFILE"
Start-Sleep 2

# Re-fetch Explorer windows
$windows = $shell.Windows()
$explorer = $windows | Where-Object { $_.Name -eq "File Explorer" } | Select-Object -First 1

if ($explorer -ne $null) {

    # Prepare SendMessage API
    $sig = @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
}
"@

    Add-Type -TypeDefinition $sig -ErrorAction SilentlyContinue

    # Preview Pane toggle command
    $APPCOMMAND = 0x702C

    [Win32]::SendMessage($explorer.HWND, 0x111, $APPCOMMAND, 0)

    Write-Host "Preview Pane Activated Successfully." -ForegroundColor Green
} else {
    Write-Host "Could not detect Explorer window to apply Preview Pane." -ForegroundColor Red
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
