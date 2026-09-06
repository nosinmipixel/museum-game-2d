# 🍝 Plan de Refactorización — Código Espagueti

> **Fecha:** July 12, 2026 (Actualizado)
> **Proyecto:** Top Down Museum Game (Defold/Lua)
> **Objetivo:** Eliminar código espagueti priorizando impacto vs. riesgo

---

## 📋 Resumen Ejecutivo

Se identificaron **12 problemas** de código espagueti en 26 scripts analizados (~6000+ líneas).

| Fase | Problemas | Estado |
|------|-----------|--------|
| 🔴 **Fase 1 — Crítico** | 1 bug + 4 refactors | ✅ Completada |
| 🟠 **Fase 2 — Alto** | 4 refactors | ✅ Completada |
| 🟡 **Fase 3 — Medio/Bajo** | 2 refactors + 1 descartado | ✅ 2/3 Completada |

---

## 🔴 FASE 1 — Crítico (✅ Completada)

### 1.1 🐛 Bug: Doble procesamiento de `trigger_response` en `cursor.script`

**Archivo:** `main/cursor.script`
**Estado:** ✅ Corregido

**Solución aplicada:**
El cursor es `COLLISION_OBJECT_TYPE_TRIGGER` y los NPCs son `KINEMATIC`. En Defold, solo `trigger_response` se envía para trigger↔kinematic (no `collision_response`/`contact_point_response`).

Se unificó el procesamiento de `trigger_response` en un ÚNICO bloque que maneja tanto hover (`mouse_hover`) como interacción (`interact`) con un `return` inmediato. Se eliminó la variable `es_colision` que incluía `trigger_response` dos veces.

**Archivos modificados:** `main/cursor.script`
**Verificación:** Clic en NPC envía `interact` una sola vez, no dos.

---

### 1.2 ♻️ Refactor: Extraer función compartida `auto_size_node()`

**Archivo:** `gui/interactive.gui_script`
**Estado:** ✅ Corregido

**Solución aplicada:**
Se extrajo `auto_size_node(text_node, bg_node, text, original_text_width, fixed_bg_width, padding_top, padding_bottom, min_height, text_scale)` como núcleo compartido. `auto_size_bubble` y `auto_size_button` quedan como wrappers delgados que solo añaden el posicionamiento específico (texto North↔South vs Center).

Antes: 2 funciones con ~90% código duplicado (~50 líneas c/u)
Ahora: 1 función compartida (15 líneas) + 2 wrappers (20 + 15 líneas)

**Archivos modificados:** `gui/interactive.gui_script`
**Precaución:** Si se cambian los paddings, actualizar también las constantes `BUBBLE_PADDING_TOP`, `BUBBLE_PADDING_BOTTOM` en el wrapper. El debug comentado usa `BUBBLE_PADDING_Y`.

---

### 1.3 ♻️ Refactor: Extraer función `update_blink_bar()`

**Archivo:** `gui/hud.gui_script`
**Estado:** ✅ Corregido

**Solución aplicada:**
Se extrajo `update_blink_bar(self, timer_key, visible_key, is_critical, bar_node, bar_color)` que usa acceso dinámico a campos via `self[timer_key]` y `self[visible_key]`. Los dos bloques blink de health bar y spray bar (~15 líneas c/u) se reemplazaron por llamadas de 1 línea.

Antes: ~30 líneas duplicadas
Ahora: 1 función (12 líneas) + 2 llamadas

**Archivos modificados:** `gui/hud.gui_script`
**Precaución:** Las variables `self.blink_timer`, `self.blink_visible`, `self.spray_blink_timer`, `self.spray_blink_visible` se inicializan en `init()` y se acceden por string key.

---

### 1.4 ♻️ Refactor: Dividir `show_current_dialog()` en `dialogue_manager.script`

**Archivo:** `main/dialogue_manager.script`
**Estado:** ✅ Corregido

**Solución aplicada:**
Se extrajeron 4 funciones con responsabilidad única:
- `handle_speaker_animation(self, speaker)` — envía `start_talking` al player o NPC
- `prepare_dialog_text(self, node, speaker)` — gsub `\\n`→`\n`, antepone nombre del hablante
- `calculate_screen_position(self, speaker)` — world_to_screen del GO que habla
- `manage_advance_timers(self, node)` — quiz o warmup + advance timer (con gsub interno para cómputo de longitud)

`show_current_dialog` pasó de ~45 líneas (6 responsabilidades) a ~20 líneas (7 pasos claros).

**Archivos modificados:** `main/dialogue_manager.script`
**Precaución:** `manage_advance_timers` hace su propio `string.gsub(node.text, "\\n", "\n")` para el cómputo de longitud (independiente del gsub en `prepare_dialog_text`).

