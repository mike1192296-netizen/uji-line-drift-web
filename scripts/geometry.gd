extends RefCounted

static func material(color: Color, metal: float = 0.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metal
	m.roughness = 0.55
	return m

static func box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.material_override = mat
	parent.add_child(n)
	n.position = pos
	return n

static func beam(parent: Node3D, a: Vector3, b: Vector3, width: float, height: float, mat: Material) -> void:
	var n = box(parent, (a+b)*0.5, Vector3(width,height,a.distance_to(b)), mat)
	n.look_at_from_position((a+b)*0.5,b,Vector3.RIGHT if absf((b-a).normalized().dot(Vector3.UP))>0.99 else Vector3.UP)

static func merge_static(parent: Node3D) -> void:
	var groups: Dictionary = {}
	for child in parent.get_children():
		if child is MeshInstance3D and child.mesh.get_surface_count()>0:
			var mat = child.material_override
			if not groups.has(mat):
				var surface = SurfaceTool.new()
				surface.begin(Mesh.PRIMITIVE_TRIANGLES)
				groups[mat] = surface
			groups[mat].append_from(child.mesh,0,child.transform)
			parent.remove_child(child)
			# Detached temporary geometry: release now, not after the entire world builds.
			child.free()
	for mat in groups:
		var instance = MeshInstance3D.new()
		instance.mesh = groups[mat].commit()
		instance.material_override = mat
		parent.add_child(instance)

static func quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for v in [a,b,c,a,c,d]: st.add_vertex(v)

static func finish(parent: Node3D, st: SurfaceTool, mat: Material) -> MeshInstance3D:
	st.generate_normals()
	st.index()
	var n = MeshInstance3D.new()
	n.mesh = st.commit()
	n.material_override = mat
	parent.add_child(n)
	return n

static func patch(parent: Node3D, vertices: Array, mat: Material) -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	quad(st,vertices[0],vertices[1],vertices[2],vertices[3])
	finish(parent,st,mat)

static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, mat: Material, segments: int = 16) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	n.mesh = mesh
	n.material_override = mat
	parent.add_child(n)
	n.position = pos
	return n

