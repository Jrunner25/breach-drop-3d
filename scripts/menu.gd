# The Void Anchor launch bay: three terminal tabs on the command deck —
# WARBOARD (pick the war), ARMORY (pick the guns), REQUISITION (pick the
# suit) — then a tactical drop map to establish landing coordinates.
extends Node3D

signal deploy_requested(cfg: Dictionary)

const TrooperModel = preload("res://scripts/trooper_model.gd")
const PlayerScript = preload("res://scripts/player.gd")
const WEAPON_KEYS := ["RIFLE", "CRYO_SHOTGUN", "DMR", "FLUX_CASTER",
					  "DOWNSIZER", "REDUNDANCY", "SYNERGY_6", "AUDIT_GAS"]
const SIDEARM_KEYS := ["EVICTION", "MICRO_MANAGER", "SEVERANCE"]

const AMBER := Color(1.0, 0.72, 0.2)
const BLUE := Color(0.45, 0.8, 1.0)
const WARN := Color(1.0, 0.35, 0.25)
const GREEN := Color(0.4, 1.0, 0.55)

# Body Chassis: the weight class IS the set's body piece. Real trade-offs.
const RIGS := [
	{"name": "RECON WEAVE", "set": "HR", "weight": "LIGHT",
	 "hp": 0.85, "speed": 1.12, "stam": 0.8, "plating": 0.0,
	 "sprint": 1.2, "radar": true,
	 "desc": "Zero plating. +20% sprint; a tactical radar pings every hostile within 70 m each 3 s. The HR Specialist body."},
	{"name": "COURIER FRAME", "set": "HR", "weight": "LIGHT",
	 "hp": 0.8, "speed": 1.18, "stam": 0.7, "plating": 12.0,
	 "sprint": 1.3,
	 "desc": "Faster still: +30% sprint and a whisper of plating, but no radar and lungs on a budget. The HR courier body."},
	{"name": "CONTRACTOR PLATE", "set": "TECH", "weight": "MEDIUM",
	 "hp": 1.0, "speed": 1.0, "stam": 1.0, "plating": 40.0,
	 "stims": 2, "throw": 1.3,
	 "desc": "The corporate balance. +2 chem-stim capacity, +30% beacon throw range. The Tech Evangelist body."},
	{"name": "AUDITOR EXO", "set": "TECH", "weight": "MEDIUM",
	 "hp": 1.05, "speed": 0.95, "stam": 1.1, "plating": 45.0,
	 "stims": 1, "throw": 1.5, "grenades": 1,
	 "desc": "The field accountant: +50% beacon throw, +1 grenade, +1 stim. Slightly slower — the ledger is heavy."},
	{"name": "SIEGE CARAPACE", "set": "TAKEOVER", "weight": "HEAVY",
	 "hp": 1.35, "speed": 0.7, "stam": 1.5, "plating": 55.0,
	 "explosive": 0.5,
	 "desc": "-30% speed, -50% explosive damage, deep plating. Built to survive your own orbital math. The Hostile Takeover body."},
	{"name": "BULWARK FRAME", "set": "TAKEOVER", "weight": "HEAVY",
	 "hp": 1.5, "speed": 0.62, "stam": 1.7, "plating": 70.0,
	 "explosive": 0.6,
	 "desc": "A walking fire door: massive health and plating, -40% explosive damage — and the speed of a filing cabinet."},
	{"name": "UNDERWRITER MK-II", "set": "", "weight": "MEDIUM",
	 "hp": 1.0, "speed": 1.0, "stam": 1.0, "plating": 40.0,
	 "clause": true,
	 "desc": "ACT OF GOD CLAUSE — 50% chance to survive lethal damage at 1 HP. Answers to no set: no synergy possible."},
]
const SET_NAMES := {"HR": "THE HR SPECIALIST", "TECH": "THE TECH EVANGELIST",
					"TAKEOVER": "THE HOSTILE TAKEOVER", "": "NO AFFILIATION"}

# The field kit, boosters, and the disposable identity
const GRENADE_KEYS := ["PINK_SLIP", "NDA", "RESTRUCTURING"]
const GRENADE_LABELS := ["PINK SLIP", "NDA CANISTER", "RESTRUCTURING"]
const BOOSTERS := [
	{"name": "EXPENSE ACCOUNT", "desc": "+50% reserve ammunition, both guns."},
	{"name": "SATELLITE UPLINK", "desc": "Tactical radar pings on any chassis."},
	{"name": "GYM MEMBERSHIP", "desc": "Stamina drains 20% slower, recovers 25% faster."},
	{"name": "OVERTIME AUTHORIZATION", "desc": "+2:00 on the mission window."},
]
const VOICES := ["RANDOMIZED", "PANICKED", "MANIACAL", "CORPORATE"]
const POSES := ["CRISP SALUTE", "DOUBLE FLEX", "PAPERWORK SLAM", "T-POSE OF POWER"]

# Rebindable actions for the CONTROLS terminal (saved to keybinds.cfg)
const BIND_ACTIONS := [
	["move_forward", "MOVE FORWARD"], ["move_back", "MOVE BACK"],
	["move_left", "MOVE LEFT"], ["move_right", "MOVE RIGHT"],
	["sprint", "SPRINT"], ["crouch", "CROUCH"], ["prone", "PRONE"],
	["dive", "COMBAT DIVE"], ["reload", "RELOAD"], ["stim", "CHEM-STIM"],
	["grenade", "GRENADE"], ["interact", "INTERACT / MOUNT"],
	["emote", "EMOTE / DEFLECT"], ["slot1", "PRIMARY WEAPON"],
	["slot2", "SIDEARM"], ["strat_open", "STRATAGEM MATRIX (HOLD)"],
]

# Asset Suit pieces: visor and ID tag. Match both to the chassis' set.
const SUIT_OPTS := ["", "HR", "TAKEOVER", "TECH"]
const SUIT_LABELS := ["STANDARD", "HR SPEC", "TAKEOVER", "TECH EVAN"]
const SUITS := {
	"HR": {"syn": "DEFLECTION OF BLAME — press G to redirect all aggro to the closest coworker within 15 m and sprint out of the meeting."},
	"TAKEOVER": {"syn": "SUNK COST FALLACY — lethal damage starts 6 s of OVERTIME: immune, infinite ammo, double speed. Then you detonate."},
	"TECH": {"syn": "SYNERGY CASCADE — every perfect first-try stratagem code cuts all active cooldowns by 5 s."},
}
const SUIT_PIECES := {
	"visor": {"HR": "-30% detection", "TAKEOVER": "-30% braced recoil",
			  "TECH": "+10% cooldown rate"},
	"tag": {"HR": "+30% stamina regen", "TAKEOVER": "+15 plating",
			"TECH": "+1 chem-stim"},
}

const PAINTS := [
	{"name": "CONTRACTOR BEIGE", "color": Color(0.62, 0.58, 0.52)},
	{"name": "ARCTIC STEEL", "color": Color(0.72, 0.78, 0.84)},
	{"name": "EMBER CORPS", "color": Color(0.52, 0.22, 0.13)},
	{"name": "VOID BLACK", "color": Color(0.14, 0.14, 0.17)},
]
const VISORS := [
	{"name": "AMBER", "color": Color(1.0, 0.7, 0.15)},
	{"name": "ICE", "color": Color(0.4, 0.85, 1.0)},
	{"name": "VIRIDIAN", "color": Color(0.35, 1.0, 0.6)},
	{"name": "THREAT RED", "color": Color(1.0, 0.25, 0.2)},
]

