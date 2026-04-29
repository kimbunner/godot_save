# Configuration Guide

Complete guide to all configurable settings for the Godot Save Addon.

## Table of Contents

1. [Editor Dock Configuration](#editor-dock-configuration)
2. [Save Node Properties](#save-node-properties)
3. [Configuration Profiles](#configuration-profiles)
4. [Runtime Configuration](#runtime-configuration)
5. [Advanced Configuration](#advanced-configuration)
6. [Best Practices](#best-practices)

---

## Editor Dock Configuration

When the addon is enabled, a dock appears in the editor for inspecting save files.

### SaveState File Viewer Dock

**Location**: View → Show in Dock → SaveState file viewer

**Purpose**: Inspect and debug .sav files without running the game

**Features**:
- Browse for save files
- Configure encryption/compression/checksums
- Load and decode files
- Display as formatted JSON
- Copy to clipboard

**Configuration Options**:

1. **File Path**: Enter path to .sav file or click "Browse…"
2. **Encrypted**: Toggle if file was encrypted
3. **Compressed**: Toggle if file was compressed
4. **AES Key**: Enter the encryption key used (default: "supersecretkey123")
5. **Format**: Choose json/txt/bin (should match Save node)
6. **Expect SHA-256 Checksum**: Toggle checksum verification
7. **Strict Integrity**: Toggle fail behavior on checksum mismatch

**Usage Workflow**:
1. Save a game with your Save node settings
2. Open the dock
3. Configure dock options to match your Save node
4. Click "Load & decode"
5. Review decoded data
6. Click "Copy JSON" if needed

---

## Save Node Properties

All properties can be configured in the Inspector.

### Basic Settings

#### folder_name
- **Type**: String
- **Default**: `"save"`
- **Description**: Folder where saves are stored relative to user:// or res://
- **Example**: `"savegames"`, `"saves/profiles"`, `"user_data/saves"`
- **Best Practice**: Keep it simple, use lowercase, no spaces

#### data_in_folder
- **Type**: bool
- **Default**: `false`
- **Description**: Store saves in project folder (true) or user folder (false)
- **Recommendation**: Always `false` for exported games
- **Use Cases**:
  - `false`: Shipped games (saves go to user home directory)
  - `true`: Development/testing only

#### save_name
- **Type**: String
- **Default**: `""` (empty)
- **Description**: Profile to auto-load when scene starts
- **Example**: `"autosave"`, `"player_data"`, `"settings"`
- **Requirement**: Only works if `auto_load_on_ready = true`

#### auto_load_on_ready
- **Type**: bool
- **Default**: `true`
- **Description**: Load `save_name` profile on startup
- **Works With**: Must have `save_name` set to a non-empty value
- **Example**:
  - Set `save_name = "autosave"`
  - Set `auto_load_on_ready = true`
  - Save loads on game start

#### print_in_terminal
- **Type**: bool
- **Default**: `true`
- **Description**: Print debug messages to console
- **Recommendation**:
  - `true` for development
  - `false` for production/shipped games
- **What Gets Printed**:
  - "Saved profile: X"
  - "File not found, returning empty dictionary"
  - "Saved profile (async): X"

---

### File Format Settings

#### file_format
- **Type**: String
- **Default**: `"json"`
- **Valid Values**: `"json"`, `"txt"`, `"bin"`
- **Comparison**:

| Format | Size | Readability | Portability | Speed | Use Case |
|--------|------|-------------|-------------|-------|----------|
| json | Medium | High | High | Medium | Most games |
| txt | Large | Medium | Medium | Slow | Debug/simple |
| bin | Small | None | Low | Fast | Performance-critical |

- **Recommendation**: Use `"json"` for most projects
- **Important**: Must match between save and load operations

---

### Security Settings

#### use_encryption
- **Type**: bool
- **Default**: `false`
- **Description**: Enable AES-256-CBC encryption
- **Recommendation**:
  - `false` for local saves only
  - `true` for sensitive data or online games
- **Requirements**:
  - `AES_KEY` must be set
  - Must be same on save and load
- **Performance**: ~10-20% slower with encryption

#### use_compression
- **Type**: bool
- **Default**: `false`
- **Description**: Enable ZIP compression
- **Benefits**:
  - Reduces file size (30-60% typically)
  - Makes tampering harder
- **Drawback**: ~5-10% slower
- **Recommendation**: Enable for large saves
- **Important**: Must match between save and load

#### use_integrity_checksum
- **Type**: bool
- **Default**: `true`
- **Description**: Add SHA-256 checksum to detect tampering
- **How It Works**:
  - Adds checksum to `_meta.checksum`
  - Verified on load
  - Detects manual edits or corruption
- **Recommendation**: Keep `true` in production
- **Performance Impact**: Negligible

#### strict_integrity
- **Type**: bool
- **Default**: `true`
- **Description**: Fail if checksum doesn't match
- **Behavior**:
  - `true`: Returns `{}` if checksum fails (fail-safe)
  - `false`: Loads anyway with warning (fail-open)
- **Recommendation**: Keep `true` unless you have reason otherwise
- **Use Case for `false`**: Allow loading corrupted saves as fallback

---

### Backup Settings

#### keep_backups
- **Type**: bool
- **Default**: `true`
- **Description**: Keep rotating backup files
- **How It Works**:
  - Saves current version as `.sav.bak1`
  - Rotates older backups: `.bak2`, `.bak3`, etc.
- **Recommendation**: Keep `true` for production
- **Example**:
  ```
  game.sav          # Current save
  game.sav.bak1     # Last save
  game.sav.bak2     # Previous save
  game.sav.bak3     # Oldest save
  ```

#### backup_limit
- **Type**: int
- **Default**: `3`
- **Description**: Number of backups to keep
- **Recommendation**: 3-5 for most games
- **Trade-offs**:
  - Higher = More disk space, better recovery
  - Lower = Less disk space, less recovery options

---

### Auto-Save Settings

#### auto_save_interval
- **Type**: float (seconds)
- **Default**: `0.0`
- **Description**: Interval between auto-saves
- **Value**:
  - `0.0`: Disabled
  - `30.0`: Every 30 seconds
  - `60.0`: Every 60 seconds (1 minute)
- **Recommendation**: 30-60 seconds for most games
- **Requirements**:
  - Must update `get_tree().root.meta("autosave_data")` in `_process()`
  - Creates Timer node automatically

---

### Screenshot Settings

#### screenshot_in_folder
- **Type**: bool
- **Default**: `false`
- **Description**: Store screenshots in project (true) or user folder (false)
- **Recommendation**: Always `false` for shipped games

#### screenshot_folder_name
- **Type**: String
- **Default**: `"screenshots"`
- **Description**: Subfolder for screenshots
- **Example**: `"screenshots"`, `"captures"`, `"memories"`

#### screenshot_print_in_terminal
- **Type**: bool
- **Default**: `true`
- **Description**: Print screenshot messages
- **Recommendation**: `false` in production to avoid log spam

#### screenshot_max_count
- **Type**: int
- **Default**: `50`
- **Description**: Maximum screenshots before rotating
- **Behavior**:
  - When exceeded, oldest screenshots deleted
  - Prevents disk space exhaustion
- **Example**: `50` keeps 50 screenshots, deletes oldest when adding 51st
- **Recommendation**:
  - `0`: Keep all (careful with disk space)
  - `10-50`: Reasonable limit
  - `100+`: For capture systems

---

### Cloud Settings

#### remote_save_url
- **Type**: String
- **Default**: `""` (empty)
- **Description**: Server endpoint for cloud sync
- **Format**: Full HTTP URL
- **Example**: `"https://api.game.com/saves/upload"`
- **Usage**:
  - Upload: `$Save.upload_save(profile)`
  - Download: `$Save.download_save(profile)`
- **Security**: Use HTTPS only
- **Recommendation**: Implement server-side validation

---

### Migration Settings

#### default_values_for_new_keys
- **Type**: Dictionary
- **Default**: `{}` (empty)
- **Description**: Default values for new keys when migrating saves
- **How It Works**:
  - Used with `migrate_save_data()`
  - Merged into old saves automatically
- **Example**:
  ```gdscript
  default_values_for_new_keys = {
      "new_feature_enabled": false,
      "exp_system": {
          "total_exp": 0,
          "level": 1
      }
  }
  ```
- **Nested Merging**: Works recursively for nested dictionaries

---

## Configuration Profiles

Different configuration for different scenarios:

### Profile 1: Simple Local Save

```gdscript
# Inspector settings
folder_name = "save"
file_format = "json"
use_encryption = false
use_compression = false
use_integrity_checksum = true
keep_backups = true
backup_limit = 3
auto_save_interval = 0.0
print_in_terminal = true
```

**Use Case**: Single-player indie games

---

### Profile 2: Secure Online Game

```gdscript
# Inspector settings
folder_name = "savedata"
file_format = "json"
use_encryption = true           # AES-256
use_compression = true          # Reduce size
use_integrity_checksum = true   # Detect tampering
keep_backups = true
backup_limit = 5
auto_save_interval = 30.0       # Auto-save every 30 seconds
print_in_terminal = false       # No spam in production
remote_save_url = "https://api.game.com/saves"
```

**Use Case**: Online multiplayer with anti-cheat

**Note**: Set `AES_KEY` in code:
```gdscript
$Save.AES_KEY = "your_game_secret_key".to_utf8_buffer()
```

---

### Profile 3: Development/Debug

```gdscript
# Inspector settings
folder_name = "dev_saves"
file_format = "json"
use_encryption = false
use_compression = false
use_integrity_checksum = true
keep_backups = true
backup_limit = 10               # Keep more for testing
auto_save_interval = 10.0       # Save every 10 seconds
print_in_terminal = true        # See all messages
screenshot_max_count = 200      # Keep more screenshots
```

**Use Case**: Development and testing

---

### Profile 4: Mobile Game

```gdscript
# Inspector settings
folder_name = "save"
file_format = "json"
use_encryption = true
use_compression = true          # Save space on mobile
use_integrity_checksum = true
keep_backups = true
backup_limit = 3
auto_save_interval = 60.0       # Less frequent to save battery
print_in_terminal = false
screenshot_max_count = 20       # Limit screenshots for battery
```

**Use Case**: Mobile devices with limited storage/battery

---

## Runtime Configuration

Change settings in code:

```gdscript
extends Node

@onready var save = $Save

func _ready():
    # Override Inspector settings
    save.file_format = "json"
    save.use_encryption = true
    save.use_compression = true
    save.AES_KEY = "my_secret".to_utf8_buffer()
    save.auto_save_interval = 30.0
    
    # Use configured values
    save.save_data({"test": true}, "test_profile")
```

**When to Use**:
- Dynamic configuration based on settings menu
- Platform-specific settings
- Runtime feature toggles

---

## Advanced Configuration

### Custom AES Key

```gdscript
extends Save

func _ready():
    super._ready()
    
    # Generate key from user ID or device
    var device_id = OS.get_unique_id()
    var key_source = (device_id + "secret_salt").to_utf8_buffer()
    
    AES_KEY = SaveCodec.sha256_bytes(key_source)
```

### Custom Save Folder Per Platform

```gdscript
func _ready():
    match OS.get_name():
        "Windows":
            folder_name = "saves_win"
        "MacOS":
            folder_name = "saves_mac"
        "Linux":
            folder_name = "saves_linux"
        "Android":
            folder_name = "saves_mobile"
    
    super._ready()
```

### Conditional Encryption

```gdscript
func _ready():
    # Only encrypt on shipped builds
    if OS.is_debug_build():
        use_encryption = false
    else:
        use_encryption = true
        AES_KEY = "production_key".to_utf8_buffer()
    
    super._ready()
```

### Per-Profile Settings

```gdscript
func save_with_profile(profile_name: String, data: Dictionary):
    # Different settings per profile
    if profile_name.starts_with("cloud_"):
        use_compression = true
        use_encryption = true
    elif profile_name.starts_with("local_"):
        use_compression = false
        use_encryption = false
    
    save_data(data, profile_name)
```

---

## Best Practices

### Configuration Checklist

Before shipping:

- [ ] **folder_name** set appropriately
- [ ] **file_format** chosen (json recommended)
- [ ] **use_encryption** enabled if sensitive data
- [ ] **AES_KEY** set securely if encrypting
- [ ] **use_compression** enabled for large saves
- [ ] **keep_backups** enabled
- [ ] **backup_limit** set to 3-5
- [ ] **print_in_terminal** set to false for production
- [ ] **auto_save_interval** configured (0 if disabled)
- [ ] **screenshot_max_count** limited appropriately
- [ ] **strict_integrity** enabled for fail-safe
- [ ] Migration strategy documented

### Common Mistakes

❌ **Different settings between save and load** - Always match encryption/compression  
❌ **Hardcoded paths** - Use folder_name property instead  
❌ **No backups in production** - Enable keep_backups  
❌ **Unencrypted sensitive data** - Enable encryption for private saves  
❌ **Large screenshot limits** - Set reasonable screenshot_max_count  
❌ **Debug printing in production** - Set print_in_terminal = false  

### Platform Considerations

**Windows/Desktop**:
- User data goes to `user://` (AppData/Roaming)
- Encryption optional but recommended
- Compression helps with large saves

**Mobile (Android/iOS)**:
- Limited disk space, enable compression
- Lower auto-save frequency (60s instead of 30s)
- Limit screenshots (10-20 max)
- Always encrypt if storing user data

**Web/HTML5**:
- LocalStorage limitations may apply
- Smaller file sizes important
- Cloud sync recommended

---

For example configurations and use cases, see [examples/BASIC_EXAMPLES.md](../examples/BASIC_EXAMPLES.md).
