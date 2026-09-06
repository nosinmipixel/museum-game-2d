# INVENTORY SYSTEM — Análisis Completo

## 1. Visión General

El sistema de inventario/coleccionables es el núcleo de progresión del juego. El jugador debe recoger objetos arqueológicos de distintos periodos históricos (Paleolítico, Neolítico, Bronce, Ibérico, Romano) y guiarlos a través de un **ciclo de vida** de 6 estados hasta que quedan permanentemente exhibidos en vitrinas.

Hay **10 objetos** en total (2 por periodo). El sistema está diseñado para que los objetos aparezcan uno a uno de forma secuencial, ordenados por periodo histórico.

---

## 2. Game Objects Implicados

### 2.1 Core del Sistema

| GO / Archivo | Tipo | Función |
|---|---|---|
| `inventory_manager` (`.go` + `.script`) | GO | Cerebro del sistema. Único punto de entrada. Recibe eventos de botones, muebles y NPCs, y orquesta las transiciones de estado. |
| `inventory_core.lua` | Módulo Lua | Máquina de estados pura (sin dependencias Defold). Define estados, timers, validación de muebles, persistencia. |
| `collectibles_data.lua` | Módulo Lua | Datos estáticos de los 10 objetos: periodo, sprite_id, item_id, si requiere restauración. Incluye `hash_to_str()` para convertir hashes Defold a strings. |
| `game_state.lua` | Módulo Lua | Almacén global. Guarda `inventory_items_status` (tabla `{ item_id = "state" }`) y persiste con `persistence.lua`. |
| `persistence.lua` | Módulo Lua | I/O de bajo nivel: `sys.save()` / `sys.load()`. |

### 2.2 Objetos Interactuables

| GO / Archivo | Tipo | Función |
|---|---|---|
| `collectible_object` (`.go` + `exhibition_object.script`) | GO | El objeto visual que aparece en el mundo. Tiene sprite, collision trigger. Su script (`exhibition_object.script`) maneja hover e interacción para el panel de exhibición. |
| `btn_collectible` (`.go` + `.script`) | GO | Botón de recogida (hijo lógico del collectible_object). Tiene su propio collision trigger y sprite (icono de mano). Al hacer clic, envía `collectible_clicked` al manager. |

### 2.3 Muebles

| GO / Archivo | Tipo | Función |
|---|---|---|
| `slot_shelf` (`slot_shelf.go` + `slot_furniture.script`) | GO | Estantería de **slot único** (1 objeto = 1 slot). Maneja `update_slot`, `clear_slot`, hover con tint (verde/rojo) y alertas persistentes. |
| `slot_showcase` (`slot_showcase.go` + `slot_furniture.script`) | GO | Vitrina de **slot único**. Mismo script que la estantería (`slot_furniture.script`). |

> ⚠️ **Nota histórica (Ago 2026):** los antiguos `furniture.go`/`showcase.go` + `furniture.script` (sistema de muebles con múltiples slots internos) fueron **eliminados** por código muerto — ningún `.go`/collection los referencia. El sistema real usa `slot_shelf.go`/`slot_showcase.go` + `slot_furniture.script`.

### 2.4 GUI

| Archivo | Tipo | Función |
|---|---|---|
| `hud.gui` + `hud.gui_script` | GUI | Heads-Up Display. Muestra: salud, spray, skills, total coleccionables, **estado del objeto activo** (icono + sprite), alertas normales y persistentes (hover). |
| `exhibition.gui` + `exhibition.gui_script` | GUI | Panel informativo al hacer clic en un objeto exhibido en vitrina. Muestra descripción, periodo, yacimiento, dimensiones. |
| `interactive.gui` + `interactive.gui_script` | GUI | Diálogos con NPCs y quizzes. |

### 2.5 Otros Implicados

| Archivo | Función |
|---|---|
| `cursor.script` | Gestiona colisiones del cursor con objetos "interactivable". Envía `mouse_hover` (hover) y `interact` (clic). |
| `screen_utils.lua` | Conversión de coordenadas mundo → pantalla (usado por burbujas y paneles). |
| `text_loader.lua` | Carga textos multi-idioma (es/en). |
| `general_text_es.lua` / `general_text_en.lua` | Textos del sistema de inventario (alertas, errores, notificaciones). |
| `exhibition_manager.script` | Gestiona el panel de exhibición (abrir/cerrar, seguimiento de posición). |
| `main.script` | Inicialización, guardado periódico, tecla R (reset desarrollo). |

---

## 3. Flujo del Sistema (Estados del Objeto)

Hay **6 estados** en el ciclo de vida: PICKUP, COLLECTED, RESTORATION, STORAGE, EXHIBITION y COMPLETED. Cada objeto pasa por este ciclo de vida. Hay **dos flujos** según si el objeto requiere restauración:

**Flujo sin restauración (objetos normales):**
```
[Timer inicial 5s] → PICKUP → COLLECTED → STORAGE → EXHIBITION → COMPLETED
                                              ↕ Timer A (10s)     ↕ Timer B (5s)
                                           (ST→EX)          (cooldown spawn)
```

**Flujo con restauración (objetos con `requires_restoration = true`):**
```
[Timer inicial 5s] → PICKUP → RESTORATION (sin timer) → STORAGE → EXHIBITION → COMPLETED
                                                           ↕ Timer A (10s)     ↕ Timer B (5s)
                                                        (ST→EX)          (cooldown spawn)
```

Hay **TRES timers** en todo el sistema:

1. **Timer inicial (~5s, configurable)**: aparece al iniciar el juego (solo si no hay partida guardada). Da tiempo al jugador a explorar antes del primer objeto.
2. **Timer A — STORAGE a EXHIBITION (10s en pruebas, 300s en producción)**: tras depositar el objeto en la estantería, da tiempo al jugador para hacer otras tareas (quizzes, explorar) antes de que el objeto esté listo para vitrina.
3. **Timer B — Cooldown post-completado (5s)**: tras completar el objeto en la vitrina, da un respiro antes de que spawnee el siguiente objeto.

> ⚙️ **Configuración centralizada (Ago 2026):** los tres timers, el cooldown de los NPCs genéricos, el de la restauradora y los intervalos de los recordatorios del HUD se ajustan desde un único punto: **`main/config.lua` → `M.balance`** (claves `initial_spawn_delay`, `storage_timer_duration`, `spawn_delay`, `npc_cooldown_seconds`, `restorer_cooldown_seconds`, `reminder_new_material`, `reminder_pending_storage`, `reminder_no_exp`, `reminder_restorer_new`, `reminder_restorer_retry`, `reminder_npc_available`). Cada clave documenta su valor sugerido preprod/prod. Los scripts leen con fallback al valor anterior (`or 60`, etc.), así que una clave borrada nunca rompe el juego.