# Tactical drop map: pixels per metre inside a 120 m AO circle
const MAP_C := Vector2(800.0, 450.0)
const MAP_R_PX := 310.0
const AO_M := 120.0
const MAP_SCALE := MAP_R_PX / AO_M

var main: Node3D
var sel_planet := 0
var sel_op := 0
var sel_rig := 2              # Contractor Plate: the corporate default
var sel_paint := 0
var sel_visor := 0
var sel_weapon := 0
var sel_sidearm := 0
var sel_suit_v := 0
var sel_suit_t := 0
var sel_grenade := 0
var sel_booster := 0
var sel_voice := 0
var sel_pose := 0

var cam_pivot: Node3D
var planet: MeshInstance3D
var planet_mat: StandardMaterial3D
var scan_ring: MeshInstance3D
var marker: MeshInstance3D
var mann_root: Node3D
var mannequin_body: StandardMaterial3D
var mannequin_visor: StandardMaterial3D
var mann_rig_built := -1      # rebuild the display when the chassis changes
var mann_gun_built := -1      # ...and re-arm it when the primary changes
var mann_gun_root: Node3D

var cur_tab := 0
var tabs: Array = []          # [tab_war, tab_armory, tab_req]
var tab_buttons: Array = []
var planet_buttons: Array = []
var op_buttons: Array = []
var rig_buttons: Array = []
var paint_buttons: Array = []
var visor_buttons: Array = []
var weapon_buttons: Array = []
var sidearm_buttons: Array = []
var suit_v_buttons: Array = []
var suit_t_buttons: Array = []
var grenade_buttons: Array = []
var booster_buttons: Array = []
var voice_buttons: Array = []
var pose_buttons: Array = []
var booster_desc: Label
var order_label: Label
var war_map_ctl: Control
var mono_font: Font
var bind_buttons := {}        # action -> its key button on the CONTROLS tab
var listening_action := ""    # waiting for the next keypress to rebind
var op_desc: Label
var mods_label: Label
var chassis_desc: Label
var suit_desc: Label
var spec_primary: Label
var spec_side: Label
var title_screen: Control

# Drop coordinates state
var drop_layer: Control
var map_ctl: Control
var confirm_btn: Button
var drop_lz := Vector2.INF    # metres from the AO nexus
var drop_recon: Array = []    # objective signals (Vector2, metres)
var drop_vents: Array = []    # swarm vent signals (Vector2, metres)
var drop_blobs: Array = []    # cosmetic patrol activity [[Vector2, radius], ..]
var t := 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_load_loadout()
	_build_bridge()
	_build_ui()
	_refresh()


func _load_loadout() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://loadout.cfg") == OK:
		sel_planet = clampi(cfg.get_value("kit", "planet", 0), 0,
							main.PLANETS.size() - 1)
		if not main.planet_unlocked(sel_planet):
			sel_planet = 0   # the supply line closed while you were away
		sel_op = clampi(cfg.get_value("kit", "op", 0), 0, 2)
		sel_rig = clampi(cfg.get_value("kit", "rig", 2), 0, RIGS.size() - 1)
		sel_paint = clampi(cfg.get_value("kit", "paint", 0), 0, PAINTS.size() - 1)
		sel_visor = clampi(cfg.get_value("kit", "visor", 0), 0, VISORS.size() - 1)
		sel_weapon = clampi(cfg.get_value("kit", "weapon", 0), 0, WEAPON_KEYS.size() - 1)
		sel_sidearm = clampi(cfg.get_value("kit", "sidearm", 0), 0,
							 SIDEARM_KEYS.size() - 1)
		sel_suit_v = clampi(cfg.get_value("kit", "suit_v", 0), 0,
							SUIT_OPTS.size() - 1)
		sel_suit_t = clampi(cfg.get_value("kit", "suit_t", 0), 0,
							SUIT_OPTS.size() - 1)
		sel_grenade = clampi(cfg.get_value("kit", "grenade", 0), 0,
							 GRENADE_KEYS.size() - 1)
		sel_booster = clampi(cfg.get_value("kit", "booster", 0), 0,
							 BOOSTERS.size() - 1)
		sel_voice = clampi(cfg.get_value("kit", "voice", 0), 0, VOICES.size() - 1)
		sel_pose = clampi(cfg.get_value("kit", "pose", 0), 0, POSES.size() - 1)


func _save_loadout() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("kit", "planet", sel_planet)
	cfg.set_value("kit", "op", sel_op)
	cfg.set_value("kit", "rig", sel_rig)
	cfg.set_value("kit", "paint", sel_paint)
	cfg.set_value("kit", "visor", sel_visor)
	cfg.set_value("kit", "weapon", sel_weapon)
	cfg.set_value("kit", "sidearm", sel_sidearm)
	cfg.set_value("kit", "suit_v", sel_suit_v)
	cfg.set_value("kit", "suit_t", sel_suit_t)
	cfg.set_value("kit", "grenade", sel_grenade)
	cfg.set_value("kit", "booster", sel_booster)
	cfg.set_value("kit", "voice", sel_voice)
	cfg.set_value("kit", "pose", sel_pose)
	cfg.save("user://loadout.cfg")


# ------------------------------------------------------------- 3D backdrop

