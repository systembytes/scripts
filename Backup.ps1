<#
  Backup — Powered by SYSTEMBYTES 
  Author: Sheik Dawood
  Description: Modular backup script with branding, logging, and folder exclusions.
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

# Drive Selection
$drives = Get-PSDrive -PSProvider 'FileSystem' | Where-Object { $_.Free -gt 0 }
Write-Host "Available Drives:" -ForegroundColor Cyan
$drives | ForEach-Object { Write-Host " [$($_.Name)] $($_.Root)" }

$selectedDrive = Read-Host "Enter the drive letter to use for backup (e.g., E)"
if (-not (Test-Path "$selectedDrive`:\")) {
    Write-Warning "Drive $selectedDrive does not exist. Please check and try again."
    Read-Host "Press Enter to exit"
    exit
}
$usbDrive = "$selectedDrive`:\Backup"
$userName = $env:USERNAME
$backupFolder = Join-Path $usbDrive $userName
if (-not (Test-Path $backupFolder)) {
    New-Item -Path $backupFolder -ItemType Directory | Out-Null
    Write-Host "Created backup folder: $backupFolder" -ForegroundColor Green
}

# Log File Setup
$logPath = Join-Path $backupFolder "SHEIKLAB_BackupLog.txt"
"Backup Log - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File $logPath

# System Info
$sys  = Get-CimInstance -ClassName Win32_ComputerSystem
$cpu  = (Get-CimInstance -ClassName Win32_Processor).Name
$gpu  = (Get-CimInstance -ClassName Win32_VideoController).Name -join " + "
$ram  = [math]::Round($sys.TotalPhysicalMemory / 1GB, 2)

@"
System Info:
PC Name     : $env:COMPUTERNAME
Username    : $env:USERNAME
Model       : $($sys.Model)
RAM         : $ram GB
CPU         : $cpu
GPU         : $gpu
"@ | Out-File $logPath -Append

Write-Host "`n==================== SYSTEM PROFILE ====================" -ForegroundColor Cyan
Write-Host " PC Name     : $env:COMPUTERNAME"
Write-Host " Username    : $env:USERNAME"
Write-Host " Model       : $($sys.Model)"
Write-Host " RAM         : $ram GB"
Write-Host " CPU         : $cpu"
Write-Host " GPU         : $gpu"
Write-Host "========================================================`n" -ForegroundColor Cyan
Start-Sleep -Seconds 1

# Backup Function
function Backup-Folder {
    param($source, $target, $label, $exclude = @())

    Write-Host "`nBacking up $label ..." -ForegroundColor Yellow
    $robocopyLog = Join-Path $backupFolder "robocopy_$label.log"

    $excludeArgs = $exclude | ForEach-Object { "/XD `"$($_)`"" }
    $excludeString = $excludeArgs -join " "

    $cmd = "robocopy `"$source`" `"$target`" /E /ZB /R:3 /W:5 /TEE /LOG:`"$robocopyLog`" $excludeString"
    Invoke-Expression $cmd

    $exitCode = $LASTEXITCODE
    if ($exitCode -ge 8) {
        Write-Host "❌ ${label}: FAILED — Exit Code $exitCode" -ForegroundColor Red
        "❌ ${label}: FAILED — Exit Code $exitCode" | Out-File $logPath -Append
        "See detailed log: robocopy_$label.log" | Out-File $logPath -Append
    } else {
        Write-Host "✅ ${label}: SUCCESS — $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green
        "✅ ${label}: SUCCESS — $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File $logPath -Append
    }
}

# Start Backup
Backup-Folder "$env:USERPROFILE\Desktop"   "$backupFolder\Desktop"   "Desktop"
Backup-Folder "$env:USERPROFILE\Documents" "$backupFolder\Documents" "Documents" @(
    "$env:USERPROFILE\Documents\My Pictures",
    "$env:USERPROFILE\Documents\My Videos",
    "$env:USERPROFILE\Documents\My Music"
)
Backup-Folder "$env:USERPROFILE\Downloads" "$backupFolder\Downloads" "Downloads"
Backup-Folder "$env:USERPROFILE\Pictures"  "$backupFolder\Pictures"  "Pictures"
Backup-Folder "$env:USERPROFILE\Videos"    "$backupFolder\Videos"    "Videos"
Backup-Folder "$env:USERPROFILE\Music"     "$backupFolder\Music"     "Music"

# PowerShell History Cleanup
Clear-History
$historyPath = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
if (Test-Path $historyPath) {
    Remove-Item $historyPath -Force
    Write-Host "PowerShell history cleared." -ForegroundColor Green
} else {
    Write-Host "No persistent history file found." -ForegroundColor Yellow
}

# Log Completion
"Backup completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File $logPath -Append

# ✅ Final Message
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "Backup Complete!"
Write-Host "Files saved in: $backupFolder"
Write-Host "Log saved in: $logPath"
Write-Host "============================================================" -ForegroundColor Green
Read-Host "Press Enter to exit"

