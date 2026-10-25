extends Node3D
const G = preload("res://scripts/geometry.gd")
signal build_progress(value: float)
signal build_finished
var progressive_build = OS.has_feature("web")
var build_complete = false
var course_id = 0
var start_index = 5
const NAMES = ["UJI RIVER", "AUTUMN RIDGE", "LAKE RUN", "UJI LINE / OSM PREVIEW"]
var points: PackedVector3Array = []
var lengths: Array[float] = [0.0]
var total_length: float = 0.0
const WIDTH = 12.0
const TARGET_LENGTH = 5000.0
var mats: Dictionary = {}
var rng = RandomNumberGenerator.new()
var leaf_mesh: SphereMesh

func surface(color: Color, kind: int) -> ShaderMaterial:
	var m = ShaderMaterial.new()
	m.shader = load("res://shaders/surface.gdshader")
	m.set_shader_parameter("base_color",color)
	m.set_shader_parameter("surface_kind",kind)
	return m

func _ready() -> void:
	rng.seed = 180035+course_id*71
	make_points()
	mats.asphalt = surface(Color(0.17,0.18,0.18),0)
	mats.ground = surface(Color(0.33,0.24,0.10) if course_id==1 else Color(0.22,0.28,0.12),1)
	mats.concrete = surface(Color(0.37,0.37,0.33),2)
	mats.bark = surface(Color(0.18,0.12,0.075),3)
	mats.white = G.material(Color(0.73,0.73,0.65))
	mats.yellow = G.material(Color(0.72,0.39,0.07))
	mats.rail = G.material(Color(0.53,0.56,0.55),0.65)
	mats.rail.roughness = 0.53
	mats.dark = G.material(Color(0.055,0.060,0.055))
	mats.red = G.material(Color(0.66,0.14,0.045))
	mats.water = ShaderMaterial.new()
	mats.water.shader = load("res://shaders/water.gdshader")
	for j in range(3):
		var m = ShaderMaterial.new()
		m.shader = load("res://shaders/leaves.gdshader")
		m.set_shader_parameter("base_color",([Color(0.42,0.14,0.025),Color(0.51,0.30,0.045),Color(0.24,0.11,0.025)] if course_id==1 else [Color(0.085,0.17,0.05),Color(0.12,0.20,0.06),Color(0.045,0.12,0.05)])[j])
		mats["leaf%d"%j] = m
	leaf_mesh = SphereMesh.new()
	leaf_mesh.radial_segments = 12
	leaf_mesh.rings = 6
	leaf_mesh.radius = 1.0
	leaf_mesh.height = 2.0
	if progressive_build:
		await get_tree().process_frame
	for start in range(0,points.size()-1,32):
		if course_id==3: build_real_chunk(start,mini(start+32,points.size()-1))
		else: build_chunk(start,mini(start+32,points.size()-1))
		build_progress.emit(float(mini(start+32,points.size()-1))/float(points.size()-1))
		if progressive_build:
			await get_tree().process_frame
	if course_id!=3: mountains()
	build_complete = true
	build_finished.emit()

