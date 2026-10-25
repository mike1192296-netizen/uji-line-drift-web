extends SceneTree
const Vehicle = preload("res://scripts/vehicle.gd")
var failures = 0
func check(ok: bool,message: String) -> void:
	if ok: print("PASS: ",message)
	else:
		push_error(message)
		failures += 1
func touch(game,index,pos,pressed,canceled=false) -> void:
	var event = InputEventScreenTouch.new()
	event.index=index
	event.position=pos
	event.pressed=pressed
	event.canceled=canceled
	game._input(event)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.start()
	touch(game,0,Vector2(1120,570),true)
	touch(game,1,Vector2(100,600),true)
	touch(game,2,Vector2(790,600),true)
	game._physics_process(1.0/60)
	check(game.car.throttle==1 and game.car.steer_input<0 and game.car.handbrake==1 and game.car.brake==0,"three simultaneous gas/steer/handbrake fingers")
	touch(game,2,Vector2(790,600),false)
	game._physics_process(1.0/60)
	check(game.car.handbrake==0 and game.held("gas")==1,"handbrake independent release")
	touch(game,2,Vector2(790,600),true)
	touch(game,2,Vector2(790,600),true,true)
	check(game.held("handbrake")==0,"canceled handbrake contact cleared")
	touch(game,2,Vector2(790,600),true)
	game._physics_process(1.0/60)
	game.show_menu("pause")
	check(game.car.handbrake==0 and game.touch_points.is_empty(),"pause releases handbrake immediately")
	game.resume()
	game._physics_process(1.0/60)
	check(game.car.handbrake==0 and game.car.throttle==0,"resume has no stuck controls")
	touch(game,2,Vector2(790,600),true)
	game._physics_process(1.0/60)
	game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.car.handbrake==0 and game.touch_points.is_empty(),"focus loss clears held handbrake")
	game.resume()
	game.assist_level=3
	game.apply_settings()
	game.save()
	var cfg=ConfigFile.new()
	cfg.load("user://settings.cfg")
	check(cfg.get_value("settings","counter_assist_level",-1)==3,"assist strength saved")
	game.show_menu("settings")
	await process_frame
	check(game.menu.position.y+game.menu.size.y<=720,"settings fits landscape viewport")
	for id in range(8):
		var integrals=[]
		for strength in [0.0,0.20,0.40,0.65]:
			var car=Vehicle.new()
			car.vehicle_id=id
			car.track=game.track
			car.counter_assist=strength
			car.effects=false
			game.add_child(car)
			car.reset()
			car.velocity=Vector3(8,0,-18)
			car.yaw_rate=0.6
			var integral=0.0
			var peak=0.0
			for i in range(180):
				car.throttle=0.25
				car.step(1.0/60)
				integral+=absf(car.slip)/60.0
				peak=maxf(peak,absf(car.yaw_rate))
			check(car.position.is_finite() and peak<3.0,"bounded recovery yaw car %d strength %.2f"%[id,strength])
			integrals.append(integral)
			car.queue_free()
			await process_frame
		print("RECOVERY ",id," integrated slip OFF/WEAK/MED/STRONG=",integrals)
		check(integrals[3]<=integrals[0],"strong assist reduces recovery slip car %d"%id)
	# Mirror the initial slide for all cars to catch direction-specific instability.
	for id in range(8):
		var mirrored=Vehicle.new()
		mirrored.vehicle_id=id
		mirrored.track=game.track
		mirrored.counter_assist=0.65
		mirrored.effects=false
		game.add_child(mirrored)
		mirrored.reset()
		mirrored.velocity=Vector3(-8,0,-18)
		mirrored.yaw_rate=-0.6
		var peak=0.0
		for frame in range(180):
			mirrored.throttle=0.25
			mirrored.step(1.0/60)
			peak=maxf(peak,absf(mirrored.yaw_rate))
		check(mirrored.position.is_finite() and peak<3.0,"mirrored slide remains bounded car %d"%id)
		mirrored.queue_free()
		await process_frame
	game.change_selection(7,0)
	game.start()
	game.car.velocity=Vector3(0,0,-20)
	game.car.handbrake=1
	game.car.steer_input=0.6
	for i in range(30): game.car.step(1.0/60)
	check(game.car.speed<20 and game.car.steer_input==0.6,"handbrake slows car without replacing steering input")
	game.car.reset()
	check(game.car.handbrake==0,"restart clears handbrake state")
	game.queue_free()
	await process_frame
	print("ASSIST HANDBRAKE RESULT: ",failures," failures")
	quit(1 if failures else 0)
