# BREACH-DROP 3D (Godot 4 port)

The real-engine port of the BREACH-DROP prototype. This is a **vertical
slice**: The White Reach tundra with the core combat loop, running on a true
GPU renderer — realtime global illumination (SDFGI), SSAO, ACES tonemapping,
bloom, volumetric ground fog, distance haze, GPU snow particles, and a sun
with a visible disk. No assets to download; the entire world is built
procedurally by the scripts.

## Run it

1. Download **Godot 4.4** (standard build, .NET not required):
   https://github.com/godotengine/godot/releases/tag/4.4-stable
   → `Godot_v4.4-stable_win64.exe.zip`
2. Open Godot → **Import** → select this folder's `project.godot`
3. Press **F5** (Run Project)

> **Why 4.4 and not the latest?** On this machine (RTX 5050 Laptop GPU,
> current NVIDIA driver), Godot **4.5, 4.6 and 4.7 crash on startup with an
> empty project** on every rendering backend (Vulkan, D3D12, OpenGL) — an
> engine/driver incompatibility, not a project bug. 4.3 and 4.4 were
> verified working here (hundreds of frames rendered). If you update your
> NVIDIA driver later (GeForce/NVIDIA app), 4.7 will likely start working —
> the project itself is fully compatible with it (validated headless).

First launch compiles shaders — give it a few seconds. If it runs slowly on
your GPU, open `scripts/main.gd` and set `env.sdfgi_enabled = false`.

## Controls

| Input | Action |
|---|---|
Standard FPS defaults — every key below is rebindable from the
**4·CONTROLS** terminal in the launch bay (saved to `keybinds.cfg`):

| Input | Action |
|---|---|
| Mouse | Look / aim (full pitch: sky to boots) |
| WASD | Move (camera-relative, with momentum) |
| SHIFT | Sprint (stamina; stands you up) |
| CTRL / X | Crouch / go prone (braced fire, smaller silhouette) |
| SPACE | Combat dive (ends prone — face down, properly) |
| LMB / RMB | Fire / aim |
| R | Reload (rounds left in the clip are discarded) |
| 1 / 2 | Draw the primary / the sidearm |
| F | Throw the equipped grenade |
| Q | Chem-stim (heals, sets fractures) |
| E | Interact / mount the skimmer |
| G | Emote — a voice-pack bark; with a full HR uniform it becomes Deflection of Blame |
| Hold TAB + arrows | Type a stratagem code |
| LMB (after release) | Throw the flare |
| ESC | Pause / release the mouse |
| ENTER | Restart after victory / defeat |

## Stratagems

| Code | Asset |
|---|---|
| `< ^ v v <` | Kinetic Strike — 450mm rod from orbit (friendly fire is real) |
| `v v ^ >` | Thermal Barrier — a 10s heat wall that melts everything inside |
| `^ v > < ^` | Ammo Pod — full resupply + 50 health on pickup |

## Two warfronts

The holo-table now carries the war map: **THE WHITE REACH** (icy tundra —
Whiteout / Longnight / Blackstorm) and **CINDERFALL** (a burned volcanic
world — Cinderwake / Emberfall / Pyrecrown). Cinderfall trades blizzards
for drifting embers, obsidian monoliths, ember-lit crater rims — and
**magma pools that burn anyone who stands in them**. Liberation tracks
per operation across both worlds.

A **VULTURE skimmer** is parked near every drop point: walk up, press
**E** to ride (fast, drifty, no shooting while riding), **E** again to
dismount. Cross the map in seconds; fight on your feet.

## The squad, the arsenal, the war

- **Two AI Breachers** drop with you, follow your lead, pick their own
  targets, and hold fire when you cross their line. When one dies, a
  reinforcement hellpod delivers the next.
- **Primary weapons** (pick in the armory, saved between runs): MK-4 Rifle,
  Cryo Shotgun (8 chilling pellets), Longshot DMR (knee-joint money), the
  Flux Caster (no ammo — manage heat, R vents early), plus the Corporate
  Claims arsenal: the **'Downsizer' Marksman** (semi-auto plate-opener,
  massive recoil), the **'Redundancy' Shotgun** (drum-fed automatic
  dispersion, paperwork-grade reloads), the **'Synergy-6' Laser** (heat-sink
  beam — pace it for infinite ammo), and the **'Audit-Gas' Dispenser**
  (corrosive stream that ignores armor and dissolves targets over time).
