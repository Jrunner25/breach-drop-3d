# The Command Input Matrix: hold SHIFT, type the arrow code, release,
# click to throw the flare. The pod falls through real 3D airspace.
extends Node

const ProjectileScript = preload("res://scripts/projectile.gd")

const CODES := {
	"KINETIC_STRIKE":  ["left", "up", "down", "down", "left"],
	"THERMAL_BARRIER": ["down", "down", "up", "right"],
	"AMMO_POD":        ["up", "down", "right", "left", "up"],
	"SENTRY_TURRET":   ["down", "up", "right", "up"],
	"ORBITAL_LASER":   ["right", "down", "up", "up", "down"],
}
const COOLDOWN := {"KINETIC_STRIKE": 60.0, "THERMAL_BARRIER": 45.0,
				   "AMMO_POD": 40.0, "SENTRY_TURRET": 75.0, "ORBITAL_LASER": 120.0}
const NAMES := {
	"KINETIC_STRIKE": "Kinetic Strike",
	"THERMAL_BARRIER": "Thermal Barrier",
	"AMMO_POD": "Ammo Pod",
	"SENTRY_TURRET": "Sentry Turret",
	"ORBITAL_LASER": "Orbital Laser",
}
const FLARE_RED := Color(1.0, 0.25, 0.15)
const FLARE_BLUE := Color(0.3, 0.7, 1.0)

var main: Node3D
var open := false
var seq: Array = []
var taps := 0            # total inputs since SHIFT went down (for perfect codes)
var matched := ""
var armed := ""
var cooldowns := {"KINETIC_STRIKE": 0.0, "THERMAL_BARRIER": 0.0, "AMMO_POD": 0.0,
				  "SENTRY_TURRET": 0.0, "ORBITAL_LASER": 0.0}
var uses := {"ORBITAL_LASER": 3}   # the big asset has a per-mission budget
var lasers: Array = []   # active sweeping beams: [node, pos, dir, time_left]


func _process(delta: float) -> void:
	# Tech Evangelist visor: the timers tick a little faster
	var cdm := 1.0
	if main.player != null:
		cdm = main.player.cd_mult
	for k in cooldowns:
		cooldowns[k] = maxf(0.0, cooldowns[k] - delta * cdm)
	if main.state != "playing":
		return

	if Input.is_action_pressed("strat_open"):
		if not open:
			open = true
			seq.clear()
			taps = 0
			matched = ""
		for d in ["up", "down", "left", "right"]:
			if Input.is_action_just_pressed("strat_" + d):
				var entered: String = d
				if main.psi_t > 0.0:
					# psionic scramble: every arrow arrives rotated one notch
					entered = {"up": "right", "right": "down",
							   "down": "left", "left": "up"}[d]
				seq.append(entered)
				taps += 1
				if seq.size() > 5:
					seq.pop_front()
				_check_match()
	else:
		if open:
			open = false
			if matched != "" and main.anchor_retasked:
				main.hud.push_msg("THE VOID ANCHOR IS RETASKED — NO SUPPORT",
								  FLARE_RED)
				matched = ""
			if matched != "" and main.ion_t > 0.0:
				main.hud.push_msg("ION STORM — NO UPLINK TO THE ANCHOR",
								  Color(0.6, 0.7, 1.0))
				matched = ""
			if matched != "" and uses.get(matched, 999) <= 0:
				main.hud.push_msg(NAMES[matched].to_upper() + " EXPENDED",
								  FLARE_RED)
				matched = ""
			if matched != "" and cooldowns[matched] <= 0.0:
				armed = matched
				# Synergy Cascade: a perfect first-try code pays out team-wide
				if taps == CODES[matched].size() and main.player != null \
						and main.player.synergy == "TECH":
					for k in cooldowns:
						cooldowns[k] = maxf(0.0, cooldowns[k] - 5.0)
					main.hud.push_msg("SYNERGY CASCADE — ALL TIMERS -5 s",
									  Color(0.3, 1.0, 0.8))
				main.hud.push_msg(NAMES[matched] + " AUTHORIZED — CLICK TO THROW",
								  FLARE_RED if matched != "AMMO_POD" else FLARE_BLUE)
			seq.clear()
			matched = ""

	if armed != "" and Input.is_action_just_pressed("fire"):
		_throw_flare(armed)
		armed = ""

	# Active orbital lasers sweep the field, burning a line through everything
	for i in range(lasers.size() - 1, -1, -1):
		var L: Array = lasers[i]
		L[3] -= delta
		L[1] += L[2] * 5.0 * delta
		L[1].y = main.ground_height(L[1].x, L[1].z)
		var node: Node3D = L[0]
		node.global_position = L[1]
		for e in main.get_tree().get_nodes_in_group("enemies"):
			var flat: Vector3 = e.global_position - L[1]
			flat.y = 0.0
			if flat.length() < 3.5:
				e.take_damage(220.0 * delta)
		var p: CharacterBody3D = main.player
		if p != null and p.alive:
			var pf: Vector3 = p.global_position - L[1]
			pf.y = 0.0
			if pf.length() < 3.5:
				p.take_damage(120.0 * delta, true)
		if randf() < 6.0 * delta:
			main._explosion_fx(L[1], 1.5)
		if L[3] <= 0.0:
			node.queue_free()
			lasers.remove_at(i)


