# OTTOMAT3D Master Script - User Guide

**Complete guide for beta testers**

Welcome to the OTTOMAT3D Master Automation Script! This guide will walk you through every feature and help you get the most out of your automated 3D printing setup.

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Main Menu Options](#main-menu-options)
3. [First-Time Setup](#first-time-setup)
4. [Job Configuration](#job-configuration)
5. [Printer-Specific Notes](#printer-specific-notes)
6. [Troubleshooting](#troubleshooting)
7. [Known Issues](#known-issues)
8. [Safety & Best Practices](#safety--best-practices)

---

## Getting Started

### What This Script Does

The OTTOMAT3D Master Script automates your entire 3D printing workflow:

**Print → Eject → Store → Load → Repeat**

- **Multi-Printer Support**: Works with 6 major printer brands
- **Smart Queue Management**: Handle multiple print jobs sequentially
- **Real-Time Monitoring**: Track printer status and job progress
- **Profile System**: Save and switch between multiple printer configurations
- **Collision-Free Operation**: Intelligent rack slot management prevents errors
- **Cross-Platform**: Runs on Windows, macOS, and Linux

### Supported Printers

| Brand | Models | Connection | Requirements |
|-------|--------|------------|--------------|
| **Bambu Lab** | A1, P1P, P1S, X1C | MQTT | LAN Mode + Developer Mode |
| **Prusa** | MK3/S/S+, MK4/S, Core One | HTTP API | PrusaLink Enabled |
| **FlashForge** | AD5X, 5M Pro | HTTP + TCP | LAN Mode Enabled |
| **Creality** | K1, K1C | WebSocket | Rooted Firmware |
| **Elegoo** | Centauri Carbon | Moonraker API | Rinkhals Custom Firmware |
| **Anycubic** | Kobra S1 | Moonraker API | Rinkhals Custom Firmware |

### System Requirements

- A supported 3D printer from the list above
- The assembled and calibrated OttoEject System
- A build plate storage rack (1-6 slots)
- Stable network connectivity (computer, printer, and OttoEject must be on the same network)

---

## Main Menu Options

When you launch the script, you'll see the main menu:

```
OTTOMAT3D AUTOMATION OPTIONS:
──────────────────────────────────────────────────
1. Setup A New Printer
2. Select a Different Printer
3. Start New Print Jobs
4. Run Last Loop (Same Printer + Same Print Jobs)
5. Modify Existing Printer Details
6. Change OttoEject IP Address
7. Test OttoEject Connection
8. Test Printer Connection
9. Move Print Bed for Calibration
```

### Option Descriptions

| Option | Description | When to Use |
|--------|-------------|-------------|
| **1. Setup A New Printer** | Configure a new printer from scratch | First time setup, adding a new printer |
| **2. Select a Different Printer** | Switch between saved printer profiles | When you have multiple printers configured |
| **3. Start New Print Jobs** | Configure a new print queue | Starting a new batch of prints |
| **4. Run Last Loop** | Repeat the previous print sequence | Re-running the same jobs |
| **5. Modify Printer Details** | Update IP, credentials, macros, etc. | Printer IP changed, updating settings |
| **6. Change OttoEject IP** | Update OttoEject network address | OttoEject IP address changed |
| **7. Test OttoEject** | Verify OttoEject connectivity | Troubleshooting connection issues |
| **8. Test Printer** | Verify printer connectivity | Troubleshooting connection issues |
| **9. Move Bed for Calibration** | Position bed for OttoEject setup | Initial OttoEject calibration |

---

## First-Time Setup

### Step 1: Setup A New Printer

**Always start with Option 1 on your first run.**

#### 1.1 Select Printer Brand

You'll see a list of supported printer brands:

```
SUPPORTED PRINTER BRANDS:
──────────────────────────────────────────────────
1. Bambu Lab
2. Prusa
3. FlashForge
4. Creality
5. Elegoo
6. Anycubic
```

Enter the number corresponding to your brand and press Enter.

#### 1.2 Select Printer Model (If Applicable)

For brands with multiple models, you'll need to specify:

**Bambu Lab Example:**
```
BAMBU LAB MODEL SELECTION:
1. P1P (Z-bed - Z-axis positioning)
2. P1S (Z-bed - Z-axis positioning)
3. X1C (Z-bed - Z-axis positioning)
4. A1 (Sling bed - Y-axis positioning)
```

**Prusa Example:**
```
PRUSA MODEL SELECTION:
1. MK3/MK3S/MK3S+ (Sling bed - Y-axis positioning)
2. MK4/MK4S (Sling bed - Y-axis positioning)
3. Core One (Z-bed - Z-axis positioning)
```

This is **critical** for determining the bed type (Z-bed vs. Sling bed) and loading the correct settings.

#### 1.3 Enter Printer Connection Details

The script will prompt you for printer-specific information:

**Bambu Lab Example (P1P):**
```
ENSURE LAN MODE + DEVELOPER MODE IS ENABLED IF FIRMWARE VERSION >= 01.08.02.00

Enter Printer IP Address:      [Find in: SETTINGS → WLAN → IP ADDRESS]
Enter Printer Serial Number:   [Find in: SETTINGS → DEVICE → PRINTER]
Enter Printer Access Code:     [Find in: SETTINGS → WLAN → ACCESS CODE]
```

**Prusa Example:**
```
Enter Printer IP Address:      [Find in: LCD → Settings → Network]
Enter PrusaLink API Key:       [Find in: LCD → Settings → Network → PrusaLink]
```

**FlashForge Example:**
```
Enter Printer IP Address:      [Find in: Screen → Settings → Network]
Enter Serial Number:           [Find on printer label]
Enter Check Code:              [Find in: Screen → Settings → Machine Info]
```

#### 1.4 Configure OttoEject IP

```
Enter OttoEject IP/Hostname (e.g., 192.168.XX.XX):
```

**Finding Your OttoEject IP:**
1. Open a web browser
2. Go to `http://ottoeject.local` (or use the IP if you know it)
3. Click **"Machine"** in the left-hand menu
4. Look for **"Host: wlan0 (192.168.X.X)"** in the top right

⚠️ **Recommendation:** Use the **IP address** instead of `ottoeject.local` hostname. Hostnames can be unreliable, especially on Windows.

#### 1.5 Macro Configuration

The script **automatically** generates the correct macro names based on your printer brand and model:

```
✅ Using default macros for Bambu Lab P1P:
   Eject: EJECT_FROM_BAMBULAB_P_ONE_C
   Load: LOAD_ONTO_BAMBULAB_P_ONE_C
   (These can be changed later via 'Modify Printer Details')
```

These macro names match the `printer.cfg` files provided by OTTOMAT3D.

#### 1.6 Save Your Printer Profile

```
💾 SAVE PRINTER PROFILE:
──────────────────────────────
Enter profile name (default: Bambu Lab P1P): [Your Name Here]
```

Give your configuration a memorable name (e.g., "My P1P", "Workshop Printer", etc.).

---

## Job Configuration

After setting up your printer, configure your print jobs with **Option 3: Start New Print Jobs**.

### Step 1: Define Job Count

```
PRINT JOB CONFIGURATION:
──────────────────────────────
Enter number of print jobs (1-6): 3
```

⚠️ **Recommendation:** For your first run after calibration, start with 2-3 short (10-minute) prints to verify everything works.

### Step 2: Configure Each Job

For each job, you'll define:
- Filename to print
- STORE slot (where the finished print goes)
- GRAB slot (where to get the next build plate)

**Example: Job 1**
```
📋 JOB 1 CONFIGURATION:
─────────────────────────
Enter filename for Job 1: test_cube.3mf

Enter STORE slot for Job 1 (1-6): 3
   ⚠️ This slot must be EMPTY

Enter GRAB slot for Job 1 (1-6): 2
   ⚠️ This slot must HAVE a build plate
```

**Note:** The **final job** in your sequence will NOT have a "GRAB" step (no plate to load for the next job).

### Step 3: AMS / Material Station Support

**For Bambu Lab printers with AMS:**
```
Use AMS for this job? (y/n): y
```

**For FlashForge printers with Material Station:**
```
Use Material Station for this job? (y/n): y
```

### Step 4: Rack Validation

The script will ask you to confirm the current state of your storage rack (top to bottom):

```
🗄️ RACK VALIDATION:
──────────────────────────────
Does slot 6 currently have a build plate? (y/n): n
  ⬜ Slot 6: Empty

Does slot 5 currently have a build plate? (y/n): y
  ✅ Slot 5: Has build plate

Does slot 4 currently have a build plate? (y/n): y
  ✅ Slot 4: Has build plate
...
```

The script will **simulate the entire job sequence** to ensure:
- You don't try to STORE to an occupied slot
- You don't try to GRAB from an empty slot
- All slots are used correctly

If validation passes, automation begins immediately.

---

## Printer-Specific Notes

### Bambu Lab

**Requirements:**
- Enable **LAN Mode**: Settings → WLAN → LAN Mode
- Enable **Developer Mode** (if firmware >= 01.08.02.00): Settings → General → Developer Mode
- Note your **Access Code**: Settings → WLAN → Access Code
- Note your **Serial Number**: Settings → Device → Printer

**Firmware Notes:**
- **A1:** Firmware `<= 01.04.00.00` does not require Developer Mode
- **P1P/P1S:** Firmware `<= 01.08.01.00` does not require Developer Mode
- **X1C:** Always requires LAN Mode + Developer Mode

**AMS Support:**
- Bambu Lab printers with AMS are supported
- The script will detect and map AMS slots automatically

**Known Issues:**
- MQTT connection may take extra time to disconnect (this is normal)
- If connection fails, restart the printer

---

### Prusa

**Requirements:**
- Enable **PrusaLink**: LCD Menu → Settings → Network → PrusaLink
- Note your **API Key**: LCD Menu → Settings → Network → PrusaLink → API Key

**Auto-Upload Feature:**
- The script automatically uploads `Y_POS_DWELL.gcode` or `Z_POS_DWELL.gcode` files for bed positioning
- These files are used for calibration and ejection sequences

**Model Support:**
- **MK3/MK3S/MK3S+**: Sling bed (Y-axis positioning)
- **MK4/MK4S**: Sling bed (Y-axis positioning)
- **Core One**: Z-bed (Z-axis positioning)

---

### FlashForge

**Requirements:**
- Enable **LAN Mode**
- Note your **Serial Number** (on printer label)
- Note your **Check Code**: Screen → Settings → Machine Info

**Material Station Support:**
- FlashForge printers with Material Station are supported
- Enable Material Station for multi-material prints

---

### Creality

**Requirements:**
- Printer **must be rooted** with Klipper firmware
- See `K1C_Root_and_Klipper_Installation_Guide.md` in the `CREALITY & ANYCUBIC USERS/` folder

**Important:**
- Add `G1 Z230` to your `END_PRINT` macro in `gcode_macro.cfg`
- Access at: `http://[PRINTER_IP]:4408/`

**Known Issue:**
- Printer may enter 'PAUSED' state instead of expected 'ERROR' state in some scenarios

---

### Elegoo

**Requirements:**
- Install **Rinkhals Custom Firmware**
- See `Rinkhals_Custom_Firmware_Installation_Guide.md` in the `CREALITY & ANYCUBIC USERS/` folder

**Automatic G-code Preprocessing:**
- The script automatically downloads G-code files before each print
- Adds `G1 Z205 F600` to the end of the file for bed positioning
- If the command already exists, the script won't duplicate it

**Known Issue:**
- Elegoo Centauri Carbon has not been thoroughly tested with this master script

---

### Anycubic

**Requirements:**
- Install **Rinkhals Custom Firmware**
- See `Rinkhals_Custom_Firmware_Installation_Guide.md` in the `CREALITY & ANYCUBIC USERS/` folder

**Automatic G-code Preprocessing:**
- The script automatically downloads G-code files before each print
- Adds `G1 Z200 F600` to the end of the file for bed positioning
- If the command already exists, the script won't duplicate it

**Calibration Note:**
- For **Option 9 (Move Print Bed)**, the script adds a +13mm compensation
- This accounts for a consistent discrepancy between direct G-code vs. end-of-file commands

**Known Issue:**
- Print percentage may stall despite the print progressing normally

---

## Troubleshooting

### Cannot Connect to OttoEject

**Solutions:**
1. Verify all devices are on the same network
2. Use IP address instead of `ottoeject.local` hostname
3. Ping the OttoEject: `ping [OTTOEJECT_IP]`
4. Restart the OttoEject Raspberry Pi
5. Check Mainsail interface is accessible: `http://[OTTOEJECT_IP]`

---

### Cannot Connect to Printer

**Bambu Lab:**
- Ensure LAN Mode + Developer Mode are enabled (latest firmware)
- Verify Access Code and Serial Number are correct
- Restart the printer

**Prusa:**
- Ensure PrusaLink is enabled
- Verify API Key is correct
- Check printer is not in sleep mode

**FlashForge:**
- Ensure LAN Mode is enabled
- Verify Check Code and Serial Number

**Creality:**
- Verify printer is rooted and Moonraker is running
- Check WebSocket connection on port 4408
- Confirm `G1 Z230` in `END_PRINT` macro

**Anycubic/Elegoo:**
- Verify Rinkhals firmware is installed
- Check Moonraker API is accessible on port 7125
- Verify G-code preprocessing completed successfully

---

### Connection Lost During Script

**Solutions:**
1. Check network stability
2. Ensure your computer doesn't go to sleep during automation
3. For Bambu Lab on long prints (60+ minutes), the script should auto-reconnect
4. Restart the script if connection doesn't recover

---

### Firewall Issues (Windows)

**Solutions:**
1. Ensure Windows Defender Firewall rules were created correctly
2. Run firewall scripts as Administrator
3. If using third-party antivirus, configure manually or temporarily disable
4. See [Windows Setup Guide](WINDOWS_SETUP.md) for details

---

## Known Issues

### Anycubic Kobra S1
- **Issue:** Print percentage sometimes stalls despite print progressing normally
- **Workaround:** The print will still complete - ignore the stalled percentage

### Bambu Lab P-Series
- **Issue:** Cannot connect to printer despite correct credentials
- **Solution:** Restart the printer to fix the issue
- **Note:** Long MQTT disconnection times are normal

### Creality K1/K1C
- **Issue:** Printer enters 'PAUSED' state instead of expected 'ERROR' state
- **Workaround:** Monitor print status manually if needed

### Elegoo Centauri Carbon
- **Issue:** Limited testing with this printer
- **Note:** Some features may not work as expected

### OttoEject
- **Issue:** Hostname (`ottoeject.local`) is sometimes unreliable, especially on Windows
- **Solution:** Use the IP address instead
- **Issue:** Cannot connect to OttoEject Mainsail interface
- **Solution:** Restart the OttoEject Raspberry Pi

---

## Safety & Best Practices

### Before Starting Automation

1. **Verify Build Plates:** Ensure all build plates are correctly seated in the rack
2. **Test Macros:** Run OttoEject macros manually from Mainsail interface to verify calibration
3. **Start Small:** Always test with 2-3 short jobs before running overnight sequences
4. **Check Network:** Ensure stable network connectivity for all devices

### During Automation

1. **Monitor First Run:** Stay nearby during the first automation run to catch any issues
2. **Check Logs:** Review log files in `src/logs/` for detailed status updates
3. **Don't Interrupt:** Avoid manually interfering with the printer or OttoEject during automation

### After Automation

1. **Review Logs:** Check logs for any errors or warnings
2. **Inspect Prints:** Verify print quality and ejection success
3. **Update Rack State:** Make note of final rack configuration for next run

---

## Log Files

For detailed debugging, check the log files located in the `src/logs/` directory. 

Each run creates a new file with a timestamp:
- `ottomat3d_YYYYMMDD_HHMMSS.log`

Logs contain:
- Detailed status updates for each operation
- Error messages and stack traces
- Printer status at each polling interval
- OttoEject macro execution results

---

## Additional Resources

- **[Windows Setup Guide](WINDOWS_SETUP.md)** - Firewall configuration, installation
- **[macOS Setup Guide](MACOS_SETUP.md)** - Security bypass, .app installation
- **[Main README](../README.md)** - Technical overview and architecture

---

## Support

For beta testers:
- Contact OTTOMAT3D support through official channels
- Provide log files when reporting issues
- Include printer model, firmware version, and error messages

---

**Last Updated:** September 2025  
**Script Version:** 1.0.0

---

*Thank you for participating in the OTTOMAT3D Beta Testing Program!*
