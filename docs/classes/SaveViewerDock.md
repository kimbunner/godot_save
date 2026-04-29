# SaveViewerDock Class - Editor Tool Documentation

**File**: `addons/GodotSavesAddon/save_viewer_dock.gd`  
**Extends**: `VBoxContainer`  
**Lines**: ~200  
**Status**: Stable

---

## Overview

`SaveViewerDock` is the editor UI dock that allows inspecting and decoding `.sav` files without running the game.

It appears at the bottom of the Godot editor (when addon is enabled) and provides:
- File browser to select save files
- Configuration options (encryption, compression, format)
- Decode button to parse files
- Display decoded data as formatted JSON
- Copy to clipboard functionality

---

## User Interface

### Layout

```
┌─────────────────────────────────────────────┐
│ SaveState file viewer                       │
├─────────────────────────────────────────────┤
│ Path to .sav / .save file       │ Browse... │
│ ☐ Encrypted (AES-256 CBC)                  │
│ ☐ Compressed (ZIP)                         │
│ ☐ Expect SHA-256 checksum in _meta         │
│ ☐ Strict integrity (reject on bad checksum)│
│ AES key (UTF-8): [supersecretkey123      ]│
│ Format: [json ▼]                           │
│ [Load & decode]  [Copy JSON]               │
│ Status: Pick a file and options...         │
├─────────────────────────────────────────────┤
│ Decoded content appears here as JSON:      │
│ {                                          │
│   "player": "Hero",                        │
│   "level": 10,                             │
│   ...                                      │
│ }                                          │
└─────────────────────────────────────────────┘
```

---

## Components

### UI Elements

```gdscript
var _path_edit: LineEdit           # File path input field
var _browse_btn: Button            # "Browse..." button
var _encrypt_chk: CheckBox         # Encryption toggle
var _compress_chk: CheckBox        # Compression toggle
var _checksum_chk: CheckBox        # Checksum verification toggle
var _strict_chk: CheckBox          # Strict integrity toggle
var _key_edit: LineEdit            # AES key input
var _fmt_opt: OptionButton         # Format selector (json/txt/bin)
var _load_btn: Button              # "Load & decode" button
var _copy_btn: Button              # "Copy JSON" button
var _status: Label                 # Status message display
var _out: TextEdit                 # Output display area
var _file_dialog: FileDialog       # File picker
```

---

## Methods

### \_ready() -> void

```gdscript
func _ready() -> void
```

Initialize dock UI on scene ready.

**Creates:**
1. Title label
2. Path row (input + browse button)
3. Encryption checkbox
4. Compression checkbox
5. Checksum checkboxes (expect, strict)
6. Key row (label + input)
7. Format dropdown
8. Button row (load, copy)
9. Status label
10. Output text display
11. File dialog
12. Signal connections

**Initial State:**
- Encryption unchecked, key field disabled
- Compression unchecked
- Checksum verification enabled
- Strict integrity enabled
- Output empty
- Default key: "supersecretkey123"

---

### \_on_crypto_toggled(pressed: bool) -> void

```gdscript
func _on_crypto_toggled(pressed: bool) -> void
```

Enable/disable AES key field based on encryption toggle.

**Parameters:**
- `pressed` (bool): Is encryption enabled?

**Behavior:**
- If `true`: Key field becomes editable
- If `false`: Key field grayed out

**When Called:**
- User toggles "Encrypted" checkbox

**Example:**
- Encrypt checkbox ON → Key field editable
- Encrypt checkbox OFF → Key field disabled

---

### \_on_browse() -> void

```gdscript
func _on_browse() -> void
```

Open file browser dialog.

**Behavior:**
- Opens FileDialog
- User selects a .sav file
- Dialog emits `file_selected` signal
- Connected to `_on_file_picked()`

**Dialog Settings:**
- Mode: FILE_MODE_OPEN_FILE (single file)
- Access: ACCESS_FILESYSTEM (full file system)
- Title: "Open save file"

---

### \_on_file_picked(p: String) -> void

```gdscript
func _on_file_picked(p: String) -> void
```

Handle file selection from browser.

**Parameters:**
- `p` (String): Full path to selected file

**Behavior:**
- Sets path_edit text to selected path
- Ready for user to click "Load & decode"

**Example:**
- User clicks Browse
- Selects `/home/user/.godot/app_userdata/MyGame/save/player.sav`
- Path field populates with this path

---

### \_format_name() -> String

```gdscript
func _format_name() -> String
```

Get format string from dropdown selection.

**Returns:** String - `"json"`, `"txt"`, or `"bin"`

**Logic:**
```
option 0 (default) → "json"
option 1           → "txt"
option 2           → "bin"
```

**Used by:** `_on_load()` to pass to SaveCodec

---

### \_on_load() -> void

```gdscript
func _on_load() -> void
```

Load and decode the selected file.

**Process:**
1. Get path from input field
2. Validate path not empty
3. Validate file exists
4. Open file and read bytes
5. Prepare decryption key (if needed)
6. Call `SaveCodec.decode_buffer()`
7. Display results or error

**Validations:**
- Path must not be empty
- File must exist
- File must be readable

**Updates:**
- `_status` label with result/error
- `_out` text display with decoded JSON
- Bytes size and key count shown in status

