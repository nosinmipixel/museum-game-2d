# Defold – Estructura de Escenas: Implementación Actual

> **Documento actualizado — refleja la implementación real tras el refactor.**
> Juego top-down exploratorio desarrollado en Defold.

---

## 0. Estado del proyecto

| Elemento | Estado |
|---|---|
| Motor | Defold |
| Colección raíz | ✅ `bootstrap.collection` (`name: "bootstrap"`) |
| Gestor de escenas | ✅ `main/scene_manager.script` |
| Nivel principal | ✅ `level_01.collection` (proxy: `bootstrap:/proxy_level_01#proxy`) |
| Pantalla de intro | ✅ `intro.collection` (proxy: `bootstrap:/proxy_intro#proxy`) |
| Input bootstrap | ✅ `scene_manager` adquiere focus y reenvía eventos |
| Input en proxys | ✅ Forwarding vía mensajes `input_event` / `mouse_event` |

---

## 1. Arquitectura actual

```
bootstrap.collection (raíz, nunca se descarga)
│
├── main_loader.go
│   └── scene_manager.script ← adquiere input focus
│
├── audio_manager.go
│   └── manager.script ← gestor de sonido ambiente
│
├── gui_library (embedded instance)
│   ├── library.gui + library.gui_script ← sistema de lectura de libros
│   └── pause.gui + pause.gui_script ← menú de pausa (P) + control de volumen
│
├── proxy_intro.go                            ┐
│   └── collectionproxy → intro.collection     │ una activa
│                                              │ a la vez
├── proxy_level_01.go                          │
│   └── collectionproxy → level_01.collection  ┘
│
└── [proxy_level_NN.go para futuros niveles]
```

---

## 2. Sistema de input

### 2.1. Modo INTRO

`scene_manager.on_input()` reenvía solo eventos de ratón (hover + click) a la GUI de intro:

```
scene_manager → msg.post("intro:/gui_intro#intro_gui", "mouse_event", {...})
```

La GUI procesa `mouse_event` en `on_message()` → hover animado + clic en botones.

### 2.2. Modo LEVEL_01

`scene_manager.on_input()` reenvía TODOS los eventos de input a **7 targets** dentro de level_01:

```
scene_manager → msg.post(..., "input_event", {...})
                  ├── level_01:/cursor#cursor        ← mouse move + click
                  ├── level_01:/player#player        ← WASD + Esc
                  ├── level_01:/player#player_spray  ← right click + space
                  ├── level_01:/game_manager#main    ← key_r (dev reset)
                  ├── level_01:/gui#interactive      ← quiz buttons (hover + click)
                  ├── level_01:/gui#hud              ← retry button (hover + click)
                  └── level_01:/gui#exhibition       ← close panel (Esc + click outside)
```

Cada script destino tiene:
- `handle_input()` — función local con la lógica de input extraída
- `on_input()` — llamada por el engine si `acquire_input_focus` funcionara
- `on_message("input_event")` — recibe eventos forwardeados desde scene_manager

### 2.3. Por qué forwarding y no acquire_input_focus

Los scripts dentro de colecciones cargadas por **collection proxy** NO reciben eventos de input incluso llamando a `acquire_input_focus`. La solución es que un script en bootstrap (scene_manager) tenga el foco y reenvíe los eventos como mensajes a los destinos correctos.

---

## 3. Flujo de transición entre escenas

### 3.1. Intro → Level_01

1. Usuario hace clic en "Start" → `intro.gui_script` envía `start_game` a `intro_manager`
2. `intro_manager` envía `goto_level_01` al `scene_manager`
3. `scene_manager` carga `PROXY_LEVEL_01` directamente (sin descargar intro primero)
4. `proxy_loaded` para level_01 → configura input forwarding (7 targets)
5. Intentar descargar PROXY_INTRO (para liberar memoria)

### 3.2. Level_01 → Intro (cuando se implemente)

1. Script dentro de level_01 envía `goto_intro` a `scene_manager`
2. `scene_manager` descarga PROXY_LEVEL_01
3. `proxy_unloaded` → carga PROXY_INTRO
4. `proxy_loaded` para intro → configura input forwarding (intro mode)

---

## 4. Protecciones implementadas

| Protección | Cómo |
|---|---|
| **Doble clic en Start** | Flag `self.loading_proxy` + check `current_proxy == PROXY_LEVEL_01` |
| **current_proxy inconsistente** | Se actualiza en `proxy_loaded` para cada escena |
| **Unload fallido** | No bloqueante — se intenta descargar pero no es crítico si falla |
| **Múltiples envíos de input** | Cada script ignora eventos que no le corresponden (vía action_id) |

---

## 7. Sistema de Suspensión (Pausa Contada + GUI en Bootstrap)

### 7.1. Arquitectura

El sistema permite que **elementos GUI alojados fuera del proxy del nivel** puedan quedar al margen de la suspensión y reproducir animaciones (flipbooks, hovers, transiciones) incluso cuando el nivel está congelado.

