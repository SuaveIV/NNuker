# NNuker

PowerShell utility to audit and remove Nahimic audio software from Windows systems. Works on MSI, Lenovo, HP, and Dell laptops.

---

## What This Does

Nahimic is audio enhancement software that ships on gaming laptops. Some people like it. Some people watch their CPU spike to 40% from a background process called "NahimicService" and develop strong opinions.

Common reasons for removal:

- Background processes eating CPU/RAM
- Audio crackling or distortion
- Conflicts with DAWs and streaming software
- Won't stay disabled when you turn it off

This tool has levels from "just scan" to "salt the earth."

---

## ⚠️ CRITICAL WARNING

**Read this before you run anything.**

This script makes permanent system changes. Level 4 removes audio drivers from the Windows driver store. Level 5 blacklists device IDs to prevent reinstallation. If your laptop uses Nahimic as part of its core audio stack (some MSI and Lenovo models do), removing it can break audio completely.

System Restore Points can fail. Windows Update sometimes corrupts them. If the restore point doesn't work and your audio drivers are gone, you'll need to reinstall them manually. If you don't have them backed up and can't find them online, you may need to reinstall Windows.

**This software is provided AS-IS with ZERO warranty.** No guarantees. No support. If something breaks, you fix it yourself.

If you're not comfortable reinstalling Windows or hunting down audio drivers, don't go past Level 3. If you're not sure what Level 0 does, read the rest of this file first.

---

## Quick Start

### Option 1: Double-Click (Easiest)

1. Right-click `NNuker.bat` → Run as Administrator
2. Pick your level from the menu
3. Follow prompts

### Option 2: PowerShell

```powershell
# Audit only (saves report to Desktop)
.\NNuker.ps1 -Level 0

# Standard removal
.\NNuker.ps1 -Level 3

# Nuclear with auto-restart
.\NNuker.ps1 -Level 5 -Force
```

---

## Removal Levels

| Level | Name | What It Does | Risk | Can You Undo It |
| ------- | ------ | -------------- | ------ | ----------------- |
| **0** | **Audit** | Scans system, saves report to Desktop | None | N/A |
| **1** | **Disable** | Stops services, kills processes | Low | Yes |
| **2** | **Basic** | Level 1 + permanently disable services | Low | Mostly |
| **3** | **Standard** | Level 2 + remove files, tasks, registry | Medium | From backup |
| **4** | **Deep** | Level 3 + remove drivers, COM, WMI | High | Maybe (audio drivers) |
| **5** | **Nuclear** | Level 4 + blacklist reinstallation | Very High | Probably not |

**Level 3 is usually enough.** It removes the user-facing junk without touching system drivers unless you've got a weird edge case.

---

## Safety Features

The script tries to protect you:

- Creates a System Restore Point automatically
- Manual backup option (M key in menu)
- Saves audit logs to Desktop
- Retries locked files instead of just failing
- Restarts audio service after removal

None of this guarantees you won't break something. It just makes it less likely.

---

## Menu Options

```powershell
==========================================
              NAHIMIC NUKER
==========================================
0: Level 0 - Detailed Audit (Saves Report)
1-5: Removal Levels (Standard is 3)
------------------------------------------
M: Manual Harvest | C: Clean Backups | R: Restore | Q: Quit
```

- **0-5**: Run the removal level
- **M**: Back up Nahimic files before removal
- **C**: Delete old backup folders (keeps most recent 3)
- **R**: Restore option (not implemented yet)
- **Q**: Quit

---

## What Gets Removed

### Level 3+

- Nahimic services
- Scheduled tasks
- Startup registry entries
- Store apps
- Files in Program Files, System32, and OEM folders

### Level 4+

- Driver store entries
- COM registrations
- WMI providers

### Level 5+

- Device installation blacklist (prevents Windows from reinstalling drivers)

---

## Should You Run This?

**Run it if:**

- Nahimic is eating your CPU or RAM
- You've got audio issues you think might be Nahimic
- It keeps re-enabling itself after you disable it
- You don't use any Nahimic features

**Don't run it if:**

- Audio works fine and you're just "cleaning up"
- You actually use the sound effects
- You're not sure what's causing your problem (run Level 0 first to check)
- This is a work laptop

If you're on the fence, Level 0 costs you nothing. It just scans and saves a report.

---

## Requirements

- Windows 10/11
- Administrator rights
- PowerShell 5.1+ (already on your system)