**RESTORATION no tiene timer.** Si un objeto requiere restauración, el estado lo gestiona un NPC restaurador (`on_restoration_completed()`), que avanza a STORAGE instantáneamente — pero ese STORAGE aún **NO está depositado** (el Timer A solo arranca al clicar la estantería): es justo el caso 2 del recordatorio `alert_pending_storage` (ver §4.1), que lo distingue del STORAGE depositado mediante el flag `timer_a_running` del HUD.

### 3.1 PICKUP — El objeto aparece en el mundo

1. `inventory_manager.init()` llama a `spawn_next_item()`
2. `inventory_core.get_next_pending_item()` busca el primer objeto cuyo estado NO sea `COMPLETED`
3. Si no hay estado previo, se establece `PICKUP`
4. El `collectible_object` se posiciona en `SPAWN_POSITION` (545, 201), se actualiza su sprite
5. El `btn_collectible` se posiciona en `BTN_SPAWN_POSITION` (545, 161), listo para clic
6. Se envía alerta al HUD: "¡Nuevo objeto disponible: [nombre]!"
7. Se almacena el periodo del objeto en `game_state.inventory_current_item_period` para que los muebles puedan consultarlo en hover
8. El HUD muestra el estado actual + sprite del objeto en `box_icon_state_container`

### 3.2 Interacción del Jugador — Clic en btn_collectible

1. El jugador mueve el cursor sobre `btn_collectible` → el cursor detecta colisión (`trigger_response`) y envía `mouse_hover` → el botón escala 1.2x
2. El jugador hace clic → `cursor.script` detecta `collision_response` + `self.clicked` → envía `interact` al `btn_collectible`
3. `btn_collectible.on_message("interact")` → envía `collectible_clicked` al `inventory_manager`
4. `inventory_manager.on_collectible_clicked()`:
   - Verifica que el estado actual sea `PICKUP`
   - Si ya no lo está, muestra alerta "ya recogido"
   - Oculta ambos GOs (mueve a `HIDDEN_POSITION` = `(-9999, -9999, 0)`)
   - Cierra panel de exhibición si estaba abierto
   - Calcula el siguiente estado: `calculate_next_state()` (según `requires_restoration`)
   - **Si el siguiente estado es STORAGE, se convierte a COLLECTED.** El estado COLLECTED distingue "recogido" de "depositado físicamente". (Históricamente evitaba que el antiguo contador `text_period_stor_*` — retirado en Ago 2026, ver §6.1 — se incrementara antes del depósito; hoy sigue siendo el estado intermedio del flujo.)
   - Establece el estado (COLLECTED o RESTORATION). El Timer A **NO** se inicia aquí.
   - Notifica al HUD con `update_hud_state`
   - Guarda el estado (`save_inventory_state`)

#### 🔧 Fix en btn_collectible.script — visibilidad tras recogida

Se corrigió un bug donde `btn_collectible` permanecía visible y cliqueable tras recoger el objeto. Causa: `go.set(".", "scale", vmath.vector3(0, 0, 0))` lanza el mismo error de "componentes ≤ 0" que `go.set_scale(0)`. Al crashear el handler, nunca llegaba a `enable_collision(false)`.

**Tres correcciones acumuladas:**

1. **`go.set_scale(0.001)`** — Reemplazado `go.set(".", "scale", (0,0,0))` por `go.set_scale((0.001, 0.001, 0.001))` para evitar el error de "componentes ≤ 0".
2. **`go.cancel_animations(".", "scale")`** — Añadido ANTES de setear la escala en `set_visible`. Detiene cualquier animación de hover activa que pudiera sobrescribir el valor en el siguiente frame.
3. **Guarda `self.collision_enabled` en `mouse_hover`** — Ignora mensajes de hover retrasados (cola de física) que lleguen DESPUÉS de desactivar el botón, evitando que re-animen la escala y re-muestren el botón.

### 3.3 Timers

**Timer inicial (5s, solo al empezar juego nuevo):**
- Se inicia en `inventory_manager.init()`
- Cuenta atrás en `update()`: `self.initial_timer -= dt`
- Al llegar a 0, se llama a `spawn_next_item()` para el primer objeto
- Si el jugador ya tiene partida guardada con objetos en progreso, el timer inicial se salta

**Timer A — STORAGE a EXHIBITION (10s pruebas / 300s producción):**
- Se inicia **exclusivamente** en `inventory_core.transition_to(STORAGE)` cuando el jugador deposita el objeto en la estantería
- **NO se inicia al recoger el objeto** (`on_collectible_clicked` solo establece el estado, sin activar el timer)
- El timer se gestiona desde `inventory_core.update()`, que devuelve `timer_expired` cuando expira
- `inventory_manager.update()` llama a `inventory_core.update(self.core, dt)` cada frame
- Mientras el timer está activo, el `inventory_manager` envía `update_timer_progress` al HUD cada 0.1s (10Hz), que muestra un **pie timer** (relleno circular) y el texto "Para vitrina: MM:SS"
- Cuando expira:
  - `on_timer_expired()` avanza el estado a EXHIBITION
  - Envía `hide_timer_progress` al HUD para ocultar el pie timer
  - Muestra alerta "listo para vitrina"
  - **No inicia Timer B** — eso solo ocurre al completar en vitrina
- **Anti-reclic**: si el jugador vuelve a hacer clic en la estantería mientras el timer está activo, se detecta (`furniture_slots`) y se aplica `in_transit` sin reiniciar el timer

**Timer B — Cooldown tras completar (5s):**
- Se inicia DESPUÉS de que el jugador completa un objeto en la vitrina (acción `"complete"`)
- `inventory_core.start_spawn_timer()` activa el contador
- Cuando expira (`spawn_expired = true`): `on_spawn_timer_expired()` → `spawn_next_item()`
- Separado del Timer A: no interfiere con el flujo de STORAGE → EXHIBITION

### 3.4 Interacción con Muebles (Estantería/Vitrina)