static func car(parent: Node3D) -> Node3D:
	var root = Node3D.new()
	root.name = "AthleteSedan"
	parent.add_child(root)
	var paint = detail(Color(0.73,0.75,0.73),3,0.20,0.22)
	var glass = material(Color(0.045,0.075,0.09),0.5)
	glass.roughness = 0.16
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var chrome = material(Color(0.65,0.68,0.70),0.85)
	chrome.roughness = 0.2
	var rubber = detail(Color(0.5,0.5,0.5),1,0.0,0.95)
	var seam = material(Color(0.11,0.13,0.13))
	# 4.84 x 1.78m, wheelbase 2.85m. Lofted hood, shoulders and trunk.
	var sections = [[-2.42,0.73,0.79],[-2.30,0.84,0.91],[-1.95,0.88,0.98],[-1.0,0.89,1.01],[-0.6,0.89,1.01],[0.7,0.89,1.02],[1.45,0.89,1.02],[2.08,0.87,0.99],[2.35,0.80,0.92],[2.42,0.73,0.82]]
	var top = SurfaceTool.new()
	top.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	for sec in sections:
		var z: float = sec[0]
		var w: float = sec[1]
		var y: float = sec[2]
		rings.append([Vector3(-w,0.78,z),Vector3(-w*0.96,y-0.04,z),Vector3(-w*0.76,y,z),Vector3(0,y+0.012,z),Vector3(w*0.76,y,z),Vector3(w*0.96,y-0.04,z),Vector3(w,0.78,z)])
	for i in range(rings.size()-1):
		for j in range(6): quad(top,rings[i][j],rings[i+1][j],rings[i+1][j+1],rings[i][j+1])
	finish(root,top,paint)
	# Cut wheel arches into the side surfaces, with a sculpted lower sill.
	for side in [-1.0,1.0]:
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(121):
			var za = -2.42+float(i)*4.84/121.0
			var zb = -2.42+float(i+1)*4.84/121.0
			var ya = arch_bottom(za)
			var yb = arch_bottom(zb)
			var wa = body_width(za)
			var wb = body_width(zb)
			quad(st,Vector3(side*wa,ya,za),Vector3(side*wb,yb,zb),Vector3(side*wb,0.80,zb),Vector3(side*wa,0.80,za))
		finish(root,st,paint)
		box(root,Vector3(side*0.85,0.28,0),Vector3(0.085,0.11,1.92),paint)
		# Door shut lines, handles, window surround and pillars.
		for z in [-0.92,0.36,1.12]:
			beam(root,Vector3(side*0.895,0.43,z),Vector3(side*0.895,0.98,z),0.008,0.008,seam)
		for z in [0.10,0.98]: box(root,Vector3(side*0.897,0.92,z),Vector3(0.026,0.035,0.19),chrome)
		beam(root,Vector3(side*0.79,1.04,-1.0),Vector3(side*0.69,1.45,-0.54),0.07,0.055,paint)
		beam(root,Vector3(side*0.69,1.45,-0.54),Vector3(side*0.69,1.46,0.70),0.05,0.05,chrome)
		beam(root,Vector3(side*0.69,1.46,0.70),Vector3(side*0.80,1.04,1.36),0.11,0.075,paint)
		beam(root,Vector3(side*0.80,1.04,-1.0),Vector3(side*0.80,1.04,1.36),0.025,0.026,chrome)
		patch(root,[Vector3(side*0.795,1.06,-0.94),Vector3(side*0.69,1.43,-0.52),Vector3(side*0.69,1.43,0.70),Vector3(side*0.795,1.06,1.30)],glass)
		beam(root,Vector3(side*0.80,1.05,0.28),Vector3(side*0.70,1.45,0.28),0.075,0.065,seam)
		box(root,Vector3(side*0.94,1.07,-0.84),Vector3(0.22,0.13,0.31),paint)
		box(root,Vector3(side*0.944,1.07,-0.675),Vector3(0.17,0.08,0.012),glass)
	# Sloping windscreen / rear glass and a gently crowned roof.
	patch(root,[Vector3(-0.79,1.04,-1.02),Vector3(-0.68,1.45,-0.54),Vector3(0.68,1.45,-0.54),Vector3(0.79,1.04,-1.02)],glass)
	patch(root,[Vector3(-0.79,1.04,1.36),Vector3(0.79,1.04,1.36),Vector3(0.68,1.46,0.70),Vector3(-0.68,1.46,0.70)],glass)
	patch(root,[Vector3(-0.70,1.45,-0.56),Vector3(-0.70,1.46,0.72),Vector3(0,1.50,0.72),Vector3(0,1.49,-0.56)],paint)
	patch(root,[Vector3(0,1.49,-0.56),Vector3(0,1.50,0.72),Vector3(0.70,1.46,0.72),Vector3(0.70,1.45,-0.56)],paint)
	for z in [0.98,1.08,1.18]:
		beam(root,Vector3(-0.65,1.46-(z-0.70)*0.64,z),Vector3(0.65,1.46-(z-0.70)*0.64,z),0.006,0.006,chrome)
	# Bumpers with grille, projector housings, fog lamps, rear lip and twin exhausts.
	box(root,Vector3(0,0.51,-2.34),Vector3(1.58,0.35,0.15),paint)
	box(root,Vector3(0,0.53,2.34),Vector3(1.60,0.37,0.15),paint)
	box(root,Vector3(0,0.77,-2.405),Vector3(0.76,0.27,0.032),rubber)
	for y in [0.67,0.72,0.77,0.82,0.87]: box(root,Vector3(0,y,-2.43),Vector3(0.76,0.018,0.028),chrome)
	box(root,Vector3(0,0.40,-2.425),Vector3(0.82,0.09,0.03),rubber)
	box(root,Vector3(0,0.73,2.425),Vector3(1.40,0.028,0.018),chrome)
	box(root,Vector3(0,0.97,2.13),Vector3(1.48,0.036,0.14),paint)
	var lens = detail(Color(0.9,0.95,1.0),0,0.45,0.18)
	var cover = material(Color(0.68,0.78,0.80,0.32),0.25)
	cover.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cover.roughness = 0.12
	cover.cull_mode = BaseMaterial3D.CULL_DISABLED
	var red = material(Color(0.34,0.012,0.018),0.25)
	red.roughness = 0.22
	red.emission_enabled = true
	red.emission = Color(0.5,0.015,0.012)
	red.emission_energy_multiplier = 0.35
	var brake_light = red.duplicate()
	root.set_meta("brake_material",brake_light)
	for side in [-1.0,1.0]:
		box(root,Vector3(side*0.59,0.81,-2.35),Vector3(0.39,0.18,0.09),rubber)
		for x in [0.49,0.67]:
			var lamp = cylinder(root,Vector3(side*x,0.82,-2.405),0.068,0.022,lens,16)
			lamp.rotation.x = PI/2
		patch(root,[Vector3(side*0.405,0.72,-2.445),Vector3(side*0.405,0.92,-2.445),Vector3(side*0.855,0.91,-2.32),Vector3(side*0.855,0.76,-2.32)],cover)
		box(root,Vector3(side*0.67,0.42,-2.41),Vector3(0.17,0.07,0.025),lens)
		box(root,Vector3(side*0.60,0.84,2.37),Vector3(0.39,0.19,0.065),brake_light)
		box(root,Vector3(side*0.60,0.83,2.408),Vector3(0.37,0.036,0.008),lens)
		box(root,Vector3(side*0.85,0.84,2.18),Vector3(0.025,0.17,0.28),red)
		var exhaust = cylinder(root,Vector3(side*0.64,0.25,2.34),0.065,0.22,chrome,12)
		exhaust.rotation.x = PI/2
	# Neutral plate, no brand logo.
	for z in [-2.435,2.435]:
		box(root,Vector3(0,0.58,z),Vector3(0.33,0.16,0.016),material(Color(0.91,0.92,0.85)))
		for x in [-0.075,-0.025,0.025,0.075]: box(root,Vector3(x,0.56,z+signf(z)*0.012),Vector3(0.018,0.048,0.003),seam)
	merge_static(root)
	# Wheel assemblies stay separate for rolling and steering animation.
	var wheels: Array[Node3D] = []
	for side in [-1.0,1.0]:
		for z in [-1.425,1.425]:
			var hub = Node3D.new()
			root.add_child(hub)
			hub.position = Vector3(side*0.79,0.35,z)
			var spin = Node3D.new()
			hub.add_child(spin)
			var tire = cylinder(spin,Vector3.ZERO,0.335,0.225,rubber,32)
			tire.rotation.z = PI/2
			var rim = cylinder(spin,Vector3(side*0.12,0,0),0.245,0.016,chrome,32)
			rim.rotation.z = PI/2
			var inset = cylinder(spin,Vector3(side*0.133,0,0),0.212,0.018,seam,24)
			inset.rotation.z = PI/2
			for j in range(10):
				var angle = TAU*float(j)/10
				var spoke = box(spin,Vector3(side*0.145,sin(angle)*0.13,cos(angle)*0.13),Vector3(0.026,0.032,0.21),chrome)
				spoke.rotation.x = -angle
			var cap = cylinder(spin,Vector3(side*0.16,0,0),0.055,0.016,chrome,16)
			cap.rotation.z = PI/2
			merge_static(spin)
			hub.set_meta("front",z<0)
			wheels.append(hub)
	root.set_meta("wheels",wheels)
	return root

