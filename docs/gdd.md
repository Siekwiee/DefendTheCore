Absolutely—here’s a concise, practical Game Design Document (GDD) tailored for a Geometry Tower–style PC game built in Lua with LÖVE2D, focused on fun, no monetization, no energy/offline progression, and some fresh twists.

Working Title

- Defend the Core: A Hub-Based Survival Defense

High Concept

- Build and upgrade your core in a persistent hub, then launch into endless survival runs. Permanent upgrades are earned in the hub between runs, while rare boss encounters during runs offer powerful temporary boosts. Clean geometric visuals, meaningful progression, and skill-based gameplay with persistent save system.

Target Platform & Tech

- Platform: PC (Windows/macOS/Linux)
- Engine: LÖVE2D (Lua)
- Display: 16:9 fixed or dynamic scaling; 60 FPS target
- Input: Keyboard + Mouse (controller optional later)
- Save System: Local file persistence for settings, resources, and progression

Player Fantasy

- You are the guardian of a powerful core facility. Between survival runs, you research permanent upgrades and manage resources in your hub. During endless survival runs, you face escalating threats with only rare boss victories offering temporary power boosts.

Core Pillars

- Hub-based progression: Permanent upgrades happen between runs in a dedicated hub screen
- Endless survival: No waves—pure survival until death with escalating difficulty
- Meaningful persistence: Resources, upgrades, and settings saved between sessions
- Clean separation: Hub for planning/upgrading, runs for pure action

Game Flow

- Main Menu → Hub (manage upgrades, resources, inventory) → Endless Run (survive until death, earn resources) → Return to Hub → Repeat
- Alternative: Main Menu → Options (dedicated settings screen) → Main Menu

Hub Screen Layout

- Center: Visual representation of your core with energy effects
- Top Bar: Resource display (Credits, Parts, Cores earned from runs)
- Bottom Navigation: Three panels
  - Left: Permanent Upgrades (research tree, unlock with resources)
  - Middle: Play Mode (start endless run, view stats)
  - Right: Inventory (items, collectibles, achievements)

Endless Run Structure

- Duration: Unlimited—survive as long as possible
- Difficulty Scaling: Enemy spawn rate increases over time, more variety at higher survival times
- Boss Encounters: Every 60-90 seconds, defeating bosses grants one powerful temporary upgrade
- No Mid-Run Drafts: Pure action gameplay, no upgrade menus during survival
- Death: Return to hub with earned resources based on survival time

Resource System

- Credits: Primary currency earned based on survival time (1 credit per 10 seconds survived)
- Parts: Rare materials from boss defeats, used for advanced upgrades
- Cores: Ultra-rare items from exceptional runs, unlock major progression tiers

Save System

- Automatic save on game exit and after each run
- Persistent storage of settings, resources, permanent upgrades, and statistics
- Profile includes best survival time, total runs, enemies defeated, etc.

Combat Overview

- Single static “tower” in center, fires projectiles/lasers based on your build.
- Enemies spawn from edges in patterns (rings, arcs, lanes) and path inward.
- Physics-lite: projectiles collide, some knockback, shields deflect.
- Damage types and counters create a light rock-paper-scissors dynamic.

Run Structure

- Duration: ~15 min for 30 waves
- Draft cadence: at start, then every 3 waves and after boss waves
- Rarity: Common/Uncommon/Rare/Epic; rarer = stronger but riskier trade-offs

Tower Stats

- Base HP (structure)
- Core ATK (projectile power)
- Fire Rate
- Projectile Speed
- Range
- AoE Radius
- Crit Chance / Crit Mult
- Heat/Overheat (if using heat mechanics)
- Module Slots (for special attachments)

Damage Types

- Kinetic: good vs unarmored, weak vs shielded
- Pierce: ignores partial armor, reduces on hit
- Energy: strong vs shielded, weak vs heavy
- Explosive: AoE, falloff at edge
- True: rare, bypasses all mitigation (limited sources)

Enemy Archetypes

- Triangle Runner: fast, low HP, punishes slow fire rate
- Square Tank: slow, armored; weak to energy or DoT
- Circle Swarm: many tiny units; weak to AoE
- Hex Shield: rotating directional shield; rewards flanking shots and pierce
- Star Splitter: breaks into smaller shapes on death
- Prism Healer: pulses regen; high priority target
- Obelisk Siege: long-range harass; forces hit-scan or snipe solutions
- Boss Examples:
  - The Dodecahedron: rotating armor plates, lash-back shockwaves
  - The Möbius: phase-shifts to invert resistances
  - The Tesseract: spawns portals, clones, and pulls bullets