1. El jugador hace clic en un mueble `slot_shelf`/`slot_showcase` → `cursor.script` envía `interact` al mueble
2. `slot_furniture.script` envía `furniture_clicked` al `inventory_manager` con `{ url, furniture_type, period }`
3. `inventory_manager.on_furniture_clicked()`:
   - Convierte la URL y tipo a strings limpios (extrae de `tostring()`)
   - Valida la interacción con `inventory_core.validate_furniture_interaction()`
   - **Acciones posibles:**
     - `"deposit"`: estado COLLECTED o STORAGE + mueble tipo "shelf" + periodo correcto → asigna slot, inicia Timer A, notifica al HUD vía `update_hud_state`
       - **Nuevo depósito (1er clic)**: `state = "storage"` — slot muestra sprite con opacidad total
       - **Re-depósito (re-clic)**: `state = "in_transit"` — slot muestra sprite semi-transparente (como archivo "cortado"), NO reinicia timer
     - `"complete"`: estado EXHIBITION + mueble tipo "showcase" + periodo correcto → marca COMPLETED, envía `clear_slot` a estantería (slot vuelve a `"0000"` vacío), asigna slot en vitrina, inicia Timer B
     - `"wrong_furniture"` + shelf: interceptado en el manager — si el item está en esta estantería, se aplica `state = "in_transit"` (segundo clic para "cortar"). Si no está, muestra alerta "necesita vitrina"
     - `"wrong_period"`: el periodo del objeto no coincide con el del mueble
     - `"invalid_state"`: el objeto no está en un estado que permita interactuar con ese mueble
     - `"no_item"`: no hay objeto activo

**Validación en inventory_core.validate_furniture_interaction() (core puro):**

| Estado | Shelf | Showcase |
|---|---|---|
| COLLECTED | `"deposit"` (si periodo coincide) | `"invalid_state"` |
| STORAGE | `"deposit"` (si periodo coincide) | `"invalid_state"` |
| EXHIBITION | `"wrong_furniture"`¹ (necesita vitrina) | `"complete"` (si periodo coincide) |
| RESTORATION | `"needs_restoration"`² | `"needs_restoration"`² |
| PICKUP | `"invalid_state"` | `"invalid_state"` |
| COMPLETED | `"invalid_state"` | `"invalid_state"` |

> ¹ El manager intercepta `wrong_furniture` + shelf y verifica si el item está realmente en esa estantería. Si sí, lo interpreta como **segundo clic → `in_transit`**. Si no, muestra el mensaje de error estándar.

> ² La pieza aún no ha completado la restauración: el manager muestra el texto localizado `error_needs_restoration` (en lugar del genérico `invalid_state`).

### 3.5 COMPLETED — Objeto exhibido permanentemente

1. Se marca como `COMPLETED` en `inventory_core.save_completion()`
2. Se busca el slot antiguo en la estantería con `find_furniture_slot_for_item()` (devuelve ruta y slot) — **ANTES** de asignar el nuevo slot en vitrina
3. Se envía `clear_slot` a la estantería con `{ slot = slot_number }` — el mueble resetea el sprite a `"0000"` (vacío, invisible), **el tránsito termina**
4. Se asigna un nuevo slot en la vitrina con `assign_furniture_slot()`
5. Se actualiza el slot de la vitrina con sprite + tinte verde claro (`0.8, 1, 0.8`)
6. Se notifica al HUD
7. **Se inicia Timer B (5s)** — cooldown antes del siguiente spawn
8. Cuando Timer B expira → `spawn_next_item()` para el siguiente objeto
9. Cuando todos los objetos están COMPLETED, el sistema muestra "¡Todos completados!" y el HUD oculta el contenedor de estado

### 3.6 Flujo completo de Corte/Pega (Cut/Paste)

El sistema implementa la metáfora de **cortar y pegar archivos** de un explorador de archivos:

```
┌─────────────────────────────────────────────────────────────────────┐
│  1er clic estantería  →  Slot FULL OPACITY ("storage")             │
│        ↓                                                           │
│  Timer expira         →  Estado EXHIBITION, slot sigue full        │
│        ↓                                                           │
│  2º clic estantería   →  Slot SEMI-TRANSPARENTE ("in_transit")    │
│        ↓                    ╔═══════════════════════╗              │
│        ↓                    ║ El objeto está CORTADO║              │
│        ↓                    ║ (visible pero fantasma)║              │
│        ↓                    ╚═══════════════════════╝              │
│  Clic vitrina           →  Slot estantería = "0000" (vacío)       │
│                            Slot vitrina = verde ("completed")     │
└─────────────────────────────────────────────────────────────────────┘
```

**Visualización de estados del slot:**

| Estado | Sprite | Opacidad | Descripción |
|--------|--------|----------|-------------|
| `"empty"` | `"0000"` | 0.3 | Slot vacío, apenas visible |
| `"storage"` | Objeto real | 1.0 | Depósito inicial, visible completo |
| `"exhibition"` | Objeto real | 1.0 | Timer expirado, sigue visible (disponible) |
| `"in_transit"` | Objeto real | **0.25** | Cortado — listo para pegar en vitrina |
| `"completed"` | Objeto real | 1.0 (tinte verde) | Permanente en vitrina |

**Nota:** el segundo clic en la estantería solo funciona si el objeto está realmente depositado en **esa** estantería. Si el jugador clica en una estantería diferente, se muestra "necesita vitrina" porque `find_furniture_slot_for_item()` no encuentra el item en esa estantería.

---

## 4. Cómo se Informa al Jugador a través de la GUI

### 4.1 HUD (`hud.gui_script`)

**Indicador de estado del objeto activo** (`box_icon_state_container`):
- Se muestra en la parte superior de la pantalla cuando hay un objeto activo
- Muestra:
  - El sprite del objeto (`box_icon_state_collectible`, usando atlas `exhibition_clic`)
  - Una flecha (`box_icon_state_arrow`)
  - El icono del estado actual (`box_icon_state`): mano (pickup), restauración, almacén, exhibición
  - **COLLECTED** (recogido sin depositar, Timer A no iniciado) usa el icono de **almacén** (`icon_state_storage`): el objeto va camino del almacén. Sin este mapeo, el HUD mostraba el icono de pickup tras recoger objetos sin restauración (fallback a mano) — corregido Ago 2026
- Se oculta cuando no hay objeto activo o todos están completados

