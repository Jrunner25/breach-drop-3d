# Spitter: squat crystal artillery. Keeps its distance and lobs acid globs
# in high arcs — standing still at the beacon is how you meet one.
extends CharacterBody3D

const ProjectileScript = preload("res://scripts/projectile.gd")
const DebrisScript = preload("res://scripts/debris.gd")

var main: Node3D
var health := 70.0
var speed := 2.6
var lob_timer := 3.0
var chill_t := 0.0
var flinch := 0.0
var body_root: Node3D
var maw_mat: StandardMaterial3D
var t := 0.0


func _ready() -> void:
	add_to_group("enemies")
	safe_margin = 0.06
	lob_timer = randf_range(2.0, 4.0)

	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.9
	cs.shape = sph
	cs.position = Vector3(0, 0.8, 0)
	add_child(cs)

	body_root = Node3D.new()
	add_child(body_root)
	var chitin := StandardMaterial3D.new()
	chitin.albedo_color = Color(0.14, 0.16, 0.14)
	chitin.roughness = 0.3
	chitin.metallic = 0.35
	maw_mat = StandardMaterial3D.new()
	maw_mat.emission_enabled = true
	maw_mat.emission = Color(0.5, 0.9, 0.3)
	maw_mat.emission_energy_multiplier = 1.4
	maw_mat.albedo_color = Color(0.15, 0.3, 0.1)

	# A bloated sac on stub legs with a skyward maw
	var sac := MeshInstance3D.new()
	var ss := SphereMesh.new()
	ss.radius = 0.85
	ss.height = 1.5
	sac.mesh = ss
	sac.material_override = chitin
	sac.position = Vector3(0, 0.8, 0.1)
	body_root.add_child(sac)
	var maw := MeshInstance3D.new()
	var mc := CylinderMesh.new()
	mc.top_radius = 0.28
	mc.bottom_radius = 0.16
	mc.height = 0.8
	maw.mesh = mc
	maw.material_override = maw_mat
	maw.position = Vector3(0, 1.5, -0.2)
	maw.rotation_degrees = Vector3(-30, 0, 0)
	body_root.add_child(maw)
	for i in range(4):
		var a := i * TAU / 4.0 + 0.4
		var leg := MeshInstance3D.new()
		var lc := CylinderMesh.new()
		lc.top_radius = 0.09
		lc.bottom_radius = 0.13
		lc.height = 0.6
		leg.mesh = lc
		leg.material_override = chitin
		leg.position = Vector3(cos(a) * 0.6, 0.25, sin(a) * 0.6)
		leg.rotation_degrees = Vector3(sin(a) * 22, 0, -cos(a) * 22)
		body_root.add_child(leg)
	# venting spikes
	for i in range(4):
		var sp := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.14, 0.5, 0.14)
		sp.mesh = pm
		sp.material_override = chitin
		sp.position = Vector3(randf_range(-0.5, 0.5), 1.3, randf_range(0.0, 0.5))
		sp.rotation_degrees = Vector3(randf_range(20, 55), 0, randf_range(-25, 25))
		body_root.add_child(sp)


func take_damage(amount: float) -> bool:
	health -= amount
	flinch = 0.15
	if health <= 0.0:
		main.on_enemy_died(260, global_position)
		main.sfx("shatter", -8.0)
		DebrisScript.burst(main, global_position + Vector3(0, 0.8, 0),
						   Color(0.3, 0.5, 0.25), 9)
		# it ruptures: the acid it was saving splashes everyone nearby
		main.explode(global_position, 4.0, 40.0, true)
		queue_free()
		return true
	return false


func apply_chill(dur: float) -> void:
	chill_t = maxf(chill_t, dur)


func _physics_process(delta: float) -> void:
	if main.state != "playing":
		return
	t += delta
	lob_timer -= delta
	chill_t = maxf(0.0, chill_t - delta)
	flinch = maxf(0.0, flinch - delta)
	body_root.scale = Vector3.ONE * (1.0 + flinch + sin(t * 3.0) * 0.02)

	var tgt: Node3D = main.nearest_target(global_position)
	if tgt != null:
		var to_t := tgt.global_position - global_position
		to_t.y = 0
		var dist := to_t.length()
		var dir := to_t.normalized()
		rotation.y = lerp_angle(rotation.y, atan2(-to_t.x, -to_t.z), 2.0 * delta)
		var mult := 0.45 if chill_t > 0.0 else 1.0
		if dist > 38.0:
			velocity.x = dir.x * speed * mult
			velocity.z = dir.z * speed * mult
		elif dist < 20.0:
			velocity.x = -dir.x * speed * mult      # waddle away, keep range
			velocity.z = -dir.z * speed * mult
		else:
			velocity.x = 0
			velocity.z = 0
			if lob_timer <= 0.0:
				lob_timer = randf_range(3.2, 4.6)
				_lob(tgt, dist)
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()


func _lob(tgt: Node3D, dist: float) -> void:
	maw_mat.emission_energy_multiplier = 4.0
	var tw := create_tween()
	tw.tween_property(maw_mat, "emission_energy_multiplier", 1.4, 0.6)
	# solve a simple arc: flight time from distance, gravity 14
	var flight := clampf(dist / 16.0, 1.2, 2.6)
	var to_t: Vector3 = tgt.global_position - global_position
	var vy := 14.0 * flight * 0.5
	var glob := ProjectileScript.new()
	glob.velocity = Vector3(to_t.x / flight, vy, to_t.z / flight)
	glob.gravity = 14.0
	glob.damage = 34.0
	glob.aoe = 3.5
	glob.life = 6.0
	glob.shooter = self
	glob.main = main
	glob.color = Color(0.55, 0.95, 0.3)
	glob.thickness = 0.14
	glob.glow = 4.0
	main.add_child(glob)
	glob.global_position = global_position + Vector3(0, 1.8, 0)
	main.sfx("stim", -14.0)   # wet hiss doubles nicely as a spit
