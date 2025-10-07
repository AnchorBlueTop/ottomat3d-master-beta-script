# macOS Setup Guide

This guide explains how to set up and run the OTTOMAT3D automation script on macOS.

## System Requirements

- **Operating System**: macOS 11 (Big Sur) or newer
- **Network Access**: Printer and OTTOeject system must be accessible on the same local network
- **Network Frequency**: All devices must be on the 2.4GHz frequency
- **Administrator Access**: Required to bypass macOS security warnings

## Installation Steps

### 1. Download and Extract

1. Download the latest macOS release: `ottomat3d-beta-test-macos.zip`
2. Extract the archive by double-clicking the .zip file
3. Move the extracted folder to your desired location (e.g., Desktop or Applications)

### 2. First Launch and Security Bypass

macOS Gatekeeper will block the app on first launch because it's not from the App Store. Follow these steps to allow it:

#### Step 1: Attempt to Open the App

1. Navigate to the extracted folder
2. Double-click `OTTOMAT3D.app` to launch
3. You will see a security warning:
   ```
   "OTTOMAT3D" cannot be opened because the developer cannot be verified.
   macOS cannot verify that this app is free from malware.
   ```
4. Click **OK** to close the warning

#### Step 2: Allow the App in Security Settings

1. Click the Apple logo in the top-left corner
2. Select **"System Settings"** (or "System Preferences" on macOS 12 and earlier)
3. Click **"Privacy & Security"** in the sidebar
4. Scroll down to the **Security** section
5. Look for the message:
   ```
   "OTTOMAT3D" was blocked from use because it is not from an identified developer.
   ```
6. Click **"Open Anyway"** next to this message
7. Enter your administrator password when prompted (or use Touch ID)

#### Step 3: Confirm Opening

1. A final confirmation dialog will appear:
   ```
   macOS cannot verify the developer of "OTTOMAT3D". Are you sure you want to open it?
   ```
2. Click **"Open"**

The app will now launch in Terminal. You only need to do this security bypass once. Subsequent launches will work without warnings.

### 3. Alternative: Bypass Security via Terminal (Advanced)

If you prefer, you can bypass Gatekeeper using Terminal:

```bash
xattr -cr /path/to/OTTOMAT3D.app
```

Replace `/path/to/` with the actual path to where you extracted the app.

### 4. Using the Script

Once the security bypass is complete:

1. Double-click `OTTOMAT3D.app` to launch
2. Terminal will open with the OTTOMAT3D menu
3. Follow the on-screen instructions to set up your printer and configure jobs

## Configuration File Location

The script stores its configuration at:
```
~/Library/Application Support/OTTOMAT3D/config.txt
```

To view or manually edit:
```bash
open ~/Library/Application\ Support/OTTOMAT3D/
```

## Troubleshooting

### App Won't Launch After Security Bypass

**Symptoms**: Double-clicking the app does nothing, or Terminal opens and closes immediately

**Solutions**:
- Right-click OTTOMAT3D.app and select "Open" instead of double-clicking
- Check that the security bypass was completed successfully
- Try the Terminal bypass method mentioned above
- Verify the app wasn't damaged during download (re-download if necessary)

### Cannot Find ottoeject.local

**Symptoms**: Script cannot find OTTOeject by hostname

**Solutions**:
- macOS has Bonjour built-in, but ensure network discovery is enabled
- Use the OTTOeject's IP address directly instead of hostname
- Verify OTTOeject is powered on and connected to network
- Check all devices are on the same network and frequency (2.4GHz)

### Terminal Closes Immediately

**Symptoms**: Terminal window opens briefly then closes

**Solutions**:
- Check the logs at: `~/Library/Application Support/OTTOMAT3D/logs/`
- Ensure the app bundle is complete (should be ~200MB)
- Try launching from Terminal manually:
  ```bash
  /path/to/OTTOMAT3D.app/Contents/MacOS/OTTOMAT3D
  ```

### Permission Denied Errors

**Symptoms**: Script reports permission errors when reading/writing files

**Solutions**:
- macOS may have blocked file system access
- Go to System Settings → Privacy & Security → Files and Folders
- Ensure OTTOMAT3D has access to necessary folders

### Firewall Blocking Connections

**Symptoms**: Cannot connect to printer or OTTOeject

**Solutions**:
- Go to System Settings → Network → Firewall
- If firewall is enabled, click "Options" and add OTTOMAT3D to allowed applications
- Or temporarily disable firewall to test if it's the cause

## Uninstalling

To completely remove OTTOMAT3D:

1. Delete the OTTOMAT3D.app from your Applications or extracted folder
2. Remove the configuration directory:
   ```bash
   rm -rf ~/Library/Application\ Support/OTTOMAT3D/
   ```

## Signing and Notarization

Note: This portfolio version of the app may not be signed and notarized. The production version distributed to beta testers includes proper Apple Developer ID signing and notarization to avoid all security warnings.

For developers: See `build_and_sign_SANITIZED.sh` for the automated build, signing, and notarization pipeline.

## Support

For issues not covered in this guide, check the logs at:
```
~/Library/Application Support/OTTOMAT3D/logs/ottomat3d.log
```