**Pie timer de exhibición** (`pie_timer_to_exhibition` + `text_timer_to_exhibition`):
- Dos nodos en el HUD creados en el editor: un nodo tipo **PIE** y un nodo tipo **TEXT**
- **Ocultos** inicialmente; se muestran solo cuando Timer A está activo (objeto depositado en estantería esperando exhibición)
- El pie se rellena de 360° (lleno) a 0° (vacío) a medida que el timer progresa
- El texto muestra `"Para vitrina: MM:SS"` con el tiempo restante
- Se actualizan 10 veces por segundo (10Hz) mediante el mensaje `update_timer_progress`
- Se ocultan automáticamente cuando: el timer expira, el objeto se completa en vitrina, o se resetea el inventario

**Contador de objetos completados** (`text_items_collected`):
- Cuenta objetos en estado `COMPLETED` desde `inventory_items_status`

**Alertas visuales** (`text_alert`):
- Mensajes temporales de 3 segundos que informan de cada transición:
  - "¡Nuevo objeto disponible: [nombre]!"
  - "Objeto recogido. Dirígete a la Zona de Almacén..."
  - "¡Restauración completada! Deposita el objeto en una estantería."
  - "¡Objeto listo para exhibición! Transfiérelo a una vitrina."
  - "Objeto depositado. Esperando periodo de exhibición..."
  - "¡[nombre] exhibido correctamente!"
  - "Este objeto ya ha sido recogido..."
  - Mensajes de error: periodo incorrecto, mueble incorrecto, estado inválido, **restauración pendiente** (`error_needs_restoration` al clicar un mueble con la pieza en RESTORATION)
  - "¡Exhibido! Preparando siguiente objeto..." (Timer B)
- **🎓 One-shot educativo** (`rule_display_case`): la primera vez que un objeto queda listo para vitrina (EXHIBITION) se muestra "Recuerda que debes ingresar todos los objetos en su correspondiente vitrina". La flag `rule_display_case_shown` persiste en el savegame para no repetirlo.

**Alertas persistentes** (`show_persistent_alert` / `hide_persistent_alert`):
- Se muestran mientras el jugador hace hover sobre un mueble
- No tienen auto-hide — se ocultan al salir del hover
- Muestran: "Estantería: Paleolítico — Periodo correcto ✓" o "Estantería: Romano — Periodo incorrecto ✗"

**⏰ Recordatorios periódicos** (`update_reminders` en `hud.gui_script`):
- Re-muestran una alerta cada X segundos mientras el jugador tenga una acción pendiente sin completar:
  - **`alert_new_material`**: el objeto activo sigue en `PICKUP` (disponible para recogida) sin haberlo recogido
  - **`alert_pending_storage`** (depósito en almacén): el objeto activo está recogido pero **sin depositar** en la estantería — `COLLECTED` (recogido sin restaurar) o `STORAGE` sin Timer A activo (restaurado pero sin depositar; el Timer A solo arranca al clicar la estantería). El flag `self.timer_a_running` del HUD (true en `update_timer_progress`, false en `hide_timer_progress`) distingue el `STORAGE` depositado (timer corriendo) del pendiente de depósito. ⚠️ **Edge guardar/recargar**: el flag es RAM-only y el Timer A no se reanuda al cargar partida (`inventory_core.init` siempre deja `timer_active = false` — comportamiento preexistente). Tras cargar con un objeto en `STORAGE` depositado, el flag queda false y el recordatorio puede avisar de un objeto ya depositado; el re-clic en la estantería reinicia el timer, así que el aviso actúa como nudge que "auto-repara" el flujo
  - **`rule_no_exp`**: el objeto activo está en `EXHIBITION` (listo para vitrina tras el tiempo obligatorio en almacén) sin haberlo expuesto
  - **`alert_new_restoration`** (restauradora, sin quiz hecho): la pieza activa sigue en `RESTORATION`, la restauradora (npc_11) está disponible y el jugador **aún no ha hecho el quiz** (intento actual == 1)
  - **`alert_new_attempt_restoration`** (restauradora, re-intento): la pieza sigue en `RESTORATION`, la restauradora está disponible y el jugador **ya hizo el quiz y falló**, pero le quedan turnos de respuesta (intento actual >= 2). Mientras el cooldown esté activo NO se recuerda (el pie timer ya muestra la cuenta atrás)
  - **`alert_npc_available`** (NPCs de quiz genéricos, re-intento): el jugador falló el quiz de un NPC (npc_01..npc_10), le quedan turnos (attempt >= 2) y el cooldown expiró (`is_npc_available`). Solo reintentos → respeta el libre albedrío del jugador a la hora de elegir NPCs (nunca se avisa de NPCs no elegidos, attempt == 1). El texto es **dinámico**: el nombre localizado del NPC (`main_text → characters`, ya cacheado por `text_loader`) se inserta en el patrón con `string.format` **solo al dispararse** (variante `text_fn` de `run_reminder`), haciendo el aviso accionable ("La Investigadora universitaria está disponible...").
- El intervalo es **configurable por alerta en `main/config.lua` → `M.balance`** (fuente única, Ago 2026):
  - `reminder_new_material = 15` (segundos; 0 = desactivado; ⚙️ PREPROD: 15 · PROD: 180)
  - `reminder_pending_storage = 15`
  - `reminder_no_exp = 15`
  - `reminder_restorer_new = 15`
  - `reminder_restorer_retry = 15`
  - `reminder_npc_available = 15`
  - ⚠️ **Los textos ya NO llevan el tiempo** (las claves `*_reminder_time` se eliminaron de `general_text_[lan].lua`): solo contienen el mensaje. Se eliminó `reminder_default_seconds` (el fallback es la constante local `REMINDER_DEFAULT_SECONDS = 180` en `hud.gui_script` si una clave de balance falta).
