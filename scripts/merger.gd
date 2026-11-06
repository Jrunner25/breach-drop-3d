# THE MERGER: a Liquidator siege-excavator. A rolling wall of plate with a
# bulldozer shield across its front — fire bounces off it. Flank it and put
# rounds into the glowing coolant vent on its BACK. Dual plasma cannons keep
# you honest at range. (Ported from the pygame BREACH-DROP "Merger".)
extends CharacterBody3D

const ProjectileScript = preload("res://scripts/projectile.gd")
const DebrisScript = preload("res://scripts/debris.gd")

var main: Node3D
var armor_tier := 4           # bulldozer plate: medium pen only chips it
var health := 1400.0
var max_health := 1400.0
var speed := 3.0
var hold_range := 16.0
var fire_timer := 1.5
var chill_t := 0.0
var t := 0.0

var body_root: Node3D
var vent: MeshInstance3D
var vent_mat: StandardMaterial3D
var shield_mat: StandardMaterial3D
var treads: Array = []

const FRONT_MULT := 0.12   # the bulldozer shield eats frontal fire
const VENT_MULT  := 1.8    # the exposed coolant vent is the kill spot


func _ready() -> void:
	add_to_group("enemies")
	safe_margin = 0.08

	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.4, 3.4, 4.2)
	cs.shape = box
	cs.position = Vector3(0, 1.9, 0)
	add_child(cs)

	body_root = Node3D.new()
	add_child(body_root)

	var plate := StandardMaterial3D.new()
	plate.albedo_color = Color(0.42, 0.45, 0.52)
	plate.roughness = 0.45
	plate.metallic = 0.6
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.14, 0.15, 0.18)
	dark.roughness = 0.5
	dark.metallic = 0.4
	shield_mat = StandardMaterial3D.new()
	shield_mat.albedo_color = Color(0.30, 0.33, 0.40)
	shield_mat.roughness = 0.3
	shield_mat.metallic = 0.75
	vent_mat = StandardMaterial3D.new()
	vent_mat.emission_enabled = true
	vent_mat.emission = Color(1.0, 0.55, 0.15)      # coolant-radiator glow
	vent_mat.emission_energy_multiplier = 2.6
	vent_mat.albedo_color = Color(0.35, 0.16, 0.05)

	# Main hull
	var hull := MeshInstance3D.new()
	var hb := BoxMesh.new()
	hb.size = Vector3(3.0, 2.6, 3.6)
	hull.mesh = hb
	hull.material_override = plate
	hull.position = Vector3(0, 2.3, 0)
	body_root.add_child(hull)

	# Cab / crown
	var cab := MeshInstance3D.new()
	var cbm := BoxMesh.new()
	cbm.size = Vector3(2.0, 1.1, 1.8)
	cab.mesh = cbm
	cab.material_override = dark
	cab.position = Vector3(0, 3.9, 0.4)
	body_root.add_child(cab)

	# Bulldozer shield across the FRONT (forward is -Z)
	var shield := MeshInstance3D.new()
	var shm := BoxMesh.new()
	shm.size = Vector3(4.2, 3.2, 0.5)
	shield.mesh = shm
	shield.material_override = shield_mat
	shield.position = Vector3(0, 1.9, -2.2)
	body_root.add_child(shield)
	# angled blade lip
	var lip := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(4.2, 0.9, 0.9)
	lip.mesh = lm
	lip.material_override = shield_mat
	lip.position = Vector3(0, 0.5, -2.5)
	lip.rotation_degrees = Vector3(35, 0, 0)
	body_root.add_child(lip)

	# Dual plasma cannons flanking the cab
	for sx in [-1.0, 1.0]:
		var brl := MeshInstance3D.new()
		var bc := CylinderMesh.new()
		bc.top_radius = 0.18
		bc.bottom_radius = 0.22
		bc.height = 2.2
		brl.mesh = bc
		brl.material_override = dark
		brl.rotation_degrees = Vector3(90, 0, 0)
		brl.position = Vector3(1.1 * sx, 2.7, -1.6)
		body_root.add_child(brl)

	# The WEAK POINT: a glowing coolant vent on the BACK (+Z)
	vent = MeshInstance3D.new()
	var vm := BoxMesh.new()
	vm.size = Vector3(2.0, 1.6, 0.5)
	vent.mesh = vm
	vent.material_override = vent_mat
	vent.position = Vector3(0, 2.3, 1.95)
	body_root.add_child(vent)
	# vent grille fins
	for i in range(4):
		var fin := MeshInstance3D.new()
		var fm := BoxMesh.new()
		fm.size = Vector3(1.9, 0.12, 0.1)
		fin.mesh = fm
		fin.material_override = dark
		fin.position = Vector3(0, 1.7 + i * 0.35, 2.2)
		body_root.add_child(fin)

	# Tracks
	for sx2 in [-1.0, 1.0]:
		var trk := MeshInstance3D.new()
		var tm := BoxMesh.new()
		tm.size = Vector3(0.7, 0.9, 4.0)
		trk.mesh = tm
		trk.material_override = dark
		trk.position = Vector3(1.6 * sx2, 0.5, 0)
		body_root.add_child(trk)
		treads.append(trk)

	# Rise out of the ground on deploy
	body_root.scale = Vector3(1, 0.05, 1)
	var tw := create_tween()
	tw.tween_property(body_root, "scale", Vector3.ONE, 0.6) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func apply_chill(dur: float) -> void:
	chill_t = maxf(chill_t, dur)


