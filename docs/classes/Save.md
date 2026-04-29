# Save Class - Complete Reference

**File**: `addons/GodotSavesAddon/save_addon.gd`  
**Extends**: `Node`  
**Class Name**: `Save`  
**Lines**: ~450  
**Status**: Stable, Production-Ready  
**Version**: 2.0

---

## Table of Contents

1. [Overview](#overview)
2. [Signals](#signals)
3. [Constants](#constants)
4. [Exported Properties](#exported-properties)
5. [Methods](#methods)
6. [Internal Implementation](#internal-implementation)
7. [Usage Examples](#usage-examples)
8. [Best Practices](#best-practices)

---

## Overview

The `Save` class is the primary interface for the Godot Save Addon. It extends `Node` and provides:

- **Data Persistence**: Save and load arbitrary Dictionary data
- **Multiple Formats**: JSON, TXT, BIN, or custom extensions
- **Security**: AES-256-CBC encryption, SHA-256 integrity checks
- **Compression**: ZIP compression to reduce file sizes
- **Backups**: Automatic rotating backup system
- **Auto-Save**: Periodic background saving
- **Screenshots**: Non-blocking threaded screenshot capture
- **Cloud Sync**: HTTP upload/download to remote servers
- **Migration**: Version tracking and data schema updates
- **Thread-Safe**: Mutex-protected async operations

### Design Philosophy

The `Save` class follows these principles:

1. **Safe Writes**: Atomic operations using temp files prevent corruption
2. **Non-Blocking**: Screenshot and async save use background threads
3. **Signal-Based**: Operations emit signals for completion/failure
4. **Flexible**: All features are optional (encryption, compression, etc.)
5. **Production-Ready**: Includes backups, validation, and error handling

---

## Signals

### save_completed(profile: String)

Emitted when a save operation completes successfully.

```gdscript
signal save_completed(profile: String)

# Usage:
$Save.save_completed.connect(func(profile): print("Saved: ", profile))
```

**When Emitted:**
- After `save_data()` completes (sync or async)
- After async save worker finishes writing
- File successfully written and validated

**Parameters:**
- `profile` (String): Name of the saved profile

---

### load_completed(profile: String, data: Dictionary)

Emitted when a load operation completes.

```gdscript
signal load_completed(profile: String, data: Dictionary)

# Usage:
$Save.load_completed.connect(
    func(profile, data): 
        if not data.is_empty():
            print("Loaded: ", profile)
)
```

**When Emitted:**
- After `edit_data()` completes
- Always emitted, even if file not found (data will be empty `{}`)
- After integrity checks and migrations

**Parameters:**
- `profile` (String): Profile name
- `data` (Dictionary): Loaded data (empty if failed/not found)

---

### save_failed(profile: String, reason: String)

Emitted when a save operation fails.

```gdscript
signal save_failed(profile: String, reason: String)

# Usage:
$Save.save_failed.connect(
    func(profile, reason):
        push_error("Save failed: ", reason)
)
```

**When Emitted:**
- File cannot be opened for writing
- Disk space exhausted
- Permission denied
- Async save worker fails

**Parameters:**
- `profile` (String): Profile name that failed
- `reason` (String): Error description

---

### load_failed(profile: String, reason: String)

Emitted when a load operation fails.

```gdscript
signal load_failed(profile: String, reason: String)

# Usage:
$Save.load_failed.connect(
    func(profile, reason):
        print("Load error: ", reason)
)
```

**When Emitted:**
- File cannot be opened for reading
- Integrity check fails (checksum mismatch)
- Decryption fails
- Decompression fails

**Parameters:**
- `profile` (String): Profile name that failed
- `reason` (String): Error description

---

### migration_applied(profile: String, from_version: int, to_version: int)

Emitted when save data is migrated to a new version.

```gdscript
signal migration_applied(profile: String, from_version: int, to_version: int)

# Usage:
$Save.migration_applied.connect(
    func(profile, from_v, to_v):
        print("Migrated %s from v%d to v%d" % [profile, from_v, to_v])
)
```

**When Emitted:**
- Loaded save version is older than `CURRENT_SAVE_VERSION`
- `migrate_save_data()` is called
- Metadata version is updated

**Parameters:**
- `profile` (String): Profile that was migrated
- `from_version` (int): Original save version
- `to_version` (int): New save version

---

## Constants

### MAX_QUEUE_LENGTH

```gdscript
const MAX_QUEUE_LENGTH: int = 4
```

Maximum number of screenshots queued before overflow.

- If queue exceeds this, new screenshots are rejected
- Print message: "Screenshot queue overflow"
- Prevents memory exhaustion from screenshot spam

### CURRENT_SAVE_VERSION

```gdscript
const CURRENT_SAVE_VERSION: int = 2
```

Current save format version.

- Incremented when save format changes
- Stored in `_meta.version`
- Used for migration detection
- Override `migrate_save_data()` for custom logic

---

## Exported Properties

All properties can be configured in the Inspector.

### File Management

#### data_in_folder

```gdscript
@export var data_in_folder: bool = false
```

Controls where save files are stored.

| Value | Path | Use Case |
|-------|------|----------|
| `false` (default) | `user://save/` | User data folder (recommended for exports) |
| `true` | `res://save/` | Project folder (development/testing only) |

**Note**: `user://` is platform-specific:
- **Windows**: `AppData/Roaming/Godot/app_userdata/ProjectName/`
- **macOS**: `~/.godot/app_userdata/ProjectName/`
- **Linux**: `~/.godot/app_userdata/ProjectName/`

#### folder_name

```gdscript
@export var folder_name: String = "save"
```

Subfolder where saves are stored.

- Default: `"save"`
- Example: With default settings, saves go to `user://save/`
- You can use nested paths: `"savegames/profiles"`

#### save_name

```gdscript
@export var save_name: String = ""
```

Profile to automatically load on `_ready()`.

- Empty string (default): No auto-load
- Example: `"autosave"` → Loads `user://save/autosave.sav` on startup
- Requires `auto_load_on_ready = true` (default)

#### print_in_terminal

```gdscript
@export var print_in_terminal: bool = true
```

Enable debug output to console.

| State | Output | Use Case |
|-------|--------|----------|
| `true` (default) | Print all save/load messages | Development |
| `false` | Silent operation | Production builds |

---

### Screenshot Settings

#### screenshot_in_folder

```gdscript
@export var screenshot_in_folder: bool = false
```

Controls where screenshots are stored.

| Value | Path | Use Case |
|-------|------|----------|
| `false` (default) | `user://screenshots/` | User data folder |
| `true` | `res://screenshots/` | Project folder |

#### screenshot_folder_name

```gdscript
@export var screenshot_folder_name: String = "screenshots"
```

Subfolder for screenshots.

- Default: `"screenshots"`
- Creates folder if doesn't exist

#### screenshot_print_in_terminal

```gdscript
@export var screenshot_print_in_terminal: bool = true
```

Enable debug output for screenshot operations.

#### screenshot_max_count

```gdscript
@export var screenshot_max_count: int = 50
```

Maximum screenshots to keep before rotating.

- Default: `50`
- When exceeded, oldest screenshots are deleted
- Set to `0` to keep all screenshots
- Prevents disk space exhaustion

---

### Security & Compression

#### use_encryption

```gdscript
@export var use_encryption: bool = false
```

Enable AES-256-CBC encryption.

**Important**:
- Must be enabled **both** when saving and loading
- Requires `AES_KEY` to be set
- See [Security Guide](../SECURITY.md)

#### use_compression

```gdscript
@export var use_compression: bool = false
```

Enable ZIP compression.

**Benefits**:
- Reduces file size (typically 30-60%)
- Makes tampering more difficult
- Slightly slower read/write

**Important**:
- Must match between save and load
- Compression happens after encryption

#### keep_backups

```gdscript
@export var keep_backups: bool = true
```

Keep rotating backup versions.

When enabled:
- `.sav.bak1` = most recent backup
- `.sav.bak2` = second most recent
- `.sav.bak3` = oldest backup
- Old backups are deleted (based on `backup_limit`)

#### backup_limit

```gdscript
@export var backup_limit: int = 3
```

Number of backup versions to keep.

- Default: `3`
- Recommended: `3-5` for production
- Higher values consume more disk space

#### use_integrity_checksum

```gdscript
@export var use_integrity_checksum: bool = true
```

Add SHA-256 checksums to detect tampering.

**Benefits**:
- Detects manual file edits
- Detects corruption
- Stored in `_meta.checksum`

#### strict_integrity

```gdscript
@export var strict_integrity: bool = true
```

Behavior when checksum fails.

| Value | Behavior |
|-------|----------|
| `true` (default) | Return empty dict `{}` (fail safe) |
| `false` | Load anyway with warning (fail-open) |

---

### Auto-Save & Features

#### auto_save_interval

```gdscript
@export var auto_save_interval: float = 0.0
```

Seconds between auto-saves.

- `0.0` (default): Disabled
- Example: `30.0` → Save every 30 seconds
- Requires `autosave_data` in root metadata

#### auto_load_on_ready

```gdscript
@export var auto_load_on_ready: bool = true
```

Auto-load `save_name` profile when scene ready.

- Requires `save_name` to be set
- Emits `load_completed` signal

#### remote_save_url

```gdscript
@export var remote_save_url: String = ""
```

Server endpoint for cloud sync.

Example:
```gdscript
$Save.remote_save_url = "https://api.example.com/saves/upload"
$Save.upload_save("player")
```

#### file_format

```gdscript
@export var file_format: String = "json"
```

Serialization format.

| Format | Format | Pros | Cons |
|--------|--------|------|------|
| `"json"` (default) | JSON text | Human-readable, portable | Larger file size |
| `"txt"` | String representation | Simple | Very large size |
| `"bin"` | GDScript binary | Compact, fast | Not portable |

#### default_values_for_new_keys

```gdscript
@export var default_values_for_new_keys: Dictionary = {}
```

Default values for new keys when migrating saves.

Used with `migrate_save_data()` for simple migrations.

Example:
```gdscript
default_values_for_new_keys = {
    "new_level_cap": 100,
    "new_currency": 0
}
```

---

## Methods

### Lifecycle

#### _ready() -> void

```gdscript
func _ready() -> void
```

Called when node enters scene tree.

**Initializes:**
1. Path prefixes (`_res_user`, `_s_res_user`)
2. Threading objects (threads, mutex)
3. Auto-save timer (if configured)
4. Auto-loads `save_name` (if configured)

**Called by**: Godot Engine

---

### File System

#### create_folder(resuser: String, folder: String) -> void

```gdscript
func create_folder(resuser: String, folder: String) -> void
```

Creates save folder if it doesn't exist.

**Parameters:**
- `resuser` (String): Path prefix (`"user://"` or `"res://"`)
- `folder` (String): Folder name to create

**Example:**
```gdscript
$Save.create_folder("user://", "save")
$Save.create_folder("user://", "screenshots")
```

---

### Saving Data

#### save_data(data: Dictionary, profile: String, filetype: String, async_save: bool) -> void

```gdscript
func save_data(
    data: Dictionary,
    profile: String = "save",
    filetype: String = ".sav",
    async_save: bool = false
) -> void
```

Saves data with encryption, compression, backups.

**Parameters:**
- `data` (Dictionary): Data to save
- `profile` (String, default: `"save"`): Filename prefix
- `filetype` (String, default: `".sav"`): File extension
- `async_save` (bool, default: `false`): Save in background thread

**Process:**
1. Creates folder if needed
2. Creates backup of existing file (if `keep_backups` enabled)
3. Adds metadata: `_meta.version`, `_meta.timestamp`
4. Optionally adds integrity checksum
5. Serializes (JSON/TXT/BIN)
6. Optionally compresses (ZIP)
7. Optionally encrypts (AES-256)
8. Writes safely (temp file + rename)
9. Emits `save_completed` or `save_failed`

**Example - Synchronous:**
```gdscript
var data = {"player": "Hero", "level": 10}
$Save.save_data(data, "player_save", ".sav", false)
# Blocks until complete, then emits signal
```

**Example - Asynchronous:**
```gdscript
var data = {"player": "Hero", "level": 10}
$Save.save_data(data, "player_save", ".sav", true)
# Returns immediately, saves in background
# Emits signal when complete
```

**Example - Custom Extension:**
```gdscript
var settings = {"volume": 0.8, "quality": "high"}
$Save.save_data(settings, "config", ".cfg")
# Saves to user://save/config.cfg
```

---

### Loading Data

#### edit_data(profile: String, filetype: String) -> Dictionary

```gdscript
func edit_data(
    profile: String = "save",
    filetype: String = ".sav"
) -> Dictionary
```

Loads, decrypts, and deserializes save file.

**Parameters:**
- `profile` (String, default: `"save"`): Filename prefix
- `filetype` (String, default: `".sav"`): File extension

**Returns:** Dictionary with loaded data, or `{}` if failed

**Process:**
1. Creates folder if needed
2. Checks if file exists
3. Reads file bytes
4. Optionally decrypts (AES-256)
5. Optionally decompresses (ZIP)
6. Deserializes (JSON/TXT/BIN)
7. Optionally verifies integrity checksum
8. Applies schema migrations (if version mismatch)
9. Emits `load_completed` or `load_failed`

**Example - Load if Exists:**
```gdscript
var data = $Save.edit_data("player_save")

if data.is_empty():
    print("No save found, starting new game")
    _new_game()
else:
    print("Loaded player: ", data["player"])
    _load_game(data)
```

**Example - With Error Handling:**
```gdscript
var data = $Save.edit_data("player_save")

match true:
    data.is_empty():
        print("File not found")
    not data.has("player"):
        print("File corrupted")
    true:
        print("Player: ", data["player"])
```

---

### Profile Management

#### list_profiles(filetype: String) -> Array

```gdscript
func list_profiles(filetype: String = ".sav") -> Array
```

Lists all save files matching extension.

**Parameters:**
- `filetype` (String, default: `".sav"`): File extension to search for

**Returns:** Array of filenames (e.g., `["save1.sav", "save2.sav"]`)

**Example:**
```gdscript
var profiles = $Save.list_profiles()
for profile in profiles:
    print("Found: ", profile)

# List only .cfg files
var configs = $Save.list_profiles(".cfg")
```

---

#### delete_all_profiles(filetype: String) -> void

```gdscript
func delete_all_profiles(filetype: String = ".sav") -> void
```

Deletes all save files matching extension.

**Parameters:**
- `filetype` (String, default: `".sav"`): File extension to delete

**Warning**: This is destructive and cannot be undone!

**Example:**
```gdscript
# Delete all .sav files
$Save.delete_all_profiles()

# Delete all .cfg files
$Save.delete_all_profiles(".cfg")

# Confirmation dialog recommended
if confirm_dialog.confirmed:
    $Save.delete_all_profiles()
```

---

### Screenshots

#### snap_screenshot(viewport: Viewport, custom_name: String) -> void

```gdscript
func snap_screenshot(
    viewport: Viewport,
    custom_name: String = ""
) -> void
```

Captures viewport as PNG in background thread.

**Parameters:**
- `viewport` (Viewport): Viewport to capture (usually `get_viewport()`)
- `custom_name` (String, default: `""`): Filename prefix

**Behavior:**
- Queues screenshot
- Processes in background (non-blocking)
- Saves as PNG in `screenshot_folder_name`
- Auto-rotates old screenshots (based on `screenshot_max_count`)
- Emits debug message (if enabled)

**Filename Format:**
- Auto-timestamp: `screenshot-YYYYMMDD_HHMMSS.png`
- Custom: `{custom_name}-YYYYMMDD_HHMMSS.png`

**Example - Auto-timestamped:**
```gdscript
# Saves to: user://screenshots/screenshot-20260429_120530.png
$Save.snap_screenshot(get_viewport())
```

**Example - Custom Name:**
```gdscript
# Saves to: user://screenshots/victory_moment-20260429_120530.png
$Save.snap_screenshot(get_viewport(), "victory_moment")
```

**Example - Screenshot on Key Press:**
```gdscript
func _input(event: InputEvent):
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_F12:
            $Save.snap_screenshot(get_viewport(), "screenshot")
```

---

### Cloud Sync

#### upload_save(profile: String, filetype: String) -> void

```gdscript
func upload_save(
    profile: String = "save",
    filetype: String = ".sav"
) -> void
```

Uploads save file to remote server via HTTP POST.

**Parameters:**
- `profile` (String, default: `"save"`): Profile to upload
- `filetype` (String, default: `".sav"`): File extension

**Requirements:**
- `remote_save_url` must be set
- File must exist locally
- Server must accept POST requests

**Example:**
```gdscript
func _ready():
    $Save.remote_save_url = "https://api.game.com/saves/upload"

func upload_game():
    $Save.upload_save("player_save")
```

---

#### download_save(profile: String, filetype: String) -> void

```gdscript
func download_save(
    profile: String = "save",
    filetype: String = ".sav"
) -> void
```

Downloads save file from remote server via HTTP GET.

**Parameters:**
- `profile` (String, default: `"save"`): Profile to download
- `filetype` (String, default: `".sav"`): File extension

**Requirements:**
- `remote_save_url` must be set
- Server must return file bytes

**Example:**
```gdscript
func download_game():
    $Save.download_save("cloud_save")
    # After download, load it
    await get_tree().timer_timeout
    var data = $Save.edit_data("cloud_save")
```

---

### Migration & Version Control

#### migrate_save_data(data: Dictionary, from_version: int) -> Dictionary

```gdscript
func migrate_save_data(
    data: Dictionary,
    from_version: int
) -> Dictionary
```

Override in subclass for custom migration logic.

**Parameters:**
- `data` (Dictionary): Old save data
- `from_version` (int): Original save version

**Returns:** Modified dictionary with migrations applied

**Default Behavior:**
- Merges `default_values_for_new_keys` if configured
- Automatically called when loaded version < CURRENT_SAVE_VERSION

**Example - Custom Migration:**
```gdscript
class_name GameSave
extends Save

func migrate_save_data(data: Dictionary, from_version: int) -> Dictionary:
    var d = data.duplicate(true)
    
    # From v1 to v2: renamed 'mana_points' to 'mana'
    if from_version < 2:
        if d.has("mana_points"):
            d["mana"] = d["mana_points"]
            d.erase("mana_points")
        d["spell_level"] = 1  # New field
    
    # From v2 to v3: restructured inventory
    if from_version < 3:
        if d.has("inventory"):
            d["inventory"] = {"items": d["inventory"]}
    
    return d
```

---

## Internal Implementation

### Threading

The `Save` class uses threads for non-blocking operations:

```gdscript
var _thread: Thread              # Screenshot processing
var _save_thread: Thread         # Async save operations
var _mutex: Mutex                # Synchronization
var _queue: Array = []           # Screenshot queue
```

**Screenshot Thread:**
- Processes PNG saves in background
- Prevents frame stuttering
- Queue-based with overflow protection

**Save Thread:**
- Performs async saves
- Encodes data while main thread continues
- Calls deferred to finish on main thread

---

### Safe Writing

The `_safe_write()` method prevents corruption:

```gdscript
func _safe_write(path: String, bytes: PackedByteArray) -> bool
    # 1. Write to temporary file (.tmp)
    # 2. Close file
    # 3. Delete original if exists
    # 4. Rename temp to original
```

This ensures if the process crashes:
- Original file is never corrupted
- Temp file can be recovered
- Operation is atomic (as much as possible)

---

### Encoding Pipeline

Data goes through multiple optional transformations:

```
Dictionary
    ↓
[Optional] Add integrity checksum → _meta.checksum
    ↓
Serialize (JSON/TXT/BIN) → Bytes
    ↓
[Optional] Compress (ZIP) → Smaller bytes
    ↓
[Optional] Encrypt (AES-256) → Encrypted bytes
    ↓
Safe write to disk
```

Decoding reverses this:
```
Bytes from disk
    ↓
[Optional] Decrypt (AES-256)
    ↓
[Optional] Decompress (ZIP)
    ↓
Deserialize (JSON/TXT/BIN) → Dictionary
    ↓
[Optional] Verify checksum
    ↓
Apply migrations
    ↓
Return to caller
```

---

## Usage Examples

### Basic Save/Load

```gdscript
extends Node

@onready var save = $Save

func _ready():
    save.save_completed.connect(func(p): print("Saved: ", p))
    save.load_completed.connect(func(p, d): print("Loaded: ", p))

func save_game():
    var game_data = {
        "player": "Hero",
        "level": 10,
        "exp": 1500
    }
    save.save_data(game_data, "autosave")

func load_game():
    var data = save.edit_data("autosave")
    return data
```

### With Encryption

```gdscript
func _ready():
    save.use_encryption = true
    save.AES_KEY = "my_secret_key".to_utf8_buffer()

func save_encrypted():
    save.save_data({"secret": "data"}, "secure_save")
```

### Multiple Profiles

```gdscript
func save_slot(slot: int):
    var data = {"slot": slot, "time": Time.get_ticks_msec()}
    save.save_data(data, "slot_%d" % slot)

func load_slot(slot: int) -> Dictionary:
    return save.edit_data("slot_%d" % slot)
```

### Auto-Save

```gdscript
func _ready():
    save.auto_save_interval = 30.0  # Every 30 seconds

func _process(delta):
    var autosave_data = {"playtime": get_playtime()}
    get_tree().root.set_meta("autosave_data", autosave_data)
```

---

## Best Practices

1. **Always connect to signals** - Use `save_completed` and `load_completed`
2. **Check for empty returns** - `edit_data()` returns `{}` if file not found
3. **Enable backups** - Keep `keep_backups = true` in production
4. **Test migrations** - Custom `migrate_save_data()` should be tested thoroughly
5. **Validate loaded data** - Check that required keys exist
6. **Use encryption** - For sensitive data, enable `use_encryption`
7. **Monitor disk space** - Set reasonable `screenshot_max_count`
8. **Handle both paths** - Code should work with `res://` and `user://`
9. **Document your schema** - Note which keys are required/optional
10. **Version your saves** - Increment `CURRENT_SAVE_VERSION` when schema changes

---

For signal-based flow examples, see [examples/](../../examples/).
