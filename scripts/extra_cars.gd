extends RefCounted
const G = preload("res://scripts/geometry.gd")

# Original meshes, dimensions used as proportion guides, not scanned models.
static func build(parent: Node3D,id: int) -> Node3D:
	var kei = id==4
	var luxury = id==5
	var sports = id==6
	var length = 3.395 if kei else (4.995 if luxury else 4.31)
	var width = 1.475 if kei else (1.85 if luxury else 1.795)
	var height = 1.755 if kei else (1.935 if luxury else 1.25)
	var axle = 1.23 if kei else (1.50 if luxury else 1.225)
	var radius = 0.285 if kei else (0.36 if luxury else 0.325)
	var belt = 0.98 if kei else (1.10 if luxury else 0.78)
	var half = width*0.5
	var root = Node3D.new()
	root.name = "TantoInspired" if kei else ("Alphard40Inspired" if luxury else "Z32Inspired")
	parent.add_child(root)
	var paint = G.detail(Color(0.53,0.73,0.65) if kei else (Color(0.72,0.74,0.72) if luxury else Color(0.77,0.61,0.035)),3,0.25,0.24)
	var black = G.material(Color(0.018,0.022,0.024))
	var chrome = G.material(Color(0.64,0.67,0.70),0.85)
	var glass = G.material(Color(0.035,0.055,0.065),0.4)
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass.roughness = 0.17
	var lens = G.detail(Color(0.9,0.94,0.98),0,0.4,0.2)
	var red = G.material(Color(0.46,0.012,0.015),0.25)
	red.emission_enabled = true
	red.emission = Color(0.65,0.008,0.012)
	red.emission_energy_multiplier = 0.35
	root.set_meta("brake_material",red)
	var nose = -length*0.5
	var tail = length*0.5
	# Loft shoulders and hood; multiple lateral sections soften the silhouette.
	var sections = [[nose,0.84,belt-0.17],[nose+0.17,0.97,belt-0.06],[-axle,1.0,belt],[-0.6,1.0,belt+0.015],[0.65,1.0,belt],[axle,0.99,belt],[tail-0.16,0.96,belt-0.03],[tail,0.84,belt-0.14]]
	var rings: Array = []
	for sec in sections:
		var w: float = half*sec[1]
		var y: float = sec[2]
		var z: float = sec[0]
		rings.append([Vector3(-w,belt-0.20,z),Vector3(-w*0.97,y-0.035,z),Vector3(-w*0.8,y,z),Vector3(0,y+0.018,z),Vector3(w*0.8,y,z),Vector3(w*0.97,y-0.035,z),Vector3(w,belt-0.20,z)])
	var top = SurfaceTool.new()
	top.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(rings.size()-1):
		for j in range(6): G.quad(top,rings[i][j],rings[i+1][j],rings[i+1][j+1],rings[i][j+1])
	G.finish(root,top,paint)
	for side in [-1.0,1.0]:
		var panel = SurfaceTool.new()
		panel.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(140):
			var za = nose+length*i/140.0
			var zb = nose+length*(i+1)/140.0
			var wa = half*lerpf(1,0.84,clampf((absf(za)-(tail-0.2))/0.2,0,1))
			var wb = half*lerpf(1,0.84,clampf((absf(zb)-(tail-0.2))/0.2,0,1))
			G.quad(panel,Vector3(side*wa,arch(za,axle,radius),za),Vector3(side*wb,arch(zb,axle,radius),zb),Vector3(side*wb,belt-0.18,zb),Vector3(side*wa,belt-0.18,za))
		G.finish(root,panel,paint)
		G.rounded_box(root,Vector3(side*(half-0.015),0.25,0),Vector3(0.07,0.10,axle*1.4),paint)
	for z in [nose+0.035,tail-0.035]:
		G.rounded_box(root,Vector3(0,belt*0.60,z),Vector3(width*0.88,belt*0.58,0.13),paint)
		G.rounded_box(root,Vector3(0,0.42,z+signf(z)*0.075),Vector3(0.32 if kei else 0.34,0.16,0.018),G.material(Color(0.74,0.63,0.13) if kei else Color(0.8,0.81,0.76)))
	var front_base = nose+0.54 if not sports else -0.92
	var front_top = front_base+(0.38 if kei else (0.62 if luxury else 0.61))
	var rear_base = tail-0.13 if not sports else 1.55
	var rear_top = tail-0.24 if not sports else 0.53
	var roof_width = half*(0.90 if not sports else 0.74)
	G.patch(root,[Vector3(-half*0.92,belt+0.015,front_base),Vector3(-roof_width,height-0.07,front_top),Vector3(roof_width,height-0.07,front_top),Vector3(half*0.92,belt+0.015,front_base)],glass)
	G.patch(root,[Vector3(-half*0.92,belt+0.015,rear_base),Vector3(half*0.92,belt+0.015,rear_base),Vector3(roof_width,height-0.07,rear_top),Vector3(-roof_width,height-0.07,rear_top)],glass)
	G.rounded_box(root,Vector3(0,height-0.04,(front_top+rear_top)*0.5),Vector3(roof_width*2+0.04,0.08,rear_top-front_top+0.09),paint)
	for side in [-1.0,1.0]:
		G.patch(root,[Vector3(side*half*0.95,belt,front_base),Vector3(side*roof_width,height-0.07,front_top),Vector3(side*roof_width,height-0.07,rear_top),Vector3(side*half*0.95,belt,rear_base)],glass)
		G.beam(root,Vector3(side*half*0.95,belt,front_base),Vector3(side*roof_width,height-0.03,front_top),0.09,0.08,paint)
		G.beam(root,Vector3(side*half*0.95,belt,rear_base),Vector3(side*roof_width,height-0.03,rear_top),0.14,0.10,paint)
		G.beam(root,Vector3(side*half*0.96,belt,front_base),Vector3(side*half*0.96,belt,rear_base),0.025,0.035,chrome if luxury else black)
		for z in ([0.58] if sports else [0.05,rear_top-0.70]):
			G.beam(root,Vector3(side*half*0.95,belt,z),Vector3(side*roof_width,height-0.07,z),0.08,0.07,black)
			G.beam(root,Vector3(side*(half+0.003),0.33,z),Vector3(side*(half+0.003),belt,z),0.008,0.008,black)
			G.rounded_box(root,Vector3(side*(half+0.01),belt-0.10,z-0.16),Vector3(0.035,0.035,0.18),chrome if not sports else paint)
		G.rounded_box(root,Vector3(side*(half+0.09),belt+0.10,front_base+0.15),Vector3(0.20,0.13,0.23),paint)
		if not sports:
			G.beam(root,Vector3(side*(half+0.005),belt-0.16,0.4),Vector3(side*(half+0.005),belt-0.16,tail-0.15),0.016,0.018,black)
	if kei:
		G.rounded_box(root,Vector3(0,0.79,nose-0.04),Vector3(0.62,0.09,0.03),black)
		for side in [-1.0,1.0]:
			G.rounded_box(root,Vector3(side*0.50,0.82,nose-0.035),Vector3(0.30,0.18,0.045),lens)
			G.rounded_box(root,Vector3(side*0.61,1.18,tail-0.015),Vector3(0.12,0.58,0.05),red)
			G.rounded_box(root,Vector3(side*0.61,1.14,tail+0.02),Vector3(0.11,0.11,0.015),lens)
	elif luxury:
		# Large trapezoidal grille, narrow lamps and chrome blocks.
		G.rounded_box(root,Vector3(0,0.68,nose-0.045),Vector3(1.25,0.63,0.025),black)
		for row in range(7):
			var w = lerpf(1.24,0.91,row/6.0)
			for col in range(9):
				G.rounded_box(root,Vector3((col-4)*w/9,0.40+row*0.082,nose-0.067),Vector3(w/12,0.031,0.022),chrome)
		for side in [-1.0,1.0]:
			G.rounded_box(root,Vector3(side*0.68,1.00,nose-0.03),Vector3(0.38,0.085,0.05),lens)
			G.rounded_box(root,Vector3(side*0.79,0.69,nose-0.02),Vector3(0.08,0.25,0.05),chrome)
			G.rounded_box(root,Vector3(side*0.65,1.15,tail-0.01),Vector3(0.43,0.12,0.05),red)
			G.rounded_box(root,Vector3(side*0.83,1.02,tail-0.01),Vector3(0.08,0.32,0.05),red)
		G.rounded_box(root,Vector3(0,1.10,tail+0.02),Vector3(1.3,0.025,0.02),chrome)
	else:
		# Low slanted rectangular lamps, T-bar roof and broad black rear light panel.
		for side in [-1.0,1.0]:
			G.patch(root,[Vector3(side*0.43,0.65,nose+0.035),Vector3(side*0.45,0.78,nose+0.28),Vector3(side*0.79,0.78,nose+0.31),Vector3(side*0.78,0.65,nose+0.07)],lens)
			G.rounded_box(root,Vector3(side*0.43,height+0.005,0.12),Vector3(0.49,0.012,0.70),glass)
			G.rounded_box(root,Vector3(side*0.55,0.60,tail+0.035),Vector3(0.59,0.13,0.015),red)
			for x in [0.52,0.66]:
				var pipe = G.cylinder(root,Vector3(side*x,0.25,tail),0.048,0.15,chrome,12)
				pipe.rotation.x = PI/2
		G.rounded_box(root,Vector3(0,0.62,tail),Vector3(1.60,0.24,0.06),black)
		G.rounded_box(root,Vector3(0,0.38,nose-0.05),Vector3(1.10,0.14,0.03),G.detail(Color(0.5,0.5,0.5),2,0.1,0.8))
		G.rounded_box(root,Vector3(0,0.84,tail-0.12),Vector3(1.47,0.045,0.16),paint)
	G.merge_static(root)
	root.set_meta("wheels",wheels(root,axle,half-0.08,radius,chrome,black,5 if sports else (8 if kei else 10)))
	return root

