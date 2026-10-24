extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func snap(name: String) -> void:
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+".png")
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.driver_view = false
	game.update_camera(0,true)
	await create_timer(1.0).timeout
	game.start()
	await create_timer(1.0).timeout
	await snap("gameplay")
	game.set_physics_process(false)
	game.camera.position = game.car.position+Vector3(4.2,2.0,-6.0)
	game.camera.look_at(game.car.position+Vector3.UP*0.8)
	game.camera.fov = 43
	await snap("car-detail")
	game.running = false
	for meters in [830,1800,2900,3700,4800]:
		var idx = 1
		while game.track.lengths[idx]<meters: idx+=1
		game.car.position = game.track.points[idx]+Vector3.UP*0.06
		game.car.look_at(game.track.points[idx+1]+Vector3.UP*0.06)
		game.car.rotation.x = 0
		game.car.progress = game.track.lengths[idx]
		for i in range(120): game._physics_process(1.0/60)
		await snap("course-%d"%meters)
	game.show_menu("title")
	await snap("title")
	game.show_menu("settings")
	await snap("settings")
	game.queue_free()
	await process_frame
	quit()