func _build_bridge() -> void:
	# A dark command deck: we sit inside a big shell and light it with holograms
	var room := MeshInstance3D.new()
	var shell := BoxMesh.new()
	shell.size = Vector3(26, 10, 26)
	room.mesh = shell
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(0.05, 0.06, 0.08)
	rm.roughness = 0.85
	rm.metallic = 0.4
	rm.cull_mode = BaseMaterial3D.CULL_FRONT   # see the inside of the box
	room.material_override = rm
	room.position = Vector3(0, 4, 0)
	add_child(room)

	# Holo-table pedestal
	var pedestal := MeshInstance3D.new()
	var ped := CylinderMesh.new()
	ped.top_radius = 1.4
	ped.bottom_radius = 1.7
	ped.height = 0.9
	pedestal.mesh = ped
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.10, 0.11, 0.14)
	pm.metallic = 0.7
	pm.roughness = 0.3
	pedestal.material_override = pm
	pedestal.position = Vector3(0, 0.45, 0)
	add_child(pedestal)

	var rim := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.35
	torus.outer_radius = 1.45
	rim.mesh = torus
	var rimm := StandardMaterial3D.new()
	rimm.emission_enabled = true
	rimm.emission = BLUE
	rimm.emission_energy_multiplier = 1.4
	rimm.albedo_color = Color(0.05, 0.1, 0.14)
	rim.material_override = rimm
	rim.position = Vector3(0, 0.92, 0)
	add_child(rim)

	# The planet below: an icy world rendered in hard light
	planet = MeshInstance3D.new()
	var ps := SphereMesh.new()
	ps.radius = 1.05
	ps.height = 2.1
	planet.mesh = ps
	var holo := StandardMaterial3D.new()
	var nt := NoiseTexture2D.new()
	var fn := FastNoiseLite.new()
	fn.frequency = 0.012
	fn.fractal_octaves = 4
	nt.noise = fn
	nt.seamless = true
	holo.albedo_texture = nt
	holo.albedo_color = Color(0.5, 0.75, 0.95, 0.85)
	holo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	holo.emission_enabled = true
	holo.emission = Color(0.25, 0.55, 0.8)
	holo.emission_energy_multiplier = 1.1
	holo.rim_enabled = true
	holo.rim = 1.0
	planet.material_override = holo
	planet.position = Vector3(0, 2.6, 0)
	add_child(planet)
	planet_mat = holo

	# A hard-light scan ring sweeping the projection
	scan_ring = MeshInstance3D.new()
	var srt := TorusMesh.new()
	srt.inner_radius = 1.18
	srt.outer_radius = 1.22
	scan_ring.mesh = srt
	var srm := StandardMaterial3D.new()
	srm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	srm.albedo_color = Color(0.5, 0.85, 1.0, 0.6)
	srm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	scan_ring.material_override = srm
	scan_ring.position = planet.position
	add_child(scan_ring)

	# Operation marker pinned to the planet
	marker = MeshInstance3D.new()
	var mc := CylinderMesh.new()
	mc.top_radius = 0.0
	mc.bottom_radius = 0.09
	mc.height = 0.3
	marker.mesh = mc
	var mm := StandardMaterial3D.new()
	mm.emission_enabled = true
	mm.emission = AMBER
	mm.emission_energy_multiplier = 2.0
	mm.albedo_color = AMBER
	marker.material_override = mm
	marker.rotation_degrees = Vector3(180, 0, 0)
	add_child(marker)

	# The armory mannequin showing your current rig
	var mq := Vector3(3.1, 0, -2.9)   # in frame beside the holo-table
	var stand := MeshInstance3D.new()
	var sc := CylinderMesh.new()
	sc.top_radius = 0.55
	sc.bottom_radius = 0.65
	sc.height = 0.25
	stand.mesh = sc
	stand.material_override = pm
	stand.position = mq + Vector3(0, 0.12, 0)
	add_child(stand)

	# The armory display: the full trooper model on a slowly turning stand
	mann_root = Node3D.new()
	mann_root.position = mq + Vector3(0, 0.25, 0)
	mann_root.rotation_degrees = Vector3(0, 155, 0)
	add_child(mann_root)
	var parts: Dictionary = TrooperModel.build(mann_root,
		PAINTS[sel_paint]["color"], VISORS[sel_visor]["color"])
	mannequin_body = parts["armor"]
	mannequin_visor = parts["visor"]
	var spot := SpotLight3D.new()
	spot.light_color = Color(0.9, 0.95, 1.0)
	spot.light_energy = 4.0
	spot.spot_range = 7.0
	spot.position = mq + Vector3(0, 4.0, 1.0)
	spot.rotation_degrees = Vector3(-72, 0, 0)
	add_child(spot)

	# Cold fill lights
	for offset in [Vector3(-6, 3, 6), Vector3(6, 3, 6)]:
		var l := OmniLight3D.new()
		l.light_color = Color(0.35, 0.55, 0.8)
		l.light_energy = 1.6
		l.omni_range = 14.0
		l.position = offset
		add_child(l)

	# Slow-orbit camera around the table
	cam_pivot = Node3D.new()
	cam_pivot.position = Vector3(0, 2.2, 0)
	add_child(cam_pivot)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.0, 6.4)
	cam.rotation_degrees = Vector3(-10, 0, 0)
	cam.fov = 55.0
	cam_pivot.add_child(cam)
	cam.current = true


func _process(delta: float) -> void:
	t += delta
	cam_pivot.rotation.y = sin(t * 0.08) * 0.55 - 0.35
	planet.rotate_y(delta * 0.25)
	# holographic instability: flicker + a scan ring sweeping the globe
	planet_mat.emission_energy_multiplier = 1.1 + sin(t * 7.0) * 0.1 \
		+ (0.25 if fmod(t, 2.7) < 0.06 else 0.0)
	scan_ring.position.y = planet.position.y + sin(t * 0.8) * 0.85
	var ring_r := sqrt(maxf(0.05, 1.0 - pow(sin(t * 0.8) * 0.81, 2.0)))
	scan_ring.scale = Vector3(ring_r, 1.0, ring_r)
	# the armory display turns slowly under its spotlight
	mann_root.rotate_y(delta * 0.4)
	# marker rides the planet surface and pulses
	var ang := t * 0.25 + sel_op * 2.1
	marker.position = planet.position + Vector3(cos(ang) * 1.12, 0.35, sin(ang) * 1.12)
	var s := 1.0 + sin(t * 5.0) * 0.15
	marker.scale = Vector3(s, s, s)


# ------------------------------------------------------------- UI helpers

