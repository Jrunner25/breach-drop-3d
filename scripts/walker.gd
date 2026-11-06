# Prism-Walker: towering brute with a charging chest lens.
# Armored (half damage) except while the lens is charging (double damage).
extends CharacterBody3D

const DebrisScript = preload("res://scripts/debris.gd")

var main: Node3D
var armor_tier := 3           # tripod plate: light rounds ricochet clean off
var chill_t := 0.0
var health := 420.0
var speed := 2.2
var state := "stride"     # stride | charge | beam | cool
var timer := 3.0
var lens: MeshInstance3D
var lens_mat: StandardMaterial3D
var beam: MeshInstance3D
var beam_light: OmniLight3D
var body_root: Node3D
var legs: Array = []
var t := 0.0


func _ready() -> void:
	add_to_group("enemies")
	safe_margin = 0.06   # heightmap seams eat careless capsules

	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 1.0
	cap.height = 5.0
	cs.shape = cap
	cs.position = Vector3(0, 2.5, 0)
	add_child(cs)

	body_root = Node3D.new()
	add_child(body_root)

	# Palette from the concept art: pale plated carapace, dark joints,
	# purple energy showing through the seams
	var plate := StandardMaterial3D.new()
	plate.albedo_color = Color(0.55, 0.58, 0.50)
	plate.roughness = 0.55
	plate.metallic = 0.3
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.14, 0.14, 0.17)
	dark.roughness = 0.6
	var seam := StandardMaterial3D.new()
	seam.emission_enabled = true
	seam.emission = Color(0.75, 0.35, 1.0)
	seam.emission_energy_multiplier = 1.2
	seam.albedo_color = Color(0.2, 0.08, 0.28)

	# Two massive striding legs on animated pivots
	for side in [-1.0, 1.0]:
		var hip := Node3D.new()
		hip.position = Vector3(0.62 * side, 2.5, 0)
		body_root.add_child(hip)
		legs.append(hip)
		var thigh := MeshInstance3D.new()
		var tc := CylinderMesh.new()
		tc.top_radius = 0.30
		tc.bottom_radius = 0.24
		tc.height = 1.3
		thigh.mesh = tc
		thigh.material_override = plate
		thigh.position = Vector3(0, -0.65, 0)
		hip.add_child(thigh)
		var shin := MeshInstance3D.new()
		var sc := CylinderMesh.new()
		sc.top_radius = 0.20
		sc.bottom_radius = 0.28
		sc.height = 1.3
		shin.mesh = sc
		shin.material_override = dark
		shin.position = Vector3(0, -1.85, 0.1)
		hip.add_child(shin)
		var foot := MeshInstance3D.new()
		var fb := BoxMesh.new()
		fb.size = Vector3(0.55, 0.25, 0.85)
		foot.mesh = fb
		foot.material_override = plate
		foot.position = Vector3(0, -2.48, -0.1)
		hip.add_child(foot)
		# glowing knee seam
		var knee := MeshInstance3D.new()
		var kb := BoxMesh.new()
		kb.size = Vector3(0.18, 0.08, 0.18)
		knee.mesh = kb
		knee.material_override = seam
		knee.position = Vector3(0, -1.28, -0.12)
		hip.add_child(knee)

	# Massive armored torso + pauldrons + head
	var pelvis := MeshInstance3D.new()
	var pb := BoxMesh.new()
	pb.size = Vector3(1.5, 0.6, 1.0)
	pelvis.mesh = pb
	pelvis.material_override = dark
	pelvis.position = Vector3(0, 2.7, 0)
	body_root.add_child(pelvis)
	var chest := MeshInstance3D.new()
	var cb2 := BoxMesh.new()
	cb2.size = Vector3(1.9, 1.5, 1.2)
	chest.mesh = cb2
	chest.material_override = plate
	chest.position = Vector3(0, 3.7, 0)
	body_root.add_child(chest)
	for side in [-1.0, 1.0]:
		var shoulder := MeshInstance3D.new()
		var ss := SphereMesh.new()
		ss.radius = 0.55
		ss.height = 1.1
		shoulder.mesh = ss
		shoulder.material_override = plate
		shoulder.position = Vector3(1.15 * side, 4.25, 0)
		body_root.add_child(shoulder)
		var arm := MeshInstance3D.new()
		var ac := CylinderMesh.new()
		ac.top_radius = 0.22
		ac.bottom_radius = 0.28
		ac.height = 1.8
		arm.mesh = ac
		arm.material_override = dark
		arm.position = Vector3(1.25 * side, 3.2, 0)
		body_root.add_child(arm)
	var head := MeshInstance3D.new()
	var hb := BoxMesh.new()
	hb.size = Vector3(0.55, 0.45, 0.6)
	head.mesh = hb
	head.material_override = plate
	head.position = Vector3(0, 4.75, -0.15)
	body_root.add_child(head)
	var eyes := MeshInstance3D.new()
	var eb := BoxMesh.new()
	eb.size = Vector3(0.4, 0.08, 0.05)
	eyes.mesh = eb
	eyes.material_override = seam
	eyes.position = Vector3(0, 4.78, -0.46)
	body_root.add_child(eyes)

	# The focus lens sits in the chest — exposed while it charges
	lens = MeshInstance3D.new()
	var ls := SphereMesh.new()
	ls.radius = 0.32
	ls.height = 0.64
	lens.mesh = ls
	lens_mat = StandardMaterial3D.new()
	lens_mat.emission_enabled = true
	lens_mat.emission = Color(0.7, 0.3, 1.0)
	lens_mat.emission_energy_multiplier = 1.0
	lens_mat.albedo_color = Color(0.18, 0.06, 0.24)
	lens.material_override = lens_mat
	lens.position = Vector3(0, 3.6, -0.68)
	body_root.add_child(lens)

	# The thermal beam (hidden until firing)
	beam = MeshInstance3D.new()
	var bc := CylinderMesh.new()
	bc.top_radius = 0.09
	bc.bottom_radius = 0.09
	bc.height = 1.0
	beam.mesh = bc
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.albedo_color = Color(0.85, 0.45, 1.0)
	bm.emission_enabled = true
	bm.emission = Color(0.75, 0.35, 1.0)
	bm.emission_energy_multiplier = 8.0
	beam.material_override = bm
	beam.visible = false
	add_child(beam)

	beam_light = OmniLight3D.new()
	beam_light.light_color = Color(0.75, 0.4, 1.0)
	beam_light.light_energy = 0.0
	beam_light.omni_range = 14.0
	add_child(beam_light)


