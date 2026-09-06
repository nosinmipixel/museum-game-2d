# 🏛️ Top Down Museum Game - Project Summary

> **Engine:** Defold  
> **Language:** Lua  
> **Resolution:** 1280×768  
> **Title:** Top Down Museum Game  
> **Current Date (of last summary):** August 13, 2026

---

## 📋 Overview

Educational/exploration top-down game where you play as a **museum conservator**. The core gameplay loop involves:

1. **Exploring** the museum environment
2. **Interacting with NPCs** (visitors) via dialogue trees with quiz questions
3. **Eliminating pests** (cockroaches) using spray
4. **Viewing exhibition objects** with informational panels
5. **Managing resources** (health, spray) via a HUD

---

## 🗂️ Project Structure

```
/
├── bootstrap.collection             # Colección raíz (nunca se descarga)
├── intro.collection                 # Escena de introducción
├── level_01.collection              # Nivel principal (cargado por proxy)
├── game.project                     # Defold project configuration
├── input/game.input_binding         # Keyboard & mouse bindings
│
├── main/
│   ├── scene_manager.script         # Gestor de escenas + enrutador de input
│   ├── main_loader.go               # GO portador del scene_manager
│   ├── proxy_intro.go               # Collection proxy para intro.collection
│   ├── proxy_level_01.go            # Collection proxy para level_01.collection
│   ├── main.script                  # Game manager: load/save, dev key R, goto_intro
│   ├── game_state.lua               # Shared state module (globals, NPC progress, callbacks)
│   ├── persistence.lua              # Save/load system with migration support
│   ├── dkjson.lua                   # JSON library
│   ├── dialogue_manager.script      # Dialogue flow controller
│   ├── npc.script                   # NPC behavior (shared across all NPCs)
│   ├── exhibition_manager.script    # Exhibition info panel manager
│   ├── spawn_enemies.script         # Enemy spawner via factory
│   ├── camera.script                # Smooth follow camera with lerp
│   ├── cursor.script                # Mouse cursor (handle_input + forwarding)
│   ├── game_manager.go              # Collection: dialogue_manager, main, exhibition_manager, sounds
│   └── intro/
│       ├── intro_manager.script     # Lógica de intro (idioma, continuar, reset, start)
│       ├── intro_animation.go       # Animación inicial: fondo, títulos bilingües
│       ├── intro_animation.script   # Control de animación con timers (6s)
│       ├── player_intro.go          # GO del jugador que camina al centro
│       └── gui/
│           ├── intro.gui            # GUI de intro
│           └── intro.gui_script     # GUI de intro: hover + mouse_event + marquee INTERMITENTE del aviso de guardado (HTML5)
│
├── features/
│   ├── player/
│   │   ├── player.script     # Movement, animations, dialog lock, attack, walk sound
│   │   ├── player_spray.script # Spray weapon system (resource management, particle creation)
│   │   ├── player.go         # Components: scripts, sounds, sprite, collision objects
│   │   └── player.atlas      # Player sprite animations (idle, walk L/R/U/D, talk, attack)
│   │
│   ├── enemy_cockroach/
│   │   ├── enemy_cockroach.script # AI: SPAWN→APPROACH→RETREAT→IDLE→DEATH
│   │   ├── enemy_cockroach.go     # Components: script, sounds, sprite, collision objects
│   │   └── enemy_cockroach.atlas  # Cockroach animations (walk, attack, death)
│   │
│   ├── npc_01/  to  npc_11/  # Individual NPC definitions (up to 20 supported)
│   │   ├── npc_XX.go         # NPC game object
│   │   └── npc_XX.atlas      # NPC sprite
│   │
│   ├── exhibition_objects/
│   │   ├── exhibition_object.script # Interactive object: hover, click, info panel
│   │   ├── ME_16061.go       # Exhibition object instance
│   │   └── ME_45681.go       # Exhibition object instance
│   │
│   ├── enemy_rat/
│   │   └── enemy_rat.go     # Rat enemy: sounds, collision objects, sprite
│   │
│   ├── props/
│   │   ├── bullet.script     # Spray particle: movement, collision, self-destruct
│   │   ├── bullet.go         # Bullet game object
│   │   ├── doors.script      # Puertas interactivas (front/side/service)
│   │   ├── door_main.script  # Puerta automática principal
│   │   ├── door_front.go     # Puerta frontal interactiva
│   │   ├── door_side.go      # Puerta lateral interactiva
│   │   ├── door_service.go   # Puerta de servicio interactiva
│   │   ├── door_main.go      # Puerta automática principal
│   │   ├── door.atlas        # Atlas de sprites de puertas
│   │   ├── kit_health.script # Botiquín de salud (pickup)
│   │   ├── spray_can.script  # Bote de spray recargable (pickup)
│   │   ├── spray_spawn_container.script # Contenedor spawn/reposición spray
│   │   ├── zone_storage.go      # Zona de almacén → aviso de sala en text_alert (zone_alert.script)
│   │   ├── zone_intake.go       # Zona de sala de ingreso → aviso en text_alert
│   │   ├── zone_alert.script    # Aviso de sala: entrar en zone_* → nombre localizado en text_alert
│   │   └── props.atlas       # Prop sprites
│   │
│   ├── furniture/
│   │   ├── slot_shelf.go      # Estantería (shelf) — slot único + slot_furniture.script
│   │   ├── slot_showcase.go   # Vitrina (showcase) — slot único + slot_furniture.script
│   │   ├── slot_furniture.script # Script compartido muebles (shelf/showcase)
│   │   ├── bookcase.go        # Estantería de libros
│   │   ├── bookcase.script    # Script de estantería de libros
│   │   └── furniture.atlas    # Atlas compartido (slots + libros de bookcase)
│
├── main/
│   ├── audio_manager.script  # Gestor de audio: playlist + eventos (pila LIFO)
│   ├── audio_manager.go      # GO con audio_manager + 13 pistas embebidas
│   ├── audio_registry.lua    # Playlist/eventos/intro (fuente única de verdad)
│   ├── config.lua            # DEV_MODE / DEBUG + make_log()/dprint()
│   ├── spray_spawn_state.lua # Estado compartido spray container ↔ cans
│
├── gui/
│   ├── library.gui           # GUI de libro abierto
│   ├── library.gui_script    # Sistema de lectura de libros
│   ├── pause.gui             # Menú de pausa
│   ├── pause.gui_script      # Control de pausa + volumen
│
├── gui/
│   ├── interactive.gui       # Dialogue & quiz GUI layout
│   ├── hud.gui               # HUD layout (bars, counters)
│   ├── interactive.gui_script       # Dialogue bubbles & quiz GUI (handle_input + forwarding)
│   ├── hud.gui_script               # HUD (health bar, spray bar, counters) (handle_input + forwarding)
│   └── exhibition.gui_script        # Exhibition info panel GUI (handle_input + forwarding)
│
├── assets/
│   ├── texts/
│   │   ├── main_text_es.json       # Main dialogue, quizzes, character data (Spanish)
│   │   ├── exhibition_text_es.json # Exhibition object descriptions (Spanish)
│   │   └── objects_text_es.json    # Object texts (Spanish)
│   │
│   ├── fonts/
│   │   ├── FurniturVF.ttf          # Variable font for UI
│   │   ├── BoldPixels.ttf          # Pixel font for titles
│   │   ├── MatrixSans-Regular.ttf  # Sans-serif font
│   │   ├── MineMouseRegular.ttf    # Mouse-style font
│   │   ├── PixelIcons-Regular.ttf  # Icon font
│   │   ├── quiz.font              # Font resource for quiz
│   │   └── dialogs.font           # Font resource for dialogs
│   │
│   ├── sounds/                     # 50+ audio files
│   │   ├── background_*.ogg        # Background music (exploration, calm, fight, library, etc.)
│   │   ├── npc_*.ogg               # NPC dialogue sounds
│   │   ├── cockroach_*.ogg/sound   # Cockroach sounds (walk, attack, death)
│   │   ├── quiz_*.ogg/sound        # Quiz sounds (success, failure, spin-fail)
│   │   ├── player_walk.ogg/sound   # Footsteps
│   │   ├── spray.ogg               # Spray sound
│   │   └── ... (various SFX)
│   │
│   ├── tiles/
│   │   ├── level_map_1.tilemap     # Tilemap level layout
│   │   └── tiles_map_1.tilesource  # Tile source definitions
│   │
│   └── textures/
│       ├── quiz_images.atlas       # Quiz question images
│       ├── exhibition_images.atlas # Exhibition object images
│       └── exhibition_clic.atlas   # Clickable exhibition icons
│
├── docs/                           # Documentación del proyecto (GOTCHAS, planes, licencias)
│   ├── plans/                      # Planes activos/parciales (GITHUB_PUBLISH, MOBILE_CONTROLS...)
│   ├── plans/archive/              # Planes ejecutados/históricos (NEST_SYSTEM, REFACTORING...)
├── README.md                       # Portada del repo (GitHub)
├── LICENSE                         # GPL-3.0
│
└── build/                          # Compiled build artifacts (auto-generated)
```

---

## 🧠 Core Systems

### 1. Game State (`main/game_state.lua`)
Central shared state module using Lua module pattern. Manages:
- **Global variables:** health (100), skills (1), stamina (100), score (0), language (es), task counters (quiz, restoration, bugs, collection items), spray (current/max)
- **NPC progress:** Per-NPC `{ attempt, completed, available_after, unlocked }` for up to 20 NPCs
- **Callback system:** `register_callback(var_name, fn)` for reactive UI updates
- **Key functions:** `load()`, `save()`, `reset_all()`, `is_npc_available(id)`, `register_npc_success/failure(id)`, `get/set/add_to_global(key, val)`, `is_npc_unlocked(id)`, `unlock_npc(id)`, `on_npc_unlocked(callback)`
- **NPC attempt logic:** 3 attempts max per NPC, 60-second cooldown after failure
- **Unlock system (hook implementado, flujo pendiente):** `unlock_npc(npc_id)` pone `progress.unlocked = true`, guarda y notifica a los listeners registrados con `on_npc_unlocked(callback)` (con `pcall` — un error en un listener no rompe el desbloqueo). El `npc_spawn_manager` (ver §7.3) se suscribe y, al recibir `npc_unlocked`, coloca al NPC en su spawn point si `config.SHOW_ALL_NPCS` es false. **⚠️ Hoy nadie llama a `unlock_npc()`**: el flujo de desbloqueo está pendiente de definir (hilo argumental vs. libre albedrío — ver «🔮 Possible Next Steps»). Con `SHOW_ALL_NPCS = true` (valor actual) todos los NPCs aparecen siempre y el desbloqueo no tiene efecto visible.

### 2. Persistence (`main/persistence.lua`)
Save/load system using Defold's `sys.save`/`sys.load`:
- Saves to platform-specific location via `sys.get_save_file("mi_juego_museo", "savegame.dat")`
- **Migration system:** Auto-migrates old NPC IDs (npc1→npc_01, npc2→npc_02) and data versions
- Supports 20 NPCs (`npc_01` to `npc_20`), first 3 unlocked by default
- `get_all_npc_ids()` returns all NPC IDs

### 3. Player (`features/player/player.script`)
- **Movement:** WASD/Arrow keys, 150 speed, collision resolution against walls
- **🧥 CLOAKING — bloqueo por muro con desbloqueo por normal (Opción B, Ago 2026):** al presionar contra un muro (`dot(normal, dirección) < -0.3` en `contact_point_response`), el jugador se detiene firme (`is_blocked_by_wall`, histéresis → sin jitter) y guarda `blocked_normal` (la normal del ÚLTIMO contacto, refrescada en TODO contacto de muro para esquinas/pasillos). El desbloqueo es por el dato físico: en cuanto la dirección ACTUAL deja de oponerse a esa normal (`dot(direction, blocked_normal) >= -0.3` — deslizarse en paralelo, cambiar de dirección o que el muro desaparezca), se desbloquea AL INSTANTE sin soltar la tecla. Condiciones previas conservadas (`direction == 0` al soltar). **Historial:** la Opción A (grace period por timer de ausencia de contacto) se probó y descartó porque el motor no re-emite `contact_point_response` estando el jugador quieto contra el muro → el timer expiraba y reintroducía jitter (ver DEV_GOTCHAS y el backup `/tmp/player.script.backup_cloaking`). **Límite conocido:** si el muro desaparece manteniendo EXACTAMENTE la misma tecla (sin cambiar de dirección), el bloqueo persiste hasta cambiar de dirección o soltar — ningún enfoque sin timer lo cubre.
- **Animations:** idle, left, right, up, down, talk, attack_L/R/U/D, death (11f @8fps), respawn (3f @8fps), dead (1f frozen)
- **Dialog system:** Locks movement during conversation, can cancel with ESC
- **Walking sound:** Plays/Stops based on movement state
- **Death system:** Polling en `update()` cada 0.1s detecta health ≤ 0 → `trigger_death()` reproduce animación death + sonido, congela en frame `dead` tras 1.4s. El jugador queda bloqueado (`is_dead = true`) hasta pulsar el botón de reintentar.
- **💀 Causa de muerte discriminada (Ago 2026):** el handler de `taken_damage` registra el campo `source` del mensaje (`self.death_cause`); el coche envía `source = "car"` (las plagas no envían source). `trigger_death` pasa la causa al HUD (`show_retry_button{ cause }`) y este muestra un mensaje de derrota distinto: `dialogs.car_defeat` (atropello) vs `dialogs.fight_defeat` (plagas) — `get_defeat_text()` en `gui/hud.gui_script` con fallbacks en cascada, conservando la causa al re-renderizar por cambio de idioma.
- **Respawn flow:** ① Click retry → sonido ② Teleport a posición inicial ③ 1s de pausa (cámara se estabiliza con lerp) ④ Animación respawn (0.5s) ⑤ `is_dead = false`, health = 100, idle, desbloqueo completo.
- **Retry button:** Botón `btn_retry_container` en el HUD (posición dinámica al 75% de altura de pantalla, efecto hover con escala 1.1x y tinte verde), se muestra al morir y se oculta al reintentar.
- **Collision groups:** `player`, `player_enemies`, `player_spawn` (masks: walls, enemies, spawn)

### 4. Spray Weapon (`features/player/player_spray.script`)
- Fires spray particles towards mouse cursor direction
- Uses factory to create bullet objects from `/player_spray#factory`
- Resource-based: consumes `spray_current`, 100 max, configurable fire rate & cone angle
- Activates on right-click or spacebar
- Triggers player attack animation

### 5. Spray Particle (`features/props/bullet.script`)
- Moves in direction of creation rotation at configurable speed
- Gradually slows down (0.95 damping)
- **Escalado progresivo:** de `start_scale = 0.2` a `end_scale = 1.0` durante `scale_duration = 0.4` s vía `go.animate` (regla §8; la escala Z se mantiene en 1 para no alterar el orden de render; el trigger crece en sincronía con el visual)
- 0.5 second auto-destruct if no collision
- On trigger collision with enemy: sends `take_damage` message, self-destructs

