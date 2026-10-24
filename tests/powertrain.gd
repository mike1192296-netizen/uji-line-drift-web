extends SceneTree
const Powertrain = preload("res://scripts/powertrain.gd")
var failures = 0
func check(ok: bool,message: String) -> void:
	if ok: print("PASS: ",message)
	else:
		push_error(message)
		failures += 1
func _initialize() -> void:
	var reports: Array = []
	for id in range(Powertrain.SPECS.size()):
		var p = Powertrain.new()
		p.setup(id)
		check(absf(p.torque_at(p.spec.torque_rpm)-p.spec.nm)<0.01,"peak torque anchor %d"%id)
		check(absf(p.torque_at(p.spec.power_rpm)*p.spec.power_rpm*TAU/60/1000-p.spec.kw)<0.01,"peak power anchor %d"%id)
		var speed = 0.0
		var time100 = -1.0
		var highest_gear = 0
		var changes = 0
		var old_gear = 0
		for frame in range(36000):
			speed = p.step(1.0/60,speed,1,0)
			if frame>0 and p.gear!=old_gear: changes+=1
			old_gear = p.gear
			highest_gear = maxi(highest_gear,p.gear)
			if speed*3.6>=100 and time100<0: time100=(frame+1)/60.0
			if not is_finite(speed): failures+=1; break
		check(time100>3 and time100<35,"reasonable acceleration range %d"%id)
		check(changes<20,"no gear hunting at full throttle %d"%id)
		if p.spec.cvt:
			check(p.ratio>=p.spec.gears[1] and p.ratio<=p.spec.gears[0],"CVT stays within ratio range %d"%id)
		else: check(highest_gear>=2,"multiple gears used %d"%id)
		var top = speed*3.6
		if p.spec.limit>0: check(top<=p.spec.limit+0.5,"level-road speed limiter %d"%id)
		for frame in range(600): speed=p.step(1.0/60,speed,0,1)
		check(speed<0.01,"brake stops vehicle %d"%id)
		p.reset()
		check(p.gear==0 and p.rpm==800 and p.wheelspin==0,"powertrain resets %d"%id)
		# Without limiter, acceleration must still converge to a finite drag/gear-limited speed.
		p.limiter_enabled = false
		speed = 0
		var before_end = 0.0
		for frame in range(36000):
			if frame==35400: before_end=speed
			speed=p.step(1.0/60,speed,1,0)
		check(speed*3.6>110 and speed*3.6<320 and absf(speed-before_end)<0.1,"unrestricted top-speed convergence %d"%id)
		if id==1: check(absf(time100-9.2)<0.6 and absf(speed*3.6-200)<5,"MINI published performance neighborhood")
		if id==3: check(absf(time100-6.3)<0.6 and absf(speed*3.6-225.3)<5,"GR86 published performance neighborhood")
		var row = {"vehicle":p.spec.name,"0_100_seconds":snappedf(time100,0.01),"limiter_on_kmh":snappedf(top,0.1),"limiter_off_kmh":snappedf(speed*3.6,0.1),"shifts":changes}
		reports.append(row)
		print("BENCHMARK: ",JSON.stringify(row))
	var f = FileAccess.open("res://build/powertrain-benchmark.json",FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(reports,"  "))
	print("POWERTRAIN RESULT: ",failures," failures")
	quit(1 if failures else 0)
