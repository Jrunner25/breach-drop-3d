# BREACH-DROP 3D — The White Reach
# Flow: Void Anchor launch bay (operation select + armory) -> gantry drop.
# The world is procedural: rolling heightmap tundra, no imported assets.
extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const TickScript   = preload("res://scripts/tick.gd")
const WalkerScript = preload("res://scripts/walker.gd")
const GunnerScript = preload("res://scripts/gunner.gd")
const SpitterScript = preload("res://scripts/spitter.gd")
const SiegeScript  = preload("res://scripts/siege_walker.gd")
const MergerScript = preload("res://scripts/merger.gd")
const AllyScript   = preload("res://scripts/ally.gd")
const StratScript  = preload("res://scripts/stratagems.gd")
const HudScript    = preload("res://scripts/hud.gd")
const MenuScript   = preload("res://scripts/menu.gd")
const SiphonScript = preload("res://scripts/siphon.gd")
const VentScript   = preload("res://scripts/vent.gd")
const ClerkScript  = preload("res://scripts/clerk.gd")
const DebrisScript = preload("res://scripts/debris.gd")
const ForemanScript = preload("res://scripts/foreman.gd")
const ArbiterScript = preload("res://scripts/arbiter.gd")

const SFX := {
	"shoot": preload("res://sfx/shoot.wav"),
	"boom": preload("res://sfx/boom.wav"),
	"click": preload("res://sfx/click.wav"),
	"breach": preload("res://sfx/breach.wav"),
	"stim": preload("res://sfx/stim.wav"),
	"wind": preload("res://sfx/wind.wav"),
	"laser": preload("res://sfx/laser.wav"),
	"hit": preload("res://sfx/hit.wav"),
	"kill": preload("res://sfx/kill.wav"),
	"shatter": preload("res://sfx/shatter.wav"),
}
const MUSIC := {
	"amb": preload("res://sfx/music_amb.wav"),
	"combat": preload("res://sfx/music_combat.wav"),
	"extract": preload("res://sfx/music_extract.wav"),
}

# The war: planets on the holo-table, each with its own operations
const PLANETS := [
	{"name": "THE WHITE REACH", "biome": "tundra",
	 "holo": Color(0.5, 0.75, 0.95),
	 "blurb": "An icy tundra world. The Swarm drinks its core heat.",
	 "cold": true, "faction": "swarm",
	 "mods": ["HOSTILE FORCE: THE SILICON SWARM — a melee tide; keep moving",
			  "EXTREME COLD — heat-sink weapons overheat 50% slower",
			  "EXTREME COLD — stamina drains 25% faster while sprinting"],
	 "ops": [
		{"name": "OPERATION WHITEOUT", "difficulty": "STANDARD", "tier": 3,
		 "mission": "siphons",
		 "desc": "Daylight sweep of the siphon fields. Shatter the cryo-siphons and get out.",
		 "waves": [{"tick": 6}, {"tick": 8, "gunner": 2}, {"tick": 8, "gunner": 3},
				   {"tick": 10, "gunner": 3, "walker": 1},
				   {"tick": 10, "gunner": 4, "spitter": 1},
				   {"tick": 12, "gunner": 4, "walker": 1, "spitter": 1}],
		 "sun_deg": -16.0, "sun_energy": 1.5, "sun_color": Color(1.0, 0.93, 0.82),
		 "sky_top": Color(0.30, 0.42, 0.58), "sky_horizon": Color(0.76, 0.80, 0.86),
		 "fog": 0.006, "vfog": 0.012, "snow": 900, "seed": 7},
		{"name": "OPERATION LONGNIGHT", "difficulty": "HARD", "tier": 6,
		 "mission": "uplink",
		 "desc": "Dusk data raid. Hold the uplink terminal while it screams our position to everything.",
		 "waves": [{"tick": 8, "gunner": 2}, {"tick": 8, "gunner": 4},
				   {"tick": 10, "gunner": 4, "spitter": 1, "sniper": 1},
				   {"tick": 12, "gunner": 5, "walker": 1, "sniper": 1},
				   {"tick": 10, "gunner": 5, "spitter": 2, "atick": 2, "sniper": 1},
				   {"tick": 14, "gunner": 6, "walker": 2, "sniper": 2},
				   {"tick": 14, "gunner": 6, "spitter": 2, "atick": 3, "sniper": 2}],
		 "sun_deg": -5.0, "sun_energy": 1.1, "sun_color": Color(1.0, 0.55, 0.3),
		 "sky_top": Color(0.16, 0.14, 0.28), "sky_horizon": Color(0.9, 0.5, 0.35),
		 "fog": 0.010, "vfog": 0.02, "snow": 700, "seed": 23},
		{"name": "OPERATION BLACKSTORM", "difficulty": "BRUTAL", "tier": 9,
		 "mission": "hunt",
		 "desc": "A Siege Walker is out in the blizzard. Find it. Shoot the knees. Bring it down.",
		 "waves": [{"tick": 10}, {"tick": 12, "atick": 2},
				   {"tick": 14, "atick": 3, "spitter": 1, "stalker": 1},
				   {"tick": 16, "gunner": 3, "atick": 3, "stalker": 1},
				   {"tick": 14, "atick": 4, "walker": 2, "stalker": 2},
				   {"tick": 18, "gunner": 4, "spitter": 2, "atick": 4,
					"stalker": 2, "merger": 1}],
		 "sun_deg": -24.0, "sun_energy": 0.7, "sun_color": Color(0.75, 0.82, 0.95),
		 "sky_top": Color(0.28, 0.32, 0.40), "sky_horizon": Color(0.55, 0.58, 0.64),
		 "fog": 0.028, "vfog": 0.05, "snow": 2400, "seed": 41},
	 ]},
	{"name": "CINDERFALL", "biome": "ash",
	 "holo": Color(1.0, 0.45, 0.2),
	 "blurb": "A burned volcanic world. The ground itself is a weapon.",
	 "interference": true, "faction": "reclaimers",
	 "vfog_color": Color(0.5, 0.33, 0.24),
	 "mods": ["HOSTILE FORCE: THE RECLAIMERS — repo-bots; use cover, kill the flare-bearers",
			  "ATMOSPHERIC INTERFERENCE — stratagem call-ins take 25% longer",
			  "VOLCANIC GROUND — magma pools burn anyone standing in them"],
	 "ops": [
		{"name": "OPERATION CINDERWAKE", "difficulty": "STANDARD", "tier": 4,
		 "mission": "siphons",
		 "desc": "The Reclaimers sank siphons into the caldera fields. Mind the magma. It doesn't mind you.",
		 "waves": [{"clerk": 5}, {"clerk": 6, "tick": 3}, {"clerk": 7, "foreman": 1},
				   {"clerk": 8, "foreman": 1, "rocket": 1},
				   {"clerk": 8, "foreman": 2, "rocket": 1},
				   {"clerk": 10, "foreman": 2, "rocket": 2, "walker": 1}],
		 "sun_deg": -20.0, "sun_energy": 0.9, "sun_color": Color(1.0, 0.6, 0.35),
		 "sky_top": Color(0.13, 0.10, 0.10), "sky_horizon": Color(0.48, 0.30, 0.22),
		 "fog": 0.012, "vfog": 0.02, "snow": 500, "seed": 63},
		{"name": "OPERATION EMBERFALL", "difficulty": "HARD", "tier": 7,
		 "mission": "uplink",
		 "desc": "Hold the uplink under a rain of embers while the Reclaimers file suppressive paperwork.",
		 "waves": [{"clerk": 6, "tick": 3}, {"clerk": 7, "foreman": 1},
				   {"clerk": 8, "foreman": 1, "rocket": 1},
				   {"clerk": 9, "foreman": 2, "rocket": 1},
				   {"clerk": 9, "foreman": 2, "rocket": 2, "walker": 1},
				   {"clerk": 11, "foreman": 3, "rocket": 2, "merger": 1}],
		 "sun_deg": -8.0, "sun_energy": 1.0, "sun_color": Color(1.0, 0.4, 0.2),
		 "sky_top": Color(0.16, 0.08, 0.06), "sky_horizon": Color(0.72, 0.32, 0.16),
		 "fog": 0.016, "vfog": 0.028, "snow": 700, "seed": 77},
		{"name": "OPERATION PYRECROWN", "difficulty": "BRUTAL", "tier": 9,
		 "mission": "hunt",
		 "desc": "A Siege Walker nests in the ashfall with a Reclaimer escort. Hunt it through the embers.",
		 "waves": [{"clerk": 7, "tick": 4}, {"clerk": 8, "foreman": 1, "rocket": 1},
				   {"clerk": 9, "foreman": 2, "rocket": 1},
				   {"clerk": 10, "foreman": 2, "rocket": 2},
				   {"clerk": 10, "foreman": 3, "rocket": 2, "walker": 1},
				   {"clerk": 12, "foreman": 3, "rocket": 3, "merger": 1}],
		 "sun_deg": -30.0, "sun_energy": 0.55, "sun_color": Color(0.9, 0.5, 0.35),
		 "sky_top": Color(0.08, 0.07, 0.08), "sky_horizon": Color(0.35, 0.22, 0.16),
		 "fog": 0.030, "vfog": 0.06, "snow": 1200, "seed": 91},
	 ]},
	{"name": "MERIDIAN VERGE", "biome": "tundra",
	 "holo": Color(0.7, 0.45, 1.0),
	 "blurb": "The contested verge between fronts. Everything bad about both worlds, plus acid.",
	 "cold": true, "interference": true, "caustic": true,
	 "locked_by_supply": true, "faction": "arbitration",
	 "vfog_color": Color(0.5, 0.42, 0.68),
	 "mods": ["HOSTILE FORCE: THE ARBITRATION — regenerating shields; rate of fire beats caliber",
			  "PSIONIC ACTIVITY — expect inverted motor controls and scrambled codes",
			  "EXTREME COLD + INTERFERENCE + CAUSTIC SQUALLS — all of it, at once"],
	 "ops": [
		{"name": "OPERATION MARGIN CALL", "difficulty": "SEVERE", "tier": 8,
		 "mission": "siphons",
		 "desc": "Siphons in an acid squall. Every system on this rock is out of warranty, including yours.",
		 "waves": [{"tick": 12, "arbiter": 1}, {"tick": 12, "arbiter": 2, "atick": 2},
				   {"tick": 14, "arbiter": 2, "spitter": 2, "atick": 3},
				   {"tick": 16, "arbiter": 3, "walker": 1, "atick": 4},
				   {"tick": 16, "arbiter": 3, "spitter": 3, "walker": 2, "atick": 4},
				   {"tick": 18, "arbiter": 4, "walker": 2, "atick": 5, "merger": 1}],
		 "sun_deg": -14.0, "sun_energy": 0.8, "sun_color": Color(0.8, 0.6, 1.0),
		 "sky_top": Color(0.14, 0.10, 0.22), "sky_horizon": Color(0.5, 0.38, 0.6),
		 "fog": 0.014, "vfog": 0.025, "snow": 1000, "seed": 113},
		{"name": "OPERATION GOLDEN HANDSHAKE", "difficulty": "SEVERE", "tier": 9,
		 "mission": "uplink",
		 "desc": "Hold the uplink while the verge screams interference at everything you love.",
		 "waves": [{"tick": 12, "arbiter": 2, "atick": 2},
				   {"tick": 14, "arbiter": 2, "atick": 3},
				   {"tick": 14, "arbiter": 3, "spitter": 3, "atick": 3},
				   {"tick": 16, "arbiter": 3, "walker": 2, "atick": 4},
				   {"tick": 18, "arbiter": 4, "spitter": 3, "walker": 2, "atick": 5},
				   {"tick": 18, "arbiter": 5, "walker": 3, "atick": 5, "merger": 1}],
		 "sun_deg": -8.0, "sun_energy": 0.7, "sun_color": Color(0.9, 0.5, 0.8),
		 "sky_top": Color(0.10, 0.07, 0.18), "sky_horizon": Color(0.6, 0.35, 0.5),
		 "fog": 0.018, "vfog": 0.035, "snow": 1400, "seed": 127},
		{"name": "OPERATION FINAL NOTICE", "difficulty": "APOCALYPTIC", "tier": 10,
		 "mission": "hunt",
		 "desc": "A Siege Walker in the acid dark, and everything the verge can field beside it. Final notice, Breacher.",
		 "waves": [{"tick": 14, "atick": 3, "arbiter": 2},
				   {"tick": 16, "atick": 4, "arbiter": 3, "spitter": 2, "stalker": 1},
				   {"tick": 16, "arbiter": 3, "atick": 5, "walker": 2, "sniper": 1},
				   {"tick": 18, "arbiter": 4, "atick": 5, "spitter": 3, "walker": 2,
					"stalker": 2},
				   {"tick": 18, "arbiter": 4, "atick": 6, "walker": 3, "merger": 1,
					"sniper": 2},
				   {"tick": 20, "arbiter": 5, "spitter": 4, "atick": 6, "walker": 3,
					"merger": 2, "stalker": 2}],
		 "sun_deg": -26.0, "sun_energy": 0.5, "sun_color": Color(0.7, 0.5, 0.9),
		 "sky_top": Color(0.06, 0.05, 0.12), "sky_horizon": Color(0.35, 0.25, 0.42),
		 "fog": 0.026, "vfog": 0.05, "snow": 2000, "seed": 139},
	 ]},
	{"name": "THE SUNKEN REACH", "biome": "swamp",
	 "holo": Color(0.4, 0.95, 0.55),
	 "blurb": "A drowned fungal basin. The Overgrowth breathes spores and acid.",
	 "caustic": true, "faction": "overgrowth",
	 "vfog_color": Color(0.30, 0.52, 0.34),
	 "mods": ["HOSTILE FORCE: THE OVERGROWTH — a spore-borne melee tide; keep the lanes clear",
			  "FUNGAL CANOPY — the deep canopy fouls orbital call-ins",
			  "CAUSTIC GROUND — acid pools digest anyone who wades in"],
	 "ops": [
		{"name": "OPERATION UNDERGROWTH", "difficulty": "STANDARD", "tier": 4,
		 "mission": "siphons",
		 "desc": "Burn the spore-siphons out of the bog before the canopy closes over you.",
		 "waves": [{"tick": 8}, {"tick": 10, "spitter": 1}, {"tick": 10, "spitter": 2},
				   {"tick": 12, "spitter": 2, "walker": 1},
				   {"tick": 12, "spitter": 2, "atick": 2},
				   {"tick": 14, "spitter": 3, "walker": 1, "atick": 2}],
		 "sun_deg": -18.0, "sun_energy": 1.0, "sun_color": Color(0.7, 0.95, 0.6),
		 "sky_top": Color(0.10, 0.20, 0.15), "sky_horizon": Color(0.42, 0.58, 0.40),
		 "fog": 0.014, "vfog": 0.03, "snow": 600, "seed": 151},
		{"name": "OPERATION DEEPWATER", "difficulty": "HARD", "tier": 7,
		 "mission": "uplink",
		 "desc": "Hold the uplink in the drowned vaults while the Overgrowth floods every lane.",
		 "waves": [{"tick": 10, "spitter": 1}, {"tick": 10, "spitter": 2},
				   {"tick": 12, "spitter": 2, "walker": 1, "stalker": 1},
				   {"tick": 14, "spitter": 3, "atick": 2, "stalker": 1},
				   {"tick": 14, "spitter": 3, "walker": 2, "atick": 3},
				   {"tick": 16, "spitter": 4, "walker": 2, "atick": 3, "merger": 1}],
		 "sun_deg": -7.0, "sun_energy": 0.85, "sun_color": Color(0.6, 0.85, 0.55),
		 "sky_top": Color(0.07, 0.14, 0.11), "sky_horizon": Color(0.34, 0.48, 0.34),
		 "fog": 0.018, "vfog": 0.038, "snow": 800, "seed": 167},
		{"name": "OPERATION ROOTKILL", "difficulty": "BRUTAL", "tier": 9,
		 "mission": "hunt",
		 "desc": "An Apex growth stalks the deep canopy. Hunt it through the spores and drop it.",
		 "waves": [{"tick": 12, "atick": 2}, {"tick": 14, "spitter": 2, "atick": 3},
				   {"tick": 14, "spitter": 2, "walker": 2, "stalker": 1},
				   {"tick": 16, "spitter": 3, "atick": 4, "stalker": 2},
				   {"tick": 16, "spitter": 3, "walker": 2, "atick": 4},
				   {"tick": 18, "spitter": 4, "walker": 3, "atick": 5, "merger": 1}],
		 "sun_deg": -28.0, "sun_energy": 0.55, "sun_color": Color(0.5, 0.8, 0.5),
		 "sky_top": Color(0.05, 0.10, 0.08), "sky_horizon": Color(0.22, 0.34, 0.24),
		 "fog": 0.028, "vfog": 0.055, "snow": 1400, "seed": 181},
	 ]},
]
const SPAWN_RADIUS := 55.0

