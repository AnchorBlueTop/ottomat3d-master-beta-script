# OTTOMAT3D Master Beta Script

**Portfolio Demonstration Notice**: This repository showcases a production automation script I developed independently for Ottomat3D's beta testing program. I designed and implemented the entire system from scratch - architecture, integrations, build pipeline, and distribution. The code is provided for technical review and portfolio demonstration purposes. See [LICENSE](LICENSE) for terms.

## Project Overview

OTTOMAT3D is a cross-platform automation script that orchestrates 3D printer control across 6 different printer brands, coordinating with proprietary robotic ejection hardware. I developed this system over a 2-month period (July-September 2025) to create a self-contained, portable automation solution that beta testers could download and run without any installation or configuration hassles.

The core challenge was creating a unified interface for printers that all use completely different APIs and communication protocols, while ensuring the entire system could be distributed as a self-contained package that works out of the box on both Windows and macOS.

## Technical Challenges Solved

### Multi-Brand Printer Integration

The script integrates with 6 different printer manufacturers, each with their own API architecture:

- **Bambu Lab (A1, P1P, P1S, X1C)**: MQTT protocol with X.509 certificate authentication and real-time status streaming
- **Prusa (MK3/MK4, Core One)**: REST API with bearer token authentication via PrusaLink
- **FlashForge (AD5X, 5M Pro)**: Dual HTTP + raw TCP socket connection with custom protocol
- **Creality (K1, K1C)**: WebSocket with custom firmware requirement (requires root access)
- **Elegoo (Centauri Carbon)**: WebSocket with Rinkhals custom firmware
- **Anycubic (Kobra S1)**: Moonraker REST API with Rinkhals custom firmware

Each printer required custom connection logic, authentication handling, and status monitoring. The solution uses a Factory pattern with polymorphic printer classes that implement a common interface (`connect()`, `start_print()`, `monitor_status()`, `disconnect()`).

### Self-Contained Distribution

Beta testers have varied environments - different Python versions, missing dependencies, corporate firewalls blocking pip. The solution was to bundle everything:

```
src/_internal/
├── python-3.13-mac/        # Complete Python 3.13 runtime for macOS
└── python-3.13-windows/    # Complete Python 3.13 runtime for Windows
```

The script ships with its own Python interpreter and all dependencies pre-installed. Users extract the ZIP and run - no pip, no virtualenv, no system Python required. Total package size is ~200MB but it eliminates all installation friction.

### macOS Security and Code Signing

Initial approach used a shell script wrapper, but macOS Gatekeeper kept blocking Python files as "unidentified developer". Having beta testers manually bypass security warnings for multiple files was unprofessional and confusing.

Solution was to use PyInstaller to create a proper .app bundle, then implement an automated signing and notarization pipeline:

1. Build .app with PyInstaller
2. Sign with Developer ID certificate
3. Create DMG package
4. Submit to Apple for notarization
5. Staple notarization ticket to .app

The build_and_sign.sh script automates this entire workflow. The result is a properly signed macOS app that installs without any security warnings.

### Dynamic G-code Modification

Elegoo and Anycubic printers have a problem: their print beds need to be raised after printing (for the ejection robot to access them), but G-code files are pre-sliced with fixed coordinates. These printers also have Z-height limits that make it impossible to add the movement in the slicer.

The solution downloads the G-code file before each print and injects movement commands:

```python
# Download G-code from printer
gcode_content = self.download_gcode(filename)

# Find print completion marker
lines = gcode_content.split('\n')
end_index = self._find_print_end(lines)

# Inject bed movement
lines.insert(end_index, "G1 Z205 F600 ; Raise bed for ejection")

# Re-upload modified G-code
self.upload_gcode(filename, '\n'.join(lines))
```

For Anycubic printers specifically, we also had to inject the full LeviQ leveling sequence before each print to ensure proper bed calibration.

### Multi-Material Printing (AMS Support)

Bambu Lab printers support multi-material printing via their Automatic Material System (AMS). Multi-color .3mf files wouldn't start printing until I figured out how AMS configuration works.

Initial assumption was that we needed to map exact colors and material types for each filament slot. Spent a week trying to implement color pickers and material selection UIs.

The breakthrough: the printer completely ignores the colors and materials sent via the API mapping table. It uses whatever filaments are physically loaded in the AMS. The mapping is just a formality to enable multi-material mode.

