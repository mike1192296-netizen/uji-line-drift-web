extends RefCounted
# SI units; catalogue anchors and explicitly estimated parameters documented in data/POWERTRAIN.md.
const SPECS = [
 {"name":"GRS184 3.5 / 6AT","ps":315,"kw":232.0,"nm":377.0,"torque_rpm":4800.0,"power_rpm":6400.0,"mass":1620.0,"radius":0.32985,"gears":[3.520,2.042,1.400,1.000,0.716,0.586],"final":3.769,"cvt":false,"ff":false,"redline":6800.0,"cda":0.65,"eff":0.86,"launch":2300.0,"shift":0.22,"limit":180.0},
 {"name":"R50 2001 / 5MT AUTO","ps":115,"kw":85.0,"nm":149.0,"torque_rpm":4500.0,"power_rpm":6000.0,"mass":1050.0,"radius":0.30425,"gears":[3.417,1.947,1.333,1.054,0.846],"final":3.940,"cvt":false,"ff":true,"redline":6800.0,"cda":0.65,"eff":0.90,"launch":2500.0,"shift":0.30,"limit":0.0},
 {"name":"ZRR70W ZS / CVT","ps":158,"kw":116.0,"nm":196.0,"torque_rpm":4400.0,"power_rpm":6200.0,"mass":1590.0,"radius":0.3262,"gears":[2.396,0.428],"final":5.470,"cvt":true,"ff":true,"redline":6600.0,"cda":0.96,"eff":0.84,"launch":2200.0,"shift":0.0,"limit":180.0},
 {"name":"GR86 RZ / 6MT AUTO","ps":235,"kw":173.0,"nm":250.0,"torque_rpm":3700.0,"power_rpm":7000.0,"mass":1270.0,"radius":0.3146,"gears":[3.626,2.188,1.541,1.213,1.000,0.767],"final":4.100,"cvt":false,"ff":false,"redline":7500.0,"cda":0.79,"eff":0.84,"launch":3200.0,"shift":0.20,"limit":180.0},
 {"name":"TANTO X NA / D-CVT","ps":52,"kw":38.0,"nm":60.0,"torque_rpm":3600.0,"power_rpm":6900.0,"mass":910.0,"radius":0.27855,"gears":[3.316,0.501],"final":5.444,"cvt":true,"ff":true,"redline":7300.0,"cda":0.86,"eff":0.85,"launch":2400.0,"shift":0.0,"limit":140.0},
 {"name":"ALPHARD Z 2.5 / CVT","ps":182,"kw":134.0,"nm":235.0,"torque_rpm":4100.0,"power_rpm":6000.0,"mass":2060.0,"radius":0.3636,"gears":[2.517,0.390],"final":5.791,"cvt":true,"ff":true,"redline":6500.0,"cda":1.04,"eff":0.84,"launch":2200.0,"shift":0.0,"limit":180.0},
 {"name":"Z32 TWIN TURBO / 5MT AUTO","ps":280,"kw":206.0,"nm":388.0,"torque_rpm":3600.0,"power_rpm":6400.0,"mass":1510.0,"radius":0.3157,"gears":[3.214,1.925,1.302,1.000,0.752],"final":3.692,"cvt":false,"ff":false,"redline":7000.0,"cda":0.62,"eff":0.88,"launch":2800.0,"shift":0.28,"limit":180.0},
 {"name":"DJ DEMIO 2016 13S / 6AT","ps":92,"kw":68.0,"nm":121.0,"torque_rpm":4000.0,"power_rpm":6000.0,"mass":1030.0,"radius":0.30225,"gears":[3.529,2.025,1.348,1.000,0.742,0.594],"final":4.060,"cvt":false,"ff":true,"redline":6500.0,"cda":0.64,"eff":0.87,"launch":2300.0,"shift":0.25,"limit":180.0}
]
var spec: Dictionary
var gear = 0
var ratio = 1.0
var rpm = 800.0
var shift_remaining = 0.0
var shift_hold = 0.0
var wheelspin = 0.0
var limiter_enabled = true
var boost = 0.0
var vehicle_id = 0

func setup(id: int) -> void:
	vehicle_id = clampi(id,0,SPECS.size()-1)
	spec = SPECS[vehicle_id]
	reset()