static func arch_bottom(z: float) -> float:
	var distance = minf(absf(z-1.425),absf(z+1.425))
	if distance<0.38: return 0.35+sqrt(0.38*0.38-distance*distance)
	return 0.27

static func body_width(z: float) -> float:
	return lerpf(0.89,0.73,clampf((absf(z)-2.08)/0.34,0,1))

static func detail(color: Color,tile: int,metal: float,rough: float) -> ShaderMaterial:
	var m = ShaderMaterial.new()
	m.shader = preload("res://shaders/car_material.gdshader")
	m.set_shader_parameter("atlas",preload("res://textures/car_materials.jpg"))
	m.set_shader_parameter("tint",color)
	m.set_shader_parameter("tile",tile)
	m.set_shader_parameter("metal",metal)
	m.set_shader_parameter("rough",rough)
	return m

static func rounded_box(parent: Node3D,pos: Vector3,size: Vector3,mat: Material) -> MeshInstance3D:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half = size*0.5
	var radius = minf(0.09,minf(half.x,minf(half.y,half.z))*0.8)
	var inner = half-Vector3.ONE*radius
	for axis in range(3):
		for side in [-1.0,1.0]:
			for u in range(6):
				for v in range(6):
					var vertices: Array[Vector3] = []
					for uv in [Vector2(u,v),Vector2(u+1,v),Vector2(u+1,v+1),Vector2(u,v+1)]:
						var p = Vector3.ZERO
						p[axis] = half[axis]*side
						p[(axis+1)%3] = (uv.x/3.0-1.0)*half[(axis+1)%3]
						p[(axis+2)%3] = (uv.y/3.0-1.0)*half[(axis+2)%3]
						var closest = p.clamp(-inner,inner)
						vertices.append(closest+(p-closest).normalized()*radius)
					if side>0: quad(st,vertices[0],vertices[3],vertices[2],vertices[1])
					else: quad(st,vertices[0],vertices[1],vertices[2],vertices[3])
	var n = finish(parent,st,mat)
	n.position = pos
	return n
