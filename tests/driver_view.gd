extends SceneTree
var failures = 0
func check(ok: bool,message: String) -> void:
	if ok: print("PASS: ",message)
	else:
		push_error(message)
		failures += 1
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	for id in range(preload("res://scripts/garage.gd").NAMES.size()):
		game.change_selection(id,0)
		game.start()
		game.driver_view = true
		game.car.rotation.y = 0.65
		game.camera.position += Vector3(25,5,25)
		game.update_camera(1.0/60)
		check(game.camera.position.distance_to(game.driver_eye())<0.001,"driver eye follows immediately, car %d"%id)
		var look: Vector3 = -game.camera.global_basis.z
		look.y = 0
		check(look.normalized().dot(-game.car.global_basis.z)>0.999,"driver heading follows immediately, car %d"%id)
		check(not game.car.model.visible and game.cockpit.visible,"unobstructed driver view, car %d"%id)
		var before: Vector3 = game.car.position
		game.touch_points[1] = Vector2(1120,570)
		game.touch_points[2] = Vector2(100,600)
		game.toggle_view()
		check(game.car.position==before and game.held("gas")==1 and game.held("left")==1,"view switch preserves driving controls")
		check(game.car.model.visible and not game.cockpit.visible,"chase restores exterior")
		game.toggle_view()
		check(game.camera.fov==78,"driver FOV fixed")
	var cfg = ConfigFile.new()
	cfg.load("user://settings.cfg")
	check(cfg.get_value("settings","driver_view",false),"view preference saved")
	game.change_selection(0,0)
	if DisplayServer.get_name()!="headless":
		var preview = game
		preview.set_physics_process(false)
		for id in range(preload("res://scripts/garage.gd").NAMES.size()):
			preview.change_selection(id,0)
			preview.start()
			preview.driver_view = true
			preview.update_camera(0,true)
			preview._physics_process(0)
			await create_timer(0.3).timeout
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://build/driver-%d.png"%id)
	game.queue_free()
	for i in range(3): await process_frame
	print("DRIVER VIEW RESULT: ",failures," failures")
	quit(1 if failures else 0)
