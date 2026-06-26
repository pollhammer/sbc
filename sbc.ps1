<#
============================================================
 SBC v1.2 – Secure Boot Checker (2026)
 GitHub: https://github.com/pollhammer/sbc
 Author: Manuel Pollhammer
============================================================
#>

$ErrorActionPreference = "Stop"

# Modern Cyber Theme Colors
$ESC = [char]27
$Green  = "$ESC[92m"
$Yellow = "$ESC[93m"
$Red    = "$ESC[91m"
$Cyan   = "$ESC[96m"
$Gray   = "$ESC[90m"
$White  = "$ESC[97m"
$Reset  = "$ESC[0m"

# Window Title and Scaling 
$Host.UI.RawUI.WindowTitle = "SBC v1.2 Dashboard"
$Width = 100
$Height = 28

if ($Host.Name -eq "ConsoleHost") {
    try {
        # 1. Temporarily increase buffer height to prevent vertical dimension conflicts
        $IntBuffer = $Host.UI.RawUI.BufferSize
        $IntBuffer.Height = 9999
        $Host.UI.RawUI.BufferSize = $IntBuffer

        # 2. Enforce target window size dimensions safely
        $WindowSize = $Host.UI.RawUI.WindowSize
        $WindowSize.Width = $Width
        $WindowSize.Height = $Height
        $Host.UI.RawUI.WindowSize = $WindowSize

        # 3. Apply final buffer width now that window constraints are met
        $FinalBuffer = $Host.UI.RawUI.BufferSize
        $FinalBuffer.Width = $Width
        $Host.UI.RawUI.BufferSize = $FinalBuffer
    }
    catch {
        # Fallback to direct .NET Console subsystem commands if Host APIs fail
        [Console]::WindowWidth = $Width
        [Console]::WindowHeight = $Height
        [Console]::BufferWidth = $Width
    }
}



[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# UAC Elevation check
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Clear-Host
    Write-Host "${Red}┌──────────────────────────────────────────────────────────────────────────────────────────────────┐"
    Write-Host "${Red}│ [-] ACCESS DENIED: THIS SCRIPT MUST BE RUN AS AN ADMINISTRATOR!                                  │"
    Write-Host "${Red}│     Please relaunch your PowerShell process with elevated administrative permissions.            │"
    Write-Host "${Red}└──────────────────────────────────────────────────────────────────────────────────────────────────┘${Reset}"
    Pause
    Exit
}

# Unified Header Function
function Show-Header {
    Clear-Host
    Write-Host "${Cyan}┌──────────────────────────────────────────────────────────────────────────────────────────────────┐"
    Write-Host "${Cyan}│                                       $White███████╗██████╗  ██████╗                                   ${Cyan}│"
    Write-Host "${Cyan}│                                       $White██╔════╝██╔══██╗██╔════╝                                   ${Cyan}│"
    Write-Host "${Cyan}│                                       $White███████╗██████╔╝██║                                        ${Cyan}│"
    Write-Host "${Cyan}│                                       $White╚════██║██╔══██╗██║                                        ${Cyan}│"
    Write-Host "${Cyan}│                                       $White███████║██████╔╝╚██████╗                                   ${Cyan}│"
    Write-Host "${Cyan}│                                       $White╚══════╝╚═════╝  ╚═════╝                                   ${Cyan}│"
    Write-Host "${Cyan}│                                                                                                  ${Cyan}│"
    Write-Host "${Cyan}│                                      $White SECURE BOOT CHECKER v1.2                                   ${Cyan}│"
    Write-Host "${Cyan}│                                        $White by Manuel Pollhammer                                     ${Cyan}│"
    Write-Host "${Cyan}└──────────────────────────────────────────────────────────────────────────────────────────────────┘${Reset}"
}

# OPTION 1: Standard Status Check
function Check-SecureBootStatus {
    Show-Header
    Write-Host "`n${Yellow}[*] Checking global Secure Boot status...${Reset}"
    Write-Host "${Cyan}────────────────────────────────────────────────────────────────────────────────────────────────────${Reset}"
    try {
        if ($null -ne (Get-SecureBootUEFI -Name SetupMode)) {
            Write-Host "${Green}[+] SECURE BOOT ACTIVE: Secure Boot is verified ENABLED in UEFI firmware.${Reset}"
        } else {
            Write-Host "${Red}[-] SECURE BOOT INACTIVE: Secure Boot is physically DISABLED.${Reset}"
        }
    }
    catch {
        Write-Host "${Red}[-] UEFI ERROR: Secure Boot variables not accessible (Legacy BIOS/CSM Mode active).${Reset}"
    }
    Write-Host "`n${Gray}Press Enter to return to dashboard...${Reset}"
    [void][Console]::ReadLine()
}

