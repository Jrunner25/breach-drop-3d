# BREACH-DROP 3D

## *Liquidators: Corporate Claims* — Worksite Design Bible

### Volume II — Planetary Worksites & the Environmental Hazard Sandbox

---

> **INTERNAL DISTRIBUTION ONLY — LIQUIDATION DIVISION**
> *"There are no dangerous worksites. Only under-motivated employees."*
> — Onboarding Deck, Slide 34

You are a contract **Liquidator**, fired at the surface of a repossessed
asset from the orbital cruiser *Void Anchor*. The planets in this document
are not battlefields. They are **worksites** — sites the Company has
foreclosed on, and which the local ecology, geology, and weather have not
yet been informed are Company property. Your job is to inform them.

Every worksite in this bible is built on one principle: **the environment
is the primary antagonist, and the enemies are just its enforcement arm.**
The Silicon Swarm, the Reclaimers, the Overgrowth, and the Arbitration are
all deadly — but on any given drop, more Liquidators are lost to the
*ground*, the *air*, and the *dark* than to hostile fire. That is by
design. The Company calls it "environmental accountability." We call it
friction.

---

## PART ONE — THE CORE COMBAT SANDBOX

Before the worksites, the four pillars every one of them is built on.

### 1. Physicalized, Symmetrical Hazards

The single most important rule of the sandbox: **every environmental effect
applies to players and enemies alike.** This is what separates a hazard from
a stat debuff. A bog that only slows you is a punishment. A bog that slows
*everything* is a battlefield — you can kite a heavy into it, funnel a swarm
through it, or die in it because you forgot it slows your dive too.

Concretely, every hazard resolves against a shared physics layer:

- **Movement friction** (bogs, snowdrifts, ice) modifies acceleration and
  top speed on any `CharacterBody3D` — you, your squad, a charging tick, a
  lumbering Merger.
- **Damage-over-time fields** (sulfur, acid, magma) tick against anything
  standing in the radius. Your grenade that knocks an enemy into a gas
  pocket is doing your job for you.
- **Impulse events** (tremors, wind, ion discharge) apply forces and stagger
  to bodies and to *loose objects* — including thrown grenades and, crucially,
  **stratagem beacons**, which are physics props, not menu selections.
- **Occlusion** (fog, reeds, smog, darkness) degrades line-of-sight and target
  acquisition for both the player's reticle *and* enemy aggro cones.

If it hurts you, it can hurt them. Learn the room, and the room becomes a
weapon.

### 2. Lighting Is Information, Not Decoration

The transition away from the flat retro renderer means light now *carries
tactical data*. Volumetric fog, god-rays, muzzle flash, magma glow, glowing
enemy eyes, and your own flashlight cone are the primary channels through
which a player reads threat. Worksites are therefore designed around a
**visibility economy**: how far can you see, how far can *they* see you, and
what does it cost to change that (a flare, a muzzle flash that gives away
your position, a lightning strike that reveals the whole field for half a
second).

The darkest and foggiest worksites are not "harder" because enemies have
more health. They are harder because **information is scarce and expensive.**

### 3. Two Weapon Economies, Two Failure Modes

The sandbox runs two parallel weapon-heat models, and worksites are tuned to
punish one or the other:

- **Kinetic (mag-fed):** finite reserve ammo, hard reloads that *discard the
  remaining clip*. Punished by worksites that separate you from resupply
  (verticality, choke points, blackout).
- **Flux (heat-sink / energy):** infinite ammo, but overheats and must vent.
  Punished by heat (faster overheat) and rewarded by cold (slower overheat) —
  and gutted by worksites that drain battery charge outright.

A worksite's climate should make the player *feel* their loadout choice was
right or wrong within the first ninety seconds.

### 4. Friction as the Pacing Engine

"Terrain friction" is the design lever that controls tempo. High-friction
zones (bogs, drifts, choke points) are slow, tense, deliberate — they turn a
sprint into a wade and a firefight into a siege. Low-friction zones (black
ice, open basalt flats, wind-swept bridges) are fast, chaotic, and lethal —
momentum you can't fully control. **A good worksite alternates the two**, so
the mission has a rhythm: creep, sprint, creep, fall.

