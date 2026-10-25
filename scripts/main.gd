extends Node3D
const Track = preload("res://scripts/track.gd")
const Vehicle = preload("res://scripts/vehicle.gd")
const Garage = preload("res://scripts/garage.gd")
const RunResult = preload("res://scripts/run_result.gd")
var result = RunResult.new()
var best_time = -1.0
var new_time_record = false
var time_label: Label
var penalty_label: Label
var selected_vehicle = 0
var selected_course = 0
var track: Node3D
var car: Node3D
var camera: Camera3D
var driver_view = true
var view_button: Button
var cockpit: Node3D
var steering_wheel: Node3D
var running = false
var score = 0.0
var best = 0
var combo = 1.0
var hud: Label
var car_name_label: Label
var rpm_label: Label
var speed_label: Label
var status: Label
var menu: PanelContainer
var menu_box: VBoxContainer
var controls: Control
var touch_points: Dictionary = {}
var mouse_down = false
var zones: Dictionary = {}
var mode = "title"
var config = ConfigFile.new()
var sensitivity = 1.0
var assist_level = 1
const ASSIST_NAMES = ["OFF", "WEAK", "MEDIUM", "STRONG"]
const ASSIST_STRENGTHS = [0.0,0.20,0.40,0.65]
var effects = true
var sound = true
var camera_started = false
var shadows = true
var startup_complete = false
var selection_loading = false
var loading_layer: CanvasLayer
var loading_label: Label
var progressive_loading = OS.has_feature("web")
var sunlight: DirectionalLight3D

func _ready() -> void:
	set_physics_process(false)
	if progressive_loading:
		show_loading("PREPARING COURSE... 0%")
		await get_tree().process_frame
		await get_tree().process_frame
	config.load("user://settings.cfg")
	selected_vehicle = clampi(config.get_value("selection","vehicle",0),0,Garage.NAMES.size()-1)
	selected_course = clampi(config.get_value("selection","course",0),0,Track.NAMES.size()-1)
	load_best()
	sensitivity = config.get_value("settings","sensitivity",1.0)
	assist_level = clampi(config.get_value("settings","counter_assist_level",1),0,3)
	effects = config.get_value("settings","effects",true)
	sound = config.get_value("settings","sound",true)
	shadows = config.get_value("settings","shadows",not OS.has_feature("web"))
	driver_view = config.get_value("settings","driver_view",true)
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.22,0.39,0.58)
	sky_mat.sky_horizon_color = Color(0.74,0.79,0.80)
	sky_mat.ground_bottom_color = Color(0.13,0.16,0.12)
	sky_mat.ground_horizon_color = Color(0.66,0.72,0.72)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.60,0.69,0.73)
	env.fog_density = 0.0007
	environment.environment = env
	add_child(environment)
	var sun = DirectionalLight3D.new()
	sunlight = sun
	sun.rotation_degrees = Vector3(-48,-30,0)
	sun.light_energy = 1.05
	sun.light_color = Color(1.0,0.94,0.82)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 100
	add_child(sun)
	track = Track.new()
	track.course_id = selected_course
	track.progressive_build = progressive_loading
	track.build_progress.connect(update_loading_progress)
	add_child(track)
	if not track.build_complete:
		await track.build_finished
	if progressive_loading:
		loading_label.text = "PREPARING CAR..."
		await get_tree().process_frame
	car = Vehicle.new()
	car.vehicle_id = selected_vehicle
	car.track = track
	add_child(car)
	car.reset()
	camera = Camera3D.new()
	add_child(camera)
	camera.far = 1600
	camera.current = true
	camera.near = 0.05
	build_cockpit()
	build_ui()
	update_camera(0,true)
	apply_settings()
	show_menu("title")
	startup_complete = true
	hide_loading()
	set_physics_process(true)

func show_loading(message: String) -> void:
	if not is_instance_valid(loading_layer):
		loading_layer = CanvasLayer.new()
		loading_layer.layer = 100
		add_child(loading_layer)
		var panel = ColorRect.new()
		panel.color = Color(0.04,0.07,0.09)
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		loading_layer.add_child(panel)
		loading_label = Label.new()
		loading_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		loading_label.add_theme_font_size_override("font_size",28)
		loading_label.add_theme_font_override("font",load("res://fonts/UjiSans.ttf"))
		panel.add_child(loading_label)
	loading_layer.show()
	loading_label.text = message

