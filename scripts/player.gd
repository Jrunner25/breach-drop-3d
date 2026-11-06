# The Breacher: over-the-shoulder camera, full pitch freedom, weight & momentum.
extends CharacterBody3D

const ProjectileScript = preload("res://scripts/projectile.gd")
const TrooperModel = preload("res://scripts/trooper_model.gd")

const PITCH_MIN := deg_to_rad(-80.0)   # look at the sky (and the hellpods)
const PITCH_MAX := deg_to_rad(78.0)    # look at your boots

# The armory's primaries
const WEAPONS := {
	"RIFLE": {"name": "MK-4 RIFLE", "damage": 26.0, "rate": 0.14, "mag": 24,
			  "reserve": 168, "speed": 110.0, "spread": 0.004, "pellets": 1,
			  "chill": 0.0, "heat": false, "kick": 4.0, "pen": 2,
			  "desc": "The honest workhorse. Full auto."},
	"CRYO_SHOTGUN": {"name": "CRYO SHOTGUN", "damage": 9.0, "rate": 0.9,
					 "mag": 6, "reserve": 48, "speed": 80.0, "spread": 0.055,
					 "pellets": 8, "chill": 1.6, "heat": false, "kick": 9.0,
					 "pen": 2, "color": Color(0.6, 0.9, 1.0),
					 "desc": "Eight frozen pellets. Chills whatever survives."},
	"DMR": {"name": "LONGSHOT DMR", "damage": 95.0, "rate": 0.85, "mag": 8,
			"reserve": 56, "speed": 170.0, "spread": 0.001, "pellets": 1,
			"chill": 0.0, "heat": false, "kick": 7.0, "pen": 4,
			"desc": "One round, one knee joint. Slow and final."},
	"FLUX_CASTER": {"name": "FLUX CASTER", "damage": 20.0, "rate": 0.10,
					"mag": 0, "reserve": 0, "speed": 120.0, "spread": 0.006,
					"pellets": 1, "chill": 0.0, "heat": true, "kick": 3.0,
					"pen": 4, "color": Color(0.45, 0.85, 1.0),
					"desc": "No ammo — only heat. Vent before it melts."},
	# Corporate Claims: the corporate-fused arsenal
	"DOWNSIZER": {"name": "'DOWNSIZER' MARKSMAN", "damage": 55.0, "rate": 0.38,
				  "mag": 10, "reserve": 70, "speed": 160.0, "spread": 0.0018,
				  "pellets": 1, "chill": 0.0, "heat": false, "kick": 13.0,
				  "reload": 1.9, "pen": 4,
				  "desc": "High-caliber semi-auto. Massive recoil; opens medium plate with a clang."},
	"REDUNDANCY": {"name": "'REDUNDANCY' SHOTGUN", "damage": 8.0, "rate": 0.26,
				   "mag": 14, "reserve": 84, "speed": 70.0, "spread": 0.085,
				   "pellets": 7, "chill": 0.0, "heat": false, "kick": 8.0,
				   "reload": 3.4, "pen": 2,
				   "desc": "Drum-fed automatic dispersion. Erases swarms point-blank; reloads like paperwork."},
	"SYNERGY_6": {"name": "'SYNERGY-6' LASER", "damage": 11.0, "rate": 0.07,
				  "mag": 0, "reserve": 0, "speed": 260.0, "spread": 0.0008,
				  "pellets": 1, "chill": 0.0, "heat": true, "kick": 0.8,
				  "heat_shot": 2.6, "pen": 4, "color": Color(1.0, 0.45, 0.35),
				  "desc": "Coherent light on a heat sink. Pace it: infinite ammo. Melt it: manual swap."},
	"AUDIT_GAS": {"name": "'AUDIT-GAS' DISPENSER", "damage": 3.0, "rate": 0.06,
				  "mag": 80, "reserve": 240, "speed": 45.0, "spread": 0.02,
				  "pellets": 1, "chill": 0.0, "heat": false, "kick": 0.3,
				  "reload": 2.4, "dot_dps": 14.0, "dot_dur": 3.0, "pen": 2,
				  "color": Color(0.72, 0.95, 0.2),
				  "desc": "Corrosive sanitizer stream. Bypasses plate — eats carapace and circuits over time."},
}
# The pocket-sized solutions that keep you on the payroll ([2] to draw)
const SIDEARMS := {
	"EVICTION": {"name": "NOTICE OF EVICTION", "damage": 85.0, "rate": 0.75,
				 "mag": 6, "reserve": 30, "speed": 150.0, "spread": 0.002,
				 "pellets": 1, "chill": 0.7, "heat": false, "kick": 12.0,
				 "reload": 2.6, "pen": 4,
				 "desc": "A hand-cannon revolver. Six rounds, no appeals — staggers whatever rushes you."},
	"MICRO_MANAGER": {"name": "MICRO-MANAGER", "damage": 9.0, "rate": 0.05,
					  "mag": 30, "reserve": 150, "speed": 85.0, "spread": 0.035,
					  "pellets": 1, "chill": 0.0, "heat": false, "kick": 2.2,
					  "reload": 1.5, "pen": 2,
					  "desc": "The whole mag in 1.5 seconds. Inaccurate, violent, perfect: a get-off-me button."},
	"SEVERANCE": {"name": "SEVERANCE PAY", "damage": 110.0, "rate": 1.2,
				  "mag": 5, "reserve": 20, "speed": 26.0, "spread": 0.004,
				  "pellets": 1, "chill": 0.0, "heat": false, "kick": 7.0,
				  "reload": 2.2, "aoe": 3.5, "gravity": 2.5, "thick": 0.09,
				  "pen": 4, "color": Color(0.55, 0.4, 1.0),
				  "desc": "A slow ball of unstable plasma. Pops armored structures from a safe distance."},
}
# Field kit: the grenade slot ([F] to throw). Smoke breaks line of sight;
# the rest of the catalogue is honest explosives.
const GRENADES := {
	"PINK_SLIP": {"name": "PINK SLIP FRAG", "count": 4, "radius": 6.0,
				  "dmg": 260.0, "color": Color(1.0, 0.4, 0.3),
				  "desc": "Standard-issue termination. 6 m of it."},
	"NDA": {"name": "NDA CANISTER", "count": 4, "smoke": true,
			"color": Color(0.7, 0.74, 0.8),
			"desc": "10 s of legally binding smoke. Nothing inside it gets spotted or shot."},
	"RESTRUCTURING": {"name": "RESTRUCTURING CHARGE", "count": 3, "radius": 4.0,
					  "dmg": 420.0, "color": Color(1.0, 0.62, 0.2),
					  "desc": "A demolition charge for load-bearing problems. Seals Swarm vents."},
}
const BOOSTERS := ["EXPENSE ACCOUNT", "SATELLITE UPLINK", "GYM MEMBERSHIP",
				   "OVERTIME AUTHORIZATION"]