---

## PART TWO — THE WORKSITES

Each dossier below is written for both the writers' room and the engine.
Where it says **[Engine]**, that line ties the concept to systems that
already exist in the build (`biome` palette, the `hazards[]` array,
volumetric fog density, the stratagem beacon as a physics body, destructible
cover, `add_shake`, DOT application). Worksites marked **BUILT** already have
a biome in the project; the rest are new palette + hazard entries.

---

### MAP 1 — THE CUBICLE SWAMPS
#### *Worksite designation: "The Wetlands Reclamation & Effluent Site"*
**Biome: Wetland / Toxic Waste · Hostile Force: The Overgrowth · Status: BUILT (swamp)**

> The brochure called it "a lush green campus with abundant natural water
> features." The water features are chemical runoff. The lush green is a
> fungal intelligence that has been quietly unionizing the local biomass for
> nine hundred years. Corporate has classified the resulting spore-tide as a
> "spontaneous employee wellness initiative" to avoid the paperwork. Your
> lungs disagree.

**The Dossier.** A drowned corporate campus sunk into a peat basin, veiled in
murky green atmospheric fog so thick the sun arrives only as pale,
knife-edged volumetric shafts between the canopy. Glowing chemical runoff —
bioluminescent acid the color of a highlighter — pools in the low ground and
lights the fog from below. Everything drips. Everything smells like a server
room that flooded and was never reported.

**Gameplay Modifiers**
- **CANOPY INTERFERENCE** — the deep fungal canopy fouls the *Void Anchor*'s
  targeting uplink. Orbital stratagem call-ins take **+25% longer** to arrive,
  and beacons thrown *under* dense canopy scatter their landing point.
- **SPORE SATURATION** — ambient spore count reduces effective sight range;
  the fog is a hard occluder, not a tint.
- **CAUSTIC GROUND** — acid pools are live DOT hazards. **[Engine]** already
  in the `hazards[]` array for the swamp biome; each pool digests anyone who
  wades in.

**Primary Environmental Obstacle: THE BOG & THE REEDS**
The defining friction of the Wetlands is a two-layer occlusion-and-mire
system.

- *On players:* Deep bog tiles drain **stamina** and cut movement/sprint
  speed to a wade; a dive into a bog is a dive into molasses — the i-frames
  land but the reposition doesn't. Tall, dense reed walls block line-of-sight
  entirely, so a firefight in the reeds is fought at contact range, by muzzle
  flash and silhouette. You never see the whole field. You see the next two
  meters of it.
- *On enemies:* The Overgrowth's melee tide (ticks, spitters) is *also*
  mired and *also* blind in the reeds — which is the entire tactical texture
  of the map. You can lose a pursuing swarm by breaking line-of-sight in a
  reed bank, or you can be ambushed by a Merger that was standing four meters
  away the whole time. Heavies bog down hardest; kite them into deep mire and
  they become stationary targets.

**Systemic Interactions.** Flux weapons love it here — the wet, cool air
bleeds heat and there's no ammo economy to strand you when resupply is a bog
away. Thermal Barrier stratagems are devastating: a wall of heat in a
reed-choked lane is a corridor of guaranteed kills the enemy can't see to
avoid. But watch your beacon throws — under canopy they drift, and a Kinetic
Strike that lands ten meters off is a Kinetic Strike that lands on *you.*

**The Loop Hook.** Creep the reeds, break contact, use the bog as a wall.
The Wetlands teach the player that *sightlines are a resource you spend and
recover*, and that the ground itself can be a leash you drag heavies onto.

**[Engine]** Palette `swamp` (murky green ground, bog mires, reed MultiMesh,
bioluminescent spore particles). Fog density high, `vfog_albedo` green.
Reeds should be tall alpha-card MultiMesh with per-instance collision-free
occlusion; bog tiles flagged as friction volumes feeding the shared
movement-friction layer.

---

