#Requires -RunAsAdministrator

<#
.SYNOPSIS
    NNuker: Professional Audit & Eradication Tool.
.DESCRIPTION
    Multi-OEM support for MSI, Lenovo, Dell, and HP.
    Level 0 provides a deep-dive audit and saves a report to the Desktop.
#>

param(
    [ValidateRange(0,5)]
    [int]$Level = -1,
    [switch]$Force,
    [string]$Store = "$env:USERPROFILE\Desktop\NNuker_Backup_$(Get-Date -Format 'yyyyMMdd_HHmm')"
)

# --- Config ---
$Targets = @(
    "C:\Windows\System32\A-Volute", "C:\Windows\SysWOW64\A-Volute",
    "C:\Windows\System32\NahimicService.exe", "$env:LOCALAPPDATA\NhNotifSys",
    "$env:ProgramData\A-Volute", "C:\Program Files\Nahimic", "C:\ProgramData\Nahimic",
    "C:\Program Files (x86)\Nahimic", "C:\Program Files\HP\HP Audio Switch",
    "$env:ProgramData\HP\Nahimic", "$env:APPDATA\HP\Nahimic"
)

# --- UI & Helpers ---
function Write-Msg ([string]$msg, [string]$color = "Cyan") {
    $ts = Get-Date -Format "HH:mm:ss"
    Write-Host "[$ts] $msg" -ForegroundColor $color
    if (Test-Path $Store) { "[$ts] $msg" | Out-File "$Store\removal.log" -Append }
}

function Show-Menu {
    Clear-Host
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "              NAHIMIC NUKER               " -ForegroundColor White
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "0: Level 0 - Detailed Audit (Saves Report)"
    Write-Host "1-5: Removal Levels (Standard is 3)"
    Write-Host "------------------------------------------"
    Write-Host "M: Manual Harvest | C: Clean Backups | R: Restore | Q: Quit"
    Write-Host ""

    $choice = Read-Host "Select Option"
    switch ($choice) {
        "Q" { exit }
        "M" { return "Harvest" }
        "C" { return "Clean" }
        "R" { return "Restore" }
        "0" { return 0 }
        "1" { return 1 }
        "2" { return 2 }
        "3" { return 3 }
        "4" { return 4 }
        "5" { return 5 }
        default { return -1 }
    }
}

function Get-Inventory {
    $inv = @{ Files=@(); Svc=@(); Tasks=@(); Apps=@(); Infs=@(); RunKeys=@(); Wmi=@(); Com=@() }

    foreach ($t in $Targets) { if (Test-Path $t) { $inv.Files += $t } }
    $inv.Svc   = Get-Service -Name "*Nahimic*" -ErrorAction SilentlyContinue
    $inv.Tasks = Get-ScheduledTask | Where-Object { $_.TaskName -match "Nahimic|A-Volute|HP.*Audio" }
    $inv.Apps  = Get-AppxPackage -AllUsers | Where-Object { $_.Name -match "Nahimic|A-Volute" }

    $inv.Infs = pnputil /enum-drivers | Select-String "oem\d+\.inf" -Context 0,3 | Where-Object { $_ -match "A-Volute|Nahimic" } | ForEach-Object {
        if ($_ -match "(oem\d+\.inf)") { $matches[1] }
    }

    $rp = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
    foreach ($p in $rp) {
        if (Test-Path $p) {
            $props = Get-ItemProperty $p
            foreach ($n in $props.PSObject.Properties.Name) {
                if ($n -match "Nahimic|A-Volute|AudioSwitch") { $inv.RunKeys += @{ Path=$p; Name=$n } }
            }
        }
    }

    $inv.Wmi = Get-WmiObject -Namespace "root\subscription" -Class __Provider | Where-Object { $_.Name -match "Nahimic|AVolute" }
    $inv.Com = Get-ChildItem "HKLM:\SOFTWARE\Classes\CLSID" -ErrorAction SilentlyContinue | Where-Object {
        (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue)."(default)" -match "Nahimic|A-Volute"
    }

    return $inv
}

# --- Runtime ---
if ($Level -eq -1 -and !$Force) {
    $Level = Show-Menu
    if ($Level -eq "Harvest") {
        if (!(Test-Path $Store)) { New-Item $Store -ItemType Directory -Force | Out-Null }
        $inv = Get-Inventory
        if ($inv.Svc) { reg export "HKLM\SYSTEM\CurrentControlSet\Services\NahimicService" "$Store\Svc_Backup.reg" /y 2>$null }
        foreach ($f in $inv.Files) { Copy-Item $f $Store -Recurse -Force -ErrorAction SilentlyContinue }
        Write-Msg "Harvest complete at $Store" "Green"; pause; exit
    }
    if ($choice -eq "Clean") {
        $Folders = Get-ChildItem ([Environment]::GetFolderPath("Desktop")) -Directory -Filter "NNuker_Backup_*" | Sort-Object CreationTime -Descending
        if ($Folders.Count -gt 3) {
            $Folders | Select-Object -Skip 3 | ForEach-Object { Remove-Item $_.FullName -Recurse -Force; Write-Msg "Deleted: $($_.Name)" "Gray" }
            Write-Msg "Cleaned old backups." "Green"
        } else { Write-Msg "Nothing to clean." "Yellow" }
        pause; exit
    }
    if ($Level -eq -1) { exit }
}