var player: CharacterBody3D
var hud: Control
var strats: Node
var snow: GPUParticles3D
var spindrift: GPUParticles3D
var menu: Node3D
var env: Environment
var sun: DirectionalLight3D
var terrain_noise: FastNoiseLite

var state := "menu"           # menu | crawl | playing | dead | gameover | victory
var planet: Dictionary = PLANETS[0]
var op: Dictionary = PLANETS[0]["ops"][0]
var waves_table: Array = PLANETS[0]["ops"][0]["waves"]
var biome := "tundra"
var hazards: Array = []            # [[pos, radius], ...] magma pools burn
var speeder: Node3D
var near_speeder := false
var lives := 4
var score := 0
var wave_idx := 0             # display counter — surges are endless
var wave_active := false
var between_timer := 4.0
var trickle: Array = []
var trickle_timer := 0.0
var respawn_timer := 0.0

# --- Hellpod drop-in (the playable mission start) ---
const DROP_HEIGHT := 260.0
var pod: Node3D
var drop_cam: Camera3D
var drop_impact := Vector3.ZERO
var drop_vel := 8.0
var drop_shake := 0.0

# The mission itself: clear the siphons, then run for the beacon
var phase := "clear"          # clear | extract | leaving
var siphons: Array = []
var beacon: Node3D
var beacon_pos := Vector3.ZERO
var extract_hold := 20.0
var dropship: Node3D

# Patrols call in breaches when they spot you
var patrol_timer := 14.0
var breach_cd := 0.0

# The clock is the real enemy: pressure builds, and when the mission
# window closes, the Void Anchor is retasked and support stops coming.
const MISSION_LIMIT := 720.0       # 12 minutes of company time
var mission_time := 0.0
var mission_limit := 720.0         # Overtime Authorization stretches it
var anchor_retasked := false
var vents: Array = []              # Swarm vents feeding the sector
var event_timer := 150.0           # the Directorate is always watching
var smokes: Array = []             # NDA canisters: [[node, pos, radius, t], ..]
var pose_name := "CRISP SALUTE"    # for the victory overlay

# The living map: friction, weather, and points of interest
var mires: Array = []              # deep drifts / ash mires: [[pos, radius], ..]
var pois: Array = []               # crash sites: [{pos, node, looted, discovered}]
var radar_pos := Vector3.ZERO      # the radar tower POI
var radar_done := false
var radar_progress := 0.0
var cache_pos := Vector3.ZERO      # secondary objective: the data cache
var cache_done := false
var cache_progress := 0.0
var radar_boost_t := 0.0           # tower-granted radar pings
var env_timer := 100.0             # dynamic weather / geology
var tremor_t := 0.0
var ion_t := 0.0                   # ion storm: stratagem link offline
var psi_t := 0.0                   # psionic inversion: controls compromised

# Disposable identities: every reinforcement is a brand-new recruit
const RECRUIT_NICKS := ["BUCKET", "STAPLER", "LATTE", "SYNERGY", "INVOICE",
						"PIVOT", "KPI", "AUDIT", "LANYARD", "BINDER", "DECAF",
						"MINUTES", "ONBOARD", "REBRAND"]
const BARKS := {
	"PANICKED": {
		"spawn": ["WHY IS THE POD ON FIRE. WHY AM I ON FIRE.",
				  "I was told this was a DESK job!",
				  "Okay. Okay okay okay. Breathe. SCREAM."],
		"extract": ["The dropship! I LOVE the dropship!",
					"Almost payday. Almost payday. Almost—"],
		"down": ["Tell HR... the onboarding... was misleading..."],
		"emote": ["Is waving tactically sound?! I'm doing it anyway!",
				  "Please don't eat me, I have DEPENDENTS!"],
	},
	"MANIACAL": {
		"spawn": ["HAHAHA! FRESH LEGS! LET'S GO!",
				  "The Swarm owes me MONEY!",
				  "New body, same grudge!"],
		"extract": ["Leaving?! I was just getting WARMED UP!",
					"Fine! FINE! But I'm taking the samples!"],
		"down": ["Worth it... totally... worth it..."],
		"emote": ["BEHOLD! Middle management in MOTION!",
				  "I flex, therefore I am!"],
	},
	"CORPORATE": {
		"spawn": ["This unit is thrilled to be deployed.",
				  "Alignment achieved. Deliverables: violence.",
				  "Per my last memo: engaging."],
		"extract": ["Extraction is a core competency.",
					"Circling back to the dropship, as per the roadmap."],
		"down": ["Please... update... the org chart..."],
		"emote": ["This gesture is brand-compliant.",
				  "Saluting stakeholders at all levels."],
	},
}

var liberation := ConfigFile.new()
var _pending_deploy: Dictionary = {}
var crawl_root: Node3D
var crawl_timer := 0.0
var _sfx_players: Array = []
var _sfx_next := 0
var wind_player: AudioStreamPlayer

# Mission variety
var mission_type := "siphons"      # siphons | uplink | hunt
var terminal: Node3D
var upload := 0.0                  # uplink progress 0..100
var boss: Node3D
var sample_nodes: Array = []

# The squad
var reinforce_timer := 0.0
var taunt_target: Node3D = null    # Deflection of Blame: the designated coworker
var taunt_t := 0.0

# Score, feel, shell
var music: Dictionary = {}         # name -> AudioStreamPlayer
var settings := {"sens": 0.0022, "vol": 0.0, "sdfgi": true}
var pause_layer: CanvasLayer
var env_ref: Environment


func _ready() -> void:
	randomize()
	process_mode = Node.PROCESS_MODE_ALWAYS   # keep running while paused
	_setup_input()
	_build_environment()
	liberation.load("user://liberation.cfg")
	_decay_liberation()
	_ensure_major_order()
	_load_settings()
	_build_pause_menu()

	# A small pool of one-shot audio players
	for i in range(8):
		var ap := AudioStreamPlayer.new()
		ap.volume_db = -8.0
		add_child(ap)
		_sfx_players.append(ap)
	wind_player = AudioStreamPlayer.new()
	wind_player.volume_db = -14.0
	var wind_stream: AudioStreamWAV = SFX["wind"]
	wind_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wind_stream.loop_end = wind_stream.data.size() / 2
	wind_player.stream = wind_stream
	add_child(wind_player)

	# The score: three loops, always spinning, mixed by game state
	for track in MUSIC:
		var mp := AudioStreamPlayer.new()
		var st: AudioStreamWAV = MUSIC[track]
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_end = st.data.size() / 2
		mp.stream = st
		mp.volume_db = -60.0
		add_child(mp)
		mp.play()
		music[track] = mp

	menu = MenuScript.new()
	menu.main = self
	add_child(menu)
	menu.position = Vector3(0, 400, 0)   # the ship hangs above the drop zone
	menu.deploy_requested.connect(_on_deploy_request)

	# Automated validation hooks:
	#   -- autodeploy [autowin]  straight into the field (optionally win it)
	#   -- autocrawl             exercise the briefing crawl path
	if "autodeploy" in OS.get_cmdline_user_args():
		get_tree().create_timer(2.0).timeout.connect(func() -> void:
			if state == "menu":
				var p_idx := 0
				if "ash" in OS.get_cmdline_user_args():
					p_idx = 1
				elif "verge" in OS.get_cmdline_user_args():
					p_idx = 2
				if "events" in OS.get_cmdline_user_args():
					for k in range(6):
						get_tree().create_timer(6.0 + k * 5.0).timeout.connect(
							func() -> void:
								if state == "playing":
									_env_event())
				if "corp" in OS.get_cmdline_user_args():
					# validation: Corporate Claims kit — laser, plasma sidearm,
					# full HR Specialist uniform (Recon Weave chassis)
					deploy({"planet": p_idx, "rig": 0, "weapon": 6,
							"sidearm": 2, "suit_v": 1, "suit_t": 1,
							"drop": Vector2(50.0, 20.0)})
				else:
					deploy({"planet": p_idx, "rig": 2})
				if "autowin" in OS.get_cmdline_user_args():
					_autowin_sequence())
	elif "autocrawl" in OS.get_cmdline_user_args():
		get_tree().create_timer(2.0).timeout.connect(func() -> void:
			if state == "menu":
				_on_deploy_request({"planet": 0, "op": 1})
				get_tree().create_timer(14.0).timeout.connect(func() -> void:
					print("AUTOCRAWL state=", state, " phase=", phase)))


func _autowin_sequence() -> void:
	# Validation: force the whole mission chain to run end to end
	get_tree().create_timer(4.0).timeout.connect(func() -> void:
		for s in siphons.duplicate():
			if is_instance_valid(s):
				s.take_damage(99999.0)
		print("AUTOWIN siphons destroyed, phase=", phase))
	get_tree().create_timer(6.0).timeout.connect(func() -> void:
		if player != null and beacon != null:
			player.global_position = beacon_pos + Vector3(1, 1.5, 1)
			player.invincible = 10 ** 9
			print("AUTOWIN at beacon, phase=", phase))
	for probe_t in [10.0, 15.0, 20.0, 25.0, 30.0, 36.0, 42.0]:
		get_tree().create_timer(probe_t).timeout.connect(func() -> void:
			var d := -1.0
			if player != null and beacon != null:
				var flat := player.global_position - beacon_pos
				flat.y = 0.0
				d = flat.length()
			print("AUTOWIN t=%s state=%s phase=%s hold=%.1f dist=%.1f" % [
				probe_t, state, phase, extract_hold, d])
			if player != null and beacon != null and phase == "extract":
				player.global_position = beacon_pos + Vector3(1, 1.5, 1))


func _decay_liberation() -> void:
	# The war does not wait for you: while you're gone the Swarm advances,
	# bleeding roughly 3% liberation per real day off every front.
	var now := Time.get_unix_time_from_system()
	var last: float = liberation.get_value("meta", "last", now)
	var days := (now - last) / 86400.0
	if days > 0.02 and liberation.has_section("war"):
		for key in liberation.get_section_keys("war"):
			var v: float = liberation.get_value("war", key, 0.0)
			liberation.set_value("war", key, maxf(0.0, v - days * 3.0))
	liberation.set_value("meta", "last", now)
	liberation.save("user://liberation.cfg")


func total_liberation() -> float:
	var sum := 0.0
	if liberation.has_section("war"):
		for key in liberation.get_section_keys("war"):
			sum += float(liberation.get_value("war", key, 0.0))
	return sum


func planet_unlocked(idx: int) -> bool:
	# Supply lines: the Verge only opens once the rear fronts hold ground
	if PLANETS[idx].get("locked_by_supply", false):
		return total_liberation() >= 80.0
	return true


func _ensure_major_order() -> void:
	# The Directorate issues one standing Major Order at a time: push a
	# named operation to a liberation target before the deadline.
	var now := Time.get_unix_time_from_system()
	var deadline: float = liberation.get_value("order", "deadline", 0.0)
	if deadline > now and str(liberation.get_value("order", "op", "")) != "":
		return
	var p: Dictionary = PLANETS[randi() % 2]   # rear fronts only
	var o: Dictionary = p["ops"][randi() % 3]
	var key := str(o["name"])
	var cur: float = liberation.get_value("war", key, 0.0)
	liberation.set_value("order", "op", key)
	liberation.set_value("order", "target", minf(100.0, cur + 15.0))
	liberation.set_value("order", "deadline", now + 3.0 * 86400.0)
	liberation.save("user://liberation.cfg")


func new_recruit(voice_idx: int) -> Dictionary:
	# The revolving door: a serial number, a nickname, and a personality
	var pool := ["PANICKED", "MANIACAL", "CORPORATE"]
	var pers: String = pool[voice_idx - 1] if voice_idx >= 1 \
		else pool[randi() % pool.size()]
	return {"name": "RCT-%04d '%s'" % [randi() % 9000 + 1000,
			RECRUIT_NICKS[randi() % RECRUIT_NICKS.size()]], "pers": pers}


func bark(kind: String) -> void:
	if player == null or hud == null or player.recruit.is_empty():
		return
	var lines: Array = BARKS[player.recruit["pers"]][kind]
	hud.push_msg("%s: \"%s\"" % [player.recruit["name"],
				 lines[randi() % lines.size()]], Color(0.75, 0.8, 0.88))


func spawn_smoke(pos: Vector3) -> void:
	# An NDA canister: ten seconds of legally binding invisibility
	var cloud := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 3.0
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 60.0
	pm.gravity = Vector3(0, 0.15, 0)
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 0.9
	pm.scale_min = 3.0
	pm.scale_max = 7.0
	cloud.process_material = pm
	cloud.amount = 140
	cloud.lifetime = 4.0
	var q := QuadMesh.new()
	q.size = Vector2(2.2, 2.2)
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.albedo_color = Color(0.75, 0.78, 0.82, 0.16)
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q.material = qm
	cloud.draw_pass_1 = q
	add_child(cloud)
	cloud.global_position = pos + Vector3(0, 1.5, 0)
	smokes.append([cloud, pos, 7.0, 10.0])


func in_smoke(p: Vector3) -> bool:
	for s in smokes:
		if p.distance_to(s[1]) < s[2]:
			return true
	return false


