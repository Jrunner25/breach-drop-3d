# A Swarm vent: a breathing hole in the tundra that feeds the surge.
# Bullets ping off the chitin rim — only explosives seal it. While it
# breathes, it keeps birthing ticks into the sector.
extends StaticBody3D

const TickScript = preload("res://scripts/tick.gd")
const DebrisScript = preload("res://scripts/debris.gd")

var main: Node3D
var health := 260.0
var spawn_timer := 8.0
var maw_mat: StandardMaterial3D
var mound: Node3D
var t := 0.0


func _ready() -> void:
	add_to_group("structures")

	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.7
	cyl.height = 1.4
	cs.shape = cyl
	cs.position = Vector3(0, 0.7, 0)
	add_child(cs)

	mound = Node3D.new()
	add_child(mound)
	var chitin := StandardMaterial3D.new()
	chitin.albedo_color = Color(0.13, 0.12, 0.15)
	chitin.roughness = 0.35
	chitin.metallic = 0.3
	# The raised rim: a ring of jagged plates around the maw
	for i in range(8):
		var ang := i * TAU / 8.0
		var plate := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.9, randf_range(0.8, 1.5), 0.5)
		plate.mesh = pm
		plate.material_override = chitin
		plate.position = Vector3(cos(ang) * 1.5, 0.4, sin(ang) * 1.5)
		plate.rotation_degrees = Vector3(randf_range(-30, -12), -rad_to_deg(ang), 0)
		mound.add_child(plate)
	# The glowing maw
	var maw := MeshInstance3D.new()
	var mc := CylinderMesh.new()
	mc.top_radius = 1.1
	mc.bottom_radius = 0.7
	mc.height = 0.5
	maw.mesh = mc
	maw_mat = StandardMaterial3D.new()
	maw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	maw_mat.albedo_color = Color(0.55, 0.2, 0.8)
	maw_mat.emission_enabled = true
	maw_mat.emission = Color(0.75, 0.35, 1.0)
	maw_mat.emission_energy_multiplier = 2.2
	maw.material_override = maw_mat
	maw.position = Vector3(0, 0.2, 0)
	mound.add_child(maw)
	var gl := OmniLight3D.new()
	gl.light_color = Color(0.75, 0.35, 1.0)
	gl.light_energy = 2.4
	gl.omni_range = 9.0
	gl.position = Vector3(0, 1.2, 0)
	mound.add_child(gl)


func take_explosive_damage(amount: float) -> void:
	# Only called by area blasts — small-arms fire never reaches this
	health -= amount
	mound.scale = Vector3.ONE * 1.15
	var tw := create_tween()
	tw.tween_property(mound, "scale", Vector3.ONE, 0.15)
	if health <= 0.0:
		main.on_vent_destroyed(self)
		main._explosion_fx(global_position + Vector3(0, 0.5, 0), 4.0)
		DebrisScript.burst(main, global_position + Vector3(0, 0.6, 0),
						   Color(0.5, 0.25, 0.7), 12)
		queue_free()


func _physics_process(delta: float) -> void:
	if main.state != "playing":
		return
	t += delta
	maw_mat.emission_energy_multiplier = 2.2 + sin(t * 3.0) * 0.8
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = randf_range(12.0, 18.0)
		if main.alive_enemies() < 40 and main.player != null \
				and main.player.global_position.distance_to(global_position) < 95.0:
			var e: CharacterBody3D = TickScript.new()
			e.main = main
			main.add_child(e)
			var a := randf() * TAU
			var px := global_position.x + cos(a) * 2.0
			var pz := global_position.z + sin(a) * 2.0
			e.global_position = Vector3(px, main.ground_height(px, pz) + 1.5, pz)
