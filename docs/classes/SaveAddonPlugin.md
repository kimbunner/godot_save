# SaveAddonPlugin Class

**File**: `addons/GodotSavesAddon/save_addon_plugin.gd`  
**Extends**: `EditorPlugin`  
**Lines**: ~20  
**Status**: Stable

---

## Overview

`SaveAddonPlugin` is the entry point for the Godot Save Addon in the editor. It registers the Save custom node type and adds the SaveState file viewer dock to the editor UI.

This is a `@tool` script (runs in editor) that extends `EditorPlugin`.

---

## What It Does

### On Enable (\_enter_tree)

When the addon is enabled:

1. **Registers Save Custom Type**
   - Makes "Save" available in "Add Child Node" dialog
   - Assigns icon for visual identification
   - Allows using Save class directly in scenes

2. **Creates SaveViewerDock**
   - Instantiates SaveViewerDock UI
   - Names it "SaveStateViewer"
   - Adds to editor docks (left panel)

3. **Makes Addon Discoverable**
   - Editor recognizes Save as custom node
   - GDScript completion works for $Save
   - Saves reference for cleanup

### On Disable (\_exit_tree)

When the addon is disabled:

1. **Removes Custom Type**
   - "Save" no longer in node picker
   - Existing Save nodes still work in loaded scenes

2. **Removes Editor Dock**
   - SaveViewerDock removed from UI
   - Safely queued for deletion
   - Reference cleared

---

## Methods

### \_enter_tree() -> void

```gdscript
func _enter_tree() -> void
```

Called by Godot when plugin is enabled. Initialize plugin.

**Process:**
1. Call `add_custom_type()` to register Save
2. Instantiate SaveViewerDock
3. Add dock to editor with `add_control_to_dock()`

**Parameters:**
- None

**Called by**: Godot Engine when plugin enabled

**Code:**
```gdscript
func _enter_tree() -> void:
    add_custom_type(
        "Save",                                              # Node name
        "Node",                                              # Base class
        preload("res://addons/GodotSavesAddon/save_addon.gd"),  # Script
        preload("res://addons/GodotSavesAddon/plugin_icon.png") # Icon
    )
    _viewer = _ViewerScene.new()
    _viewer.name = "SaveStateViewer"
    add_control_to_dock(DOCK_SLOT_LEFT_UL, _viewer)
```

**What Happens:**
- `Save` custom node becomes available in scene editor
- Icon displays in node picker and scene tree
- SaveViewerDock appears at bottom-left of editor

---

### \_exit_tree() -> void

```gdscript
func _exit_tree() -> void
```

Called by Godot when plugin is disabled. Clean up.

**Process:**
1. Remove custom type from registry
2. Check if viewer dock still exists
3. Remove from editor docks
4. Queue viewer for deletion
5. Clear reference

**Parameters:**
- None

**Called by**: Godot Engine when plugin disabled

**Code:**
```gdscript
func _exit_tree() -> void:
    remove_custom_type("Save")
    if is_instance_valid(_viewer):
        remove_control_from_docks(_viewer)
        _viewer.queue_free()
        _viewer = null
```

**What Happens:**
- Save nodes removed from picker (existing scenes unaffected)
- SaveViewerDock hidden and deleted
- Addon cleanly unloaded

---

## Properties

### \_viewer

```gdscript
var _viewer: Control
```

Reference to SaveViewerDock instance.

- Type: `Control` (UI node)
- Created in `_enter_tree()`
- Deleted in `_exit_tree()`
- Used to manage dock lifecycle

---

### \_ViewerScene

```gdscript
const _ViewerScene := preload("res://addons/GodotSavesAddon/save_viewer_dock.gd")
```

Preloaded class reference for SaveViewerDock.

- Used to instantiate dock UI
- Preloaded for efficiency
- Path relative to addon folder

---

## Editor Integration

### How It Integrates with Godot

1. **Plugin.cfg Registration**
   - Godot reads `plugin.cfg` on startup
   - Finds `script="save_addon_plugin.gd"`
   - Loads and instantiates plugin

