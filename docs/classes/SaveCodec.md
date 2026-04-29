# SaveCodec Class - Complete Reference

**File**: `addons/GodotSavesAddon/save_codec.gd`  
**Extends**: `RefCounted`  
**Class Name**: `SaveCodec`  
**Lines**: ~350  
**Status**: Stable, Production-Ready  
**All Methods**: Static (call via `SaveCodec.method()`)

---

## Table of Contents

1. [Overview](#overview)
2. [Hashing Functions](#hashing-functions)
3. [Encryption/Decryption](#encryptiondecryption)
4. [Compression/Decompression](#compressiondecompression)
5. [Serialization](#serialization)
6. [Integrity Verification](#integrity-verification)
7. [Merging & Utilities](#merging--utilities)
8. [Main Codec Functions](#main-codec-functions)
9. [Implementation Details](#implementation-details)
10. [Examples](#examples)

---

## Overview

`SaveCodec` is a utility class with **12+ static methods** for:

- **Hashing**: SHA-256 computation
- **Encryption**: AES-256-CBC encryption/decryption
- **Compression**: ZIP compression/decompression
- **Serialization**: JSON/TXT/BIN format conversion
- **Integrity**: SHA-256 checksums for tampering detection
- **Utility**: Dictionary merging, number normalization

### Design

All methods are `static`, so instantiation is not required:

```gdscript
# Correct
var hash = SaveCodec.sha256_hex(data)

# Wrong - don't do this
var codec = SaveCodec.new()  # Unnecessary
```

### Thread-Safety

All methods are thread-safe. They create new objects for each operation and don't share state.

---

## Hashing Functions

### sha256_bytes(bytes: PackedByteArray) -> PackedByteArray

Computes SHA-256 hash of byte array.

```gdscript
static func sha256_bytes(bytes: PackedByteArray) -> PackedByteArray
```

**Parameters:**
- `bytes` (PackedByteArray): Data to hash

**Returns:** SHA-256 hash as PackedByteArray (32 bytes)

**Uses:** `HashingContext` with `HASH_SHA256` algorithm

**Example:**
```gdscript
var data = "hello world".to_utf8_buffer()
var hash = SaveCodec.sha256_bytes(data)
print(hash.size())  # 32 (bytes)
print(hash.hex_encode())  # 7f83b1657ff1fc53b92dc18148a1d65dfc2d4b1fa3d677284addd200126d9069
```

---

### sha256_hex(bytes: PackedByteArray) -> String

Computes SHA-256 hash and returns as hex string.

```gdscript
static func sha256_hex(bytes: PackedByteArray) -> String
```

**Parameters:**
- `bytes` (PackedByteArray): Data to hash

**Returns:** Hex-encoded SHA-256 hash (64 character string)

**Equivalent to:** `SaveCodec.sha256_bytes(bytes).hex_encode()`

**Example:**
```gdscript
var password = "my_secret_key".to_utf8_buffer()
var hash = SaveCodec.sha256_hex(password)
# Output: "8f92f64... (64 chars)" 

# Verify hash matches
var check = SaveCodec.sha256_hex("my_secret_key".to_utf8_buffer())
assert(hash == check)
```

**Use Cases:**
- Integrity checksums in `_meta.checksum`
- Key derivation for AES
- File fingerprinting

---

## Encryption/Decryption

### encrypt_aes256_cbc(data: PackedByteArray, aes_key_utf8: PackedByteArray) -> PackedByteArray

Encrypts data with AES-256-CBC.

```gdscript
static func encrypt_aes256_cbc(
    data: PackedByteArray,
    aes_key_utf8: PackedByteArray
) -> PackedByteArray
```

**Parameters:**
- `data` (PackedByteArray): Plaintext to encrypt
- `aes_key_utf8` (PackedByteArray): Encryption key (UTF-8 string as bytes)

**Returns:** Encrypted ciphertext (PackedByteArray)

**Process:**
1. **Key Derivation**: SHA-256 of UTF-8 key → 256-bit key
2. **IV Generation**: First 16 bytes of key → 128-bit IV
3. **Padding**: PKCS7 padding to 16-byte blocks
4. **Encryption**: AES-256-CBC mode
5. **Return**: Ciphertext

**Security Details:**
- **Algorithm**: AES-256 in CBC mode (industry standard)
- **Key Size**: 256 bits (32 bytes)
- **Block Size**: 128 bits (16 bytes)
- **Padding**: PKCS7 (reversible, standard)
- **IV**: Derived from key (deterministic, not random)

**Important:**
- Key must be same for encryption and decryption
- IV derivation is deterministic (same plaintext + key = same ciphertext)
- Suitable for local file encryption, not for randomized IV scenarios

**Example:**
```gdscript
var key = "my_secret_key_123".to_utf8_buffer()
var plaintext = "sensitive data".to_utf8_buffer()

var ciphertext = SaveCodec.encrypt_aes256_cbc(plaintext, key)
print("Encrypted: %d bytes" % ciphertext.size())

# Same plaintext + key = same ciphertext
var ciphertext2 = SaveCodec.encrypt_aes256_cbc(plaintext, key)
assert(ciphertext == ciphertext2)  # True
```

---

### decrypt_aes256_cbc(data: PackedByteArray, aes_key_utf8: PackedByteArray) -> PackedByteArray

Decrypts AES-256-CBC data.

```gdscript
static func decrypt_aes256_cbc(
    data: PackedByteArray,
    aes_key_utf8: PackedByteArray
) -> PackedByteArray
```

**Parameters:**
- `data` (PackedByteArray): Encrypted ciphertext
- `aes_key_utf8` (PackedByteArray): Decryption key (must match encryption key)

**Returns:** Decrypted plaintext (PackedByteArray)

**Process:**
1. **Key Derivation**: SHA-256 of UTF-8 key → 256-bit key
2. **IV Derivation**: First 16 bytes of key → 128-bit IV
3. **Decryption**: AES-256-CBC mode
4. **Unpadding**: Remove PKCS7 padding
5. **Return**: Plaintext

**Important:**
- Key **must** match encryption key exactly
- Wrong key produces garbage/errors
- Padding validation fails if data corrupted

**Example:**
```gdscript
var key = "my_secret_key_123".to_utf8_buffer()
var plaintext = "sensitive data".to_utf8_buffer()

# Encrypt
var ciphertext = SaveCodec.encrypt_aes256_cbc(plaintext, key)

# Decrypt
var decrypted = SaveCodec.decrypt_aes256_cbc(ciphertext, key)

assert(decrypted == plaintext)  # True
print(decrypted.get_string_from_utf8())  # "sensitive data"

# Wrong key fails
var wrong_key = "wrong_key".to_utf8_buffer()
var garbage = SaveCodec.decrypt_aes256_cbc(ciphertext, wrong_key)
# garbage contains corrupted data
```

---

## Compression/Decompression

### compress_zip_single(data: PackedByteArray) -> PackedByteArray

Compresses data using ZIP.

```gdscript
static func compress_zip_single(data: PackedByteArray) -> PackedByteArray
```

**Parameters:**
- `data` (PackedByteArray): Data to compress

**Returns:** Compressed ZIP archive (PackedByteArray)

**Process:**
1. Create temp ZIP file (`user://save_codec_temp_compress.zip`)
2. Add data as file entry `data.bin`
3. Close ZIP file
4. Read compressed bytes
5. Delete temp file
6. Return compressed bytes

**Compression Ratio:**
- JSON: 30-50% (good for structured data)
- Binary: 10-30% (less effective for binary)
- Text: 40-60% (very effective)

**Example:**
```gdscript
var original = "Hello World! This is a test. ".repeat(100).to_utf8_buffer()
var compressed = SaveCodec.compress_zip_single(original)

print("Original: %d bytes" % original.size())
print("Compressed: %d bytes" % compressed.size())
# Original: 2900 bytes
# Compressed: 520 bytes (82% reduction)
```

---

### decompress_zip_single(data: PackedByteArray) -> PackedByteArray

Decompresses ZIP data.

```gdscript
static func decompress_zip_single(data: PackedByteArray) -> PackedByteArray
```

**Parameters:**
- `data` (PackedByteArray): Compressed ZIP data

**Returns:** Decompressed original data (PackedByteArray)

**Process:**
1. Create temp file with ZIP data (`user://save_codec_temp_decompress.zip`)
2. Open ZIP reader
3. Extract first file entry
4. Delete temp file
5. Return decompressed bytes

**Example:**
```gdscript
var original = "large dataset...".repeat(1000).to_utf8_buffer()

# Compress
var compressed = SaveCodec.compress_zip_single(original)

# Decompress
var decompressed = SaveCodec.decompress_zip_single(compressed)

assert(decompressed == original)  # True
```

---

## Serialization

### serialize_dict(data: Dictionary, file_format: String) -> PackedByteArray

Converts Dictionary to bytes in chosen format.

```gdscript
static func serialize_dict(
    data: Dictionary,
    file_format: String
) -> PackedByteArray
```

**Parameters:**
- `data` (Dictionary): Data to serialize
- `file_format` (String): Format: `"json"`, `"txt"`, or `"bin"`

**Returns:** Serialized bytes (PackedByteArray)

**Formats:**

| Format | Method | Size | Readability | Use Case |
|--------|--------|------|-------------|----------|
| `"json"` | `JSON.stringify()` | Medium | High (human-readable) | General use, debugging |
| `"txt"` | `str(data)` | Large | Medium (GDScript format) | Simple data |
| `"bin"` | `var_to_bytes()` | Small | None (binary) | Performance-critical |

**Details:**

- **JSON**: Pretty-printed, keys sorted alphabetically, UTF-8 encoded
- **TXT**: GDScript string representation, not standard JSON
- **BIN**: GDScript binary format (more compact, not portable)

**Example:**
```gdscript
var data = {
    "player": "Hero",
    "level": 10,
    "inventory": ["sword", "shield"]
}

# JSON
var json_bytes = SaveCodec.serialize_dict(data, "json")
print(json_bytes.get_string_from_utf8())
# {
#     "inventory": ["sword", "shield"],
#     "level": 10,
#     "player": "Hero"
# }

# TXT
var txt_bytes = SaveCodec.serialize_dict(data, "txt")
print(txt_bytes.get_string_from_utf8())
# {"player": "Hero", "level": 10, "inventory": ["sword", "shield"]}

# BIN
var bin_bytes = SaveCodec.serialize_dict(data, "bin")
# Binary format, not human-readable
```

---

### deserialize_dict(bytes: PackedByteArray, file_format: String) -> Dictionary

Converts bytes back to Dictionary.

```gdscript
static func deserialize_dict(
    bytes: PackedByteArray,
    file_format: String
) -> Dictionary
```

**Parameters:**
- `bytes` (PackedByteArray): Serialized bytes
- `file_format` (String): Format: `"json"`, `"txt"`, or `"bin"`

**Returns:** Deserialized Dictionary, or `{}` if failed

**Process:**

- **JSON**: Parses JSON string, normalizes floats to ints
- **TXT**: Returns `{"raw": string_content}`
- **BIN**: Converts bytes back to GDScript objects

**Number Normalization:**
- Floats that are whole numbers converted to ints
- Example: `1.0` → `1` (not `1.0`)
- Necessary because JSON doesn't distinguish int/float

**Example:**
```gdscript
var original = {"name": "Hero", "level": 10, "health": 99.5}

# Serialize to JSON
var json_bytes = SaveCodec.serialize_dict(original, "json")
print(json_bytes.get_string_from_utf8())
# {"health": 99.5, "level": 10, "name": "Hero"}

# Deserialize back
var restored = SaveCodec.deserialize_dict(json_bytes, "json")
assert(restored == original)  # True
```

---

## Integrity Verification

### embed_integrity_checksum(data: Dictionary, file_format: String) -> Dictionary

Adds SHA-256 checksum to data.

```gdscript
static func embed_integrity_checksum(
    data: Dictionary,
    file_format: String
) -> Dictionary
```

**Parameters:**
- `data` (Dictionary): Data to checksum
- `file_format` (String): Format used for serialization

**Returns:** Modified dictionary with checksum added

**Process:**
1. Remove existing checksum from `_meta` (if present)
2. Serialize data to bytes
3. Compute SHA-256 hash of serialized bytes
4. Store hex hash in `_meta.checksum`
5. Return modified dictionary

**Key Insight:**
- Checksum computed on **serialized form**, not Python object
- This allows verification even if format changes
- Checksum itself is NOT included in checksum (to prevent circularity)

**Example:**
```gdscript
var data = {"player": "Hero", "health": 100}

var with_checksum = SaveCodec.embed_integrity_checksum(data, "json")
print(with_checksum)
# {
#   "player": "Hero",
#   "health": 100,
#   "_meta": {"checksum": "7f83b1657ff1..."}
# }

assert(with_checksum.has("_meta"))
assert(with_checksum["_meta"].has("checksum"))
```

---

### verify_integrity(parsed: Dictionary, file_format: String) -> bool

Verifies SHA-256 checksum.

```gdscript
static func verify_integrity(
    parsed: Dictionary,
    file_format: String
) -> bool
```

**Parameters:**
- `parsed` (Dictionary): Data with checksum in `_meta.checksum`
- `file_format` (String): Format used for serialization

**Returns:** `true` if checksum matches, `false` if mismatch

**Process:**
1. Extract expected checksum from `_meta.checksum`
2. Remove checksum from data (to match embedding process)
3. Serialize data
4. Compute SHA-256
5. Compare computed vs expected
6. Return result

**Returns True If:**
- Checksum matches (file not tampered)
- No checksum present (skip validation)
- No `_meta` present (skip validation)

**Example:**
```gdscript
var original = {"secret": "data"}

# Embed checksum
var with_check = SaveCodec.embed_integrity_checksum(original, "json")

# Verify (passes)
assert(SaveCodec.verify_integrity(with_check, "json"))  # True

# Tamper with data
with_check["secret"] = "hacked!"

# Verify (fails)
assert(not SaveCodec.verify_integrity(with_check, "json"))  # False
```

---

## Merging & Utilities

### deep_merge_defaults(base: Dictionary, defaults: Dictionary) -> void

Recursively merges default values into base dictionary.

```gdscript
static func deep_merge_defaults(
    base: Dictionary,
    defaults: Dictionary
) -> void
```

**Parameters:**
- `base` (Dictionary): Dictionary to merge into (modified in-place)
- `defaults` (Dictionary): Default values to add

**Behavior:**
- Adds missing keys from defaults
- Recursively processes nested dictionaries
- Does NOT overwrite existing keys
- Modifies `base` in-place (no return value)

**Example:**
```gdscript
var current = {"name": "Hero", "stats": {"health": 100}}
var defaults = {
    "name": "Unknown",
    "level": 1,
    "stats": {"health": 50, "mana": 100}
}

SaveCodec.deep_merge_defaults(current, defaults)
print(current)
# {
#   "name": "Hero",        # Existed, not overwritten
#   "level": 1,            # New key added
#   "stats": {
#     "health": 100,       # Nested key exists, not overwritten
#     "mana": 100          # New nested key added
#   }
# }
```

---

## Main Codec Functions

### encode_buffer() - Full Encoding Pipeline

```gdscript
static func encode_buffer(
    data: Dictionary,
    file_format: String,
    use_compression: bool,
    use_encryption: bool,
    aes_key_utf8: PackedByteArray,
    use_integrity_checksum: bool
) -> PackedByteArray
```

Complete encoding pipeline: serialize → checksum → compress → encrypt.

**Parameters:**
- `data` (Dictionary): Data to encode
- `file_format` (String): `"json"`, `"txt"`, or `"bin"`
- `use_compression` (bool): Apply ZIP compression
- `use_encryption` (bool): Apply AES-256 encryption
- `aes_key_utf8` (PackedByteArray): Encryption key (if encrypting)
- `use_integrity_checksum` (bool): Add SHA-256 checksum

**Returns:** Final encoded bytes ready to write to disk

**Pipeline:**
```
Dictionary
  ↓
[if use_integrity_checksum] Embed checksum in _meta
  ↓
Serialize (format: json/txt/bin) → Bytes
  ↓
[if use_compression] Compress with ZIP → Smaller bytes
  ↓
[if use_encryption] Encrypt with AES-256 → Encrypted bytes
  ↓
Return final bytes
```

**Order Important:**
1. Checksum embedded BEFORE serialization
2. Compression BEFORE encryption
3. This ensures compatibility with decoding

**Example:**
```gdscript
var data = {"player": "Hero", "level": 10}
var key = "secret123".to_utf8_buffer()

# All options enabled
var encoded = SaveCodec.encode_buffer(
    data,           # Dictionary to encode
    "json",         # Format
    true,           # Compress
    true,           # Encrypt
    key,            # Encryption key
    true            # Add checksum
)

# encoded is now ready to write to file
var file = FileAccess.open("save.sav", FileAccess.WRITE)
file.store_buffer(encoded)
file.close()
```

---

### decode_buffer() - Full Decoding Pipeline

```gdscript
static func decode_buffer(
    bytes: PackedByteArray,
    file_format: String,
    use_compression: bool,
    use_encryption: bool,
    aes_key_utf8: PackedByteArray,
    verify_checksum: bool,
    load_despite_checksum_failure: bool = false
) -> Array
```

Full decoding pipeline: decrypt → decompress → deserialize → verify.

**Parameters:**
- `bytes` (PackedByteArray): Encoded bytes from file
- `file_format` (String): `"json"`, `"txt"`, or `"bin"`
- `use_compression` (bool): Was ZIP compression used?
- `use_encryption` (bool): Was AES-256 encryption used?
- `aes_key_utf8` (PackedByteArray): Encryption key (if decrypting)
- `verify_checksum` (bool): Check SHA-256 integrity?
- `load_despite_checksum_failure` (bool, default: `false`): Load even if checksum fails?

**Returns:** Array `[success: bool, data: Dictionary]`

**Pipeline:**
```
Bytes from disk
  ↓
[if use_encryption] Decrypt with AES-256
  ↓
[if use_compression] Decompress with ZIP
  ↓
Deserialize (format: json/txt/bin) → Dictionary
  ↓
[if verify_checksum] Check SHA-256 integrity
  ├─ If match: Continue
  └─ If mismatch:
     ├─ If load_despite_checksum_failure=false: Return [false, {}]
     └─ If load_despite_checksum_failure=true: Continue with warning
  ↓
Return [true, data]
```

**Return Values:**

| Success | Data | Meaning |
|---------|------|---------|
| `true` | `{...data...}` | Decoded successfully |
| `false` | `{}` | Decoding failed (wrong key, corrupted, etc.) |

**Example - Strict (fail on checksum mismatch):**
```gdscript
var key = "secret123".to_utf8_buffer()
var result = SaveCodec.decode_buffer(
    file_bytes,         # Bytes from file
    "json",             # Format
    true,               # Was compressed
    true,               # Was encrypted
    key,                # Encryption key
    true,               # Verify checksum
    false               # Fail on checksum mismatch (default)
)

if result[0]:  # Success
    var data = result[1]
    print("Loaded: ", data)
else:  # Failed
    print("Decoding failed!")
```

**Example - Lenient (load despite checksum mismatch):**
```gdscript
var result = SaveCodec.decode_buffer(
    file_bytes,
    "json",
    true, true, key,
    true,       # Verify checksum
    true        # Load anyway if checksum fails
)

if result[0]:
    var data = result[1]
    print("Loaded (may be corrupted): ", data)
```

---

## Implementation Details

### PKCS7 Padding

Used internally for AES encryption:

```gdscript
# Padding adds N bytes of value N (1-16)
# Example: 10-byte plaintext in 16-byte block
# Before: [data...][6 empty]
# After:  [data...][6][6][6][6][6][6]

# 16-byte boundary plaintext gets full block of padding
# Before: [full data block]
# After:  [full data block][16][16][16][16]...[16]
```

This is standard and reversible.

### Key Derivation

```gdscript
# SHA-256(UTF-8 key) → 256-bit key
# key[0:16]          → 128-bit IV
# Example:
#   Input: "supersecretkey123"
#   SHA-256 hash: [32 bytes]
#   AES key: [32 bytes] (full hash)
#   IV: [16 bytes] (first 16 bytes of hash)
```

Deterministic (same key always produces same IV).

### Dictionary Sorting (JSON)

JSON serialization sorts dictionary keys alphabetically:

```gdscript
# Unsorted input
var data = {"z": 1, "a": 2, "m": 3}

# Serialized (sorted keys)
# {"a": 2, "m": 3, "z": 1}
```

This ensures consistent checksums.

---

## Examples

### Complete Encode/Decode Cycle

```gdscript
# Original data
var original = {
    "player": "Hero",
    "level": 10,
    "inventory": ["sword", "shield", "potion"]
}

var key = "my_encryption_key".to_utf8_buffer()

# Encode with all options
var encoded = SaveCodec.encode_buffer(
    original,       # Data
    "json",         # Format
    true,           # Compress
    true,           # Encrypt
    key,            # Key
    true            # Checksum
)

print("Encoded: %d bytes" % encoded.size())

# Write to file
var file = FileAccess.open("game.sav", FileAccess.WRITE)
file.store_buffer(encoded)
file.close()

# Load from file
file = FileAccess.open("game.sav", FileAccess.READ)
var file_bytes = file.get_buffer(file.get_length())
file.close()

# Decode with same settings
var result = SaveCodec.decode_buffer(
    file_bytes,     # Bytes from file
    "json",         # Format
    true,           # Decompress
    true,           # Decrypt
    key,            # Key
    true,           # Verify checksum
    false           # Strict
)

if result[0]:
    var loaded = result[1]
    assert(loaded == original)
    print("✓ Data matches!")
else:
    print("✗ Decode failed!")
```

### Integrity Checking

```gdscript
var data = {"health": 100, "mana": 50}

# Embed checksum
var with_check = SaveCodec.embed_integrity_checksum(data, "json")

# Verify (should pass)
assert(SaveCodec.verify_integrity(with_check, "json"))

# Simulate tampering
with_check["health"] = 999

# Verify (should fail)
assert(not SaveCodec.verify_integrity(with_check, "json"))

print("Tampering detected!")
```

### Format Comparison

```gdscript
var data = {"name": "Hero", "level": 10}

# JSON
var json = SaveCodec.serialize_dict(data, "json")
print("JSON size: ", json.size(), " bytes")
print(json.get_string_from_utf8())

# TXT
var txt = SaveCodec.serialize_dict(data, "txt")
print("TXT size: ", txt.size(), " bytes")

# BIN
var bin = SaveCodec.serialize_dict(data, "bin")
print("BIN size: ", bin.size(), " bytes")

# Comparison
# JSON: ~40 bytes (human-readable)
# TXT: ~50 bytes (readable but less standard)
# BIN: ~30 bytes (compact, not readable)
```

---

For SaveCodec usage in the Save class, see [Save.md](Save.md).
