# 🎥 Culling por cámara para NPCs — Informe de implementación

> **Objetivo:** Desactivar la lógica de patrulla de los NPCs que están fuera de pantalla para reducir raycasts y CPU en HTML5.  
> **Fecha:** Agosto 2026  
> **Contexto:** 14 NPCs activos, solo 2-3 visibles simultáneamente → ~11 NPCs ejecutan lógica innecesaria.

---

## 📐 Geometría de la cámara

### Parámetros conocidos

| Parámetro | Valor | Fuente |
|-----------|-------|--------|
| Resolución lógica | 1280 × 768 | `game.project [display]` |
| `orthographic_zoom` | 2.0 | `level_01.collection` / `screen_utils.lua` |
| Cámara | Ortográfica, FIXED | `level_01.collection` |
| Seguimiento | Lerp 0.07 (suave) | `camera.script` |

### Área visible en unidades de mundo

Con cámara ortográfica y zoom = 2.0:

```
Ancho visible = 1280 / 2.0 = 640 unidades
Alto visible  = 768 / 2.0  = 384 unidades
```

El centro de la cámara está en la posición del jugador (con lerp). El **área visible** desde el centro es:

```
                  ← 320 uds →
            ┌─────────────────────┐
            │                     │  ↑
            │     ÁREA VISIBLE    │  192 uds
            │     (centro: cam)   │  ↓
            └─────────────────────┘
                  ← 320 uds →
```

**⚠️ Este diagrama es para 1280×768.** Con resize, el área visible cambia. La zona de culling se calcula dinámicamente (ver abajo).

### Zona de culling (dinámica, relativa al viewport)

Los márgenes de culling se calculan **en runtime** a partir del tamaño de ventana actual y el zoom de la cámara. Esto garantiza que el culling se adapte a cualquier resolución (fullscreen, ventana, móvil).

```
visible_w = window_width / ortho_zoom
visible_h = window_height / ortho_zoom
margin_x  = visible_w × 0.65   -- 130% del ancho visible / 2
margin_y  = visible_h × 0.65   -- 130% del alto visible / 2
```

**Ejemplo con ventana 1280×768, zoom 2.0:**
```
visible_w = 1280 / 2.0 = 640 uds
margin_x  = 640 × 0.65 = 416 uds
→ Zona de culling: 832 × 520 unidades
```

**Ejemplo con ventana 1920×1080, zoom 2.0:**
```
visible_w = 1920 / 2.0 = 960 uds
margin_x  = 960 × 0.65 = 624 uds
→ Zona de culling: 1248 × 780 unidades (se adapta al resize)
```

**Resultado:** Un NPC solo ejecuta lógica de patrulla si está dentro de un rectángulo **relativo al viewport actual** centrado en la cámara.

---

## 📊 Impacto estimado

### Distribución de NPCs en el nivel

Con 14 NPCs distribuidos en un museo con ~4-5 salas:

| Escenario | NPCs visibles | NPCs off-screen | Ahorro |
|-----------|---------------|-----------------|--------|
| Sala pequeña | 2-3 | 11-12 | ~80% |
| Pasillo | 1-2 | 12-13 | ~90% |
| Sala grande | 3-4 | 10-11 | ~75% |
| **Promedio** | **~2.5** | **~11.5** | **~82%** |

### Raycasts ahorrados

| | Antes | Después (culling) |
|---|---|---|
| NPCs raycasteando | 10 (patrol-enabled) | ~2 (en pantalla) |
| Raycasts por frame (pico) | 168 | ~24 |
| Raycasts por frame (promedio) | ~40 | ~8 |

**Reducción: ~80% de raycasts.**

---

## 🔧 Diseño de implementación

### Opción A: Culling en `npc.script → update()` (recomendada)

Añadir un check de visibilidad al inicio de `update()` que retorne temprano si el NPC está fuera de pantalla. Los márgenes se calculan **a partir del tamaño de ventana actual** para adaptarse a resize, fullscreen y móviles.

