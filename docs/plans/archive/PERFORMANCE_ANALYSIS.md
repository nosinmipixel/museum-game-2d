# Análisis de Rendimiento - Top Down Museum Game (Defold)

> **Fecha:** Junio 2026
> **Proyecto:** Test Defold Museum Game
> **Motor:** Defold (Lua)

---

## 🔴 CRÍTICO: El sistema de persistencia escribe a disco en cada acción

**Archivos involucrados:** `main/game_state.lua`, `main/persistence.lua`, `features/player/player_spray.script`

### Problema

`game_state.set_global()` encadena la siguiente llamada en cada invocación:

```
set_global() → M.save() → persistence.guardar_progreso() → sys.save() (escritura a disco)
```

Esto significa que **cada partícula de spray que dispara el jugador provoca una escritura completa del archivo de guardado a disco**.

### Flujo crítico

En `features/player/player_spray.script`, la función `fire_particle()` se ejecuta cada `fire_rate = 0.05` segundos (hasta 20 veces/segundo):

```lua
function fire_particle(self)
    self.resources = self.resources - 1
    game_state.set_global("spray_current", self.resources) -- ← ¡sys.save() aquí!
    ...
end
```

Con la tasa de disparo de 0.05s, el juego intenta escribir a disco **20 veces por segundo** mientras se dispara spray. Esto incluye serializar toda la tabla de estado (globals + 20 NPCs + quiz state) cada vez.

### Problema adicional en persistence.lua

Muchas funciones en `persistence.lua` hacen:

```lua
function alguna_funcion()
    local datos = cargar_progreso()   -- 1. sys.load() (lectura completa de disco)
    -- modificar algo en memoria
    return guardar_progreso(datos)     -- 2. sys.save() (escritura completa a disco)
end
```

Hay **13+ llamadas a `cargar_progreso()`** desde distintas funciones. Cada `cargar_progreso()` ejecuta:

- Validación de versión y migración de datos
- Bucle de 20 iteraciones para verificar NPCs
- Comprobación de campos por defecto para cada variable global
- Inicialización de estructura `current_quiz` si falta

### Impacto medido

| Escenario | Operaciones de I/O por segundo |
|-----------|-------------------------------|
| Disparo continuo de spray | ~20 lecturas/escrituras de disco/segundo |
| Cambio de variable global | 1 lectura + 1 escritura por cambio |
| Múltiples NPCs activos | Lectura/escritura por cada interacción |

**Esto causa micro-pausas visibles durante el combate**, especialmente en plataformas con I/O más lento como móvil o WebAssembly.### ✅ Solución implementada (Junio 2026)

Se implementó el guardado diferido con dirty flag:

- `M.save()` ahora **solo marca los datos como pendientes** (`M._dirty = true`) sin escribir a disco
- Se añadió `M.flush()` que escribe a disco **solo si hay cambios pendientes**
- `main.script` ejecuta `game_state.flush()` cada 5 segundos en `update()`
- `main.script.final()` ejecuta `flush()` al cerrar el juego para no perder datos
- `M.reset_all()` sigue escribiendo inmediatamente (operación destructiva)
- En DEV_MODE, se fuerza `flush()` inmediato tras el reset inicial
- Se eliminó el `require` redundante en `init_default_npc_progress()`
- Se eliminaron los stubs vacíos de `main.script` que añadían overhead

---

## 🟠 ALTO: JSON re-parseado en cada inicio de quiz

**Archivo:** `gui/interactive.gui_script` (línea ~383)

### Problema

```lua
local file = sys.load_resource(path)
local data = json.decode(file)  -- Se carga y parsea TODO el JSON cada vez que inicia un quiz
```

Cada vez que se inicia un quiz, la GUI:
1. Lee el archivo JSON completo desde el sistema de recursos (`sys.load_resource`)
2. Parsear el JSON completo con el decoder de `dkjson.lua`

Esto ocurre incluso cuando `dialogue_manager.script` ya ha cargado y parseado el mismo JSON en su `init()`. La GUI ignora ese dato cacheado y hace su propia carga redundante.

### Impacto

Con quizzes frecuentes, se desperdicia CPU en parsear un archivo que no cambia durante la ejecución.

### Solución recomendada

Cachear el resultado de `json.decode()` después de la primera carga, ya sea:
- En el mismo script (variable `self.dialog_data_cache`)
- Pasar la data desde el `dialogue_manager` mediante un mensaje