**Example Output:**
```
Status: OK — 1024 bytes raw, 5 top-level keys.
Output:
{
  "player": "Hero",
  "level": 10,
  "health": 100,
  "inventory": ["sword", "shield"],
  "position": [100, 200]
}
```

---

### \_on_copy() -> void

```gdscript
func _on_copy() -> void
```

Copy decoded JSON to clipboard.

**Process:**
1. Check if output not empty
2. Copy to system clipboard
3. Update status message

**Requirements:**
- Must have decoded data first
- Click "Load & decode" before "Copy JSON"

**Result:**
- JSON copied to clipboard
- Can paste into text editor, etc.

---

## Signal Connections

```gdscript
# File dialog → file selected
_file_dialog.file_selected.connect(_on_file_picked)

# Encryption toggle → enable/disable key field
_encrypt_chk.toggled.connect(_on_crypto_toggled)

# Initial call to set key field state
_on_crypto_toggled(_encrypt_chk.button_pressed)
```

---

## Workflow

### Typical Usage

1. **Browse for File**
   - Click "Browse…"
   - Select a .sav file
   - Path field populates

2. **Configure Options**
   - Enable encryption if file encrypted
   - Enter encryption key if needed
   - Enable compression if file compressed
   - Select correct format (json/txt/bin)
   - Choose checksum options

3. **Load & Decode**
   - Click "Load & decode"
   - Status shows results
   - Output displays decoded JSON

4. **Copy or Inspect**
   - Read data in output area
   - Click "Copy JSON" to copy to clipboard
   - Paste into editor/validator as needed

### Example Workflow

```
1. File saved with: encryption=true, compression=true, format="json"
2. In dock, enable: [✓ Encrypted] [✓ Compressed] [json]
3. Enter key: "my_secret_key"
4. Click "Load & decode"
5. View decoded data
6. Click "Copy JSON"
7. Paste into text editor
```

---

## Properties

### Size and Layout

```gdscript
size_flags_vertical = Control.SIZE_EXPAND_FILL
custom_minimum_size = Vector2(320, 200)
```

- Dock expands to fill available space
- Minimum 320x200 pixels
- Output area expands with dock

### Output Text Edit

```gdscript
_out.editable = false              # Read-only (can't edit in dock)
_out.custom_minimum_size = Vector2(0, 220)  # Min height for output
```

---

## Common Operations

### Check Checksum

1. Load file with checksum options:
   - Enable: "Expect SHA-256 checksum"
   - Enable: "Strict integrity"
2. Click "Load & decode"
3. If checksum fails: Status shows error
4. If checksum passes: Data displays normally

### Decrypt Encrypted Save

1. Enable: "Encrypted (AES-256 CBC)"
2. Enter encryption key in field
3. Configure other options
4. Click "Load & decode"
5. If key wrong: Shows error
6. If key correct: Data displays

### Compare Formats

Same file in different formats:

1. Select format "json" → Load
2. Select format "txt" → Load
3. Select format "bin" → Load
4. Compare outputs in each format

### Debug Save Corruption

1. Load file normally
2. If fails, try with:
   - Disable: "Strict integrity"
   - Enable: "Expect SHA-256 checksum"
3. Try partial data recovery

---

## Limitations

1. **Read-Only**: Cannot edit saves in dock
2. **Single File**: One file at a time
3. **Display Only**: Must have correct options for format to parse
4. **No Undo**: No history/undo functionality
5. **Size Limit**: Very large saves may display slowly

---

## Integration with Save Class

The dock mirrors Save class configuration:

| Save Class Setting | Dock Setting |
|-------------------|--------------|
| `use_encryption` | Encrypted checkbox |
| `AES_KEY` | AES key field |
| `use_compression` | Compressed checkbox |
| `file_format` | Format dropdown |
| `use_integrity_checksum` | Expect checksum checkbox |
| `strict_integrity` | Strict integrity checkbox |

**Important**: Settings in dock must match Save class settings used to create the save file.

---

## Error Messages

### "Enter a file path."
- Path field is empty
- Type path or click Browse

### "File does not exist: [path]"
- Path points to non-existent file
- Check path spelling
- Use Browse button

### "Could not open file for reading."
- File exists but can't be read
- Permission issue
- File locked by another process
- Try closing game if running

### "Decode failed or checksum mismatch..."
- Format/encryption/compression settings wrong
- File corrupted
- Try disabling "Strict integrity" to load anyway
- Or adjust options to match Save class

---

## Tips & Tricks

### Inspect Without Running Game

- Make quick changes to save
- See how game would load it
- Verify data structure
- No need to run game

### Quick Format Check

- Load same file in all formats
- See which format works
- Useful for debugging

### Test Encryption

- Load file with wrong key
- Verify encryption working
- See garbage data if key wrong
- See correct data if key right

### Copy for Analysis

- Copy JSON output
- Paste into validator (jsonlint.com)
- Verify structure
- Share with team for debugging

---

## Troubleshooting

### Dock Not Showing?

1. Check View → Show in Dock → SaveState file viewer
2. Plugin must be enabled
3. Try reloading project

### Can't Load File?

1. Check path is correct
2. Verify file exists
3. Check options match Save class
4. Try Browse button

### Key Not Working?

1. Make sure encryption enabled
2. Check key matches exactly
3. Spaces matter!
4. Try default: "supersecretkey123"

---

For Save class documentation, see [Save.md](Save.md).