### MAP 2 — THE FROZEN ASSETS
#### *Worksite designation: "The Cold Storage & Depreciation Facility"*
**Biome: Glacial / Extreme Cold · Hostile Force: The Silicon Swarm · Status: BUILT (tundra)**

> An entire planet the Company uses as a walk-in freezer for assets it has
> written down but not yet written off. The Silicon Swarm drinks the core
> heat straight out of the crust, which is technically theft of Company
> property, which is the only reason we're funding your extraction. Dress
> warm. There is no dress code, because there is no HR, because HR froze.

**The Dossier.** A blinding white glacial shelf under rolling blizzard fronts,
broken by deep, cathedral-blue ice caverns and the frozen skeletons of
industrial wreckage — cranes, silos, a half-sunk hauler — every surface
throwing back the flat cold light of a sun that gives no warmth. In calm
weather it is the most beautiful worksite in the portfolio. Then the front
rolls in, the world goes to a howling white wall, and beauty becomes a
whiteout you can die twelve meters from your squad in.

**Gameplay Modifiers**
- **EXTREME COLD** — heat-sink (Flux) weapons overheat **50% slower**; a huge
  buff. But stamina drains **25% faster** while sprinting — the cold taxes the
  body. **[Engine]** already modeled on the tundra planet.
- **BLIZZARD FRONTS** — periodic weather events collapse sight range to near
  zero and howl fog past the player. During a whiteout, everyone is blind.
- **BATTERY DRAIN** — the deep cold saps energy cells: energy-weapon and
  gadget *charge* bleeds passively, so a Flux user gets the overheat buff but
  fights a slow, constant loss of reserve capacity. Choose your economy.

**Primary Environmental Obstacle: BLACK ICE & SNOWDRIFT**
The Frozen Assets run on a **momentum vs. mire** contrast — the two frictions
sit side by side, and reading which is which is a survival skill.

- *On players:* **Black ice** slicks kill your ground friction — acceleration
  and braking go soft, so a sprint across an ice sheet is a commitment you
  can't take back mid-slide, and a combat dive turns into a genuine slide with
  real travel. **Snowdrifts** are the opposite: deep powder that restricts
  sprint entirely and forces a wade, exactly when the blizzard means you want
  to be moving fast.
- *On enemies:* The Swarm slides too. A charging tick that hits black ice
  overshoots; a heavy that commits to a lunge on ice keeps going. You can bait
  a charge across a slick and let the enemy's own momentum carry it off a
  ledge or into a Thermal Barrier. Drifts bog the Swarm the same way bogs do
  in the Wetlands — the map has two "sticky" and two "slippery" surface types
  and the whole firefight is choreography across them.

**Systemic Interactions.** This is the Flux Engineer's home turf — and its
trap. The 50%-slower overheat tempts you into sustained fire, but the battery
drain means your *reserve* is quietly dying, so the disciplined play is still
burst-and-vent. Kinetic users are unaffected by cold's weapon effects and
should lean in. Blizzard windows are the map's clock: fights that start in
clear weather and finish in a whiteout completely change character halfway
through.

**The Loop Hook.** Respect momentum. The Frozen Assets teach that *speed you
can't control is a liability*, and that the safest sprint is sometimes a
walk. The blizzard turns every objective into a race against your own
visibility.

**[Engine]** Palette `tundra` (bright ground, blue ice spires, snow + spindrift
GPU particles). Black-ice patches as low-friction surface volumes; drifts as
high-friction volumes; blizzard as a timed spike in `fog_density` /
`volumetric_fog_density`. Battery drain as a passive tick on Flux reserve.

---

### MAP 3 — THE SMOG-BELTS
#### *Worksite designation: "The Thermal Extraction & Ash Remediation Site"*
**Biome: Desert / Volcanic Wasteland · Hostile Force: The Reclaimers · Status: BUILT (ash)**

> A burned volcanic shelf the Company strip-mined for geothermal yield and
> then abandoned mid-quarter, leaving the ground quite literally on fire. The
> Reclaimers — repossession bots with a legal department — are here to file
> the same paperwork you are, which makes this a jurisdictional dispute
> settled with autocannons. The air is 40% particulate. The Company provides
> no respirator. The Company provides a **motivational poster** about breathing.

