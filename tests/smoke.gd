extends SceneTree
var failures = 0
func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		failures += 1
	else: print("PASS: ",message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	check(absf(game.track.total_length-5000)<0.1,"downhill course is 5000m")
	game.change_selection(0,0)
	game.start()
	var touch = InputEventScreenTouch.new()
	touch.index = 0
	touch.position = Vector2(1120,570)
	touch.pressed = true
	game._input(touch)
	var left = InputEventScreenTouch.new()
	left.index = 1
	left.position = Vector2(100,600)
	left.pressed = true
	game._input(left)
	check(game.held("gas")==1 and game.held("left")==1,"two-finger accelerator + steering")
	touch.pressed = false
	game._input(touch)
	check(game.held("gas")==0 and game.held("left")==1,"independent finger release")
	game.show_menu("pause")
	check(game.touch_points.is_empty() and not game.running,"pause clears held controls")
	game.start()
	game.car.throttle = 1.0
	for i in range(180): game.car.step(1.0/60)
	check(game.car.speed>12,"manual throttle accelerates")
	var before: float = game.car.speed
	game.car.throttle = 0
	game.car.brake = 1
	for i in range(120): game.car.step(1.0/60)
	check(game.car.speed<before*0.3,"brake reduces speed")
	game.car.reset()
	game.car.throttle = 1
	game.car.brake = 0
	var max_slip = 0.0
	for i in range(300):
		game.car.steer_input = 0.7 if i>100 else 0.0
		game.car.step(1.0/60)
		max_slip = maxf(max_slip,absf(game.car.slip))
		check_finite(game.car.position)
	check(max_slip>0.12,"steering and throttle produce drift without drift button")
	game.score = 1234
	game.save()
	var cfg = ConfigFile.new()
	cfg.load("user://settings.cfg")
	check(cfg.get_value("game","best",0)>=1234,"best score persisted")
	game.start()
	check(game.score==0 and game.car.velocity==Vector3.ZERO,"restart resets run")
	var original_best: int = game.best
	game.change_selection(1,1)
	check(game.score==0 and game.touch_points.is_empty(),"selection clears score and inputs")
	var selected_best: int = game.best
	game.score = selected_best+17
	game.save()
	game.change_selection(2,2)
	check(game.car.vehicle_id==2 and game.track.course_id==2,"vehicle and course switch together")
	game.change_selection(1,1)
	check(game.best==selected_best+17,"combination score restored")
	game.change_selection(0,0)
	check(game.best==original_best,"other combination does not overwrite sedan best")
	game.queue_free()
	await process_frame
	print("SMOKE RESULT: ",failures," failures")
	quit(1 if failures else 0)

func check_finite(v: Vector3) -> void:
	if not v.is_finite():
		failures += 1
