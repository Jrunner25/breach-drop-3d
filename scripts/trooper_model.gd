# Shared builder for the armored contractor model — used by the player in
# the field and the armory mannequin in the launch bay.
extends RefCounted


static func _box(parent: Node3D, size: Vector3, pos: Vector3,
				 mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.material_override = mat
	m.position = pos
	m.rotation_degrees = rot
	parent.add_child(m)
	return m


static func build(body_root: Node3D, paint: Color, visor_color: Color,
				  rig: Dictionary = {}) -> Dictionary:
	# Plated armor: helmet, chest rig, pauldrons, heavy backpack,
	# articulated legs. The chassis decides the silhouette: weight class
	# scales the build, the set affiliation colors the trim, and each
	# rig's perk hardware is bolted on where you can see it.
	var armor := StandardMaterial3D.new()
	armor.albedo_color = paint
	armor.roughness = 0.55
	armor.metallic = 0.45
	# material wear: scratched plating catches light unevenly, and a faint
	# normal breakup gives the panels dents instead of CAD-perfect faces
	var scratch := NoiseTexture2D.new()
	var sn := FastNoiseLite.new()
	sn.frequency = 0.7
	sn.fractal_octaves = 3
	scratch.noise = sn
	scratch.seamless = true
	armor.roughness_texture = scratch
	var dents := NoiseTexture2D.new()
	var dn := FastNoiseLite.new()
	dn.frequency = 0.45
	dents.noise = dn
	dents.seamless = true
	dents.as_normal_map = true
	armor.normal_enabled = true
	armor.normal_texture = dents
	armor.normal_scale = 0.35
	armor.uv1_triplanar = true
	armor.uv1_scale = Vector3(6.0, 6.0, 6.0)
	# the under-suit is cloth: it absorbs light instead of bouncing it
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.13, 0.13, 0.15)
	dark.roughness = 1.0
	dark.metallic = 0.0
	var trim := StandardMaterial3D.new()
	# trim color declares the set affiliation at a glance
	match str(rig.get("set", "?")):
		"HR": trim.albedo_color = Color(0.25, 0.7, 1.0)
		"TECH": trim.albedo_color = Color(0.3, 1.0, 0.55)
		"TAKEOVER": trim.albedo_color = Color(1.0, 0.28, 0.2)
		"": trim.albedo_color = Color(0.75, 0.75, 0.78)   # the Underwriter's grey
		_: trim.albedo_color = Color(0.95, 0.45, 0.10)
	trim.roughness = 0.45
	trim.metallic = 0.2
	var power := StandardMaterial3D.new()
	power.emission_enabled = true
	power.emission = Color(0.2, 0.85, 1.0)
	power.emission_energy_multiplier = 0.9
	power.albedo_color = Color(0.05, 0.2, 0.25)

	var hip_l: Node3D
	var hip_r: Node3D
	for side in [-1.0, 1.0]:
		var hip := Node3D.new()
		hip.position = Vector3(0.15 * side, 0.86, 0)
		body_root.add_child(hip)
		_box(hip, Vector3(0.19, 0.42, 0.22), Vector3(0, -0.22, 0), armor)
		_box(hip, Vector3(0.05, 0.30, 0.02), Vector3(0.10 * side, -0.24, -0.11), trim)
		_box(hip, Vector3(0.16, 0.40, 0.18), Vector3(0, -0.62, 0.02), dark)
		_box(hip, Vector3(0.18, 0.10, 0.30), Vector3(0, -0.82, -0.04), armor)
		if side < 0:
			hip_l = hip
		else:
			hip_r = hip

	_box(body_root, Vector3(0.36, 0.18, 0.26), Vector3(0, 0.92, 0), dark)
	_box(body_root, Vector3(0.42, 0.42, 0.30), Vector3(0, 1.20, 0), armor)
	_box(body_root, Vector3(0.46, 0.26, 0.36), Vector3(0, 1.32, -0.02), armor)
	_box(body_root, Vector3(0.30, 0.05, 0.02), Vector3(0, 1.38, -0.21), trim)
	_box(body_root, Vector3(0.10, 0.16, 0.02), Vector3(-0.14, 1.24, -0.18), dark)

	for side in [-1.0, 1.0]:
		_box(body_root, Vector3(0.20, 0.16, 0.26), Vector3(0.31 * side, 1.42, 0), armor)
		_box(body_root, Vector3(0.22, 0.04, 0.28), Vector3(0.31 * side, 1.51, 0), trim)
	_box(body_root, Vector3(0.13, 0.34, 0.15), Vector3(-0.33, 1.15, -0.05), dark,
		 Vector3(18, 0, 8))
	_box(body_root, Vector3(0.13, 0.30, 0.14), Vector3(0.33, 1.18, -0.18), dark,
		 Vector3(42, 0, -6))

	_box(body_root, Vector3(0.38, 0.52, 0.24), Vector3(0, 1.22, 0.28), dark)
	_box(body_root, Vector3(0.30, 0.14, 0.20), Vector3(0, 1.54, 0.26), armor)
	_box(body_root, Vector3(0.12, 0.24, 0.10), Vector3(-0.27, 1.12, 0.30), armor)
	_box(body_root, Vector3(0.12, 0.20, 0.10), Vector3(0.27, 1.16, 0.30), dark)
	_box(body_root, Vector3(0.035, 0.22, 0.02), Vector3(-0.12, 1.30, 0.41), power)
	var antenna := MeshInstance3D.new()
	var ac := CylinderMesh.new()
	ac.top_radius = 0.008
	ac.bottom_radius = 0.012
	ac.height = 0.5
	antenna.mesh = ac
	antenna.material_override = dark
	antenna.position = Vector3(0.16, 1.72, 0.30)
	body_root.add_child(antenna)

	var head := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 0.20
	hs.height = 0.40
	head.mesh = hs
	head.material_override = armor
	head.position = Vector3(0, 1.66, 0)
	body_root.add_child(head)
	_box(body_root, Vector3(0.34, 0.09, 0.20), Vector3(0, 1.74, -0.05), armor)
	_box(body_root, Vector3(0.10, 0.05, 0.34), Vector3(0, 1.80, 0.0), dark)

	var visor := MeshInstance3D.new()
	var vb := BoxMesh.new()
	vb.size = Vector3(0.24, 0.09, 0.05)
	visor.mesh = vb
	var vm := StandardMaterial3D.new()
	vm.emission_enabled = true
	vm.emission = visor_color
	vm.emission_energy_multiplier = 0.6
	vm.albedo_color = visor_color * 0.12
	visor.material_override = vm
	visor.position = Vector3(0, 1.67, -0.17)
	body_root.add_child(visor)

	var gun_root := Node3D.new()
	gun_root.position = Vector3(0.32, 1.12, -0.42)
	body_root.add_child(gun_root)
	build_gun(gun_root, "RIFLE")

	var gun_tip := Node3D.new()
	gun_tip.position = Vector3(0.32, 1.14, -1.20)
	body_root.add_child(gun_tip)

	# ---- the rig's perk hardware, worn where everyone can see it ----
	if rig.get("radar", false):
		# recon sensor mast + dish on the pack
		for ax in [Vector3(0.10, 1.86, 0.32), Vector3(0.04, 1.94, 0.34)]:
			var an := MeshInstance3D.new()
			var acyl := CylinderMesh.new()
			acyl.top_radius = 0.006
			acyl.bottom_radius = 0.01
			acyl.height = 0.42
			an.mesh = acyl
			an.material_override = dark
			an.position = ax
			body_root.add_child(an)
		_box(body_root, Vector3(0.16, 0.14, 0.03), Vector3(-0.12, 1.62, 0.34),
			 trim, Vector3(-20, 30, 0))
	if rig.get("explosive", 1.0) < 1.0:
		# siege plating: an extra chest slab and heavier pauldrons
		_box(body_root, Vector3(0.40, 0.30, 0.08), Vector3(0, 1.28, -0.20), armor)
		for side in [-1.0, 1.0]:
			_box(body_root, Vector3(0.24, 0.10, 0.30),
				 Vector3(0.33 * side, 1.56, 0), armor)
	if rig.get("stims", 0) > 0 or rig.get("throw", 1.0) > 1.0:
		# tech kit: med-pod cells on the hip, an oversized service pack
		for i in range(3):
			_box(body_root, Vector3(0.05, 0.10, 0.05),
				 Vector3(0.24, 0.96 - i * 0.02, 0.14 + i * 0.07), power)
		_box(body_root, Vector3(0.30, 0.30, 0.14), Vector3(0, 1.10, 0.36), dark)
	if rig.get("clause", false):
		# the Underwriter carries the paperwork: a hard-shell case
		_box(body_root, Vector3(0.10, 0.26, 0.34), Vector3(-0.30, 0.92, 0.10), trim)
		_box(body_root, Vector3(0.12, 0.04, 0.36), Vector3(-0.30, 1.06, 0.10), dark)

	# weight class silhouette: LIGHT runs lean, HEAVY fills the doorway
	match str(rig.get("weight", "MEDIUM")):
		"LIGHT":
			body_root.scale = Vector3(0.88, 1.04, 0.90)
		"HEAVY":
			body_root.scale = Vector3(1.20, 0.97, 1.14)
		_:
			body_root.scale = Vector3.ONE   # rebuilt mannequins must reset

	return {"armor": armor, "visor": vm, "hip_l": hip_l, "hip_r": hip_r,
			"gun_tip": gun_tip, "head": head, "gun_root": gun_root}


