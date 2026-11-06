# A burst of flying crystal chunks — the Swarm doesn't bleed, it shatters.
extends Node3D

var chunks: Array = []   # [mesh, velocity, spin_axis]
var life := 2.2


static func burst(parent: Node3D, pos: Vector3, color: Color, count: int = 7,
				  force: float = 7.0) -> void:
	var node: Node3D = load("res://scripts/debris.gd").new()
	parent.add_child(node)
	node.global_position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.2
	mat.metallic = 0.4
	for i in range(count):
		var m := MeshInstance3D.new()
		var prism := PrismMesh.new()
		var s := randf_range(0.08, 0.28)
		prism.size = Vector3(s, s * randf_range(1.2, 2.6), s)
		m.mesh = prism
		m.material_override = mat
		m.position = Vector3(randf_range(-0.2, 0.2), randf_range(0, 0.4),
							 randf_range(-0.2, 0.2))
		m.rotation_degrees = Vector3(randf_range(0, 360), randf_range(0, 360), 0)
		node.add_child(m)
		var vel := Vector3(randf_range(-1, 1), randf_range(0.6, 1.6),
						   randf_range(-1, 1)).normalized() * force \
						   * randf_range(0.5, 1.2)
		node.chunks.append([m, vel,
							Vector3(randf_range(-1, 1), randf_range(-1, 1),
									randf_range(-1, 1)).normalized()])


func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	for c in chunks:
		var m: MeshInstance3D = c[0]
		c[1] += Vector3(0, -16.0, 0) * delta
		m.position += c[1] * delta
		m.rotate(c[2], 6.0 * delta)
		if life < 0.5:
			m.scale = Vector3.ONE * maxf(0.01, life * 2.0)
