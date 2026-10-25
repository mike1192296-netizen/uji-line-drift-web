extends SceneTree
const Garage = preload("res://scripts/garage.gd")
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
	check(Garage.NAMES.size()==8,"eight selectable cars")
	for id in range(8):
		game.change_selection(id,0)
		check(game.car_name_label.text.begins_with("CAR: "+Garage.NAMES[id]),"HUD updates on selection %d"%id)
		for driver in [true,false]:
			game.driver_view = driver
			game.start()
			check(game.car_name_label.is_visible_in_tree(),"car name visible in both views %d"%id)
			check(game.car_name_label.mouse_filter==Control.MOUSE_FILTER_IGNORE,"name cannot intercept touch")
			check(not game.car_name_label.get_rect().intersects(game.time_label.get_rect()) and not game.car_name_label.get_rect().intersects(game.rpm_label.get_rect()),"car name does not overlap time or RPM")
			game._physics_process(0)
			check(game.car_name_label.text.begins_with("CAR: "+Garage.NAMES[id]),"name retained on restart")
	game.change_selection(7,0)
	check(game.car.model.name=="DJDemio13SInspired","dedicated DJ mesh")
	check(game.car.model.get_meta("wheels").size()==4,"four animated DJ wheels")
	check(game.car.drivetrain.spec.ff and game.car.drivetrain.spec.gears.size()==6,"DJ FF six-speed powertrain")
	game.car.throttle=1
	for frame in range(300): game.car.step(1.0/60)
	check(game.car.speed>5 and game.car.position.is_finite(),"DJ accelerates without invalid state")
	game.queue_free()
	await process_frame
	print("DEMIO HUD RESULT: ",failures," failures")
	quit(1 if failures else 0)