**The Dossier.** A saturated orange-and-black sky, the sun a bruised smear
behind rolling smoke, and the ground a field of cooling basalt veined with
glowing magma cracks that light the ash from beneath. Heat-distortion shimmer
rises off every hot surface, so distant targets *warp* — you're never quite
sure of the range. Drifting embers hang in the air like slow orange snow.
Everything is the color of a server fire.

**Gameplay Modifiers**
- **ATMOSPHERIC INTERFERENCE** — particulate and thermal noise degrade the
  targeting uplink; stratagem call-ins take **+25% longer**, and heat-shimmer
  distorts long-range aim. **[Engine]** modeled on the ash planet.
- **HIGH DRY-HEAT** — the inverse of the Frozen Assets. Standard/Flux weapons
  **overheat faster**; sustained fire is a luxury the climate taxes.
- **VOLCANIC GROUND** — magma cracks are live DOT hazards in the `hazards[]`
  array; standing in one cooks you. The ground is not a floor. It's a warning.

**Primary Environmental Obstacle: TREMORS & SULFUR POCKETS**
The Smog-Belts add a *timing* hazard on top of a *positioning* hazard.

- *On players:* Localized **tremors** ripple out from the magma system and
  **stagger** anyone caught standing — a hard interrupt to your aim, your
  reload, your dive. You feel it before you see it (screen shake, a low
  rumble), and the tell is your window to brace or reposition. **Sulfur gas
  pockets** are invisible-until-you're-in-them DOT clouds pooling in the low
  ground; they punish the player who runs a route without reading the terrain.
- *On enemies:* Tremors stagger the Reclaimers too, opening free damage
  windows — a quake that interrupts *your* reload also interrupts a Foreman's
  rocket wind-up. Sulfur and magma hurt them exactly as much as you; the
  Reclaimers' ranged game means you'll often be maneuvering them, deliberately
  or not, across ground that's killing them. A grenade that drops a heavy into
  a magma crack is the map doing your job.

**Systemic Interactions.** Kinetic weapons shine — no overheat penalty, and
the stagger-heavy environment rewards high-impact bursts between tremors.
Flux users must fight the climate's overheat tax with discipline. The
call-in delay means your orbital stratagems are a *plan*, not a *panic
button* — throw the beacon early, fight the thirty seconds, and don't stand
on your own target when the rod finally comes down.

**The Loop Hook.** Read the ground and the clock. The Smog-Belts teach that
*the floor is a threat and the environment has a tempo* — brace the tremor,
avoid the low ground, and let the Reclaimers cook themselves on the terrain
you learned to walk around.

**[Engine]** Palette `ash` (basalt ground, magma pools + OmniLight, ember GPU
particles, obsidian spires). Tremors as a periodic `add_shake` + stagger
impulse event; sulfur pockets as invisible DOT volumes; magma already in
`hazards[]`.

---

### MAP 4 — THE BOARDROOM CHASM
#### *Worksite designation: "The Vertical Integration & Restructuring Site"*
**Biome: Rocky Canyons / Vertigo · Hostile Force: The Arbitration · Status: NEW**

> The Company's most aggressive restructuring: they mined a mountain range
> into a maze of towering basalt spires and bottomless ravines, connected by
> "land bridges" the safety memo generously calls "walkways." There are no
> guardrails. Guardrails are a Q3 initiative that keeps getting deprioritized.
> The Arbitration runs the site — regenerating-shield litigators who understand
> that the cheapest way to win a dispute is to let the fall damage argue for
> them.

**The Dossier.** Towering, knife-sharp basalt pillars in harsh high-contrast
light — hard black shadow, blinding lit rock, nothing in between. Deep
shadowed ravines drop into dust and dark below. Swirling dust devils track
across the flats and up the columns, and the whole site *breathes* with
high-altitude wind you can hear before you feel. It is beautiful and it is
lethal and it is one gust away from a workplace-safety statistic.