func reset() -> void:
	gear = 0
	ratio = spec.gears[0]
	rpm = 800
	shift_remaining = 0
	shift_hold = 0
	wheelspin = 0
	boost = 0

func torque_at(revs: float) -> float:
	# Interpolate unknown curve shape through the two published peak anchors.
	var power_torque = spec.kw*1000.0/(spec.power_rpm*TAU/60.0)
	var x = [800.0,spec.torque_rpm*0.55,spec.torque_rpm,spec.power_rpm,spec.redline]
	var y = [spec.nm*0.55,spec.nm*0.85,spec.nm,power_torque,power_torque*0.78]
	var torque: float = y[-1]
	if revs<=x[0]: torque = y[0]
	else:
		for i in range(x.size()-1):
			if revs<=x[i+1]:
				torque = lerpf(y[i],y[i+1],(revs-x[i])/(x[i+1]-x[i]))
				break
	return minf(torque,minf(spec.nm,spec.kw*1000.0/maxf(revs*TAU/60.0,1)))

func step(dt: float,speed: float,throttle: float,brake: float,slope: float = 0.0,slip: float = 0.0) -> float:
	speed = maxf(0,speed)
	throttle = clampf(throttle,0,1)
	brake = clampf(brake,0,1)
	shift_remaining = maxf(0,shift_remaining-dt)
	shift_hold = maxf(0,shift_hold-dt)
	var wheel_rpm = speed/spec.radius*60.0/TAU
	var coupled = wheel_rpm*ratio*spec.final
	if spec.cvt:
		var target_rpm = lerpf(1400.0,spec.power_rpm,pow(throttle,0.7))
		if brake>0.1: target_rpm = maxf(target_rpm,2600.0)
		var target_ratio = clampf(target_rpm/maxf(wheel_rpm*spec.final,1),spec.gears[1],spec.gears[0])
		ratio = move_toward(ratio,target_ratio,dt*2.2)
	else:
		var upshift = lerpf(2300.0,spec.redline-220.0,throttle)
		if shift_hold<=0:
			if coupled>upshift and gear<spec.gears.size()-1:
				gear += 1
				shift_remaining = spec.shift
				shift_hold = 0.65
			elif gear>0:
				var down_rpm = wheel_rpm*spec.gears[gear-1]*spec.final
				if coupled<lerpf(1250.0,spec.power_rpm*0.48,throttle) and down_rpm<upshift-450:
					gear -= 1
					shift_remaining = spec.shift
					shift_hold = 0.65
		ratio = spec.gears[gear]
	coupled = wheel_rpm*ratio*spec.final
	# Simplified launch clutch/torque-converter slip; no free extra power.
	rpm = maxf(800.0,maxf(coupled,lerpf(800.0,spec.launch,throttle)))
	var torque = torque_at(minf(rpm,spec.redline))*throttle
	if vehicle_id==6:
		boost = move_toward(boost,throttle,dt*2.5)
		torque *= lerpf(0.72,1.0,boost)
	if coupled>=spec.redline or (limiter_enabled and spec.limit>0 and speed*3.6>=spec.limit): torque = 0
	if shift_remaining>0: torque *= 0.15
	var force = torque*ratio*spec.final*spec.eff/spec.radius
	var mass: float = spec.mass+75.0
	# Approximate driven-axle traction, reduced by lateral slip and braking load transfer.
	var traction = mass*9.81*(0.55 if spec.ff else 0.65)*clampf(1.0-absf(slip)*0.40-brake*0.18,0.40,1.0)
	wheelspin = maxf(0,force/traction-1.0)
	force = minf(force,traction)
	var resistance = 0.5*1.225*spec.cda*speed*speed+mass*9.81*0.012
	var engine_brake = (1-throttle)*torque_at(rpm)*0.055*ratio*spec.final/spec.radius*minf(speed/3,1)
	var acceleration = (force-resistance-engine_brake)/mass-slope*9.81-brake*9.5
	rpm = minf(rpm,spec.redline)
	return maxf(0,speed+acceleration*dt)

func gear_text() -> String:
	return "CVT %.2f"%ratio if spec.cvt else "GEAR %d"%(gear+1)
