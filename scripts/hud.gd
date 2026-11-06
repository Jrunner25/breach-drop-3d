# Visor HUD: compass top-center, threat banner, minimalist bars bottom-left,
# white circle-and-dot reticle that blooms with recoil and movement.
extends Control

const AMBER := Color(1.0, 0.72, 0.2)
const BLUE := Color(0.45, 0.8, 1.0)
const WARN := Color(1.0, 0.3, 0.2)
const WHITE := Color(0.93, 0.95, 0.97)
const ARROW := {"up": "^", "down": "v", "left": "<", "right": ">"}

var main: Node3D
var msgs: Array = []      # [text, color, timer]
var popups: Array = []    # [text, world_pos, timer]
var hitmark_t := 0.0
var hitmark_kill := false
var hud_font: Font       # clean monospace: the visor projects in fixed width


func hitmark(killed: bool) -> void:
	hitmark_t = 0.18
	hitmark_kill = killed


func add_popup(text: String, world_pos: Vector3) -> void:
	popups.append([text, world_pos, 1.1])


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["Cascadia Mono", "Consolas",
									   "Lucida Console", "Courier New"])
	hud_font = sf


func push_msg(text: String, color: Color = AMBER) -> void:
	msgs.append([text, color, 3.5])


func _process(delta: float) -> void:
	for m in msgs:
		m[2] -= delta
	msgs = msgs.filter(func(m): return m[2] > 0.0)
	for pop in popups:
		pop[2] -= delta
		pop[1] += Vector3(0, 0.8 * delta, 0)
	popups = popups.filter(func(pop): return pop[2] > 0.0)
	hitmark_t = maxf(0.0, hitmark_t - delta)
	queue_redraw()


