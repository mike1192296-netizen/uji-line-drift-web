extends Node3D
const Garage = preload("res://scripts/garage.gd")
const AXLES = [1.45,1.2335,1.41,1.2875,1.23,1.50,1.225]
const RADII = [0.335,0.315,0.33,0.33,0.285,0.36,0.325]
const G = preload("res://scripts/geometry.gd")
const Powertrain = preload("res://scripts/powertrain.gd")
var drivetrain = Powertrain.new()
var vehicle_id = 0
var track: Node3D
var velocity = Vector3.ZERO
var steering = 0.0
var yaw_rate = 0.0
var throttle = 0.0
var brake = 0.0
var steer_input = 0.0
var assist = 0.75
var slip = 0.0
var speed = 0.0
var nearest_index = 0
var progress = 0.0
var hit = false
var model: Node3D
var smoke: CPUParticles3D
var engine: AudioStreamPlayer
var squeal: AudioStreamPlayer
var mark_timer = 0.0
var marks: Array[Node3D] = []
var effects = true

func _ready() -> void:
	drivetrain.setup(vehicle_id)
	model = preload("res://scripts/garage.gd").build(self,vehicle_id)
	smoke = CPUParticles3D.new()
	add_child(smoke)
	smoke.position = Vector3(0,0.3,1.5)
	smoke.amount = 40
	smoke.lifetime = 0.9
	smoke.emitting = false
	smoke.direction = Vector3(0,1,0)
	smoke.spread = 65
	smoke.gravity = Vector3(0,0.5,0)
	smoke.initial_velocity_min = 0.7
	smoke.initial_velocity_max = 1.8
	smoke.scale_amount_min = 0.3
	smoke.scale_amount_max = 0.9
	smoke.local_coords = false
	var mesh = SphereMesh.new()
	mesh.radial_segments = 6
	mesh.rings = 3
	mesh.radius = 0.4
	mesh.height = 0.8
	mesh.material = G.material(Color(0.75,0.8,0.8,0.35))
	mesh.material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke.mesh = mesh
	engine = AudioStreamPlayer.new()
	add_child(engine)
	engine.stream = make_sound(false)
	engine.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	engine.stream.loop_end = 22050
	engine.volume_db = -15
	if DisplayServer.get_name() != "headless": engine.play()
	squeal = AudioStreamPlayer.new()
	add_child(squeal)
	squeal.stream = make_sound(true)
	squeal.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	squeal.stream.loop_end = 22050
	squeal.volume_db = -80
	if DisplayServer.get_name() != "headless": squeal.play()

func reset() -> void:
	drivetrain.setup(vehicle_id)
	position = track.points[5]+Vector3.UP*0.06
	rotation = Vector3.ZERO
	velocity = Vector3.ZERO
	yaw_rate = 0
	steering = 0
	nearest_index = 5
	progress = 0
	speed = 0
	slip = 0
	throttle = 0
	brake = 0
	steer_input = 0
	smoke.emitting = false
	model.rotation = Vector3.ZERO
	for mark in marks:
		mark.queue_free()
	marks.clear()

