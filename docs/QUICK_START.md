# Quick Start Guide

Get the Godot Save Addon up and running in 5 minutes.

## ⚡ 5-Minute Setup

### Step 1: Install the Addon
1. Copy `addons/GodotSavesAddon` to your project's `addons/` folder
2. Restart Godot Editor
3. Enable the addon: **Project → Project Settings → Plugins** → Check "Godot Saves Addon"

### Step 2: Add Save Node to Your Scene
1. Right-click in the Scene tree
2. Select "Add Child Node"
3. Search for and add **Save**
4. Name it (e.g., `SaveManager`)

### Step 3: Configure Basic Settings (Inspector)
- **folder_name**: Where saves are stored (default: "save")
- **file_format**: "json", "txt", or "bin" (default: "json")
- **save_name**: Profile to auto-load on ready (optional)
- **print_in_terminal**: Enable debug output (default: true)

## 🎯 Basic Usage Examples

### Example 1: Save Data

```gdscript
extends Node

@onready var save_mgr = $SaveManager

func _ready():
    # Connect to signals
    save_mgr.save_completed.connect(_on_save_completed)
    save_mgr.save_failed.connect(_on_save_failed)

func save_game():
    var game_data = {
        "player_name": "Hero",
        "level": 5,
        "exp": 1200,
        "inventory": ["sword", "shield", "potion"]
    }
    
    save_mgr.save_data(game_data, "game_save")
    print("Saving game...")

func _on_save_completed(profile: String):
    print("Game saved: ", profile)

func _on_save_failed(profile: String, reason: String):
    print("Save failed: ", reason)
```

### Example 2: Load Data

```gdscript
func load_game():
    var loaded_data = $SaveManager.edit_data("game_save")
    
    if loaded_data.is_empty():
        print("No save file found!")
        return
    
    print("Loaded player: ", loaded_data["player_name"])
    print("Level: ", loaded_data["level"])
```

### Example 3: Handle Load Signal

```gdscript
func _ready():
    $SaveManager.load_completed.connect(_on_load_completed)
    $SaveManager.load_failed.connect(_on_load_failed)

func _on_load_completed(profile: String, data: Dictionary):
    print("Loaded profile '%s' with %d keys" % [profile, data.size()])
    # Use the data here

func _on_load_failed(profile: String, reason: String):
    print("Load failed for '%s': %s" % [profile, reason])
```

### Example 4: Multiple Save Profiles

```gdscript
func _ready():
    # Save multiple game slots
    var slot1 = {"name": "Save 1", "level": 10}
    var slot2 = {"name": "Save 2", "level": 20}
    
    $SaveManager.save_data(slot1, "slot_1")
    $SaveManager.save_data(slot2, "slot_2")

func load_slot(slot_num: int):
    var profile = "slot_%d" % slot_num
    var data = $SaveManager.edit_data(profile)
    return data
```

### Example 5: List All Saves

```gdscript
func list_all_saves():
    var profiles = $SaveManager.list_profiles()
    
    for profile in profiles:
        print("Found save: ", profile)
    
    return profiles
```

### Example 6: Delete Saves

```gdscript
# Delete a single profile
func delete_save(profile: String):
    var path = "user://save/" + profile + ".sav"
    DirAccess.remove_absolute(path)

# Delete all saves
func delete_all_saves():
    $SaveManager.delete_all_profiles()
    print("All saves deleted")
```

### Example 7: Screenshots

```gdscript
func take_screenshot():
    $SaveManager.snap_screenshot(get_viewport(), "gameplay_moment")
    print("Screenshot saved!")

func take_screenshot_with_timestamp():
    # Timestamp is added automatically
    $SaveManager.snap_screenshot(get_viewport())
```

## 🔐 With Encryption

