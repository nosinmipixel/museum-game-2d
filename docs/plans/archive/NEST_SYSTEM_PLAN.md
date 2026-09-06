# 🪺 SISTEMA DE NIDOS DE ENEMIGOS — ESTRATEGIA (✅ EJECUTADO — ARCHIVADO)

> **Estado: ✅ IMPLEMENTADO (Agosto 2026).** Fases 2-4 implementadas y verificadas, con las
> simplificaciones posteriores del modelo de ocultación (armarios con z estable + activación
> por estado — GOTCHA #31). Archivo histórico: la especificación original queda como
> referencia; el estado actual del sistema vive en `docs/PROJECT_SUMMARY.md` y
> `docs/DEV_GOTCHAS.md`.
>
> **Fecha:** 2026-08-17 · **Motor:** Defold 1.13 · **Licencia:** GPL-3.0-only

---

## 1. 🎯 Objetivo

Añadir profundidad a la mecánica de emisión de enemigos y a la interacción del jugador:

1. Un objeto **`nest_container`** en la escena con una lista de puntos **`nest_spawn_01..10`**
   (marcadores vacíos colocados con el editor de Defold).
2. Al empezar, se distribuyen **5 nidos activos** en 5 puntos aleatorios.
3. Cada nido es un emisor de enemigos (reutiliza `spawn_enemies.script` tal cual: trigger,
   oleadas escalonadas, `reactivate_delay`, guards de muerte).
4. El jugador puede eliminar el **nido completo** si tiene **insecticida especial** (recurso raro):
   clic sobre el nido con carga → destrucción (mismo patrón que gato + lata de comida).
5. Al destruir un nido, el contenedor coloca **otro nido nuevo** en otro punto libre, hasta
   agotar los 10 puntos (la plaga tiene 10 "vidas" acotadas).

## 2. ✅ Decisiones confirmadas (2026-08-17)

| Decisión | Opción elegida |
|---|---|
| **Aplicación del insecticida** | **Clic sobre el nido** (hover + clic, patrón gato/lata). Consume 1 carga → destruye el nido con animación/sonido. Sin carga → alerta localizada |
| **Rareza del pickup** | **Probabilidad en spray points**: un % (configurable) de que un respawn del spray sea un bote de **insecticida** (sprite distinto) en vez de spray |
| **Tarea de plagas** | **Híbrido**: el umbral sigue siendo `PESTS_MIN = 20`, pero cada nido destruido suma un **bonus configurable** (default +5) a `task_bugs_total`. El grind SIEMPRE es posible; el nido es la vía estratégica |
| **Nidos simultáneos** | **5 activos de 10**; al destruir uno se repone en otro punto libre hasta agotar los 10 |
| **Rangos aleatorios** | Sí: parámetros de oleada con `_max` opcional (backwards-compatible); los nidos leen rangos de `config.balance` |
| **Cargas máximas de insecticida** | **2** — el HUD muestra "x/2" (`text_icon_poison`) |
| **Hover del nido** | **Tint rojizo** (animado con `go.animate`), sin arte nuevo |
| **Z del sprite del nido** | **0.01** — verificado en runtime: los `nest_spawn` a 0.01 dejan el nido POR DEBAJO de ratones/cucarachas (§3.4) |
| **Z de los spray_spawn** | **0.1** — necesario para el sistema de ocultación (se bajaron de 1.0) |
| **Visibilidad del icono HUD** | **Oculto hasta la 1ª carga** — patrón `box_icon_cat_food` (§8) |

## 3. 🏗️ Arquitectura

### 3.1 Archivos NUEVOS

| Archivo | Rol | Patrón reutilizado |
|---|---|---|
| `main/nest_spawn_state.lua` | Puente contenedor↔nido (`pending_spawn{ position, index }`, `container_url`) | Espejo de `main/spray_spawn_state.lua` |
| `main/nest_spawn_state.lua` (mismo) | Registro de nidos destruidos (`mark_destroyed(go.get_id())` / `is_destroyed(id)`) | Flag de módulo como `enemy_state.waves_paused` (GOTCHA #33) |
| `features/props/nest_container.go` + `.script` | Descubre `nest_spawn_01..10`, elige 5 aleatorios, crea nidos, gestiona reposición | Clon estructural de `spray_spawn_container.go/.script` |
| `features/enemies/nest.go` | GO del nido: spawn_enemies.script + factories + sprite + collisionobjects | `spawn_enemies` GO del editor + `spray_can.go` (interact) + `enemy_cockroach.go` (factories) |
| `features/enemies/nest.script` | Ciclo de vida del nido: leer config de `nest_spawn_state`, hover/interact, destrucción, purga, notificar contenedor | `spray_can.script` (pickup/interact) + `office_cabinet.script` (hover/clic) |

### 3.2 Archivos MODIFICADOS

| Archivo | Cambio | Por qué |
|---|---|---|
| `main/spawn_enemies.script` | **Guard opcional de nido destruido** en los 2 callbacks de timer: `nest_spawn_state.is_destroyed(go.get_id())` junto a `enemy_state.is_waves_paused()` | Evita que un timer pendiente cree enemigos tras destruir el nido (ruido de consola + bicho fantasma). Sin cambio de comportamiento para el spawner standalone (id no registrado → false) |
| `features/props/spray_spawn_container.script` | Al reponer/crear un bote, tirada de probabilidad: ¿spray o insecticida? (lee `config.balance.nest.insecticide_chance`) | Modelo de rareza elegido |
| `features/props/spray_can.script` | Variante insecticida: si el pending_spawn marca `is_insecticide`, al recoger otorga carga de `nest_insecticide` (no rellena spray) y usa sprite/anim distinta | Un solo tipo de GO recogible, dos efectos |
| `main/config.lua` | Nueva sección `M.balance.nest` (valores de balance) | Fuente única ajustable sin tocar código |
| `gui/hud.gui` + `hud.gui_script` | Icono de cargas de insecticida + contador (nodos nuevos) | Feedback del recurso raro |
| `assets/texts/general_text_es.lua` / `_en.lua` | Textos de alerta nuevos (sin insecticida, nido destruido, etc.) | Localización (GOTCHA #20/#37/#38) |
| `level_01.collection` | Instancia `nest_container` + hijos `nest_spawn_01..10` (marcadores vacíos, sin arte) | Escena |

### 3.3 Estructura del GO `nest.go`

```
nest.go
├── components
│   ├── spawn_enemies.script     ← oleadas (reutilizado tal cual; exige collisionobject "collisionobject")
│   └── nest.script              ← ciclo de vida + interacción (nuevo)
├── embedded_components
│   ├── collisionobject          ← TRIGGER, group "spawn", mask "player_spawn", esfera r=50
│   │                              (el nombre EXACTO lo exige spawn_enemies.script: "#collisionobject")
│   ├── collisionobject_interact ← KINEMATIC, group "interactivable", mask "cursor" (hover/clic)
│   ├── sprite                   ← arte del nido (default_animation "nest_idle")
│   ├── bug_factory              → /features/enemy_cockroach/enemy_cockroach.go
│   └── rat_factory              → /features/enemy_rat/enemy_rat.go
```

### 3.4 🎚️ Z del sprite del nido (⚠️ VALOR FINAL VERIFICADO EN RUNTIME: 0.01)

**Decisión cerrada por prueba en el editor (2026-08-17):** los marcadores `nest_spawn_01..10`
van a **z 0.01** para que el nido quede **por debajo de ratones y cucarachas** (los enemigos
nacen en la z del spawner, por encima, y deben dibujarse delante del nido al salir).

- El sprite en `nest.go` NO lleva z local (z=0) → el nido hereda la z del marcador que lo creó
  (`go.get_position()` copia la posición completa, igual que `food_spawn_container`).
- **z 0.01** cumple la regla mínima del GOTCHA #9 (sprites del mundo en z ≥ 0.01; en 0 no se
  renderizan) y deja el orden correcto: nido 0.01 < enemigos.
- ⚠️ **Lección**: el z de un objeto NO es universal — `food_cat_can`/`food_spawn` van a 0.1
  (objetos recogibles SIN criaturas encima) y `spray_spawn` también a **0.1** (necesario para el
  sistema de ocultación). El nido es el caso distinto: al ser un emisor, sus criaturas deben
  pasar POR DELANTE → z 0.01.
- Orden de profundidad del proyecto: tilemap ~0.0001 · nidos 0.01 · enemigos (z del spawner) ·
  jugador/latas 0.1 · sprays 0.1 · puertas 0.2.

⚠️ **Dos collisionobjects distintos**: el trigger de oleadas (detecta al jugador) y el de
interacción (lo detecta el cursor). Ambos coexisten en el mismo GO (patrón ya usado en `spray_can.go`).

## 4. 🔄 Flujos

### 4.1 Arranque (nest_container.init → update)
1. Descubrir `nest_spawn_01..10` por naming (mismo bucle que `discover_spawn_points`).
2. Elegir 5 índices aleatorios sin repetición.
3. Por cada uno: escribir `nest_spawn_state.pending_spawn = { index, position, config }` →
   `factory.create("#nest_factory", position)` (factory síncrono → el `init()` del nido lee y limpia).
4. `nest_spawn_state.container_url = msg.url()` para que los nidos notifiquen su destrucción.

### 4.2 Oleadas (sin tocar)
Cada nido hereda de `spawn_enemies.script`: trigger → oleada escalonada → `reactivate_delay`
mientras el jugador siga en `activation_radius`. Los nidos **lejanos quedan dormidos** hasta que
el jugador entra en su radio (comportamiento natural del trigger).

### 4.3 Destrucción del nido (nest.script)
1. Jugador con cursor sobre el nido (`mouse_hover` → **tint rojizo**) y clic (`interact`).
2. Si `nest_insecticide > 0`:
   - `game_state.add_to_global("nest_insecticide", -1)`
   - `game_state.add_to_global("task_bugs_total", balance.nest.nest_bonus)` → re-evalúa tarea (híbrido)
   - `nest_spawn_state.mark_destroyed(go.get_id())` (antes de borrar → el guard de spawn_enemies corta timers)
   - **Purga**: borrar enemigos vivos de `enemy_state.get_spawned()` dentro de `purge_radius` del nido
     (el nido "arrasa su camada" — coste del insecticida invertido)
   - Reproducir animación de destrucción + sonido → `msg.post(container_url, "nest_destroyed", { index })` → `go.delete()`
3. Si `nest_insecticide == 0` → alerta localizada "necesitas insecticida".

### 4.4 Reposición (nest_container)
- Al recibir `nest_destroyed { index }`: marcar punto como libre.
- Si quedan puntos libres y no se ha destruido el **total de 10** → elegir punto libre aleatorio y
  crear nido nuevo (dormido hasta que el jugador se acerque).
- Si se agotaron los 10 → no más nidos (plaga erradicada; la tarea puede seguir completándose por grind).

### 4.5 Muerte / reintentar
- Los nidos son GOs **persistentes de la colección** (el contenedor es estático; los nidos son
  instancias de factory **del contenedor**, no enemigos) → sobreviven a `enemy_state.clear_alive()`.
- Los enemigos sueltos se limpian como hoy. La plaga sigue donde estaba. ✅ coherente.

## 5. ⚙️ Configuración (`main/config.lua` → `M.balance.nest`)

```lua
-- 🪺 SISTEMA DE NIDOS (leído por nest_container.script / nest.script / spray_spawn_container)
M.balance.nest = {
    active_count      = 5,     -- nidos simultáneos (de 10 puntos)
    insecticide_chance = 0.18, -- prob. de que un respawn del spray sea bote de insecticida
    insecticide_max   = 2,     -- cargas máximas de insecticida que puede llevar el jugador
    nest_bonus        = 5,     -- task_bugs_total por nido destruido (tarea híbrida, PESTS_MIN=20)
    purge_radius      = 120,   -- radio de purga de enemigos al destruir el nido
    respawn_delay     = 1.5,   -- retardo (s) entre destrucción y colocación del nido nuevo
}
```

Convención del proyecto: los consumidores leen con fallback (`config.balance.nest.xxx or default`),
una clave borrada nunca rompe el juego.

## 6. 🎲 Rangos aleatorios en los parámetros de oleada

**Mecanismo (backwards-compatible, no rompe las configs del editor):**

- Se mantienen los go.property escalares actuales (`total_enemies`, `spawn_interval`,
  `spawn_radius`) como **mínimo**.
- Se añade un `_max` opcional: si `x_max > x` → tirar uniforme en `[x, x_max]` **por oleada**;
  si no, comportamiento actual idéntico (el spawner standalone del editor no cambia).
- Para los **nidos** (creados por factory, sin config por instancia en el editor), los rangos
  viven en `config.balance.nest_ranges`:

```lua
M.balance.nest_ranges = {
    total_enemies  = { min = 3, max = 5 },      -- 3..5 por oleada
    spawn_interval = { min = 2.5, max = 5.0 },  -- 2.5..5 s entre apariciones
    spawn_radius   = { min = 15, max = 30 },    -- dispersión
    enemy_types    = { "cockroach", "rat", "mix" },  -- tipo elegido al azar por nido
    reactivate_delay = { min = 8, max = 20 },   -- ritmo de oleadas por nido
}
```

## 7. 🏆 Integración con la tarea de plagas (híbrido)

- **Hoy**: `task_bugs_total >= tasks.PESTS_MIN (20)` — solo kills (+1 por bicho muerto).
- **Con nidos**: cada destrucción suma `nest_bonus` (+5) vía `add_to_global("task_bugs_total", bonus)`
  → la re-evaluación de la tarea ya existe en `add_to_global` (no hay que tocar `tasks.lua` ni
  `game_state.lua`).
- **Resultado**: 20 se alcanza solo matando (grind siempre posible, sin dependencia del RNG del
  insecticida) o combinando nidos (+5) con kills. El nido es la vía eficiente, nunca un bloqueo.

## 8. 🧩 Assets y UI — ESTADO VERIFICADO (2026-08-17, todos listos)

| # | Asset | Uso | Dónde va | Estado |
|---|---|---|---|---|
| 1 | **Sprite de nido**: `nest_idle` (animación `PLAYBACK_NONE` con frame `nest_enemies_01`) | El nido visible en la escena → `default_animation: "nest_idle"` | `features/props/props.atlas` | ✅ **Listo** — usar `nest_idle` (misma imagen estática, semántica de animación) |
| 2 | **Animación de destrucción**: `nest_destruction` | One-shot al destruir el nido | `features/props/props.atlas` | ✅ **Listo** — 6 frames (`nest_enemies_01..06`) a 5 fps |
| 3 | **Bote de insecticida**: `pickup_poison_nest` | Pickup en escena — aparece en los spray points | `features/props/props.atlas` | ✅ **Listo** — imagen registrada en el atlas |
| 4 | **Icono + contador HUD**: `box_icon_poison` + `text_icon_poison` | Cargas del jugador (0/2) | `gui/hud.gui` (nodos ya creados) + textura `icon_poison_anim` en `gui.atlas` (4 frames) | ✅ **Listo** |
| 5 | **Sonido de destrucción** | Feedback auditivo al destruir el nido | `assets/sounds/nest_plague_destruction.sound` (+ `.ogg`) | ✅ **Listo** — ruta real: `assets/sounds/` (no `sounds/` raíz) |
| 6 | **Sonido de recogida del insecticida** (opcional) | Puede reutilizar `pick_up.sound` existente | — | 🟡 Opcional |

**Visibilidad del icono (decisión: OCULTO hasta la 1ª carga):** mismo patrón que
`box_icon_cat_food` — `gui.set_enabled(self.box_icon_poison, has_insecticide)` con
`has_insecticide = nest_insecticide >= 1` (aplicado en init + en cada refresh de estado, igual
que `hud.gui_script` L940/1243). Motivo: el insecticida es un recurso raro opcional que empieza
en 0 — mostrar "0/2" desde el inicio es ruido; el icono aparece como recompensa al coger el
primer bote (feedback positivo, patrón ya probado con la comida del gato).

**NO necesitan arte** (los preparo yo en la implementación):
- Marcadores `nest_spawn_01..10` → GOs vacíos (`data: ""`), como `spray_spawn_01` (verificado en
  `level_01.collection` L2271). **Van a z 0.01** (§3.4, verificado en runtime) — el usuario ya los
  recolocó en el editor (posiciones x/y definitivas, z 0.01 confirmado).
- Textos localizados de alerta (sin insecticida / nido destruido) → `general_text_es/en.lua`.
- Hover del nido → **tint rojizo** (decisión 2026-08-17; p. ej. `vmath.vector4(1.5, 0.8, 0.8, 1)`
  animado con `go.animate`), sin arte nuevo (patrón props).

## 9. ⚠️ Riesgos y notas técnicas (GOTCHAs a respetar)

1. **GOTCHA #4**: `factory.create()` no acepta id → no adivinar nombres; los nidos se registran
   por `go.get_id()` real.
2. **GOTCHA #26**: el **enemigo** se auto-registra en `enemy_state` en su `init()`; el nido NO
   registra enemigos (ya lo hacen) — solo usa `get_spawned()` para la purga.
3. **GOTCHA #33**: el guard de nido destruido en `spawn_enemies.script` debe ser **flag de módulo**
   (como `waves_paused`), no mensajes (varias instancias, ids dinámicos).
4. **Properties de factory poco fiables** (motivo de `spray_spawn_state`) → config del nido vía
   `nest_spawn_state.pending_spawn`, no por properties de `factory.create`.
5. **Ruido de consola**: destruir un nido con oleada en vuelo dispararía `factory.create` de
   timers pendientes → el guard de §3.2 lo impide (sin errores ni bichos fantasma).
6. **El nombre "collisionobject"** del trigger del nido es OBLIGATORIO (spawn_enemies.script hace
   `msg.post("#collisionobject", "disable"/"enable")`).
7. **Muerte del jugador**: los guards existentes (`player_dead`/`waves_paused`) ya cubren al nido
   (hereda spawn_enemies.script) — sin trabajo extra.
8. **Colisión con props existentes**: los nidos se colocan en puntos del editor; el diseñador debe
   evitar superposición con mobiliario interactivo (los puntos se eligen a mano).

## 10. 📋 Orden de implementación (al recibir los assets)

| Fase | Contenido | Depende de assets | Estado |
|---|---|---|---|
| **1. Infraestructura** | `nest_spawn_state.lua`, `nest_container.go/.script`, `nest.go` base, guard en `spawn_enemies.script`, instancia en `level_01.collection` | Sprite nido (#1) | ✅ **IMPLEMENTADA (2026-08-17)** |
| **2. Insecticida** | Variante en `spray_spawn_container` + `spray_can.script`, cargo `nest_insecticide`, clic→destrucción, purga, anim+sonido | Bote insecticida (#3), anim destrucción (#2), sonido (#5) | ✅ **IMPLEMENTADA (2026-08-17)** |
| **3. Tarea + rangos** | Bonus híbrido en balance, rangos `_max` en spawn_enemies, `nest_ranges` | — | ✅ **IMPLEMENTADA (2026-08-17)** |
| **4. UI + textos** | Icono/contador HUD (#4), alertas localizadas, documentación (GOTCHAs, PROJECT_SUMMARY) | Icono HUD (#4) | ✅ **IMPLEMENTADA (2026-08-17)** — icono/contador, textos y documentación en PROJECT_SUMMARY (§5.1/§5.2/§6.4) |

### ✅ Fase 1 — Detalle de lo implementado (2026-08-17)

- `main/nest_spawn_state.lua` — puente contenedor↔nido (`pending_spawn`, `container_url`, `mark_destroyed`/`is_destroyed` + `reset`).
- `features/props/nest_container.go` + `.script` — descubre `nest_spawn_01..10` (z 0.01), elige 5 aleatorios, crea nidos vía `#nest_factory`, repone en punto libre tras `nest_destroyed` hasta agotar los 10 (la plaga tiene 10 vidas).
- `features/enemies/nest.go` + `nest.script` — GO del nido: `spawn_enemies.script` (oleadas) + `nest.script` (hover tint rojizo, interact con insecticida → destrucción con anim `nest_destruction` + sonido, purga de enemigos en radio 100, notificación y borrado diferido) + `collisionobject` trigger (spawn/player_spawn, esfera 50) + `collisionobject_interact` (interactivable/cursor) + sprite `nest_idle` + `bug_factory`/`rat_factory` + sonido `nest_plague_destruction`.
- Guard de nido destruido en `main/spawn_enemies.script` (3 puntos: inicio de oleada, callback del timer escalonado y reactivación) — flag de módulo (GOTCHA #33).
- `main/config.lua` → `M.balance.nest` (`nest_bonus=5`, `insecticide_chance=0.18`, `insecticide_max=2`).
- `main/game_state.lua` → global `nest_insecticide = 0` (defaults + reset).
- `assets/texts/general_text_es/en.lua` → `alert_no_insecticide` localizada.
- `level_01.collection` → instancia `nest_container` + 10 marcadores `nest_spawn_01..10` (recolocados por el usuario en el editor a z 0.01, posiciones x/y definitivas).

**Pendiente de la Fase 1 (manual):** ✅ hecho — el usuario recolocó los marcadores y ajustó los
`spray_spawn_01..06` a z 0.1 (ocultación).

### ✅ Fase 2 — Detalle de lo implementado (2026-08-17)

- `main/spray_spawn_state.lua` → `pending_spawn` ahora lleva `is_insecticide` (bool): el contenedor
  lo marca y el spray_can lo lee en su `init()`. `nil/false` → spray normal (comportamiento
  original, incluye los GOs del editor).
- `features/props/spray_spawn_container.script` → tirada de rareza en `spawn_spray_can_at_index`:
  `math.random() < config.balance.nest.insecticide_chance` (fallback 0.18). Aplica por igual al
  spawn inicial y a cada reposición (ambos pasan por la misma función).
- `features/props/spray_can.script` → variante insecticida: si `pending_spawn.is_insecticide`,
  cambia al sprite `pickup_poison_nest` (flipbook en `init()`, antes del primer render → sin
  parpadeo) y al clic otorga **1 carga de `nest_insecticide`** con tope `insecticide_max` (2,
  fallback si la clave se borrara). Mismo contrato de recogida: `#pick_up` + `spray_picked_up` al
  contenedor + `go.delete()`. Con cargas al máximo → alerta localizada `hint_insecticide_max`.
- `assets/texts/general_text_es/en.lua` → clave `hint_insecticide_max` ("Ya llevas el máximo de
  insecticida posible" / "You are already carrying the maximum amount of insecticide").
- La destrucción del nido (clic→destrucción, purga, anim `nest_destruction` + sonido) ya estaba
  en `nest.script` desde la Fase 1; esta fase completa el lado del RECURSO (pickup).

**Verificación:** `luac -p` ✅ (todos los archivos) + `audit_globals.sh -q` → `0 violaciones` ✅.
Pendiente de prueba en runtime (convención del proyecto). Probado por el usuario (2026-08-17).

### ✅ Fase 3 — Detalle de lo implementado (2026-08-17)

- `main/config.lua` → `M.balance.nest_ranges` (total_enemies 3..5, spawn_interval 2.5..5.0 s,
  spawn_radius 15..30, enemy_types {cockroach, rat, mix}, reactivate_delay 8..20 s).
- `main/spawn_enemies.script` → propiedades `_max` opcionales (`total_enemies_max`,
  `spawn_interval_max`, `spawn_radius_max`, `reactivate_delay_max`): si `x_max > x`, CADA oleada
  tira un valor uniforme en `[x, x_max]` (`roll_range`, enteros con `math.random(a,b)` y floats por
  interpolación). `x_max = 0` (default) o ≤ x → comportamiento original idéntico
  (backwards-compatible; los spawners del editor no cambian).
- `main/spawn_enemies.script` → ruta de nido: `go.property("use_nest_ranges", false)`; en `init()`,
  si es true lee `config.balance.nest_ranges`, elige `enemy_type` AL AZAR POR NIDO y guarda los
  rangos en `self.nest_ranges` (tirada por oleada en `spawn_enemies()`). Si la tabla se borra o
  falta una clave → fallback a los valores fijos de `nest.go` (convención del proyecto).
- `features/enemies/nest.go` → componente `spawn_enemies` con `use_nest_ranges: true`
  (PROPERTY_TYPE_BOOLEAN).

**Verificación:** `luac -p` ✅ + `audit_globals.sh -q` → `0 violaciones` ✅. Pendiente de prueba en
runtime (variedad de oleadas entre nidos y por oleada).

### ✅ Fase 4 — Detalle de lo implementado (2026-08-17)

- `gui/hud.gui_script` → `refresh_insecticide_icon(self)`: lee `nest_insecticide` y
  `config.balance.nest.insecticide_max` (fallback 2), escribe el contador "x/2" en `text_icon_poison`
  (cached: solo re-renderiza si cambia) y toglea **icono + texto** juntos con `nest_insecticide >= 1`
  (patrón `box_icon_cat_food`: oculto hasta la 1ª carga). Se llama en `init()` (estado inicial,
  cubre partidas cargadas) y en cada `update_texts()` (polling del HUD). Forward declaration
  `local refresh_insecticide_icon` (GOTCHA #1) + handles cacheados en `init()`.
- `gui/gui.atlas` → 🔧 **FIX GOTCHA #8**: los 4 frames `icon_poison_nest_01..04.png` estaban solo
  dentro del bloque `animation { id: "icon_poison_anim" }` y NO en la sección `images` → el build
  descartaba la animación en silencio y el icono del HUD no se habría renderizado. Ahora están
  registrados en `images` (mismo patrón que `cat_food_icon_anim`, que sí funcionaba).
- Textos localizados: ya estaban (Fase 1 `alert_no_insecticide`, Fase 2 `hint_insecticide_max`).

**Verificación:** `luac -p` ✅ + `audit_globals.sh -q` → `0 violaciones` ✅. **Probado en runtime por
el usuario (2026-08-17):** icono/contador correctos con `DEBUG_ALL_INSECTICIDE = true`.

**Documentación:** `docs/PROJECT_SUMMARY.md` actualizado — variante insecticida en §5.1/§5.2 y nueva
sección §6.4 «Enemy Nest System» (arquitectura, guard, destrucción, HUD, config).

**Pendiente:** poner `M.DEBUG_ALL_INSECTICIDE = false` en `main/config.lua` antes de compilar a
producción (flag de pruebas).

> Cada fase se verifica con `luac -p` + `audit_globals.sh` + prueba en runtime antes de pasar a la
> siguiente (convención del proyecto).
