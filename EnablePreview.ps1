# 🖥️ Branding Banner
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
# 🔵 ENABLE PREVIEW PANE IN FILE EXPLORER
# -----------------------------------------------------

Write-Host "`nEnabling Preview Pane in File Explorer..." -ForegroundColor Yellow

$signature = @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll")]
    public static extern IntPtr FindWindowEx(IntPtr parentHwnd, IntPtr childAfterHwnd, string className, string windowTitle);

    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
}
"@

Add-Type $signature

$explorer = [Win32]::FindWindow("CabinetWClass", $null)
if ($explorer -ne 0) {
    $APPCOMMAND = 0x702C  # Preview Pane toggle command
    [Win32]::SendMessage($explorer, 0x111, $APPCOMMAND, 0)
    Write-Host "Preview Pane Toggled." -ForegroundColor Green
} else {
    Write-Host "No active Explorer window found. Open a folder and run again." -ForegroundColor Red
}

Start-Sleep -Seconds 1

# -----------------------------------------------------
# 🔵 UNBLOCK FILES
# -----------------------------------------------------

$folders = @(
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\Documents",
    "$env:USERPROFILE\Videos",
    "$env:USERPROFILE\Music"
)

Write-Host "`nUnblocking Files..." -ForegroundColor Yellow

Get-ChildItem $folders -Filter *.pdf -Recurse -ErrorAction SilentlyContinue | Unblock-File
Get-ChildItem $folders -Recurse -ErrorAction SilentlyContinue | Unblock-File

Write-Host "All files unblocked." -ForegroundColor Green

# -----------------------------------------------------
# 🔵 CLEAR POWERSHELL HISTORY
# -----------------------------------------------------

Write-Host "`nClearing PowerShell History..." -ForegroundColor Yellow

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

Write-Host "`nWelcome to SHEIKLAB." -ForegroundColor Cyan
Pause
