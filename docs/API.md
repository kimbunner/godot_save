# Complete API Reference

Full API documentation for the Godot Save Addon.

## Table of Contents

1. [Save Class](#save-class) - Main save/load functionality
2. [SaveCodec Class](#savecodec-class) - Serialization utilities
3. [SaveAddonPlugin](#saveaddonplugin) - Editor plugin
4. [SaveViewerDock](#saveviewerdock) - Editor tool

---

## Save Class

**File**: `addons/GodotSavesAddon/save_addon.gd`  
**Extends**: `Node`  
**Class Name**: `Save`  
**Lines**: ~450  
**Status**: Stable, Production-Ready

### Overview

The `Save` class is the main interface for saving, loading, and managing game data. It handles:

- Data serialization in multiple formats
- Optional encryption and compression
- Backup management
- Auto-save functionality
- Screenshot capture
- Cloud sync
- Schema migration
- Integrity verification

### Signals

```gdscript
# Emitted when save operation completes successfully
signal save_completed(profile: String)

# Emitted when load operation completes successfully
signal load_completed(profile: String, data: Dictionary)

# Emitted when save operation fails
signal save_failed(profile: String, reason: String)

# Emitted when load operation fails
signal load_failed(profile: String, reason: String)

# Emitted when save data is migrated to new version
signal migration_applied(profile: String, from_version: int, to_version: int)
```

### Constants

| Name | Type | Value | Description |
|------|------|-------|-------------|
| `MAX_QUEUE_LENGTH` | int | 4 | Max queued screenshots before overflow |
| `CURRENT_SAVE_VERSION` | int | 2 | Current save format version |

### Exported Properties

#### File Management

```gdscript
@export var data_in_folder: bool = false
# If true, save to res:// (project folder)
# If false, save to user:// (user data folder)

@export var folder_name: String = "save"
# Folder where save files are stored

@export var save_name: String = ""
# Profile to auto-load on _ready() (blank = disabled)

@export var print_in_terminal: bool = true
# Print debug messages to console
```

#### Screenshot Settings

```gdscript
@export var screenshot_in_folder: bool = false
# If true, save screenshots to res:// (project)
# If false, save to user:// (user data)

@export var screenshot_folder_name: String = "screenshots"
# Where screenshots are stored

@export var screenshot_print_in_terminal: bool = true
# Print screenshot debug messages

@export var screenshot_max_count: int = 50
# Maximum screenshots to keep (older ones deleted)
```

#### Security & Compression

```gdscript
@export var use_encryption: bool = false
# Enable AES-256-CBC encryption

@export var use_compression: bool = false
# Enable ZIP compression

@export var keep_backups: bool = true
# Keep rotating backup files

@export var backup_limit: int = 3
# Number of backup versions to keep

@export var use_integrity_checksum: bool = true
# Add SHA-256 checksum to _meta for tampering detection

@export var strict_integrity: bool = true
# Return {} if checksum fails (false = load anyway with warning)
```

#### Auto-Save & Cloud

```gdscript
@export var auto_save_interval: float = 0.0
# Seconds between auto-saves (0 = disabled)

@export var auto_load_on_ready: bool = true
# Load save_name profile when scene ready

@export var remote_save_url: String = ""
# Server endpoint for cloud sync

@export var file_format: String = "json"
# Serialization format: "json", "txt", or "bin"

@export var default_values_for_new_keys: Dictionary = {}
# Default values merged into old saves during migration
```

### Internal Variables

```gdscript
var _res_user: String = "user://"           # Path prefix (res:// or user://)
var _s_res_user: String = "user://"         # Screenshot path prefix
var _thread: Thread                         # Screenshot processing thread
var _save_thread: Thread                    # Async save thread
var _mutex: Mutex                           # Thread synchronization
var _queue: Array = []                      # Screenshot queue
var _autosave_timer: Timer                  # Auto-save timer
var AES_KEY: PackedByteArray = "supersecretkey123".to_utf8_buffer()
```

### Methods

#### Initialization

```gdscript
func _ready() -> void
```
- Called when node enters tree
- Initializes threads and paths
- Starts auto-save timer if configured
- Auto-loads save if `save_name` set

#### Folder Management

```gdscript
func create_folder(resuser: String, folder: String) -> void
```
- Creates save folder if doesn't exist
- `resuser`: Path prefix ("user://" or "res://")
- `folder`: Folder name to create

**Parameters:**
- `resuser` (String): Resource path prefix
- `folder` (String): Folder name

**Example:**
```gdscript
$Save.create_folder("user://", "save")
```

#### Saving Data

```gdscript
func save_data(data: Dictionary, profile: String = "save", filetype: String = ".sav", async_save: bool = false) -> void
```

Saves data to a file with backups, encryption, and compression.

**Parameters:**
- `data` (Dictionary): Data to save
- `profile` (String): Profile/filename (default: "save")
- `filetype` (String): File extension (default: ".sav")
- `async_save` (bool): If true, saves in background thread (default: false)

**Behavior:**
1. Creates folder if needed
2. Creates backup if file exists
3. Adds metadata (_meta with version and timestamp)
4. Encodes with selected format/encryption/compression
5. Writes safely using temp file
6. Emits `save_completed` or `save_failed`

**Example:**
```gdscript
var game_data = {
    "player": "Hero",
    "level": 10,
    "health": 100
}

# Synchronous save
$Save.save_data(game_data, "player_save")

# Asynchronous save (non-blocking)
$Save.save_data(game_data, "player_save", async_save: true)

# Custom file extension
$Save.save_data(game_data, "settings", ".cfg")
```

#### Loading Data

```gdscript
func edit_data(profile: String = "save", filetype: String = ".sav") -> Dictionary
```

Loads and decrypts save file, applies migrations.

**Parameters:**
- `profile` (String): Profile to load (default: "save")
- `filetype` (String): File extension (default: ".sav")

**Returns:** Dictionary with loaded data, or empty dict `{}` if failed

**Behavior:**
1. Creates folder if needed
2. Checks if file exists
3. Reads and decodes file
4. Verifies integrity checksum
5. Applies version migrations
6. Emits `load_completed` or `load_failed`

**Example:**
```gdscript
var data = $Save.edit_data("player_save")

if data.is_empty():
    print("No save found")
else:
    print("Player: ", data["player"])
```

#### Profile Management

```gdscript
func list_profiles(filetype: String = ".sav") -> Array
```

Lists all save profiles.

**Parameters:**
- `filetype` (String): File extension to search for

**Returns:** Array of filenames matching extension

**Example:**
```gdscript
var saves = $Save.list_profiles()
for save in saves:
    print("Found: ", save)
```

```gdscript
func delete_all_profiles(filetype: String = ".sav") -> void
```

Deletes all save files with given extension.

**Parameters:**
- `filetype` (String): File extension to delete

**Example:**
```gdscript
$Save.delete_all_profiles()  # Delete all .sav files
```

#### Screenshots

```gdscript
func snap_screenshot(viewport: Viewport, custom_name: String = "") -> void
```

Captures viewport as PNG in background.

**Parameters:**
- `viewport` (Viewport): Viewport to capture
- `custom_name` (String): Filename prefix (auto-timestamped if blank)

**Behavior:**
- Queues screenshot
- Processes in background thread
- Auto-rotates old screenshots if limit exceeded
- Emits messages (if enabled)

**Example:**
```gdscript
# Auto-timestamped: "screenshot-20260429_145230.png"
$Save.snap_screenshot(get_viewport())

# Custom name: "gameplay-moment-20260429_145230.png"
$Save.snap_screenshot(get_viewport(), "gameplay_moment")
```

#### Cloud Sync

```gdscript
func upload_save(profile: String = "save", filetype: String = ".sav") -> void
```

Uploads save file to remote server via HTTP POST.

**Parameters:**
- `profile` (String): Profile to upload
- `filetype` (String): File extension

**Requires:** `remote_save_url` set in export properties

**Example:**
```gdscript
$Save.remote_save_url = "https://api.example.com/save/upload"
$Save.upload_save("player_save")
```

```gdscript
func download_save(profile: String = "save", filetype: String = ".sav") -> void
```

Downloads save file from remote server via HTTP GET.

**Parameters:**
- `profile` (String): Profile to download
- `filetype` (String): File extension

**Requires:** `remote_save_url` set

**Example:**
```gdscript
$Save.download_save("cloud_save")
```

#### Migration & Version Control

```gdscript
func migrate_save_data(data: Dictionary, from_version: int) -> Dictionary
```

Override this method in a subclass for custom migrations.

**Parameters:**
- `data` (Dictionary): Old save data
- `from_version` (int): Version number of loaded save

**Returns:** Modified data with migrations applied

**Example:**
```gdscript
extends Save

func migrate_save_data(data: Dictionary, from_version: int) -> Dictionary:
    var d = data.duplicate(true)
    
    if from_version < 2:
        # Add new required fields
        d["new_field"] = "default_value"
        d["exp_points"] = 0
    
    return d
```

#### Logging

```gdscript
func _log(msg: String, is_screenshot: bool = false) -> void
```

Internal logging function.

- `msg` (String): Message to print
- `is_screenshot` (bool): If true, uses screenshot_print_in_terminal setting

---

## SaveCodec Class

**File**: `addons/GodotSavesAddon/save_codec.gd`  
**Extends**: `RefCounted`  
**Class Name**: `SaveCodec`  
**Lines**: ~350  
**Status**: Stable

### Overview

Utility class for serialization, encryption, compression, and integrity verification. All methods are `static`, so use directly: `SaveCodec.method_name()`.

### Static Methods

#### Hashing

```gdscript
static func sha256_bytes(bytes: PackedByteArray) -> PackedByteArray
```

Computes SHA-256 hash of byte array.

**Parameters:**
- `bytes` (PackedByteArray): Data to hash

**Returns:** SHA-256 hash as PackedByteArray (32 bytes)

```gdscript
static func sha256_hex(bytes: PackedByteArray) -> String
```

Computes SHA-256 hash and returns as hex string.

**Parameters:**
- `bytes` (PackedByteArray): Data to hash

**Returns:** Hex-encoded SHA-256 hash (64 chars)

**Example:**
```gdscript
var data = "hello world".to_utf8_buffer()
var hash = SaveCodec.sha256_hex(data)
print(hash)  # 7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069
```

#### Encryption (AES-256-CBC)

```gdscript
static func encrypt_aes256_cbc(data: PackedByteArray, aes_key_utf8: PackedByteArray) -> PackedByteArray
```

Encrypts data with AES-256-CBC.

**Parameters:**
- `data` (PackedByteArray): Data to encrypt
- `aes_key_utf8` (PackedByteArray): Encryption key (UTF-8 string as bytes)

**Returns:** Encrypted data (PackedByteArray)

**Process:**
1. Derives 256-bit key from UTF-8 key via SHA-256
2. Uses first 16 bytes of key as IV
3. PKCS7-pads plaintext
4. Encrypts with CBC mode
5. Returns ciphertext

```gdscript
static func decrypt_aes256_cbc(data: PackedByteArray, aes_key_utf8: PackedByteArray) -> PackedByteArray
```

Decrypts AES-256-CBC data.

**Parameters:**
- `data` (PackedByteArray): Encrypted data
- `aes_key_utf8` (PackedByteArray): Encryption key

**Returns:** Decrypted plaintext (PackedByteArray)

**Example:**
```gdscript
var key = "mysecretkey".to_utf8_buffer()
var plaintext = "sensitive data".to_utf8_buffer()

var encrypted = SaveCodec.encrypt_aes256_cbc(plaintext, key)
var decrypted = SaveCodec.decrypt_aes256_cbc(encrypted, key)

assert(decrypted.get_string_from_utf8() == "sensitive data")
```

#### Compression (ZIP)

```gdscript
static func compress_zip_single(data: PackedByteArray) -> PackedByteArray
```

Compresses data using ZIP.

**Parameters:**
- `data` (PackedByteArray): Data to compress

**Returns:** Compressed data (PackedByteArray)

**Process:**
1. Creates temp ZIP file
2. Adds data as single file entry
3. Closes and reads ZIP
4. Deletes temp file
5. Returns compressed bytes

```gdscript
static func decompress_zip_single(data: PackedByteArray) -> PackedByteArray
```

Decompresses ZIP data.

**Parameters:**
- `data` (PackedByteArray): Compressed ZIP data

**Returns:** Decompressed data (PackedByteArray)

**Example:**
```gdscript
var original = "large data string".to_utf8_buffer()

var compressed = SaveCodec.compress_zip_single(original)
var decompressed = SaveCodec.decompress_zip_single(compressed)

assert(original == decompressed)
print("Original: %d bytes, Compressed: %d bytes" % [original.size(), compressed.size()])
```

#### Serialization

```gdscript
static func serialize_dict(data: Dictionary, file_format: String) -> PackedByteArray
```

Converts Dictionary to bytes in chosen format.

**Parameters:**
- `data` (Dictionary): Data to serialize
- `file_format` (String): "json", "txt", or "bin"

**Returns:** Serialized bytes

**Formats:**
- `"json"`: Pretty JSON (keys sorted)
- `"txt"`: String representation
- `"bin"`: GDScript binary format

**Example:**
```gdscript
var data = {"name": "Player", "level": 10}

var json_bytes = SaveCodec.serialize_dict(data, "json")
var txt_bytes = SaveCodec.serialize_dict(data, "txt")
var bin_bytes = SaveCodec.serialize_dict(data, "bin")
```

```gdscript
static func deserialize_dict(bytes: PackedByteArray, file_format: String) -> Dictionary
```

Converts bytes back to Dictionary.

**Parameters:**
- `bytes` (PackedByteArray): Serialized bytes
- `file_format` (String): "json", "txt", or "bin"

**Returns:** Deserialized Dictionary (empty if failed)

**Example:**
```gdscript
var json_str = '{"name":"Hero","level":10}'
var bytes = json_str.to_utf8_buffer()
var data = SaveCodec.deserialize_dict(bytes, "json")
print(data["name"])  # "Hero"
```

#### Integrity

```gdscript
static func embed_integrity_checksum(data: Dictionary, file_format: String) -> Dictionary
```

Adds SHA-256 checksum to `_meta` field.

**Parameters:**
- `data` (Dictionary): Data to add checksum to
- `file_format` (String): Format used for serialization

**Returns:** Modified dictionary with checksum in `_meta.checksum`

**Process:**
1. Removes existing checksum from `_meta`
2. Serializes data to bytes
3. Computes SHA-256 of serialized data
4. Stores hex checksum in `_meta.checksum`

```gdscript
static func verify_integrity(parsed: Dictionary, file_format: String) -> bool
```

Verifies SHA-256 checksum.

**Parameters:**
- `parsed` (Dictionary): Data with checksum in `_meta.checksum`
- `file_format` (String): Format used for serialization

**Returns:** true if checksum matches, false if mismatch

**Example:**
```gdscript
var original = {"health": 100, "name": "Hero"}
var with_checksum = SaveCodec.embed_integrity_checksum(original, "json")
var is_valid = SaveCodec.verify_integrity(with_checksum, "json")
print(is_valid)  # true
```

#### Merging

```gdscript
static func deep_merge_defaults(base: Dictionary, defaults: Dictionary) -> void
```

Recursively merges default values into base dictionary.

**Parameters:**
- `base` (Dictionary): Dictionary to merge into (modified in-place)
- `defaults` (Dictionary): Default values to add

**Behavior:**
- Adds missing keys from defaults
- Recursively merges nested dictionaries
- Does not overwrite existing values

**Example:**
```gdscript
var save_data = {"name": "Hero"}
var defaults = {"name": "Unknown", "level": 1, "health": 100}

SaveCodec.deep_merge_defaults(save_data, defaults)
print(save_data)
# {"name": "Hero", "level": 1, "health": 100}
```

#### Main Encoding/Decoding

```gdscript
static func encode_buffer(
    data: Dictionary,
    file_format: String,
    use_compression: bool,
    use_encryption: bool,
    aes_key_utf8: PackedByteArray,
    use_integrity_checksum: bool
) -> PackedByteArray
```

Full encoding pipeline: serialize → checksum → compress → encrypt.

**Parameters:**
- `data` (Dictionary): Data to encode
- `file_format` (String): "json", "txt", or "bin"
- `use_compression` (bool): Apply ZIP compression
- `use_encryption` (bool): Apply AES-256 encryption
- `aes_key_utf8` (PackedByteArray): Encryption key
- `use_integrity_checksum` (bool): Add SHA-256 checksum

**Returns:** Final encoded bytes ready to write to file

**Process:**
1. Optional: Add SHA-256 checksum to `_meta`
2. Serialize to chosen format
3. Optional: Compress with ZIP
4. Optional: Encrypt with AES-256
5. Return final bytes

```gdscript
static func decode_buffer(
    bytes: PackedByteArray,
    file_format: String,
    use_compression: bool,
    use_encryption: bool,
    aes_key_utf8: PackedByteArray,
    verify_checksum: bool,
    load_despite_checksum_failure: bool = false
) -> Array
```

Full decoding pipeline: decrypt → decompress → deserialize → verify.

**Parameters:**
- `bytes` (PackedByteArray): Encoded bytes from file
- `file_format` (String): "json", "txt", or "bin"
- `use_compression` (bool): Was ZIP compression used
- `use_encryption` (bool): Was AES-256 encryption used
- `aes_key_utf8` (PackedByteArray): Encryption key
- `verify_checksum` (bool): Check SHA-256 integrity
- `load_despite_checksum_failure` (bool): Load even if checksum fails (default: false)

**Returns:** Array `[success: bool, data: Dictionary]`
- If success is true: `[true, {loaded_data}]`
- If success is false: `[false, {}]`

**Process:**
1. Optional: Decrypt with AES-256
2. Optional: Decompress with ZIP
3. Deserialize from chosen format
4. Optional: Verify SHA-256 checksum
5. Return result array

**Example:**
```gdscript
var key = "secret123".to_utf8_buffer()
var original = {"player": "Hero", "level": 10}

# Encode with all options
var encoded = SaveCodec.encode_buffer(
    original, "json", true, true, key, true
)

# Decode with same options
var result = SaveCodec.decode_buffer(
    encoded, "json", true, true, key, true
)

if result[0]:
    var decoded = result[1]
    print("Success:", decoded == original)
else:
    print("Decoding failed")
```

---

## SaveAddonPlugin

**File**: `addons/GodotSavesAddon/save_addon_plugin.gd`  
**Extends**: `EditorPlugin`  
**Lines**: ~20

### Overview

Editor plugin that registers the Save custom type and editor dock.

### Methods

```gdscript
func _enter_tree() -> void
```

Called when plugin is enabled. Registers Save custom type and dock.

```gdscript
func _exit_tree() -> void
```

Called when plugin is disabled. Removes custom type and dock.

### What It Does

1. Registers `Save` as custom node type (icon shown in editor)
2. Creates and adds SaveViewerDock to editor UI
3. Cleans up when plugin disabled

---

## SaveViewerDock

**File**: `addons/GodotSavesAddon/save_viewer_dock.gd`  
**Extends**: `VBoxContainer`  
**Lines**: ~200

### Overview

Editor dock UI for decoding and inspecting .sav files without running the game.

### Features

- Browse and select .sav files
- Toggle encryption/compression/checksums
- Set AES encryption key
- Choose serialization format (json/txt/bin)
- Load and decode files
- Display decoded data as formatted JSON
- Copy JSON to clipboard

### Properties

```gdscript
var _path_edit: LineEdit                # File path input
var _browse_btn: Button                 # Browse button
var _encrypt_chk: CheckBox              # Encryption toggle
var _compress_chk: CheckBox             # Compression toggle
var _checksum_chk: CheckBox             # Checksum verification toggle
var _strict_chk: CheckBox               # Strict integrity toggle
var _key_edit: LineEdit                 # AES key input
var _fmt_opt: OptionButton              # Format selector
var _load_btn: Button                   # Load button
var _copy_btn: Button                   # Copy to clipboard button
var _status: Label                      # Status message
var _out: TextEdit                      # Output display
var _file_dialog: FileDialog            # File browser
```

### Usage in Editor

1. Open the dock (View → Show in Dock → SaveState file viewer)
2. Browse to a .sav file
3. Configure options to match your Save node
4. Click "Load & decode"
5. View the decoded data
6. Click "Copy JSON" to copy to clipboard

---

## Complete Example: Using All Components

```gdscript
extends Node

@onready var save = $Save

func _ready():
    # Configure
    save.use_encryption = true
    save.AES_KEY = "my_game_key".to_utf8_buffer()
    save.use_compression = true
    save.use_integrity_checksum = true
    save.keep_backups = true
    save.backup_limit = 5
    
    # Connect signals
    save.save_completed.connect(_on_save_done)
    save.load_completed.connect(_on_load_done)
    save.save_failed.connect(_on_save_failed)
    save.load_failed.connect(_on_load_failed)
    save.migration_applied.connect(_on_migration)

func save_game():
    var game_data = {
        "player_name": "Hero",
        "level": 10,
        "inventory": ["sword", "shield"],
        "stats": {"health": 100, "mana": 50}
    }
    
    # Synchronous
    save.save_data(game_data, "player")
    
    # Or async
    save.save_data(game_data, "player", async_save: true)

func load_game():
    var data = save.edit_data("player")
    if not data.is_empty():
        print("Loaded: ", data["player_name"])
    return data

func take_screenshot():
    save.snap_screenshot(get_viewport(), "gameplay")

func upload_to_cloud():
    save.remote_save_url = "https://api.example.com/saves"
    save.upload_save("player")

func _on_save_done(profile: String):
    print("✓ Saved: ", profile)

func _on_load_done(profile: String, data: Dictionary):
    print("✓ Loaded: ", profile, " with ", data.size(), " keys")

func _on_save_failed(profile: String, reason: String):
    print("✗ Save failed: ", reason)

func _on_load_failed(profile: String, reason: String):
    print("✗ Load failed: ", reason)

func _on_migration(profile: String, from: int, to: int):
    print("Migrated from v%d to v%d" % [from, to])
```

---

For detailed class documentation, see:
- [Save Class](classes/Save.md)
- [SaveCodec Class](classes/SaveCodec.md)
- [SaveAddonPlugin](classes/SaveAddonPlugin.md)
- [SaveViewerDock](classes/SaveViewerDock.md)
