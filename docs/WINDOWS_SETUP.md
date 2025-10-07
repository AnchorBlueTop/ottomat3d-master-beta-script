# Windows Setup Guide

This guide explains how to set up and run the OTTOMAT3D automation script on Windows.

## System Requirements

- **Operating System**: Windows 10 or newer
- **Network Access**: Printer and OTTOeject system must be accessible on the same local network
- **Network Frequency**: All devices must be on the 2.4GHz frequency
- **Bonjour Service**: Highly recommended for reliable device discovery by hostname (e.g., `ottoeject.local`)

## Important Firewall Notice

These setup instructions are designed for **Windows Defender Firewall** (the built-in Windows firewall).

If you have third-party antivirus software (Norton, McAfee, Kaspersky, Avast, etc.), you will need to either:
1. Temporarily disable the third-party antivirus during script operation
2. Manually configure firewall rules in your antivirus software

The batch scripts provided will NOT work with third-party firewall systems.

## Installation Steps

### 1. Download and Extract

1. Download the latest Windows release: `ottomat3d-beta-test-win64.zip`
2. Extract the archive to your desired location (e.g., Desktop)
3. Navigate to the extracted folder

### 2. Configure Windows Defender Firewall Rules

The firewall blocks the script from communicating with printers by default. The provided `.bat` scripts create the necessary outbound firewall rules.

#### Required: OTTOeject and Python Firewall Rules

1. Locate `1_OTTOEJECT_FIREWALL_RULE_(REQUIRED).bat` in the windows_setup folder
2. Right-click the file and select **"Run as administrator"**
3. Allow the script to make changes when prompted
4. A command window will appear briefly and close automatically

This creates firewall rules for:
- Python.exe (allows all outbound connections)
- Port 80 (OTTOeject communication)

#### Optional: Printer-Specific Firewall Rules

Run the appropriate script for your printer brand:

- `2_BAMBU_LAB_FIREWALL_RULE.bat` - For Bambu Lab printers (MQTT port 8883)
- `3_PRUSA_FIREWALL_RULE.bat` - For Prusa printers (HTTP port 80)
- `4_FLASHFORGE_FIREWALL.bat` - For FlashForge printers (ports 8080, 8898, 8899)
- `5_CREALITY_FIREWALL_RULE.bat` - For Creality printers (port 7125)
- `6_ELEGOO_FIREWALL_RULE.bat` - For Elegoo printers (port 7125)
- `7_ANYCUBIC_FIREWALL_RULE.bat` - For Anycubic printers (port 7125)

Each must be run **as administrator** using the same process as step 1.

### 3. Verify Firewall Configuration (Optional)

To confirm firewall rules were created:

1. Search for "Windows Defender" in the Start Menu
2. Open **Windows Defender Firewall with Advanced Security**
3. Click **Outbound Rules** in the left sidebar
4. Look for rules named:
   - "Allow Python.exe"
   - "Allow OTTOeject on Port 80"
   - Printer-specific rules (if you ran those scripts)

### 4. Launch the Script

1. In the extracted folder, double-click `run_ottomat3d.bat`
2. A command window will open with the OTTOMAT3D menu
3. Follow the on-screen instructions to set up your printer and configure jobs

## Troubleshooting

### Connection Lost During Script

**Symptoms**: Script disconnects from printer or OTTOeject mid-operation

**Solutions**:
- Check that all devices are on the same network
- Verify devices are using 2.4GHz frequency (not 5GHz)
- Restart router if issues persist
- Check firewall rules are active

### Cannot Access ottoeject.local

**Symptoms**: Script cannot find OTTOeject by hostname

**Solutions**:
- Install Bonjour service (included with iTunes or can be downloaded separately)
- Use the OTTOeject's IP address directly instead of hostname
- Verify OTTOeject is powered on and connected to network

### Firewall Rules Not Created

**Symptoms**: Batch scripts don't create rules, or errors appear

**Solutions**:
- Confirm Windows Defender is your active firewall (not third-party antivirus)
- Right-click and select "Run as administrator" (required)
- If using third-party antivirus, see Third-Party Antivirus section below

### Script Won't Start

**Symptoms**: Double-clicking `run_ottomat3d.bat` does nothing

**Solutions**:
- Try running as administrator
- Check that Python executable exists in the bundled `_internal` folder
- Verify extraction completed successfully (folder should be ~200MB)

## Third-Party Antivirus Users

If you have Norton, McAfee, Kaspersky, Avast, or other third-party antivirus:

### Option 1: Manual Firewall Configuration

Access your antivirus firewall settings and create outbound rules for:
- Python.exe (allow all traffic)
- Ports: 80, 443, 7125, 8080, 8883, 8898, 8899
- Allow LAN communication

### Option 2: Temporarily Disable Antivirus

Temporarily disable the third-party antivirus during script operations. Remember to re-enable it after use.

## Removing Firewall Rules

To remove all firewall rules created by the setup scripts:

1. Run `REMOVE_ALL_FIREWALL_RULES.bat` as administrator
2. All OTTOMAT3D-related rules will be deleted

## Support

For issues not covered in this guide, check the logs in `src/logs/ottomat3d.log` for diagnostic information.