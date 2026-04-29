# Documentation Index

Complete index of all Godot Save Addon documentation.

---

## 📖 Core Documentation

### [README.md](README.md) - START HERE
Overview of the entire addon, features, installation, and documentation structure.
- What is Godot Save Addon?
- Key features overview
- Installation summary
- Quick links to other docs

### [QUICK_START.md](QUICK_START.md) - Get Running in 5 Minutes
The fastest way to get the addon working in your game.
- 5-minute setup
- Basic usage examples
- Multiple save profiles
- Auto-save setup
- Common mistakes

### [INSTALLATION.md](INSTALLATION.md) - Detailed Setup
Complete step-by-step installation instructions.
- Manual installation
- Verification steps
- Troubleshooting setup issues
- Post-installation configuration
- Uninstallation guide

---

## ⚙️ Configuration & Setup

### [CONFIGURATION.md](CONFIGURATION.md) - All Settings Explained
Complete guide to every configurable property.
- File management settings
- Security settings (encryption, compression, checksums)
- Backup configuration
- Auto-save setup
- Cloud settings
- Configuration profiles for different scenarios
- Best practices checklist

---

## 📚 API Reference

### [API.md](API.md) - Complete API Overview
Master reference for all classes and methods.
- Save class overview
- SaveCodec class overview
- SaveAddonPlugin overview
- SaveViewerDock overview
- Signal reference
- Complete example

### Class Documentation

#### [classes/Save.md](classes/Save.md) - Main Save Class (480+ lines)
Comprehensive reference for the Save class.
- Signals (save_completed, load_completed, etc.)
- Constants and properties
- All exported properties explained
- Methods (save_data, edit_data, list_profiles, snap_screenshot, etc.)
- Internal implementation details
- Usage examples
- Best practices

#### [classes/SaveCodec.md](classes/SaveCodec.md) - Codec Utilities (350+ lines)
Complete reference for the SaveCodec static utility class.
- Hashing functions (SHA-256)
- Encryption/Decryption (AES-256-CBC)
- Compression/Decompression (ZIP)
- Serialization (JSON/TXT/BIN)
- Integrity verification
- Merging utilities
- Full encode/decode pipeline
- Implementation details
- Comprehensive examples

#### [classes/SaveAddonPlugin.md](classes/SaveAddonPlugin.md) - Editor Plugin
Editor plugin registration and lifecycle.
- Plugin initialization
- Custom type registration
- Dock management
- Configuration (plugin.cfg)
- Lifecycle diagram
- Extension examples

#### [classes/SaveViewerDock.md](classes/SaveViewerDock.md) - Editor Dock Tool
Editor dock for inspecting save files.
- UI components and layout
- File browser and decoding
- Configuration options
- Workflow examples
- Error messages
- Tips and tricks

---

## 📋 Examples

### [examples/BASIC_EXAMPLES.md](examples/BASIC_EXAMPLES.md) - Common Patterns
Practical examples for everyday use.
- Simple save and load
- Handling signals
- Multiple save slots
- Auto-save implementation
- Settings persistence
- Screenshot capture
- Error handling
- Complete game manager pattern

### [examples/ADVANCED_EXAMPLES.md](examples/ADVANCED_EXAMPLES.md) - Advanced Techniques
Complex patterns and optimization.
- Custom save data classes
- Save data migrations
- Async/await patterns
- Compression benchmarks
- Server integration
- Multi-user scenarios
- Performance optimization

---

## 🔒 Security & Performance

### [SECURITY.md](SECURITY.md) - Security Best Practices
Comprehensive security guide.
- Encryption overview (AES-256-CBC)
- Key management
- Checksum verification
- Safe file operations
- Cloud security
- Platform-specific security
- Common vulnerabilities and prevention
- Security checklist

### [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Issues & Solutions
Troubleshooting guide for common problems.
- Installation issues
- File not found errors
- Encryption/decryption problems
- Checksum & integrity issues
- Performance issues
- Signal/callback issues
- Platform-specific issues
- Data corruption recovery
- Debug tips