func step(dt: float) -> void:
	hit = false
	steering = move_toward(steering,steer_input,dt*([2.8,3.6,2.1,3.5,3.3,1.9,3.0][vehicle_id]))
	var forward = -global_basis.z
	var right = global_basis.x
	var longitudinal = velocity.dot(forward)
	var lateral = velocity.dot(right)
	speed = velocity.length()
	slip = atan2(lateral,maxf(absf(longitudinal),2.0))
	var road = track.nearest(position,nearest_index)
	nearest_index = road.index
	progress = road.progress
	var slide = clampf(absf(steering)*speed/18.0*(throttle*0.75+brake*0.65),0,1)
	if vehicle_id in [1,2,4,5]: slide = clampf(absf(steering)*speed/18.0*(brake*1.1+(1.0-throttle)*0.42+throttle*0.12),0,1)
	var grip = lerpf(8.8,2.7,slide) if vehicle_id in [1,2,4,5] else lerpf(7.5,2.0,slide)
	if vehicle_id==2: grip += 0.7
	if vehicle_id==3: grip *= 0.94
	lateral *= exp(-grip*dt)
	longitudinal = drivetrain.step(dt,longitudinal,throttle,brake,road.direction.y*forward.dot(road.direction),slip)
	var desired_yaw = -steering*clampf(speed/8.0,0,1)*lerpf(0.85,0.48,clampf(speed/50,0,1))
	desired_yaw *= 1.0+slide*0.6
	if vehicle_id==1: desired_yaw *= 1.18*(1.0-throttle*clampf(speed/50,0,1)*0.14)
	if vehicle_id==2: desired_yaw *= 0.82
	if vehicle_id==3: desired_yaw *= 1.12
	if vehicle_id==4: desired_yaw *= 1.13
	if vehicle_id==5: desired_yaw *= 0.74
	if vehicle_id==6: desired_yaw *= 0.99
	desired_yaw -= clampf(slip,-0.65,0.65)*assist*1.5
	if absf(slip)>0.8:
		desired_yaw -= slip*2.0
	yaw_rate = lerpf(yaw_rate,desired_yaw,1-exp(-([4.5,6.0,3.4,5.8,6.3,3.0,4.8][vehicle_id])*dt))
	rotation.y += yaw_rate*dt
	velocity = forward*longitudinal+right*lateral
	position += velocity*dt
	road = track.nearest(position,nearest_index)
	position.y = road.point.y+0.06
	if absf(road.offset)>4.9:
		position -= road.right*(road.offset-clampf(road.offset,-4.9,4.9))
		velocity -= road.right*velocity.dot(road.right)*1.2
		velocity *= 0.84
		hit = true
	model.rotation.z = lerpf(model.rotation.z,-steering*speed*0.0018,dt*5)
	model.rotation.x = lerpf(model.rotation.x,road.direction.y+(brake-throttle*0.3)*0.025,dt*5)
	# Visual-only wheel rotation and brake-light response. Handling is unchanged.
	for wheel in model.get_meta("wheels",[]):
		wheel.rotation.y = -steering*0.38 if wheel.get_meta("front") else 0.0
		wheel.get_child(0).rotation.x -= (speed+(minf(drivetrain.wheelspin,2.0)*5.0 if bool(wheel.get_meta("front",false))==bool(drivetrain.spec.ff) else 0.0))*dt/RADII[vehicle_id]
	var brake_material: StandardMaterial3D = model.get_meta("brake_material")
	brake_material.emission_energy_multiplier = 1.6 if brake>0.1 else 0.35
	var drifting = speed>6 and absf(slip)>0.12
	if vehicle_id in [1,2,4,5]: smoke.position.z = (AXLES[vehicle_id])*(1 if drifting else -1)
	smoke.emitting = effects and (drifting or (throttle>0.8 and drivetrain.wheelspin>0.08))
	engine.pitch_scale = 0.5+drivetrain.rpm/6000.0*1.7
	squeal.volume_db = -20 if drifting else -80
	mark_timer -= dt
	if drifting and effects and mark_timer<=0:
		mark_timer = 0.08
		for side in [-0.78,0.78]:
			var mark = G.box(get_parent(),position+global_basis*Vector3(side,0.015,AXLES[vehicle_id]),Vector3(0.22,0.015,0.75),G.material(Color(0.035,0.04,0.04)))
			mark.rotation.y = rotation.y
			marks.append(mark)
		while marks.size()>240:
			marks.pop_front().queue_free()

func _exit_tree() -> void:
	engine.stop()
	squeal.stop()

func make_sound(skidding: bool) -> AudioStreamWAV:
	var wave = AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	var data = PackedByteArray()
	data.resize(44100)
	var rng = RandomNumberGenerator.new()
	rng.seed = 18
	for i in range(22050):
		var t = float(i)/22050.0
		var value = sin(TAU*90*t)*0.35+sin(TAU*180*t)*0.2+sin(TAU*270*t)*0.15
		if skidding: value = sin(TAU*1100*t)*0.15+rng.randf_range(-0.2,0.2)
		data.encode_s16(i*2,int(value*24000))
	wave.data = data
	return wave

func set_vehicle(id: int) -> void:
	vehicle_id = clampi(id,0,Garage.NAMES.size()-1)
	remove_child(model)
	model.free()
	model = preload("res://scripts/garage.gd").build(self,vehicle_id)
	smoke.position.z = AXLES[vehicle_id]
	reset()
