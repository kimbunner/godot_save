# Installation Guide

Complete step-by-step instructions for installing the Godot Save Addon.

## System Requirements

- **Godot Engine**: 4.0 or later
- **Platform**: Windows, macOS, Linux
- **Storage**: ~2 MB for addon files
- **Runtime**: GDScript compatible

## Installation Steps

### Method 1: Manual Installation (Recommended)

#### Step 1: Copy the Addon Files

1. Locate your Godot project folder
2. Create an `addons` folder if it doesn't exist:
   ```
   your_project/
   └── addons/
   ```

3. Copy the entire `GodotSavesAddon` folder:
   ```
   your_project/
   └── addons/
       └── GodotSavesAddon/
           ├── save_addon.gd
           ├── save_codec.gd
           ├── save_addon_plugin.gd
           ├── save_viewer_dock.gd
           ├── plugin.cfg
           └── ... (other files)
   ```

#### Step 2: Enable the Addon in Godot Editor

1. **Open your project in Godot 4.x**

2. **Go to Project Menu**:
   - Click `Project` → `Project Settings`

3. **Navigate to Plugins Tab**:
   - Click the `Plugins` tab at the top

4. **Search for the Addon**:
   - In the search box, type "Godot Saves" or "Save"
   - You should see "Godot Saves Addon"

5. **Enable It**:
   - Click the checkbox next to "Godot Saves Addon"
   - Status should change to "Enabled" (green checkmark)

6. **Restart Editor** (recommended):
   - Close and reopen Godot for full plugin initialization

### Method 2: Using GitHub/Asset Store

If obtained from GitHub:

```bash
# Clone or download
git clone https://github.com/kimbunner/godot_save.git

# Copy addon to your project
cp -r godot_save/addons/GodotSavesAddon /path/to/your/project/addons/
```

## Verification

### Check Installation

After enabling, verify the addon is working:

1. **Scene Editor**: Right-click in scene tree → "Add Child Node"
2. Search for **"Save"**
3. You should see a "Save" node option available
4. Click to add it

This confirms the addon is properly installed.

### Check Editor Dock

1. Look at the bottom of the Godot Editor
2. You should see a new dock titled **"SaveState file viewer"**
3. This is the editor tool for inspecting save files

If you don't see it:
- Go to `View` → `Show in Dock` → Look for "SaveState file viewer"

## Project Structure After Installation

```
your_project/
├── addons/
│   └── GodotSavesAddon/
│       ├── save_addon.gd              (Main class, ~450 lines)
│       ├── save_codec.gd              (Codec utility, ~350 lines)
│       ├── save_addon_plugin.gd       (Editor plugin, ~20 lines)
│       ├── save_viewer_dock.gd        (Editor UI, ~200 lines)
│       ├── plugin.cfg                 (Metadata)
│       ├── plugin_icon.png            (Editor icon)
│       ├── icon.png                   (Node icon)
│       ├── plugin_icon.png.import
│       ├── icon.png.import
│       ├── save_addon.gd.uid
│       ├── save_codec.gd.uid
│       ├── save_addon_plugin.gd.uid
│       └── save_viewer_dock.gd.uid
├── scenes/
│   └── main.tscn (your scenes)
├── project.godot
└── ... (your other folders)
```

## Configuration (First Time)

### 1. Add Save Node to Main Scene

```gdscript
# In your main scene's script:
extends Node

func _ready():
    # Save node should be added to the scene
    # via the Scene editor (not in code)
    pass
```

**Or add via Scene Editor:**
1. Open your main scene
2. Right-click the root node
3. "Add Child Node"
4. Search "Save"
5. Click to add

### 2. Configure in Inspector

Select the Save node and configure in the Inspector panel:

| Property | Default | Recommended |
|----------|---------|-------------|
| folder_name | "save" | Keep default |
| file_format | "json" | "json" for readability |
| save_name | "" | "autosave" for auto-load |
| use_encryption | false | true for released games |
| use_compression | false | true for large saves |
| keep_backups | true | Keep true |
| backup_limit | 3 | 3-5 backups |
| auto_save_interval | 0.0 | 30-60 for timed saves |
| print_in_terminal | true | false in production |

### 3. Create a Save Manager Script

```gdscript
# SaveManager.gd
extends Node

@onready var save = $Save

func _ready():
    save.save_completed.connect(_on_save_completed)
    save.load_completed.connect(_on_load_completed)

func save_game(data: Dictionary):
    save.save_data(data, "autosave")

func load_game() -> Dictionary:
    return save.edit_data("autosave")

func _on_save_completed(profile: String):
    print("✓ Game saved: ", profile)

func _on_load_completed(profile: String, data: Dictionary):
    print("✓ Game loaded: ", profile)
```