func sfx(name: String, volume_db := -8.0) -> void:
	var ap: AudioStreamPlayer = _sfx_players[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx_players.size()
	ap.stream = SFX[name]
	ap.volume_db = volume_db
	ap.play()


func _on_deploy_request(cfg: Dictionary) -> void:
	# Between the launch bay and the drop: the briefing crawl
	sfx("click")
	_pending_deploy = cfg
	menu.visible = false
	state = "crawl"
	crawl_timer = 11.0
	var p_idx: int = cfg.get("planet", 0)
	_build_crawl(PLANETS[p_idx], PLANETS[p_idx]["ops"][cfg.get("op", 0)])


func _build_crawl(the_planet: Dictionary, the_op: Dictionary) -> void:
	crawl_root = Node3D.new()
	add_child(crawl_root)
	crawl_root.position = Vector3(0, 800, 0)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 2.0, 8.0)
	cam.rotation_degrees = Vector3(18, 0, 0)   # gazing up into the void
	crawl_root.add_child(cam)
	cam.current = true

	var label := Label3D.new()
	label.text = "MANDATORY ONBOARDING ORIENTATION\n\n%s\n\n%s  ·  %s\n\nThe VOID ANCHOR holds station\nover the worksite at %s.\n%s\n\nMeet your quota.\nLight the beacon.\nReturn to service, Liquidator." % [
		the_op["name"], str(the_planet["name"]),
		the_op["difficulty"] + " CONTRACT",
		str(the_planet["name"]).to_lower().capitalize(),
		str(the_planet["blurb"])]
	label.font_size = 120
	label.modulate = Color(1.0, 0.72, 0.2)
	label.outline_size = 0
	label.pixel_size = 0.01
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Corporate briefing display, not a space-opera crawl: a shallow tilt
	label.rotation_degrees = Vector3(-26, 0, 0)
	label.position = Vector3(0, -3.0, 0)
	crawl_root.add_child(label)
	# a red CONFIDENTIAL stamp for corporate menace
	var stamp := Label3D.new()
	stamp.text = "CONFIDENTIAL · LIQUIDATION DIVISION · DO NOT DISTRIBUTE"
	stamp.font_size = 44
	stamp.modulate = Color(0.9, 0.22, 0.16)
	stamp.pixel_size = 0.01
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp.rotation_degrees = Vector3(-26, 0, 0)
	stamp.position = Vector3(0, -1.2, 0)
	crawl_root.add_child(stamp)
	var tw := create_tween()
	tw.tween_property(label, "position", Vector3(0, 6.0, -26.0), 12.0)
	tw.parallel().tween_property(stamp, "position", Vector3(0, 7.6, -26.0), 12.0)


# ------------------------------------------------------------------ input

func _setup_input() -> void:
	# Standard FPS defaults: SHIFT sprints, CTRL crouches, TAB opens the
	# stratagem matrix. User re-binds from keybinds.cfg override everything.
	var keys := {
		"move_forward": KEY_W, "move_back": KEY_S,
		"move_left": KEY_A, "move_right": KEY_D,
		"sprint": KEY_SHIFT, "dive": KEY_SPACE,
		"crouch": KEY_CTRL, "prone": KEY_X,
		"reload": KEY_R, "restart": KEY_ENTER, "stim": KEY_Q,
		"interact": KEY_E, "emote": KEY_G, "grenade": KEY_F,
		"slot1": KEY_1, "slot2": KEY_2,
		"strat_open": KEY_TAB,
		"strat_up": KEY_UP, "strat_down": KEY_DOWN,
		"strat_left": KEY_LEFT, "strat_right": KEY_RIGHT,
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		apply_binding(action, keys[action])
	if not InputMap.has_action("fire"):
		InputMap.add_action("fire")
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("fire", mb)
	if not InputMap.has_action("aim"):
		InputMap.add_action("aim")
		var mb2 := InputEventMouseButton.new()
		mb2.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event("aim", mb2)
	var cfg := ConfigFile.new()
	if cfg.load("user://keybinds.cfg") == OK and cfg.has_section("keys"):
		for action in cfg.get_section_keys("keys"):
			if InputMap.has_action(str(action)):
				apply_binding(str(action), int(cfg.get_value("keys", action)))


func apply_binding(action: String, keycode: int) -> void:
	InputMap.action_erase_events(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode as Key
	InputMap.action_add_event(action, ev)


func save_binding(action: String, keycode: int) -> void:
	apply_binding(action, keycode)
	var cfg := ConfigFile.new()
	cfg.load("user://keybinds.cfg")
	cfg.set_value("keys", action, keycode)
	cfg.save("user://keybinds.cfg")


func clear_bindings() -> void:
	var cfg := ConfigFile.new()
	cfg.save("user://keybinds.cfg")   # wipe the file
	_setup_input()                    # back to factory defaults


func binding_key(action: String) -> String:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			return OS.get_keycode_string(ev.physical_keycode)
	return "?"


# ------------------------------------------------------------------ shell

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		settings["sens"] = cfg.get_value("opt", "sens", 0.0022)
		settings["vol"] = cfg.get_value("opt", "vol", 0.0)
		settings["sdfgi"] = cfg.get_value("opt", "sdfgi", true)
	AudioServer.set_bus_volume_db(0, settings["vol"])
	if env_ref != null:
		env_ref.sdfgi_enabled = settings["sdfgi"]


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("opt", "sens", settings["sens"])
	cfg.set_value("opt", "vol", settings["vol"])
	cfg.set_value("opt", "sdfgi", settings["sdfgi"])
	cfg.save("user://settings.cfg")


func _build_pause_menu() -> void:
	pause_layer = CanvasLayer.new()
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_layer.visible = false
	add_child(pause_layer)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.02, 0.04, 0.8)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(shade)

	var box := VBoxContainer.new()
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["Cascadia Mono", "Consolas",
									   "Lucida Console", "Courier New"])
	var th := Theme.new()
	th.default_font = sf
	box.theme = th
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-180, -170)
	box.custom_minimum_size = Vector2(360, 0)
	box.add_theme_constant_override("separation", 14)
	pause_layer.add_child(box)

	var title := Label.new()
	title.text = "— HOLDING PATTERN —"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.72, 0.2))
	box.add_child(title)

	var resume := Button.new()
	resume.text = "RESUME"
	resume.pressed.connect(_toggle_pause)
	box.add_child(resume)

	var sens_label := Label.new()
	sens_label.text = "MOUSE SENSITIVITY"
	box.add_child(sens_label)
	var sens_slider := HSlider.new()
	sens_slider.min_value = 0.0006
	sens_slider.max_value = 0.006
	sens_slider.step = 0.0002
	sens_slider.value = settings["sens"]
	sens_slider.value_changed.connect(func(v: float) -> void:
		settings["sens"] = v
		if player != null:
			player.sens = v
		_save_settings())
	box.add_child(sens_slider)

	var vol_label := Label.new()
	vol_label.text = "VOLUME"
	box.add_child(vol_label)
	var vol_slider := HSlider.new()
	vol_slider.min_value = -40.0
	vol_slider.max_value = 6.0
	vol_slider.step = 1.0
	vol_slider.value = settings["vol"]
	vol_slider.value_changed.connect(func(v: float) -> void:
		settings["vol"] = v
		AudioServer.set_bus_volume_db(0, v)
		_save_settings())
	box.add_child(vol_slider)

	var gi := CheckBox.new()
	gi.text = "GLOBAL ILLUMINATION (turn off if slow)"
	gi.button_pressed = settings["sdfgi"]
	gi.toggled.connect(func(on: bool) -> void:
		settings["sdfgi"] = on
		env_ref.sdfgi_enabled = on
		_save_settings())
	box.add_child(gi)

	var abort := Button.new()
	abort.text = "ABORT — RETURN TO THE VOID ANCHOR"
	abort.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().reload_current_scene())
	box.add_child(abort)


func _toggle_pause() -> void:
	if state != "playing" and not get_tree().paused:
		return
	get_tree().paused = not get_tree().paused
	pause_layer.visible = get_tree().paused
	if get_tree().paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		if state == "playing" or get_tree().paused:
			_toggle_pause()
	if state in ["gameover", "victory"] and Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
	# The crawl can be skipped by the impatient
	if state == "crawl" and ((event is InputEventKey and event.pressed)
			or (event is InputEventMouseButton and event.pressed)):
		_finish_crawl()


func _finish_crawl() -> void:
	if state != "crawl":
		return
	if crawl_root != null:
		crawl_root.queue_free()
		crawl_root = null
	deploy(_pending_deploy)


# ------------------------------------------------------------------ deploy

func deploy(cfg: Dictionary = {}) -> void:
	planet = PLANETS[cfg.get("planet", 0)]
	biome = planet["biome"]
	op = planet["ops"][cfg.get("op", 0)]
	waves_table = op["waves"]
	mission_type = op["mission"]
	_apply_op_environment()
	_build_terrain()
	var drop: Vector2 = cfg.get("drop", Vector2(4.3, 3.1))
	var recon: Array = cfg.get("recon", [])
	_spawn_speeder(drop)

	var rig: Dictionary = menu.RIGS[cfg.get("rig", 2)]
	var paint: Color = menu.PAINTS[cfg.get("paint", 0)]["color"]
	var visor: Color = menu.VISORS[cfg.get("visor", 0)]["color"]
	var weapon: String = menu.WEAPON_KEYS[cfg.get("weapon", 0)]
	var sidearm: String = menu.SIDEARM_KEYS[cfg.get("sidearm", 0)]
	var opts: Array = menu.SUIT_OPTS
	var grenade: String = menu.GRENADE_KEYS[cfg.get("grenade", 0)]
	pose_name = menu.POSES[cfg.get("pose", 0)]

	menu.queue_free()
	menu = null

	player = PlayerScript.new()
	player.main = self
	player.custom = {"rig": rig, "paint": paint, "visor": visor,
					 "weapon": weapon, "sidearm": sidearm,
					 "suit_visor": opts[cfg.get("suit_v", 0)],
					 "suit_tag": opts[cfg.get("suit_t", 0)],
					 "grenade": grenade,
					 "booster": cfg.get("booster", 0)}
	player.voice_idx = cfg.get("voice", 0)
	player.recruit = new_recruit(player.voice_idx)
	mission_limit = MISSION_LIMIT + (120.0 if cfg.get("booster", 0) == 3 else 0.0)
	add_child(player)
	player.global_position = Vector3(drop.x,
									 ground_height(drop.x, drop.y) + 1.2, drop.y)

	# The squad drops with you
	for i in range(2):
		_spawn_ally(i, player.global_position
					+ Vector3(2.5 * (1 if i == 0 else -1), 1.0, 2.5))

	strats = StratScript.new()
	strats.main = self
	add_child(strats)

	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = HudScript.new()
	hud.main = self
	canvas.add_child(hud)

	phase = "clear"
	extract_hold = 20.0
	upload = 0.0
	mission_time = 0.0
	anchor_retasked = false
	event_timer = randf_range(130.0, 200.0)
	env_timer = randf_range(80.0, 140.0)
	tremor_t = 0.0
	ion_t = 0.0
	psi_t = 0.0
	_spawn_vents(cfg.get("vents", []))
	_spawn_pois()
	match mission_type:
		"siphons":
			_spawn_siphons(recon)
			hud_msg_later("SHATTER THE CRYO-SIPHONS", Color(0.85, 0.5, 1.0))
		"uplink":
			_spawn_terminal(recon)
			hud_msg_later("REACH THE UPLINK TERMINAL", Color(0.85, 0.5, 1.0))
		"hunt":
			_spawn_boss(recon)
			hud_msg_later("HUNT THE SIEGE WALKER — SHOOT THE KNEES",
						  Color(1.0, 0.4, 0.3))
	_spawn_samples()
	wind_player.play()

	# The playable start: ride the Gantry Spike down instead of blinking in
	_start_drop()

	# Major Order bonus: a fulfilled order queues extra orbital budget
	if liberation.get_value("order", "reward", false):
		liberation.set_value("order", "reward", false)
		liberation.save("user://liberation.cfg")
		strats.uses["ORBITAL_LASER"] = 4
		hud_msg_later("MAJOR ORDER BONUS — ORBITAL LASER x4", Color(0.3, 1.0, 0.8))

	# The drop coordinates have consequences: land on the signal and the
	# Swarm meets you at the door; land dark and you get room to breathe.
	if not recon.is_empty():
		var near_obj := 1e9
		for pt in recon:
			near_obj = minf(near_obj, drop.distance_to(pt))
		if near_obj < 25.0:
			patrol_timer = 8.0
			hud_msg_later("HOT DROP — THEY SAW YOU COMING", Color(1.0, 0.3, 0.2))
			get_tree().create_timer(6.0).timeout.connect(func() -> void:
				if state == "playing" and player != null and player.alive:
					var a := randf() * TAU
					trigger_breach(player.global_position
								   + Vector3(cos(a) * 12.0, 0, sin(a) * 12.0)))
		elif near_obj > 60.0:
			patrol_timer = 32.0
			hud_msg_later("QUIET SECTOR — UNMONITORED INSERTION",
						  Color(0.5, 1.0, 0.55))


func hud_msg_later(text: String, color: Color) -> void:
	get_tree().create_timer(1.5).timeout.connect(func() -> void:
		if hud != null:
			hud.push_msg(text, color))


func _spawn_ally(slot: int, pos: Vector3) -> void:
	var a: CharacterBody3D = AllyScript.new()
	a.main = self
	a.slot = slot
	add_child(a)
	a.global_position = pos
	if hud != null:
		hud.push_msg("%s HAS YOUR FLANK" % a.callsign, Color(0.5, 0.85, 1.0))


func on_ally_died(a: Node3D) -> void:
	if hud != null:
		hud.push_msg("%s IS DOWN — REINFORCEMENT INBOUND" % a.callsign,
					 Color(1.0, 0.4, 0.3))
	reinforce_timer = 8.0


func _spawn_terminal(recon: Array = []) -> void:
	var pos: Vector3
	if recon.size() > 0:
		pos = Vector3(recon[0].x, 0, recon[0].y)
	else:
		var ang := randf() * TAU
		pos = Vector3(cos(ang) * 55.0, 0, sin(ang) * 55.0)
	pos.y = ground_height(pos.x, pos.z)
	terminal = Node3D.new()
	add_child(terminal)
	terminal.global_position = pos
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.14, 0.15, 0.18)
	dark.metallic = 0.6
	dark.roughness = 0.35
	var console := MeshInstance3D.new()
	var cb := BoxMesh.new()
	cb.size = Vector3(1.4, 1.2, 0.7)
	console.mesh = cb
	console.material_override = dark
	console.position = Vector3(0, 0.6, 0)
	terminal.add_child(console)
	var screen := MeshInstance3D.new()
	var sb := BoxMesh.new()
	sb.size = Vector3(1.1, 0.6, 0.06)
	screen.mesh = sb
	var sm := StandardMaterial3D.new()
	sm.emission_enabled = true
	sm.emission = Color(0.3, 0.9, 0.6)
	sm.emission_energy_multiplier = 1.6
	sm.albedo_color = Color(0.05, 0.2, 0.12)
	screen.material_override = sm
	screen.position = Vector3(0, 1.35, -0.2)
	screen.rotation_degrees = Vector3(-18, 0, 0)
	terminal.add_child(screen)
	var tl := OmniLight3D.new()
	tl.light_color = Color(0.3, 0.9, 0.6)
	tl.light_energy = 2.0
	tl.omni_range = 8.0
	tl.position = Vector3(0, 2, 0)
	terminal.add_child(tl)


