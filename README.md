# OTTOMAT3D Master Automation Application

I designed and built this entire automation application over a 10 week period for Ottomat3D's beta testing program. Every component - architecture, API integrations, build pipeline, and distribution system - was developed independently.

![Main Menu](docs/screenshots/main_menu.png)

## What This Is

OTTOMAT3D Master Beta Script is a cross-platform CMD/Terminal application that orchestrates 3D printer control across 6 different manufacturer APIs, coordinating with robotic ejection hardware to enable fully automated multi-job print workflows. I had developed indivudal python scripts beforehand for each printer model earlier, which was then combined into one unviversal 'master' script that contains every functionality. This represents approximately 300+ hours of work spanning June through September 2025.

Prominent Features of the Script Application: 
- Complete printer abstraction layer supporting 6 different communication protocols
- Self-contained Python runtime distribution (~24MB)
- Profile management system with persistent configuration
- Real-time status monitoring and error recovery
- Advanced features like AMS mapping and dynamic G-code modification
- Professionally signed and notarized macOS application
- Automated build and distribution pipeline

## Development Timeline

### Week 1-2 (Early July 2025): Foundation
- Built core automation orchestration engine
- Implemented printer setup wizard and configuration system
- Integrated 6 printer brands (Bambu Lab, Prusa, FlashForge, Creality, Elegoo, Anycubic)
- Created rack validation system to prevent storage slot conflicts
- Developed ejection sequence coordination with robotic hardware

**Technical Challenge**: Each printer uses completely different APIs - MQTT with certificates, HTTP with bearer tokens, WebSockets requiring custom firmware, dual HTTP+TCP connections. Had to design a Factory pattern that abstracts all of this behind a unified interface.

### Week 3 (Mid July): Advanced Features
- Implemented profile management system for multiple printer configurations
- Built dynamic G-code modification engine for Elegoo/Anycubic printers
- Solved bed-raising problem: Print bed must be lowered for the ejection bot to grab hold off the build plate. 
  Solution: download G-code before each print, inject `G1 Z205 F600` movement command after print completion, re-upload modified file.
  Some printers we can inject G-code commands dynamically as they home (G28) downwards instead of upwards which we can't do with finished prints on the build plate.

### Week 4 (Late July): macOS Distribution Crisis
Initial approach used shell script wrapper, but macOS Gatekeeper blocked it. Every Python file triggered "unidentified developer" warnings. Having beta testers bypass security warnings for 20+ random files was unprofessional.

**Solution**: Pivoted to PyInstaller to create proper .app bundle with custom icon. This required learning PyInstaller configuration, handling hiddenimports, and bundling the entire Python 3.13 runtime.

Week 4 (Late July): macOS Distribution Crisis
Initial approach used shell script wrapper, but macOS Gatekeeper blocked it. Every Python file triggered "unidentified developer" warnings. Having beta testers bypass security warnings for 20+ random files was unprofessional.

Solution: Pivoted to PyInstaller to create proper .app bundle with custom icon. This required learning PyInstaller configuration, handling hiddenimports, and bundling the entire Python 3.13 runtime.

New Problem: Built .app on M-series MacBook (ARM64). Only worked on Apple Silicon Macs. Intel Mac users couldn't run it at all.

## Week 5-6 (Early August): Code Signing Hell & Cross-Architecture Nightmare
Built .app successfully, but colleagues couldn't open it. Terminal would flash and close immediately. Spent 2 weeks debugging multiple issues simultaneously:
Architecture Problem: PyInstaller on Apple Silicon builds ARM64-only binaries. Beta testers had Intel Macs, M1 Macs, M2 Macs - complete mix. The ARM64 .app wouldn't even launch on Intel Macs. Even among Apple Silicon Macs, builds on M1 Max didn't work reliably on M2.
Solution Path:

Researched Rosetta 2 as compatibility layer for running x86_64 on Apple Silicon
Attempted separate builds for ARM64 and x86_64 (maintaining two build pipelines)
Discovered architecture-specific Python packages (websockets, Pillow) caused issues
Architecture-specific .so files (compiled C extensions) wouldn't work cross-architecture

Final Solution: Universal build approach using Rosetta 2 compatibility. Modified build_and_sign.sh to:

Backup ARM64-specific packages (websockets, Pillow with ARM binaries)
Download x86_64 versions of architecture-specific packages
Verify binaries are actually x86_64 (not ARM64 disguised)
Build .app with x86_64 packages
Restore ARM64 packages after build (keep dev environment clean)
Result: x86_64 .app that runs via Rosetta 2 on Apple Silicon, natively on Intel Macs

Code Signing Issues (parallel to architecture work):

Terminal wrapper permission problems
Gatekeeper blocking without clear error messages
Learning about Apple's hardened runtime requirements
Even with Apple Developer ID, apps were blocked

Breakthrough: Complete workflow requires Developer ID signing of every component + notarization + ticket stapling. Built automated build_and_sign.sh pipeline handling:

Cross-architecture package swapping
Component-level code signing (executables, wrappers, bundles)
Notarization submission and monitoring
Automatic ticket stapling
Build verification on both architectures

### Week 7 (Mid August): AMS Implementation
Multi-material .3mf files from Bambu Studio wouldn't start printing. Spent a week implementing Bambu Lab's Automatic Material System (AMS) configuration.

Initial approach: tried to get user input for filament colors, material types, and slot mappings, based off online implementation.

**Major Discovery**: The printer requires an 'AMS Mapping Table' to be sent before we call the 'start_print' API. Mapping Table does not require correct filament details for each slot, completely ignores the colors and materials sent via the API. It uses whatever filaments are physically loaded in the AMS. The mapping is just a formality to enable multi-material mode. 
The gcode file must also have had their filaments 'synced' before being sliced in Bambu Studio. 

This revelation simplified the entire feature from 5+ user inputs down to a single yes/no question: "Does this print use AMS?"

### Week 8 (Late August): Material Station + LeviQ
- Implemented FlashForge Material Station (similar to Bambu AMS but uses empty material mappings)
- Added Anycubic LeviQ full bed leveling sequence injection before each print. 
- Anycubic printers weren't doing complete leveling via script, had to reverse-engineer the LeviQ sequence 

### Week 9 (Early September): Critical Bug Fixes
Final push before beta testing launch:

**Bug 1 - Bambu Connection Test**: Connection validation was failing. Root cause was in the bambulabs_api package itself. Had to fork and patch the package locally, then modify build_and_sign.sh to use local package instead of remote PyPI version.

**Bug 2 - Profile Switching**: Y-Sling printers (Bambu A1) move bed via Y-axis. Z-Bed printers (most others) move via Z-axis. Profile switching wasn't updating the movement commands. A P1P profile would try `Y200` movement (wrong), A1 profile would try `Z200` (also wrong). Fixed by correctly mapping bed movement commands based on printer type on profile switch.

**Improvement**: Moved macOS config file from app bundle to `~/Library/Application Support/OTTOMAT3D/` (proper macOS convention) as write permissions prevented from writing within package contents.

### Week 10 (Mid September): Beta Launch
Shipped Windows and macOS versions to beta testers.

## Technical Architecture

### Multi-Protocol Printer Abstraction

```python
# Factory pattern creates appropriate printer instance
printer = PrinterFactory.create_printer(brand, config)

# Polymorphic interface works across all brands
printer.connect()
printer.start_print(filename, use_ams=True)
status = printer.get_status()
printer.disconnect()
```

Behind this simple interface:
- **Bambu Lab**: MQTT with X.509 certificates, JSON status messages, AMS slot mapping
- **Prusa**: REST API with bearer tokens, multipart file upload, PrusaLink integration
- **FlashForge**: Dual connection - HTTP for control + raw TCP socket for file transfer
- **Creality**: WebSocket with JSON-RPC, requires rooted firmware
- **Elegoo**: WebSocket with Moonraker API, Rinkhals custom firmware
- **Anycubic**: Moonraker REST API, Rinkhals firmware, LeviQ leveling injection

### Self-Contained Distribution

Challenge: Beta testers have different Python versions, missing dependencies, corporate firewalls blocking pip.

Solution: Bundle complete Python 3.13 runtime with all dependencies:
```
src/_internal/
├── python-3.13-mac/        # Complete Python interpreter
│   └── lib/python3.13/
│       └── site-packages/  # All dependencies pre-installed
└── python-3.13-windows/    # Windows equivalent
```

Result: 24MB zip download that works anywhere. No pip, no virtualenv, no system Python required.

### Dynamic G-code Modification

Elegoo and Anycubic printers have fixed Z-height ceilings. The ejection robot needs bed raised to Z205, but print files are already sliced with max Z180.

