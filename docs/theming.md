# Theming design

Status: **design agreed, not yet implemented.** No theming code exists in this
repo yet. This document is the spec to build from.

Audience: whoever (human or agent) implements the theming system here. It
assumes familiarity with Wombat's basic model but not with the discussion that
produced this design.

---

## 1. The problem

Colours are currently hand-copied across every consumer. Measured on this repo:

| File | hex occurrences |
| --- | --- |
| `src/dot_config/yazi/flavors/gruvbox-dark-hard.yazi/flavor.toml` | 70 |
| `src/dot_config/wezterm/config/appearance.lua` | 23 |
| `src/dot_config/starship.toml` | 19 |
| `src/dot_config/zsh/env/common.zsh` | 16 |
| `src/dot_tmux.conf` | 7 |
| `src/dot_config/fastfetch/config-compact.jsonc` | 6 |
| `src/dot_config/fastfetch/config.jsonc` | 5 |
| `src/dot_config/nvim/lua/config/ftb_popup.lua` | 1 |
| **total** | **147 occurrences** |

Those 147 occurrences are **19 unique colours**, written in 6 different
syntaxes (TOML, Lua, zsh, tmux.conf, JSONC, and — externally — JSON).

Two more sources of truth sit outside that table:

- **VS Code**: `gruvbox-dark-hard.json` at the repo root (currently untracked,
  dropped in as a reference sample) — 258 `colors` keys, 127 `tokenColors`
  rules, 9 `semanticTokenColors` entries, resolving to ~24 base colours.
- **Neovim**: `ellisonleao/gruvbox.nvim`, a *plugin* supplying its own complete
  palette. It is not in this repo at all, yet defines most of what nvim renders.

The current guarantee that these agree is a comment in
`src/dot_config/nvim/lua/plugins/theme.lua`:

> the same hex palette as tmux (gruvbox-tmux) and starship's gruvbox_dark
> table, so all three stay pixel-identical.

A hand-maintained comment is the only thing enforcing consistency across nine
sources. That is the problem this system removes.

---

## 2. Core principle

**There is exactly one palette. It is the only place a hex literal ever
appears.** Everything else — every semantic role, every consumer adapter — is a
*reference* that ultimately resolves to a palette entry.

Layers may be stacked as deep as useful, and may transform colours on the way
through, but no layer introduces a new literal colour.

---

## 3. Architecture

```
palette              ~26 literal hex values — the ONLY hex in the repo
    |
    v
shared semantic      syntax.* · diagnostic.* · diff.* · ui.* (small core)
    |                cross-editor vocabulary; see §5
    v
adapters             one per consumer, in that consumer's native vocabulary
    |                vscode.json · nvim.toml · tmux.toml · yazi.toml · ...
    v
outputs              generated artifacts (w.install templates or w.generate)
```

Proposed layout:

```
themes/
  gruvbox-dark-hard/
    palette.toml       literal hex, the single source of truth
    semantic.toml      shared cross-consumer roles
    vscode.json        VS Code adapter (native key names)
    nvim.toml          Neovim adapter
    tmux.toml          tmux adapter
    yazi.toml          ... one per consumer
lua/
  theme/
    colors.lua         colour maths (alpha/mix/lighten/darken/is_dark)
    resolve.lua        reference resolution + cycle detection
modules/
  theme.lua            loads the active theme, exports the resolved table
```

Active theme is selected in `knobs/settings.toml` under a `[theme]` section, so
it participates in the existing profile-override merge in
`modules/system/settings.lua` for free (a `work` profile could select a light
theme without touching anything else).

---

## 4. Reference resolution

### 4.1 The two value forms

Everywhere except `palette.toml`, a value is a reference:

```toml
# string  = plain reference
border = "ui.border"

# object  = reference plus transforms
border = { ref = "ui.border", alpha = 0.5 }
```

Same rule in JSON:

```json
"editor.background":      "ui.background",
"button.hoverBackground": { "ref": "accent", "alpha": 0.38 }
```

**Rationale for object-form over a string DSL** (`"accent@38"`, `"mix(a,b,.5)"`):
it is native to both TOML and JSON, needs no parser, is unambiguous (string vs
table), extends naturally to new transforms, and keeps every value inspectable
as ordinary data. A string expression language would have to be written,
tested, and would inevitably grow.

