# Arbitration Arbiter: a shielded plasma caster. The blue shield eats ANY
# hit for at most 15 damage — rate of fire strips it, big slow rounds are
# wasted paperwork. Crack the shield and it blinks sideways out of spite.
extends CharacterBody3D

const ProjectileScript = preload("res://scripts/projectile.gd")
const DebrisScript = preload("res://scripts/debris.gd")

const SHIELD_MAX := 60.0
const SHIELD_HIT_CAP := 15.0   # a shield doesn't care how big the bullet was

var main: Node3D
var health := 70.0
var armor_tier := 1
var shield := SHIELD_MAX
var shield_delay := 0.0        # regen holds off while under fire
var speed := 3.4
var fire_timer := 0.0
var chill_t := 0.0
var flinch := 0.0
var body_root: Node3D
var shield_mesh: MeshInstance3D
var shield_mat: StandardMaterial3D
var t := 0.0


func _ready() -> void:
	add_to_group("enemies")
	safe_margin = 0.06
	fire_timer = randf_range(1.0, 2.0)

	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.42
	cap.height = 1.8
	cs.shape = cap
	cs.position = Vector3(0, 0.9, 0)
	add_child(cs)

	body_root = Node3D.new()
	add_child(body_root)
	var robe := StandardMaterial3D.new()
	robe.albedo_color = Color(0.16, 0.13, 0.24)
	robe.roughness = 0.5
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(0.65, 0.55, 0.3)
	gold.metallic = 0.85
	gold.roughness = 0.25
	var glow := StandardMaterial3D.new()
	glow.emission_enabled = true
	glow.emission = Color(0.4, 0.7, 1.0)
	glow.emission_energy_multiplier = 2.6
	glow.albedo_color = Color(0.1, 0.2, 0.35)

	# A tall robed silhouette with a floating lens for a face
	_box(Vector3(0.5, 1.2, 0.4), Vector3(0, 0.7, 0), robe)
	_box(Vector3(0.6, 0.16, 0.46), Vector3(0, 1.4, 0), gold)
	_box(Vector3(0.26, 0.34, 0.26), Vector3(0, 1.62, 0), robe)
	_box(Vector3(0.16, 0.16, 0.06), Vector3(0, 1.64, -0.16), glow)  # the lens
	# caster arm
	_box(Vector3(0.08, 0.08, 0.55), Vector3(0.26, 1.15, -0.2), gold)

	# The shield bubble
	shield_mesh = MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 1.05
	sph.height = 2.1
	shield_mesh.mesh = sph
	shield_mat = StandardMaterial3D.new()
	shield_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shield_mat.albedo_color = Color(0.35, 0.65, 1.0, 0.16)
	shield_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shield_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	shield_mesh.material_override = shield_mat
	shield_mesh.position = Vector3(0, 0.95, 0)
	add_child(shield_mesh)


func _box(size: Vector3, pos: Vector3, mat: Material) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.material_override = mat
	m.position = pos
	body_root.add_child(m)


func take_damage(amount: float) -> bool:
	if shield > 0.0:
		shield -= minf(amount, SHIELD_HIT_CAP)
		shield_delay = 2.5
		shield_mat.albedo_color.a = 0.4    # flash on hit
		if shield <= 0.0:
			shield = 0.0
			main.sfx("shatter", -14.0)
			if randf() < 0.5:
				_blink()
		return false
	health -= amount
	flinch = 0.12
	if health <= 0.0:
		main.on_enemy_died(260, global_position)
		main.sfx("shatter", -10.0)
		DebrisScript.burst(main, global_position + Vector3(0, 1, 0),
						   Color(0.4, 0.7, 1.0), 9)
		queue_free()
		return true
	return false


func apply_chill(dur: float) -> void:
	chill_t = maxf(chill_t, dur)


func _blink() -> void:
	# sideways displacement, out of your sight picture
	var side := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	var np := global_position + side * 7.0
	np.y = main.ground_height(np.x, np.z) + 1.0
	DebrisScript.burst(main, global_position + Vector3(0, 1, 0),
					   Color(0.4, 0.7, 1.0), 5)
	global_position = np


func _physics_process(delta: float) -> void:
	if main.state != "playing":
		return
	t += delta
	fire_timer -= delta
	chill_t = maxf(0.0, chill_t - delta)
	flinch = maxf(0.0, flinch - delta)
	shield_delay = maxf(0.0, shield_delay - delta)
	if shield_delay <= 0.0 and shield < SHIELD_MAX:
		shield = minf(SHIELD_MAX, shield + 20.0 * delta)
	# shield presentation: visible while charged, breathing softly
	shield_mesh.visible = shield > 0.0
	shield_mat.albedo_color.a = lerpf(shield_mat.albedo_color.a,
									  0.10 + 0.10 * shield / SHIELD_MAX, 6.0 * delta)
	body_root.scale = Vector3.ONE * (1.0 + flinch * 0.7)
	body_root.position.y = sin(t * 2.2) * 0.06

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
		if dist > 26.0:
			velocity.x = dir.x * speed * mult
			velocity.z = dir.z * speed * mult
		else:
			# drift laterally, unhurried — the shield does the worrying
			var side := Vector3(-dir.z, 0, dir.x) * (1.0 if fmod(t, 6.0) < 3.0 else -1.0)
			velocity.x = side.x * speed * 0.45 * mult
			velocity.z = side.z * speed * 0.45 * mult
		if dist < 38.0 and fire_timer <= 0.0 \
				and not main.in_smoke(tgt.global_position):
			fire_timer = randf_range(1.6, 2.4)
			_cast(tgt)

	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()


func _cast(tgt: Node3D) -> void:
	var origin := global_position + Vector3(0, 1.2, 0) - transform.basis.z * 0.6
	var dir: Vector3 = (tgt.global_position + Vector3(0, 0.8, 0) - origin).normalized()
	var bolt := ProjectileScript.new()
	bolt.velocity = dir * 30.0
	bolt.damage = 26.0
	bolt.shooter = self
	bolt.main = main
	bolt.color = Color(0.45, 0.75, 1.0)
	bolt.glow = 7.0
	bolt.thickness = 0.07
	main.add_child(bolt)
	bolt.global_position = origin
	main.sfx("laser", -18.0)
