# 🎮 Plan de control de disparo — Opciones, pros y contras

> **Documento de análisis.** Estado: **✅ DECISIÓN EJECUTADA (Agosto 2026)** — la recomendación §8 (híbrido contextual) se siguió íntegra: escritorio sin cambios (Opción 1) y móvil con **Opción 5** (joystick + botón de disparo con auto-aim), implementada en `docs/plans/archive/MOBILE_CONTROLS_PLAN.md`. El gamepad twin-stick queda como opcional/futuro (no planificado). Archivo histórico: su valor es documentar el *porqué* de la elección (referencia para reconsiderar twin-stick/gamepad).
> Objetivo: evaluar las alternativas de control de disparo (inputs + dinámicas) para decidir el esquema de **escritorio web (GitHub Pages)** y el **esquema táctil (móvil)**.
> 🔗 Complementa a `docs/plans/archive/MOBILE_CONTROLS_PLAN.md` (implementación de la Opción 5) y a `docs/plans/GITHUB_PUBLISH_PLAN.md` (publicación).

---

## 1. Contexto del juego (factores que condicionan la decisión)

| Factor del juego | Valor | Impacto en la decisión |
|---|---|---|
| Enemigos | Cucarachas lentas (80 u/s), atacan en contacto, retroceden tras atacar (ver `enemy_cockroach.script`) | **La precisión milimétrica NO es crítica** — son objetivos lentos |
| Spray | Cono 25°, cadencia 0.05s, recursos 100 (gasta 1/partícula) (`player_spray.script`) | **Recursos escasos** → el disparo en vacío es castigado |
| Cámara | Sigue al jugador (top-down) | Apuntado siempre desde la posición del jugador |
| Interacción | Clic izquierdo = interactuar (cursor/bookcases) | En táctil habrá conflicto tap=interactuar vs tap=disparar |
| Técnico | **Doble espejo X** en `fire_particle` (`atan2(dir.x, dir.y)` + `SPRAY_OFFSET` invertido) con compensación en la puntería (`world_pos.x = camera_pos.x - (world_pos.x - camera_pos.x)`) | **Cualquier cambio de puntería debe resolver esto primero** |
| Arquitectura | `scene_manager` reenvía `input_event` a 7 targets (`input_targets`) | Añadir un joystick = solo sumarlo a la lista |
| Input bindings | Flechas + WASD (nuevo), espacio (spray), R/P/ESC/TAB, ratón (`touch`, `click`, `click_right`) | Base lista para mapear nuevas acciones |

---

## 2. Opción 1 — ACTUAL: puntería con ratón + clic derecho (o espacio)

**Inputs:** posición del ratón (apunta) + `click_right` / `key_space` mantener (dispara).
**Dinámica:** el spray apunta al punto del mundo bajo el ratón; dispara mientras se mantiene pulsado.

**Pros**
- ✅ Precisión absoluta (el jugador decide cada objetivo).
- ✅ Permite *kiting*: moverse en una dirección y disparar a otra (retirada con fuego).
- ✅ Estándar de escritorio: natural y sin curva de aprendizaje.
- ✅ Espacio como alternativa de teclado (accesibilidad).
- ✅ Ya funciona; la arquitectura está hecha.

**Contras**
- ❌ **Inviable en táctil**: no hay ratón ni clic derecho.
- ❌ Requiere coordinar ratón + teclado (dos manos).
- ❌ El parche del doble espejo X es frágil: cualquier refactor de puntería lo rompe (ya ocurrió).
- ❌ No aprovecha la escasez de recursos (puede gastar spray en vacío si el jugador apunta mal).

**Estado:** implementado y funcional en escritorio. Nota (Agosto 2026): `key_space` dispara hacia **FACING** (última dirección de movimiento) salvo que el ratón se haya armado por intención explícita (`click_right`); el kiting en vivo (ratón durante el disparo) solo aplica al disparo con clic derecho (`firing_source == "mouse"`).

---

## 3. Opción 2 — Doble joystick (twin-stick)

**Inputs:** joystick virtual izquierdo = movimiento; joystick derecho = apuntar + disparar.
**Dinámica:** disparo continuo en la dirección del joystick derecho mientras se mantiene.

**Pros**
- ✅ Independencia total movimiento/apuntado → kiting ideal.
- ✅ Estándar probado en móvil (Nuclear Throne, Enter the Gungeon, Geometry Wars).
- ✅ Dos dedos separados → sin conflicto con la zona de interactuar.
- ✅ Escalable a gamepad (joysticks analógicos reales) en el futuro.

**Contras**
- ❌ **Sobredimensionado para este juego**: los enemigos son lentos; el twin-stick es la solución de un bullet-hell, no de un juego de gestión de museo.
- ❌ Alta curva de aprendizaje y fatiga táctil en sesiones largas.
- ❌ Ocupa pantalla (dos zonas táctiles) y complica el HUD.
- ❌ En escritorio no aporta nada frente al ratón.
- ❌ Requiere resolver el doble espejo X **y** diseñar la zona muerta radial (deadzone) para evitar drift/jitter.