- **Sidearms** (key **2**, key **1** back to the primary): the **Notice of
  Eviction** hand-cannon (six staggering rounds), the **Micro-Manager**
  machine pistol (the whole mag in 1.5 s), and **Severance Pay** (a slow
  plasma ball that pops armored structures at range).
- **Every weapon has its own model**: the pencil-barreled Longshot with
  its optic, the coil-wrapped Flux Caster, the drum-fed Redundancy, the
  finned Synergy-6 emitter, the Audit-Gas tank-and-nozzle, the Eviction's
  revolver drum, the Severance's unstable violet orb — swapping slots
  swaps the model in your hands, and the armory mannequin shoulders
  whatever primary you've selected.
- **Right-click aims** (tight spread, slow walk); **Q** fires a chem-stim.
- **Enemy ladder**: Shard-Ticks, armored ticks, Husk Gunners (ranged),
  Spitters (arcing acid artillery — they rupture when killed), Prism-Walker
  brutes, and the **SIEGE WALKER** boss: shoot the glowing knees (3x) —
  hull hits do almost nothing.
- **Missions rotate per operation**: siphon demolition (Whiteout), the
  uplink hold (Longnight — stand at the terminal while it uploads), and
  the Siege Walker hunt (Blackstorm).
- **Samples**: five glowing canisters per drop. Each one you're carrying
  when the dropship leaves adds Liberation — die and they're snow.
- **Layered score**: ambient drone, combat pulse, and extraction climax
  crossfade with the state of the fight (all synthesized, `sfx/`).
- **ESC pauses** with settings: mouse sensitivity, volume, GI toggle.
  Loadout and settings persist between sessions.

## The deck: three terminals

The launch bay is no longer one flat menu — it's three terminal tabs on
the Void Anchor's command deck:

1. **WARBOARD** — pick the warfront and operation, and read the active
   **planetary modifiers** before you commit: on The White Reach,
   *Extreme Cold* makes heat-sink weapons overheat 50% slower but drains
   sprint stamina 25% faster; on Cinderfall, *Atmospheric Interference*
   makes every stratagem call-in take 25% longer.
2. **ARMORY** — primaries and sidearms with a live **spec sheet**: damage,
   magazine, fire rate, reload, recoil bar, traits, and **armor
   penetration on a 0–10 scale**. Penetration is deterministic: under the
   target's armor value the round **ricochets for zero damage**, dead even
   chips for half, over it punches clean. Armored ticks and Prism-Walkers
   wear armor 3; the Merger and the Siege hull wear 4. Light weapons carry
   AP 2, marksman/energy weapons AP 4. Corrosion ignores the whole
   conversation.
3. **REQUISITION** — the Asset Suit (see below) plus paint and visor glass.

## The Asset Suits (Corporate Claims)

Your **Body Chassis is your weight class** — and it *is* one set's body
piece. Add the matching **Visor** and **ID Tag** to wear the full uniform
and activate its Corporate Synergy. **Seven chassis** now cover the three
weight classes, and every one reads differently on the mannequin and in
the field: weight shapes the silhouette (LIGHT runs lean, HEAVY fills the
doorway), trim color declares the set (HR blue, Tech green, Takeover red,
Underwriter grey), and each rig's perk hardware is visibly bolted on —
radar masts, siege slabs, med-pod cells, the Underwriter's hard-shell
case. New frames: the **COURIER** (light HR: +30% sprint, no radar), the
**AUDITOR EXO** (medium Tech: +50% throw, +1 grenade, +1 stim), and the
**BULWARK** (heavy Takeover: a walking fire door).

| Chassis | Weight / Set | What the chassis does | Full-Uniform Synergy |
|---|---|---|---|
| **Recon Weave** | Light — The HR Specialist | Zero plating, +20% sprint, tactical radar pings every hostile within 70 m each 3 s | **Deflection of Blame** — press **G** to redirect all aggro to the closest coworker within 15 m and sprint out of the meeting |
| **Contractor Plate** | Medium — The Tech Evangelist | The corporate balance: +2 chem-stim capacity, +30% beacon throw range | **Synergy Cascade** — every perfect first-try stratagem code cuts all active cooldowns by 5 s |
| **Siege Carapace** | Heavy — The Hostile Takeover | -30% speed, -50% explosive damage, deep plating: survives your own orbital math | **Sunk Cost Fallacy** — lethal damage starts 6 s of **OVERTIME**: immune, infinite ammo, double speed. Then you detonate |

