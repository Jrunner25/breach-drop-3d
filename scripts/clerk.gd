# Reclaimer Clerk: standard repo-bot infantry. Advances to range, plants
# its feet, fires tight three-round bursts — and if you let it live, it
# raises a red flare and a repo dropship answers.
extends CharacterBody3D

const ProjectileScript = preload("res://scripts/projectile.gd")
const DebrisScript = preload("res://scripts/debris.gd")

var main: Node3D
var health := 45.0
var armor_tier := 1
var speed := 3.8
var fire_timer := 0.0
var burst := 0
var burst_timer := 0.0
var flare_timer := 0.0
var chill_t := 0.0
var flinch := 0.0
var body_root: Node3D
var eye_mat: StandardMaterial3D
var t := 0.0


func _ready() -> void:
	add_to_group("enemies")
	safe_margin = 0.06
	fire_timer = randf_range(1.2, 2.4)
	flare_timer = randf_range(8.0, 16.0)

	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.7
	cs.shape = cap
	cs.position = Vector3(0, 0.85, 0)
	add_child(cs)

	body_root = Node3D.new()
	add_child(body_root)
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.32, 0.30, 0.28)
	steel.metallic = 0.75
	steel.roughness = 0.35
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.14, 0.13, 0.13)
	dark.metallic = 0.6
	eye_mat = StandardMaterial3D.new()
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1.0, 0.2, 0.1)
	eye_mat.emission_energy_multiplier = 2.2
	eye_mat.albedo_color = Color(0.3, 0.05, 0.03)

	# A gaunt corporate skeleton: angular torso, clipboard-flat chest plate
	_box(Vector3(0.16, 0.5, 0.18), Vector3(-0.11, 0.35, 0), dark)
	_box(Vector3(0.16, 0.5, 0.18), Vector3(0.11, 0.35, 0), dark)
	_box(Vector3(0.4, 0.46, 0.26), Vector3(0, 0.86, 0), steel)
	_box(Vector3(0.46, 0.1, 0.3), Vector3(0, 1.12, 0), dark)
	_box(Vector3(0.24, 0.22, 0.24), Vector3(0, 1.32, 0), steel)      # head
	_box(Vector3(0.2, 0.05, 0.04), Vector3(0, 1.33, -0.13), eye_mat) # eye slit
	# antenna: the flare mast
	_box(Vector3(0.02, 0.4, 0.02), Vector3(0.14, 1.5, 0.06), dark)
	# blaster arm
	_box(Vector3(0.07, 0.09, 0.6), Vector3(0.22, 0.9, -0.26), dark)


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
		main.on_enemy_died(140, global_position)
		main.sfx("shatter", -12.0)
		DebrisScript.burst(main, global_position + Vector3(0, 1, 0),
						   Color(0.32, 0.30, 0.28), 7)
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
	burst_timer -= delta
	chill_t = maxf(0.0, chill_t - delta)
	flinch = maxf(0.0, flinch - delta)
	body_root.scale = Vector3.ONE * (1.0 + flinch * 0.7)

	var tgt: Node3D = main.nearest_target(global_position)
	if tgt == null:
		velocity.x = 0
		velocity.z = 0
	else:
		var to_t := tgt.global_position - global_position
		to_t.y = 0
		var dist := to_t.length()
		var dir := to_t.normalized()
		rotation.y = lerp_angle(rotation.y, atan2(-to_t.x, -to_t.z), 7.0 * delta)
		var mult := 0.45 if chill_t > 0.0 else 1.0
		if dist > 24.0:
			velocity.x = dir.x * speed * mult
			velocity.z = dir.z * speed * mult
		else:
			# feet planted: clerks don't dance, they file
			velocity.x = move_toward(velocity.x, 0.0, 16.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 16.0 * delta)
		if dist < 36.0 and not main.in_smoke(tgt.global_position):
			if burst <= 0 and fire_timer <= 0.0:
				burst = 3
				fire_timer = randf_range(1.6, 2.6)
			if burst > 0 and burst_timer <= 0.0:
				burst -= 1
				burst_timer = 0.13
				_shoot(tgt)
			# the flare: let a clerk live and it files for reinforcements
			flare_timer -= delta
			if flare_timer <= 0.0:
				flare_timer = randf_range(16.0, 24.0)
				_raise_flare()

	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()


func _raise_flare() -> void:
	if main.breach_cd > 0.0:
		return
	# a red bolt straight up, then the sky answers
	var flare := ProjectileScript.new()
	flare.velocity = Vector3(0, 40.0, 0)
	flare.damage = 0.0
	flare.color = Color(1.0, 0.2, 0.1)
	flare.glow = 9.0
	flare.thickness = 0.05
	flare.life = 1.4
	main.add_child(flare)
	flare.global_position = global_position + Vector3(0, 1.6, 0)
	main.sfx("stim", -10.0)
	main.trigger_breach(global_position)


func _shoot(tgt: Node3D) -> void:
	var origin := global_position + Vector3(0, 1.0, 0) - transform.basis.z * 0.6
	var aim: Vector3 = tgt.global_position + Vector3(0, 0.9, 0)
	var dir := (aim - origin).normalized()
	dir = dir.rotated(Vector3.UP, randf_range(-0.02, 0.02))
	var bolt := ProjectileScript.new()
	bolt.velocity = dir * 55.0
	bolt.damage = 8.0
	bolt.shooter = self
	bolt.main = main
	bolt.color = Color(1.0, 0.25, 0.12)
	bolt.glow = 5.0
	main.add_child(bolt)
	bolt.global_position = origin
	main.sfx("shoot", -20.0)