### 5.1. Spray Can Pickup (`features/props/spray_can.script`)
Bote de spray recogible que restaura el recurso de spray:
- **Detección de proximidad:** Solo reacciona a hover/clic si el jugador está a ≤200 uds
- **Al recoger:** Restaura `spray_current` a `max_spray`, reproduce sonido `pick_up`, notifica al `spray_spawn_container` y se autodestruye
- **Si ya está lleno:** Muestra alerta con `hint_insecticide` desde textos generales
- **Efectos hover:** Escala 1.2x + tint aclarado (1.3, 1.3, 1.2)
- **Spawn index:** Lee `spray_state.pending_spawn` en init() para identificar su punto de origen
- **🪺 Variante insecticida (Fase 2, Ago 2026, ver docs/plans/archive/NEST_SYSTEM_PLAN.md):** si `pending_spawn.is_insecticide`, el bote usa el sprite `pickup_poison_nest` y al recoger otorga **1 carga de `nest_insecticide`** (tope `insecticide_max`, 2) en vez de rellenar spray. Mismo contrato de recogida (sonido `pick_up` + notificación + autodestrucción). Al máximo → alerta localizada `hint_insecticide_max`. En hover muestra el hint persistente `hint_hover_insecticide_poison` (patrón `show_persistent_alert`, GOTCHA #13: el exit siempre procesado para no colgar la alerta).
- **🗄️ Ocultación por armario (Ago 2026, simplificado):** los armarios mantienen una z **estable en el editor** (z 0.19 → sprite 0.20, delante del jugador en z 0.1; ya no se anima el z al abrir/cerrar) y los botes viven a z **0.22** (por encima del armario y de los frentes de puerta 0.21). La visibilidad es por **activación**: `office_cabinet.script` notifica `cabinet_state.set_open` al FINALIZAR la animación (callback del flipbook) y `spray_can.script` consulta `cabinet_state.get_open(pos)` en su `update()` — dentro de un armario CERRADO desactiva sprite + colisiones (ni hover ni clic); se activa al abrir y se desactiva si cierran sin recogerlo. Complementa el picking z-aware (GOTCHA #31): `cursor.script` usa z-first (punto preciso); el sensor móvil (`mobile_interact.script`) usa **facing-first** (el candidato más alineado con la dirección de movimiento del jugador; distancia solo como desempate) y excluye candidatos cubiertos por un armario cerrado + armarios abiertos con contenido (el bote interior es el objetivo). Facing-first es necesario porque la distancia GO-a-GO haría que un armario en el muro (GO 54 uds por encima del pasillo) perdiera siempre contra las puertas adyacentes, y que entre dos puertas simétricas solo ganara la más cercana al cruce. Además, el sensor puntúa contra el **punto de interacción** (centro de la caja cursor), no contra el GO: `doors.script` registra el suyo por tipo en `main/interactable_box.lua` (door_side +27 en x, door_front −10, door_service −5) y los armarios lo exponen vía `cabinet_state.get_center()`. Sin esto, apoyado en una puerta su GO (desplazado de la caja) queda detrás del jugador (dot negativo) y facing-first elige el armario de encima (caso door_side4 ↔ office_cabinet1).
- **🚶 Auto-cierre de armarios (Ago 2026):** si el jugador se aleja ≥ `cabinet_auto_close_distance` (**200** uds por defecto, configurable en `config.balance` → `main/config.lua`) dejando la puerta abierta, el armario se cierra solo en su `update()` (mismo patrón de distancia al cuadrado que `door_main.script`). Va por el MISMO `close_cabinet()` que el clic → la ocultación del interior (`cabinet_state.set_open(false)` al terminar la animación) se aplica igual: los botes no recogidos quedan ocultos. No se evalúa mientras hay animación en curso (`is_animating`) y no hay riesgo de flickering: al cerrarse no se vuelve a abrir solo (solo por clic).

### 5.2. Spray Spawn Container (`features/props/spray_spawn_container.script`)
Gestiona la creación y reposición de spray cans:
- **Detección dinámica:** Escanea hijos con naming `spray_spawn_01..NN` y guarda sus posiciones
- **Máximo activos:** `MAX_ACTIVE = 3` spray cans simultáneos
- **Inicialización:** Selecciona aleatoriamente MAX_ACTIVE puntos, crea spray cans via `factory.create()`
- **Reposición:** Al recibir `spray_picked_up{ spawn_index }`, marca el punto como libre y crea uno nuevo en otro punto aleatorio
- **Estado compartido:** Usa `main/spray_spawn_state.lua` para pasar `pending_spawn{ index, position, is_insecticide }` al spray can antes de `factory.create()` (factory es síncrono, sin condiciones de carrera)
- **🪺 Tirada de rareza (Fase 2, Ago 2026):** al crear/reponer cada bote tira `config.balance.nest.insecticide_chance` (0.18) → si acierta, el bote nace como **insecticida** (`is_insecticide = true`) en vez de spray (sprite `pickup_poison_nest`). 🔧 `config.DEBUG_ALL_INSECTICIDE = true` fuerza que TODOS los botes sean de veneno (solo pruebas; poner a `false` en producción)

### 5.3. Health Kit (`features/props/kit_health.script`)
Botiquín de salud que restaura la vida al máximo:
- **Al recoger:** Si health < 100, restaura a 100 y reproduce `pick_up`
- **Si ya está lleno:** Muestra alerta persistente con `hint_medkit` desde textos generales
- **Efectos hover:** Escala 1.2x + tint aclarado (1.3, 1.3, 1.2)
- **No se autodestruye:** Es reutilizable (a diferencia del spray can)

### 6. Enemy AI

#### 6.1. Cockroach (`features/enemy_cockroach/enemy_cockroach.script`)
State machine with 5 states:
| State | Behavior |
|---|---|
| `SPAWN` | Initial state, transitions immediately to APPROACH |
| `APPROACH` | Chases player, applies damage on collision (20 HP, 1.5s cooldown), triggers attack animation+sound, transitions to RETREAT |
| `RETREAT` | Flees from player for 1.8s (faster: 1.2x speed), then IDLE |
| `IDLE` | Stops for 1.2s, then APPROACH again |
| `DEATH` | Plays death animation, increments `task_bugs_total`, sound, deletes self after animation + 2s timeout |

- Collision groups: `enemies` (masks: `player_enemies`, `walls`, `spray`)
- Dodge behavior: random perpendicular direction when hitting walls
- Configurable properties: speed, damage, retreat_duration, idle_duration, health
- **Proximity Audio System:** `apply_proximity_audio(sound_url, player_pos, emitter_pos)` ajusta dinámicamente:
  - **Gain (volumen):** 100% a ≤100u, 0% a ≥1000u, interpolación lineal entre ambos
  - **Pan (estéreo):** -1.0 (izquierda) a +1.0 (derecha) según posición X relativa del jugador
  - Sonidos afectados: `walk` (loop, se actualiza cada frame en `update()`), `attack` y `death` (one-shots, se ajustan antes de `sound.play()` en `on_message()`)
  - Posiciones almacenadas como variables de instancia (`self.my_pos`, `self.player_pos`) para acceso cruzado entre `update()` y `on_message()`

#### 6.2. Rat (`features/enemy_rat/enemy_rat.go` + `enemy_rat.script`)

Segundo tipo de enemigo con su propio atlas de animaciones e **IA de embestida telegrafiada** (Ago 2026):
- **Animaciones:** walk (4 frames), idle (3 frames), attack (4 frames), death (6 frames)
- **Sonidos:** `rat_attack.sound`, `rat_death.sound`, `rat_squeak.sound` (⚠️ sin walk — se acerca en silencio)
- **Sistema de colisiones:** group `"enemies"`, mask `"player_enemies"` (contacto), mask `"walls"` (paredes), group `"enemy"`, mask `"spray"` (trigger para balas)
- **Máquina de estados:** `APPROACH → WINDUP → CHARGE → RECOVERY → APPROACH` (+ `DEATH`):
  | Estado | Comportamiento |
  |---|---|
  | `APPROACH` | Persigue al jugador a `speed` (50) hasta `charge_range` (260) |
  | `WINDUP` | Se detiene, suena `rat_squeak` + animación `attack` en bucle (amago telegrafiado, 0.6s) |
  | `CHARGE` | **Lock del objetivo al INICIO del amago** y embestida en línea recta a `charge_speed` (100). No se re-apunta → esquivable incluso en pasillos estrechos (basta moverse durante el amago). Daño SOLO aquí (una vez por carga) |
  | `RECOVERY` | Aturdida 1.2s tras llegar / chocar contra muro (crash) / timeout (vulnerable al spray) |
- **Propiedades configurables (editor):** `speed`, `damage` (default **35** vs 20 cucaracha), `health` (3 vs 1), `charge_range`, `windup_duration`, `charge_speed`, `charge_max_duration`, `recovery_duration`
- **Diferencias clave vs cucaracha:** daño mayor pero solo en la embestida (esquivable), 3 sprays para matar, sin sonido de aproximación (silencio → más tensión), la embestida se detiene contra muros (crash)
- **Nota:** la rata SÍ incrementa `task_bugs_total` al morir (mismo contador de plagas que la cucaracha)
- **Detalle sprite (verificado Ago 2026):** el arte de la rata mira al SUR (cabeza abajo) y el sprite del GO no tiene rotación horneada (eliminada en el editor) → el `look_at` de la rata compensa con **+90°** (`atan2 + π/2`). La cucaracha usa `atan2` plano con horneada de −90° (arte mirando al norte): **no copiar el look_at entre enemigos** sin verificar arte y rotación horneada de cada uno

#### 6.3. Cat Companion (`features/cat/cat.script`)

Gato del museo: un **acompañante** que patrulla, persigue/ataca enemigos y puede activar un **modo mascota (PET)** de seguimiento directo por estela. Es el sistema más complejo del proyecto.

**Archivos clave:** `features/cat/cat.script` (cerebro, ~1250 líneas), `features/cat/cat_nav.lua` (navegación con esquive de paredes), `features/cat/cat.go` (4 collision objects + sprite + sonidos), `features/cat/cat.atlas` (12 animaciones), `main/enemy_state.lua` (registro de ids reales de enemigos factory). Usa `features/npc/npc_patrol.lua` para la patrulla y `main/config.lua` para logs (`DEBUG_CAT`, `DEBUG_NAV`).

**Máquina de estados:** `INACTIVE → PATROL → INTERACT → CHASE → ATTACK`; y `INTERACT + (clic + comida) → PET → RETURN_PATROL → PATROL`.

**Propiedades configurables (go.properties, editor):** `patrol_enabled` (`true`), `patrol_speed` (`40`), `patrol_radius` (`200`), `activate_radius` (`300`, radio para despertar), `attack_damage` (`15`), `attack_cooldown` (`0.8`), `attack_range` (`20`), `pet_duration` (`180` s), `pet_follow_dist` (`60`, distancia ideal al jugador), `pet_max_dist` (`120`, máxima antes de acelerar), `pet_speed` (`150` px/s), `sit_idle_time` (`2.0` s de jugador quieto para sentarse).

| Estado | Comportamiento |
|---|---|
| `INACTIVE` | Oculto hasta que el jugador entra en `activate_radius` → PATROL |
| `PATROL` | `patrol.update()` de `npc_patrol.lua` + animación sincronizada (`sync_patrol_anim`); prioridad máxima: enemigo visible → CHASE; jugador fuera de rango → INACTIVE |
| `INTERACT` | Idle junto al jugador (≤100 u); enemigo visible → CHASE; jugador se aleja → PATROL |
| `CHASE` | Persigue a `current_enemy` con `nav.move_towards()` (esquive de paredes); verifica línea de visión cada frame; si está a `attack_range` → ATTACK |
| `ATTACK` | Con cooldown `attack_cooldown`: animación direccional (`attack_anim`, left/right según eje X), sonido `cat_attack` y `msg.post(enemy, "take_damage")`. Enemigo muerto → PATROL; se aleja > 2×rango → CHASE |
| `PET` | Modo mascota: sigue al jugador por **estela** (ring buffer), ataca enemigos con prioridad, se sienta (`idle_sitting`) si el jugador está quieto ≥ `sit_idle_time` |
| `RETURN_PATROL` | Al expirar `pet_timer`: vuelve al spawn con `nav.move_towards`, re-activa la colisión con el jugador y reinicia la patrulla |

**🐾 Modo PET — seguimiento por estela (estilo Fear & Hunger):**
- **Activación:** clic sobre el gato con `cat_food_count ≥ 1` (comida). Consume la comida, notifica al contenedor (`food_used`), muestra el hint `hint_cat_pet_start` y suena `cat_purr`. Sin comida: solo `cat_meow`.
- **⏱️ Pie timer del HUD (`box_pet_container`: `pie_timer_pet` + `box_icon_pet`):** reloj circular que se vacía 360° → 0° mostrando el tiempo restante del modo mascota; oculto e inactivo mientras el gato no está en PET. El gato envía `update_pet_timer { remaining, progress }` a 10Hz durante el PET y `hide_pet_timer` al salir (timer expirado o reset por muerte) — mismo modelo que `pie_timer_to_exhibition` (gui/hud.gui_script).
- **No-físico:** durante PET se desactiva `collisionobject_player` (grupo `npcs` ↔ `player_npcs`) para que **no empuje ni bloquee al jugador**; se re-activa al salir.
- **Estela (ring buffer):** `PET_TRAIL_SIZE = 300` entradas (~5 s @60 fps) con dedup ≥ 2 px. El gato avanza **waypoint a waypoint por el camino real del jugador** (transitable por construcción) hacia el punto de la estela a `pet_follow_dist`. Al no navegar en línea recta a un punto lejano, no se activan los raycasts de paredes ni la escalada de desatasco que causaban el comportamiento errático.
- **Cursor monótono (`pet_trail_off`):** offset del gato sobre la estela (+1 por entrada nueva del jugador, −1 por paso del gato). Evita el *parpadeo* de animación cuando el jugador vuelve sobre sus pasos y atraviesa al gato (la estela se pliega; el cursor nunca "salta" de lado). Latch de movimiento con histéresis `PET_RESUME_MARGIN = 2`.
- **Reincorporación (`PET_REJOIN_DIST = 40`, híbrida Ago 2026):** el reenganche se dispara tras combate (cursor de estela sin anclar, aunque el gato quede CERCA de la estela) o si el gato queda lejos de ella; usa `nav.move_towards` (con esquive). **Atajo directo:** si la línea gato→T (punto de seguimiento a `pet_follow_dist` del jugador ACTUAL, `has_clear_path` con raycast) está despejada de paredes, navega directo a T sin deshacer la estela plegada grabada durante el combate (caso típico: gato peleando junto al jugador). **Fallback:** si hay pared, rejoin al waypoint más cercano (C) y camino transitable por la estela. El avance directo normal no tiene recuperación de atasco (esa es la escalera N1-N4 de cat_nav).
- **Detección de atasco:** ventana de `PET_PROGRESS_INTERVAL = 0.15` s midiendo desplazamiento real (≥ `PET_PROGRESS_MIN = 6` px); si no progresa en `PET_STUCK_TIMEOUT = 0.6` s (empujando un muro), fuerza reincorporación con nav hacia el punto objetivo **T** (margen para rodear el muro).
- **🚪 Espera en puerta cerrada (Ago 2026):** si la estela cruza una puerta interactiva que el jugador cerró detrás de sí (imposible de rodear, empotrada en la pared), el atasco NO escala a la navegación N1-N4 (dejaba al gato errático): el gato **se sienta junto a la puerta, maúlla** (`PET_DOOR_MEOW_INTERVAL = 5` s) **y reanuda el seguimiento cuando la abran**. Detección sin raycasts: el `contact_point_response` contra el grupo `walls` expone el `other_id` del GO — si su nombre contiene `door_`, es una puerta (`wall_contact_is_door`). Para saber cuándo la abren, hace **avances de prueba** (`PET_DOOR_TRIAL_STEP = 8` px cada `PET_DOOR_PROBE_INTERVAL = 0.4` s) hacia el punto bloqueado: mientras la puerta siga cerrada la corrección `wall_push` deshace el avance y el contacto vuelve; si el avance deja de recibir contacto, la puerta se abrió (`doors.script` desactivó `collisionobject_npcs`) → reanuda. La reanudación usa el MISMO reenganche que tras combatir enemigos (`pet_trail_off = nil` + `pet_moving = false`): si la línea directa gato→T está despejada a través de la puerta abierta, el gato toma el **atajo directo a T** (acorta el recorrido); si hay pared, retoma la estela waypoint a waypoint. Sin este reset, el gato reandaba TODA la estela desde su cursor anclado (que siguió avanzando durante la espera) — el rodeo del jugador al otro lado en vez de cruzar recto por la puerta abierta. Aplica también si el reenganche (`rejoin`) choca con una puerta cerrada. Se limpia en `exit_pet`, al activar PET, al pasar a combate y en `reset_cat` (muerte del jugador).
- **Velocidad:** `pet_speed` (150) normal; `pet_speed × 2` si `dist_to_player > pet_max_dist`.
- **Idle_sitting + ronroneo:** si el jugador está quieto ≥ `sit_idle_time` → `idle_sitting` con **ronroneo en bucle** (`PURR_LOOP_INTERVAL = 4.5` s; el ogg dura ~5 s). Si el jugador se mueve, se levanta y detiene el ronroneo.

**⚔️ Combate en PET (prioridad sobre la estela):**
- Cada frame busca enemigos **visibles y cerca del jugador** (`find_visible_enemy_near`, radio 250 px + línea de visión).
- **TARGET LOCK con histéresis:** si `current_enemy` sigue siendo válido (vivo, < 250 px del jugador, con LOS) se **mantiene**; otro enemigo solo lo arrebata si está a < `PET_TARGET_SWITCH_FACTOR = 0.7` × la distancia del actual. Sin este lock, con varios enemigos equidistantes el target cambiaba de frame a frame (el gato "bailaba"). **Bug crítico corregido:** el lock solo se siembra si el enemigo es válido — si murió/salió de rango/sin LOS y no hay otro candidato, devuelve `nil` (nunca la URL muerta que rompía `go.get_position`).
- Si el enemigo está a `attack_range`: ataca (animación + sonido + `take_damage`); si no, se acerca con `nav.move_towards` (sin alejarse mucho del jugador).

**🔍 Detección de enemigos (vías de detección):**
1. **Ids reales registrados** en `main/enemy_state.lua` por el **propio enemigo en su `init()`** (`enemy_state.register(go.get_id())` en `enemy_cockroach.script`/`enemy_rat.script` — GOTCHA #4 y #26: cubre por igual los estáticos del editor y los de factory; adivinar `"enemy_cockroach1"` era la causa de no detectar a las del grupo).
2. **Cucaracha estática** del `level_01.collection` (`/enemy_cockroach`) y **rata fija** (`/enemy_rat`) por naming directo.
3. **Trigger de proximidad** (`collisionobject_enemy`, TRIGGER group `spray` mask `enemy`): escucha `trigger_response` con `other_group == hash("enemy")` (GOTCHA #5: entre dos TRIGGERS el engine envía `trigger_response`, no `contact_point_response`).

**👁️ Línea de visión (`has_line_of_sight`):** `physics.raycast(my_pos, target_pos, { hash("walls") }, { all = true })` — si algún hit es del grupo `walls`, no hay visión. Dos GOTCHAs encadenados: **#43** (la máscara era el grupo inexistente `collision_object` → el raycast no golpeaba nada) y **#44** (sin el 4º argumento `{ all = true }` el raycast síncrono devuelve los campos del hit a nivel superior de la tabla, NO una lista → `ipairs` no iteraba → LOS siempre `true`). Ambos hacían que el gato "viera" y atacara enemigos a través de los muros. Usada en CHASE/ATTACK/PET: el gato ignora a los enemigos sin línea de visión (no los persigue ni ataca en vano).

**🧭 Navegación (`features/cat/cat_nav.lua`):**
- `nav.move_towards(self, target, speed, dt)` → `true` si llegó (≤ `ARRIVED_DIST = 10`). Movimiento directo con **snap a 8 direcciones** (`snap_to_eight_dirs`), raycast frontal (`FRONT_PROBE = 30`) para detectar paredes y **esquive con wall-following** (elige la tangente de la pared que apunta al objetivo usando la normal del `contact_point_response` o del raycast).
- **Recuperación progresiva de atascos** (mide desplazamiento real entre frames; el nivel crece, nunca decrece hasta moverse): N1 (0.4 s) blend 60% lateral + 40% forward; N2 (1.0 s) wall-following por tangente; N3 (2.0 s) dirección opuesta al objetivo; N4 (3.0 s) dirección aleatoria ciclando cada 0.5 s.
- Las normales de pared se pasan desde `cat.script` (`self.nav_wall_normal`) porque el raycast apunta al target y no detecta paredes laterales.

**Colisiones (`cat.go`):** `collisionobject_player` (KINEMATIC, group `npcs`, mask `player_npcs`), `collisionobject_walls` (KINEMATIC, group `npcs`, mask `walls` — empuja al gato fuera de paredes acumulando `wall_push_pos/neg`), `collisionobject_enemy` (TRIGGER, group `spray`, mask `enemy`), `collisionobject_cursor` (KINEMATIC, group `interactivable`, mask `cursor` — hover/clic del cursor).

**Animaciones (`cat.atlas`):** `idle`, `idle_sitting`, `walk_left/right/top/down`, `run_left/right/top/down`, `attack_left/right`. `walk_anim` elige run/walk según si `speed > patrol_speed` y la dirección por eje dominante (`dy > 0 → _top`, convención de `npc.script`).

**Sonidos:** `cat_meow` (interacción sin comida), `cat_purr` (ronroneo PET), `cat_attack` (ataque), `cat_angry` (daño recibido: `take_damage`/`hit` → maullido de queja).

**Mensajes recibidos:** `mouse_hover` (hover, solo fuera de PET; resalta sprite + hint), `interact` (clic → `on_interact`), `trigger_response` (enemigos), `contact_point_response` (paredes), `take_damage`/`hit`. **URLs cacheadas en `init()`** (regla #4): `self.hud_url`, `self.sprite_url`, `self.player_url`.

> ⚠️ **Referencia cruzada:** la detección de enemigos del gato ilustra los **GOTCHAS #4 y #5** de `docs/DEV_GOTCHAS.md` (naming de instancias factory vs editor; `trigger_response` vs `contact_point_response`). Ver sección «🔧 Conventions & Patterns».

#### 6.4. Enemy Nest System (`features/enemies/nest.go` + `nest.script`)

🪺 Sistema de **nidos de enemigos** (Ago 2026, ver `docs/plans/archive/NEST_SYSTEM_PLAN.md`): emisores persistentes que reutilizan `spawn_enemies.script` (trigger, oleadas escalonadas, `reactivate_delay`, guards de muerte) y que el jugador puede eliminar con **insecticida especial** para frenar la plaga de forma estratégica.

- **Arquitectura:** `features/props/nest_container.go/.script` descubre los marcadores `nest_spawn_01..10` (hijos del editor a z 0.01, sin arte) y crea **5 nidos activos** vía factory `#nest_factory` en puntos aleatorios. Al destruir uno, repone otro en un punto libre hasta agotar los 10 (la plaga tiene 10 "vidas"). El puente contenedor↔nido es `main/nest_spawn_state.lua` (`pending_spawn`, `container_url`, `mark_destroyed`/`is_destroyed` — GOTCHA #4: `factory.create` no acepta id; GOTCHA #33: flags de módulo).
- **GO del nido (`features/enemies/nest.go`):** `spawn_enemies.script` (oleadas; exige el collisionobject `#collisionobject` TRIGGER, group `spawn`, mask `player_spawn`, esfera r=50) + `nest.script` + `collisionobject_interact` (group `interactivable`, mask `cursor`, hover/clic) + sprite `nest_idle` + `bug_factory`/`rat_factory` + sonido `nest_plague_destruction`. Sprite a **z 0.01** → los enemigos nacen POR ENCIMA del nido (orden de render correcto, GOTCHA #9).
- **Guard de nido destruido (`main/spawn_enemies.script`):** `nest_spawn_state.is_destroyed(go.get_id())` en los callbacks de timer (inicio de oleada, escalonado y reactivación) → un nido destruido no emite bichos fantasma ni ruido de consola. Sin cambio de comportamiento para el spawner standalone (id no registrado → false).
- **Destrucción (`nest.script`):** hover → tint rojizo animado; clic con `nest_insecticide > 0` → consume 1 carga, suma `nest_bonus` (+5) a `task_bugs_total` (tarea de plagas **híbrida**, PESTS_MIN=20: el grind siempre es posible), marca el nido destruido, **purga** los enemigos vivos en radio 100, reproduce `nest_destruction` + sonido, notifica al contenedor (`nest_destroyed{ spawn_index }`) y se borra. Sin cargas → alerta localizada `alert_no_insecticide`.
- **Insecticida (recurso raro):** ver §5.1/§5.2 — el `spray_spawn_container` tira `config.balance.nest.insecticide_chance` (0.18) por bote; el `spray_can` nace como veneno con `is_insecticide` y otorga cargas de `nest_insecticide` (tope `insecticide_max = 2`).
- **HUD (Fase 4):** icono `box_icon_poison` + contador `text_icon_poison` ("x/2") en `gui/hud.gui_script` vía `refresh_insecticide_icon`, **ocultos hasta la 1ª carga** (patrón `box_icon_cat_food`). Los 4 frames `icon_poison_nest_01..04` están registrados en `images` de `gui/gui.atlas` (GOTCHA #8).
- **Configuración:** `main/config.lua` → `M.balance.nest` (`nest_bonus = 5`, `insecticide_chance = 0.18`, `insecticide_max = 2`, `enemy_despawn_distance = 400`) y `M.balance.nest_ranges` (Fase 3): `total_enemies` 3..5, `spawn_interval` 2.5..5.0 s, `spawn_radius` 15..30, `reactivate_delay` 8..20 s y `enemy_types` {cockroach, rat, mix} — consumidores con fallback (una clave borrada nunca rompe el juego).
- **🚶 Despawn por distancia (Ago 2026):** los enemigos de nido (flag `from_nest` puesto por `spawn_enemies.script` en `factory.create` solo cuando `use_nest_ranges`) **desaparecen si el jugador se aleja sin interactuar** — fuera de pantalla (400 uds > lo visible a zoom 2.0: ~373 en la esquina) y el nido los re-emite al volver (trigger r=50). Reglas: **solo nidos** (estáticos del editor y spawners standalone persisten como siempre), **solo sin interacción** (`engaged` se activa si el enemigo recibe daño o golpea al jugador → se queda hasta morir), nunca en pleno ataque (la distancia cubre el charge_range 260 de la rata), sondeo throttled 0.5s con distancia² (zero-alloc) y limpieza de sonidos antes de `go.delete()` (mismo patrón que `handle_damage`). Pone **techo natural a la acumulación de oleadas** (buffer de colisión fijo, GOTCHA #27). Las muertes perdidas no suman a `task_bugs_total`, pero el nido sigue emitiendo al volver (grind intacto) y el bonus por destrucción (+5) mantiene la tarea híbrida viable.
- **Rangos aleatorios de oleada (Fase 3, Ago 2026):** `spawn_enemies.script` admite propiedades `_max` opcionales (`total_enemies_max`, `spawn_interval_max`, `spawn_radius_max`, `reactivate_delay_max`): si `x_max > x`, CADA oleada tira un valor uniforme en `[x, x_max]` (`roll_range`); con `x_max = 0` o ≤ x el comportamiento es idéntico al original (backwards-compatible, los spawners del editor no cambian). Los nidos (flag `use_nest_ranges: true` en `nest.go`) leen `config.balance.nest_ranges` y eligen `enemy_type` AL AZAR POR NIDO en `init()` → los 5 nidos no son clones.
- **Muerte/reintentar:** los nidos son instancias de factory DEL CONTENEDOR (no enemigos) → sobreviven a `enemy_state.clear_alive()`; la plaga sigue donde estaba.

### 7. NPC System (`main/npc.script`)
Generic NPC script shared across all NPCs:
- Auto-detects NPC ID from game object path (e.g., `npc_01`)
- Shows/hides interaction icon based on `game_state.is_npc_available()`
- Green icon = available, Red icon = unavailable, Hidden = completed
- Interaction range: 100 units
- Hover highlight effect (1.2x tint)
- Talking animation via `start_talking`/`stop_talking` messages
- Unavailable feedback: flash red tint for 0.3s

#### 7.1. NPC Patrol System (`features/npc/npc_patrol.lua`)

Autonomous patrol movement for NPCs, opt-in via `go.property("patrol_enabled", false)`:

| Archivo | Función |
|---|---|
| `features/npc/npc_patrol.lua` | Módulo de patrulla reutilizable |
| `main/npc.script` | Integración: init, update, pause/resume, wall collision |

**Configuración por NPC (go.properties en npc.script):**
| Propiedad | Default | Descripción |
|---|---|---|
| `patrol_enabled` | `false` | Activar/desactivar patrulla |
| `patrol_speed` | `40` | Velocidad de paseo (px/s) |
| `patrol_radius` | `250` | Radio máximo desde spawn |

**Máquina de estados:**
```
           ┌──────────────────────────┐
           │                          │
           ▼                          │
   ┌──────────────┐    ┌──────────────┐ │
   │    IDLE       │───►│   PATROL     │─┘
   │ (quieto,     │◄───│ (moviéndose  │
   │  0.5-2.0s)   │    │  a destino)  │
   └──────────────┘    └──────┬───────┘
           ▲                  │
           │    ┌──────────────┐
           │    │  HIT_WALL    │
           └────┤ (cambia      │
                │  dirección)  │
                └──────────────┘
```

**Comportamiento:**
- **Movimiento cardinal puro:** Solo 4 direcciones (←↑→↓), nunca diagonal
- **Tramos:** 80–300px por tramo, con pausas de 0.5–2.0s entre tramos
- **Límite radial:** No puede alejarse más de `patrol_radius` uds de su punto de spawn
- **Detección de jugador:** Se detiene si el jugador está a ≤100 uds, reanuda a ≥150 uds (histéresis)
- **Colisión con paredes:** Detectada vía `contact_point_response` con `message.group == hash("walls")`:
  1. Separación física usando `message.normal * message.distance` (corrección consolidada, aplicada una vez al inicio del update → sin jitter)
  2. **Choque FRONTAL** (la pared se opone al movimiento) → pausa breve `WALL_TURN_IDLE` (0.35s, "girar con intención") y la re-elección llega desde el IDLE excluyendo esa pared: el space check comprueba si hay **otra dirección disponible** (incluidas las salidas laterales del cruce, gracias a PROBE_EPS).
  3. **Roce lateral** → solo la corrección de empuje, **sin re-elegir** (antes se re-elegía en cada contacto y el NPC se atascaba contra las paredes laterales de los pasillos).
- **🧭 Space check (Ago 2026):** antes de comprometerse a un tramo, `pick_direction_with_clearance` mide el espacio libre en cada cardinal con **3 raycast paralelos** contra `walls` (centro + bordes del cuerpo de la entidad → mide el hueco REAL, un pasillo por el que solo cabe el rayo central se descarta) y exige un hueco mínimo `NAV_CLEARANCE` (**60** uds, configurable en `config.balance.npc_nav_clearance`):
  - **📐 Semiejes por entidad (Ago 2026):** los rayos laterales usan los **semiejes reales de la caja de colisión de cada entidad**, pasados a `patrol.init(self, spawn, half_x, half_y)` — NPCs: 11×15 → 5.5/7.5 (default); gato: 25×25 → 12.5/12.5 desde `cat.script` (constante `CAT_BODY_HALF`). **Hallazgo que motivó la parametrización:** la sonda asumía la caja de los NPCs para todos; el gato (más ancho, ±12.5) medía huecos optimistas (±7.5) y podía engancharse en huecos justos donde los NPCs sí pasaban. Al cambiar la caja de un NPC/gato, actualizar la llamada (GOTCHA #42).
  1. **Óptimas** = cardinales con hueco ≥ umbral → **aleatoria entre TODAS ellas (incluida la de retroceso)**: es la variabilidad del recorrido — un guardia que va y viene por un pasillo con sus pausas, o gira a cualquier salida en un cruce. Sin anti-backtracking fijo: la exclusión solo aplica a la pared que acaba de detener al NPC (y a la dirección hacia otro NPC).
  2. **Fallback:** si ninguna llega al umbral (callejón/borde), se elige la de **mayor hueco** (avanza igual, nunca se queda clavado).
  3. Sin sitio ni para moverse (< `NAV_MIN_FREE` = 5 uds) → IDLE breve (0.4s) en vez de micro-choques contra la pared.
  4. **PROBE_EPS (2 uds):** los hits del raycast a ≤ 2 uds del origen se ignoran — son artefactos del propio cuerpo tocando/solapando la geometría (al sondear desde la pared frontal con la que se acaba de chocar). Sin esto, las salidas laterales de un cruce leerían como bloqueadas y el NPC "no encontraría" otra dirección.
  Coste: 12 raycasts solo al elegir tramo (cada 0.5–2s o al chocar) — despreciable. La colisión reactiva (`contact_point_response`) se mantiene como red de seguridad.
  - **🧪 Mejora pendiente (Iteración 2):** el space check elige dirección por el espacio libre MEDIDO, pero no verifica el desplazamiento REAL del NPC durante el tramo. Un timer de atasco por tramo (medir la posición cada ~0.15s; si lleva ~0.6s sin progresar, re-elegir dirección forzando otra óptima distinta) sería la red de seguridad definitiva para casos límite no cubiertos: callejones sin salida donde el fallback de "mayor hueco" avanza poco, o geometría que cambia a mitad de tramo (p. ej. una puerta que se cierra delante). Mismo patrón que el desatasco N1-N4 de `cat_nav.lua` (ya probado en este proyecto) y que el `pet_stuck` del seguimiento por estela del gato. Pendiente de probar en runtime si los casos límite aparecen.
- **Control externo:** `patrol.pause()` (al empezar diálogo) y `patrol.resume()` (al terminar)
- **Sistema de colisiones:** NPC usa group `"npcs"`, mask `"walls"` ↔ Level walls usan group `"walls"`, mask `"npcs"`
- **Separación entre NPCs (Ago 2026):** los NPCs no colisionan por física (KINEMATIC↔KINEMATIC), así que la patrulla se separa **por distancia** consultando el registro `npc_spawn_state.npc_urls` (getter `get_all_npc_urls()`; escaneo throttled a `NPC_SCAN_INTERVAL = 0.15s` por NPC para no alocar por frame):
  1. Otro NPC a < `NPC_SEPARATION_DIST = 40` uds → se excluye la dirección hacia él al re-elegir dirección (IDLE o esquive).
  2. Avanzando hacia él (dot > 0) → se desvía en perpendicular re-elegiendo dirección (misma mecánica que el esquive de paredes).
  3. Contacto (< `NPC_STOP_DIST = 22` uds) → se detiene `NPC_STOP_IDLE = 0.8s` y al reanudar evita esa dirección.
  - Solo se evitan **entre ellos**: el gato (`NPC_CAT_ID = "cat"`) queda excluido de la separación.
  - No corre con el jugador cerca (los NPCs están congelados por el stop del jugador; el solape en ese caso sería estático).

**Arquitectura:**
- El script `npc.script` ejecuta `patrol.update()` solo si `patrol_enabled` y `not is_talking`
- `update()` original de npc.script fue eliminado por optimización, y se reemplazó por la versión de patrulla guardada con `if self.patrol_enabled and not self.is_talking`

### 7.2. Door System

#### 7.2.1. Interactive Doors (`features/props/doors.script`)
Puertas que el jugador abre/cierra manualmente con clic:
- **Auto-detección de tipo:** El prefijo de animación se extrae del ID del componente (`door_front`, `door_side`, `door_service`)
- **Estados:** `closed_door` (collision player activo) ↔ `open_door` (collision desactivado / desplazada — ver colisión abierta abajo)
- **Interacción:** Hover aclara sprite (tint 1.3), clic toggle con animación (forward/backward) + sonido (`door_open`/`door_closed`)
- **Distancia:** Solo interactúa si jugador ≤ `interact_distance` (200 uds por defecto)
- **🚨 Tintado climático (Ago 2026):** las puertas con `climate_control=true` (configurado por instancia en `level_01.collection`; `door_side`/`door_service`) muestran un **rojo suave persistente `(1.5, 0.6, 0.6)` mientras están ABIERTAS** — señal visible a distancia de "puerta problemática" (con varias abiertas, el jugador identifica cuáles son). Al cerrarlas, el tint vuelve a normal (feedback de resolución). El **hover intensifica** el rojo a `(1.7, 0.5, 0.5)` (no lo sustituye); las puertas cerradas o no climáticas mantienen el aclarado normal. Helper `get_base_tint(self)` como fuente única de verdad. Mismo lenguaje de color que el warning climático del HUD (rojo = empeorando).
- **Tipos de puerta:**
  - `door_front.go` — Puerta frontal interactiva, sprite 0.5x
  - `door_side.go` — Puerta lateral interactiva, sprite 0.5x
  - `door_service.go` — Puerta de servicio interactiva, sprite 1.8x
- **Script unificado:** `doors.script` es compartido por los 3 tipos, que solo varían en sprite y collision shapes
- **🐱 Gato en PET ante puerta cerrada (Ago 2026):** si el gato en modo mascota queda bloqueado por una puerta interactiva cerrada (la estela cruza una puerta que el jugador cerró), el gato **espera sentado junto a ella** (maullando de vez en cuando) en vez de intentar rodearla, y **reanuda el seguimiento automáticamente al abrirla** — el toggle de `collisionobject_npcs` de `open_door()/close_door()` es la señal que el gato detecta con sus avances de prueba (ver sección del gato).
- **🚪 Colisión abierta desplazada (Ago 2026, `door_side`):** las puertas de sprite simple (`door_side`, flag `use_open_collision=true` en el `.go`) NO deshabilitan su colisión al abrir: la **desplazan** a un segundo collision object `collisionobject_player_open` (caja en `(12,30,0)`, 25×30×20 uu) situado donde queda el panel visible abierto. Así el jugador no puede solaparse visualmente con el panel (gap visual) y el hueco de la puerta queda libre. Las puertas divididas (`door_front`/`door_service`, flag `false`) siguen deshabilitándola del todo: sus sprites divididos (front z=0.2 / back z=0.0) ya resuelven el z-ordering. `door_main.script` (script propio) no participa. Al cerrar se retira la colisión abierta y se restaura la cerrada.
- **🚪 Colisión NPCs/gato/ENEMIGOS con toggle (Ago 2026):** el `collisionobject_npcs` (group `walls`, **máscaras `npcs` + `enemies`**) ahora se **desactiva al abrir** y se **reactiva al cerrar** en `doors.script` — antes quedaba siempre activo y NPCs/gato se atascaban en el hueco de puertas abiertas (hallazgo del análisis de colisiones); con los enemigos en la máscara (nuevo, Ago 2026: ratas/cucarachas, group `enemies`, mask `walls`, antes atravesaban todas las puertas) el toggle era imprescindible o se habrían atascado también. Efecto de juego: una puerta **cerrada bloquea a todos por igual** (NPCs, gato, enemigos) y es herramienta táctica (cerrarla para escapar de una rata; la embestida choca contra la puerta cerrada → RECOVERY aturdida); una **abierta es transitable** para todos. Se reutiliza el collider existente (sin tocar el pool fijo, GOTCHA #27). Los enemigos la tratan como pared (reaccionan a group `walls` con empuje/esquive; sin cambios de IA).

#### 7.2.2. Automatic Main Door (`features/props/door_main.script`)
Puerta que se abre automáticamente por proximidad:
- **Animaciones:** `door_main_idle` (cerrada), `door_main_open` (forward), `door_main_close` (backward con callback a idle)
- **Histéresis:** `open_distance=100`, `close_distance=100` (evita flickering)
- **Sonidos:** `door_sliding_open`, `door_sliding_close`
- **Callback en animación:** Usa `sprite.play_flipbook()` con callback para detectar fin de animación
- **🧱 Colisión (Ago 2026):** `collisionobject_player` (group `walls`, mask `player`) + `collisionobject_npcs` (group `walls`, máscaras `npcs` + `enemies` — añadido Ago 2026 para que la entrada principal bloquee a los NPCs igual que las puertas interactivas, y con `enemies` desde Ago 2026 para que también bloquee a ratas/cucarachas; mismas 2 cajas 37×10 en x=±59, y=−74). Ambos permanecen SIEMPRE activos: la puerta principal no gestiona colisión en runtime (el script solo anima sprites y suena) — a diferencia de las puertas interactivas, cuyo `collisionobject_npcs` sí se togglea al abrir/cerrar (§7.2.1). Coherente: la entrada principal bloquea a todos (jugador, NPCs, enemigos) siempre, abierta o cerrada

### 7.3. NPC Spawn System (spawn points + desbloqueo)

Sistema de posicionamiento de NPCs por **puntos de spawn en el editor** (implementado junto con el refactor de escena):

| Archivo | Función |
|---|---|
| `features/npc/npc_spawn_manager.go` | GO contenedor `spawn_npcs` (hijos `spawn_npc_cat`, `spawn_npc_01..NN` colocados a mano en el editor) |
| `features/npc/npc_spawn_manager.script` | Descubre los spawn points por naming (`spawn_npc_%02d`, patrón de `food_spawn_container`), coloca cada NPC y escucha `npc_unlocked` |
| `main/npc_spawn_state.lua` | Módulo compartido: registro de URLs reales de NPCs (`register_npc`) y de spawn points (`register_spawn_point`) — GOTCHA #4 |
| `main/npc.script` | Registra su URL real (`go.get_id()`) en `init()`; re-ancla la patrulla al recibir `npc_spawn_updated` |
| `features/cat/cat.script` | Registra `"cat"`; en `npc_spawn_updated` re-ancla spawn/patrulla y vuelve a `INACTIVE` |

**Comportamiento:**
- **Posicionamiento:** en su primer `update()`, el gestor coloca a cada NPC en su spawn point. Con `config.SHOW_ALL_NPCS = true` (por defecto) TODOS los NPCs van a su spawn point; con `false`, solo los desbloqueados (los demás reposan en staging `(-100, 0, 0.1)`). Preserva la z original del NPC (0.1) para no alterar el orden de render.
- **Desbloqueo en runtime:** `game_state.unlock_npc(id)` → listener → `msg.post(manager, "npc_unlocked")` → `position_npc()` teletransporta al NPC a su spawn y le envía `npc_spawn_updated`. El listener se registra UNA sola vez (`unlock_listener_registered`, game_state es módulo persistente entre recargas).
- **Debug:** `DEBUG_NPC_SPAWN` + `config.make_log()` (silenciado por defecto).
- **Nota de diseño:** el bloqueo solo ahorra recursos si esconde con `go.disable()` real o sin instanciar; con 14 NPCs el ahorro es despreciable, por eso el default es mostrar todos (ver comentario en `config.lua`).

### 8. Dialogue System (`main/dialogue_manager.script`)
Full narrative dialogue flow:
- Loads dialogues from JSON (`assets/texts/main_text_XX.json`)
- Dialogue blocks keyed by `{npc_id}_attempt{attempt}` (e.g., `npc_01_attempt1`)
- Each dialog node has: `speaker`, `text`, `next`, optional `is_quiz`, `start_quiz`, `what_question`
- Typewriter text effect on GUI (0.03s per character)
- Auto-advance after calculated read time (char_count * 0.03 + 1.5s) or manual click
- 0.3s warmup timer to prevent accidental advances
- Quiz integration: pauses dialogue, awaits quiz result, branches to `success`/`failure` nodes
- Sound per dialog node (dialogue audio loops)
- Talking animations triggered per speaker
- NPC cooldown/unavailable messages
- **Dueño del listener global de ventana (`window.set_listener`):** Defold solo permite **UN listener global** (cada `window.set_listener` reemplaza al anterior). `dialogue_manager` es el **único** que lo registra, en `init()` (`window.set_listener(on_window_event)`), porque es el único script que conoce al hablante actual y su posición en el mundo. En `WINDOW_EVENT_RESIZED` / `WINDOW_EVENT_FOCUS_GAINED` (robustez HTML5: algunos navegadores entregan el resize solo tras el focus gained) recalcula `screen_pos` con el nuevo tamaño de ventana y envía `reposition_dialog` a `interactive.gui_script`, que re-ancla el globo con `gui.set_screen_position` **sin reiniciar el typewriter**. Se libera en `final()` con `pcall(function() window.set_listener(nil) end)` (el `pcall` evita errores si la versión de Defold no acepta `nil` para limpiar el listener). ⚠️ Si otro script necesita escuchar eventos de ventana, debe centralizarse (nunca registrar un segundo listener). Ver docs/DEV_GOTCHAS.md → **GOTCHA #6**.

### 9. Quiz System (`gui/interactive.gui_script`)
Integrated in the GUI layer:
- 3 answer buttons with hover scale animation (1.15x)
- Shuffled answer order
- Typewriter effect on question text
- Pie timer: 10-second countdown (360°→0° fill angle animation)
- Auto-size buttons based on text length
- Auto-resolve failure on timeout
- Image support per question
- Reads from JSON quiz pools

#### 9.1. Layout del Quiz (editor-relative)

**Principio:** el editor es la única fuente de verdad del layout. Los hijos (`button_X_image`, `text_X`) están en `(0,0)` relativo al padre; **todo el posicionamiento recae en los contenedores** `button_1/2/3`. Redistribuir nodos en el editor no exige retocar el script.

**Jerarquía de nodos (`gui/interactive.gui`):**

| Nodo | Padre | Posición (editor) | Tamaño (editor) | Rol |
|---|---|---|---|---|
| `button_1/2/3` | — | (200, 333/263/193) | 300×50 | Contenedor + hitbox de `pick_node` (pivot CENTER) |
| `button_X_image` | `button_X` | `(0,0)` | 300×50 | Imagen visible, auto-redimensionada en runtime |
| `text_X` | `button_X` | `(0,0)` | 1300×100 (scale 0.2) | Texto de la respuesta |
| `box_background_quiz` | — | (198, 356) | 360×600 | Fondo del quiz (capa `quiz_background`) |
| `box_icon_quiz` | — | (331, 78) | 200×100 | Icono decorativo (capa `quiz_background`) |
| `pie_timer_quiz` | — | (328, 492) | 50×50 | Cuenta atrás del quiz (capa `quiz_background`) |

**Captura en `init()`:** se leen las posiciones Y de los botones (`editor_button_y`), la altura del editor (`gui.get_size`) y se derivan el ancla `quiz_top_anchor = y₁ + altura/2` (borde superior del primer botón) y `button_gap` (distancia entre centros − altura, mínimo 8px). Al ejecutarse antes de cualquier quiz, los valores coinciden siempre con los del editor.

**`reposition_quiz_buttons(button_heights)`:** apila los contenedores desde el ancla hacia abajo con `pos.y = current_y − h/2`, decrementando `current_y` en `h + gap`. Como los hijos están en `(0,0)` y el contenedor tiene pivot CENTER, el borde superior de la imagen coincide exactamente con `current_y`. **Sin valores absolutos.**

**`auto_size_button(container, bg, text, answer)`:** mide el texto (`resource.get_text_metrics`), redimensiona la imagen a `(fixed_bg_width, target_bg_height)` con padding 10px, centra el texto **siguiendo la posición de la imagen** (ambos pivot CENTER → centrado real sobre el botón) y redimensiona el contenedor a `gui.get_size(button_bg)` para que la **hitbox de `pick_node` cubra todo el botón visible**, incluso con textos largos (wrapping). Devuelve `target_bg_height`, que `reposition_quiz_buttons` usa para apilar los botones.

**Show/hide:** `hide_quiz_interface()` / `show_quiz_interface()` gestionan el patrón completo (fondo, icono, pregunta, imagen, pie timer, botones). Los nodos `box_background_quiz` y `box_icon_quiz` se añadieron a ambas funciones y a la capa `quiz_background` (renderizan detrás de `quiz_buttons`).

**Nota histórica:** los hijos antes tenían offsets residuales (`-18`, `-19`, `-16`) que causaban desalineación vertical del texto (el script asumía `(0,0)`). Se normalizaron a `(0,0)` y los padres se compensaron −18px para mantener la composición visual idéntica.

### 10. Exhibition System
Two-way architecture:
- **`exhibition_object.script`**: On click, sends world/screen position to manager
- **`exhibition_manager.script`**: Looks up object data from JSON, sends to GUI, tracks camera distance (auto-closes if player >100 units away)
- **`exhibition.gui_script`**: Displays panel with description, period, site, dimensions, image
- Panel follows world position (screen-space conversion with dynamic resolution)
- Close on ESC or click outside

### 11. Camera (`main/camera.script`)
Smooth follow camera with lerp factor (default 0.07):
- Follows `/player` position
- Exposes `GLOBAL_CAMERA_X/Y` for other systems
- Broadcasts `camera_moved` message to spray system
- Orthographic zoom: 2.0

### 12. Retry Button / HUD (`main/hud.gui_script`)
- `btn_retry_container` (padre, 150×50, pivot CENTER) → maneja hover/click/scale
- `btn_retry` (hijo, 125×40, textura `gui/button_green`) → imagen visible del botón
- `text_retry` (hijo, texto "Reintentar") → texto centrado
- Posición dinámica: `(BASE_WIDTH × 0.5, BASE_HEIGHT × 0.75)` — se adapta a cambios de resolución
- Efectos hover: escala 1.1x + tinte verde claro, aplicados al contenedor para herencia visual
- 💀 Al morir muestra en `text_alert` el mensaje de derrota **persistente** (sin timeout, se oculta al reintentar) discriminado por causa: `cause = "car"` (atropello) → `dialogs.car_defeat`; resto/plagas → `dialogs.fight_defeat` (`get_defeat_text`, Ago 2026)

### 12.1. Bookcase System (`features/furniture/bookcase.script`)
Estanterías de libros interactivas que abren el sistema de lectura:
- **Auto-detección de tipo:** Extrae sufijo del nombre del GO (`bookcase_pal` → `"pal"`, `bookcase_neo` → `"neo"`, etc.) o usa `go.property("book_type")`
- **Tipos soportados:** `pal`, `neo`, `bro`/`bronze`, `ibe`/`iberian`, `rom`/`roman`, `restor`
- **Hover:** Aclara el sprite `sprite_books` (tint 1.2, 1.2, 1.1) y muestra el título del libro en `text_alert` (HUD) con `show_alert { text, replace = true }` — reemplazo instantáneo para evitar el "retraso" al pasar rápido entre estanterías cercanas (sistema de alertas, §13.1)
- **Clic:** Envía `show_book{ book_type }` a `bootstrap:/gui_library#library`
- **Componentes:** `bookcase.go` con sprites `sprite_bookcase` (estante) + `sprite_books` (libros), collision objects para cursor y player

### 12.2. Library Reading System (`gui/library.gui_script`)

GUI de lectura de libros alojada en bootstrap (fuera del proxy):

#### 12.2.1. Paginación de Texto

Divide el contenido del libro en spreads (2 páginas) usando `resource.get_text_metrics()`:

| Parámetro | Valor | Descripción |
|---|---|---|
| `MAX_CHARS_PER_PAGE` | 250 | Límite de caracteres por nodo (respeta ~256 chars de Defold en distance field fonts) |
| `FIT_HEIGHT_RATIO` | 0.97 | Fracción de la altura del nodo usada como límite de página |
| `CHUNK_FILL_RATIO` | 0.95 | Cuánto del fit_height rellenar como máximo en cada chunk |
| `CHUNK_SNAP_LOOKBACK` | 6 | Máximo de palabras hacia atrás para snap a cláusula |
| `PARAGRAPH_SEPARATOR` | `"\n\n"` | Separador entre párrafos |
| `column_width` | 1200 uu | Ancho lógico del nodo (contra el que el motor aplica line-wrap) |

**Snap a cláusula:** Al partir texto, busca hacia atrás (máx 6 palabras) puntos de corte preferidos:
1. Fin de frase (`. ! ?`) — preferido
2. Marcadores de cláusula (`, ; :`) — segunda opción
3. Si no encuentra, corta en el punto de la búsqueda binaria

**Protección de integridad:** Tras paginar, compara `#palabras original == #palabras paginado`; si hay pérdida (chunking imperfecto), activa fallback de 1 página con todo el contenido.

#### 12.2.2. Animaciones de Navegación

| Elemento | Descripción |
|---|---|
| **Paso de página** | Flipbook overlay `box_pages_flip` con animaciones `book_page_forward`/`book_page_backward` (4 frames @5fps, ~0.8s) + sonido `page_turn` |
| **Hover botones** | `btn_backward`, `btn_forward`, `btn_close` con flipbooks de 2 frames: `idle` (oscuro) → `hover_on` (5fps) → `hover_off` (5fps) |
| **Callback animación** | `gui.play_flipbook()` recibe callback que ejecuta `display_page()` + oculta overlay al terminar |
| **Bloqueo doble clic** | Flag `self._navigating` impide avanzar/retroceder durante animación |

#### 12.2.3. Input

- `library.gui_script` mantiene `acquire_input_focus` permanentemente (comparte GO con `pause.gui_script`, liberarlo rompería la tecla P)
- `on_input()` descarta todo input cuando `is_visible == false`
- Hover detectado via `gui.pick_node()`, action_id == nil
- Clic con debounce de 0.01s para evitar doble procesamiento (on_input + on_message)
- ESC cierra el libro (enviado por scene_manager como `input_event`)

#### 12.2.4. Flujo apertura/cierre

```
Abrir libro:
  bookcase.script → msg.post("bootstrap:/gui_library#library", "show_book", { book_type })
                  → library.gui_script busca el libro en self.books_data
                  → pause_game_world() → scene_manager → set_time_step(factor=0)
                  → Pagina contenido y muestra primera spread

Cerrar libro:
  Clic en box_close (o ESC)
    → hide_library() → cancel _navigating → ocultar todo
    → resume_game_world() → scene_manager → set_time_step(factor=1)
```

#### 12.2.5. Otros

- **Soporte multi-idioma:** Recarga textos al cambiar idioma vía callback de `game_state` (`register_callback("language", ...)`)
- **Fixes aplicados:** [FIX A–F] para límite de caracteres, márgenes, chunking y detección de progreso (documentados en cabecera del script)

### 13. Cursor (`main/cursor.script`)
Mouse cursor with collision-based interaction:
- Follows mouse position in world space
- Detects hover via `trigger_response` → sends `mouse_hover` to targets
- On click + collision with `interactivable` group → sends `interact` message
- **📏 Rango GLOBAL de interacción (Ago 2026):** `M.balance.interaction_range` (80 uds) aplicado en las 4 vías de interact (clic del bucle, safety net, fallback `collision_response`/`contact_point_response` y hover en enter) contra `interactable_box.world_point(url)` (punto registrado por puertas/armarios, fallback al GO). El rango se aplica TAMBIÉN en el sensor móvil (`mobile_interact.script`, sensor 180×180 en `player.go`). ⚠️ **Hallazgo (Ago 2026, GOTCHA #5):** el fallback `collision_response`/`contact_point_response` NO era código muerto — el cursor TRIGGER sí recibe esos mensajes de interactables KINEMATIC, y disparaba `interact` sin gate (ME_5225 a 285 uds). Ahora está gateado con el mismo `is_player_in_range`.

### 13. HUD (`main/hud.gui_script`)
Real-time UI updates every 0.1s:
- **Health bar**: Green→yellow→orange→red gradient, blink at <20% health
- **Spray bar**: Blue gradient, blink at <20% spray
- **Text counters**: skills, quiz total, restoration total, items collected, bugs total

### 13.1. Sistema de Alertas `text_alert` (cola FIFO + flag `replace`) (Ago 2026)

El nodo `text_alert` del HUD es un **contenedor de mensajes compartido** por múltiples fuentes (recogidas, hover de muebles/gato, títulos de estanterías). El HUD recibe 3 tipos de mensaje:

| Mensaje | Tipo | Comportamiento |
|---|---|---|
| `show_alert { text }` | Transitorio (toast) | Se muestra 3s y se oculta solo; si hay algo visible, **entra en cola FIFO** |
| `show_alert { text, replace = true }` | Transitorio con **reemplazo** | Se muestra **AL INSTANTE** sin cola (hover posicional, p. ej. títulos de estanterías) |
| `show_persistent_alert { text }` | Persistente | Se muestra sin timer, prioridad máxima; se oculta manualmente |
| `hide_persistent_alert` | — | Oculta la persistente y reanuda el siguiente de la cola |

**🆕 Fuente de alertas: aviso de zona/sala (Ago 2026):** `features/props/zone_alert.script` (zona `zone_intake` en `level_01.collection`) envía `show_alert` con el **nombre localizado de la sala** (`general_text → M.locations.room_*`) al entrar el jugador en la zona (trigger `zone_ambient` ↔ `player_sound`). La clave se auto-detecta del id del GO (`zone_intake` → `room_intake`), así que el script es reutilizable para cualquier zona futura sin tocar código.

**Diseño (Ago 2026):**
- **Cola FIFO acotada** (`ALERT_QUEUE_MAX = 4`): ningún toast se pierde; si la cola se llena se descarta el **más antiguo** (prevalece la información reciente).
- **Temporizador ÚNICO** (`self.alert_timer` en `update()`): sin `timer.delay` apilados → cada alerta dura sus 3s completos (antes, el primer timer en expirar ocultaba la alerta actual aunque fuera más nueva).
- **Prioridad persistente**: la persistente (hover de muebles/gato) se muestra al instante; el toast que estuviera visible vuelve al **frente** de la cola y se reanuda al ocultar la persistente (`alert_push_interrupted_to_front`).
- **Dedup**: mismo texto que el visible → reinicia el temporizador en vez de encolarlo.
- **Flag `replace`** (hover posicional): el mensaje se muestra YA; el toast desplazado vuelve al frente de la cola (no se pierde); una persistente desplazada se descarta (el emisor la re-afirma en su próximo enter/exit). Los toasts ya encolados no se tocan. **Motivo:** sin él, al pasar rápido entre estanterías cercanas el título anterior completaba sus 3s y el nuevo quedaba encolado (efecto "retraso").

**Fuentes emisoras:**

| Tipo | Fuentes |
|---|---|
| Transitorios (3s, con cola) | `inventory_manager` (~18 llamadas), `player` (agotado), `spray_can`, `kit_health`, `kit_stamina`, `food_cat_can`, `bookcase` (antes del flag), `cat` (inicio PET) |
| Persistente (hover) | `slot_furniture` (hover de muebles), `cat` (hint de hover) |
| `replace = true` | `bookcase` (título en hover, §12.1) |

**Implementación:** `gui/hud.gui_script` → `alert_enqueue(self, text, persistent, replace, defer)`, `alert_show_next(self)`, `alert_push_interrupted_to_front(self)`; estado en `init()`; temporizador en `update()` (zero-garbage: solo aritmética). 🔊 **Sonido en avisos proactivos (Ago 2026):** el mensaje `show_alert` acepta el flag opcional `alert_sound = true` — el HUD reproduce `smooth_notification` al recibirlo (omitido durante un diálogo/quiz). Lo usan los avisos puntuales proactivos (llegan por timer/polling, no por un clic): re-intento de la restauradora, "¡Objeto listo para exhibición!" (Timer A expira) y "¡Estás agotado!" (stamina). Los avisos reactivos (respuesta a un clic: recogidas, depósitos, errores, hints de props — que ya tienen sus propios sonidos `#pick_up`/`#spawn_collectible`/`#insertion`) no lo llevan por diseño.

**⏰ Recordatorios periódicos (Ago 2026):** `update_reminders(self, dt)` re-muestra `alert_new_material` (objeto en PICKUP sin recoger), `alert_pending_storage` (objeto recogido pero **sin depositar** en la estantería — COLLECTED o STORAGE sin Timer A activo, p. ej. tras la restauración; el flag `timer_a_running` del HUD, gestionado por `update_timer_progress`/`hide_timer_progress`, distingue el STORAGE depositado del pendiente de depósito), `rule_no_exp` (objeto en EXHIBITION listo para vitrina sin exponer), dos variantes de restauración — `alert_new_restoration` (pieza en RESTORATION sin haber hecho el quiz, intento 1) y `alert_new_attempt_restoration` (pieza en RESTORATION tras fallar el quiz con turnos restantes, intento ≥ 2) — y `alert_npc_available` (NPC de quiz genérico fallado con turnos restantes cuyo cooldown expiró; solo reintentos, respeta el libre albedrío, con el **nombre localizado del NPC** insertado en el texto) — cada X segundos mientras la acción siga pendiente. Cada disparo reproduce un **aviso sonoro suave** (`smooth_notification.sound`, componente montado en el objeto `gui` de `level_01.collection`, grupo `sfx` → lo controla el slider de efectos) desde `run_reminder` (`sound.play("#smooth_notification")`). La distinción de la restauradora usa el TIPO del NPC (`npc_spawn_state.find_npc_by_type(npc_spawn_state.NPC_TYPE_QUIZ_RESTORATION)` + `get_npc_attempt`); la de NPCs genéricos itera `npc_spawn_state.npc_types` filtrando `NPC_TYPE_QUIZ_GENERAL` (Ago 2026: la propiedad `npc_type` del editor — quiz_general / quiz_restoration / quiz_false — reemplaza a los ids hardcodeados). El intervalo es **configurable por alerta en `main/config.lua` → `M.balance`** (fuente única: `reminder_new_material` / `reminder_pending_storage` / `reminder_no_exp` / `reminder_restorer_new` / `reminder_restorer_retry` / `reminder_npc_available`, en segundos; 0 = desactivado; ⚙️ PREPROD: 15 · PROD: 180). Los textos (`general_text_[lan].lua`) solo contienen el **mensaje**, no el tiempo (las claves `*_reminder_time` se eliminaron en Ago 2026 para evitar la doble fuente). Se lee con `load_reminder_config()` solo en `init()` (opción B: al no depender del idioma, ya NO se llama en el callback de cambio de idioma). El recordatorio de la restauradora complementa al aviso proactivo único del `dialogue_manager` (timer en RAM) y sobrevive a guardar/recargar (polling de `get_npc_cooldown_remaining`). El **aviso proactivo también suena** (Ago 2026): `schedule_restoration_alert` envía `show_alert` con `alert_sound = true` y el HUD reproduce el mismo `smooth_notification` al recibirlo (flag opcional de `show_alert`, omitido durante un diálogo/quiz — coherente con la pausa de recordatorios). Los nombres de NPC vienen de `main_text_[lan].lua → characters` (ya cacheado por `text_loader`); el texto dinámico usa la variante `text_fn` de `run_reminder` (`string.format` solo al dispararse). 🗣️ **Pausa durante diálogo (Ago 2026):** mientras el jugador está en un diálogo/quiz con un NPC (`game_state.dialog_active`, flag RAM gestionado por el `dialogue_manager`), `update_reminders` **congela** los contadores (nada se dispara ni suena — se reanudan al cerrar el diálogo desde donde iban) y los avisos puntuales (`show_alert` transitorios) se **encolan** en vez de mostrarse (los `replace` de hover posicional no se difieren); si el jugador muere durante un quiz, `trigger_death` cancela con `dialog_cancelled` (incondicional, a diferencia de `cancel_dialog` que está gateado por `not waiting_quiz`) y el respawn limpia el flag por defensa en profundidad.

#### 🔜 Opción C — Builds preprod/prod con el mecanismo nativo de Defold (documentada, NO implementada)

> **Estado (Ago 2026):** planificada y documentada para una futura iteración. La opción B (tiempos en `M.balance`) es la fuente única actual; esta opción la superpondría **sin cambiarla**.

**Objetivo:** poder generar builds de **preproducción** y **producción** desde el mismo repositorio **sin tocar ni una línea de código**, usando el mecanismo oficial de Defold: `[custom]` en `game.project` + `sys.get_config*()` en runtime + overrides por build vía `bob.jar`.

**Arquitectura prevista (3 capas, cada una con fallback a la anterior):**

```
game.project → [custom] sección          ← capa de BUILD (valores por defecto del proyecto)
        ↓ sys.get_config_string/number(..., fallback)
main/config.lua → M.balance              ← capa de CÓDIGO (defaults actuales, NO se eliminan)
        ↓
hud.gui_script / consumidores          ← leen de config.balance (sin cambios)
general_text_[lan].lua                   ← solo texto (sin cambios)
```

**Implementación prevista (solo cuando se active):**

1. **`game.project`** — añadir sección `[custom]` con las claves que deben variar por entorno:
   ```ini
   [custom]
   reminder_new_material = 15
   reminder_no_exp = 15
   storage_timer_duration = 10
   npc_cooldown_seconds = 60
   ```
2. **`main/config.lua`** — helper de lectura con fallback (ej. para `M.balance.reminder_new_material`):
   ```lua
   local function cfg(key, default)
       if type(sys.get_config_number) == "function" then
           local v = sys.get_config_number("custom." .. key, default)
           if v ~= default then return v end  -- [custom] manda si está definido
       end
       return default
   end
   reminder_new_material = cfg("reminder_new_material", 15),
   ```
   ⚠️ `config.lua` es actualmente **Lua puro sin API Defold** (lo require `inventory_core`, que debe seguir siendo testeable fuera del motor). El acceso a `sys.get_config` debería hacerse de forma **defensiva** (`type() == "function"`) y, si se prefiere, moverse a un módulo separado o a `load_reminder_config()` en `hud.gui_script` (que ya es runtime de Defold) para no romper ese contrato.
3. **Build por entorno con `bob.jar`** (documentado en el manual oficial de Defold — https://defold.com/manuals/bob/):
   ```bash
   # Preproducción: timers rápidos (si [custom] de game.project ya los trae, no hace falta nada)
   java -jar bob.jar build

   # Producción: override sin tocar código
   java -jar bob.jar --config=custom.reminder_new_material=180 \
                     --config=custom.storage_timer_duration=300 build
   ```
   Alternativa equivalente con archivos `.properties` aplicados de izquierda a derecha:
   ```bash
   java -jar bob.jar --settings=prod.properties build
   ```
   con `prod.properties` conteniendo `[custom]\nreminder_new_material = 180\n...`.

**⚠️ Limitaciones del editor:** el `Ctrl+B` del editor de Defold compila **siempre con los valores de `game.project` tal cual** — no hay un selector de builds preprod/prod en la GUI. Los overrides solo aplican cuando se compila con `bob.jar` desde línea de comandos o CI/CD. Para el día a día, mantener en `game.project`/[custom] los valores de **preproducción** (los actuales) y hacer los builds de producción vía `bob.jar --config/--settings`.

**Alcance futuro posible:** extender el mismo patrón a cualquier clave de `M.balance` (timers, cooldowns, clima, rangos de interacción, audio de enemigos…) — el helper `cfg()` es genérico y reutilizable.

### 14. Input Architecture (post-refactor)

El input se gestiona mediante un **input dispatcher centralizado**: `scene_manager.script` (en bootstrap) adquiere el foco y reenvía los eventos como mensajes. Se adoptó el forwarding como **decisión de arquitectura** (dispatcher único para control de escenas y pausa), NO porque `acquire_input_focus` sea imposible en colecciones por proxy.

> ⚠️ **Matiz técnico:** en Defold, `acquire_input_focus` **sí funciona** en colecciones cargadas por proxy, con una condición previa: el **collection proxy debe adquirir el foco desde la colección principal** (enviar `acquire_input_focus` al GO que contiene el componente proxy) antes de que los scripts internos puedan recibir `on_input`. El forwarding evita esa gestión de foco por proxy y centraliza el control.

Flujo actual:

- **Modo INTRO**: reenvía eventos de ratón como `mouse_event` → `intro:/gui_intro#intro_gui`
- **Modo LEVEL_01**: reenvía TODOS los eventos como `input_event` → 7 targets (cursor, player, player_spray, main, interactive, hud, exhibition)

Cada script destino tiene una función `handle_input()` local llamada desde `on_input` (engine) y desde `on_message("input_event")` (forwarding).

### 15. Input Bindings
| Input | Action | Usage |
|---|---|---|
| Arrow Keys / WASD | up/down/left/right | Player movement |
| Space | key_space | Spray fire |
| ESC | key_esc | Cancel dialog, close panels |
| R | key_r | Dev: reset all game state |
| N | debug_victory | Dev: simulate full victory (key_n + DEV_MODE) |
| Left Click / Touch | click / touch | Interaction, quiz selection |
| Right Click | click_right | Spray fire |

### 16. Sistema de Suspensión (Pausa Contada con GUI Persistente)

#### 16.1. Propósito

Permitir que **elementos GUI situados en `bootstrap.collection`** (fuera del proxy del nivel) sigan reproduciendo animaciones (flipbooks, hovers, transiciones) incluso cuando el nivel principal está congelado por `set_time_step`. El sistema de lectura de libros (`library.gui`) es el principal beneficiario: las animaciones de paso de página y hover de botones funcionan fluidamente mientras el juego permanece pausado.

#### 16.2. Componentes

| Componente | Archivo | Función |
|---|---|---|
| **Contador de pausas** | `main/scene_manager.script` | `self.paused_count` — soporta múltiples sistemas pausando a la vez |
| **Congelación del nivel** | `main/scene_manager.script` | `msg.post(PROXY_LEVEL_01, "set_time_step", { factor = 0, mode = 1 })` |
| **Reanudación del nivel** | `main/scene_manager.script` | `msg.post(PROXY_LEVEL_01, "set_time_step", { factor = 1, mode = 0 })` |
| **Cliente principal** | `gui/library.gui_script` | `pause_game_world()`, `resume_game_world()` — envía mensajes al scene_manager |
| **GUI persistente** | `bootstrap.collection` → `gui_library` | `library.gui` embebido en bootstrap, fuera del proxy |

#### 16.3. Flujo

```
Abrir libro:
   library.gui_script → msg.post("bootstrap:/main_loader#scene_manager", "pause_game")
                      → scene_manager.paused_count = 0 → 1
                      → msg.post(proxy_level_01, "set_time_step", { factor = 0, mode = 1 })
                      → ✅ Nivel congelado, GUI del libro sigue animando

Cerrar libro:
   library.gui_script → msg.post("bootstrap:/main_loader#scene_manager", "resume_game")
                      → scene_manager.paused_count = 1 → 0
                      → msg.post(proxy_level_01, "set_time_step", { factor = 1, mode = 0 })
                      → ✅ Nivel reanudado
```

#### 16.4. Ubicación de Componentes GUI

| GUI | Colección | Animaciones durante pausa |
|---|---|---|
| `library.gui` | `bootstrap.collection` (embebido) | ✅ Continúan (fuera del proxy) |
| `hud.gui` | `level_01.collection` | ❌ Congeladas (dentro del proxy) |
| `interactive.gui` | `level_01.collection` | ❌ Congeladas (dentro del proxy) |
| `exhibition.gui` | `level_01.collection` | ❌ Congeladas (dentro del proxy) |

#### 16.5. Animaciones del Library.gui

| Animación | Nodo | Atlas | Descripción |
|---|---|---|---|
| Hover On (botones) | `box_backward`, `box_forward`, `box_close` | `gui/gui.atlas` | 2 frames off→on, 5 fps, `PLAYBACK_ONCE_FORWARD` |
| Hover Off (botones) | `box_backward`, `box_forward`, `box_close` | `gui/gui.atlas` | 2 frames on→off, 5 fps, `PLAYBACK_ONCE_BACKWARD` |
| Paso de página atrás | `box_pages_flip` | `gui/gui.atlas` | `book_page_backward`, 4 frames @ 5 fps, callback al terminar |
| Paso de página adelante | `box_pages_flip` | `gui/gui.atlas` | `book_page_forward`, 4 frames @ 5 fps, callback al terminar |

Todas estas animaciones se reproducen con el **time-step del motor principal** (no el del proxy), por lo que no se ven afectadas por `set_time_step(factor=0)`.

---

## 🎯 Game Flow & Progression

1. **Start:** `main.script` loads game state from persistence
2. **Exploration:** Player moves through museum with camera following
3. **NPC Interaction:** Click on NPC → Dialogue starts → Quiz → Success/Failure
   - **Success:** NPC marked completed, task_quiz_total +1
   - **Failure:** NPC attempt +1, 60s cooldown, after 3 failures permanently locked
   - **Unlock (pendiente de cablear):** el punto de inserción natural de `game_state.unlock_npc(next_npc)` es `dialogue_manager.on_quiz_result` (tras `register_npc_success`). No se ha cableado porque la secuencia de desbloqueo aún no está definida (ver «🔮 Possible Next Steps»)
4. **Pest Control:** Cockroaches spawn via triggers, chase player, spray to kill
5. **Exhibitions:** Click on exhibition objects to view informative panels
6. **Persistence:** Game auto-saves on state changes

### 15. Inventory / Collectibles System (`main/inventory_manager.script`)

Cycle-of-life system for 10 archaeological objects across 5 periods (Pal, Neo, Bro, Ibe, Rom):

- **States:** `PICKUP → (RESTORATION?) → STORAGE → EXHIBITION → COMPLETED`
- **Timers:** Timer A (STORAGE→EXHIBITION), Timer B (cooldown post-complete), Initial spawn timer — **todos configurables desde `main/config.lua → M.balance`** (punto único preprod/prod, junto con los cooldowns de NPCs, el intervalo por defecto de los recordatorios del HUD, el clima/stamina (rangos ideales, valores iniciales, simulador, sirena y drenaje) y la interacción/feedback de NPC (rangos de interacción, globos de "no disponible" y polling del icono) y el audio de enemigos por proximidad (distancia máx/mín del loop walk, histéresis y rango de one-shots))
- **Furniture:** Shared `slot_furniture.script` for `slot_shelf.go` (shelf) and `slot_showcase.go` (showcase)
- **Cut/Paste visual:** Second click on shelf marks slot as `"in_transit"` (alpha 0.25, semi-transparent), click on showcase clears old slot to `"0000"`
- **Slot states:** `empty`, `storage`, `exhibition`, `in_transit`, `completed` — each with distinct sprite + tint
- **btn_collectible fix:** `go.set_scale(0.001)` + `cancel_animations` + collision guard to prevent visibility bugs
- **Sequential:** One item at a time, Timer B (configurable, 5s default) between items

---

## 🔄 Message Passing Architecture (Key Channels)

```
╔══════════════════════════════════════════════════════════════╗
║                      GAME LOOP                               ║
╚══════════════════════════════════════════════════════════════╝

player.script ←→ dialogue_manager.script ←→ interactive.gui (quiz)
       ↕                                          ↕
  player_spray.script                    hud.gui (health/spray bars)
       ↕
  bullet.script → enemy_cockroach.script
       ↕
  camera.script

╔══════════════════════════════════════════════════════════════╗
║                      EXHIBITION SYSTEM                       ║
╚══════════════════════════════════════════════════════════════╝

exhibition_object.script → exhibition_manager.script → exhibition.gui

╔══════════════════════════════════════════════════════════════╗
║                      INPUT / INTERACTION                     ║
╚══════════════════════════════════════════════════════════════╝

cursor.script → npc.script (mouse_hover, interact)
             → exhibition_object.script (mouse_hover, interact)
             → furniture.script (mouse_hover, interact)
             → btn_collectible (mouse_hover, interact)

╔══════════════════════════════════════════════════════════════╗
║                      NPC PATROL SYSTEM                       ║
╚══════════════════════════════════════════════════════════════╝

npc.script ──llama──→ patrol.update() / patrol.init() (npc_patrol.lua)
  ↕                          ↕
  ├── start_talking ────────→ patrol.pause()
  ├── stop_talking ─────────→ patrol.resume()
  └── contact_point_response → patrol.on_contact_point()
       ↕
  level walls (collisionobject2, group="walls", mask="npcs")

╔══════════════════════════════════════════════════════════════╗
║                 BACKGROUND SOUND SYSTEM                       ║
╚══════════════════════════════════════════════════════════════╝

scene_manager ─────────────────────────→ audio_manager.script
  ├── start_playlist        (level_01 cargada)
  └── stop_playlist         (intro cargada)

player.script ──────────────────────────→ audio_manager.script
  ├── play_event { id = "death" }        (trigger_death)
  └── stop_event { id = "death" }        (trigger_respawn)

dialogue_manager ───────────────────────→ audio_manager.script
  ├── play_event { id = "quiz" }         (start_quiz)
  └── stop_event { id = "quiz" }         (resultado/cancel/fin)

library.gui_script ─────────────────────→ audio_manager.script
  ├── play_event { id = "library" }      (show_book)
  └── stop_event { id = "library" }      (hide_library/final)

pause.gui_script ───────────────────────→ audio_manager.script
  ├── play_event { id = "pause" }        (show_pause)
  ├── stop_event { id = "pause" }        (hide_pause)
  ├── set_volume           { volume }
  ├── toggle_audio         { enabled }
  └── get_audio_state      (no data)

zone_storage (zone_alert.script) ────────→ hud.gui (text_alert)
  └── show_alert { text = locations.room_storage }  (entrar en zona)

zone_intake (zone_alert.script) ────────→ hud.gui (text_alert)
  └── show_alert { text = locations.room_intake }  (entrar en zona)

audio_manager.script ───────────────────→ pause.gui_script
  └── audio_state          { volume, enabled }

╔══════════════════════════════════════════════════════════════╗
║                   BOOKCASE / LIBRARY SYSTEM                   ║
╚══════════════════════════════════════════════════════════════╝

cursor.script → bookcase.script (mouse_hover, interact)
                     │
                     ▼
              show_book { book_type }
                     │
                     ▼
          bootstrap:/gui_library#library (library.gui_script)
                     │
                     ├── pause_game_world() → scene_manager ("pause_game")
                     │                        └→ set_time_step(factor=0, mode=1)
                     │
                     ├── Pagina contenido (resource.get_text_metrics)
                     ├── Muestra spread en text_page_left + text_page_right
                     ├── Maneja input (gui.pick_node): hover + clic botones
                     │     ├── box_forward/backward → flipbook overlay + display_page()
                     │     └── box_close → hide_library()
                     │
                     └── resume_game_world() → scene_manager ("resume_game")
                                              └→ set_time_step(factor=1, mode=0)

╔══════════════════════════════════════════════════════════════╗
║                      PERSISTENCE                              ║
╚══════════════════════════════════════════════════════════════╝

main.script (bootstrap) → game_state.lua → persistence.lua
```

---

## 🔧 Conventions & Patterns

- **Coding standards (guía canónica):** `docs/DEFOLD_LUA_STANDARDS.md` es la **guía canónica de buenas prácticas Lua/Defold** del proyecto (v2.0, `Last Updated: Agosto 2026`). Contiene 9 secciones (memoria, hashes, arquitectura, mensajería, strings/URLs, ciclo de vida, errores, animación, organización) y un **checklist de 10 reglas** para revisiones de código/PRs. Puntos clave validados contra la documentación oficial: pre-hashear identificadores (nunca `hash()` en hot paths), comparar `message_id` con hashes precomputados, cachear `msg.url()` en `init()`, URLs relativas preferidas, `go.animate()` (engine-side en C++, sin garbage de Lua), `timer.delay()`, limpieza en `final()`, módulos `local M = {} ... return M`, zero-garbage en `update()`. **Excepción clave:** los callbacks de ciclo de vida de Defold (`init`, `update`, `on_message`, `on_input`, `final`, `on_reload`) DEBEN seguir siendo globales.
  - **Fuentes oficiales de respaldo:** [Message passing](https://defold.com/manuals/message-passing/), [Addressing](https://defold.com/manuals/addressing/), [Lua in Defold](https://defold.com/manuals/lua/), [Lua modules](https://defold.com/manuals/modules/), [Optimizing a Defold game](https://defold.com/manuals/optimization/), [Profiling](https://defold.com/manuals/profiling/), [API reference `hash`/`msg`/`go`/`timer`/`gui`](https://defold.com/ref/stable/), [Lua 5.1 reference manual (`pcall`)](https://www.lua.org/manual/5.1/manual.html).
- **Auditoría de funciones globales:** `audit_globals.sh` (raíz) es la herramienta reutilizable que verifica la regla #1 del checklist (sin funciones globales no-ciclo-de-vida). Uso: `bash audit_globals.sh [-q|-v]`; exit code 0 = limpio (compatible con CI). Estado actual: **0 violaciones** tras las Fases 1-4 (13 archivos convertidos). Ver docs/DEV_GOTCHAS.md → GOTCHA #1.
- **Detección de enemigos del gato / instancias factory:** Ver docs/DEV_GOTCHAS.md → **GOTCHA #4** (`factory.create()` no acepta parámetro de id → el motor auto-genera los nombres de las instancias; NO adivinar nombres) y **GOTCHA #26** (el registro en `main/enemy_state.lua` lo hace el **propio enemigo en su `init()`** con `go.get_id()` — cubre estáticos del editor y de factory; antes lo hacía `spawn_enemies.script` solo para las de factory, dejando invisibles los estáticos). También **GOTCHA #5** (entre dos TRIGGERS el engine envía `trigger_response` con `other_group`, no `contact_point_response`). **Distinción clave:** el naming dinámico es legítimo para objetos colocados en el editor (`npc_%02d`, `food_spawn_%02d`, `spray_spawn_%02d` — nombres fijos en `.collection`), pero NO para instancias de factory. Referencia: `main/enemy_state.lua` (módulo compartido con `register`/`get_spawned`/`reset`), `features/enemy_cockroach.script`/`features/enemy_rat.script` (registran su id en `init()`), `features/cat/cat.script` (`scan_enemies()` consume `enemy_state` + handler `trigger_response`).
- **Config module:** `main/config.lua` expone `DEV_MODE` (reset en inicio, tecla R), `DEBUG` (kill-switch global de logs), `make_log(toggle)` (logs granulares por archivo) y `dprint()` (alias global, compatibilidad). Ver sección «18. Debug Logging System».
- **Lua modules:** `require "main.game_state"`, `require "main.persistence"`, `require "main.dkjson"`
- **Script-to-script communication:** Defold message passing (`msg.post(url, msg_id, data)`)
- **GUI scripts:** Separate `.gui_script` files, `gui.get_node()` for UI elements
- **JSON texts:** Split by language and domain (`main_text_es.json`, `exhibition_text_es.json`)
- **NPC IDs:** Format `npc_XX` (zero-padded, e.g., `npc_01`), up to 20
- **Animation naming:** `idle`, `walk`, `talk`, `attack_*`, `death`
- **Sprite URLs:** Auto-resolved from NPC ID (e.g., `sprite_01` for `npc_01`)
- **Collision groups:** `player`, `player_enemies`, `player_spawn`, `enemies`, `walls`, `npcs`, `cursor`, `interactivable`, `spawn`, `spray`, `zone_ambient`

---

## 🔍 Auditoría de calidad (Agosto 2026) — 10 hallazgos cerrados

> Auditoría completa del juego (37 scripts, GUI, atlas, textos y configuración) realizada en Agosto 2026. **Los 10 hallazgos están aplicados y verificados**; el anexo con los detalles de cada fix vive en `docs/plans/archive/REFACTORING_PLAN.md` (sección «Anexo — Auditoría de calidad»). Cada uno tiene su GOTCHA asociado en `docs/DEV_GOTCHAS.md`.

| # | Hallazgo | GOTCHA |
|---|----------|--------|
| 1 | 🔴 Atlas `icon_quiz_main_anim` — frames sin registrar en `images` (build descartaba el flipbook del quiz en silencio) | #8 |
| 2 | 🔴 `item_id` desalineados con el catálogo de la sala (`neo_hacha`/`ibe_kili`/`rom_copa` sin ficha → "No se encontró el objeto con ID") | — |
| 3 | 🟠 `bro_hacha` con `item_id = 3098` → mostraba la ficha de la Hoz para el "Hacha de cobre" | — |
| 4 | 🟠 Textos hardcodeados en español en `inventory_manager.script` (2 alertas + clave cruda del periodo) | #20 |
| 5 | 🟠 `print()` directo en `cursor.script` e `interactive.gui_script` — logueaban SIEMPRE en producción | #36 |
| 6 | 🟡 `reset_all()` no conservaba `sfx_volume`/`temp_units`/`fps_overlay` ("Nueva partida" borraba preferencias) | #35 |
| 7 | 🟡 5 scripts de props con `print()` crudo (kit_health, kit_stamina, food_cat_can, spray_can, slot_furniture) | #36 |
| 8 | 🟡 10 scripts con `DEBUG_X = true` (activaban todo el logging al depurar) | #36 |
| 9 | 🟡 Fallbacks en español de `collectibles_data` enmascaraban objetos nuevos sin traducir | #39 |
| 10 | 🟡 3 scripts de `features/` con `print()` de debug (cockroach, btn_collectible, npc_spawn_manager) | #36 |

**Cobertura de logs completa:** el grep de cobertura del GOTCHA #36 recorre TODO el árbol (`.`, incluyendo `features/`, `intro/`, `main/`, `gui/`). No quedan prints de debug sin sistema de log; los únicos `print()` restantes son diagnósticos de error reales (categoría 3: `text_loader`, `collectibles_data`, contenedores de spawn, `game_state` victoria/callbacks) y checks gateados por `config.DEBUG`/flags propios (check de localización, `climate_controller`).

**Localización:** cadena completa — etiquetas de GUI y mensajes de módulos en `general_text` (secciones `M.exhibition`, `M.save`), fallbacks de catálogo como red de seguridad + `check_localization_coverage()` en dev (ES+EN), rangos con fallback neutro. GOTCHAs #20 → #34 → #37 → #38 → #39.

**Verificación:** `luac -p` en todos los archivos tocados + `audit_globals.sh` → 0 violaciones tras cada tanda.

---

## 🔮 Possible Next Steps / Areas for Expansion

- Add more NPCs (up to 20 supported)
- 🔲 **NPC unlocking progression — hook listo, falta la regla (PENDIENTE DE DISEÑO):** El mecanismo está implementado y probado de extremo a extremo: `game_state.unlock_npc(id)` → listener → `npc_spawn_manager` reposiciona al NPC en su spawn point (con `SHOW_ALL_NPCS = false`). Los NPCs 01–03 nacen desbloqueados (`persistence.lua`); 04–13 nacen bloqueados. **Falta decidir la regla de desbloqueo** (quién desbloquea a quién): opciones contempladas — (A) lineal numérica (completar `npc_N` desbloquea `npc_{N+1}`), (B) tabla `UNLOCK_CHAIN` en `config.lua` (orden narrativo controlado por el diseñador), (C) campo `unlocks` en el JSON de diálogo, (D) libre albedrío (todos visibles, sin desbloqueo). **Decisión tomada (Agosto 2026):** se deja sin cablear a la espera de definir si habrá hilo argumental o libre albedrío; `SHOW_ALL_NPCS` permanece `true`. Para activarlo en el futuro: definir la regla + una llamada a `unlock_npc()` en `dialogue_manager.on_quiz_result` + `SHOW_ALL_NPCS = false`.
- Add more quiz pools and questions
- Create additional levels/museum rooms
- ✅ Item collection system implemented (10 objects, 5 periods, cut/paste flow)
- Add restoration minigame
- Improve audio management (background music crossfade, volume controls) — *proximity audio for enemies implemented*
- Refine death/respawn visual polish (death animation freeze frame improvements)
- Add game over / death screen polish
- Add language selection (currently Spanish only, structure ready for others)
- Implement tutorial/onboarding
- Add save file management (multiple slots)
- Polish UI transitions and animations
- 🔲 **Mejora #3 (checklist §2, regla #3): pre-hashear identificadores** — convertir las comparaciones `message_id == hash("...")` / `action_id == hash("...")` en constantes pre-computadas a nivel de archivo (`local MSG_X = hash("...")`). **Pendiente de baja prioridad** (higiene/typ-safety, no rendimiento: los eventos de mensaje no son hot paths). Si se aplica, limitar el alcance a los identificadores más usados (`input_event`, `mouse_hover`, `interact`, `take_damage`/`hit`, ~15 scripts), respetando los `hash()` dinámicos de runtime.
- 🔲 **Extensión de auditoría (`audit_globals.sh`)** — extender el script reutilizable a otras reglas del checklist de `docs/DEFOLD_LUA_STANDARDS.md` (p. ej. `hash()` en runtime dentro de hot paths, URLs hardcodeadas repetidas en `msg.post`, concatenación `..` en bucles). **Pendiente.**

---

### 17. Background Sound System (`main/audio_manager.script`)

Sistema de audio de fondo **dirigido por eventos** (refactor Ago 2026): una playlist global secuencial + sonidos de evento específicos que la interrumpen en bucle mientras su sistema esté activo. Se eliminó la activación por zonas de contacto excepto la del **almacén**.

#### 17.1. Arquitectura

```
bootstrap.collection (raíz)
│
├── audio_manager.go            ← 13 pistas embebidas (todas las de fondo)
│   ├── manager.script          ← Cerebro del sistema (audio_manager.script)
│   └── calm_1/2, exploration_1..4, fight_1, quiz_1, library_1,
│       death_1, endgame_1, storage_1, start_1 (embedded)
│
├── main/audio_registry.lua     ← Playlist + eventos + intro (fuente única)
│
└── level_01.collection
    ├── zone_storage.go         ← Zona de almacén (aviso de sala en text_alert)
    └── zone_intake.go          ← Zona de sala de ingreso (aviso text_alert)
```

#### 17.2. Modelo de reproducción

- **🎶 Playlist global (bucle):** `calm_1 → calm_2 → exploration_1..4 → storage_1` en secuencia (`storage_1`, la antigua pista de la zona de almacén, se integró en la playlist como pista regular en Ago 2026 — ya no se dispara por zona). Cada pista suena su **duración completa** (`dur` estático en `audio_registry.lua`, medido con ffprobe — **GOTCHA #17**: esta versión del motor no expone `sound.get_length` en runtime) y comienza la siguiente; al final de la lista, vuelve a la primera. Suena siempre **mientras no haya una orden específica**.
- **🎯 Eventos (pila LIFO en el gestor):** `play_event { id }` empuja un sonido que se reproduce en bucle mientras su sistema esté activo; `stop_event { id }` lo retira (ambos idempotentes). Al vaciarse la pila, la playlist se reanuda en la pista **siguiente** a la interrumpida (no se repite).
- **⚔️ Sonido de pelea (fight_1):** el sondeo de "oleada viva" vive en `main/spawn_enemies.script` (**level_01** — único contexto donde los ids relativos de `factory.create` resuelven con `go.exists`; GOTCHA #18) y notifica al gestor de bootstrap con `play_event`/`stop_event { id = "fight" }` cada 0.5s (mensajes idempotentes a URL completa `bootstrap:/audio_manager#manager`). El gestor no valida objetos del proxy desde bootstrap. Se autorrepara en muerte/reintentar/nuevas oleadas.
- **🎬 Intro:** la escena de intro usa el mensaje legacy `play_ambient` (pista única + loop opcional: `start_1`, luego `calm_1` en loop para el menú). Al cargar `level_01`, `scene_manager` envía `start_playlist`; al volver a la intro, `stop_playlist`.

#### 17.3. Eventos de audio (emisores)

| Evento (`id`) | Pista | Emisor | Activo mientras |
|---|---|---|---|
| `death` | `background_death_1` | `player.script` | `trigger_death` → `trigger_respawn` (animación de muerte + pantalla de reintentar) |
| `endgame` | `background_endgame_1` | ⚠️ **Por implementar** (entrada preparada en el registro, sin emisor aún) | — |
| `fight` | `background_fight_1` | `spawn_enemies.script` (sondeo local de `enemy_state` en level_01) | Algún enemigo de oleada vivo y jugador no muerto |
| `library` | `background_library_1` | `library.gui_script` | `show_book` → `hide_library`/`final` (libro abierto) |
| `pause` | `background_exploration_4` | `pause.gui_script` | `show_pause` → `hide_pause` (menú de pausa abierto) |
| `quiz` | `background_quiz_1` | `dialogue_manager.script` | `start_quiz` → resultado/cancelación/fin de conversación |

> 🏭 **Ago 2026:** `storage` dejó de ser evento — `background_storage_1` (storage_1) es ahora pista regular de la playlist. Las zonas (`zone_storage`, `zone_intake`) solo emiten aviso de sala en text_alert vía `zone_alert.script`.

> 📌 **Ampliar la lista:** añadir un sonido de evento futuro = 1 entrada en `registry.EVENTS` + 1 `play_event`/`stop_event { id }` desde el gameplay (el componente de sonido debe existir en `main/audio_manager.go`).

#### 17.4. Mensajes del Sistema

| Mensaje | Origen → Destino | Descripción |
|---|---|---|
| `start_playlist` | `scene_manager` → `audio_manager` | Arranca la playlist global (level_01 cargada) |
| `stop_playlist` | `scene_manager` → `audio_manager` | Detiene la playlist (intro cargada) |
| `play_event { id }` | player / dialogue / library / pause / spawn_enemies → `audio_manager` | Empuja un evento en la pila (bucle) |
| `stop_event { id }` | idem → `audio_manager` | Retira el evento; al vaciarse la pila reanuda la playlist |
| `play_ambient { sound_url, loop }` | `intro_animation` → `audio_manager` | Legacy: pista única de la intro (loop opcional) |
| `set_volume` | `pause.gui_script` → `audio_manager` | Cambia el volumen global (0.0–1.0) |
| `toggle_audio` | `pause.gui_script` → `audio_manager` | Activa/desactiva todo el audio |
| `get_audio_state` / `audio_state` | `pause.gui_script` ↔ `audio_manager` | Consulta estado actual de volumen |

#### 17.5. Sistema de Fade

| Operación | Duración | Pasos | Descripción |
|---|---|---|---|
| Fade in | 0.2s | 4 | Desde gain 0 hasta target gain, con pasos lineales |
| Fade out | 0.2s | 4 | Desde gain actual hasta 0, luego `sound.stop()` |

#### 17.6. Control de Volumen (Menú de Pausa)

- Tecla **P** abre/cierra menú de pausa (GUI embebida en bootstrap, fuera del proxy); además dispara el evento de audio `pause` (`background_exploration_4` en bucle — el gestor vive en bootstrap, así que sigue sonando con el nivel congelado por `set_time_step`)
- Control deslizante con botones + / - (incrementos de 0.1) y botón mute (volumen 0 ↔ 1)
- Barra de progreso con 3 colores: verde (≥60%), amarillo (30-60%), rojo (<30%)
- El volumen se persiste en `game_state.audio_volume` y `game_state.audio_enabled`; se aplica a la pista actual (playlist o evento)

#### 17.7. Archivos Clave

| Archivo | Función |
|---|---|
| `main/audio_registry.lua` | Playlist (7 pistas), eventos (6 ids) e intro — fuente única de verdad |
| `main/audio_manager.script` | Cerebro: pila de eventos LIFO, playlist secuencial, fades, volumen |
| `main/audio_manager.go` | GO con script + 13 componentes de sonido embebidos |
| `features/props/zone_storage.go` | Zona de almacén (trigger `zone_ambient`/`player_sound` + `zone_alert.script` → aviso de sala en text_alert; sin componentes de sonido) |
| `features/props/zone_alert.script` | Aviso de sala: al entrar en una `zone_*` envía `show_alert` con el nombre localizado (`locations.room_*`) |
| `features/props/zone_intake.go` | Zona de sala de ingreso (trigger `zone_ambient`/`player_sound` + `zone_alert.script`) |
| `features/player/player.script` | Evento `death` (trigger_death → trigger_respawn) |
| `main/dialogue_manager.script` | Evento `quiz` (start_quiz → resultado/cancel/fin) |
| `gui/library.gui_script` | Evento `library` (show_book → hide_library/final) |
| `gui/pause.gui_script` | Evento `pause` (show_pause → hide_pause) + control de volumen |
| `main/scene_manager.script` | `start_playlist` / `stop_playlist` según la escena cargada |
| `main/spawn_enemies.script` | Sondeo de `enemy_state` (oleada viva) → evento `fight` |
| `bootstrap.collection` | Contiene `audio_manager` como instancia fuera del proxy |
| `main/game_state.lua` | Persistencia de `audio_volume` y `audio_enabled` |
| `assets/sounds/background_*.ogg` | Archivos de audio (ogg) para cada pista |
| `assets/sounds/background_*.sound` | Definiciones de sonido (.sound) para Defold |

### 18. Debug Logging System (`main/config.lua`)

Sistema de logging centralizado con **kill-switch global** + **toggles granulares por archivo/subsistema**.

#### 18.1. Flags y API

| Elemento | Tipo | Descripción |
|---|---|---|
| `M.DEV_MODE` | bool (`true`) | Modo desarrollo: resetea progreso y partida al iniciar, activa tecla R. **Cambiar a `false` antes de compilar a producción.** |
| `M.DEBUG` | bool (`false`) | **Kill-switch global:** si es `false`, ningún log del sistema imprime. |
| `M.make_log(enabled)` | factory | Devuelve una función `dprint(...)` que imprime solo si `M.DEBUG` (global) **Y** `enabled` (toggle capturado en el closure) son `true`. |
| `M.dprint` | alias | Equivale a `M.make_log(true)`: imprime cuando `M.DEBUG` esté activo, sin granularidad. Conservado como API pública de compatibilidad; los módulos nuevos deben usar `make_log()`. |

#### 18.2. Toggles granulares por archivo

Cada script que quiera logs propios crea su función en la cabecera:

```lua
local config = require "main.config"

-- 🔧 DEBUG granular: true = loguea cuando M.DEBUG esté activo; false = silenciado
local DEBUG_CAR = true
local dprint = config.make_log(DEBUG_CAR)
```

| Toggle | Archivo | Default |
|---|---|---|
| `DEBUG_NPC` | `main/npc.script` | `true` |
| `DEBUG_CAR` | `features/props/car.script` | `true` |
| `DEBUG_CAR_SPAWN` | `features/props/car_start_point.script` | `true` |
| `DEBUG_DOORS` | `features/props/doors.script` | `true` |
| `DEBUG_DOOR_MAIN` | `features/props/door_main.script` | `true` |
| `DEBUG_SPRAY_SPAWN` | `features/props/spray_spawn_container.script` | `true` |
| `DEBUG_FOOD_SPAWN` | `features/props/food_spawn_container.script` | `true` |
| `DEBUG_NAV` | `features/cat/cat_nav.lua` | `false` (logs `[GATO-NAV]` de atasco/navegación) |
| `DEBUG_CAT` | `features/cat/cat.script` | `false` (logs `[GATO]` de estados, ataques e interacción) |
| `DEBUG_PLAYER` | `features/player/player.script` | `false` (logs `[%04d]`/`[JUGADOR]` de animación, movimiento, muros, muerte/respawn) |
| `DEBUG_HUD` | `gui/hud.gui_script` | `false` (logs `[HUD]` de eventos: idioma, retry, estado, alertas) |
| `DEBUG_DIALOGUE` | `main/dialogue_manager.script` | `false` (logs del flujo de diálogo, quiz y audio) |
| `DEBUG_EXHIBITION` | `main/exhibition_manager.script` | `false` (logs del gestor de exhibición y textos) |
| `DEBUG_SCENE` | `main/scene_manager.script` | `false` (logs de carga de escenas, pausa y enrutado de input) |
| `DEBUG_AUDIO` | `main/audio_manager.script` | `false` (logs de ambientes, playlists y fades) |
| `DEBUG_INVENTORY` | `main/inventory_manager.script` | `false` (logs del ciclo de vida de coleccionables) |

#### 18.3. Comportamiento

| `M.DEBUG` | Toggle local | Resultado |
|---|---|---|
| `false` | — | Nada se imprime (producción) |
| `true` | `true` | El log del archivo se imprime |
| `true` | `false` | El log del archivo se silencia (p. ej. `DEBUG_NAV`) |

**Para depurar:** 1) `M.DEBUG = true` en `main/config.lua`; 2) poner a `true` el toggle del subsistema que interese (los 8 primeros ya están en `true`; los 9 restantes —`DEBUG_NAV`, `DEBUG_CAT`, `DEBUG_PLAYER`, `DEBUG_HUD`, `DEBUG_DIALOGUE`, `DEBUG_EXHIBITION`, `DEBUG_SCENE`, `DEBUG_AUDIO`, `DEBUG_INVENTORY`— están en `false` por defecto).

> ⚠️ **Nota:** los logs `[GATO]` de `features/cat/cat.script` **ya están integrados** (toggle `DEBUG_CAT`), así como los de `player.script` (`DEBUG_PLAYER`), `hud.gui_script` (`DEBUG_HUD`), `dialogue_manager` (`DEBUG_DIALOGUE`), `exhibition_manager` (`DEBUG_EXHIBITION`), `scene_manager` (`DEBUG_SCENE`), `audio_manager` (`DEBUG_AUDIO`) e `inventory_manager` (`DEBUG_INVENTORY`). Todos los `print()` sueltos de estos 5 gestores se migraron a `dprint()` (59 en total).

---

### 19. Orden de Render Global de las GUI (`gui.set_render_order`)

#### 19.1. Esquema

Todas las escenas GUI del juego tienen un orden de render **explícito** fijado en el `init()` de su `gui_script` (**mayor = encima**):

| Orden | GUI | Script donde se fija | Game object / Colección |
|---|---|---|---|
| **6** | `victory.gui` (pantalla de victoria) | `gui/victory.gui_script` `init()` | `gui_victory` / `bootstrap.collection` |
| **5** | `web_controls.gui` (controles táctiles) | `gui/web_controls.gui_script` `init()` | `gui_web_controls` / `bootstrap.collection` |
| **4** | `pause.gui` (menú de pausa) | `gui/pause.gui_script` `init()` | `gui_library` / `bootstrap.collection` |
| **3** | `library.gui` (libro abierto) | `gui/library.gui_script` `init()` | `gui_library` / `bootstrap.collection` |
| **2** | `exhibition.gui` (panel de exhibición) | `gui/exhibition.gui_script` `init()` | `gui` / `level_01.collection` |
| **1** | `interactive.gui` (diálogo/quiz) | `gui/interactive.gui_script` `init()` | `gui` / `level_01.collection` |
| **0** | `hud.gui` (HUD) | `gui/hud.gui_script` `init()` | `gui` / `level_01.collection` |

#### 19.2. Por qué existe

`gui.set_render_order(n)` asigna el orden de render a **esa escena GUI**, y el motor ordena **todas las escenas GUI del frame** por ese valor (más alto = encima), independientemente del game object o colección donde vivan. Por eso el esquema es **global**: el quiz/exhibición (nivel) y la pausa/libro (bootstrap) compiten por el mismo espacio y hay que ordenarlos todos juntos.

**Sin él**, el orden dependía del orden implícito de componentes dentro de cada game object (el último listado se dibuja encima). Con el orden `interactive → hud → exhibition` del GO `gui` en `level_01.collection`, el resultado era `exhibition` arriba, `hud` en medio e `interactive` abajo — **no** el deseado (`exhibition, interactive, hud`). Fijar los valores hace el orden determinista y a prueba de reordenaciones en el editor.

**Detalle:** el orden de nodos **dentro** de cada escena sigue siendo el del árbol del `.gui` (jerarquía + propiedad *Layer* por nodo); `set_render_order` solo ordena escenas completas entre sí.

---

### 20. Sistema de Tareas, Rangos y Victoria (Ago 2026)

#### 20.1. Las 4 tareas y sus umbrales — fuente única: `main/tasks.lua`

| # | Tarea | Condición | Umbrales |
|---|---|---|---|
| 1 | Catálogo y exposiciones | 10 objetos en estado `completed` (`inventory_items_status`) | 10 expuestos |
| 2 | Asistencia al público | Las 10 interacciones de quiz general TERMINADAS y mín. 8 acertadas | 10 interacciones / 8 aciertos |
| 3 | Restauración | Las 5 interacciones de restauración TERMINADAS y mín. 3 acertadas | 5 interacciones / 3 aciertos |
| 4 | Control de plagas | Bichos eliminados (`task_bugs_total`) | mín. 20 |

- **Tarea 2** se evalúa al terminar TODAS las interacciones generales: los 10 NPCs `quiz_general` (`npc_01`..`npc_10`) quedan `completed` (por acierto o agotar los 3 intentos) y `task_quiz_total >= 8`.
- **Tarea 3** se evalúa al terminar TODAS las restauraciones: los 5 objetos con `requires_restoration` (uno por periodo) salen del estado `restoration` y `task_restoration_total >= 3`.

#### 20.2. Rangos (`skills`)

`skills = 1 + tasks_completed` (0..4 tareas → rango 1..5). Los nombres viven en `general_text_[lan].lua → M.ranks` (novato → director). El HUD muestra el rango textual (`text_skills`) y el contador "Tareas: X/4" (`text_tasks_total`, texto `inventory.tasks_progress`).

#### 20.3. Evaluación (event-driven, monótona)

`game_state.evaluate_tasks()` recalcula las 4 tareas desde el estado real (idempotente y barato) y se llama SOLO en sesión, desde:

- Quiz → `register_npc_success` / `register_npc_failure`
- Plagas → `add_to_global("task_bugs_total")`
- Exposición / Restauración → `save_inventory_state` (inventory_manager, con `inventory_items_status` fresco)

Diseño: el conteo **solo sube** (`count > prev`). Un valor persistido solo puede subestimar y se auto-corrige al alza con el siguiente evento. La victoria se dispara **solo ante una transición real en sesión** (la 4ª tarea completada por una acción del jugador): cargar una partida ya ganada **NO** re-muestra la victoria (flag RAM `_victory_triggered`, reseteado en `reset_all` para poder volver a ganar).

#### 20.4. Flujo de victoria

`evaluate_tasks()` → listeners (`game_state.on_victory`) → `gui/victory.gui_script` (bootstrap, GO `gui_victory`, render order 6):

1. Pausa el nivel (`pause_game` → `set_time_step factor=0`)
2. Muestra `dialogs.game_over_victory` + "Rango final: %s" (`dialogs.victory_rank_label`) + botón "Nueva partida" (`ui.btn_new_game`)
3. Botón: `resume_game` + `reset_all` + `goto_intro` (vuelve a la intro con progreso limpio)

El listener de victoria hace **solo** `msg.post` a URL absoluta (`bootstrap:/gui_victory#victory`) y el trabajo `gui.*` se hace en `on_message` del gui_script — ver docs/DEV_GOTCHAS.md → **GOTCHA #24**. Hook de animación TBD: constante `VICTORY_ANIMATION_URL` comentada en `victory.gui_script` (el destino debe vivir FUERA de level_01).

#### 20.5. Atajo de pruebas (tecla N)

Con `config.DEV_MODE = true`, la tecla N (`input/game.input_binding` → `debug_victory`, handler en `scene_manager.on_input`) llama a `game_state.debug_force_victory()`: marca las condiciones de las 4 tareas y dispara la secuencia de victoria real. Resetea `tasks_completed`/`_victory_triggered` internamente para que siempre dispare (herramienta de pruebas; en producción queda desactivada por DEV_MODE).

#### 20.6. Bugs corregidos asociados (Ago 2026)

- **`scene_manager.current_proxy` stale tras `goto_intro`**: el `proxy_loaded` de la intro no lo actualizaba → el siguiente `goto_level_01` se ignoraba con el guard "level_01 ya está activo" → imposible re-entrar al juego. Fix: la rama intro de `proxy_loaded` fija `current_proxy = PROXY_INTRO`.
- **Input reenviado a un nivel descargado**: `goto_intro` ahora limpia `input_mode`/`input_target`/`input_targets` inmediatamente (evita "Could not find socket 'level_01'" durante la transición).
- **Callbacks muertos tras descargar level_01**: `notify_callbacks` es auto-curativo (pcall + retirada) — ver docs/DEV_GOTCHAS.md → **GOTCHA #25**.

#### 20.7. Textos nuevos

`general_text_[lan].lua`: `dialogs.game_over_victory`, `dialogs.victory_rank_label`, `inventory.tasks_progress`. Input binding nuevo: `KEY_N → debug_victory` (dev).

---

*Summary generated on August 13, 2026 – Updated August 16, 2026 (auditoría de calidad, 10 hallazgos cerrados). Keep this file updated when significant architectural changes are made.*
