# Save.gd
class_name Save
extends Node

signal save_completed(profile: String)
signal load_completed(profile: String, data: Dictionary)
signal save_failed(profile: String, reason: String)

const MAX_QUEUE_LENGTH: int = 4
@onready var AES_KEY: PackedByteArray = "supersecretkey123".to_utf8_buffer()
const SAVE_VERSION: int = 1

@export var data_in_folder: bool = false
@export var folder_name: String = "save"
@export var save_name: String = ""
@export var print_in_terminal: bool = true

@export var screenshot_in_folder: bool = false
@export var screenshot_folder_name: String = "screenshots"
@export var screenshot_print_in_terminal: bool = true
@export var screenshot_max_count: int = 50

@export var use_encryption: bool = false
@export var use_compression: bool = false
@export var keep_backups: bool = true
@export var backup_limit: int = 3

@export var auto_save_interval: float = 0.0 ## Seconds (0 = disabled)
@export var auto_load_on_ready: bool = true
@export var remote_save_url: String = "" ## For cloud sync
@export var file_format: String = "json" ## "json", "txt", "bin"

var _res_user: String = "user://"
var _s_res_user: String = "user://"
var _thread: Thread
var _mutex: Mutex
var _queue: Array = []
var _autosave_timer: Timer

func _ready() -> void:
	_res_user = "res://" if data_in_folder else "user://"
	_s_res_user = "res://" if screenshot_in_folder else "user://"
	_thread = Thread.new()
	_mutex = Mutex.new()

	if auto_load_on_ready and save_name != "":
		# attempt to load default profile and emit load_completed
		var loaded := edit_data(save_name)
		emit_signal("load_completed", "default", loaded)

	if auto_save_interval > 0:
		_autosave_timer = Timer.new()
		_autosave_timer.wait_time = auto_save_interval
		_autosave_timer.autostart = true
		_autosave_timer.one_shot = false
		_autosave_timer.timeout.connect(_on_autosave)
		add_child(_autosave_timer)


func _log(msg: String, is_screenshot: bool = false) -> void:
	if (is_screenshot and screenshot_print_in_terminal) or (not is_screenshot and print_in_terminal):
		print(msg)


func create_folder(resuser: String, folder: String) -> void:
	var dir := DirAccess.open(resuser)
	if not dir.dir_exists_absolute(resuser + folder):
		dir.make_dir_absolute(resuser + folder)
		_log("Making directory: " + resuser + folder)


### --- CRYPTO HELPERS (AES-256 CBC using AESContext + HashingContext) ---

func _sha256(bytes: PackedByteArray) -> PackedByteArray:
	var h := HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	h.update(bytes)
	return h.finish() # 32 bytes


func _pkcs7_pad(bytes: PackedByteArray, block_size: int = 16) -> PackedByteArray:
	var pad_len := block_size - (bytes.size() % block_size)
	if pad_len == 0:
		pad_len = block_size
	var out := PackedByteArray(bytes)
	var orig := out.size()
	out.resize(orig + pad_len)
	for i in range(pad_len):
		out[orig + i] = pad_len
	return out


func _pkcs7_unpad(bytes: PackedByteArray, block_size: int = 16) -> PackedByteArray:
	if bytes.is_empty():
		return bytes
	var pad_len := int(bytes[bytes.size() - 1])
	# basic validation to avoid crashes on corrupted data
	if pad_len <= 0 or pad_len > block_size or pad_len > bytes.size():
		push_error("PKCS7 unpad validation failed, returning original bytes.")
		return bytes
	return bytes.slice(0, bytes.size() - pad_len)


func _encrypt(data: PackedByteArray) -> PackedByteArray:
	if not use_encryption:
		return data
	# Derive 32-byte key, use first 16 bytes as IV
	var key := _sha256(AES_KEY) # 32 bytes
	var iv := key.slice(0, 16)
	var aes := AESContext.new()
	aes.start(AESContext.MODE_CBC_ENCRYPT, key, iv)
	var input := _pkcs7_pad(data, 16)
	var out := aes.update(input)
	aes.finish() # just finalize, no output
	return out


func _decrypt(data: PackedByteArray) -> PackedByteArray:
	if not use_encryption:
		return data
	var key := _sha256(AES_KEY)
	var iv := key.slice(0, 16)
	var aes := AESContext.new()
	aes.start(AESContext.MODE_CBC_DECRYPT, key, iv)
	var out := aes.update(data)
	aes.finish()
	out = _pkcs7_unpad(out, 16)
	return out


