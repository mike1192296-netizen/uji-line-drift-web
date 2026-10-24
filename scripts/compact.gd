extends RefCounted
const G = preload("res://scripts/geometry.gd")

static func build(parent: Node3D) -> Node3D:
	var root = Node3D.new()
	root.name = "R50InspiredCooper"
	parent.add_child(root)
	var paint = G.detail(Color(0.035,0.16,0.11),3,0.35,0.23)
	var white = G.material(Color(0.78,0.80,0.77),0.15)
	white.roughness = 0.25
	white.cull_mode = BaseMaterial3D.CULL_DISABLED
	var black = G.material(Color(0.018,0.022,0.023))
	var glass = G.material(Color(0.035,0.065,0.08),0.4)
	glass.roughness = 0.18
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var chrome = G.material(Color(0.66,0.69,0.70),0.85)
	chrome.roughness = 0.2
	var sections = [[-1.815,0.68,0.73],[-1.68,0.80,0.89],[-1.38,0.844,0.99],[-0.67,0.844,1.01],[0.65,0.844,1.01],[1.46,0.82,0.99],[1.75,0.76,0.91],[1.815,0.70,0.76]]
	var rings: Array = []
	for sec in sections:
		var z: float = sec[0]
		var w: float = sec[1]
		var h: float = sec[2]
		rings.append([Vector3(-w,0.77,z),Vector3(-w*0.94,h-0.04,z),Vector3(0,h,z),Vector3(w*0.94,h-0.04,z),Vector3(w,0.77,z)])
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(rings.size()-1):
		for j in range(4): G.quad(st,rings[i][j],rings[i+1][j],rings[i+1][j+1],rings[i][j+1])
	G.finish(root,st,paint)
	for side in [-1.0,1.0]:
		var panel = SurfaceTool.new()
		panel.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(100):
			var za = -1.815+float(i)*3.63/100
			var zb = -1.815+float(i+1)*3.63/100
			var wa = lerpf(0.844,0.70,clampf((absf(za)-1.46)/0.355,0,1))
			var wb = lerpf(0.844,0.70,clampf((absf(zb)-1.46)/0.355,0,1))
			G.quad(panel,Vector3(side*wa,arch(za),za),Vector3(side*wb,arch(zb),zb),Vector3(side*wb,0.79,zb),Vector3(side*wa,0.79,za))
		G.finish(root,panel,paint)
		G.rounded_box(root,Vector3(side*0.835,0.26,0),Vector3(0.08,0.10,1.75),black)
		# Black arch extensions distinguish the short three-door body.
		for z in [-1.2335,1.2335]:
			for j in range(18):
				var a = PI*float(j)/18
				var b = PI*float(j+1)/18
				G.beam(root,Vector3(side*0.85,0.34+sin(a)*0.37,z+cos(a)*0.37),Vector3(side*0.85,0.34+sin(b)*0.37,z+cos(b)*0.37),0.07,0.07,black)
		G.patch(root,[Vector3(side*0.79,1.02,-0.65),Vector3(side*0.72,1.40,-0.34),Vector3(side*0.72,1.40,1.29),Vector3(side*0.79,1.02,1.58)],glass)
		G.beam(root,Vector3(side*0.80,1.01,-0.65),Vector3(side*0.73,1.42,-0.34),0.08,0.06,paint)
		G.beam(root,Vector3(side*0.80,1.01,1.58),Vector3(side*0.73,1.42,1.29),0.11,0.07,paint)
		G.beam(root,Vector3(side*0.80,1.01,0.55),Vector3(side*0.73,1.42,0.55),0.08,0.08,black)
		G.beam(root,Vector3(side*0.80,1.01,-0.65),Vector3(side*0.80,1.01,1.58),0.022,0.025,chrome)
		G.beam(root,Vector3(side*0.846,0.36,0.57),Vector3(side*0.846,0.97,0.57),0.008,0.008,black)
		G.rounded_box(root,Vector3(side*0.852,0.91,0.38),Vector3(0.026,0.035,0.20),chrome)
		G.rounded_box(root,Vector3(side*0.91,1.03,-0.54),Vector3(0.20,0.14,0.24),white)
	G.patch(root,[Vector3(-0.79,1.02,-0.66),Vector3(-0.72,1.40,-0.34),Vector3(0.72,1.40,-0.34),Vector3(0.79,1.02,-0.66)],glass)
	G.patch(root,[Vector3(-0.77,1.02,1.59),Vector3(0.77,1.02,1.59),Vector3(0.70,1.40,1.30),Vector3(-0.70,1.40,1.30)],glass)
	G.patch(root,[Vector3(-0.74,1.42,-0.37),Vector3(-0.74,1.43,1.32),Vector3(0,1.47,1.32),Vector3(0,1.46,-0.37)],white)
	G.patch(root,[Vector3(0,1.46,-0.37),Vector3(0,1.47,1.32),Vector3(0.74,1.43,1.32),Vector3(0.74,1.42,-0.37)],white)
	G.rounded_box(root,Vector3(0,0.57,-1.77),Vector3(1.48,0.32,0.10),paint)
	G.rounded_box(root,Vector3(0,0.51,1.77),Vector3(1.47,0.36,0.10),paint)
	G.rounded_box(root,Vector3(0,0.42,-1.83),Vector3(1.5,0.12,0.07),black)
	G.rounded_box(root,Vector3(0,0.40,1.83),Vector3(1.5,0.13,0.07),black)
	G.rounded_box(root,Vector3(0,0.73,-1.82),Vector3(0.77,0.22,0.03),black)
	for y in [0.65,0.70,0.75,0.80,0.84]: G.rounded_box(root,Vector3(0,y,-1.84),Vector3(0.76,0.018,0.025),chrome)
	var lens = G.detail(Color(0.88,0.93,0.96),0,0.4,0.18)
	var red = G.material(Color(0.45,0.01,0.01),0.2)
	red.emission_enabled = true
	red.emission = Color(0.6,0.01,0.01)
	red.emission_energy_multiplier = 0.35
	root.set_meta("brake_material",red)
	for side in [-1.0,1.0]:
		var ring = G.cylinder(root,Vector3(side*0.565,0.91,-1.70),0.145,0.04,chrome,32)
		ring.rotation.x = PI/2-0.18
		var lamp = G.cylinder(root,Vector3(side*0.565,0.91,-1.73),0.12,0.045,lens,24)
		lamp.rotation.x = PI/2-0.18
		G.rounded_box(root,Vector3(side*0.69,0.84,1.77),Vector3(0.13,0.32,0.06),red)
		G.rounded_box(root,Vector3(side*0.69,0.82,1.81),Vector3(0.115,0.055,0.012),lens)
		var fog = G.cylinder(root,Vector3(side*0.55,0.43,-1.875),0.053,0.025,lens,16)
		fog.rotation.x = PI/2
	for z in [-1.87,1.84]: G.rounded_box(root,Vector3(0,0.52,z),Vector3(0.32,0.14,0.016),white)
	G.rounded_box(root,Vector3(0,0.96,1.75),Vector3(0.36,0.05,0.035),chrome)
	G.beam(root,Vector3(0.03,1.08,1.58),Vector3(0.30,1.15,1.55),0.018,0.018,black)
	var exhaust = G.cylinder(root,Vector3(-0.53,0.24,1.81),0.055,0.17,chrome,12)
	exhaust.rotation.x = PI/2
	G.merge_static(root)
	var wheels: Array[Node3D] = []
	for side in [-1.0,1.0]:
		for z in [-1.2335,1.2335]:
			var hub = Node3D.new()
			root.add_child(hub)
			hub.position = Vector3(side*0.75,0.33,z)
			var spin = Node3D.new()
			hub.add_child(spin)
			var tire = G.cylinder(spin,Vector3.ZERO,0.315,0.20,G.detail(Color(0.5,0.5,0.5),1,0.0,0.95),32)
			tire.rotation.z = PI/2
			var rim = G.cylinder(spin,Vector3(side*0.105,0,0),0.225,0.015,chrome,24)
			rim.rotation.z = PI/2
			var inset = G.cylinder(spin,Vector3(side*0.117,0,0),0.195,0.015,black,24)
			inset.rotation.z = PI/2
			for j in range(8):
				var angle = TAU*float(j)/8
				var spoke = G.rounded_box(spin,Vector3(side*0.13,sin(angle)*0.11,cos(angle)*0.11),Vector3(0.025,0.04,0.20),chrome)
				spoke.rotation.x = -angle
			var cap = G.cylinder(spin,Vector3(side*0.14,0,0),0.05,0.02,chrome,12)
			cap.rotation.z = PI/2
			G.merge_static(spin)
			hub.set_meta("front",z<0)
			wheels.append(hub)
	root.set_meta("wheels",wheels)
	return root

static func arch(z: float) -> float:
	var d = minf(absf(z-1.2335),absf(z+1.2335))
	return 0.33+sqrt(0.36*0.36-d*d) if d<0.36 else 0.26
