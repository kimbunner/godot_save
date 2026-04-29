# Godot Save Addon - Complete Documentation

Welcome to the complete documentation for the **Godot Save Addon**, a comprehensive solution for saving, loading, encrypting, and managing game data in Godot 4.

## 📚 Documentation Index

### Getting Started
- [Quick Start Guide](QUICK_START.md) - Get up and running in 5 minutes
- [Installation](INSTALLATION.md) - Step-by-step setup instructions

### Configuration & Setup
- [Configuration Guide](CONFIGURATION.md) - All exportable properties and settings
- [Project Settings](PROJECT_SETTINGS.md) - How to configure the addon in your project

### API Reference
- [API Overview](API.md) - Complete API documentation
- **Classes:**
  - [Save](classes/Save.md) - Main save/load class (extends Node)
  - [SaveCodec](classes/SaveCodec.md) - Serialization, encryption, and compression utilities
  - [SaveAddonPlugin](classes/SaveAddonPlugin.md) - Editor plugin registration
  - [SaveViewerDock](classes/SaveViewerDock.md) - Editor dock for viewing save files

### Usage Examples
- [Basic Examples](examples/BASIC_EXAMPLES.md) - Common use cases
- [Advanced Examples](examples/ADVANCED_EXAMPLES.md) - Encryption, compression, cloud sync
- [Screenshots](examples/SCREENSHOTS.md) - Screenshot system usage
- [Cloud Sync](examples/CLOUD_SYNC.md) - Upload and download saves

### Additional Resources
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues and solutions
- [File Format Guide](FILE_FORMAT.md) - Understanding .sav, .json, .txt, .bin formats
- [Security](SECURITY.md) - Best practices for encryption and data protection
- [Performance Tips](PERFORMANCE.md) - Optimization and best practices

## 🚀 Quick Overview

**Godot Save Addon** is an all-in-one solution for:

✅ **Save & Load** - Store game data in multiple formats (.sav, .json, .txt, .bin)  
✅ **Encryption** - Secure saves with AES-256-CBC encryption  
✅ **Compression** - Reduce file size with ZIP compression  
✅ **Backups** - Automatic rotating backups with configurable limits  
✅ **Auto-Save** - Periodic automatic saving with timer support  
✅ **Screenshots** - Non-blocking screenshot capture with queue management  
✅ **Integrity** - SHA-256 checksums to detect tampering and corruption  
✅ **Cloud Sync** - Upload/download saves from remote servers  
✅ **Editor Tools** - Built-in viewer to inspect and debug save files  
✅ **Thread-Safe** - Async operations with mutex protection  

## 📋 Features

| Feature | Description |
|---------|-------------|
| **Multiple Formats** | JSON, TXT, BIN, or custom extensions |
| **AES-256 CBC** | Military-grade encryption with key derivation |
| **ZIP Compression** | Optional file compression to reduce size |
| **Safe Writes** | Atomic writes using temp files and renames |
| **Backup System** | Keep up to N rotating backup versions |
| **Auto-Save** | Background timer for periodic saves |
| **Screenshot Queue** | Non-blocking threaded screenshot capture |
| **SHA-256 Checksums** | Integrity verification with metadata |
| **Cloud Ready** | Built-in HTTP upload/download support |
| **Migration Support** | Version tracking and schema migration |
| **Editor Viewer** | Decrypt and inspect save files in editor |

## 📦 Addon Contents

```
addons/GodotSavesAddon/
├── save_addon.gd              # Main Save class
├── save_codec.gd              # Codec for serialization/encryption
├── save_addon_plugin.gd       # Editor plugin entry point
├── save_viewer_dock.gd        # Editor dock UI
├── plugin.cfg                 # Plugin metadata
├── plugin_icon.png            # Editor icon
├── icon.png                   # Save node icon
└── *.uid                       # UID files
```

## 🛠 Installation

1. **Copy the addon folder:**
   ```
   cp -r addons/GodotSavesAddon /path/to/your/project/addons/
   ```

2. **Enable in Project Settings:**
   - Open Godot Editor
   - Go to Project → Project Settings → Plugins
   - Find "Godot Saves Addon"
   - Click the checkbox to enable

3. **Add Save node to scene:**
   - Right-click in Scene tree → Add Child Node
   - Search for "Save"
   - Configure in Inspector

See [Installation](INSTALLATION.md) for detailed steps.

## 🎯 Basic Usage

```gdscript
# Save data
var player_data = {
    "name": "Player",
    "level": 10,
    "health": 100
}
$Save.save_data(player_data, "player", ".sav")

# Load data
var loaded = $Save.edit_data("player", ".sav")
print(loaded)

# Connect to signals
$Save.save_completed.connect(_on_save_completed)
$Save.load_completed.connect(_on_load_completed)

# Take a screenshot
$Save.snap_screenshot(get_viewport(), "my_screenshot")
```

See [Quick Start](QUICK_START.md) for more examples.

## 🔒 Security

The addon implements several security layers:

1. **Encryption**: Optional AES-256-CBC encryption
2. **Compression**: Optional ZIP compression (reduces tampering opportunities)
3. **Integrity Checking**: SHA-256 checksums in metadata
4. **Safe Writes**: Atomic file operations prevent corruption
5. **Key Derivation**: PBKDF2-like SHA-256 based KDF

See [Security](SECURITY.md) for best practices.

## 📖 Documentation Structure

Each component is fully documented:

- **[Save Class](classes/Save.md)** (480+ lines)
  - 20+ public methods
  - 4 signals
  - 20+ export properties
  - Complete implementation details

- **[SaveCodec Class](classes/SaveCodec.md)** (350+ lines)
  - 12+ utility methods
  - Serialization (JSON/TXT/BIN)
  - Encryption/Decryption
  - Compression/Decompression
  - Integrity verification

- **[SaveAddonPlugin](classes/SaveAddonPlugin.md)** (15 lines)
  - Editor registration
  - Custom types
  - Dock management

- **[SaveViewerDock](classes/SaveViewerDock.md)** (200+ lines)
  - Editor UI
  - File browser
  - Decode and inspect
  - Interactive options

## 🎓 Learning Path

1. Start with [Quick Start](QUICK_START.md)
2. Review [Configuration](CONFIGURATION.md)
3. Read [Basic Examples](examples/BASIC_EXAMPLES.md)
4. Study the [Save Class](classes/Save.md) API
5. Explore [Advanced Examples](examples/ADVANCED_EXAMPLES.md)
6. Review [Security](SECURITY.md) best practices
7. Check [Troubleshooting](TROUBLESHOOTING.md) if needed

## 🐛 Troubleshooting

Common issues and solutions are documented in [TROUBLESHOOTING.md](TROUBLESHOOTING.md):

- File not found errors
- Encryption/decryption failures
- Checksum mismatches
- Permission issues
- Performance optimization

## 📞 Support

For issues or questions:

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Review relevant examples in [examples/](examples/)
3. Consult the [API documentation](API.md)
4. Check [Security](SECURITY.md) for encryption-related issues

## 📄 License

See LICENSE file in project root.

## 🎯 Version Info

- **Version**: 2.0
- **Godot Compatibility**: 4.x
- **Status**: Stable
- **Authors**: Kimbunner, Kcfresh53

---

**Last Updated**: 2026  
**Documentation Version**: 1.0

For the complete API reference, start with [API.md](API.md).