func make_points() -> void:
	if course_id==3:
		make_real_points()
		return
	var curve = Curve3D.new()
	# Fictional Uji River-inspired route: original opening, then gorge/forest sections.
	var plan = [Vector2(0,0),Vector2(0,-100),Vector2(55,-190),Vector2(-30,-290),Vector2(-80,-390),Vector2(0,-445),Vector2(80,-390),Vector2(150,-450),Vector2(135,-560),Vector2(60,-650),Vector2(110,-750),Vector2(210,-830),Vector2(250,-980),Vector2(180,-1130),Vector2(80,-1190),Vector2(30,-1320),Vector2(150,-1390),Vector2(230,-1320),Vector2(320,-1400),Vector2(370,-1570),Vector2(300,-1700),Vector2(160,-1790),Vector2(200,-1950),Vector2(320,-2070),Vector2(390,-2240),Vector2(290,-2310),Vector2(190,-2240),Vector2(100,-2320),Vector2(60,-2480),Vector2(180,-2610),Vector2(280,-2750),Vector2(230,-2910),Vector2(100,-2980),Vector2(70,-3140),Vector2(190,-3240),Vector2(310,-3310),Vector2(320,-3470),Vector2(240,-3620),Vector2(120,-3730),Vector2(160,-3890),Vector2(280,-4020)]
	if course_id==1:
		plan = [Vector2(0,0),Vector2(0,-130),Vector2(-80,-250),Vector2(-220,-340),Vector2(-250,-460),Vector2(-130,-500),Vector2(30,-430),Vector2(160,-520),Vector2(170,-690),Vector2(30,-800),Vector2(-160,-840),Vector2(-240,-960),Vector2(-180,-1080),Vector2(20,-1100),Vector2(180,-1220),Vector2(160,-1400),Vector2(-20,-1540),Vector2(-220,-1570),Vector2(-300,-1720),Vector2(-190,-1840),Vector2(20,-1800),Vector2(160,-1930),Vector2(100,-2120),Vector2(-100,-2280),Vector2(-260,-2410),Vector2(-180,-2590),Vector2(30,-2720),Vector2(90,-2930),Vector2(-70,-3110),Vector2(-160,-3330)]
	elif course_id==2:
		plan = [Vector2(0,0),Vector2(0,-200),Vector2(100,-420),Vector2(320,-620),Vector2(400,-880),Vector2(300,-1120),Vector2(70,-1300),Vector2(-100,-1540),Vector2(-40,-1800),Vector2(190,-1970),Vector2(440,-2160),Vector2(500,-2440),Vector2(350,-2690),Vector2(100,-2880),Vector2(-40,-3140),Vector2(60,-3380),Vector2(300,-3540),Vector2(430,-3810),Vector2(300,-4100)]
	var anchors: Array[Vector3] = []
	var distance = 0.0
	for i in range(plan.size()):
		if i>0: distance += plan[i].distance_to(plan[i-1])
		anchors.append(Vector3(plan[i].x,320-distance*[0.055,0.075,0.035][course_id],plan[i].y))
	for i in range(anchors.size()):
		var tangent = (anchors[mini(anchors.size()-1,i+1)]-anchors[maxi(0,i-1)])*0.17
		curve.add_point(anchors[i],-tangent,tangent)
	curve.bake_interval = 5.0
	points = curve.get_baked_points()
	var raw_length = 0.0
	for i in range(points.size()-1): raw_length += points[i].distance_to(points[i+1])
	var ratio = TARGET_LENGTH/raw_length
	var origin = points[0]
	for i in range(points.size()): points[i] = origin+(points[i]-origin)*ratio
	for i in range(points.size()-1):
		total_length += points[i].distance_to(points[i+1])
		lengths.append(total_length)

func right_at(i: int) -> Vector3:
	return (points[mini(points.size()-1,i+1)]-points[maxi(0,i-1)]).normalized().cross(Vector3.UP).normalized()