**Rationale for allowing transforms in adapters at all** (rather than forcing
every derived colour to be named in a layer): 42 of VS Code's 258 keys are
alpha variants of a base hue. Naming all 42 would drag VS Code-specific chrome
names (`button.hoverBackground`) into a shared layer that nvim also reads.
Editor-specific tweaks belong in that editor's own adapter.

### 4.2 Resolution rules

- A reference is a dotted path into the resolved theme table
  (`ui.border`, `syntax.function`, `palette.blue_bright`).
- References chain: adapter -> semantic -> palette, or adapter -> adapter.
  Resolution walks until it lands on a literal, which can only come from
  `palette.toml` — that is the recursion base case.
- **Cycle detection is required.** A reference loop must produce a clear error
  naming the cycle, not hang or stack-overflow.
- A missing reference is a hard error naming the path and the file. Do not
  silently fall back.
- Transforms apply *after* the reference resolves to a literal.

### 4.3 Fallback chains

Wombat ships a `coalesce` template helper (first *defined* argument wins —
null-coalescing, not truthiness; errors only if every argument is missing):

```handlebars
{{coalesce theme.tmux.border theme.ui.border theme.palette.gray}}
```

This is a **safety net for genuinely optional values, not the backbone.** The
intended design is that each adapter defines its consumer's full required
vocabulary, so there is no "might be missing" case at render time — the theme
author resolves it once, at authoring time, by writing whichever single
reference is correct.

Note: Handlebars' built-in `or` returns a **boolean**, not a value, so it
cannot be used for this. `coalesce` exists specifically because of that.

---

## 5. The shared semantic layer

**Decision: share syntax, diagnostics, and diff/git. Do not try to share UI
chrome beyond a small core.**

Evidence from `gruvbox-dark-hard.json`:

- `semanticTokenColors` keys are `constant.builtin`, `property`, `parameter`,
  `variable`, `function`, `function.builtin`, `method`, `component` — these are
  **LSP semantic token types**, which map essentially 1:1 onto Neovim's
  treesitter captures (`@constant.builtin`, `@property`, `@parameter`, ...).
  Same vocabulary by design, not coincidence.
- The whole syntax surface is small: **127 token rules collapse to 19 unique
  colours**; 9 semantic entries to 5. A shared layer of that size is very
  tractable.
- UI chrome is the opposite: **258 keys**, including `activityBar`, `peekView`,
  `notifications`, `quickInput`, `titleBar` — concepts with no Neovim
  counterpart. Neovim's side is a couple of dozen groups (`Normal`,
  `NormalFloat`, `StatusLine`, `Pmenu`, `Visual`, `CursorLine`,
  `WinSeparator`).

So the shared layer covers:

| Group | Contents |
| --- | --- |
| `syntax.*` | comment, string, number, boolean, keyword, operator, function, method, variable, parameter, property, type, constant, constructor, namespace, punctuation, tag, attribute |
| `diagnostic.*` | error, warn, info, hint, ok |
| `diff.*` | add, change, delete, text |
| `ui.*` (core only) | background, foreground, surface, overlay, border, selection, cursor, accent, muted |

Anything outside that stays in the consuming adapter. Changing
`syntax.function` propagates to both editors; `activityBar.dropBorder` stays in
`vscode.json` where it belongs.

---

## 6. Per-consumer notes

**Format follows the consumer, not a repo-wide default.** TOML for shallow
adapters; JSON where the consumer's native format already is JSON.

### 6.1 VS Code

Authored as **`vscode.json` — a real VS Code theme file structurally**: same
key names, same three sections (`colors`, `tokenColors`, `semanticTokenColors`),
with references instead of hex values. This means VS Code's own documentation
and any published theme are directly copy-pasteable, and you retain full control
of the theme.

Generation is **`w.generate` + `w.json.encode`, not a template.** Reasons:

- The three sections have different shapes (`colors` is a flat map,
  `tokenColors` is an array of scope/settings rules, `semanticTokenColors` is
  another map). Reproducing that in Handlebars while fighting 258 keys, comma
  placement, and quoting is mechanical work Lua should just do.