**Gameplay Modifiers**
- **HIGH WINDS** — the defining modifier. Powerful, shifting wind currents
  physically **push loose objects**: thrown grenades, and — critically —
  **stratagem beacons** get redirected in flight and after they land if they
  haven't anchored. Your orbital drop lands where the *wind* decides, not
  where you threw it.
- **EXTREME VERTICALITY** — traversal is funneled onto narrow land bridges and
  exposed ledges; open ground is scarce and every one is a killbox.
- **FALL EXPOSURE** — lethal drops are everywhere; **fall damage** (and
  outright death on the deep ravines) is the constant tax on aggression and
  panic alike.

**Primary Environmental Obstacle: THE DROP & THE GUST**
The Boardroom Chasm is the sandbox's purest expression of *physics as
threat* — no DOT, no occlusion, just gravity and force.

- *On players:* Verticality forces you onto **narrow bridges** where there is
  no room to strafe, dive, or reposition — a fight on a land bridge is a duel
  with a cliff on both sides. **Wind gusts** apply lateral force to your body
  mid-air (during a dive or a jump) and to everything you throw; a grenade
  cook near a ledge is a coin flip. A knockback that would be a bruise on flat
  ground is a **death** here. The map weaponizes your own recoil and momentum.
- *On enemies:* The Arbitration can be *thrown*. A well-placed explosive, a
  Thermal Barrier's shove, or a lucky gust sends a shielded litigator off a
  bridge — bypassing the regenerating shield entirely, because the ravine
  doesn't care about shields. Enemies pathing across bridges are as exposed as
  you are; wind pushes their thrown attacks too. The whole map is a physics
  puzzle where "shoot it" and "push it off" are both valid answers, and the
  second one is cheaper.

**Systemic Interactions.** Anti-shield fights against the Arbitration usually
want rate-of-fire over caliber — but here, *displacement* trumps both. Bring
knockback. Beware your own stratagems: with wind redirecting beacons, orbital
call-ins on this map are a genuine risk to the squad, and the disciplined
play is to throw *into* dead ground and wait. Grenades become unreliable and
that unreliability is the point.

**The Loop Hook.** Fight the map, not just the enemy. The Boardroom Chasm
teaches that *position and force are lethal on their own* — that the safest
kill is the one gravity finishes, and the deadliest mistake is trusting a
throw to a wind that has other plans.

**[Engine]** NEW palette `chasm` (sharp basalt columns via scaled/rotated
prisms, high-contrast key light, low ambient, dust-devil GPU particles).
Wind as a global force vector applied to the grenade/beacon rigidbodies and
to airborne character velocity; land bridges as authored narrow nav corridors
over kill-volumes; fall damage scaled to fall distance with instant-death
ravines.

---

### MAP 5 — THE ABANDONED ARCHIVES
#### *Worksite designation: "The Legacy Records & Data-Reclamation Site"*
**Biome: Overgrown Urban Ruins · Hostile Force: The Overgrowth (feral) · Status: NEW**

> A brutalist megacity the Company built to store paperwork and then forgot
> it owned. Decades of deferred maintenance later, the concrete is being
> digested by giant bioluminescent flora that grew up through the filing
> floors, and the only light in the deep stacks is the glow of moss that has
> opinions about intruders. The records are still in there. So is whatever
> has been reading them.

**The Dossier.** Decaying concrete towers — cracked, canted, half-collapsed —
reclaimed by enormous glowing plant life that ropes between buildings and
lights the interiors in sickly green-blue. Outside: dark canyons between
skyscrapers. Inside: tight corridors lit only by moss and your muzzle flash,
sudden shafts where a floor gave way, and the constant sense that the ceiling
is a suggestion. It is the claustrophobic inverse of the Boardroom Chasm —
there, the danger was open air; here, it's the walls closing in.

**Gameplay Modifiers**
- **URBAN DENSITY** — tight, claustrophobic **choke points** dominate; the map
  is a warren of corridors, stairwells, and collapsed rooms with almost no open
  sightlines. Crowd control and doorway discipline win fights.