This simplified the UX from 20+ user inputs down to a single yes/no question: "Does this print job use AMS?" The script sends placeholder values and the printer handles the rest.

FlashForge printers with Material Stations work the same way - empty material mappings work perfectly because the printer auto-maps based on tool change commands in the G-code.

### Custom Bambulabs API Package Fix

During beta testing, we discovered Bambu Lab printers' connection test was failing. The issue was in the bambulabs_api Python package itself - a bug in how it handled connection validation.

The challenge: our build script downloads the bambulabs_api package fresh from PyPI when building the macOS app. We needed to use a locally patched version instead.

Solution in build_and_sign.sh:
```bash
# Copy local modified bambulabs_api package
cp -r /path/to/modified/bambulabs_api site-packages/

# Build app with local packages
pyinstaller OTTOMAT3D-x86_64.spec
```

This ensures the .app bundle uses our patched version rather than the buggy PyPI release.

### Profile System and Bed Movement Types

Different printers move the bed in different directions for ejection:
- Y-Sling printers (Bambu A1): Move bed via Y-axis (Y200)
- Z-Bed printers (most others): Move bed via Z-axis (Z200)

The script tracks this per printer profile. Bug during development: switching between profiles with different bed types wasn't updating the movement command. A P1P profile would try to do Y200 movements (wrong), or an A1 profile would try Z200 (also wrong).

The fix ensures bed movement commands are regenerated when switching profiles, not just when initially setting up a printer.

## System Architecture

```
main.py
├── setup/
│   ├── printer_setup.py       # Printer configuration wizard
│   └── job_setup.py            # Print job queue configuration
├── operations/
│   ├── automation.py           # Main automation loop
│   ├── calibration.py          # Bed movement for ejection alignment
│   ├── ejection.py             # Eject sequence coordination
│   └── testing.py              # Connection testing utilities
├── printers/
│   ├── printer_factory.py      # Factory pattern for printer instantiation
│   ├── bambu_printer.py        # Bambu Lab MQTT implementation
│   ├── prusa_printer.py        # Prusa HTTP API implementation
│   ├── flashforge_printer.py   # FlashForge HTTP+TCP implementation
│   ├── creality_printer.py     # Creality WebSocket implementation
│   ├── elegoo_printer.py       # Elegoo WebSocket implementation
│   └── anycubic_printer.py     # Anycubic Moonraker implementation
├── ottoeject/
│   └── controller.py           # Robot hardware control via HTTP
├── config/
│   └── config_manager.py       # Configuration persistence and profile management
├── utils/
│   ├── gcode_processor.py      # G-code parsing and modification
│   ├── rack_manager.py         # Print bed storage slot validation
│   ├── macro_utils.py          # Klipper macro execution helpers
│   └── logger.py               # Structured logging with rotation
└── ui/
    └── display.py              # CLI menu system and status display
```

## Key Features

**Multi-Printer Support**: Works with 6 major 3D printer brands out of the box. Each printer integration handles brand-specific quirks (authentication, file transfer, status monitoring).

**Profile Management**: Save multiple printer configurations and switch between them instantly. Supports different printers of the same brand with different setups (e.g., A1 with AMS vs A1 without AMS).

**Queue System**: Configure multiple print jobs in advance. The script will print, eject, store, load fresh plate, and start the next job automatically.

**Rack Validation**: Prevents conflicts by tracking which storage slots are occupied. Won't let you assign two jobs to the same slot or exceed rack capacity.

**Real-Time Monitoring**: Polls printer status continuously during prints. Displays current temperature, progress percentage, time remaining, and error states.

**Automatic Bed Leveling**: For Anycubic printers, injects the full LeviQ leveling sequence before each print to ensure proper bed calibration.

**macOS App Bundle**: Properly signed and notarized .app for macOS. Windows gets a portable executable via PyInstaller.

**Comprehensive Logging**: All operations logged to rotating log files with timestamps, making troubleshooting straightforward.

## Development Timeline

**Week 1 (July)**: Core script logic, printer setup wizard, basic automation loop. Implemented support for Bambu, Prusa, Anycubic, Creality, and FlashForge printers.

**Week 2 (July)**: Rack validation system to prevent storage conflicts. Ejection sequence implementation for all supported printers.

**Week 3 (July)**: Profile management system for saving/loading multiple printer configurations. G-code modification system for Anycubic/Elegoo printers (inject Z-height movement commands).