const WALK_SPEED := 6.2
const SPRINT_MULT := 1.55
const ACCEL := 22.0
const SPRINT_ACCEL := 9.0              # momentum: sprinting steers badly
const STAMINA_MAX := 100.0

var main: Node3D
var custom := {}          # rig stats + paint/visor colors from the armory
var pivot: Node3D
var arm: SpringArm3D
var cam: Camera3D
var gun_tip: Node3D
var gun_root: Node3D
var muzzle_light: OmniLight3D
var body_mesh: MeshInstance3D
var armor_mat: StandardMaterial3D
var visor_mat: StandardMaterial3D
var hip_l: Node3D
var hip_r: Node3D
var body_root: Node3D
var speed_mult := 1.0
var stam_mult := 1.0
var bob_t := 0.0

var max_health := 150.0
var health := 150.0
var max_plating := 40.0
var plating := 40.0
var plating_delay := 0.0
var stamina := STAMINA_MAX
var sprinting := false

var weapon_key := "RIFLE"
var side_key := "EVICTION"
var active_slot := 0          # 0: primary, 1: sidearm — keys 1 / 2
var slot_state := [{}, {}]    # the holstered gun's ammo/heat, stashed on swap
var wpn: Dictionary = WEAPONS["RIFLE"]
var mag_size := 24
var ammo := 24
var reserve := 168
var reloading := false
var reload_timer := 0.0
var reload_total := 1.7
var fire_timer := 0.0
var recoil := 0.0
var heat := 0.0               # Flux Caster thermal load (0..100)
var overheated := false
var vent_timer := 0.0
var aiming := false
var sens := 0.0022
var samples := 0
var mounted := false          # riding the VULTURE skimmer

var dive_timer := 0.0
var dive_cd := 0.0
var invincible := 0.0
var shake := 0.0
var alive := true

# Stance: 0 standing, 1 crouched, 2 prone. Braced stances tame recoil and
# sway and shrink your silhouette; prone crawling is the deep-stealth play.
var stance := 0
const STANCE_SPEED := [1.0, 0.55, 0.25]
const STANCE_KICK := [1.0, 0.7, 0.4]
const STANCE_SWAY := [1.0, 0.7, 0.45]
const STANCE_STEALTH := [1.0, 0.7, 0.45]
const STANCE_HEIGHT := [1.62, 1.12, 0.55]

