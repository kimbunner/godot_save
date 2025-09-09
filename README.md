# 📦 Godot Save – Secure Save, Load, and Screenshot Plugin for Godot 4

![Godot](https://img.shields.io/badge/Godot-4.x-blue?style=for-the-badge)
![License](https://img.shields.io/github/license/yourusername/godot-save?style=for-the-badge)
![Status](https://img.shields.io/badge/status-stable-brightgreen?style=for-the-badge)

Godot Save is an easy-to-use addon for Godot 4 that combines **saving/loading, encryption, compression, backups, auto-save, and screenshot management** in one place.

Inspired by [PersistenceNode](https://github.com/MatiasVME/Persistence) and [Godot-Screenshot-Queue](https://github.com/fractilegames/godot-screenshot-queue), this addon brings their best features together with a modern Godot 4 implementation.

---

## ✨ Features

✅ **Save & Load** data in `.sav`, `.json`, or `.txt`  
✅ **AES-256 Encryption** (optional)  
✅ **ZIP Compression** (optional)  
✅ **Automatic Backups** with configurable limit  
✅ **Auto-Save** timer support  
✅ **Screenshot Queue** (non-blocking)  
✅ **Safe Writes** (temp + rename system to prevent corruption)  
✅ **Cloud Sync Support** (upload/download saves from your server)

---

## 🚀 Installation

1. Download or clone this repository.
2. Copy the `addons/godot-save/` folder into your project.
3. Enable the addon in **Project → Project Settings → Plugins**.

---

## 📖 Usage

### 💾 Saving Data
```gdscript
var data = {"prop":[{"val1": true}, {"val2": false}]}
$Save.save_data(data, "filename", ".json")
📖 Loading / Editing Data
gdscript
Copy code
var player_data = $Save.edit_data("player_data", ".json")
print(player_data)
🗑 Deleting Data
gdscript
Copy code
$Save.remove_data("player_data", ".json")
📸 Taking Screenshots
gdscript
Copy code
$Save.snap_screenshot(get_viewport(), "my_screenshot")
⚙️ Configuration (Inspector)
Setting	Type	Default	Description
use_encryption	bool	false	Encrypt save files with AES-256.
use_compression	bool	false	Compress save files using ZIP.
keep_backups	bool	true	Keep rotating .bak files.
backup_limit	int	3	Max number of backup versions to keep.
use_auto_save	bool	false	Automatically save after a set interval.
auto_save_interval	float	60.0	Interval in seconds for auto-save.
screenshot_max_count	int	10	Maximum screenshots to keep before rotating.
remote_save_url	String	""	(Optional) Server endpoint for cloud sync.

🛡 Encryption & Compression
Enable both in the Inspector for secure, compact saves:

gdscript
Copy code
const AES_KEY = "my_super_secret_key"
Key is hashed into a 32-byte key internally.

Compression uses ZipPacker/ZipReader to keep saves small.

Must be enabled both on save and load.

🌐 Cloud Sync Example
gdscript
Copy code
await $Save.upload_save("profile1")
await $Save.download_save("profile1")
This lets you back up or restore player data from a server endpoint.

🖼 Screenshots
Stored in user://screenshots/

Automatically rotates oldest screenshots if limit is reached

Uses background threads to avoid frame stutter

📜 License
MIT License – free to use, modify, and distribute.
See LICENSE for details.

🙌 Credits
Author: Purna Shrestha

Inspired by:

PersistenceNode

Godot-Screenshot-Queue