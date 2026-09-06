# SYSTEM PROMPT ADDENDUM: Defold & Lua Coding Standards

> **Version:** 2.0
> **Last Updated:** Agosto 2026
> **Scope:** All Lua scripts (`.script`, `.gui_script`, `.lua`) within Defold projects.

---

## Table of Contents
1. [Memory & Performance Optimization](#1-memory--performance-optimization)
2. [Hash Management](#2-hash-management)
3. [Architecture & State Management](#3-architecture--state-management)
4. [Message Passing & on_message](#4-message-passing--on_message)
5. [String & URL Manipulation](#5-string--url-manipulation)
6. [Lifecycle Management](#6-lifecycle-management)
7. [Error Handling](#7-error-handling)
8. [Animation & Tweening](#8-animation--tweening)
9. [Code Organization & Patterns](#9-code-organization--patterns)

---

## 1. Memory & Performance Optimization

### Mandatory Localization

Always declare variables and functions with the `local` keyword.
Global scope execution is strictly prohibited.

> **Note:** Defold's lifecycle callbacks (`init`, `update`, `on_message`,
> `on_input`, `final`, `on_reload`) MUST remain global — the engine looks
> them up as globals. Localization applies to all *helper* variables and
> functions.

```lua
-- ❌ FORBIDDEN
function updatePlayer() end
score = 0

-- ✅ CORRECT
local function updatePlayer() end
local score = 0
```

### Cache External Functions

Cache library functions at the top of the file only when they are called
inside high-frequency loops or callbacks. Do not cache preemptively
without a measurable performance justification.

```lua
-- ✅ Useful when called hundreds of times per frame
local vector3  = vmath.vector3
local sin      = math.sin
local abs      = math.abs
```

### Zero-Garbage Update Loops

Never instantiate tables, vectors, or strings inside `update(self, dt)`
or `fixed_update(self, dt)`. Every allocation inside a hot path
contributes to GC pressure and frame spikes.

```lua
-- ❌ FORBIDDEN inside update()
function update(self, dt)
    local dir      = vmath.vector3(1, 0, 0)   -- new table every frame
    local enemies  = {}                         -- new table every frame
    local label    = "score: " .. self.score   -- new string every frame
end

-- ✅ CORRECT — pre-allocate in init(), mutate in update()
function init(self)
    self.dir     = vmath.vector3(1, 0, 0)
    self.enemies = {}
end

function update(self, dt)
    self.dir.x = 1    -- mutate, never recreate
end
```

### Patrón canónico Zero-Garbage en update() (refactor Ago 2026)

Dos enfoques probados en el refactor global de hot paths (cámara, jugador,
enemigos, props). Elegir en este orden:

#### Enfoque 1 — Distancia al cuadrado sin vector (solo necesitas un escalar)

Si solo necesitas una magnitud (distancia, comparación de rango), **no alojes
ningún vector**: la resta `a - b` crea un vector nuevo por frame.

```lua
-- ❌ player_pos - my_pos aloja un vector cada frame
local dist = vmath.length(player_pos - my_pos)

-- ✅ componentes + cuadrado, con el umbral precalculado
-- init():  self.range_sqr = self.interact_distance * self.interact_distance
local dx = player_pos.x - door_pos.x
local dy = player_pos.y - door_pos.y
local in_range = (dx * dx + dy * dy) <= self.range_sqr
```

- **Equivalencia:** con ambos lados no negativos, `dist <= R` ⇔ `dist² <= R²`.
- **Precalcula el cuadrado** en `init()` o como constante de módulo (nunca
  `R * R` por frame). Precedente: `MOVE_HIDE_THRESHOLD_SQR` en
  `dialogue_manager.script`.
- **2D vs 3D:** el plano del juego es XY; diferencias de Z despreciables.
  Si ambos vectores provienen del mismo GO (mismo z), la comparación 2D es
  **exacta**.
- `math.sqrt()` solo si necesitas la magnitud para otra cosa (p. ej. para
  imprimir `floor(dist)` en logs de entrada).
- **Ejemplos:** `doors.script` (`range_sqr`), `door_main.script`
  (`open_distance_sqr`/`close_distance_sqr`), `office_cabinet.script`
  (`close_distance_sqr`), `dialogue_manager.script` (ocultar globo "no disponible").

#### Enfoque 2 — Mutar vector pre-asignado (necesitas el vector)

Para movimiento, orientación o cualquier resultado vectorial real:

```lua
-- init():  pre-asignar UNA vez
self.tmp_move = vmath.vector3()
self.tmp_rot  = vmath.quat_rotation_z(0)

-- update():
local pos = go.get_position()          -- API del motor (inevitable)
local new = self.tmp_move
new.x = pos.x + self.velocity.x * dt   -- a + b*c*dt ⇔ escribir cada componente
new.y = pos.y + self.velocity.y * dt
new.z = pos.z + self.velocity.z * dt
go.set_position(new)                   -- el motor COPIA el valor → reutilizable

-- resets por componentes: NUNCA self.x = vmath.vector3() de nuevo
self.direction.x, self.direction.y, self.direction.z = 0, 0, 0
```

Reglas:
- `go.set_position`/`go.set_rotation` copian el valor → reutilizar el scratch
  es seguro entre frames y entre estados mutuamente excluyentes.
- Escribe el scratch **por completo** antes de consumirlo (sin estado medio).
- **Orientación sin alocar:** mutar el quat por componentes — `rot.z =
  sin(θ/2)`, `rot.w = cos(θ/2)` es exactamente `vmath.quat_rotation_z(θ)`
  (ver `set_rotation_from_dir` en `enemy_rat.script`/`enemy_cockroach.script`).
- **Cuidado con semántica de referencias:** si pasas el scratch a otro módulo
  que guarda la referencia (p. ej. `aiming.set_facing`), muta solo cuando
  vayas a re-registrar; al parar no lo toques (fallback conserva la última
  dirección — ver `reset_movement_state` en `player.script`).
- **Ejemplos:** `bullet.script` (movimiento + decaimiento de velocidad por
  componentes), `car.script` (MOVING/BRAKING con `if/else` para el reinicio
  a start), `player.script`, `camera.script`.

#### Qué NO se puede eliminar (aceptado)

- `go.get_position()` / `go.exists()` — API del motor (alocación engine-side).
- `string.format` / `..` — solo bajo flags DEBUG (`make_log`).
- Alocaciones event-driven (una vez por transición/timer, fuera del hot path).

### Object Reusability

Mutate existing `self` properties or pre-allocated vectors instead of
creating new ones inside frequent cycles.

```lua
-- ❌ FORBIDDEN
function update(self, dt)
    local newPos = vmath.vector3(self.pos.x + dt, self.pos.y, 0)
    go.set_position(newPos)
end

-- ✅ CORRECT
function update(self, dt)
    self.pos.x = self.pos.x + dt
    go.set_position(self.pos)
end
```

### GUI Node Pooling

Avoid excessive or uncontrolled use of `gui.clone()`.
Reuse node pools where possible. Hide inactive nodes instead of
deleting and recreating them.

```lua
-- ✅ Pool pattern
local function get_node_from_pool(self)
    for _, node in ipairs(self.node_pool) do
        if not gui.is_enabled(node) then
            gui.set_enabled(node, true)
            return node
        end
    end
end

local function return_node_to_pool(node)
    gui.set_enabled(node, false)
end
```

## 2. Hash Management

Pre-hashing is critical in Defold. Calling `hash()` at runtime inside
frequently executed callbacks creates unnecessary overhead and is considered
an anti-pattern.

### Pre-hash All Identifiers

Declare all animation IDs, message IDs, property names, and URL fragments
as hashed constants at the top of every file.

```lua
-- ✅ Declare at file scope, outside any function
local ANIM_IDLE   = hash("idle")
local ANIM_RUN    = hash("run")
local ANIM_JUMP   = hash("jump")

local PROP_TINT   = hash("tint")
local PROP_SCALE  = hash("scale")

local MSG_ENABLE  = hash("enable")
local MSG_DISABLE = hash("disable")
local MSG_DAMAGE  = hash("damage")
```

### Never Hash at Runtime in Hot Paths

```lua
-- ❌ FORBIDDEN — hashing inside update() or on_input()
function update(self, dt)
    sprite.play_flipbook("#sprite", hash("run"))
end

-- ✅ CORRECT — use the pre-hashed constant
function update(self, dt)
    sprite.play_flipbook("#sprite", ANIM_RUN)
end
```

### Hash Comparison in Conditionals

```lua
-- ❌ FORBIDDEN — string comparison at runtime
if message_id == "damage" then ... end

-- ✅ CORRECT — hash comparison is O(1) and zero-allocation
if message_id == MSG_DAMAGE then ... end
```

## 3. Architecture & State Management

### No Global State (_G)

Shared or global data (e.g., player stats, game configuration, managers)
must reside exclusively inside pure Lua modules (`.lua`).
Writing to `_G` is strictly forbidden.

```lua
-- ❌ FORBIDDEN
_G.player_health = 100

-- ✅ CORRECT — encapsulated Lua module
-- /player/player_data.lua
local M = {}
M.health = 100
return M
```

### Encapsulation via self

Script-specific state must be stored in the `self` reference table
provided by Defold's lifecycle callbacks.

```lua
function init(self)
    self.health    = 100
    self.is_alive  = true
    self.velocity  = vmath.vector3()
end
```

### Decoupled Communication

Cross-component interaction must be handled exclusively via `msg.post()`.
Direct cross-script table manipulation is strictly forbidden.

```lua
-- ❌ FORBIDDEN
other_script.health = 50

-- ✅ CORRECT
msg.post("/player#health_script", MSG_DAMAGE, { amount = 50 })
```

### Robust URL Addressing

Prefer relative URLs or pre-cached absolute URLs resolved during `init()`.
Avoid hardcoded string paths that silently break upon collection renaming.

```lua
-- ❌ FRAGILE
msg.post("/level/hud/ui#gui_script", "update_score", { score = self.score })

-- ✅ CORRECT — cache URL in init()
function init(self)
    self.hud_url = msg.url("/level/hud/ui#gui_script")
end

function update(self, dt)
    msg.post(self.hud_url, MSG_UPDATE_SCORE, { score = self.score })
end
```

## 4. Message Passing & on_message

### Canonical on_message Pattern

Always compare `message_id` against pre-hashed constants.
Never use raw string literals inside `on_message`.

```lua
local MSG_DAMAGE  = hash("damage")
local MSG_HEAL    = hash("heal")
local MSG_RESPAWN = hash("respawn")

function on_message(self, message_id, message, sender)
    if message_id == MSG_DAMAGE then
        self.health = self.health - message.amount
        if self.health <= 0 then
            self:die()
        end

    elseif message_id == MSG_HEAL then
        self.health = math.min(self.max_health, self.health + message.amount)

    elseif message_id == MSG_RESPAWN then
        self:respawn()
    end
end
```

### Message Payload Conventions

Always use named fields inside the message table. Avoid positional or
ambiguous keys.
Keep payloads flat and minimal. Never pass nested tables unless strictly
necessary.

```lua
-- ❌ AVOID — ambiguous payload
msg.post(url, MSG_DAMAGE, { 50 })

-- ✅ CORRECT — explicit, self-documenting payload
msg.post(url, MSG_DAMAGE, { amount = 50, source = "fire" })
```

## 5. String & URL Manipulation

### Avoid String Concatenation in Hot Paths

The `..` operator creates a new string object on every call.
Never use it inside `update()`, `on_input()`, or any other
high-frequency function.

```lua
-- ❌ FORBIDDEN inside update() or loops
local label = "score: " .. self.score

-- ✅ CORRECT — pre-build static strings in init()
--    For dynamic labels, update only on data change, not every frame.
function on_message(self, message_id, message, sender)
    if message_id == MSG_UPDATE_SCORE then
        self.score = message.value
        -- Update the label only when the value actually changes
        gui.set_text(self.score_node, tostring(self.score))
    end
end
```

### string.format() Is Not Garbage-Free

`string.format()` allocates a new string on every call, exactly like `..`.
Use it for debugging or one-off formatting only — never inside hot paths.

```lua
-- ⚠️ Also allocates — acceptable for debug logs only
print(string.format("Health: %d / %d", self.health, self.max_health))

-- ✅ For runtime UI, update the string only on value change (see above)
```

### Pre-parsed URLs

Never construct or concatenate URLs dynamically inside `update()`.
Always resolve and cache URL objects during `init(self)`.

```lua
-- ❌ FORBIDDEN
function update(self, dt)
    msg.post("/enemies/enemy_" .. self.id .. "#script", MSG_DISABLE)
end

-- ✅ CORRECT
function init(self)
    self.enemy_url = msg.url("/enemies/enemy_" .. self.id .. "#script")
end

function update(self, dt)
    msg.post(self.enemy_url, MSG_DISABLE)
end
```

## 6. Lifecycle Management

### Always Clean Up in final()

Use `final(self)` to cancel timers, release resources, and unsubscribe
from any active listeners. Neglecting cleanup leads to dangling handles
and memory leaks.

```lua
function init(self)
    self.timer_id   = timer.delay(2.0, true, function() self:spawn_wave() end)
    self.is_active  = true
end

function final(self)
    -- ✅ Cancel all active timers
    if self.timer_id then
        timer.cancel(self.timer_id)
        self.timer_id = nil
    end

    -- ✅ Disable physics or listeners if applicable
    self.is_active = false
end
```

### Timer Guidelines

Prefer `timer.delay()` over manual countdown logic in `update()` for
simple delayed or repeating actions.

```lua
-- ❌ AVOID — manual timer in update()
function update(self, dt)
    self.cooldown = self.cooldown - dt
    if self.cooldown <= 0 then
        self:fire()
        self.cooldown = 1.0
    end
end

-- ✅ PREFERRED for simple cases
function init(self)
    self.fire_timer = timer.delay(1.0, true, function() self:fire() end)
end
```

> **Note:** Manual `dt` accumulation in `update()` remains valid and
> preferred when the interval must be dynamic or the logic is tightly
> coupled to per-frame state.

## 7. Error Handling

### Defensive URL Validation

Always validate that cached URLs are non-nil before posting messages,
especially when the target object may be destroyed at runtime.

```lua
local function safe_post(url, message_id, message)
    if url then
        msg.post(url, message_id, message)
    else
        print("[WARN] safe_post: attempted to post to a nil URL")
    end
end
```

### Use pcall for Unsafe Operations

Wrap any operation that may fail at runtime (file I/O, JSON parsing,
external module calls) in `pcall` to prevent unhandled errors from
crashing the game loop.

```lua
local ok, result = pcall(function()
    return json.decode(raw_data)
end)

if not ok then
    print("[ERROR] Failed to parse JSON: " .. tostring(result))
    return
end

-- Safe to use result here
```

### Assert for Invariants During Development

Use `assert()` to catch programming errors early during development.
Remove or gate asserts behind a debug flag for production builds.

```lua
local DEBUG = true  -- toggle per build

local function expect(value, message)
    if DEBUG then
        assert(value, message)
    end
end

-- Usage
expect(self.config ~= nil, "Config must be initialized before use")
```

## 8. Animation & Tweening

### Prefer go.animate() Over Manual Interpolation

Use `go.animate()` for property transitions whenever possible.
It is implemented engine-side in C++ (not in the Lua VM), so it
produces no per-frame Lua garbage, and supports easing curves natively.

```lua
-- ❌ AVOID — manual lerp in update() for simple transitions
function update(self, dt)
    self.pos.y = self.pos.y + self.speed * dt
    go.set_position(self.pos)
end

-- ✅ PREFERRED for fire-and-forget transitions
go.animate(".", "position.y", go.PLAYBACK_ONCE_FORWARD,
    target_y, go.EASING_OUTQUAD, duration)
```

### Cancel Animations Before Reassigning

Always cancel an ongoing animation on a property before starting a new
one on the same property to avoid conflicting tweens.

```lua
go.cancel_animations(".", "position")
go.animate(".", "position", go.PLAYBACK_ONCE_FORWARD,
    target_pos, go.EASING_INSINE, 0.3)
```

### Use Callbacks for Chained Sequences

```lua
go.animate(".", "position.y", go.PLAYBACK_ONCE_FORWARD,
    100, go.EASING_OUTBOUNCE, 0.5,
    0,  -- delay
    function()
        -- ✅ Triggered once, zero per-frame cost
        msg.post("#", MSG_LAND_COMPLETE)
    end
)
```

## 9. Code Organization & Patterns

### MVC / Separation of Concerns

Keep core game logic inside pure Lua modules (`.lua`).
Use `.script` and `.gui_script` files solely as thin controllers that
bridge engine lifecycle events to the underlying logic layer.

```text
/player/
    player.go
    player.script       ← controller: lifecycle, input, msg routing
    player_logic.lua    ← pure logic: stats, movement, abilities
    player_data.lua     ← pure data: constants, config tables
```

### Feature-Driven File Structure

Organize project files by feature domain, not by technical file type.

```text
-- ❌ AVOID
/scripts/
/gui_scripts/
/modules/

-- ✅ PREFERRED
/player/
/enemies/
/ui/
/common/
/audio/
```

### Module Structure Convention

All Lua modules must follow the `local M = {} ... return M` pattern.
No module may expose mutable global state.

```lua
-- /common/health.lua
local M = {}

local MAX_HEALTH = 100

function M.new(initial)
    return { current = initial or MAX_HEALTH, max = MAX_HEALTH }
end

function M.apply_damage(instance, amount)
    instance.current = math.max(0, instance.current - amount)
    return instance.current <= 0
end

function M.apply_heal(instance, amount)
    instance.current = math.min(instance.max, instance.current + amount)
end

return M
```

### Cabecera Estándar de Archivo (File Header)

Todo archivo Lua (`.script`, `.gui_script`, `.lua`) DEBE abrir con la cabecera
canónica siguiente. Es la identidad visual del proyecto y la vía más rápida
para entender el rol de un archivo sin leer su código.

```lua
-- main/example.script
-- ═══════════════════════════════════════════════════════
-- 🖼️ SISTEMA DE COLECCIONABLES
-- ═══════════════════════════════════════════════════════
--
--   Descripción funcional: para qué existe este script, en
--   2-4 líneas (p. ej. "ÚNICO punto de entrada de la lógica").
--
--   Mensajes que ENVÍA (msg.post):
--     → "update_hud_state"      (hacia HUD)
--   Mensajes que RECIBE (on_message):
--     ← "collectible_clicked"   (desde btn_collectible)
--   Llamadas directas:
--     inventory_core:update(dt) — timers (sin msg.post)
--
--   ⚠️ Advertencias / prerequisitos (opcional)
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-15
-- ═══════════════════════════════════════════════════════
```

Reglas:

- **Ruta relativa sin barra inicial** — convención del proyecto:
  `main/foo.script`, nunca `/main/foo.script` (la barra inicial es de rutas de
  recurso del editor, no de cabeceras).
- **Strings de mensajes copiados EXACTOS** como se pasan a `hash()` en el
  código → `grep` encuentra a la vez cabecera e implementación.
- **Separar ENVÍA / RECIBE / llamadas directas**: nunca mezclar `msg.post`
  con llamadas a módulos en la misma línea (no son el mismo concepto).
- **Emoji identificativo opcional** (🔄 máquina de estados, 🪳 spawn, 🐀 IA de
  la rata) — acelera el escaneo visual del proyecto.
- **Sin número de versión por archivo** (se desincroniza en un repo de 77+
  archivos): usar `Última actualización: AAAA-MM-DD`. Si es imprescindible
  versionar, hacerlo SOLO en módulos core (`inventory_core`, `game_state`...).
- **Licencia**: referencia al archivo `LICENSE` de la raíz (no `LICENSE.txt`).

### Input Handling

Process input exclusively inside `on_input(self, action_id, action)`.
Never poll input state manually inside `update()`.

```lua
local INPUT_JUMP  = hash("jump")
local INPUT_FIRE  = hash("fire")

function on_input(self, action_id, action)
    if action_id == INPUT_JUMP and action.pressed then
        self:jump()
    elseif action_id == INPUT_FIRE and action.pressed then
        self:fire()
    end
    return false
end
```

---

## Quick Reference Checklist

| # | Rule | Scope |
|---|------|-------|
| 1 | All variables and functions use `local` (except Defold lifecycle callbacks) | All files |
| 2 | No allocations inside `update()` or `fixed_update()` — ver patrón canónico §1 (distancia² sin vector / mutar pre-asignado) | Scripts |
| 3 | All hashes pre-computed at file scope | All files |
| 4 | All URLs resolved and cached in `init()` | Scripts |
| 5 | No `..` concatenation in hot paths | All files |
| 6 | `on_message` uses only pre-hashed `message_id` comparisons | Scripts |
| 7 | `final()` cancels all timers and releases resources | Scripts |
| 8 | `go.animate()` preferred over manual lerp in `update()` | Scripts |
| 9 | Game logic lives in `.lua` modules, not in `.script` files | Architecture |
| 10 | File structure organized by feature domain | Project |
| 11 | All scripts carry the canonical file header (banner + ENVÍA/RECIBE, §9) | All files |