# Localized damage: the body keeps the score
var arm_hurt := false         # fractured arm: aim sway doubles
var leg_hurt := false         # fractured leg: no sprinting, slower

# The disposable identity: assigned by the Void Anchor, replaced on death
var recruit := {}             # {"name": .., "pers": ..} from main.new_recruit
var voice_idx := 0            # 0 randomized, else fixed personality

# Field kit and pre-drop booster
var grenade_key := "PINK_SLIP"
var grenades := 4
var grenade_bonus := 0        # Auditor Exo carries a spare
var bogged := false           # wading through a deep drift / ash mire

# The battle-scarred suit: you drop in clean; the mission files its wear
var grime := 0.0              # 0 factory-fresh .. 1 caked
var base_paint := Color(0.62, 0.58, 0.52)
var reserve_mult := 1.0       # Expense Account: fatter reserves
var has_clause := false       # Underwriter rig: Act of God survival clause

# Chem-stims: instant field healing, refilled by ammo pods
var stims := 3
var stim_heal := 0.0

# The Asset Suit (Corporate Claims): the chassis IS the set's body piece;
# match the visor and ID tag to it for the full-uniform synergy
var chassis_set := ""         # from the rig: HR (Recon) | TECH (Contractor) | TAKEOVER (Siege)
var suit_visor := ""
var suit_tag := ""
var synergy := ""             # "HR" | "TAKEOVER" | "TECH" when the uniform matches
var radar := false            # Recon Weave: tactical radar pings hostiles
var radar_t := 0.0
var radar_pings: Array = []   # enemy position snapshots for the compass
var detect_mult := 1.0        # HR visor: patrols spot you later
var sprint_mult := 1.0        # HR chassis: faster sprint
var stam_regen_mult := 1.0    # HR tag
var braced_recoil_mult := 1.0 # Takeover visor: recoil while aiming
var explosive_mult := 1.0     # Takeover chassis: incoming explosive damage
var plating_bonus := 0.0      # Takeover tag
var cd_mult := 1.0            # Tech visor: stratagem cooldown recovery rate
var throw_mult := 1.0         # Tech chassis: flare throw range
var bonus_stims := 0          # Tech tag
var overtime_t := 0.0         # Sunk Cost Fallacy: six seconds of borrowed time
var overtime_used := false
var emote_cd := 0.0           # Deflection of Blame
var burst_t := 0.0            # blame deflected: escape speed burst


func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	safe_margin = 0.06   # generous margin: never tunnel through terrain seams
	floor_snap_length = 0.4

	# Armory customization: the Body Chassis dictates the weight class
	if custom.has("rig"):
		var rig: Dictionary = custom["rig"]
		max_health = 150.0 * rig["hp"]
		health = max_health
		speed_mult = rig["speed"]
		stam_mult = rig["stam"]
	weapon_key = custom.get("weapon", "RIFLE")
	wpn = WEAPONS[weapon_key]
	mag_size = wpn["mag"]
	ammo = mag_size
	reserve = wpn["reserve"]
	side_key = custom.get("sidearm", "EVICTION")
	var sd: Dictionary = SIDEARMS[side_key]
	slot_state[1] = {"ammo": sd["mag"], "reserve": sd["reserve"],
					 "heat": 0.0, "over": false, "vent": 0.0}
	_apply_suit()
	stims = 3 + bonus_stims
	grenade_key = custom.get("grenade", "PINK_SLIP")
	grenade_bonus = custom.get("rig", {}).get("grenades", 0)
	grenades = int(GRENADES[grenade_key]["count"]) + grenade_bonus
	reserve = int(reserve * reserve_mult)
	slot_state[1]["reserve"] = int(int(slot_state[1]["reserve"]) * reserve_mult)
	if main != null and main.settings.has("sens"):
		sens = main.settings["sens"]

	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.8
	cs.shape = cap
	cs.position = Vector3(0, 0.9, 0)
	add_child(cs)

	_build_body()

	# Over-the-shoulder rig: pivot (pitch) -> spring arm -> camera.
	# The sideways offset composes the character to the lower-left.
	pivot = Node3D.new()
	pivot.position = Vector3(0.55, 1.62, 0)
	add_child(pivot)
	arm = SpringArm3D.new()
	arm.spring_length = 2.7
	arm.collision_mask = 1
	arm.add_excluded_object(get_rid())   # never collide with our own body
	pivot.add_child(arm)
	cam = Camera3D.new()
	cam.fov = 72.0
	arm.add_child(cam)
	cam.current = true    # take over from the launch-bay camera
	pivot.rotation.x = deg_to_rad(-12.0)


