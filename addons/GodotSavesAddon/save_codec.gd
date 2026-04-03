## Shared serialization, encryption, compression, and integrity helpers for Save and the editor viewer.
class_name SaveCodec
extends RefCounted


static func sha256_bytes(bytes: PackedByteArray) -> PackedByteArray:
	var h := HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	h.update(bytes)
	return h.finish()


static func sha256_hex(bytes: PackedByteArray) -> String:
	var raw := sha256_bytes(bytes)
	return raw.hex_encode()


static func _pkcs7_pad(bytes: PackedByteArray, block_size: int = 16) -> PackedByteArray:
	var pad_len := block_size - (bytes.size() % block_size)
	if pad_len == 0:
		pad_len = block_size
	var out := PackedByteArray(bytes)
	var orig := out.size()
	out.resize(orig + pad_len)
	for i in range(pad_len):
		out[orig + i] = pad_len
	return out


static func _pkcs7_unpad(bytes: PackedByteArray, block_size: int = 16) -> PackedByteArray:
	if bytes.is_empty():
		return bytes
	var pad_len := int(bytes[bytes.size() - 1])
	if pad_len <= 0 or pad_len > block_size or pad_len > bytes.size():
		push_error("SaveCodec: PKCS7 unpad validation failed.")
		return bytes
	return bytes.slice(0, bytes.size() - pad_len)


static func _derive_key_iv(aes_key_utf8: PackedByteArray) -> Array:
	var key := sha256_bytes(aes_key_utf8)
	var iv := key.slice(0, 16)
	return [key, iv]


static func encrypt_aes256_cbc(data: PackedByteArray, aes_key_utf8: PackedByteArray) -> PackedByteArray:
	var kv := _derive_key_iv(aes_key_utf8)
	var key: PackedByteArray = kv[0]
	var iv: PackedByteArray = kv[1]
	var aes := AESContext.new()
	aes.start(AESContext.MODE_CBC_ENCRYPT, key, iv)
	var input := _pkcs7_pad(data, 16)
	var out := aes.update(input)
	aes.finish()
	return out


static func decrypt_aes256_cbc(data: PackedByteArray, aes_key_utf8: PackedByteArray) -> PackedByteArray:
	var kv := _derive_key_iv(aes_key_utf8)
	var key: PackedByteArray = kv[0]
	var iv: PackedByteArray = kv[1]
	var aes := AESContext.new()
	aes.start(AESContext.MODE_CBC_DECRYPT, key, iv)
	var out := aes.update(data)
	aes.finish()
	return _pkcs7_unpad(out, 16)


static func compress_zip_single(data: PackedByteArray) -> PackedByteArray:
	var temp_path := "user://save_codec_temp_compress.zip"
	var zp := ZIPPacker.new()
	if zp.open(temp_path) != OK:
		push_error("SaveCodec: failed to open temp zip for compression.")
		return data
	zp.start_file("data.bin")
	zp.write_file(data)
	zp.close()
	var compressed := FileAccess.get_file_as_bytes(temp_path)
	DirAccess.remove_absolute(temp_path)
	return compressed


static func decompress_zip_single(data: PackedByteArray) -> PackedByteArray:
	var temp_path := "user://save_codec_temp_decompress.zip"
	var f := FileAccess.open(temp_path, FileAccess.WRITE)
	if f == null:
		push_error("SaveCodec: failed to write temp zip for decompression.")
		return data
	f.store_buffer(data)
	f.close()
	var zr := ZIPReader.new()
	if zr.open(temp_path) != OK:
		push_error("SaveCodec: failed to open zip for decompression.")
		return data
	var files := zr.get_files()
	if files.is_empty():
		zr.close()
		DirAccess.remove_absolute(temp_path)
		return data
	var decompressed := zr.read_file(files[0])
	zr.close()
	DirAccess.remove_absolute(temp_path)
	return decompressed


