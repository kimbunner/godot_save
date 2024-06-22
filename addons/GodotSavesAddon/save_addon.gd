extends Node

## Node that handles saving and loading user data
##
## The save node can create and store data in the specified data format.
## The node also handles saving screenshots.
##
## @tutorial(Project Github): https://github.com/kimbunner/godot_save


const MAX_QUEUE_LENGTH: int = 4

## Toggles the use of "user://" and "res://"
## [codeblock]
## true = "res://"
## false = "user://"
## [/codeblock]
@export var data_in_folder: bool = false

## Folder name for saving data
@export var folder_name: String = "save"

## Determines if file debug statements are printed
## if false, this script will not print
@export var print_in_terminal: bool = true

## Toggles the use of "user://" and "res://"
## [codeblock]
## true = "res://"
## false = "user://"
## [/codeblock]
@export var screenshot_in_folder: bool = false

## Folder name for saving screenshots
@export var screenshot_folder_name: String = "screenshots"

## Determines if screenshot debug statements are printed
## if false, this script will not print
@export var screenshot_print_in_terminal: bool = true

# Internal variables
var _res_user: String = "user://"
var _s_res_user: String = "user://"

# Thread and mutex for handling screenshot saving
var _thread: Thread
var _mutex: Mutex
var _queue: Array = []


func _ready() -> void:
	# Set the path for data saving
	_res_user = "res://" if data_in_folder else "user://"
	
	# Set the path for screenshot saving
	_s_res_user = "res://" if screenshot_in_folder else "user://"
	
	_thread = Thread.new()
	_mutex = Mutex.new()


## Creates a folder if it doesn't exist. [br]
## [param resuser] The base path ("user://" or "res://"). [br]
## [param folder] The name of the folder to create.
func create_folder(resuser: String, folder: String) -> void:
	var path: DirAccess = DirAccess.open(resuser)
	if not path.dir_exists_absolute(resuser + folder):
		path.make_dir_absolute(resuser + folder)
		if print_in_terminal:
			print("Making directory: " + resuser + folder)


## Saves data to a file. [br]
## [param data] Dictionary containing data to save. [br]
## [param profile] The name of the profile (default is "save"). [br]
## [param filetype] The file extension (default is ".sav"). [br]
func save_data(data: Dictionary, profile: String = "save", filetype: String = ".sav") -> void:
	create_folder(_res_user, folder_name)
	
	if profile == "":
		profile = "save"
	
	var thefile: FileAccess = FileAccess.open(_res_user + folder_name + "/" + profile + filetype, FileAccess.WRITE)
	thefile.store_line(JSON.stringify(data))
	thefile.close()
	
	if print_in_terminal:
		print("Saved: " + str(data))


## Loads data from a file. [br]
## [param profile] The name of the profile (default is "save"). [br]
## [param filetype] The file extension (default is ".sav"). [br]
## @return Dictionary containing loaded data.
func edit_data(profile: String = "save", filetype: String = ".sav") -> Dictionary:
	create_folder(_res_user, folder_name)
	
	var data: Dictionary = {}
	if profile == "":
		profile = "save"
	
	var path: String = _res_user + folder_name + "/" + profile + filetype
	if not FileAccess.file_exists(path):
		if print_in_terminal:
			print("The file doesn't exist yet, returning empty dictionary")
	else:
		var thefile: FileAccess = FileAccess.open(path, FileAccess.READ)
		if not thefile.eof_reached():
			var almost_data = JSON.parse_string(thefile.get_line())
			if almost_data != null:
				data = almost_data
	return data


## Saves data to a specific folder. [br]
## [param data] Dictionary containing data to save. [br]
## [param resuser] The base path ("user://" or "res://"). [br]
## [param folder] The name of the folder to save the data. [br]
## [param profile] The name of the profile (default is "save"). [br]
## [param filetype] The file extension (default is ".sav").
func save_data_in_folder(data: Dictionary, resuser: String, folder: String, profile: String = "save", filetype: String = ".sav") -> void:
	create_folder(resuser, folder)
	
	if profile == "":
		profile = "save"
	
	var thefile: FileAccess = FileAccess.open(resuser + folder + "/" + profile + filetype, FileAccess.WRITE)
	thefile.store_line(JSON.stringify(data))
	thefile.close()
	
	if print_in_terminal:
		print("Saved: " + str(data))