Visor pieces: HR -30% detection · Takeover -30% braced recoil · Tech +10%
cooldown rate. ID Tags: HR +30% stamina regen · Takeover +15 plating ·
Tech +1 chem-stim. Mix-and-match keeps the bumps, forfeits the synergy.

## Drop coordinates

**Launch no longer fires blind.** ESTABLISH DROP COORDINATES opens a
tactical map of the AO: recon has already flagged the objective
**signals** (purple) and patrol activity (red). Click your LZ:

- **Hot drop** (within 25 m of a signal): patrols come early and a Swarm
  breach opens on your head seconds after landing.
- **Quiet sector** (60 m+ from every signal): an unmonitored insertion —
  the first patrol takes its time.

The objectives on the ground are exactly where the map said they'd be.

## Disposable identities

You are not a hero; you are a staffing pipeline. Every gantry spike and
every reinforcement delivers a **brand-new recruit** — serial number,
nickname, and personality (`RCT-4471 'STAPLER' · PANICKED`). The **voice
pack** (Requisition deck) decides who screams out of the next pod:
RANDOMIZED, PANICKED, MANIACAL, or CORPORATE — recruits bark on deployment,
extraction, and death. Pick a **victory pose** for the dropship (T-POSE OF
POWER is available and load-bearing).

## The field kit and boosters

- **Grenade slot (F)**: PINK SLIP FRAG (honest 6 m termination), NDA
  CANISTER (10 s of smoke — nothing inside gets spotted or shot at), or the
  RESTRUCTURING CHARGE (a demo charge that seals Swarm vents).
- **Booster** (one passive per drop): EXPENSE ACCOUNT (+50% reserves),
  SATELLITE UPLINK (radar pings on any chassis), GYM MEMBERSHIP (better
  stamina economy), or OVERTIME AUTHORIZATION (+2:00 mission window).
- **UNDERWRITER MK-II** chassis: no set affiliation, no synergy — but the
  **ACT OF GOD CLAUSE** gives a 50% chance to survive lethal damage at 1 HP.

## The presentation layer

Rendering upgrades on top of the base pipeline (ACES tonemapping, HDR
bloom, SSAO, SDFGI, and SSR have been on since the first build):

- **4096px directional shadows** with high-quality soft filtering and a
  180 m shadow range — long, dramatic terrain shadows; TAA smooths the
  procedural detail.
- **Material wear on the armor**: scratched-metal roughness maps and
  dented normal breakup on every plate, over a light-absorbing cloth
  under-suit — the plating catches light unevenly, the way used gear does.
- **Terrain detritus**: 700 scattered pebbles and 90 cracked-ground slabs
  per map (one draw call each) plus doubled terrain normal grain, so the
  drifts stop reading as flat sheets.
- **The holographic HUD restyle**: everything renders in a clean system
  monospace (Cascadia Mono/Consolas); health, stamina, and plating are
  thin neon lines with soft glow cores instead of retro rectangles; the
  objective is filed into a quiet upper-left panel with a low-opacity
  backing instead of shouting from screen center; and the visor frame
  picks up chromatic aberration when the projector is under stress.



Graphics that communicate danger, not just decorate it:

- **Atmospheric soup**: every world's volumetric fog catches light in its
  own color — snow-white on the Reach, ember-brown on Cinderfall, bruised
  violet on the Verge. The sun cuts god-ray shafts through it, and the big
  light sources (extraction pillar, breach flares, the orbital laser,
  your own muzzle flash) physically carve the fog around them. In heavy
  weather you'll see the glow of an eye-slit before you see the machine
  wearing it.
- **Pyroclastic explosions**: every blast now kicks a billowing black
  smoke column into the sky, throws glowing embers ballistically, kicks
  up rock debris, and leaves a **scorch crater** the ground keeps for 40
  seconds. The pressure wave shoves you — anything with real force behind
  it (rocket salvos, grenades, orbitals) knocks you flat and tumbling.
- **The ground keeps a ledger**: kills splatter the terrain — neon acid
  for the Swarm, glowing blue for the Arbitration, black oil for the
  Reclaimers — fading out after 45 seconds.
