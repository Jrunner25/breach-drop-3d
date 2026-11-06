# Reclaimer Foreman: heavy repo chassis. The SHIELD pattern walks behind a
# ballistic slab — frontal hits ping off, flank it or crack it with AP.
# The ROCKET pattern lobs arcing salvos that blow you clean out of cover.
extends CharacterBody3D

const ProjectileScript = preload("res://scripts/projectile.gd")
const DebrisScript = preload("res://scripts/debris.gd")

var main: Node3D
var rocket := false           # rocket pattern instead of the shield slab
var health := 220.0
var armor_tier := 3
var speed := 2.6
var fire_timer := 0.0
var salvo := 0
var salvo_timer := 0.0
var chill_t := 0.0
var flinch := 0.0
var body_root: Node3D


func _ready() -> void:
	add_to_group("enemies")
	safe_margin = 0.06
	if rocket:
		health = 190.0
	fire_timer = randf_range(1.5, 3.0)

	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.55
	cap.height = 2.1
	cs.shape = cap
	cs.position = Vector3(0, 1.05, 0)
	add_child(cs)

	body_root = Node3D.new()
	add_child(body_root)
	var plate := StandardMaterial3D.new()
	plate.albedo_color = Color(0.38, 0.34, 0.30)
	plate.metallic = 0.8
	plate.roughness = 0.3
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.12, 0.11, 0.11)
	dark.metallic = 0.6
	var eye := StandardMaterial3D.new()
	eye.emission_enabled = true
	eye.emission = Color(1.0, 0.2, 0.1)
	eye.emission_energy_multiplier = 2.4
	eye.albedo_color = Color(0.3, 0.05, 0.03)

	# Broad bipedal hulk
	_box(Vector3(0.24, 0.7, 0.26), Vector3(-0.2, 0.45, 0), dark)
	_box(Vector3(0.24, 0.7, 0.26), Vector3(0.2, 0.45, 0), dark)
	_box(Vector3(0.75, 0.65, 0.45), Vector3(0, 1.15, 0), plate)
	_box(Vector3(0.85, 0.14, 0.5), Vector3(0, 1.52, 0), dark)
	_box(Vector3(0.3, 0.26, 0.3), Vector3(0, 1.72, -0.02), plate)   # head
	_box(Vector3(0.24, 0.06, 0.05), Vector3(0, 1.73, -0.17), eye)
	if rocket:
		# shoulder rocket pods
		for side in [-1.0, 1.0]:
			_box(Vector3(0.24, 0.24, 0.5), Vector3(0.42 * side, 1.62, 0.05), dark)
			_box(Vector3(0.18, 0.18, 0.1), Vector3(0.42 * side, 1.62, -0.24), eye)
	else:
		# the ballistic slab: a riot door welded to an arm
		_box(Vector3(1.0, 1.5, 0.1), Vector3(0, 1.1, -0.5), plate)
		_box(Vector3(0.09, 0.11, 0.7), Vector3(0.34, 1.1, -0.3), dark)  # blaster


func _box(size: Vector3, pos: Vector3, mat: Material) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.material_override = mat
	m.position = pos
	body_root.add_child(m)


func take_damage_at(amount: float, pos: Vector3) -> bool:
	# The shield pattern shrugs off frontal hits — flank it or go AP heavy
	if not rocket:
		var to_hit := pos - global_position
		to_hit.y = 0.0
		var fwd := -global_transform.basis.z
		if to_hit.length() > 0.05 and to_hit.normalized().dot(fwd) > 0.25:
			amount *= 0.15
			if main.hud != null and randf() < 0.3:
				main.hud.add_popup("SLAB", pos)
	return take_damage(amount)


func take_damage(amount: float) -> bool:
	health -= amount
	flinch = 0.1
	if health <= 0.0:
		main.on_enemy_died(320, global_position)
		main.sfx("boom", -10.0)
		DebrisScript.burst(main, global_position + Vector3(0, 1.2, 0),
						   Color(0.38, 0.34, 0.30), 10)
		main._explosion_fx(global_position + Vector3(0, 1, 0), 2.5)
		queue_free()
		return true
	return false


func apply_chill(dur: float) -> void:
	chill_t = maxf(chill_t, dur)


func _physics_process(delta: float) -> void:
	if main.state != "playing":
		return
	fire_timer -= delta
	salvo_timer -= delta
	chill_t = maxf(0.0, chill_t - delta)
	flinch = maxf(0.0, flinch - delta)
	body_root.scale = Vector3.ONE * (1.0 + flinch * 0.5)

	var tgt: Node3D = main.nearest_target(global_position)
	if tgt == null:
		velocity.x = 0
		velocity.z = 0
	else:
		var to_t := tgt.global_position - global_position
		to_t.y = 0
		var dist := to_t.length()
		var dir := to_t.normalized()
		# always squared to the target: the slab only works face-on
		rotation.y = lerp_angle(rotation.y, atan2(-to_t.x, -to_t.z), 4.0 * delta)
		var mult := 0.45 if chill_t > 0.0 else 1.0
		var hold := 30.0 if rocket else 14.0
		if dist > hold:
			velocity.x = dir.x * speed * mult
			velocity.z = dir.z * speed * mult
		else:
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
		if not main.in_smoke(tgt.global_position):
			if rocket:
				if salvo <= 0 and fire_timer <= 0.0 and dist < 55.0:
					salvo = 3
					fire_timer = randf_range(4.5, 6.5)
				if salvo > 0 and salvo_timer <= 0.0:
					salvo -= 1
					salvo_timer = 0.3
					_fire_rocket(tgt)
			elif dist < 26.0 and fire_timer <= 0.0:
				fire_timer = 0.17
				_fire_blaster(tgt)

	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()


func _fire_blaster(tgt: Node3D) -> void:
	var origin := global_position + Vector3(0, 1.1, 0) - transform.basis.z * 0.7
	var dir: Vector3 = (tgt.global_position + Vector3(0, 0.8, 0) - origin).normalized()
	dir = dir.rotated(Vector3.UP, randf_range(-0.045, 0.045))
	var bolt := ProjectileScript.new()
	bolt.velocity = dir * 50.0
	bolt.damage = 7.0
	bolt.shooter = self
	bolt.main = main
	bolt.color = Color(1.0, 0.25, 0.12)
	bolt.glow = 5.0
	main.add_child(bolt)
	bolt.global_position = origin
	main.sfx("shoot", -21.0)


func _fire_rocket(tgt: Node3D) -> void:
	var origin := global_position + Vector3(0, 1.7, 0)
	var to_t: Vector3 = tgt.global_position - origin
	var flat := Vector3(to_t.x, 0, to_t.z)
	var dir := (flat.normalized() + Vector3(0, 0.55, 0)).normalized()
	var rkt := ProjectileScript.new()
	rkt.velocity = dir * (flat.length() * 0.85 + 8.0)
	rkt.gravity = 9.0
	rkt.damage = 30.0
	rkt.aoe = 3.2
	rkt.life = 5.0
	rkt.shooter = self
	rkt.main = main
	rkt.color = Color(1.0, 0.5, 0.15)
	rkt.thickness = 0.06
	main.add_child(rkt)
	rkt.global_position = origin
	main.sfx("laser", -16.0)