func _apply_suit() -> void:
	# The chassis carries the weight class; visor and tag are minor bumps.
	# All three from one set -> the Corporate Synergy passive goes live.
	var rig: Dictionary = custom.get("rig", {})
	chassis_set = rig.get("set", "")
	max_plating = rig.get("plating", 40.0)
	sprint_mult = rig.get("sprint", 1.0)
	radar = rig.get("radar", false)
	bonus_stims = rig.get("stims", 0)
	throw_mult = rig.get("throw", 1.0)
	explosive_mult = rig.get("explosive", 1.0)
	suit_visor = custom.get("suit_visor", "")
	suit_tag = custom.get("suit_tag", "")
	match suit_visor:
		"HR": detect_mult = 0.7
		"TAKEOVER": braced_recoil_mult = 0.7
		"TECH": cd_mult = 1.1
	match suit_tag:
		"HR": stam_regen_mult = 1.3
		"TAKEOVER": plating_bonus = 15.0
		"TECH": bonus_stims += 1
	has_clause = rig.get("clause", false)
	if chassis_set != "" and suit_visor == chassis_set \
			and suit_tag == chassis_set:
		synergy = chassis_set
	max_plating += plating_bonus
	# The pre-drop booster: one passive, chosen on the deck
	match int(custom.get("booster", 0)):
		0: reserve_mult = 1.5              # Expense Account
		1: radar = true                    # Satellite Uplink
		2:                                 # Gym Membership
			stam_mult *= 0.8
			stam_regen_mult *= 1.25
		3: pass                            # Overtime Authorization (the Anchor handles it)
	# Caustic squalls eat plating before you even land
	if main != null and main.planet.get("caustic", false):
		max_plating *= 0.7
	plating = max_plating


func blast_toss() -> void:
	# The pressure wave wins: knocked flat, tumbling, no steering
	stance = 2
	dive_timer = maxf(dive_timer, 0.45)
	shake = maxf(shake, 7.0)
	grime = minf(1.0, grime + 0.12)


func stealth_mult() -> float:
	# How far away things notice you: suit optics times body posture
	return detect_mult * STANCE_STEALTH[stance]


func _switch_slot(s: int) -> void:
	if s == active_slot:
		return
	slot_state[active_slot] = {"ammo": ammo, "reserve": reserve, "heat": heat,
							   "over": overheated, "vent": vent_timer}
	active_slot = s
	wpn = WEAPONS[weapon_key] if s == 0 else SIDEARMS[side_key]
	mag_size = wpn["mag"]
	var st: Dictionary = slot_state[s]
	ammo = st["ammo"]
	reserve = st["reserve"]
	heat = st["heat"]
	overheated = st["over"]
	vent_timer = st["vent"]
	reloading = false            # rounds mid-swap stay in the old clip
	fire_timer = maxf(fire_timer, 0.35)   # draw time
	if gun_root != null:
		TrooperModel.build_gun(gun_root, weapon_key if s == 0 else side_key)
	main.sfx("click", -14.0)


func resupply() -> void:
	# Ammo pod: both guns topped up, stims and grenades restocked
	reserve = int(int(wpn["reserve"]) * reserve_mult)
	var other_def: Dictionary = SIDEARMS[side_key] if active_slot == 0 \
		else WEAPONS[weapon_key]
	if not slot_state[1 - active_slot].is_empty():
		slot_state[1 - active_slot]["reserve"] = \
			int(int(other_def["reserve"]) * reserve_mult)
	stims = 3 + bonus_stims
	grenades = int(GRENADES[grenade_key]["count"]) + grenade_bonus


func _build_body() -> void:
	body_root = Node3D.new()
	add_child(body_root)
	base_paint = custom.get("paint", Color(0.62, 0.58, 0.52))
	var parts: Dictionary = TrooperModel.build(
		body_root,
		base_paint,
		custom.get("visor", Color(1.0, 0.7, 0.15)),
		custom.get("rig", {}))
	armor_mat = parts["armor"]
	visor_mat = parts["visor"]
	hip_l = parts["hip_l"]
	hip_r = parts["hip_r"]
	gun_tip = parts["gun_tip"]
	gun_root = parts["gun_root"]
	body_mesh = parts["head"]
	TrooperModel.build_gun(gun_root, weapon_key)   # carry what you picked

	muzzle_light = OmniLight3D.new()
	muzzle_light.light_color = Color(1.0, 0.85, 0.5)
	muzzle_light.light_energy = 0.0
	muzzle_light.light_volumetric_fog_energy = 2.5   # flashes punch the fog
	muzzle_light.omni_range = 6.0
	gun_tip.add_child(muzzle_light)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var s := sens * (0.55 if aiming else 1.0)
		rotate_y(-event.relative.x * s)
		pivot.rotation.x = clampf(pivot.rotation.x - event.relative.y * s,
								  -PITCH_MAX, -PITCH_MIN)


