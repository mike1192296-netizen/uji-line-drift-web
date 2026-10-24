extends RefCounted
const G = preload("res://scripts/geometry.gd")
const NAMES = ["ATHLETE SEDAN", "R50 COOPER", "70 VOXY", "GR86", "TANTO", "ALPHARD", "Z32 300ZX"]
const NOTES = ["FR / 3.5 class / flowing power slides", "FF / 1.6 class / lift-off and brake rotation", "FF / 2.0 class / heavier, calmer response", "FR / 2.4 class / light, quick drift response", "FF / kei class / light and nimble", "FF / luxury van / heavy, smooth response", "FR / V6 turbo class / powerful, planted"]

static func build(parent: Node3D,id: int) -> Node3D:
	if id==0: return G.car(parent)
	if id==1: return preload("res://scripts/compact.gd").build(parent)
	if id>=4: return preload("res://scripts/extra_cars.gd").build(parent,id)
	return build_variant(parent,id==2)

static func build_variant(parent: Node3D,van: bool) -> Node3D:
	var root = Node3D.new()
	root.name = "Voxy70Inspired" if van else "GR86Inspired"
	parent.add_child(root)
	var paint = G.detail(Color(0.055,0.048,0.075) if van else Color(0.60,0.035,0.025),3,0.25,0.23)
	var black = G.material(Color(0.016,0.02,0.023))
	var glass = G.material(Color(0.04,0.07,0.09),0.4)
	glass.roughness = 0.18
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var chrome = G.material(Color(0.60,0.64,0.67),0.85)
	var lens = G.detail(Color(0.85,0.91,0.96),0,0.5,0.2)
	var red = G.material(Color(0.45,0.01,0.015),0.2)
	red.emission_enabled = true
	red.emission = Color(0.6,0.01,0.01)
	red.emission_energy_multiplier = 0.35
	root.set_meta("brake_material",red)
	var length = 4.60 if van else 4.265
	var halfwidth = 0.85 if van else 0.8875
	var axle = 1.41 if van else 1.2875
	var shoulder = 1.04 if van else 0.84
	var sections = [[-length/2,0.82,shoulder-0.20],[-length/2+0.18,0.96,shoulder-0.04],[-axle,1.0,shoulder],[-0.65,1.0,shoulder],[0.7,1.0,shoulder],[axle,1.0,shoulder], [length/2-0.15,0.95,shoulder-0.02],[length/2,0.85,shoulder-0.12]]
	var rings: Array = []
	for sec in sections:
		var w: float = halfwidth*sec[1]
		var z: float = sec[0]
		var h: float = sec[2]
		rings.append([Vector3(-w,shoulder-0.2,z),Vector3(-w*0.95,h-0.04,z),Vector3(0,h,z),Vector3(w*0.95,h-0.04,z),Vector3(w,shoulder-0.2,z)])
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(rings.size()-1):
		for j in range(4): G.quad(st,rings[i][j],rings[i+1][j],rings[i+1][j+1],rings[i][j+1])
	G.finish(root,st,paint)
	for side in [-1.0,1.0]:
		var panels = SurfaceTool.new()
		panels.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(120):
			var za = -length/2+length*float(i)/120
			var zb = -length/2+length*float(i+1)/120
			var wa = halfwidth*lerpf(1,0.85,clampf((absf(za)-(length/2-0.2))/0.2,0,1))
			var wb = halfwidth*lerpf(1,0.85,clampf((absf(zb)-(length/2-0.2))/0.2,0,1))
			G.quad(panels,Vector3(side*wa,arch(za,axle),za),Vector3(side*wb,arch(zb,axle),zb),Vector3(side*wb,shoulder-0.18,zb),Vector3(side*wa,shoulder-0.18,za))
		G.finish(root,panels,paint)
		G.rounded_box(root,Vector3(side*(halfwidth-0.02),0.27,0),Vector3(0.06,0.10,axle*1.4),paint)
	G.rounded_box(root,Vector3(0,0.63,-length/2+0.02),Vector3(halfwidth*1.70,0.47,0.10),paint)
	G.rounded_box(root,Vector3(0,0.66,length/2-0.02),Vector3(halfwidth*1.70,0.55,0.10),paint)
	if van:
		# Tall 70-series silhouette, short bonnet, long roof and upright rear hatch.
		G.patch(root,[Vector3(-0.80,1.05,-1.55),Vector3(-0.72,1.79,-0.91),Vector3(0.72,1.79,-0.91),Vector3(0.80,1.05,-1.55)],glass)
		G.patch(root,[Vector3(-0.76,1.16,2.21),Vector3(0.76,1.16,2.21),Vector3(0.72,1.79,2.10),Vector3(-0.72,1.79,2.10)],glass)
		G.rounded_box(root,Vector3(0,1.84,0.58),Vector3(1.48,0.10,3.12),paint)
		for side in [-1.0,1.0]:
			G.patch(root,[Vector3(side*0.81,1.05,-1.50),Vector3(side*0.73,1.79,-0.90),Vector3(side*0.73,1.79,2.08),Vector3(side*0.81,1.05,2.19)],glass)
			for z in [-0.91,0.10,1.35,2.10]:
				G.beam(root,Vector3(side*0.81,1.02,z),Vector3(side*0.74,1.83,z),0.09,0.09,paint)
			G.beam(root,Vector3(side*0.81,1.04,-1.55),Vector3(side*0.73,1.81,-0.91),0.14,0.12,paint)
			for z in [0.05,1.25]:
				G.beam(root,Vector3(side*0.853,0.34,z),Vector3(side*0.853,1.03,z),0.008,0.008,black)
				G.rounded_box(root,Vector3(side*0.862,0.95,z-0.12),Vector3(0.03,0.04,0.20),chrome)
			G.beam(root,Vector3(side*0.856,0.89,0.65),Vector3(side*0.856,0.89,2.12),0.018,0.018,chrome)
			G.rounded_box(root,Vector3(side*0.93,1.17,-1.19),Vector3(0.24,0.23,0.23),paint)
			G.rounded_box(root,Vector3(side*0.60,0.98,-2.26),Vector3(0.40,0.12,0.07),lens)
			G.rounded_box(root,Vector3(side*0.60,0.82,-2.29),Vector3(0.36,0.12,0.07),lens)
			G.rounded_box(root,Vector3(side*0.72,1.16,2.28),Vector3(0.14,0.77,0.06),red)
			for y in [0.90,1.08,1.25]: G.rounded_box(root,Vector3(side*0.72,y,2.315),Vector3(0.13,0.055,0.01),lens)
		G.rounded_box(root,Vector3(0,0.89,-2.31),Vector3(0.72,0.23,0.025),black)
		for y in [0.81,0.87,0.93,0.99]: G.rounded_box(root,Vector3(0,y,-2.33),Vector3(0.73,0.025,0.02),chrome)
	else:
		# Low coupe cabin, swept headlamps and broad lower grille.
		G.patch(root,[Vector3(-0.79,0.89,-0.80),Vector3(-0.67,1.28,-0.29),Vector3(0.67,1.28,-0.29),Vector3(0.79,0.89,-0.80)],glass)
		G.patch(root,[Vector3(-0.77,0.89,1.35),Vector3(0.77,0.89,1.35),Vector3(0.64,1.28,0.52),Vector3(-0.64,1.28,0.52)],glass)
		G.patch(root,[Vector3(-0.68,1.29,-0.30),Vector3(-0.65,1.30,0.54),Vector3(0.65,1.30,0.54),Vector3(0.68,1.29,-0.30)],paint)
		for side in [-1.0,1.0]:
			G.patch(root,[Vector3(side*0.79,0.9,-0.78),Vector3(side*0.67,1.27,-0.28),Vector3(side*0.64,1.27,0.52),Vector3(side*0.77,0.90,1.30)],glass)
			G.beam(root,Vector3(side*0.80,0.9,-0.82),Vector3(side*0.68,1.29,-0.30),0.065,0.065,paint)
			G.beam(root,Vector3(side*0.77,0.89,1.35),Vector3(side*0.64,1.30,0.52),0.11,0.09,paint)
			G.beam(root,Vector3(side*0.80,0.89,0.50),Vector3(side*0.65,1.28,0.40),0.05,0.05,black)
			G.beam(root,Vector3(side*0.889,0.30,0.62),Vector3(side*0.889,0.84,0.62),0.008,0.008,black)
			G.rounded_box(root,Vector3(side*0.90,0.80,0.45),Vector3(0.025,0.027,0.18),paint)
			G.rounded_box(root,Vector3(side*0.95,0.92,-0.60),Vector3(0.18,0.11,0.22),paint)
			G.patch(root,[Vector3(side*0.40,0.68,-2.11),Vector3(side*0.47,0.81,-2.10),Vector3(side*0.82,0.82,-1.96),Vector3(side*0.78,0.71,-2.04)],lens)
			G.rounded_box(root,Vector3(side*0.64,0.73,2.08),Vector3(0.36,0.13,0.05),red)
			var pipe = G.cylinder(root,Vector3(side*0.65,0.25,2.10),0.075,0.18,chrome,16)
			pipe.rotation.x = PI/2
		G.rounded_box(root,Vector3(0,0.47,-2.17),Vector3(1.05,0.22,0.03),G.detail(Color(0.6,0.6,0.6),2,0.1,0.8))
		G.rounded_box(root,Vector3(0,0.79,2.10),Vector3(1.45,0.025,0.03),black)
		G.rounded_box(root,Vector3(0,0.88,1.95),Vector3(1.40,0.04,0.13),paint)
	for z in [-length/2+0.03,length/2-0.03]:
		G.rounded_box(root,Vector3(0,0.48,z),Vector3(halfwidth*1.72,0.25,0.10),paint)
		G.rounded_box(root,Vector3(0,0.57,z+signf(z)*0.06),Vector3(0.33,0.15,0.015),G.material(Color(0.8,0.8,0.76)))
	G.merge_static(root)
	root.set_meta("wheels",wheels(root,axle,halfwidth-0.09,black,chrome,van))
	return root