func update_loading_progress(value: float) -> void:
	if is_instance_valid(loading_label):
		loading_label.text = "PREPARING COURSE... %d%%" % roundi(value*100)

func hide_loading() -> void:
	if is_instance_valid(loading_layer):
		loading_layer.hide()

func label(text: String, size: int, parent: Node) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size",size)
	parent.add_child(l)
	return l

func button(text: String, callback: Callable, parent: Node) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(300,54)
	b.add_theme_font_size_override("font_size",24)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func build_ui() -> void:
	var layer = CanvasLayer.new()
	add_child(layer)
	var root = Control.new()
	var theme = Theme.new()
	theme.default_font = load("res://fonts/UjiSans.ttf")
	root.theme = theme
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	hud = label("",25,root)
	hud.position = Vector2(30,24)
	speed_label = label("",44,root)
	speed_label.position = Vector2(30,65)
	status = label("",25,root)
	status.position = Vector2(470,35)
	time_label = label("",23,root)
	time_label.position = Vector2(30,125)
	car_name_label = label("CAR: "+Garage.NAMES[selected_vehicle]+"  /  ASSIST "+ASSIST_NAMES[assist_level],22,root)
	car_name_label.position = Vector2(30,242)
	car_name_label.add_theme_color_override("font_color",Color(0.85,1.0,0.97))
	car_name_label.add_theme_color_override("font_shadow_color",Color(0,0,0,0.95))
	car_name_label.add_theme_constant_override("shadow_offset_x",2)
	car_name_label.add_theme_constant_override("shadow_offset_y",2)
	car_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rpm_label = label("",22,root)
	rpm_label.position = Vector2(30,205)
	penalty_label = label("",25,root)
	penalty_label.position = Vector2(470,78)
	penalty_label.modulate = Color(1.0,0.52,0.20)
	var pause = button("II",func():
		if running: show_menu("pause"),root)
	pause.custom_minimum_size = Vector2(70,55)
	pause.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pause.position = Vector2(1170,20)
	pause.size = Vector2(80,55)
	view_button = button("",toggle_view,root)
	view_button.custom_minimum_size = Vector2(180,55)
	view_button.position = Vector2(975,20)
	view_button.size = Vector2(180,55)
	view_button.add_theme_font_size_override("font_size",20)
	controls = Control.new()
	root.add_child(controls)
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for item in [["left",Rect2(25,530,150,155),"◀"],["right",Rect2(195,530,150,155),"▶"],["handbrake",Rect2(720,545,145,140),"H-BRAKE"],["brake",Rect2(885,545,150,140),"BRAKE"],["gas",Rect2(1055,475,195,210),"ACCEL"]]:
		zones[item[0]] = item[1]
		var panel = Panel.new()
		controls.add_child(panel)
		panel.position = item[1].position
		panel.size = item[1].size
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.04,0.10,0.12,0.7)
		style.border_color = Color(0.3,0.75,0.71,0.8)
		style.set_border_width_all(2)
		style.set_corner_radius_all(22)
		panel.add_theme_stylebox_override("panel",style)
		var l = label(item[2],28,panel)
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu = PanelContainer.new()
	root.add_child(menu)
	menu.position = Vector2(390,105)
	menu.size = Vector2(500,500)
	menu_box = VBoxContainer.new()
	menu_box.add_theme_constant_override("separation",12)
	menu.add_child(menu_box)

