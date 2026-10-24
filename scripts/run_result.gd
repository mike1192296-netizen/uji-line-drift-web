extends RefCounted
const CONTACT_PENALTY = 3.0
const CLEAR_TIME = 0.6
var elapsed = 0.0
var penalty = 0.0
var contacts = 0
var finished = false
var touching = false
var clear_elapsed = 0.0
var notice = 0.0

func reset() -> void:
	elapsed = 0
	penalty = 0
	contacts = 0
	finished = false
	touching = false
	clear_elapsed = 0
	notice = 0

func advance(dt: float,hit: bool) -> void:
	if finished: return
	elapsed += maxf(dt,0)
	notice = maxf(0,notice-dt)
	if hit:
		if not touching:
			contacts += 1
			penalty += CONTACT_PENALTY
			notice = 1.5
			touching = true
		clear_elapsed = 0
	elif touching:
		clear_elapsed += dt
		if clear_elapsed>=CLEAR_TIME:
			touching = false
			clear_elapsed = 0

func total() -> float:
	return elapsed+penalty

static func clock(seconds: float) -> String:
	if seconds<0: return "--:--.--"
	var ticks = int(floor(seconds*100.0+0.00001))
	return "%02d:%02d.%02d" % [ticks/6000,(ticks/100)%60,ticks%100]