---

## Installation

1. Download `NNuker.ps1` and `NNuker.bat` to the same folder
2. Right-click `NNuker.bat` → Run as Administrator

The batch file handles elevation automatically.

---

## Usage Examples

**First scan:**

```powershell
.\NNuker.bat
# Pick 0
# Check the report on your Desktop
```

**Standard removal:**

```powershell
.\NNuker.bat
# Pick 3
# Restore point gets created
# Nahimic removed, audio service restarted
```

**Nuclear (auto-restart):**

```powershell
.\NNuker.ps1 -Level 5 -Force
# Everything removed + blacklist applied
# Auto-restarts in 60 seconds
```

**Backup first:**

```powershell
.\NNuker.bat
# Pick M
# Backup saved to Desktop
# Run again and pick removal level
```

---

## Audit Report (Level 0)

Level 0 creates a report at `~/Desktop/Nahimic_Backup_*/Scan_Report.txt`:

```text
--- NAHIMIC SCAN REPORT ---
Date: 3/15/2026 10:30:45 AM
---------------------------
[Files]
  - C:\Windows\System32\A-Volute
  - C:\Program Files\Nahimic
[Services]
  - Nahimic service (Running)
[Drivers]
  - oem42.inf
[Tasks]
  - NhNotifSys
[WMI]
  - A-Volute Provider
```

Use this to see what you're dealing with before you start deleting things.

---

## Troubleshooting

### **Script won't run**

- Right-click `NNuker.bat` → Run as Administrator
- Don't run the .ps1 file directly

### **Audio stopped working**

1. Restart computer
2. Check Device Manager for disabled audio devices
3. Reinstall audio drivers from your laptop manufacturer
4. Use System Restore if you have the restore point

### **Nahimic came back after Windows Update**

- Run Level 5 to blacklist drivers
- May need to manually block in Device Manager afterward

### **"VSS failed" error**

- Volume Shadow Copy might be disabled
- Script asks if you want to continue without restore point
- Don't continue unless you have manual backups

---

## Restoring After Removal

### **Option 1: System Restore**

1. Search → "Create a restore point"
2. Click System Restore
3. Select restore point: `Nahimic_Nuke_L[X]`
4. Follow the wizard

### **Option 2: Manual Backup**

If you used Manual Harvest (M key):

1. Open backup folder on Desktop
2. Copy files back to original locations
3. Import `Svc_Backup.reg` to restore services

---

## Command-Line Parameters

```powershell
.\NNuker.ps1 [-Level <0-5>] [-Force] [-Store <path>]

  -Level    Removal level (0-5). Leave blank for menu.
  -Force    Skip confirmations, auto-restart after Level 5.
  -Store    Custom backup location (default: Desktop)
```

Examples:

```powershell
# Silent Level 3 with custom backup
.\NNuker.ps1 -Level 3 -Store "D:\Backups\Nahimic"

# Nuclear with auto-restart, no prompts
.\NNuker.ps1 -Level 5 -Force
```

---

## Final Warnings

Read this part:

1. **Level 3+ deletes files.** They don't come back without backups.
2. **Level 4+ removes drivers.** You may need to reinstall audio drivers.
3. **Level 5 blacklists Nahimic permanently.** Windows can't auto-reinstall it.

Always run Level 0 first. Let the script create the restore point. Keep the backup folder until you're sure everything works. Test your audio immediately.

Have your laptop manufacturer's audio drivers downloaded before you start, just in case.

---
---

## Disclaimers

This is an independent community tool. There is no affiliation with, endorsement by, or connection to:

- A-Volute (Nahimic developer)
- MSI, Lenovo, HP, or Dell
- Microsoft Corporation

All company names, product names, and trademarks mentioned in this documentation are the property of their respective owners. References to these names are for compatibility information only and do not imply any business relationship or endorsement.

This tool modifies or removes software from the above companies. Use of this tool may void warranties or violate terms of service. Check your OEM's policies before proceeding.

---

## License

[MIT License.](LICENSE) Do what you want with it.

Based on the original work by [sgeraldes](https://gist.github.com/sgeraldes/97a9a2832629828865393e9437ed567a).

---

## Contributing

Bug reports welcome. Include your laptop model and what happened. The `Scan_Report.txt` from Level 0 helps.

PRs accepted for additional OEM support.

---

## Credits

- Original: sgeraldes' Check-Nahimic.ps1