func show_menu(which: String) -> void:
	if selection_loading: return
	running = false
	mode = which
	menu_box.add_theme_constant_override("separation",8 if which in ["settings","garage"] else 12)
	touch_points.clear()
	mouse_down = false
	car.handbrake = 0
	car.smoke.emitting = false
	car.engine.stream_paused = true
	car.squeal.stream_paused = true
	save()
	menu.show()
	controls.hide()
	time_label.hide()
	rpm_label.hide()
	penalty_label.hide()
	for child in menu_box.get_children():
		menu_box.remove_child(child)
		child.queue_free()
	label("宇治川ライン DRIFT",34,menu_box)
	label("V0.4.3  /  DOWNHILL SESSION",19,menu_box)
	label("BEST SCORE %06d  /  TIME %s" % [best,RunResult.clock(best_time)],19,menu_box)
	if which == "garage":
		button("CAR: "+Garage.NAMES[selected_vehicle]+"  /  ASSIST "+ASSIST_NAMES[assist_level],func():
			await change_selection((selected_vehicle+1)%Garage.NAMES.size(),selected_course)
			show_menu("garage"),menu_box)
		label(Garage.NOTES[selected_vehicle],17,menu_box)
		var spec = car.drivetrain.spec
		label("%d PS / %d Nm / %d kg\n%s" % [spec.ps,spec.nm,spec.mass,spec.name],18,menu_box)
		button("COURSE: "+Track.NAMES[selected_course],func():
			await change_selection(selected_vehicle,(selected_course+1)%Track.NAMES.size())
			show_menu("garage"),menu_box)
		label("%.2f km / tap to change"%(track.total_length/1000.0),20,menu_box)
		if selected_course==3:
			label("OSM curve preview / elevation unverified\nWidth and scenery are placeholders",16,menu_box)
			var credit = LinkButton.new()
			credit.text = "© OpenStreetMap contributors / ODbL"
			credit.uri = "https://www.openstreetmap.org/copyright"
			credit.add_theme_font_size_override("font_size",16)
			menu_box.add_child(credit)
		button("DRIVE",start,menu_box)
		button("BACK",func(): show_menu("title"),menu_box)
	elif which == "settings":
		var s = HSlider.new()
		s.min_value = 0.6
		s.max_value = 1.3
		s.step = 0.05
		s.value = sensitivity
		label("Steering sensitivity",22,menu_box)
		menu_box.add_child(s)
		s.value_changed.connect(func(v): sensitivity=v)
		button("Counter assist: "+ASSIST_NAMES[assist_level],func():
			assist_level = (assist_level+1)%ASSIST_NAMES.size()
			apply_settings()
			show_menu("settings"),menu_box)
		button("Smoke / skid marks: "+str(effects),func():
			effects = not effects
			show_menu("settings"),menu_box)
		button("Sound: "+str(sound),func():
			sound = not sound
			apply_settings()
			show_menu("settings"),menu_box)
		button("Shadows: "+str(shadows),func():
			shadows = not shadows
			apply_settings()
			show_menu("settings"),menu_box)
		button("BACK",func():
			apply_settings()
			show_menu("finish" if result.finished else ("pause" if camera_started else "title")),menu_box)
	else:
		if which == "finish":
			label("FINISH  /  SCORE %06d\nRUN  %s\nCONTACTS  %d  /  PENALTY +%.1fs\nFINAL  %s%s" % [int(score),RunResult.clock(result.elapsed),result.contacts,result.penalty,RunResult.clock(result.total()),"  NEW BEST!" if new_time_record else ""],23,menu_box)
		if which == "pause": button("RESUME",resume,menu_box)
		button("START" if which == "title" else "RESTART",start,menu_box)
		button("CAR / COURSE",func(): show_menu("garage"),menu_box)
		button("SETTINGS",func(): show_menu("settings"),menu_box)
		if which != "finish": label("Left / Right + ACCEL / BRAKE\nNo drift button. Brake, turn, then accelerate.\nKeyboard: arrows / WASD  •  Space handbrake
Counter assist in SETTINGS  •  Esc pause",18,menu_box)

	if which in ["settings","garage"]:
		for child in menu_box.get_children():
			if child is Button:
				child.custom_minimum_size.y = 40
				child.add_theme_font_size_override("font_size",20)

func start() -> void:
	if selection_loading or not startup_complete: return
	result.reset()
	new_time_record = false
	car.reset()
	score = 0
	combo = 1
	camera_started = true
	update_camera(0,true)
	resume()

func resume() -> void:
	if selection_loading or not startup_complete: return
	if result.finished:
		show_menu("finish")
		return
	apply_settings()
	menu.hide()
	controls.show()
	time_label.show()
	rpm_label.show()
	penalty_label.show()
	running = true
	car.engine.stream_paused = false
	car.squeal.stream_paused = false

func apply_settings() -> void:
	car.counter_assist = ASSIST_STRENGTHS[assist_level]
	car_name_label.text = "CAR: "+Garage.NAMES[selected_vehicle]+"  /  ASSIST "+ASSIST_NAMES[assist_level]
	car.effects = effects
	sunlight.shadow_enabled = shadows
	AudioServer.set_bus_mute(0,not sound)

func save() -> void:
	best = maxi(best,int(score))
	config.set_value("records",record_key(),best)
	if selected_vehicle==0 and selected_course==0: config.set_value("game","best",best)
	config.set_value("selection","vehicle",selected_vehicle)
	config.set_value("selection","course",selected_course)
	config.set_value("settings","sensitivity",sensitivity)
	config.set_value("settings","counter_assist_level",assist_level)
	config.set_value("settings","effects",effects)
	config.set_value("settings","sound",sound)
	config.set_value("settings","shadows",shadows)
	config.set_value("settings","driver_view",driver_view)
	config.save("user://settings.cfg")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and running:
		show_menu("pause")

func _input(event: InputEvent) -> void:
	if selection_loading: return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if running: show_menu("pause")
		elif mode == "pause": resume()
	if not running: return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C:
		toggle_view()
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled: touch_points[event.index] = event.position
		else: touch_points.erase(event.index)
	elif event is InputEventScreenDrag:
		touch_points[event.index] = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_down = event.pressed
		if mouse_down: touch_points[-1] = event.position
		else: touch_points.erase(-1)
	elif event is InputEventMouseMotion and mouse_down:
		touch_points[-1] = event.position

func held(action: String) -> float:
	for p in touch_points.values():
		if zones[action].has_point(p): return 1.0
	return 0.0

func _physics_process(dt: float) -> void:
	if not startup_complete: return
	if running:
		car.throttle = maxf(held("gas"),float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		car.handbrake = maxf(held("handbrake"),float(Input.is_physical_key_pressed(KEY_SPACE)))
		car.brake = maxf(held("brake"),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)))
		var left = maxf(held("left"),float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)))
		var right = maxf(held("right"),float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)))
		car.steer_input = (right-left)*sensitivity
		car.step(dt)
		result.advance(dt,car.hit)
		if car.hit:
			combo = 1
		elif car.speed>7 and absf(car.slip)>0.12:
			combo = minf(combo+dt*0.2,5)
			score += car.speed*absf(car.slip)*dt*combo*15
		else: combo = maxf(1,combo-dt*0.4)
		if car.progress>track.total_length-8: finish_run()
	update_camera(dt)
	hud.text = "SCORE %06d   ×%.1f   BEST %06d" % [int(score),combo,best]
	time_label.text = "TIME %s   CONTACTS %d   +%.1fs\nTOTAL %s   BEST %s" % [RunResult.clock(result.elapsed),result.contacts,result.penalty,RunResult.clock(result.total()),RunResult.clock(best_time)]
	penalty_label.text = "CONTACT +3.0s" if result.notice>0 else ""
	rpm_label.text = "%s   %04d RPM" % [car.drivetrain.gear_text(),int(car.drivetrain.rpm)]
	speed_label.text = "%03d km/h" % int(car.speed*3.6)
	status.text = "DRIFT  %.0f°" % absf(rad_to_deg(car.slip)) if car.speed>7 and absf(car.slip)>0.12 else ("OSM PREVIEW  %d / %d m" if selected_course==3 else "DOWNHILL  %d / %d m") % [int(car.progress),roundi(track.total_length)]

