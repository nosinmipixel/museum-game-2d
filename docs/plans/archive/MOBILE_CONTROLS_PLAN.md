# 📱 Plan de implementación — Controles táctiles (móvil/HTML5)

> **Documento de planificación.** Estado: **✅ EJECUTADO (Agosto 2026)** — Fases 0-5, 6 y 7c implementadas y verificadas (binding multitáctil, montaje de la GUI con activación solo en táctil, D-pad, botón spray + auto-aim, botón option + sensor de proximidad, neutralización del cursor, overlay de rotación, retención de la intro hasta landscape, fondo de pausa a pantalla completa y cámara dinámica de la intro). Única excepción deliberada: el fullscreen automático al girar NO se implementó (decisión Opción C, ver Fase 6). Archivo histórico: el estado actual del esquema táctil vive en `docs/PROJECT_SUMMARY.md` y `docs/DEV_GOTCHAS.md`.
> Objetivo: añadir un esquema de control táctil para el build HTML5 en dispositivos móviles, reutilizando la infraestructura ya existente (detección de plataforma, capa de puntería unificada, registro de enemigos).
> 🔗 Complementa a `docs/plans/archive/INPUT_CONTROL_PLAN.md` (decisión de esquema: **Opción 5 — botón de disparo + auto-aim asistido**) y `docs/plans/GITHUB_PUBLISH_PLAN.md` (fase de controles táctiles).

---

## 1. Objetivo

- Mostrar una GUI de controles táctiles (`gui/web_controls.gui`) **superpuesta a todas las demás**, activa **únicamente en dispositivos táctiles** (móvil/tableta).
- **D-pad** (nodo `joystick`): controlar el movimiento del jugador.
- **Botón `btn_spray`**: activar el disparo de spray (con auto-aim hacia el enemigo más cercano en rango, fallback a la dirección de movimiento/FACING).
- **Botón `btn_option`**: activar el elemento interactivo **más cercano al jugador** (equivalente a la tecla E de otros juegos), con feedback visual de cuál será el objetivo para resolver la ambigüedad cuando NPCs/objetos están muy juntos.

---

## 2. Estado actual del proyecto (hallazgos del análisis — Agosto 2026)