func _mk_label(parent: Control, text: String, pos: Vector2, size_px: int,
			   color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


func _mk_button(parent: Control, text: String, pos: Vector2, w: float,
				cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(w, 34)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.14, 0.9)
	sb.border_color = Color(0.25, 0.4, 0.5)
	sb.set_border_width_all(1)
	b.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate()
	sbh.bg_color = Color(0.14, 0.20, 0.28, 0.95)
	b.add_theme_stylebox_override("hover", sbh)
	b.add_theme_stylebox_override("pressed", sbh)
	b.pressed.connect(cb)
	b.pressed.connect(func() -> void: main.sfx("click", -10.0))
	parent.add_child(b)
	return b


func _mk_panel(parent: Control, pos: Vector2, size: Vector2) -> void:
	var p := ColorRect.new()
	p.color = Color(0.03, 0.05, 0.08, 0.75)
	p.position = pos
	p.size = size
	parent.add_child(p)


func _mk_tab() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


# ------------------------------------------------------------- UI build

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var ui := Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	# deck terminals render in fixed-width: clean, technical, corporate
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["Cascadia Mono", "Consolas",
									   "Lucida Console", "Courier New"])
	var th := Theme.new()
	th.default_font = sf
	ui.theme = th
	mono_font = sf
	canvas.add_child(ui)

	_mk_label(ui, "BREACH-DROP", Vector2(40, 24), 44, AMBER)
	_mk_label(ui, "VOID ANCHOR — LAUNCH BAY", Vector2(42, 74), 16, BLUE)

	# The deck terminals: four tabs, one job each
	var tab_names := ["1·WARBOARD", "2·ARMORY", "3·REQUISITION", "4·CONTROLS"]
	for i in range(4):
		var idx := i
		var b := _mk_button(ui, tab_names[i], Vector2(520 + i * 180, 44), 170,
							func() -> void: _set_tab(idx))
		b.add_theme_font_size_override("font_size", 13)
		tab_buttons.append(b)

	var tab_war := _mk_tab()
	var tab_arm := _mk_tab()
	var tab_req := _mk_tab()
	var tab_ctl := _mk_tab()
	for tab in [tab_war, tab_arm, tab_req, tab_ctl]:
		ui.add_child(tab)
	tabs = [tab_war, tab_arm, tab_req, tab_ctl]

	# ---------------- TAB 1: THE WARBOARD ----------------
	_mk_panel(tab_war, Vector2(40, 120), Vector2(440, 620))
	_mk_label(tab_war, "SELECT WARFRONT", Vector2(56, 132), 18, BLUE)
	for i in range(main.PLANETS.size()):
		var idx := i
		var b := _mk_button(tab_war, main.PLANETS[i]["name"],
							Vector2(56 + i * 136, 164), 128,
							func() -> void:
								if not main.planet_unlocked(idx):
									main.sfx("boom", -18.0)
									mods_label.text = "SUPPLY LINE SEVERED — combined liberation %d/80 required to open MERIDIAN VERGE." % int(main.total_liberation())
									return
								sel_planet = idx
								sel_op = 0
								_refresh())
		b.add_theme_font_size_override("font_size", 11)
		planet_buttons.append(b)
	_mk_label(tab_war, "SELECT OPERATION", Vector2(56, 214), 18, BLUE)
	for i in range(3):
		var idx := i
		var b := _mk_button(tab_war, "", Vector2(56, 248 + i * 44), 408,
							func() -> void:
								sel_op = idx
								_refresh())
		op_buttons.append(b)
	_mk_label(tab_war, "PLANETARY MODIFIERS", Vector2(56, 396), 18, BLUE)
	mods_label = _mk_label(tab_war, "", Vector2(56, 428), 13,
						   Color(1.0, 0.75, 0.4))
	mods_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mods_label.custom_minimum_size = Vector2(408, 0)
	mods_label.size = Vector2(408, 64)
	op_desc = _mk_label(tab_war, "", Vector2(56, 506), 13, Color(0.7, 0.74, 0.8))
	op_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	op_desc.custom_minimum_size = Vector2(408, 0)
	op_desc.size = Vector2(408, 190)
	_mk_label(tab_war,
			  "The Holo-Glove does not pause the fight. Neither does anything else.",
			  Vector2(56, 712), 12, Color(0.9, 0.35, 0.3))

	# Right: the sector map (supply lines) and the standing Major Order
	_mk_panel(tab_war, Vector2(1100, 120), Vector2(460, 310))
	_mk_label(tab_war, "SECTOR MAP — SUPPLY LINES", Vector2(1116, 132), 18, BLUE)
	war_map_ctl = Control.new()
	war_map_ctl.set_anchors_preset(Control.PRESET_FULL_RECT)
	war_map_ctl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	war_map_ctl.draw.connect(_draw_sector_map)
	tab_war.add_child(war_map_ctl)
	_mk_panel(tab_war, Vector2(1100, 450), Vector2(460, 230))
	_mk_label(tab_war, "MAJOR ORDER — THE DIRECTORATE", Vector2(1116, 462), 18,
			  Color(1.0, 0.72, 0.2))
	order_label = _mk_label(tab_war, "", Vector2(1116, 496), 13,
							Color(0.8, 0.84, 0.88))
	order_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	order_label.custom_minimum_size = Vector2(428, 0)
	order_label.size = Vector2(428, 170)

	# ---------------- TAB 2: THE ARMORY ----------------
	_mk_panel(tab_arm, Vector2(40, 120), Vector2(460, 680))
	_mk_label(tab_arm, "PRIMARY INSTRUMENTS", Vector2(56, 132), 18, BLUE)
	for i in range(WEAPON_KEYS.size()):
		var idx := i
		var wname: String = PlayerScript.WEAPONS[WEAPON_KEYS[i]]["name"]
		var b := _mk_button(tab_arm, wname, Vector2(56, 166 + i * 40), 428,
							func() -> void:
								sel_weapon = idx
								_refresh())
		weapon_buttons.append(b)
	_mk_label(tab_arm, "SIDEARMS", Vector2(56, 506), 18, BLUE)
	for i in range(SIDEARM_KEYS.size()):
		var idx := i
		var sname: String = PlayerScript.SIDEARMS[SIDEARM_KEYS[i]]["name"]
		var b := _mk_button(tab_arm, sname, Vector2(56, 540 + i * 40), 428,
							func() -> void:
								sel_sidearm = idx
								_refresh())
		sidearm_buttons.append(b)
	_mk_label(tab_arm, "FIELD KIT — GRENADE [F]", Vector2(56, 668), 18, BLUE)
	for i in range(GRENADE_KEYS.size()):
		var idx := i
		var b := _mk_button(tab_arm, GRENADE_LABELS[i],
							Vector2(56 + i * 146, 700), 138,
							func() -> void:
								sel_grenade = idx
								_refresh())
		b.add_theme_font_size_override("font_size", 12)
		grenade_buttons.append(b)
	_mk_panel(tab_arm, Vector2(1100, 120), Vector2(460, 680))
	_mk_label(tab_arm, "SPEC SHEET — PRIMARY", Vector2(1116, 132), 18, BLUE)
	spec_primary = _mk_label(tab_arm, "", Vector2(1116, 164), 13,
							 Color(0.8, 0.84, 0.88))
	spec_primary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	spec_primary.custom_minimum_size = Vector2(428, 0)
	spec_primary.size = Vector2(428, 210)
	_mk_label(tab_arm, "SPEC SHEET — SIDEARM", Vector2(1116, 392), 18, BLUE)
	spec_side = _mk_label(tab_arm, "", Vector2(1116, 424), 13,
						  Color(0.8, 0.84, 0.88))
	spec_side.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	spec_side.custom_minimum_size = Vector2(428, 0)
	spec_side.size = Vector2(428, 200)
	_mk_label(tab_arm, "BOOSTER — ONE PASSIVE PER DROP", Vector2(1116, 636), 18,
			  BLUE)
	for i in range(BOOSTERS.size()):
		var idx := i
		var b := _mk_button(tab_arm, BOOSTERS[i]["name"],
							Vector2(1116 + (i % 2) * 220,
									668 + int(i / 2.0) * 40), 210,
							func() -> void:
								sel_booster = idx
								_refresh())
		b.add_theme_font_size_override("font_size", 11)
		booster_buttons.append(b)
	booster_desc = _mk_label(tab_arm, "", Vector2(1116, 752), 12,
							 Color(0.7, 0.74, 0.8))
	booster_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	booster_desc.custom_minimum_size = Vector2(428, 0)
	booster_desc.size = Vector2(428, 40)

	# ---------------- TAB 3: THE REQUISITION ----------------
	_mk_panel(tab_req, Vector2(40, 120), Vector2(580, 660))
	_mk_label(tab_req, "BODY CHASSIS — PICK YOUR WEIGHT CLASS",
			  Vector2(56, 132), 18, BLUE)
	for i in range(RIGS.size()):
		var idx := i
		var label: String = "%s   ·   %s   ·   %s" % [
			RIGS[i]["name"], RIGS[i]["weight"], SET_NAMES[RIGS[i]["set"]]]
		var b := _mk_button(tab_req, label, Vector2(56, 166 + i * 40), 548,
							func() -> void:
								sel_rig = idx
								_refresh())
		b.add_theme_font_size_override("font_size", 13)
		rig_buttons.append(b)
	chassis_desc = _mk_label(tab_req, "", Vector2(56, 448), 12,
							 Color(0.7, 0.74, 0.8))
	chassis_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chassis_desc.custom_minimum_size = Vector2(548, 0)
	chassis_desc.size = Vector2(548, 50)
	_mk_label(tab_req, "VISOR PIECE", Vector2(56, 508), 15, BLUE)
	for i in range(SUIT_OPTS.size()):
		var idx := i
		var b := _mk_button(tab_req, SUIT_LABELS[i],
							Vector2(56 + i * 138, 538), 130,
							func() -> void:
								sel_suit_v = idx
								_refresh())
		suit_v_buttons.append(b)
	_mk_label(tab_req, "ID TAG", Vector2(56, 584), 15, BLUE)
	for i in range(SUIT_OPTS.size()):
		var idx := i
		var b := _mk_button(tab_req, SUIT_LABELS[i],
							Vector2(56 + i * 138, 614), 130,
							func() -> void:
								sel_suit_t = idx
								_refresh())
		suit_t_buttons.append(b)
	_mk_label(tab_req, "UNIFORM STATUS", Vector2(56, 660), 15, BLUE)
	suit_desc = _mk_label(tab_req, "", Vector2(56, 686), 12,
						  Color(0.7, 0.74, 0.8))
	suit_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	suit_desc.custom_minimum_size = Vector2(548, 0)
	suit_desc.size = Vector2(548, 90)
	_mk_panel(tab_req, Vector2(1100, 120), Vector2(460, 680))
	_mk_label(tab_req, "PAINT SCHEME", Vector2(1116, 132), 18, BLUE)
	for i in range(PAINTS.size()):
		var idx := i
		var b := _mk_button(tab_req, PAINTS[i]["name"],
							Vector2(1116 + (i % 2) * 220, 166 + int(i / 2.0) * 44),
							210,
							func() -> void:
								sel_paint = idx
								_refresh())
		paint_buttons.append(b)
	_mk_label(tab_req, "VISOR GLASS", Vector2(1116, 268), 18, BLUE)
	for i in range(VISORS.size()):
		var idx := i
		var b := _mk_button(tab_req, VISORS[i]["name"],
							Vector2(1116 + (i % 2) * 220, 302 + int(i / 2.0) * 44),
							210,
							func() -> void:
								sel_visor = idx
								_refresh())
		visor_buttons.append(b)
	# The disposable identity: pick the voice, pick the pose, get recycled
	_mk_label(tab_req, "VOICE PACK — PER RECRUIT", Vector2(1116, 404), 18, BLUE)
	for i in range(VOICES.size()):
		var idx := i
		var b := _mk_button(tab_req, VOICES[i],
							Vector2(1116 + (i % 2) * 220, 438 + int(i / 2.0) * 44),
							210,
							func() -> void:
								sel_voice = idx
								_refresh())
		voice_buttons.append(b)
	_mk_label(tab_req, "VICTORY POSE", Vector2(1116, 540), 18, BLUE)
	for i in range(POSES.size()):
		var idx := i
		var b := _mk_button(tab_req, POSES[i],
							Vector2(1116 + (i % 2) * 220, 574 + int(i / 2.0) * 44),
							210,
							func() -> void:
								sel_pose = idx
								_refresh())
		pose_buttons.append(b)
	var id_note := _mk_label(tab_req,
			  "Every reinforcement is a brand-new recruit. The voice pack decides who screams out of the next pod.",
			  Vector2(1116, 672), 11, Color(0.55, 0.6, 0.66))
	id_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	id_note.custom_minimum_size = Vector2(428, 0)
	id_note.size = Vector2(428, 40)

	# ---------------- TAB 4: CONTROLS ----------------
	_mk_panel(tab_ctl, Vector2(40, 120), Vector2(520, 730))
	_mk_label(tab_ctl, "KEY BINDINGS — CLICK A KEY, THEN PRESS THE NEW ONE",
			  Vector2(56, 132), 16, BLUE)
	for i in range(BIND_ACTIONS.size()):
		var action: String = BIND_ACTIONS[i][0]
		_mk_label(tab_ctl, BIND_ACTIONS[i][1], Vector2(56, 176 + i * 38), 13,
				  Color(0.7, 0.74, 0.8))
		var b := _mk_button(tab_ctl, main.binding_key(action),
							Vector2(370, 168 + i * 38), 170,
							func() -> void: _start_listen(action))
		b.add_theme_font_size_override("font_size", 13)
		bind_buttons[action] = b
	var reset := _mk_button(tab_ctl, "RESET TO DEFAULTS", Vector2(56, 788), 220,
							func() -> void:
								listening_action = ""
								main.clear_bindings()
								_refresh_bindings())
	reset.add_theme_font_size_override("font_size", 13)
	_mk_label(tab_ctl, "Mouse is fixed: LMB fire, RMB aim. Stratagem codes\nalways use the arrow keys. ESC cancels a rebind.",
			  Vector2(300, 792), 11, Color(0.55, 0.6, 0.66))

	# Launch — opens the tactical drop map, never fires blind
	var launch := _mk_button(ui, ">>  ESTABLISH DROP COORDINATES  <<",
							 Vector2.ZERO, 440,
							 func() -> void: _open_drop_map())
	launch.add_theme_font_size_override("font_size", 20)
	launch.add_theme_color_override("font_color", AMBER)
	launch.anchor_left = 0.5
	launch.anchor_right = 0.5
	launch.anchor_top = 1.0
	launch.anchor_bottom = 1.0
	launch.offset_left = -220
	launch.offset_right = 220
	launch.offset_top = -92
	launch.offset_bottom = -40

	_build_drop_map(ui)
	_set_tab(0)

	# ---- Title screen: sits on top of the bay until START is pressed ----
	title_screen = Control.new()
	title_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_screen.theme = th
	canvas.add_child(title_screen)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.02, 0.04, 0.88)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_screen.add_child(shade)

	var big := Label.new()
	big.text = "BREACH-DROP"
	big.add_theme_font_size_override("font_size", 110)
	big.add_theme_color_override("font_color", AMBER)
	big.set_anchors_preset(Control.PRESET_CENTER)
	big.position = Vector2(-390, -190)
	title_screen.add_child(big)
	var sub := Label.new()
	sub.text = "NULL ZONE CONTRACT OPERATIONS  ·  SILICON SWARM SUPPRESSION"
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", BLUE)
	sub.set_anchors_preset(Control.PRESET_CENTER)
	sub.position = Vector2(-330, -60)
	title_screen.add_child(sub)

	var start := Button.new()
	start.text = "START"
	start.add_theme_font_size_override("font_size", 34)
	start.add_theme_color_override("font_color", AMBER)
	var sbs := StyleBoxFlat.new()
	sbs.bg_color = Color(0.08, 0.10, 0.14, 0.95)
	sbs.border_color = AMBER
	sbs.set_border_width_all(2)
	sbs.set_content_margin_all(14)
	start.add_theme_stylebox_override("normal", sbs)
	var sbh2 := sbs.duplicate()
	sbh2.bg_color = Color(0.2, 0.16, 0.06, 0.95)
	start.add_theme_stylebox_override("hover", sbh2)
	start.add_theme_stylebox_override("pressed", sbh2)
	start.set_anchors_preset(Control.PRESET_CENTER)
	start.position = Vector2(-90, 20)
	start.size = Vector2(180, 70)
	start.pressed.connect(func() -> void: title_screen.queue_free())
	title_screen.add_child(start)

	var quit := Button.new()
	quit.text = "QUIT"
	quit.add_theme_font_size_override("font_size", 18)
	quit.set_anchors_preset(Control.PRESET_CENTER)
	quit.position = Vector2(-45, 120)
	quit.size = Vector2(90, 40)
	quit.pressed.connect(func() -> void: get_tree().quit())
	title_screen.add_child(quit)