## Loads data from a specific folder. [br]
## [param resuser] The base path ("user://" or "res://"). [br]
## [param folder] The name of the folder to load the data from. [br]
## [param profile] The name of the profile (default is "save"). [br]
## [param filetype] The file extension (default is ".sav"). [br]
## @return Dictionary containing loaded data
func edit_data_in_folder(resuser: String, folder: String, profile: String = "save", filetype: String = ".sav") -> Dictionary:
	create_folder(resuser, folder)
	
	var data: Dictionary = {}
	if profile == "":
		profile = "save"
	
	var path: String = resuser + folder + "/" + profile + filetype
	if not FileAccess.file_exists(path):
		if print_in_terminal:
			print("The file doesn't exist yet, returning empty dictionary")
	else:
		var thefile: FileAccess = FileAccess.open(path, FileAccess.READ)
		if not thefile.eof_reached():
			var almost_data = JSON.parse_string(thefile.get_line())
			if almost_data != null:
				data = almost_data
	return data


## Removes a data file. [br]
## [param profile] The name of the profile (default is "save"). [br]
## [param filetype] The file extension (default is ".sav").
func remove_data(profile: String = "save", filetype: String = ".sav") -> void:
	var path: String = _res_user + folder_name + "/" + profile + filetype
	DirAccess.remove_absolute(path)
	if print_in_terminal:
		print(path + " removed")


## Removes a data file from a specific folder. [br]
## [param resuser] The base path ("user://" or "res://").[br]
## [param folder] The name of the folder to remove the data from. [br]
## [param profile] The name of the profile (default is "save"). [br]
## [param filetype] The file extension (default is ".sav").
func remove_data_in_folder(resuser: String, folder: String, profile: String = "save", filetype: String = ".sav") -> void:
	var path: String = resuser + folder + "/" + profile + filetype
	DirAccess.remove_absolute(path)
	if print_in_terminal:
		print(path + " removed")

func _exit_tree() -> void:
	# Ensure the thread is finished before exiting
	if _thread.is_alive():
		_thread.wait_to_finish()


## Takes a screenshot and saves it. [br]
## [param viewport] The viewport from which the screenshot is taken.
func snap_screenshot(viewport: Viewport) -> void:
	create_folder(_s_res_user, screenshot_folder_name)
	
	var dt: Dictionary = Time.get_datetime_dict_from_system()
	var timestamp: String = "%04d%02d%02d%02d%02d%02d" % [dt["year"], dt["month"], dt["day"], dt["hour"], dt["minute"], dt["second"]]
	
	var image: Image = viewport.get_texture().get_image()
	
	screenshot_save(image, _s_res_user + screenshot_folder_name + "/screenshot-" + timestamp + ".png")


## Saves a screenshot. [br]
## [param image] The image to be saved. [br]
## [param path] The path where the image will be saved.
func screenshot_save(image: Image, path: String) -> void:
	_mutex.lock()
	
	if _queue.size() < MAX_QUEUE_LENGTH:
		_queue.push_back({"image": image, "path": path})
	else:
		if screenshot_print_in_terminal:
			print("Screenshot queue overflow")
	
	if _queue.size() == 1:
		if _thread.is_alive():
			_thread.wait_to_finish()
		_thread.start(worker_function.bind(1))  # Pass the correct argument
	
	_mutex.unlock()


## Worker function for saving screenshots in a separate thread.
## [param _userdata] Unused parameter for thread callable.
func worker_function(_userdata) -> void:
	_mutex.try_lock()
	while not _queue.is_empty():
		var item: Dictionary = _queue.front()
		_mutex.unlock()
		
		call_deferred("_save_screenshot", item)  # Use call_deferred to call the function safely
		
		_mutex.lock()
		_queue.pop_front()
	
	_mutex.unlock()


## Actual function to save the screenshot called with call_deferred.
## [param item] Dictionary containing image and path.
func _save_screenshot(item: Dictionary) -> void:
	if screenshot_print_in_terminal:
		print("Saving screenshot to " + item["path"])
	
	item["image"].save_png(item["path"])