| Pieza | Estado | Ubicación |
|---|---|---|
| Detección de plataforma (escritorio vs táctil) | ✅ **Implementada** | `main/platform.lua` — `detect()`, `is_html5()`, `is_mobile()`, `is_touch()`, `pointer_type()`, `is_detected()`. Llamada en `scene_manager.script:init()` (bootstrap, al arrancar). HTML5: `html5.run()` **síncrono** que devuelve el resultado de `matchMedia('(pointer: coarse)')` como string. ⚠️ El API antiguo `html5.set_callback` fue **eliminado** del motor (wasm 1.13) — llamarlo en el init del bootstrap causaba pantalla negra en PC/móvil (fix aplicado) |
| Capa de puntería unificada | ✅ **Implementada** | `features/player/aiming.lua` — fuentes `MOUSE / STICK / AUTO / FACING` con prioridad. **`set_stick()` / `set_auto()` ya existen como API** (marcadas "futuro" en los comentarios) |
| Registro de enemigos (GOTCHA #4) | ✅ **Implementada** | `main/enemy_state.lua` — `register(id)`, `get_spawned()`, `reset()` |
| FACING del jugador | ✅ **Implementada** | `player.script` alimenta `aiming.set_facing(last_direction)` cada frame → el D-pad dará la fuente FACING gratis |
| Esquema móvil decidido | ✅ **Decidido** | `docs/plans/archive/INPUT_CONTROL_PLAN.md` §8 → **Opción 5**: joystick movimiento + botón disparo con auto-aim |
| GUI de controles | ⚠️ **A medias** | `gui/web_controls.gui` existe con nodos: `joystick` (D-pad: `btn_up`/`btn_down`/`btn_left`/`btn_right`/`btn_center`), `btn_spray` (textura `button_web_bug`), `btn_option` (textura `button_web_option`). Texturas confirmadas en `gui/gui.atlas` |
| GUI script de controles | ❌ **No existe** | Falta `gui/web_controls.gui_script` |
| Binding multitáctil | ❌ **No existe** | `input/game.input_binding` solo tiene `mouse_trigger` (single-touch vía MOUSE_BUTTON_1) |
| GUI montada en bootstrap | ❌ **No** | Falta instancia en `bootstrap.collection` |
| Puentes táctil → lógica | ❌ **No** | Faltan: movimiento, spray, interacción |
| Sensor de proximidad para el botón option | ❌ **No** | Falta |

**Conclusión:** el trabajo se reduce a construir el `gui_script`, el binding multitáctil, el montaje de la GUI y los puentes táctil→lógica. El 80% de la infraestructura de soporte ya existe.

---

## 3. Arquitectura propuesta

```
[Pantalla táctil] → touch_multi (nuevo binding TOUCH_MULTI)
        │
        ▼
scene_manager (bootstrap) ──forward input_event (+ campo touch)──► web_controls.gui_script (8º target)
        │                                                        (render order 5, SOLO si platform.is_touch())
        ▼
┌─────────────────────────────────────────────────────────────────────┐
│ web_controls.gui_script (bootstrap:/gui_web_controls#web_controls)  │
│  · gui.pick_node() por cada touch point contra los botones          │
│  · D-pad  → input_event {up/down/left/right, value} → player        │
│  · spray  → mensaje "mobile_spray" {pressed}        → player_spray  │
│  · option → mensaje "mobile_interact"               → player_interact│
└─────────────────────────────────────────────────────────────────────┘
```

**Principio rector: reutilizar los handlers existentes en lugar de duplicar lógica.**

- El D-pad **inyecta las mismas acciones que el teclado** (`up`/`down`/`left`/`right`) → `player.handle_input` las procesa igual y el jugador hereda gratis todos los gates (muerte, diálogo, bloqueo por muros, agotamiento).
- El botón spray reutiliza el mecanismo de disparo de `player_spray` (cadencia, recursos, sonido, gates de muerte) con la fuente de puntería **AUTO** (auto-aim) y fallback **FACING** (que ya alimenta `player.script` cada frame).
- El botón option reutiliza el contrato de interacción existente (mensaje `"interact"` + feedback `mouse_hover` con tint) que ya implementan TODOS los interactables.

**Ventaja arquitectónica clave:** al añadir `web_controls` como target del forwarding de `scene_manager`, hereda **gratis**:
- El guard de pausa (`if self.is_paused then return` — los mensajes sí atraviesan `set_time_step`, los `on_input` del proxy no).
- El enrutado por escena (solo recibe input en modo `level_01`, nunca en intro).

---

## 4. Cambios por archivo

### Fase 0 — Binding multitáctil ✅ IMPLEMENTADA

**Archivo:** `input/game.input_binding`

Añadir un trigger de tipo touch multi (en el editor: sección *Touch Triggers* → `TOUCH_MULTI`):

```
touch_trigger {
  input: TOUCH_MULTI
  action: "touch_multi"
}
```

⚠️ **Regla crítica (verificada en el manual oficial de Defold, "Mouse and touch input"):**
- El action del multi-touch **NO puede ser el mismo** que el del `MOUSE_BUTTON_LEFT/MOUSE_BUTTON_1` (asignarlo pisa el single-touch). El proyecto ya usa `"touch"` y `"click"` para MOUSE_BUTTON_1 → el nuevo action debe ser único, p. ej. `"touch_multi"`.
- Bug conocido: los touch inputs no pueden compartir nombre de action con otros inputs.
- El multi-touch llega a `on_input` como `action.touch`: tabla indexada 1..N, cada entrada con `id`, `x`, `y`, `screen_x`, `screen_y`, `pressed`, `released` (y `tap_count`). `x`/`y` son las mismas coordenadas que usa `gui.pick_node` (patrón ya probado en `hud.gui_script`).

### Fase 1 — Montar la GUI y activarla solo en táctil ✅ IMPLEMENTADA

**Archivo:** `bootstrap.collection`
- Añadir instancia embebida `gui_web_controls` (junto a `gui_library`) con el componente `/gui/web_controls.gui`. Así queda **superpuesta a todas las escenas** (intro y nivel) y persiste entre transiciones.

**Archivo nuevo:** `gui/web_controls.gui_script`
- `init()`:
  - `gui.set_render_order(5)` — por encima de pause=4 > library=3 > exhibition=2 > interactive=1 > hud=0.
  - Cachear nodos (`joystick`, `btn_up/down/left/right`, `btn_spray`, `btn_option`).
  - **Deshabilitar todo por defecto** (`gui.set_enabled(node, false)` en el contenedor y los botones — el nodo `joystick` ya nace `visible: false` en el `.gui`).
- **Activación:** cuando `platform.is_detected() and platform.is_touch()` con **polling en `update()`** (la detección HTML5 es asíncrona) y timeout de ~2s para degradar a escritorio (mantener oculto).
- **Visibilidad solo en gameplay:** `scene_manager` envía `mobile_controls { active = true }` al cargar `level_01` y `{ active = false }` al volver a intro → los controles no flotan sobre la intro.

**Archivo:** `main/scene_manager.script`
- Añadir `"bootstrap:/gui_web_controls#web_controls"` al array `input_targets` (modo `level_01`).
- Añadir `touch = action.touch` al `event` que reenvía (hoy construye el event sin ese campo).

### Fase 2 — D-pad → movimiento (sin tocar `player.script`) ✅ IMPLEMENTADA

En `web_controls.gui_script`, por cada touch point de `action.touch`:
- Con `pressed`/`released` + `gui.pick_node(btn_up/btn_down/btn_left/btn_right, td.x, td.y)` → actualizar el estado de cada botón y componer el vector (soporta diagonales: up+left simultáneos gracias al multi-touch).
- Publicar a `level_01:/player#player` el mismo `input_event` que manda `scene_manager`:
  `{ action_id = hash("up"|"down"|"left"|"right"), value = 1|0 }`.
- `player.handle_input` ya lo entiende (up→y+, down→y-, left→x-, right→x+; normaliza en `update_movement`). **Cero cambios en `player.script`.**

> ✅ **Fix aplicado (Agosto 2026):** el jugador solo se movía a ráfagas al mantener pulsado.
> Causa: `player.script` resetea `direction` al final de cada `update()`
> (`reset_movement_state`), y el teclado funciona porque `key_trigger` re-alimenta
> `value=1` CADA frame mientras la tecla está pulsada. Fix: además de la transición
> prensa/suelta (value 1/0), `process_touch` re-envía `value=1` cada frame mientras
> el botón esté pulsado (rama `elseif pressed`). Claves de `self.dpad` normalizadas
> a `btn_up/...` (coinciden con `DPAD_BUTTONS`).

### Fase 3 — Botón spray + auto-aim (Opción 5) ✅ IMPLEMENTADA

**Decisiones confirmadas (Agosto 2026):** auto-aim **siempre al enemigo más cercano en rango** (sin cono) + **trigger inteligente ON** (`SMART_TRIGGER = true`): no se gasta spray si no hay enemigo en rango.

**Archivo:** `web_controls.gui_script`
- `btn_spray` → mensaje **`mobile_spray`** `{ pressed = true/false }` a `level_01:/player#player_spray`. **Contrato MANTENIDO** (no disparo único como `btn_option`): el touch que presiona `btn_spray` queda **capturado por `touch_id`** (misma técnica que el D-pad), de modo que el release se detecta por id — aunque el dedo se deslice fuera del botón, soltar corta el spray (sin spray "infinito").
- `reset_dpad()` (al ocultar controles) también suelta el spray capturado → `mobile_spray {pressed=false}`.

**Archivo:** `features/player/player_spray.script`
- Handler `mobile_spray` (patrón `click_right`/`key_space`): `pressed` → `firing = true`, `firing_source = "mobile"`, `refresh_auto_aim()` + `attack_direction`; `released` → `firing = false`, limpiar fuente, `aiming.clear_auto()`, `stop_attack`. Gate `player_dead` respetado.
- `update()`: mientras `firing_source == "mobile"` se **refresca el auto-aim cada frame** (`refresh_auto_aim`) → el spray sigue al enemigo en movimiento, no solo al press.
- **Smart trigger:** `has_target = refresh_auto_aim(self)`; con `SMART_TRIGGER` y sin enemigo en rango, `firing_effective = false` → ni dispara ni suena (protege el recurso). En escritorio (`click_right`/`space`) dispara siempre, igual que antes.

**Archivo nuevo:** `features/player/auto_aim.lua` (módulo, patrón `M = {}`)
- `find_nearest(player_pos, range, out)` → dirección normalizada al enemigo más cercano en rango o `nil`. Recorre `enemy_state.get_spawned()` filtrando `go.exists()` (GOTCHA #4) y distancia al jugador. **Zero-alloc:** muta el vector `out` (estándar #2/#8).

**Configurable (en `main/config.lua`):** `AUTO_AIM_RANGE = 250` (el bullet vive ~0.5s a 200-400 px/s → alcance real ~100-200 uds; 250 da margen sin apuntar a lejanos), `SMART_TRIGGER = true` y `AUTO_AIM_HYSTERESIS = 0.25`.

> ✅ **Histéresis aplicada (Agosto 2026):** un enemigo que oscila en el borde de `AUTO_AIM_RANGE` hacía titilar el sonido loop del spray (start/stop por frame). Ahora, al perder el objetivo se concede una ventana de gracia (`AUTO_AIM_HYSTERESIS`): durante la gracia el disparo continúa **apuntando a la última dirección conocida** (se re-aplica `aiming.set_auto(self.auto_aim_out)` — `find_nearest` no muta el buffer al devolver `nil`), y si el objetivo reaparece dentro de la ventana **no hay ninguna interrupción** (ni sonido ni ráfaga). La gracia solo se concede si la sesión de disparo llegó a tener objetivo (`mobile_had_target`): pulsar spray sin enemigos sigue sin gastar nada. Estado reseteado en press/release/muerte.

### Fase 4 — Botón option = "tecla E" (el reto de los objetos juntos) ✅ IMPLEMENTADA

**Problema:** NPCs y objetos de exhibición muy próximos entre sí (ej: `ME_4946`(1627,1578) ↔ `ME_4947`(1672,1577) ≈ 45 uds; `ME_23982`(1664,1022) ↔ `ME_23983`(1632,1022) ≈ 32 uds; vitrinas en fila a ~30 uds). Un simple "enviar interact al más cercano" funciona pero deja al jugador sin saber *cuál* se llevará el click.

**Solución en dos capas (implementada, Agosto 2026):**

1. **Sensor de proximidad en el jugador** — collision object trigger **`collisionobject_interact`** añadido a `features/player/player.go` (patrón `player_spray`):
   - `type: COLLISION_OBJECT_TYPE_TRIGGER`, grupo **`"cursor"`**, máscara **`"interactivable"`**, caja ~120×120 (data 60,60,10 — coherente con el `INTERACTION_RANGE = 100` de `npc.script`).
   - **Truco clave (verificado):** todos los interactables del juego (NPCs `npc_01.go`, objetos `ME_16061.go`, `bookcase.go`, `kit_health.go`, `cat.go`…) ya usan `group: "interactivable"` + `mask: "cursor"` — el mismo par que usa `cursor.script` → **no hay que tocar ~100 archivos `.go`**.
   - **Cambio de diseño respecto al plan:** en lugar de GO hijo, el sensor es **componente + collision object en `player.go`** (patrón `player_spray`). Ventajas: `lock_dialog`/`unlock_dialog` llegan gratis (dialogue_manager los postea al GO `/player`), y la URL `level_01:/player#player_interact` usa el patrón ya verificado de `level_01:/player#player_spray`.

2. **`features/player/mobile_interact.script` (nuevo)** — componente `player_interact`:
   - Mantiene `self.nearby` (mapa `tostring(url) → url`, patrón `cursor.script`), alimentado por `trigger_response` (GOTCHA #5: `other_group`, mensaje `trigger_response` por ser trigger↔trigger).
   - **Selección del más cercano al jugador** en `update()` (misma técnica de distancia mínima que `cursor.script`), con limpieza de GOs destruidos (`go.exists`).
   - **Feedback visual continuo:** si el objetivo actual cambia → `mouse_hover {enter=false}` al anterior y `{enter=true}` al nuevo. **Todos los interactables ya reaccionan al hover con tint** (verificado: `npc.script` → highlight, `bookcase`, `slot_furniture`, `doors`, `exhibition_object`…). El jugador ve resaltado el objetivo antes de pulsar → resuelve la ambigüedad de objetos juntos.
   - Al recibir `mobile_interact {pressed=true}`: `msg.post(target, "interact")`.
   - Gates de estado: `player_died`/`player_respawned` (reenviados por `player.script` junto a los de `player_spray`) y `lock_dialog`/`unlock_dialog` (llegan solos, mismo GO) → no interactuar muerto ni en diálogo.
   - Activación solo en táctil: `platform.is_touch()` (en escritorio el sensor no resalta ni responde — el ratón sigue usando el cursor).

**Archivo:** `web_controls.gui_script`
- `btn_option` → `msg.post("level_01:/player#player_interact", "mobile_interact", { pressed = true })` (disparo único, no mantenido).

**Opcional (refinamiento futuro):** raycast de línea de visión del jugador al objetivo con grupo `walls` (API `physics.raycast(from, to, groups)` — GOTCHA #2) para no poder interactuar a través de paredes.

### Fase 5 — Neutralizar el ratón en táctil (conflicto latente) ✅ IMPLEMENTADA

**Archivo:** `main/cursor.script`
- En móvil, un toque dispara también los actions single-touch `touch`/`click` (MOUSE_BUTTON_1). El cursor queda estático en su posición de spawn y podría interactuar con objetos cercanos al pulsar un botón de la GUI (toques fantasma).
- Si `platform.is_touch()` → **cursor neutralizado por completo**:
  - `handle_input` retorna inmediatamente (se ignoran clics y movimiento).
  - `init()` desactiva el collision object del cursor (`msg.post("#collisionobject", "disable")`) → sin `trigger_response` → sin hover ni interact fantasma desde el cursor estático.
  - `on_message` con guard `if self.touch_active then return end` (defensa en profundidad).
- La interacción en móvil pasa al botón option (sensor `mobile_interact`, Fase 4). En escritorio el cursor funciona igual que siempre.

### Fase 6 — Layout en pantalla real ⏳ PARCIALMENTE IMPLEMENTADA

> ✅ **Overlay de rotación (implementado, `assets/custom_template.html`, Ago 2026):**
> el template muestra un aviso "Rota tu dispositivo" a pantalla completa cuando el
> viewport es portrait en un dispositivo táctil: `@media (orientation: portrait) and
> (pointer: coarse)` — CSS puro, sin JS y sin recursos externos (compatible con el
> `COEP: require-corp` del template). Funciona en la vista por defecto y en fullscreen
> (la media query se evalúa contra el viewport real). El guard `pointer: coarse` evita
> mostrarlo en escritorio.
>
> 📱 **Fullscreen en móvil: analizado y NO implementado (decisión Opción C, Ago 2026):**
> se evaluó pedir pantalla completa cuando el dispositivo gira a landscape. Veredicto
> de compatibilidad (MDN Fullscreen API + fuentes oficiales):
>   • **Android Chrome:** `requestFullscreen()` funciona y **sobrevive al giro** (no sale
>     de fullscreen al rotar; reajusta el layout), PERO exige gesto de usuario
>     (transient activation) — el evento `orientationchange` NO cuenta como gesto →
>     no se puede auto-fullscreen "al girar". El patrón viable sería fullscreen en el
>     PRIMER toque (listener JS de `touchstart` con guard `pointer: coarse` + catch de
>     la promesa rechazada; en iOS es no-op).
>   • **iPhone Safari:** la Fullscreen API NO existe para canvas/div (solo
>     `webkitEnterFullScreen` en `<video>`). Única vía a pantalla completa real:
>     modo standalone PWA ("añadir a pantalla de inicio") — ya soportado por las meta
>     tags `apple-mobile-web-app-capable`/`mobile-web-app-capable` del template.
>   • **Salir de fullscreen al volver a portrait: NO recomendado** — el overlay de
>     rotación ya tapa toda la pantalla en portrait (fullscreen vs ventana es
>     indistinguible visualmente), salir provoca re-layout del canvas con riesgo de
>     WebGL context loss (pantalla negra/recarga), y el comportamiento sería
>     inconsistente entre plataformas (iOS no tiene fullscreen que "sacar"). Patrón
>     estándar de juegos web: entrar una vez (gesto del jugador) y quedarse hasta
>     que el usuario salga (deslizar hacia abajo / botón atrás / ESC).
>   • **Si algún día se implementa:** todo en `custom_template.html` (JS puro, sin tocar
>     Lua), **desacoplado de la orientación** — nunca enlazar el estado de fullscreen
>     con la rotación (entrar en el primer toque, salir solo por gesto del sistema).
>
> >
> ✅ **Mínimo de toque en botones del quiz (implementado, Ago 2026):** el
> auto-ajuste ya crece los botones con textos largos, pero el mínimo era 40 uu
> (unidades de escena) → ~20px reales en móvil landscape, por debajo del
> estándar de toque (44/48px). Ahora `auto_size_button` calcula
> `min_height = max(40, 48 × get_dpr() / fit)` con `get_gui_fit()`
> (window.get_size() vs ref 1280×768, clamp defensivo ≥0.4) → ≥48px CSS reales
> de hitbox (el contenedor/pick crece con el fondo). ⚠️ **Corrección DPR
> (GOTCHA #11 de docs/DEV_GOTCHAS.md):** con `display.high_dpi=1` en HTML5,
> `window.get_size()` devuelve el buffer FÍSICO (CSS × DPR), así que sin
> `get_dpr()` (html5.run('window.devicePixelRatio'), síncrono, patrón
> platform.lua) el mínimo en móvil se quedaba en 40 uu — sin cambio visible.
> En native DPR=1 → la fórmula equivale a `max(40, 48/fit)`. Con botones más altos, `reposition_quiz_buttons`
> usa un **gap adaptativo**: el ancla sigue siendo el borde del botón 1 del
> editor (layout desktop idéntico al editor), y el gap se encoge (mín. 8) solo
> cuando la pila no cabe entre el ancla y el borde inferior del panel — así en
> móvil la pila comprimida no desborda el panel (fix del code review).
>
> ✅ **Ocultar controles durante el quiz (implementado, Ago 2026):** el joystick
> (abajo-izquierda) solapa con los botones de respuesta del quiz (`interactive.gui`,
> panel en x∈[18,378] — mismo lado) y capturaría los toques (render order 5 > 1).
> Ahora `interactive.gui_script` avisa con `quiz_state {active}` al abrir/cerrar el
> quiz → `web_controls` oculta los controles (mismo patrón que `pause_state`).
>
> ✅ **Ocultar controles durante la lectura de libros (implementado, Ago 2026):**
> `library.gui_script` avisa con `library_state {active}` al abrir/cerrar la biblioteca
> → `web_controls` oculta los controles (mismo patrón que `pause_state`/`quiz_state`).
> Facilita la lectura (los controles no aplican y flotarían encima, render order 5 > 3);
> se restaura y resetea el D-pad al cerrar.
>
> ✅ **Botón de pausa táctil (implementado, Ago 2026):** nuevo nodo `btn_pause` en
> `web_controls.gui` → `web_controls.gui_script` envía `request_pause` a
> `bootstrap:/gui_library#pause`, que activa la pausa con el MISMO gating que la
> tecla P (`pause_enabled` + no ya pausado). Reanudar se hace desde el menú
> (`btn_resume` ya acepta toques vía single-touch). Además, el menú de pausa avisa
> con `pause_state {active}` para que los controles táctiles (render order 5 > 4)
> se oculten mientras está abierto y no queden flotando encima; al cerrarse se
> restauran y se resetea el D-pad.
>
> ✅ **Fondo del menú de pausa a pantalla completa (implementado, `gui/pause.gui`, Ago 2026):**
> el nodo `pause_background` (box negro 1280×780) dejaba bandas letterbox al cambiar el
> aspect de la ventana porque estaba en `FIT` (default de los nodos). Se aplicó el patrón
> declarativo del fondo de `hud.gui` (GOTCHA #9 de `docs/DEV_GOTCHAS.md`): `size 2560×1560` (2×)
> + `scale 0.5` + `adjust_mode: ADJUST_MODE_ZOOM` → cubre toda la pantalla en cualquier
> resolución y orientación. **100% en el `.gui`, sin scripts** (el intento anterior por
> script — `set_screen_size`/`cover_background` — se revirtió por romper el menú).
>
> ✅ **Retención de la intro hasta landscape (implementado, `intro/intro_animation.script`, Ago 2026):**
> el overlay tapa la intro en portrait, pero el juego seguiría corriendo detrás (timers
> y música). Decisión confirmada: en `init()`, si `platform.is_touch() and is_portrait()`
> (alto > ancho vía `window.get_size()`), NO se arranca el timeline — `update()` espera
> (polling, patrón web_controls) hasta que la ventana esté en horizontal y solo entonces
> se lanza `start_animation()` completo (música incluida). El jugador ve SIEMPRE la
> animación desde el principio al rotar. Desktop intacto (`is_touch() false`).
>
> ✅ **RESUELTO (Fase 7c, ver sección propia):** el título de la intro no se veía en
> móvil porque la intro NO tenía cámara (el render por defecto proyecta según el
> canvas real, no según la referencia 1280×768) — el label `title_es` en mundo
> (640,500) caía fuera del área visible. Se añadió GO cámara en `intro.collection`
> en (640,384) con `orthographic_projection: 1` (zoom estático 1.0 = default) y el
> script ajusta `orthographic_zoom` en runtime a `cover = max(vis_w/1280, vis_h/768)`
> → el área visible siempre cubre el mundo 1280×768 (Opción B confirmada con el usuario).

### Fase 7c — Cámara dinámica de la intro (cover) ✅ IMPLEMENTADA

> **Archivo:** `intro/intro_animation.script` + cámara en `intro.collection`
>
> **Problema:** con la cámara estática en (640,384) zoom 1.0 (mundo 1:1, factor
> mundo→px = zoom×DPR — GOTCHA #11), la escena es una "ventana" fija de 1280×768:
> en móvil landscape (960×432 CSS) el fondo se recorta y el jugador de la cinemática
> (y=137) queda FUERA del área visible; en ultra-wide el fondo no cubre (barras).
>
> **Solución (Opción B, confirmada):** zoom de cámara dinámico tipo *cover* —
> `camera.set_orthographic_zoom("/camera#camera", cover)` con
> `cover = max(vis_w / 1280, vis_h / 768)` y `vis = window.get_size() / get_display_scale()`
> (px CSS, GOTCHA #11 — misma fórmula que el adaptive zoom del manual oficial).
> Todo el mundo (fondo, título, jugador) escala como una
> UNIDAD → composición idéntica al diseño en cualquier proporción:
>
> ⚠️ **GOTCHA (Agosto 2026):** `go.set("/camera", "orthographic_zoom", cover)`
> (URL de GO sin fragmento) falla con `'/camera' does not have any property
> called 'orthographic_zoom'`. Las propiedades de componente requieren el
> fragmento (`#camera`); se usa la función dedicada del módulo camera
> (`set_orthographic_zoom`), presente en el motor 1.13 (verificado en el wasm).
>
> | Pantalla | cover | Resultado |
> |---|---|---|
> | PC 1280×768 | 1.0 | Sin cambios (composición del editor) |
> | Móvil 960×432 CSS | 0.75 | Zoom-out: se ve TODO el ancho del arte |
> | Ultra-wide 2560×1080 | 2.0 | Zoom-in: cubre y recorta el sobrante |
>
> **Detalles:** se recalcula en `init()` y por polling en `update()` solo si cambió
> `window.get_size()` (sin tocar el listener global de ventana, GOTCHA #6); guard
> `w<=0` para el primer frame HTML5. El zoom estático 1.0 del `.collection` queda
> como fallback del primer frame (indiferente en la práctica: `init()` lo
> sobrescribe). La GUI de la intro no se ve afectada (se renderiza aparte).
>
> ✅ **Material de los títulos (Ago 2026, GOTCHA #12):** los labels `title_es`/
> `title_en` NO respondían al zoom de cámara (se quedaban fijos en pantalla) porque
> el material de fuente por defecto tiene tag `"gui"` → se renderizan en espacio de
> pantalla, ignorando la cámara. Se creó `assets/fonts/font-df-tile.material` (copia
> con tag `"tile"`) y se asignó a los labels → ahora son labels de mundo reales y
> escalan con el cover como el fondo y el jugador. Esto además arregla el bug
> histórico de que el título no se veía en móvil (quedaba fuera de pantalla).

- `web_controls.gui` usa coordenadas absolutas de la resolución de referencia (1280×768): D-pad abajo-izquierda (~21,39 escala 3), spray (1084,75) y option (1193,75) abajo-derecha. **Estado: aceptado** — el tamaño de los controles en el móvil real se considera correcto (no se reescala).
- Si algún día hace falta: reposicionar/escalar desde el script según `window.get_size()` (patrón `screen_utils`, GOTCHA #6: `gui.set_screen_position` para screen space).

---

## 5. Riesgos y gotchas

| # | Riesgo | Mitigación |
|---|---|---|
| 🔴 | Multi-touch no puede compartir action con `MOUSE_BUTTON_1` (doc oficial) | Action nuevo `"touch_multi"` |
| 🔴 | GOTCHA #5: trigger↔trigger → `trigger_response` + `other_group` (nunca `contact_point_response`/`group`) | Sensor de proximidad como TRIGGER |
| 🔴 | GOTCHA #1: helpers globales colisionan entre scripts; las `local function` deben ir ANTES de `on_message` | Seguir estándar; verificar con `bash audit_globals.sh -q` (debe dar 0) |
| 🔴 | GOTCHA #4: nunca adivinar nombres de instancias de factory | Auto-aim usa `enemy_state.get_spawned()` + `go.exists()` |
| ⚠️ | `gui.pick_node` puede no detectar nodos deshabilitados/invisibles | Habilitar los nodos (contenedor y botones) al activar, no solo el contenedor |
| ⚠️ | Pausa (`set_time_step mode=1`) bloquea `on_input` del proxy pero NO los mensajes | Gating por forwarding de `scene_manager` (ya implementado) — no postear directamente al jugador sin pasar por su guard |
| ⚠️ | Alcance propio de cada interactable al recibir `interact` (npc exige rango ≤100; otros pueden no tenerlo) | Radio del sensor coherente (~120); verificar cada tipo en la Fase 4 |
| ⚠️ | Detección de plataforma HTML5 es asíncrona | `web_controls` consulta `is_detected()` con polling + timeout |
| ⚠️ | `touchdata.x/y` para `gui.pick_node` | Usar el mismo patrón que `hud.gui_script` (ya probado con el botón reintentar) |

---

## 6. Orden de implementación

1. **Fase 0** — Binding `touch_multi`. ✅
2. **Fase 1** — Montar GUI en bootstrap + `web_controls.gui_script` (activación por plataforma + señal de escena) + forward de `touch` en `scene_manager`. ✅
3. **Fase 2** — D-pad → movimiento (inyección de `input_event`). ✅
4. **Fase 3** — Spray + auto-aim (`mobile_spray` + `auto_aim.lua`). ✅
5. **Fase 4** — Botón option + sensor de proximidad + highlight del objetivo. ✅
6. **Fase 5** — Neutralizar cursor en táctil. ✅
7. **Fase 6** — Layout/posicionamiento en pantalla real. ✅ (overlay de rotación, retención de intro hasta landscape, fondo del menú de pausa a pantalla completa — patrón 2× + ZOOM; fullscreen automático descartado por decisión Opción C)
8. **Fase 7c** — Cámara dinámica de la intro (cover): título centrado y fondo cubriendo en cualquier proporción. ✅

**Validación por fase:**
- `bash audit_globals.sh -q` → 0 violaciones (GOTCHA #1).
- Build HTML5 sin errores (`bob.jar build` o el editor).
- Prueba en móvil real: movimiento D-pad, disparo con auto-aim, interacción con highlight del objetivo.

---

## 7. Decisiones pendientes (confirmar antes de implementar)

- [x] **Visibilidad durante la intro:** solo gameplay (vía señal de `scene_manager`).
- [x] **Auto-aim:** **enemigo más cercano en rango siempre** (confirmado Fase 3 — sin cono).
- [x] **Trigger inteligente:** **cortar el disparo sin enemigo en rango** (`SMART_TRIGGER = true` — confirmado Fase 3).
- [x] **Botón option:** un toque = interactuar con el objetivo resaltado (confirmado Fase 4).
- [x] **Orientación:** **overlay de rotación landscape** implementado en el template HTML5 (`@media (orientation: portrait) and (pointer: coarse)` — CSS puro, compatible con COEP, funciona en normal y fullscreen). Se permite portrait pero con el aviso de rotación
- [x] **Fullscreen en móvil:** **NO implementado** (decisión Opción C, ver nota en Fase 6). Android: posible solo con gesto de usuario (primer toque), no al girar; iPhone: imposible desde JS (solo PWA standalone); salir de fullscreen al volver a portrait no recomendado (WebGL context loss + overlay ya tapa en portrait).

---

## 8. Referencias

- `docs/plans/archive/INPUT_CONTROL_PLAN.md` — decisión de esquema móvil (Opción 5) y capa unificada `aim_direction`.
- `docs/DEV_GOTCHAS.md` — GOTCHAS #1, #2, #4, #5, #6, #9 (normas obligatorias para scripts, raycast, enemy_state, triggers, screen space y fondos a pantalla completa).
- `docs/DEFOLD_LUA_STANDARDS.md` — estándares de código Lua del proyecto.
- Manual oficial Defold: *Input* y *Mouse and touch input* (`defold.com/manuals/input`, `defold.com/manuals/input-mouse-and-touch`) — triggers touch single/multi, `action.touch`, restricción de nombres de action.
- `main/platform.lua` — detección de plataforma (ya implementada).
- `features/player/aiming.lua` — capa unificada de puntería (ya implementada).

---

*Última actualización: Agosto 2026 — ✅ Todas las fases implementadas. Plan archivado (Agosto 2026).*