- La distinción de la restauradora se hace por **tipo** (Ago 2026): el NPC de quiz de restauración se resuelve con `npc_spawn_state.find_npc_by_type(npc_spawn_state.NPC_TYPE_QUIZ_RESTORATION)` y se consulta su `game_state.get_npc_attempt(...)`: 1 = sin quiz hecho (variante `alert_new_restoration`), ≥ 2 = falló con turnos restantes (variante `alert_new_attempt_restoration`). El de NPCs genéricos itera `npc_spawn_state.npc_types` filtrando `NPC_TYPE_QUIZ_GENERAL` (se excluyen por tipo la restauradora y los NPCs de ambiente `quiz_false`) — sin ids hardcodeados (la propiedad `npc_type` se configura en el editor)
- El contador se reinicia al cambiar el estado (la acción ya no está pendiente)
- 🗣️ **Pausa durante diálogo/quiz** (Ago 2026): mientras el jugador está en una interacción con un NPC (`game_state.dialog_active`, flag en RAM gestionado por el `dialogue_manager` — true en `start_conversation`, false en `end_conversation`/`cancel_dialog`/`final`), los recordatorios se **congelan** (no se disparan ni suenan; se reanudan al cerrar el diálogo desde donde iban) y los avisos puntuales (`show_alert` transitorios) se **encolan** en vez de mostrarse (los `replace` de hover posicional NO se difieren: los re-afirma su emisor). Si el jugador muere durante un quiz, `trigger_death` envía `dialog_cancelled` (cancelación incondicional — el `cancel_dialog` normal está gateado por `not waiting_quiz`) y el respawn limpia el flag por defensa en profundidad
- 🔊 **Aviso sonoro**: cada disparo de recordatorio reproduce `smooth_notification.sound` (componente montado en el objeto `gui` de `level_01.collection`, grupo `sfx` → respeta el slider de efectos del menú de pausa). Se toca desde `run_reminder`, solo al superar el intervalo (nunca por polling). Además, los **avisos puntuales proactivos** pueden pedir el mismo sonido con el flag `alert_sound = true` en el mensaje `show_alert` (el HUD lo reproduce al recibirlo, omitido durante un diálogo/quiz): lo usan el aviso de re-intento de la restauradora (`schedule_restoration_alert`), "¡Objeto listo para exhibición!" (`on_timer_expired` — el Timer A expira mientras el jugador está en otra zona) y "¡Estás agotado!" (`player.script`, polling de stamina). Los avisos reactivos (respuesta a un clic) NO llevan sonido de notificación por diseño
- ⚠️ **Para verlos en preprod**: los recordatorios solo se disparan si la acción sigue pendiente durante el intervalo (15s en preprod). Si juegas activo (recoges/depositas/expones enseguida), el contador se reinicia al cambiar el estado y no verás ninguno — es el comportamiento por diseño.
- El recordatorio de la restauradora complementa al aviso proactivo único del `dialogue_manager` (`schedule_restoration_alert`, timer en RAM que no sobrevive a guardar/recargar) con un aviso persistente por polling (patrón documentado en DEV_GOTCHAS). 🔊 **El aviso proactivo también suena** (Ago 2026): `schedule_restoration_alert` envía `show_alert` con el flag `alert_sound = true`, y el HUD reproduce el mismo `smooth_notification` al recibirlo (omitido si el jugador está en un diálogo/quiz, coherente con la pausa de recordatorios)

**Contadores por periodo** (`box_icon_period_container`):
- 5 iconos (pal, neo, bro, ibe, rom) con **progreso por periodo**: `text_period_exhib_*`
  muestra "exhibidas/total" (p. ej. `1/2`), con el total calculado desde `collectibles_data`
  (2 objetos por periodo; se adapta solo si se añaden objetos).
- La fila `text_period_stor_*` fue **retirada (Ago 2026)** y sus nodos **eliminados del `.gui`**:
  el estado STORAGE es transitorio (0→1→0 al expirar el Timer A) y la pieza se ve físicamente
  en la estantería, así que el contador no aportaba información y parecía un fallo.
- Los contadores se actualizan **por evento** (no por polling) — ver §6.1.

### 4.2 Panel de Exhibición (`exhibition.gui_script`)

- Al hacer clic en un `exhibition_object` (objeto ya en vitrina), se abre un panel con:
  - Imagen del objeto
  - Descripción, periodo, yacimiento, dimensiones
- El panel sigue al objeto en el mundo (actualización de posición cada 2 frames)
- Se cierra al hacer clic fuera, al pulsar ESC, o al alejarse (>100 unidades)
- Se cierra automáticamente al recoger un nuevo objeto (desde `on_collectible_clicked`)

### 4.3 Botón "Reintentar"

- Aparece cuando el jugador muere (mensaje `show_retry_button`)
- Al hacer clic, envía `respawn_player`
- Tiene efectos hover (escala + color)

#### 💀 Mensaje de derrota (discriminado por causa, Ago 2026)

- Al morir, `show_retry_button` muestra también el texto de derrota de
  `general_text_[lan].lua` en `text_alert`, como alerta **persistente** (sin
  timeout): permanece visible hasta que el jugador pulse Reintentar o reaparezca.
- **Causa de la muerte:** `player.script` pasa `cause` en `show_retry_button`
  (registrada en el handler de `taken_damage` desde el campo `source`).
  `cause = "car"` (atropello, `car.script` envía `source = "car"`) →
  `dialogs.car_defeat` ("Deberías prestar atención al tráfico…"); cualquier
  otra / nil (plagas) → `dialogs.fight_defeat`. Fallbacks en cascada en
  `gui/hud.gui_script` (`get_defeat_text`: clave específica → fight_defeat →
  constante); el re-render por cambio de idioma conserva la causa.
- Se oculta al recibir `hide_retry_button` (enviado por `player.script` en
  `trigger_respawn`), reanudando la cola FIFO de alertas si había transitorios
  pendientes.
- Si el idioma cambia en caliente con la derrota visible, el texto se
  re-renderiza con la localización nueva.

### 4.4 Hover en Muebles (slot_furniture.script)

- El `cursor.script` envía `mouse_hover{ enter = true/false }` al mueble
- Al **entrar** en hover:
  - Se compara el periodo del objeto activo (`game_state.inventory_current_item_period`) con el del mueble
  - Si coincide: tint verde luminoso (`0.5, 1.5, 0.5`) + alerta "Periodo correcto ✓"
  - Si no coincide: tint rojizo (`1.5, 0.5, 0.5`) + alerta "Periodo incorrecto ✗"
  - Si no hay objeto activo: no se aplica tint, solo se muestra el nombre del mueble
  - La alerta es persistente (no desaparece automáticamente)
- Al **salir** del hover: se resetea el tint a blanco y se oculta la alerta persistente

---

## 5. Arquitectura de Mensajes

### 5.1 Diagrama de Flujo

