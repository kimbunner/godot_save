# Advanced Examples

Advanced patterns and techniques for the Godot Save Addon.

## Table of Contents

1. [Custom Save Data Classes](#custom-save-data-classes)
2. [Save Data Migrations](#save-data-migrations)
3. [Async/Await Patterns](#asyncawait-patterns)
4. [Compression Benchmarks](#compression-benchmarks)
5. [Server Integration](#server-integration)
6. [Multi-User Scenarios](#multi-user-scenarios)
7. [Performance Optimization](#performance-optimization)

---

## Custom Save Data Classes

### Structured Save Data

```gdscript
# GameData.gd
class_name GameData
extends RefCounted

var player: PlayerData
var level: LevelData
var inventory: Array[ItemData]

func to_dict() -> Dictionary:
    return {
        "player": player.to_dict(),
        "level": level.to_dict(),
        "inventory": inventory.map(func(item): return item.to_dict())
    }

static func from_dict(data: Dictionary) -> GameData:
    var gd = GameData.new()
    gd.player = PlayerData.from_dict(data.get("player", {}))
    gd.level = LevelData.from_dict(data.get("level", {}))
    
    var inv_data = data.get("inventory", [])
    gd.inventory = []
    for item_data in inv_data:
        gd.inventory.append(ItemData.from_dict(item_data))
    
    return gd

class PlayerData:
    var name: String
    var level: int
    var exp: int
    var health: int
    var max_health: int
    
    func to_dict() -> Dictionary:
        return {
            "name": name,
            "level": level,
            "exp": exp,
            "health": health,
            "max_health": max_health
        }
    
    static func from_dict(d: Dictionary) -> PlayerData:
        var p = PlayerData.new()
        p.name = d.get("name", "Unknown")
        p.level = d.get("level", 1)
        p.exp = d.get("exp", 0)
        p.health = d.get("health", 100)
        p.max_health = d.get("max_health", 100)
        return p

# Similar for LevelData, ItemData...
```

### Usage

```gdscript
extends Node

@onready var save = $Save

var game_data: GameData

func save_game():
    game_data = GameData.new()
    # ... populate game_data from scene
    
    save.save_data(game_data.to_dict(), "autosave")

func load_game():
    var dict = save.edit_data("autosave")
    game_data = GameData.from_dict(dict)
```

---

## Save Data Migrations

### Version-Based Migration

```gdscript
# SaveData.gd
class_name SaveData
extends Save

const CURRENT_VERSION = 3

func migrate_save_data(data: Dictionary, from_version: int) -> Dictionary:
    var d = data.duplicate(true)
    
    # v1 → v2: Rename fields
    if from_version < 2:
        if d.has("mana_points"):
            d["mana"] = d["mana_points"]
            d.erase("mana_points")
        
        if d.has("max_mp"):
            d["max_mana"] = d["max_mp"]
            d.erase("max_mp")
    
    # v2 → v3: Restructure inventory
    if from_version < 3:
        var old_inv = d.get("inventory", [])
        d["inventory"] = {
            "items": old_inv,
            "capacity": 20,
            "weight": calculate_weight(old_inv)
        }
    
    return d

func calculate_weight(items: Array) -> float:
    var weight = 0.0
    for item in items:
        weight += item.get("weight", 0.5)
    return weight
```

### Complex Migration with Defaults

```gdscript
func _ready():
    super._ready()
    
    # Define new required fields
    default_values_for_new_keys = {
        "version_info": {
            "game_version": "1.2",
            "last_updated": Time.get_datetime_string_from_system()
        },
        "settings": {
            "difficulty": "normal",
            "language": "en"
        },
        "features": {
            "tutorial_completed": false,
            "dlc_unlocked": []
        }
    }

func migrate_save_data(data: Dictionary, from_version: int) -> Dictionary:
    var d = data.duplicate(true)
    
    # Call super to apply default_values_for_new_keys
    d = super.migrate_save_data(d, from_version)
    
    # Custom migration logic
    if from_version == 1:
        d["old_format"] = true
    
    return d
```

---

## Async/Await Patterns

### Wait for Save Completion

```gdscript
func save_and_wait(data: Dictionary, profile: String) -> bool:
    var saved = false
    var failed = false
    
    $Save.save_completed.connect(func(p): 
        if p == profile:
            saved = true
    )
    $Save.save_failed.connect(func(p, reason):
        if p == profile:
            failed = true
            print("Save failed: ", reason)
    )
    
    $Save.save_data(data, profile)
    
    while not saved and not failed:
        await get_tree().process_frame
    
    return saved
```

### Async Save Wrapper

```gdscript
func save_async(data: Dictionary, profile: String) -> Signal:
    var signal = Signal(Object.new())
    
    var callback = func(p):
        if p == profile:
            signal.emit(true)
    
    $Save.save_completed.connect(callback)
    $Save.save_data(data, profile, async_save: true)
    
    return signal

# Usage
var result = await save_async(data, "profile")
print("Saved: ", result)
```

### Load with Timeout

```gdscript
func load_with_timeout(profile: String, timeout_sec: float = 5.0) -> Dictionary:
    var loaded = {}
    var timeout = false
    
    var timer = get_tree().create_timer(timeout_sec)
    timer.timeout.connect(func(): timeout = true)
    
    $Save.load_completed.connect(func(p, data):
        if p == profile and not timeout:
            loaded = data
    )
    
    $Save.edit_data(profile)
    
    while loaded.is_empty() and not timeout:
        await get_tree().process_frame
    
    return loaded if not timeout else {}
```

---

## Compression Benchmarks

### Test Compression Effectiveness

```gdscript
func test_compression():
    var test_data = {
        "large_array": range(1000).map(func(i): return {"id": i, "data": "x" * 100}),
        "strings": ["test"] * 500
    }
    
    # Uncompressed
    var uncompressed = SaveCodec.serialize_dict(test_data, "json")
    print("Uncompressed: %d bytes" % uncompressed.size())
    
    # Compressed
    var compressed = SaveCodec.compress_zip_single(uncompressed)
    print("Compressed: %d bytes" % compressed.size())
    
    var ratio = 100.0 - (compressed.size() / float(uncompressed.size()) * 100.0)
    print("Compression ratio: %.1f%%" % ratio)
```

### Profile Different Formats

```gdscript
func profile_formats(data: Dictionary):
    var results = {}
    
    for fmt in ["json", "txt", "bin"]:
        var bytes = SaveCodec.serialize_dict(data, fmt)
        results[fmt] = {
            "size": bytes.size(),
            "format": fmt
        }
    
    # JSON is typically 2-3x larger than BIN
    for fmt in results:
        print("%s: %d bytes" % [fmt, results[fmt]["size"]])
```

---

## Server Integration

### Cloud Save Sync

```gdscript
class_name CloudSaveManager
extends Node

var api_url: String = "https://api.game.com"
var user_token: String = ""

func upload_save(profile: String):
    var file = FileAccess.open("user://save/" + profile + ".sav", FileAccess.READ)
    var file_bytes = file.get_buffer(file.get_length())
    file.close()
    
    var http = HTTPRequest.new()
    add_child(http)
    
    var headers = [
        "Authorization: Bearer " + user_token,
        "Content-Type: application/octet-stream"
    ]
    
    var url = api_url + "/saves/" + profile
    
    http.request_raw(url, PackedStringArray(headers), HTTPClient.METHOD_POST, file_bytes)
    
    var response = await http.request_completed
    return response[1] == 200

func download_save(profile: String) -> bool:
    var http = HTTPRequest.new()
    add_child(http)
    
    var headers = ["Authorization: Bearer " + user_token]
    var url = api_url + "/saves/" + profile
    
    http.request(url, PackedStringArray(headers), HTTPClient.METHOD_GET)
    
    var response = await http.request_completed
    
    if response[1] != 200:
        return false
    
    var bytes = response[3]
    var path = "user://save/" + profile + ".sav"
    
    var f = FileAccess.open(path, FileAccess.WRITE)
    f.store_buffer(bytes)
    f.close()
    
    return true

func sync_to_cloud(profile: String) -> bool:
    # Upload to cloud
    if not await upload_save(profile):
        return false
    
    # Update sync timestamp
    var data = $Save.edit_data(profile)
    data["_sync_time"] = Time.get_ticks_msec()
    $Save.save_data(data, profile)
    
    return true
```

### Server-Side Validation

```gdscript
# Example server endpoint (pseudocode)
@app.route('/api/saves/<profile>', methods=['POST'])
def save_game(profile):
    # Verify user token
    user = verify_token(request.headers['Authorization'])
    if not user:
        return {'error': 'Unauthorized'}, 401
    
    # Validate save data
    data = load_save(request.data)
    
    # Check for impossible stats
    if data['player']['level'] > 9999:
        return {'error': 'Invalid level'}, 400
    
    if data['player']['exp'] > MAX_EXP:
        return {'error': 'Invalid exp'}, 400
    
    # Store save
    store_save(user.id, profile, data)
    
    # Return checksum for integrity
    checksum = compute_checksum(request.data)
    return {'checksum': checksum, 'stored': True}
```

---

## Multi-User Scenarios

### Per-User Save Profiles

```gdscript
class_name MultiUserSaveManager
extends Node

@onready var save = $Save

var current_user_id: String = ""

func _ready():
    # Create user-specific folder
    var user_folder = "saves/user_%s" % current_user_id
    save.folder_name = user_folder

func save_for_user(user_id: String, data: Dictionary, profile: String):
    current_user_id = user_id
    save.folder_name = "saves/user_%s" % user_id
    save.save_data(data, profile)

func load_for_user(user_id: String, profile: String) -> Dictionary:
    current_user_id = user_id
    save.folder_name = "saves/user_%s" % user_id
    return save.edit_data(profile)

func list_user_saves(user_id: String) -> Array:
    save.folder_name = "saves/user_%s" % user_id
    return save.list_profiles()
```

### Shared Settings

```gdscript
# Global settings vs per-user settings
func save_shared_settings(data: Dictionary):
    # Save to shared location
    var original_folder = $Save.folder_name
    $Save.folder_name = "shared_settings"
    $Save.save_data(data, "game_settings")
    $Save.folder_name = original_folder

func load_shared_settings() -> Dictionary:
    var original_folder = $Save.folder_name
    $Save.folder_name = "shared_settings"
    var data = $Save.edit_data("game_settings")
    $Save.folder_name = original_folder
    return data
```

---

## Performance Optimization

### Lazy Loading

```gdscript
class GameData:
    var player_data: Dictionary
    var level_data: Dictionary
    var world_state: Dictionary
    
    var _loaded_sections: Dictionary = {}
    
    func load_section(name: String) -> Dictionary:
        if _loaded_sections.has(name):
            return _loaded_sections[name]
        
        match name:
            "player":
                _loaded_sections["player"] = player_data
                return player_data
            "level":
                _loaded_sections["level"] = level_data
                return level_data
            # ...
        
        return {}
    
    func unload_section(name: String):
        _loaded_sections.erase(name)
```

### Streaming Saves

```gdscript
# Save in chunks for large data
func save_large_data(data: Dictionary, profile: String):
    # Split into chunks
    var chunks = {}
    
    var chunk_size = 1000
    var player_chunk = data.get("players", []).slice(0, chunk_size)
    chunks["players_part1"] = player_chunk
    
    for name in chunks:
        $Save.save_data({"data": chunks[name]}, profile + "_" + name)

func load_large_data(profile: String) -> Dictionary:
    var result = {}
    var players = []
    
    var part1 = $Save.edit_data(profile + "_players_part1")
    players.append_array(part1.get("data", []))
    
    result["players"] = players
    return result
```

### Batch Saves

```gdscript
# Save multiple profiles efficiently
func batch_save(saves: Dictionary):
    for profile in saves:
        $Save.save_data(saves[profile], profile, async_save: true)
    
    # Wait for all to complete
    var count = 0
    var target = saves.size()
    
    $Save.save_completed.connect(func(p):
        if saves.has(p):
            count += 1
    )
    
    while count < target:
        await get_tree().process_frame
```

---

For basic examples, see [BASIC_EXAMPLES.md](BASIC_EXAMPLES.md).
