extends SceneTree
var failures = 0
func check(ok: bool,message: String) -> void:
	if ok: print("PASS: ",message)
	else:
		push_error(message)
		failures+=1
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.effects=false
	var original_settings=game.config.encode_to_text()
	game.change_selection(7,3)
	check(game.track.total_length>10700 and game.track.total_length<11000,"OSM route uses real approximate 10.86km length, not 5km scaling")
	check(absf(game.track.points[0].y)<0.001 and absf(game.track.points[-1].y)<0.001,"unverified elevation explicitly flat preview")
	check((game.track.points[1]-game.track.points[0]).normalized().dot(Vector3.FORWARD)>0.999,"start direction aligned without changing steering")
	game.show_menu("garage")
	await process_frame
	check(game.menu.position.y+game.menu.size.y<=720,"preview disclaimer and garage fit viewport")
	for vehicle in range(8):
		game.change_selection(vehicle,3)
		game.assist_level=1
		game.start()
		var completed=false
		var contacts=0
		for i in range(100000):
			var car=game.car
			var target: Vector3=game.track.points[mini(car.nearest_index+5,game.track.points.size()-1)]
			var delta: Vector3=target-car.position
			delta.y=0
			var forward: Vector3=-car.global_basis.z
			var angle=forward.signed_angle_to(delta.normalized(),Vector3.UP)
			car.steer_input=clampf(-angle*2.5,-1,1)
			car.throttle=1.0 if car.speed<14.0 else 0.0
			car.brake=0.4 if car.speed>16 else 0.0
			car.step(1.0/60)
			if car.hit: contacts+=1
			if not car.position.is_finite(): break
			if car.progress>game.track.total_length-8:
				completed=true
				print("REAL ROUTE COMPLETE car=",vehicle," seconds=",float(i)/60," contacts=",contacts)
				break
		check(completed,"OSM preview finish car %d"%vehicle)
		await process_frame
	game.change_selection(0,0)
	game.config.clear()
	game.config.parse(original_settings)
	game.config.save("user://settings.cfg")
	game.queue_free()
	await process_frame
	print("REAL ROUTE RESULT: ",failures," failures")
	quit(1 if failures else 0)