$Inv = Get-Inventory

if ($Level -eq 0) {
    if (!(Test-Path $Store)) { New-Item $Store -ItemType Directory -Force | Out-Null }
    $ReportFile = "$Store\Scan_Report.txt"
    $ReportOutput = New-Object System.Collections.Generic.List[string]
    $ReportOutput.Add("--- NAHIMIC SCAN REPORT ---")
    $ReportOutput.Add("Date: $(Get-Date)")
    $ReportOutput.Add("---------------------------")

    Write-Host "`n--- DETAILED AUDIT ---" -ForegroundColor Yellow
    $sections = @{ "Files"=$Inv.Files; "Services"=$Inv.Svc; "Drivers"=$Inv.Infs; "Tasks"=$Inv.Tasks; "WMI"=$Inv.Wmi }
    foreach ($k in $sections.Keys) {
        if ($sections[$k]) {
            $ReportOutput.Add("[$k]"); Write-Host "[$k]" -ForegroundColor Cyan
            foreach ($i in $sections[$k]) { $ReportOutput.Add("  - $i"); Write-Host "  - $i" -ForegroundColor Gray }
        }
    }
    $ReportOutput | Out-File $ReportFile
    Write-Host "`nReport saved to: $ReportFile" -ForegroundColor Green
    Write-Host "Press any key to return to menu..."
    $null = [Console]::ReadKey(); $Level = Show-Menu
    if ($Level -eq 0 -or $Level -eq -1) { exit }
}

if (!(Test-Path $Store)) { New-Item $Store -ItemType Directory -Force | Out-Null }
$RP_Key = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"
$Old_Freq = (Get-ItemProperty $RP_Key -Name "SystemRestorePointCreationFrequency" -ErrorAction SilentlyContinue).SystemRestorePointCreationFrequency ?? 1440

try {
    Write-Msg "Safety backup..."
    Set-ItemProperty $RP_Key -Name "SystemRestorePointCreationFrequency" -Value 0
    Checkpoint-Computer -Description "Nahimic_Nuke_L$Level" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
} catch {
    Write-Msg "VSS failed." "Red"
    if (!$Force) { if ((Read-Host "Continue? (y/n)") -ne "y") { exit } }
} finally {
    Set-ItemProperty $RP_Key -Name "SystemRestorePointCreationFrequency" -Value $Old_Freq
}

Write-Msg "Executing Level $Level..." "Yellow"
Get-Process | Where-Object { $_.Name -match "Nahimic|A-Volute|AudioSwitch" } | Stop-Process -Force -ErrorAction SilentlyContinue
foreach ($s in $Inv.Svc) { Stop-Service $s -Force -ErrorAction SilentlyContinue; if ($Level -ge 1) { Set-Service $s -StartupType Disabled } }

if ($Level -ge 3) {
    $Inv.Tasks | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
    foreach ($rk in $Inv.RunKeys) { Remove-ItemProperty $rk.Path $rk.Name -Force -ErrorAction SilentlyContinue }
    foreach ($f in $Inv.Files) { for ($i=0; $i -lt 3; $i++) { try { Remove-Item $f -Recurse -Force -ErrorAction Stop; break } catch { Start-Sleep -Seconds 2 } } }
}

if ($Level -ge 4) {
    $Inv.Wmi | ForEach-Object { $_.Delete() }
    $Inv.Com | ForEach-Object { Remove-Item $_.PSPath -Recurse -Force }
    foreach ($inf in $Inv.Infs) { pnputil /delete-driver $inf /uninstall /force | Out-Null }
}

if ($Level -ge 5) {
    $Restrict = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions\DenyDeviceIDs"
    if (!(Test-Path $Restrict)) { New-Item $Restrict -Force | Out-Null }
    Set-ItemProperty (Split-Path $Restrict) -Name "DenyDeviceIDs" -Value 1 -Type DWord
    Set-ItemProperty $Restrict -Name "1" -Value "ROOT\Nahimic_Mirroring"
    Set-ItemProperty $Restrict -Name "2" -Value "SWC\VEN_AVOL&AID_0300"
}

Restart-Service Audiosrv -Force -ErrorAction SilentlyContinue
Write-Msg "Done. Log: $Store" "Cyan"
if ($Force) { shutdown /r /t 60 /c "Nahimic Nuke Finalized." }