func reset_at(pos: Vector3) -> void:
	global_position = pos
	health = max_health
	plating = max_plating
	stamina = STAMINA_MAX
	ammo = mag_size
	reserve = int(int(wpn["reserve"]) * reserve_mult)
	heat = 0.0
	overheated = false
	grenades = int(GRENADES[grenade_key]["count"]) + grenade_bonus
	var other_def: Dictionary = SIDEARMS[side_key] if active_slot == 0 \
		else WEAPONS[weapon_key]
	slot_state[1 - active_slot] = {"ammo": other_def["mag"],
								   "reserve": int(int(other_def["reserve"]) * reserve_mult),
								   "heat": 0.0, "over": false, "vent": 0.0}
	stims = 3 + bonus_stims
	overtime_t = 0.0
	overtime_used = false        # a fresh spike, a fresh fallacy
	burst_t = 0.0
	emote_cd = 0.0
	stance = 0
	arm_hurt = false
	leg_hurt = false
	grime = 0.0                  # new recruit, factory paint
	alive = true
	invincible = 2.0
	visible = true
	arm.spring_length = 2.7
	pivot.rotation.x = deg_to_rad(-12.0)


func take_damage(amount: float, shrapnel: bool = false) -> void:
	if invincible > 0.0 or not alive or overtime_t > 0.0:
		return
	if shrapnel:
		amount *= explosive_mult   # Takeover chassis shrugs off the blast
	plating_delay = 3.5
	shake = maxf(shake, 2.0)
	grime = minf(1.0, grime + 0.05)   # every hit leaves a mark on the paint
	if plating > 0.0:
		var absorbed: float = minf(plating, amount)
		plating -= absorbed
		amount -= absorbed
	if amount > 0.0:
		health -= amount
		# Localized damage: heavy hits fracture limbs. Stims mend them.
		if amount >= 22.0 and health > 0.0 and randf() < 0.3:
			if randf() < 0.5 and not arm_hurt:
				arm_hurt = true
				main.hud.push_msg("ARM FRACTURE — AIM COMPROMISED",
								  Color(1.0, 0.45, 0.3))
			elif not leg_hurt:
				leg_hurt = true
				main.hud.push_msg("LEG FRACTURE — SPRINT DISABLED",
								  Color(1.0, 0.45, 0.3))
		if health <= 0.0:
			if synergy == "TAKEOVER" and not overtime_used:
				# Sunk Cost Fallacy: refuse the outcome for six more seconds
				overtime_used = true
				overtime_t = 6.0
				health = 1.0
				main.sfx("stim")
				main.hud.push_msg("SUNK COST FALLACY — OVERTIME",
								  Color(1.0, 0.3, 0.2))
				return
			if has_clause and randf() < 0.5:
				# Act of God Clause: the Underwriter's policy pays out
				health = 1.0
				invincible = maxf(invincible, 1.0)
				main.sfx("stim")
				main.hud.push_msg("ACT OF GOD CLAUSE — CLAIM APPROVED (1 HP)",
								  Color(0.3, 1.0, 0.8))
				return
			health = 0.0
			alive = false
			visible = false
			main.on_player_died()


func add_shake(f: float) -> void:
	shake = maxf(shake, f)


func aim_point() -> Vector3:
	var from := cam.global_position
	var dir := -cam.global_transform.basis.z
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * 300.0)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit:
		return hit.position
	return from + dir * 300.0


