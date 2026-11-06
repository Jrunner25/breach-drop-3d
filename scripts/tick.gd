# Shard-Tick: dog-sized crystalline arachnid. Rushes, leaps, shatters.
extends CharacterBody3D

const DebrisScript = preload("res://scripts/debris.gd")

var main: Node3D
var health := 40.0
var armored := false          # plated variant: slower, much tougher
var stalker := false          # translucent ambusher: fast, hits hard
var armor_tier := 1           # 0..10 armor scale; the plated variant wears 3
var melee_dmg := 12.0
var points := 90
var chill_t := 0.0
var speed := 5.6
var lunge_cd := 0.0
var lunge_timer := 0.0
var melee_cd := 0.0
var shards: Node3D
var core: MeshInstance3D
var legs: Array = []
var scuttle_t := 0.0
var patrol := false            # wandering until it spots prey
var patrol_pt := Vector3.ZERO
var patrol_retarget := 0.0
var base_scale := Vector3.ONE


func _ready() -> void:
	add_to_group("enemies")
	safe_margin = 0.06   # heightmap seams eat careless capsules
	if armored:
		health = 110.0
		speed = 4.2
		armor_tier = 3
		points = 160
	elif stalker:
		health = 60.0
		speed = 8.0
		melee_dmg = 18.0
		points = 220

	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.55
	cs.shape = sph
	cs.position = Vector3(0, 0.5, 0)
	add_child(cs)

	# A crystalline spider: chitin body, arched legs, back spikes,
	# purple-glowing eye cluster — straight out of the concept art
	shards = Node3D.new()
	shards.position = Vector3(0, 0.5, 0)
	add_child(shards)
	var chitin := StandardMaterial3D.new()
	chitin.albedo_color = Color(0.10, 0.10, 0.13)
	chitin.roughness = 0.2
	chitin.metallic = 0.45
	var bone := StandardMaterial3D.new()
	bone.albedo_color = Color(0.52, 0.55, 0.48)   # pale plated carapace
	bone.roughness = 0.6
	var glow := StandardMaterial3D.new()
	glow.emission_enabled = true
	glow.emission = Color(0.75, 0.35, 1.0)        # the purple core light
	glow.emission_energy_multiplier = 2.8
	glow.albedo_color = Color(0.2, 0.08, 0.28)
	if stalker:
		# the stalker is mostly refraction: a translucent shape with dim eyes
		chitin.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		chitin.albedo_color = Color(0.10, 0.10, 0.13, 0.4)
		bone.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		bone.albedo_color = Color(0.52, 0.55, 0.48, 0.35)
		glow.emission_energy_multiplier = 1.1

	# Abdomen + armored head plate
	var abdomen := MeshInstance3D.new()
	var ab := SphereMesh.new()
	ab.radius = 0.34
	ab.height = 0.46
	abdomen.mesh = ab
	abdomen.material_override = chitin
	abdomen.position = Vector3(0, 0.05, 0.18)
	shards.add_child(abdomen)
	var headm := MeshInstance3D.new()
	var hb := SphereMesh.new()
	hb.radius = 0.22
	hb.height = 0.32
	headm.mesh = hb
	headm.material_override = bone
	headm.position = Vector3(0, -0.02, -0.26)
	shards.add_child(headm)

	# Purple eye cluster on the face
	for eye_pos in [Vector3(-0.08, 0.02, -0.42), Vector3(0.08, 0.02, -0.42),
					Vector3(0, 0.10, -0.40)]:
		var e := MeshInstance3D.new()
		var es := SphereMesh.new()
		es.radius = 0.045
		es.height = 0.09
		e.mesh = es
		e.material_override = glow
		e.position = eye_pos
		shards.add_child(e)
	core = headm

	# Jagged spikes raking backward off the abdomen
	for i in range(6):
		var sp := MeshInstance3D.new()
		var sc := CylinderMesh.new()
		sc.top_radius = 0.0
		sc.bottom_radius = randf_range(0.035, 0.06)
		sc.height = randf_range(0.35, 0.65)
		sp.mesh = sc
		sp.material_override = chitin
		sp.position = Vector3(randf_range(-0.18, 0.18), 0.20,
							  0.18 + randf_range(-0.08, 0.16))
		sp.rotation_degrees = Vector3(randf_range(35, 75), 0,
									  randf_range(-30, 30))
		sp.rotate_object_local(Vector3.RIGHT, PI)   # tips sweep back and up
		shards.add_child(sp)

	# Six arched legs on animated roots
	for i in range(6):
		var side := -1.0 if i < 3 else 1.0
		var zoff: float = [-0.20, 0.0, 0.20][i % 3]
		var root := Node3D.new()
		root.position = Vector3(0.18 * side, 0.0, zoff)
		shards.add_child(root)
		legs.append(root)
		var upper := MeshInstance3D.new()
		var uc := CylinderMesh.new()
		uc.top_radius = 0.030
		uc.bottom_radius = 0.045
		uc.height = 0.45
		upper.mesh = uc
		upper.material_override = chitin
		upper.position = Vector3(0.18 * side, 0.12, 0)
		upper.rotation_degrees = Vector3(0, 0, -62 * side)
		root.add_child(upper)
		var lower := MeshInstance3D.new()
		var lc := CylinderMesh.new()
		lc.top_radius = 0.012
		lc.bottom_radius = 0.028
		lc.height = 0.52
		lower.mesh = lc
		lower.material_override = bone
		lower.position = Vector3(0.40 * side, -0.15, 0)
		lower.rotation_degrees = Vector3(0, 0, 24 * side)
		root.add_child(lower)

	# Armored variant: pale plating reads bigger and meaner
	var final_scale := Vector3.ONE * (1.3 if armored else 1.0)
	base_scale = final_scale
	if armored:
		bone.albedo_color = Color(0.65, 0.66, 0.58)
		chitin.albedo_color = Color(0.30, 0.30, 0.28)

	# Burrow-up: the Swarm erupts from under the snow
	shards.scale = Vector3.ONE * 0.05
	var tw := create_tween()
	tw.tween_property(shards, "scale", final_scale, 0.45) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func take_damage(amount: float) -> bool:
	health -= amount
	# flinch: the whole cluster jolts
	if shards != null:
		shards.scale = base_scale * 1.18
		var tw := create_tween()
		tw.tween_property(shards, "scale", base_scale, 0.12)
	if health <= 0.0:
		_die()
		return true
	return false