---

### 1.5 ♻️ Refactor: Dividir `on_message()` del cockroach

**Archivo:** `features/enemy_cockroach/enemy_cockroach.script`
**Estado:** ✅ Corregido

**Solución aplicada:**
Se extrajeron 3 handlers:
- `handle_player_collision(self, message)` — ataque, daño, animación, transición a RETREAT
- `handle_wall_collision(self, message)` — separación física + esquive lateral
- `handle_damage(self, message)` — muerte, sonidos, animación death, go.delete()

`on_message` pasó de ~90 líneas a ~12 líneas (dispatcher puro).

**Archivos modificados:** `features/enemy_cockroach/enemy_cockroach.script`
**Precaución:** `stop_all_enemy_sounds` se llama con un objeto temporal `{ sound_urls = self.sound_urls_list }` (patrón preexistente). `apply_proximity_audio` usa `self.my_pos` y `self.player_pos` que se actualizan en `update()`.

---

## 🟠 FASE 2 — Alto (✅ Completada)

### 2.1 ♻️ Refactor: Dividir `on_furniture_clicked()` en `inventory_manager.script`

**Archivo:** `main/inventory_manager.script`
**Estado:** ✅ Corregido

**Solución aplicada:**
Se extrajeron 3 handlers grandes:
- `handle_deposit(self, message, furniture_url_str)` — nuevo depósito o re-clic en estantería: slot, sonido, timer STORAGE, HUD, persistencia
- `handle_complete(self, message, furniture_url_str)` — completar en vitrina: slot antiguo→clear, slot nuevo→completed, Timer B, HUD, persistencia
- `handle_wrong_furniture_shelf(self, furniture_url_str, furniture_period)` — marcar slot como in_transit para vitrina

Las 5 acciones simples (wrong_furniture genérico, wrong_period, invalid_state, no_item, fallback) se mantienen inline (~3 líneas c/u). `on_furniture_clicked` pasó de ~150 líneas a ~30 líneas (guard + parseo + dispatcher).

**Archivos modificados:** `main/inventory_manager.script`
**Precaución:** Cada handler calcula `local inv = self.texts.inventory or {}` internamente (antes se definía una vez en el preamble). `handle_complete` tiene `inv` al inicio de la función (no duplicado).

---

### 2.2 ♻️ Refactor: Dividir `cargar_progreso()` en `persistence.lua`

**Archivo:** `main/persistence.lua`
**Estado:** ✅ Corregido

**Solución aplicada:**
Se extrajeron 4 funciones:
- `create_fresh_save()` — crea estructura nueva con valores por defecto (Rama A original)
- `ensure_globals(datos)` — verifica todas las claves de `DEFAULT_GLOBALS`
- `ensure_npc_progress(datos)` — verifica NPCs 1..NPC_COUNT + preserva NPCs especiales
- `ensure_quiz_state(datos)` — verifica estructura `current_quiz`

`cargar_progreso()` pasó de ~120 líneas (2 ramas, B con 4 sub-bloques anidados) a ~20 líneas (flujo lineal). Se simplificó la migración de `available_at`→`available_after` de 6 líneas anidadas a 1 línea (`progress.available_at or 0`).

**Archivos modificados:** `main/persistence.lua`
**Precaución:** En Lua, `0` es truthy, así que `progress.available_at or 0` funciona correctamente incluso si `available_at = 0`.

---

### 2.3 ♻️ Refactor: Simplificar flujo de `update()` en `player.script`

**Archivo:** `features/player/player.script`
**Estado:** ✅ Corregido

**Solución aplicada:**
Se extrajeron 2 funciones:
- `update_walk_sound(self, is_moving)` — unifica el sonido de caminar duplicado en ATTACK y NORMAL
- `reset_movement_state(self)` — unifica el triple cleanup `direction=0, correction=0` en DAMAGE, ATTACK y NORMAL

El sonido de caminar aparecía 2 veces (~10 líneas c/u) y ahora es 1 función + 2 llamadas. El cleanup aparecía 3 veces y ahora es 1 función + 3 llamadas.

**Archivos modificados:** `features/player/player.script`
**Precaución:** Los early returns de DAMAGE y ATTACK requieren cleanup antes del return, por lo que `reset_movement_state` se llama 3 veces (no se puede unificar al final).

---

### 2.4 ♻️ Refactor: Eliminar variable global `spray_container_url`

**Archivos:** `features/props/spray_can.script`, `features/props/spray_spawn_container.script`, `main/spray_spawn_state.lua`
**Estado:** ✅ Corregido