func _physics_process(delta: float) -> void:
	fire_timer = maxf(0.0, fire_timer - delta)
	recoil = maxf(0.0, recoil - 34.0 * delta)
	invincible = maxf(0.0, invincible - delta)
	dive_cd = maxf(0.0, dive_cd - delta)
	dive_timer = maxf(0.0, dive_timer - delta)
	plating_delay = maxf(0.0, plating_delay - delta)
	shake = maxf(0.0, shake - 6.0 * delta)
	emote_cd = maxf(0.0, emote_cd - delta)
	burst_t = maxf(0.0, burst_t - delta)

	# Camera shake
	if cam != null:
		cam.h_offset = randf_range(-shake, shake) * 0.02
		cam.v_offset = randf_range(-shake, shake) * 0.02

	if not alive or main.state != "playing":
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		if not alive:
			# death cam: pull back and look down at the field
			arm.spring_length = lerpf(arm.spring_length, 8.0, 2.0 * delta)
			pivot.rotation.x = lerpf(pivot.rotation.x, deg_to_rad(-38.0), 2.0 * delta)
		return

	# Overtime: immune, unlimited, doubled — then the bill arrives
	if overtime_t > 0.0:
		overtime_t -= delta
		if overtime_t <= 0.0:
			main.explode(global_position, 9.0, 650.0, false)
			health = 0.0
			alive = false
			visible = false
			main.on_player_died()
			return

	# The emote wheel (G): pure personality — unless you're a full HR
	# Specialist, in which case it's a weapon (Deflection of Blame)
	if Input.is_action_just_pressed("emote") and emote_cd <= 0.0 and not mounted:
		if synergy == "HR":
			var best: Node3D = null
			var best_d := 15.0
			for a in get_tree().get_nodes_in_group("allies"):
				var d: float = a.global_position.distance_to(global_position)
				if d < best_d:
					best_d = d
					best = a
			if best != null:
				emote_cd = 25.0
				burst_t = 3.0
				main.taunt(best, 6.0)
				main.sfx("click", -4.0)
				main.hud.push_msg("DEFLECTION OF BLAME — %s OWNS THIS" % best.callsign,
								  Color(0.3, 0.8, 1.0))
			else:
				main.hud.push_msg("NO COWORKER WITHIN 15 m", Color(1.0, 0.6, 0.2))
		else:
			emote_cd = 5.0
			main.bark("emote")

	# The field kit: F throws whatever the company issued you
	if Input.is_action_just_pressed("grenade") and grenades > 0 and not mounted \
			and (main.strats == null or main.strats.armed == ""):
		_throw_grenade()

	# The suit keeps the mission's diary: caking slowly with the biome,
	# faster when you're bogged, prone, or getting hit
	grime = minf(1.0, grime + delta / 600.0
				 + (delta / 40.0 if bogged or stance == 2 else 0.0))
	if armor_mat != null:
		var gcol := Color(0.84, 0.89, 0.94)      # frost caking (tundra default)
		if main.biome == "ash":
			gcol = Color(0.10, 0.095, 0.09)      # soot
		elif main.biome == "swamp":
			gcol = Color(0.16, 0.22, 0.14)       # bog mud and spores
		armor_mat.albedo_color = base_paint.lerp(gcol, grime * 0.55)
		armor_mat.roughness = lerpf(0.5, 0.95, grime)

	# Recon Weave radar (or a calibrated radar tower): 3-second hostile pings
	if radar or main.radar_boost_t > 0.0:
		radar_t -= delta
		if radar_t <= 0.0:
			radar_t = 3.0
			radar_pings.clear()
			for e in get_tree().get_nodes_in_group("enemies"):
				if e.global_position.distance_to(global_position) < 70.0:
					radar_pings.append(e.global_position)

	# Heat-sink weapons (Flux Caster, Synergy-6)
	if wpn["heat"]:
		if overheated:
			vent_timer -= delta
			if vent_timer <= 0.0:
				overheated = false
				heat = 0.0
		else:
			heat = maxf(0.0, heat - 30.0 * delta)
			if Input.is_action_just_pressed("reload") and heat > 5.0:
				overheated = true          # voluntary early vent
				vent_timer = 1.2
				main.sfx("stim", -16.0)

	# ADS: shoulder in tight, glass up (never while riding)
	aiming = Input.is_action_pressed("aim") and not mounted
	var arm_target := 1.5 if aiming else (4.4 if mounted else 2.7)
	arm.spring_length = lerpf(arm.spring_length, arm_target, 10.0 * delta)

	if plating_delay <= 0.0 and plating < max_plating:
		plating = minf(max_plating, plating + 10.0 * delta)

	# Chem-stim: hiss, then health floods back — and the bones knit
	if Input.is_action_just_pressed("stim") and stims > 0 \
			and (health < max_health or arm_hurt or leg_hurt):
		stims -= 1
		stim_heal = 45.0
		health = minf(max_health, health + 15.0)
		if arm_hurt or leg_hurt:
			arm_hurt = false
			leg_hurt = false
			main.hud.push_msg("FRACTURES SET", Color(0.55, 1.0, 0.6))
		main.sfx("stim")
	if stim_heal > 0.0:
		var tick_heal: float = minf(stim_heal, 18.0 * delta)
		stim_heal -= tick_heal
		health = minf(max_health, health + tick_heal)

	if reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			reloading = false
			var fresh: int = mini(mag_size, reserve)
			reserve -= fresh
			ammo = fresh   # rounds left in the old clip are gone

	# ---- stance: stand / crouch / prone ----
	if Input.is_action_just_pressed("crouch") and not mounted:
		stance = 1 if stance != 1 else 0
	if Input.is_action_just_pressed("prone") and not mounted:
		stance = 2 if stance != 2 else 0
	if mounted:
		stance = 0

	# ---- movement: weight & momentum ----
	var iv := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if main.psi_t > 0.0:
		iv = -iv                      # psionic inversion: left is a lie
	var wish := (transform.basis * Vector3(iv.x, 0, iv.y))
	wish.y = 0
	wish = wish.normalized() if wish.length() > 0.01 else Vector3.ZERO

	# Sprinting pulls you up onto your feet — and needs two working legs
	if Input.is_action_pressed("sprint") and stance != 0 and not leg_hurt \
			and wish != Vector3.ZERO:
		stance = 0
	sprinting = Input.is_action_pressed("sprint") and stamina > 1.0 \
		and wish != Vector3.ZERO and not aiming and not mounted \
		and not leg_hurt and stance == 0
	var speed: float = WALK_SPEED * speed_mult \
		* ((SPRINT_MULT * sprint_mult) if sprinting else 1.0) \
		* (0.55 if aiming else 1.0) * STANCE_SPEED[stance]
	if leg_hurt:
		speed *= 0.8                  # a fractured leg keeps the receipts
	bogged = not mounted and main.in_mire(global_position)
	if bogged:
		speed *= 0.55                 # deep drift: wading, not walking
	if main.tremor_t > 0.0:
		speed *= 0.6                  # the ground is busy right now
		shake = maxf(shake, 2.5)
	if burst_t > 0.0:
		speed *= 1.6                  # blame deflected: run
	if overtime_t > 0.0:
		speed *= 2.0
	if mounted:
		speed = 24.0                  # the skimmer doesn't care about stamina
	if sprinting:
		var drain := 20.0 * stam_mult
		if main.planet.get("cold", false):
			drain *= 1.25             # extreme cold: the body pays extra
		stamina = maxf(0.0, stamina - drain * delta)
	else:
		stamina = minf(STAMINA_MAX, stamina + 16.0 * stam_regen_mult * delta)

	# Body-cam feel: head-bob scaled by ground speed, FOV widens at a sprint,
	# and the camera rides the stance down to snow level
	var ground_speed := Vector2(velocity.x, velocity.z).length()
	bob_t += delta * ground_speed * 1.5
	var head_h: float = STANCE_HEIGHT[stance] \
		+ sin(bob_t) * clampf(ground_speed / 10.0, 0.0, 1.0) * 0.05
	pivot.position.y = lerpf(pivot.position.y, head_h, 10.0 * delta)
	var fov_target := 50.0 if aiming else (78.0 if sprinting else 72.0)
	cam.fov = lerpf(cam.fov, fov_target, 7.0 * delta)

	# Legs swing while moving; the torso leans into a sprint, folds into a
	# crouch, and goes flat when prone
	var swing := clampf(ground_speed / 6.0, 0.0, 1.2)
	hip_l.rotation.x = sin(bob_t) * 0.55 * swing
	hip_r.rotation.x = -sin(bob_t) * 0.55 * swing
	var lean := -0.12 if sprinting else 0.0
	if stance == 2:
		lean = -1.42                  # face DOWN in the drift, not sunbathing
	body_root.rotation.x = lerpf(body_root.rotation.x, lean, 8.0 * delta)
	var squat := 0.72 if stance == 1 else 1.0
	body_root.scale.y = lerpf(body_root.scale.y, squat, 10.0 * delta)

	var accel := SPRINT_ACCEL if sprinting else ACCEL
	if mounted:
		accel = 7.0                   # hover physics: fast but drifty
	if dive_timer > 0.0:
		pass   # committed to the dive: no steering mid-air
	else:
		velocity.x = move_toward(velocity.x, wish.x * speed, accel * delta)
		velocity.z = move_toward(velocity.z, wish.z * speed, accel * delta)

	if Input.is_action_just_pressed("dive") and dive_cd <= 0.0 and not mounted:
		var dir := wish if wish != Vector3.ZERO else -transform.basis.z
		velocity.x = dir.x * 14.0
		velocity.z = dir.z * 14.0
		dive_timer = 0.32
		dive_cd = 1.6
		invincible = maxf(invincible, 0.4)
		stance = 2                    # a combat dive ends face-down. Always.

	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()

	# ---- weapon ----
	# Holster and draw: [1] the primary instrument, [2] the sidearm
	if Input.is_action_just_pressed("slot1"):
		_switch_slot(0)
	if Input.is_action_just_pressed("slot2"):
		_switch_slot(1)

	if not wpn["heat"] and Input.is_action_just_pressed("reload") \
			and not reloading and ammo < mag_size and reserve > 0:
		reloading = true
		reload_total = wpn.get("reload", 1.7)
		reload_timer = reload_total

	# Suppress the trigger while a stratagem flare is in hand
	var strat_armed: bool = main.strats != null and main.strats.armed != ""
	var can_fire: bool
	if wpn["heat"]:
		can_fire = not overheated
	else:
		can_fire = not reloading and ammo > 0
	if Input.is_action_pressed("fire") and fire_timer <= 0.0 \
			and can_fire and not strat_armed and not mounted:
		_fire()