func _spawn_boss(recon: Array = []) -> void:
	var pos: Vector3
	if recon.size() > 0:
		pos = Vector3(recon[0].x, 0, recon[0].y)
	else:
		var ang := randf() * TAU
		pos = Vector3(cos(ang) * 70.0, 0, sin(ang) * 70.0)
	boss = SiegeScript.new()
	boss.main = self
	add_child(boss)
	boss.global_position = Vector3(pos.x, ground_height(pos.x, pos.z) + 2.0, pos.z)


func on_boss_killed() -> void:
	boss = null
	score += 5000
	if hud != null:
		hud.push_msg("SIEGE WALKER DESTROYED", Color(1.0, 0.72, 0.2))
	if mission_type == "hunt" and phase == "clear":
		_light_beacon()


func _spawn_samples() -> void:
	# Higher threat tiers carry richer sample fields — risk pays
	sample_nodes.clear()
	var count := clampi(3 + int(op.get("tier", 5)) / 2, 4, 8)
	for i in range(count):
		var ang := randf() * TAU
		var dist := randf_range(30.0, 90.0)
		var node := Node3D.new()
		add_child(node)
		var px := cos(ang) * dist
		var pz := sin(ang) * dist
		node.global_position = Vector3(px, ground_height(px, pz), pz)
		var m := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.12
		cyl.bottom_radius = 0.12
		cyl.height = 0.5
		m.mesh = cyl
		var mat := StandardMaterial3D.new()
		mat.emission_enabled = true
		mat.emission = Color(0.3, 1.0, 0.8)
		mat.emission_energy_multiplier = 2.4
		mat.albedo_color = Color(0.1, 0.3, 0.25)
		m.material_override = mat
		m.position = Vector3(0, 0.4, 0)
		m.rotation_degrees = Vector3(0, 0, 22)
		node.add_child(m)
		var l := OmniLight3D.new()
		l.light_color = Color(0.3, 1.0, 0.8)
		l.light_energy = 1.2
		l.omni_range = 4.0
		l.position = Vector3(0, 0.8, 0)
		node.add_child(l)
		sample_nodes.append(node)


func _spawn_siphons(recon: Array = []) -> void:
	siphons.clear()
	for i in range(3):
		var sx: float
		var sz: float
		if recon.size() == 3:
			sx = recon[i].x
			sz = recon[i].y
		else:
			var ang := i * TAU / 3.0 + randf_range(-0.4, 0.4)
			var dist := randf_range(45.0, 75.0)
			sx = cos(ang) * dist
			sz = sin(ang) * dist
		var s: StaticBody3D = SiphonScript.new()
		s.main = self
		add_child(s)
		s.global_position = Vector3(sx, ground_height(sx, sz), sz)
		siphons.append(s)


func on_siphon_destroyed(s: Node3D) -> void:
	siphons.erase(s)
	score += 500
	sfx("boom", -4.0)
	if siphons.is_empty():
		_light_beacon()
	else:
		hud.push_msg("SIPHON DOWN — %d REMAIN" % siphons.size(),
					 Color(0.85, 0.5, 1.0))


func _light_beacon() -> void:
	phase = "extract"
	var ang := randf() * TAU
	beacon_pos = Vector3(cos(ang) * 55.0, 0, sin(ang) * 55.0)
	beacon_pos.y = ground_height(beacon_pos.x, beacon_pos.z)
	beacon = Node3D.new()
	add_child(beacon)
	beacon.global_position = beacon_pos
	# A pillar of hard light reaching for the Void Anchor
	var pillar := MeshInstance3D.new()
	var pc := CylinderMesh.new()
	pc.top_radius = 0.8
	pc.bottom_radius = 1.6
	pc.height = 160.0
	pillar.mesh = pc
	var pmat := StandardMaterial3D.new()
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmat.albedo_color = Color(0.4, 0.8, 1.0, 0.28)
	pmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	pillar.material_override = pmat
	pillar.position = Vector3(0, 80, 0)
	beacon.add_child(pillar)
	var ring := MeshInstance3D.new()
	var rt := TorusMesh.new()
	rt.inner_radius = 5.4
	rt.outer_radius = 6.0
	ring.mesh = rt
	var rm := StandardMaterial3D.new()
	rm.emission_enabled = true
	rm.emission = Color(0.4, 0.8, 1.0)
	rm.emission_energy_multiplier = 1.6
	rm.albedo_color = Color(0.1, 0.2, 0.3)
	ring.material_override = rm
	ring.position = Vector3(0, 0.4, 0)
	beacon.add_child(ring)
	var bl := OmniLight3D.new()
	bl.light_color = Color(0.4, 0.8, 1.0)
	bl.light_energy = 4.0
	bl.light_volumetric_fog_energy = 3.0   # the pillar owns the fog around it
	bl.omni_range = 20.0
	bl.position = Vector3(0, 6, 0)
	beacon.add_child(bl)
	sfx("breach", -6.0)
	hud.push_msg("EXTRACTION BEACON LIT — RUN, BREACHER", Color(0.4, 0.8, 1.0))


func _begin_leaving() -> void:
	phase = "leaving"
	hud.push_msg("THE VOID ANCHOR ANSWERS", Color(0.4, 0.8, 1.0))
	bark("extract")
	# The recovery dropship descends onto the beacon
	dropship = Node3D.new()
	add_child(dropship)
	dropship.global_position = beacon_pos + Vector3(0, 120, 0)
	var hull := MeshInstance3D.new()
	var hb := BoxMesh.new()
	hb.size = Vector3(6.0, 2.2, 9.0)
	hull.mesh = hb
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color(0.35, 0.38, 0.45)
	hm.metallic = 0.7
	hm.roughness = 0.35
	hull.material_override = hm
	dropship.add_child(hull)
	for side in [-1.0, 1.0]:
		var wing := MeshInstance3D.new()
		var wb := BoxMesh.new()
		wb.size = Vector3(3.4, 0.4, 4.0)
		wing.mesh = wb
		wing.material_override = hm
		wing.position = Vector3(4.4 * side, 0.4, 0.5)
		dropship.add_child(wing)
		var glow := OmniLight3D.new()
		glow.light_color = Color(0.5, 0.8, 1.0)
		glow.light_energy = 6.0
		glow.omni_range = 12.0
		glow.position = Vector3(4.4 * side, -1.0, 0.5)
		dropship.add_child(glow)
	var tw := create_tween()
	tw.tween_property(dropship, "global_position",
					  beacon_pos + Vector3(0, 3.5, 0), 4.5) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.0)
	tw.tween_callback(func() -> void:
		state = "victory"
		var key := str(op["name"])
		var cur: float = liberation.get_value("war", key, 0.0)
		var gain := 3.0 + float(op.get("tier", 5))   # higher tiers move the war
		if player != null:
			gain += player.samples * 2.0     # samples pay off ONLY if you live
			score += player.samples * 250
		# secondary objectives pay out at extraction
		if vents.is_empty():
			gain += 2.0
		if cache_done:
			gain += 2.0
		liberation.set_value("war", key, minf(100.0, cur + gain))
		# Major Order check: fulfilled orders queue a reward for the next drop
		if str(liberation.get_value("order", "op", "")) == key \
				and float(liberation.get_value("war", key, 0.0)) \
					>= float(liberation.get_value("order", "target", 100.0)) \
				and float(liberation.get_value("order", "deadline", 0.0)) \
					> Time.get_unix_time_from_system():
			liberation.set_value("order", "reward", true)
			liberation.set_value("order", "deadline", 0.0)
			if hud != null:
				hud.push_msg("MAJOR ORDER FULFILLED — THE DIRECTORATE IS PLEASED",
							 Color(0.3, 1.0, 0.8))
		liberation.save("user://liberation.cfg"))


# ------------------------------------------------------------------ world

func _build_environment() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky_mat := ProceduralSkyMaterial.new()
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.sky = sky

	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_hdr_threshold = 1.3
	env.glow_intensity = 0.6
	env.ssao_enabled = true
	env.ssao_intensity = 2.5
	env.sdfgi_enabled = true                      # realtime GI: snow bounce light
	env.ssr_enabled = true                        # icy sheen picks up the sky
	env.ssr_max_steps = 32
	env.fog_enabled = true
	env.fog_aerial_perspective = 0.6              # distance melts into the sky
	env.volumetric_fog_enabled = true
	# Cinematic grade: a touch of contrast and saturation, HD2-style
	env.adjustment_enabled = true
	env.adjustment_brightness = 1.02
	env.adjustment_contrast = 1.12
	env.adjustment_saturation = 1.08

	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	env_ref = env
	env.sdfgi_enabled = settings["sdfgi"]

	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.light_angular_distance = 0.7              # soft, realistic shadow edges
	sun.shadow_blur = 1.2
	sun.directional_shadow_max_distance = 180.0   # long dramatic terrain shadows
	add_child(sun)
	_set_menu_lighting()


func _set_menu_lighting() -> void:
	# The launch bay is a dark interior: kill the sun and sky ambient,
	# let the holograms do the lighting
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.04, 0.055, 0.08)
	env.ambient_light_energy = 1.0
	env.fog_enabled = false
	env.volumetric_fog_enabled = false
	sun.light_energy = 0.1
	var sky_mat: ProceduralSkyMaterial = env.sky.sky_material
	sky_mat.sky_top_color = Color(0.01, 0.015, 0.03)
	sky_mat.sky_horizon_color = Color(0.03, 0.05, 0.08)


func _apply_op_environment() -> void:
	env.ambient_light_source = Environment.AMBIENT_SOURCE_BG
	env.fog_enabled = true
	env.volumetric_fog_enabled = true
	var sky_mat: ProceduralSkyMaterial = env.sky.sky_material
	sky_mat.sky_top_color = op["sky_top"]
	sky_mat.sky_horizon_color = op["sky_horizon"]
	sky_mat.ground_bottom_color = op["sky_horizon"] * 0.85
	sky_mat.ground_horizon_color = op["sky_horizon"]
	env.fog_light_color = op["sky_horizon"] * 0.95
	env.fog_density = op["fog"]
	env.volumetric_fog_density = op["vfog"]
	# the atmospheric soup: each world's air catches light in its own color
	env.volumetric_fog_albedo = planet.get("vfog_color", Color(0.85, 0.88, 0.93))
	# god rays: the sun slices through the fog in visible shafts
	sun.light_volumetric_fog_energy = 3.0
	sun.rotation_degrees = Vector3(op["sun_deg"], 140, 0)
	sun.light_color = op["sun_color"]
	sun.light_energy = op["sun_energy"]


func ground_height(x: float, z: float) -> float:
	# Natural terrain in three octaves: smooth rolling dunes, soft interior
	# highlands, and a ring of climbable mountains rising toward the edge.
	# Flattened around the drop pad.
	var h: float = terrain_noise.get_noise_2d(x, z) * 6.0
	h += terrain_noise.get_noise_2d(x * 2.3 + 100.0, z * 2.3) * 0.7
	var hill := terrain_noise.get_noise_2d(x * 0.45 + 900.0, z * 0.45) * 0.5 + 0.5
	h += hill * hill * 9.0
	var d := Vector2(x, z).length()
	var ridge := terrain_noise.get_noise_2d(x * 0.35 + 500.0, z * 0.35) * 0.5 + 0.5
	h += smoothstep(100.0, 175.0, d) * (10.0 + ridge * 26.0)
	return h * smoothstep(6.0, 42.0, d)


func _biome_palette() -> Dictionary:
	# Every biome-dependent surface colour in one place, so a new world only
	# needs a palette entry rather than edits scattered through _build_terrain.
	match biome:
		"ash":
			return {
				"mire": Color(0.09, 0.08, 0.075, 0.95),
				"spire": Color(0.09, 0.08, 0.10), "spire_rough": 0.08, "spire_metal": 0.3,
				"rock": Color(0.20, 0.17, 0.16),
				"shrub": Color(0.16, 0.12, 0.10),
				"pebble": Color(0.24, 0.20, 0.18),
				"crack": Color(0.06, 0.055, 0.05),
				"cave": Color(0.16, 0.14, 0.13),
				"mtn0": Color(0.16, 0.13, 0.13), "mtn1": Color(0.22, 0.18, 0.17),
				"cap": Color(0.45, 0.15, 0.08), "cap_glow": true,
				"cap_emit": Color(1.0, 0.35, 0.1),
				"ground": Color(0.17, 0.15, 0.14), "ground_rough": 0.92,
			}
		"swamp":
			return {
				"mire": Color(0.05, 0.11, 0.09, 0.95),        # black bog water
				"spire": Color(0.24, 0.34, 0.26), "spire_rough": 0.55, "spire_metal": 0.0,
				"rock": Color(0.19, 0.25, 0.21),              # mossed boulders
				"shrub": Color(0.17, 0.33, 0.20),             # reeds and sedge
				"pebble": Color(0.15, 0.21, 0.17),
				"crack": Color(0.04, 0.09, 0.07),             # root channels
				"cave": Color(0.17, 0.23, 0.19),
				"mtn0": Color(0.16, 0.24, 0.21), "mtn1": Color(0.21, 0.30, 0.26),
				"cap": Color(0.30, 0.42, 0.36), "cap_glow": false,
				"cap_emit": Color(0.2, 1.0, 0.7),
				"ground": Color(0.13, 0.21, 0.17), "ground_rough": 0.55,
			}
		_:
			return {
				"mire": Color(0.99, 1.0, 1.0, 0.95),
				"spire": Color(0.82, 0.90, 0.97), "spire_rough": 0.06, "spire_metal": 0.15,
				"rock": Color(0.42, 0.47, 0.55),
				"shrub": Color(0.33, 0.40, 0.38),
				"pebble": Color(0.55, 0.60, 0.68),
				"crack": Color(0.30, 0.36, 0.46),
				"cave": Color(0.34, 0.38, 0.45),
				"mtn0": Color(0.50, 0.55, 0.65), "mtn1": Color(0.58, 0.62, 0.72),
				"cap": Color(0.92, 0.94, 0.98), "cap_glow": false,
				"cap_emit": Color(1.0, 1.0, 1.0),
				"ground": Color(0.90, 0.93, 0.97), "ground_rough": 0.8,
			}


