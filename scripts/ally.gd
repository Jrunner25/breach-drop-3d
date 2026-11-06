# An AI Breacher squadmate: follows your lead, picks targets, checks fire
# when you cross the line, and dies so a hellpod can bring the next one.
extends CharacterBody3D

const ProjectileScript = preload("res://scripts/projectile.gd")
const TrooperModel = preload("res://scripts/trooper_model.gd")
const DebrisScript = preload("res://scripts/debris.gd")

const NAMES := ["VOSS", "OKONKWO", "REYES", "TANAKA", "IBRAHIM", "KOWALSKI"]
const PAINTS := [Color(0.62, 0.58, 0.52), Color(0.72, 0.78, 0.84),
				 Color(0.52, 0.22, 0.13), Color(0.35, 0.42, 0.35)]

var main: Node3D
var callsign := "VOSS"
var slot := 0                 # formation slot behind the player
var health := 120.0
var max_health := 120.0
var speed := 5.8
var fire_timer := 0.0
var alive := true
var body_root: Node3D
var hip_l: Node3D
var hip_r: Node3D
var gun_tip: Node3D
var bob_t := 0.0


func _ready() -> void:
	add_to_group("allies")
	safe_margin = 0.06
	callsign = NAMES[randi() % NAMES.size()]

	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.8
	cs.shape = cap
	cs.position = Vector3(0, 0.9, 0)
	add_child(cs)

	body_root = Node3D.new()
	add_child(body_root)
	var parts: Dictionary = TrooperModel.build(
		body_root, PAINTS[randi() % PAINTS.size()], Color(0.4, 0.85, 1.0))
	hip_l = parts["hip_l"]
	hip_r = parts["hip_r"]
	gun_tip = parts["gun_tip"]


func take_damage(amount: float, _shrapnel: bool = false) -> void:
	if not alive:
		return
	health -= amount
	if health <= 0.0:
		alive = false
		main.on_ally_died(self)
		main.sfx("boom", -14.0)
		DebrisScript.burst(main, global_position + Vector3(0, 1, 0),
						   Color(0.5, 0.5, 0.5), 6)
		queue_free()


func _physics_process(delta: float) -> void:
	if main.state != "playing" or not alive:
		return
	fire_timer = maxf(0.0, fire_timer - delta)
	var p: Node3D = main.player
	if p == null:
		return

	# Nearest hostile within engagement range
	var target: Node3D = null
	var best := 32.0
	for e in main.get_tree().get_nodes_in_group("enemies"):
		var d: float = e.global_position.distance_to(global_position)
		if d < best:
			best = d
			target = e

	var goal: Vector3
	if target != null and best < 26.0:
		# Engaged: hold ground, face the threat
		goal = global_position
		var to_e: Vector3 = target.global_position - global_position
		rotation.y = lerp_angle(rotation.y, atan2(-to_e.x, -to_e.z), 8.0 * delta)
		if fire_timer <= 0.0:
			fire_timer = randf_range(0.35, 0.6)
			_shoot(target, p)
	else:
		# Formation: a slot behind the player's shoulder
		var back: Vector3 = p.global_transform.basis.z
		var side: Vector3 = p.global_transform.basis.x
		goal = p.global_position + back * 3.0 \
			+ side * (2.2 if slot == 0 else -2.2)
		var to_g := goal - global_position
		to_g.y = 0
		if to_g.length() > 1.2:
			rotation.y = lerp_angle(rotation.y, atan2(-to_g.x, -to_g.z), 6.0 * delta)

	var to_goal := goal - global_position
	to_goal.y = 0
	if to_goal.length() > 1.2:
		var run: float = 1.6 if to_goal.length() > 9.0 else 1.0
		var dir := to_goal.normalized()
		velocity.x = dir.x * speed * run
		velocity.z = dir.z * speed * run
	else:
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)

	# walk cycle
	var gs := Vector2(velocity.x, velocity.z).length()
	bob_t += delta * gs * 1.5
	var swing := clampf(gs / 6.0, 0.0, 1.2)
	hip_l.rotation.x = sin(bob_t) * 0.55 * swing
	hip_r.rotation.x = -sin(bob_t) * 0.55 * swing

	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()


func _shoot(target: Node3D, p: Node3D) -> void:
	var origin := gun_tip.global_position
	var aim: Vector3 = target.global_position + Vector3(0, 0.5, 0)
	var dir := (aim - origin).normalized()
	# trigger discipline: don't shoot through the boss (that's you)
	var to_p: Vector3 = p.global_position + Vector3(0, 1, 0) - origin
	if to_p.length() < aim.distance_to(origin) \
			and dir.angle_to(to_p.normalized()) < 0.25:
		return
	dir = dir.rotated(Vector3.UP, randf_range(-0.02, 0.02))
	var bolt := ProjectileScript.new()
	bolt.velocity = dir * 100.0
	bolt.damage = 16.0
	bolt.shooter = self
	bolt.main = main
	main.add_child(bolt)
	bolt.global_position = origin
	main.sfx("shoot", -18.0)