```lua
-- npc.script

local ORTHO_ZOOM = 2.0  -- Debe coincidir con screen_utils.lua ORTHO_ZOOM

-- Factor de margen: 1.30 = 30% extra más allá del borde visible
-- (configurable en config.balance → npc_cull_margin_factor)
local CULL_MARGIN_FACTOR = (config.balance and config.balance.npc_cull_margin_factor) or 1.30

local function is_on_screen(npc_pos)
    -- 📏 Calcular área visible ACTUAL desde el tamaño de ventana
    local ww, wh = window.get_size()
    local visible_w = ww / ORTHO_ZOOM
    local visible_h = wh / ORTHO_ZOOM
    
    -- Margen = mitad del área visible × factor (130% = 30% extra)
    local margin_x = (visible_w * CULL_MARGIN_FACTOR) / 2
    local margin_y = (visible_h * CULL_MARGIN_FACTOR) / 2
    
    -- Posición de la cámara (resuelta en runtime, no cacheada a nivel de módulo)
    local cam_pos = go.exists("/camera") and go.get_position("/camera") or vmath.vector3(0, 0, 0)
    
    local dx = math.abs(npc_pos.x - cam_pos.x)
    local dy = math.abs(npc_pos.y - cam_pos.y)
    return dx < margin_x and dy < margin_y
end

function update(self, dt)
    -- Icon polling (siempre, es barato y necesario para game logic)
    self.icon_poll_timer = self.icon_poll_timer + dt
    if self.icon_poll_timer >= ICON_POLL_INTERVAL then
        self.icon_poll_timer = 0
        update_icon_state(self)
    end

    -- 🎥 Culling: si el NPC está fuera de pantalla, no ejecutar patrulla
    if self.patrol_enabled and not self.is_talking then
        local my_pos = go.get_position()
        if not is_on_screen(my_pos) then
            return  -- NPC off-screen: skip patrol + raycasts + animation
        end

        local player_pos = get_player_position()
        if player_pos then
            patrol.update(self, dt, player_pos, my_pos)
        end
        sync_walk_animation(self)
    end
end
```

**Nota sobre `window.get_size()`:** Devuelve el tamaño actual de la ventana en px físicos. En HTML5 con `high_dpi`, este valor incluye el DPR. Pero como `ORTHO_ZOOM` y la cámara operan en el mismo espacio, la división `ww / ORTHO_ZOOM` siempre da el área visible correcta en unidades de mundo.

**Coste de `window.get_size()`:** Es una llamada al motor muy barata (microsegundos). Se ejecuta 14 veces por frame (una por NPC), lo cual es despreciable comparado con los raycasts que ahorra.

**Ventajas:**
- Implementación trivial (~15 líneas)
- El NPC **se congela** cuando sale de pantalla (patrol_state preservado)
- Al volver a pantalla, retoma exactamente donde se quedó
- No afecta la lógica de game_state ni iconos

**Desventajas:**
- El NPC se "congela" visualmente (pero está fuera de pantalla, así que invisible)
- Al volver, puede estar en medio de un tramo → el movimiento se reanuda suavemente

### Opción B: Culling solo en `patrol.update()` (más granular)

Permitir que `update()` siga ejecutándose (icon polling, etc.) pero desactivar solo la lógica de patrulla dentro de `npc_patrol.lua`.

```lua
-- npc_patrol.lua

function M.update(self, dt, player_pos, my_pos)
    if self.patrol_state == "DISABLED" then return end
    
    -- 🎥 Skip raycasts si el NPC está fuera de pantalla
    -- (el caller ya verificó visibilidad, este es un fallback)
    if self._off_screen then return end
    
    -- ... resto de lógica existente ...
end
```

**Ventajas:**
- Más granular: solo se desactivan raycasts, no el icon polling
- El NPC sigue respondiendo a `contact_point_response` (colisiones con paredes)

**Desventajas:**
- Más complejo: requiere coordinar el flag `_off_screen` entre npc.script y npc_patrol.lua
- El NPC sigue ejecutando `sync_walk_animation()` (desperdicio menor)

### Opción C: Culling con `go.disable()` (máximo ahorro)

Desactivar completamente el GO del NPC cuando está off-screen.

```lua
-- npc.script
if not is_on_screen(my_pos) then
    go.set_enabled(false)  -- Desactiva TODOS los componentes
    return
end
```

**Ventajas:**
- Máximo ahorro: zero CPU para el NPC off-screen
- Defold no ejecuta `update()`, `on_message()`, ni física