func _build_terrain() -> void:
	terrain_noise = FastNoiseLite.new()
	terrain_noise.seed = op["seed"]
	var pal := _biome_palette()
	terrain_noise.frequency = 0.009
	terrain_noise.fractal_octaves = 4

	# Displaced heightmap ground with real trimesh collision
	var plane := PlaneMesh.new()
	plane.size = Vector2(440, 440)
	plane.subdivide_width = 150
	plane.subdivide_depth = 150
	var arrays: Array = plane.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in range(verts.size()):
		var v := verts[i]
		v.y = ground_height(v.x, v.z)
		verts[i] = v
	arrays[Mesh.ARRAY_VERTEX] = verts
	var raw := ArrayMesh.new()
	raw.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var st := SurfaceTool.new()
	st.create_from(raw, 0)
	st.generate_normals()
	var terrain_mesh := st.commit()

	var ground := StaticBody3D.new()
	ground.name = "TerrainBody"
	var gmesh := MeshInstance3D.new()
	gmesh.mesh = terrain_mesh
	gmesh.material_override = _snow_material()
	ground.add_child(gmesh)
	# HeightMapShape3D: the purpose-built terrain collider (1m sample grid)
	var cs := CollisionShape3D.new()
	var hm := HeightMapShape3D.new()
	var W := 441
	hm.map_width = W
	hm.map_depth = W
	var data := PackedFloat32Array()
	data.resize(W * W)
	var half := (W - 1) / 2.0
	for iz in range(W):
		var row := iz * W
		for ix in range(W):
			data[row + ix] = ground_height(ix - half, iz - half)
	hm.map_data = data
	cs.shape = hm
	ground.add_child(cs)
	add_child(ground)

	# Magma pools: Cinderfall's ground fights back
	hazards.clear()
	if biome == "ash":
		for i in range(9):
			var hang := randf() * TAU
			var hdist := randf_range(18.0, 110.0)
			var hp := Vector3(cos(hang) * hdist, 0, sin(hang) * hdist)
			hp.y = ground_height(hp.x, hp.z) + 0.06
			var pr := randf_range(2.2, 4.5)
			var pool := _soft_disc(pr, Color(1.0, 0.38, 0.09), 2.4)
			add_child(pool)
			pool.global_position = hp
			var pl := OmniLight3D.new()
			pl.light_color = Color(1.0, 0.45, 0.15)
			pl.light_energy = 3.0
			pl.omni_range = pr * 3.0
			add_child(pl)
			pl.global_position = hp + Vector3(0, 1.5, 0)
			hazards.append([hp, pr])
	elif biome == "swamp":
		# Caustic acid pools: the Undergrowth's ground digests trespassers
		for i in range(8):
			var hang := randf() * TAU
			var hdist := randf_range(16.0, 115.0)
			var hp := Vector3(cos(hang) * hdist, 0, sin(hang) * hdist)
			hp.y = ground_height(hp.x, hp.z) + 0.06
			var pr := randf_range(2.4, 5.0)
			var pool := _soft_disc(pr, Color(0.42, 1.0, 0.2), 1.8)
			add_child(pool)
			pool.global_position = hp
			var pl := OmniLight3D.new()
			pl.light_color = Color(0.4, 1.0, 0.3)
			pl.light_energy = 2.2
			pl.omni_range = pr * 3.0
			add_child(pl)
			pl.global_position = hp + Vector3(0, 1.2, 0)
			hazards.append([hp, pr])

	# Deep drifts / ash mires: the terrain itself slows you to a wade.
	# Feathered edges so the drifts read as part of the ground.
	mires.clear()
	var mire_col: Color = pal.mire
	for i in range(10):
		var mang := randf() * TAU
		var mdist := randf_range(18.0, 130.0)
		var mp := Vector3(cos(mang) * mdist, 0, sin(mang) * mdist)
		mp.y = ground_height(mp.x, mp.z) + 0.05
		var mr := randf_range(4.0, 8.5)
		var pool := _soft_disc(mr, mire_col, 0.0)
		add_child(pool)
		pool.global_position = mp
		mires.append([mp, mr])

	# Jagged spires: blue ice on the Reach, black obsidian on Cinderfall
	var ice := StandardMaterial3D.new()
	ice.albedo_color = pal.spire
	ice.roughness = pal.spire_rough
	ice.metallic = pal.spire_metal
	for i in range(46):
		var ang := randf() * TAU
		var dist := randf_range(16.0, 150.0)
		var pos := Vector3(cos(ang) * dist, 0, sin(ang) * dist)
		pos.y = ground_height(pos.x, pos.z)
		_spawn_spire(pos, ice)

	# Rounded boulders half-buried in drifts (basalt blocks on Cinderfall)
	var rock := StandardMaterial3D.new()
	rock.albedo_color = pal.rock
	rock.roughness = 0.95
	for i in range(38):
		var ang := randf() * TAU
		var dist := randf_range(10.0, 160.0)
		var body := StaticBody3D.new()
		var m := MeshInstance3D.new()
		var sm := SphereMesh.new()
		var r := randf_range(0.9, 2.6)
		sm.radius = r
		sm.height = r * randf_range(1.1, 1.6)
		m.mesh = sm
		m.material_override = rock
		body.add_child(m)
		var bs := CollisionShape3D.new()
		var sph := SphereShape3D.new()
		sph.radius = r * 0.9
		bs.shape = sph
		body.add_child(bs)
		var px := cos(ang) * dist
		var pz := sin(ang) * dist
		body.position = Vector3(px, ground_height(px, pz) - r * 0.35, pz)
		body.rotation_degrees = Vector3(randf_range(-25, 25), randf_range(0, 360),
										randf_range(-25, 25))
		add_child(body)

	# Frozen scrub via MultiMesh (dense ground foliage, one draw call)
	var shrub_mesh := CylinderMesh.new()
	shrub_mesh.top_radius = 0.0
	shrub_mesh.bottom_radius = 0.22
	shrub_mesh.height = 0.55
	var shrub_mat := StandardMaterial3D.new()
	shrub_mat.albedo_color = pal.shrub   # burned stumps / frozen scrub / reeds
	shrub_mat.roughness = 1.0
	shrub_mesh.material = shrub_mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = shrub_mesh
	mm.instance_count = 500
	for i in range(500):
		var px := randf_range(-160.0, 160.0)
		var pz := randf_range(-160.0, 160.0)
		var tr := Transform3D(Basis(Vector3.UP, randf() * TAU).scaled(
			Vector3.ONE * randf_range(0.6, 1.8)),
			Vector3(px, ground_height(px, pz) + 0.2, pz))
		mm.set_instance_transform(i, tr)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	add_child(mmi)

	# Detritus scatter: pebbles and cracked-ground slabs break up the flats
	var peb_mesh := SphereMesh.new()
	peb_mesh.radius = 0.09
	peb_mesh.height = 0.13
	peb_mesh.radial_segments = 6
	peb_mesh.rings = 3
	var peb_mat := StandardMaterial3D.new()
	peb_mat.albedo_color = pal.pebble
	peb_mat.roughness = 0.95
	peb_mesh.material = peb_mat
	var pmm := MultiMesh.new()
	pmm.transform_format = MultiMesh.TRANSFORM_3D
	pmm.mesh = peb_mesh
	pmm.instance_count = 700
	for i in range(700):
		var px := randf_range(-150.0, 150.0)
		var pz := randf_range(-150.0, 150.0)
		var basis := Basis(Vector3.UP, randf() * TAU).scaled(
			Vector3(randf_range(0.5, 2.4), randf_range(0.35, 1.2),
					randf_range(0.5, 2.4)))
		pmm.set_instance_transform(i, Transform3D(basis,
			Vector3(px, ground_height(px, pz) + 0.02, pz)))
	var pmi := MultiMeshInstance3D.new()
	pmi.multimesh = pmm
	add_child(pmi)

	var crack_mesh := BoxMesh.new()
	crack_mesh.size = Vector3(1.6, 0.02, 0.12)
	var crack_mat := StandardMaterial3D.new()
	crack_mat.albedo_color = pal.crack
	crack_mat.roughness = 1.0
	crack_mesh.material = crack_mat
	var cmm := MultiMesh.new()
	cmm.transform_format = MultiMesh.TRANSFORM_3D
	cmm.mesh = crack_mesh
	cmm.instance_count = 90
	for i in range(90):
		var cx := randf_range(-140.0, 140.0)
		var cz := randf_range(-140.0, 140.0)
		var cb := Basis(Vector3.UP, randf() * TAU).scaled(
			Vector3(randf_range(0.6, 2.2), 1.0, randf_range(0.7, 1.6)))
		cmm.set_instance_transform(i, Transform3D(cb,
			Vector3(cx, ground_height(cx, cz) + 0.015, cz)))
	var cmi := MultiMeshInstance3D.new()
	cmi.multimesh = cmm
	add_child(cmi)

	# Cave shelters: hollow rock overhangs you can actually stand inside —
	# cover from rocket salvos, shade from the sun shafts
	var cave_rock := StandardMaterial3D.new()
	cave_rock.albedo_color = pal.cave
	cave_rock.roughness = 0.95
	for i in range(4):
		var cang := randf() * TAU
		var cdist := randf_range(40.0, 115.0)
		var cpos := Vector3(cos(cang) * cdist, 0, sin(cang) * cdist)
		cpos.y = ground_height(cpos.x, cpos.z)
		_spawn_cave(cpos, cave_rock)

	# Two rings of snow-capped mountains for the horizon
	for ring in range(2):
		var count := 14 + ring * 6
		for i in range(count):
			var ang := i * TAU / count + randf_range(-0.12, 0.12) + ring * 0.2
			var dist := randf_range(270.0, 340.0) + ring * 120.0
			var base := MeshInstance3D.new()
			var peak := CylinderMesh.new()
			peak.top_radius = 0.0
			peak.bottom_radius = randf_range(45, 100)
			peak.height = randf_range(60, 150) + ring * 40.0
			base.mesh = peak
			var mmat := StandardMaterial3D.new()
			mmat.albedo_color = pal.mtn0 if ring == 0 else pal.mtn1
			mmat.roughness = 1.0
			base.material_override = mmat
			base.position = Vector3(cos(ang) * dist, peak.height * 0.30, sin(ang) * dist)
			add_child(base)
			# snow caps on the Reach; ember-lit crater rims on Cinderfall
			var cap := MeshInstance3D.new()
			var capm := CylinderMesh.new()
			capm.top_radius = 0.0
			capm.bottom_radius = peak.bottom_radius * 0.35
			capm.height = peak.height * 0.35
			cap.mesh = capm
			var capmat := StandardMaterial3D.new()
			capmat.albedo_color = pal.cap
			if pal.cap_glow:
				capmat.emission_enabled = true
				capmat.emission = pal.cap_emit
				capmat.emission_energy_multiplier = 0.5
			cap.material_override = capmat
			cap.position = base.position + Vector3(0, peak.height * 0.325, 0)
			add_child(cap)

	# Snow flurries follow the player
	snow = GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(35, 14, 35)
	pm.direction = Vector3(0.3, -1, 0)
	pm.spread = 20.0
	pm.gravity = Vector3(1.2 if op["snow"] > 1500 else 0.6, -1.8, 0)
	pm.initial_velocity_min = 0.8
	pm.initial_velocity_max = 3.2 if op["snow"] > 1500 else 2.4
	pm.scale_min = 0.4
	pm.scale_max = 1.0
	snow.process_material = pm
	snow.amount = op["snow"]
	snow.lifetime = 9.0
	var flake := QuadMesh.new()
	flake.size = Vector2(0.06, 0.06)
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if biome == "ash":
		fm.albedo_color = Color(1.0, 0.55, 0.2)      # drifting embers
		fm.emission_enabled = true
		fm.emission = Color(1.0, 0.45, 0.15)
		fm.emission_energy_multiplier = 2.0
		pm.gravity = Vector3(0.4, -0.4, 0.2)          # embers hang and drift
		pm.initial_velocity_min = 0.3
		pm.initial_velocity_max = 1.2
	elif biome == "swamp":
		fm.albedo_color = Color(0.6, 1.0, 0.7)        # bioluminescent spores
		fm.emission_enabled = true
		fm.emission = Color(0.4, 1.0, 0.6)
		fm.emission_energy_multiplier = 1.6
		flake.size = Vector2(0.09, 0.09)
		pm.gravity = Vector3(0.2, 0.12, 0.1)          # spores rise and swirl
		pm.initial_velocity_min = 0.15
		pm.initial_velocity_max = 0.8
	else:
		fm.albedo_color = Color(0.95, 0.97, 1.0)
	fm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	flake.material = fm
	snow.draw_pass_1 = flake
	add_child(snow)

	# Spindrift: wind-blown snow streaking low across the ground
	spindrift = GPUParticles3D.new()
	var sm := ParticleProcessMaterial.new()
	sm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	sm.emission_box_extents = Vector3(40, 0.6, 40)
	sm.direction = Vector3(1, 0, 0.25)
	sm.spread = 8.0
	sm.gravity = Vector3(0, -0.3, 0)
	sm.initial_velocity_min = 7.0
	sm.initial_velocity_max = 14.0
	sm.particle_flag_align_y = true   # streaks ride their velocity vector
	spindrift.process_material = sm
	spindrift.amount = int(op["snow"] / 4.0)
	spindrift.lifetime = 2.6
	var streak := QuadMesh.new()
	streak.size = Vector2(0.04, 0.9)   # long axis rides the velocity
	var stm := StandardMaterial3D.new()
	stm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	stm.albedo_color = Color(0.95, 0.97, 1.0, 0.30)
	stm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	stm.cull_mode = BaseMaterial3D.CULL_DISABLED   # visible from both sides
	streak.material = stm
	spindrift.draw_pass_1 = streak
	add_child(spindrift)


func _snow_material() -> StandardMaterial3D:
	var gm := StandardMaterial3D.new()
	var pal := _biome_palette()
	gm.albedo_color = pal.ground
	gm.roughness = pal.ground_rough
	var alb := NoiseTexture2D.new()
	var fa := FastNoiseLite.new()
	fa.frequency = 0.05
	alb.noise = fa
	alb.seamless = true
	gm.albedo_texture = alb            # subtle tonal variation in the drifts
	var rough_noise := NoiseTexture2D.new()
	var fn := FastNoiseLite.new()
	fn.frequency = 0.03
	rough_noise.noise = fn
	rough_noise.seamless = true
	gm.roughness_texture = rough_noise
	var norm_noise := NoiseTexture2D.new()
	var fn2 := FastNoiseLite.new()
	fn2.frequency = 0.12
	norm_noise.noise = fn2
	norm_noise.seamless = true
	norm_noise.as_normal_map = true
	gm.normal_enabled = true
	gm.normal_texture = norm_noise
	gm.normal_scale = 1.1                  # the drifts have real physical grain
	gm.uv1_triplanar = true
	gm.uv1_scale = Vector3(0.06, 0.06, 0.06)
	return gm


func _spawn_cave(pos: Vector3, rock: StandardMaterial3D) -> void:
	# A hollow overhang: two lean walls, a slab roof, a closed back, and a
	# rubble skin so it reads as geology instead of architecture
	var body := StaticBody3D.new()
	var parts := [
		[Vector3(1.4, 4.2, 6.5), Vector3(-2.7, 1.7, 0), Vector3(0, 0, 14)],
		[Vector3(1.4, 4.2, 6.5), Vector3(2.7, 1.7, 0), Vector3(0, 0, -14)],
		[Vector3(6.8, 1.4, 6.5), Vector3(0, 3.9, 0), Vector3(4, 0, 0)],
		[Vector3(6.0, 4.0, 1.4), Vector3(0, 1.6, 3.2), Vector3(-8, 0, 0)],
	]
	for prt in parts:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = prt[0]
		m.mesh = bm
		m.material_override = rock
		m.position = prt[1]
		m.rotation_degrees = prt[2]
		body.add_child(m)
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = prt[0]
		cs.shape = bs
		cs.position = prt[1]
		cs.rotation_degrees = prt[2]
		body.add_child(cs)
	# rubble skin: prisms piled over the shell to break the box silhouette
	for i in range(7):
		var rub := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(randf_range(1.5, 3.2), randf_range(1.2, 2.6),
						  randf_range(1.5, 3.2))
		rub.mesh = pm
		rub.material_override = rock
		rub.position = Vector3(randf_range(-3.0, 3.0), randf_range(3.6, 5.0),
							   randf_range(-2.0, 3.0))
		rub.rotation_degrees = Vector3(randf_range(-25, 25), randf_range(0, 360),
									   randf_range(-25, 25))
		body.add_child(rub)
	body.position = pos
	body.rotation_degrees = Vector3(0, randf_range(0, 360), 0)
	add_child(body)


