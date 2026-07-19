extends Control

@export var world : Node3D

var opacity_tween : Tween

const SETTINGS_PATH := "user://settings.cfg"
var settings := ConfigFile.new()


func _ready():
	# One-time steps.
	# Pick a voice. Here, we arbitrarily pick the first English voice.
	var voices = DisplayServer.tts_get_voices_for_language("en")
	var voice_id = voices[0]
	
	PlayerData.init_player_data()
	
	load_settings()
	
	%IPLabel.text = "To play, go to: http://" + get_local_ip() + ":8000"
	
	
	
	# Käytetään isoja kirjaimia (HTTP)
	var url = "HTTP://" + str(get_local_ip()) + ":8000"

	# 1. Alphanumeric-tila on tässä lisäosassa numero 2
	$QRCode.mode = 2 

	# 2. Syötetään isoin kirjaimin oleva teksti sisään
	$QRCode.data = url

func change_to_menu():
	%QRCode.hide()
	#%QRCode.modulate.a = move_toward(%QRCode.modulate.a,0.0,0.1)
	if opacity_tween and opacity_tween.is_valid():
		opacity_tween.kill()
	
	%PlayerPositionContainer.accept_input = false
	
	%MenuButtonContainer.visible = true
	%GameLogo.visible = true
	
	opacity_tween = create_tween()
	opacity_tween.set_parallel(true)
	
	opacity_tween.tween_property(%MenuButtonContainer, "modulate:a", 1.0, 0.3)
	opacity_tween.tween_property(%SelectionButtonContainer, "modulate:a", 0.0, 0.3)
	opacity_tween.tween_property(%GameLogo, "modulate:a", 1.0, 0.3)
	
	opacity_tween.chain().tween_callback(func():
		%SelectionButtonContainer.visible = false
	)
	
	
	world.change_to_menu()

func change_to_selection():
	%QRCode.show()
	#%QRCode.modulate.a = move_toward(%QRCode.modulate.a,1.0,0.1)
	
	%PlayerPositionContainer.init_data()
	%PlayerPositionContainer.accept_input = true
	
	if opacity_tween and opacity_tween.is_valid():
		opacity_tween.kill()
	
	%SelectionButtonContainer.visible = true
	
	opacity_tween = create_tween()
	opacity_tween.set_parallel(true)

	opacity_tween.tween_property(%MenuButtonContainer, "modulate:a", 0.0, 0.3)
	opacity_tween.tween_property(%SelectionButtonContainer, "modulate:a", 1.0, 0.3)
	opacity_tween.tween_property(%GameLogo, "modulate:a", 0.0, 0.3)

	# runs AFTER tween finishes
	opacity_tween.chain().tween_callback(func():
		%MenuButtonContainer.visible = false
		%GameNameLabel.visible = false
		%GameLogo.visible
	)

	world.change_to_selection()


func _on_start_button_pressed():
	change_to_selection()
	%swoosh1.play()

func _on_start_match_button_pressed():
	var player_ids : Array = %PlayerPositionContainer.get_player_ids()
	var hats : Dictionary = %PlayerPositionContainer.get_hats()
	var names = {}
	
	for id in player_ids:
		names[id] = PlayerData.player_names[id]
	
	print(names)
	
	get_parent().start_match(player_ids,hats,names)
	self.queue_free()

func _on_back_button_pressed():
	change_to_menu()
	%swoosh2.play()

func _on_exit_button_pressed():
	get_tree().quit()


func _on_replays_button_pressed():
	get_parent().change_to_replays()
	self.queue_free()

func get_local_ip() -> String:
	var addresses = IP.get_local_addresses()
	print("🔍 Kaikki löydetyt verkkokorttien IP:t: ", addresses)
	
	# Vaihe 1: Yritetään ensin löytää perinteinen kotiverkon osoite
	for address in addresses:
		if address.begins_with("192.168."):
			return address
			
	# Vaihe 2: Jos 192.168 ei löydy, otetaan muut paikalliset osoitteet
	for address in addresses:
		if address.begins_with("10.") or address.begins_with("172.16."):
			return address
			
	return "127.0.0.1" # Fallback