func record_key() -> String:
	return "%d_%d" % [selected_course,selected_vehicle]

func load_best() -> void:
	var legacy = config.get_value("game","best",0) if selected_course==0 and selected_vehicle==0 else 0
	best = config.get_value("records",record_key(),legacy)
	best_time = config.get_value("times",record_key(),-1.0)

func change_selection(vehicle_id: int,course_id: int) -> void:
	if selection_loading: return
	selection_loading = true
	save()
	result.reset()
	new_time_record = false
	running = false
	touch_points.clear()
	mouse_down = false
	score = 0
	combo = 1
	if selected_course!=course_id:
		set_physics_process(false)
		if progressive_loading:
			show_loading("PREPARING COURSE... 0%")
			await get_tree().process_frame
		remove_child(track)
		track.free()
		track = Track.new()
		track.course_id = course_id
		track.progressive_build = progressive_loading
		track.build_progress.connect(update_loading_progress)
		add_child(track)
		if not track.build_complete:
			await track.build_finished
		car.track = track
	selected_course = course_id
	selected_vehicle = vehicle_id
	car_name_label.text = "CAR: "+Garage.NAMES[selected_vehicle]+"  /  ASSIST "+ASSIST_NAMES[assist_level]
	car.set_vehicle(vehicle_id)
	camera_started = false
	update_camera(0,true)
	load_best()
	save()
	selection_loading = false
	hide_loading()
	set_physics_process(true)

