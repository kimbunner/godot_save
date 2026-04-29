# Basic Examples

Common usage patterns for the Godot Save Addon.

## Table of Contents

1. [Simple Save and Load](#simple-save-and-load)
2. [Handling Signals](#handling-signals)
3. [Multiple Save Slots](#multiple-save-slots)
4. [Auto-Save](#auto-save)
5. [Settings Persistence](#settings-persistence)
6. [Screenshot Capture](#screenshot-capture)
7. [Error Handling](#error-handling)
8. [Game Manager Pattern](#game-manager-pattern)

---

## Simple Save and Load

### Basic Example

```gdscript
extends Node

@onready var save = $Save

func save_game():
    var data = {
        "player_name": "Hero",
        "level": 10,
        "health": 100,
        "position": Vector2(100, 200)
    }
    save.save_data(data, "player")

func load_game():
    var data = save.edit_data("player")
    if data.is_empty():
        print("No save found")
        return
    
    print("Loaded: ", data["player_name"])
    return data
```

### With Type Checking

```gdscript
func load_game_safe() -> Dictionary:
    var data = save.edit_data("player")
    
    # Validate data structure
    if data.is_empty():
        push_error("Save file not found")
        return {}
    
    if not (data.has("player_name") and data.has("level")):
        push_error("Save file corrupted (missing keys)")
        return {}
    
    return data
```

### One-Liner Loading

```gdscript
func quick_load() -> Variant:
    var data = $Save.edit_data("quicksave")
    return data if not data.is_empty() else null
```

---

## Handling Signals

### Connect in _ready

```gdscript
extends Node

func _ready():
    $Save.save_completed.connect(_on_save_done)
    $Save.load_completed.connect(_on_load_done)
    $Save.save_failed.connect(_on_save_failed)
    $Save.load_failed.connect(_on_load_failed)

func save_game():
    $Save.save_data({"data": "test"}, "game")

func _on_save_done(profile: String):
    print("✓ Saved: ", profile)

func _on_load_done(profile: String, data: Dictionary):
    if not data.is_empty():
        print("✓ Loaded: ", profile, " with %d keys" % data.size())

func _on_save_failed(profile: String, reason: String):
    print("✗ Save failed: ", reason)

func _on_load_failed(profile: String, reason: String):
    print("✗ Load failed: ", reason)
```

### Using Callable

```gdscript
@onready var save = $Save

func _ready():
    save.save_completed.connect(
        func(profile): 
            print("Saved: ", profile)
    )
    
    save.load_completed.connect(
        func(profile, data):
            if data.is_empty():
                print("No data")
            else:
                process_loaded_data(data)
    )
```

### Async Pattern with Await

```gdscript
@onready var save = $Save

func _ready():
    save.save_completed.connect(func(p): _save_done.emit(p))

signal _save_done(profile: String)

func save_with_callback():
    save.save_data({"test": true}, "async_save")
    var profile = await _save_done
    print("Async save done: ", profile)
```

---

## Multiple Save Slots

### Save Slot System

```gdscript
extends Node

const SLOT_COUNT = 3

func save_to_slot(slot: int, data: Dictionary):
    if slot < 1 or slot > SLOT_COUNT:
        push_error("Invalid slot: ", slot)
        return
    
    var profile = "slot_%d" % slot
    $Save.save_data(data, profile)

func load_from_slot(slot: int) -> Dictionary:
    var profile = "slot_%d" % slot
    return $Save.edit_data(profile)

func delete_slot(slot: int):
    var path = "user://save/slot_%d.sav" % slot
    DirAccess.remove_absolute(path)

func get_all_slots() -> Array:
    var slots = []
    for i in range(1, SLOT_COUNT + 1):
        var data = load_from_slot(i)
        slots.append({
            "slot": i,
            "data": data,
            "exists": not data.is_empty()
        })
    return slots

# UI Example
func display_slot_menu():
    var slots = get_all_slots()
    for slot_info in slots:
        if slot_info["exists"]:
            print("Slot %d: %s (Level %d)" % [
                slot_info["slot"],
                slot_info["data"].get("player_name", "Unknown"),
                slot_info["data"].get("level", 0)
            ])
        else:
            print("Slot %d: Empty" % slot_info["slot"])
```

### Quick Save / Quick Load

```gdscript
func quick_save(data: Dictionary):
    $Save.save_data(data, "quicksave")

func quick_load() -> Dictionary:
    return $Save.edit_data("quicksave")

func has_quicksave() -> bool:
    return not $Save.list_profiles().has("quicksave.sav")
```

---

## Auto-Save

### Setup Auto-Save

```gdscript
extends Node

func _ready():
    # Configuration
    $Save.auto_save_interval = 30.0  # Every 30 seconds
    
    # Connect to be notified
    $Save.save_completed.connect(func(p): 
        print("Auto-saved at: ", Time.get_ticks_msec() / 1000.0)
    )

var playtime: float = 0

func _process(delta):
    playtime += delta
    
    # Update auto-save data
    var autosave_data = {
        "playtime": playtime,
        "last_checkpoint": get_current_checkpoint(),
        "health": get_player_health(),
        "position": get_player_position()
    }
    
    get_tree().root.set_meta("autosave_data", autosave_data)
```

### Manual Auto-Save on Events

```gdscript
func _ready():
    # Disable timer-based auto-save
    $Save.auto_save_interval = 0.0
    
    # Instead, save on important events
    player.level_up.connect(_on_level_up)
    player.died.connect(_on_player_died)

func _on_level_up(new_level: int):
    var data = {
        "level": new_level,
        "checkpoint": get_checkpoint()
    }
    $Save.save_data(data, "autosave")

func _on_player_died():
    var data = {
        "death_count": get_death_count(),
        "last_death_pos": player.global_position
    }
    $Save.save_data(data, "deaths_log")
```

---

## Settings Persistence

### Save Settings

```gdscript
extends Node

class Settings:
    var master_volume: float = 0.8
    var music_volume: float = 0.6
    var sfx_volume: float = 0.9
    var screen_resolution: Vector2i = Vector2i(1920, 1080)
    var fullscreen: bool = true
    var lang: String = "en"
    
    func to_dict() -> Dictionary:
        return {
            "master_volume": master_volume,
            "music_volume": music_volume,
            "sfx_volume": sfx_volume,
            "screen_resolution": [screen_resolution.x, screen_resolution.y],
            "fullscreen": fullscreen,
            "lang": lang
        }
    
    func from_dict(d: Dictionary):
        master_volume = d.get("master_volume", 0.8)
        music_volume = d.get("music_volume", 0.6)
        sfx_volume = d.get("sfx_volume", 0.9)
        
        var res = d.get("screen_resolution", [1920, 1080])
        screen_resolution = Vector2i(res[0], res[1])
        
        fullscreen = d.get("fullscreen", true)
        lang = d.get("lang", "en")

var settings = Settings.new()

func _ready():
    load_settings()
    apply_settings()

func load_settings():
    var data = $Save.edit_data("settings", ".cfg")
    if not data.is_empty():
        settings.from_dict(data)

func save_settings():
    $Save.save_data(settings.to_dict(), "settings", ".cfg")

func apply_settings():
    AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
    AudioServer.set_bus_volume_db(
        AudioServer.get_bus_index("Master"),
        linear2db(settings.master_volume)
    )
```

---

## Screenshot Capture

### Basic Screenshot

```gdscript
extends Node

func _input(event: InputEvent):
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_F12:
            $Save.snap_screenshot(get_viewport())

func _on_important_moment():
    # Capture with custom name
    $Save.snap_screenshot(get_viewport(), "victory")
```

### Screenshot with UI Hiding

```gdscript
var ui_layer: CanvasLayer

func take_clean_screenshot():
    # Hide UI temporarily
    ui_layer.visible = false
    await get_tree().process_frame  # Wait for rendering
    
    # Take screenshot
    $Save.snap_screenshot(get_viewport(), "clean")
    
    # Restore UI
    ui_layer.visible = true

func screenshot_with_text(text: String):
    var image = get_viewport().get_texture().get_image()
    var label = Label.new()
    label.text = text
    # Custom processing...
    
    # Use snap_screenshot for simple cases
    $Save.snap_screenshot(get_viewport(), text)
```

---

## Error Handling

### Defensive Load

```gdscript
func load_with_fallback(profile: String) -> Dictionary:
    var data = $Save.edit_data(profile)
    
    if data.is_empty():
        print("Save not found, using defaults")
        return get_default_data()
    
    # Validate required keys
    var required_keys = ["player_name", "level", "health"]
    for key in required_keys:
        if not data.has(key):
            print("Missing key: ", key)
            return get_default_data()
    
    return data

func get_default_data() -> Dictionary:
    return {
        "player_name": "New Hero",
        "level": 1,
        "health": 100,
        "position": Vector2.ZERO
    }
```

### Try-Catch for Serialization

```gdscript
func safe_save(data: Dictionary, profile: String):
    if typeof(data) != TYPE_DICTIONARY:
        push_error("Data must be Dictionary")
        return
    
    try:
        $Save.save_data(data, profile)
    except:
        push_error("Save failed")
```

### Handle Missing Files Gracefully

```gdscript
func load_or_create(profile: String) -> Dictionary:
    var existing = $Save.edit_data(profile)
    
    if existing.is_empty():
        # Create new with defaults
        var new_data = create_new_save()
        $Save.save_data(new_data, profile)
        return new_data
    
    return existing

func create_new_save() -> Dictionary:
    return {
        "player": "NewPlayer",
        "level": 1,
        "created_at": Time.get_datetime_string_from_system()
    }
```

---

## Game Manager Pattern

### Complete Game Manager

```gdscript
# GameManager.gd
extends Node

@onready var save = $Save

var current_game: Dictionary = {}
var current_profile: String = ""

func _ready():
    save.save_completed.connect(_on_save_completed)
    save.load_completed.connect(_on_load_completed)

func new_game(player_name: String):
    current_profile = "game_" + Time.get_datetime_string_from_system().replace(":", "-")
    current_game = {
        "player_name": player_name,
        "level": 1,
        "exp": 0,
        "health": 100,
        "max_health": 100,
        "inventory": [],
        "position": Vector2.ZERO,
        "playtime": 0.0,
        "created_at": Time.get_datetime_string_from_system()
    }
    
    save_game()

func load_game(profile: String):
    current_profile = profile
    current_game = save.edit_data(profile)

func save_game():
    if current_profile.is_empty():
        push_error("No active profile")
        return
    
    current_game["saved_at"] = Time.get_datetime_string_from_system()
    save.save_data(current_game, current_profile)

func quick_save():
    current_game["saved_at"] = Time.get_datetime_string_from_system()
    save.save_data(current_game, "quicksave")

func level_up():
    current_game["level"] += 1
    current_game["exp"] = 0
    current_game["max_health"] += 10
    save_game()

func gain_exp(amount: int):
    current_game["exp"] += amount
    
    var exp_for_level = current_game["level"] * 100
    if current_game["exp"] >= exp_for_level:
        level_up()
    else:
        save_game()

func take_damage(amount: int):
    current_game["health"] -= amount
    save_game()
    
    if current_game["health"] <= 0:
        game_over()

def game_over():
    save.delete_all_profiles()
    new_game(current_game["player_name"])

def get_save_list() -> Array:
    var profiles = save.list_profiles()
    var result = []
    
    for profile in profiles:
        var data = save.edit_data(profile)
        if not data.is_empty():
            result.append({
                "name": profile,
                "player": data.get("player_name", "Unknown"),
                "level": data.get("level", 0),
                "playtime": data.get("playtime", 0)
            })
    
    return result

func _on_save_completed(profile: String):
    print("✓ Game saved: ", profile)

func _on_load_completed(profile: String, data: Dictionary):
    if not data.is_empty():
        print("✓ Game loaded: ", profile)
```

### Usage

```gdscript
extends Node

func _ready():
    # New game
    GameManager.new_game("Hero")
    
    # Get save list for UI
    var saves = GameManager.get_save_list()
    for save_info in saves:
        print("%s - Level %d" % [save_info["player"], save_info["level"]])

func _process(delta):
    # Game loop
    if Input.is_action_just_pressed("save"):
        GameManager.save_game()
    
    if Input.is_action_just_pressed("quick_save"):
        GameManager.quick_save()

func on_player_gained_exp(amount: int):
    GameManager.gain_exp(amount)

func on_player_took_damage(amount: int):
    GameManager.take_damage(amount)
```

---

For advanced examples, see [ADVANCED_EXAMPLES.md](ADVANCED_EXAMPLES.md).