static func serialize_dict(data: Dictionary, file_format: String) -> PackedByteArray:
	match file_format:
		"json":
			return JSON.stringify(data).to_utf8_buffer()
		"txt":
			return str(data).to_utf8_buffer()
		"bin":
			return var_to_bytes(data)
		_:
			return JSON.stringify(data).to_utf8_buffer()


static func deserialize_dict(bytes: PackedByteArray, file_format: String) -> Dictionary:
	match file_format:
		"json":
			var parsed = JSON.parse_string(bytes.get_string_from_utf8())
			if typeof(parsed) == TYPE_DICTIONARY:
				return parsed
			return {}
		"txt":
			return {"raw": bytes.get_string_from_utf8()}
		"bin":
			var v = bytes_to_var(bytes)
			if typeof(v) == TYPE_DICTIONARY:
				return v
			return {}
		_:
			return {}


static func deep_merge_defaults(base: Dictionary, defaults: Dictionary) -> void:
	for k in defaults:
		if not base.has(k):
			base[k] = defaults[k]
		elif typeof(base[k]) == TYPE_DICTIONARY and typeof(defaults[k]) == TYPE_DICTIONARY:
			deep_merge_defaults(base[k], defaults[k])


static func _strip_checksum_from_meta(d: Dictionary) -> void:
	if not d.has("_meta"):
		return
	var m: Variant = d["_meta"]
	if typeof(m) != TYPE_DICTIONARY:
		return
	if m.has("checksum"):
		m.erase("checksum")


static func embed_integrity_checksum(data: Dictionary, file_format: String) -> Dictionary:
	var out := data.duplicate(true)
	_strip_checksum_from_meta(out)
	var payload := serialize_dict(out, file_format)
	var hex := sha256_hex(payload)
	if not out.has("_meta") or typeof(out.get("_meta")) != TYPE_DICTIONARY:
		out["_meta"] = {}
	(out["_meta"] as Dictionary)["checksum"] = hex
	return out


static func verify_integrity(parsed: Dictionary, file_format: String) -> bool:
	if not parsed.has("_meta") or typeof(parsed["_meta"]) != TYPE_DICTIONARY:
		return true
	var meta: Dictionary = parsed["_meta"]
	if not meta.has("checksum"):
		return true
	var expected: String = str(meta["checksum"])
	var copy := parsed.duplicate(true)
	_strip_checksum_from_meta(copy)
	var payload := serialize_dict(copy, file_format)
	var actual := sha256_hex(payload)
	return actual == expected


static func encode_buffer(
	data: Dictionary,
	file_format: String,
	use_compression: bool,
	use_encryption: bool,
	aes_key_utf8: PackedByteArray,
	use_integrity_checksum: bool
) -> PackedByteArray:
	var to_pack := data
	if use_integrity_checksum:
		to_pack = embed_integrity_checksum(data.duplicate(true), file_format)
	var bytes := serialize_dict(to_pack, file_format)
	if use_compression:
		bytes = compress_zip_single(bytes)
	if use_encryption:
		bytes = encrypt_aes256_cbc(bytes, aes_key_utf8)
	return bytes


## Returns ``[ok: bool, data: Dictionary]``. When ``ok`` is false, ``data`` is empty.
static func decode_buffer(
	bytes: PackedByteArray,
	file_format: String,
	use_compression: bool,
	use_encryption: bool,
	aes_key_utf8: PackedByteArray,
	verify_checksum: bool,
	load_despite_checksum_failure: bool = false
) -> Array:
	var b := bytes
	if use_encryption:
		b = decrypt_aes256_cbc(b, aes_key_utf8)
	if use_compression:
		b = decompress_zip_single(b)
	var data := deserialize_dict(b, file_format)
	if verify_checksum and typeof(data) == TYPE_DICTIONARY and not data.is_empty():
		if data.has("_meta") and typeof(data["_meta"]) == TYPE_DICTIONARY and data["_meta"].has("checksum"):
			if not verify_integrity(data, file_format):
				push_error("SaveCodec: integrity check failed (checksum mismatch). File may be corrupted or tampered.")
				if not load_despite_checksum_failure:
					return [false, {}]
	return [true, data]
