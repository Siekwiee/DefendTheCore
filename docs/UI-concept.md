Here’s a complete UI design concept for your LÖVE2D Geometry Tower–like PC game. It includes a cohesive color palette, typography, spacing system, component specs (buttons, sliders, cards), tooltip behavior, screen layouts, accessibility variants, and implementation notes for LÖVE2D.

Visual Identity

- Style: Minimal, geometric, high readability. Strong contrast on a dark background with vibrant accents for damage types and interactive elements.
- Tone: Crisp, modern, a bit “sci-technical.”
- Motion: Subtle, 120–200 ms easing for most UI transitions. Small scale/alpha fades.

Core Color Palette
Base

- Background 900: #0B0F14 (primary canvas)
- Surface 800: #11161C (panels, HUD cards)
- Surface 700: #1A222B (hovered/raised surface)
- Divider: #26313C (hairline dividers)

Text

- Text High: #E6EDF3 (primary text)
- Text Mid: #B7C4CF (secondary text)
- Text Low: #8392A3 (tertiary/disabled)

Primary/Accents

- Primary (Interactive): #4FC3F7 (buttons, links, selections)
- Primary Hover: #7FD9FF
- Primary Active: #2BB6F3
- Warning/HP: #FF6B6B
- Warning Hover: #FF8585
- Success: #66D19E
- Highlight: #FFD166 (crit, boons)
- Focus Ring: #A0E3FF (2 px outer glow)

Combat/Damage Type Coding

- Kinetic: #8EC5FF
- Pierce: #A78BFA
- Energy: #7CF6FF
- Explosive: #FFB86B
- True: #FFD166

Status/Utility

- Slow/Freeze: #A0E9FF
- Burn/DoT: #FFA07A
- Shock/Chain: #B0FF92
- Shield: #74D3FF
- Armor: #9AA6B2

Color Rationale

- High-contrast on dark backgrounds improves readability and makes action VFX pop.
- Damage types are distinct and colorblind-friendly when paired with shape/icon cues (see Accessibility).

Typography

- Primary: Inter or JetBrains Mono (if you want a “techy” vibe). Inter is strongly recommended for readability.
- Weights: Regular (400), Medium (500), Semibold (600), Bold (700)
- Sizes (desktop, 1080p baseline):
  - H1: 36 px / 44 line-height (page titles)
  - H2: 28 px / 36 (section headings)
  - H3: 22 px / 28 (card headers)
  - Body: 16 px / 22 (default)
  - Secondary: 14 px / 20 (tooltips, captions)
  - Mono Numbers: optional for stats (JetBrains Mono 14–16 px)

Spacing & Layout Grid

- Base spacing unit: 8 px
- Common paddings: 12/16/24 px
- Panel radius: 8 px
- Button radius: 6 px
- Card radius: 10 px
- Grid: 12-column layout at 1080p with 24 px gutters; scale proportionally for other resolutions

Core Screens and Layouts

1. Main Menu

- Layout:
  - Left: Title and short tagline
  - Center: Primary actions
  - Right/Bottom-right: Version, credits, settings cog
- Components:
  - Title “PolyTower” (H1)
  - Buttons: Play, Daily Seed, Settings, Codex, Quit
  - Footer: Version v0.1.0, build date
- Background: Subtle animated geometric grid lines in #10151B with slow parallax
- Example placement:
  - Title at top-left with 24 px margin
  - Button stack centered vertically: 280 px width, 16 px gaps

2. In-Run HUD

- Top bar:
  - Left: Wave indicator (Wave 7/30), timer, difficulty tag
  - Center: Boss health bar when relevant (hidden otherwise)
  - Right: Score, rerolls left, pause button
- Center: Tower area uncluttered; minimal overlays
- Bottom panel:
  - Status row: Core stats (ATK, Fire Rate, Range), icons + numbers
  - Active skill: Space bar icon + charge meter
- Visual rules:
  - Avoid covering center; keep actionable UI at edges
  - Use surface 800 with 80–90% opacity and subtle shadow for legibility
- Health indicators:
  - Tower HP ring around tower: dynamic color from Success → Warning
- Targeting mode indicator:
  - Small pill at lower-right: “Target: Shielded” with quick Q/E hint

3. Draft/Upgrade Screen (Modal between waves)

- Center modal, 3–5 cards visible
- Card size: 280–320 px width, flexible height
- Each card:
  - Header with icon and color by tag family (e.g., Beam = Energy color)
  - Big name (H3), rarity pill at top-right (Common/Uncommon/Rare/Epic)
  - Short description (Body)
  - Delta stats list with colored indicators (+ in Success, – in Warning)
