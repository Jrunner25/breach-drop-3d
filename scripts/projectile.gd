# A glowing bolt: manual raycast flight. Supports arcing globs (gravity),
# area damage, cryo-chill payloads, weak-point hits and hit feedback.
extends Node3D

var velocity := Vector3.ZERO
var damage := 26.0
var life := 2.2
var shooter: Node3D = null
var main: Node3D = null
var gravity := 0.0            # >0 for artillery arcs
var aoe := 0.0                # >0: explode on impact instead of pinging
var chill := 0.0              # seconds of slow applied to the victim
var dot_dps := 0.0            # corrosive payload: damage per second after impact
var dot_dur := 0.0
var pen := 4                  # armor penetration, 0..10 scale (default medium
							  # keeps allies/turrets effective vs plated units)
var color := Color(1.0, 0.85, 0.45)
var thickness := 0.02
var glow := 6.0


func _ready() -> void:
	var m := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = thickness
	cyl.bottom_radius = thickness
	cyl.height = 0.7 if gravity == 0.0 else 0.25
	m.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = glow
	m.material_override = mat
	m.rotation_degrees = Vector3(90, 0, 0)   # align with -Z travel
	add_child(m)
	if velocity.length() > 0.01:
		look_at(global_position + velocity, Vector3.UP)


func _physics_process(delta: float) -> void:
	velocity.y -= gravity * delta
	if gravity > 0.0 and velocity.length() > 0.01:
		look_at(global_position + velocity, Vector3.UP)
	var step := velocity * delta
	var q := PhysicsRayQueryParameters3D.create(global_position, global_position + step)
	if shooter != null and is_instance_valid(shooter):
		q.exclude = [shooter.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit:
		_impact(hit)
		return
	global_position += step
	life -= delta
	if life <= 0.0:
		queue_free()


func _impact(hit: Dictionary) -> void:
	var col: Object = hit.collider
	if aoe > 0.0 and main != null:
		main.explode(hit.position, aoe, damage, true)
	elif col != null:
		# Deterministic penetration: under the armor value the round
		# ricochets for nothing; dead even chips for half; over punches clean
		var dmg := damage
		if "armor_tier" in col:
			var tier := int(col.armor_tier)
			if pen < tier:
				dmg = 0.0
				if main != null and shooter == main.player:
					if randf() < 0.35:
						main.hud.add_popup("RICOCHET", hit.position)
					main.sfx("click", -22.0)
			elif pen == tier:
				dmg *= 0.5
		var died: bool = false
		if dmg > 0.0:
			if col.has_method("take_damage_at"):
				died = bool(col.take_damage_at(dmg, hit.position))
			elif col.has_method("take_damage"):
				var r: Variant = col.take_damage(dmg)
				died = r is bool and r
		if chill > 0.0 and col.has_method("apply_chill"):
			col.apply_chill(chill)
		# corrosion eats on a schedule, and it doesn't care about armor
		if dot_dps > 0.0 and main != null and col.has_method("take_damage"):
			main.apply_dot(col, dot_dps, dot_dur)
		# feedback for the trigger-puller — a ricochet is not a hit
		if main != null and shooter == main.player and dmg > 0.0 \
				and col.is_in_group("enemies"):
			main.register_hit(died)
	queue_free()