```gdscript
extends Node

@onready var save_mgr = $SaveManager

func _ready():
    # Enable encryption in Inspector or code:
    save_mgr.use_encryption = true
    save_mgr.AES_KEY = "your_secret_key_here".to_utf8_buffer()

func save_encrypted():
    var data = {"secret": "confidential_data"}
    save_mgr.save_data(data, "encrypted_save")
    # File is now encrypted with AES-256!
```

## 📦 With Compression

```gdscript
func _ready():
    $SaveManager.use_compression = true

func save_compressed():
    var large_data = {}
    # ... populate with lots of data
    $SaveManager.save_data(large_data, "compressed_save")
    # File is now compressed!
```

## 🔄 Auto-Save

```gdscript
func _ready():
    $SaveManager.auto_save_interval = 30.0  # Save every 30 seconds
    
    # Store data to auto-save in the root's metadata
    get_tree().root.set_meta("autosave_data", {
        "playtime": 0,
        "last_checkpoint": "level_1"
    })

func _process(delta):
    var meta = get_tree().root.get_meta("autosave_data")
    meta["playtime"] += delta
```

## 🎨 Full Example: Game Manager

```gdscript
extends Node

@onready var save = $SaveManager

var current_game_data = {}

func _ready():
    # Configure
    save.use_encryption = false
    save.keep_backups = true
    save.backup_limit = 3
    
    # Connect signals
    save.save_completed.connect(_on_save_done)
    save.load_completed.connect(_on_load_done)
    
    # Auto-load if available
    load_game("autosave")

func new_game():
    current_game_data = {
        "player_name": "New Hero",
        "level": 1,
        "exp": 0,
        "health": 100,
        "inventory": []
    }

func save_game(profile: String = "autosave"):
    current_game_data["last_saved"] = Time.get_ticks_msec()
    save.save_data(current_game_data, profile)

func load_game(profile: String):
    current_game_data = save.edit_data(profile)
    if not current_game_data.is_empty():
        print("Loaded: ", profile)

func _on_save_done(profile: String):
    print("✓ Saved: ", profile)

func _on_load_done(profile: String, data: Dictionary):
    if not data.is_empty():
        print("✓ Loaded: ", profile, " (%d keys)" % data.size())
```

## 📋 Configuration Checklist

Before deploying, configure these in the Inspector:

- [ ] **folder_name** - Set where saves are stored
- [ ] **save_name** - Set default profile to load
- [ ] **file_format** - Choose json/txt/bin
- [ ] **use_encryption** - Enable if needed
- [ ] **use_compression** - Enable for large saves
- [ ] **keep_backups** - Set backup strategy
- [ ] **auto_save_interval** - Set auto-save frequency (0 = disabled)
- [ ] **screenshot_max_count** - Limit screenshot folder size
- [ ] **print_in_terminal** - Disable in production

## 🔗 Next Steps

1. Read [Configuration](CONFIGURATION.md) for all options
2. Explore [examples/](../examples/) for more use cases
3. Review [Security](SECURITY.md) best practices
4. Check [Troubleshooting](TROUBLESHOOTING.md) if issues arise

## 💡 Tips

- **Signals are important**: Always connect to `save_completed` and `load_completed` to know when operations finish
- **Use profiles**: Different profiles for game slots, settings, cache, etc.
- **Backups are essential**: Keep `keep_backups = true` in production
- **Test encryption**: If using encryption, test on real data before shipping
- **Monitor performance**: Use `print_in_terminal = false` in production builds
- **Validate data**: Check loaded data before using it (corrupted saves may return `{}`)

## ⚠️ Common Mistakes

❌ **Not connecting to signals** - Load/save operations are asynchronous  
❌ **Using encryption without testing** - Always test key derivation  
❌ **Ignoring integrity checks** - Enable checksums in production  
❌ **Not handling empty loads** - Always check if `edit_data()` returns `{}`  
❌ **Storing critical data without backups** - Enable backup system  

---

For more details, see [API.md](API.md) and the [Save class documentation](classes/Save.md).
