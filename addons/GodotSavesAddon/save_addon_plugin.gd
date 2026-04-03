@tool
extends EditorPlugin

const _ViewerScene := preload("res://addons/GodotSavesAddon/save_viewer_dock.gd")

var _viewer: Control


func _enter_tree() -> void:
	add_custom_type(
		"Save",
		"Node",
		preload("res://addons/GodotSavesAddon/save_addon.gd"),
		preload("res://addons/GodotSavesAddon/plugin_icon.png")
	)
	_viewer = _ViewerScene.new()
	_viewer.name = "SaveStateViewer"
	add_control_to_dock(DOCK_SLOT_LEFT_UL, _viewer)


func _exit_tree() -> void:
	remove_custom_type("Save")
	if is_instance_valid(_viewer):
		remove_control_from_docks(_viewer)
		_viewer.queue_free()
		_viewer = null