**Solución aplicada:**
Se movió la URL del contenedor de una variable global (`spray_container_url`) al módulo compartido `spray_spawn_state.lua` (`M.container_url`). El módulo ya existía y ya era requerido por ambos scripts.

**Archivos modificados:** `main/spray_spawn_state.lua`, `features/props/spray_spawn_container.script`, `features/props/spray_can.script`
**Precaución:** El contenedor asigna `spray_state.container_url = msg.url()` en su `init()`. Si el contenedor no se ha inicializado, `spray_state.container_url` será `nil` y el spray_can no podrá notificar (mismo comportamiento que antes con la global).

---

## 🟡 FASE 3 — Medio/Bajo

### 3.1 ♻️ Refactor: Tabla de lookup para hash→string en `furniture.script`

**Archivo:** `features/furniture/furniture.script`
**Estado:** ✅ Corregido

**Solución aplicada:**
Se reemplazaron las cadenas if-elseif (14 líneas para convertir 2 furniture types + 5 periodos) por 2 tablas de lookup constantes:
```lua
local FURNITURE_TYPE_STR = {
    [hash("shelf")] = "shelf",
    [hash("showcase")] = "showcase",
}
local PERIOD_STR = {
    [hash("pal")] = "pal",  [hash("neo")] = "neo",
    [hash("bro")] = "bro",  [hash("ibe")] = "ibe",  [hash("rom")] = "rom",
}
```
Además se añadieron comentarios de documentación encima de cada `go.property()` indicando los valores válidos (visibles en el panel Properties del editor).

**Archivos modificados:** `features/furniture/furniture.script`
**Precaución:** Si se añade un nuevo furniture_type o periodo, hay que añadirlo tanto a la lookup table como al comentario de `go.property()`.

---

### 3.2 ♻️ Refactor: Cachear dirección del ratón en `player_spray.script`

**Archivo:** `features/player/player_spray.script`
**Estado:** ✅ Corregido

**Solución aplicada:**
Se cachea `self.last_aim_direction = dir` en `handle_input()` después de normalizar. En `fire_particle()` se reemplazó el recálculo (~6 líneas con normalize + fallback) por `local dir = self.last_aim_direction or vmath.vector3(0, 1, 0)` (1 línea).

**Nota:** La dirección ahora queda fija desde el clic (antes se recalculaba con `player_pos` actual cada tick). Al ser un arma de cono de dispersión, la diferencia es imperceptible.

**Archivos modificados:** `features/player/player_spray.script`
**Precaución:** Si se necesita que la dirección se actualice mientras se dispara (ej: seguimiento preciso del ratón), habrá que actualizar `last_aim_direction` en cada frame durante el disparo, no solo en el clic inicial.

---

### 3.3 ♻️ Strategy pattern para `on_input()` en `scene_manager.script`

**Archivo:** `main/scene_manager.script`
**Estado:** ❌ Descartado (no procede)

**Motivo:**
- Solo 2 modos fijos (intro y level_01), sin expectativa de crecimiento
- Cada modo tiene early returns y lógica específica — extraerlos a una tabla de handlers no reduce la complejidad real
- El código actual (~30 líneas) ya es legible: cada bloque tiene su propio `if` con `return` al final
- El coste de mantenimiento de la tabla de handlers supera el beneficio

**Decisión:** Se mantiene el código original sin cambios.

---

## 📊 Estado Final del Plan

| Tarea | Estado | Archivos afectados |
|-------|--------|-------------------|
| 🔴 1.1 trigger_response | ✅ | `cursor.script` |
| 🔴 1.2 auto_size_node | ✅ | `interactive.gui_script` |
| 🔴 1.3 update_blink_bar | ✅ | `hud.gui_script` |
| 🔴 1.4 show_current_dialog | ✅ | `dialogue_manager.script` |
| 🔴 1.5 on_message cockroach | ✅ | `enemy_cockroach.script` |
| 🟠 2.1 on_furniture_clicked | ✅ | `inventory_manager.script` |
| 🟠 2.2 cargar_progreso | ✅ | `persistence.lua` |
| 🟠 2.3 update() player | ✅ | `player.script` |
| 🟠 2.4 spray_container_url | ✅ | `spray_can.script`, `spray_spawn_container.script`, `spray_spawn_state.lua` |
| 🟡 3.1 hash→string lookup | ✅ | `furniture.script` |
| 🟡 3.2 dirección ratón | ✅ | `player_spray.script` |
| 🟡 3.3 on_input strategy | ❌ | No procede |

---

## 🧹 Anexo — Auditoría de calidad (Agosto 2026, aplicada)