---

## 4. Opción 3 — Tap rápido (tap-to-shoot / tap-to-aim)

**Inputs:** tocar un punto de la pantalla → el spray dispara hacia ese punto.
**Dinámica:** tap único o mantener-pulsar para ráfaga continua hacia el punto.

**Pros**
- ✅ Muy intuitivo para usuarios casuales de móvil.
- ✅ Sin joysticks → libera pantalla.
- ✅ Simple de implementar (el `input_event` ya trae `screen_x/screen_y` y la conversión a mundo ya existe).

**Contras**
- ❌ **El dedo tapa el objetivo** (input occlusion): justo lo que quieres rociar queda bajo tu mano.
- ❌ **Malo para seguimiento continuo**: huir de una cucaracha mientras disparas exige re-tapear constantemente.
- ❌ **Conflicto directo con la interacción**: el tap ya está asignado a interactuar (cursor). Habría que distinguir "tap en objeto" (interactuar) de "tap en vacío" (disparar) — ambigüedad que frustra.
- ❌ Con recursos limitados, el tap en vacío gasta spray sin sentido.

---

## 5. Opción 4 — Disparo automático (auto-fire + auto-aim al enemigo más cercano)

**Inputs:** solo movimiento (joystick o teclado). El disparo es automático.
**Dinámica:** si hay un enemigo en rango, el spray apunta y dispara solo hacia el más cercano (o el de mayor prioridad).

