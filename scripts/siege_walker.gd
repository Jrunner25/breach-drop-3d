# SIEGE WALKER: a nine-meter crystalline quadruped that strides over the
# dunes and shells you from range. Its hull shrugs off fire — shoot the
# glowing knee joints (3x damage) or learn to love the bombardment.
extends CharacterBody3D

const ProjectileScript = preload("res://scripts/projectile.gd")
const DebrisScript = preload("res://scripts/debris.gd")

var main: Node3D
var armor_tier := 4           # siege hull: medium pen only chips it. The knees.
var health := 2200.0
var max_health := 2200.0
var speed := 1.7
var burst_timer := 5.0
var burst_left := 0
var burst_gap := 0.0
var chill_t := 0.0
var body_root: Node3D
var legs: Array = []
var knees: Array = []          # knee marker nodes (weak points)
var knee_mat: StandardMaterial3D
var cannon: Node3D
var t := 0.0


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	safe_margin = 0.08

	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 2.4
	cap.height = 9.0
	cs.shape = cap
	cs.position = Vector3(0, 4.5, 0)
	add_child(cs)

	body_root = Node3D.new()
	add_child(body_root)
	var plate := StandardMaterial3D.new()
	plate.albedo_color = Color(0.42, 0.45, 0.40)
	plate.roughness = 0.5
	plate.metallic = 0.35
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.12, 0.12, 0.15)
	dark.roughness = 0.55
	knee_mat = StandardMaterial3D.new()
	knee_mat.emission_enabled = true
	knee_mat.emission = Color(0.75, 0.35, 1.0)
	knee_mat.emission_energy_multiplier = 2.2
	knee_mat.albedo_color = Color(0.2, 0.08, 0.28)

	# Four striding legs with exposed knee joints
	for i in range(4):
		var side := -1.0 if i % 2 == 0 else 1.0
		var fore := -1.0 if i < 2 else 1.0
		var hip := Node3D.new()
		hip.position = Vector3(1.8 * side, 6.2, 1.6 * fore)
		body_root.add_child(hip)
		legs.append(hip)
		var thigh := MeshInstance3D.new()
		var tc := CylinderMesh.new()
		tc.top_radius = 0.42
		tc.bottom_radius = 0.3
		tc.height = 3.4
		thigh.mesh = tc
		thigh.material_override = plate
		thigh.position = Vector3(0.7 * side, -1.5, 0)
		thigh.rotation_degrees = Vector3(0, 0, -22 * side)
		hip.add_child(thigh)
		var shin := MeshInstance3D.new()
		var sc := CylinderMesh.new()
		sc.top_radius = 0.26
		sc.bottom_radius = 0.4
		sc.height = 3.4
		shin.mesh = sc
		shin.material_override = dark
		shin.position = Vector3(1.35 * side, -4.6, 0)
		shin.rotation_degrees = Vector3(0, 0, 8 * side)
		hip.add_child(shin)
		# THE WEAK POINT: a glowing knee joint
		var knee := MeshInstance3D.new()
		var ks := SphereMesh.new()
		ks.radius = 0.5
		ks.height = 1.0
		knee.mesh = ks
		knee.material_override = knee_mat
		knee.position = Vector3(1.15 * side, -3.0, 0)
		hip.add_child(knee)
		knees.append(knee)

	# Hull: a fortress of plates with a chin cannon
	var hull := MeshInstance3D.new()
	var hb := BoxMesh.new()
	hb.size = Vector3(4.6, 2.8, 6.4)
	hull.mesh = hb
	hull.material_override = plate
	hull.position = Vector3(0, 7.4, 0)
	body_root.add_child(hull)
	var crown := MeshInstance3D.new()
	var cb := BoxMesh.new()
	cb.size = Vector3(3.0, 1.2, 3.6)
	crown.mesh = cb
	crown.material_override = dark
	crown.position = Vector3(0, 9.3, 0.4)
	body_root.add_child(crown)
	var eyes := MeshInstance3D.new()
	var eb := BoxMesh.new()
	eb.size = Vector3(1.6, 0.2, 0.1)
	eyes.mesh = eb
	eyes.material_override = knee_mat
	eyes.position = Vector3(0, 7.8, -3.25)
	body_root.add_child(eyes)
	# spinal crystal spikes
	for i in range(5):
		var sp := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.5, randf_range(1.2, 2.4), 0.5)
		sp.mesh = pm
		sp.material_override = dark
		sp.position = Vector3(randf_range(-1.0, 1.0), 9.6, -2.0 + i * 1.1)
		sp.rotation_degrees = Vector3(randf_range(15, 40), 0, randf_range(-15, 15))
		body_root.add_child(sp)

	cannon = Node3D.new()
	cannon.position = Vector3(0, 6.4, -3.4)
	body_root.add_child(cannon)
	var barrel := MeshInstance3D.new()
	var brl := CylinderMesh.new()
	brl.top_radius = 0.22
	brl.bottom_radius = 0.3
	brl.height = 2.6
	barrel.mesh = brl
	barrel.material_override = dark
	barrel.rotation_degrees = Vector3(90, 0, 0)
	barrel.position = Vector3(0, 0, -1.2)
	cannon.add_child(barrel)