func _check_match() -> void:
	matched = ""
	for key in CODES:
		var code: Array = CODES[key]
		if seq.size() >= code.size() and seq.slice(seq.size() - code.size()) == code:
			matched = key
			return


func _throw_flare(key: String) -> void:
	cooldowns[key] = COOLDOWN[key]
	if uses.has(key):
		uses[key] -= 1
	var color: Color = FLARE_BLUE if key in ["AMMO_POD", "SENTRY_TURRET"] \
		else FLARE_RED

	var flare := RigidBody3D.new()
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.09
	cs.shape = sph
	flare.add_child(cs)
	var m := MeshInstance3D.new()
	var ms := SphereMesh.new()
	ms.radius = 0.09
	ms.height = 0.18
	m.mesh = ms
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 8.0
	mat.albedo_color = color
	m.material_override = mat
	flare.add_child(m)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 4.0
	light.omni_range = 8.0
	flare.add_child(light)

	main.add_child(flare)
	var p: CharacterBody3D = main.player
	flare.global_position = p.gun_tip.global_position
	var dir: Vector3 = (p.aim_point() - flare.global_position).normalized()
	# Tech Evangelist chassis: the beacon flies further
	flare.linear_velocity = dir * 16.0 * p.throw_mult + Vector3(0, 4.0, 0)

	# 2.2 seconds after the throw, the Void Anchor answers — longer where
	# the atmosphere fights the signal
	var fuse := 2.2
	if main.planet.get("interference", false):
		fuse *= 1.25
	get_tree().create_timer(fuse).timeout.connect(
		func() -> void:
			var pos: Vector3 = flare.global_position
			flare.queue_free()
			_drop_pod(key, Vector3(pos.x, 0, pos.z)))


func _drop_pod(key: String, target: Vector3) -> void:
	var pod := Node3D.new()
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.7, 2.4, 0.7)
	m.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.38, 0.45)
	mat.metallic = 0.7
	mat.roughness = 0.3
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.6, 0.2)
	mat.emission_energy_multiplier = 2.0
	m.add_child(_streak())
	pod.add_child(m)
	m.material_override = mat
	main.add_child(pod)
	pod.global_position = target + Vector3(0, 140, 0)

	# The pod screams down through the airspace, then the ground answers
	var duration: float = 140.0 / 95.0
	if main.planet.get("interference", false):
		duration *= 1.25
	var tw := main.get_tree().create_tween()
	tw.tween_property(pod, "global_position", target + Vector3(0, 1.2, 0), duration)
	tw.tween_callback(func() -> void:
		pod.queue_free()
		_impact(key, target))


