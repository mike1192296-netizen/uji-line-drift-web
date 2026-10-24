extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.driver_view = false
	game.update_camera(0,true)
	await create_timer(0.5).timeout
	game.set_physics_process(false)
	game.menu.hide()
	game.controls.hide()
	for id in range(preload("res://scripts/garage.gd").NAMES.size()):
		game.change_selection(id,0)
		game.camera.position = game.car.position+Vector3(4.0,2.1,-6.0)
		game.camera.look_at(game.car.position+Vector3.UP*0.95)
		game.camera.fov = 40
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/car-%d.png"%id)
	game.show_menu("garage")
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/garage.png")
	game.queue_free()
	await process_frame
	quit()
