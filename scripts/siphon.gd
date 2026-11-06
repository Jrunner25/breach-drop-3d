# A cryo-siphon: a Swarm crystal structure sunk into the permafrost.
# Destroy all of them to light the extraction beacon.
extends StaticBody3D

var main: Node3D
var health := 220.0
var crystal_mat: StandardMaterial3D
var t := 0.0


func _ready() -> void:
	add_to_group("objectives")

	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.6, 6.0, 2.6)
	cs.shape = box
	cs.position = Vector3(0, 3.0, 0)
	add_child(cs)

	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.12, 0.12, 0.16)
	dark.roughness = 0.3
	dark.metallic = 0.5
	crystal_mat = StandardMaterial3D.new()
	crystal_mat.albedo_color = Color(0.35, 0.18, 0.5)
	crystal_mat.roughness = 0.15
	crystal_mat.emission_enabled = true
	crystal_mat.emission = Color(0.7, 0.3, 1.0)
	crystal_mat.emission_energy_multiplier = 1.2

	# A cluster of leaning crystal shards over a dark root mass
	var base := MeshInstance3D.new()
	var bs := SphereMesh.new()
	bs.radius = 1.6
	bs.height = 1.6
	base.mesh = bs
	base.material_override = dark
	base.position = Vector3(0, 0.3, 0)
	add_child(base)
	for i in range(4):
		var m := MeshInstance3D.new()
		var prism := PrismMesh.new()
		var w := randf_range(0.7, 1.3)
		var h := randf_range(4.0, 7.0)
		prism.size = Vector3(w, h, w)
		m.mesh = prism
		m.material_override = crystal_mat
		m.position = Vector3(randf_range(-0.7, 0.7), h * 0.42, randf_range(-0.7, 0.7))
		m.rotation_degrees = Vector3(randf_range(-14, 14), randf_range(0, 360),
									 randf_range(-14, 14))
		add_child(m)

	var light := OmniLight3D.new()
	light.light_color = Color(0.7, 0.35, 1.0)
	light.light_energy = 2.5
	light.omni_range = 9.0
	light.position = Vector3(0, 3.0, 0)
	add_child(light)


func _process(delta: float) -> void:
	t += delta
	crystal_mat.emission_energy_multiplier = 1.2 + sin(t * 2.4) * 0.35


func take_damage(amount: float) -> void:
	health -= amount
	crystal_mat.emission_energy_multiplier = 3.5   # flinch flash
	if health <= 0.0:
		main._explosion_fx(global_position + Vector3(0, 2.5, 0), 6.0)
		main.on_siphon_destroyed(self)
		queue_free()
