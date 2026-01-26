<#
  Endpoint Deployment — Powered by SYSTEMBYTES
  Version: 3.6
  Author: Sheik Dawood
  Description: Modular, OEM-aware endpoint deployment script for Technarch clients across the UAE.
  Last Updated: 2025-10-18
#>

# Admin Rights Check
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator!"
    Pause; exit
}

# SHEIKLAB Banner
$host.UI.RawUI.WindowTitle = "Endpoint Deployment"
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
Start-Sleep -Seconds 3

# Log File Setup
# $logPath = "$env:TEMP\TeknarchInstallLog.txt"
# "Teknarch Setup Log - $(Get-Date)" | Out-File $logPath
$logDir = "C:\SHEIKLAB"
$dateTag = Get-Date -Format "yyyyMMdd_HHmmss"
$logPath = "$logDir\EndpointDeployment_$dateTag.txt"
New-Item -Path $logDir -ItemType Directory -Force | Out-Null
"SHEIKLAB Endpoint Deployment Log — $dateTag" | Out-File $logPath

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
Start-Sleep -Seconds 2


function Install-App ($Id, $Name) {
    Write-Host "Installing $Name ..." -ForegroundColor Yellow
    try {
        winget install --id $Id -e --accept-source-agreements --accept-package-agreements
        $installStatus = if ($LASTEXITCODE -eq 0) { "Success" } else { "Failed" }
    } catch {
        $installStatus = "Error: $($_.Exception.Message)"
    }
    "${Name}: $installStatus — $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File $logPath -Append
    Write-Host "${Name}: $installStatus" -ForegroundColor Cyan
    Write-Host ""
}

# 🛠️ Custom Installers
function Install-HPSupportAssistant {
    $url = "https://ftp.hp.com/pub/softpaq/sp163001-163500/sp163238.exe"
    $exe = "$env:TEMP\HP_Support_Assistant.exe"
    Invoke-WebRequest -Uri $url -OutFile $exe
    Start-Process -FilePath $exe -ArgumentList "/S" -Wait
    Remove-Item $exe -Force
}

function Install-AMDAdrenalinDriver {
    $url = "https://drivers.amd.com/drivers/installer/25.20/whql/amd-software-adrenalin-edition-25.11.1-minimalsetup-251111_web.exe"
    $exe = "$env:TEMP\amd-adrenalin-setup.exe"
    Invoke-WebRequest -Uri $url -OutFile $exe
    Start-Process -FilePath $exe -ArgumentList "/S" -Wait
    Remove-Item $exe -Force
}

function Install-NvidiaApp {
    $url = "https://us.download.nvidia.com/nvapp/client/11.0.5.266/NVIDIA_app_v11.0.5.266.exe"
    $exe = "$env:TEMP\NVIDIA_app.exe"
    Invoke-WebRequest -Uri $url -OutFile $exe
    Start-Process -FilePath $exe -ArgumentList "/S" -Wait
    Remove-Item $exe -Force
}

function Install-GigabyteControlCenter {
    $url = "https://download.gigabyte.com/FileList/Utility/GCC_24.07.02.01.zip"
    $zip = "$env:TEMP\GCC.zip"; $dest = "$env:TEMP\GCC"
    Invoke-WebRequest -Uri $url -OutFile $zip
    Expand-Archive -Path $zip -DestinationPath $dest -Force
    Start-Process "$dest\setup.exe" -ArgumentList "/S" -Wait
    Remove-Item $zip, $dest -Recurse -Force
}

# OEM Detection
$manufacturer = $sys.Manufacturer.Trim()
Write-Host "Detected OEM: $manufacturer" -ForegroundColor Cyan
switch -Wildcard ($manufacturer) {
    "*Dell*"     { Install-App "Dell.CommandUpdate" "Dell Command | Update" }
    "*LENOVO*"   { Install-App "9WZDNCRFJ4MV" "Lenovo Vantage" }
    "*ASUS*"     { Install-App "Asus.ArmouryCrate" "Asus Armoury Crate" }
    "*HP*"       { Install-HPSupportAssistant }
    "*Acer*"     { Install-App "9P8BB54NQNQ4" "Acer Care Center" }
    "*Gigabyte*" { Install-GigabyteControlCenter }
    default      { Write-Host "No OEM-specific tools required." -ForegroundColor Yellow }
}

# ====================
# CPU/GPU Detection
# ====================
if ($cpu -like "*AMD*")   { Install-AMDAdrenalinDriver }
if ($cpu -like "*Intel*") { Install-App "Intel.IntelDriverAndSupportAssistant" "Intel® Driver & Support Assistant" }
if ($gpu -like "*NVIDIA*") { Install-NvidiaApp }