**Pros**
- ✅ **Carga cognitiva mínima** — perfecto para el público casual de un juego de gestión.
- ✅ El jugador se centra en lo importante: moverse, gestionar recursos, explorar.
- ✅ **Precedente en el proyecto**: el gato ya detecta enemigos (GOTCHA #5: `trigger_response` con `other_group`).
- ✅ Encaja con la temática: eres el conservador del museo, no un soldado.

**Contras**
- ❌ **Quita agencia**: no puedes decidir "dejo esta cucaracha y rocío la de la esquina".
- ❌ **Con recursos escasos (100) es peligroso**: auto-fire descontrolado agota el spray → hay que priorizar por amenaza y **solo disparar si hay enemigo en rango** (nunca gastar en vacío).
- ❌ Riesgo de "flickering" de objetivo (el spray oscila entre dos cucarachas cercanas).
- ❌ Puede sentirse pasivo en escritorio, donde el ratón es más divertido.

---

## 6. Opción 5 — Botón de disparo + auto-aim asistido ⭐ (recomendada para móvil)

**Inputs:** joystick izquierdo (movimiento) + botón de disparo (mantener). La puntería se asiste: si hay un enemigo dentro del cono, el spray "se pega" ligeramente a él.
**Dinámica:** mantener el botón = disparar hacia el enemigo más cercano dentro del cono de asistencia; si no hay, hacia la dirección de movimiento.

**Pros**
- ✅ **Sensación de control** ("yo aprieto el gatillo") con la dificultad de apuntado táctil mitigada.
- ✅ **Aprovecha el cono de 25° existente**: la asistencia solo *expande* el cono hacia el objetivo más cercano, sin anular la puntería manual.
- ✅ Cadencia deliberada → el jugador controla el gasto de recursos (mantener = disparar, soltar = ahorrar).
- ✅ Patrón probado (Archero) y cómodo en móvil.

**Contras**
- ❌ Añade un botón al HUD móvil.
- ❌ Si el cono de asistencia es muy ancho, "el juego juega por ti" (uncanny valley); si es muy estrecho, se siente insensible — hay que calibrarlo.
- ❌ Requiere resolver el doble espejo X antes.

---

## 7. Opción 6 — Disparo por dirección de enfrentamiento (facing-direction)

**Inputs:** disparar (clic derecho/espacio/botón) hacia donde **mira o se mueve** el personaje.
**Dinámica:** el spray sale en la dirección de movimiento/última animación (`attack_walk_*`).

**Pros**
- ✅ **Muy simple**: sin puntería, sin joystick derecho, sin conflicto de input.
- ✅ El juego **ya tiene las animaciones por dirección** (`attack_walk_left/up_left/...`) → infraestructura lista.
- ✅ Cero ambigüedad táctil (mueves = disparas hacia donde te mueves).

**Contras**
- ❌ **Inflexible**: no puedes huir de una cucaracha y dispararle a la vez (kiting hacia atrás imposible) — y el juego tiene enemigos que atacan al contacto, donde huir disparando es la estrategia natural.
- ❌ Frustrante acorralado (la única defensa es girarte hacia el enemigo).
- ❌ Con recursos escasos, disparar al moverte desperdicia spray.

---

## 8. Opción 7 — Híbrido contextual (recomendación estratégica)

El juego tiene dos públicos — **escritorio web** (GitHub Pages) y **móvil futuro**. No hay un solo esquema correcto; hay un **esquema por plataforma**:

| Plataforma | Esquema recomendado |
|---|---|
| **Escritorio (web)** | Mantener el actual: ratón + clic derecho (+ espacio). Es preciso y estándar. |
| **Móvil** | Joystick izquierdo (movimiento) + **botón disparo con auto-aim asistido** (Opción 5), con priorización por amenaza y solo dispara si hay enemigo en rango (protege los 100 de recursos). |
| **Gamepad (futuro)** | Twin-stick clásico (Opción 2) — el mismo código de "dirección de puntería" sirve para los tres. |

**La clave técnica:** todo se reduce a **unificar la "fuente de puntería"** (`aim_direction`) en una capa única (ratón / joystick derecho / auto-aim). Ese refactor **resolvería de paso el doble espejo X** — la opción de arreglar `fire_particle` (la "Opción B" del análisis previo: quitar el espejo de la puntería, corregir `atan2`/`SPRAY_OFFSET`), que hoy impide tocar el sistema con seguridad.

---

## 9. Orden de implementación sensato

1. **Unificar la puntería** (capa `aim_direction` + resolver el doble espejo X en `fire_particle`) — base para todo lo demás.
2. **Escritorio:** queda como está (sin cambios).
3. **Móvil:** joystick movimiento + botón con asistencia de cono (la opción que mejor encaja con la escasez de recursos y el ritmo lento del juego).
4. **(Opcional/futuro)** Gamepad twin-stick reutilizando la misma capa de puntería.

---

## 10. Checklist de decisión (✅ cerrado — Archivado Ago 2026)

- [x] Opción 1 (ratón + clic derecho): **implementado y funcional en escritorio** — sin cambios previstos.
- [x] Confirmar si el móvil es objetivo real de la publicación → **SÍ (resuelto de facto):** el juego se prueba y ajusta en HTML5 móvil (picking del sensor táctil, GOTCHA #31) y `GITHUB_PUBLISH_PLAN` incluye la fase de controles táctiles.
- [x] Decidir esquema móvil → **Opción 5 (botón + auto-aim)**: decidida e implementada en `MOBILE_CONTROLS_PLAN` (Fase 3).
- [x] Diseñar la capa unificada `aim_direction` (ratón / joystick / auto-aim). ✅ **Implementado (Agosto 2026):** `features/player/aiming.lua` (fuentes `mouse/stick/auto/facing` con prioridad; `get_direction` zero-alloc).
- [x] Resolver el doble espejo X de `fire_particle` dentro de esa capa (quitar compensación de la puntería y arreglar `atan2`/`SPRAY_OFFSET`). ✅ **Implementado:** `atan2(-dir.x, dir.y)` + emisión hacia la mira en `fire_particle`; `get_attack_animation` corregido para direcciones reales (el jugador mira hacia donde dispara).
- [x] **Kiting solo con disparo de ratón + Space→FACING** (`firing_source` en `player_spray.script`). ✅ **Implementado (Agosto 2026):** bug "Space mientras se mueve → dirección impredecible" — el movimiento de ratón incidental/espurio durante el disparo con `key_space` armaba la fuente MOUSE (persistente, prioridad máxima) en un punto arbitrario, eclipsando a FACING y rotando la dirección al moverse el jugador. Fix: `self.firing_source` (`"mouse"` | `"space"`, se fija al pulsar, se limpia al soltar/`reset_firing`) — la rama de kiting exige `firing_source == "mouse"`, así que el ratón solo se arma con `click_right` (press/release o kiting en vivo) y `key_space` cae a FACING (dirección de movimiento).
- [x] Definir detección de plataforma en runtime (escritorio vs táctil) para activar el esquema correspondiente. ✅ **Implementado (Agosto 2026):** `main/platform.lua` (módulo compartido, patrón `M = {}` como `game_state.lua`; conectado en `main.script` `init()`). **HTML5:** puente JS→Lua (patrón `save_manager.lua`: `html5.set_callback` + `Module.luaCallback`) que detecta táctil con la técnica fiable 2025-2026 — `matchMedia('(pointer: coarse)')` + `navigator.maxTouchPoints` + `'ontouchstart' in window`. **Nativo:** `sys.get_sys_info().system_name` (`"Android"`/`"iOS"`/`"iPhone OS"` → móvil; `"Darwin"` queda fuera por ambigüedad con macOS). API: `detect()`, `is_html5()`, `is_mobile()`, `is_touch()`, `pointer_type()`, `is_detected()`. ⚠️ La entrega de `Module.luaCallback` no se garantiza síncrona: los consumidores deben consultar tras un frame o usar `is_detected()`. **Resuelto:** el esquema táctil (joystick + botón con auto-aim, Opción 5) se activó al decidir el esquema móvil — implementado en `MOBILE_CONTROLS_PLAN`.

---
*Última actualización: Agosto 2026 — ✅ Decisión ejecutada. Plan archivado (Agosto 2026).*