func apply_chill(dur: float) -> void:
	chill_t = maxf(chill_t, dur)


func _die() -> void:
	main.on_enemy_died(points, global_position)
	main.sfx("shatter", -12.0)
	DebrisScript.burst(main, global_position + Vector3(0, 0.5, 0),
					   Color(0.52, 0.55, 0.48) if armored else Color(0.15, 0.15, 0.2), 8)
	# Glass-shard burst: blinding fragments that cut whoever stands close
	var p: Node3D = main.player
	if p != null and p.global_position.distance_to(global_position) < 3.0:
		p.take_damage(10.0, true)
	main._explosion_fx(global_position + Vector3(0, 0.5, 0), 2.0)
	queue_free()


func _physics_process(delta: float) -> void:
	if main.state != "playing":
		return
	lunge_cd = maxf(0.0, lunge_cd - delta)
	melee_cd = maxf(0.0, melee_cd - delta)

	# Scuttle: legs row forward/back (yaw) and lift (roll) in tripod phase
	var ground_speed := Vector2(velocity.x, velocity.z).length()
	scuttle_t += delta * (5.0 + ground_speed * 2.4)
	var amt := clampf(ground_speed / 4.0 + 0.2, 0.0, 1.0)
	for i in range(legs.size()):
		var ph := scuttle_t + i * 2.1
		legs[i].rotation.y = sin(ph) * 0.5 * amt
		legs[i].rotation.z = cos(ph) * 0.22 * amt
	# body bobs with the scuttle; pitches into a pounce mid-lunge
	shards.position.y = 0.5 + sin(scuttle_t * 0.5) * 0.035
	if lunge_timer > 0.0:
		shards.rotation.x = lerpf(shards.rotation.x, -0.4, 14.0 * delta)
	else:
		shards.rotation.x = lerpf(shards.rotation.x, 0.0, 10.0 * delta)

	# Face the direction of travel
	if ground_speed > 0.5:
		var target_yaw := atan2(-velocity.x, -velocity.z)
		shards.rotation.y = lerp_angle(shards.rotation.y, target_yaw, 8.0 * delta)

	chill_t = maxf(0.0, chill_t - delta)
	var p: Node3D = main.nearest_target(global_position)
	if p == null:
		velocity.x = 0
		velocity.z = 0
	elif patrol:
		# Wandering the reach. Spot the Breacher -> scream for a breach.
		var to_prey := p.global_position - global_position
		to_prey.y = 0
		var spot := 17.0
		if p == main.player:
			# soft stealth: suit optics plus posture — crawl past them
			spot *= main.player.stealth_mult()
		if to_prey.length() < spot and not main.in_smoke(p.global_position):
			patrol = false
			main.trigger_breach(global_position)
		else:
			patrol_retarget -= delta
			if patrol_retarget <= 0.0:
				patrol_retarget = randf_range(4.0, 8.0)
				var a := randf() * TAU
				patrol_pt = global_position + Vector3(cos(a) * 12.0, 0, sin(a) * 12.0)
			var to_wp := patrol_pt - global_position
			to_wp.y = 0
			if to_wp.length() > 1.5:
				var wd := to_wp.normalized()
				velocity.x = wd.x * speed * 0.35
				velocity.z = wd.z * speed * 0.35
			else:
				velocity.x = 0
				velocity.z = 0
	else:
		var to_p := p.global_position - global_position
		to_p.y = 0
		var dist := to_p.length()
		var dir := to_p.normalized()

		var mult := 0.45 if chill_t > 0.0 else 1.0
		if lunge_timer > 0.0:
			lunge_timer -= delta   # committed mid-leap
		elif dist < (7.0 if stalker else 5.0) and lunge_cd <= 0.0:
			# Leap at the prey, trying to impale
			lunge_timer = 0.35
			lunge_cd = 1.8
			velocity = dir * (20.0 if stalker else 16.0) * mult
			velocity.y = 4.5
		else:
			velocity.x = dir.x * speed * mult
			velocity.z = dir.z * speed * mult

		if dist < 1.4 and melee_cd <= 0.0:
			melee_cd = 0.9
			p.take_damage(melee_dmg)

	if not is_on_floor():
		velocity.y -= 18.0 * delta
	elif lunge_timer <= 0.0:
		velocity.y = 0.0
	move_and_slide()