static func arch(z: float,axle: float,radius: float) -> float:
	var d = minf(absf(z-axle),absf(z+axle))
	var r = radius+0.035
	return radius+sqrt(r*r-d*d) if d<r else 0.25

static func wheels(root: Node3D,axle: float,width: float,radius: float,chrome: Material,black: Material,spokes: int) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var rubber = G.detail(Color(0.5,0.5,0.5),1,0.0,0.95)
	for side in [-1.0,1.0]:
		for z in [-axle,axle]:
			var hub = Node3D.new()
			root.add_child(hub)
			hub.position = Vector3(side*width,radius,z)
			hub.set_meta("front",z<0)
			var spin = Node3D.new()
			hub.add_child(spin)
			var tire = G.cylinder(spin,Vector3.ZERO,radius,0.20,rubber,32)
			tire.rotation.z = PI/2
			var rim = G.cylinder(spin,Vector3(side*0.11,0,0),radius*0.72,0.018,chrome,32)
			rim.rotation.z = PI/2
			var disc = G.cylinder(spin,Vector3(side*0.125,0,0),radius*0.63,0.016,black,32)
			disc.rotation.z = PI/2
			for j in range(spokes):
				var a = TAU*j/spokes
				var spoke = G.rounded_box(spin,Vector3(side*0.14,sin(a)*radius*0.35,cos(a)*radius*0.35),Vector3(0.025,0.055 if spokes==5 else 0.03,radius*0.63),chrome)
				spoke.rotation.x = -a
			G.merge_static(spin)
			result.append(hub)
	return result