Wave Design

- 30 waves per standard run
- Every 5 waves: themed mini-challenge (e.g., “shielded storm”)
- Every 10 waves: boss
- Optional endless mode after 30 with scaling intensity and corruption mutators

Draft/Upgrade System

- Draft 3 picks of 5 choices each time (reroll limited)
- Types:
  - Stat Mods: +15% fire rate, +1 pierce, +20% range
  - Form Mods: change firing mode (beam, burst, shotgun, rail, arc)
  - Utility Mods: slow on hit, mark targets, chain lightning, burn/bleed
  - Economy Mods: extra draft choice next time, convert unused picks into power
  - Synergy Keys: set tags that unlock future synergies (e.g., “Beam”, “Status”)
- Sample Upgrades:
  - Rail Coil: Convert shots to rail rounds (high pierce, long charge). -20% fire rate.
  - Prisma Lens: Beams now split on kill into 2 minor beams.
  - Flux Capacitor: Overheat system added: +40% fire rate until heat cap, then 2s cooldown. +10% base fire rate.
  - Interference Mesh: +20% energy damage; shots apply 10% slow (stacking to 40% briefly).
  - Fragmentation Core: Kills cause micro-shrapnel (explosive, small AoE).
  - Deflectors: 15% chance to ricochet at 70% damage; +1 projectile on ricochet.
  - Harmonic Resonator: Every 10th shot is guaranteed crit and chains to 3 targets.
  - Entropy Tax: +30% damage, -30% range; if enemies are within “danger radius,” gain +15% damage more.
- Synergy Sets (2–3 pieces):
  - Beam Suite: Beam base + Prisma Lens + Thermal Bloom → Beams ramp damage over time and carve lines through grouped foes.
  - Ballistics Suite: Rail Coil + Deflectors + Kinetic Stabilizer → Pinpoint sniping with lethal ricochets.
  - Status Suite: Interference Mesh + Ion Brand + Harmonic Resonator → Slow, mark, and chain crits.
- Curses/Boons:
  - Take a curse to draft an extra epic now (e.g., “enemies move 10% faster”).
  - Boons awarded for flawless waves.

Moment-to-Moment Feel

- Satisfying fire cadence (punchy audio), telegraphed enemy attacks, clean screen feedback:
  - Color-code damage types
  - Distinct hit sounds for armor break, shield pop, crit
  - Micro-screenshake and palette flashes kept subtle and togglable

Meta Progression (Optional, Non-power Creep)

- Unlock-only, no permanent stat boosts:
  - New enemy variants
  - New upgrade pools or cosmetic palettes
  - New challenge mutators (e.g., “No AoE run”)
  - Lore snippets in a minimal codex
- Unlock by achievements (e.g., “Beat Wave 20 with Beam build”).

Difficulty & Modes

- Standard
- Hard (faster spawns, smarter pathing, fewer draft rerolls)
- Daily Seed (fixed upgrade RNG seed for fairness and shareability)
- Endless (after beating Standard once)

Art & Audio Direction

- Visuals: flat shapes, strong contrast, minimal gradients. Use 2–3 accent colors per run theme.
- Effects: Line renderers for beams, simple circles for AoE, additive glow via shaders if desired.
- UI: Diegetic rings around tower for range/heat. Draft UI is card-like panels.
- Audio: Procedural bleeps and clicks; synthy ambient track; clear layers for hits, crits, shield pops.

Accessibility

- Colorblind-friendly palette sets
- Motion toggle (reduce screenshake/flash)
- Remappable controls
- Adjustable game speed (90–110%) for accessibility without breaking balance

Controls

- Mouse aim (if directional) or auto-target priority
- Keyboard:
  - Space: Overdrive/Active Skill (if taken)
  - R: Reroll draft (limited)
  - Q/E: Cycle targets mode (Closest, Strongest, Shielded, Boss)
  - P: Pause
- Optional: Controller sticks for aim/menus

Active Skills (Optional spice)