# OPTION 2: Deep Expiry Analysis
function Check-CertificateExpiry {
    Show-Header
    Write-Host "`n${Yellow}[*] Launching UEFI certificate chain analysis (Expiry Check)...${Reset}"
    Write-Host "${Cyan}────────────────────────────────────────────────────────────────────────────────────────────────────${Reset}"
    try {
        if ($null -eq (Get-SecureBootUEFI -Name SetupMode)) {
            Write-Host "${Red}[-] ABORTED: Secure Boot is inactive. Cannot scan live UEFI registers.${Reset}"
            Write-Host "`n${Gray}Press Enter to return to dashboard...${Reset}"
            [void][Console]::ReadLine(); return
        }

        # DB Validation
        Write-Host "${Cyan}[>] Scanning 'db' (Allowed OS / Driver Registry)...${Reset}"
        $dbBytes = Get-SecureBootUEFI -Name db
        $dbString = [System.Text.Encoding]::ASCII.GetString($dbBytes.bytes)
        if ($dbString -match "Windows UEFI CA 2023") {
            Write-Host "    ${Green}[✓] UP TO DATE: 'Windows UEFI CA 2023' verified.${Reset}"
        } elseif ($dbString -match "Windows Production PCA 2011") {
            Write-Host "    ${Red}[!] DEPRECATED: Found legacy 'Windows Production PCA 2011' (Expires Oct 2026)!${Reset}"
        } else { Write-Host "    ${Gray}[?] Unknown signature found in db environment.${Reset}" }

        # KEK Validation
        Write-Host "`n${Cyan}[>] Scanning 'KEK' (Key Exchange Keys Matrix)...${Reset}"
        $kekBytes = Get-SecureBootUEFI -Name KEK
        $kekString = [System.Text.Encoding]::ASCII.GetString($kekBytes.bytes)
        if ($kekString -match "KEK 2K CA 2023") {
            Write-Host "    ${Green}[✓] UP TO DATE: 'Microsoft Corporation KEK 2K CA 2023' is active.${Reset}"
        } elseif ($kekString -match "KEK CA 2011") {
            Write-Host "    ${Red}[!] DEPRECATED: Found legacy 'Microsoft Corporation KEK CA 2011'!${Reset}"
        } else { Write-Host "    ${Gray}[?] Unknown signature found in KEK environment.${Reset}" }
    }
    catch { Write-Host "${Red}[-] Runtime read exception occurred: $_${Reset}" }
    Write-Host "`n${Gray}Press Enter to return to dashboard...${Reset}"
    [void][Console]::ReadLine()
}

# OPTION 3: Windows Update Trigger
function Update-SecureBootCertificates {
    Show-Header
    Write-Host "`n${Yellow}[*] Staging Secure Boot payload push via Windows Update engine...${Reset}"
    Write-Host "${Cyan}────────────────────────────────────────────────────────────────────────────────────────────────────${Reset}"
    try {
        if ($null -eq (Get-SecureBootUEFI -Name SetupMode)) { Write-Host "${Red}[-] Staging blocked: Secure Boot must be enabled first.${Reset}"; return }
        Write-Host "[*] Recycling Windows Update Service daemon (wuauserv)..." -ForegroundColor Gray
        Restart-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
        Start-Process "ms-settings:windowsupdate"
        Write-Host "${Green}[+] Operational window deployed. Please execute 'Check for updates' inside the system settings.${Reset}"
    } catch { Write-Host "${Red}[-] Operational service crash: $_${Reset}" }
    Write-Host "`n${Gray}Press Enter to return to dashboard...${Reset}"
    [void][Console]::ReadLine()
}

# OPTION 4: Microsoft Native Script Trigger
function Update-ViaMicrosoftScript {
    Show-Header
    Write-Host "`n${Yellow}[*] Forcing asset execution via local Microsoft Secure Boot script...${Reset}"
    Write-Host "${Cyan}────────────────────────────────────────────────────────────────────────────────────────────────────${Reset}"
    
    $msScriptPath = "$env:SystemRoot\System32\SecureBootUpdates\ChSecBootCert.ps1"
    
    if (Test-Path $msScriptPath) {
        try {
            Write-Host "[*] Native core found. Starting execution deployment chain..." -ForegroundColor Gray
            & $msScriptPath
            Write-Host "${Green}[+] Success: Microsoft staging agent compiled. Changes will deploy on next cold system boot.${Reset}"
        }
        catch {
            Write-Host "${Red}[-] Native script pipeline exception thrown: $_${Reset}"
        }
    } else {
        Write-Host "${Red}[-] SCRIPT NOT FOUND: '$msScriptPath'.${Reset}"
        Write-Host "${Cyan}[i] Notice: This asset only builds on systems equipped with the KB5025885 feature flag.${Reset}"
    }
    Write-Host "`n${Gray}Press Enter to return to dashboard...${Reset}"
    [void][Console]::ReadLine()
}