- **STRUCTURAL DECAY** — **destructible walls and floors.** Explosions
  (yours or theirs) crumble cover, open new routes, and drop ceilings — the
  geometry is not fixed. **[Engine]** the build already has destructible cover;
  this map makes it a core mechanic instead of a flavor detail.
- **VERTICAL AMBUSH** — enemies hold elevated **sniper perches** in the broken
  towers and drop on you from above; threat comes from the Z-axis, not just the
  floor plan.

**Primary Environmental Obstacle: THE CHOKE & THE COLLAPSE**
The Archives turn *architecture itself* into the systemic hazard.

- *On players:* Choke points mean you fight in doorways where the whole enemy
  tide funnels onto one lane — a nightmare or a dream depending on whether you
  brought area denial. **Destructible geometry** cuts both ways: an explosion
  that clears a barricade can also drop the wall you were using for cover, or
  the floor you were standing on, or the ceiling onto your squad. Vertical
  perches mean you must constantly clear *up*, not just forward — the reticle
  has to leave the horizon.
- *On enemies:* The feral Overgrowth swarms the chokes and climbs the perches,
  but the collapse mechanic is the great equalizer: **blow the supports and
  bury a lane.** Drop a tower section on a heavy, cave in a corridor to seal a
  breach, collapse a floor to dump a sniper perch and its occupant into the
  dark below. The map rewards players who read the building as a set of
  triggers, not just a set of rooms.

**Systemic Interactions.** This is Thermal Barrier and grenade country —
choke points make area denial king. Kinetic weapons risk running dry in the
long room-to-room grind with resupply far behind you; conserve, and reload
*behind* cover because a discarded clip in a doorway fight is a death
sentence. Every explosive is also a demolition tool — the best play is often
to reshape the room rather than clear it.

**The Loop Hook.** Hold the doorway, watch the ceiling, and remember the
walls are ammunition. The Archives teach that *the map is destructible and
therefore negotiable* — that you can win a fight by changing the room instead
of winning the room.

**[Engine]** NEW palette `urban` (cracked concrete, bioluminescent flora
emission, moss lighting, glow-lit interiors). Lean on the existing
destructible-cover system, promoted to structural chunks with authored
collapse triggers; sniper-perch nav points for elevated enemy AI; tight
authored interiors rather than open procedural flats.

---

### MAP 6 — THE SHADOW OUTPOST
#### *Worksite designation: "The After-Hours Operations & Nightshift Site"*
**Biome: Tidally Locked / Eternal Night · Hostile Force: The Reclaimers (autonomous) · Status: NEW**

> A tidally locked rock with one face turned forever from its star — the
> Company's designated **nightshift**, where the sun is a rumor and the only
> overtime is the kind you don't clock out from. Autonomous Reclaimer units
> run the site with no supervisor and no off switch; you find them the way you
> find everything here, by the red glow of their optics finding you first. The
> Company issued you a flashlight. The Company did not issue you spare
> batteries. The Company believes in you.

**The Dossier.** Total, absolute dark. The only light in the world is what you
bring: your weapon-mounted flashlight cone, the sputter of a dropped flare,
the muzzle flash that shows you the enemy and shows the enemy *you*, and the
glowing red eyes of Reclaimer optics tracking through the black. Then the ion
storm rolls in — and for one strobing instant of blue-white lightning the
entire field is revealed, every silhouette burned onto your retina, before
the dark slams back down and takes your HUD with it. It is the most terrifying
worksite in the portfolio, and it is the cheapest to light, which is why
Facilities loves it.

**Gameplay Modifiers**
- **ETERNAL NIGHT** — the visibility economy taken to its absolute limit.
  Target identification depends **entirely** on flashlights, flares, muzzle
  flash, and enemy eye-glow. Light is the scarcest resource on the map, and
  every source you use also marks *your* position.
- **ION STORMS** — periodic electromagnetic events that **disable the HUD,
  mini-map, and Stratagem call-ins** for their duration. No orbital support, no
  map, no ammo counter — just you, the dark, and the red eyes. The storm's only
  gift is the lightning: split-second full-field illumination you must learn to
  fight *by*.