```
cursor.script
  ├── "mouse_hover" → btn_collectible (hover pickup)
  ├── "mouse_hover" → exhibition_object (hover vitrina)
  ├── "mouse_hover" → slot_shelf / slot_showcase (hover mueble — tint + alerta persistente)
  ├── "interact" → btn_collectible
  │     └── "collectible_clicked" → inventory_manager
  ├── "interact" → slot_shelf / slot_showcase
  │     └── "furniture_clicked" → inventory_manager
  │           ├── 1er clic (deposit) → "update_slot" { state = "storage" } (full opacity)
  │           ├── 2º clic (re-deposit) → "update_slot" { state = "in_transit" } (semi-transparente)
  │           └── clic vitrina (complete) → "clear_slot" + "update_slot" { state = "completed" }
  └── "interact" → exhibition_object
        └── "start_exhibition_info" → exhibition_manager → exhibition.gui

inventory_manager
  ├── "update_hud_state" → hud.gui
  ├── "show_alert" → hud.gui
  ├── "update_slot" → slot_shelf / slot_showcase — con { slot, sprite_id, state }
  │     ├── state = "storage" → sprite full opacity
  │     ├── state = "in_transit" → sprite alpha 0.25 (cortado)
  │     └── state = "completed" → sprite tinte verde
  ├── "clear_slot" → furniture (estantería) — con { slot } → resetea a "0000"
  ├── "update_timer_progress" → hud.gui (cada 0.1s mientras Timer A activo) — con { remaining, progress }
  ├── "hide_timer_progress" → hud.gui (al expirar timer, completar objeto, o resetear)
  └── "set_custom_id" → collectible_object

slot_furniture.script
  ├── "show_persistent_alert" → hud.gui (hover: texto que no desaparece automáticamente)
  └── "hide_persistent_alert" → hud.gui (al salir de hover)

main.script (tecla R en DEV_MODE)
  └── "reset_inventory" → inventory_manager
```

---

## 6. Funciones y Aspectos Menos Elaborados

### 6.1 Contadores por periodo — ✅ IMPLEMENTADOS (actualización por evento)

Los 5 iconos de periodo (`box_icon_period_pal/neo/bro/ibe/rom`) muestran **progreso por periodo** ("exhibidas/total"):

| Línea | Nodo GUI | Estado | Significado |
|---|---|---|---|
| Inferior (y=26) | `text_period_exhib_*` | `"completed"` | Progreso del periodo: "exhibidas/total" (p. ej. `1/2`) |
| ~~Superior (y=52)~~ | ~~`text_period_stor_*`~~ | ~~`"storage"`~~ | ~~Retirado Ago 2026~~ — estado STORAGE transitorio (0→1→0 al expirar Timer A) y visible en el mundo; los nodos se eliminaron del `.gui` |

**Arquitectura: actualización por evento (no por polling)**

En lugar de recalcular los contadores cada 0.1s en `update_texts()`, se calculan **solo cuando cambia el estado de un objeto**. Esto es posible porque los objetos coleccionables cambian de estado solo ~50 veces en toda la partida:

| Evento | Estado | Script origen |
|---|---|---|
| Recoger objeto | PICKUP → COLLECTED/RESTORATION | `inventory_manager:on_collectible_clicked()` |
| Depositar en estantería | COLLECTED/STORAGE → STORAGE (inicia timer) | `inventory_manager:on_furniture_clicked("deposit")` |
| Timer expira | STORAGE → EXHIBITION | `inventory_manager:on_timer_expired()` |
| Colocar en vitrina | EXHIBITION → COMPLETED | `inventory_manager:on_furniture_clicked("complete")` |
| Restauración completa | RESTORATION → STORAGE | `inventory_manager:on_restoration_completed()` |

El `inventory_manager.script` ya envía `update_hud_state` en cada uno de estos eventos. El `hud.gui_script` ahora responde a ese mensaje llamando a `update_period_counts(self)`.

**Implementación:**

1. **`inventory_core.lua`** — nueva función `get_storage_by_period()` (gemela de `get_completed_by_period()`) que cuenta objetos en estado `"storage"` agrupados por periodo.

2. **`hud.gui_script`** — función local `update_period_counts(self)` que:
   - Lee `items_status` de `game_state` una sola vez
   - Calcula el total de objetos por periodo desde `collectibles_data` (se adapta solo si se añaden objetos)
   - Cuenta objetos en estado `"completed"` → `exhib.*`
   - Escribe "exhibidas/total" (p. ej. `1/2`) en `text_period_exhib_*` (los nodos `text_period_stor_*` se eliminaron del `.gui` Ago 2026)
   - Se llama al cargar partida (para progreso existente) y en cada `update_hud_state`

3. **Nodos GUI**: No se modificó el `.gui`. Los 10 nodos de texto ya existían:
   - ~~`text_period_stor_pal/neo/bro/ibe/rom`~~ (eliminados del `.gui` Ago 2026)
   - `text_period_exhib_pal/neo/bro/ibe/rom` (muestran "exhibidas/total")

**Rendimiento:**

- `update_texts()` (polling 0.1s) **ya no itera** los nodos de periodo
- `update_period_counts()` se ejecuta solo ~50 veces en toda la partida
- El polling continúa solo para: salud, spray, skills, total coleccionables, tareas (valores que cambian con frecuencia)

**Contenedor:** `box_icon_period_container` tiene `visible: false` en el `.gui` — pendiente de activar.

### 6.2 Sistema de restauración — ✅ ACTIVADO (Ago 2026)

- Un objeto por periodo tiene `requires_restoration = true` (pal_bifaz, neo_cantaro,
  bro_quesera, ibe_pebetero, rom_lucerna — decisión de diseño)
- Flujo activo: PICKUP → RESTORATION (sin timer) → quiz de **npc_11 (Restauradora, pool_2)** →
  STORAGE (Timer A) → EXHIBITION → COMPLETED (Timer B). COLLECTED se omite para objetos
  de restauración porque RESTORATION ya cumple la función de "intermedio antes del depósito"
- **Resolución del quiz** (dialogue_manager.on_quiz_result + game_state.register_restoration_success/failure):
  - **Acierto** → `task_restoration_total +1` (NO suma a task_quiz_total), la pieza pasa a
    almacenable (`restoration_completed` → `/inventory_manager`) y la restauradora se **resetea**
    (intento 1, sin `completed`) para atender el siguiente objeto.
  - **Fallo 1-2** → cooldown de 60s + aviso `alert_new_attempt_restoration` al volver a estar
    disponible (timer simple: no sobrevive a guardar/recargar a mitad de cooldown — aceptado).
    El HUD lo refuerza con un **recordatorio periódico** (intervalo `reminder_restorer_retry` en
    `M.balance`, ver §4.1) que sobrevive a guardar/recargar: mientras la pieza siga en RESTORATION, la
    restauradora esté disponible y el jugador haya fallado con turnos restantes (intento ≥ 2),
    re-muestra el aviso cada X segundos. Si el jugador aún no ha hecho el quiz (intento 1), se
    usa la variante `alert_new_restoration` con su propio intervalo.
  - **Fallo 3 (agotado)** → la pieza pasa a almacenable **sin punto** (justificado en el diálogo
    del intento 3: "no me queda otra que aceptar la pieza para su análisis") y la restauradora se
    resetea para el siguiente objeto.