func _set_tab(i: int) -> void:
	cur_tab = i
	listening_action = ""
	_refresh_bindings()
	for j in range(tabs.size()):
		tabs[j].visible = (j == i)
		tab_buttons[j].modulate = AMBER if j == i else Color.WHITE


func _start_listen(action: String) -> void:
	if listening_action != "":
		bind_buttons[listening_action].text = main.binding_key(listening_action)
	listening_action = action
	bind_buttons[action].text = "PRESS A KEY..."


func _refresh_bindings() -> void:
	for action in bind_buttons:
		bind_buttons[action].text = main.binding_key(action)


func _unhandled_key_input(event: InputEvent) -> void:
	# The CONTROLS terminal is listening for the next keypress
	if listening_action == "" or not (event is InputEventKey) or not event.pressed:
		return
	var key := int(event.physical_keycode)
	if key == KEY_ESCAPE:
		bind_buttons[listening_action].text = main.binding_key(listening_action)
		listening_action = ""
		get_viewport().set_input_as_handled()
		return
	main.save_binding(listening_action, key)
	bind_buttons[listening_action].text = OS.get_keycode_string(key)
	listening_action = ""
	main.sfx("click", -8.0)
	get_viewport().set_input_as_handled()


func _draw_sector_map() -> void:
	# The war at a glance: the Anchor's station, three fronts, one chain
	# of supply. You fight where the lines reach.
	var f: Font = mono_font if mono_font != null else ThemeDB.fallback_font
	var c := war_map_ctl
	var station := Vector2(1165, 300)
	var nodes := [Vector2(1265, 230), Vector2(1360, 330), Vector2(1480, 250)]
	var chain := [station, nodes[0], nodes[1], nodes[2]]
	for i in range(chain.size() - 1):
		var open: bool = i < 2 or main.planet_unlocked(2)
		var lcol := Color(0.35, 0.6, 0.75, 0.9) if open \
			else Color(0.5, 0.3, 0.3, 0.7)
		c.draw_line(chain[i], chain[i + 1], lcol, 2.0 if open else 1.0)
	# the Void Anchor station
	c.draw_colored_polygon(PackedVector2Array([
		station + Vector2(0, -9), station + Vector2(9, 0),
		station + Vector2(0, 9), station + Vector2(-9, 0)]), Color(0.9, 0.93, 0.97))
	c.draw_string(f, station + Vector2(-40, 26), "VOID ANCHOR",
				  HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.75, 0.8))
	for p in range(3):
		var np: Vector2 = nodes[p]
		var pd: Dictionary = main.PLANETS[p]
		var unlocked: bool = main.planet_unlocked(p)
		var lib := 0.0
		for o in pd["ops"]:
			lib += float(main.liberation.get_value("war", str(o["name"]), 0.0))
		lib /= 3.0
		var col: Color = pd["holo"] if unlocked else Color(0.3, 0.32, 0.36)
		c.draw_circle(np, 10.0, col)
		c.draw_arc(np, 13.0, -PI / 2, -PI / 2 + TAU * lib / 100.0, 32, GREEN, 2.0)
		if p == sel_planet:
			c.draw_arc(np, 17.0, 0, TAU, 32, AMBER, 1.4)
		c.draw_string(f, np + Vector2(-44, 30), str(pd["name"]),
					  HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
					  Color(0.8, 0.84, 0.9) if unlocked else Color(0.5, 0.4, 0.4))
		var sub := ("%d%% LIBERATED" % int(lib)) if unlocked \
			else "LOCKED %d/80" % int(main.total_liberation())
		c.draw_string(f, np + Vector2(-44, 43), sub,
					  HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
					  GREEN if unlocked else WARN)


