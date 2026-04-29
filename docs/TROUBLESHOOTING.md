# Troubleshooting Guide

Common issues and solutions when using the Godot Save Addon.

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [File Not Found Errors](#file-not-found-errors)
3. [Encryption/Decryption Problems](#encryptiondecryption-problems)
4. [Checksum & Integrity Issues](#checksum--integrity-issues)
5. [Performance Issues](#performance-issues)
6. [Signal/Callback Issues](#signalcallback-issues)
7. [Platform-Specific Issues](#platform-specific-issues)
8. [Data Corruption](#data-corruption)

---

## Installation Issues

### Problem: Addon Not Appearing in Scene

**Symptoms:**
- Can't find "Save" node in "Add Child Node" dialog
- Addon not visible in Scene tree

**Solutions:**

1. **Check if enabled**:
   - Project → Project Settings → Plugins
   - Find "Godot Saves Addon"
   - Verify checkbox is checked

2. **Reload project**:
   ```
   File → Reload Project
   ```

3. **Check file structure**:
   - Addon should be in: `addons/GodotSavesAddon/`
   - Required files:
     - `save_addon.gd`
     - `save_addon_plugin.gd`
     - `plugin.cfg`

4. **Check Output panel** for errors:
   - If there's a syntax error in plugin files, it won't load
   - Fix the error and reload

---

### Problem: Editor Dock Not Visible

**Symptoms:**
- SaveState file viewer dock doesn't appear in editor

**Solutions:**

1. **Check View menu**:
   - View → Show in Dock
   - Look for "SaveState file viewer"
   - Click to show

2. **Reset editor layout**:
   - Window → Editor Layout → Default
   - Reload project

3. **Check if plugin enabled**:
   - Plugin must be enabled for dock to appear
   - See "Addon Not Appearing in Scene" above

---

### Problem: "Cannot find script" Error

**Symptoms:**
- Error: "Cannot load script save_addon_plugin.gd"
- Error appears in Output tab

**Solutions:**

1. **Check file exists**:
   - Navigate to `addons/GodotSavesAddon/`
   - Verify all `.gd` files are present

2. **Check .uid files**:
   - Each `.gd` file should have `.gd.uid`
   - If missing, close and reopen Godot
   - Godot will regenerate them

3. **Fix plugin.cfg**:
   - Open `addons/GodotSavesAddon/plugin.cfg`
   - Check: `script="save_addon_plugin.gd"` (correct path)
   - Path should be relative to plugin folder

---

## File Not Found Errors

### Problem: "File not found, returning empty dictionary"

**Symptoms:**
- `edit_data()` returns `{}`
- Message: "File not found, returning empty dictionary"

**This is NOT an error** - it's normal when:
- Loading first time (no save exists yet)
- Profile name is wrong
- File was deleted

**Solutions:**

1. **Check profile name**:
   ```gdscript
   # Wrong
   var data = $Save.edit_data("save")  # Looking for save.sav
   
   # Right - match the profile you saved with
   var data = $Save.edit_data("player")  # Looking for player.sav
   ```

2. **Check file extension**:
   ```gdscript
   # If saved as .json
   $Save.save_data(data, "test", ".json")
   
   # Must load as .json
   var loaded = $Save.edit_data("test", ".json")
   ```

3. **Check save path**:
   - By default: `user://save/`
   - If `data_in_folder = true`: `res://save/`
   - Check that folder actually exists and contains file

4. **Handle missing files gracefully**:
   ```gdscript
   var data = $Save.edit_data("player")
   
   if data.is_empty():
       print("No save file, creating new game")
       var new_data = create_default_save()
       $Save.save_data(new_data, "player")
       return new_data
   
   return data
   ```

---

### Problem: Wrong Folder Location

**Symptoms:**
- Saves disappear after game restart
- Saves in wrong location

**Solutions:**

1. **Check data_in_folder setting**:
   - `false` (default): `user://save/` - Correct for most games
   - `true`: `res://save/` - Only for development

2. **Verify folder_name**:
   ```gdscript
   $Save.folder_name = "savegames"  # Creates user://savegames/
   ```

3. **Find save files**:
   - Open FileManager
   - Navigate to where saves are stored
   - Windows: `C:\Users\[User]\AppData\Roaming\Godot\app_userdata\[ProjectName]\save\`
   - macOS: `~/.godot/app_userdata/[ProjectName]/save/`
   - Linux: `~/.godot/app_userdata/[ProjectName]/save/`

---

## Encryption/Decryption Problems

### Problem: Encryption/Decryption Fails

**Symptoms:**
- Error: "SaveCodec: integrity check failed"
- Wrong key produces garbage data
- Cannot decrypt saved files

**Solutions:**

1. **Check encryption enabled on both save and load**:
   ```gdscript
   # Save with encryption
   $Save.use_encryption = true
   $Save.AES_KEY = "secret".to_utf8_buffer()
   $Save.save_data(data, "test")
   
   # Load with SAME encryption
   $Save.use_encryption = true
   $Save.AES_KEY = "secret".to_utf8_buffer()  # Must match!
   var loaded = $Save.edit_data("test")
   ```

2. **Verify key matches**:
   ```gdscript
   # Wrong - different keys
   # Save
   $Save.AES_KEY = "secret123".to_utf8_buffer()
   
   # Load
   $Save.AES_KEY = "secret124".to_utf8_buffer()  # Different!
   ```

3. **Check key derivation**:
   - Key is hashed with SHA-256 internally
   - Same plaintext key always produces same derived key
   - If key changes, files become unreadable

4. **Test with simple data**:
   ```gdscript
   $Save.use_encryption = true
   $Save.AES_KEY = "test".to_utf8_buffer()
   
   # Test with minimal data
   $Save.save_data({"test": 1}, "encrypt_test")
   var result = $Save.edit_data("encrypt_test")
   
   if result.is_empty():
       print("Encryption failed")
   else:
       print("Encryption works: ", result)
   ```

---

### Problem: "Cannot Decrypt" After Update

**Symptoms:**
- Old saves won't load after code changes
- Encryption parameters changed

**Solution:**

Old saves are **permanently unreadable** if:
- Encryption key changed
- File format changed (json ↔ txt)
- Compression toggle changed

**Prevention**:
- Never change encryption key in production
- Document your encryption key securely
- Test migrations thoroughly
- Keep backups of old saves

---

## Checksum & Integrity Issues

### Problem: "Integrity Check Failed"

**Symptoms:**
- Error: "SaveCodec: integrity check failed (checksum mismatch)"
- Save loads as `{}`

**Causes**:
1. File was manually edited
2. File corrupted on disk
3. Different format used (saved as json, loaded as txt)
4. Compression mismatch (saved compressed, loaded uncompressed)

**Solutions:**

1. **Check format matches**:
   ```gdscript
   # Save
   $Save.file_format = "json"
   $Save.save_data(data, "test")
   
   # Load with SAME format
   $Save.file_format = "json"  # Must match!
   var loaded = $Save.edit_data("test")
   ```

2. **Check compression matches**:
   ```gdscript
   # Save
   $Save.use_compression = true
   $Save.save_data(data, "test")
   
   # Load with SAME compression
   $Save.use_compression = true  # Must match!
   var loaded = $Save.edit_data("test")
   ```

3. **Disable strict mode to recover data**:
   ```gdscript
   $Save.strict_integrity = false
   var loaded = $Save.edit_data("test")  # Loads anyway with warning
   ```

4. **Restore from backup**:
   - If `keep_backups = true`, older versions available
   - `.sav.bak1` is most recent backup
   - Manually restore if needed

---

### Problem: "Use_integrity_checksum" Setting Confusion

**Question**: Should I enable or disable checksums?

**Answer**: Keep it **enabled** (`true`):
- Helps detect file corruption
- Minimal performance impact
- Only matters if file manually edited

**When to disable** (`false`):
- Testing without checksum validation
- Trying to load corrupted files (use with caution)
- Legacy saves without checksums

---

## Performance Issues

### Problem: Saves/Loads Are Slow

**Symptoms:**
- Game freezes when saving
- Loading takes long time
- Frame drops during save

**Solutions:**

1. **Use async saves**:
   ```gdscript
   # Blocks main thread (slow)
   $Save.save_data(large_data, "test", async_save: false)
   
   # Non-blocking (fast)
   $Save.save_data(large_data, "test", async_save: true)
   ```

2. **Enable compression**:
   ```gdscript
   $Save.use_compression = true  # Smaller files = faster I/O
   $Save.save_data(data, "test")
   ```

3. **Reduce data size**:
   - Don't save unnecessary data
   - Compress images/assets separately
   - Archive old saves

4. **Check disk speed**:
   - Slow disk = slow saves
   - Use SSD if possible
   - Check disk space (low space = slow I/O)

---

### Problem: Memory Leak with Screenshots

**Symptoms:**
- Memory usage grows over time
- Game slows down with many screenshots
- "Screenshot queue overflow" message

**Solutions:**

1. **Set screenshot limit**:
   ```gdscript
   $Save.screenshot_max_count = 50  # Rotate old screenshots
   ```

2. **Don't spam screenshots**:
   ```gdscript
   # Wrong - takes screenshot every frame!
   func _process(delta):
       $Save.snap_screenshot(get_viewport())  # BAD
   
   # Right - take screenshot on demand
   func _input(event):
       if event is InputEventKey and event.pressed:
           if event.keycode == KEY_F12:
               $Save.snap_screenshot(get_viewport())  # Good
   ```

3. **Monitor queue size**:
   - Default max queue: 4 screenshots
   - If exceeded, queue overflows
   - Increase if needed: Access via `$Save._queue`

---

## Signal/Callback Issues

### Problem: Signals Not Firing

**Symptoms:**
- `save_completed` never emits
- `load_completed` never called
- No response to save/load operations

**Solutions:**

1. **Connect before calling**:
   ```gdscript
   # Wrong - signal fires before connected
   $Save.save_data(data, "test")
   $Save.save_completed.connect(_on_save_done)  # Too late!
   
   # Right - connect in _ready
   func _ready():
       $Save.save_completed.connect(_on_save_done)
   
   func _on_save_done(profile):
       print("Saved: ", profile)
   ```

2. **Use proper signal syntax**:
   ```gdscript
   # Wrong - missing .connect()
   $Save.save_completed(_on_save_done)
   
   # Right
   $Save.save_completed.connect(_on_save_done)
   ```

3. **Check function signature**:
   ```gdscript
   # save_completed has 1 parameter
   func _on_save_done(profile: String):  # Correct
       pass
   
   # load_completed has 2 parameters
   func _on_load_done(profile: String, data: Dictionary):  # Correct
       pass
   ```

---

### Problem: Callback Never Called

**Symptoms:**
- Function defined but never executes
- Breakpoint in callback not hit

**Solutions:**

1. **Verify connection syntax**:
   ```gdscript
   # Using Callable
   $Save.save_completed.connect(Callable(self, "_on_save_done"))
   
   # Using func
   $Save.save_completed.connect(func(p): print("Saved: ", p))
   
   # Wrong - missing .connect()
   $Save.save_completed(_on_save_done)  # This won't work!
   ```

2. **Check node exists**:
   ```gdscript
   if not is_node_ready():
       print("Node not ready, can't connect")
   ```

3. **Ensure node is added to scene**:
   - Save node must be in scene tree
   - Signal won't work on orphaned nodes

---

## Platform-Specific Issues

### Windows: Permission Denied

**Symptoms:**
- Error: "Permission denied" when saving
- Cannot write to user:// folder

**Solutions**:

1. **Check folder permissions**:
   - Right-click folder → Properties → Security
   - Verify your user has Write permission

2. **Use different folder**:
   ```gdscript
   $Save.folder_name = "My Games/MyGame/saves"
   ```

3. **Run as administrator**:
   - Some system folders restricted
   - Try running Godot as admin

---

### macOS: File Access Denied

**Symptoms:**
- Save fails with permission error
- File not found in expected location

**Solutions:**

1. **Check sandbox permissions**:
   - Some macOS versions restrict file access
   - Check Privacy & Security settings

2. **Use different path**:
   ```gdscript
   $Save.folder_name = "Saves"  # Uses ~/.godot/app_userdata/
   ```

---

### Linux: Path Issues

**Symptoms:**
- Save path contains backslashes
- Files not found in expected location

**Solutions**:

1. **Always use forward slashes**:
   ```gdscript
   # Wrong - Windows style
   $Save.folder_name = "saves\player"
   
   # Right - Unix style
   $Save.folder_name = "saves/player"
   ```

2. **Check folder permissions**:
   ```bash
   chmod 755 ~/.godot/app_userdata/ProjectName/
   ```

---

## Data Corruption

### Problem: Corrupted Save File

**Symptoms:**
- File exists but won't load
- Checksum mismatch
- Garbage data in save file

**Recovery:**

1. **Use backup**:
   - If `keep_backups = true`
   - Copy `.sav.bak1` → `.sav`
   - Try loading again

2. **Disable strict integrity**:
   ```gdscript
   $Save.strict_integrity = false
   var data = $Save.edit_data("corrupted_save")
   # May return partial/garbage data
   ```

3. **Inspect in editor dock**:
   - Open SaveState file viewer
   - Disable strict integrity
   - Try to decode
   - See what data is readable

---

### Problem: Data Lost After Crash

**Symptoms:**
- Game crashed while saving
- Save file missing/corrupted
- Lost player progress

**Prevention**:

1. **Enable backups**:
   ```gdscript
   $Save.keep_backups = true
   $Save.backup_limit = 5
   ```

2. **Use async saves carefully**:
   ```gdscript
   # Async saves don't block, but aren't instant
   $Save.save_data(data, "important", async_save: true)
   # Don't quit immediately after!
   ```

3. **Wait for signal**:
   ```gdscript
   var saved = false
   
   $Save.save_completed.connect(func(p): saved = true)
   $Save.save_data(important_data, "backup")
   
   await get_tree().root.tree_exiting
   while not saved:
       await get_tree().process_frame
   
   # Now safe to quit
   get_tree().quit()
   ```

---

## Debug Tips

### Enable All Terminal Output

```gdscript
@onready var save = $Save

func _ready():
    save.print_in_terminal = true
    save.screenshot_print_in_terminal = true
```

Check Output tab for detailed messages.

### Test Manually

```gdscript
func test_save_system():
    print("=== Testing Save System ===")
    
    var test_data = {"test": true, "time": Time.get_ticks_msec()}
    
    print("1. Testing basic save...")
    $Save.save_data(test_data, "test_profile")
    
    print("2. Testing load...")
    var loaded = $Save.edit_data("test_profile")
    print("Loaded: ", loaded)
    assert(loaded == test_data, "Data mismatch!")
    
    print("3. Testing encryption...")
    $Save.use_encryption = true
    $Save.save_data(test_data, "test_encrypted")
    loaded = $Save.edit_data("test_encrypted")
    assert(loaded == test_data, "Encrypted load failed!")
    
    print("✓ All tests passed!")
```

### Check Save Files Exist

```gdscript
func list_saves():
    var dir = DirAccess.open("user://save")
    if dir == null:
        print("Save folder doesn't exist!")
        return
    
    for file in dir.get_files():
        print(file)
```

---

For more help, see [API.md](../API.md) and [CONFIGURATION.md](../CONFIGURATION.md).