func _draw() -> void:
	var f: Font = hud_font
	var vp := get_viewport_rect().size
	var w := vp.x
	var h := vp.y
	var p: CharacterBody3D = main.player
	if p == null:
		return

	_draw_compass(f, w)
	_draw_threat(f, w)
	_draw_mission(f, w, h)
	_draw_vitals(f, h, p)
	_draw_weapon(f, h, p)
	_draw_strats(f, w, h)
	_draw_msgs(f, w, h)
	_draw_popups(f)
	_draw_squad(f)
	_draw_reticle(w, h, p)
	_draw_visor(w, h, p)

	# samples banked on your rig
	if p.samples > 0:
		draw_string(f, Vector2(w - 130, 52), "SAMPLES %d" % p.samples,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.3, 1.0, 0.8))

	# top-left: contract line + spikes
	draw_string(f, Vector2(16, 24),
				"VOID ANCHOR // " + str(main.planet["name"]) + " — "
				+ str(main.op["name"]),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, AMBER)
	if main.near_speeder and main.player != null and not main.player.mounted:
		var pr := "%s — MOUNT THE VULTURE SKIMMER" % main.binding_key("interact")
		var pw := f.get_string_size(pr, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_string(f, Vector2(w * 0.5 - pw / 2, h * 0.58), pr,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.3, 0.8, 1.0))
	for i in range(4):
		var c := BLUE if i < main.lives else Color(0.25, 0.28, 0.32)
		var x := 20.0 + i * 18.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, 36), Vector2(x + 6, 48), Vector2(x - 6, 48)]), c)
	# who's inside the armor right now (it changes)
	if not p.recruit.is_empty():
		draw_string(f, Vector2(96, 47), "%s  ·  %s" % [
					p.recruit["name"], p.recruit["pers"]],
					HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.6, 0.66, 0.72))
	draw_string(f, Vector2(w - 120, 24), "SCORE %d" % main.score,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, AMBER)

	# The mission clock: the Void Anchor bills by the minute
	if main.state == "playing":
		var left: float = main.mission_limit - main.mission_time
		if left > 0.0:
			var ccol := WHITE if left > 180.0 else (AMBER if left > 60.0 else WARN)
			draw_string(f, Vector2(w - 260, 24), "T-%02d:%02d" % [
						int(left) / 60, int(left) % 60],
						HORIZONTAL_ALIGNMENT_LEFT, -1, 14, ccol)
		elif sin(Time.get_ticks_msec() / 300.0) > -0.3:
			draw_string(f, Vector2(w - 300, 24), "ANCHOR RETASKED",
						HORIZONTAL_ALIGNMENT_LEFT, -1, 14, WARN)

	# Planetary events: the sky and the ground filing their own reports
	if main.state == "playing":
		var ev_y := 104.0
		if main.ion_t > 0.0:
			var it := "ION STORM — STRATAGEMS OFFLINE %d s" % int(ceil(main.ion_t))
			var iw := f.get_string_size(it, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
			draw_string(f, Vector2(w * 0.5 - iw / 2, ev_y), it,
						HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.6, 0.7, 1.0))
			ev_y += 18.0
		if main.psi_t > 0.0 and sin(Time.get_ticks_msec() / 120.0) > -0.4:
			var pt := "PSIONIC INVERSION %d s — TRUST NOTHING" % int(ceil(main.psi_t))
			var pw := f.get_string_size(pt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
			draw_string(f, Vector2(w * 0.5 - pw / 2, ev_y), pt,
						HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.75, 0.5, 1.0))
			ev_y += 18.0
		if p.bogged:
			var bt := "BOGGED — DEEP DRIFT"
			var bw := f.get_string_size(bt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			draw_string(f, Vector2(w * 0.5 - bw / 2, ev_y), bt,
						HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.85, 0.9))
		# radar tower calibration: hold position, let the dish think
		if not main.radar_done and p.alive \
				and p.global_position.distance_to(main.radar_pos) < 4.5:
			var rt := "CALIBRATING RADAR — %d%%" % int(main.radar_progress)
			var rw := f.get_string_size(rt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
			draw_string(f, Vector2(w * 0.5 - rw / 2, h * 0.55), rt,
						HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.4, 0.85, 1.0))
		# the data cache siphon works the same way
		if not main.cache_done and p.alive \
				and p.global_position.distance_to(main.cache_pos) < 3.5:
			var kt := "SIPHONING DATA CACHE — %d%%" % int(main.cache_progress)
			var kw := f.get_string_size(kt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
			draw_string(f, Vector2(w * 0.5 - kw / 2, h * 0.52), kt,
						HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.72, 0.2))

	# Structural damage: fractures nag from under the reticle until stimmed
	var frac_y := h * 0.60
	for frac in [[p.arm_hurt, "ARM FRACTURE — aim compromised"],
				 [p.leg_hurt, "LEG FRACTURE — sprint disabled"]]:
		if frac[0]:
			var ft: String = str(frac[1])
			var fw := f.get_string_size(ft, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			draw_string(f, Vector2(w * 0.5 - fw / 2, frac_y), ft,
						HORIZONTAL_ALIGNMENT_LEFT, -1, 13, WARN)
			frac_y += 16.0

	# Sunk Cost Fallacy: six seconds of company time
	if p.overtime_t > 0.0:
		if sin(Time.get_ticks_msec() / 90.0) > -0.4:
			var ot := "OVERTIME  %.1f — NOTHING LEFT TO LOSE" % p.overtime_t
			var otw := f.get_string_size(ot, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
			draw_string(f, Vector2(w * 0.5 - otw / 2, h * 0.22), ot,
						HORIZONTAL_ALIGNMENT_LEFT, -1, 30, WARN)

	# state overlays
	if main.state == "dead":
		_overlay(f, w, h, "POSITION VACATED",
				 "dispatching replacement contractor...", WARN)
	elif main.state == "gameover":
		_review_overlay(f, w, h, false)
	elif main.state == "victory":
		_review_overlay(f, w, h, true)


func _draw_popups(f: Font) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	for pop in popups:
		if cam.is_position_behind(pop[1]):
			continue
		var sp: Vector2 = cam.unproject_position(pop[1])
		var c := Color(1.0, 0.85, 0.4, clampf(pop[2] * 1.6, 0.0, 1.0))
		draw_string(f, sp, str(pop[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, c)


func _draw_squad(f: Font) -> void:
	var y := 152.0   # below the objective panel
	for a in main.get_tree().get_nodes_in_group("allies"):
		var frac: float = clampf(a.health / a.max_health, 0.0, 1.0)
		draw_string(f, Vector2(20, y), str(a.callsign),
					HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.85, 0.95))
		draw_rect(Rect2(90, y - 9, 70, 6), Color(0.08, 0.09, 0.12, 0.8))
		draw_rect(Rect2(90, y - 9, 70 * frac, 6),
				  WHITE if frac > 0.4 else WARN)
		y += 18.0


func _draw_compass(f: Font, w: float) -> void:
	var cx := w * 0.5
	var top := 10.0
	var half_w := 220.0
	var half_win := 1.22
	var px_per_rad := half_w / half_win
	draw_line(Vector2(cx - half_w, top + 22), Vector2(cx + half_w, top + 22),
			  Color(0.3, 0.45, 0.55), 1.0)
	# Godot yaw: facing -Z at rotation.y == 0. Define North as -Z.
	var yaw: float = main.player.rotation.y
	for deg in range(0, 360, 15):
		var a := deg_to_rad(float(deg))
		var diff := wrapf(-yaw - a, -PI, PI)
		if absf(diff) > half_win:
			continue
		var x := cx + diff * px_per_rad
		var card: String = {0: "N", 90: "E", 180: "S", 270: "W"}.get(deg, "")
		if card != "":
			draw_string(f, Vector2(x - 5, top + 14), card,
						HORIZONTAL_ALIGNMENT_LEFT, -1, 14, WHITE)
			draw_line(Vector2(x, top + 17), Vector2(x, top + 22), WHITE, 1.0)
		else:
			draw_line(Vector2(x, top + 19), Vector2(x, top + 22),
					  Color(0.3, 0.45, 0.55), 1.0)
	# markers: objectives amber-purple, the beacon cyan, walkers red
	var markers: Array = []
	for s in main.siphons:
		if is_instance_valid(s):
			markers.append([s.global_position, Color(0.8, 0.45, 1.0)])
	if main.phase != "clear" and main.beacon != null:
		markers.append([main.beacon_pos, Color(0.4, 0.85, 1.0)])
	for e in main.get_tree().get_nodes_in_group("enemies"):
		if e.has_method("_run_beam"):
			markers.append([e.global_position, WARN])
	for b in main.get_tree().get_nodes_in_group("boss"):
		markers.append([b.global_position, Color(1.0, 0.15, 0.1)])
	# Swarm vents still breathing in the sector
	for v in main.vents:
		if is_instance_valid(v):
			markers.append([v.global_position, Color(1.0, 0.6, 0.2)])
	# scouted crash sites with loot still on the ground
	for poi in main.pois:
		if poi["discovered"] and not poi["looted"]:
			markers.append([poi["pos"], Color(1.0, 0.85, 0.3)])
	# the radar tower, until it's been calibrated
	if not main.radar_done:
		markers.append([main.radar_pos, Color(0.85, 0.9, 0.95)])
	# the data cache, until it's been siphoned
	if not main.cache_done:
		markers.append([main.cache_pos, Color(1.0, 0.72, 0.2)])
	# Recon Weave radar: 3-second snapshots of every hostile nearby
	if main.player.radar:
		for ping in main.player.radar_pings:
			markers.append([ping, Color(0.4, 1.0, 0.5, 0.8)])
	for m in markers:
		var to_m: Vector3 = m[0] - main.player.global_position
		var az := atan2(-to_m.x, -to_m.z)
		var diff2 := wrapf(az - yaw, -PI, PI)
		var x2 := cx + clampf(diff2, -half_win, half_win) * px_per_rad
		draw_colored_polygon(PackedVector2Array([
			Vector2(x2, top + 26), Vector2(x2 - 4, top + 32), Vector2(x2 + 4, top + 32)]),
			m[1])
	# heading caret
	draw_colored_polygon(PackedVector2Array([
		Vector2(cx, top + 21), Vector2(cx - 5, top + 13), Vector2(cx + 5, top + 13)]),
		AMBER)


func _draw_mission(f: Font, _w: float, _h: float) -> void:
	# the objective lives in a quiet panel, upper-left — the visor files it,
	# it doesn't shout it
	var txt := ""
	var col := Color(0.8, 0.45, 1.0)
	var frac := -1.0
	match main.phase:
		"clear":
			match main.mission_type:
				"siphons":
					txt = "SHATTER THE CRYO-SIPHONS · %d REMAIN" % main.siphons.size()
				"uplink":
					if main.player != null and main.terminal != null \
							and main.player.global_position.distance_to(
								main.terminal.global_position) < 4.5:
						txt = "UPLOADING · %d%%" % int(main.upload)
						col = Color(0.3, 0.9, 0.6)
						frac = main.upload / 100.0
					else:
						txt = "REACH THE UPLINK TERMINAL · %d%% SENT" % int(main.upload)
				"hunt":
					txt = "HUNT THE SIEGE WALKER — SHOOT THE KNEES"
					col = Color(1.0, 0.4, 0.3)
		"extract":
			txt = "REACH THE EXTRACTION BEACON"
			col = Color(0.4, 0.85, 1.0)
			if main.player != null:
				var flat: Vector3 = main.player.global_position - main.beacon_pos
				flat.y = 0.0
				if flat.length() < 6.0:
					txt = "HOLD THE BEACON · %d s" % int(ceil(main.extract_hold))
					frac = 1.0 - main.extract_hold / 20.0
		"leaving":
			txt = "THE DROPSHIP IS DOWN"
			col = Color(0.5, 1.0, 0.55)
	# secondaries: optional work the Directorate still expects
	var vleft := 0
	for v in main.vents:
		if is_instance_valid(v):
			vleft += 1
	var secs := [
		["SEAL THE SWARM VENTS" + (" · %d LEFT" % vleft if vleft > 0 else ""),
		 vleft == 0],
		["RECOVER THE DATA CACHE", main.cache_done],
	]
	draw_rect(Rect2(16, 56, 384, 80), Color(0.0, 0.0, 0.0, 0.35))
	draw_line(Vector2(16, 56), Vector2(16, 136), col, 2.0)
	draw_string(f, Vector2(26, 70), "OBJECTIVE", HORIZONTAL_ALIGNMENT_LEFT, -1,
				10, Color(0.5, 0.56, 0.62))
	draw_string(f, Vector2(26, 88), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)
	if frac >= 0.0:
		_slim_bar(26, 94, 200, 3, frac, col)
	var sy := 112.0
	for s in secs:
		var done: bool = s[1]
		var scol := Color(0.4, 0.9, 0.5) if done else Color(0.6, 0.64, 0.7)
		draw_string(f, Vector2(26, sy),
					("[OK] " if done else "[ .. ] ") + str(s[0]),
					HORIZONTAL_ALIGNMENT_LEFT, -1, 11, scol)
		sy += 14.0


func _draw_threat(f: Font, w: float) -> void:
	var cx := w * 0.5
	if main.wave_active:
		var flick := sin(Time.get_ticks_msec() / 220.0) > -0.55
		var txt := "! SWARM SURGE %d — CONTACTS x%d !" % [
			main.wave_idx + 1,
			main.alive_enemies() + main.trickle.size()]
		var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_rect(Rect2(cx - tw / 2 - 14, 44, tw + 28, 24), Color(0.35, 0.05, 0.04, 0.55))
		draw_rect(Rect2(cx - tw / 2 - 14, 44, tw + 28, 24), WARN, false, 1.0)
		draw_string(f, Vector2(cx - tw / 2, 61), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
					WARN if flick else Color(0.55, 0.16, 0.12))
	elif main.state == "playing":
		var txt2 := "NEXT SURGE %d s" % int(ceil(main.between_timer))
		var tw2 := f.get_string_size(txt2, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_string(f, Vector2(cx - tw2 / 2, 58), txt2,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 14, BLUE)


func _slim_bar(x: float, y: float, w: float, bh: float, frac: float, fill: Color) -> void:
	# a thin holographic line: dark track, soft glow pass, bright core
	var cy := y + bh * 0.5
	draw_line(Vector2(x, cy), Vector2(x + w, cy), Color(0.04, 0.06, 0.09, 0.75), bh)
	if frac > 0.0:
		var fx := x + w * clampf(frac, 0.0, 1.0)
		var glow := fill
		glow.a = 0.25
		draw_line(Vector2(x, cy), Vector2(fx, cy), glow, bh + 4.0)
		draw_line(Vector2(x, cy), Vector2(fx, cy), fill, maxf(1.6, bh - 2.0))
	draw_line(Vector2(x + w, y - 1), Vector2(x + w, y + bh + 1),
			  Color(0.30, 0.34, 0.38), 1.0)


func _draw_vitals(f: Font, h: float, p: CharacterBody3D) -> void:
	var bx := 22.0
	var by := h - 74.0
	_slim_bar(bx, by, 230, 5, p.plating / p.max_plating, BLUE)
	var hf: float = p.health / p.max_health
	var col := WHITE if hf > 0.5 else (Color(1.0, 0.6, 0.2) if hf > 0.3 else WARN)
	_slim_bar(bx, by + 9, 230, 9, hf, col)
	_slim_bar(bx, by + 22, 230, 3, p.stamina / p.STAMINA_MAX,
			  Color(0.55, 0.86, 0.47) if p.stamina > 30 else WARN)
	draw_string(f, Vector2(bx + 238, by + 16), str(int(p.health)),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)
	# chem-stims [Q]
	var stim_slots: int = 3 + p.bonus_stims
	for i in range(stim_slots):
		var sc := Color(0.55, 1.0, 0.6) if i < p.stims else Color(0.2, 0.24, 0.26)
		draw_rect(Rect2(bx + 238 + i * 10, by - 2, 6, 12), sc)
	draw_string(f, Vector2(bx + 240 + stim_slots * 10, by + 8),
				main.binding_key("stim"),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.5, 0.55, 0.6))
	# Stance readout: know how tall you're standing
	if p.stance > 0:
		draw_string(f, Vector2(bx + 238 + (3 + p.bonus_stims) * 10 + 24, by + 8),
					"CROUCHED" if p.stance == 1 else "PRONE",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.55, 0.8, 0.95))
	# Corporate Synergy readout
	if p.synergy != "":
		var sname: String = {"HR": "HR SPECIALIST", "TAKEOVER": "HOSTILE TAKEOVER",
							 "TECH": "TECH EVANGELIST"}[p.synergy]
		draw_string(f, Vector2(bx, by + 38), "FULL UNIFORM — " + sname,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.3, 1.0, 0.8))
		if p.synergy == "HR":
			var ready: bool = p.emote_cd <= 0.0
			var etxt := "%s — DEFLECT BLAME" % main.binding_key("emote") if ready \
				else "DEFLECT IN %d s" % int(ceil(p.emote_cd))
			draw_string(f, Vector2(bx + 170, by + 38), etxt,
						HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
						Color(0.3, 0.8, 1.0) if ready else Color(0.45, 0.5, 0.55))


func _draw_weapon(f: Font, h: float, p: CharacterBody3D) -> void:
	var bx := 22.0
	var by := h - 108.0
	# the kit: [1] primary / [2] sidearm, the drawn gun lit up
	var c0 := Color(0.85, 0.88, 0.92) if p.active_slot == 0 else Color(0.42, 0.46, 0.52)
	var c1 := Color(0.85, 0.88, 0.92) if p.active_slot == 1 else Color(0.42, 0.46, 0.52)
	draw_string(f, Vector2(bx, by - 34), "%s %s  x%d" % [
				main.binding_key("grenade"),
				str(p.GRENADES[p.grenade_key]["name"]), p.grenades],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
				Color(0.6, 0.66, 0.72) if p.grenades > 0 else Color(0.4, 0.3, 0.3))
	draw_string(f, Vector2(bx, by - 20), main.binding_key("slot1") + " "
				+ str(p.WEAPONS[p.weapon_key]["name"]),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, c0)
	draw_string(f, Vector2(bx, by - 6), main.binding_key("slot2") + " "
				+ str(p.SIDEARMS[p.side_key]["name"]),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, c1)
	if p.wpn["heat"]:
		# Flux Caster: thermal readout instead of a magazine
		if p.overheated:
			if sin(Time.get_ticks_msec() / 60.0) > 0:
				draw_string(f, Vector2(bx, by + 14), "CELL MELTED — VENTING",
							HORIZONTAL_ALIGNMENT_LEFT, -1, 16, WARN)
		else:
			var hcol := BLUE if p.heat < 50 else (Color(1.0, 0.6, 0.2)
					if p.heat < 80 else WARN)
			draw_string(f, Vector2(bx, by + 14), "%d%%" % int(p.heat),
						HORIZONTAL_ALIGNMENT_LEFT, -1, 24, hcol)
		var frac: float = p.heat / 100.0
		var hc := Color(0.35 + 0.65 * frac, 0.7 - 0.5 * frac, 1.0 - frac)
		_slim_bar(bx, by + 22, 230, 5, frac, hc)
		return
	if p.reloading:
		draw_string(f, Vector2(bx, by + 14), "SWAPPING CLIP",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 16, AMBER)
		_slim_bar(bx, by + 20, 120, 4, 1.0 - p.reload_timer / p.reload_total, AMBER)
	else:
		var col := WHITE if p.ammo > p.mag_size / 4 else WARN
		draw_string(f, Vector2(bx, by + 18), str(p.ammo),
					HORIZONTAL_ALIGNMENT_LEFT, -1, 30, col)
		draw_string(f, Vector2(bx + 44, by + 18), "/ %d" % p.reserve,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.55, 0.58, 0.62))