- Interaction:
  - Hover shows expanded tooltip (synergy tags, future unlock hints)
  - Select button (Primary), or Right-click for compare with current loadout
- Navigation:
  - Reroll button (shows remaining counts)
  - “Skip for +X score” optional economy twist
- Keyboard:
  - 1/2/3/4 quick-select cards
  - R for reroll
  - Esc cancels/returns

4. Pause Menu (Overlay)

- Dim background (black at 30–40% opacity)
- Panel with:
  - Resume, Settings, Restart, Quit to Menu
  - Run seed string and “Copy Seed” button

5. Settings

- Tabs: Gameplay, Audio, Video, Controls, Accessibility
- Controls tab:
  - Bindings table with “Press any key” rebind
- Accessibility tab:
  - Colorblind presets, reduced motion toggle, text size scaling (0.9–1.25x)
  - High-contrast mode (see below)

6. Results Screen

- Large score number, wave reached, build summary
- Cards of selected upgrades with small icons
- Achievements earned
- Buttons: Retry, Main Menu, Save Seed

Components Specification

Buttons

- Sizes:
  - Large: 280x48 px (menus)
  - Medium: 200x40 px (dialogs)
  - Small: 120x32 px (toolbars)
- States:
  - Default: bg Surface 700, text Text High
  - Hover: bg Primary Hover with 12% overlay; glow 2 px Focus Ring
  - Active: bg Primary Active with slight inset shadow
  - Disabled: bg Surface 800, text Text Low
- Primary button colorization: text on dark background with a thin Primary border; or solid Primary bg for key calls-to-action
- Icon buttons (e.g., pause, settings): 32x32 px, filled on hover

Cards (Draft/Upgrade)

- Background: Surface 800
- Border: 1 px Divider
- Hover: lift 2 px with subtle shadow and 1.02x scale over 120 ms
- Rarity color strip (top or left edge):
  - Common: #8392A3
  - Uncommon: #66D19E
  - Rare: #4FC3F7
  - Epic: #A78BFA
- Content layout:
  - Top row: Icon, name, rarity pill
  - Body: Description, effect bullets
  - Footer: Select button, tags (small pills)

Pills/Tags

- Background: Surface 700
- Text: Text Mid
- Icon: small geometric glyph
- Tag color hints by family (Beam/Pierce/Status, etc.)

Tooltips

- Trigger: Hover 250 ms delay; stays 150 ms after hover-out if moving toward tooltip
- Placement: Prefer top-right of cursor, flip if near edges
- Style:
  - Background: Surface 800, 95% opacity
  - Border: Divider
  - Shadow: subtle
  - Text: Secondary size (14 px)
  - Content: Title, quick stats, synergy callout with color-coded keywords
- Performance tip: cache tooltip canvases for repeated items

Progress Bars

- Generic bar:
  - Track: Surface 700
  - Fill: Primary
  - Corners: 6 px radius
- Special bars:
  - HP: from Success → Warning via gradient; low HP pulses 0.8–1 alpha at 1 Hz
  - Overheat: Energy color for fill; when overheated, fill turns Warning and animates diagonal stripes
  - Boss bar: thicker (20 px), centered top, label inside

Sliders

- Track: Surface 700, 4 px height
- Filled segment: Primary
- Handle: 12 px circle, Surface 800 with Primary stroke
- Hover: handle grows to 14 px, adds Focus Ring

Toggles/Switches

- Track: 36x18 px
- Off: Surface 700; knob Surface 800
- On: Primary; knob Primary Hover
- Keyboard focus: Focus Ring

Checkboxes/Radio

- 18x18 px, 2 px stroke Divider, tick/inner dot in Primary when active

Lists/Tables

- Row height: 32–40 px
- Zebra rows by subtle alpha shift of Surface 800/700
- Selected row border in Primary

Icons

- Line icons at 2 px weight, 24x24 px default
- Status/Damage icons:
  - Kinetic: bullet triangle
  - Pierce: chevron with through-line
  - Energy: beam prism
  - Explosive: burst/star
  - True: diamond
- Use consistent metaphor + shape for colorblind redundancy

HUD Specifics

Top Bar

- Left cluster:
  - Wave pill: “W7/30” with Surface 700 bg, Text High
  - Timer: small clock icon + mm:ss
  - Difficulty: small colored tag (Standard/Hard)
- Right cluster:
  - Score: counter with mono font
  - Rerolls: dice icon + number
  - Pause: icon button

Center Boss Bar

- Appears only during boss waves
- Label: Boss Name (H3), small skull icon if enraged
- De-spawns 600 ms after kill with fade/slide up

Bottom Stats Strip