- Lua can `require("theme.colors")` directly and call `colors.alpha(...)` while
  building the table — no Handlebars bridge needed at all.

**Important TOML gotcha, if any VS Code-shaped data is ever put in TOML:** 255
of the 258 keys are dotted (`widget.shadow`, `editor.background`). Written bare
in TOML, `editor.background = "x"` parses as *nested* `{editor = {background =
"x"}}`, not the flat string key VS Code requires. They must be quoted:
`"editor.background" = "x"`. This is a large silent-failure surface and is a
significant reason VS Code's adapter is JSON, where the problem cannot occur.

**Alpha:** 42 of 258 entries are 8-digit RGBA (e.g. `button.background` and
`button.hoverBackground` are the same blue at different opacities). Keep the
palette pure hue; express opacity with the object form
(`{ ref = "accent", alpha = 0.38 }`). `#0000` appears 10 times as a
transparent sentinel — it is not a colour and should be representable directly.

### 6.2 Neovim

**Decision: option 1 — feed the existing plugin.** `ellisonleao/gruvbox.nvim`
accepts `palette_overrides` and `overrides` in its `opts`. Generate a Lua file
injecting *our* palette into it.

- Keeps the plugin's exhaustive group coverage (treesitter, LSP, and every
  plugin integration) without owning it.
- Makes our palette authoritative, closing the ninth source of truth.
- Small effort relative to writing a colorscheme.

Rejected for now, but the path stays open: **option 2 — generate a standalone
colorscheme and drop the plugin.** More faithful to "all us", but a complete
nvim colorscheme is 200+ highlight groups including per-plugin ones, and that
coverage becomes ours to maintain forever. Because the shared semantic layer
would already exist, switching later is a contained change. Revisit if the
plugin's overrides prove too limiting.

`src/dot_config/nvim/lua/plugins/theme.lua` is the file that changes. All 12
nvim files under `src/dot_config/nvim/` are already tracked in git and deployed
as Wombat artifacts. `lazy-lock.json` and `lazyvim.json` are deliberately
untracked (editor-generated churn; `.lazy-lock.json` with a leading dot was
never the file lazy.nvim reads and was removed).

### 6.3 Everything else

tmux, yazi, wezterm, starship, fastfetch, and zsh all take shallow TOML
adapters and render through ordinary `.tmpl` templates. Their existing hex
literals (see §1) get replaced with references.

---

## 7. Wombat mechanics available

All verified against the binary at the time of writing. Wombat is pre-1.0 and
its API does move — re-verify before relying on details.

| API | Purpose |
| --- | --- |
| `w.toml.decode(path)` · `w.json.decode(path)` | Read repo data files as frozen Lua data. Digest joins build identity. (Renamed from `w.data.toml`/`w.data.json`.) |
| `w.json.encode(value)` · `w.toml.encode(map)` | Encode to string. Never touches the repo; pair with `w.generate`. |
| `w.array(values?)` · `w.null` | Lua `{}` is a map. Use `w.array()` for empty arrays; `w.null` for explicit null. Needed for correct `tokenColors` array shape. |
| `w.generate(name, {content=, to=})` | Publish Lua-computed bytes as an artifact. |
| `w.install(source, {to=, with=})` | Declare an artifact; `with` makes it a template. |
| `w.template.helpers(module, options?)` | Register a Lua helper pack for templates. |

### 7.1 Lua template helpers

`w.template.helpers("theme.colors", { prefix = "color_" })` registers helpers
globally for every template in the plan. Modules resolve beneath `lua/` using
`?.lua` and `?/init.lua`.

```handlebars
{{color_alpha theme.background 0.6 suffix="cc"}}
{{#if (color_is_dark theme.background)}}dark{{else}}light{{/if}}
```

Constraints that matter for this design:

- Helpers are **value functions** — usable in interpolation and subexpressions,
  **not** as blocks.
- Positional template args become positional Lua args; a final string-keyed
  options table always carries Handlebars hash arguments.
- Must return exactly one frozen value (null, boolean, finite number, string,
  array, map). Return `w.null`, not `nil`.