**Desventajas:**
- **No se puede reactivar con `go.set_enabled(true)` desde el mismo script** (el GO está desactivado, no recibe mensajes)
- Requiere un gestor externo (como `npc_spawn_manager`) que reactive los GOs basándose en la cámara
- Complejidad significativa
- Riesgo de bugs: si el GO se desactiva durante una conversación, el dialogue_manager pierde la referencia

---

## 🎯 Recomendación: Opción A

La **Opción A** (culling en `npc.script → update()`) es la mejor balance entre efectividad y complejidad:

| Criterio | Opción A | Opción B | Opción C |
|----------|----------|----------|----------|
| Complejidad | ⭐ Baja | ⭐⭐ Media | ⭐⭐⭐ Alta |
| Ahorro CPU | ~80% | ~75% | ~95% |
| Riesgo de bugs | Bajo | Bajo | Alto |
| Impacto visual | Ninguno (off-screen) | Ninguno | Ninguno |
| Mantenimiento | Fácil | Medio | Difícil |

---

## 📋 Parámetros configurables (config.balance)

```lua
-- Añadir a config.balance:
npc_cull_margin_factor = 1.30,  -- Factor de margen (1.0 = sin margen, 1.5 = 50% extra)
```

| Valor | Comportamiento |
|-------|---------------|
| `1.0` | Culling exacto al borde visible (mínimo margen) |
| `1.30` | **Default:** 30% extra (recomendado para transiciones suaves) |
| `1.50` | 50% extra (más conservador, NPCs se actualizan antes de entrar en pantalla) |

El factor se aplica como multiplicador del área visible: `margin = (window/zoom × factor) / 2`. Un valor de 1.30 significa que el NPC empieza a ejecutar lógica cuando está a un 30% más allá del borde de la ventana.

---

## ⚠️ Consideraciones

### 1. El NPC se congela off-screen

Cuando un NPC sale de la zona de culling:
- Su `patrol_state` se preserva (IDLE o PATROL)
- Su posición se preserva
- Si estaba en PATROL, se detiene (no avanza)
- Al volver a pantalla, reanuda desde donde se quedó

**¿Es esto problemático?** No. El NPC estaba fuera de pantalla, así que el jugador no lo ve. Al volver, el NPC aparece en una posición coherente (no se teletransporta).

### 2. `contact_point_response` sigue activo

Incluso con el culling, Defold sigue enviando `contact_point_response` al GO (la física no se desactiva). Si el NPC está pegado a una pared off-screen, sigue recibiendo el push. Esto es correcto: evita que el NPC se meta en paredes mientras está "congelado".

### 3. Icon polling no se desactiva

El `update_icon_state()` sigue ejecutándose (2 Hz). Esto es intencionado: si el jugador completó un quiz mientras el NPC estaba off-screen, el icono debe actualizarse para que cuando vuelva a verlo esté correcto.

### 4. Animación de caminata

`sync_walk_animation()` se desactiva con el culling. El sprite del NPC se queda en el último frame de animación. Al volver a pantalla, se re-anima. Como el NPC estaba fuera de pantalla, esto es invisible.

### 5. Resize / fullscreen / móvil

Los márgenes de culling se recalculan **cada frame** a partir de `window.get_size()`. Esto garantiza que:

| Escenario | Comportamiento |
|-----------|---------------|
| Resize manual de ventana | Los márgenes se adaptan al nuevo tamaño |
| Toggle fullscreen | Los márgenes se adaptan |
| HTML5 con high_dpi | `window.get_size()` devuelve px físicos; la división por `ORTHO_ZOOM` da unidades de mundo correctas |
| Móvil (landscape/portrait) | Los márgenes se adaptan al orientación actual |

No hay que hacer nada especial para cada caso: la fórmula `ww / ORTHO_ZOOM` funciona universalmente.

---

## 🔗 Referencias

- `main/camera.script` — Cámara de seguimiento (lerp 0.07)
- `main/screen_utils.lua` — Conversión mundo→pantalla (ORTHO_ZOOM = 2.0)
- `features/npc/npc_patrol.lua` — Lógica de patrulla y raycasts
- `main/npc.script` — Update del NPC (punto de implementación)
- `main/config.lua` — Parámetros configurables
- `docs/PERFORMANCE_NPC_RAYCAST.md` — Mitigaciones de raycasts
- `docs/PERFORMANCE_NOTES.md` — Métricas de rendimiento