func strip_vertex(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	G.quad(st,a,b,c,d)

func build_chunk(start: int, end: int) -> void:
	var chunk = Node3D.new()
	add_child(chunk)
	var road = SurfaceTool.new()
	road.begin(Mesh.PRIMITIVE_TRIANGLES)
	var land = SurfaceTool.new()
	land.begin(Mesh.PRIMITIVE_TRIANGLES)
	var water = SurfaceTool.new()
	water.begin(Mesh.PRIMITIVE_TRIANGLES)
	var leaves: Array = [[],[],[]]
	for i in range(start,end):
		var a = points[i]
		var b = points[i+1]
		var ra = right_at(i)
		var rb = right_at(i+1)
		var bridge = (lengths[i]>1740 and lengths[i]<1860) or (lengths[i]>3630 and lengths[i]<3740)
		var tunnel = (lengths[i]>780 and lengths[i]<880) or (lengths[i]>2820 and lengths[i]<2980)
		strip_vertex(road,a-ra*6,b-rb*6,b+rb*6,a+ra*6)
		# Shoulder, drainage ditch, corrugated steel rail and road markings.
		for side in [-1.0,1.0]:
			G.beam(chunk,a+ra*5.5*side+Vector3.UP*0.028,b+rb*5.5*side+Vector3.UP*0.028,0.12,0.014,mats.white)
			G.beam(chunk,a+ra*5.88*side,b+rb*5.88*side,0.2,0.07,mats.concrete)
			for band in range(3):
				var y = 0.76+float(band)*0.12
				var off = 6.13+ (0.04 if band==1 else 0.0)
				G.beam(chunk,a+ra*off*side+Vector3.UP*y,b+rb*off*side+Vector3.UP*y,0.055,0.145,mats.rail)
			G.box(chunk,a+ra*6.16*side+Vector3.UP*0.48,Vector3(0.10,1.08,0.12),mats.rail)
			if i%4==0: G.box(chunk,a+ra*6.08*side+Vector3.UP*1.02,Vector3(0.1,0.09,0.1),mats.white if side>0 else mats.red)
			if not bridge:
				var near_a = a+ra*6*side-Vector3.UP*0.12
				var near_b = b+rb*6*side-Vector3.UP*0.12
				var mid_a = a+ra*20*side+Vector3.UP*(7.0 if side<0 else -9.0)
				var mid_b = b+rb*20*side+Vector3.UP*(7.0 if side<0 else -9.0)
				var far_a = a+ra*70*side+Vector3.UP*(20+sin(i*0.16)*4 if side<0 else -14)
				var far_b = b+rb*70*side+Vector3.UP*(20+sin((i+1)*0.16)*4 if side<0 else -14)
				strip_vertex(land,near_a,near_b,mid_b,mid_a)
				strip_vertex(land,mid_a,mid_b,far_b,far_a)
		if i%2==0: G.beam(chunk,a+Vector3.UP*0.028,b+Vector3.UP*0.028,0.12,0.014,mats.yellow)
		# River runs below the downhill road, instead of a single flat water plane.
		strip_vertex(water,a+ra*24-Vector3.UP*10.7,b+rb*24-Vector3.UP*10.7,b+rb*(180 if course_id==2 else 65)-Vector3.UP*10.7,a+ra*(180 if course_id==2 else 65)-Vector3.UP*10.7)
		if bridge:
			G.beam(chunk,a-Vector3.UP*0.45,b-Vector3.UP*0.45,12.5,0.8,mats.concrete)
			if i%5==0: G.box(chunk,a-Vector3.UP*6,Vector3(1.3,12,2.5),mats.concrete)
		elif not tunnel:
			if i%3==0:
				for side in [-1.0,1.0]:
					var offset = rng.randf_range(10,19) if side<0 else rng.randf_range(12,18)
					var pos = a+ra*side*offset+Vector3.UP*((offset-6)/14.0*(7 if side<0 else -9))
					tree(chunk,pos,rng.randf_range(0.7,1.25),leaves)
					if side<0: tree(chunk,a-ra*rng.randf_range(28,48)+Vector3.UP*13,rng.randf_range(1.2,1.7),leaves)
			if i%7==0:
				var rock = MeshInstance3D.new()
				var sphere = SphereMesh.new()
				sphere.radial_segments = 7
				sphere.rings = 3
				rock.mesh = sphere
				rock.material_override = mats.concrete
				chunk.add_child(rock)
				rock.position = a+ra*19-Vector3.UP*9.3
				rock.scale = Vector3(rng.randf_range(2,4),rng.randf_range(1,3),rng.randf_range(2,5))
		if tunnel: tunnel_segment(chunk,a,b,ra,rb)
		# Cut-stone retaining walls on selected outside bends.
		if i%110<18 and not bridge:
			G.beam(chunk,a-ra*7.4+Vector3.UP*1.1,b-rb*7.4+Vector3.UP*1.1,0.55,2.6,mats.concrete)
		if i%60==12: sign_board(chunk,a+ra*7.2,(b-a).normalized())
	G.finish(chunk,road,mats.asphalt)
	G.finish(chunk,land,mats.ground)
	G.finish(chunk,water,mats.water)
	G.merge_static(chunk)
	for n in chunk.get_children():
		if n is GeometryInstance3D:
			n.visibility_range_end = 900
			n.visibility_range_end_margin = 25
	for j in range(3):
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = leaf_mesh
		mm.instance_count = leaves[j].size()
		for k in range(leaves[j].size()): mm.set_instance_transform(k,leaves[j][k])
		var instance = MultiMeshInstance3D.new()
		instance.multimesh = mm
		instance.material_override = mats["leaf%d"%j]
		instance.visibility_range_end = 500
		instance.visibility_range_end_margin = 25
		chunk.add_child(instance)

func tree(chunk: Node3D, pos: Vector3, scale_value: float, leaves: Array) -> void:
	G.cylinder(chunk,pos+Vector3.UP*3.1*scale_value,0.16*scale_value,6.2*scale_value,mats.bark,6)
	var palette = rng.randi_range(0,2)
	for j in range(6):
		var angle = float(j)*2.4
		var center = pos+Vector3(sin(angle)*1.6,5.8+rng.randf_range(-1,1.7),cos(angle)*1.6)*scale_value
		var basis = Basis.from_euler(Vector3(rng.randf(),rng.randf()*TAU,rng.randf())).scaled(Vector3(2.2,1.7,2.0)*scale_value)
		leaves[palette].append(Transform3D(basis,center))

func tunnel_segment(chunk: Node3D,a: Vector3,b: Vector3,ra: Vector3,rb: Vector3) -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(12):
		var t0 = PI*float(j)/12
		var t1 = PI*float(j+1)/12
		var v0 = ra*cos(t0)*7+Vector3.UP*(2.0+sin(t0)*4.5)
		var v1 = ra*cos(t1)*7+Vector3.UP*(2.0+sin(t1)*4.5)
		var w0 = rb*cos(t0)*7+Vector3.UP*(2.0+sin(t0)*4.5)
		var w1 = rb*cos(t1)*7+Vector3.UP*(2.0+sin(t1)*4.5)
		strip_vertex(st,a+v0,b+w0,b+w1,a+v1)
	for side in [-1.0,1.0]: G.beam(chunk,a+ra*7*side+Vector3.UP,b+rb*7*side+Vector3.UP,0.35,2.1,mats.concrete)
	G.finish(chunk,st,mats.concrete)

func sign_board(chunk: Node3D,pos: Vector3,direction: Vector3) -> void:
	G.cylinder(chunk,pos+Vector3.UP*1.7,0.055,3.4,mats.rail,8)
	var sign_root = Node3D.new()
	chunk.add_child(sign_root)
	sign_root.position = pos+Vector3.UP*3
	sign_root.look_at(pos+Vector3.UP*3-direction)
	var panel = G.box(sign_root,Vector3.ZERO,Vector3(0.9,0.9,0.06),mats.yellow)
	panel.rotation.z = PI/4
	G.beam(sign_root,Vector3(-0.23,-0.16,-0.04),Vector3(0.15,0.16,-0.04),0.07,0.07,mats.dark)
	G.beam(sign_root,Vector3(0.15,0.16,-0.04),Vector3(-0.08,0.30,-0.04),0.07,0.07,mats.dark)

func mountains() -> void:
	var noise = FastNoiseLite.new()
	noise.seed = 180
	noise.frequency = 0.004
	noise.fractal_octaves = 4
	var mat = surface(Color(0.11,0.19,0.09),1)
	for side in [-1.0,1.0]:
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var grid: Array = []
		for z in range(111):
			var row: Array[Vector3] = []
			for x in range(21):
				var xx = (-130.0-float(x)*35) if side<0 else (490.0+float(x)*35)
				var zz = 300.0-float(z)*45
				var ridge = sin(PI*float(x)/20)*120
				var yy = 300+zz*0.055+ridge+noise.get_noise_2d(xx,zz)*90
				row.append(Vector3(xx,yy,zz))
			grid.append(row)
		for z in range(110):
			for x in range(20): G.quad(st,grid[z][x],grid[z+1][x],grid[z+1][x+1],grid[z][x+1])
		for z in range(110):
			var a: Vector3 = grid[z][0]
			var b: Vector3 = grid[z+1][0]
			G.quad(st,a,b,Vector3(b.x,-350,b.z),Vector3(a.x,-350,a.z))
		G.finish(self,st,mat)

func nearest(pos: Vector3, hint: int) -> Dictionary:
	var best = INF
	var result: Dictionary = {}
	for i in range(maxi(0,hint-15),mini(points.size()-1,hint+25)):
		var a = points[i]
		var d = points[i+1]-a
		var flat = Vector3(d.x,0,d.z)
		var t = clampf(Vector3(pos.x-a.x,0,pos.z-a.z).dot(flat)/flat.length_squared(),0,1)
		var p = a+d*t
		var distance = Vector2(pos.x-p.x,pos.z-p.z).length_squared()
		if distance < best:
			best = distance
			var right = d.normalized().cross(Vector3.UP).normalized()
			result = {"index":i,"point":p,"right":right,"offset":(pos-p).dot(right),"direction":d.normalized(),"progress":lengths[i]+d.length()*t}
	return result


func make_real_points() -> void:
	# Licensed OSM centreline only. Y=0 is explicitly unverified, NOT measured road height.
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://routes/uji_visible_route_osm.json"))
	var raw: Array[Vector3] = []
	for xyz in data.local_xyz_m: raw.append(Vector3(xyz[0],0,xyz[2]))
	var origin = raw[0]
	var first = raw[1]-raw[0]
	var align = -atan2(-first.x,-first.z)
	for i in range(raw.size()): raw[i]=(raw[i]-origin).rotated(Vector3.UP,align)
	# Linear 5 m resampling follows the real polyline without arbitrary 5 km scaling.
	points = PackedVector3Array([raw[0]])
	for i in range(raw.size()-1):
		var count = maxi(1,ceili(raw[i].distance_to(raw[i+1])/5.0))
		for j in range(1,count+1): points.append(raw[i].lerp(raw[i+1],float(j)/count))
	lengths = [0.0]
	for i in range(points.size()-1): lengths.append(lengths[-1]+points[i].distance_to(points[i+1]))
	total_length = lengths[-1]
	start_index = 1

func build_real_chunk(start: int,end: int) -> void:
	# Geometry-preview surroundings: no fabricated river/tunnel/bridge elevations.
	# Road width and guardrail placement are gameplay placeholders, not surveyed dimensions.
	var chunk = Node3D.new()
	add_child(chunk)
	var road = SurfaceTool.new()
	road.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ground = SurfaceTool.new()
	ground.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(start,end):
		var a = points[i]
		var b = points[i+1]
		var ra = right_at(i)
		var rb = right_at(i+1)
		strip_vertex(road,a-ra*6,b-rb*6,b+rb*6,a+ra*6)
		for side in [-1.0,1.0]:
			strip_vertex(ground,a+ra*6*side-Vector3.UP*0.05,b+rb*6*side-Vector3.UP*0.05,b+rb*40*side-Vector3.UP*0.05,a+ra*40*side-Vector3.UP*0.05)
			G.beam(chunk,a+ra*5.5*side+Vector3.UP*0.028,b+rb*5.5*side+Vector3.UP*0.028,0.12,0.014,mats.white)
			G.beam(chunk,a+ra*6.13*side+Vector3.UP*0.90,b+rb*6.13*side+Vector3.UP*0.90,0.06,0.16,mats.rail)
			if i%2==0: G.box(chunk,a+ra*6.13*side+Vector3.UP*0.45,Vector3(0.08,0.90,0.08),mats.rail)
		if i%2==0: G.beam(chunk,a+Vector3.UP*0.028,b+Vector3.UP*0.028,0.12,0.014,mats.yellow)
	G.finish(chunk,road,mats.asphalt)
	G.finish(chunk,ground,mats.ground)
	G.merge_static(chunk)
	for n in chunk.get_children():
		if n is GeometryInstance3D:
			n.visibility_range_end = 650
			n.visibility_range_end_margin = 25