func _spawn_spire(pos: Vector3, mat: StandardMaterial3D) -> void:
	var body := StaticBody3D.new()
	var cluster := randi_range(1, 3)
	for i in range(cluster):
		var m := MeshInstance3D.new()
		var prism := PrismMesh.new()
		var w := randf_range(1.2, 3.4)
		var h := randf_range(6.0, 22.0)
		prism.size = Vector3(w, h, w)
		m.mesh = prism
		m.material_override = mat
		m.position = Vector3(randf_range(-1.5, 1.5), h * 0.42, randf_range(-1.5, 1.5))
		m.rotation_degrees = Vector3(randf_range(-9, 9), randf_range(0, 360),
									 randf_range(-9, 9))
		body.add_child(m)
	var cs := CollisionShape3D.new()
	var cb := BoxShape3D.new()
	cb.size = Vector3(2.4, 8.0, 2.4)
	cs.shape = cb
	cs.position = Vector3(0, 4.0, 0)
	body.add_child(cs)
	body.position = pos
	add_child(body)


# ------------------------------------------------------------------ waves

func pressure() -> float:
	# Procedural friction: +25% spawn pressure per 4 minutes on the clock,
	# doubled once the mission window has closed
	var p := 1.0 + mission_time / 240.0 * 0.25
	if anchor_retasked:
		p *= 2.0
	return minf(p, 3.0)


func _directorate_event() -> void:
	# The single-player Joel: an unseen Game Master nudging the war
	match randi() % 3:
		0:
			hud.push_msg("DIRECTORATE NOTICE: SWARM PUSH DETECTED",
						 Color(1.0, 0.5, 0.2))
			for i in range(6):
				trickle.append("tick")
			wave_active = true
		1:
			hud.push_msg("DIRECTORATE GRANT: ORBITAL WINDOW — COOLDOWNS WAIVED",
						 Color(0.3, 1.0, 0.8))
			for k in strats.cooldowns:
				strats.cooldowns[k] = 0.0
		2:
			hud.push_msg("SUPPLY AUDIT PASSED — CRATE INBOUND", Color(0.3, 0.7, 1.0))
			if player != null and player.alive:
				var a := randf() * TAU
				var pos := player.global_position + Vector3(cos(a) * 7.0, 0, sin(a) * 7.0)
				strats._drop_pod("AMMO_POD", Vector3(pos.x, 0, pos.z))


func _soft_disc(radius: float, core: Color, glow_energy: float) -> MeshInstance3D:
	# A ground patch with a feathered rim — pools and drifts blend into the
	# terrain instead of sitting on it like coasters
	var m := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(radius * 2.4, radius * 2.4)
	m.mesh = pm
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.9),
									Color(1, 1, 1, 0)])
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(0.5, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = core
	mat.albedo_texture = gt
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if glow_energy > 0.0:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.emission = Color(core.r, core.g, core.b)
		mat.emission_energy_multiplier = glow_energy
	mat.roughness = 0.35
	m.material_override = mat
	m.scale = Vector3(randf_range(0.85, 1.35), 1.0, randf_range(0.85, 1.35))
	m.rotation.y = randf() * TAU
	return m


func in_mire(p: Vector3) -> bool:
	for m in mires:
		var flat: Vector3 = p - m[0]
		flat.y = 0.0
		if flat.length() < m[1]:
			return true
	return false


func _spawn_pois() -> void:
	# Crash sites: minor loot, found by physical scouting (or the radar tower)
	pois.clear()
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.22, 0.22, 0.25)
	dark.metallic = 0.6
	dark.roughness = 0.5
	for i in range(3):
		var ang := randf() * TAU
		var dist := randf_range(35.0, 125.0)
		var pos := Vector3(cos(ang) * dist, 0, sin(ang) * dist)
		pos.y = ground_height(pos.x, pos.z)
		var site := Node3D.new()
		add_child(site)
		site.global_position = pos
		var hull := MeshInstance3D.new()
		var hb := BoxMesh.new()
		hb.size = Vector3(1.2, 1.0, 3.0)
		hull.mesh = hb
		hull.material_override = dark
		hull.position = Vector3(0, 0.4, 0)
		hull.rotation_degrees = Vector3(randf_range(-20, 20), randf_range(0, 360), 24)
		site.add_child(hull)
		var can := MeshInstance3D.new()
		var cc := CylinderMesh.new()
		cc.top_radius = 0.16
		cc.bottom_radius = 0.16
		cc.height = 0.5
		can.mesh = cc
		var cm := StandardMaterial3D.new()
		cm.emission_enabled = true
		cm.emission = Color(1.0, 0.85, 0.3)
		cm.emission_energy_multiplier = 1.8
		cm.albedo_color = Color(0.3, 0.26, 0.1)
		can.material_override = cm
		can.position = Vector3(1.2, 0.3, 0.6)
		site.add_child(can)
		var sl := OmniLight3D.new()
		sl.light_color = Color(1.0, 0.7, 0.3)
		sl.light_energy = 1.2
		sl.omni_range = 5.0
		sl.position = Vector3(0, 1.2, 0)
		site.add_child(sl)
		pois.append({"pos": pos, "node": site, "looted": false, "discovered": false})

	# Secondary objective: a black-box data cache somewhere in the sector
	cache_done = false
	cache_progress = 0.0
	var kang := randf() * TAU
	var kdist := randf_range(40.0, 105.0)
	cache_pos = Vector3(cos(kang) * kdist, 0, sin(kang) * kdist)
	cache_pos.y = ground_height(cache_pos.x, cache_pos.z)
	var cache := Node3D.new()
	add_child(cache)
	cache.global_position = cache_pos
	var kbox := MeshInstance3D.new()
	var kb := BoxMesh.new()
	kb.size = Vector3(0.9, 0.7, 0.9)
	kbox.mesh = kb
	var km := StandardMaterial3D.new()
	km.albedo_color = Color(0.16, 0.14, 0.1)
	km.metallic = 0.7
	km.emission_enabled = true
	km.emission = Color(1.0, 0.72, 0.2)
	km.emission_energy_multiplier = 1.2
	kbox.material_override = km
	kbox.position = Vector3(0, 0.35, 0)
	kbox.rotation_degrees = Vector3(0, 35, 8)
	cache.add_child(kbox)
	var kl := OmniLight3D.new()
	kl.light_color = Color(1.0, 0.72, 0.2)
	kl.light_energy = 1.4
	kl.omni_range = 6.0
	kl.position = Vector3(0, 1.2, 0)
	cache.add_child(kl)

	# The radar tower: calibrate it and the whole sector confesses
	radar_done = false
	radar_progress = 0.0
	radar_boost_t = 0.0
	var rang := randf() * TAU
	var rdist := randf_range(45.0, 100.0)
	radar_pos = Vector3(cos(rang) * rdist, 0, sin(rang) * rdist)
	radar_pos.y = ground_height(radar_pos.x, radar_pos.z)
	var tower := Node3D.new()
	add_child(tower)
	tower.global_position = radar_pos
	var mast := MeshInstance3D.new()
	var mc := CylinderMesh.new()
	mc.top_radius = 0.12
	mc.bottom_radius = 0.3
	mc.height = 11.0
	mast.mesh = mc
	mast.material_override = dark
	mast.position = Vector3(0, 5.5, 0)
	tower.add_child(mast)
	var dish := MeshInstance3D.new()
	var db := BoxMesh.new()
	db.size = Vector3(1.8, 1.2, 0.15)
	dish.mesh = db
	dish.material_override = dark
	dish.position = Vector3(0, 10.6, 0)
	dish.rotation_degrees = Vector3(-30, 40, 0)
	tower.add_child(dish)
	var tl := OmniLight3D.new()
	tl.light_color = Color(0.9, 0.95, 1.0)
	tl.light_energy = 1.6
	tl.omni_range = 7.0
	tl.position = Vector3(0, 10.5, 0)
	tower.add_child(tl)


func _update_pois(delta: float) -> void:
	if player == null or not player.alive:
		return
	var pp := player.global_position
	for poi in pois:
		if poi["looted"]:
			continue
		var d: float = pp.distance_to(poi["pos"])
		if not poi["discovered"] and d < 22.0:
			poi["discovered"] = true
			hud.push_msg("POI SPOTTED — CRASH SITE", Color(1.0, 0.85, 0.3))
			sfx("click", -8.0)
		if d < 2.6:
			poi["looted"] = true
			score += 150
			match randi() % 4:
				0:
					player.samples += 1
					hud.push_msg("SALVAGE: SAMPLE CANISTER (+1)", Color(0.3, 1.0, 0.8))
				1:
					player.stims = 3 + player.bonus_stims
					hud.push_msg("SALVAGE: CHEM-STIM CACHE", Color(0.55, 1.0, 0.6))
				2:
					player.grenades = int(player.GRENADES[player.grenade_key]["count"]) \
						+ player.grenade_bonus
					hud.push_msg("SALVAGE: FIELD KIT RESTOCK", Color(1.0, 0.85, 0.3))
				_:
					player.reserve += int(player.wpn.get("mag", 12)) * 2
					hud.push_msg("SALVAGE: LOOSE AMMUNITION", Color(1.0, 0.85, 0.3))
			sfx("click", -4.0)
			if is_instance_valid(poi["node"]):
				for child in poi["node"].get_children():
					if child is MeshInstance3D and child.position.x > 0.5:
						child.queue_free()   # the canister is spent

	# The data cache: stand over it while the Holo-Glove siphons it
	if not cache_done:
		if pp.distance_to(cache_pos) < 3.5:
			cache_progress += delta / 3.0 * 100.0
			if cache_progress >= 100.0:
				cache_done = true
				score += 500
				sfx("click", -2.0)
				hud.push_msg("DATA CACHE RECOVERED — THE DIRECTORATE APPROVES",
							 Color(1.0, 0.72, 0.2))
		else:
			cache_progress = maxf(0.0, cache_progress - 25.0 * delta)

	# Radar calibration: stand at the mast and let it think
	radar_boost_t = maxf(0.0, radar_boost_t - delta)
	if not radar_done:
		if pp.distance_to(radar_pos) < 4.5:
			radar_progress += delta / 3.0 * 100.0
			if radar_progress >= 100.0:
				radar_done = true
				radar_boost_t = 90.0
				for poi in pois:
					poi["discovered"] = true
				sfx("breach", -10.0)
				hud.push_msg("RADAR ALIGNED — SECTOR REVEALED, HOSTILES PINGED",
							 Color(0.4, 0.85, 1.0))
		else:
			radar_progress = maxf(0.0, radar_progress - 20.0 * delta)


func _env_event() -> void:
	# The planet has opinions: dynamic weather and geology
	var pool: Array = ["tremor", "ion"]
	if biome == "ash" or planet.get("caustic", false):
		pool.append("meteor")
	if planet.get("faction", "") == "arbitration":
		pool.append("psi")
		pool.append("psi")
	match pool[randi() % pool.size()]:
		"tremor":
			tremor_t = 3.0
			hud.push_msg("SEISMIC TREMOR — FOOTING COMPROMISED", Color(1.0, 0.75, 0.4))
			sfx("boom", -6.0)
			if player != null:
				player.add_shake(7.0)
			for e in get_tree().get_nodes_in_group("enemies"):
				if e.has_method("apply_chill"):
					e.apply_chill(2.5)
		"ion":
			ion_t = 25.0
			hud.push_msg("ION STORM — STRATAGEM LINK OFFLINE", Color(0.6, 0.7, 1.0))
			sfx("laser", -12.0)
		"psi":
			psi_t = 8.0
			hud.push_msg("PSIONIC INVERSION — MOTOR CONTROLS COMPROMISED",
						 Color(0.75, 0.5, 1.0))
			sfx("stim", -8.0)
		"meteor":
			hud.push_msg("METEOR BARRAGE INBOUND", Color(1.0, 0.4, 0.2))
			sfx("breach", -8.0)
			var center := player.global_position + Vector3(
				randf_range(-25, 25), 0, randf_range(-25, 25))
			for i in range(8):
				get_tree().create_timer(1.2 + i * 0.45).timeout.connect(func() -> void:
					if state != "playing":
						return
					var hitp := center + Vector3(randf_range(-22, 22), 0,
												 randf_range(-22, 22))
					hitp.y = ground_height(hitp.x, hitp.z)
					explode(hitp, 5.0, 110.0))


func _spawn_vents(pts: Array = []) -> void:
	# Swarm vents: structural spawners. Explosives only — seal them to thin
	# the local pressure. Higher threat tiers seed more of them, and every
	# extra vent hardens the whole network's chitin.
	vents.clear()
	var count := clampi(2 + int(op.get("tier", 5)) / 4, 2, 4)
	if not pts.is_empty():
		count = pts.size()
	for i in range(count):
		var vx: float
		var vz: float
		if i < pts.size():
			vx = pts[i].x
			vz = pts[i].y
		else:
			var ang := randf() * TAU
			var dist := randf_range(30.0, 90.0)
			vx = cos(ang) * dist
			vz = sin(ang) * dist
		var v: StaticBody3D = VentScript.new()
		v.main = self
		v.health = 160.0 + 90.0 * count
		add_child(v)
		v.global_position = Vector3(vx, ground_height(vx, vz), vz)
		vents.append(v)


func on_vent_destroyed(v: Node3D) -> void:
	vents.erase(v)
	score += 400
	sfx("boom", -6.0)
	if hud != null:
		hud.push_msg("SWARM VENT SEALED — LOCAL PRESSURE DOWN",
					 Color(0.75, 0.45, 1.0))


func _begin_wave(idx: int) -> void:
	wave_idx = idx
	wave_active = true
	trickle.clear()
	var comp: Dictionary = waves_table[min(idx, waves_table.size() - 1)]
	for kind in comp:
		for i in range(comp[kind]):
			trickle.append(kind)
	trickle.shuffle()
	trickle_timer = 0.5
	hud.push_msg("SWARM SURGE %d" % (idx + 1), Color(1.0, 0.3, 0.2))


func get_targets() -> Array:
	var t: Array = []
	if player != null and player.alive:
		t.append(player)
	for a in get_tree().get_nodes_in_group("allies"):
		t.append(a)
	return t


func taunt(target: Node3D, dur: float) -> void:
	taunt_target = target
	taunt_t = dur


func nearest_target(pos: Vector3) -> Node3D:
	# Deflection of Blame: while the taunt holds, everyone blames the coworker
	if taunt_t > 0.0 and is_instance_valid(taunt_target):
		return taunt_target
	var best: Node3D = null
	var best_d := 1e9
	for t in get_targets():
		var d: float = t.global_position.distance_to(pos)
		if d < best_d:
			best_d = d
			best = t
	return best


func register_hit(killed: bool) -> void:
	if hud != null:
		hud.hitmark(killed)
	sfx("kill" if killed else "hit", -6.0 if killed else -14.0)