static func arch(z: float,axle: float) -> float:
	var d = minf(absf(z-axle),absf(z+axle))
	return 0.34+sqrt(0.37*0.37-d*d) if d<0.37 else 0.26

static func wheels(root: Node3D,axle: float,width: float,black: Material,chrome: Material,van: bool) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for side in [-1.0,1.0]:
		for z in [-axle,axle]:
			var hub = Node3D.new()
			root.add_child(hub)
			hub.position = Vector3(side*width,0.34,z)
			var spin = Node3D.new()
			hub.add_child(spin)
			var tire = G.cylinder(spin,Vector3.ZERO,0.33,0.22,G.detail(Color(0.5,0.5,0.5),1,0.0,0.95),32)
			tire.rotation.z = PI/2
			var ring = G.cylinder(spin,Vector3(side*0.12,0,0),0.235,0.02,chrome,24)
			ring.rotation.z = PI/2
			var disc = G.cylinder(spin,Vector3(side*0.133,0,0),0.205,0.016,black,24)
			disc.rotation.z = PI/2
			for j in range(8 if van else 10):
				var angle = TAU*float(j)/(8 if van else 10)
				var spoke = G.rounded_box(spin,Vector3(side*0.145,sin(angle)*0.12,cos(angle)*0.12),Vector3(0.026,0.035,0.21),chrome)
				spoke.rotation.x = -angle
			G.merge_static(spin)
			hub.set_meta("front",z<0)
			result.append(hub)
	return result
