# ⚠️ DEV GOTCHAS — Defold Museum Game

> Patrones peligrosos descubiertos durante el desarrollo.
> **Lee esto antes de añadir cualquier script que responda a interacciones del ratón.**

---

## 🔴 GOTCHA #1: Funciones globales con mismo nombre en distintos scripts

### El problema

En Defold, **todos los scripts de una misma colección comparten el entorno Lua**. Si dos scripts definen la misma función como **global** (sin `local`), la que se carga **última** sobrescribe silenciosamente a las demás.

```lua
-- ❌ PELIGROSO: función global
--    Si bookcase.script y cat.script definen esto, el último cargado GANA.
function on_interact(self)
    ...
end
```

**Caso real (Julio 2026):** El clic sobre el gato no funcionaba. El debug mostraba `[GATO] on_interact ejecutándose` pero el cuerpo de la función no corría. Causa: `bookcase.script` definía `function on_interact(self)` como global y se cargaba después que `cat.script` en `level_01.collection`. El gato ejecutaba la versión de bookcase, que al recibir `self` sin `book_type` retornaba inmediatamente.

### La solución

```lua
-- ✅ CORRECTO: función local
local function on_interact(self)
    ...
end
```

### ⚠️ Regla adicional para `local`

En Defold, las funciones de ciclo de vida globales (`on_message`, `update`, `init`) **no capturan variables `local` definidas después de ellas** en el archivo. La función `local` debe definirse **ANTES** de la función global que la usa:

```lua
-- ✅ CORRECTO: local function definida ANTES de on_message
local function on_interact(self)
    ...
end

function on_message(self, message_id, message, sender)
    ...
    on_interact(self)  -- funciona: on_interact ya está definida
    ...
end
```

```lua
-- ❌ ERROR: "attempt to call global 'on_interact' (a nil value)"
function on_message(self, message_id, message, sender)
    ...
    on_interact(self)  -- error: on_interact aún no está definida
    ...
end

local function on_interact(self)  -- definida DEMASIADO TARDE
    ...
end
```

### Checklist para nuevos scripts interactivos

Antes de hacer commit de un script que reciba `interact`, `mouse_hover`, o cualquier mensaje del cursor:

- [ ] `on_interact` está definido como `local function`
- [ ] La definición de `local function on_interact` está **ANTES** de `function on_message`
- [ ] He comprobado que ningún otro script en la misma colección define una función con el mismo nombre como global
- [ ] He hecho `grep -rn "function on_interact" features/` para verificar

### Archivos afectados (ya corregidos)

| Archivo | Estado |
|---------|--------|
| `features/cat/cat.script` | ✅ `local function on_interact` **antes** de `on_message` (línea 525 < 571) |
| `features/furniture/bookcase.script` | ✅ **4 `local function` antes de `on_message`**: `on_interact` (112), `apply_hover_tint` (144), `reset_hover_tint` (148), `show_book_title_alert` (152); `on_message` en 173. En Ago 2026 `on_interact` estaba después (165 > 108) y las 3 de hover eran globales — todo corregido |
| `features/props/doors.script` | ✅ Ya era `local` (141 < 219) |
| `main/npc.script` | ✅ Ya era `local` (125 < 198) |

> ⚠️ **Caso real (Agosto 2026):** bookcase.script *era* `local` en `on_interact`, pero la definición estaba **después** de `function on_message`. Resultado: `ERROR:SCRIPT: bookcase.script:125: attempt to call global 'on_interact' (a nil value)` al clicar una estantería. **Ser `local` no basta** — el orden también importa. Se movió la definición antes de `on_message`, y en el mismo pase se convirtieron las 3 helpers de hover (`apply_hover_tint`, `reset_hover_tint`, `show_book_title_alert`) de globales a `local` y se colocaron también antes de `on_message`.

> 💡 **Verificación rápida:** TODAS las `local function` que usa `on_message` deben estar ANTES de `function on_message` en el mismo archivo. `grep -n "local function\|function on_message" features/furniture/bookcase.script` y comparar números de línea.

### Cómo detectar este bug

Si un script recibe el mensaje `interact` y su `on_interact` se ejecuta (ves el print), pero el cuerpo de la función parece no hacer nada, sospecha de colisión de nombres globales. Haz:

```bash
grep -rn "function on_interact" --include="*.script" --include="*.lua"
```

Si ves más de una definición sin `local`, hay colisión.

### 🔎 Auditoría automatizada: `audit_globals.sh` (raíz del proyecto)

Script reutilizable que recorre **todos** los `.script`/`.gui_script`/`.lua` del proyecto y detecta cualquier función global no-ciclo-de-vida. Implementa la regla #1 del checklist de `docs/DEFOLD_LUA_STANDARDS.md`.

```bash
bash audit_globals.sh     # lista violaciones (si las hay) + total
bash audit_globals.sh -q  # solo el total (para CI/scripts)
bash audit_globals.sh -v  # verbose: también lista los archivos limpios
```

**Exit code:** `0` si NO hay violaciones, `1` si hay alguna → se puede usar en CI.

**Qué clasifica como correcto (no-violación):**

| Clasificación | Ejemplo |
|---|---|
| Ciclo de vida | `function init/update/fixed_update/on_message/on_input/on_reload/final` |
| Export de módulo | `local M = {}` + `function M.foo()` |
| Forward declaration | `local X` arriba + `function X(self)` abajo (asigna al local) |
| Asignación local | `local X` arriba + `X = function(...)` abajo (patrón `library.gui_script`) |

**Qué detecta como violación:** cualquier `function X` o `X = function(...)` de nivel superior sin `local X` previo y sin ser ciclo de vida ni `M.X`.

> ✅ **Estado actual (Agosto 2026):** las Fases 1-4 del checklist #1 convirtieron **todas las funciones globales detectadas** en locales (13 archivos: persistence, interactive, hud, player_spray, dialogue_manager, inventory_manager, furniture, slot_furniture, cat, car_start_point, food_spawn_container, spray_spawn_container, intro_animation). La auditoría completa devuelve **0 violaciones**.
> 
> **Regla práctica:** tras añadir o modificar un script, ejecuta `bash audit_globals.sh -q` — debe devolver `TOTAL VIOLACIONES GLOBALES: 0` y exit code 0.

---

## 🔴 GOTCHA #2: API de `physics.raycast` depende de la versión de Defold