# =====================================
# powerdesk — Runtime & Framework
# =====================================
$appsPowerdesk = @(
    @{ Id = "Microsoft.VCRedist.2005.x86"; Name = "Visual C++ 2005 x86" },
    @{ Id = "Microsoft.VCRedist.2008.x86"; Name = "Visual C++ 2008 x86" },
    @{ Id = "Microsoft.VCRedist.2010.x64"; Name = "Visual C++ 2010 x64" },
    @{ Id = "Microsoft.VCRedist.2010.x86"; Name = "Visual C++ 2010 x86" },
    @{ Id = "Microsoft.VCRedist.2012.x64"; Name = "Visual C++ 2012 x64" },
    @{ Id = "Microsoft.VCRedist.2012.x86"; Name = "Visual C++ 2012 x86" },
    @{ Id = "Microsoft.VCRedist.2013.x64"; Name = "Visual C++ 2013 x64" },
    @{ Id = "Microsoft.VCRedist.2013.x86"; Name = "Visual C++ 2013 x86" },
    @{ Id = "Microsoft.VCRedist.2015+.x64"; Name = "Visual C++ 2015 - 2022 x64" },
    @{ Id = "Microsoft.VCRedist.2015+.x86"; Name = "Visual C++ 2015 - 2022 x86" },
    @{ Id = "Microsoft.DotNet.DesktopRuntime.6"; Name = ".NET Desktop Runtime 6 (LTS)" },
    @{ Id = "Microsoft.DotNet.DesktopRuntime.8"; Name = ".NET Desktop Runtime 8 (LTS)" },
    @{ Id = "Microsoft.DotNet.AspNetCore.6"; Name = "ASP.NET Core Runtime 6 (LTS)" },
    @{ Id = "Microsoft.DotNet.AspNetCore.8"; Name = "ASP.NET Core Runtime 8 (LTS)" },
    @{ Id = "Oracle.JavaRuntimeEnvironment"; Name = "Java 8" }
)

# ============================
# powerbuild — Application
# ============================
$appsPowerbuild = $appsPowerdesk + @(
    @{ Id = "7zip.7zip"; Name = "7-Zip" },
    @{ Id = "Google.Chrome"; Name = "Google Chrome" },
    @{ Id = "Mozilla.Firefox"; Name = "Mozilla Firefox" },
    @{ Id = "9NKSQGP7F2NH"; Name = "WhatsApp" },
    @{ Id = "SlackTechnologies.Slack"; Name = "Slack" },
    @{ Id = "Zoom.Zoom"; Name = "Zoom Workplace" },
    @{ Id = "AnyDesk.AnyDesk"; Name = "AnyDesk" },
    @{ Id = "RustDesk.RustDesk"; Name = "RustDesk" },
    @{ Id = "Microsoft.Office"; Name = "Microsoft 365 Apps for enterprise" },
    @{ Id = "PDFgear.PDFgear"; Name = "PDFgear" }  
    # @{ Id = "JAMSoftware.TreeSize.Free"; Name = "TreeSize Free" },
    # @{ Id = "9WZDNCRFJCTK"; Name = "AutoCAD - DWG Viewer & Editor" },
    # @{ Id = "BlenderFoundation.Blender"; Name = "Blender" },
    # @{ Id = "XPDBVSS44R0L9H"; Name = "Notion" },
    # @{ Id = "Algento.Botim"; Name = "Botim" },
    # @{ Id = "9NBLGGH4XXVW"; Name = "Trello" }  
)

# =================================
# powerstack — Content Creation
# =================================
$appsPowerstack = $appsPowerbuild + @( 
    @{ Id = "Audacity.Audacity"; Name = "Audacity" },
    @{ Id = "Microsoft.Sysinternals.ZoomIt"; Name = "ZoomIt" },
    @{ Id = "EpicGames.EpicGamesLauncher"; Name = "Epic Games Launcher" },
    @{ Id = "ByteDance.CapCut"; Name = "CapCut" },
    @{ Id = "Canva.Affinity"; Name = "Affinity" },
    @{ Id = "Google.GoogleDrive"; Name = "Google Drive" },
     @{ Id = "VideoLAN.VLC"; Name = "VLC media player" },
    @{ Id = "Telegram.TelegramDesktop"; Name = "Telegram Desktop" }
    # @{ Id = "Discord.Discord"; Name = "Discord" },
    # @{ Id = "OBSProject.OBSStudio"; Name = "OBS Studio" },
    # @{ Id = "ShareX.ShareX"; Name = "ShareX" },
    # @{ Id = "Canva.Canva"; Name = "Canva Desktop" },
)

# Profile Selection
Write-Host "`nAvailable Profiles:" -ForegroundColor Cyan
Write-Host "  - powerdesk   (Runtime & Framework)"
Write-Host "  - powerbuild  (Application)"
Write-Host "  - powerstack  (Content Creation)"
$profile = Read-Host "Enter profile name"

# Profile Mapping
switch ($profile.ToLower()) {
    "powerdesk"   { $appsToInstall = $appsPowerdesk }
    "powerbuild"  { $appsToInstall = $appsPowerbuild }
    "powerstack"  { $appsToInstall = $appsPowerstack }
    default {
        Write-Warning "Unknown profile name: $profile"
        Pause; exit
    }
}

# Install Loop
Write-Host "`nStarting installation for profile: $profile" -ForegroundColor Cyan
foreach ($app in $appsToInstall) {
    Install-App -Id $app.Id -Name $app.Name
}
Write-Host "`nAll installations attempted for profile: $profile" -ForegroundColor Green

# PowerShell History Cleanup
Clear-History
$historyPath = [System.IO.Path]::Combine($env:APPDATA, 'Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt')
if (Test-Path $historyPath) {
    Remove-Item $historyPath -Force
    Write-Host "PowerShell history cleared." -ForegroundColor Green
} else {
    Write-Host "No persistent history file found." -ForegroundColor Yellow
}

# Final Message
Write-Host "`nDeployment complete. Welcome to SHEIKLAB." -ForegroundColor Cyan
Pause

