- **NO OVERWATCH** — with the uplink down during storms, the *Void Anchor*
  can't see you. You are, briefly and completely, on your own.

**Primary Environmental Obstacle: THE DARK & THE STORM**
The Shadow Outpost's hazard is *the absence of information*, made physical.

- *On players:* You cannot fight what you cannot see, and every act of seeing
  costs you. A flashlight paints the enemy but paints a target on your chest.
  A flare lights a room but burns down and leaves you night-blind. Muzzle
  flash reveals the field in strobes but broadcasts your position with every
  trigger pull. During an ion storm you lose your HUD, your minimap, and your
  stratagems — the fight strips down to raw target-ID and trigger discipline.
- *On enemies:* The autonomous Reclaimers *have* the advantage the dark denies
  you — their red optics see fine, and the eye-glow that lets you spot them is
  the only tell you get. But light is symmetrical: a flare thrown into their
  midst lets you *and them* fight in the open, and the ion lightning that
  blinds you reveals *them* too. The skilled player weaponizes the storm —
  timing pushes to the lightning flashes, using the enemy's own eye-glow as a
  targeting reticle, and treating darkness as concealment as much as threat.

**Systemic Interactions.** Flares become a primary tool, not a stratagem
gimmick — light discipline is the core skill of the map. Kinetic muzzle flash
is a double-edged sword (it reveals and betrays); consider suppressed or
lower-flash options if the loadout allows. Because ion storms kill stratagem
call-ins, you cannot lean on orbital support here — the map is deliberately
built to strip away the safety net and make the *fundamentals* (movement,
aim, positioning, light) carry you. Fight the gaps between storms; survive the
storms themselves.

**The Loop Hook.** Manage light like ammunition and fight the storm's rhythm.
The Shadow Outpost is the capstone worksite — it takes the visibility economy
that every other map hinted at and makes it the *entire* game, proving that in
*Breach-Drop*, **seeing is the hardest thing you'll do all shift.**

**[Engine]** NEW palette `night` (near-black ambient, no sun, sky pitch dark).
Player flashlight as a real SpotLight3D on the weapon; flares as timed
point-lights with falloff; Reclaimer eye-glow as small emissive/OmniLight
nodes; ion storm as a timed state that disables the HUD CanvasLayer, blocks
stratagem input, and fires periodic full-scene flash lighting (a bright,
brief DirectionalLight pulse) synced to thunder SFX.

---

## PART THREE — THE WORKSITE MATRIX

A quick-reference of how the six worksites distribute the sandbox's pressure,
so no two drops feel the same and each teaches a different core skill.

| Worksite | Biome | Core Hazard Type | Punishes | Rewards | Teaches |
|---|---|---|---|---|---|
| Cubicle Swamps | Wetland | Occlusion + mire | Sightline reliance | Flux, area denial | Sightlines are spendable |
| Frozen Assets | Glacial | Momentum + weather | Uncontrolled speed | Cold-tuned Flux, patience | Respect momentum |
| Smog-Belts | Volcanic | Timing + ground DOT | Standing still, low ground | Kinetic, tremor-timing | The floor is a clock |
| Boardroom Chasm | Canyon | Physics / gravity | Panic, bad throws | Knockback, positioning | Force is a weapon |
| Abandoned Archives | Urban ruin | Architecture / destructible | Open aggression | Demolition, doorway control | The map is negotiable |
| Shadow Outpost | Eternal night | Information denial | Careless light use | Light discipline, fundamentals | Seeing is the fight |

### Design throughline
Read top to bottom, the worksites form a **difficulty and literacy curve**:
they start by teaching the player to read *space* (fog, ice, ground), escalate
to reading *force* (wind, gravity, collapse), and culminate in the hardest
lesson of all — reading a battlefield you can barely *see*. Each hazard is
symmetrical, physical, and legible; each worksite is a hostile employer; and
every single one of them would like to remind you that your extraction bonus
is contingent on completing the assignment.

Do the job. Light the beacon. Come home, Liquidator.

*— End of Volume II —*