- **The battle-scarred suit**: you drop in factory-fresh. The mission
  cakes your armor with frost or soot — slowly by default, quickly when
  you're bogged, prone, blast-tossed, or getting hit. Every death resets
  it: new recruit, clean paint.
- **The diegetic visor**: a curved frame at the screen corners, red
  integrity bleed from the edges when you're near death, and localized
  static/scanlines whenever the gear is under pressure — heavy shake, ion
  storms, psionic inversions, Overtime.

## The living map

The terrain is a combatant:

- **Natural geography**: smooth rolling dunes and soft interior highlands
  give way to a **ring of climbable mountains** toward the AO edge, and
  four hollow **cave shelters** per map offer hard cover you can actually
  stand inside. Lava pools and deep drifts blend into the ground with
  feathered edges instead of sitting on it like coasters.
- **The vent network scales**: higher threat tiers seed up to four Swarm
  vents, spawns pour disproportionately out of the living ones (40% of
  all pressure), and every extra vent hardens the whole network's chitin —
  more vents, more enemies, tougher to seal.
- **Every mission carries secondaries**: seal the vents and recover the
  **data cache** (stand over it to siphon) — each pays +2 liberation at
  extraction on top of score.

- **Deep drifts / ash mires**: pale powder fields on the Reach, black mud
  on Cinderfall — walk into one and you wade at half speed (BOGGED on the
  HUD). Plan your escape routes around them.
- **Dynamic events** roll in every couple of minutes: **seismic tremors**
  (everyone staggered, footing gone), **ion storms** (25 s with the
  stratagem uplink dead), **meteor barrages** (ash worlds — a walking
  carpet of impacts), and on the Verge, **psionic inversions** (8 s of
  reversed movement and rotated stratagem arrows. Trust nothing).
- **Points of interest**: three crash sites with salvage (samples, stims,
  field kit, ammo) hide on every map — spot them by physically scouting
  within 22 m, or find the **radar tower** and stand at the mast for 3 s:
  the whole sector confesses, plus 90 s of hostile radar pings.
- **Blast physics**: explosions now shove you (and rocket salvos will
  happily shove you out of cover).

## Three fronts, three combat puzzles

- **THE SILICON SWARM** (White Reach): the melee tide you know — now with
  **Longsight Husks** (amber-eyed snipers that tag you from 60 m) and
  translucent **Stalkers** (fast, hard-hitting ambushers you'll barely
  see coming). Keep moving, watch the patrols.
- **THE RECLAIMERS** (Cinderfall): repo-bots that shoot back. **Clerks**
  advance in squads, plant their feet, and fire tight bursts — leave one
  alive too long and it raises a red flare for a **repo dropship**.
  **Foremen** come in two patterns: a ballistic slab that pings frontal
  hits (flank it), and a rocket carrier whose arcing salvos blow you out
  of cover. Use the rocks. There is no shame in a rock.
- **THE ARBITRATION** (Meridian Verge): shielded psionic manipulators.
  **Arbiters** carry regenerating shields that absorb at most 15 damage
  per hit — a Micro-Manager strips one in a second; a Longshot DMR wastes
  its whole round. Crack the shield and they blink sideways. The Voteless
  tide runs interference while psionic inversions scramble your hands.

## The war table

The warboard now runs the whole campaign:

- **Supply lines**: the sector map chains VOID ANCHOR → WHITE REACH →
  CINDERFALL → **MERIDIAN VERGE**. The Verge stays severed until the rear
  fronts hold **80 combined liberation points** — then a third world opens
  with SEVERE/APOCALYPTIC operations and all three planetary modifiers at
  once, including CAUSTIC SQUALLS (-30% plating).
- **Threat tiers 1–10** on every operation. Higher tiers spawn richer
  sample fields (4→8 canisters) and move the liberation bar further.
- **Major Orders**: the Directorate keeps one standing order (push a named
  operation to a liberation target within 3 real days). Fulfil it and your
  next drop carries **Orbital Laser x4**.

## Procedural friction

The clock is the real enemy:

- **Mission window: 12 minutes.** Spawn pressure climbs ~25% every four
  minutes on the clock. When the window closes the **Void Anchor is
  retasked** — no more stratagems, and the Swarm pushes twice as hard.
  Extract or don't.