# Directional armor: the front shield shrugs off fire; the back vent is fatal.
func take_damage_at(amount: float, pos: Vector3) -> bool:
	var to_hit := pos - global_position
	to_hit.y = 0.0
	if to_hit.length() > 0.05:
		to_hit = to_hit.normalized()
		var fwd := -global_transform.basis.z   # the shield faces this way
		var d := to_hit.dot(fwd)
		if d > 0.45:
			amount *= FRONT_MULT                # clanged off the bulldozer shield
			_spark()
		elif d < -0.4:
			amount *= VENT_MULT                 # cooked the coolant vent
			vent_mat.emission_energy_multiplier = 7.0
			var tw := create_tween()
			tw.tween_property(vent_mat, "emission_energy_multiplier", 2.6, 0.4)
			DebrisScript.burst(main, pos, Color(1.0, 0.55, 0.15), 5, 5.0)
	return take_damage(amount)


func _spark() -> void:
	DebrisScript.burst(main, global_position + Vector3(0, 1.9, 0) \
		- global_transform.basis.z * 2.3, Color(0.7, 0.75, 0.85), 2, 3.0)


func take_damage(amount: float) -> bool:
	health -= amount
	if health <= 0.0:
		main.on_enemy_died(3200, global_position)
		main.sfx("shatter", -4.0)
		for i in range(3):
			var p := global_position + Vector3(randf_range(-2, 2),
											   randf_range(1, 4), randf_range(-2, 2))
			main.get_tree().create_timer(i * 0.25).timeout.connect(
				func() -> void: main._explosion_fx(p, 4.0))
		DebrisScript.burst(main, global_position + Vector3(0, 2, 0),
						   Color(0.42, 0.45, 0.52), 12, 9.0)
		queue_free()
		return true
	return false


func _physics_process(delta: float) -> void:
	if main.state != "playing":
		return
	t += delta
	fire_timer -= delta
	chill_t = maxf(0.0, chill_t - delta)

	var tgt: Node3D = main.nearest_target(global_position)
	if tgt == null:
		velocity.x = 0
		velocity.z = 0
	else:
		var to_t := tgt.global_position - global_position
		to_t.y = 0
		var dist := to_t.length()
		var dir := to_t.normalized()
		# Keep the shield squared at the target
		rotation.y = lerp_angle(rotation.y, atan2(-to_t.x, -to_t.z), 1.4 * delta)
		var mult := 0.5 if chill_t > 0.0 else 1.0
		if dist > hold_range:
			velocity.x = dir.x * speed * mult
			velocity.z = dir.z * speed * mult
		else:
			velocity.x = 0
			velocity.z = 0
		if fire_timer <= 0.0 and dist < 60.0:
			fire_timer = 1.6
			_plasma_volley(tgt)

	# tread churn
	for trk in treads:
		trk.position.y = 0.5 + sin(t * 8.0) * 0.03

	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()


func _plasma_volley(tgt: Node3D) -> void:
	for sx in [-1.0, 1.0]:
		var origin := global_position + global_transform.basis * Vector3(1.1 * sx, 2.7, -2.2)
		var aim: Vector3 = tgt.global_position + Vector3(0, 0.9, 0)
		var dir := (aim - origin).normalized()
		dir = dir.rotated(Vector3.UP, randf_range(-0.03, 0.03))
		var shot := ProjectileScript.new()
		shot.velocity = dir * 48.0
		shot.damage = 22.0
		shot.aoe = 1.6
		shot.shooter = self
		shot.main = main
		shot.color = Color(0.5, 0.85, 1.0)
		shot.thickness = 0.13
		shot.glow = 6.0
		shot.life = 4.0
		main.add_child(shot)
		shot.global_position = origin
	main.sfx("boom", -18.0)