- They run in a **separate deterministic sandboxed Lua state**: table, string,
  UTF-8, deterministic math, and a minimal `require("wombat")` with `w.array`
  and `w.null`. **No** files, processes, environment, network, clock,
  randomness, or dynamic loaders.
- Helper source and its full top-level `require()` closure are frozen into the
  plan and participate in identity and template-cache keys — so helpers are as
  reproducible as any other input.
- Name conflicts, including shadowing built-ins or `coalesce`, are errors.

**Use the same `lua/theme/colors.lua` two ways:** registered via
`w.template.helpers()` for `.tmpl` consumers, and plain `require()`d as a
library from Lua that builds tables for `w.generate` (VS Code). One
implementation of the colour maths, two call paths.

### 7.2 Strictness

Rendering keeps two deliberate guarantees:

- **Missing values are a hard error**, on every construct that resolves a value.
- **`recursive_lookup` is off** — a name missing inside `{{#with x}}` does not
  silently fall through to a same-named parent value.

Both are load-bearing for a theme system: a typo'd colour role should fail the
build, never render as something plausible-but-wrong.

---

## 8. The palette

Current colours in `src/` (19 unique, counts across 147 occurrences), which is
standard gruvbox dark-hard:

```
#fe8019 orange_bright  18     #504945 bg2             7
#83a598 blue_bright    18     #fbf1c7 fg0             3
#fabd2f yellow_bright  15     #665c54 bg3             3
#1d2021 bg0_hard       14     #3c3836 bg1             3
#fb4934 red_bright     12     #453e38 (custom shade)  2
#8ec07c aqua_bright    11     #d65d0e orange          1
#ebdbb2 fg1            10     #bdae93 fg3             1
#b8bb26 green_bright   10     #928374 gray            1
#d3869b purple_bright   9     #7c6f64 bg4             1
#d5c4a1 fg2             8
```

The VS Code sample additionally uses the *neutral* (non-bright) hue variants
`#458588` blue, `#689d6a` aqua, `#98971a` green, `#cc241d` red, `#d79921`
yellow, `#b16286` purple, plus `#a89984` fg4. The union is the full standard
gruvbox palette: 8 background/foreground neutrals plus 7 hues in neutral and
bright variants, ~26 entries. `#453e38` is a custom in-between shade and should
be checked — it may be an ad-hoc value that can collapse into a standard slot.

---

## 9. Open questions

1. **Should each consumer's required symbol set be declared and validated?**
   i.e. a manifest of the names `tmux.toml` must define, checked at build time
   so a new theme that forgot a symbol fails during construction rather than at
   render. Better safety; more moving parts for a one-person, few-theme repo.
   Leaning yes, not decided.
2. **Is `#453e38` deliberate**, or an ad-hoc shade that should collapse into a
   standard gruvbox slot?
3. **How is the light/dark or multi-theme switch surfaced?** A `[theme]` key in
   `knobs/settings.toml` is assumed above, but whether themes are switchable at
   runtime (a command that re-applies) or only at build time is not settled.
   Build-time only is simpler and matches Wombat's model.
4. **Does anything need `w.toml.encode`**, or is TOML always authored by hand
   and only JSON generated?

---

## 10. Suggested implementation order

1. `themes/gruvbox-dark-hard/palette.toml` — the 26 literals, named.
2. `lua/theme/colors.lua` — alpha, mix, lighten, darken, is_dark. Pure
   functions, no state.
3. `lua/theme/resolve.lua` — reference walk, transform application, cycle
   detection, clear errors.
4. `modules/theme.lua` — load palette + semantic + adapters, export resolved
   table. Register `w.template.helpers("theme.colors")`.
5. **One consumer end to end: tmux.** Smallest (7 hexes), proves the whole
   chain, easy to eyeball.
6. Remaining `.tmpl` consumers: starship, yazi, wezterm, fastfetch, zsh.
7. `semantic.toml` — the shared syntax/diagnostic/diff layer.
8. Neovim via `palette_overrides` (§6.2).
9. VS Code via `vscode.json` + `w.generate` (§6.1) — largest, do last, benefits
   from every lesson above.

Verify with `wombat build` and `wombat diff` at each step; `wombat explain
<path>` shows the frozen context a file rendered with, which is the main
debugging tool when a colour comes out wrong.