func _draw_strats(f: Font, w: float, h: float) -> void:
	var s: Node = main.strats
	# bottom-center loadout chips (five wide)
	var x := w * 0.5 - 400.0
	for key in s.CODES:
		var spent: bool = s.uses.get(key, 999) <= 0
		var ready: bool = s.cooldowns[key] <= 0.0 and not spent \
			and not main.anchor_retasked and main.ion_t <= 0.0
		var base_col: Color = BLUE if key in ["AMMO_POD", "SENTRY_TURRET"] else WARN
		var col: Color = base_col if ready else Color(0.35, 0.37, 0.4)
		draw_rect(Rect2(x, h - 40, 150, 30), Color(0.06, 0.07, 0.1, 0.7))
		draw_rect(Rect2(x, h - 40, 150, 30), col, false, 1.0)
		var code := ""
		for d in s.CODES[key]:
			code += ARROW[d] + " "
		var chip_name: String = s.NAMES[key]
		if s.uses.has(key):
			chip_name += "  x%d" % s.uses[key]
		draw_string(f, Vector2(x + 8, h - 27), chip_name,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
		if main.anchor_retasked:
			draw_string(f, Vector2(x + 8, h - 15), "RETASKED",
						HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
		elif main.ion_t > 0.0:
			draw_string(f, Vector2(x + 8, h - 15), "ION STORM",
						HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
		elif spent:
			draw_string(f, Vector2(x + 8, h - 15), "EXPENDED",
						HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
		elif ready:
			draw_string(f, Vector2(x + 8, h - 15), code,
						HORIZONTAL_ALIGNMENT_LEFT, -1, 12, AMBER)
		else:
			draw_string(f, Vector2(x + 8, h - 15), "%ds" % int(s.cooldowns[key]),
						HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
		x += 160.0

	# live input readout while SHIFT is held
	if s.open:
		var seq_txt := "> "
		for d in s.seq:
			seq_txt += ARROW[d] + " "
		draw_rect(Rect2(24, h * 0.5 - 40, 260, 60), Color(0.04, 0.08, 0.12, 0.85))
		draw_rect(Rect2(24, h * 0.5 - 40, 260, 60), BLUE, false, 1.0)
		draw_string(f, Vector2(36, h * 0.5 - 18), "COMMAND INPUT MATRIX",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 14, BLUE)
		draw_string(f, Vector2(36, h * 0.5 + 6), seq_txt,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 18,
					AMBER if s.matched != "" else WHITE)
	if s.armed != "":
		var txt: String = s.NAMES[s.armed] + " — CLICK TO THROW FLARE"
		var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_string(f, Vector2(w * 0.5 - tw / 2, h - 60), txt,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 16, AMBER)


func _draw_msgs(f: Font, w: float, h: float) -> void:
	var y := h * 0.30
	for m in msgs.slice(-4):
		var c: Color = m[1]
		c.a = clampf(m[2] * 1.5, 0.0, 1.0)
		var tw := f.get_string_size(m[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		draw_rect(Rect2(w * 0.5 - tw / 2 - 8, y - 14, tw + 16, 20),
				  Color(0.0, 0.0, 0.0, 0.25 * c.a))
		draw_string(f, Vector2(w * 0.5 - tw / 2, y), m[0],
					HORIZONTAL_ALIGNMENT_LEFT, -1, 17, c)
		y += 24.0


func _draw_reticle(w: float, h: float, p: CharacterBody3D) -> void:
	if main.state != "playing":
		return
	var cx := w * 0.5
	var cy := h * 0.5
	var r: float = 10.0 + p.recoil
	if p.sprinting:
		r += 8.0
	if p.aiming:
		r *= 0.55
	draw_arc(Vector2(cx, cy), r, 0, TAU, 40, WHITE, 1.2)
	draw_circle(Vector2(cx, cy), 1.6, WHITE)
	draw_line(Vector2(cx, cy + r), Vector2(cx, cy + r + 5), WHITE, 1.0)
	# hit confirmation: four ticks; red and bold on a kill
	if hitmark_t > 0.0:
		var hc := WARN if hitmark_kill else WHITE
		var hw := 2.4 if hitmark_kill else 1.4
		for d in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			draw_line(Vector2(cx, cy) + d * (r * 0.4),
					  Vector2(cx, cy) + d * (r * 0.4 + 7.0), hc, hw)


func _draw_visor(w: float, h: float, p: CharacterBody3D) -> void:
	# The diegetic layer: you are looking through a tactical visor, and the
	# visor is having a mission too.
	# curved corner frame
	var vc := Color(0.5, 0.75, 0.95, 0.10)
	draw_arc(Vector2(96, 96), 72.0, PI, PI * 1.5, 24, vc, 2.0)
	draw_arc(Vector2(w - 96, 96), 72.0, PI * 1.5, TAU, 24, vc, 2.0)
	draw_arc(Vector2(w - 96, h - 96), 72.0, 0, PI * 0.5, 24, vc, 2.0)
	draw_arc(Vector2(96, h - 96), 72.0, PI * 0.5, PI, 24, vc, 2.0)

	# structural integrity bleeding in red from the frame
	var hf: float = p.health / p.max_health
	if hf < 0.35 and p.alive:
		var a := (0.35 - hf) * 1.6 * (0.7 + 0.3 * sin(Time.get_ticks_msec() / 180.0))
		var red := Color(0.8, 0.1, 0.08, clampf(a, 0.0, 0.5))
		draw_rect(Rect2(0, 0, w, 22), red)
		draw_rect(Rect2(0, h - 22, w, 22), red)
		draw_rect(Rect2(0, 0, 22, h), red)
		draw_rect(Rect2(w - 22, 0, 22, h), red)

	# static and scanlines: the gear struggling under warzone pressure
	var noise := clampf(p.shake / 7.0, 0.0, 1.0)
	if main.ion_t > 0.0:
		noise = maxf(noise, 0.55)
	if main.psi_t > 0.0:
		noise = maxf(noise, 0.4)
	if p.overtime_t > 0.0:
		noise = maxf(noise, 0.35)
	if noise > 0.05:
		for i in range(int(16.0 * noise)):
			draw_rect(Rect2(randf() * w * 0.85, randf() * h,
							randf_range(30, 220), 1.5),
					  Color(0.7, 0.9, 1.0, randf() * 0.22 * noise))
		if randf() < noise * 0.5:
			draw_rect(Rect2(0, randf() * h, w, randf_range(2.0, 6.0)),
					  Color(0.8, 0.95, 1.0, 0.06 + 0.10 * noise))
	# chromatic aberration on the frame when the projector is struggling
	if noise > 0.3:
		var off := noise * 2.5
		draw_arc(Vector2(96 - off, 96), 72.0, PI, PI * 1.5, 24,
				 Color(1.0, 0.2, 0.2, 0.12), 2.0)
		draw_arc(Vector2(96 + off, 96), 72.0, PI, PI * 1.5, 24,
				 Color(0.2, 0.8, 1.0, 0.12), 2.0)
		draw_arc(Vector2(w - 96 - off, h - 96), 72.0, 0, PI * 0.5, 24,
				 Color(1.0, 0.2, 0.2, 0.12), 2.0)
		draw_arc(Vector2(w - 96 + off, h - 96), 72.0, 0, PI * 0.5, 24,
				 Color(0.2, 0.8, 1.0, 0.12), 2.0)


func _overlay(f: Font, w: float, h: float, title: String, sub: String, col: Color) -> void:
	draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.55))
	var tw := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 48).x
	draw_string(f, Vector2(w * 0.5 - tw / 2, h * 0.45), title,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 48, col)
	var sw := f.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	draw_string(f, Vector2(w * 0.5 - sw / 2, h * 0.45 + 40), sub,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 18, WHITE)


# ------------------------------------------------------------ performance review

func _ctext(f: Font, cx: float, y: float, text: String, size: int, col: Color) -> void:
	var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(f, Vector2(cx - tw / 2.0, y), text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func _grade_letter(t: float) -> Array:
	# Maps a 0..1 performance fraction to a letter, a colour, and HR's verdict
	if t >= 0.85:
		return ["A", Color(0.4, 1.0, 0.5), "Exceeds expectations."]
	elif t >= 0.65:
		return ["B", Color(0.7, 1.0, 0.5), "Meets expectations."]
	elif t >= 0.45:
		return ["C", AMBER, "Adequate. Barely."]
	elif t >= 0.25:
		return ["D", Color(1.0, 0.6, 0.2), "Needs improvement."]
	return ["F", WARN, "Escalated to HR."]


func _review_row(f: Font, lx: float, vx: float, gx: float, y: float,
				 label: String, val: String, frac: float) -> void:
	draw_string(f, Vector2(lx, y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, WHITE)
	draw_string(f, Vector2(vx, y), val, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, BLUE)
	var g := _grade_letter(frac)
	draw_string(f, Vector2(gx, y), str(g[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, g[1])
	draw_string(f, Vector2(gx + 34, y), str(g[2]), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, g[1])


func _review_overlay(f: Font, w: float, h: float, success: bool) -> void:
	draw_rect(Rect2(0, 0, w, h), Color(0.02, 0.02, 0.03, 0.85))
	var cx := w * 0.5
	var y := h * 0.13
	_ctext(f, cx, y, "PERFORMANCE REVIEW", 46, AMBER)
	y += 32
	_ctext(f, cx, y, "LIQUIDATION DIVISION  ·  POST-DEPLOYMENT EVALUATION", 16, BLUE)
	y += 46
	var vcol: Color = Color(0.4, 1.0, 0.5) if success else WARN
	_ctext(f, cx, y, ("CONTRACT FULFILLED" if success else "CONTRACT TERMINATED"),
		   30, vcol)
	y += 56

	var samples: int = main.player.samples if main.player != null else 0
	var used: int = maxi(0, 4 - main.lives)
	var mins: int = int(main.mission_time) / 60
	var secs: int = int(main.mission_time) % 60
	var f_score := clampf(float(main.score) / 6000.0, 0.0, 1.0)
	var f_samp := clampf(float(samples) / 5.0, 0.0, 1.0)
	var f_head := 1.0 - clampf(float(used) / 4.0, 0.0, 1.0)
	var f_time := 1.0 - clampf(main.mission_time / maxf(1.0, main.mission_limit), 0.0, 1.0)

	var lx := w * 0.27
	var vx := w * 0.52
	var gx := w * 0.68
	_review_row(f, lx, vx, gx, y, "QUOTA ATTAINMENT", "%d pts" % main.score, f_score)
	y += 40
	_review_row(f, lx, vx, gx, y, "ASSET RECOVERY", "%d samples" % samples, f_samp)
	y += 40
	_review_row(f, lx, vx, gx, y, "HEADCOUNT EFFICIENCY",
				"%d contractors expended" % used, f_head)
	y += 40
	_review_row(f, lx, vx, gx, y, "TIME-TO-VALUE", "%d:%02d on the clock"
				% [mins, secs], f_time)
	y += 58

	var overall := (f_score + f_samp + f_head + f_time) / 4.0
	if not success:
		overall *= 0.5
	var og := _grade_letter(overall)
	_ctext(f, cx, y, "OVERALL RATING:   %s" % str(og[0]), 30, og[1])
	y += 34
	_ctext(f, cx, y, str(og[2]), 18, og[1])
	y += 42
	var plan := "Recommendation: promotion pending headcount review."
	if overall < 0.3:
		plan = "Recommendation: contract voided, deposit forfeited."
	elif overall < 0.65:
		plan = "Recommendation: Performance Improvement Plan issued."
	_ctext(f, cx, y, plan, 16, WHITE)
	y += 42
	_ctext(f, cx, y, "ENTER — return to the Void Anchor", 18, AMBER)