La versión de Defold de este proyecto usa: `physics.raycast(from_v3, to_v3, groups_array, options)` donde `groups_array` es un array simple de hashes: `{ hash("walls") }` (GOTCHA #43: solo grupos que EXISTAN en el proyecto) y `options` es el 4º argumento — **obligatorio en la práctica**: `{ all = true }` (GOTCHA #44: sin él, el raycast síncrono NO devuelve una lista y `ipairs` no itera nada).

**NO** usa el formato `{ types = { hash(...) } }` ni la API posicional antigua `(x1,y1,z1,x2,y2,z2,groups)`.

```lua
-- ✅ CORRECTO para este proyecto
local result = physics.raycast(my_pos, probe_end, { hash("walls") }, { all = true }) or {}
for _, hit in ipairs(result) do
    if hit.group == hash("walls") then ...
```

Devuelve `nil` cuando no hay colisiones → usar `or {}`.

> ⚠️ **Ago 2026 (GOTCHA #44):** el 4º argumento `{ all = true }` NO es opcional si quieres
> iterar el resultado con `ipairs`. SIN él, el raycast síncrono devuelve los CAMPOS del hit
> (fraction/position/normal/group/id) a nivel superior de la tabla — NO una lista → `ipairs`
> no itera nada → cualquier comprobación de pared devuelve "despejado" SIEMPRE (degradación
> silenciosa: el gato "veía" a través de los muros). Con `{ all = true }` devuelve una lista
> ordenada por distancia (todas las intersecciones; sin él, solo el hit más cercano).
> `groups_array` debe listar grupos que EXISTAN en el proyecto (ver GOTCHA #43): un grupo
> inexistente como `collision_object` no da error, pero el raycast no golpea nada.

---

## 🔴 GOTCHA #3: `go.exists()` ignora el fragmento de la URL (solo comprueba el game object)

### El problema

En Defold, `go.exists(url)` **NO comprueba la existencia de un componente**: ignora el fragmento (`#nombre`) de la URL y solo devuelve `true` si el *game object* existe. Es fiable para game objects completos (ej: `go.exists(msg.url("/player"))`), pero **no para componentes**.

```lua
-- ❌ PELIGROSO: devuelve true aunque el componente no exista
--    (door_side solo tiene "sprite", no "sprite_front")
if go.exists(msg.url(nil, go.get_id(), hash("sprite_front"))) then
    ...  -- se ejecuta igualmente → errores al animar/hacer go.get
end
```

**Caso real (Agosto 2026):** Al dividir las puertas en dos sprites (`sprite_front` z=0.2 / `sprite_back` z=0.0), `door_side` compartía el mismo `doors.script` que `door_front`/`door_service` pero conservaba un único componente `sprite`. La detección con `go.exists("sprite_front")` devolvía `true` para `door_side`, y al hacer hover se lanzaba:

```
ERROR:SCRIPT: features/props/doors.script:59: could not find component 'sprite_front' when resolving '(null)'
ERROR:GAMEOBJECT: Component '/door_side#sprite_front' could not be found when dispatching message 'play_animation'
```

### La solución: módulo compartido `main/component_utils.lua`

`go.get(url, propiedad)` lanza error si el componente no existe; `pcall` lo captura y devuelve `false`. Úsalo en `init()` o en handlers (el coste de `pcall` es despreciable), no en bucles por frame.

**El proyecto tiene un módulo compartido para esto: `main/component_utils.lua`.** No dupliques el helper localmente — usa siempre el módulo:

```lua
local component_utils = require "main.component_utils"

if component_utils.component_exists(msg.url(nil, go.get_id(), hash("sprite_front")), "tint") then
    ...
end
```

**Firma:** `component_exists(url, prop)` → `true` si el componente existe, `false` si no.

> ⚠️ **Historial:** inicialmente se definió un helper local (`sprite_component_exists`) en `doors.script` y otro (`component_exists`) en `exhibition_object.script`. En Ago 2026 se extrajeron a `main/component_utils.lua` para eliminar la duplicación. **Regla: si necesitas comprobar existencia de un componente, usa el módulo, no un helper local nuevo.**

**Consumidores actuales del módulo:**
- `features/props/doors.script` → `component_exists(front_url/back_url, "tint")` para detectar puertas divididas vs simples.
- `features/exhibition_objects/exhibition_object.script` → `component_exists(self.sprite_url, "tint")` (fallback sprite→cofre, hover, interact y set_active) y `component_exists(self.clic_url, "gain")` (sonido de clic). Este script **cachea las URLs en `init()`** (`self.sprite_url`, `self.clic_url`) siguiendo la regla #4 — no construyas `msg.url` inline en handlers.

### Cuándo aplicar

- Detectar qué componentes existen en un `.go` compartido por varios prototipos (como `doors.script` con `door_front`/`door_service`/`door_side`).
- La propiedad a consultar debe ser válida para el tipo de componente (ej: `"tint"` para sprites, `"gain"` para sonidos).

---

## 🔴 GOTCHA #4: `factory.create()` no acepta un id → NO adivines los nombres de las instancias

### El problema

La firma de `factory.create()` es `factory.create(url, position, rotation, properties, scale)` — **no existe un parámetro de id**. Cuando no se especifica uno, el engine **auto-genera el nombre** de cada instancia. Adivinar ese nombre (p. ej. `"enemy_cockroach1"`) es frágil: depende del esquema interno del motor y rompe en cuanto cambia.

```lua
-- ❌ PELIGROSO: adivinar el nombre auto-generado de las instancias
for i = 0, 10 do
    local url = msg.url("/enemy_cockroach" .. ((i == 0) and "" or i))
    if go.exists(url) then  -- solo acierta la estática del editor, no las del factory
        ...
    end
end
```

**Caso real (Agosto 2026):** el gato (`cat.script`) no atacaba a las cucarachas creadas por `factory.create()` en grupo; solo atacaba a la **única cucaracha estática** del `level_01.collection` (la única con id `/enemy_cockroach`, i=0). El bucle `/enemy_cockroach1`…`/enemy_cockroach10` nunca coincidía con los ids reales auto-generados por el motor.

### La solución: registrar el id que devuelve `factory.create()`

`factory.create()` **devuelve el id real** de la instancia creada como primer retorno. Guárdalo en un módulo compartido en el momento del spawn (patrón ya usado con `food_spawn_state.lua` / `spray_spawn_state.lua`).

**El proyecto tiene un módulo para esto: `main/enemy_state.lua`.** No dupliques listas locales — usa siempre el módulo:

```lua
-- 🪳 El PROPIO enemigo se registra en su init() (patrón ACTUAL desde Ago
--    2026, ver GOTCHA #26): cubre por igual los estáticos del editor y los
--    creados por factory (ambos pasan por init()). go.get_id() devuelve el
--    id real, mismo contrato que el devuelto por factory.create.
--    features/enemy_cockroach.script / features/enemy_rat.script:
local enemy_state = require "main.enemy_state"
...
enemy_state.register(go.get_id())
```

```lua
-- 🐱 cat.script: consumir la lista registrada (filtrar con go.exists)
for _, enemy_id in ipairs(enemy_state.get_spawned()) do
    if go.exists(enemy_id) then
        table.insert(found, enemy_id)
    end
end
```

**API de `enemy_state`:** `register(id)` (añade el id del enemigo, lo llama el propio enemigo en su `init()`), `get_spawned()` (lista de ids; filtrar con `go.exists` antes de usar), `reset()` (limpiar al re-cargar nivel).

> ⚠️ **Nota:** las instancias del factory devuelven hashes (`id`) y los objetos colocados en el editor se direccionan con `msg.url("...")`; `go.exists` / `go.get_position` / `msg.post` aceptan ambos, pero el dedup por `tostring()` NO los empareja entre sí (hash ≠ url del mismo objeto) → puede haber iteraciones duplicadas inofensivas.

### 🟢 La distinción clave: naming del editor ≠ naming de factory

**El GOTCHA #4 aplica SOLO a instancias creadas por `factory.create()`**, cuyos nombres son **auto-generados** por el motor y no se pueden adivinar. La convención de nombres para objetos **colocados en el editor** (NPCs, puntos de spawn, contenedores) es **legítima y fiable**: sus nombres están fijos en el `.collection` y nunca los genera el motor.

| Script | Patrón encontrado | ¿Factory? | Veredicto |
|---|---|---|---|
| `features/cat/cat.script` | `scan_enemies()` adivinaba `enemy_cockroach1..10` | ✅ Sí (`bug_factory`) | ✅ **Ya migrado** a `enemy_state.get_spawned()` |
| `main/spawn_enemies.script` | `pcall(factory.create, "#bug_factory", ...)` | ✅ Sí | ✅ **Ya no registra** (desde Ago 2026 el propio enemigo se registra en su `init()` — GOTCHA #26; evitó ids duplicados) |
| `features/props/car_start_point.script` | `pcall(factory.create, CAR_FACTORY, ...)` → `car_id` | ✅ Sí | ✅ **Modelo a seguir**: usa el id real devuelto (guardado en `self.car_ids`, limpieza con `go.delete(car_id)`) — nunca adivina nombres |
| `features/player/player_spray.script` | `factory.create("/player_spray#factory", ...)` | ✅ Sí | ✅ Fire-and-forget (partículas): no necesita direccionarlas después |
| `features/props/food_spawn_container.script` | `"food_spawn_" .. string.format("%02d", i)` + `go.exists(name)` | ❌ No | ✅ **Legítimo**: descubre **hijos colocados en el editor** (`level_01.collection` líneas 1082–1084). Las latas creadas por factory se comunican vía `food_spawn_state` (módulo compartido), nunca por nombre |
| `features/props/spray_spawn_container.script` | `"spray_spawn_" .. string.format("%02d", i)` + `go.exists(name)` | ❌ No | ✅ **Legítimo**: descubre hijos del editor (`level_01.collection` líneas 119–124). Los spray cans usan `spray_spawn_state` |
| `main/main.script` | `"/npc_" .. string.format("%02d", i)` (`npc_01`, `npc_02`…) | ❌ No | ✅ **Legítimo**: NPCs colocados en el editor con nombres fijos (`level_01.collection` línea 1110 `children: "npcs"`) |
| `main/dialogue_manager.script` | `"/" .. id` (`self.current_npc`, `affected_npc`, `npc_id`; L89/106/126/366/412) | ❌ No | ✅ **Legítimo**: direcciona NPCs del editor por su id guardado (desde el módulo de progreso), nunca instancias de factory |
| `features/npc/npc_spawn_manager.script` | `"spawn_npc_" .. string.format("%02d", i)` + `go.exists(name)` + `"spawn_npc_cat"` | ❌ No | ✅ **Legítimo**: descubre **hijos del editor** del contenedor `spawn_npcs` (`level_01.collection`). Los NPCs se registran por su URL real vía `npc_spawn_state` (GOTCHA #4), nunca por nombre adivinado |

> 📋 **Regla práctica (auditoría Ago 2026):** antes de marcar un `msg.url("...")` dinámico como anti-patrón, comprueba si el objetivo es una instancia de factory (→ GOTCHA #4, usa módulo compartido) o un objeto del editor (→ naming fiable, OK). La auditoría completa confirmó que **ningún otro script necesita migrar**: los únicos naming dinámicos del proyecto (`npc_%02d`, `food_spawn_%02d`, `spray_spawn_%02d`) apuntan a objetos estáticos del editor.

### Cuándo aplicar

- Siempre que necesites direccionar (detectar, dañar, borrar) instancias creadas con `factory.create()`.
- Nunca dependas del nombre auto-generado: usa el id devuelto o `msg.url(nil, id)`.

---

## 🔴 GOTCHA #5: entre dos TRIGGERS llega `trigger_response` (con `other_group`), NO `contact_point_response`

### El problema

Cuando **ambos** collision objects implicados son de tipo `COLLISION_OBJECT_TYPE_TRIGGER`, el engine envía **`trigger_response`** (con los campos `enter`, `other_id`, `other_group`, `other_position`). **`contact_point_response` solo ocurre en colisiones con al menos un objeto NO-trigger** (kinematic/dynamic/static).

```lua
-- ❌ PELIGROSO: escuchar contact_point_response para detectar otro TRIGGER
elseif message_id == hash("contact_point_response") then
    if message.group == hash("enemy") then  -- NUNCA se ejecuta para trigger-trigger
        ...
    end
end
```

**Caso real (Agosto 2026):** el `collisionobject_enemy` del gato (TRIGGER, group `spray`, mask `enemy`) y el `collisionobject_bullet` de la cucaracha (TRIGGER, group `enemy`, mask `spray`) se solapan físicamente, pero el handler del gato escuchaba `contact_point_response` → **nunca detectaba cucarachas por proximidad**. Además, el campo correcto es `other_group` (el grupo del OTRO objeto), no `group`.

**Caso real 2 (Ago 2026) — trigger de zona con máscara que nunca detecta al jugador:** los triggers de zona (`zone_storage.go` / `zone_intake.go`, group `zone_ambient`) tenían `mask: "player"`, pero el collider del jugador que solapa las zonas es `collisionobject_sound` (group `player_sound`, mask `zone_ambient`) en `player.go`; el collider de group `player` (`collisionobject_walls`) tiene mask `walls`, sin `zone_ambient`. La detección de trigger exige AMBAS direcciones (el grupo del otro objeto en la máscara del trigger Y el grupo del trigger en la máscara del otro) → **el trigger nunca disparaba**; el audio de `zone_storage` solo funcionaba por el fallback de distancia de `ambient_trigger.script`. Fix: `mask: "player_sound"` en las zonas + `other_group` acepta `player`/`player_sound` en `ambient_trigger.script` / `zone_alert.script` (🗑️ Ago 2026: `ambient_trigger.script` se eliminó — `storage_1` pasó a la playlist y las zonas solo emiten aviso de sala con `zone_alert.script`; la regla aplica a este último). **Regla:** al crear un trigger que debe detectar al jugador, mirar QUÉ collider del jugador lo cruzará (su grupo real) y usar ese grupo en la máscara del trigger; y comprobar el otro sentido (la máscara del collider del jugador debe incluir el grupo del trigger — `collisionobject_sound` ya incluye `zone_ambient`).

### La solución: escuchar `trigger_response` y usar `other_group`

```lua
-- ✅ CORRECTO: detectar otro TRIGGER
elseif message_id == hash("trigger_response") then
    if message.enter and message.other_group == hash("enemy") then
        local other_id = message.other_id
        if other_id and go.exists(other_id) then
            self.nearby_enemies[tostring(other_id)] = other_id
        end
    end
end
```

**Campos del mensaje `trigger_response`:** `enter` (bool), `other_id` (hash del otro GO), `other_group` (grupo del otro objeto), `other_position`.

> ✅ **Referencia en el propio proyecto:** `car.script`, `car_start_point.script` y `bullet.script` ya usaban `message.other_group` / `message.other_id` en `trigger_response` correctamente — el gato era la excepción que escuchaba `contact_point_response`.

### Cuándo aplicar

- Cualquier par de collision objects **trigger ↔ trigger** (detección de proximidad mutua, triggers de área, sensores).
- Regla rápida: ¿el otro objeto es TRIGGER? → usa `trigger_response` + `other_group`. ¿Es un objeto físico normal? → `contact_point_response` + `group`.

### ⚠️ Corrección (Ago 2026): trigger ↔ KINEMATIC SÍ entrega `collision_response`/`contact_point_response` al TRIGGER

**Verificado por diagnóstico en runtime:** el cursor de `cursor.script` es `COLLISION_OBJECT_TYPE_TRIGGER` (group `cursor`, mask `interactivable`) y sus interactables son KINEMATIC — y **el cursor SÍ recibe `collision_response`/`contact_point_response`** de ellos (no solo `trigger_response`). El fallback "defensivo" que escuchaba esos mensajes en el cursor **no era código muerto**: con un clic en vacío (`self.clicked = true` sin interact), el mensaje de colisión disparaba `interact` a **cualquier** distancia (caso real: `ME_5225` interactuado a 285 uds con `interaction_range=80` — el rango global se aplicaba al hover pero no al clic). **Regla derivada:** cualquier vía de interacción alternativa (fallbacks, safety nets) debe llevar el MISMO gate de distancia (`is_player_in_range`), y no asumir que un mensaje "no va a llegar" por el tipo del collision object — si el handler existe, el engine puede entregarlo.

## 🔴 GOTCHA #6: `gui.set_position()` espera coordenadas LOCALES; `gui.set_screen_position()` para screen space (globos/paneles anclados al mundo)

### El problema

`gui.set_position(node, pos)` interpreta `pos` en el **espacio local de la escena GUI** (resolución de referencia + adjust mode FIT/ZOOM/STRETCH). No es lo mismo que los **píxeles de ventana** (`window.get_size()`). Si le pasas coordenadas de ventana, el globo solo queda bien cuando la ventana coincide con la resolución de referencia (1280×768 en este proyecto) — al redimensionar (fullscreen HTML5) la GUI aplica su propio ajuste y el globo se descolga del objeto.

**Caso real (Agosto 2026):** los globos de diálogo (`balloon_npc_container`/`balloon_player_container` en `interactive.gui`) y el panel de exhibición (`box_exhibition_container` en `exhibition.gui`) recibían `screen_pos` calculado por `screen_utils.world_to_screen()` (píxeles de ventana) y lo aplicaban con `gui.set_position()` → fallaba en fullscreen. Además, `world_to_screen` multiplicaba por `scale_factor = window/BASE`, lo que era un segundo error: con el render por defecto y cámara ortográfica (`orthographic_zoom: 2.0`), **1 unidad de mundo = zoom px siempre** (al agrandar la ventana se ve más mundo, no se estira), así que el `scale_factor` descolgaba aún más.

### La solución: `gui.set_screen_position()` + screen space real en `world_to_screen`

```lua
-- ✅ CORRECTO: aplicar la posición de pantalla en el límite GUI
-- (el motor convierte a local teniendo en cuenta adjust mode y tamaño de ventana ACTUALES)
gui.set_screen_position(container, message.screen_pos)
```

```lua
-- ✅ world_to_screen emite screen space real (origen abajo-izquierda, Y hacia arriba),
--   SIN scale_factor: 1 unidad de mundo = ORTHO_ZOOM px siempre
function M.world_to_screen(world_pos)
	local window_width, window_height = window.get_size()
	local cam_pos = ...
	local screen_pos = vmath.vector3()
	screen_pos.x = (window_width / 2) + ((world_pos.x - cam_pos.x) * ORTHO_ZOOM)
	screen_pos.y = (window_height / 2) + ((world_pos.y - cam_pos.y) * ORTHO_ZOOM) + BUBBLE_OFFSET_Y
	screen_pos.z = 0
	return screen_pos
end
```

> ✅ **Referencia en el propio proyecto:** `interactive.gui_script` (globos player/npc), `exhibition.gui_script` (panel + `update_position`) y `screen_utils.lua` (módulo compartido, comentado con este GOTCHA). `exhibition_manager` reenvía `update_position` cada 2 frames → el panel se auto-corrige tras un resize.

### Cuándo aplicar

- Cualquier nodo GUI que deba anclarse a un game object del mundo (globos de diálogo, paneles de objeto, marcadores).
- Regla rápida: si el valor procede de `world_to_screen`/`window.get_size()` → **`gui.set_screen_position()`** (o `gui.screen_to_local()` + `gui.set_position()`). Si es una posición de layout fija del editor → `gui.set_position()`.

> ⚠️ **Nota adicional (Agosto 2026):** **NO existe `gui.set_screen_size`** en la API del
> motor 1.13 (`attempt to call field 'set_screen_size' (a nil value)`). El tamaño de un
> nodo se ajusta SIEMPRE en **unidades de escena** con `gui.set_size` (referencia 1280×768
> bajo FIT); solo la POSICIÓN tiene variante screen space (`gui.set_screen_position`).
> Para cubrir la ventana entera con un nodo bajo FIT: `tamaño = ventana / fit` donde
> `fit = min(w/1280, h/768)`, y posición centrada con `gui.set_screen_position(w/2, h/2)`.
> → **Alternativa declarativa recomendada (sin script):** GOTCHA #9 — `size` 2× referencia
> + `scale 0.5` + `adjust_mode: ADJUST_MODE_ZOOM` en el propio `.gui` (patrón de `hud.gui`).

## 🔴 GOTCHA #7: `window.set_listener(nil)` no es fiable para liberar el listener según la versión de Defold

### El problema

`window.set_listener(callback)` es un **listener GLOBAL ÚNICO** (cada llamada reemplaza al anterior). La API acepta `window.set_listener(nil)` para liberarlo, pero **el comportamiento varía según la versión de Defold**:

- En algunas versiones, pasar `nil` limpia el listener correctamente.
- En otras es un **no-op silencioso** (el callback anterior sigue registrado) o puede lanzar un error.

Si el listener no se libera de verdad y el script dueño (`dialogue_manager`) se finaliza (p. ej. al descargarse `level_01`), un evento posterior (`WINDOW_EVENT_RESIZED`/`FOCUS_GAINED`) invocará el callback de un script ya destruido → error al acceder a `self.active` (o peor).

**Caso real (Agosto 2026):** `dialogue_manager.script` es el dueño del listener único global — registrado en `init()` con `window.set_listener(on_window_event)` y liberado en `final()` con `pcall(function() window.set_listener(nil) end)`. El `pcall` silencia el error de las versiones que no aceptan `nil`, pero **no garantiza la liberación** si el no-op es silencioso.

### La solución: `pcall` + aceptar el riesgo residual

```lua
-- ✅ CORRECTO (mitigación aplicada en el proyecto, main/dialogue_manager.script)
function final(self)
    pcall(function() window.set_listener(nil) end)  -- no lanza error en ninguna versión
end
```

- El `pcall` convierte el posible error en silencio → compatibilidad entre versiones.
- **Riesgo residual aceptado:** si la versión hace no-op silencioso, un resize tras descargar `level_01` invocaría el callback de un script finalizado. Mitigación manual: verificar en runtime si el nivel se descarga con diálogo activo; si ocurre, centralizar la liberación (p. ej. notificar al dueño antes de descargar el nivel).
- **Regla de oro:** nunca registres un segundo `window.set_listener` en otro script (reemplazaría al del `dialogue_manager`). Cualquier necesidad de escuchar eventos de ventana debe centralizarse en el mismo dueño (ver PROJECT_SUMMARY §8).

> ✅ **Referencia en el propio proyecto:** `main/dialogue_manager.script` — `window.set_listener(on_window_event)` en `init()` (línea ~237), `pcall(function() window.set_listener(nil) end)` en `final()` (línea ~255). El handler re-ancla los globos de diálogo (`reposition_dialog` → `interactive.gui_script` con `gui.set_screen_position`, GOTCHA #6).

### Cuándo aplicar

- Cualquier script que registre `window.set_listener` (solo debe existir uno en todo el proyecto: `dialogue_manager`).
- Al liberar el listener en `final()`, envuélvelo siempre en `pcall` y ten presente que el no-op silencioso puede dejar el callback vivo según la versión.
- Antes de actualizar la versión de Defold del proyecto, comprobar el comportamiento de `window.set_listener(nil)` en esa versión concreta.

## 🔴 GOTCHA #8: las imágenes de una animación deben estar registradas en la sección `images` del atlas o el build descarta la animación

### El problema

En un `.atlas` de Defold, una **animación** (`animations { id: "..." animation { image: ... } }`) solo se compila al runtime si **todas** sus imágenes están también registradas en la sección **`images { image: ... }`** del mismo atlas. Si una imagen existe en el bloque de la animación pero no en la lista de imágenes registradas, el build **descarta la animación entera** de forma silenciosa (sin error de build).

El fallo solo aparece en runtime, con dos síntomas encadenados:

```
WARNING:GUI: The animation 'X' could not be found.
ERROR:SCRIPT: gui/....gui_script:NNN: Animation 'X' invalid for node 'node' (no animation set)
```

**Caso real (Agosto 2026):** en `gui/gui.atlas`, la animación `book_appaerance` (typo intencional del id) referenciaba los frames `book_appearance_01..06.png` dentro de su bloque, pero esas 6 imágenes **no estaban en la sección `images`** del atlas → el build la descartó y `gui.play_flipbook(self.box_book, hash("book_appaerance"))` falló en runtime al abrir un libro. El fix fue añadir los 6 bloques `images { image: ... }` junto al resto de imágenes del libro (ahora en las líneas ~113-128).

### La solución: registrar siempre las imágenes antes de usarlas en una animación

- Al añadir una animación al atlas en el editor, **Defold registra las imágenes automáticamente** — el problema aparece cuando se edita el `.atlas` a mano (o se copian/pegan bloques) y las imágenes quedan solo dentro de la animación.
- Regla de verificación: toda ruta que aparezca en un bloque `animation { image: ... }` debe aparecer también en la sección `images` del mismo archivo.
- Si el atlas se mantiene a mano, es útil un chequeo automático: separar la sección `images` (antes de `animations {`), extraer sus rutas con regex y comparar contra las de los bloques `animation`.

> ✅ **Referencia en el propio proyecto:** `gui/gui.atlas` — animación `book_appaerance` (id con typo intencional) con sus 6 frames `book_appearance_01..06.png` ahora registrados en `images` (líneas ~113-128). Usada desde `gui/library.gui_script` con `gui.play_flipbook(self.box_book, ANIM_BOOK_APPEARANCE)` al abrir un libro.

> ✅ **Mismo bug detectado y CORREGIDO (Ago 2026, auditoría):** la animación `icon_quiz_main_anim` (usada por el quiz en `interactive.gui` → `box_icon_quiz`) tenía el mismo bug latente: referenciaba `icon_quiz_main_01/02/03.png` en su bloque de animación con solo `icon_quiz_main.png` registrada en `images` — el build descartaba la animación en silencio. Fix: los 3 frames se registraron en la sección `images` del atlas (mismo archivo, junto al resto de imágenes). Regla de verificación aplicada en la auditoría: toda ruta en un bloque `animation {}` debe aparecer también en `images`.

### Cuándo aplicar

- Al editar cualquier `.atlas` a mano (añadir frames, copiar bloques de animación, o reordenar imágenes).
- Ante el error runtime `Animation 'X' invalid for node` / `WARNING:GUI: The animation ... could not be found`: lo primero es comprobar que todas las imágenes de la animación están en la sección `images` del atlas.
- En revisiones de atlas con muchas animaciones, ejecutar el chequeo automático de rutas (imágenes de animación vs. sección `images`) para detectar el bug latente antes de que llegue a runtime.

---

## 🔴 GOTCHA #9: fondo a pantalla completa en GUI — patrón declarativo (2× tamaño + `scale` 0.5 + `ADJUST_MODE_ZOOM` por nodo)

### El problema

Un nodo box usado como **fondo de pantalla** (p. ej. `pause_background` en `pause.gui`: box negro 1280×780) sin `adjust_mode` explícito queda en **`FIT`** (el default de los nodos). Bajo FIT, cuando la ventana cambia de aspect ratio respecto a la referencia (1280×768 en este proyecto), el contenido del nodo se escala al lado **más corto** del bounding box estirado → quedan **bandas letterbox** por donde se ve la escena.

### La solución: patrón declarativo (sin script)

Replicar el patrón del nodo `background` de `hud.gui` (probado en producción):

```text
nodes {
  position { x: 640.0, y: 384.0 }   -- centro de la referencia 1280×768
  scale    { x: 0.5, y: 0.5 }        -- compensa el tamaño 2× (render aparente = referencia)
  size     { x: 2560.0, y: 1536.0 }  -- 2× la referencia → margen para aspect ratios extremos
  type: TYPE_BOX
  id: "background"
  adjust_mode: ADJUST_MODE_ZOOM      -- ★ la clave: ajuste por NODO
}
```

Reglas:

- `size = 2 × referencia` (2560×1536 para 1280×768) + `scale = 0.5` → renderizado aparente = la referencia, pero con el doble de tamaño bruto para cubrir portrait/ultrawide sin descolgarse.
- `adjust_mode: ADJUST_MODE_ZOOM` **a nivel de nodo** → el contenido se escala al lado **más largo** del bounding box estirado → cubre SIEMPRE (recorta el exceso; invisible en un fill plano).
- Requiere `adjust_reference: ADJUST_REFERENCE_PARENT` ("Per Node") en la escena GUI — es el default y el que **habilita** el ajuste por nodo. Con `Disabled` los nodos mantienen tamaño fijo.
- Es **100% declarativo**: no hace falta script ni API de runtime.

### Semántica de los adjust modes por nodo (manual oficial de Defold)

| Modo | Escala el contenido al… | Resultado |
|---|---|---|
| `FIT` (default) | lado **más corto** del bounding box estirado | cabe → **bandas letterbox** |
| `ZOOM` | lado **más largo** del bounding box estirado | cubre → **sin bandas** (recorta exceso) |
| `STRETCH` | llena el bounding box | sin bandas pero **distorsiona** (no mantiene aspect) |

### Aplicación en el proyecto (Agosto 2026)

- `gui/hud.gui` — nodo `background`: 2× tamaño + `scale 0.5` + `ADJUST_MODE_ZOOM` (patrón original probado).
- `gui/pause.gui` — nodo `pause_background`: se aplicó el mismo patrón (2560×1560 + `scale 0.5` + ZOOM) tras fallar el enfoque por script.
- `gui/library.gui` — nodo `box_background` (oscurecido de la biblioteca): aplicado el mismo patrón (2560×1560 + `scale 0.5` + ZOOM) en Ago 2026 — era un FIT 1280×780 sin ZOOM y dejaba bandas sin oscurecer al redimensionar (mismo caso que `pause_background`; al ser nodo raíz gestionado por id en `library.gui_script`, no requirió cambios de script).
- `gui/interactive.gui` — usa `ADJUST_MODE_STRETCH` en 3 nodos para estirar paneles al ancho de pantalla (mismo mecanismo, otra semántica).

### ⚠️ Requisito crítico (Ago 2026): el fondo a pantalla completa debe ser nodo RAÍZ

El ajuste por nodo se calcula contra el **tamaño ajustado del PADRE** — o la **escena** para nodos raíz (tooltip del editor de Defold: *"Per Node uses the parent's adjusted size, or the scene for root nodes"*). Un ZOOM en un nodo HIJO de un contenedor FIT (p. ej. `pause_background` hijo de `pause_root`) NO cubre la pantalla: el padre FIT reduce su caja a la del lado más corto (letterbox) y el ZOOM del hijo solo escala dentro de esa caja → **bandas laterales sin oscurecer en móvil/ultrawide**, justo donde el jugador ve la escena a través del menú.

**Caso real corregido (`gui/pause.gui`, Ago 2026):** `pause_background` tenía 2× tamaño + `scale 0.5` + ZOOM (el patrón completo) pero **colgaba de `pause_root`** → en móvil (926×428 CSS) quedaban bandas de ~106 px a cada lado. Fix: se quitó `parent: "pause_root"` (nodo raíz, como el `background` de `hud.gui`) y su enable/disable se gestiona **explícitamente** en `pause.gui_script` (init/show_pause/hide_pause), porque ya no lo cubre el árbol de GOTCHA #32.

- Regla rápida: fondo a pantalla completa → nodo RAÍZ + `size` 2× referencia + `scale 0.5` + `adjust_mode: ADJUST_MODE_ZOOM`. Si el fondo es HIJO de un contenedor FIT, el ZOOM no cubre — o se hace raíz o se elimina el ajuste del padre.

> ⚠️ **Historia (Agosto 2026):** el primer intento de cubrir la pantalla fue por **script** en `pause.gui_script` (`cover_background`: `gui.set_size` con `ventana/fit` + `gui.set_screen_position`) — rompió el menú de pausa y se revirtió. La solución final es **declarativa en el `.gui`** (este GOTCHA). Lección: antes de cubrir un fondo por script, probar el patrón declarativo.

### Cuándo aplicar

- Cualquier nodo box que deba cubrir TODA la pantalla como fondo (menús, overlays, HUD).
- Regla rápida: fondo a pantalla completa → `size` 2× referencia + `scale 0.5` + `adjust_mode: ADJUST_MODE_ZOOM` (y `adjust_reference: ADJUST_REFERENCE_PARENT` en la escena).

---

## 🔴 GOTCHA #10: `gui.pick_node()` es puramente geométrico — pickea nodos deshabilitados e invisibles

### El problema

`gui.pick_node(node, x, y)` **no respeta el estado `enabled` ni `visible` del nodo**: es una comprobación puramente geométrica (el punto `(x,y)` cae dentro de los bounds del nodo). Un nodo ocultado con `gui.set_enabled(node, false)` o `gui.set_visible(node, false)` **se sigue pickeando** → un botón invisible puede disparar su acción si el handler no comprueba su estado.

> Confirmado **by design** por el equipo de Defold (foro oficial): *"gui.pick_node() determines if the node is pickable by the supplied coordinates and nothing else. If you need to check if node is enabled you should use it together with gui.is_enabled()."* (AGulev, Ragnar Svensson, britzl).

**Caso real (Agosto 2026):** en la intro, los botones de la segunda parte (`btn_start`, `btn_continue`, `btn_es`…) se ocultan durante la animación inicial con `gui.set_enabled(false)`, pero `handle_click` hacía `gui.pick_node(node, x, y)` **sin comprobar `gui.is_enabled`** → eran invisibles pero clickables: un clic en su zona durante la animación disparaba la acción (`start_game`, `set_language`…).

### La solución: comprobar `gui.is_enabled()` ANTES de pickear (helper compartido)

```lua
-- ✅ CORRECTO: gate de estado antes del pick geométrico
local function pick_enabled(node, x, y)
  return node and gui.is_enabled(node) and gui.pick_node(node, x, y)
end
```

```lua
-- ❌ PELIGROSO: pick sin comprobar estado (detecta nodos ocultos)
if gui.pick_node(gui.get_node("btn_start"), x, y) then
    ...
end
```

> ⚠️ **Nota:** si el nodo es **hijo** de un contenedor, comprobar el hijo no basta — hay que verificar que TODA la jerarquía de ancestros esté habilitada (recomendación de britzl en el foro).

> ✅ **Referencia en el propio proyecto:** `intro/gui/intro.gui_script` — helper `pick_enabled()` (línea ~228) usado en TODOS los `handle_click`/`handle_mouse_move` + root fix en `on_message`: `if not gui_visible then return end` (se ignoran TODOS los `mouse_event` mientras la GUI está oculta). `library.gui_script` ya hacía el gate equivalente con `self.is_visible`.

### Cuándo aplicar

- Cualquier `gui.pick_node` sobre nodos que puedan estar ocultos/deshabilitados (menús con fases, botones condicionales, ventanas modales).
- Regla rápida: **todo `gui.pick_node` debe ir acompañado de `gui.is_enabled(node)`** (directo o vía helper). Y si la GUI entera puede estar oculta, añadir el gate de estado al recibir el evento de input.

---

## 🔴 GOTCHA #11: `window.get_size()` en HTML5 con `display.high_dpi = 1` devuelve píxeles FÍSICOS (CSS × devicePixelRatio)

### El problema

Con `display.high_dpi = 1` (activado en este proyecto para la nitidez en móviles de alta densidad), el canvas HTML5 tiene un buffer de render de tamaño **físico** (`game_canvas.width = CSS × dpr`, ver `dmloader.js` del bundle) y **`window.get_size()` devuelve ese tamaño físico**, no el CSS lógico del navegador. Confirmado por el staff de Defold (foro oficial, hilo *"High DPI Window Size Discrepancy"*, AGulev/britzl): high_dpi ON → un proyecto 640×360 se reporta como 704×396 con DPR 1.1.

**Caso real (Agosto 2026):** el mínimo de toque screen-aware de los botones del quiz usaba `min_uu = 48 / fit` con `fit = min(w/1280, h/768)`. En el móvil (canvas CSS 650×390, DPR 3) `window.get_size()` devolvía 1950×1170 → `fit = 1.52` → `min_uu = max(40, 48/1.52) = 40` → **sin cambio visible en móvil**. En el build nativo (DPR=1) sí funcionaba (fit=1.0 → 48 uu), lo que confundía el diagnóstico: el código parecía correcto pero el móvil no mejoraba.

### La solución: compensar con `devicePixelRatio`

```lua
-- html5.run() devuelve el resultado como STRING (ver main/platform.lua;
-- el API viejo luaCallback está ELIMINADO en 1.13). pcall por seguridad.
local function get_dpr()
    if type(html5) == "table" and type(html5.run) == "function" then
        local ok, res = pcall(function() return html5.run("window.devicePixelRatio") end)
        local dpr = ok and tonumber(res)
        if dpr and dpr > 0 then return dpr end
    end
    return 1
end

-- El estándar de toque (44-48px) se mide en CSS px → compensar con DPR:
-- min_uu = MIN_TOUCH_HEIGHT_PX × get_dpr() / fit
```

En native (desktop/móvil) `get_dpr() = 1` → la fórmula queda igual que antes. Referencia en el proyecto: `gui/interactive.gui_script` (`get_dpr` + `auto_size_button`, Ago 2026).

### Mundo → pantalla: NO usar `camera.world_to_screen()` con `set_screen_position` en HTML5 high_dpi (verificado Ago 2026)

**Intento fallido (Agosto 2026):** se sustituyó la fórmula manual por `camera.world_to_screen()` — en PC (DPR=1) quedó perfecto (incluido el resize), pero en HTML5 móvil (DPR 2-3) los globos quedaron **mucho más desplazados**. Causa: en HTML5 high_dpi `camera.world_to_screen()` devuelve el punto en px **LÓGICOS** (CSS), mientras que `gui.set_screen_position()` trabaja en px **FÍSICOS** (el espacio de `window.get_size()`, que con high_dpi devuelve CSS × DPR). En PC ambos espacios coinciden (DPR=1) → parecía correcto.

**Solución final (revertida y verificada):** `screen_utils.world_to_screen` usa la fórmula manual con `window.get_size()` (px físicos), que SÍ coincide con el espacio de `set_screen_position` en todas las plataformas → posición exacta en móvil y PC. El **gap** (offset vertical) se compensa con DPR: `BUBBLE_OFFSET_Y_CSS × window.get_display_scale()` → hueco constante en todos los dispositivos (antes: 50 px físicos = 16 CSS px en móvil DPR 3 → demasiado pegado). 📏 Ago 2026: el valor se bajó de 50 a **5 CSS px** y luego a **0 px (en prueba)** — el 5 queda conservado en la constante por si se revierte — y TODOS los globos (exhibición + diálogos de jugador/NPC) anclan al borde superior del sprite en vez del centro del GO (`anchor_offset_y` en `world_to_screen`; lo calcula `exhibition_object.script` con size×scale y `dialogue_manager.script` con el sprite del cuerpo — player → "sprite", NPC → "sprite_anim", frames 96×80 → 40 uds). El hueco ahora se mide desde el borde, no del centro. Referencia: `main/screen_utils.lua` (`M.get_display_scale()`, `BUBBLE_OFFSET_Y_CSS`).

**Regla:** `camera.screen_xy_to_world()` / `camera.world_to_screen()` comparten espacio con las coords de INPUT (lógico), NO con `gui.set_screen_position()` (físico). Para anclar GUI al mundo usa la fórmula con `window.get_size()`; los TAMAÑOS y OFFSETS expresados en CSS px se compensan con `window.get_display_scale()` (API del motor desde 1.4: DPR en HTML5, escala del sistema en native).

### 🎯 PERO el término de OFFSET (world−cam)×zoom SÍ debe escalarse por DPR (verificado con diagnóstico en pantalla, Ago 2026)

**El problema (caso real, final):** con la fórmula "centro físico + offset sin DPR" los globos quedaban **perfectos en PC (DPR=1) y desplazados en móvil (DPR 2.5)** sin errores en consola — el peor tipo de bug. Un diagnóstico en pantalla (`[GLOBO-FIT]`, texto amarillo temporal) dio los números definitivos en el móvil:

```
win=2400x1080 dpr=2.50 env=(1280,699) dev=(1280,699) local=(697,497)
```

Verificación de la conversión del motor (FIT, px físicos):

- `scale = min(2400/1280, 1080/768) = 1.40625`
- `local.y = 699 / 1.40625 = 497.1` ✓ (tamaño FÍSICO de ventana)
- `local.x = (1280 − 300) / 1.40625 = 697` ✓ — el `300` es el **letterbox FIT**: área visible `1280×1.40625 = 1800px`, margen `(2400−1800)/2 = 300px` a cada lado

**Conclusión:** el roundtrip GUI es cerrado (`dev == env` → el globo se renderiza EXACTAMENTE donde se le dice). El desplazamiento venía de la **fórmula mundo→pantalla**: la cámara proyecta en espacio CSS y el render escala ese espacio ×DPR sobre el canvas físico, pero la fórmula usaba el centro físico (`win/2`, correcto, ya incluye el factor) con un offset `(world−cam)×zoom` **sin escalar**. Resultado en móvil: globo desplazado hacia el centro por `offset×(DPR−1)`.

```lua
-- ✅ CORRECTO (main/screen_utils.lua): el OFFSET se escala por DPR
local dpr = M.get_display_scale()
screen_pos.x = (window_width / 2) + ((world_pos.x - cam_pos.x) * ORTHO_ZOOM) * dpr
screen_pos.y = (window_height / 2) + ((world_pos.y - cam_pos.y) * ORTHO_ZOOM) * dpr + offset_y
```

- En native/PC `get_display_scale() = 1` → la fórmula queda idéntica a antes (cero impacto en desktop).
- En HTML5 móvil (DPR 2-3) el offset crece ×DPR → el globo/panel vuelve a quedar **exacto sobre el personaje**.
- Afecta a TODAS las anclas del proyecto de una vez: `dialogue_manager.script`, `exhibition_manager.script` y `exhibition_object.script` usan el mismo `screen_utils.world_to_screen`.

> ⚠️ **Resumen mental del espacio de pantalla en HTML5 high_dpi:** centro de pantalla = `win/2` (físico, ya ×DPR); offsets de mundo (`(world−cam)×zoom`) y gaps en CSS px se escalan por DPR. El orden importa: `win/2 + offset×DPR` (NO `(win/2 + offset)×DPR`, que desplazaría el centro).

### 🚨 NO cachear `msg.url(nil, path)` a nivel de módulo — se liga al socket de CREACIÓN (rompió los globos en TODAS las plataformas, Ago 2026)

**El problema:** en un módulo `.lua`, el código top-level corre **una sola vez**, en el contexto del PRIMER `require` (durante la carga de la colección). `msg.url(nil, "/camera", nil)` evalúa el socket en ese momento de creación — que puede ser bootstrap/la colección que inicia la carga del proxy, o un gui_script — NO la colección del script que lo consumirá después. La URL queda **permanentemente ligada** a ese socket: cuando `world_to_screen()` se llama luego desde `dialogue_manager.script` (level_01), `go.exists(url)` busca `/camera` en el socket equivocado → devuelve `false` → la cámara se asume en `(0,0,0)` → los globos se dibujan a miles de px fuera de pantalla → **"el diálogo no funciona" SIN errores en consola** (la conversación arranca, hay audio, pero el globo es invisible).

```lua
-- ❌ PELIGROSO: msg.url a nivel de módulo (socket resuelto en el 1er require)
local CAMERA_GO_URL = msg.url(nil, "/camera", nil)   -- ¡ligado para siempre!
function M.world_to_screen(world_pos)
    ...
    local cam_pos = go.exists(CAMERA_GO_URL) and go.get_position(CAMERA_GO_URL) or vmath.vector3(0,0,0)
```

```lua
-- ✅ CORRECTO: string path (se resuelve contra la colección del LLAMADOR en tiempo de uso)
function M.world_to_screen(world_pos)
    ...
    local cam_pos = go.exists("/camera") and go.get_position("/camera") or vmath.vector3(0,0,0)
```

> ✅ **Referencia en el propio proyecto:** `main/screen_utils.lua` — tras el incidente, `world_to_screen` resuelve la cámara con `go.exists("/camera")`/`go.get_position("/camera")` dentro de la función. El resto del proyecto ya seguía la regla (URLs creadas en `init()`/handlers, no a nivel de módulo); `scene_manager.script` es la única excepción segura porque usa socket EXPLÍCITO (`msg.url("bootstrap:/proxy_intro#proxy")`).

**Regla:** nunca crees `msg.url(nil, ...)` en el top-level de un módulo compartido. Si necesitas una URL reutilizable, créala en `init()` del script que la usa o resuélvela inline en la función (string path si basta). Las únicas excepciones válidas a nivel de módulo son URLs con socket explícito (ej: `msg.url("bootstrap:/...")`).

### Cuándo aplicar

- Cualquier conversión px↔uu dependiente del tamaño de ventana en HTML5 con `high_dpi = 1`: mínimos de toque, escalado de botones, dimensiones de fondo, etc.
- Regla rápida: en HTML5 con high_dpi, `window.get_size()` = buffer físico (×DPR). Si el requisito se expresa en CSS px (como el estándar de toque), hay que compensar con `get_dpr()`.

---

## 🔴 GOTCHA #12: el material de fuente por defecto (`/builtins/fonts/font-df.material`) tiene tag `"gui"` → los LABELS se renderizan en ESPACIO DE PANTALLA, ignorando la cámara

### El problema

El material builtin `font-df.material` (el que usan CUALQUIER label por defecto) declara `tags: "gui"` (verificado en el código fuente del motor: `engine/engine/content/builtins/fonts/font-df.material`). El `default.render_script` dibuja el predicado `"gui"` con la proyección de GUI — `ortho(0, win_w, 0, win_h)`, sin cámara — en un paso posterior al mundo. Consecuencia:

- La posición del label (coordenadas de mundo) se interpreta como **px de pantalla**: un label en mundo (640,500) se dibuja fijo en pantalla (640,500), **sin importar la posición ni el zoom de la cámara**.
- Los sprites (`sprite.material`, tag `"tile"`) SÍ se renderizan con la cámara → escalan y se reposicionan con `orthographic_zoom`; los labels NO → parecen "congelados en su posición original" al hacer fullscreen/resize, y quedan FUERA de pantalla en resoluciones menores que su coordenada (el título de la intro en (640,500) no se veía en móvil 960×432 CSS — el bug histórico de la Fase 0-1).

### La solución

Para labels que deben vivir en el MUNDO (escalar/posicionarse con la cámara), usar un material de fuente con tag `"tile"` (mismo vertex/fragment program y constante `view_proj`). El componente label usa su PROPIO material si está definido (verificado en `comp_label.cpp`: `GetMaterialResource` → `component->m_Material ? component->m_Material : resource->m_Material`), así que se cambia por label sin tocar la fuente (que otras entidades pueden compartir, p. ej. la GUI).

```
-- assets/fonts/font-df-tile.material (copia de font-df.material con tag "tile")
name: "font"
tags: "tile"
vertex_program: "/builtins/fonts/font-df.vp"
fragment_program: "/builtins/fonts/font-df.fp"
vertex_constants { name: "view_proj" type: CONSTANT_TYPE_VIEWPROJ }
```

> ✅ **Referencia en el propio proyecto:** `intro/intro_animation.go` — `title_es`/`title_en` usan `/assets/fonts/font-df-tile.material` (Ago 2026). El fondo y el jugador (sprites) ya usaban `sprite.material` (tag `"tile"`) → escalan con la cámara.

### Notas

- El `sdf_scale` del renderer SDF (`font_renderer.cpp`) solo afecta al suavizado (anti-aliasing), NO al tamaño del texto — no hay ningún mecanismo de "texto a tamaño fijo" en el motor.
- Al pasar a `"tile"`, el label entra en el pase de mundo: participa en el depth test con el resto del mundo (orden por z correcto; la intro lo tiene a z=1, delante del fondo a z=0, igual que el jugador).
- Los globos de diálogo/quiz del juego usan GUI (`interactive.gui`), no labels de mundo → no afectados.

---

## 🔴 GOTCHA #13: `gui.pick_node()` usa el boundary del nodo → el `scale` SÍ amplía la diana (patrón "diana táctil ampliada" solo en móvil)

### El problema

Botones pequeños (p. ej. `btn_forward`/`btn_backward` de la intro: iconos 64×64 px con `SIZE_MODE_AUTO`) que en escritorio se tocan bien con el ratón, pero en landscape móvil la GUI se reduce con FIT (~0.56× para una ventana 926×428 CSS) y la diana real queda en **~35 px CSS**, por debajo del estándar de toque (44 px recomendados por Apple/Google). Resultado: toques que "fallan" sobre botones que visualmente parecen suficientemente grandes — el síntoma es "problemas de responsividad en móvil" sin errores en consola.

### La solución: escalar el nodo SOLO en táctil (visual + área de pick)

`gui.pick_node(node, x, y)` NO testea solo el tamaño crudo: usa el **boundary del nodo, que incluye el `scale`**. Verificado en el código fuente del motor 1.13 (`engine/gui/src/gui.cpp` → `PickNode`): `CalculateNodeTransform(... CALCULATE_NODE_BOUNDARY | CALCULATE_NODE_INCLUDE_SIZE | CALCULATE_NODE_RESET_PIVOT ...)` y test en espacio local 0..1. Por tanto **`gui.set_scale(node, 1.5)` agranda el visual Y el área de pick a la vez** (64 uu → 96 uu ≈ 53 px CSS en móvil).

```lua
-- 📱 Solo en táctil: flechas de la intro a 1.5×
local platform = require "main.platform"
local TOUCH_NAV_SCALE = 1.5
local TOUCH_NAV_IDS   = { btn_forward = true, btn_backward = true }

-- en init(), por nodo:
local base = 1.0
if platform.is_touch() and TOUCH_NAV_IDS[id] then
  base = TOUCH_NAV_SCALE
  gui.set_scale(node, vmath.vector3(base, base, 1.0))
end
```

⚠️ **Requisito: el sistema de hover debe ser relativo a la escala base.** Si el hover anima `PROP_SCALE` a un valor ABSOLUTO (1.0/1.08), al entrar en hover "desharía" la ampliación. Patrón aplicado: `self.base_scale[id]` por nodo; hover = `base × 1.08`, normal = `base`; `reset_hover` restaura `base_scale` (nunca 1.0 fijo). Así el hover de PC (base 1.0) queda idéntico a antes.

> ✅ **Referencia en el propio proyecto:** `intro/gui/intro.gui_script` (Ago 2026) — `TOUCH_NAV_SCALE=1.5` + `platform.is_touch()` en `init()`, `base_scale` poblado para TODOS los botones (normales + diálogo), `animate_hover`/`reset_hover` relativos a la base. La detección es fiable en `init` de la GUI: `platform.detect()` se llama SÍNCRONO en `scene_manager.script:init()` (bootstrap), ANTES del `async_load` del proxy de la intro.

### ⚠️ Matiz (Ago 2026): FILAS ESTRECHAS — diana completa ≠ escala completa (cap `max_scale` + reposicionado)

Escalar a la diana completa (88 uu) **no siempre es viable**: en filas donde varios controles conviven con una barra estrecha (p. ej. la fila de volumen del menú de pausa: barra de solo ~100 uu con `btn_sound` 16 uu y `btn_volume_±` 30 uu), aplicar la escala completa a todos los hace **solaparse entre sí y con la barra**. La diana y el layout entran en conflicto.

**Solución aplicada (`main/gui_touch.lua` + `gui/pause.gui_script`):**

1. **`max_scale` por nodo** — el helper compartido acepta un tope específico: `total_scale(height_uu, max_scale)` → `min(max_scale, TARGET/height)`. La fila de volumen usa escalas **moderadas** (sonido 3.0×, ± 1.6×) en vez de la diana completa, y se acepta un target menor (aun así 2× más grande que antes).
2. **El layout del editor manda (NO reposicionar por script)** — las dianas crecen desde el centro del nodo, así que basta con que el editor distribuya los elementos con margen suficiente para la escala ampliada. Un reposicionado hardcodeado en táctil (`gui.set_position` con valores fijos) **anula la redistribución del editor en móvil** y puede introducir solapes nuevos (caso real Ago 2026: `text_vol_pct` movido a x=320 chocaba con `btn_vol_up` ampliado a 1.6× → x∈[267,315]). Se eliminó: `pause.gui_script` ya no reposiciona nada en táctil.

```lua
-- main/gui_touch.lua (firma final, Ago 2026)
function M.total_scale(height_uu, max_scale)
    if not platform.is_touch() or not height_uu or height_uu <= 0 then return 1.0 end
    local cap = max_scale or MAX_TOTAL_SCALE  -- 4.0 por defecto
    return math.min(cap, math.max(1.0, TARGET_HEIGHT_UU / height_uu))  -- TARGET_HEIGHT_UU = 88
end
```

Regla: **diana completa por defecto, cap explícito cuando la fila es estrecha** — y si aun con el cap se solapan, **redistribuir los nodos en el editor** (con margen para la escala ampliada), nunca reposicionar por script solo en táctil.

### ⚠️ Matiz (Ago 2026): la LISTA de escalado debe cubrir TODAS las dianas del GUI

`pause.gui_script` cachea la escala base de TODOS los botones en `self.editor_scale` (incluido `units`) pero en `show_pause` **solo aplicaba la escala táctil a una sublista** (`lan`, `sound`, `io`, `vol`, `sfx`, `fps`…) — `btn_units` quedó **fuera** de la lista de aplicación. Síntoma en móvil: el toggle FPS (70×44 uu → 2.0× ≈ 49 CSS px) se veía **2× más grande** que el de unidades (70×44 uu sin escalar ≈ 24 CSS px), visual y diana inconsistentes entre dos botones gemelos.

- Regla: **cada botón cacheado en `editor_scale` debe tener su `node_base_scale` + `gui.set_scale` en `show_pause`** (o el equivalente del GUI). Al añadir un toggle nuevo (p. ej. FPS) junto a uno existente (unidades), verificar que AMBOS reciben el mismo tratamiento táctil — mismo tamaño de nodo ⇒ misma escala.
- El texto hijo (`btn_units_text`) hereda la escala del padre automáticamente: no hace falta escalarlo aparte.

### Cuándo aplicar

- Botones/dianas pequeñas en GUIs que se reducen con FIT en landscape móvil (target efectivo < 44 px CSS).
- Regla rápida: target táctil pequeño → `gui.set_scale` 1.5× solo con `platform.is_touch()` + hover relativo a la base. En PC (base 1.0) no cambia nada.

---

## 🔴 GOTCHA #14: anti-doble evento sin `mousemove` — el doble binding `touch`+`click` es el MISMO botón físico y en táctil no hay hover que desbloquee

### El problema

En Defold, `MOUSE_BUTTON_1` y `MOUSE_BUTTON_LEFT` son **el mismo botón físico** (ambos valen 1). Si el binding declara dos acciones para ambos (p. ej. `touch` y `click`, como en `input/game.input_binding`), **un solo clic genera DOS acciones** → dos `mouse_event` → una acción de navegación se dispararía dos veces (avanzar 2 páginas de golpe).

El anti-doble evento clásico "bloquear hasta que haya movimiento de ratón" es **frágil en táctil**: los eventos de ratón sintetizados en HTML5 llegan como prensa/suelta, no como *moves* fiables, y en táctil no existe hover. **Caso real (intro, Ago 2026):** el primer toque en `btn_forward` avanzaba 1 página y dejaba `nav_locked = true` para siempre → **todos los toques siguientes se ignoraban** hasta recargar la página (el desbloqueo solo ocurría en un `mouse_event` con `action_id == nil`, que en móvil no llega).

### La solución: cooldown temporal (se desbloquea solo en todas las plataformas)

```lua
-- 🛡️ El doble evento del MISMO clic cae DENTRO del cooldown (se absorbe);
--    el siguiente toque ya encuentra nav_locked = false.
local NAV_COOLDOWN = 0.3  -- segundos
...
if not self.nav_locked then
  self.nav_locked = true
  timer.delay(NAV_COOLDOWN, false, function() self.nav_locked = false end)
  current_synopsis = current_synopsis + 1
  ...
end
```

- El `mousemove` de desktop puede seguir desbloqueando ANTES (mejor UX con hover), pero ya no es el mecanismo principal.
- El cooldown cubre ambos eventos del mismo clic (mismo frame o frame siguiente) sin depender de ningún evento de movimiento.

> ✅ **Referencia en el propio proyecto:** `intro/gui/intro.gui_script` — `NAV_COOLDOWN = 0.3` (Ago 2026). `handle_mouse_move` conserva el desbloqueo inmediato en desktop como conveniencia.

### Cuándo aplicar

- Cualquier GUI con navegación/botones que deba funcionar en táctil y que use doble binding `touch`+`click` (o cualquier anti-doble evento que dependa de `mousemove`).
- Regla rápida: si el desbloqueo de un gate de input depende de un evento de MOVIMIENTO del ratón, en táctil quedará bloqueado → usar cooldown temporal.

---

## 🔴 GOTCHA #15: orientación de sprites — el `look_at` depende del ARTE (dirección del dibujo) y de la rotación horneada del GO, NO se copia entre enemigos

### El problema

`go.set_rotation(vmath.quat_rotation_z(atan2(dir.y, dir.x)))` orienta el GO hacia el movimiento, pero la cabeza del sprite apunta hacia donde mire el **arte en su orientación base**, modificada por la **rotación horneada** del componente sprite en el `.go`. Si el arte no mira hacia +X (derecha), el sprite queda desalineado (perpendicular, invertido, etc.) aunque la fórmula sea "la de siempre".

Caso real (Ago 2026): la rata del museo — arte dibujado mirando al **SUR** (cabeza abajo, cola arriba) con rotación horneada de +90° en `enemy_rat.go`. Dos intentos fallidos antes de acertar:

- `atan2 + π` (asumido entonces como la fórmula de la cucaracha — pero la cucaracha real usa `atan2` plano, ver Referencias) → cabeza **perpendicular** al movimiento.
- `atan2` plano → cabeza **perpendicular** al otro lado.

⚠️ **Las dimensiones del lienzo NO son representativas de la orientación:** un PNG 96×80 no implica que el dibujo sea horizontal (la rata estaba dibujada vertical con padding). Solo la inspección visual del arte CRUDO en el atlas es fiable.

### La fórmula (despejar la rotación del GO)

```
cabeza_mundo = ángulo_del_arte + rotación_GO + rotación_horneada_del_sprite
```

Se despeja `rotación_GO` para que `cabeza_mundo = atan2(dir.y, dir.x)` (dirección de movimiento):

- Arte mirando al SUR (−90°) y horneada **0°** (eliminada en el editor): `rotación_GO = atan2(dir.y, dir.x) + 90°` (π/2).
- Arte mirando al SUR (−90°) y horneada **+90°**: `rotación_GO = atan2(dir.y, dir.x)` (plano).
- Arte mirando al NORTE (+90°) y horneada **−90°**: `rotación_GO = atan2(dir.y, dir.x)` (plano) — caso de la cucaracha.
- Invariante equivalente: **`rotación_GO + horneada = θ + 90°`** (para arte mirando al sur).

### La solución (verificada Ago 2026)

1. **Confirmar la dirección del arte CRUDO** en el atlas (preguntar/verificar visualmente — nunca deducirla del tamaño del lienzo).
2. **Comprobar la rotación horneada del sprite** en el `.go` (`rotation { z: ..., w: ... }` dentro del `embedded_components` del sprite). En la rata se eliminó al trabajarla en el editor → el sprite muestra el arte tal cual (sur).
3. Despejar con la fórmula anterior. En la rata quedó: `look_at = atan2(dir.y, dir.x) + math.pi / 2`, verificado en las 4 direcciones cardinales.

```lua
-- features/enemy_rat/enemy_rat.script (look_at, Ago 2026)
local angle = math.atan2(dir.y, dir.x) + math.pi / 2  -- +90° compensa el arte mirando al sur
```

> ✅ **Referencias en el propio proyecto:** `features/enemy_rat/enemy_rat.script` (`look_at` con `+π/2`, arte=sur, horneada=0) y `features/enemy_cockroach/enemy_cockroach.script` (`look_at` con `atan2` plano, horneada de −90° — con esa horneada solo el arte mirando al NORTE alinea la cabeza). Ambos funcionan con fórmulas DISTINTAS porque su arte/horneada son distintos.

### Cuándo aplicar

- Cualquier sprite orientable con `go.set_rotation` (enemigos, NPCs, props) cuyo arte no mire a +X (derecha).
- Regla rápida: **nunca copiar el `look_at` de otro enemigo** — verificar (a) hacia dónde mira el arte crudo y (b) la rotación horneada del sprite en el `.go`, y despejar la fórmula.
- La forma más robusta a futuro: **normalizar el arte a +X** (derecha) y eliminar la horneada → `look_at = atan2` plano sin offsets, verificable de un vistazo en el editor.

## 🔴 GOTCHA #16: un `state gate` que ignore `mouse_hover exit` puede colgar alertas persistentes del HUD

### El problema

Los emisores de `show_persistent_alert` (hover de muebles/gato) muestran su texto al **entrar** en hover y lo ocultan con `hide_persistent_alert` al **salir**. La alerta **persistente NO tiene auto-timeout** (a diferencia de `show_alert`, que dura 3s): solo desaparece cuando el emisor envía `hide_persistent_alert`.

Si el handler de `mouse_hover` está dentro de un **gate de estado** que se activa mientras el cursor sigue sobre el objeto (p. ej. `if self.state ~= STATE.PET`), el `exit` de hover llega pero se **ignora** → `hide_persistent_alert` nunca se envía y la alerta queda **colgada** (visible) indefinidamente.

El segundo síntoma es más sutil: el HUD (sistema de cola FIFO de `hud.gui_script`) trata la alerta colgada como "current". Al interactuar con otro elemento de información, su alerta **desplaza** a la colgada a la **cola** (`alert_push_interrupted_to_front`); cuando esa información se oculta, la del objeto original **reaparece**. Es decir: el mensaje "vuelve a aparecer" tras cualquier otra interacción.

```lua
-- ❌ PELIGROSO: el exit de hover queda tragado por el gate de estado
if message_id == hash("mouse_hover") then
    if self.state ~= STATE.PET then
        if message.enter then
            msg.post(self.hud_url, "show_persistent_alert", { text = self.hint })
        else
            msg.post(self.hud_url, "hide_persistent_alert")  -- nunca llega en PET
        end
    end
end
```

**Caso real (Agosto 2026):** el hint del gato ("¡Miau! Si tienes algo rico para mí…") se mostraba en hover y, al hacerlo mascota (clic → PET), el `exit` era ignorado por el `if self.state ~= STATE.PET`. El mensaje quedaba visible todo el modo mascota y reaparecía tras interactuar con cualquier otro elemento (estanterías, vitrinas).

### La solución

1. **El cambio de estado que "se traga" el exit debe limpiar el estado de hover explícitamente** — al entrar en el nuevo estado, el emisor envía su propio `hide_persistent_alert` (y resetea el highlight si aplica):

```lua
-- ✅ CORRECTO: al activar PET, el gato limpia su propio hover (cat.script on_interact)
highlight_sprite(self, false)
msg.post(self.hud_url, "hide_persistent_alert")
```

2. **Regla general:** cualquier gate de estado dentro de un handler `mouse_hover` debe garantizar que el `exit` se procese SIEMPRE, o que la transición de estado limpie el hover de forma explícita (highlight + `hide_persistent_alert`).
3. **`hide_persistent_alert` es seguro como red de seguridad:** el HUD solo actúa si hay una persistente current; enviarlo sin persistente es un no-op inofensivo.

### Auditoría de emisores (Agosto 2026)

| Emisor | Alerta persistente | ¿Gate de estado? | Veredicto |
|---|---|---|---|
| `features/cat/cat.script` | ✅ | ✅ (PET) | ❌ **Tenía el bug** — corregido: limpia hover al entrar en PET |
| `features/furniture/slot_furniture.script` | ✅ | ❌ | ✅ Seguro: el exit se procesa siempre (gateado solo por `self.is_hovered`, en sync con la alerta); colisiones estáticas → el exit del cursor siempre llega |
| `main/npc.script` | ❌ (solo tint) | ❌ | ✅ Seguro: sin alertas persistentes |
| `features/furniture/bookcase.script` | ❌ (`show_alert` transitorio) | ❌ | ✅ Seguro: auto-timeout 3s por diseño |

### Cuándo aplicar

- Cualquier script que muestre `show_persistent_alert` y tenga **estados que cambian con el cursor encima** (modos, diálogos, muerte, recogida…): auditar que el `exit` de hover no quede tragado por un gate.
- Regla rápida: si un handler `mouse_hover` está dentro de `if <estado> then`, el exit puede colgarse → limpiar el hover al cambiar de estado.

---

## 🔴 GOTCHA #17: no asumas una API del motor — `sound.get_length` NO existe en esta versión

### El problema

Asumir que una función del motor existe porque aparece en la documentación oficial actual puede romper el juego en runtime si el editor usa una versión anterior. `sound.get_length(url)` (presente en Defold moderno) **no está expuesta en esta versión del motor**: al llamarla, el juego crashea con:

```
ERROR:SCRIPT: main/audio_manager.script: attempt to call field 'get_length' (a nil value)
```

### Caso real (Agosto 2026)

El refactor del sistema de audio usaba `sound.get_length()` para avanzar la playlist "hasta el final de la pista". Crash inmediato en `schedule_advance` (timer de avance).

**Trampa añadida:** el `build/` antiguo del proyecto SÍ contenía `get_length` en su `.wasm` (motor más nuevo), pero el **editor** con el que se ejecuta Play usa un motor anterior — los builds viejos NO son una fuente fiable para conocer la API del motor de runtime.

### La solución

1. **Duración como dato estático:** las duraciones reales de los `.ogg` se miden con ffprobe (`ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 <file>.ogg`) y se guardan en el registro de audio (`main/audio_registry.lua`, campo `dur`). El avance de la playlist usa `timer.delay(dur)` — mecanismo probado que ya usaba el sistema de zonas anterior.
2. **Fallback:** si una pista no declara `dur`, se usa `DEFAULT_TRACK_DURATION`.
3. **Fuente fiable de la API:** para confirmar qué funciones existen, probar en el editor (o inspeccionar las anotaciones Lua del editor) — nunca fiarse de builds compilados con otra versión ni de la doc web sin verificar la versión local.

### Cuándo aplicar

- Cualquier uso de una API del motor que no esté ya usada en el proyecto: verificar antes con un `print(type(sound.get_length))`-style o probando en el editor.
- Siempre que se añada un sonido/pista nueva: actualizar también su `dur` en `audio_registry.lua`.

**Mismo caso, campo `loop` del `.sound` (Ago 2026):** el DDF de los `.sound` en esta versión NO acepta el campo `loop` — declararlo hace que el recurso NO cargue:

```
The file ".../end_game_victory.sound" could not be loaded:
dmSoundDDF.SoundDesc.loop   ← campo desconocido en esta versión
```

El loop se controla SOLO en runtime con `sound.play(url, { loop = 1 })`; el `.sound` no lo declara. Sin la clave, el sonido ya suena una vez (loop desactivado por defecto).

---

## 🔴 GOTCHA #18: `go.exists` con ids relativos resuelve en la colección del llamante — el sondeo de objetos de un proxy debe vivir en la colección dueña

### El problema

Los módulos Lua **SÍ se comparten** entre colecciones en este proyecto (`[script] shared_state = 1` en `game.project`) — por eso `game_state` funciona de forma cruzada (guardado, quiz, pausa, clima). Lo que NO se comparte es el **contexto de resolución de URLs**: un id "pelado" (el que devuelve `factory.create`, p. ej. `enemy_cockroach1`) pasado a `go.exists()` / `go.get()` se resuelve **dentro de la colección del script que llama**. El gato (`cat.script`, level_01) resuelve los ids en level_01 → los enemigos existen → funciona. Un script de **bootstrap** resuelve el MISMO id contra su propio ámbito (colección raíz, sin instancia de nivel) → `go.exists` devuelve false siempre → parecía que el módulo "estaba vacío" cuando el problema era de resolución, no de estado.

### Caso real (Agosto 2026)

El refactor de audio puso el sondeo de "oleada viva" (fight) dentro del `audio_manager` (bootstrap) con `enemy_state.get_spawned()` + `go.exists(id)`. La lista de ids SÍ llegaba (módulo compartido), pero `go.exists` fallaba desde bootstrap por resolución relativa → 0 enemigos vivos → `background_fight_1` nunca sonaba. El MISMO código funciona desde level_01 (el gato lo demuestra: `features/cat/cat.script`).

### La solución

1. **El poll vive en la colección dueña de los objetos:** la detección de pelea se movió a `main/spawn_enemies.script` (level_01, donde los ids relativos resuelven — mismo contexto que el gato).
2. **Cruce de colecciones por MENSAJES con URL completa:** level_01 notifica a bootstrap con `msg.post("bootstrap:/audio_manager#manager", "play_event", { id = "fight" })` / `stop_event` (idempotentes). El audio_manager solo recibe órdenes; no valida objetos del proxy.
3. **Regla general del proyecto:** los mensajes entre colecciones SIEMPRE usan URL completa (`bootstrap:/...`, `level_01:/...`, `intro:/...`) — patrón ya usado por `web_controls` ("level_01:/player#player"), `scene_manager`, `pause` y `library.gui`. Un id pelado enviado desde bootstrap a level_01 falla silenciosamente.

### Cuándo aplicar

- Cualquier script de bootstrap que necesite VALIDAR objetos de level_01 (`go.exists`, `go.get`, `msg.post` a un id pelado): la comprobación se hace en level_01 y se comunica el RESULTADO por mensaje a una URL completa.
- Desde bootstrap a level_01 usa siempre URLs completas — nunca ids pelados.
- Leer DATOS de módulos compartidos (`game_state`, `enemy_state`, `text_loader`…) desde bootstrap ES seguro (estado global con `shared_state = 1`); lo que falla es resolver URLs/objetos relativos a otra colección.

---

## 🔴 GOTCHA #19: un nodo GUI declarado `visible: false` en el `.gui` puede no aparecer aunque el script lo active con `gui.set_enabled(true)`

### El problema

El estado inicial de un nodo se declara en el archivo `.gui` (campo `visible`). Si el script pretende mostrarlo después con `gui.set_enabled(node, true)`, el resultado NO está garantizado: en esta versión del motor el flag `visible: false` del archivo se aplica como estado inicial y puede dejar el nodo permanentemente invisible a pesar de `set_enabled(true)` — especialmente si la activación ocurre desde `init()` (antes de que el escenario termine de aplicar el estado declarado). El síntoma es un build que compila y corre SIN errores y un nodo que nunca aparece.

### Caso real (Agosto 2026)

El overlay de FPS (`text_fps_debug` en `gui/hud.gui`) se declaró con `visible: false` y se activaba con `gui.set_enabled(node, true)` + `gui.set_text()` desde `init()`. El build compilaba, sin errores, y el nodo NUNCA aparecía (ni en build de escritorio ni HTML5), aunque el código fuera correcto y el nodo existiera en el `.guic` compilado. Tras marcar `visible: true` en el editor (equivalente a omitir el campo), el overlay se ve desde el primer frame.

Nota: los contenedores `box_pet_container` / `btn_retry_container` también se declaran `visible: false` en el archivo y SÍ funcionan con `gui.set_enabled(true)` — la diferencia observable es que su activación llega por MENSAJE (`update_pet_timer` / `show_retry_button`), no desde `init()`. La regla segura es no fiarse del flag del archivo para nodos que deban poder mostrarse.

### La solución

1. **Regla:** un nodo que deba mostrarse/ocultarse en runtime se declara `visible: true` (o se omite el campo) en el `.gui`, y la visibilidad se controla EXCLUSIVAMENTE con `gui.set_enabled(node, bool)` desde el script.
2. `visible: false` en el archivo solo se usa como estado inicial para nodos que NUNCA deben verse sin una activación explícita posterior — y esa activación debe llegar por mensaje/update, no desde `init()`.

### Cuándo aplicar

- Al crear cualquier nodo GUI nuevo que se muestre/oculte dinámicamente: decláralo `visible: true` en el archivo.
- Si un nodo "no aparece" sin errores: comprueba primero el campo `visible` del nodo en el `.gui` antes de tocar lógica.

---

## 🔴 GOTCHA #20: nombres de personaje hardcodeados en español en fallbacks — al localizar el juego, un string "de respaldo" vuelve a aparecer en cualquier idioma

### El problema

Cuando un texto mostrado por la GUI lleva un nombre hardcodeado en el script como valor por defecto ("Conservador", "Anciano", "Personaje"…), ese string sobrevive a la localización: el texto real llega localizado por `characters`, pero el fallback salta en cuanto el dato esperado no está (texto sin prefijo `"Nombre: "`, datos ausentes) y muestra español en un juego en inglés — o cualquier idioma en el que el fallback no exista. La traducción del archivo de textos no lo detecta: el grep de acentos/ñ no mira el código, solo los `.lua` de contenido.

### Caso real (Agosto 2026)

Al traducir `main_text_en.lua` por completo, quedaron tres fallbacks en código con nombres en español: `local name_str = "Conservador"` y `local name_str = "Anciano"` en `gui/interactive.gui_script` (handler de `show_gui_dialog`) y `or "Conservador"` / `or "Personaje"` en `get_speaker_name()` de `main/dialogue_manager.script`. En la práctica eran casi inalcanzables (el `full_text` siempre trae el prefijo "Nombre: " localizado), pero con un texto inesperado el globo habría mostrado "Conservador"/"Anciano" en inglés.

> 📋 **Hallazgo adicional de la auditoría (Ago 2026) — alertas del HUD hardcodeadas + clave cruda del periodo:** `main/inventory_manager.script` mostraba DOS textos visibles en español directamente desde código: `"El objeto ya está depositado en esta estantería."` (re-clic en estantería) y `"Objeto listo para vitrina. Dirígete a la vitrina del periodo " .. furniture_period .. "."` — este segundo, además de estar en español, **concatenaba la clave cruda del periodo** (`pal`/`neo`/`bro`…), así que en inglés se veía "…period pal.". Fix: las claves pasaron a `general_text` → `M.inventory` (`already_deposited`, `ready_for_showcase` con `%s`, `error_wrong_furniture`) y el periodo se resuelve con `inv.periods[furniture_period]` (tabla ya localizada). Regla reforzada: **ningún string de UI visible se hardcodea en un script, ni siquiera en `msg.post(..., "show_alert", { text = ... })`** — y si se concatena un dato de dominio (periodo, nombre…), usar su versión localizada, nunca la clave interna.

### La solución

1. **Los fallbacks se resuelven con los datos localizados, nunca con strings en un idioma:**
   - `interactive.gui_script`: `local name_str = (self.texts.characters[message.speaker] and self.texts.characters[message.speaker].name) or ""` — el nombre real viene SIEMPRE en `message.full_text` (prefijo que prepara `dialogue_manager` con el idioma actual); el fallback solo cubre un texto sin prefijo.
   - `dialogue_manager.get_speaker_name()`: `or speaker_key` (el id del personaje es neutro en cualquier idioma) en vez de `or "Conservador"` / `or "Personaje"`.
2. **Regla:** ningún nombre de personaje (ni string de UI visible) se hardcodea en un script; si necesita un valor por defecto, se toma de `characters` localizado o se devuelve un valor neutro (vacío / id).

### Cuándo aplicar

- Al localizar contenido: además de traducir los archivos de texto, buscar en el código los strings de UI visibles que actúan como default (grep de los nombres viejos en `*.script`/`*.gui_script`).
- Al escribir fallbacks de texto: resolverlos desde los datos localizados o con un valor neutro, nunca con un literal en un idioma concreto.

---

## 🔴 GOTCHA #21: comentarios `--` (Lua) en archivos de datos protobuf-text — el parser del editor los rechaza y rompe la carga del recurso

### El problema

Los archivos de datos de Defold (`game.project`, `.gui`, `.go`, `.collection`, `.sound`, `.input_binding`…) NO son Lua: usan el formato de texto de propiedades (INI o protobuf-text). Si se les inserta un comentario estilo Lua `-- ...` (habitual al documentar una edición hecha a mano), el parser del editor no lo ignora: lo interpreta como contenido inválido y muestra `RENDER ERROR: ... Expected identifier. Found '--'` (o `Invalid setting line`), impidiendo cargar el recurso.

### Caso real (Agosto 2026)

Dos RENDER ERRORES seguidos por la misma causa durante la implementación de los grupos de sonido y el slider de Efectos:

1. `game.project`: al añadir comentarios `-- 🎛️ Grupos de sonido...` en la sección `[sound]` → `Invalid setting line: -- 🎛️ Grupos...`. Se eliminaron (los comentarios en `game.project` no se pueden usar en esta versión del editor).
2. `gui/pause.gui`: al clonar los nodos del slider de volumen como `sfx_*`, se dejaron dos líneas de comentario `-- 🎛️ CONTROL DE EFECTOS...` entre bloques `nodes { ... }` → `197:1: Expected identifier. Found '--'`. Se eliminaron y el recurso volvió a cargar.

Nota: en `game.project` además intenté declarar los grupos con `use_sound_groups` + `groups = [...]` — claves que NO existen (los grupos de sonido se crean automáticamente desde la propiedad `group` de los `.sound`, ver GOTCHA #17 sobre no asumir APIs).

### La solución

1. **Regla:** ningún archivo de datos (`game.project`, `*.gui`, `*.go`, `*.collection`, `*.sound`, `*.input_binding`) lleva comentarios `--`. La documentación de un nodo/recurso se pone en el script que lo controla, o se omite.
2. Antes de validar, verificar que no quedan líneas con `--` fuera de archivos Lua: `grep -rn '^\s*--' --include='*.gui' --include='*.go' --include='*.collection' --include='*.sound' .`
3. Si el editor reporta `Expected identifier. Found '--'` o `Invalid setting line`, la primera sospecha es un comentario (o una clave no soportada) insertado en un archivo de datos.

### Cuándo aplicar

- Al editar a mano `game.project` o clonar nodos en un `.gui` / `.go`: no añadir comentarios `--`; si se necesita contexto, documentar en el script asociado.
- Al recibir un RENDER ERROR de un recurso de datos: grep de `--` en el archivo antes de buscar otros problemas.

---

## 🔴 GOTCHA #22: temporizador visible con fuente en `game_state` — polling 10Hz del HUD vs timers/mensajes del emisor

### El problema

Hay dos formas de alimentar un temporizador visible en el HUD (pie timer / cuenta atrás), y elegir la equivocada rompe la cuenta en algún escenario:

1. **Por mensajes del emisor** (patrón Timer A de exhibición): el script dueño del estado envía `update_timer_progress` (con `remaining`/`progress`) a 10Hz desde su `update()`. Es el patrón correcto cuando el timer es **estado en RAM del emisor** (timer interno del core, no persiste en el savegame).
2. **Por polling del HUD** (patrón cooldown de la restauradora): el HUD lee la fuente directamente en su polling de `update_texts()` (10Hz). Es el patrón correcto cuando la fuente es **wall-clock persistido** (`os.time()` + timestamp en el savegame).

Errores típicos de mezclar los patrones:
- Un cooldown persistido NO debe conducirse con un `timer.delay` en RAM: al guardar/recargar a mitad de cuenta el timer muere y el pie desaparece aunque el cooldown siga activo (el aviso proactivo del dialogue_manager aceptó esa pérdida a propósito; un pie visible no debe perderla).
- Un timer de estado en RAM no debe consultarse por polling desde otro script sin compartir el estado (doble fuente de verdad).

### Caso real (Agosto 2026)

Pie timer del cooldown del NPC de quiz de restauración: tras fallar su quiz de restauración, cooldown de 60s (`game_state.RESTORER_COOLDOWN_SECONDS`, `available_after = os.time() + ...`). El HUD lo conduce en `update_restoration_timer()` desde `update_texts()` (10Hz): el NPC se resuelve por TIPO (`npc_spawn_state.find_npc_by_type(NPC_TYPE_QUIZ_RESTORATION)`, Ago 2026 — antes `"npc_11"` hardcodeado), `remaining = game_state.get_npc_cooldown_remaining(...)`, `progress = remaining / RESTORER_COOLDOWN_SECONDS`, ángulo 360°×progress y texto con `set_text_cached`. Mismo gate que el quiz (pieza activa en estado `"restoration"`). Frente al Timer A de exhibición, que el inventory_manager conduce por mensajes `update_timer_progress` a 10Hz desde su `update()` (estado en RAM del core, no sobrevive a save/load).

> ✅ **Referencia en el propio proyecto:** `gui/hud.gui_script` — `update_restoration_timer()` (polling) vs handler `update_timer_progress` + `main/inventory_manager.script` `update()` (mensajes).

### La solución

1. **Si la fuente de verdad es un timestamp persistido (`os.time()` + `available_after`) → polling desde el HUD.** El HUD ya hace polling a 10Hz (`update_texts`); leer `game_state` es una lectura de tabla barata y la cuenta se recupera sola tras guardar/recargar.
2. **Si la fuente de verdad es un timer en RAM del emisor → mensajes a 10Hz** (como `update_timer_progress`): el emisor conoce el estado y solo él debe emitir; el HUD es pasivo (recibe y pinta).
3. **Regla de dedo:** ¿el temporizador sobrevive a guardar/recargar? Sí → polling de `game_state`. No → mensajes del emisor.
4. **Coste de alocación:** en ambos casos el texto se formatea a 10Hz; usar `set_text_cached` del HUD (o el patrón cache del inventario) para no alocar strings cuando el valor no cambia.

### Cuándo aplicar

- Al crear cualquier cuenta atrás visible en el HUD (cooldowns, timers de flujo): decidir primero si la fuente es persisted (`os.time`) o RAM (timer del core) y elegir el patrón correspondiente.
- Al clonar un pie timer nuevo: copiar el patrón del cooldown de la restauradora (polling + gate + `set_text_cached`) si la fuente es un cooldown de NPC, o el del Timer A (mensajes) si es un timer interno del core.

---

## 🔴 GOTCHA #23: los callbacks de fin de animación (`gui.animate` / `sprite.play_flipbook`) NO son fiables en esta versión — un bucle que dependa del callback muere silenciosamente

### El problema

En esta versión de Defold, el callback de fin de animación de `gui.animate()` (y el de `sprite.play_flipbook()`) **no se invoca de forma fiable**. Un bucle que encadene la siguiente pasada DENTRO del callback (p. ej. un marquee que "vuelve a empezar al terminar") hace exactamente **UNA pasada** y se detiene en silencio — sin errores en consola, porque la animación en sí sí completa.

```lua
-- ❌ EL BUG: el callback nunca se llama → la animación se ejecuta UNA vez y el ciclo muere
gui.animate(warn, gui.PROP_POSITION, to, gui.EASING_LINEAR, 15.0, 0.0, nil, function()
    tick()  -- nunca llega aquí en esta versión
end)
```

### Caso real (Agosto 2026)

El `warning_text` de la intro (marquee intermitente del aviso de guardado, HTML5): el ciclo se encadenaba en el callback del `gui.animate` y el aviso cruzaba la pantalla **una sola vez** ("Marquee no se repite. Aparece sólo una vez."). Evidencia previa en el propio proyecto: `player.script` documenta *"play_flipbook con callback no funciona en esta versión de Defold"* y usa un `timer.delay(1.4)` para cubrir el ciclo de la animación de muerte.

### La solución: el ciclo lo conduce un `timer`, no el callback

```lua
-- ✅ CORRECTO: un timer cubre la duración de la animación + la pausa
-- (en el marquee: cruce 15s + pausa 8s) y relanza el ciclo.
gui.animate(warn, gui.PROP_POSITION, to, gui.EASING_LINEAR, MARQUEE_DURATION, 0.0, nil, nil)
self._marquee_timer = timer.delay(MARQUEE_DURATION + MARQUEE_PAUSE, false, function()
    self._marquee_timer = nil
    cycle()
end)
```

- El callback se deja en `nil` (si otra versión lo invocara, no hace nada → **nunca hay doble ciclo**).
- El `stop_*` debe cancelar también el `timer` (no solo la animación), y el inicio debe ser **idempotente** (cancelar un timer pendiente antes de crear uno nuevo).
- Requiere conocer la duración de la animación (constante) para dimensionar el timer del ciclo.

> ✅ **Referencia en el propio proyecto:** `intro/gui/intro.gui_script` — `start_marquee`/`stop_marquee` (Ago 2026). Patrón hermano: `features/player/player.script` (animación de muerte con `timer.delay(1.4)`).

### Cuándo aplicar

- Cualquier bucle/colao de animación que encadene la siguiente pasada en el callback de fin (`gui.animate` o `sprite.play_flipbook`): conducir el ciclo con `timer.delay` (duración conocida) en lugar del callback.
- Al añadir una animación secuencial (marquee, loop, cola de animaciones), asumir el callback no fiable por defecto.
- ⚠️ `gui.play_flipbook` con callback (`library.gui_script`, paginación del libro) usa la firma `function(scr, node)` y según el doc funciona — antes de depender de un callback para lógica crítica, verificar en runtime que se invoca en esta versión.

---

## 🔴 GOTCHA #24: `gui.*` y `msg.post(".")` se resuelven con el contexto del script que LLAMA, no del que creó la closure

### El problema

Cuando un `gui_script` registra un callback/listener en un módulo persistente (`game_state`, etc.) y ese módulo lo invoca desde el contexto de OTRO script (p. ej. `scene_manager.on_input` → `game_state.evaluate_tasks()` → callback), ocurren DOS fallos distintos:

1. **`gui.*` lanza error de contexto**: `"You can only access gui.* functions and values from a gui script instance (.gui_script file)"` en el primer `gui.get_node`/`gui.set_text` del callback — aunque la closure se creara DENTRO del gui_script. Lo que manda es el contexto de ejecución de la llamada, no el de creación.
2. **`msg.post(".")` se pierde en silencio**: `"."` se resuelve a la URL del script que está ejecutando la llamada (p. ej. scene_manager), no a la del gui_script que creó la closure. El mensaje llega a un handler que no lo conoce → sin error y sin efecto.

### El patrón correcto: reenvío por mensaje con URL absoluta

```lua
-- gui_script (p. ej. gui/victory.gui_script)
local VICTORY_GUI_URL = "bootstrap:/gui_victory#victory"  -- URL ABSOLUTA del propio componente

game_state.on_victory(function()
    -- ✅ Contexto ajeno: solo msg.post a URL absoluta (nunca "." ni gui.*)
    msg.post(VICTORY_GUI_URL, "show_victory")
end)

function on_message(self, message_id, message)
    if message_id == hash("show_victory") then
        show_victory(self)  -- ✅ Contexto gui_script: aquí gui.* funciona
    end
end
```

- El callback en contexto ajeno hace SOLO `msg.post` a la URL absoluta del componente (documentada en su `.collection`).
- El trabajo `gui.*` se ejecuta en `on_message` del propio gui_script (contexto correcto).

### Caso real (Agosto 2026)

`gui/victory.gui_script` — el listener de victoria se invocaba desde `scene_manager` vía `game_state.evaluate_tasks()`: primero dio el error de `gui.*`; tras reenviar con `msg.post(".")` el mensaje se perdía en silencio (nunca llegaba el `show_victory`). Con URL absoluta + `on_message` funcionó.

### Cuándo aplicar

- Cualquier callback registrado en un módulo persistente que un `.script` pueda invocar, y que necesite tocar `gui.*` o enviarse mensajes a sí mismo.
- Regla general: **un gui_script nunca asume que sus closures se ejecutan en su propio contexto**.

---

## 🔴 GOTCHA #25: los callbacks de `register_callback` capturan el `self` del componente — al descargar su colección quedan MUERTOS y se acumulan

### El problema

`game_state.register_callback(var, fn)` vive en un módulo PERSISTENTE (misma tabla toda la sesión). Los scripts que registran callbacks capturan su `self` (componente):

```lua
-- features/player/player_spray.script
game_state.register_callback("spray_current", function(_, old, new)
    self.resources = new  -- self = componente de level_01
end)
```

Al descargar level_01 (victoria → "Nueva partida" → intro), el componente se destruye pero la closure **permanece registrada**. En la siguiente carga del nivel:

1. El siguiente `set_global("spray_current", ...)` dispara el callback MUERTO → `self.resources = new` sobre un `self` destruido → `ERROR:SCRIPT: attempt to index a nil value` (traza con `__newindex`).
2. Cada recarga del nivel registra OTRO callback más → acumulación ilimitada de closures muertas.

### La solución: `notify_callbacks` auto-curativo (pcall + retirada)

```lua
function M.notify_callbacks(var_name, old_value, new_value)
    local list = M.callbacks[var_name]
    if not list then return end
    for i = #list, 1, -1 do  -- reversa: retirada segura durante el recorrido
        local ok, err = pcall(list[i], var_name, old_value, new_value)
        if not ok then
            print("[GameState] Callback '" .. var_name .. "' eliminado tras error: " .. tostring(err))
            table.remove(list, i)
        end
    end
end
```

- Un callback muerto se **auto-elimina** tras el primer error → no vuelve a fallar ni se acumula.
- Los callbacks restantes siguen ejecutándose (antes, un fallo abortaba la lista entera y el resto nunca corría).

### Caso real (Agosto 2026)

`features/player/player_spray.script` tras el flujo victoria → "Nueva partida" → recarga del nivel: `attempt to index a nil value` en `__newindex` cada vez que se disparaba `spray_current`.

### Cuándo aplicar

- Al registrar callbacks desde scripts de colecciones que se descargan (level_01): el diseño auto-curativo de `notify_callbacks` ya cubre el caso; no hace falta unregister manual.
- Al añadir un nuevo `register_callback` desde un script del nivel: recordar que la closure sobrevivirá a la descarga de su colección.

---

## 🔴 GOTCHA #26: los enemigos ESTÁTICOS del editor no se registran en `enemy_state` → invisibles para el auto-aim del spray móvil y el gato

### El problema

`enemy_state` (main/enemy_state.lua) registra los ids de los enemigos vivos para que el auto-aim del spray móvil (`auto_aim.find_nearest`), el gato y el sondeo de pelea los detecten. Hasta Ago 2026, el registro SOLO lo hacía `spawn_enemies.script` tras `factory.create()` → **los enemigos colocados estáticos en el editor (p. ej. la cucaracha de `level_01.collection`) NUNCA se registraban**.

**Caso real (Agosto 2026):** el botón de spray en móvil no funcionaba. Síntoma: al pulsar `btn_spray` no salían partículas ni sonaba el spray, sin errores en consola. Causa: con `SMART_TRIGGER = true` (config.lua), el spray móvil solo dispara si `auto_aim.find_nearest()` encuentra un enemigo **registrado** dentro de `AUTO_AIM_RANGE` — y la cucaracha estática del nivel no estaba en `enemy_state.spawned`. En PC el spray funcionaba porque el ratón dispara siempre (sin smart trigger), lo que confundía el diagnóstico: el código móvil parecía correcto.

### La solución: que el PROPIO enemigo se registre en su `init()`

```lua
-- features/enemy_cockroach.script (y enemy_rat.script), en init():
local enemy_state = require "main.enemy_state"
...
enemy_state.register(go.get_id())  -- id real, sirve para estáticos y factory
```

- Cubre **ambos orígenes** a la vez: las instancias del editor (que solo pasan por `init()`) y las de factory (que también pasan por `init()` tras `factory.create()`).
- Se **eliminó el `enemy_state.register(id)` de `spawn_enemies.script`**: el script de la instancia recién creada se registra a sí mismo en el mismo frame → sin ids duplicados en la lista.
- `go.get_id()` devuelve el id real del GO (hash) — mismo contrato que el id devuelto por `factory.create()`; los consumidores ya filtran con `go.exists()`.

### Efectos colaterales correctos (por diseño)

- El **gato** ahora detecta y caza también a la cucaracha estática.
- El **sondeo de pelea** (`spawn_enemies.script`, fight music) la cuenta como oleada viva mientras exista.
- `clear_alive()` (respawn) la borra junto al resto: al reiniciar, los estáticos desaparecen igual que los dinámicos.

### Cuándo aplicar

- Cualquier entidad que deba ser detectable por sistemas que consultan `enemy_state` (auto-aim, gato, sondeo) y que pueda existir en DOS formas: estática (editor) y dinámica (factory).
- Regla rápida: si el registro de una entidad vive en el SPAWNER (solo cubre factory), los consumidores no verán las instancias del editor → mover el registro al `init()` de la propia entidad (cubre ambos orígenes sin duplicados).

## 🔴 GOTCHA #27: el pool de collision objects es un buffer FIJO — añadir collision objects a prototipos multiplicados por instancias puede saturarlo

**Síntoma:** al cargar el nivel (o al spawnear en runtime):

```
ERROR:GAMESYS: Collision object could not be created since the buffer is full (256).
Increase the 'physics.max_collision_object_count' value in [game.project]
```

**Causa raíz:** `physics.max_collision_object_count` (defecto **256**) es un pool asignado al arrancar. El error NO indica "demasiada física", sino que se superó el número de collision objects **simultáneos** (estáticos del nivel + dinámicos creados con factory/bullets). El coste de añadir UN collision object a un prototipo es `nº de instancias × 1` — en `level_01` con 25 instancias de `door_side`, añadir `collisionobject_player_open` costó **+25** de golpe.

**Caso real (Agosto 2026):** `level_01` ya consumía **239/256** (93%). El fix del gap visual de `door_side` (colisión desplazada al abrir, GOTCHA sobre sprite simple) añadió 25 collision objects → **264**, superando el pool: los últimos 8 intentos de creación fallaron (sin orden garantizado, pueden fallar puertas, slots o NPCs).

### Cómo dimensionar el valor

- **Estático:** para cada prototipo del nivel → `collision objects del .go × nº de instancias` (script `python3` para contarlo, ver historial).
- **Dinámico:** peor caso concurrente → enemigos × collision objects por enemigo + balas + pickups. En este proyecto: `15 enemigos × 3 + 10 balas × 1 ≈ 55`.
- **Total peor caso ≈ 319** → se subió a `max_collision_object_count = 512` (margen 193). Coste de memoria por objeto es pequeño (Box2D body + fixtures), el doble de pool sigue siendo despreciable en móvil.

### Regla práctica

- Antes de añadir un collision object a un prototipo usado por N instancias, comprueba `max_collision_object_count` vs el consumo estático real. Una colisión extra en un prototipo × 25 instancias puede tumbar el nivel aunque en el editor "solo sea una caja más".
- El pool se REUTILIZA al descargar colecciones (intro ↔ level_01 comparten slots), así que el límite debe cubrir la colección más pesada, no la suma de todas.

---

## 🔴 GOTCHA #28: El sondeo de "pelea" debe filtrar por distancia al jugador

**Síntoma (Agosto 2026):** al entrar en level_01, el nivel arranca con la música de pelea (`background_fight_1`) en lugar de la playlist normal. El jugador no tiene por qué estar en combate: la música "rara" dura hasta matar a un enemigo lejano.

**Causa raíz:** el sondeo de oleada viva (`spawn_enemies.script` → `play_event { id = "fight" }`) contaba **cualquier enemigo vivo** (`enemy_state.get_spawned()` + `go.exists`) **sin mirar la distancia al jugador**. Desde el GOTCHA #26, los enemigos estáticos del editor también se registran en `enemy_state` en su `init()`. La cucaracha estática de `level_01.collection` (posición 609,1930 — a ~1380 uu del spawn del jugador en 1156,664) disparaba `fight` desde el **primer frame** del nivel.

**La solución (patrón canónico):** el poll solo cuenta enemigos dentro de `config.FIGHT_COMBAT_RADIUS` (250 uu, configurable — Ago 2026: bajado de 400 porque la pantalla visible es 640×384 uds a zoom 2.0, distancia máx. en pantalla ≈ 373 uds en la esquina, así que con 400 la música arrancaba SIEMPRE con el enemigo desencuadrado) del jugador, **con histéresis espacial**: entra con el radio base y sale con radio × 1.25 (mismo patrón que `PROXIMITY_HYSTERESIS` de la cucaracha y `AUTO_AIM_HYSTERESIS` del spray). Distancia al cuadrado sin vector (zero-alloc, estándar §2).

```lua
-- main/spawn_enemies.script (update, cada 0.5s)
local radius = config.FIGHT_COMBAT_RADIUS
if self.fight_in_combat then radius = radius * 1.25 end
local radius_sqr = radius * radius
for _, id in ipairs(enemy_state.get_spawned()) do
    if go.exists(id) then
        local pos = go.get_position(id)
        local dx, dy = pos.x - p.x, pos.y - p.y
        if dx * dx + dy * dy <= radius_sqr then
            in_combat = true; break
        end
    end
end
self.fight_in_combat = in_combat
```

**Lección:** cualquier sondeo que decida música/estado según "hay enemigos vivos" debe **contextualizarse con la distancia al jugador** (radio de combate). Los enemigos estáticos del editor son legítimos y deben registrarse (GOTCHA #26 — los necesita el spray móvil y el gato), pero un consumidor que no filtre distancia asumirá que el jugador está en combate desde el inicio del nivel. Radio de referencia del proyecto: auto-aim del spray 250, gato 300, fight 250 (Ago 2026: bajado de 400 para que el enemigo esté en pantalla cuando suena; ⚠️ el charge_range de la rata es 260, la música entra justo al amagar la embestida).

---

## 🔴 GOTCHA #29: HTML5 — sin sonido hasta el primer gesto del usuario (autoplay)

**Síntoma (Agosto 2026):** al abrir el juego en el navegador, no se oye NADA (ni la música de la intro cinemática ni el menú) hasta que el usuario hace clic/toca la página. No es un bug del audio_manager: `sound.play()` se ejecuta (el fade, el loop y los estados del manager funcionan), pero el navegador no reproduce nada.

**Causa:** política de autoplay del navegador (Chrome/Safari/Firefox). El `AudioContext` nace en estado `suspended` y solo se reanuda tras un gesto del usuario (clic, toque, tecla). El motor de Defold lo crea internamente; la llamada a `sound.play()` en `init()` queda "en cola" hasta que el contexto se reanuda. Cita de Mathias Westerdahl (Defold): *"It is part of the standard, that sounds don't autostart on web pages before the user interacts with the page."* (forum.defold.com/t/no-autostart-sound-on-html5/77052).

**Impacto real en este juego:** el flujo ya exige un primer clic (botones Continuar/Nueva partida del menú), así que el audio se desbloquea a más tardar en ese gesto. Lo único que se pierde es la **música de la animación cinemática** (primeros ~6 s, `start_1`) si el jugador aún no ha interactuado; el menú (`calm_1` loop) se oye desde el primer clic.

**Opciones si algún día se quiere oír la intro completa (NO implementado, decisión Ago 2026):**
- Overlay "Toca para jugar" que exige el gesto ANTES de arrancar la animación (mismo patrón que `waiting_landscape` de la intro: pausar la animación de verdad, no solo taparla — el overlay de rotación enseñó que la animación corre por detrás).
- El gesto desbloquea el contexto para TODA la sesión; no hace falta tocar nada del audio_manager.

---

## 🔴 GOTCHA #30: HTML5 — la `<meta>` COOP NO funciona en Chrome (solo cabeceras HTTP reales)

**Síntoma (Agosto 2026):** el comentario de `assets/custom_template.html` afirma que los `<meta http-equiv="Cross-Origin-Opener-Policy">` / `<meta http-equiv="Cross-Origin-Embedder-Policy">` habilitan `SharedArrayBuffer` → motor pthread → sonido con hilos. Pero al servir el juego por el **servidor local** (Java, :43887), `crossOriginIsolated === false` y `typeof SharedArrayBuffer === "undefined"` → el build `wasm_pthread-web` degrada a **single-thread en silencio**. Además, `game.project` configura `sound.use_thread = 1` y el motor registra en el navegador `SOUND: useThread: 0`.

**Causa:** Chrome **ignora `Cross-Origin-Opener-Policy` en `<meta>`** — COOP solo puede establecerse por **cabecera HTTP real** (no existe equivalente en meta; COEP sí se respeta por meta, pero COOP no). Sin AMBAS cabeceras reales (`COOP: same-origin` + `COEP: require-corp`), el navegador no aísla el contexto (`crossOriginIsolated = false`) → sin `SharedArrayBuffer` → el motor no puede lanzar hilos y degrada sin avisar.

**Verificación empírica (Agosto 2026, con el build real):**
- Servidor local (solo cabeceras `Content-type`/`Content-length`): `crossOriginIsolated = false`, sin `SharedArrayBuffer`. ✅
- Mismo build servido con cabeceras HTTP reales (COOP + COEP): `crossOriginIsolated = true`, `SharedArrayBuffer` disponible. ✅
- Con cabeceras reales el motor SIGUIÓ registrando `useThread: 0` en headless → la activación del sonido con hilos depende de más factores (build del motor, contexto de audio válido), no solo de las cabeceras. No asumir que con SAB disponible `useThread` pasa a 1.

**Matices / lecciones:**
1. El comentario del template **confunde contexto seguro (HTTPS)** con **cabeceras COOP/COEP**: GitHub Pages cumple el primero pero **no envía las segundas por defecto** (no permite cabeceras personalizadas; habría que poner Cloudflare/Netlify u otro proxy delante). En `http://IP:8080` sin HTTPS ni siquiera el contexto seguro se cumple.
2. Para activar el motor con hilos de verdad hay que servir el build con **ambas cabeceras HTTP** desde un servidor que permita configurarlas (`python3 -m http.server` NO sirve; un proxy Node/Nginx/Netlify sí).
3. **Consecuencia práctica hoy:** en el servidor local el juego corre single-thread. Es el modo más compatible, pero `sound.use_thread = 1` de `game.project` no se aplica en el navegador mientras no se sirvan las cabeceras reales.

---

## 🔴 GOTCHA #31: `go.animate()` NO puede animar `position.z` de un COMPONENTE (sprite) — hay que mover el game object

### El problema

El `position` (y sus componentes `position.x/y/z`) es una propiedad del **game object**, no de los componentes. Animar `position.z` de un componente sprite con `go.animate()` falla en runtime:

```
ERROR:SCRIPT: features/furniture/office_cabinet.script:80: '[level_01:/office_cabinet#sprite_office_cabinet]' does not have any property called 'position.z'
```

Sí funciona en cambio animar propiedades **propias del componente** (ej: `tint` de un sprite, como hacen `doors.script`/`bookcase.script`).

**Caso real (Agosto 2026):** el armario (`office_cabinet.script`) debía bajar su puerta de z=0.2 a z=0.01 al abrirse (para revelar objetos interiores en z=0.1). El primer intento animó `position.z` del sprite → error en runtime al primer clic (hover/tint funcionaban, solo fallaba el z).

### La solución: mover el GAME OBJECT, con el sprite a z local 0

1. **En el `.go`:** poner el sprite a `position { z: 0 }` (su z en pantalla pasa a ser la del game object).
2. **En el script:** animar el id del propio game object:

```lua
-- ✅ CORRECTO: animar el .go (position es propiedad del game object)
go.animate(go.get_id(), "position.z", go.PLAYBACK_ONCE_FORWARD, Z_OPEN, go.EASING_OUTQUAD, 0.15)

-- ❌ ERROR en runtime: position.z no existe en el componente sprite
go.animate("#sprite_office_cabinet", "position.z", go.PLAYBACK_ONCE_FORWARD, Z_OPEN, go.EASING_OUTQUAD, 0.15)
```

3. **En `init()`:** fijar el z de cerrado del game object (`go.get_position()` + `pos.z = ...` + `go.set_position(pos)`), porque la instancia de la colección arranca en z=0 y sin eso el armario cerrado no ocultaría el interior.

> ✅ **Referencia en el propio proyecto:** `features/furniture/office_cabinet.script` — sprite del `.go` a z local **0.01** (nunca en z=0: a 0 no se renderiza → invisible).
>
> 🗄️ **Simplificado (Ago 2026):** el armario ya **no anima su z** — mantiene una z **estable definida en el editor** (colección z 0.19 → sprite en pantalla 0.20, delante del jugador en z 0.1; antes el go se animaba entre `GO_Z_CLOSED = 0.19` y `GO_Z_OPEN = 0.00`, lo que hacía que con la puerta abierta el personaje quedara por encima del armario). La ocultación del interior pasó a ser por **activación**: `office_cabinet.script` notifica `cabinet_state.set_open()` en el callback del flipbook (cuando la animación de apertura/cierre FINALIZA), y los objetos interiores (botes de spray/insecticida a z 0.22, por encima) consultan `cabinet_state.get_open(pos)` en su `update()` y se activan/desactivan (sprite + colisiones off → sin hover ni clic posibles). Los botes fuera de armarios están siempre activos.

> ⚠️ **Regla de z mínima:** un sprite en `z=0` puede no renderizarse (oculto tras el fondo/suelo en 0 por depth test). Mantener siempre los sprites del mundo en `z ≥ 0.01` tanto en el `.go` como en runtime.

### Cuándo aplicar

- Cualquier reposicionado/animación de z (o x/y) de un sprite u otro componente en runtime: usar siempre `go.animate`/`go.set_position` sobre el **game object**, no sobre el componente.
- Recordar que el z local del componente en el `.go` se SUMA al del game object: si el componente tiene un offset propio, hay que compensarlo (o ponerlo a 0) para que los valores animados sean los reales en pantalla.

> 🖱️ **Aplicación — el picking de interacción también debe ser z-aware (Ago 2026):**
> como la física es 2D (ignora z) y el z es el mecanismo de ocultación, un objeto
> oculto tras un armario cerrado seguía recibiendo hover/clic (el bote de spray a
> z 0.1 dentro del armario a z 0.19 era "el más cercano" al cursor). Regla: un
> objeto ocultado por z nunca debe ganar un pick de interacción — el z ES la
> visibilidad. Pero el criterio de selección difiere por selector:
>
> - **`main/cursor.script` (clic con ratón): z-first** — gana el de MAYOR z (el
>   frontal según el depth test), con la distancia solo como desempate a z igual.
>   El cursor es un punto preciso: apuntar a una puerta nunca solapa su caja con
>   la de un slot, así que el z-first no causa colisiones falsas.
> - **`features/player/mobile_interact.script` (sensor táctil ~180×180 — data
>   90,90,10 en `player.go`, cubre el rango global `interaction_range`=80):
>   FACING-FIRST** — gana el candidato más ALINEADO con la dirección de movimiento
>   del jugador (`aiming.state.facing_dir`, la última dirección, conservada al
>   parar); la distancia solo desempata a igual alineación y el z a igual
>   distancia. Sin facing (nunca se movió) → el más cercano. ⚠️ La distancia GO-a-GO
>   falla: un armario en el muro (GO 54 uds por encima del pasillo) pierde SIEMPRE
>   contra las puertas adyacentes aunque el jugador esté pegado a él, y entre dos
>   puertas simétricas solo gana la más cercana al cruce. Facing-first resuelve
>   ambos: andar hacia el objeto lo selecciona. Filtros del sensor: candidatos
>   cubiertos por un armario CERRADO (`cabinet_state.is_covered(pos, url)` — ⚠️
>   con el url del candidato: el GO del armario está dentro de su PROPIA caja, y
>   sin excluirla el armario cerrado se autoexcluiría del sensor, nunca
>   seleccionable en móvil) y armarios ABIERTOS con contenido
>   (`cabinet_state.is_open` + `has_candidate_inside` — el bote interior activado
>   es el objetivo; al recogerlo el armario vuelve a ser elegible). El caso
>   slot↔puerta queda cubierto: andar a la puerta la selecciona (slot a z 0.16
>   queda en el lateral).
>
> ⚠️ **El hover también (Ago 2026):** el cursor envía `mouse_hover` a TODOS los
> objetos solapados, así que el bote tapado mostraba su alerta persistente con el
> armario cerrado. Modelo actual (simplificado): `main/cabinet_state.lua` registra
> armarios con caja de cobertura + estado abierto/cerrado; `office_cabinet.script`
> registra su caja (coincide con su collisionobject_cursor: BOX 32.5×37.5 en y=+2
> local, escalada por el scale del GO — actualizar si se redimensiona; Ago 2026
> quedó corregida la desincronización con 32.5×27.5 en y=-7, que dejaba la banda
> superior del armario sin cobertura de ocultación) y notifica `set_open` al FINALIZAR cada
> animación; el objeto interior consulta `get_open(pos)` en su `update()` y se
> DESACTIVA (sprite + colisiones off) dentro de un armario cerrado → la física
> 2D ya no lo detecta: ni hover, ni clic, ni alerta. `is_covered()` queda como
> defensa genérica del sensor móvil (excluir candidatos tapados). Cualquier
> objeto interior futuro debe usar el mismo patrón `get_open` + desactivación.
>
> **El picking móvil puntúa contra el PUNTO DE INTERACCIÓN, no contra el GO
> (Ago 2026):** el sensor móvil mide dot/distancia desde el CENTRO de la caja
> cursor (el punto donde se interactúa), no desde el GO — los GOs no
> representan dónde se interactúa. `doors.script` registra su punto por tipo
> (`door_side` +27 en x, `door_front` −10 en y, `door_service` −5 en y — debe
> coincidir con el collisionobject_cursor del .go) en `main/interactable_box.lua`;
> los armarios lo exponen vía `cabinet_state.get_center()`. Sin esto, un GO
> desplazado de su caja deja la puerta "detrás" del jugador cuando este se
> apoya en ella (dot negativo) y facing-first elige cualquier candidato
> alineado con su dirección — caso real: `door_side4` (GO en 840, caja en
> 867) ↔ `office_cabinet1` (921,1044); el armario ganaba aunque la puerta
> estuviera a 8 uds y el armario a 91.
>
> **Rango de interacción GLOBAL (Ago 2026, unificado):** antes cada objeto
> tenía su propio gate por distancia (NPCs 100, botes de spray/comida 200,
> ME_*/puertas/armarios… sin gate — el cursor de escritorio interactuaba con
> cualquier cosa visible en pantalla). Ahora hay UN rango global
> (`M.balance.interaction_range = 80`, main/config.lua) aplicado en los DOS
> hubs — `cursor.script` (enter + clic) y `mobile_interact.script` (filtro de
> candidatos) — midiendo desde el jugador al PUNTO DE INTERACCIÓN
> (`interactable_box.world_point()`: punto registrado → centro de armario →
> GO). Se retiraron los gates por-objeto (npc.script, spray_can,
> food_cat_can). ⚠️ Acoplamiento con el editor: el sensor táctil de
> `player.go` (data 90,90,10 = 180×180) debe cubrir ~2× el rango — ajustar a
> mano si cambia. Y si se cambia la caja de una puerta, actualizar también
> `INTERACT_OFFSET` en `doors.script` (el punto se re-registra solo en cada
> init). El sensor se amplió de 120×120 a 180×180 para que el rango efectivo
> móvil (80) coincida con el de escritorio (antes 60 vs 80/100/∞ —
> incoherente).

---

## 🔴 GOTCHA #32: los GUI con muchos nodos no deben gestionar `set_enabled` con listas manuales — nodo raíz + `gui.get_tree()`

> ⚠️ **Corregido (Agosto 2026) tras verificar el código fuente del motor** (`engine/gui/src/gui.cpp`): la versión anterior de este GOTCHA afirmaba que `set_enabled` "no se propaga a los hijos". Eso es **falso para el render** — ver el modelo real abajo. El problema y la solución (nodo raíz + `gui.get_tree()`) se mantienen; solo cambia el *porqué*.

### El modelo REAL del motor (verificado en `gui.cpp`)

| Aspecto | Comportamiento | Evidencia en el código fuente |
|---|---|---|
| **Render** | Deshabilitar un padre **SÍ oculta a todo su subárbol** (la recolección de nodos a dibujar solo desciende a los hijos dentro del bloque `if (n->m_Node.m_Enabled)`) | `CollectRenderEntries()` — la recursión `CollectRenderEntries(scene, n->m_ChildHead, ...)` está dentro del `if (enabled)` |
| **Animaciones** | Se pausan si **cualquier ancestro** está deshabilitado | `IsNodeEnabledRecursive()` usada en el paso de animaciones |
| **Flag `enabled`** | Es **por nodo**: `gui.is_enabled(node)` devuelve el flag propio, sin mirar al padre (solo con `recursive=true` sube por la cadena de ancestros) | `IsNodeEnabled(scene, node, recursive)` |
| **Picking** | `gui.pick_node()` es **geométrico puro**: NO comprueba `enabled` ni `visible` → un nodo oculto sigue siendo "pickable" | `PickNode()` — solo transform inverso + bounds (confirmado por AGulev, equipo Defold, foro 2026) |
| **`visible`** | Por nodo, **no** se hereda: un padre con `visible: false` NO oculta a sus hijos | `IsVisible()` comprueba solo `n->m_Node.m_IsVisible` |
| **`alpha`** | Se hereda SOLO con `inherit_alpha` activado (multiplicación de opacidad) | cálculo de opacidad por nodo en el render |
| **Adjust mode** | Un nodo hijo ajusta contra la escala ajustada del **padre** → el root debe tener el tamaño de la referencia, NO 0×0 | `m_LocalAdjustScale` del padre usado en el cálculo |

### El problema (real)

Un menú con N nodos obliga a listarlos TODOS en cada toggle de visibilidad, y cualquier nodo nuevo añadido en el editor queda **visible por defecto** si no se añade a mano a cada lista del script. Además, `gui.pick_node()` es geométrico: aunque el render se oculte (cascada por padre), un nodo deshabilitado por su padre sigue siendo pickable — por eso los handlers de input se gatean además por el estado del script (`self.is_paused`, `self.is_visible`, etc.).

**Caso real (Agosto 2026):** al añadir `box_logo` y `text_name` a `pause.gui` aparecían visibles al arrancar — `pause.gui_script` los ocultaba/mostraba uno a uno en `init()`/`show_pause()`/`hide_pause()`, y los nodos nuevos no estaban en ninguna lista.

### La solución: nodo raíz invisible + recorrer el árbol con `gui.get_tree()`

1. **En el `.gui`:** crear un nodo raíz `pause_root` (box invisible: tamaño = resolución de referencia y `alpha: 0`) y colgar TODOS los nodos top-level de él (`parent: "pause_root"`).
2. **Quitar `inherit_alpha` de los hijos** (si el root tiene alpha 0 y los hijos heredan alpha, se volverían invisibles).
3. **En el script**, un helper que recorre el árbol con `gui.get_tree()` (disponible desde Defold 1.4.8):

```lua
local function set_tree_enabled(root, enabled)
	if not root then return end
	for _, node in pairs(gui.get_tree(root)) do
		gui.set_enabled(node, enabled)
	end
end
```

4. **Alternar todo el menú con una sola llamada** en `init`/`show`/`hide`. Cualquier nodo nuevo añadido bajo `pause_root` en el editor queda cubierto automáticamente, sin tocar el script.

> ✅ **¿Por qué recorrer el árbol si el render ya cascada?** Porque `set_enabled` sobre el root solo oculta el render (y pausa animaciones); el **flag por nodo** sigue en `true` y el **picking geométrico** sigue devolviendo el nodo. Recorrer el árbol deja TODOS los flags en el estado correcto (reset limpio al reabrir: nada queda "colgado" de un estado previo) y garantiza el comportamiento completo: no render, no animación, no picking.

> ✅ **Referencia en el propio proyecto:** `gui/pause.gui` + `gui/pause.gui_script` — `pause_root` (box 1280×768, alpha 0), 23 nodos colgados de él, y `set_tree_enabled()` usado en `init`/`show_pause`/`hide_pause`. Detalle: el desplegable de idioma arranca cerrado → tras habilitar el árbol en `show_pause`, se vuelven a desactivar sus hijos (`lan_header_bg`, `lan_option_01`, `lan_option_text`).

> ✅ **Aprovechando la cascada:** los globos de diálogo de `interactive.gui` (`balloon_npc_container`/`balloon_player_container`) ocultan bien a sus hijos con `set_enabled` sobre el contenedor — el render del subárbol sí se oculta con el padre.

### Cuándo aplicar

- Cualquier GUI con un grupo de nodos que se muestre/oculte como bloque: estructura de nodo raíz + `gui.get_tree()`.
- Antes de añadir un nodo nuevo a un GUI gestionado con listas explícitas de `set_enabled`: valorar migrar a la estructura de raíz para que el nodo se cubra solo.

---

## 🔴 GOTCHA #33 — Los callbacks de `game_state` se ELIMINAN si lanzan un error

**Problema (Ago 2026):** `game_state.notify_callbacks` envuelve cada callback en `pcall` y, si uno lanza un error, lo **elimina permanentemente** de la lista (diseñado para limpiar callbacks de componentes descargados, ver FIX en game_state.lua). Consecuencia real: el callback de idioma del HUD moría en la PRIMERA invocación → `text_period_label` (que solo se refrescaba en el callback) dejaba de responder, mientras `text_skills`/`text_tasks_total` seguían bien porque `update_texts` los refresca cada 0.1 s.

**Causa raíz (encontrada, ver GOTCHA #34):** el callback del HUD llamaba `gui.set_text`/`gui.set_enabled` directamente. Pero los callbacks de `game_state` se ejecutan SÍNCRONOS dentro del stack del script que llamó `set_global` (p. ej. `pause.gui_script` al cambiar de idioma) → la escena GUI activa es la de la pausa y usar nodos del HUD lanza `Node used in the wrong scene`. No era un error transitorio: ocurría SIEMPRE en el primer cambio desde la pausa.

**Solución adoptada (hud.gui_script, Ago 2026):** el callback YA NO toca gui — solo hace `msg.post(self.self_url, "language_changed")` y el `on_message` del HUD (que corre en la escena GUI correcta) hace el refresco completo. Los mensajes SÍ atraviesan `set_time_step` (ver MOBILE_CONTROLS_PLAN) → refresco instantáneo incluso durante la pausa. Como red de seguridad se mantiene el **polling en `update_texts`** que detecta el cambio de `game_state.get_global("language")` contra `self._lang` cacheado (mismo patrón que `temp_units` y `fps_overlay`); el callback ya no fija `self._lang`, así que el polling siempre puede detectar la diferencia aunque el mensaje se pierda o el callback muera.

**Regla:** un callback de `game_state` NO debe tocar gui (GOTCHA #34); los refrescos dependientes del idioma deben vivir en `on_message`/`update` del componente, replicados con polling en el bucle de actualización si necesitan ser fiables.

---

## 🔴 GOTCHA #34 — Un callback de `game_state` NO puede tocar gui (escena GUI equivocada)

**Problema (Ago 2026):** los callbacks registrados con `game_state.register_callback` se ejecutan de forma **síncrona dentro del stack del script que llamó `set_global`** — no en el contexto del componente que los registró. Si ese script es un GUI (p. ej. `pause.gui_script` al cambiar el idioma), la **escena GUI activa** durante el callback es la del script llamador. Cualquier `gui.set_*`/`gui.get_node` sobre nodos del componente registrador lanza `ERROR: ... Node used in the wrong scene`.

**Caso real (hud.gui_script):** el callback de idioma llamaba `refresh_period_label` → `gui.set_text(self.period_label, ...)` → `Node used in the wrong scene` en el PRIMER cambio de idioma desde la pausa. `game_state` eliminó el callback (GOTCHA #33) y, como `self._lang` ya se había actualizado al nuevo idioma antes del fallo, el polling de `update_texts` tampoco detectó la diferencia → el primer cambio nunca se aplicaba (el segundo sí, vía polling).

**Solución (hud.gui_script):** el callback SOLO hace `msg.post(self.self_url, "language_changed")`. Los mensajes entre componentes **sí atraviesan `set_time_step`** (ver MOBILE_CONTROLS_PLAN), así que el `on_message` del HUD (que corre en la escena GUI correcta) hace el refresco completo al instante, incluso con el nivel congelado por la pausa.

**Regla:** los callbacks de `game_state` deben limitarse a actualizar DATOS (tablas, flags) o postear mensajes. Todo `gui.set_*` debe ejecutarse en `init`/`update`/`on_message`/`on_input` del propio componente. Para refrescos dependientes del idioma, además, replica con polling en el bucle de actualización (patrón `temp_units`/`fps_overlay`/`_lang`): así un callback muerto o un mensaje perdido no deja el componente roto.

---

## 🔴 GOTCHA #35 — `reset_all()` reconstruye `M.globals` desde cero: las preferencias creadas en runtime se pierden si no se conservan explícitamente

**Problema (Ago 2026, auditoría):** `game_state.reset_all()` ("Nueva partida") reconstruye `M.globals` con una tabla literal de valores por defecto. Todo lo que NO esté en esa tabla se pierde. El caso silencioso y traicionero: claves que **se crean en runtime vía `set_global`** — `temp_units` ("c"/"f") y `fps_overlay` (overlay de FPS) NO están en la tabla de defaults, así que un `reset_all()` las borraba sin error: el jugador reiniciaba y perdía sus preferencias de unidades de temperatura y overlay FPS (el volumen de efectos `sfx_volume`, que sí está en defaults, también se perdía porque la tabla de reset no lo incluía). El juego seguía funcionando por los fallbacks (`or "c"` / `or false`), lo que hacía el bug invisible: sin errores, solo "preferencias olvidadas".

**Solución (game_state.lua, Ago 2026):** capturar las preferencias ANTES del rebuild y restaurarlas después:

```lua
function M.reset_all()
    -- 🎛️ Preferencias del jugador que NO se reinician con la partida
    local prefs = {
        sfx_volume = M.globals.sfx_volume,
        temp_units = M.globals.temp_units,
        fps_overlay = M.globals.fps_overlay,
    }
    M.globals = { ... }  -- tabla literal de defaults (progreso)
    for k, v in pairs(prefs) do
        if v ~= nil then M.globals[k] = v end
    end
    ...
end
```

**Regla:** en `reset_all()`/`cargar_progreso()`, distinguir PROGRESO (se reinicia) de PREFERENCIAS del jugador (se conservan). Antes de reconstruir `M.globals`, listar explícitamente qué se conserva — y sospechar de cualquier clave que viva fuera de la tabla de defaults (se crea en runtime): es la primera candidata a perderse en un reset.

---

## 🔴 GOTCHA #36 — `print()` crudo en un script imprime SIEMPRE en producción — usar `config.make_log` + toggle local

**Problema (Ago 2026, auditoría):** el proyecto tiene un sistema de log granular (`main/config.lua` → `M.make_log(enabled)` + `M.DEBUG`), pero varios scripts usaban `print()` directo: `main/cursor.script` (3 logs de interacción "🎯 Cursor detectó…"), `gui/interactive.gui_script` (5 logs de quiz/idioma, incluido el `ERROR QUIZ`) y —descubiertos en la revisión posterior de pendientes— **5 scripts de props** (`kit_health`, `kit_stamina`, `food_cat_can`, `spray_can` + 2 restantes de `slot_furniture`, 17 `print()` en total: hints recargados por idioma, restauración de salud/spray/energía, recogida de latas…). Como `print()` no pasa por `M.DEBUG`, **imprimían en consola incluso en builds de producción** — ruido constante y datos de debug expuestos en el bundle final. La auditoría no los detectó con `grep` de acentos (no contienen texto visible) ni con `audit_globals.sh` (no son funciones globales): solo se ven con `grep -rn "print("`. 

> 📋 **Lección de cobertura (Ago 2026):** la primera auditoría convirtió los prints de `cursor`/`interactive` pero se saltó `features/props/` — los 5 scripts de props quedaron logueando en producción hasta la revisión de pendientes. Moraleja: el grep de verificación debe cubrir TODO el árbol (incluido `features/**`), y al auditar un patrón (print → dprint) hay que repetir el grep al final para confirmar que no quedaron archivos por el camino.

**Solución (Ago 2026):** cada script define su toggle local y usa el factory:

```lua
local config = require "main.config"
local DEBUG_CURSOR = false  -- toggle local del archivo
local dprint = config.make_log(DEBUG_CURSOR)
...
dprint("🎯 Cursor detectó interacción (hover) con: " .. tostring(closest_url))
```

Con `DEBUG_X = true` + `M.DEBUG = true` se reactivan para debug; en producción (`M.DEBUG = false`) son silencio total. El `ERROR QUIZ` también pasó a `dprint` siguiendo la convención de `library.gui_script` (los errores también son logs granulares).

**Regla:** en este proyecto, `print()` directo es un anti-patrón. Todo log debe pasar por `config.make_log` (o `config.dprint` global) con su toggle local. Verificación en auditorías: `grep -rn "print(" --include="*.script" --include="*.gui_script" --include="*.lua"` **recorriendo TODO el árbol** (`.`, no solo `main/` y `gui/` — los props viven en `features/`), excluyendo: (1) el `print` de `config.lua` dentro de `make_log` (es el sistema), (2) el `print` de `game_state.lua` que imprime el error de callback (diagnóstico real), (3) los errores de recursos (`text_loader`, `collectibles_data`) y (4) los checks gateados por `config.DEBUG` (GOTCHA #39) y `debug_print` con flag propio (climate_controller). Además de convertir prints, revisar que los toggles `DEBUG_X` estén en `false`: un flag a `true` es inerte con `M.DEBUG = false`, pero activaría todo el logging al depurar cualquier otra cosa (`grep -rn "DEBUG_\w* = true"`).

> ⚠️ **Sub-caso (Ago 2026, despawn de la rata):** si un script que NO tenía logs empieza a usar `dprint` y olvidas el `local dprint = config.make_log(DEBUG_X)` en su cabecera, la llamada cae a la **global** `dprint` (nil) → `attempt to call global 'dprint' (a nil value)` **solo en runtime** al ejecutarse esa línea. `luac -p` y `audit_globals.sh` NO lo detectan (sintaxis válida; no es global en datos). Regla: al añadir el primer `dprint` a un script, verificar que el `make_log` esté declarado ANTES (arriba, junto a los requires) — y si el script no tiene sistema de logs, añadírselo o usar `print` (que al menos no revienta). Búsqueda de verificación: `grep -rln "dprint" --include="*.script" --include="*.gui_script" --include="*.lua"` y comparar contra los que definen `make_log`.

---

## 🔴 GOTCHA #37 — Texto visible construido con literales en un `gui_script`: las ETIQUETAS hardcodeadas sobreviven a la localización aunque los DATOS estén localizados

**Problema (Ago 2026, auditoría):** un panel puede recibir sus **datos** localizados (campos de un catálogo) y aun así mostrar texto en español si las **etiquetas** que preceden a esos campos están hardcodeadas como literales en el script. Es un sub-caso de GOTCHA #20 (texto visible en código) pero más traicionero: el contenido parece localizado porque los campos cambian de idioma, y solo las etiquetas quedan fijas — el bug pasa desapercibido a simple vista.

**Caso real (`gui/exhibition.gui_script`, panel de ficha del objeto):** los campos `description`/`period`/`site`/`dimensions` llegan localizados desde `exhibition_text_{es,en}.lua` (cargado por `exhibition_manager`), pero el panel los precedía con literales en español:

```lua
-- ❌ ANTES: etiquetas hardcodeadas (visibles en cualquier idioma)
local info_text = "Objeto #" .. tostring(matched_object.id) .. "\n\n"
info_text = info_text .. "Descripción: " .. matched_object.description .. "\n"
info_text = info_text .. "Periodo: " .. matched_object.period .. "\n"
info_text = info_text .. "Yacimiento: " .. matched_object.site .. "\n"
info_text = info_text .. "Dimensiones: " .. matched_object.dimensions
-- else: "Dimensiones: No constan"
```

En inglés el jugador veía "Objeto #20 / Descripción: …" — campos en inglés, etiquetas en español.

**Solución (`gui/exhibition.gui_script` + `general_text_{es,en}.lua`, Ago 2026):**

1. **Etiquetas al catálogo general:** nueva sección `M.exhibition` en `general_text_{es,en}.lua` con `label_object`, `label_description`, `label_period`, `label_site`, `label_dimensions`, `no_dimensions` (con espacios finales en los literales para el formato).
2. **Helper de render único:** `render_info_text(self, matched_object)` (local, definida ANTES de `on_message` — GOTCHA #1) construye el texto con `(labels.X or "fallback")` y lo aplica al nodo. Se usa tanto en `display_gui_info` como en el re-render por idioma.
3. **Recarga en caliente con el patrón de GOTCHA #34:** el callback de idioma SOLO recarga las tablas y postea `msg.post(self.self_url, "language_changed")` (no toca gui — escena equivocada); el `on_message` re-renderiza el panel con `self.last_matched_object` si está abierto.
4. **Fallbacks en español permitidos** (`or "Descripción: "`): solo se usan si el catálogo falla; siguen la convención de fallback neutro del resto del proyecto.

**Regla:** al localizar un panel que combina DATOS de catálogo + ETIQUETAS, verificar ambas fuentes por separado. Grep de verificación: buscar los literales sospechosos (`grep -rn '"Descripción: \|Periodo: \|Objeto #' --include="*.script" --include="*.gui_script"`) y, para construcción de texto multilinea con `..`, revisar que TODOS los fragmentos provengan de tablas localizadas o variables — no solo los campos.

---

## 🔴 GOTCHA #38 — Los MÓDULOS `.lua` no deben devolver texto visible: devolver CLAVES neutras y traducir en el GUI (patrón save_manager)

**Problema (Ago 2026, auditoría):** un módulo de lógica (`.lua` puro, sin GUI) que devuelve **strings visibles** rompe la localización igual que un literal en un script: el texto viaja por el código sin pasar por `general_text`, así que se muestra en un solo idioma sin importar el idioma del juego. Es la versión "módulo" de GOTCHA #37, y es más fácil que pase desapercibida: los mensajes se ven correctamente en el idioma de desarrollo y nadie revisa los `return` de un módulo con grep de acentos.

**Caso real (`main/save_manager.lua`, Ago 2026):** `export_save()`/`process_import()` devolvían mensajes en español (`"✅ Partida exportada como .json (descargada en el navegador)"`, `"❌ Error al exportar la partida"`, `"Partida importada correctamente"`, `"No se pudo leer el archivo de guardado"`, `"Error al leer el JSON: …"`) que el menú de pausa mostraba directamente en `text_info` — visibles en inglés igual que en español.

**Solución (patrón adoptado, verificado con Importar/Exportar en runtime):**

1. **El módulo devuelve CLAVES neutras** (identificadores, no texto): `return true, "exported_html5"`, `return false, "export_error"`, `return false, "import_json_error", tostring(err)` (el detalle `%s` —ruta, error— como tercer retorno).
2. **Las claves se traducen en el GUI** con `general_text` → `M.save`:

```lua
-- gui/pause.gui_script (helper local, antes de on_input — GOTCHA #1)
local function resolve_save_msg(self, key, detail)
	local save_txt = (text_loader.load("general", self.current_lang) or {}).save or {}
	if key == "exported_desktop" then
		return string.format(save_txt.exported_desktop or "✅ Partida exportada en: %s", detail or "")
	elseif key == "import_json_error" then
		return string.format(save_txt.import_json_error or "❌ Error al leer el JSON: %s", detail or "")
	elseif key == "exported_html5" then return save_txt.exported_html5 or "…"
	…
	end
	return key  -- fallback: clave sin traducir
end
```

3. **Los estados internos se quedan como están**: códigos como `"retry"`/`"exhausted"` (game_state) o `"PATROL"`/`"IDLE"` (npc_patrol) son decisiones de lógica, NO texto visible — no se traducen.

**Regla:** al auditar localización, distinguir tres tipos de string en un módulo: **texto visible** (→ clave neutra + traducción en el GUI), **estado interno** (→ no se toca) y **diagnóstico de error real** (→ consola vía `print`/`dprint`, no al jugador). Regla rápida: un `return true/false, "…"` cuyo segundo valor acabe en `gui.set_text` o `show_alert` debe ser una clave, no un literal.

---

## 🔴 GOTCHA #39 — Los fallbacks en español de `collectibles_data` ENMASCARAN los objetos nuevos sin traducir: mantenerlos como red de seguridad + verificación de cobertura ES/EN en dev

**Problema (Ago 2026, auditoría):** `collectibles_data.lua` define `name` (objetos) y `display_name` (periodos) en español como **fallback** detrás de los localizados (`general_text` → `inventory.item_names` / `inventory.periods`). El fallback es intencional (red de seguridad si el catálogo falla al cargar) pero tiene un coste oculto: **enmascara los olvidos**. Si alguien añade un objeto nuevo a `collectibles_data` sin traducirlo en `item_names` (ES y EN), el juego en inglés muestra el nombre en español **en silencio** — sin error, sin warning, sin nada que delate el hueco en una revisión de código. El fallback convierte un error de desarrollo en un bug invisible de producción.

**Los consumidores y su prioridad (verificado Ago 2026):**

| Campo | Consumidores | Prioridad |
|---|---|---|
| `M.items[*].name` | `inventory_manager.get_item_name` (L41), `slot_furniture.show_hover_alert` (L244) | `item_names[id]` localizado → **fallback `item_data.name`** |
| `M.periods[*].display_name` | `slot_furniture.show_hover_alert` (L224) | `inv.periods[key]` localizado → **fallback `display_name`** |
| — | `inventory_core.lua` | **NO usa `.name`** (solo `item.period`/`item_id`) |

Con los catálogos ES/EN completos (10 objetos + 5 periodos, claves idénticas verificadas con diff), **los fallbacks son código muerto en el flujo feliz** — solo se alcanzan si falla el catálogo.

**Decisión (confirmada Ago 2026):** mantener los fallbacks (no quitarlos) — quitar la red de seguridad haría que un fallo del catálogo mostrara claves crudas (`pal_bifaz`) o `nil` al jugador, peor que un nombre en español. El problema real (olvido de traducción) se resuelve con una **verificación de cobertura en dev**.

**Solución (`main/inventory_manager.script`, Ago 2026):** función local `check_localization_coverage()` llamada en `init` tras cargar textos:

```lua
-- 🔍 Solo dev: config.DEBUG gatea la función entera
local function check_localization_coverage()
	if not config.DEBUG then return end
	local function check(catalog, labels, what)
		for key in pairs(catalog) do
			if not labels[key] then
				print("[Localization] ⚠️ FALTA TRADUCCIÓN de " .. what .. " '" .. tostring(key) .. "' en general_text (ES o EN)")
			end
		end
	end
	for _, lang in ipairs({ "es", "en" }) do
		local general = text_loader.load("general", lang) or {}
		local inventory = general.inventory or {}
		check(collectibles_data.items, inventory.item_names or {}, "objeto")
		check(collectibles_data.periods, inventory.periods or {}, "periodo")
	end
end
```

**Reglas:**
1. **Fallbacks en español = red de seguridad, no contrato**: mantenerlos está bien (protegen ante fallo del catálogo), pero todo texto visible en un idioma concreto debe tener su versión localizada accesible SIEMPRE en el flujo feliz.
2. **Añadir un fallback español a un dato nuevo obliga a un check de cobertura**: si el fallback puede enmascarar un olvido, la cobertura (catálogo localizado ⊇ catálogo de código, ES y EN) debe verificarse en dev — idealmente con la misma función, extendiéndola a la categoría nueva.
3. **El check usa `print()` a propósito**: es un diagnóstico de desarrollo que debe verse independientemente de los toggles granulares de `make_log`; el gate real es `config.DEBUG` (caso distinto de GOTCHA #36, que es sobre ruido en producción).
4. **Verificación de cobertura con `for` en ambos idiomas**: cargar `general` en `"es"` Y `"en"` explícitamente — el fallback a español de `text_loader` enmascararía también el check si solo se mirara el idioma actual.

## 🔴 GOTCHA #40 — En un archivo `.go` los componentes embebidos usan ESCAPES SIMPLES (`\n`, `\"`) en `data`, no dobles (`\\n`, `\\\"`) — el escape doble solo vale dentro de un `.collection`

**Problema (Ago 2026, sistema de nidos):** al crear `features/enemies/nest.go` con un
`embedded_components` de tipo `collisionobject`, el `data` se escribió con escapes DOBLES
(`\\n`, `\\\"`) porque el patrón que se tenía delante venía de un `.collection` (donde el texto
embebido está anidado en una capa extra de escape). Resultado al cargar el proyecto:

```
The file "/features/enemies/nest.go" could not be loaded:
Invalid embedded component 'collisionobject' of type 'collisionobject'
```

**Por qué:** en un `.collection`, el `data` de un `embedded_instances` es una string que a su vez
contiene el texto del `.go` embebido → necesita doble escape. En un archivo `.go` real, el
`data` de un `embedded_components` es texto plano de protobuf → escapes SIMPLES.

**La solución:** reescribir el `data` con escapes simples, idéntico al patrón de `spray_can.go`
(referencia válida del proyecto):

```
-- ✅ CORRECTO en .go (como spray_can.go / food_spawn_container.go)
embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_TRIGGER\n"
  "mass: 0.0\n"
  "group: \"spawn\"\n"
  ...
  "}"  →  ojo: el cierre es "" (string vacía), no "}"  ← NO, ver regla abajo
}
```

**Reglas:**
1. **Copiar el patrón de un `.go` existente del proyecto, nunca de un `.collection`**: si el
   `data` necesita escapes, el archivo de referencia correcto es un `.go` (p. ej.
   `spray_can.go` para collisionobjects, `food_spawn_container.go` para factories).
2. **El último fragmento del `data` es `""` (string vacía)**, no `"}"` — el bloque `{...}` del
   protobuf ya se cierra con la última línea escapada (`"}\n"` o similar) y el `embedded_components`
   se cierra con `}` a nivel del .go.
3. **Verificación rápida de sanidad**: contar backslashes en el archivo nuevo vs el de
   referencia (`grep -c '\\' nest.go spray_can.go` → el mismo número es buena señal).
4. **El editor es la prueba final**: si el error "Invalid embedded component" persiste, el
   archivo no carga ni compila — revisar `luac -p` no sirve (los `.go` no son Lua).

## 🔴 GOTCHA #41 — `ERROR:PHYSICS: Trigger overlap capacity reached`: la capacidad de overlaps por TRIGGER es limitada (default 32) y un sensor grande la desborda en zonas densas

**Problema (Ago 2026, rango de interacción):** al ampliar el sensor táctil del jugador de 120×120 a 180×180 (para cubrir `interaction_range = 80`), la sala de exposiciones (ME_* a ~45 uds entre sí, + slots, puertas, armarios, NPCs…) superó la capacidad de solapes de UN solo trigger: el motor dejó de almacenar enter/exit de los solapes sobrantes → `ERROR:PHYSICS` en consola y **objetos que el sensor deja de detectar** (desaparecen del `nearby` de `mobile_interact.script` sin error visible en el juego).

**Por qué:** la capacidad es **por collision object de tipo TRIGGER** (no global). El sensor es UN trigger cuyo box solapa simultáneamente todos los interactables a su alrededor; en zonas densas supera el límite. El cursor de escritorio no sufre el problema (box pequeño → 1-3 solapes).

**La solución (`game.project`, verificado en foro de Defold, DEF-1520):** la capacidad es configurable desde Defold 1.2.103:

```
[physics]
trigger_overlap_capacity = 128
```

**Reglas:**
1. **La capacidad se configura por proyecto (`game.project` → `[physics]`), no por objeto**: subirla a 128 da margen para el sensor 180×180 en las zonas más densas; el coste de memoria es despreciable (arrays por trigger).
2. **Un trigger grande + zonas densas = revisar la capacidad**: si el sensor o el rango vuelven a crecer, o se añaden muchos interactables nuevos, el error reaparecerá — es el síntoma de "el trigger solapa más objetos de los que puede recordar".
3. **El error no rompe el juego, pero degrada en silencio**: los solapes no almacenados no generan enter/exit → el móvil deja de ver objetos sin ningún error en el flujo de juego (solo el ERROR:PHYSICS en consola).
4. **Acoplamiento con el rango de interacción**: `interaction_range` (config.lua) ↔ sensor en `player.go` (data 90,90,10 = 180×180) ↔ `trigger_overlap_capacity` — los tres se ajustan juntos.

## 🔴 GOTCHA #42 — La sonda de espacio libre de la patrulla usa los SEMIEJES REALES de cada entidad: cambiar la caja de colisión de un NPC/gato sin actualizar `patrol.init` desajusta la navegación en silencio

**Problema (Ago 2026, space check de `npc_patrol.lua`):** la sonda que mide el hueco libre
antes de cada tramo (`probe_free_distance`) dispara 3 rayos paralelos (centro + los 2 bordes
del cuerpo) contra `walls`. Inicialmente los rayos laterales usaban constantes de módulo
fijas a la caja de los NPCs (**11×15** → semiejes 5.5/7.5). El **gato** patrulla con el MISMO
módulo (`cat.script` → `patrol.update`), pero su `collisionobject_walls` es una caja
**25×25** (semieje 12.5). Resultado: la sonda le medía huecos **optimistas** (±7.5) que su
cuerpo real (±12.5) no atravesaba → el gato podía engancharse en huecos justos (puertas,
recovecos) donde los NPCs sí pasaban, sin ningún error visible.

**Por qué:** la sonda mide el ancho del hueco con los bordes del cuerpo; si los semiejes son
menores que los reales, un hueco que "cabe" según los rayos no cabe según el collider. La
colisión reactiva (`contact_point_response`) lo rescata igualmente, pero con micro-choques
repetidos (el síntoma de "enganchado").

**La solución (parametrización por entidad):** `patrol.init(self, spawn_pos [, half_x, half_y])`
guarda los semiejes en `self.npc_half_x/half_y` (default: caja NPC 5.5/7.5). El gato pasa los
suyos desde `cat.script` con la constante `CAT_BODY_HALF = 12.5` (caja 25×25 de `cat.go`):

```lua
-- ✅ CORRECTO: el gato mide con su cuerpo real
patrol.init(self, self.spawn_pos, CAT_BODY_HALF, CAT_BODY_HALF)
```

**Reglas:**
1. **Los semiejes deben coincidir con la caja de colisión contra paredes** (`collisionobject_walls`
   de `npc_XX.go` / `cat.go`): si se cambia esa caja, actualizar la llamada a `patrol.init`
   (o el default en `npc_patrol.lua`). Hay un aviso ⚠️ en los comentarios de ambos archivos.
2. **El desajuste no da error**: es una degradación silenciosa de la navegación (huecos
   medidos optimistas → enganchones en huecos justos). Detectarlo requiere probar en runtime
   con `DEBUG_PATROL`.
3. **Solo afecta al estado PATROL** (`npc_patrol.lua`): CHASE/ATTACK/PET del gato usan
   `cat_nav.lua` (esquive con sus propias sondas fijas), y el seguimiento por estela no
   hace raycasts de pared.

---

## 🔴 GOTCHA #43 — La máscara del raycast debe listar grupos REALES del proyecto: `{ hash("collision_object") }` no golpea NADA (los muros son `walls`)

**Problema (Ago 2026):** las sondas de pared del gato (`cat_nav.lua`) y su línea de visión
(`cat.script` → `has_clear_path` → `has_line_of_sight`) pasaban a `physics.raycast` la máscara
`{ hash("collision_object") }`. **Ningún collision object del proyecto pertenece al grupo
`collision_object`** — los muros son `walls`, y el resto tienen grupos propios (`npcs`,
`enemies`, `spray`, `interactivable`…). Con una máscara sin coincidencias, `physics.raycast`
devolvía `nil`/vacío SIEMPRE → `has_line_of_sight` devolvía `true` incondicionalmente.

**Síntomas observados (el bug que motivó el GOTCHA):**
1. **El gato atacaba enemigos a través de los muros.** En CHASE/ATTACK/PET, `has_line_of_sight`
   siempre era `true` → el gato detectaba (y perseguía/atacaba) a cualquier enemigo a < 300 px
   (o < 250 px del jugador en PET) aunque hubiera una pared entre ambos — el jugador veía al
   gato "golpeando el aire" contra el muro, centrado en un enemigo inalcanzable.
2. **Sondas de esquive inertes (`cat_nav.lua`):** el raycast frontal y las sondas laterales
   nunca detectaban paredes → la escalera de desatasco N1-N4 escalaba solo por temporizador
   sin reaccionar a obstáculos, y el gato empujaba los muros sin esquivarlos.
3. **Atajo directo del rejoin post-combate (`cat.script`):** `has_clear_path` siempre `true` →
   el gato tomaba el atajo directo a T aunque hubiera una pared en la línea (fallback de estela
   inalcanzable), navegando en vano contra el muro.

**La solución (dos partes — ver también GOTCHA #44):**
1. Usar la máscara con el grupo real `{ hash("walls") }`, definido una vez por archivo
   (`RAYCAST_WALLS` en `cat_nav.lua` y `cat.script`) y verificado contra los grupos de los
   `.go` del proyecto.
2. Pasar el 4º argumento `{ all = true }` a `physics.raycast` — **necesario pero no
   suficiente**: con la máscara corregida pero SIN `{ all = true }`, el raycast devuelve los
   campos del hit a nivel superior de la tabla (no una lista) y `ipairs(result)` no itera nada
   → `has_line_of_sight` seguía devolviendo `true` SIEMPRE. **Este segundo bug era el que
   persistía tras corregir la máscara** (Ago 2026: builds nuevos de PC y HTML5 seguían con el
   gato cazando a través de muros).

Con ambas correcciones el gato **ignora a los enemigos sin línea de visión** (no los persigue
ni ataca en vano), el esquive N1-N4 detecta paredes reales y el rejoin solo toma el atajo si el
camino está despejado.

**Reglas:**
1. **La máscara del raycast son GRUPOS del proyecto, no una API**: el formato es
   `physics.raycast(from, to, groups_array)` (GOTCHA #2) — pero `groups_array` debe contener
   grupos que EXISTAN en los `.go`/`.collection` (`walls` para muros). Un grupo inexistente no
da error: el raycast simplemente no golpea nada (degradación silenciosa, difícil de detectar
porque el código no falla).
2. **Antes de confiar en un raycast, verificar los grupos**: `grep -rn 'group: "' --include="*.go"`
   en el proyecto. Si un script asume `collision_object`, `walls` o cualquier grupo, comprobar
   que ese grupo está declarado en los collision objects (o añadirlo).
3. **Corregido (Ago 2026):** `features/npc/npc_patrol.lua` (`RAYCAST_GROUPS`) usaba el MISMO
   patrón roto — máscara `{ hash("collision_object") }` Y sin `{ all = true }` → sus sondas de
   espacio libre (`probe_free_distance`) medían huecos optimistas (sin detectar paredes).
   Corregido con máscara `{ hash("walls") }` + `{ all = true }` junto al gato.

---

## 🔴 GOTCHA #44 — El raycast síncrono sin `{ all = true }` NO devuelve una lista: `ipairs()` no itera nada (LOS siempre true)

**Problema (Ago 2026):** `physics.raycast(from, to, groups)` SIN el 4º argumento `options` es
síncrono pero **no devuelve una lista**: devuelve una tabla con los CAMPOS del hit más cercano
a nivel superior (`result.fraction`, `result.position`, `result.normal`, `result.group`,
`result.id`). El engine solo construye la lista (`{[1]=hit, [2]=hit, …}`) cuando recibe el
4º argumento `{ all = true }` (`list_format` en `script_physics.cpp` de Defold: el formato de
lista se activa únicamente si se pasa el argumento `options`).

Consecuencia: el patrón

```lua
local result = physics.raycast(from, to, { hash("walls") }) or {}
for _, hit in ipairs(result) do   -- ¡nunca itera: result no tiene parte de array!
    if hit.group == hash("walls") then return false end
end
return true                        -- SIEMPRE true
```

**nunca iteraba** → cualquier comprobación de pared devolvía "despejado" SIEMPRE. Este era el
bug REAL que persistía tras corregir la máscara (GOTCHA #43): el gato seguía viendo/atacando
enemigos a través de los muros en builds nuevos de PC y HTML5 (el fix de la máscara era
necesario pero NO suficiente).

**Síntomas:** `has_line_of_sight` (`cat.script` → `has_clear_path`), el raycast frontal y las
sondas laterales de `cat_nav.lua`, y `probe_free_distance` de `npc_patrol.lua` eran todos
INERTES (siempre "despejado"), con o sin máscara correcta. El gato detectaba (y perseguía /
atacaba) enemigos a < 300 px (o < 250 px del jugador en PET) aunque hubiera una pared entre
ambos.

**La solución:** pasar SIEMPRE el 4º argumento a `physics.raycast`:

```lua
local result = physics.raycast(from, to, { hash("walls") }, { all = true }) or {}
for _, hit in ipairs(result) do
    if hit.group == hash("walls") then return false end
end
return true
```

Con `{ all = true }` el resultado es una lista de TODOS los hits ordenados por distancia
(fraction ascendente); sin él, solo se devuelve el hit más cercano (y sin formato de lista).

**Reglas:**
1. **Todo `physics.raycast` que se itere con `ipairs` debe pasar `{ all = true }`** como 4º
   argumento. Sin él, el código "funciona" pero la comprobación es un no-op silencioso (el
   síntoma típico: una línea de visión que siempre ve despejado).
2. **Verificar el formato del resultado antes de asumirlo**: con `{ all = true }` es
   `{{fraction=…, group=…}, …}`; sin él es `{fraction=…, group=…}` (campos a nivel superior).
3. Encadena con GOTCHA #2 (formato de la API) y #43 (la máscara era necesaria pero no
   suficiente) — corrección completa en `features/cat/cat.script`, `cat_nav.lua` y
   `npc_patrol.lua`.

---

*Última actualización: Agosto 2026*