---

## 🟠 ALTO: NPC.script ejecuta update() en todos los NPCs cada frame

**Archivo:** `main/npc.script`

### Problema

```lua
function update(self, dt)
    update_icon_state(self)  -- Corre en CADA frame para CADA NPC de la escena
end
```

`update_icon_state()` accede a `game_state.npc_progress[npc_id]` y llama a `game_state.is_npc_available()`. Aunque tiene una caché que evita cambios visuales redundantes:

```lua
if new_state == self.last_icon_state then return end
```

...sigue ejecutando la función completa (búsqueda en tabla, llamadas a funciones, condicionales) para cada NPC en cada frame.

### Cálculo de impacto

Con `NPC_COUNT = 20` NPCs a 60 FPS:
- 20 NPCs × 60 frames/s = **1200 ejecuciones de `is_npc_available()` por segundo**
- Cada ejecución hace búsquedas en tablas anidadas y condicionales

### Solución implementada (híbrido, Ago 2026)

Se eliminó el polling **por frame** y se adoptó un enfoque mixto:

- **Eventos para cambios discretos:** tras un quiz, `dialogue_manager` envía `npc_state_changed` al NPC (únicamente el afectado), que refresca su icono al instante. Los NPCs ya no ejecutan `update_icon_state()` en cada frame.
- **Polling throttled SOLO para la expiración del cooldown wall-clock** (`ICON_POLL_INTERVAL = 0.5`, 2 Hz) en `npc.script.update()`: el cooldown (`os.time() + 60` en `register_npc_failure`) **no genera ningún evento al expirar** — solo la restauradora recibe un `timer.delay` del dialogue_manager, que además no sobrevive a guardar/recargar. Sin este poll, el icono de un NPC fallado quedaba en rojo para siempre tras reactivarse (bug reportado). Con la caché `last_icon_state`, cuando el estado no cambia el coste es despreciable (lecturas de tabla + `os.time`, sin alocaciones). Es la alternativa que este mismo análisis contemplaba ("bajar la frecuencia a 1-2 veces por segundo usando un timer").

> ⚠️ Nota: con 13 NPCs a 2 Hz serían ~26 `is_npc_available()`/s como peor caso — trivial frente a los 1200/s del polling por frame original.

---

## 🟡 MEDIO: main.script con stubs vacíos

**Archivo:** `main/main.script`

### Problema

```lua
function update(self, dt) end           -- ← stub vacío
function late_update(self, dt) end      -- ← stub vacío
function fixed_update(self, dt) end     -- ← stub vacío
function on_message(self, ...) end      -- ← stub vacío
function on_reload(self) end            -- ← stub vacío
```

Defold invoca **todas** estas funciones en cada frame aunque estén vacías. Cada stub añade:
- Overhead de llamada a función Lua
- Overhead de paso de parámetros
- Overhead de retorno

### Solución recomendada

**Eliminar estas funciones.** En Defold, si una función no está definida, el motor no la llama, ahorrando ese overhead. Solo mantener las que realmente se usan (`init`, `final`, `on_input`).

---

## 🟡 MEDIO: Variables globales no usadas

**Archivo:** `main/camera.script`

### Problema

```lua
function init(self)
    GLOBAL_CAMERA_X = go.get_position().x  -- Se escribe pero nunca se lee
    GLOBAL_CAMERA_Y = go.get_position().y  -- Se escribe pero nunca se lee
end

function update(self, dt)
    ...
    GLOBAL_CAMERA_X = new_x  -- Se escribe pero nunca se lee
    GLOBAL_CAMERA_Y = new_y  -- Se escribe pero nunca se lee
end
```

- Estas variables globales contaminan el namespace global de Lua
- **No son leídas por ningún otro script** del proyecto (solo se mencionan en docs/PROJECT_SUMMARY.md como documentación)
- `player_spray.script` ya recibe la posición de cámara correctamente mediante el mensaje `camera_moved`

### Solución recomendada

Eliminar las líneas que escriben `GLOBAL_CAMERA_X` y `GLOBAL_CAMERA_Y`.

---

## 🟡 MEDIO: Función world_to_screen() duplicada en 3 archivos

