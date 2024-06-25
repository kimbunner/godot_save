# Godot Save - A simple save, load and screenshot plugin for Godot 4  
Godot Save is an easy to use addon created to make saving and loading files easier in Godot 4.

### Contributor <a href="https://github.com/kcfresh53" target="_blank">Purna Shrestha</a>

Inspired by [PersistenceNode](https://github.com/MatiasVME/Persistence) by MatiasVME and [Godot-Screenshot-Queue](https://github.com/fractilegames/godot-screenshot-queue) by fractilegames,
this addon is designed to bring elements of both systems into one while porting the functionality to Godot 4.

# Usage
## Saving
### save_data(data: Dictionary, profile: String = "save", filetype: String = ".sav") -> void

```gdscript
var data = {"prop":[{"val1": true}, {"val2": false}]}
$Save.save_data(data,"filename",".json")
```
## Loading / Editing
### edit_data(profile: String = "save", filetype: String = ".sav") -> Dictionary

```gdscript
var player_data = $Save.edit_data("player_data",".json")
```
## Deleting save data
### remove_data(profile: String = "save", filetype: String = ".sav") -> void

```gdscript
$Save.remove_data("player_data",".json")
```
## Taking Screenshots
### snap_screenshot(viewport: Viewport) -> void

```gdscript
$Save.snap_screenshots(get_viewport())
```

