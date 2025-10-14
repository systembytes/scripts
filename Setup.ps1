# SHEIKLAB - Installer v2.0 (PowerShell Edition)
$host.UI.RawUI.WindowTitle = "SHEIKLAB - Installer v2.0"
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
Write-Host "WELCOME MR. SHEIK" -ForegroundColor Cyan
Start-Sleep -Seconds 5

# Check for admin rights
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator!"
    Pause
    exit
}

# Define install function
function Install-App {
    param (
        [string]$Id,
        [string]$Name
    )
    Write-Host "Installing $Name ..." -ForegroundColor Yellow
    winget install --id $Id -e --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -eq 0) {
        Write-Host "$Name installed successfully!" -ForegroundColor Green
    } else {
        Write-Host "Failed to install $Name" -ForegroundColor Red
    }
    Write-Host ""
}

# App list
$apps = @(
    @{ Id = "Microsoft.VCRedist.2010.x64"; Name = "Microsoft Visual C++ 2010 x64" },
    @{ Id = "Microsoft.VCRedist.2010.x86"; Name = "Microsoft Visual C++ 2010 x86" },
    @{ Id = "Microsoft.VCRedist.2012.x64"; Name = "Microsoft Visual C++ 2012 x64" },
    @{ Id = "Microsoft.VCRedist.2012.x86"; Name = "Microsoft Visual C++ 2012 x86" },
    @{ Id = "Microsoft.VCRedist.2013.x64"; Name = "Microsoft Visual C++ 2013 x64" },
    @{ Id = "Microsoft.VCRedist.2013.x86"; Name = "Microsoft Visual C++ 2013 x86" },
    @{ Id = "Microsoft.VCRedist.2015+.x64"; Name = "Microsoft Visual C++ 2015-2022 x64" },
    @{ Id = "Microsoft.VCRedist.2015+.x86"; Name = "Microsoft Visual C++ 2015-2022 x86" },
    # @{ Id = "Microsoft.Office"; Name = "Microsoft 365 Apps for enterprise" },
    @{ Id = "Google.Chrome"; Name = "Google Chrome" }
    # @{ Id = "Mozilla.Firefox"; Name = "Mozilla Firefox (en-US)" },
    # @{ Id = "RustDesk.RustDesk"; Name = "RustDesk" },
    # @{ Id = "AnyDesk.AnyDesk"; Name = "AnyDesk" },
    # @{ Id = "PDFgear.PDFgear"; Name = "PDFgear" },
    # @{ Id = "7zip.7zip"; Name = "7-Zip" },
    # @{ Id = "VideoLAN.VLC"; Name = "VLC media player" },
    # @{ Id = "Notepad++.Notepad++"; Name = "Notepad++" },
    # @{ Id = "Intel.IntelDriverAndSupportAssistant"; Name = "Intel® Driver & Support Assistant" },
    # @{ Id = "Dell.CommandUpdate"; Name = "Dell Command | Update" },
    # @{ Id = "9NKSQGP7F2NH"; Name = "WhatsApp" },
    # @{ Id = "SlackTechnologies.Slack"; Name = "Slack" },
    # @{ Id = "Zoom.Zoom"; Name = "Zoom Workplace" }
)

# Run installs
foreach ($app in $apps) {
    Install-App -Id $app.Id -Name $app.Name
}

Write-Host ""
Write-Host "All installations attempted." -ForegroundColor Cyan
Pause

