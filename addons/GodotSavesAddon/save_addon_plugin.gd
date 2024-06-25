@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("Save", "Node", preload("res://addons/GodotSavesAddon/save_addon.gd"), preload("res://addons/GodotSavesAddon/plugin_icon.png"))
	# Initialization of the plugin goes here.
	pass


func _exit_tree():
	remove_custom_type("Save")
	# Clean-up of the plugin goes here.
	pass
