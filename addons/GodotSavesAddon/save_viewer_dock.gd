extends VBoxContainer
## Editor dock: inspect .sav / .save files using the same codec as ``Save`` (decrypt/decompress/verify optional).

var _path_edit: LineEdit
var _browse_btn: Button
var _encrypt_chk: CheckBox
var _compress_chk: CheckBox
var _checksum_chk: CheckBox
var _strict_chk: CheckBox
var _key_edit: LineEdit
var _fmt_opt: OptionButton
var _load_btn: Button
var _copy_btn: Button
var _status: Label
var _out: TextEdit
var _file_dialog: FileDialog


func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(320, 200)

	var title := Label.new()
	title.text = "SaveState file viewer"
	add_child(title)

	var path_row := HBoxContainer.new()
	path_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(path_row)

	_path_edit = LineEdit.new()
	_path_edit.placeholder_text = "Path to .sav / .save file"
	_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	path_row.add_child(_path_edit)

	_browse_btn = Button.new()
	_browse_btn.text = "Browse…"
	_browse_btn.pressed.connect(_on_browse)
	path_row.add_child(_browse_btn)

	_encrypt_chk = CheckBox.new()
	_encrypt_chk.text = "Encrypted (AES-256 CBC)"
	add_child(_encrypt_chk)

	_compress_chk = CheckBox.new()
	_compress_chk.text = "Compressed (ZIP)"
	add_child(_compress_chk)

	_checksum_chk = CheckBox.new()
	_checksum_chk.text = "Expect SHA-256 checksum in _meta"
	_checksum_chk.button_pressed = true
	add_child(_checksum_chk)

	_strict_chk = CheckBox.new()
	_strict_chk.text = "Strict integrity (reject on bad checksum)"
	_strict_chk.button_pressed = true
	add_child(_strict_chk)

	var key_row := HBoxContainer.new()
	key_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(key_row)

	var key_lbl := Label.new()
	key_lbl.text = "AES key (UTF-8):"
	key_lbl.custom_minimum_size.x = 120
	key_row.add_child(key_lbl)

	_key_edit = LineEdit.new()
	_key_edit.placeholder_text = "Matches Save node default if unchanged"
	_key_edit.text = "supersecretkey123"
	_key_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_row.add_child(_key_edit)

	var fmt_row := HBoxContainer.new()
	add_child(fmt_row)

	var fmt_lbl := Label.new()
	fmt_lbl.text = "Format:"
	fmt_lbl.custom_minimum_size.x = 120
	fmt_row.add_child(fmt_lbl)

	_fmt_opt = OptionButton.new()
	_fmt_opt.add_item("json", 0)
	_fmt_opt.add_item("txt", 1)
	_fmt_opt.add_item("bin", 2)
	_fmt_opt.selected = 0
	fmt_row.add_child(_fmt_opt)

	var btn_row := HBoxContainer.new()
	add_child(btn_row)

	_load_btn = Button.new()
	_load_btn.text = "Load & decode"
	_load_btn.pressed.connect(_on_load)
	btn_row.add_child(_load_btn)

	_copy_btn = Button.new()
	_copy_btn.text = "Copy JSON"
	_copy_btn.pressed.connect(_on_copy)
	btn_row.add_child(_copy_btn)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.text = "Pick a file and options matching your Save node."
	add_child(_status)

	_out = TextEdit.new()
	_out.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_out.custom_minimum_size = Vector2(0, 220)
	_out.editable = false
	add_child(_out)

	_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.title = "Open save file"
	_file_dialog.file_selected.connect(_on_file_picked)
	add_child(_file_dialog)

	_encrypt_chk.toggled.connect(_on_crypto_toggled)
	_on_crypto_toggled(_encrypt_chk.button_pressed)


func _on_crypto_toggled(pressed: bool) -> void:
	_key_edit.editable = pressed


func _on_browse() -> void:
	_file_dialog.popup_centered_ratio(0.6)


func _on_file_picked(p: String) -> void:
	_path_edit.text = p


func _format_name() -> String:
	match _fmt_opt.selected:
		1:
			return "txt"
		2:
			return "bin"
		_:
			return "json"


func _on_load() -> void:
	var p := _path_edit.text.strip_edges()
	if p == "":
		_status.text = "Enter a file path."
		return
	if not FileAccess.file_exists(p):
		_status.text = "File does not exist: %s" % p
		return

	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		_status.text = "Could not open file for reading."
		return
	var bytes := f.get_buffer(f.get_length())
	f.close()

	var key := PackedByteArray()
	if _encrypt_chk.button_pressed:
		key = _key_edit.text.to_utf8_buffer()

	var res: Array = SaveCodec.decode_buffer(
		bytes,
		_format_name(),
		_compress_chk.button_pressed,
		_encrypt_chk.button_pressed,
		key,
		_checksum_chk.button_pressed,
		not _strict_chk.button_pressed
	)

	if not res[0]:
		_status.text = "Decode failed or checksum mismatch. Try options matching your Save node or disable strict integrity."
		_out.text = ""
		return

	var data: Dictionary = res[1]
	_status.text = "OK — %d bytes raw, %d top-level keys." % [bytes.size(), data.size()]
	var txt := JSON.stringify(data, "\t")
	if txt == "" and not data.is_empty():
		txt = str(data)
	_out.text = txt


func _on_copy() -> void:
	if _out.text == "":
		return
	DisplayServer.clipboard_set(_out.text)
	_status.text = "Copied to clipboard."
