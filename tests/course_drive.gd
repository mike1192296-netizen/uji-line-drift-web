extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.effects = false
	for course in range(3):
		for vehicle in range(preload("res://scripts/garage.gd").NAMES.size()):
			game.change_selection(vehicle,course)
			game.start()
			assert(absf(game.track.total_length-5000)<0.1)
			var completed = false
			var collisions = 0
			for i in range(36000):
				var car = game.car
				var target: Vector3 = game.track.points[mini(car.nearest_index+5,game.track.points.size()-1)]
				var delta: Vector3 = target-car.position
				delta.y = 0
				var forward: Vector3 = -car.global_basis.z
				var angle = forward.signed_angle_to(delta.normalized(),Vector3.UP)
				car.steer_input = clampf(-angle*2.5,-1,1)
				car.throttle = 1.0 if car.speed<14.0 else 0.0
				car.brake = 0.4 if car.speed>16 else 0.0
				car.step(1.0/60)
				if car.hit: collisions+=1
				if not car.position.is_finite():
					push_error("non-finite vehicle position")
					quit(1)
					return
				if car.progress>game.track.total_length-8:
					print("COURSE COMPLETE: course=",course," car=",vehicle," time=",float(i)/60,"s contacts=",collisions)
					completed = true
					break
			if not completed:
				push_error("course drive timed out")
				quit(1)
				return
			await process_frame
	game.change_selection(0,0)
	game.queue_free()
	await process_frame
	quit()