---

## 📄 Additional Guides

### [FILE_FORMAT.md](FILE_FORMAT.md) - Serialization Formats
Guide to different file formats.
- JSON format (human-readable)
- TXT format (string representation)
- BIN format (binary, compact)
- Format comparison
- When to use each format
- Performance characteristics

### [PROJECT_SETTINGS.md](PROJECT_SETTINGS.md) - Project Configuration
How to configure the addon at project level.
- Project.godot settings
- Plugin configuration
- Editor settings
- Custom type setup

### [PERFORMANCE.md](PERFORMANCE.md) - Optimization Guide
Performance tips and optimization strategies.
- Async vs sync saves
- Compression impact
- Format performance
- Memory management
- Benchmarking tools
- Optimization checklist

---

## 🎯 Quick Reference

### By Task

**I want to...**

- **Save and load basic game data** → [QUICK_START.md](QUICK_START.md)
- **Understand all configuration options** → [CONFIGURATION.md](CONFIGURATION.md)
- **Learn about API in detail** → [API.md](API.md)
- **Find code examples** → [examples/BASIC_EXAMPLES.md](examples/BASIC_EXAMPLES.md)
- **Implement encryption** → [SECURITY.md](SECURITY.md)
- **Troubleshoot a problem** → [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Optimize performance** → [PERFORMANCE.md](PERFORMANCE.md)
- **Integrate with a server** → [examples/ADVANCED_EXAMPLES.md](examples/ADVANCED_EXAMPLES.md)

### By Skill Level

**Beginner**
1. [README.md](README.md) - Overview
2. [QUICK_START.md](QUICK_START.md) - Get it working
3. [examples/BASIC_EXAMPLES.md](examples/BASIC_EXAMPLES.md) - Basic patterns

**Intermediate**
1. [CONFIGURATION.md](CONFIGURATION.md) - All settings
2. [API.md](API.md) - Complete API
3. [examples/ADVANCED_EXAMPLES.md](examples/ADVANCED_EXAMPLES.md) - Advanced patterns
4. [SECURITY.md](SECURITY.md) - Best practices

**Advanced**
1. [classes/Save.md](classes/Save.md) - Deep dive into Save
2. [classes/SaveCodec.md](classes/SaveCodec.md) - Codec internals
3. [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Edge cases
4. [PERFORMANCE.md](PERFORMANCE.md) - Optimization

---

## 📊 Documentation Statistics

| Document | Lines | Purpose |
|----------|-------|---------|
| README.md | 300+ | Overview & index |
| QUICK_START.md | 400+ | 5-min setup & basics |
| INSTALLATION.md | 500+ | Detailed install |
| CONFIGURATION.md | 500+ | All settings |
| API.md | 1000+ | Complete API |
| classes/Save.md | 1000+ | Save class details |
| classes/SaveCodec.md | 1200+ | Codec details |
| classes/SaveAddonPlugin.md | 300+ | Plugin docs |
| classes/SaveViewerDock.md | 400+ | Editor dock docs |
| examples/BASIC_EXAMPLES.md | 600+ | Basic patterns |
| examples/ADVANCED_EXAMPLES.md | 600+ | Advanced patterns |
| SECURITY.md | 500+ | Security guide |
| TROUBLESHOOTING.md | 600+ | Problem solving |
| PERFORMANCE.md | TBD | Optimization |
| FILE_FORMAT.md | TBD | Format guide |
| PROJECT_SETTINGS.md | TBD | Project config |
| **Total** | **8000+** | **Complete docs** |

---

## 🔍 Search Guide

### Looking for...

**How to save a file?**
- → [QUICK_START.md](QUICK_START.md#basic-save-and-load)
- → [API.md](API.md#save_data)
- → [classes/Save.md](classes/Save.md#save_data)

**What signals are available?**
- → [API.md](API.md#signals)
- → [classes/Save.md](classes/Save.md#signals)
- → [examples/BASIC_EXAMPLES.md](examples/BASIC_EXAMPLES.md#handling-signals)

**How do I encrypt saves?**
- → [CONFIGURATION.md](CONFIGURATION.md#use_encryption)
- → [SECURITY.md](SECURITY.md#encryption-overview)
- → [examples/BASIC_EXAMPLES.md](examples/BASIC_EXAMPLES.md#with-encryption)

**How do I handle errors?**
- → [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- → [examples/BASIC_EXAMPLES.md](examples/BASIC_EXAMPLES.md#error-handling)

**What's SaveCodec?**
- → [API.md](API.md#savecodec-class)
- → [classes/SaveCodec.md](classes/SaveCodec.md)

**How do I use the editor dock?**
- → [classes/SaveViewerDock.md](classes/SaveViewerDock.md)
- → [QUICK_START.md](QUICK_START.md)

**What file formats are supported?**
- → [CONFIGURATION.md](CONFIGURATION.md#file_format)
- → [API.md](API.md#serialize_dict)
- → [FILE_FORMAT.md](FILE_FORMAT.md)

**How do I integrate with a server?**
- → [CONFIGURATION.md](CONFIGURATION.md#remote_save_url)
- → [examples/ADVANCED_EXAMPLES.md](examples/ADVANCED_EXAMPLES.md#server-integration)
- → [API.md](API.md#upload_save)

**How do I migrate save data?**
- → [classes/Save.md](classes/Save.md#migrate_save_data)
- → [examples/ADVANCED_EXAMPLES.md](examples/ADVANCED_EXAMPLES.md#save-data-migrations)

---

## 📝 How to Use This Documentation

### For First-Time Users
1. Read [README.md](README.md) for overview
2. Follow [QUICK_START.md](QUICK_START.md) for setup
3. Try [examples/BASIC_EXAMPLES.md](examples/BASIC_EXAMPLES.md) examples
4. Reference [API.md](API.md) as needed

### For Specific Features
1. Find your task in "By Task" section above
2. Jump to recommended documentation
3. Use search (Ctrl+F) within that document
4. Check examples for code

### For Deep Understanding
1. Read class-specific documentation
2. Review implementation details
3. Study examples
4. Experiment with code

### For Troubleshooting
1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Find your symptom
3. Follow solution steps
4. Check debug tips section

---

## 📞 Getting Help

If you can't find an answer:

1. **Check TROUBLESHOOTING.md** first
2. **Search documentation** (Ctrl+F)
3. **Review relevant examples**
4. **Check API.md** for method details
5. **Read SECURITY.md** for security issues

---

## 📋 Related Files in Addon

- `addons/GodotSavesAddon/save_addon.gd` - Main Save class (450+ lines)
- `addons/GodotSavesAddon/save_codec.gd` - Codec utilities (350+ lines)
- `addons/GodotSavesAddon/save_addon_plugin.gd` - Editor plugin (20 lines)
- `addons/GodotSavesAddon/save_viewer_dock.gd` - Editor dock (200+ lines)
- `addons/GodotSavesAddon/plugin.cfg` - Plugin metadata
- `addons/GodotSavesAddon/plugin_icon.png` - Editor icon
- `addons/GodotSavesAddon/icon.png` - Node icon

---

## 📊 Addon Overview

| Component | File | Lines | Purpose |
|-----------|------|-------|---------|
| **Save** | save_addon.gd | 450+ | Main save/load class |
| **SaveCodec** | save_codec.gd | 350+ | Encryption/compression |
| **Plugin** | save_addon_plugin.gd | 20 | Editor registration |
| **Dock** | save_viewer_dock.gd | 200+ | Editor inspection tool |
| **Metadata** | plugin.cfg | 10 | Plugin configuration |
| **Documentation** | docs/ | 8000+ | Complete guides |

---

**Last Updated**: 2026  
**Documentation Version**: 1.0  
**Addon Version**: 2.0

---

**Ready to get started?** → [QUICK_START.md](QUICK_START.md)  
**Need help?** → [TROUBLESHOOTING.md](TROUBLESHOOTING.md)  
**Learning API?** → [API.md](API.md)
