# 🗂️ Plan de Reorganización General del Proyecto

> **Estado:** ⏳ Pendiente — plan aprobado pendiente de ejecución en fases
> **Fecha:** 2026-09-04
> **Proyecto:** Top Down Museum Game (Defold / Lua)
> **Autor:** Codebuff (con revisión pendiente del equipo)

---

## 0. Resumen ejecutivo

El proyecto se reorganizará para acercarse a la estructura propuesta (ver §2), que **no es exhaustiva**: solo orienta la adaptación. El trabajo real consiste en:

1. **Mover ~1.200 archivos** a nuevas ubicaciones (código → `entities/`, arte → `assets/`, textos → `texts/`, niveles → `world/`, colecciones de escena a `intro/` y `world/levels/`).
2. **Reescribir todas las referencias** que Defold resuelve por ruta absoluta (`/carpeta/archivo.ext`) en los 314 archivos de texto del proyecto que contienen referencias.
3. **Actualizar las referencias dinámicas en Lua** (rutas de `sys.load_resource`, módulos `require`, y 1 URL de fallback).
4. **Actualizar `game.project`** (`custom_resources` debe incluir la nueva carpeta `/texts`).

Hay **7 decisiones abiertas (D1–D7)** con recomendación por defecto (§11). Ninguna bloquea el grueso del plan; deben validarse antes de ejecutar la fase 1.

---

## 1. Inventario actual (verificado el 2026-09-04)

**1.285 archivos** en el árbol del proyecto (excluyendo `build/`, `.internal/` y `.git`). No existe repositorio git.

| Extensión | Nº | Nota |
|---|---|---|
| `.png` | 764 | Arte (incluye sprites de atlas, frames de animación) |
| `.go` | 113 | Game objects (texto con referencias) |
| `.pxo` | 94 | Fuentes Aseprite — **gitignored** (`*.pxo`) |
| `.sound` / `.ogg` | 72 / 71 | Pares recurso+audio en `assets/sounds/` |
| `.script` / `.lua` | 39 / 33 | Scripts y módulos |
| `.atlas` | 30 | Atlas de sprites/GUI |
| `.gui` + `.gui_script` | 8 + 8 | GUIs |
| `.collection` | 3 | `bootstrap`, `intro`, `level_01` |
| `.tilesource` / `.tilemap` | 2 / 2 | Mapas de azulejos |
| `.font` / `.ttf` | 4 / 5 | Fuentes |
| Otros | ~40 | `.md`, `.txt`, `game.project`, `.input_binding`, `.material`, `.html`, `.sh`, licencias, jpg |

**314 archivos de texto contienen referencias por ruta** (`.go`, `.collection`, `.atlas`, `.gui`, `.script`, `.lua`, `.font`, `.sound`, `.tilesource`, `.tilemap`, `game.project`…).

Distribución de referencias por prefijo de ruta (archivos que contienen el prefijo):

| Prefijo | Archivos que lo referencian (principales) |
|---|---|
| `/features/…` | 123 en `features/`, 4 en `gui/`, 1 en `main/`, 1 `level_01.collection`, 1 en `intro/` |
| `/assets/…` | 101 en `features/`, 84 en `assets/`, 7 en `gui/`, 5 en `main/`, colecciones, `game.project` |
| `/gui/…` | 14 en `features/`, 8 en `gui/`, 2 en `main/`, 2 en `intro/`, colecciones |
| `/main/…` | 14 en `features/`, 4 en `main/`, `level_01.collection`, `bootstrap.collection` |
| `/intro/…` | 3 en `intro/`, 2 en `assets/`, `intro.collection` |

---

## 2. Estructura objetivo propuesta

