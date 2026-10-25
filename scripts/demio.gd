extends RefCounted
const G = preload("res://scripts/geometry.gd")
const Extra = preload("res://scripts/extra_cars.gd")
# Original DJ-inspired five-door mesh. 2016 13S 2WD proportions; no scanned assets.
static func build(parent: Node3D) -> Node3D:
	var root = Node3D.new()
	root.name = "DJDemio13SInspired"
	parent.add_child(root)
	var paint = G.detail(Color(0.54,0.025,0.035),3,0.38,0.22)
	var black = G.material(Color(0.018,0.022,0.026))
	var chrome = G.material(Color(0.65,0.68,0.71),0.80)
	var glass = G.material(Color(0.025,0.055,0.075),0.35)
	glass.roughness = 0.18
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var lens = G.detail(Color(0.88,0.93,0.97),0,0.35,0.20)
	var red = G.material(Color(0.55,0.012,0.018),0.2)
	red.emission_enabled = true
	red.emission = Color(0.70,0.012,0.018)
	red.emission_energy_multiplier = 0.35
	root.set_meta("brake_material",red)
	# Long bonnet, pinched nose, curved shoulder and short five-door hatch.
	var sections = [[-2.03,0.62,0.75],[-1.88,0.77,0.88],[-1.55,0.83,0.94],[-1.20,0.8475,0.98],[-0.70,0.84,1.01],[0.10,0.835,1.02],[0.85,0.8475,1.05],[1.38,0.83,1.04],[1.80,0.79,0.98],[2.03,0.69,0.88]]
	var rings: Array = []
	for sec in sections:
		var z: float = sec[0]
		var w: float = sec[1]
		var h: float = sec[2]
		rings.append([Vector3(-w,0.78,z),Vector3(-w*0.97,h-0.05,z),Vector3(-w*0.65,h,z),Vector3(0,h+0.015,z),Vector3(w*0.65,h,z),Vector3(w*0.97,h-0.05,z),Vector3(w,0.78,z)])
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(rings.size()-1):
		for j in range(6): G.quad(st,rings[i][j],rings[i+1][j],rings[i+1][j+1],rings[i][j+1])
	G.finish(root,st,paint)
	for side in [-1.0,1.0]:
		var panel = SurfaceTool.new()
		panel.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(120):
			var a = -2.03+4.06*i/120.0
			var b = -2.03+4.06*(i+1)/120.0
			var wa = lerpf(0.8475,0.66,clampf((absf(a)-1.55)/0.48,0,1))
			var wb = lerpf(0.8475,0.66,clampf((absf(b)-1.55)/0.48,0,1))
			G.quad(panel,Vector3(side*wa,Extra.arch(a,1.285,0.30225),a),Vector3(side*wb,Extra.arch(b,1.285,0.30225),b),Vector3(side*wb,0.80,b),Vector3(side*wa,0.80,a))
		G.finish(root,panel,paint)
		G.rounded_box(root,Vector3(side*0.81,0.27,0),Vector3(0.07,0.10,1.88),paint)
		G.patch(root,[Vector3(side*0.79,1.03,-0.72),Vector3(side*0.65,1.46,-0.16),Vector3(side*0.64,1.46,1.04),Vector3(side*0.77,1.05,1.64)],glass)
		G.beam(root,Vector3(side*0.79,1.02,-0.72),Vector3(side*0.66,1.48,-0.16),0.075,0.065,paint)
		G.beam(root,Vector3(side*0.77,1.04,1.64),Vector3(side*0.65,1.48,1.04),0.15,0.10,paint)
		G.beam(root,Vector3(side*0.79,1.03,0.35),Vector3(side*0.65,1.47,0.35),0.085,0.065,black)
		G.beam(root,Vector3(side*0.79,1.03,-0.72),Vector3(side*0.77,1.05,1.64),0.025,0.025,black)
		for z in [0.34,1.35]:
			G.beam(root,Vector3(side*0.848,0.35,z),Vector3(side*0.848,0.98,z),0.008,0.008,black)
			G.rounded_box(root,Vector3(side*0.85,0.96,z-0.19),Vector3(0.025,0.035,0.17),paint)
		G.rounded_box(root,Vector3(side*0.91,1.06,-0.56),Vector3(0.20,0.12,0.23),paint)
		# Swept front lights and wide rear lamps distinguish DJ from the R50.
		G.patch(root,[Vector3(side*0.43,0.79,-1.99),Vector3(side*0.46,0.90,-1.90),Vector3(side*0.79,0.95,-1.58),Vector3(side*0.79,0.83,-1.75)],lens)
		G.rounded_box(root,Vector3(side*0.62,0.95,1.99),Vector3(0.36,0.15,0.05),red)
		G.rounded_box(root,Vector3(side*0.67,0.93,2.025),Vector3(0.15,0.045,0.012),lens)
	G.patch(root,[Vector3(-0.79,1.03,-0.73),Vector3(-0.65,1.47,-0.16),Vector3(0.65,1.47,-0.16),Vector3(0.79,1.03,-0.73)],glass)
	G.patch(root,[Vector3(-0.76,1.04,1.70),Vector3(0.76,1.04,1.70),Vector3(0.64,1.47,1.04),Vector3(-0.64,1.47,1.04)],glass)
	for side in [-1.0,1.0]:
		G.patch(root,[Vector3(0,1.525,-0.18),Vector3(0,1.525,1.09),Vector3(side*0.66,1.48,1.09),Vector3(side*0.67,1.48,-0.18)],paint)
	G.rounded_box(root,Vector3(0,0.53,-1.96),Vector3(1.46,0.36,0.13),paint)
	G.rounded_box(root,Vector3(0,0.54,1.98),Vector3(1.44,0.40,0.12),paint)
	# Five-point grille and slim silver signature wing (no badge/brand texture).
	G.patch(root,[Vector3(-0.44,0.83,-2.037),Vector3(-0.28,0.52,-2.055),Vector3(0.28,0.52,-2.055),Vector3(0.44,0.83,-2.037)],black)
	G.beam(root,Vector3(-0.44,0.84,-2.045),Vector3(-0.28,0.52,-2.065),0.025,0.025,chrome)
	G.beam(root,Vector3(-0.28,0.52,-2.065),Vector3(0.28,0.52,-2.065),0.025,0.025,chrome)
	G.beam(root,Vector3(0.28,0.52,-2.065),Vector3(0.44,0.84,-2.045),0.025,0.025,chrome)
	G.rounded_box(root,Vector3(0,0.39,-2.04),Vector3(0.90,0.09,0.022),black)
	G.rounded_box(root,Vector3(0,1.48,1.10),Vector3(1.33,0.045,0.16),paint)
	G.rounded_box(root,Vector3(0,1.44,1.19),Vector3(0.30,0.025,0.018),red)
	for z in [-2.075,2.055]:
		G.rounded_box(root,Vector3(0,0.61,z),Vector3(0.33,0.16,0.015),G.material(Color(0.82,0.82,0.77)))
	G.merge_static(root)
	root.set_meta("wheels",Extra.wheels(root,1.285,0.7475,0.30225,chrome,black,8))
	return root