**Week 4 (July)**: macOS shell script not working - Gatekeeper blocking Python files. Pivoted to PyInstaller .app bundle approach with custom icon.

**Week 1-2 (August)**: Built .app successfully but colleagues couldn't open it ("unidentified developer" errors). Implemented terminal wrapper, then discovered proper solution: code signing with Apple Developer ID.

**Week 3 (August)**: Created comprehensive build_and_sign.sh script for automated app building, signing, and notarization. Figured out AMS mapping for Bambu Lab multi-material prints after extensive testing.

**Week 4 (August)**: Implemented FlashForge Material Station support (similar to Bambu AMS). Added LeviQ leveling sequence injection for Anycubic printers.

**Week 1 (September)**: Bug fixes before beta launch. Fixed Bambu connection test bug (required patching bambulabs_api package). Fixed profile switching bug where bed movement type wasn't updating. Moved macOS config files to proper Application Support directory.

**Week 2 (September)**: Shipped to beta testers on Windows and macOS.

## Installation

**macOS**: Extract the .zip, open OTTOMAT3D.app. The app is signed and notarized - no security warnings.

**Windows**: Extract the .zip, run run_ottomat3d.bat. Windows Defender may require firewall rule approval on first run.

See [docs/USER_GUIDE.md](docs/USER_GUIDE.md) for complete setup instructions and usage.

## Usage Example

```
OTTOMAT3D AUTOMATION OPTIONS:
────────────────────────────────────────────────────
1. Run Last Loop (Same Printer + Same Print Jobs)
2. Use Existing Printer, Configure New Jobs
3. Select a Different Printer + New Print Jobs
4. Setup A New Printer + New Print Jobs
5. Modify Existing Printer Details
6. Change OttoEject IP Address
7. Change OttoRack Slot Count
8. Test Printer Connection
9. Test OttoEject Connection
10. Move Print Bed for Calibration
```

First-time setup (Option 4):
1. Select printer brand
2. Enter IP address
3. Enter authentication credentials (access code, API key, etc.)
4. Configure printer-specific settings (macros, bed type, AMS support)
5. Configure print jobs (filenames, storage slots)
6. Validate rack state
7. Run automation

The script handles the rest: print, monitor, eject, store, load, repeat.

## Repository Structure

```
.
├── LICENSE                     # Portfolio demonstration license
├── README.md                   # This file
├── build_and_sign.sh           # macOS app build and signing pipeline
├── terminal_wrapper.sh         # macOS app terminal wrapper
├── run_ottomat3d.command       # macOS launch script
├── docs/
│   ├── USER_GUIDE.md           # Complete user manual
│   └── screenshots/            # UI screenshots for documentation
├── src/                        # Main source code
│   ├── main.py                 # Entry point
│   ├── config/                 # Configuration management
│   ├── setup/                  # Setup wizards
│   ├── operations/             # Automation logic
│   ├── printers/               # Printer integrations
│   ├── ottoeject/              # Robot control
│   ├── utils/                  # Helper utilities
│   ├── ui/                     # CLI display
│   ├── gcode/                  # G-code templates
│   └── requirements.txt        # Python dependencies
└── windows_setup/              # Windows firewall configuration scripts
```

## Technical Skills Demonstrated

- **Software Architecture**: Factory pattern, Strategy pattern, polymorphic interfaces
- **API Integration**: REST, MQTT, WebSocket, TCP sockets
- **Cross-Platform Development**: Windows and macOS support with platform-specific builds
- **Build Automation**: PyInstaller, code signing, notarization workflows
- **Security**: Certificate-based authentication, API key management, code signing
- **CLI Design**: Intuitive menu system, real-time status updates, error handling
- **Configuration Management**: Profile system, persistent storage, validation
- **Network Programming**: Connection pooling, retry logic, timeout handling
- **Testing**: Connection validation, error simulation, recovery testing

## Known Issues

**Bambu MQTT Timeouts**: Bambu printers occasionally timeout during MQTT operations. This is handled gracefully with automatic reconnection.

**Creality Firmware Requirement**: Creality K1/K1C printers require rooted firmware for WebSocket access. This is a printer limitation, not a script issue.

**Windows Firewall**: Windows requires firewall rules for printer communication. Included batch scripts automate this setup.

## Contact

For questions about this project, contact Harshil Patel.

This code represents independent work developed for Ottomat3D during summer 2025.