```python
def inject_bed_movement(self, gcode_path):
    # Download G-code from printer
    content = self.download_gcode(gcode_path)
    
    # Find print end marker
    lines = content.split('\n')
    end_index = self._find_print_end(lines)
    
    # Inject movement command
    lines.insert(end_index, "G1 Z205 F600 ; Raise bed for ejection")
    
    # Re-upload modified G-code
    self.upload_gcode(gcode_path, '\n'.join(lines))
```

For Anycubic, also inject complete LeviQ bed leveling sequence before print start.

### macOS Code Signing Pipeline

```bash
# build_and_sign.sh automates everything:

# 1. Build .app with PyInstaller
pyinstaller OTTOMAT3D-x86_64.spec

# 2. Sign with Developer ID
codesign --deep --force --options runtime \
    --sign "Developer ID Application: ..." \
    dist/OTTOMAT3D.app

# 3. Create DMG
hdiutil create -volname OTTOMAT3D \
    -srcfolder dist/OTTOMAT3D.app \
    -ov -format UDZO dist/OTTOMAT3D.dmg

# 4. Submit for Apple notarization
xcrun notarytool submit dist/OTTOMAT3D.dmg \
    --wait

# 5. Staple notarization ticket
xcrun stapler staple dist/OTTOMAT3D.app
```

Result: Properly signed macOS app that installs without any security warnings.

### AMS (Automatic Material System) Implementation

The breakthrough that simplified everything:

```python
# What I thought I needed:
ams_config = {
    'slots': [
        {'slot': 0, 'color': user_input_color_1, 'material': user_input_material_1},
        {'slot': 1, 'color': user_input_color_2, 'material': user_input_material_2},
        # ... complex user input collection
    ]
}

# What actually works:
ams_config = {
    'slots': [
        {'slot': 0, 'color': '808080', 'material': 'PETG'},  # Placeholder
        {'slot': 1, 'color': '000000', 'material': 'PETG'},  # Printer ignores
        {'slot': 2, 'color': 'FF0000', 'material': 'PETG'},  # these values
        {'slot': 3, 'color': '0000FF', 'material': 'PETG'},  # completely
    ]
}
```
The printer uses whatever filaments are physically loaded. The API configuration is just to enable multi-material mode. This reduced the feature from 5+ inputs to one yes/no question.

```python
                self.logger.info(" Starting print with AMS mapping...")
                ams_mapping = [0, 1, 2, 3]  # T0→Slot1, T1→Slot2, T2→Slot3, T3→Slot4
                
                try:
                    response = self.printer_instance.start_print(
                    filename, "", use_ams=True, ams_mapping=ams_mapping, flow_calibration=True)
                    self.logger.info(f"✅ AMS print started successfully!")
                    
                except TimeoutError:
                    self.logger.info(" AMS print command sent (timeout on response - normal)")
                except Exception as e:
                    self.logger.error(f"❌ AMS print failed: {e}")
                    return False
            else:
                # Single material print
                self.logger.info(f" Starting single-material print: {filename}")
                try:
                    response = self.printer_instance.start_print(
                    filename, "", use_ams=False)
                except TimeoutError:
                    self.logger.info("Print command sent (timeout on response - normal)")
            
            # Wait and validate
            wait_time = self.first_job_wait_seconds if is_first_job else (20 if use_ams else 10)
            self.logger.info(f" Waiting {wait_time}s for initialization...")
            time.sleep(wait_time)
```
The printer requires an AMS Mapping Table to be send before we call the start the print via API. 
This was discovered spontanoeously after our Bambu Lab X1-C showed an "AMS Mapping Table Error" message after an hour of hanging. 

## Key Features

**Profile System**: Save multiple printer configurations. Switch between different printers or different configurations of the same printer instantly.

**Job Queue**: Configure multiple print jobs in advance. Application handles print → eject → store → load → next job automatically.

**Rack Validation**: Prevents conflicts by tracking storage slot assignments and simulating entire automation loop. Won't let you assign two jobs to the same slot. 

**Real-Time Monitoring**: Status updates every 10 seconds during prints. Shows temperature, progress, time remaining, error states.

**Error Recovery**: Connection retry logic, timeout handling, graceful degradation if monitoring fails.

**Cross-Platform**: Single codebase works on Windows and macOS with platform-specific builds.

![Job Setup and Rack Validation](docs/screenshots/job_setup_and_rack_validation.png)