func _streak() -> MeshInstance3D:
	var s := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.05
	cyl.bottom_radius = 0.16
	cyl.height = 26.0
	s.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.8, 0.5, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.3)
	mat.emission_energy_multiplier = 3.0
	s.material_override = mat
	s.position = Vector3(0, 14, 0)
	return s


func _impact(key: String, pos: Vector3) -> void:
	match key:
		"KINETIC_STRIKE":
			# 450mm tungsten rod. The blast checks distance, not IFF.
			main.explode(pos, 14.0, 900.0, true)
		"AMMO_POD":
			main._explosion_fx(pos, 2.0)
			_spawn_ammo_crate(pos)
		"THERMAL_BARRIER":
			main._explosion_fx(pos, 2.0)
			_spawn_barrier(pos)
		"SENTRY_TURRET":
			main._explosion_fx(pos, 1.5)
			_spawn_turret(pos)
		"ORBITAL_LASER":
			main.sfx("laser", -2.0)
			_spawn_laser(pos)


func _spawn_turret(pos: Vector3) -> void:
	# An automated gun that shoots whatever moves. Including you. Stay behind it.
	var turret := Node3D.new()
	main.add_child(turret)
	turret.global_position = pos
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.2, 0.22, 0.26)
	dark.metallic = 0.6
	dark.roughness = 0.4
	var base := MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(1.0, 0.5, 1.0)
	base.mesh = bb
	base.material_override = dark
	base.position = Vector3(0, 0.25, 0)
	turret.add_child(base)
	var head := Node3D.new()
	head.position = Vector3(0, 0.85, 0)
	turret.add_child(head)
	var body := MeshInstance3D.new()
	var hb := BoxMesh.new()
	hb.size = Vector3(0.5, 0.45, 0.7)
	body.mesh = hb
	body.material_override = dark
	head.add_child(body)
	var barrel := MeshInstance3D.new()
	var brl := CylinderMesh.new()
	brl.top_radius = 0.05
	brl.bottom_radius = 0.05
	brl.height = 0.9
	barrel.mesh = brl
	barrel.material_override = dark
	barrel.rotation_degrees = Vector3(90, 0, 0)
	barrel.position = Vector3(0, 0.05, -0.6)
	head.add_child(barrel)
	var eye := OmniLight3D.new()
	eye.light_color = Color(1.0, 0.4, 0.2)
	eye.light_energy = 1.0
	eye.omni_range = 3.0
	eye.position = Vector3(0, 0.3, 0)
	head.add_child(eye)

	var gun_timer := Timer.new()
	gun_timer.wait_time = 0.35
	gun_timer.autostart = true
	turret.add_child(gun_timer)
	gun_timer.timeout.connect(func() -> void:
		if not is_instance_valid(turret):
			return
		var best: Node3D = null
		var best_d := 30.0
		for e in main.get_tree().get_nodes_in_group("enemies"):
			var d: float = e.global_position.distance_to(turret.global_position)
			if d < best_d:
				best_d = d
				best = e
		if best == null:
			return
		var target: Vector3 = best.global_position + Vector3(0, 0.6, 0)
		head.look_at(target, Vector3.UP)
		var origin: Vector3 = head.global_position \
			+ (target - head.global_position).normalized() * 1.1
		var bolt := ProjectileScript.new()
		bolt.velocity = (target - origin).normalized() * 100.0
		bolt.damage = 18.0
		main.add_child(bolt)
		bolt.global_position = origin
		main.sfx("shoot", -16.0))
	get_tree().create_timer(30.0).timeout.connect(func() -> void:
		if is_instance_valid(turret):
			main._explosion_fx(turret.global_position, 2.0)
			turret.queue_free())