## Troubleshooting Installation

### Issue: Addon Not Appearing in Scene

**Cause**: Addon not enabled or syntax error in plugin files

**Solution**:
1. Check Project → Project Settings → Plugins
2. Verify "Godot Saves Addon" is enabled (green checkmark)
3. Check Output panel for errors
4. Restart Godot completely

### Issue: Save Node Not Found

**Cause**: Plugin initialization incomplete

**Solution**:
1. Reload the project (File → Reload Project)
2. Or close and reopen Godot
3. Verify addon is in `addons/GodotSavesAddon/` folder

### Issue: Editor Dock Not Visible

**Cause**: Dock not shown or layout issue

**Solution**:
1. Go to `View` menu
2. Look for `Show in Dock` option
3. Select "SaveState file viewer"
4. If not there, reload project

### Issue: GDScript Errors

**Cause**: Missing .uid files or file import issues

**Solution**:
1. Click `File → Reload Current Scene`
2. Or `File → Reload Project`
3. Wait for Godot to re-import addon files
4. Check Output tab for specific errors

### Issue: "Cannot open module" Error

**Cause**: Plugin path incorrect in plugin.cfg

**Solution**:
1. Open `addons/GodotSavesAddon/plugin.cfg`
2. Verify `script="save_addon_plugin.gd"` is correct
3. Check file path spelling
4. Reload project

## Platform-Specific Notes

### Windows
- File paths use backslashes
- Addon location: `C:\Users\YourUser\AppData\Roaming\Godot\...` (user data)
- Project addons: `your_project\addons\GodotSavesAddon\`

### macOS
- User folder: `/Users/YourUser/.godot/`
- Use forward slashes in paths
- May need to allow app permissions for file access

### Linux
- User folder: `/home/username/.godot/`
- Use forward slashes in paths
- Check folder permissions (chmod +x)

## Post-Installation

### 1. Test the Installation

Create a simple test scene:

```gdscript
extends Node

func _ready():
    # Test save
    $Save.save_data({"test": true}, "test_profile")
    
    # Test load
    var data = $Save.edit_data("test_profile")
    print("Test result: ", data)
```

### 2. Review Documentation

- Read [QUICK_START.md](QUICK_START.md) for basic usage
- Review [CONFIGURATION.md](CONFIGURATION.md) for all options
- Check [examples/](examples/) for common patterns

### 3. Understand File Locations

By default, saves are stored in:

**Development**:
- Windows: `user://save/` → `AppData/Roaming/Godot/app_userdata/ProjectName/save/`
- macOS: `user://save/` → `~/.godot/app_userdata/ProjectName/save/`
- Linux: `user://save/` → `~/.godot/app_userdata/ProjectName/save/`

**Exported Game**:
- Windows: Next to .exe in `save/` folder
- macOS: Inside .app bundle
- Linux: Next to executable in `save/` folder

### 4. Configure for Production

Before shipping your game:

1. **Security**:
   - Enable encryption if storing sensitive data
   - Review [Security.md](SECURITY.md)

2. **Performance**:
   - Disable `print_in_terminal` for production
   - Test with large saves

3. **User Experience**:
   - Set appropriate `auto_save_interval`
   - Configure `backup_limit` appropriately
   - Test save/load flow with real game

4. **Testing**:
   - Test save/load with various data sizes
   - Test encryption/decryption
   - Test on target platforms
   - Verify save files are created in correct location

## Uninstallation

To remove the addon:

1. **Disable in Editor**:
   - Project → Project Settings → Plugins
   - Uncheck "Godot Saves Addon"

2. **Delete Addon Folder**:
   ```
   rm -r addons/GodotSavesAddon/
   ```

3. **Remove from Scripts**:
   - Update any scripts that reference the Save class
   - Remove Save nodes from scenes

4. **Reload Project**:
   - Close and reopen Godot

## Updating the Addon

To update to a newer version:

1. **Backup current version**:
   ```
   cp -r addons/GodotSavesAddon addons/GodotSavesAddon.backup
   ```

2. **Replace addon files**:
   - Delete old `addons/GodotSavesAddon/`
   - Copy new version

3. **Reload project**:
   - Close and reopen Godot

4. **Check changelog** for breaking changes

## Support

If installation fails:

1. Check the [Troubleshooting](TROUBLESHOOTING.md) guide
2. Verify Godot version is 4.0+
3. Check Output panel for error messages
4. Review file paths and folder structure
5. Try a fresh Godot project with just the addon

---

**Next Steps**: See [QUICK_START.md](QUICK_START.md) to start using the addon.
