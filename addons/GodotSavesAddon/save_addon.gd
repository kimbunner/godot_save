# Save.gd
class_name Save
extends Node

signal save_completed(profile: String)
signal load_completed(profile: String, data: Dictionary)
signal save_failed(profile: String, reason: String)
signal load_failed(profile: String, reason: String)
signal migration_applied(profile: String, from_version: int, to_version: int)

const MAX_QUEUE_LENGTH: int = 4
## Bump when you add new required fields; override ``migrate_save_data`` for custom steps.
const CURRENT_SAVE_VERSION: int = 2

@onready var AES_KEY: PackedByteArray = "supersecretkey123".to_utf8_buffer()

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

## SHA-256 over serialized payload (before compression/encryption). Helps detect manual edits.
@export var use_integrity_checksum: bool = true
## If true, ``edit_data`` returns ``{}`` when the checksum does not match.
@export var strict_integrity: bool = true

@export var auto_save_interval: float = 0.0 ## Seconds (0 = disabled)
@export var auto_load_on_ready: bool = true
@export var remote_save_url: String = "" ## For cloud sync
@export var file_format: String = "json" ## "json", "txt", "bin"

## Shallow/recursive defaults merged when a loaded save is older than ``CURRENT_SAVE_VERSION``.
## For complex migrations, override ``migrate_save_data`` instead.
@export var default_values_for_new_keys: Dictionary = {}

var _res_user: String = "user://"
var _s_res_user: String = "user://"
var _thread: Thread
var _mutex: Mutex
var _queue: Array = []
var _autosave_timer: Timer

var _save_thread: Thread


func _ready() -> void:
	_res_user = "res://" if data_in_folder else "user://"
	_s_res_user = "res://" if screenshot_in_folder else "user://"
	_thread = Thread.new()
	_save_thread = Thread.new()
	_mutex = Mutex.new()

	if auto_load_on_ready and save_name != "":
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


## Override in a subclass for custom per-version migrations. Call ``super`` if you extend defaults.
func migrate_save_data(data: Dictionary, from_version: int) -> Dictionary:
	var d := data.duplicate(true)
	if from_version < CURRENT_SAVE_VERSION and not default_values_for_new_keys.is_empty():
		SaveCodec.deep_merge_defaults(d, default_values_for_new_keys.duplicate(true))
	return d


func _apply_schema_migrations(data: Dictionary, profile: String) -> Dictionary:
	if typeof(data) != TYPE_DICTIONARY or data.is_empty():
		return data
	var meta: Variant = data.get("_meta", {})
	var loaded_version: int = 1
	if typeof(meta) == TYPE_DICTIONARY and meta.has("version"):
		loaded_version = int(meta["version"])
	if loaded_version > CURRENT_SAVE_VERSION:
		var msg := "Save newer than game (file v%s vs game v%s)." % [str(loaded_version), str(CURRENT_SAVE_VERSION)]
		push_warning(msg)
		return data
	if loaded_version < CURRENT_SAVE_VERSION:
		var migrated := migrate_save_data(data, loaded_version)
		if not migrated.has("_meta") or typeof(migrated["_meta"]) != TYPE_DICTIONARY:
			migrated["_meta"] = {}
		(migrated["_meta"] as Dictionary)["version"] = CURRENT_SAVE_VERSION
		emit_signal("migration_applied", profile, loaded_version, CURRENT_SAVE_VERSION)
		return migrated
	return data


func _aes_key_bytes() -> PackedByteArray:
	return AES_KEY


func _encode_save_payload(data: Dictionary) -> PackedByteArray:
	return SaveCodec.encode_buffer(
		data,
		file_format,
		use_compression,
		use_encryption,
		_aes_key_bytes(),
		use_integrity_checksum
	)


func _decode_save_bytes(bytes: PackedByteArray) -> Array:
	return SaveCodec.decode_buffer(
		bytes,
		file_format,
		use_compression,
		use_encryption,
		_aes_key_bytes(),
		use_integrity_checksum,
		not strict_integrity
	)


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


