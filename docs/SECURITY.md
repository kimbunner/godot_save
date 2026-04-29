# Security Best Practices

Guide to securing your game data with the Godot Save Addon.

## Table of Contents

1. [Encryption Overview](#encryption-overview)
2. [Key Management](#key-management)
3. [Checksum Verification](#checksum-verification)
4. [Safe File Operations](#safe-file-operations)
5. [Cloud Security](#cloud-security)
6. [Platform-Specific Security](#platform-specific-security)
7. [Common Vulnerabilities](#common-vulnerabilities)
8. [Security Checklist](#security-checklist)

---

## Encryption Overview

### When to Use Encryption

**Enable encryption if:**
- Game has online multiplayer
- Storing sensitive player data (passwords, tokens)
- Implementing anti-cheat system
- Game is competitive (prevent save game hacks)

**Skip encryption for:**
- Single-player offline games
- Non-competitive games
- Development/testing (performance)

### AES-256-CBC Details

The addon uses AES-256 in CBC mode:

- **Algorithm**: AES-256-CBC (industry standard)
- **Key Size**: 256 bits (32 bytes)
- **IV**: Derived from key via SHA-256 (deterministic)
- **Padding**: PKCS7 (reversible, standard)
- **Strength**: Military-grade encryption

### Key Derivation

```
User Key (e.g., "my_secret_123")
  ↓
UTF-8 Encode
  ↓
SHA-256 Hash
  ↓
256-bit Key (32 bytes) + IV derivation
```

This is deterministic - same key always produces same ciphertext.

---

## Key Management

### Storing the Encryption Key

**⚠️ CRITICAL**: Never hardcode keys in source code!

**Bad - Don't Do This**:
```gdscript
# Bad! Key is visible in source code
$Save.AES_KEY = "hardcoded_secret_key".to_utf8_buffer()
```

**Better Options**:

1. **Environment Variable**:
```gdscript
var key_string = OS.get_environment("GAME_SAVE_KEY")
if key_string.is_empty():
    key_string = "fallback_dev_key"  # Dev only
$Save.AES_KEY = key_string.to_utf8_buffer()
```

2. **Configuration File** (non-repo):
```gdscript
# secrets/save_key.txt (add to .gitignore)
func load_key_from_file():
    var file = FileAccess.open("secrets/save_key.txt", FileAccess.READ)
    var key = file.get_as_text().strip_edges()
    $Save.AES_KEY = key.to_utf8_buffer()
```

3. **Derived from System ID**:
```gdscript
# Deterministic but not hardcoded
var device_id = OS.get_unique_id()
var base_key = "game_name_" + device_id
var key = SaveCodec.sha256_bytes(base_key.to_utf8_buffer())
$Save.AES_KEY = key
```

4. **Server-Provided Key** (online games):
```gdscript
# Request key from your authentication server
var response = await auth_server.get_save_key(user_id)
$Save.AES_KEY = response.save_key.to_utf8_buffer()
```

### Key Rotation

If you need to change keys (compromise suspected):

```gdscript
func rotate_save_keys(old_key: String, new_key: String):
    var profiles = $Save.list_profiles()
    
    for profile in profiles:
        # Load with old key
        $Save.AES_KEY = old_key.to_utf8_buffer()
        var data = $Save.edit_data(profile)
        
        if data.is_empty():
            continue
        
        # Save with new key
        $Save.AES_KEY = new_key.to_utf8_buffer()
        $Save.save_data(data, profile)
    
    print("Key rotation complete")
```

---

## Checksum Verification

### What Checksums Protect

Checksums detect:
- Manual file edits (stat hacks, value manipulation)
- File corruption
- Incomplete saves

Checksums **don't** protect against:
- Encryption bypass (encryption does)
- Cheating at data level (needs server validation)
- Lost data (backups do)

### Enable Checksums

```gdscript
@onready var save = $Save

func _ready():
    # Always enabled by default
    save.use_integrity_checksum = true
    
    # Fail if checksum fails (recommended)
    save.strict_integrity = true
```

### Verify in Code

```gdscript
func verify_save_integrity(profile: String) -> bool:
    var file_path = "user://save/" + profile + ".sav"
    
    if not FileAccess.file_exists(file_path):
        return false
    
    var f = FileAccess.open(file_path, FileAccess.READ)
    var bytes = f.get_buffer(f.get_length())
    f.close()
    
    # Attempt to decode with checksum verification
    var result = SaveCodec.decode_buffer(
        bytes,
        "json",
        false,  # compression
        false,  # encryption
        PackedByteArray(),
        true,   # verify_checksum
        false   # fail on mismatch
    )
    
    return result[0]  # True if checksum valid
```

---

## Safe File Operations

### Atomic Writes

The addon uses atomic writes internally:

```
1. Write to temp file (.tmp)
2. Close file
3. Delete original if exists
4. Rename temp to original
```

This prevents corruption if crash occurs during write.

**Never** do:
```gdscript
# Bad - not atomic
file.store_buffer(data)  # Direct write
```

**Good** - addon does this:
```gdscript
func _safe_write(path: String, bytes: PackedByteArray) -> bool:
    var temp_path := path + ".tmp"
    var f := FileAccess.open(temp_path, FileAccess.WRITE)
    if f == null:
        return false
    f.store_buffer(bytes)
    f.close()
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(path)
    DirAccess.rename_absolute(temp_path, path)
    return true
```

### Backup Strategy

Enable backups for critical data:

```gdscript
func setup_secure_saves():
    $Save.keep_backups = true
    $Save.backup_limit = 5  # Keep 5 versions
```

Files created:
- `game.sav` - Current
- `game.sav.bak1` - Most recent
- `game.sav.bak2` - Previous
- ... up to `bak5`

Recovery:
```gdscript
func restore_from_backup(profile: String, backup_num: int = 1):
    var original = "user://save/" + profile + ".sav"
    var backup = original + ".bak" + str(backup_num)
    
    if FileAccess.file_exists(backup):
        DirAccess.copy_absolute(backup, original)
        print("Restored from backup %d" % backup_num)
```

---

## Cloud Security

### Secure Upload

```gdscript
func upload_save_securely(profile: String, session_token: String):
    var file_path = "user://save/" + profile + ".sav"
    
    var f = FileAccess.open(file_path, FileAccess.READ)
    var file_bytes = f.get_buffer(f.get_length())
    f.close()
    
    var http = HTTPRequest.new()
    add_child(http)
    
    var headers = [
        "Authorization: Bearer " + session_token,
        "Content-Type: application/octet-stream"
    ]
    
    http.request_raw(
        $Save.remote_save_url,
        PackedStringArray(headers),
        HTTPClient.METHOD_POST,
        file_bytes
    )
```

### Validate Downloads

```gdscript
func download_and_verify(profile: String) -> bool:
    var http = HTTPRequest.new()
    add_child(http)
    
    var response = await http.request_completed
    
    if response[1] != 200:
        print("Download failed: code", response[1])
        return false
    
    # Verify checksum from server
    var downloaded_bytes = response[3]
    var expected_checksum = get_server_checksum(profile)
    
    var actual_checksum = SaveCodec.sha256_hex(downloaded_bytes)
    
    if actual_checksum != expected_checksum:
        print("Checksum mismatch - file tampered!")
        return false
    
    # Write if valid
    return $Save._safe_write("user://save/" + profile + ".sav", downloaded_bytes)
```

### Rate Limiting

Prevent upload spam/attacks:

```gdscript
var last_upload_time = 0.0

func upload_with_ratelimit(profile: String) -> bool:
    var now = Time.get_ticks_msec() / 1000.0
    
    if now - last_upload_time < 5.0:  # Min 5 seconds between uploads
        print("Upload too frequent")
        return false
    
    last_upload_time = now
    $Save.upload_save(profile)
    return true
```

---

## Platform-Specific Security

### Desktop (Windows/macOS/Linux)

✅ **Good**:
- User folder is per-user
- Data not shared between users
- Encryption can prevent casual cheating

⚠️ **Risks**:
- Local admin can bypass anything
- Sophisticated hackers can modify encrypted saves
- Solution: Server-side validation

### Mobile (Android/iOS)

✅ **Good**:
- Sandboxed app folder
- OS-level encryption (Android 6+, iOS)
- Difficult to access without device unlock

⚠️ **Risks**:
- Rooted/jailbroken devices bypass OS security
- Developers can read app storage
- Solution: Add server-side verification

### Web (HTML5)

⚠️ **High Risk** - Avoid for sensitive data:
- Browser LocalStorage is not secure
- Browser history can contain data
- No encryption support
- Solution: Use server for critical data only

---

## Common Vulnerabilities

### Vulnerability 1: Stat Hacking

**Problem**: Player modifies save file (edit level from 1 to 99)

**Prevention**:
1. Enable checksums (detect edits)
2. Enable encryption (prevent reading)
3. Server-side validation (authoritative)

```gdscript
# Server-side validation
if not validate_player_level(player_id, claimed_level):
    print("Stat hack detected!")
    reject_save()
```

### Vulnerability 2: Save Swapping

**Problem**: Player swaps save files from different games

**Prevention**:
1. Store account ID in save
2. Verify account ID on load
3. Server-side validation

```gdscript
func save_securely(data: Dictionary):
    data["_account_id"] = get_user_id()
    data["_device_id"] = OS.get_unique_id()
    $Save.save_data(data, "secure_save")

func load_securely() -> Dictionary:
    var data = $Save.edit_data("secure_save")
    
    # Verify metadata
    if data.get("_account_id") != get_user_id():
        print("Save swap detected!")
        return {}
    
    return data
```

### Vulnerability 3: Decryption Key Theft

**Problem**: Key is hardcoded and extracted from binary

**Prevention**:
1. Don't hardcode keys
2. Use server-provided keys
3. Use device-specific keys
4. Implement anti-tampering

```gdscript
# Server-provided key (better)
var save_key = await fetch_key_from_server(user_token)
$Save.AES_KEY = save_key.to_utf8_buffer()
```

### Vulnerability 4: Checksum Bypass

**Problem**: Attacker recalculates checksum after editing

**Prevention**:
1. Use encryption (prevents read/edit)
2. Server-side validation (authoritative)
3. Time-based checks (timestamp aging)

```gdscript
# Check save isn't too old
if not data.has("_timestamp"):
    print("Old save format")
    return

var save_age = Time.get_ticks_msec() - int(data["_timestamp"])
if save_age > 30 * 24 * 60 * 60 * 1000:  # 30 days
    print("Save too old")
    return
```

---

## Security Checklist

### Before Shipping

- [ ] **Encryption**: Enable if online/competitive
- [ ] **Key Management**: Key not hardcoded
- [ ] **Checksums**: Enabled by default
- [ ] **Backups**: Enabled (keep_backups = true)
- [ ] **Server Validation**: For competitive games
- [ ] **HTTPS**: For cloud saves
- [ ] **Rate Limiting**: For upload/download
- [ ] **Audit Logging**: Log save operations
- [ ] **Testing**: Test on target platform
- [ ] **Documentation**: Save format documented

### For Competitive Games

- [ ] Server-side save validation
- [ ] Encrypted network transmission (HTTPS)
- [ ] Rate limiting on uploads
- [ ] Anomaly detection (impossible stats)
- [ ] Regular backups on server
- [ ] Account validation checks
- [ ] Integrity verification

### For Offline Games

- [ ] Encryption enabled (optional)
- [ ] Checksums enabled (default)
- [ ] Backups enabled
- [ ] Data validation on load
- [ ] Error recovery strategy

---

## Summary

| Threat | Encryption | Checksums | Server Validation | Backups |
|--------|:----------:|:---------:|:-----------------:|:-------:|
| Corruption | ✓ | ✓ | ✓ | ✓ |
| Stat hacking | ✓ | ✓ | ✓ | - |
| Save swapping | - | ✓ | ✓ | - |
| File deletion | - | - | - | ✓ |
| Tampering | ✓ | ✓ | ✓ | - |

**Minimum**: Checksums + Backups  
**Recommended**: Encryption + Checksums + Backups  
**High-Security**: All above + Server Validation

---

For key management details, see [API.md](API.md).