func take_damage_at(amount: float, pos: Vector3) -> bool:
	# Knee hits are the whole fight
	var weak := false
	for k in knees:
		if pos.distance_to(k.global_position) < 1.4:
			weak = true
			break
	if weak:
		amount *= 3.0
		knee_mat.emission_energy_multiplier = 6.0
		var tw := create_tween()
		tw.tween_property(knee_mat, "emission_energy_multiplier", 2.2, 0.4)
		DebrisScript.burst(main, pos, Color(0.75, 0.35, 1.0), 4, 4.0)
	else:
		amount *= 0.3
	return take_damage(amount)


func take_damage(amount: float) -> bool:
	health -= amount
	if health <= 0.0:
		main.on_enemy_died(5000, global_position)
		main.sfx("shatter", -2.0)
		# it comes down in stages
		for i in range(4):
			var p := global_position + Vector3(randf_range(-3, 3),
											   randf_range(1, 8),
											   randf_range(-3, 3))
			main.get_tree().create_timer(i * 0.3).timeout.connect(
				func() -> void: main._explosion_fx(p, 5.0))
		DebrisScript.burst(main, global_position + Vector3(0, 6, 0),
						   Color(0.42, 0.45, 0.40), 14, 12.0)
		main.on_boss_killed()
		queue_free()
		return true
	return false


func apply_chill(dur: float) -> void:
	chill_t = maxf(chill_t, dur)


func _physics_process(delta: float) -> void:
	if main.state != "playing":
		return
	t += delta
	burst_timer -= delta
	burst_gap -= delta
	chill_t = maxf(0.0, chill_t - delta)

	var stride := clampf(Vector2(velocity.x, velocity.z).length() / speed, 0.0, 1.0)
	for i in range(legs.size()):
		var ph := t * 1.4 + (i % 2) * PI + float(i < 2) * PI * 0.5
		legs[i].rotation.x = sin(ph) * 0.22 * stride
	body_root.position.y = sin(t * 2.8) * 0.18 * stride
	body_root.rotation.z = sin(t * 1.4) * 0.03 * stride

	var tgt: Node3D = main.nearest_target(global_position)
	if tgt == null:
		velocity.x = 0
		velocity.z = 0
	else:
		var to_t := tgt.global_position - global_position
		to_t.y = 0
		var dist := to_t.length()
		var dir := to_t.normalized()
		rotation.y = lerp_angle(rotation.y, atan2(-to_t.x, -to_t.z), 0.7 * delta)
		var mult := 0.5 if chill_t > 0.0 else 1.0
		if dist > 30.0:
			velocity.x = dir.x * speed * mult
			velocity.z = dir.z * speed * mult
		else:
			velocity.x = 0
			velocity.z = 0
		# stomp shockwave if you get under it
		if dist < 9.0 and burst_gap <= 0.0:
			burst_gap = 2.5
			main.explode(global_position + dir * 4.0, 7.0, 60.0, true)
		# cannon bursts from range
		if burst_timer <= 0.0 and dist >= 9.0 and dist < 70.0:
			burst_timer = 4.5
			burst_left = 3
		if burst_left > 0 and burst_gap <= 0.0:
			burst_gap = 0.35
			burst_left -= 1
			_cannon_shot(tgt)

	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()


func _cannon_shot(tgt: Node3D) -> void:
	var origin := cannon.global_position - body_root.global_transform.basis.z * 0.0 \
		+ global_transform.basis * Vector3(0, 0, -2.0)
	var aim: Vector3 = tgt.global_position + Vector3(0, 0.8, 0)
	var dir := (aim - origin).normalized()
	dir = dir.rotated(Vector3.UP, randf_range(-0.02, 0.02))
	var shell := ProjectileScript.new()
	shell.velocity = dir * 55.0
	shell.damage = 45.0
	shell.aoe = 2.5
	shell.shooter = self
	shell.main = main
	shell.color = Color(1.0, 0.45, 0.25)
	shell.thickness = 0.1
	shell.glow = 6.0
	shell.life = 4.0
	main.add_child(shell)
	shell.global_position = origin
	main.sfx("boom", -16.0)
