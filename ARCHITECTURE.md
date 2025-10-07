# OTTOMAT3D Architecture Documentation

This document provides a detailed technical overview of the OTTOMAT3D automation system architecture, design decisions, and implementation details.

## Table of Contents

1. [System Overview](#system-overview)
2. [Design Patterns](#design-patterns)
3. [Module Architecture](#module-architecture)
4. [Printer Integration Layer](#printer-integration-layer)
5. [Configuration Management](#configuration-management)
6. [Build System](#build-system)
7. [Error Handling Strategy](#error-handling-strategy)
8. [Performance Considerations](#performance-considerations)

## System Overview

OTTOMAT3D is a Python-based automation orchestrator that coordinates 3D printers with robotic ejection hardware. The system must handle:

- Heterogeneous printer APIs (6 different communication protocols)
- Real-time status monitoring during multi-hour print jobs
- Configuration persistence across sessions
- Error recovery and retry logic
- Cross-platform execution (Windows/macOS)

### High-Level Flow

```
User Input → Configuration → Printer Connection → Job Queue → Automation Loop
                                                                      ↓
                                                    Print → Monitor → Eject → Store → Load → Next Job
```

### Core Components

- **Entry Point**: `main.py` - CLI menu system and user interaction
- **Configuration**: `config_manager.py` - Profile and job persistence
- **Setup**: `printer_setup.py`, `job_setup.py` - Configuration wizards
- **Operations**: `automation.py`, `ejection.py` - Core automation logic
- **Printers**: 6 printer-specific implementations - API adapters
- **Hardware**: `ottoeject/controller.py` - Robot communication
- **Utilities**: G-code processing, rack management, logging

## Design Patterns

### Factory Pattern - Printer Instantiation

The `PrinterFactory` class abstracts printer creation based on brand selection. This allows the automation logic to work with a generic `Printer` interface without knowing implementation details.

```python
class PrinterFactory:
    @staticmethod
    def create_printer(brand, config):
        if brand == "Bambu Lab":
            return BambuPrinter(config)
        elif brand == "Prusa":
            return PrusaPrinter(config)
        elif brand == "FlashForge":
            return FlashForgePrinter(config)
        # ... etc
```

**Why This Pattern**: Each printer brand has completely different connection requirements, authentication schemes, and status monitoring mechanisms. The Factory pattern lets us add new printer brands without modifying the automation logic.

### Strategy Pattern - Printer Operations

Each printer class implements a common interface but with brand-specific strategies:

```python
class BambuPrinter:
    def connect(self):
        # MQTT connection with certificate auth
        
    def start_print(self, filename, use_ams=False):
        # Send MQTT publish command with AMS configuration
        
    def get_status(self):
        # Parse MQTT status messages
        
    def disconnect(self):
        # Clean MQTT disconnect
```

**Why This Pattern**: The automation loop calls `printer.start_print()` without caring whether it's talking to an MQTT broker, WebSocket connection, or HTTP API. Each printer handles its own protocol.

### Singleton Pattern - Configuration Manager

The `ConfigManager` class maintains a single source of truth for configuration:

```python
class ConfigManager:
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
```

**Why This Pattern**: Configuration needs to be consistent across all modules. Multiple instances could lead to desynchronization between what's in memory and what's on disk.

## Module Architecture

### Setup Module (`setup/`)

Responsible for initial configuration and job setup.

**printer_setup.py**:
- Presents brand selection menu
- Collects brand-specific connection details (IP, credentials, macro names)
- Tests printer connection
- Saves configuration to profile

**job_setup.py**:
- Collects job queue information (filenames, storage slots)
- Validates rack state (no conflicts, within capacity)
- For Bambu printers, asks about AMS usage per job
- Saves job configuration

### Operations Module (`operations/`)

Contains the core automation logic.

**automation.py**:
```python
def run_automation(printer, jobs, ottoeject):
    for job in jobs:
        printer.start_print(job['filename'], job.get('use_ams', False))
        
        while printer.is_printing():
            status = printer.get_status()
            display_status(status)
            time.sleep(10)
        
        ottoeject.eject(job['store_slot'])
        ottoeject.load_fresh_plate()
```

**ejection.py**:
- Coordinates ejection sequence with OttoEject hardware
- Sends HTTP commands to robot controller
- Handles timeouts and retry logic

**calibration.py**:
- Moves print bed to calibration position
- Different movement commands based on bed type (Y-sling vs Z-bed)

**testing.py**:
- Connection validation for printers and OttoEject
- Reports success/failure with diagnostic information

### Printers Module (`printers/`)

Each printer implementation handles:
1. Connection establishment
2. Authentication
3. File transfer (if applicable)
4. Print initiation
5. Status monitoring
6. Disconnection

#### Bambu Lab Implementation

Uses paho-mqtt for MQTT communication:

```python
def connect(self):
    self.client = mqtt.Client()
    self.client.tls_set(cert_reqs=ssl.CERT_REQUIRED)
    self.client.username_pw_set("bblp", self.access_code)
    self.client.connect(self.ip, 8883)
    self.client.subscribe(f"device/{self.serial}/report")
```

**Challenges**:
- Certificate-based authentication requires proper SSL context
- MQTT messages are JSON with nested status fields
- AMS configuration requires specific filament mapping structure
- Connection can be slow (5-10 seconds)

#### Prusa Implementation

Uses requests library for HTTP API:

```python
def start_print(self, filename):
    headers = {"X-Api-Key": self.api_key}
    response = requests.post(
        f"http://{self.ip}/api/files/local/{filename}",
        headers=headers,
        json={"command": "select", "print": True}
    )
```

**Challenges**:
- API key must be in header for every request
- File upload is multipart/form-data
- Status polling returns extensive JSON (must parse carefully)

#### FlashForge Implementation

Uses dual connection: HTTP for control, TCP for file transfer:

```python
def upload_file(self, filepath):
    # HTTP endpoint for initiating upload
    control_response = requests.post(f"http://{self.ip}/upload")
    
    # Raw TCP socket for file data
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.connect((self.ip, 8899))
    with open(filepath, 'rb') as f:
        sock.sendall(f.read())
```

**Challenges**:
- Must coordinate two separate connections
- TCP protocol is undocumented (reverse engineered)
- File transfer has no progress indication

#### Creality / Elegoo / Anycubic Implementations

All three use WebSocket connections but with different message formats:

```python
async def connect(self):
    self.ws = await websockets.connect(f"ws://{self.ip}:7125/websocket")
    
async def start_print(self, filename):
    message = json.dumps({
        "jsonrpc": "2.0",
        "method": "printer.print.start",
        "params": {"filename": filename},
        "id": 1
    })
    await self.ws.send(message)
```

**Challenges**:
- Requires asyncio event loop integration
- Firmware must be custom (Rinkhals for Anycubic/Elegoo, rooted for Creality)
- Connection stability varies

### OttoEject Module (`ottoeject/`)

Communicates with the ejection robot over HTTP:

```python
def eject(self, slot_number):
    response = requests.post(
        f"http://{self.ip}/eject",
        json={"slot": slot_number}
    )
    
    # Poll for completion
    while not self.is_eject_complete():
        time.sleep(2)
```

**Design Decision**: HTTP was chosen over MQTT/WebSocket for simplicity. The robot doesn't need real-time bidirectional communication - just command/response.

### Configuration Module (`config/`)

Manages persistent storage in `config.txt`:

```
[PRINTER]
PRINTER_BRAND=Bambu Lab
PRINTER_IP=192.168.1.100
ACCESS_CODE=12345678
SERIAL_NUMBER=ABC123
BED_TYPE=Z

[JOBS]
TOTAL_JOBS=3
JOB_1_FILENAME=part1.3mf
JOB_1_USE_AMS=true
JOB_1_STORE_SLOT=1
JOB_2_FILENAME=part2.gcode
JOB_2_USE_AMS=false
JOB_2_STORE_SLOT=2
...
```

**File Location**:
- **Windows**: Same directory as script
- **macOS**: `~/Library/Application Support/OTTOMAT3D/config.txt`

**Why Different Locations**: macOS apps shouldn't write to their own bundle directory (security/sandboxing). Application Support is the standard location for user-modifiable config files.

### Utils Module (`utils/`)

**gcode_processor.py**:
Parses and modifies G-code files:

```python
def inject_z_movement(gcode_path, z_height):
    with open(gcode_path, 'r') as f:
        lines = f.readlines()
    
    # Find end of print (before "END_PRINT" macro)
    for i, line in enumerate(lines):
        if 'END_PRINT' in line or 'M84' in line:
            lines.insert(i, f"G1 Z{z_height} F600\n")
            break
    
    with open(gcode_path, 'w') as f:
        f.writelines(lines)
```

**rack_manager.py**:
Validates storage slot assignments:

```python
def validate_rack_state(jobs, rack_capacity):
    assigned_slots = [job['store_slot'] for job in jobs]
    
    # Check for duplicates
    if len(assigned_slots) != len(set(assigned_slots)):
        return False, "Duplicate slot assignments detected"
    
    # Check capacity
    if max(assigned_slots) > rack_capacity:
        return False, f"Slot {max(assigned_slots)} exceeds rack capacity"
    
    return True, "Rack state valid"
```

**logger.py**:
Rotating file logger with structured output:

```python
def setup_logger(name):
    logger = logging.getLogger(name)
    handler = RotatingFileHandler(
        'logs/ottomat3d.log',
        maxBytes=10*1024*1024,  # 10MB
        backupCount=5
    )
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    return logger
```

## Printer Integration Layer

### Connection Management

Each printer maintains its own connection state:

```python
class BambuPrinter:
    def __init__(self, config):
        self.connected = False
        self.client = None
        self.last_status = {}
```

**Thread Safety**: Not required - script is single-threaded with synchronous operations. Async operations (WebSocket printers) use asyncio event loop but don't share state between coroutines.

### Status Monitoring

Two approaches depending on printer type:

**Push-based (Bambu MQTT)**:
```python
def on_message(client, userdata, msg):
    data = json.loads(msg.payload)
    self.last_status = data
    
self.client.on_message = on_message
```

**Pull-based (Everyone else)**:
```python
def monitor_print():
    while True:
        status = printer.get_status()  # HTTP/WebSocket request
        display_status(status)
        time.sleep(10)  # Poll every 10 seconds
```

**Trade-off**: Push is more efficient but requires maintaining persistent connection. Pull is simpler and works with stateless HTTP APIs.

### File Transfer Strategies

**Bambu**: Files already on SD card (pre-loaded by user via Bambu Studio)
**Prusa**: Upload via PrusaLink HTTP multipart
**FlashForge**: Upload via TCP socket
**Creality/Elegoo/Anycubic**: Files on printer's storage (Moonraker API doesn't require upload from script)

## Configuration Management

### Profile System

Multiple profiles stored in single config file with `[PROFILE_NAME]` sections:

```
[PROFILE_BAMBU_A1]
PRINTER_BRAND=Bambu Lab
...

[PROFILE_PRUSA_MK4]
PRINTER_BRAND=Prusa
...
```

**Switching Profiles**:
1. Read all profiles from config file
2. Present selection menu
3. Load selected profile into active configuration
4. Update `[CURRENT_PROFILE]` pointer

### Job Configuration

Jobs are stored with the active profile. Changing profiles clears job configuration (intentional - different printers have different file sets).

### AMS Configuration

Special handling for Bambu Lab:

```
JOB_1_USE_AMS=true
JOB_2_USE_AMS=false
```

Only written for Bambu Lab printers. Other brands ignore this field.

## Build System

### Python Bundling

**Challenge**: Beta testers don't have Python installed, or have incompatible versions.

**Solution**: Bundle Python 3.13 runtime with all dependencies:

```bash
# Download standalone Python build
curl -O https://www.python.org/ftp/python/3.13.0/python-3.13.0-macos11.pkg

# Extract to src/_internal/
pkgutil --expand python-3.13.0-macos11.pkg python-extracted
cp -r python-extracted/Python.framework/Versions/3.13 src/_internal/python-3.13-mac
```

**Windows**: Similar process with Windows embeddable Python distribution.

### PyInstaller Configuration

`OTTOMAT3D-x86_64.spec` defines the build:

```python
a = Analysis(
    ['src/main.py'],
    pathex=['src/', 'src/_internal/python-3.13-mac/lib/python3.13/site-packages'],
    binaries=[],
    datas=[
        ('src/gcode', 'gcode'),
        ('README.md', '.'),
    ],
    hiddenimports=[
        'bambulabs_api',
        'PrusaLinkPy',
        'websockets',
        # ... all dependencies
    ],
)
```

**hiddenimports**: PyInstaller's static analysis misses dynamically imported modules. Must explicitly list all dependencies.

### macOS Code Signing

`build_and_sign.sh` automates the entire pipeline:

```bash
#!/bin/bash

# 1. Clean previous builds
rm -rf build/ dist/

# 2. Build .app with PyInstaller
pyinstaller OTTOMAT3D-x86_64.spec

# 3. Sign the .app bundle
codesign --deep --force --verify --verbose \
    --sign "Developer ID Application: [NAME] ([TEAM_ID])" \
    --options runtime \
    dist/OTTOMAT3D.app

# 4. Create DMG
hdiutil create -volname OTTOMAT3D -srcfolder dist/OTTOMAT3D.app \
    -ov -format UDZO dist/OTTOMAT3D.dmg

# 5. Submit for notarization
xcrun notarytool submit dist/OTTOMAT3D.dmg \
    --apple-id [APPLE_ID] \
    --team-id [TEAM_ID] \
    --password [APP_SPECIFIC_PASSWORD] \
    --wait

# 6. Staple notarization ticket
xcrun stapler staple dist/OTTOMAT3D.app
```

**Why Notarization**: macOS Gatekeeper blocks unsigned apps. Notarization tells Gatekeeper "Apple has verified this app is malware-free".

**Hardened Runtime**: Required for notarization. Restricts what the app can do (no dynamic code execution, library injection, etc).

## Error Handling Strategy

### Connection Failures

```python
def connect_with_retry(printer, max_retries=3):
    for attempt in range(max_retries):
        try:
            printer.connect()
            return True
        except Exception as e:
            logger.error(f"Connection attempt {attempt + 1} failed: {e}")
            if attempt < max_retries - 1:
                time.sleep(5)
    return False
```

**Retry Logic**: Exponential backoff not used - 5 second fixed delay between retries. Network issues usually resolve quickly or not at all (wrong IP, firewall block).

### Print Monitoring

```python
try:
    while printer.is_printing():
        status = printer.get_status()
        if status['state'] == 'error':
            logger.error(f"Print error: {status['error_message']}")
            return False
        display_status(status)
        time.sleep(10)
except Exception as e:
    logger.error(f"Monitoring failed: {e}")
    # Continue anyway - print may still complete
```

**Defensive Approach**: If monitoring fails, don't abort. The print might complete successfully even if we can't see status updates.

### G-code Modification Failures

```python
try:
    inject_z_movement(gcode_path, z_height)
except Exception as e:
    logger.error(f"G-code modification failed: {e}")
    # Ask user if they want to continue with unmodified file
    if not confirm("Print without bed raise?"):
        return False
```

**User Decision**: Some failures are recoverable with manual intervention. Give user the option rather than aborting automatically.

## Performance Considerations

### Status Polling Frequency

10-second interval chosen as compromise:
- More frequent: Unnecessary network traffic, log spam
- Less frequent: Status updates feel stale, slower error detection

For multi-hour prints, 10 seconds is negligible overhead.

### File Transfer Optimization

No optimization implemented - files transferred once at print start, typically under 50MB. Not a bottleneck.

### Memory Usage

**Bounded**: Configuration and status data are small (KB range). G-code files read/modified in memory but released after upload.

**No Leaks**: Connections properly closed in `disconnect()` methods. MQTT client explicitly calls `disconnect()` and `loop_stop()`.

### CPU Usage

**Minimal**: Script spends 99% of time sleeping during status polling. CPU intensive only during:
- PyInstaller build (one-time, on dev machine)
- G-code parsing (short duration, small files)

## Security Considerations

### Credential Storage

Stored in plaintext in config.txt. Not ideal but acceptable for this use case:
- Beta testers control their own machines
- Printers are on local network (not internet-exposed)
- No shared/multi-user environments

Production version would use OS keychain (keyring library on Python).

### Code Signing

macOS .app is signed with Developer ID certificate. This proves:
- Code hasn't been tampered with since signing
- Apple has verified the developer's identity

Does NOT encrypt or obfuscate the code - Python source is still readable in the .app bundle.

### Network Communication

All printer communication is unencrypted (HTTP, plain MQTT, WebSocket without TLS):
- Printers only support unencrypted protocols
- Local network traffic (not over internet)
- Acceptable risk for beta testing environment

Production deployment would require VPN or network segmentation.

## Future Improvements

### Async Refactoring

Current implementation is synchronous. Could refactor to asyncio for:
- Parallel status monitoring of multiple printers
- Non-blocking UI updates
- Better WebSocket integration

Trade-off: Added complexity. Current single-threaded approach is easier to debug and sufficient for single-printer automation.

### Database Backend

Replace config.txt with SQLite:
- Better query performance for large profile/job lists
- Transactional updates (atomic profile switches)
- Schema versioning for upgrades

Trade-off: Dependency on SQLite (but available in Python stdlib). Config.txt is human-readable and easily edited manually.

### Plugin Architecture

Allow community-contributed printer integrations:
```python
# plugins/my_printer.py
class MyPrinter(BasePrinter):
    def connect(self): ...
    def start_print(self): ...
```

Trade-off: Security (running untrusted code). Would need sandboxing and code review process.

### Web UI

Replace CLI with web interface:
- Better for remote monitoring
- More intuitive for non-technical users
- Mobile-friendly

Trade-off: Increases complexity significantly (need web server, frontend framework, API layer). CLI is sufficient for beta testing with technical users.

---

This architecture evolved iteratively based on real-world beta testing feedback. The design prioritizes simplicity and reliability over performance optimization, which is appropriate for the use case (long-running print jobs with human supervision).