```
bootstrap.collection (raíz, nunca se descarga)
│
├── gui_library (embedded instance)
│   └── library.gui + library.gui_script
│       ├── Animaciones: flipbooks de paso de página
│       ├── Animaciones: hover_on / hover_off en botones
│       └── ¡NO se ven afectadas por la pausa del nivel!
│
├── proxy_level_01.go
│   └── level_01.collection
│       ├── gui#hud          ← Animaciones congeladas durante pausa
│       ├── gui#interactive   ← Animaciones congeladas durante pausa
│       └── gui#exhibition    ← Animaciones congeladas durante pausa
│
└── scene_manager.script
    └── paused_count (contador de pausas)
```

### 7.2. Mecanismo: `set_time_step` con Contador de Pausas

El sistema utiliza `set_time_step` enviado al componente `proxy` del nivel para congelar TODO lo que ocurre dentro de la colección cargada por proxy:

```
set_time_step { factor = 0, mode = 1 }
```

| Parámetro | Valor | Efecto |
|---|---|---|
| `factor = 0` | Congela el flujo temporal (física, `update()`, `go.animate()`, timers, animaciones de sprites) |
| `mode = 1` | Además ignora las acciones de input del proxy (la entrada por `acquire_input_focus` de la GUI del libro sigue funcionando) |

Para soportar **múltiples sistemas solicitando pausa simultáneamente** (libro abierto + diálogo + menú de pausa), se implementa un **contador de pausas** (`paused_count`):

```lua
-- main/scene_manager.script
local function pause_time(self)
  self.paused_count = self.paused_count + 1
  if self.paused_count == 1 and self.current_proxy == PROXY_LEVEL_01 then
    msg.post(PROXY_LEVEL_01, "set_time_step", { factor = 0, mode = 1 })
  end
end

local function resume_time(self)
  if self.paused_count == 0 then return end
  self.paused_count = self.paused_count - 1
  if self.paused_count == 0 and self.current_proxy == PROXY_LEVEL_01 then
    msg.post(PROXY_LEVEL_01, "set_time_step", { factor = 1, mode = 0 })
  end
end
```

| Evento | `paused_count` | Acción |
|---|---|---|
| Primer sistema pide pausa | 0 → 1 | `set_time_step(factor=0)` — nivel congelado |
| Segundo sistema pide pausa | 1 → 2 | Solo incrementa contador |
| Primer sistema libera pausa | 2 → 1 | Solo decrementa contador |
| Último sistema libera pausa | 1 → 0 | `set_time_step(factor=1)` — nivel reanudado |

### 7.3. Mensajes de Pausa/Reanudación

Cualquier script dentro o fuera del nivel puede enviar estos mensajes al `scene_manager`:

| Mensaje | Acción |
|---|---|
| `"pause_game"` → `scene_manager` | Incrementa `paused_count`; si es el primero, congela el nivel |
| `"resume_game"` → `scene_manager` | Decrementa `paused_count`; si es el último, reanuda el nivel |

### 7.4. GUI del Libro (Library) — Caso de Uso Principal

**`gui/library.gui_script`** es el caso principal que usa este sistema.

#### 7.4.1. Ubicación

El componente GUI `library.gui` está **embebido en `bootstrap.collection`** (`gui_library`), fuera del proxy del nivel.

#### 7.4.2. Flujo de Apertura

1. El jugador hace clic en una estantería de libros (`bookcase.go`) → el cursor detecta colisión y envía `interact`
2. `bookcase.script` recibe `interact`, extrae el `book_type` del nombre del GO (`bookcase_pal` → `"pal"`)
3. `bookcase.script` envía `show_book{ book_type = bt }` a `bootstrap:/gui_library#library`
4. `library.gui_script.on_message("show_book")`:
   - Busca el libro en `self.books_data` por `book_type`
   - Llama a `pause_game_world()` → envía `"pause_game"` al `scene_manager`
   - El nivel se congela (`set_time_step factor=0 mode=1`)
   - Muestra la GUI del libro y pagina el contenido

#### 7.4.3. Flujo de Cierre

1. El jugador hace clic en botón de cierre (`box_close`) o pulsa ESC (desde `scene_manager`)
2. `hide_library()`:
   - Cancela navegación en curso
   - Oculta todos los nodos GUI
   - Llama a `resume_game_world()` → envía `"resume_game"` al `scene_manager`
   - El nivel se reanuda cuando `paused_count` llega a 0

#### 7.4.4. Animaciones de Navegación

| Elemento | Descripción |
|---|---|
| **Paso de página** | Flipbook overlay `box_pages_flip` con animaciones `book_page_forward`/`book_page_backward` (4 frames @ 5fps, ~0.8s) + sonido `page_turn` |
| **Hover botones** | `btn_backward`, `btn_forward`, `btn_close` con flipbooks de 2 frames: `idle` (oscuro) → `hover_on` (5fps) → `hover_off` (5fps) |
| **Callback animación** | `gui.play_flipbook()` recibe callback que ejecuta `display_page()` + oculta overlay al terminar |
| **Bloqueo doble clic** | Flag `self._navigating` impide avanzar/retroceder durante animación |

