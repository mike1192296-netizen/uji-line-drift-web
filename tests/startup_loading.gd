extends SceneTree
var failures = 0
func check(ok: bool, text: String) -> void:
	if not ok:
		failures += 1
		push_error(text)
	else: print("PASS: ",text)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	game.progressive_loading = true
	root.add_child(game)
	check(not game.startup_complete,"startup yields before world generation")
	check(game.loading_layer.visible,"visible loading overlay exists before world generation")
	var frames = 0
	while not game.startup_complete and frames<500:
		await process_frame
		frames += 1
	check(game.startup_complete,"progressive startup reaches title")
	check(frames>10,"world construction yields multiple frames")
	check(game.track.build_complete and not game.loading_layer.visible,"completed world hides loader")
	game.set_physics_process(false)
	await game.change_selection(0,0)
	var previous_record = game.config.get_value("records",game.record_key(),-1)
	game.change_selection(7,3)
	check(game.selection_loading,"course transition sets reentry guard")
	game.start()
	game.resume()
	check(not game.running,"keyboard start and resume blocked during transition")
	await game.change_selection(0,1)
	while game.selection_loading:
		await process_frame
	check(game.selected_course==3,"repeated selection ignored during build")
	check(game.track.build_complete and game.track.course_id==3,"OSM route async selection completes")
	check(game.car.vehicle_id==7 and not game.loading_layer.visible,"car selection and loader finish together")
	game.start()
	check(game.running,"start available after async route load")
	game.show_menu("pause")
	await game.change_selection(0,0)
	check(game.track.build_complete and game.selected_course==0,"returning to old route completes")
	check(game.config.get_value("records",game.record_key(),-1)==previous_record,"saved record retained")
	print("STARTUP LOADING RESULT: ",failures," failures; initial frames ",frames)
	game.queue_free()
	await process_frame
	quit(failures)