- Icons + label + number:
  - ATK, Fire Rate, Range, Crit, Pierce
- Color numbers when temporarily buffed (flash to Primary Hover on change)
- Active skill meter: circular wedge with key hint “Space”

Draft Modal

- Dim background to 60% with blur (optional)
- Cards arranged 3-wide; for 4–5 choices, wrap to 2 rows
- Keyboard accelerators displayed as small top-left badges on cards

Accessibility

Colorblind Presets

- Deuteranopia/Protanopia:
  - Adjust Energy to #86E3CE
  - Explosive to #FDB15A
  - Pierce to #CBA0FF with double-chevron icon
  - Add shape cues: beam effects use solid lines; explosive uses radial spikes; pierce adds arrowheads
- Tritanopia:
  - Replace Primary with #5CC8A1
  - Shield: shift to #9FC3FF
- High-Contrast Mode:
  - Background: #00060A
  - Text High: #FFFFFF
  - Primary: #00E5FF
  - Borders increase to 2 px; focus ring 3 px
- Reduced Motion:
  - Disable scale-on-hover; use opacity-only transitions
  - Disable background parallax/animated grid

Audio UI

- Button click: short “tick”
- Confirm: upward “bleep”
- Cancel/error: soft “thunk”
- Hover: subtle noise swell
- Accessibility:
  - Volume sliders per channel (Master, SFX, Music, UI)
  - Optional audio cue on tooltip open

Microcopy Guidelines

- Keep labels concise and literal
- Use verbs for buttons: Play, Resume, Reroll, Select, Skip
- Tooltips: 1–2 sentences max; use bullets for stats
- Avoid jargon unless defined in codex; show tags on cards for discoverability

LÖVE2D Implementation Notes

Scaling

- Use a virtual resolution (e.g., 1920x1080) and scale to window size
- Maintain 16:9 safe area; letterbox if needed; center critical UI

Style Constants (Lua)

- Put palette and sizes in a theme.lua
- Example:

UI System

- Create a lightweight UI module for:
  - Layout stacks (vertical/horizontal with spacing and padding)
  - Components: button, label, icon, slider, toggle, card
  - Focus handling for keyboard navigation
  - Theming via theme.lua
- Use love.graphics.setScissor for panel clipping
- Pre-render rounded rectangles with love.graphics.newMesh or use love.graphics.polygon for crisp corners

Typography Rendering

- Load Inter at sizes you need; cache Fonts by size
- Use love.graphics.printf for wrapping text on cards/tooltips
- Provide a textScale in settings that multiplies font sizes

Tooltip Manager

- Tracks current hover target and time
- Positions tooltip near cursor with screen-edge flip
- Draws after other UI; accepts content via a function that returns lines/icons

Icon Set

- Use vector drawing (primitives) for consistency and resolution independence
- Centralize icons in icons.lua with functions like drawBeamIcon(x,y,sz,color)

Focus/Navigation

- Keyboard navigation grid for menus and draft cards
- Visual focus ring using an outer stroke in Focus color
- Gamepad mapping: D-pad/left stick to navigate, A to select, B to back

States & Transitions

- UI state machine: menu, run, draft, pause, settings, results
- Fade transitions (120–200 ms)
- Pause overlays dim world and stop updates for non-essential systems

Performance (doesent care for now only improve performance if its actually needed)

- Batch draw calls where possible
- Avoid excessive alpha-blended layers; keep panels opaque 90–95%
- Cache static UI canvases (e.g., settings screen background)

Layout Callouts and Measurements (1080p reference)

- Main menu button stack: center x, y = 45% of screen height
- HUD top bar height: 56 px
- Bottom stats strip height: 72 px
- Draft card: 300x380 px, gap 16 px
- Boss bar: 20 px height, 60% screen width, centered

Iconography and Redundancy

- Each damage type uses a unique shape:
  - Kinetic: triangle bullet
  - Pierce: double-chevron with line through enemies
  - Energy: prism/beam line
  - Explosive: burst star
  - True: diamond with inner dot
- Each status effect has its own outline pattern in addition to color:
  - Slow: dashed circle
  - Burn: small upward triangles (flames)
  - Shock: zig-zag line

Testing Checklist

- Legibility at 80% text scale
- Hover/active states visible on Surface 800 background
- Focus rings visible for keyboard-only navigation
- Tooltips never clip off screen on 1280x720 minimum
- Boss bar not overlapping top-left wave/timer cluster

If you want, I can:

- Produce a .aseprite or SVG icon set matching the palette
- Deliver a LÖVE2D UI starter kit (theme, button, card, tooltip, slider, layout)
- Generate JSON/Lua style tokens to keep palette and sizes consistent across modules
