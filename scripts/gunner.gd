# Husk Gunner: a crystallized soldier-husk with a scavenged shard-rifle.
# Advances to range, strafes, and pours purple bolts at whoever is closest.
extends CharacterBody3D

const ProjectileScript = preload("res://scripts/projectile.gd")
const DebrisScript = preload("res://scripts/debris.gd")

var main: Node3D
var health := 55.0
var sniper := false           # Longsight Husk: one heavy round from way out
var speed := 4.2
var engage := 34.0            # opens fire inside this range
var hold := 22.0              # holds ground and strafes inside this range
var shot_min := 0.9
var shot_max := 1.6
var bolt_speed := 45.0
var bolt_dmg := 9.0
var points := 180
var fire_timer := 0.0
var strafe_dir := 1.0
var strafe_t := 0.0
var chill_t := 0.0
var flinch := 0.0
var body_root: Node3D
var visor_mat: StandardMaterial3D
var t := 0.0


func _ready() -> void:
	add_to_group("enemies")
	safe_margin = 0.06
	if sniper:
		health = 70.0
		speed = 3.0
		engage = 60.0
		hold = 38.0
		shot_min = 2.8
		shot_max = 3.6
		bolt_speed = 95.0
		bolt_dmg = 34.0
		points = 260
	fire_timer = randf_range(0.5, 2.0)
	strafe_dir = 1.0 if randf() > 0.5 else -1.0

	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.42
	cap.height = 1.7
	cs.shape = cap
	cs.position = Vector3(0, 0.85, 0)
	add_child(cs)

	body_root = Node3D.new()
	add_child(body_root)
	var chitin := StandardMaterial3D.new()
	chitin.albedo_color = Color(0.16, 0.15, 0.19)
	chitin.roughness = 0.35
	chitin.metallic = 0.4
	var bone := StandardMaterial3D.new()
	bone.albedo_color = Color(0.5, 0.53, 0.46)
	bone.roughness = 0.65
	visor_mat = StandardMaterial3D.new()
	visor_mat.emission_enabled = true
	# the Longsight's eye burns amber — you'll see it before the shot
	visor_mat.emission = Color(1.0, 0.75, 0.2) if sniper else Color(0.75, 0.35, 1.0)
	visor_mat.emission_energy_multiplier = 2.2 if sniper else 1.6
	visor_mat.albedo_color = Color(0.3, 0.2, 0.05) if sniper else Color(0.2, 0.08, 0.28)

	# Hunched biped: plated torso, crystal growths, glowing eye-slit
	_box(Vector3(0.18, 0.5, 0.2), Vector3(-0.13, 0.35, 0), chitin)
	_box(Vector3(0.18, 0.5, 0.2), Vector3(0.13, 0.35, 0), chitin)
	_box(Vector3(0.44, 0.5, 0.34), Vector3(0, 0.85, 0.02), bone)
	_box(Vector3(0.5, 0.14, 0.38), Vector3(0, 1.14, 0), chitin)
	_box(Vector3(0.3, 0.26, 0.28), Vector3(0, 1.36, -0.04), bone)     # head
	_box(Vector3(0.24, 0.06, 0.04), Vector3(0, 1.38, -0.19), visor_mat)
	# crystal spurs breaking through the shoulders
	for side in [-1.0, 1.0]:
		var spur := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.12, 0.45, 0.12)
		spur.mesh = pm
		spur.material_override = chitin
		spur.position = Vector3(0.27 * side, 1.3, 0.05)
		spur.rotation_degrees = Vector3(0, 0, -30 * side)
		body_root.add_child(spur)
	# shard rifle
	_box(Vector3(0.08, 0.1, 0.7), Vector3(0.24, 0.95, -0.3), chitin)


func _box(size: Vector3, pos: Vector3, mat: Material) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.material_override = mat
	m.position = pos
	body_root.add_child(m)


func take_damage(amount: float) -> bool:
	health -= amount
	flinch = 0.12
	if health <= 0.0:
		main.on_enemy_died(points, global_position)
		main.sfx("shatter", -10.0)
		DebrisScript.burst(main, global_position + Vector3(0, 1, 0),
						   Color(0.5, 0.53, 0.46), 8)
		queue_free()
		return true
	return false


func apply_chill(dur: float) -> void:
	chill_t = maxf(chill_t, dur)


func _physics_process(delta: float) -> void:
	if main.state != "playing":
		return
	t += delta
	fire_timer -= delta
	chill_t = maxf(0.0, chill_t - delta)
	flinch = maxf(0.0, flinch - delta)
	strafe_t -= delta
	if strafe_t <= 0.0:
		strafe_t = randf_range(1.2, 2.6)
		strafe_dir *= -1.0
	body_root.scale = Vector3.ONE * (1.0 + flinch * 0.8)
	body_root.position.y = sin(t * 6.0) * 0.03

	var tgt: Node3D = main.nearest_target(global_position)
	if tgt == null:
		velocity.x = 0
		velocity.z = 0
	else:
		var to_t := tgt.global_position - global_position
		to_t.y = 0
		var dist := to_t.length()
		var dir := to_t.normalized()
		rotation.y = lerp_angle(rotation.y, atan2(-to_t.x, -to_t.z), 6.0 * delta)
		var mult := 0.45 if chill_t > 0.0 else 1.0
		if dist > hold:
			velocity.x = dir.x * speed * mult
			velocity.z = dir.z * speed * mult
		else:
			# hold range, strafe sideways
			var side := Vector3(-dir.z, 0, dir.x) * strafe_dir
			velocity.x = side.x * speed * 0.55 * mult
			velocity.z = side.z * speed * 0.55 * mult
		if dist < engage and fire_timer <= 0.0 \
				and not main.in_smoke(tgt.global_position):
			fire_timer = randf_range(shot_min, shot_max)
			_shoot(tgt)

	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()


func _shoot(tgt: Node3D) -> void:
	var origin := global_position + Vector3(0, 1.0, 0) \
		- transform.basis.z * 0.7
	var aim: Vector3 = tgt.global_position + Vector3(0, 0.9, 0)
	var dir := (aim - origin).normalized()
	var wobble := 0.008 if sniper else 0.03
	dir = dir.rotated(Vector3.UP, randf_range(-wobble, wobble))
	var bolt := ProjectileScript.new()
	bolt.velocity = dir * bolt_speed
	bolt.damage = bolt_dmg
	bolt.shooter = self
	bolt.main = main
	bolt.color = Color(1.0, 0.75, 0.25) if sniper else Color(0.8, 0.4, 1.0)
	bolt.glow = 7.0 if sniper else 5.0
	if sniper:
		bolt.thickness = 0.04
		bolt.life = 3.0
	main.add_child(bolt)
	bolt.global_position = origin
	main.sfx("shoot" if not sniper else "laser", -20.0)