2. **EditorPlugin Callbacks**
   - `_enter_tree()` called on enable
   - `_exit_tree()` called on disable
   - `_handles()`, `_edit()`, etc. for custom editing (not used here)

3. **Custom Type System**
   - `add_custom_type()` registers new node type
   - Makes it appear in "Add Child Node" dialog
   - Assigns script and icon
   - Fully integrated with scene system

4. **Dock System**
   - `add_control_to_dock()` adds UI panel
   - `DOCK_SLOT_LEFT_UL` = bottom-left position
   - Persists across sessions
   - User can hide/show via View menu

---

## Configuration (plugin.cfg)

```ini
[plugin]
name="Godot Saves Addon"
description="Makes saving and loading files easier."
author="Kimbunner, Kcfresh53"
version="2.0"
script="save_addon_plugin.gd"
```

**Key Fields:**
- `script`: Path to plugin class (relative to plugin folder)
- `name`: Display name in plugins list
- `version`: Plugin version (informational)
- `description`: Help text in plugins list
- `author`: Credits

---

## Lifecycle Diagram

```
Godot Start
  ↓
Read plugin.cfg
  ↓
Plugin Enabled? (Project Settings → Plugins)
  ├─ Yes: Call _enter_tree()
  │  ├─ Register Save custom type
  │  ├─ Create SaveViewerDock
  │  └─ Add dock to editor
  │
  └─ No: Skip
      
Game Running
  ↓
Plugin Still Enabled?
  ├─ Yes: Continue
  └─ No: Call _exit_tree()
        ├─ Remove custom type
        ├─ Remove dock
        └─ Clean up

User Disables Plugin
  ↓
Call _exit_tree()
  ├─ Remove Save from picker
  ├─ Remove dock from UI
  └─ Fully unload addon
```

---

## Important Notes

### Why This Approach?

1. **Automatic Initialization**
   - Addon auto-registers on enable
   - No manual setup required
   - User just checks a checkbox

2. **Clean Separation**
   - Plugin manages editor UI
   - Save class manages game logic
   - SaveViewerDock provides inspection tool

3. **Safe Cleanup**
   - Properly removes custom types on disable
   - Prevents memory leaks
   - Allows re-enabling without issues

### Custom Type Arguments

```gdscript
add_custom_type(
    "Save",                                    # 1. Display name
    "Node",                                    # 2. Base class (what it extends)
    preload("res://addons/GodotSavesAddon/save_addon.gd"),  # 3. Script to use
    preload("res://addons/GodotSavesAddon/plugin_icon.png") # 4. Icon (optional)
)
```

- **Name**: Shows in "Add Child Node" dialog
- **Base**: Tells Godot it's a Node subclass
- **Script**: The class to instantiate (`save_addon.gd`)
- **Icon**: Visual identification in picker and scene tree

### Dock Slot Options

Available dock positions:
```gdscript
DOCK_SLOT_LEFT_UL    # Bottom-left (used here)
DOCK_SLOT_LEFT_BL    # Bottom-left
DOCK_SLOT_RIGHT_UL   # Bottom-right
DOCK_SLOT_RIGHT_BL   # Bottom-right
```

---

## Example: Custom Plugin Extension

If you wanted to extend the plugin:

```gdscript
# Save a reference to the plugin
extends EditorPlugin

var save_plugin: EditorPlugin

func _enter_tree():
    # Access the Save plugin
    save_plugin = get_editor_interface().get_editor_addons_manager().get_addon("SaveAddon")
    
    # Could add more custom features here
```

---

## Debugging

### Plugin Not Loading?

Check:
1. Is addon enabled in Project Settings → Plugins?
2. Does `plugin.cfg` exist?
3. Does `save_addon_plugin.gd` exist?
4. Are there syntax errors? Check Output panel

### Custom Type Not Appearing?

1. Reload project (File → Reload Project)
2. Restart Godot completely
3. Check plugin is enabled
4. Check Output for errors

### Dock Not Showing?

1. Check View → Show in Dock → SaveState file viewer
2. Plugin must be enabled
3. Try reloading project
4. Check Output for errors

---

For SaveViewerDock (the UI), see [SaveViewerDock.md](SaveViewerDock.md).