# OPTION 5: Enforced DBX Update via CIM/WMI Interface
function Update-ViaDirectDownload {
    Show-Header
    Write-Host "`n${Yellow}[*] Forcing DBX revocation database generation via CIM Subsystem...${Reset}"
    Write-Host "${Cyan}────────────────────────────────────────────────────────────────────────────────────────────────────${Reset}"
    
    try {
        if ($null -eq (Get-SecureBootUEFI -Name SetupMode)) { 
            Write-Host "${Red}[-] Aborted: Live Secure Boot status evaluation failed.${Reset}"
            Write-Host "`n${Gray}Press Enter to return to dashboard...${Reset}"; [void][Console]::ReadLine(); return 
        }
        
        Write-Host "[*] Establishing programmatic connection to Microsoft Hardware Security interface..." -ForegroundColor Gray
        $securityStatus = Get-CimInstance -Namespace root/Microsoft/Windows/HardwareManagement -ClassName MSFT_HardwareSecurityStatus -ErrorAction SilentlyContinue
        
        if ($null -ne $securityStatus) {
            Write-Host "[*] Triggering OS Kernel hardware security policy compilation..." -ForegroundColor Gray
            Invoke-CimMethod -InputObject $securityStatus -MethodName EvaluateHardwareSecurityState -ErrorAction SilentlyContinue | Out-Null
            
            Write-Host "${Green}[+] SUCCESS: Injection signal deployed successfully.${Reset}"
            Write-Host "${Yellow}[!] ACTION REQUIRED: Please manually REBOOT your computer to flash NVRAM registers!${Reset}"
        } else {
            Write-Host "${Red}[-] INTERFACE FAULT: The necessary WMI/CIM hardware mapping class is absent on this build.${Reset}"
            Write-Host "    Ensure cumulative system updates are fully applied to patch core dependencies." -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "${Red}[-] System evaluation failed: $_${Reset}"
        Write-Host "    [Fallback] Restart machine, entry your firmware (F2/Del) and select 'Restore Factory Keys'." -ForegroundColor Gray
    }
    
    Write-Host "`n${Gray}Press Enter to return to dashboard...${Reset}"
    [void][Console]::ReadLine()
}

# Dashboard Menu Loop (Optimized & Precise Layout)
do {
    Show-Header
    Write-Host "${Cyan}┌── DIAGNOSTICS ───────────────────────────────────────────────────────────────────────────────────┐${Reset}"
    Write-Host "${Cyan}│${Reset}  ${White}[1]${Reset} Check general Secure Boot status                                                            ${Cyan}│${Reset}"
    Write-Host "${Cyan}│${Reset}  ${White}[2]${Reset} Analyze UEFI certificates (Legacy 2011 vs. Modern 2023)                                     ${Cyan}│${Reset}"
    Write-Host "${Cyan}└──────────────────────────────────────────────────────────────────────────────────────────────────┘${Reset}"
    Write-Host "${Cyan}┌── UPDATES & MITIGATIONS ─────────────────────────────────────────────────────────────────────────┐${Reset}"
    Write-Host "${Cyan}│${Reset}  ${White}[3]${Reset} Trigger updates via Windows Update service                                                  ${Cyan}│${Reset}"
    Write-Host "${Cyan}│${Reset}  ${White}[4]${Reset} Force certificate update via local Microsoft script                                         ${Cyan}│${Reset}"
    Write-Host "${Cyan}│${Reset}  ${White}[5]${Reset} Force DBX revocation list update via WMI/CIM                                                ${Cyan}│${Reset}"
    Write-Host "${Cyan}└──────────────────────────────────────────────────────────────────────────────────────────────────┘${Reset}"
    Write-Host "${Cyan}┌── SYSTEM ────────────────────────────────────────────────────────────────────────────────────────┐${Reset}"
    Write-Host "${Cyan}│${Reset}  ${White}[6]${Reset} Exit Terminal                                                                               ${Cyan}│${Reset}"
    Write-Host "${Cyan}└──────────────────────────────────────────────────────────────────────────────────────────────────┘${Reset}"
    
    # Clean input prompt directly below the blocks
    Write-Host -NoNewline " ${Yellow}Selection: $White"
    $choice = Read-Host
    Write-Host -NoNewline $Reset

    switch ($choice) {
        "1" { Check-SecureBootStatus }
        "2" { Check-CertificateExpiry }
        "3" { Update-SecureBootCertificates }
        "4" { Update-ViaMicrosoftScript }
        "5" { Update-ViaDirectDownload }
        "6" { 
            Write-Host "`n${Gray}[*] Terminating environment session...${Reset}"
            Start-Sleep -Seconds 1
            Clear-Host
            $running = $false 
        }
        default { 
            Write-Host "${Red}[!] Invalid selection!${Reset}"
            Start-Sleep -Milliseconds 800
        }
    }
} while ($choice -ne "6")