## System Requirements

**Windows**:
- Windows 10 or newer
- Windows Defender Firewall (or manual configuration for third-party antivirus)

**macOS**:
- macOS 11 (Big Sur) or newer
- Administrator access for security bypass

**Network**:
- All devices (computer, printer, OttoEject) on same local network
- 2.4GHz frequency recommended

## Installation

### Windows
1. Download `ottomat3d-beta-test-win64.zip`
2. Extract to desired location
3. Run firewall configuration scripts in `windows_setup/` folder
4. Double-click `run_ottomat3d.bat`

See [docs/WINDOWS_SETUP.md](docs/WINDOWS_SETUP.md) for detailed instructions.

### macOS
1. Download `ottomat3d-beta-test-macos.zip`
2. Extract and move to Applications or Desktop
3. Right-click OTTOMAT3D.app → Open (bypass Gatekeeper)
4. Go to System Settings → Privacy & Security → Click "Open Anyway"

See [docs/MACOS_SETUP.md](docs/MACOS_SETUP.md) for detailed instructions.

## Usage

![Printer Selection](docs/screenshots/printer_selection.png)

First-time setup:
1. Launch application
2. Select Option 4: "Setup A New Printer"
3. Choose printer brand
4. Enter IP address and authentication details
5. Configure printer-specific settings (macros, AMS, bed type)
6. Configure print jobs (filenames, storage slots)
7. Validate rack state
8. Run automation

![Profile Selection](docs/screenshots/profile_selection.png)

The application monitors print progress in real-time, coordinates with the ejection robot after each print, and automatically proceeds to the next job in the queue.

![Automation Progress](docs/screenshots/Automation_sequence.jpeg)

## Technical Skills Demonstrated

- **Software Architecture**: Factory pattern, Strategy pattern, Singleton pattern
- **API Integration**: REST, MQTT, WebSocket, TCP sockets - 6 different protocols
- **Network Programming**: Certificate-based auth, bearer tokens, connection pooling, retry logic
- **Cross-Platform Development**: Windows and macOS with platform-specific builds
- **Build Automation**: PyInstaller, code signing, notarization, DMG creation
- **CLI Design**: Menu system, real-time updates, input validation, error messages
- **Configuration Management**: INI-style config files, profile system, validation
- **Error Handling**: Graceful degradation, retry logic, user-friendly error messages
- **Testing**: Connection validation, integration testing with hardware
- **Documentation**: User guides, setup instructions, troubleshooting

## Project Structure

```
.
├── LICENSE                     # Portfolio demonstration license
├── README.md                   # This file
├── ARCHITECTURE.md             # Deep technical documentation
├── build_and_sign.sh           # macOS build pipeline (original)
├── build_and_sign_SANITIZED.sh # Sanitized version for portfolio
├── src/
│   ├── main.py                 # Application entry point
│   ├── config/                 # Configuration management
│   ├── setup/                  # Setup wizards
│   ├── operations/             # Automation logic
│   ├── printers/               # Printer integrations (6 brands)
│   ├── ottoeject/              # Robot hardware control
│   ├── utils/                  # Utilities (G-code, logging, rack management)
│   ├── ui/                     # CLI interface
│   └── gcode/                  # G-code templates
├── docs/
│   ├── USER_GUIDE.md           # Complete user manual
│   ├── WINDOWS_SETUP.md        # Windows installation guide
│   ├── MACOS_SETUP.md          # macOS installation guide
│   └── screenshots/            # Application screenshots
└── windows_setup/              # Windows firewall configuration scripts
```

## Known Limitations

- Bambu Lab MQTT connections can timeout (handled gracefully with reconnection)
- Creality printers require root to inject 'G1 Z200 F600' into end of 'END_PRINT' macro. 
- Anycubic printers require Rinkhals custom firmware
- Elegoo printers cannot move print bed independetly for calibration without starting an entire print job. 
- Windows requires firewall rules for printer communication
- macOS .app requires security bypass on first launch

## Repository Notes

This repository showcases the production application as deployed to beta testers. Personal information has been sanitized from build scripts (Developer ID, paths). The complete source code, build system, and documentation are included for technical review.

For questions about this project, contact Harshil Patel.

---

**Development Period**: July - September 2025  
**Total Conversations**: 88+ over 2 months  
**Lines of Code**: 5,000+ Python  
**Beta Testers**: Active testing program  
**Status**: Production deployment complete