func _spawn_laser(pos: Vector3) -> void:
	# A pillar of coherent light walks across the field
	var node := Node3D.new()
	main.add_child(node)
	node.global_position = pos
	var beam := MeshInstance3D.new()
	var bc := CylinderMesh.new()
	bc.top_radius = 0.5
	bc.bottom_radius = 1.1
	bc.height = 160.0
	beam.mesh = bc
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.albedo_color = Color(1.0, 0.3, 0.2, 0.7)
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.emission_enabled = true
	bm.emission = Color(1.0, 0.3, 0.2)
	bm.emission_energy_multiplier = 4.0
	beam.material_override = bm
	beam.position = Vector3(0, 80, 0)
	node.add_child(beam)
	var gl := OmniLight3D.new()
	gl.light_color = Color(1.0, 0.35, 0.2)
	gl.light_energy = 12.0
	gl.light_volumetric_fog_energy = 4.0   # the beam carves the atmosphere
	gl.omni_range = 24.0
	gl.position = Vector3(0, 3, 0)
	node.add_child(gl)
	var ang := randf() * TAU
	lasers.append([node, pos, Vector3(cos(ang), 0, sin(ang)), 6.0])


func _spawn_ammo_crate(pos: Vector3) -> void:
	var crate := Node3D.new()
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.1, 1.0, 1.1)
	m.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.35, 0.5)
	mat.emission_enabled = true
	mat.emission = FLARE_BLUE
	mat.emission_energy_multiplier = 1.2
	m.material_override = mat
	m.position = Vector3(0, 0.5, 0)
	crate.add_child(m)
	main.add_child(crate)
	crate.global_position = pos

	var timer := Timer.new()
	timer.wait_time = 0.2
	timer.autostart = true
	crate.add_child(timer)
	timer.timeout.connect(func() -> void:
		if not is_instance_valid(crate):
			return
		var p: CharacterBody3D = main.player
		if p != null and p.alive and p.global_position.distance_to(crate.global_position) < 2.5:
			p.resupply()
			p.health = minf(p.max_health, p.health + 50.0)
			main.hud.push_msg("RESUPPLY SECURED", FLARE_BLUE)
			main.sfx("click", -4.0)
			crate.queue_free())
	get_tree().create_timer(25.0).timeout.connect(func() -> void:
		if is_instance_valid(crate):
			crate.queue_free())


func _spawn_barrier(pos: Vector3) -> void:
	var ring := Node3D.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.45, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.4, 0.05)
	mat.emission_energy_multiplier = 5.0
	var radius := 6.0
	for i in range(16):
		var ang := i * TAU / 16.0
		var m := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.02
		cyl.bottom_radius = 0.10
		cyl.height = randf_range(1.2, 2.2)
		m.mesh = cyl
		m.material_override = mat
		m.position = Vector3(cos(ang) * radius, cyl.height * 0.5, sin(ang) * radius)
		ring.add_child(m)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.5, 0.15)
	light.light_energy = 3.0
	light.omni_range = radius * 2.5
	light.position = Vector3(0, 1.5, 0)
	ring.add_child(light)
	main.add_child(ring)
	ring.global_position = pos

	# The heat wall melts small enemies for 10 seconds — and cooks you too
	var tick_timer := Timer.new()
	tick_timer.wait_time = 0.25
	tick_timer.autostart = true
	ring.add_child(tick_timer)
	tick_timer.timeout.connect(func() -> void:
		for e in main.get_tree().get_nodes_in_group("enemies"):
			if e.global_position.distance_to(ring.global_position) < radius:
				e.take_damage(16.0)
		var p: CharacterBody3D = main.player
		if p != null and p.alive \
				and p.global_position.distance_to(ring.global_position) < radius:
			p.take_damage(9.0, true))
	get_tree().create_timer(10.0).timeout.connect(func() -> void:
		if is_instance_valid(ring):
			ring.queue_free())