func _throw_grenade() -> void:
	grenades -= 1
	main.sfx("click", -8.0)
	var gd: Dictionary = GRENADES[grenade_key]
	var g := RigidBody3D.new()
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.09
	cs.shape = sph
	g.add_child(cs)
	var m := MeshInstance3D.new()
	var ms := SphereMesh.new()
	ms.radius = 0.09
	ms.height = 0.18
	m.mesh = ms
	var mat := StandardMaterial3D.new()
	mat.albedo_color = gd["color"]
	mat.emission_enabled = true
	mat.emission = gd["color"]
	mat.emission_energy_multiplier = 2.0
	m.material_override = mat
	g.add_child(m)
	main.add_child(g)
	g.global_position = gun_tip.global_position
	var dir := (aim_point() - g.global_position).normalized()
	g.linear_velocity = dir * 15.0 + Vector3(0, 4.5, 0)
	# 2 seconds on the fuse, then the payload speaks for itself
	get_tree().create_timer(2.0).timeout.connect(func() -> void:
		if not is_instance_valid(g):
			return
		var pos: Vector3 = g.global_position
		g.queue_free()
		if gd.get("smoke", false):
			main.spawn_smoke(pos)
			main.sfx("stim", -14.0)
		else:
			main.explode(pos, gd["radius"], gd["dmg"]))