func alive_enemies() -> int:
	return get_tree().get_nodes_in_group("enemies").size()


func _make_hellpod() -> Node3D:
	# A Gantry Spike: an armoured drop-pod with a nose cone, fins and a
	# retro-thruster flame. Built from primitives, no assets needed.
	var root := Node3D.new()
	var hull := StandardMaterial3D.new()
	hull.albedo_color = Color(0.17, 0.18, 0.21)
	hull.metallic = 0.7
	hull.roughness = 0.4
	var body := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.55
	cyl.bottom_radius = 0.85
	cyl.height = 2.2
	body.mesh = cyl
	body.material_override = hull
	root.add_child(body)
	var nose := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.85
	cone.height = 1.2
	nose.mesh = cone
	nose.material_override = hull
	nose.position = Vector3(0, 1.7, 0)
	root.add_child(nose)
	var fin_mat := StandardMaterial3D.new()
	fin_mat.albedo_color = Color(0.9, 0.55, 0.15)
	fin_mat.metallic = 0.3
	for i in range(4):
		var fin := MeshInstance3D.new()
		var fm := BoxMesh.new()
		fm.size = Vector3(0.09, 0.95, 0.72)
		fin.mesh = fm
		fin.material_override = fin_mat
		var a := i * PI / 2.0
		fin.position = Vector3(cos(a) * 0.78, -0.85, sin(a) * 0.78)
		fin.rotation.y = -a
		root.add_child(fin)
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.6, 0.2)
	glow.light_energy = 6.0
	glow.omni_range = 14.0
	glow.position = Vector3(0, -1.7, 0)
	root.add_child(glow)
	var fx := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, -1, 0)
	pm.spread = 14.0
	pm.initial_velocity_min = 10.0
	pm.initial_velocity_max = 20.0
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.6
	pm.scale_max = 1.5
	fx.process_material = pm
	fx.amount = 70
	fx.lifetime = 0.5
	fx.position = Vector3(0, -1.5, 0)
	var q := QuadMesh.new()
	q.size = Vector2(0.7, 0.7)
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.albedo_color = Color(1.0, 0.75, 0.3)
	qm.emission_enabled = true
	qm.emission = Color(1.0, 0.6, 0.2)
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q.material = qm
	fx.draw_pass_1 = q
	root.add_child(fx)
	return root


func _start_drop() -> void:
	# Freeze the Breacher inside the pod; the chase camera rides it down.
	drop_impact = player.global_position
	player.visible = false
	pod = _make_hellpod()
	add_child(pod)
	pod.global_position = drop_impact + Vector3(0, DROP_HEIGHT, 0)
	drop_cam = Camera3D.new()
	drop_cam.fov = 68.0
	add_child(drop_cam)
	drop_cam.global_position = pod.global_position + Vector3(0, 11, 16)
	drop_cam.look_at(pod.global_position, Vector3.UP)
	drop_cam.current = true
	drop_vel = 8.0
	drop_shake = 0.0
	state = "drop"
	sfx("breach", -3.0)
	if hud != null:
		hud.push_msg("GANTRY SPIKE AWAY — %s" % player.recruit["name"],
					 Color(0.5, 0.85, 1.0))
		hud.push_msg("STEER WITH WASD — BRACE FOR IMPACT",
					 Color(1.0, 0.72, 0.2))


func _update_drop(delta: float) -> void:
	if pod == null:
		_drop_impact(drop_impact)
		return
	# HD2-style aim: nudge the landing point while you fall
	var steer := Input.get_vector("move_left", "move_right",
								  "move_forward", "move_back")
	pod.global_position.x += steer.x * 16.0 * delta
	pod.global_position.z += steer.y * 16.0 * delta
	var gy := ground_height(pod.global_position.x, pod.global_position.z)
	var h: float = pod.global_position.y - gy
	if h > 45.0:
		drop_vel = minf(drop_vel + 130.0 * delta, 110.0)   # freefall
	else:
		drop_vel = lerpf(drop_vel, 20.0, 7.0 * delta)       # retro burn
		drop_shake = 1.0
	pod.global_position.y -= drop_vel * delta
	pod.rotate_y(delta * 1.4)
	# chase cam rides above and behind the fall line
	var back := 15.0 + h * 0.03
	var want := pod.global_position + Vector3(0, 9.0 + h * 0.04, back)
	drop_cam.global_position = drop_cam.global_position.lerp(want, 8.0 * delta)
	drop_cam.look_at(pod.global_position + Vector3(0, -8.0, 0), Vector3.UP)
	if drop_shake > 0.0:
		drop_cam.h_offset = randf_range(-1.0, 1.0) * 0.03 * drop_shake
		drop_cam.v_offset = randf_range(-1.0, 1.0) * 0.03 * drop_shake
	# snow/spindrift should follow the pod during the fall
	if snow != null:
		snow.global_position = pod.global_position + Vector3(0, 8, 0)
	if pod.global_position.y <= gy + 0.8:
		_drop_impact(Vector3(pod.global_position.x, gy, pod.global_position.z))


func _drop_impact(pos: Vector3) -> void:
	# Slam: dust burst, hard camera shake, a crater flash of light
	if pod != null:
		pod.global_position = pos + Vector3(0, 1.1, 0)
	_explosion_fx(pos, 6.0)
	# the pod crushes anything directly beneath it (never the squad)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.global_position.distance_to(pos) < 5.0:
			e.take_damage(120.0)
	# hand control to the Breacher, standing in the crater
	player.global_position = pos + Vector3(0, 1.2, 0)
	player.visible = true
	if player.cam != null:
		player.cam.current = true
	player.add_shake(8.0)
	if drop_cam != null:
		drop_cam.queue_free()
		drop_cam = null
	# leave the spent pod as a landmark, then clear it after a beat
	if pod != null:
		var doomed := pod
		pod = null
		get_tree().create_timer(7.0).timeout.connect(func() -> void:
			if is_instance_valid(doomed):
				doomed.queue_free())
	state = "playing"
	_begin_wave(0)
	bark("spawn")
	if hud != null:
		hud.push_msg(op["name"], Color(1.0, 0.72, 0.2))
		hud.push_msg("BREACHER DOWN AND LIVE", Color(0.5, 1.0, 0.55))


func _physics_process(delta: float) -> void:
	if snow != null and player != null:
		snow.global_position = player.global_position + Vector3(0, 8, 0)
	if spindrift != null and player != null:
		spindrift.global_position = player.global_position + Vector3(0, 0.4, 0)

	if get_tree().paused:
		return
	_update_music(delta)
	if state == "crawl":
		crawl_timer -= delta
		if crawl_timer <= 0.0:
			_finish_crawl()
		return
	if state == "dead":
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			_respawn()
		return
	if state == "drop":
		_update_drop(delta)
		return
	if state != "playing":
		return

	# Uplink mission: the terminal only counts while someone stands at it
	if mission_type == "uplink" and phase == "clear" and terminal != null \
			and player != null and player.alive:
		if player.global_position.distance_to(terminal.global_position) < 4.5:
			upload += 4.0 * delta
			if upload >= 100.0:
				terminal.queue_free()
				terminal = null
				score += 800
				_light_beacon()

	# Samples: grab them if you dare, cash them if you live
	for i in range(sample_nodes.size() - 1, -1, -1):
		var s: Node3D = sample_nodes[i]
		if not is_instance_valid(s):
			sample_nodes.remove_at(i)
			continue
		if player != null and player.alive \
				and player.global_position.distance_to(s.global_position) < 2.2:
			player.samples += 1
			sfx("click", -6.0)
			hud.push_msg("SAMPLE SECURED (%d)" % player.samples,
						 Color(0.3, 1.0, 0.8))
			s.queue_free()
			sample_nodes.remove_at(i)

	# The ground burns on Cinderfall
	for hz in hazards:
		if player != null and player.alive:
			var flat_p: Vector3 = player.global_position - hz[0]
			flat_p.y = 0.0
			if flat_p.length() < hz[1]:
				player.take_damage(14.0 * delta, true)
		for a in get_tree().get_nodes_in_group("allies"):
			var flat_a: Vector3 = a.global_position - hz[0]
			flat_a.y = 0.0
			if flat_a.length() < hz[1]:
				a.take_damage(14.0 * delta)

	_update_speeder(delta)

	# The squad regenerates by hellpod
	reinforce_timer = maxf(0.0, reinforce_timer - delta)
	var ally_count := get_tree().get_nodes_in_group("allies").size()
	if ally_count < 2 and reinforce_timer <= 0.0 and player != null:
		reinforce_timer = 9.0
		var ang2 := randf() * TAU
		var drop := player.global_position \
			+ Vector3(cos(ang2) * 6.0, 0, sin(ang2) * 6.0)
		drop.y = ground_height(drop.x, drop.z)
		_ally_pod(drop, ally_count)

	# NDA smoke dissipates on a deadline, like all confidentiality
	for i in range(smokes.size() - 1, -1, -1):
		smokes[i][3] -= delta
		if smokes[i][3] <= 0.0:
			if is_instance_valid(smokes[i][0]):
				smokes[i][0].queue_free()
			smokes.remove_at(i)

	# The mission clock: the longer this drags, the harder the ground pushes.
	# When the window closes, the Void Anchor is retasked — no more support.
	mission_time += delta
	if mission_time > mission_limit and not anchor_retasked:
		anchor_retasked = true
		sfx("breach", -4.0)
		hud.push_msg("MISSION WINDOW CLOSED — THE VOID ANCHOR IS RETASKED",
					 Color(1.0, 0.3, 0.2))
		hud.push_msg("NO FURTHER STRATAGEM SUPPORT. EXTRACT.", Color(1.0, 0.3, 0.2))

	# The Directorate watches the feed and adjusts the war in real time
	event_timer -= delta
	if event_timer <= 0.0:
		event_timer = randf_range(130.0, 200.0)
		_directorate_event()

	# The planet takes its own turns: weather, geology, psionics
	tremor_t = maxf(0.0, tremor_t - delta)
	ion_t = maxf(0.0, ion_t - delta)
	psi_t = maxf(0.0, psi_t - delta)
	env_timer -= delta
	if env_timer <= 0.0:
		env_timer = randf_range(90.0, 150.0)
		_env_event()
	_update_pois(delta)

	# Surges are endless ambient pressure — the mission is the objectives.
	# During extraction the Swarm pushes twice as hard.
	if wave_active and not trickle.is_empty():
		trickle_timer -= delta
		if trickle_timer <= 0.0:
			var base := randf_range(0.35, 0.8) if phase != "clear" \
				else randf_range(0.6, 1.6)
			trickle_timer = base / pressure()
			_spawn_enemy(trickle.pop_back())

	if wave_active and trickle.is_empty() and alive_enemies() == 0:
		wave_active = false
		between_timer = 5.0 / pressure()
		hud.push_msg("SURGE REPELLED", Color(0.5, 1.0, 0.55))
	elif not wave_active:
		between_timer -= delta
		if between_timer <= 0.0:
			_begin_wave(wave_idx + 1)

	taunt_t = maxf(0.0, taunt_t - delta)

	# Patrols wander the reach; spotting you costs dearly
	breach_cd = maxf(0.0, breach_cd - delta)
	patrol_timer -= delta
	if patrol_timer <= 0.0 and alive_enemies() < 34:
		patrol_timer = randf_range(20.0, 32.0)
		_spawn_patrol()

	# Extraction hold: stand in the beacon light while the Swarm objects
	if phase == "extract" and beacon != null and player != null and player.alive:
		var flat := player.global_position - beacon_pos
		flat.y = 0.0
		if flat.length() < 6.0:
			extract_hold -= delta
			if extract_hold <= 0.0:
				_begin_leaving()
		# leaving the ring pauses the clock — it does not reset


func _spawn_speeder(drop: Vector2 = Vector2(4.3, 3.1)) -> void:
	# The VULTURE skimmer: parked near the drop, E to ride
	speeder = Node3D.new()
	add_child(speeder)
	var sx := drop.x - 10.3
	var sz := drop.y + 1.9
	speeder.global_position = Vector3(sx, ground_height(sx, sz) + 0.5, sz)
	var hull_mat := StandardMaterial3D.new()
	hull_mat.albedo_color = Color(0.45, 0.42, 0.36)
	hull_mat.metallic = 0.55
	hull_mat.roughness = 0.4
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.12, 0.12, 0.14)
	var body := MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(0.8, 0.45, 2.6)
	body.mesh = bb
	body.material_override = hull_mat
	body.position = Vector3(0, 0.4, 0)
	speeder.add_child(body)
	# forward forks
	for side in [-1.0, 1.0]:
		var fork := MeshInstance3D.new()
		var fb := BoxMesh.new()
		fb.size = Vector3(0.18, 0.22, 1.1)
		fork.mesh = fb
		fork.material_override = dark
		fork.position = Vector3(0.4 * side, 0.32, -1.7)
		speeder.add_child(fork)
	var seat := MeshInstance3D.new()
	var sb := BoxMesh.new()
	sb.size = Vector3(0.5, 0.2, 0.9)
	seat.mesh = sb
	seat.material_override = dark
	seat.position = Vector3(0, 0.68, 0.4)
	speeder.add_child(seat)
	var engine := MeshInstance3D.new()
	var eb := BoxMesh.new()
	eb.size = Vector3(0.5, 0.3, 0.3)
	engine.mesh = eb
	var em := StandardMaterial3D.new()
	em.emission_enabled = true
	em.emission = Color(0.3, 0.8, 1.0)
	em.emission_energy_multiplier = 2.0
	em.albedo_color = Color(0.1, 0.25, 0.3)
	engine.material_override = em
	engine.position = Vector3(0, 0.42, 1.35)
	speeder.add_child(engine)
	var gl := OmniLight3D.new()
	gl.light_color = Color(0.3, 0.8, 1.0)
	gl.light_energy = 1.2
	gl.omni_range = 4.0
	gl.position = Vector3(0, 0.4, 1.4)
	speeder.add_child(gl)


func _update_speeder(delta: float) -> void:
	if speeder == null or player == null:
		near_speeder = false
		return
	if player.mounted:
		# the skimmer rides under the Breacher, hovering and leaning
		var hover := 0.35 + sin(Time.get_ticks_msec() / 180.0) * 0.08
		speeder.global_position = player.global_position + Vector3(0, hover - 0.3, 0)
		speeder.rotation.y = player.rotation.y
		var lateral: float = player.velocity.dot(
			player.global_transform.basis.x)
		speeder.rotation.z = lerpf(speeder.rotation.z,
								   clampf(-lateral * 0.02, -0.35, 0.35),
								   6.0 * delta)
		near_speeder = true
	else:
		speeder.rotation.z = lerpf(speeder.rotation.z, 0.0, 4.0 * delta)
		near_speeder = player.alive and \
			player.global_position.distance_to(speeder.global_position) < 3.5
	if Input.is_action_just_pressed("interact") and state == "playing" \
			and player.alive:
		if player.mounted:
			player.mounted = false
			# park it where you stand
			var pp := player.global_position
			speeder.global_position = Vector3(pp.x, ground_height(pp.x, pp.z) + 0.5,
											  pp.z) + player.global_transform.basis.x * 1.4
			sfx("click", -6.0)
		elif near_speeder:
			player.mounted = true
			sfx("click", -4.0)
			hud.push_msg("VULTURE SKIMMER — E TO DISMOUNT", Color(0.3, 0.8, 1.0))


