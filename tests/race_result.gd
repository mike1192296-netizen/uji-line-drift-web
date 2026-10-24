extends SceneTree
const Result = preload("res://scripts/run_result.gd")
var failures = 0
func check(ok: bool,message: String) -> void:
	if ok: print("PASS: ",message)
	else:
		push_error(message)
		failures += 1
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var run = Result.new()
	run.advance(1.0,true)
	for i in range(120): run.advance(1.0/60,true)
	check(run.contacts==1 and run.penalty==3,"continuous contact counted once")
	run.advance(0.1,false)
	run.advance(0.1,true)
	check(run.contacts==1,"brief contact jitter not double counted")
	run.advance(0.61,false)
	run.advance(0.1,true)
	check(run.contacts==2 and run.penalty==6,"separate contact adds three seconds")
	run.finished = true
	var final: float = run.total()
	run.advance(20,true)
	check(run.total()==final,"finished result frozen")
	run.reset()
	check(run.total()==0 and run.contacts==0 and not run.touching,"reset clears timing and contact latch")
	check(Result.clock(65.23)=="01:05.23" and Result.clock(-1)=="--:--.--","minute and hundredth formatting")
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	var original_config: String = game.config.encode_to_text()
	game.change_selection(3,2)
	if game.config.has_section_key("times",game.record_key()): game.config.erase_section_key("times",game.record_key())
	game.load_best()
	game.start()
	for i in range(60): game._physics_process(1.0/60)
	check(absf(game.result.elapsed-1)<0.001,"active race clock runs")
	game.show_menu("pause")
	var paused: float = game.result.elapsed
	for i in range(60): game._physics_process(1.0/60)
	check(game.result.elapsed==paused and game.best_time<0,"pause freezes clock and does not record unfinished race")
	game.resume()
	# Exercise the actual rail collision path, not just the counter in isolation.
	for i in range(5):
		game.car.position = game.track.points[5]+game.track.right_at(5)*6
		game.car.nearest_index = 5
		game._physics_process(1.0/60)
	check(game.result.contacts==1 and game.result.penalty==3,"vehicle collision reaches penalty counter")
	game.car.position = game.track.points[5]
	for i in range(40): game._physics_process(1.0/60)
	game.car.position = game.track.points[5]+game.track.right_at(5)*6
	game._physics_process(1.0/60)
	check(game.result.contacts==2,"second physical collision counted")
	game.result.elapsed = 120
	var idx: int = game.track.points.size()-2
	game.car.position = game.track.points[idx]
	game.car.nearest_index = idx
	game._physics_process(1.0/60)
	check(game.mode=="finish" and game.result.finished and not game.running,"goal opens results and freezes race")
	check(absf(game.best_time-game.result.total())<0.001,"best time includes penalties")
	var saved = ConfigFile.new()
	saved.load("user://settings.cfg")
	check(absf(saved.get_value("times","2_3",-1)-game.best_time)<0.001,"finished best time persisted")
	var previous_best: float = game.best_time
	game.resume()
	check(not game.running,"finished run cannot resume")
	if DisplayServer.get_name()!="headless":
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/finish-result.png")
	game.start()
	check(game.result.elapsed==0 and game.result.contacts==0,"restart clears clock and contacts")
	game.result.elapsed = 200
	game.finish_run()
	check(game.best_time==previous_best,"slower finish does not replace record")
	game.change_selection(0,0)
	check(game.result.total()==0,"selection resets race")
	game.change_selection(3,2)
	check(game.best_time==previous_best,"vehicle/course best restored independently")
	game.config.clear()
	game.config.parse(original_config)
	game.config.save("user://settings.cfg")
	game.queue_free()
	for i in range(3): await process_frame
	print("RACE RESULT: ",failures," failures")
	quit(1 if failures else 0)