- **Stance-based gunplay**: crouching (**C**) cuts recoil 30% and sway
  30%; prone (**X**) cuts recoil 60% and sway 55% — and shrinks your
  patrol-detection radius (crouch ×0.7, prone ×0.45, stacking with HR
  optics). Sprinting stands you up. Movement while braced is slow.
- **Localized limb damage**: heavy hits can fracture an **arm** (aim sway
  nearly doubles) or a **leg** (sprint disabled, 20% slower). A chem-stim
  (**Q**) sets the bones.
- **Swarm vents** (orange on the drop map and compass): structural
  spawners that keep birthing ticks into the sector. Small arms ping off
  the chitin — **only explosives seal them** (Kinetic Strike, Severance
  Pay, the Orbital Laser's ground fire). Sealing one thins local pressure
  and pays 400 score.
- **Stratagem budgets**: the Orbital Laser carries **3 uses per mission**;
  the chip on the HUD counts them down.
- **The Directorate is watching**: every couple of minutes an unseen Game
  Master nudges the war — a surprise Swarm push, a free orbital window
  with all cooldowns waived, or a passed supply audit with a crate on the
  house.
- **The war does not wait**: Liberation decays ~3% per real day while
  you're off-contract. The front line remembers whether you show up.

## The mission loop

1. Pick your operation and rig, launch, sit through the briefing crawl
   (any key skips it)
2. **Shatter the 3 cryo-siphons** — purple markers on the compass
3. The **extraction beacon** lights (cyan pillar) — run to it
4. **Hold the beacon ring for 20 seconds** while the Swarm surges twice as
   hard; leaving the ring pauses the clock
5. The dropship descends. Victory feeds the **Liberation %** for that
   operation (persistent, shown in the launch bay)

Meanwhile: **patrols** wander the reach — if one spots you it screams a
**SWARM BREACH** into existence (red flare, ticks erupting from the snow).
Kill patrols before they see you.

New tools: `v ^ > ^` **Sentry Turret** (30s of automated fire — it does not
check IFF, stay behind it), `> v ^ ^ v` **Orbital Laser** (a sweeping beam
that burns a random line across the field), and **chem-stims on Q** (3
charges, instant heal over time, refilled by Ammo Pods).

All sound effects are procedurally synthesized WAVs in `sfx/` — regenerate
with the Python script if you want to tweak them.

## What's in this slice

- **The Launch Bay**: the game boots onto the Void Anchor — a holographic
  planet table for operation select and an armory mannequin for character
  customization (armor rig with real stats, paint scheme, visor color)
- **Three operations** on the White Reach, each a different war:
  *Whiteout* (clear daylight, standard), *Longnight* (red dusk, hard),
  *Blackstorm* (full blizzard, knife-range visibility, brutal)
- **Real terrain**: rolling heightmap snow dunes with matched collision,
  noise-detailed snow material, dense frozen scrub, boulders, ice spires,
  and two layered rings of snow-capped mountains fading into the haze
- Over-the-shoulder camera with head-bob and sprint-FOV, full pitch freedom
- Escalating Swarm surges: Shard-Ticks (lunge, melee, glass-burst on death)
  and Prism-Walkers (armored tripods — shoot the charging lens for double
  damage and a catastrophic backfire)
- Stratagem flow: code → flare → pod physically falls from the sky → impact
- Compass with walker threat markers, surge alert banner, minimalist vitals,
  circle-and-dot reticle that blooms with recoil and sprinting
- 4 Gantry Spikes (lives), score, victory/defeat back to the Void Anchor

Headless smoke-test / demo flag: run with `-- autodeploy` to skip the menu
after 2 seconds (used for automated validation). Add `corp` for the
Corporate Claims kit, `ash` / `verge` to pick the warfront, and `events`
to force-fire the environmental event roller.

## Roadmap (ported from the pygame prototype's design)

- Flux Engineer doctrine (heat/overheat/vent) and armor rig selection
- The other six zones incl. elevation maps and the frontline assault mode
- Omni-Frame exosuit, Chem-Injector, Kinetic Anchor
- The Holo-Glove (Grid / Uplink / Vector Map) — build as a `SubViewport`
  panel projected onto a wrist quad
- Asset pass: replace procedural primitives with free PBR packs
  (AmbientCG textures, Kenney/Quaternius models) for the final look