- Overdrive: temporary fire-rate burst, builds charge via kills
- Phase Shield: brief invulnerability that reflects projectiles
- Warp Pulse: radial knockback + slow

Scoring

- Score = damage dealt + efficiency bonuses – leak penalties
- Style multipliers for multi-kills, overheat management, perfect waves
- Leaderboard seed sharing (local file-based for now)

Technical Design (LÖVE2D)

- Modules:
  - main.lua: bootstrap, state machine (menu, run, pause, results)
  - systems/
    - input.lua
    - ecs.lua or lightweight entity registry
    - physics.lua (simple AABB or circle collision; no Box2D needed)
    - render.lua (batched draws; layers: background, effects, UI)
    - audio.lua (source pooling)
    - rng.lua (seed control for daily runs)
    - waves.lua (spawner patterns)
    - upgrades.lua (definitions + weighted RNG by tags)
    - combat.lua (projectiles, damage calc, crit/armor/shields)
    - ai.lua (enemy steering/pathing toward center)
    - balance.lua (tables for difficulty curves)
    - save.lua (achievements, cosmetic unlocks, settings)
- Data-Driven Content:
  - JSON or Lua tables for enemies, upgrades, waves
  - Tag system: upgrades/enemies tagged for synergy filters
- Performance Targets:
  - 1,000+ active projectiles smoothly on modest CPUs
  - Use love.graphics.setColor/setBlendMode sparingly; batch with spritebatches if using textures
  - Spatial partitioning: uniform grid or quad-tree for collisions

Sample Data Sketches (Lua)

- Upgrade example:

```lua
return {
  id = "rail_coil",
  name = "Rail Coil",
  rarity = "rare",
  tags = { "ballistics", "pierce" },
  apply = function(state)
    state.weapon.type = "rail"
    state.weapon.fireRate = state.weapon.fireRate * 0.8
    state.weapon.pierce = (state.weapon.pierce or 0) + 3
    state.weapon.chargeTime = 0.5
  end,
  desc = "Convert shots to rail rounds with high pierce. -20% fire rate."
}
```

- Enemy example:

```lua
return {
  id = "hex_shield",
  hp = 120,
  speed = 70,
  armor = 0.2,
  shield = {
    arcs = 3, -- number of protected sectors
    rotateSpeed = 40 -- deg/sec
  },
  rewards = 3,
  tags = { "shielded" }
}
```

- Wave pattern generator snippet:

```lua
local function ringSpawn(center, radius, count, angleOffset)
  local enemies = {}
  for i = 1, count do
    local angle = angleOffset + (i / count) * (2 * math.pi)
    table.insert(enemies, {
      spawnX = center.x + math.cos(angle) * radius,
      spawnY = center.y + math.sin(angle) * radius,
      type = "triangle_runner"
    })
  end
  return enemies
end
```

Balance Curve (Starting Points)

- Health: grows ~12% per wave; armor introduced by wave 6
- Spawn count: +10–15% per wave; variety introduced in bands
- Boss HP: 25x baseline of wave
- Player growth: each draft yields ~15–25% effective power if synergized

Polish & Juice Ideas

- Armor crack shader on enemies as they near death
- Heat shimmer on overheat builds
- Slow-mo 0.3s on boss kill or perfect wave
- Minimal vignette color shifts by damage type dominance

Project Scope & Milestones

- Week 1–2: Core loop prototype (shooting, waves, basic draft UI)
- Week 3–4: 8 enemies, 20 upgrades, 15 waves, 1 boss; sound placeholders
- Week 5–6: Full run (30 waves), 3 bosses, 45+ upgrades, balance pass
- Week 7: Accessibility, achievements, daily seed mode, juice
- Week 8: Playtest, difficulty curves, performance tuning, packaging

“Different From Geometry Tower” Notes

- No energy/offline/shops; roguelike-only session play
- Heavier emphasis on synergies and curses
- Directional shields, splitters, and rail/beam forms to deepen tactics
- Daily seed and challenge mutators for variety without grind

Next Steps when base is finished

- Build a minimal draft UI and seedable RNG
- Pick 2–3 core firing identities to implement first: Beam, Rail, Shotgun
- Implement 6 core enemies: Runner, Tank, Swarm, Shield, Splitter, Healer
- Add one boss and a 15-wave demo; iterate on feel/feedback