# ------------------------------------------------------------- drop map

func _build_drop_map(ui: Control) -> void:
	drop_layer = Control.new()
	drop_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	drop_layer.visible = false
	ui.add_child(drop_layer)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.02, 0.04, 0.95)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	drop_layer.add_child(shade)

	map_ctl = Control.new()
	map_ctl.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_ctl.mouse_filter = Control.MOUSE_FILTER_STOP
	map_ctl.draw.connect(_draw_map)
	map_ctl.gui_input.connect(_on_map_input)
	drop_layer.add_child(map_ctl)

	var back := _mk_button(drop_layer, "< BACK TO THE DECK", Vector2(40, 826), 220,
						   func() -> void: drop_layer.visible = false)
	back.add_theme_font_size_override("font_size", 15)
	confirm_btn = _mk_button(drop_layer, ">>  LAUNCH GANTRY SPIKE  <<",
							 Vector2(660, 820), 300,
							 func() -> void: _confirm_drop())
	confirm_btn.size = Vector2(300, 46)
	confirm_btn.add_theme_font_size_override("font_size", 18)
	confirm_btn.add_theme_color_override("font_color", AMBER)


func _roll_recon() -> Array:
	# Pre-scout the objectives so the map tells the truth about the ground
	var mission: String = main.PLANETS[sel_planet]["ops"][sel_op]["mission"]
	var pts: Array = []
	match mission:
		"siphons":
			for i in range(3):
				var ang := i * TAU / 3.0 + randf_range(-0.4, 0.4)
				var dist := randf_range(45.0, 75.0)
				pts.append(Vector2(cos(ang) * dist, sin(ang) * dist))
		"uplink":
			var ang := randf() * TAU
			pts.append(Vector2(cos(ang) * 55.0, sin(ang) * 55.0))
		"hunt":
			var ang := randf() * TAU
			pts.append(Vector2(cos(ang) * 70.0, sin(ang) * 70.0))
	return pts


func _open_drop_map() -> void:
	drop_recon = _roll_recon()
	drop_vents.clear()
	var tier: int = main.PLANETS[sel_planet]["ops"][sel_op].get("tier", 5)
	var vcount := clampi(2 + tier / 4, 2, 4)
	for i in range(vcount):
		var vang := randf() * TAU
		var vdist := randf_range(30.0, 90.0)
		drop_vents.append(Vector2(cos(vang) * vdist, sin(vang) * vdist))
	drop_blobs.clear()
	for i in range(4):
		var ang := randf() * TAU
		var dist := randf_range(25.0, 100.0)
		drop_blobs.append([Vector2(cos(ang) * dist, sin(ang) * dist),
						   randf_range(9.0, 18.0)])
	drop_lz = Vector2.INF
	confirm_btn.disabled = true
	drop_layer.visible = true
	map_ctl.queue_redraw()
	main.sfx("breach", -14.0)


func _zone_assessment() -> Array:
	var near := 1e9
	for pt in drop_recon:
		near = minf(near, drop_lz.distance_to(pt))
	if near < 25.0:
		return ["HOT DROP — expect immediate contact", WARN]
	if near > 60.0:
		return ["QUIET SECTOR — unmonitored insertion", GREEN]
	return ["TACTICAL INSERTION — short walk to the signal", AMBER]


func _m2px(m: Vector2) -> Vector2:
	return MAP_C + m * MAP_SCALE