> Auditoría completa del juego (37 scripts, GUI, atlas, textos y configuración). Los 6 hallazgos se corrigieron en dos tandas. Cada fix tiene su GOTCHA o documentación asociada en `docs/DEV_GOTCHAS.md`.

| # | Hallazgo | Estado | Archivos | Referencia |
|---|----------|--------|----------|------------|
| 1 | 🔴 Atlas `icon_quiz_main_anim` — frames de animación sin registrar en `images` (build descartaba el flipbook del quiz en silencio) | ✅ | `gui/gui.atlas` | GOTCHA #8 (referencia actualizada) |
| 2 | 🔴 `item_id` desalineados con el catálogo de la sala — `neo_hacha` (5094), `ibe_kili` (22354), `rom_copa` (248) sin ficha en `exhibition_text` → "No se encontró el objeto con ID" al clicar su vitrina | ✅ | `assets/texts/exhibition_text_{es,en}.lua` (3 fichas nuevas) | — |
| 3 | 🟠 `bro_hacha` con `item_id = 3098` → mostraba la ficha de la Hoz para el "Hacha de cobre" | ✅ | `main/collectibles_data.lua` (3098→7623) + ficha 7623 en `exhibition_text_{es,en}.lua` | — |
| 4 | 🟠 Textos hardcodeados en español en `inventory_manager.script` (alerta de re-clic + alerta de vitrina que concatenaba la clave cruda del periodo: "…period pal." en inglés) | ✅ | `main/inventory_manager.script` + claves en `general_text_{es,en}.lua` (`M.inventory`), periodo resuelto con `inv.periods[...]` | GOTCHA #20 |
| 5 | 🟠 `print()` directo en `cursor.script` (3) e `interactive.gui_script` (5) — logueaban SIEMPRE, incluso en producción, ignorando `M.DEBUG` | ✅ | `main/cursor.script` (`DEBUG_CURSOR`), `gui/interactive.gui_script` (`DEBUG_INTERACTIVE`) → `config.make_log` | GOTCHA #36 |
| 6 | 🟡 `reset_all()` reconstruía `M.globals` sin conservar `sfx_volume`/`temp_units`/`fps_overlay` → "Nueva partida" borraba preferencias del jugador en silencio (fallbacks lo enmascaraban) | ✅ | `main/game_state.lua` (prefs capturadas antes del rebuild y restauradas) | GOTCHA #35 |
| 7 | 🟡 5 scripts de props con `print()` crudo (kit_health, kit_stamina, food_cat_can, spray_can + 2 restantes de slot_furniture) — logueaban SIEMPRE en producción (mismo patrón que el hallazgo #5, no cubierto por la primera auditoría) | ✅ | `features/props/{kit_health,kit_stamina,food_cat_can,spray_can}.script`, `features/furniture/slot_furniture.script` → `config.make_log` + toggle local | GOTCHA #36 |
| 8 | 🟡 10 scripts con `DEBUG_X = true` (npc, office_cabinet, car, car_start_point, food_spawn_container, doors, spray_spawn_container, ambient_trigger, door_main, npc_spawn_manager) — inertes con `M.DEBUG = false` pero activaban todo el logging al depurar | ✅ | los 10 scripts → `DEBUG_X = false` | — |
| 9 | 🟡 Fallbacks en español de `collectibles_data` (name/display_name) enmascaran objetos nuevos sin traducir | ✅ | `main/inventory_manager.script` (`check_localization_coverage()` en dev, ES+EN) — fallbacks mantenidos como red de seguridad | GOTCHA #39 |
| 10 | 🟡 3 scripts de `features/` con `print()` de debug crudo (cockroach, btn_collectible, npc_spawn_manager) — la re-auditoría del grep de cobertura (GOTCHA #36) los detectó fuera de `props/` | ✅ | `features/enemy_cockroach/enemy_cockroach.script` (`DEBUG_COCKROACH`), `features/collectibles/btn_collectible.script` (`DEBUG_BTN_COLLECTIBLE`), `features/npc/npc_spawn_manager.script` → `dprint` | GOTCHA #36 |

> 🔍 **Nota de cobertura (Ago 2026):** se MANTIENEN como `print` los 11 diagnósticos de recursos/configuración en `features/` (⚠️ factory, puntos de spawn, spawn_index, animación death) — categoría 3 del GOTCHA #36: errores reales que deben verse en producción (igual que `text_loader`). Tras esta tanda, el grep de cobertura cubre TODO el árbol y no quedan prints de debug sin sistema de log.

**Verificación:** `luac -p` en todos los archivos tocados + `audit_globals.sh` → 0 violaciones tras cada tanda.

---

*Generado por Codebuff — July 12, 2026 (Actualizado Ago 2026)*