func save_data(data: Dictionary, profile: String = "save", filetype: String = ".sav", async_save: bool = false) -> void:
	create_folder(_res_user, folder_name)
	if profile == "":
		profile = "save"

	var path := _res_user + folder_name + "/" + profile + filetype
	print(path)

	if keep_backups and FileAccess.file_exists(path):
		for i in range(backup_limit, 1, -1):
			var old_backup := path + ".bak" + str(i - 1)
			var new_backup := path + ".bak" + str(i)
			if FileAccess.file_exists(old_backup):
				DirAccess.rename_absolute(old_backup, new_backup)
		DirAccess.copy_absolute(path, path + ".bak1")

	data["_meta"] = {"version": CURRENT_SAVE_VERSION, "timestamp": Time.get_datetime_string_from_system()}

	if async_save:
		var snapshot: Dictionary = data.duplicate(true)
		if _save_thread.is_alive():
			_save_thread.wait_to_finish()
		_save_thread.start(
			_async_save_worker.bind(
				{
					"path": path,
					"profile": profile,
					"snapshot": snapshot,
					"key": _aes_key_bytes().duplicate(),
					"fmt": file_format,
					"compress": use_compression,
					"encrypt": use_encryption,
					"checksum": use_integrity_checksum,
				}
			)
		)
		return

	var bytes := _encode_save_payload(data)
	var ok := _safe_write(path, bytes)
	if not ok:
		emit_signal("save_failed", profile, "Cannot write file")
		return

	emit_signal("save_completed", profile)
	_log("Saved profile: " + profile)


func _async_save_worker(ud: Dictionary) -> void:
	var bytes := SaveCodec.encode_buffer(
		ud["snapshot"],
		ud["fmt"],
		ud["compress"],
		ud["encrypt"],
		ud["key"],
		ud["checksum"]
	)
	call_deferred("_async_save_finish", ud["path"], ud["profile"], bytes)


func _async_save_finish(path: String, profile: String, bytes: PackedByteArray) -> void:
	if _save_thread.is_alive():
		_save_thread.wait_to_finish()
	var ok := _safe_write(path, bytes)
	if not ok:
		emit_signal("save_failed", profile, "Cannot write file (async)")
	else:
		emit_signal("save_completed", profile)
		_log("Saved profile (async): " + profile)


func edit_data(profile: String = "save", filetype: String = ".sav") -> Dictionary:
	create_folder(_res_user, folder_name)
	if profile == "":
		profile = "save"

	var path := _res_user + folder_name + "/" + profile + filetype
	print(path)
	if not FileAccess.file_exists(path):
		_log("File not found, returning empty dictionary")
		return {}

	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_log("Unable to open file for reading")
		emit_signal("load_failed", profile, "Cannot open file")
		return {}
	var bytes := f.get_buffer(f.get_length())
	f.close()

	var dec := _decode_save_bytes(bytes)
	if not dec[0]:
		emit_signal("load_failed", profile, "Integrity check failed")
		emit_signal("load_completed", profile, {})
		return {}

	var data: Dictionary = dec[1]
	data = _apply_schema_migrations(data, profile)

	emit_signal("load_completed", profile, data)
	return data


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


func upload_save(profile: String = "save", filetype: String = ".sav") -> void:
	if remote_save_url == "":
		_log("No remote_save_url set, skipping upload")
		return
	var path := _res_user + folder_name + "/" + profile + filetype
	if not FileAccess.file_exists(path):
		_log("No file to upload")
		return

	var f := FileAccess.open(path, FileAccess.READ)
	var file_bytes := f.get_buffer(f.get_length())
	f.close()

	var http := HTTPRequest.new()
	add_child(http)
	http.connect("request_completed", Callable(self, "_on_upload_completed"), ConnectFlags.CONNECT_ONE_SHOT)
	http.request_raw(remote_save_url, PackedStringArray(), HTTPClient.METHOD_POST, file_bytes)


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


func _on_autosave() -> void:
	var autosave_data := get_tree().get_root().get_meta("autosave_data", {})
	save_data(autosave_data, "autosave")


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
		files.sort()
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