#### 7.4.5. Paginación de Texto

El sistema usa `resource.get_text_metrics()` para medir altura del texto y dividir en spreads (2 páginas):

- **Límites:** `MAX_CHARS_PER_PAGE = 250` (respeta límite ~256 chars de Defold en distance field fonts)
- **Fit height:** 97% de la altura del nodo (`FIT_HEIGHT_RATIO = 0.97`)
- **Snap a cláusula:** Corta en `. ! ?` preferentemente, luego `, ; :`, con lookback de 6 palabras
- **Integridad:** Verifica que ninguna palabra se pierda; si detecta pérdida, activa fallback (1 página con todo)
- **Multi-idioma:** Recarga textos via callback de `game_state` cuando cambia el idioma

#### 7.4.6. Input

- `library.gui_script` mantiene `acquire_input_focus` permanentemente (comparte GO con `pause.gui_script`)
- `on_input()` descarta todo input cuando `is_visible == false`
- Hover detectado via `gui.pick_node()`, action_id == nil
- Clic con debounce de 0.01s para evitar doble procesamiento (on_input + on_message)

Las animaciones del libro **siguen funcionando** porque la GUI está en bootstrap y el time-step del motor principal no se ve afectado por `set_time_step(factor=0)` del proxy.

### 7.5. GUI dentro del Nivel (HUD, Interactive, Exhibition)

Estas GUI están **dentro de `level_01.collection`** y, por tanto, se congelan cuando el nivel está pausado:

| Componente GUI | Ubicación | Animaciones durante pausa |
|---|---|---|
| `gui#hud` | `level_01.collection` | ❌ Congeladas |
| `gui#interactive` | `level_01.collection` | ❌ Congeladas |
| `gui#exhibition` | `level_01.collection` | ❌ Congeladas |
| `gui_library#library` | `bootstrap.collection` | ✅ Continúan |

Esto es **intencional**: las barras de salud/spray, los botones de quiz y los paneles de exhibición pertenecen al mundo del juego y no deberían actualizarse durante una pausa.

### 7.6. Archivos Clave del Sistema

| Archivo | Función |
|---|---|
| `main/scene_manager.script` | Core del sistema: `pause_time()`, `resume_time()`, `paused_count` |
| `gui/library.gui_script` | Cliente principal: `pause_game_world()`, `resume_game_world()` |
| `gui/library.gui` | Definición GUI con nodos y animaciones del libro |
| `gui/gui.atlas` | Atlas con sprites de animaciones (botones idle/hover_on/hover_off, book_page_forward/backward) |
| `bootstrap.collection` | Contiene `gui_library` como instancia embebida (fuera del proxy) |

---

## 5. Checklist de archivos modificados

| Archivo | Cambio |
|---|---|
| `bootstrap.collection` | Creada con main_loader, proxy_intro, proxy_level_01 |
| `main/main_loader.go` | Creado con scene_manager.script |
| `main/scene_manager.script` | Gestor de escenas + enrutador de input (modos intro/level_01) |
| `main/cursor.script` | `handle_input()` + `on_message("input_event")` |
| `features/player/player.script` | `handle_input()` + `on_message("input_event")` |
| `features/player/player_spray.script` | `handle_input()` + `on_message("input_event")` |
| `main/main.script` | `handle_input()` + `on_message("input_event")` + `handle_input` para goto_intro |
| `gui/interactive.gui_script` | `handle_input()` + `on_message("input_event")` |
| `gui/exhibition.gui_script` | `handle_input()` + `on_message("input_event")` |
| `gui/hud.gui_script` | `handle_input()` + `on_message("input_event")` |
| `intro.collection` | Creada con intro_manager + gui_intro |
| `intro/gui/intro.gui_script` | GUI con hover animado, recibe `mouse_event` de scene_manager |
| `intro/intro_manager.script` | Lógica de idioma, continuar, reset, start_game |
| `level_01.collection` | Copia de main.collection con `name: "level_01"` |
| `main/level_01.go` | Creado |
| `main/proxy_intro.go` | Creado |
| `main/proxy_level_01.go` | Creado |
| `game.project` | `main_collection = /bootstrap.collection` |

---

## 6. Cómo añadir futuros niveles

1. Duplicar `level_01.collection` → `level_NN.collection`, cambiar `name` y contenido
2. Crear `main/proxy_level_NN.go` con referencia a la colección
3. Añadir `proxy_level_NN` como instancia en `bootstrap.collection`
4. Declarar `PROXY_LEVEL_NN` en `scene_manager.script` y añadir handler
5. Si el nivel necesita scripts que reciban input, añadirlos a `self.input_targets`