Leyenda: ✅ **se queda** · ▶ **se mueve** · ✚ **nueva** · ⚠️ **requiere decisión (D#)**

```
RAÍZ
├── audit_globals.sh                 ✅ (raíz)
├── bootstrap.collection             ✅ (raíz; referenciado por game.project)
├── game.project                     ✅ (+ custom_resources → D5)
├── LICENSE / README.md / README_ES.md / .gitattributes / .gitignore   ✅
│
├── texts/                           ✚ ▶ assets/texts/ → texts/ (8 .lua)   [D5]
│
├── assets/
│   ├── sprites/                     ✚ (nace de assets/textures/ + arte de features/)
│   │   ├── props/
│   │   │   ├── furniture/           ▶ assets/textures/furniture/ + furniture.atlas
│   │   │   ├── breakables/          ▶ subconjunto de assets/textures/props/  [D3]
│   │   │   ├── decor/               ▶ subconjunto de assets/textures/props/  [D3]
│   │   │   └── particle.png, props.atlas, door.atlas, car_*.atlas…  [D1][D3]
│   │   └── characters/
│   │       ├── player/              ▶ arte de features/player/ (≈86 archivos)
│   │       ├── cat/                 ▶ arte de features/cat/
│   │       ├── npcs/npc_01…13/      ▶ arte de features/npc_XX/
│   │       ├── enemies/cockroach/ … ▶ arte de features/enemy_cockroach|rat/
│   │       └── intro/               ▶ assets/textures/intro/ (⚠️ [D4])
│   ├── ui/                          ✚ ▶ (atlas + iconos + burbujas)
│   │   ├── gui.atlas, balloons.atlas, quiz_images.atlas,
│   │   │   exhibition_clic.atlas, exhibition_images.atlas
│   │   ├── icons/                   ▶ gui/icons/ (80)
│   │   ├── dialogue/                ▶ burbujas de features/{speech_bubble_*,button_bubble}/
│   │   ├── hud/                     ▶ Degradado_Cuadrado…, speech_bubble_*_3px (⚠️ [D3])
│   │   ├── exhibition/              ▶ assets/textures/exhibition/ (72)
│   │   ├── exhibition_clic/         ▶ assets/textures/exhibition_clic/ (81)
│   │   └── quiz/                    ▶ assets/textures/quiz/ (19)
│   ├── sounds/                      ✅ se queda (143)
│   └── fonts/                       ✅ se queda (16)
│
├── entities/                        ✚ ▶ código de features/
│   ├── player/                      ▶ features/player/ (go, scripts, lua)
│   ├── cat/                         ▶ features/cat/ (código)
│   ├── npcs/                        ▶ features/npc/ + features/npc_01…13/
│   ├── enemies/                     ▶ features/enemies/ + enemy_cockroach/ + enemy_rat/ (código)
│   └── props/                       ▶ features/{props, furniture, exhibition_objects, collectibles}/
│                                     (subcarpetas mirror: furniture/, exhibition_objects/, collectibles/)
│
├── gui/                             ✅ .gui + .gui_script se quedan (arte sale a assets/ui/)
├── input/game.input_binding         ✅
├── main/                            ✅ completa (coincide con el árbol propuesto)
├── intro/                           ✅ gui/ y scripts; ▶ intro.collection entra aquí desde la raíz
├── docs/                            ✅ (+ este plan)  [D4: npc_list.txt]
├── world/                           ✚
│   ├── levels/                      ▶ level_01.collection (raíz) + level_map_1.tilemap
│   └── tilesets/                    ▶ assets/tiles/ (tilesource + texturas)
├── build/  ·  .internal/  ·  .editor_settings    🚫 no tocar (generados/ignorados)
```

> ⚠️ **Diferencia con la estructura propuesta:** el árbol propuesto lista `main/main.collection` como "colección principal del juego", pero **ese archivo no existe** — el rol lo cumplen `bootstrap.collection` (raíz, nunca se descarga) + `level_01.collection` (nivel por proxy). **No se creará `main.collection`** salvo petición explícita [D6].

---

## 3. Tabla A — Lo que SE QUEDA donde está (0 movimientos)

| Ruta | Por qué |
|---|---|
| `game.project`, `bootstrap.collection`, `LICENSE`, `README.md`, `README_ES.md`, `.gitattributes`, `.gitignore`, `audit_globals.sh` | Raíz del árbol propuesto; `bootstrap.collection` es la colección raíz |
| `main/` (35 archivos) | Coincide con `main/` propuesto |
| `gui/*.gui` + `gui/*.gui_script` (16) | Coinciden con `gui/` propuesto (diseño visual y código GUI) |
| `input/game.input_binding` | `input/` propuesto |
| `intro/` → `gui/`, `intro_animation.*`, `intro_manager.*`, `player_intro.go` | `intro/` propuesto (lógica + gui) |
| `assets/sounds/` (143) | `assets/sounds/` propuesto, idéntico |
| `assets/fonts/` (16) | `assets/fonts/` propuesto, idéntico |
| `docs/` (completa) | `docs/` propuesto |
| `build/`, `.internal/`, `.editor_settings` | Generados / gitignored |

---

## 4. Tabla B — Lo que SE MUEVE como unidad (carpeta o archivo entero)

En todos los casos, **cada ruta interna y externa que apunte a un archivo movido se reescribe** (ver §7 y §8). La regla es "reescribir por prefijo de carpeta movida" (nunca tocar `name:`, ids de instancia ni ids de componente).

| Origen | Destino | Archivos | Referencias afectadas |
|---|---|---|---|
| `assets/texts/` | `texts/` (raíz) | 8 `.lua` | `main/text_loader.lua` (10 rutas), `game.project` `custom_resources` [D5] |
| `gui/gui.atlas` | `assets/ui/gui.atlas` | 1 | 14 `.go` (npc_XX, collectibles), 7 `.gui`, 1 `.gui_script`, atlases propios |
| `gui/icons/` | `assets/ui/icons/` | 80 | imágenes de `gui.atlas` + `.pxo` (gitignored) |
| `gui/Degradado_Cuadrado_pxArt.png`, `gui/speech_bubble_*_3px.png` | `assets/ui/hud/` (⚠️ [D3]) | 3 | imágenes de `gui.atlas` |
| `features/speech_bubble_npc/`, `features/speech_bubble_player/`, `features/button_bubble/` | `assets/ui/dialogue/` | 10 | imágenes de `balloons.atlas` |
| `assets/textures/exhibition/` | `assets/ui/exhibition/` | 72 | imágenes de `exhibition_images.atlas` |
| `assets/textures/exhibition_clic/` | `assets/ui/exhibition_clic/` | 81 | imágenes de `exhibition_clic.atlas` |
| `assets/textures/quiz/` | `assets/ui/quiz/` | 19 | imágenes de `quiz_images.atlas` |
| `assets/textures/furniture/` | `assets/sprites/props/furniture/` | 55 | imágenes de `furniture.atlas`, `props.atlas`… |
| `assets/textures/intro/` | `assets/sprites/characters/intro/` (⚠️) | 2 | `intro_animation.go` (`intro.atlas`) [D4] |
| `assets/textures/exhibition_clic.atlas` | `assets/ui/exhibition_clic.atlas` | 1 | 67 `.go` (ME_*, furniture slots, collectibles), `hud.gui` |
| `assets/textures/exhibition_images.atlas` | `assets/ui/exhibition_images.atlas` | 1 | `exhibition.gui` |
| `assets/textures/quiz_images.atlas` | `assets/ui/quiz_images.atlas` | 1 | `interactive.gui` |
| `assets/textures/intro/intro.atlas` | `assets/sprites/characters/intro/intro.atlas` | 1 | `intro_animation.go` |
| `features/props/balloons.atlas` | `assets/ui/balloons.atlas` | 1 | `exhibition.gui`, `interactive.gui` |
| `intro.collection` (raíz) | `intro/intro.collection` | 1 | `main/proxy_intro.go` (`collection:`) |
| `level_01.collection` (raíz) | `world/levels/level_01.collection` | 1 | `main/proxy_level_01.go` (`collection:`) |
| `assets/tiles/level_map_1.tilemap` | `world/levels/level_map_1.tilemap` | 1 | `level_01.collection` (componente tilemap + 3 `collision_shape`) |
| `assets/tiles/tiles_map_1.tilesource`, `tileset_map_1.png`, `tileset_map_1_collisions.png` | `world/tilesets/` | 3 | `level_map_1.tilemap` (`tile_set:`), tilemap del nivel |

---

## 5. Tabla C — Lo que SE DIVIDE (código y arte se separan)

Cada carpeta de `features/` contiene mezclado código (`.go/.script/.lua`) y arte (`.png/.pxo/.atlas`). Con la opción por defecto **D1 = "el atlas viaja con su arte"**, la división es:

| Origen `features/…` | Código → `entities/…` | Arte (incl. atlas) → `assets/sprites/…` |
|---|---|---|
| `player/` (92) | `entities/player/` — player.go, player.script, player_spray.script, mobile_interact.script, aiming.lua, auto_aim.lua | `characters/player/` — player.atlas + 14 carpetas de frames + player_dance*.pxo (≈86) |
| `cat/` (47) | `entities/cat/` — cat.go, cat.script, cat_nav.lua | `characters/cat/` — cat.atlas + 43 png/pxo |
| `npc_01…13/` (21–24 c/u) | `entities/npcs/npc_XX/` — solo el `.go` (13) | `characters/npcs/npc_XX/` — npc_XX.atlas + pngs + .pxo |
| `npc/` (3) | `entities/npcs/` — npc_patrol.lua, npc_spawn_manager.go/.script | — |
| `enemy_cockroach/` (16) | `entities/enemies/enemy_cockroach/` | `characters/enemies/enemy_cockroach/` |
| `enemy_rat/` (22) | `entities/enemies/enemy_rat/` | `characters/enemies/enemy_rat/` (⚠️ excluir `Sin título.jpg`) |
| `enemies/` (2) | `entities/enemies/` — nest.go, nest.script | — |
| `props/` (38) | `entities/props/` — 28 archivos de código | `assets/sprites/props/` — props.atlas, door.atlas, car_01..03.atlas (las imágenes que referencian vienen de §4) |
| `furniture/` (8) | `entities/props/furniture/` — 6 .go/.script + slot_furniture.script | `assets/sprites/props/furniture/` — furniture.atlas |
| `exhibition_objects/` (65) | `entities/props/exhibition_objects/` — exhibition_object.script + 64 ME_*.go | — (su sprite usa `exhibition_clic.atlas`, ya en `assets/ui/`) |
| `collectibles/` (3) | `entities/props/collectibles/` | — |
| `npc_list.txt` | → `docs/` (notas de producción) [D4] | — |

---

## 6. Encajes dudosos y propuestas

Archivos que **no encajan** o cuyo encaje es dudoso en la estructura propuesta:

| Archivo | Problema | Propuesta |
|---|---|---|
| `assets/custom_template.html` | Plantilla HTML5; no es arte/audio/fuente. Referenciada por `game.project → [html5] htmlfile` | **Dejar en `assets/`** (menor riesgo; solo hay que actualizar la ruta en `game.project` si se mueve) |
| `main/main.collection` (propuesto) | No existe; rol cubierto por `bootstrap.collection` | No crear [D6] |
| `features/exhibition_objects/` y `features/collectibles/` | La estructura `entities/` no las contempla | Subcarpetas `entities/props/exhibition_objects/` y `entities/props/collectibles/` [D2] |
| `assets/tiles/tileset_map.atlas` | **Huérfano**: nadie lo referencia; está vacío (solo `extrude_borders`) | Cuarentena `_archive/` o borrar [D4] |
| `assets/tiles/hT2RVe.png` | **Huérfano**: ninguna referencia | Cuarentena o borrar [D4] |
| `assets/tiles/intro.tilemap` + `intro.tilesource` | **Huérfanos**: `intro.tilemap` no lo usa nadie; `intro.tilesource` referencia `/assets/textures/intro/intro.png`, **archivo inexistente** (el real es `intro_sprite.png`) → recurso roto desde hace tiempo | Cuarentena o borrar [D4] |
| `features/enemy_rat/Sin título.jpg` | JPG basura sin referencia | Borrar / archivar [D4] |
| `features/props/textures_pixelart_atlas.png`, `Speech_Balloons.png` | **Huérfanos**: sin referencias | Cuarentena o borrar [D4] |
| `assets/textures/props/` (121) | Mezcla iconos HUD, objetos fungibles, mobiliario, decorado y elementos dinámicos (puertas, coches) | Separar por criterio → `furniture/`, `breakables/`, `decor/` + iconos → `assets/ui/icons/` [D3 + Anexo A] |
| `assets/textures/props/icon_*` (stamina, temperature, poison_nest…) | Son iconos, no sprites de props | → `assets/ui/icons/` [D3] |
| `.pxo` (94) | Fuentes de edición Aseprite, **gitignored** (no se versionan) | Mover junto a su `.png` hermano por higiene; no afectan al build [D4] |
| `assets/fonts/font-df-tile.material` | Material custom dentro de fonts (usado por labels) | Se queda con `assets/fonts/` (sin movimiento) |
| `features/npc_list.txt` | Lista de producción | → `docs/` [D4] |
| `texts/` vs `assets/texts/` | La estructura propone `texts/` en raíz; hoy está bajo `assets/` y es **custom resource** | Mover a raíz + `custom_resources = /assets, /texts` [D5] |
| Imágenes de exhibición/quiz | Son fotografías de museo (contenido), no "arte de interfaz" | Subcarpetas propias dentro de `assets/ui/` (cerca de sus atlas) [D3] |

---

## 7. Referencias a revisar y reescribir (mapa completo)

Defold resuelve **todo** por ruta absoluta de proyecto (`/carpeta/archivo.ext`). Tras cualquier movimiento hay que reescribir las rutas en **todos** estos formatos. Ejemplos reales encontrados:

### 7.1 Referencias estáticas en recursos de texto (se reescriben con el mapeo de §4–§5)

| Tipo de archivo | Campo / contexto | Ejemplo real | Afectado por mover… |
|---|---|---|---|
| `.go` | `component:` | `/features/player/player.script` | `features/*` → `entities/*` |
| `.go` | `prototype:` (factories) | `/features/enemy_rat/enemy_rat.go` (en nest.go) | idem |
| `.go` | sprite `textures { texture: }` | `/features/npc_01/npc_01.atlas`, `/gui/gui.atlas`, `/assets/textures/exhibition_clic.atlas` | atlas movidos |
| `.go` | sonido embebido `data: "sound: …"` | `/assets/sounds/clic.ogg` | (sounds no se mueven) |
| `.go` | label `font:` / `material:` | `/assets/fonts/title.font`, `/assets/fonts/font-df-tile.material` | (no se mueven) |
| `.go` | tilemap/collision `data:` | `collision_shape: "/assets/tiles/level_map_1.tilemap"` | tiles → `world/` |
| `.collection` | `prototype:` | `/features/player/player.go`, `/main/game_manager.go` | features/main (main no se mueve) |
| `.collection` | datos embebidos **con escape** | `component: \"/gui/library.gui\"`, `data: \"collection: \\\"/intro.collection\\\"\\n\"` | gui/colecciones |
| `.atlas` | `images { image: }` | `/assets/textures/props/car_b_run_01.png`, `/gui/icons/icon_heart.png` | todas las imágenes de arte |
| `.tilesource` | `image:` | `/assets/tiles/tileset_map_1.png` | tiles → `world/tilesets/` |
| `.tilemap` | `tile_set:` | `/assets/tiles/tiles_map_1.tilesource`, `/assets/tiles/intro.tilesource` | idem |
| `.gui` | `texture:` (ruta absoluta) | `/gui/gui.atlas`, `/assets/textures/quiz_images.atlas`, `/features/player/player.atlas` (en victory.gui), `/features/props/balloons.atlas` | atlas movidos |
| `.gui` | `font:` | `/assets/fonts/dialogs.font` | (no se mueven) |
| `.font` / `.sound` | `font:` / `sound:` | `/assets/fonts/MatrixSans-Regular.ttf`, `/assets/sounds/mouse-click.ogg` | (no se mueven) |
| `game.project` | `main_collection`, `htmlfile`, `custom_resources` | `/bootstrap.collectionc`, `/assets/custom_template.html`, `/assets` | `custom_resources` [+ `/texts`] |

> 🔎 **Nota importante:** las referencias de `.gui` por **id de imagen/animation** (p. ej. `texture: "gui/icon_heart"`, `"balloons/speech_bubble_a"`) **no cambian**: dependen del contenido del atlas, que no se modifica.

### 7.2 Referencias dinámicas en Lua (se reescriben a mano)

| Archivo | Línea | Referencia | Cambio |
|---|---|---|---|
| `main/text_loader.lua` | 50–67 | 10 rutas `/assets/texts/*_<lang>.lua` | → `/texts/*_<lang>.lua` |
| `main/npc.script` | 25 | `require "features.npc.npc_patrol"` | → `require "entities.npcs.npc_patrol"` |
| `features/cat/cat.script` | 29–30 | `require "features.npc.npc_patrol"`, `require "features.cat.cat_nav"` | → `entities.npcs.…`, `entities.cat.…` |
| `features/player/player.script` | 25 | `require "features.player.aiming"` | → `entities.player.aiming` |
| `features/player/mobile_interact.script` | 46 | `require "features.player.aiming"` | → `entities.player.aiming` |
| `features/player/player_spray.script` | 30–31 | `require("features.player.aiming")`, `require("features.player.auto_aim")` | → `entities.player.…` |
| `main/npc.script` | 74 | `msg.url("/features/player/player")` (fallback muerto; el go real se llama `player` en `level_01.collection`) | Actualizar a `/entities/player/player` o eliminar el fallback |

> Los `require "main.*"` (~40 usos) **no cambian** (`main/` no se mueve). Los comentarios que citan rutas `features.*` pueden actualizarse por higiene, no son funcionales.

### 7.3 Direccionamiento en runtime que NO cambia

- `name:` interno de las colecciones (`intro`, `level_01`, `bootstrap`) → no tocar.
- Ids de instancia (`player`, `game_manager`, `ME_16061`…) y de componente (`proxy`, `hud`, `interactive`…).
- Mensajes por id de colección: `"bootstrap:/audio_manager#manager"`, `"level_01:/cursor#cursor"`, `"/gui#hud"`, `"/gui_intro#intro_gui"`, `"/intro_manager#intro_manager"`, etc.
- Fábricas por componente (`#bug_factory`, `#rat_factory`, `#factory`).
- Animaciones y nodos de GUI (referencias por nombre dentro del atlas).

---

## 8. Cambios de configuración

1. **`game.project`** → `[project] custom_resources = /assets, /texts` (lista separada por comas; verificada en la documentación oficial de Defold). Sin esto, `sys.load_resource("/texts/*.lua")` falla en runtime porque los textos dejan de estar empaquetados como custom resource.
2. **`main/text_loader.lua`** → registro `TEXT_FILES` con `/texts/…`.
3. **`main/proxy_intro.go`** y **`main/proxy_level_01.go`** → `collection: "/intro/intro.collection"` y `"/world/levels/level_01.collection"`.
4. **`level_01.collection`** → referencias a `level_map_1.tilemap` y a todos los prototipos `features/*` movidos.
5. **Requires** listados en §7.2.

---

## 9. Riesgos y medidas

| Riesgo | Medida |
|---|---|
| No hay git → un error no se puede revertir con diff | Backup **grsync ya realizado por el usuario**. Antes de ejecutar: tar/verificar el backup y (recomendado) `git init` + commit de línea base |
| Mover un archivo y olvidar una referencia → error de build o recurso roto silencioso | Estrategia de "prefijos de carpeta" (§4–§5) + auditoría programática post-movimiento (§10, Fase 6): **ninguna ruta entre comillas debe apuntar a un archivo inexistente** |
| Colisiones de prefijo al reescribir (p. ej. `/features/npc/` vs `/features/npc_01/`) | Sustituir siempre el prefijo de carpeta **más largo primero**; mapeos disjuntos |
| Direccionamiento por id de colección si Defold derivara el id del path (no es el caso: deriva del `name:` interno) | Mantener `name:` intacto; verificación en runtime (Fase 5) |
| Textos fuera de `custom_resources` | Añadir `/texts` (§8) |
| `.pxo` gitignored no se versionarían | Mover por higiene junto al png; no afecta al build |
| El editor de Defold conserva caché (`.internal`, `build/`) | Rebuild limpio tras la reorganización (o borrar `build/default`), validar con el editor |
| Cambios de última hora sobre la clasificación `breakables`/`decor` | D3 + Anexo A, revisión con el equipo antes de la fase 3 |

---

## 10. Plan de ejecución por fases (runbook)

> Orden elegido para que **cada fase deje el proyecto compilable**: primero recursos autocontenidos, después las carpetas que arrastran más referencias. Entre fase y fase: `luac -p` + greps de control + apertura en el editor de Defold (compila y lista rutas rotas).

### Fase 0 — Línea base y salvaguardas
- Verificar backup grsync; opcional `git init` + commit.
- Registrar salida de: `find` completo de archivos, y lista de referencias (`grep -rn '"/' --include=…` sobre los 314 archivos).
- `luac -p` (si disponible) sobre todos los `.lua/.script/.gui_script`.

### Fase 1 — Textos (independiente)
- `assets/texts/` → `texts/` (8 archivos).
- `game.project`: `custom_resources = /assets, /texts`.
- `text_loader.lua`: 10 rutas.
- ✔️ Verificar: apertura en editor sin errores; al cambiar idioma en la intro los textos cargan (log de `text_loader`).

### Fase 2 — Atlas y texturas de UI (autocontenidas)
- Mover atlases e imágenes según §4 (fila "ui"): `gui.atlas`, `balloons.atlas`, `quiz_images.atlas`, `exhibition_clic.atlas`, `exhibition_images.atlas`, carpetas `exhibition/`, `exhibition_clic/`, `quiz/`, `gui/icons/`, burbujas, Degradado + speech 3px.
- Reescribir `image:` dentro de los atlas y `texture:` absolutas en `.gui` y `.go` que los usan (14 .go, 8 .gui).
- ✔️ Verificar: las 5 atlases se abren en el editor con todas sus imágenes presentes (0 imágenes rotas).

### Fase 3 — Sprites de entidades + split code/arte
- Aplicar Tabla C (entities vs assets/sprites) según D1.
- Mover `assets/textures/{furniture,props,intro}` y clasificar `props/` (D3, Anexo A).
- Mover huérfanos a cuarentena (D4).
- Reescribir prefijos `/features/*` → `/entities/*` o `/assets/sprites/*` en los archivos movidos y en los que los referencian (≈130 archivos).
- Requieres (§7.2).
- ✔️ Verificar: grep de que no queda **ninguna** referencia a `/features/`; todas las imágenes de atlas existen.

### Fase 4 — Colecciones y niveles
- `intro.collection` → `intro/`; `level_01.collection` → `world/levels/`.
- Tiles: tilemap del nivel → `world/levels/`; tilesources/texturas → `world/tilesets/` (cuarentena de huérfanos).
- `main/proxy_intro.go`, `main/proxy_level_01.go`.
- ✔️ Verificar: build completo del proyecto en el editor sin errores de recurso.

### Fase 5 — Validación en runtime
- Ejecutar juego: intro → start → nivel 1. Comprobar: textos en ES/EN, GUIs (hud/interactive/exhibition/library/pause/victory), sprites de player/cat/npc/enemigos/props/puertas/coches, quiz con imágenes, panel de exhibición, sonidos.
- Cambio de idioma en caliente (recarga de textos).
- Guardar/cargar partida (persistencia no toca rutas, pero verificar).

### Fase 6 — Auditoría final programática
- Script de control: recorrer los 314 archivos de texto, extraer todas las rutas `"/…"` referenciadas (incluidas las variantes escapadas de `.collection`) y comprobar que el archivo existe. **0 rutas rotas**.
- `luac -p` + `audit_globals.sh` (0 violaciones).
- Actualizar `docs/PROJECT_SUMMARY.md` (sección 🗂️ Project Structure) y READMEs si citan rutas.
- Decidir qué hacer con `build/` (regenerar) y con la cuarentena `_archive/`.

---

## 11. Decisiones abiertas (D1–D7)

| # | Decisión | Recomendación por defecto |
|---|---|---|
| D1 | ¿El `.atlas` de cada entidad viaja con el **arte** (`assets/sprites/…`, fiel al árbol propuesto) o con el **código** (`entities/…`)? | **Con el arte** (los atlas listados en la propuesta viven en `assets/ui/`). Alternativa de menor movimiento: atlas junto al `.go` (menos reescrituras) |
| D2 | Subcarpetas dentro de `entities/props/` | Mantener mirror de las actuales: `furniture/`, `exhibition_objects/`, `collectibles/` + resto plano |
| D3 | Clasificación de `assets/textures/props/` (121) en `furniture/`, `breakables/`, `decor/` e `icons/` | Criterios del Anexo A; lista de dudosos explícita para revisión |
| D4 | Huérfanos y basura (`tileset_map.atlas`, `hT2RVe.png`, `intro.tilemap/.tilesource` rotos, `Sin título.jpg`, `textures_pixelart_atlas.png`, `Speech_Balloons.png`, `npc_list.txt`) | Cuarentena en `_archive/` (no borrar en la 1ª pasada) o mover a `docs/` |
| D5 | `texts/` en raíz (exige `custom_resources` + reescritura de `text_loader`) | **Mover a raíz** (la estructura lo pide explícitamente) |
| D6 | `main.collection` propuesto inexistente | No crearlo; documentar que `bootstrap.collection` lo sustituye |
| D7 | Ubicación del arte de la intro (`assets/textures/intro/`) | `assets/sprites/characters/intro/` (o `assets/ui/` si se trata como pantalla de menú) |

---

## Anexo A — Criterio de clasificación de `assets/textures/props/`

Grupos de la estructura propuesta + criterio de aplicación (se listan los grupos de archivos; la ejecución aplica reglas por nombre con revisión individual de los dudosos):

- **`furniture/`** — mobiliario y contenedores estáticos: `bookcase*`, `office_cabinet*`, `office_chair*`, `office_pc*`, `office_printer*`, `office_docs_cabinet*`, `table_brown*`, `armchair*`, `showcase_*`, `storage_*`, `tree_ficus*` (planta decorativa de sala)…
- **`breakables/`** — fungibles/consumibles recogibles: `spray_can*`, `cat_food_can*`, `food_cat_can*`, `health_kit*`, `pickup_poison_nest*`…
- **`decor/`** — escenografía estática: `bin_trash_street*`, `streetlamp*`, `tree_little*`, `vending_machine*`…
- **`interactive/`** *(propuesta, si no encaja en decor)* — elementos dinámicos con lógica propia: `door_*`, `car_*` (sus atlas viven en `assets/sprites/props/`)…
- **`assets/ui/icons/`** — iconos HUD: `icon_stamina*`, `icon_temperature*`, `icon_poison_nest*` (verificar uso real en cada `.go`/`.gui` antes de mover)…
- **Dudosos a revisar individualmente:** `nest_enemies_*`, `book_open_*`, `book_pages_flip_*`, `book_appearance_*`, `fire_extinguisher`, `poison_nest.pxo`, `icon_poison_nest.pxo`, `door_service_128px.pxo`, `office_pc_32.pxo`…

> ⚠️ La regla anterior no sustituye la comprobación de **quién referencia cada imagen** (`.atlas` → `.go`/`.gui`): si una imagen solo la usa un sprite de un GO que vive en `entities/props/`, puede plantearse dejarla en `assets/sprites/props/` aunque no sea "fungible".

---

## Anexo B — Auditorías de verificación (comandos)

```bash
# 1. Rutas absolutas que apuntan a archivos que ya no existen (tras cada fase)
#    (versión textual; la auditoría completa parsea también las variantes escapadas)
grep -rhoE '"/[a-zA-Z0-9_./-]+\.(go|script|lua|atlas|png|gui|font|sound|ogg|tilesource|tilemap|ttf|material|collection)"' \
  --include='*.go' --include='*.collection' --include='*.atlas' --include='*.gui' \
  --include='*.script' --include='*.lua' --include='*.gui_script' --include='*.font' \
  --include='*.sound' --include='*.tilesource' --include='*.tilemap' \
  . | grep -vE '\./build|\./\.internal' | sort -u | while read -r p; do
    f="${p#\"}"; f="${f%\"}"; [ -e ".$f" ] || echo "ROTA: $f"; done

# 2. No deben quedar referencias al árbol viejo
grep -rn '/features/' --include='*.go' --include='*.collection' --include='*.atlas' \
  --include='*.gui' --include='*.script' --include='*.lua' --include='*.gui_script' . \
  | grep -vE '\./build|\./\.internal|\./docs' || echo "OK: sin refs a /features/"

# 3. Sintaxis Lua
luac -p $(find . -name '*.lua' -o -name '*.script' -o -name '*.gui_script' \
  | grep -vE '\./build|\./\.internal')

# 4. Globals (convención del proyecto)
./audit_globals.sh
```