func take_damage(amount: float) -> bool:
	# Plating shrugs it off — unless the lens is exposed and charging
	amount *= 2.0 if state == "charge" else 0.5
	health -= amount
	if health <= 0.0:
		main.on_enemy_died(1500, global_position)
		main.sfx("shatter", -6.0)
		DebrisScript.burst(main, global_position + Vector3(0, 3, 0),
						   Color(0.55, 0.58, 0.50), 12, 9.0)
		if state == "charge":
			# Catastrophic lens backfire
			main.explode(global_position + Vector3(0, 3, 0), 8.0, 200.0, true)
		else:
			main._explosion_fx(global_position + Vector3(0, 3, 0), 5.0)
		queue_free()
		return true
	return false


func apply_chill(dur: float) -> void:
	chill_t = maxf(chill_t, dur)


func _physics_process(delta: float) -> void:
	if main.state != "playing":
		beam.visible = false
		return
	t += delta
	timer -= delta
	body_root.position.y = sin(t * 2.2) * 0.12   # eerie rhythmic stride
	# Heavy alternating leg stride while moving; the whole hull rolls with it
	var stride := clampf(Vector2(velocity.x, velocity.z).length() / speed, 0.0, 1.0)
	if legs.size() == 2:
		legs[0].rotation.x = sin(t * 2.2) * 0.35 * stride
		legs[1].rotation.x = -sin(t * 2.2) * 0.35 * stride
	body_root.rotation.z = sin(t * 2.2) * 0.05 * stride
	body_root.rotation.x = 0.06 * stride   # leans into the advance

	chill_t = maxf(0.0, chill_t - delta)
	var p: Node3D = main.nearest_target(global_position)
	if p == null:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var to_p := p.global_position - global_position
	to_p.y = 0
	var dist := to_p.length()
	# Face the prey (walkers pivot slowly)
	var target_yaw := atan2(-to_p.x, -to_p.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 1.2 * delta)

	beam.visible = state == "beam"
	beam_light.light_energy = 6.0 if state == "beam" else 0.0

	match state:
		"stride":
			lens_mat.emission_energy_multiplier = 1.0
			if dist < 30.0 and timer <= 0.0:
				state = "charge"
				timer = 2.2
				velocity = Vector3.ZERO
			else:
				var mult := 0.5 if chill_t > 0.0 else 1.0
				velocity.x = to_p.normalized().x * speed * mult
				velocity.z = to_p.normalized().z * speed * mult
		"charge":
			# Rooted, lens blazing — shoot it NOW
			velocity = Vector3.ZERO
			lens_mat.emission_energy_multiplier = 2.0 + (2.2 - timer) * 6.0
			if timer <= 0.0:
				state = "beam"
				timer = 1.8
		"beam":
			velocity = Vector3.ZERO
			_run_beam(p, delta)
			if timer <= 0.0:
				state = "cool"
				timer = 3.5
		"cool":
			lens_mat.emission_energy_multiplier = 1.0
			if timer <= 0.0:
				state = "stride"

	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()


func _run_beam(p: Node3D, delta: float) -> void:
	var from := lens.global_position
	var target: Vector3 = p.global_position + Vector3(0, 1.0, 0)
	var q := PhysicsRayQueryParameters3D.create(from, target)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var end := target
	var hit_player := false
	if hit:
		end = hit.position
		hit_player = hit.collider == p
	# stretch the beam mesh between lens and endpoint
	var mid := (from + end) * 0.5
	beam.global_position = mid
	beam.look_at(end, Vector3.UP)
	beam.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	beam.scale = Vector3(1, from.distance_to(end), 1)
	beam_light.global_position = mid
	if hit_player:
		p.take_damage(45.0 * delta)