func _fire() -> void:
	fire_timer = wpn["rate"]
	var free_fire := overtime_t > 0.0   # Overtime: the company covers the ammo
	if wpn["heat"]:
		if not free_fire:
			var hs: float = wpn.get("heat_shot", 8.0)
			if main.planet.get("cold", false):
				hs *= 0.67            # extreme cold: the sink runs 50% cooler
			heat += hs
			if heat >= 100.0:
				heat = 100.0
				overheated = true       # the cell melts: 3 seconds of regret
				vent_timer = 3.0
				main.sfx("boom", -18.0)
	elif not free_fire:
		ammo -= 1
		if ammo <= 0 and reserve > 0:
			reloading = true
			reload_total = wpn.get("reload", 1.7)
			reload_timer = reload_total
	var kick: float = wpn["kick"] * STANCE_KICK[stance]
	if aiming or stance > 0:
		kick *= braced_recoil_mult      # Takeover visor: a braced stock
	recoil = minf(24.0, recoil + kick)
	pivot.rotation.x = clampf(pivot.rotation.x + kick * 0.0015,
							  -PITCH_MAX, -PITCH_MIN)

	var target := aim_point()
	var origin := gun_tip.global_position
	var base_dir := (target - origin).normalized()
	# aim discipline: weapon spread + recoil + stance; ADS tightens it all,
	# bracing tightens it more, a fractured arm ruins it
	var sway: float = wpn["spread"] + recoil * 0.0012 \
		+ (0.02 if sprinting else 0.0)
	sway *= STANCE_SWAY[stance]
	if aiming:
		sway *= 0.35
	if arm_hurt:
		sway *= 1.8
	for i in range(wpn["pellets"]):
		var dir := base_dir.rotated(Vector3.UP, randf_range(-sway, sway))
		var side := dir.cross(Vector3.UP)
		if side.length() > 0.01:
			dir = dir.rotated(side.normalized(), randf_range(-sway, sway))
		var bolt := ProjectileScript.new()
		bolt.velocity = dir * wpn["speed"]
		bolt.damage = wpn["damage"]
		bolt.chill = wpn["chill"]
		bolt.aoe = wpn.get("aoe", 0.0)
		bolt.gravity = wpn.get("gravity", 0.0)
		bolt.dot_dps = wpn.get("dot_dps", 0.0)
		bolt.dot_dur = wpn.get("dot_dur", 0.0)
		bolt.thickness = wpn.get("thick", 0.02)
		bolt.pen = wpn.get("pen", 2)
		bolt.shooter = self
		bolt.main = main
		if wpn.has("color"):
			bolt.color = wpn["color"]
		main.add_child(bolt)
		bolt.global_position = origin
	main.sfx("shoot", -12.0)

	muzzle_light.light_energy = 3.0
	var t := get_tree().create_tween()
	t.tween_property(muzzle_light, "light_energy", 0.0, 0.08)
