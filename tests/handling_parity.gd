extends SceneTree
const Legacy = preload("res://tests/reference/vehicle.gd")
const Current = preload("res://scripts/vehicle.gd")
const Track = preload("res://scripts/track.gd")
var failures = 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world = Node3D.new()
	root.add_child(world)
	var track = Track.new()
	world.add_child(track)
	for id in range(7):
		var a = Legacy.new()
		var b = Current.new()
		for car in [a,b]:
			car.vehicle_id = id
			car.track = track
			car.effects = false
			world.add_child(car)
			car.reset()
		for frame in range(1800):
			for car in [a,b]:
				car.throttle = 1.0 if frame%480<360 else 0.0
				car.brake = 0.7 if frame%480>=420 else 0.0
				car.steer_input = sin(frame/100.0)*0.45 if frame>180 else 0.0
				car.step(1.0/60)
			if a.position!=b.position or a.velocity!=b.velocity or a.rotation!=b.rotation or a.drivetrain.rpm!=b.drivetrain.rpm or a.drivetrain.gear!=b.drivetrain.gear:
				push_error("Handling parity failed car %d frame %d"%[id,frame])
				failures += 1
				break
		print("PARITY car ",id," checked 1800 deterministic throttle/brake/steer frames")
		a.queue_free()
		b.queue_free()
		await process_frame
	world.queue_free()
	await process_frame
	print("HANDLING PARITY RESULT: ",failures," failures")
	quit(1 if failures else 0)