- **Gate del quiz**: npc.script solo ofrece el quiz si el objeto activo está en estado
  RESTORATION (global `inventory_current_item_id` seteado por inventory_manager). Sin pieza
  pendiente, la restauradora responde con el mensaje localizado `npc_restorer_unavailable`
  (ES/EN).

### 6.3 ~~storage_slot.script y storage_collectibles.script VACÍOS~~ ✅ ELIMINADOS

Estos archivos eran esqueletos vacíos de una implementación anterior. Fueron eliminados en la limpieza de `features/collectibles/`:

- ~~`storage_slot.go` + `storage_slot.script`~~ ✅
- ~~`storage_collectibles.go` + `storage_collectibles.script`~~ ✅
- ~~`btn_storage_collectible.go`~~ ✅
- ~~`collectibles.script`~~ ✅

### 6.4 Gestión de slots en muebles — ✅ CORREGIDO

En `inventory_manager.script`:
- `assign_furniture_slot()` asigna slots en `self.furniture_slots[furniture_id]` — tabla anidada `{ [furniture_path] = { [slot] = item_id } }`
- `find_furniture_slot_for_item()` recorre todos los muebles y slots para localizar un item → devuelve `furniture_path, slot` (dos valores)
- Al hacer `"complete"` en vitrina:
  1. Se busca el slot antiguo en la estantería con `find_furniture_slot_for_item()` (ANTES de asignar en vitrina)
  2. Se envía `clear_slot` al mueble con `{ slot = old_slot }` — el mensaje va directamente a la URL del mueble
  3. Se asigna nuevo slot en la vitrina

**Bug corregido**: anteriormente `find_furniture_slot_for_item()` devolvía una ruta concatenada (`"/furniture_shelf_pal/storage_slot_01"`) que no existía como GO hijo, por lo que el `clear_slot` no llegaba nunca al mueble.

### 6.5 Contenedor de periodo pendiente de activar

El contenedor `box_icon_period_container` existe en `hud.gui` con sus 5 iconos + textos, y `update_period_counts()` actualiza los textos. **Ago 2026**: se confirmó que la rejilla SÍ se ve en el juego pese a que el archivo declara `visible: false` (el flag no bloquea el render en esta versión/build) — no requiere activación por script. Los 5 textos de exhibición muestran progreso "exhibidas/total"; la fila de almacén se retiró y sus nodos se eliminaron del `.gui` (ver §6.1).

### 6.6 Pie timer de exhibición — ✅ IMPLEMENTADO

El Timer A (STORAGE → EXHIBITION) ahora tiene feedback visual en el HUD mediante dos nodos:

- **`pie_timer_to_exhibition`** (tipo PIE): círculo que se vacía progresivamente (360° → 0°) indicando el tiempo restante
- **`text_timer_to_exhibition`** (tipo TEXT): muestra `"Para vitrina: MM:SS"`

**Flujo de visualización:**
1. El jugador deposita el objeto en la estantería → `transition_to(STORAGE)` inicia el timer
2. En cada `update()` del manager, mientras `timer_active == true`, se envía `update_timer_progress { remaining, progress }` al HUD **cada 0.1s (10Hz)**
3. El HUD actualiza el ángulo del pie (`fill_angle = 360 * progress`) y el texto con el tiempo restante
4. Cuando el timer expira → `on_timer_expired()` envía `hide_timer_progress` y los nodos se ocultan
5. También se ocultan al completar el objeto en vitrina (`"complete"`) o al resetear (`on_reset_inventory`)

**Tecnicismos:**
- `self.timer_duration` se captura en el **primer frame** en que `timer_active` se vuelve true, almacenando `current_timer` como referencia para calcular `progress = remaining / timer_duration`
- Esto evita modificar `inventory_core.lua` (el timer sigue funcionando exactamente igual)
- El envío a 10Hz (no a 60fps) es suficiente para una animación suave del pie y minimiza el impacto en rendimiento

**Texto configurable** desde `assets/texts/general_text_[lan].lua`:
- `timer_exhibition_label = "Para vitrina:"` / `"For showcase:"`

### 6.7 Sistema de Corte/Pega (in_transit) — ✅ IMPLEMENTADO

El slot de la estantería ahora tiene **cinco estados visuales** manejados por `slot_furniture.script.set_slot_sprite()`:

| Estado | Sprite | Tint | Uso |
|--------|--------|------|-----|
| `"empty"` | `"0000"` | `(1,1,1,0.3)` | Slot vacío (semi-transparente, apenas visible) |
| `"storage"` | Objeto | `(1,1,1,1)` | Depósito inicial — opacidad total |
| `"exhibition"` | Objeto | `(1,1,1,1)` | Timer expirado — sigue visible completo |
| `"in_transit"` | Objeto | `(1,1,1,0.25)` | **Cortado** — semi-transparente, como archivo cortado en explorador |
| `"completed"` | Objeto | `(0.8,1,0.8,1)` | Vitrina — tinte verde claro |

**Flujo de activación de `in_transit`:**

Hay **dos caminos** que activan `in_transit`:

1. **Re-clic en estantería (STORAGE)**: mientras el Timer A está activo, si el jugador vuelve a hacer clic en la misma estantería, `on_furniture_clicked` detecta `already_deposited = true` y envía `state = "in_transit"` al slot. **No reinicia el timer.**
2. **Segundo clic en estantería (EXHIBITION)**: tras expirar el timer, el core devuelve `action = "wrong_furniture"`. El manager intercepta esto (`furniture_type == "shelf"`), verifica si el item está realmente en esa estantería (`item_in_this_shelf`), y si sí, envía `state = "in_transit"`. Si no está, muestra alerta "necesita vitrina".

**Flujo de finalización de `in_transit`:**

- El tránsito termina **exclusivamente** cuando el jugador deposita el objeto en una vitrina (acción `"complete"`)
- `on_furniture_clicked("complete")` envía `clear_slot` a la estantería → el slot vuelve a `"0000"` vacío
- La vitrina recibe `update_slot { state = "completed" }` con el sprite y tinte verde

### 6.9 ~~Bug potencial de doble transición~~ ✅ CORREGIDO