### --- COMPRESSION HELPERS ---
func _compress(data: PackedByteArray) -> PackedByteArray:
	if not use_compression:
		return data

	var temp_path := "user://temp_compress.zip"

	# --- Write ZIP ---
	var zp := ZIPPacker.new()
	if zp.open(temp_path) != OK:
		push_error("Failed to open temp ZIP file for compression.")
		return data

	zp.start_file("data.bin")
	zp.write_file(data)
	zp.close()

	# --- Read back compressed data ---
	var compressed := FileAccess.get_file_as_bytes(temp_path)

	# --- Cleanup temp file ---
	DirAccess.remove_absolute(temp_path)

	return compressed


func _decompress(data: PackedByteArray) -> PackedByteArray:
	if not use_compression:
		return data

	# Write ZIP to temp file first
	var temp_path := "user://temp_decompress.zip"
	var f := FileAccess.open(temp_path, FileAccess.WRITE)
	if f == null:
		push_error("Failed to write temp ZIP file for decompression.")
		return data
	f.store_buffer(data)
	f.close()

	# Read contents using ZIPReader
	var zr := ZIPReader.new()
	if zr.open(temp_path) != OK:
		push_error("Failed to open ZIP for decompression.")
		return data

	var files := zr.get_files()
	if files.size() == 0:
		push_error("No files found in ZIP, returning original data.")
		return data

	var decompressed := zr.read_file(files[0])
	zr.close()

	DirAccess.remove_absolute(temp_path)
	return decompressed



### --- SAFE FILE WRITE HELPER ---