func _draw_map() -> void:
	var f: Font = mono_font if mono_font != null else ThemeDB.fallback_font
	var c := map_ctl
	c.draw_string(f, Vector2(MAP_C.x - 310, 60),
				  "TACTICAL DROP — ESTABLISH LANDING COORDINATES",
				  HORIZONTAL_ALIGNMENT_LEFT, -1, 26, AMBER)
	var op_d: Dictionary = main.PLANETS[sel_planet]["ops"][sel_op]
	c.draw_string(f, Vector2(MAP_C.x - 310, 90),
				  str(main.PLANETS[sel_planet]["name"]) + "  ·  " + str(op_d["name"]),
				  HORIZONTAL_ALIGNMENT_LEFT, -1, 15, BLUE)

	# AO rings: 30 m per band out to the 120 m operational edge
	for r in [30.0, 60.0, 90.0, 120.0]:
		var col := Color(0.25, 0.42, 0.52, 0.9) if r < 120.0 \
			else Color(0.45, 0.7, 0.85)
		c.draw_arc(MAP_C, r * MAP_SCALE, 0, TAU, 96, col, 1.0)
		c.draw_string(f, MAP_C + Vector2(4, -r * MAP_SCALE - 4), "%d m" % int(r),
					  HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.4, 0.55, 0.65))
	c.draw_line(MAP_C - Vector2(MAP_R_PX, 0), MAP_C + Vector2(MAP_R_PX, 0),
				Color(0.2, 0.34, 0.42, 0.6), 1.0)
	c.draw_line(MAP_C - Vector2(0, MAP_R_PX), MAP_C + Vector2(0, MAP_R_PX),
				Color(0.2, 0.34, 0.42, 0.6), 1.0)
	c.draw_circle(MAP_C, 3.0, BLUE)
	c.draw_string(f, MAP_C + Vector2(8, 4), "AO NEXUS",
				  HORIZONTAL_ALIGNMENT_LEFT, -1, 11, BLUE)

	# Patrol activity: stay out of the red if you like being alive
	for blob in drop_blobs:
		var bp: Vector2 = _m2px(blob[0])
		c.draw_circle(bp, blob[1] * MAP_SCALE, Color(0.9, 0.2, 0.15, 0.13))
		c.draw_arc(bp, blob[1] * MAP_SCALE, 0, TAU, 40,
				   Color(0.9, 0.25, 0.2, 0.5), 1.0)

	# Swarm vents: structural spawners, explosives only
	for pt in drop_vents:
		var vp: Vector2 = _m2px(pt)
		c.draw_colored_polygon(PackedVector2Array([
			vp + Vector2(0, -7), vp + Vector2(6, 5), vp + Vector2(-6, 5)]),
			Color(1.0, 0.6, 0.2))
		c.draw_string(f, vp + Vector2(10, 4), "VENT",
					  HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.6, 0.2))

	# Objective signals from the recon sweep
	for pt in drop_recon:
		var pp: Vector2 = _m2px(pt)
		var d := 7.0
		c.draw_colored_polygon(PackedVector2Array([
			pp + Vector2(0, -d), pp + Vector2(d, 0),
			pp + Vector2(0, d), pp + Vector2(-d, 0)]), Color(0.8, 0.45, 1.0))
		c.draw_string(f, pp + Vector2(10, 4), "SIGNAL",
					  HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 0.45, 1.0))

	# The chosen LZ
	if drop_lz.is_finite():
		var lp := _m2px(drop_lz)
		c.draw_arc(lp, 12.0, 0, TAU, 32, BLUE, 1.6)
		c.draw_circle(lp, 3.4, BLUE)
		c.draw_string(f, lp + Vector2(16, 4), "LZ",
					  HORIZONTAL_ALIGNMENT_LEFT, -1, 13, BLUE)
		var zone := _zone_assessment()
		var zw := f.get_string_size(zone[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		c.draw_string(f, Vector2(MAP_C.x - zw / 2, MAP_C.y + MAP_R_PX + 42),
					  zone[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, zone[1])
	else:
		var hint := "CLICK INSIDE THE AO TO SET YOUR LANDING ZONE"
		var hw := f.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		c.draw_string(f, Vector2(MAP_C.x - hw / 2, MAP_C.y + MAP_R_PX + 42),
					  hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
					  Color(0.6, 0.66, 0.72))


func _on_map_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		var m: Vector2 = (event.position - MAP_C) / MAP_SCALE
		if m.length() <= AO_M - 2.0:
			drop_lz = m
			confirm_btn.disabled = false
			map_ctl.queue_redraw()
			main.sfx("click", -10.0)


func _confirm_drop() -> void:
	if not drop_lz.is_finite():
		return
	_save_loadout()
	deploy_requested.emit({
		"planet": sel_planet, "op": sel_op, "rig": sel_rig,
		"paint": sel_paint, "visor": sel_visor, "weapon": sel_weapon,
		"sidearm": sel_sidearm, "suit_v": sel_suit_v, "suit_t": sel_suit_t,
		"grenade": sel_grenade, "booster": sel_booster,
		"voice": sel_voice, "pose": sel_pose,
		"drop": drop_lz, "recon": drop_recon, "vents": drop_vents})


# ------------------------------------------------------------- refresh

func _spec_bar(v: float, vmax: float) -> String:
	var n := clampi(int(round(v / vmax * 10.0)), 1, 10)
	return "#".repeat(n) + "-".repeat(10 - n)


func _spec_text(w: Dictionary) -> String:
	var lines: Array = []
	if w["heat"]:
		lines.append("AMMO       heat sink — no magazines")
		lines.append("HEAT/SHOT  %.1f  (R vents early)"
					 % float(w.get("heat_shot", 8.0)))
	else:
		lines.append("MAGAZINE   %d rounds  ·  %d reserve" % [w["mag"], w["reserve"]])
		lines.append("RELOAD     %.1f s" % float(w.get("reload", 1.7)))
	var pellets := int(w["pellets"])
	lines.append("DAMAGE     %d%s" % [int(w["damage"]),
				 (" x %d pellets" % pellets) if pellets > 1 else ""])
	lines.append("FIRE RATE  %d rpm" % int(60.0 / float(w["rate"])))
	lines.append("RECOIL     %s (%d)" % [_spec_bar(float(w["kick"]), 14.0),
										 int(w["kick"])])
	var ap := int(w.get("pen", 2))
	if ap >= 4:
		lines.append("ARMOR PEN  %d/10 — MEDIUM: opens plated units" % ap)
	else:
		lines.append("ARMOR PEN  %d/10 — LIGHT: ricochets off plate" % ap)
	var traits: Array = []
	if float(w["chill"]) > 0.0:
		traits.append("cryo/stagger")
	if w.has("dot_dps"):
		traits.append("corrosive DoT — ignores all armor")
	if w.has("aoe"):
		traits.append("explosive AoE")
	if not traits.is_empty():
		lines.append("TRAITS     " + ", ".join(traits))
	lines.append("")
	lines.append(str(w["desc"]))
	return "\n".join(lines)


func _refresh() -> void:
	var planet_d: Dictionary = main.PLANETS[sel_planet]
	for i in range(planet_buttons.size()):
		if not main.planet_unlocked(i):
			planet_buttons[i].modulate = Color(0.45, 0.35, 0.35)
		else:
			planet_buttons[i].modulate = AMBER if i == sel_planet else Color.WHITE
	for i in range(op_buttons.size()):
		var op_i: Dictionary = planet_d["ops"][i]
		op_buttons[i].text = "%s  ·  %s  ·  THREAT %d/10" % [
			str(op_i["name"]), str(op_i["difficulty"]), int(op_i.get("tier", 5))]
		op_buttons[i].modulate = AMBER if i == sel_op else Color.WHITE
	if war_map_ctl != null:
		war_map_ctl.queue_redraw()
	# The standing Major Order and its countdown
	var o_key := str(main.liberation.get_value("order", "op", ""))
	if main.liberation.get_value("order", "reward", false):
		order_label.text = "ORDER FULFILLED.\n\nReward queued: ORBITAL LASER x4 on your next drop. A new order follows once it's spent."
	elif o_key != "":
		var tgt := float(main.liberation.get_value("order", "target", 100.0))
		var cur_l := float(main.liberation.get_value("war", o_key, 0.0))
		var left := float(main.liberation.get_value("order", "deadline", 0.0)) \
			- Time.get_unix_time_from_system()
		order_label.text = "Bring %s to %d%% liberation (currently %d%%).\n\nDEADLINE: %dh %02dm.\nREWARD: Orbital Laser x4 on the drop after fulfillment.\n\nComplete the operation to move the bar — the whole operation, not a warm-up lap." % [
			o_key, int(tgt), int(cur_l),
			int(left / 3600.0), int(fmod(left, 3600.0) / 60.0)]
	else:
		order_label.text = "No standing order. The Directorate is drafting one."
	# retint the hologram to the selected world
	if planet_mat != null:
		var hc: Color = planet_d["holo"]
		planet_mat.albedo_color = Color(hc.r, hc.g, hc.b, 0.85)
		planet_mat.emission = hc * 0.7
	var mods: Array = planet_d.get("mods", [])
	mods_label.text = "\n".join(mods) if not mods.is_empty() \
		else "No active modifiers."
	var op: Dictionary = planet_d["ops"][sel_op]
	var lib: float = main.liberation.get_value("war", str(op["name"]), 0.0)
	op_desc.text = "%s\nLIBERATION: %d%%\n\n%s\n\nMISSION WINDOW: 12:00 — when it closes, stratagem support ends and the Swarm doubles down. Liberation decays while you're away; the war does not wait." % [
		str(planet_d["blurb"]), int(lib), str(op["desc"])]

	# Armory tab: highlight + live spec sheets
	for i in range(weapon_buttons.size()):
		weapon_buttons[i].modulate = AMBER if i == sel_weapon else Color.WHITE
	for i in range(sidearm_buttons.size()):
		sidearm_buttons[i].modulate = AMBER if i == sel_sidearm else Color.WHITE
	for i in range(grenade_buttons.size()):
		grenade_buttons[i].modulate = AMBER if i == sel_grenade else Color.WHITE
	for i in range(booster_buttons.size()):
		booster_buttons[i].modulate = AMBER if i == sel_booster else Color.WHITE
	for i in range(voice_buttons.size()):
		voice_buttons[i].modulate = AMBER if i == sel_voice else Color.WHITE
	for i in range(pose_buttons.size()):
		pose_buttons[i].modulate = AMBER if i == sel_pose else Color.WHITE
	spec_primary.text = _spec_text(PlayerScript.WEAPONS[WEAPON_KEYS[sel_weapon]])
	spec_side.text = _spec_text(PlayerScript.SIDEARMS[SIDEARM_KEYS[sel_sidearm]])
	var gd: Dictionary = PlayerScript.GRENADES[GRENADE_KEYS[sel_grenade]]
	spec_side.text += "\n\nFIELD KIT: %s x%d — %s" % [
		gd["name"], int(gd["count"]), str(gd["desc"])]
	booster_desc.text = str(BOOSTERS[sel_booster]["desc"])

	# Requisition tab
	for i in range(rig_buttons.size()):
		rig_buttons[i].modulate = AMBER if i == sel_rig else Color.WHITE
	for i in range(suit_v_buttons.size()):
		suit_v_buttons[i].modulate = AMBER if i == sel_suit_v else Color.WHITE
	for i in range(suit_t_buttons.size()):
		suit_t_buttons[i].modulate = AMBER if i == sel_suit_t else Color.WHITE
	for i in range(paint_buttons.size()):
		paint_buttons[i].modulate = AMBER if i == sel_paint else Color.WHITE
	for i in range(visor_buttons.size()):
		visor_buttons[i].modulate = AMBER if i == sel_visor else Color.WHITE
	var rig: Dictionary = RIGS[sel_rig]
	chassis_desc.text = str(rig["desc"])
	var cs: String = rig["set"]
	var v_opt: String = SUIT_OPTS[sel_suit_v]
	var t_opt: String = SUIT_OPTS[sel_suit_t]
	if cs == "":
		var pieces0: Array = []
		if v_opt != "":
			pieces0.append("VISOR " + SUIT_PIECES["visor"][v_opt])
		if t_opt != "":
			pieces0.append("ID TAG " + SUIT_PIECES["tag"][t_opt])
		suit_desc.text = ("%s\n" % " · ".join(pieces0) if not pieces0.is_empty() else "") \
			+ "The Underwriter answers to no set — piece bumps apply, but no Corporate Synergy is possible."
		suit_desc.add_theme_color_override("font_color", Color(0.7, 0.74, 0.8))
	elif v_opt == cs and t_opt == cs:
		suit_desc.text = "FULL UNIFORM — %s\n%s" % [SET_NAMES[cs], SUITS[cs]["syn"]]
		suit_desc.add_theme_color_override("font_color", Color(0.3, 1.0, 0.8))
	else:
		var pieces: Array = []
		if v_opt != "":
			pieces.append("VISOR " + SUIT_PIECES["visor"][v_opt])
		if t_opt != "":
			pieces.append("ID TAG " + SUIT_PIECES["tag"][t_opt])
		var line := " · ".join(pieces) if not pieces.is_empty() \
			else "Standard-issue pieces — chassis stats only."
		suit_desc.text = "%s\nMatch VISOR and ID TAG to the %s chassis to unlock: %s" \
			% [line, SET_NAMES[cs], SUITS[cs]["syn"]]
		suit_desc.add_theme_color_override("font_color", Color(0.7, 0.74, 0.8))

	# the armory display wears exactly what you picked — chassis, gun and all
	if mann_rig_built != sel_rig:
		mann_rig_built = sel_rig
		mann_gun_built = -1
		for c in mann_root.get_children():
			c.queue_free()
		var parts: Dictionary = TrooperModel.build(mann_root,
			PAINTS[sel_paint]["color"], VISORS[sel_visor]["color"],
			RIGS[sel_rig])
		mannequin_body = parts["armor"]
		mannequin_visor = parts["visor"]
		mann_gun_root = parts["gun_root"]
	if mann_gun_built != sel_weapon and mann_gun_root != null:
		mann_gun_built = sel_weapon
		TrooperModel.build_gun(mann_gun_root, WEAPON_KEYS[sel_weapon])
	mannequin_body.albedo_color = PAINTS[sel_paint]["color"]
	mannequin_visor.emission = VISORS[sel_visor]["color"]
	mannequin_visor.albedo_color = VISORS[sel_visor]["color"] * 0.2