**Archivos involucrados:**
- `main/dialogue_manager.script`
- `main/exhibition_manager.script`
- `features/exhibition_objects/exhibition_object.script`

### Problema

La misma función de conversión de coordenadas mundo → pantalla está implementada **3 veces** de forma casi idéntica:

```lua
local function world_to_screen(world_pos)
    local base_width = 1280
    local base_height = 768
    local window_width, window_height = window.get_size()
    local scale_factor_x = window_width / base_width
    local scale_factor_y = window_height / base_height
    local ortho_zoom = 2.0
    local camera_go_url = msg.url(nil, "/camera", nil)
    local cam_pos = go.exists(camera_go_url) and go.get_position(camera_go_url) or ...
    -- ... más cálculos
end
```

Esto es una violación del principio DRY (Don't Repeat Yourself). Si se necesita cambiar la fórmula de conversión (por ejemplo, ajustar el zoom o la resolución base), hay que modificar 3 archivos.

### Solución recomendada

Extraer a un módulo Lua compartido, por ejemplo `main/screen_utils.lua`, y requerirlo desde donde sea necesario.

---

## 🟡 MEDIO: Persistencia con I/O duplicado en funciones auxiliares

**Archivo:** `main/persistence.lua`

### Problema

Funciones como `guardar_progreso_npc()`, `incrementar_quiz_total()`, `actualizar_variable_global()`, etc. hacen:

```lua
function incrementar_quiz_total(increment)
    local datos = cargar_progreso()  -- sys.load() completo
    datos.globals.task_quiz_total = datos.globals.task_quiz_total + increment
    return guardar_progreso(datos)   -- sys.save() completo
end
```

Para incrementar un simple contador, se lee y escribe el archivo completo con datos de 20 NPCs, variables globales y quiz state.

### Solución recomendada

Centralizar todas las operaciones en un **sistema de estado en memoria** (ya existe `game_state.lua` para esto) y evitar llamar directamente a las funciones de `persistence.lua` que hacen doble I/O.

---



## 🟢 BAJO: require redundante dentro de función

**Archivo:** `main/game_state.lua` (línea ~68)

```lua
function M.init_default_npc_progress()
    local persistence = require "main.persistence"  -- Ya requerido al inicio del archivo
```

`require` en Lua cachea los módulos, así que la segunda llamada simplemente devuelve la misma tabla. No tiene impacto en rendimiento pero es código redundante.

---

## 📋 Tabla Resumen de Prioridades

| Prioridad | Problema | Archivo(s) | Acción recomendada |
|-----------|----------|-----------|--------------------|
| 🔴 **Crítico** | `sys.save()` en cada partícula de spray | `game_state.lua`, `player_spray.script`, `persistence.lua` | Cachear en RAM y guardado diferido periódico |
| 🟠 **Alto** | JSON re-parseado en cada quiz | `interactive.gui_script` | ✅ **Solucionado:** Cacheado en `self.dialog_data_cache` tras primera carga |
| 🟠 **Alto** | NPC update() cada frame/NPC | `npc.script` | ✅ **Solucionado:** Evento `npc_state_changed` tras quiz + poll throttled 2 Hz solo para expiración de cooldown wall-clock (icono de disponibilidad) |
| 🟡 **Medio** | Stubs vacíos en main.script | `main.script` | ✅ **Solucionado:** Eliminados junto con la primera optimización |
| 🟡 **Medio** | Variables globales `GLOBAL_CAMERA_X/Y` no usadas | `camera.script` | ✅ **Solucionado:** Eliminadas, no se leían en ningún otro script |
| 🟡 **Medio** | `world_to_screen()` duplicado en 3 archivos | `dialogue_manager`, `exhibition_manager`, `exhibition_object` | ✅ **Solucionado:** Extraído a `main/screen_utils.lua` compartido |
| 🟡 **Medio** | Persistencia lee/escribe archivo completo en cada operación auxiliar | `persistence.lua` | ✅ **Solucionado:** Las 10 funciones ahora delegan a `game_state` en RAM, sin I/O directo |
| 🟢 **Bajo** | `require` redundante dentro de función | `game_state.lua` | Eliminar línea duplicada |

## 🧠 Observaciones Adicionales

- El proyecto usa `pcall()` extensivamente como protección contra errores de GO eliminados. Esto es una buena práctica defensiva, pero `pcall` tiene overhead. Evaluar si es necesario en todos los casos.
- Hay múltiples timers creados/cancelados en `dialogue_manager.script`. Defold maneja bien los timers, pero la cancelación frecuente de timers repetitivos puede acumular overhead.
- El sistema de notificaciones por callback en `game_state.lua` es correcto pero actualmente solo se usa para `max_spray` y `spray_current`. Podría extenderse para eliminar el polling de los NPCs.

---

---

## 🧱 Análisis del Tilemap (Agosto 2026): ¿vale la pena el chunking / carga progresiva de zonas?

> **Archivo:** `assets/tiles/level_map_1.tilemap` · **Tilesource:** `assets/tiles/tiles_map_1.tilesource` (`tileset_map_1.png`)
> **Montaje:** `level_01.collection` → GO `level2` con el tilemap como componente + **3 collision objects estáticos** (grupo `walls`, máscaras `player` / `enemies` / `npcs`) con el tilemap como shape.

### Números reales del mapa (medidos Ago 2026)

| Dato | Valor |
|---|---|
| Cuadrícula | ~70 × 80 tiles (máx. x=69, y=79) |
| Tile | 32 × 32 px |
| Dimensiones del mundo | 2240 × 2560 px |
| Celdas pintadas (7 capas) | **7.571** (capa 1 suelo: 5.417 · capas 2-7 decoración/muros: 2.154) |
| Tiles distintos | 660 (una sola textura 1024×1024) |
| Área visible (zoom 2.0, 1280×768) | 640 × 384 px = 20 × 12 tiles |
| Colisión | 3 collision objects estáticos con shape de tilemap |

El mapa es **grande para el juego** (~23 pantallas explorables) pero **diminuto como tilemap** de Defold.

### Cómo renderiza Defold los tilemaps (fuentes: docs oficiales + foro, hilo de Mathias Westerdahl)

1. **No hay culling por tile:** dentro de un tilemap no se descartan tiles individuales fuera de cámara.
2. **Frustum culling a nivel de componente** (por bounding box): como el tilemap abarca todo el nivel, su bbox siempre interseca la cámara → **todos los tiles se envían cada frame sí o sí**.
3. **Batching:** los tiles del mismo tilesource+material se agrupan en muy pocos draw calls (7 capas → pocos).
4. **Coste real:** ~7.6k quads ≈ **30k vértices por frame** batched → **trivial** para cualquier GPU, incluida WebGL móvil (los problemas empiezan en cientos de miles de vértices o miles de draw calls).
5. **Memoria:** la cuadrícula (~39k celdas potenciales × pocos bytes) y una textura 1024² son minúsculos.
6. **Física:** los estáticos de Box2D se indexan por AABB en el broadphase; los muros lejanos no cuestan contacto ni solución por frame.

### Veredicto: NO implementar chunking

Con chunks se pasaría de renderizar 7.6k quads a ~1.7k visibles (20×12 tiles × 7 capas): un ahorro **despreciable frente al fill rate de lo visible y al resto de sistemas**. El coste, en cambio, es alto:

- Partir el tilemap en N sub-tilemaps (herramienta/script de edición).
- Los **3 collision objects** con shape de tilemap se convierten en 3×N (o uno por chunk).
- Un gestor de streaming (cargar/descargar por distancia del jugador) con los bugs típicos: hitches al cargar, bordes entre chunks, coordenadas.

Además, los cuellos de botella reales del proyecto identificados en este mismo documento (I/O de guardado, parseo JSON, polling de NPCs) no son render, y el build pesado viene de texturas/`custom_resources` (ver docs/plans/GITHUB_PUBLISH_PLAN.md), no del tilemap.

### Cuándo SÍ merecería la pena (y qué patrón usar)

- Si el mapa creciera **10×+** (p. ej. 700×800 tiles o más) o fuera procedural/infinito → **patrón oficial recomendado por el equipo de Defold**: partir el mapa (p. ej. en Tiled, que exporta a formato Defold) en tilemaps pequeños dentro de **sub-colecciones cargadas con collection proxies**, que gestionan carga/descarga aislada de recursos sin hitches ni picos de memoria. Referencia: `britzl/publicexamples/infinite_map`.
- Si la memoria de texturas del tileset fuera el problema (aquí es 1 textura, no lo es).
- Si apareciera un problema de render **medido con el profiler** en móvil — hasta entonces, no tocar nada (regla del propio proyecto: optimizar sin medición es prohibido, `docs/DEFOLD_LUA_STANDARDS.md` §1).
- Para worlds procedurales pequeños también es viable `tilemap.set_tile()` en runtime, pero **nunca en bucles por frame** (provoca stutter; cargar un chunk por frame, no todos síncronos).

### Alternativa barata (si algún día se quisiera aligerar)

Fusionar las capas decorativas (2-5 y 7: 1.204 celdas en total) — coste cero en gameplay, algo menos de complejidad de geometría. Tampoco es necesario hoy.

---

## 📖 Fuentes y Caracteres Especiales del Español — Lección Aprendida

### Contexto

El sistema de lectura de libros (`gui/library.gui_script`) tuvo un problema intermitente donde el texto completo no se visualizaba correctamente. Los textos en español contienen caracteres acentuados (á, é, í, ó, ú, ü, ñ) y puntuación especial (¿, ¡, «, », ª, º) que pueden no renderizarse si la fuente no está configurada para incluirlos.

### Causa Raíz

Defold genera un **glyph bank** (atlas de textura) a partir del archivo `.font` durante la compilación. Este glyph bank contiene solo los caracteres que Defold sabe que va a necesitar. Si un carácter acentuado no está incluido en el glyph bank, el motor no puede renderizarlo y el nodo de texto muestra un espacio vacío o un rectángulo.

El archivo `.font` de Defold tiene dos mecanismos para controlar qué caracteres se incluyen:

1. **`all_chars: false`** (valor por defecto) — solo se incluyen los caracteres listados explícitamente en el campo `characters` (ASCII 32-126 por defecto).
2. **`all_chars: true`** — se incluyen **todos** los glifos disponibles en el archivo TTF/OTF fuente.

**Problema original:** El campo `characters` en los archivos `.font` incluye solo los caracteres ASCII estándar más una selección manual de caracteres españoles. Si esta selección está incompleta o si `all_chars` está desactivado, los caracteres acentuados no se renderizan.

### Solución Aplicada

Los tres archivos `.font` del proyecto (`assets/fonts/dialogs.font`, `quiz.font`, `title.font`) ahora tienen:

```
all_chars: true
characters: " !\"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~áéíóúüñÁÉÍÓÚÜÑ¿¡ªº«»"
```

- `all_chars: true` garantiza que **todos** los glifos del TTF fuente están disponibles, incluyendo cualquier carácter español que pudiera faltar en la lista manual.
- El campo `characters` se mantiene como lista explícita para que, incluso si `all_chars` se desactivara accidentalmente, los caracteres esenciales del español sigan incluidos.

### Archivos Afectados

| Archivo .font | Uso |
|---|---|
| `assets/fonts/dialogs.font` | Diálogos, HUD, libros, quizzes, textos generales |
| `assets/fonts/quiz.font` | Preguntas de quiz (si usa fuente separada) |
| `assets/fonts/title.font` | Títulos en pantalla |

### Cómo Detectar este Problema en el Futuro

Si al añadir nuevos textos en español (o cualquier idioma con caracteres no ASCII: alemán, francés, catalán, etc.) los caracteres especiales aparecen como espacios vacíos o rectángulos:

1. **Verificar `all_chars`**: Abrir el archivo `.font` en el editor de Defold y comprobar que `all_chars` está activado.
2. **Verificar la fuente TTF**: Asegurarse de que el archivo `.ttf` fuente contiene los glifos necesarios (ej: `MatrixSans-Regular.ttf` soporta Latin Extended).
3. **Consola de errores**: Buscar mensajes como `Out of available cache cells! Consider increasing cache_width or cache_height` — esto indica que el glyph bank está lleno y necesita más espacio.
4. **Previsualización en editor**: Si el carácter no aparece en la previsualización del `.font` dentro del editor de Defold, no se renderizará en tiempo de ejecución.

### Nota sobre `gui/library.gui_script`

El script del sistema de libros ya documenta internamente varios fixes (FIX A–FIX F) relacionados con la paginación y el límite interno de ~256 caracteres por nodo de texto distance field. El problema de los caracteres especiales españoles es **independiente** de esos fixes — opera a nivel de la generación del glyph bank, no a nivel de la lógica de paginación.

---

*Análisis generado por Codebuff — Junio 2026*