func build_cockpit() -> void:
	# Lightweight generic right-hand-drive dashboard. Exterior glass is opaque,
	# so hide the exterior model in driver view and use this dedicated interior.
	const G = preload("res://scripts/geometry.gd")
	cockpit = Node3D.new()
	camera.add_child(cockpit)
	var dash_mat = G.material(Color(0.024,0.028,0.030))
	G.rounded_box(cockpit,Vector3(-0.30,-0.49,-0.70),Vector3(1.65,0.20,0.42),dash_mat)
	G.rounded_box(cockpit,Vector3(0,-0.39,-0.80),Vector3(0.36,0.10,0.16),dash_mat)
	steering_wheel = Node3D.new()
	cockpit.add_child(steering_wheel)
	steering_wheel.position = Vector3(0,-0.40,-0.56)
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.142
	torus.outer_radius = 0.166
	torus.rings = 24
	torus.ring_segments = 8
	ring.mesh = torus
	ring.material_override = dash_mat
	ring.rotation.x = PI/2
	steering_wheel.add_child(ring)
	for end in [Vector3(-0.145,0,0),Vector3(0.145,0,0),Vector3(0,-0.145,0)]:
		G.beam(steering_wheel,Vector3.ZERO,end,0.023,0.022,dash_mat)
	G.rounded_box(steering_wheel,Vector3.ZERO,Vector3(0.10,0.07,0.035),dash_mat)
	for node in cockpit.find_children("*","GeometryInstance3D",true,false):
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func toggle_view() -> void:
	driver_view = not driver_view
	update_camera(0,true)
	save()

func driver_eye() -> Vector3:
	return car.position+car.global_basis*Vector3(0.32,[1.18,1.16,1.57,1.03,1.43,1.62,1.02,1.22][selected_vehicle],-0.12)

func update_camera(dt: float,snap: bool = false) -> void:
	car.model.visible = not driver_view
	cockpit.visible = driver_view
	view_button.text = "VIEW: DRIVER" if driver_view else "VIEW: CHASE"
	var forward = -car.global_basis.z
	if driver_view:
		# No delayed chase interpolation, speed zoom, roll or velocity steering.
		camera.position = driver_eye()
		var road = track.nearest(car.position,car.nearest_index)
		var grade = road.direction.y/maxf(Vector2(road.direction.x,road.direction.z).length(),0.1)
		camera.look_at(camera.position+forward+Vector3.UP*grade)
		camera.fov = 78
		steering_wheel.rotation.z = -car.steering*1.3
	else:
		var travel = car.velocity.normalized() if car.speed>3 else forward
		var desired = car.position-forward*7-travel*2.5+Vector3.UP*4.2
		camera.position = desired if snap else camera.position.lerp(desired,1-exp(-dt*5))
		camera.look_at(car.position+Vector3.UP+forward*3)
		camera.fov = 67+car.speed*0.24 if snap else lerpf(camera.fov,67+car.speed*0.24,dt*3)

func finish_run() -> void:
	if result.finished or not running: return
	result.finished = true
	new_time_record = best_time<0 or result.total()<best_time
	if new_time_record:
		best_time = result.total()
		config.set_value("times",record_key(),best_time)
	show_menu("finish")