Anteriormente, `inventory_core.update()` auto-avanzaba el estado cuando el timer expiraba, y luego `inventory_manager.on_timer_expired()` lo volvía a avanzar. Esto causaba que:
- Timer de RESTORATION → el objeto saltaba directamente a EXHIBITION (saltándose STORAGE)
- Timer de STORAGE → nunca se mostraba la alerta correcta

**Corregido**: ahora `inventory_core.update()` solo señaliza que el timer expiró (`return true`) sin cambiar el estado. El manager (`on_timer_expired()`) es el único que gestiona la transición.

### 6.10 ~~btn_collectible.script visible tras recogida~~ ✅ CORREGIDO

`go.set(".", "scale", (0,0,0))` lanzaba un error de "componentes ≤ 0" similar a `go.set_scale(0)` en Defold, causando que el handler crasheara antes de desactivar la colisión del botón. Esto dejaba `btn_collectible` visible y cliqueable tras recoger el objeto.

**Tres correcciones:**
1. `go.set_scale(vmath.vector3(0.001, 0.001, 0.001))` en lugar de `(0,0,0)` — evita el error
2. `go.cancel_animations(".", "scale")` antes de setear escala — detiene hover animation
3. Guarda `self.collision_enabled` en `mouse_hover` — ignora mensajes retrasados

### 6.11 ~~Iconos de exhibición (exhibition_icon)~~ ✅ ELIMINADO

Anteriormente, `furniture.go` tenía tres sprites `exhibition_icon_1/2/3` que se mostraban debajo de cada slot para indicar "objeto listo para vitrina". El flujo era: Timer A expira → `inventory_manager` enviaba `show_exhibition_icon` → `furniture.script` mostraba el icono.

**Eliminado** porque:
- El mensaje se enviaba a una ruta inexistente (`/furniture_shelf_pal/storage_slot_01`) — bug que producía errores en consola
- Incluso si llegara al mueble, faltaba el parámetro `slot` para saber qué icono mostrar
- El hover ya proporciona feedback visual (tint verde/rojo) y textual (alerta persistente), haciendo redundantes los iconos

### 6.12 ~~hash_to_str() roto para Defold moderno~~ ✅ CORREGIDO

En Defold 1.4+, `type(hash("pal"))` devuelve `"hash"` (no `"userdata"`). El `hash_to_str()` original solo chequeaba `type == "userdata"`, por lo que los hash caían en `return tostring(h)` que devolvía `"hash: [pal]"` (con espacio y corchetes). Esto causaba que comparaciones de periodo como `"pal" == " [pal]"` fallaran.

**Corregido**: ahora `hash_to_str()` maneja tres formatos:
1. `"hash: [pal]"` (Defold moderno con corchetes) → captura `"pal"`
2. `"hash:pal"` (formato antiguo) → captura `"pal"`
3. `"pal"` (ya es string) → devuelve tal cual

Además:
- `notify_manager()` en `slot_furniture.script` ahora compara el hash directamente con `==` en lugar de usar `tostring()`, lo que evita problemas cuando el override del editor no registra el string en la tabla de hashes de Defold.
- Los antiguos intentos de runtime repositioning (child GOs `slot_furniture_1/2/3`) fueron eliminados. Cada tipo de mueble (shelf/showcase) tiene ahora su propio `.go` con posiciones de slot hardcodeadas en el editor.

### 6.13 Sin soporte para múltiples objetos simultáneos

El sistema solo maneja **un objeto a la vez** (`self.current_item`). No hay cola de objetos pendientes visibles. El Timer B (5s) da un pequeño respiro entre objetos, pero sigue siendo un flujo estrictamente secuencial.

### 6.14 Sin animaciones de transición

- Cuando un objeto se recoge, simplemente desaparece (se mueve a -9999, -9999)
- Cuando un objeto se deposita en una estantería, el sprite aparece instantáneamente
- No hay efectos de partículas, animaciones de "guardado" o "exhibición"


---

## 7. Resumen de Archivos

| Archivo | Estado | Líneas | Función |
|---|---|---|---|
| `main/inventory_manager.script` | ✅ Activo | ~430 | Orquestador central + flujo corte/pega (`in_transit`) + envío progreso pie timer |
| `main/inventory_core.lua` | ✅ Activo | ~250 | Máquina de estados + timers duales (helpers de contadores del HUD eliminados Ago 2026 — el HUD recalcula desde `game_state`) |
| `main/collectibles_data.lua` | ✅ Activo | ~145 | Datos de 10 objetos + hash_to_str() |
| `gui/hud.gui_script` | ✅ Activo | ~470 | HUD + estado objeto + alertas persistentes + pie timer exhibición + progreso por periodo "exhibidas/total" (event-driven) |
| `main/exhibition_manager.script` | ✅ Activo | ~120 | Panel exhibición |
| `gui/exhibition.gui_script` | ✅ Activo | ~130 | GUI panel exhibición |
| `gui/interactive.gui_script` | ✅ Activo | ~350 | Diálogos + quizzes |
| `main/cursor.script` | ✅ Activo | ~60 | Input + colisiones |
| `main/screen_utils.lua` | ✅ Activo | ~40 | Coordenadas mundo→pantalla |
| `main/game_state.lua` | ✅ Activo | ~260 | Estado global + persistencia |
| `main/persistence.lua` | ✅ Activo | ~230 | I/O de disco |
| `features/collectibles/btn_collectible.script` | ✅ Activo | ~65 | Botón de recogida (fix scale 0 → 0.001, cancel_animations, guarda collision) |
| `features/exhibition_objects/exhibition_object.script` | ✅ Activo | ~100 | Objeto en vitrina (hover+clic) |
| `features/furniture/slot_furniture.script` | ✅ Activo | ~180 | Mueble compartido (slot único) + estado `in_transit` (alpha 0.25), hover tint, clear_slot |
| `features/furniture/slot_shelf.go` | ✅ Activo | — | Estantería (shelf): slot único, `slot_sprite_1` |
| `features/furniture/slot_showcase.go` | ✅ Activo | — | Vitrina (showcase): slot único, `slot_sprite_1` |
| ~~`features/furniture/furniture.script`~~ | ❌ Eliminado | — | Antiguo mueble multi-slot — código muerto (Ago 2026) |
| ~~`features/furniture/furniture.go`~~ | ❌ Eliminado | — | Antigua estantería multi-slot — no usada (Ago 2026) |
| ~~`features/furniture/showcase.go`~~ | ❌ Eliminado | — | Antigua vitrina multi-slot — no usada (Ago 2026) |