func _safe_write(path: String, bytes: PackedByteArray) -> bool:
	var temp_path := path + ".tmp"
	var f := FileAccess.open(temp_path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_buffer(bytes)
	f.close()
	# remove original if exists, then rename temp -> final
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	# rename: DirAccess.rename_absolute requires full paths existing; use rename if possible
	DirAccess.rename_absolute(temp_path, path)
	return true


### --- SAVE / LOAD ---

func save_data(data: Dictionary, profile: String = "save", filetype: String = ".sav", async: bool = false) -> void:
	create_folder(_res_user, folder_name)
	if profile == "": profile = "save"

	var path := _res_user + folder_name + "/" + profile + filetype
	print(path)

	# Backup rotation
	if keep_backups and FileAccess.file_exists(path):
		# rotate bakN -> bakN+1
		for i in range(backup_limit, 1, -1):
			var old_backup := path + ".bak" + str(i - 1)
			var new_backup := path + ".bak" + str(i)
			if FileAccess.file_exists(old_backup):
				DirAccess.rename_absolute(old_backup, new_backup)
		# copy current to .bak1
		DirAccess.copy_absolute(path, path + ".bak1")

	# Add metadata
	data["_meta"] = {"version": SAVE_VERSION, "timestamp": Time.get_datetime_string_from_system()}

	var bytes: PackedByteArray
	match file_format:
		"json":
			bytes = JSON.stringify(data).to_utf8_buffer()
		"txt":
			bytes = str(data).to_utf8_buffer()
		"bin":
			bytes = var_to_bytes(data)

	# compress -> encrypt -> write
	bytes = _compress(bytes)
	bytes = _encrypt(bytes)

	var ok := _safe_write(path, bytes)
	if not ok:
		emit_signal("save_failed", profile, "Cannot write file")
		return

	emit_signal("save_completed", profile)
	_log("Saved profile: " + profile)


func edit_data(profile: String = "save", filetype: String = ".sav") -> Dictionary:
	create_folder(_res_user, folder_name)
	if profile == "": profile = "save"

	var path := _res_user + folder_name + "/" + profile + filetype
	print(path)
	if not FileAccess.file_exists(path):
		_log("File not found, returning empty dictionary")
		return {}

	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_log("Unable to open file for reading")
		return {}
	var bytes := f.get_buffer(f.get_length())
	f.close()

	# decrypt -> decompress -> parse
	bytes = _decrypt(bytes)
	bytes = _decompress(bytes)

	var data: Dictionary = {}
	match file_format:
		"json":
			var parsed = JSON.parse_string(bytes.get_string_from_utf8())
			# JSON.parse_string returns a Variant (Dictionary or Array or Error) depending on content
			if typeof(parsed) == TYPE_DICTIONARY:
				data = parsed
			else:
				# JSON.parse_string sometimes returns a result object; attempt safe conversion:
				# if parse failed, fallback to empty dict
				data = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
		"txt":
			data = {"raw": bytes.get_string_from_utf8()}
		"bin":
			var v = bytes_to_var(bytes)
			if typeof(v) == TYPE_DICTIONARY:
				data = v
			else:
				data = {}

	if typeof(data) != TYPE_DICTIONARY:
		emit_signal("load_completed", profile, {})
		return {}

	emit_signal("load_completed", profile, data)
	return data


### --- SLOT MANAGEMENT ---

func list_profiles(filetype: String = ".sav") -> Array:
	var profiles := []
	var dir := DirAccess.open(_res_user + folder_name)
	if dir == null:
		return profiles
	for file in dir.get_files():
		if file.ends_with(filetype):
			profiles.append(file)
	return profiles


func delete_all_profiles(filetype: String = ".sav") -> void:
	var dir := DirAccess.open(_res_user + folder_name)
	if dir == null:
		return
	for file in dir.get_files():
		if file.ends_with(filetype):
			dir.remove(file)


### --- CLOUD SYNC (basic) ---

# NOTE: This is a minimal upload/download example. For production, add authentication & error handling.
func upload_save(profile: String = "save", filetype: String = ".sav") -> void:
	if remote_save_url == "":
		_log("No remote_save_url set, skipping upload")
		return
	var path := _res_user + folder_name + "/" + profile + filetype
	if not FileAccess.file_exists(path):
		_log("No file to upload")
		return

	var f := FileAccess.open(path, FileAccess.READ)
	var bytes := f.get_buffer(f.get_length())
	f.close()

	var http := HTTPRequest.new()
	add_child(http)
	http.connect("request_completed", Callable(self, "_on_upload_completed"), ConnectFlags.CONNECT_ONE_SHOT)
	http.request(remote_save_url, [], HTTPClient.METHOD_POST, bytes_to_var(bytes))


func _on_upload_completed(result, response_code, headers, body) -> void:
	_log("Upload completed: code=" + str(response_code))


func download_save(profile: String = "save", filetype: String = ".sav") -> void:
	if remote_save_url == "":
		_log("No remote_save_url set, skipping download")
		return

	var http := HTTPRequest.new()
	add_child(http)
	http.connect("request_completed", Callable(self, "_on_download_completed").bind(profile, filetype), ConnectFlags.CONNECT_ONE_SHOT)
	http.request(remote_save_url, [], HTTPClient.METHOD_GET)


func _on_download_completed(profile: String, filetype: String, result, response_code, headers, body) -> void:
	if response_code != 200:
		_log("Download failed, code: " + str(response_code))
		return
	var path := _res_user + folder_name + "/" + profile + filetype
	_safe_write(path, body)
	_log("Downloaded save for profile: " + profile)


### --- AUTOSAVE ---

func _on_autosave() -> void:
	var autosave_data := get_tree().get_root().get_meta("autosave_data", {})
	save_data(autosave_data, "autosave")


### --- SCREENSHOT QUEUE (kept from earlier versions) ---

func snap_screenshot(viewport: Viewport, custom_name: String = "") -> void:
	create_folder(_s_res_user, screenshot_folder_name)
	var dt := Time.get_datetime_dict_from_system()
	var timestamp := "%04d%02d%02d_%02d%02d%02d" % [dt["year"], dt["month"], dt["day"], dt["hour"], dt["minute"], dt["second"]]
	var filename := custom_name if custom_name != "" else "screenshot-" + timestamp
	var image: Image = viewport.get_texture().get_image()
	screenshot_save(image, _s_res_user + screenshot_folder_name + "/" + filename + ".png")
	_clean_screenshot_folder()


func _clean_screenshot_folder() -> void:
	if screenshot_max_count <= 0:
		return
	var dir := DirAccess.open(_s_res_user + screenshot_folder_name)
	if dir == null:
		return
	var files := dir.get_files()
	if files.size() > screenshot_max_count:
		files.sort() # alphabetical => oldest first if timestamped like above
		for i in range(files.size() - screenshot_max_count):
			dir.remove(files[i])


func screenshot_save(image: Image, path: String) -> void:
	_mutex.lock()
	if _queue.size() < MAX_QUEUE_LENGTH:
		_queue.push_back({"image": image, "path": path})
	else:
		_log("Screenshot queue overflow", true)

	if _queue.size() == 1:
		if _thread.is_alive():
			_thread.wait_to_finish()
		_thread.start(worker_function.bind(1))
	_mutex.unlock()


func worker_function(_userdata) -> void:
	_mutex.try_lock()
	while not _queue.is_empty():
		var item := _queue.front()
		_mutex.unlock()
		call_deferred("_save_screenshot", item)
		_mutex.lock()
		_queue.pop_front()
	_mutex.unlock()


func _save_screenshot(item: Dictionary) -> void:
	_log("Saving screenshot to " + item["path"], true)
	item["image"].save_png(item["path"])