func _ally_pod(drop: Vector3, slot: int) -> void:
	# A reinforcement hellpod screams down and delivers a fresh Breacher
	var pod := Node3D.new()
	add_child(pod)
	pod.global_position = drop + Vector3(0, 120, 0)
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.9, 2.6, 0.9)
	m.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.38, 0.45)
	mat.metallic = 0.7
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.7, 1.0)
	mat.emission_energy_multiplier = 2.0
	m.material_override = mat
	pod.add_child(m)
	var tw := create_tween()
	tw.tween_property(pod, "global_position", drop + Vector3(0, 1.3, 0), 1.4) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		_explosion_fx(drop, 2.5)
		pod.queue_free()
		if state == "playing":
			_spawn_ally(slot, drop + Vector3(0, 1.2, 0)))


func _update_music(delta: float) -> void:
	# Three always-spinning loops, mixed by what the war is doing
	var amb_t := -14.0 if state in ["playing", "dead"] else -22.0
	var combat_t := -60.0
	var extract_t := -60.0
	if state == "playing":
		if phase in ["extract", "leaving"]:
			extract_t = -8.0
			amb_t = -26.0
		elif alive_enemies() > 3 and wave_active:
			combat_t = -10.0
			amb_t = -20.0
	var k := 1.5 * delta
	music["amb"].volume_db = lerpf(music["amb"].volume_db, amb_t, k)
	music["combat"].volume_db = lerpf(music["combat"].volume_db, combat_t, k)
	music["extract"].volume_db = lerpf(music["extract"].volume_db, extract_t, k)


func _spawn_patrol() -> void:
	var ang := randf() * TAU
	var dist := randf_range(45.0, 70.0)
	var center := player.global_position + Vector3(cos(ang) * dist, 0, sin(ang) * dist)
	for i in range(4):
		var e: CharacterBody3D = TickScript.new()
		e.main = self
		e.patrol = true
		add_child(e)
		var px := center.x + randf_range(-4, 4)
		var pz := center.z + randf_range(-4, 4)
		e.global_position = Vector3(px, ground_height(px, pz) + 2.0, pz)


func trigger_breach(pos: Vector3) -> void:
	if breach_cd > 0.0:
		return
	breach_cd = 30.0
	sfx("breach", -2.0)
	var faction: String = planet.get("faction", "swarm")
	match faction:
		"reclaimers":
			hud.push_msg("!! REPO DROPSHIP INBOUND !!", Color(1.0, 0.3, 0.2))
		"arbitration":
			hud.push_msg("!! THE VOTELESS ANSWER !!", Color(0.5, 0.7, 1.0))
		_:
			hud.push_msg("!! SWARM BREACH !!", Color(1.0, 0.3, 0.2))
	# A red column marks where the ground is about to open
	var flare := Node3D.new()
	add_child(flare)
	flare.global_position = pos
	var fm := MeshInstance3D.new()
	var fc := CylinderMesh.new()
	fc.top_radius = 0.3
	fc.bottom_radius = 0.9
	fc.height = 60.0
	fm.mesh = fc
	var fmat := StandardMaterial3D.new()
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.albedo_color = Color(1.0, 0.2, 0.15, 0.4)
	fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.material_override = fmat
	fm.position = Vector3(0, 30, 0)
	flare.add_child(fm)
	var fl := OmniLight3D.new()
	fl.light_color = Color(1.0, 0.25, 0.15)
	fl.light_energy = 8.0
	fl.light_volumetric_fog_energy = 3.5   # a red blade through the blizzard
	fl.omni_range = 18.0
	fl.position = Vector3(0, 4, 0)
	flare.add_child(fl)
	get_tree().create_timer(4.0).timeout.connect(func() -> void:
		if is_instance_valid(flare):
			flare.queue_free())
	# The ground (or the sky) answers, in the local dialect
	for i in range(8):
		get_tree().create_timer(0.5 + i * 0.35).timeout.connect(func() -> void:
			if state != "playing" or alive_enemies() >= 40:
				return
			var e: CharacterBody3D
			match faction:
				"reclaimers":
					e = ForemanScript.new() if i == 7 else ClerkScript.new()
				"arbitration":
					e = ArbiterScript.new() if i == 7 else TickScript.new()
				_:
					e = TickScript.new()
			e.main = self
			add_child(e)
			var a := randf() * TAU
			var d := randf_range(1.0, 6.0)
			var bx := pos.x + cos(a) * d
			var bz := pos.z + sin(a) * d
			e.global_position = Vector3(bx, ground_height(bx, bz) + 1.5, bz))


func _spawn_enemy(kind: String) -> void:
	var e: CharacterBody3D
	match kind:
		"walker":
			e = WalkerScript.new()
		"gunner":
			e = GunnerScript.new()
		"spitter":
			e = SpitterScript.new()
		"merger":
			e = MergerScript.new()
		"clerk":
			e = ClerkScript.new()
		"foreman":
			e = ForemanScript.new()
		"rocket":
			e = ForemanScript.new()
			e.rocket = true
		"arbiter":
			e = ArbiterScript.new()
		"sniper":
			e = GunnerScript.new()
			e.sniper = true
		"stalker":
			e = TickScript.new()
			e.stalker = true
		"atick":
			e = TickScript.new()
			e.armored = true
		_:
			e = TickScript.new()
	e.main = self
	add_child(e)
	# 40% of pressure pours out of the living vents — sealing them matters
	var live_vents: Array = vents.filter(func(v): return is_instance_valid(v))
	if not live_vents.is_empty() and randf() < 0.4:
		var vent: Node3D = live_vents[randi() % live_vents.size()]
		var va := randf() * TAU
		var vx: float = vent.global_position.x + cos(va) * randf_range(2.0, 8.0)
		var vz: float = vent.global_position.z + sin(va) * randf_range(2.0, 8.0)
		e.global_position = Vector3(vx, ground_height(vx, vz) + 2.0, vz)
		return
	var ang := randf() * TAU
	var p := player.global_position
	var ex := p.x + cos(ang) * SPAWN_RADIUS
	var ez := p.z + sin(ang) * SPAWN_RADIUS
	e.global_position = Vector3(ex, ground_height(ex, ez) + 2.0, ez)


var splats: Array = []   # the ground keeps a ledger of everything that died


func on_enemy_died(points: int, pos: Vector3) -> void:
	score += points
	if hud != null:
		hud.add_popup("+%d" % points, pos + Vector3(0, 1.5, 0))
	_splatter(pos)


func _splatter(pos: Vector3) -> void:
	# pressurized biology (or hydraulic fluid) coating the terrain
	if terrain_noise == null:
		return
	var col: Color
	var glow := true
	match planet.get("faction", "swarm"):
		"reclaimers":
			col = Color(0.05, 0.05, 0.07)   # oil and coolant
			glow = false
		"arbitration":
			col = Color(0.35, 0.65, 1.0)
		_:
			col = Color(0.55, 0.95, 0.35)   # neon swarm acid
	var m := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	var r := randf_range(0.5, 1.1)
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = 0.03
	m.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.25
	if glow:
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 0.5
	m.material_override = mat
	add_child(m)
	m.global_position = Vector3(pos.x, ground_height(pos.x, pos.z)
								+ randf_range(0.015, 0.035), pos.z)
	m.scale = Vector3(randf_range(0.8, 1.3), 1.0, randf_range(0.8, 1.3))
	splats.append(m)
	if splats.size() > 40:
		var old: Node = splats.pop_front()
		if is_instance_valid(old):
			old.queue_free()
	get_tree().create_timer(45.0).timeout.connect(func() -> void:
		if is_instance_valid(m):
			splats.erase(m)
			m.queue_free())


func on_player_died() -> void:
	bark("down")
	lives -= 1
	if lives <= 0:
		state = "gameover"
	else:
		state = "dead"
		respawn_timer = 3.0


func _respawn() -> void:
	# The revolving door turns: a brand-new recruit rides the spike down
	player.recruit = new_recruit(player.voice_idx)
	player.reset_at(Vector3(0, ground_height(0, 0) + 1.5, 0))
	state = "playing"
	hud.push_msg("REINFORCEMENT: %s  (%d spikes left)" % [
				 player.recruit["name"], lives], Color(0.5, 0.85, 1.0))
	bark("spawn")


# Corrosion: scheduled damage ticks that skip the weak-point armor game entirely
func apply_dot(target: Node, dps: float, dur: float) -> void:
	var ticks := int(round(dur / 0.4))
	for i in range(1, ticks + 1):
		get_tree().create_timer(0.4 * i).timeout.connect(func() -> void:
			if state == "playing" and is_instance_valid(target) \
					and target.has_method("take_damage"):
				target.take_damage(dps * 0.4))


# Area damage helper: physics is neutral — it damages everything in range
func explode(pos: Vector3, radius: float, dmg: float, hurt_player: bool = true) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		var d: float = e.global_position.distance_to(pos)
		if d < radius:
			e.take_damage(dmg * maxf(0.15, 1.0 - d / radius))
	# Structures (Swarm vents) only answer to explosives
	for s in get_tree().get_nodes_in_group("structures"):
		var ds: float = s.global_position.distance_to(pos)
		if ds < radius and s.has_method("take_explosive_damage"):
			s.take_explosive_damage(dmg * maxf(0.15, 1.0 - ds / radius))
	if hurt_player and player != null:
		var dp := player.global_position.distance_to(pos)
		if dp < radius:
			var impact := dmg * 0.5 * maxf(0.15, 1.0 - dp / radius)
			player.take_damage(impact, true)
			# blast physics: the pressure wave doesn't ask permission
			var push := player.global_position - pos
			push.y = 0.4
			if push.length() > 0.05:
				player.velocity += push.normalized() \
					* clampf(dmg * 0.06, 3.0, 14.0) * (1.0 - dp / radius)
			# a big enough wave puts you on the ground, tumbling — rocket
			# salvos, grenades, orbitals; anything with real pressure behind it
			if impact > 14.0 and player.alive and player.overtime_t <= 0.0:
				player.blast_toss()
	# the blast doesn't spare the squad either
	for a in get_tree().get_nodes_in_group("allies"):
		var da: float = a.global_position.distance_to(pos)
		if da < radius:
			a.take_damage(dmg * 0.5 * maxf(0.15, 1.0 - da / radius), true)
	player.add_shake(clampf(dmg / 100.0, 1.0, 8.0))
	_explosion_fx(pos, radius)


func _explosion_fx(pos: Vector3, radius: float) -> void:
	sfx("boom", -14.0 + clampf(radius, 0.0, 10.0))
	var boom := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.5
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 80.0
	pm.gravity = Vector3(0, -6, 0)
	pm.initial_velocity_min = radius * 0.8
	pm.initial_velocity_max = radius * 2.0
	pm.scale_min = 0.5
	pm.scale_max = 2.0
	boom.process_material = pm
	boom.amount = 96
	boom.lifetime = 1.1
	boom.one_shot = true
	boom.explosiveness = 0.95
	var q := QuadMesh.new()
	q.size = Vector2(0.5, 0.5)
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.albedo_color = Color(1.0, 0.62, 0.2)
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q.material = qm
	boom.draw_pass_1 = q
	add_child(boom)
	boom.global_position = pos
	boom.emitting = true

	var flash := OmniLight3D.new()
	flash.light_color = Color(1.0, 0.7, 0.35)
	flash.light_energy = 24.0
	flash.omni_range = radius * 3.0
	add_child(flash)
	flash.global_position = pos + Vector3(0, 2, 0)

	var t := get_tree().create_tween()
	t.tween_property(flash, "light_energy", 0.0, 0.5)
	t.tween_callback(flash.queue_free)
	get_tree().create_timer(3.0).timeout.connect(boom.queue_free)

	# The pyroclastic column: black smoke climbing off the blast
	var column := GPUParticles3D.new()
	var cm := ParticleProcessMaterial.new()
	cm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	cm.emission_sphere_radius = maxf(0.4, radius * 0.25)
	cm.direction = Vector3(0, 1, 0)
	cm.spread = 14.0
	cm.gravity = Vector3(0, 2.2, 0)
	cm.initial_velocity_min = 2.0
	cm.initial_velocity_max = 5.5
	cm.scale_min = 1.6
	cm.scale_max = 4.2
	cm.damping_min = 0.4
	cm.damping_max = 1.0
	column.process_material = cm
	column.amount = 48
	column.lifetime = 3.2
	column.one_shot = true
	column.explosiveness = 0.55
	var cq := QuadMesh.new()
	cq.size = Vector2(1.6, 1.6)
	var cqm := StandardMaterial3D.new()
	cqm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cqm.albedo_color = Color(0.07, 0.07, 0.08, 0.45)
	cqm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cqm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	cq.material = cqm
	column.draw_pass_1 = cq
	add_child(column)
	column.global_position = pos
	column.emitting = true
	get_tree().create_timer(4.5).timeout.connect(column.queue_free)

	# Embers ride the pressure wave out, then rain back down
	var embers := GPUParticles3D.new()
	var epm := ParticleProcessMaterial.new()
	epm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	epm.emission_sphere_radius = 0.4
	epm.direction = Vector3(0, 1, 0)
	epm.spread = 70.0
	epm.gravity = Vector3(0, -9.0, 0)
	epm.initial_velocity_min = radius * 1.5
	epm.initial_velocity_max = radius * 3.0
	epm.scale_min = 0.3
	epm.scale_max = 0.7
	embers.process_material = epm
	embers.amount = 40
	embers.lifetime = 1.6
	embers.one_shot = true
	embers.explosiveness = 0.95
	var eq := QuadMesh.new()
	eq.size = Vector2(0.12, 0.12)
	var eqm := StandardMaterial3D.new()
	eqm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	eqm.albedo_color = Color(1.0, 0.55, 0.15)
	eqm.emission_enabled = true
	eqm.emission = Color(1.0, 0.5, 0.12)
	eqm.emission_energy_multiplier = 2.5
	eqm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	eq.material = eqm
	embers.draw_pass_1 = eq
	add_child(embers)
	embers.global_position = pos
	embers.emitting = true
	get_tree().create_timer(2.5).timeout.connect(embers.queue_free)

	# Kicked-up rock, and a scorch the ground keeps for a while
	DebrisScript.burst(self, pos + Vector3(0, 0.5, 0), Color(0.35, 0.36, 0.4), 6)
	if terrain_noise != null:
		var gy := ground_height(pos.x, pos.z)
		if absf(pos.y - gy) < 4.0:
			var scorch := MeshInstance3D.new()
			var sc := CylinderMesh.new()
			sc.top_radius = radius * 0.65
			sc.bottom_radius = radius * 0.65
			sc.height = 0.04
			scorch.mesh = sc
			var scm := StandardMaterial3D.new()
			scm.albedo_color = Color(0.05, 0.045, 0.04)
			scm.roughness = 1.0
			scorch.material_override = scm
			add_child(scorch)
			scorch.global_position = Vector3(pos.x, gy + 0.03, pos.z)
			get_tree().create_timer(40.0).timeout.connect(func() -> void:
				if is_instance_valid(scorch):
					scorch.queue_free())