static func _cyl(parent: Node3D, r: float, length: float, pos: Vector3,
				 mat: Material, rot := Vector3(90, 0, 0)) -> MeshInstance3D:
	# a cylinder lying along the barrel axis by default
	var m := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = length
	m.mesh = c
	m.material_override = mat
	m.position = pos
	m.rotation_degrees = rot
	parent.add_child(m)
	return m


static func build_gun(gun_root: Node3D, key: String) -> void:
	# Every instrument has its own silhouette. Rebuilt on weapon swap, so
	# the gun in your hands is the gun on your HUD.
	for c in gun_root.get_children():
		c.queue_free()
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.16, 0.16, 0.18)
	metal.roughness = 0.4
	metal.metallic = 0.7
	var grip := StandardMaterial3D.new()
	grip.albedo_color = Color(0.10, 0.10, 0.11)
	grip.roughness = 0.9
	var glow := StandardMaterial3D.new()
	glow.emission_enabled = true
	glow.emission = Color(0.2, 0.85, 1.0)
	glow.emission_energy_multiplier = 1.2
	glow.albedo_color = Color(0.05, 0.2, 0.25)
	match key:
		"CRYO_SHOTGUN":
			glow.emission = Color(0.45, 0.85, 1.0)
		"SYNERGY_6":
			glow.emission = Color(1.0, 0.4, 0.3)
			glow.albedo_color = Color(0.25, 0.06, 0.05)
		"AUDIT_GAS":
			glow.emission = Color(0.65, 0.95, 0.2)
			glow.albedo_color = Color(0.15, 0.22, 0.04)
		"SEVERANCE":
			glow.emission = Color(0.6, 0.45, 1.0)
			glow.albedo_color = Color(0.12, 0.08, 0.25)

	match key:
		"CRYO_SHOTGUN":
			# fat-bore scattergun with an under-tube and frost jacket
			_box(gun_root, Vector3(0.10, 0.14, 0.46), Vector3(0, 0, 0.02), metal)
			_box(gun_root, Vector3(0.09, 0.09, 0.5), Vector3(0, 0.02, -0.48), metal)
			_box(gun_root, Vector3(0.05, 0.05, 0.44), Vector3(0, -0.06, -0.44), grip)
			_box(gun_root, Vector3(0.03, 0.03, 0.4), Vector3(0.06, 0.02, -0.4), glow)
			_box(gun_root, Vector3(0.06, 0.18, 0.10), Vector3(0, -0.14, 0.06), grip)
			_box(gun_root, Vector3(0.07, 0.11, 0.16), Vector3(0, -0.02, 0.28), grip)
		"DMR":
			# long, thin, patient: pencil barrel and a proper optic
			_box(gun_root, Vector3(0.07, 0.11, 0.5), Vector3(0, 0, 0.0), metal)
			_cyl(gun_root, 0.022, 0.72, Vector3(0, 0.02, -0.72), metal)
			_cyl(gun_root, 0.035, 0.22, Vector3(0, 0.11, -0.10), grip)
			_box(gun_root, Vector3(0.06, 0.12, 0.22), Vector3(0, -0.03, 0.32), grip)
			_box(gun_root, Vector3(0.06, 0.18, 0.09), Vector3(0, -0.14, 0.04), grip)
		"FLUX_CASTER":
			# a thermal block wrapped in coil rings, cell glowing
			_box(gun_root, Vector3(0.12, 0.16, 0.46), Vector3(0, 0, 0.0), metal)
			_cyl(gun_root, 0.04, 0.34, Vector3(0, 0.02, -0.44), metal)
			for i in range(3):
				_box(gun_root, Vector3(0.15, 0.15, 0.025),
					 Vector3(0, 0.02, -0.3 - i * 0.11), grip)
			_box(gun_root, Vector3(0.05, 0.09, 0.14), Vector3(0.07, 0.0, 0.05), glow)
			_box(gun_root, Vector3(0.06, 0.18, 0.10), Vector3(0, -0.14, 0.08), grip)
		"DOWNSIZER":
			# heavy semi-auto: thick barrel, muzzle brake, tall optic
			_box(gun_root, Vector3(0.10, 0.15, 0.55), Vector3(0, 0, 0.02), metal)
			_cyl(gun_root, 0.03, 0.7, Vector3(0, 0.02, -0.75), metal)
			_box(gun_root, Vector3(0.09, 0.09, 0.10), Vector3(0, 0.02, -1.06), grip)
			_cyl(gun_root, 0.04, 0.24, Vector3(0, 0.13, -0.05), grip)
			_box(gun_root, Vector3(0.05, 0.17, 0.09), Vector3(0, -0.15, -0.06), metal)
			_box(gun_root, Vector3(0.06, 0.18, 0.10), Vector3(0, -0.14, 0.1), grip)
		"REDUNDANCY":
			# drum-fed autoshotgun: short, wide, all appetite
			_box(gun_root, Vector3(0.11, 0.15, 0.5), Vector3(0, 0, 0.0), metal)
			_box(gun_root, Vector3(0.08, 0.08, 0.32), Vector3(0, 0.02, -0.42), metal)
			_box(gun_root, Vector3(0.10, 0.04, 0.34), Vector3(0, 0.09, -0.36), grip)
			_cyl(gun_root, 0.09, 0.07, Vector3(0, -0.13, -0.08), grip,
				 Vector3(0, 0, 90))
			_box(gun_root, Vector3(0.06, 0.18, 0.10), Vector3(0, -0.14, 0.1), grip)
		"SYNERGY_6":
			# sleek emitter rail with heat fins and a red line down the side
			_box(gun_root, Vector3(0.06, 0.10, 0.68), Vector3(0, 0, -0.05), metal)
			_box(gun_root, Vector3(0.02, 0.03, 0.55), Vector3(0.045, 0.01, -0.1), glow)
			for i in range(3):
				_box(gun_root, Vector3(0.11, 0.02, 0.07),
					 Vector3(0, 0.07 + i * 0.015, -0.05 - i * 0.1), grip)
			_box(gun_root, Vector3(0.03, 0.03, 0.22), Vector3(0, 0.01, -0.5), glow)
			_box(gun_root, Vector3(0.06, 0.18, 0.10), Vector3(0, -0.14, 0.06), grip)
		"AUDIT_GAS":
			# pressurized sanitizer: tank underneath, cone nozzle up front
			_box(gun_root, Vector3(0.09, 0.11, 0.42), Vector3(0, 0, 0.0), metal)
			_cyl(gun_root, 0.06, 0.28, Vector3(0, -0.12, 0.02), metal,
				 Vector3(0, 0, 0))
			_box(gun_root, Vector3(0.02, 0.06, 0.3), Vector3(0.055, -0.06, -0.1), glow)
			var noz := MeshInstance3D.new()
			var nc := CylinderMesh.new()
			nc.top_radius = 0.012
			nc.bottom_radius = 0.05
			nc.height = 0.3
			noz.mesh = nc
			noz.material_override = grip
			noz.position = Vector3(0, 0.0, -0.4)
			noz.rotation_degrees = Vector3(90, 0, 0)
			gun_root.add_child(noz)
			_box(gun_root, Vector3(0.06, 0.16, 0.10), Vector3(0, -0.14, 0.1), grip)
		"EVICTION":
			# a hand-cannon revolver: visible drum, stub barrel, no apologies
			_box(gun_root, Vector3(0.06, 0.10, 0.2), Vector3(0, 0, 0.05), metal)
			_cyl(gun_root, 0.05, 0.09, Vector3(0, 0.0, -0.1), grip)
			_cyl(gun_root, 0.028, 0.3, Vector3(0, 0.02, -0.3), metal)
			_box(gun_root, Vector3(0.05, 0.15, 0.07), Vector3(0, -0.11, 0.1), grip,
				 Vector3(-15, 0, 0))
		"MICRO_MANAGER":
			# a pocket hurricane: stub SMG, magazine longer than the gun
			_box(gun_root, Vector3(0.07, 0.10, 0.28), Vector3(0, 0, 0.0), metal)
			_cyl(gun_root, 0.02, 0.14, Vector3(0, 0.01, -0.2), metal)
			_box(gun_root, Vector3(0.04, 0.2, 0.06), Vector3(0, -0.15, -0.02), metal)
			_box(gun_root, Vector3(0.05, 0.12, 0.07), Vector3(0, -0.10, 0.1), grip,
				 Vector3(-12, 0, 0))
		"SEVERANCE":
			# plasma pistol: a rounded core with an unstable violet orb
			_box(gun_root, Vector3(0.08, 0.10, 0.28), Vector3(0, 0, 0.02), metal)
			var orb := MeshInstance3D.new()
			var os_m := SphereMesh.new()
			os_m.radius = 0.045
			os_m.height = 0.09
			orb.mesh = os_m
			orb.material_override = glow
			orb.position = Vector3(0, 0.01, -0.2)
			gun_root.add_child(orb)
			_box(gun_root, Vector3(0.10, 0.03, 0.16), Vector3(0, 0.07, -0.02), grip)
			_box(gun_root, Vector3(0.05, 0.13, 0.07), Vector3(0, -0.10, 0.09), grip,
				 Vector3(-14, 0, 0))
		_:
			# MK-4 RIFLE: the honest workhorse everyone learned on
			_box(gun_root, Vector3(0.09, 0.13, 0.62), Vector3(0, 0, -0.05), metal)
			_box(gun_root, Vector3(0.06, 0.06, 0.42), Vector3(0, 0.02, -0.55), metal)
			_box(gun_root, Vector3(0.06, 0.18, 0.10), Vector3(0, -0.14, 0.02), grip)
			_box(gun_root, Vector3(0.05, 0.07, 0.16), Vector3(0, 0.10, 0.05), grip)
			_box(gun_root, Vector3(0.05, 0.14, 0.08), Vector3(0, -0.12, -0.16), metal)
			_box(gun_root, Vector3(0.02, 0.05, 0.10), Vector3(0.05, 0.0, -0.12), glow)