func _on_fullscreen_button_toggled(toggled_on):
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	save_settings()

func _on_settings_button_pressed():
	%SettingsPanel.show()


func _on_render_slider_value_changed(value):
	get_viewport().scaling_3d_scale = value
	save_settings()



func set_vsync(enabled: bool) -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED
	)

func set_fps_limit(fps: int) -> void:
	Engine.max_fps = max(fps, 0) # 0 = Unlimited

func set_msaa(level: int) -> void:
	match level:
		0:
			get_viewport().msaa_3d = Viewport.MSAA_DISABLED
		2:
			get_viewport().msaa_3d = Viewport.MSAA_2X
		4:
			get_viewport().msaa_3d = Viewport.MSAA_4X
		8:
			get_viewport().msaa_3d = Viewport.MSAA_8X

func set_screen_space_aa(enabled: bool) -> void:
	get_viewport().screen_space_aa = (
		Viewport.SCREEN_SPACE_AA_FXAA
		if enabled
		else Viewport.SCREEN_SPACE_AA_DISABLED
	)

func set_taa(enabled: bool) -> void:
	get_viewport().use_taa = enabled

func set_debanding(enabled: bool) -> void:
	get_viewport().use_debanding = enabled

func set_fsr(enabled: bool) -> void:
	get_viewport().scaling_3d_mode = (
		Viewport.SCALING_3D_MODE_FSR2
		if enabled
		else Viewport.SCALING_3D_MODE_BILINEAR
	)

func set_fsr_sharpness(value: float) -> void:
	get_viewport().fsr_sharpness = clampf(value, 0.0, 2.0)


func _on_vsync_button_toggled(toggled_on):
	set_vsync(toggled_on)
	save_settings()

func _on_option_button_item_selected(index):
	set_msaa(index)
	save_settings()


func set_master_volume(value: float) -> void:
	var db := linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		db
	)


func _on_volume_slider_value_changed(value):
	set_master_volume(value)
	save_settings()

func save_settings() -> void:
	settings.set_value("graphics", "fullscreen", %FullscreenButton.button_pressed)
	settings.set_value("graphics", "render_scale", %RenderSlider.value)
	settings.set_value("graphics", "vsync", %VsyncButton.button_pressed)
	settings.set_value("graphics", "msaa", %OptionButton.selected)

	settings.set_value("audio", "master_volume", %VolumeSlider.value)

	settings.save(SETTINGS_PATH)


func load_settings() -> void:
	if settings.load(SETTINGS_PATH) != OK:
		# Defaults
		%FullscreenButton.set_pressed_no_signal(false)
		_on_fullscreen_button_toggled(false)

		%RenderSlider.value = 1.0
		get_viewport().scaling_3d_scale = 1.0

		%VsyncButton.set_pressed_no_signal(true)
		set_vsync(true)

		%OptionButton.select(2)
		set_msaa(4)

		%VolumeSlider.value = 100
		set_master_volume(100)

		save_settings()
		return

	var fullscreen: bool = settings.get_value("graphics", "fullscreen", false)
	%FullscreenButton.set_pressed_no_signal(fullscreen)
	_on_fullscreen_button_toggled(fullscreen)

	var render_scale: float = settings.get_value("graphics", "render_scale", 1.0)
	%RenderSlider.value = render_scale
	get_viewport().scaling_3d_scale = render_scale

	var vsync: bool = settings.get_value("graphics", "vsync", true)
	%VsyncButton.set_pressed_no_signal(vsync)
	set_vsync(vsync)

	var msaa_index: int = settings.get_value("graphics", "msaa", 2)
	%OptionButton.select(msaa_index)
	set_msaa([0, 2, 4, 8][msaa_index])

	var volume: float = settings.get_value("audio", "master_volume", 100.0)
	%VolumeSlider.value = volume
	set_master_volume(volume)
