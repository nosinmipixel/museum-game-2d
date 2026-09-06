# 🚶 Mitigaciones de rendimiento: Raycasts de patrulla NPCs (HTML5)

> **Archivo afectado:** `features/npc/npc_patrol.lua`  
> **Fecha:** Agosto 2026  
> **Contexto:** 14 NPCs patrolando, ~168 raycasts potenciales por frame en peor caso, rendimiento degradado en HTML5 con iGPU integrada.

---

## 📊 Análisis del problema

### Flujo de raycasts actual

Cuando un NPC termina un tramo de patrulla, ejecuta `pick_direction_with_clearance()`:

```
pick_direction_with_clearance()
  └─ probe_free_distance() × 4 direcciones cardinales
       └─ 3 raycasts por dirección (centro + 2 laterales)
            └─ physics.raycast(from, to, {hash("walls")}, {all = true})
```

**Coste máximo por NPC:** 4 × 3 = **12 raycasts síncronos**

**Peor caso (todos terminan tramo en el mismo frame):** 14 NPCs × 12 = **~168 raycasts**

### Diferencia native vs HTML5

| Componente | Native | HTML5 |
|-----------|--------|-------|
| `physics.raycast()` | Bullet → driver OpenGL (microsegundos) | WASM → JS → WebGL2 → driver Intel iGPU |
| Threading | Posible paralelismo | Single-threaded (todo en 1 hilo) |
| Overhead por raycast | ~0.001 ms | ~0.05-0.1 ms (estimado) |
| 168 raycasts | ~0.17 ms | ~8-17 ms |

**Conclusión:** 168 raycasts síncronos en HTML5 pueden costar **8-17 ms**, suficiente para tirar un frame de 16.67 ms.

---

## 🔧 Mitigaciones investigadas

### 1. Escalonar raycasts entre frames (round-robin)

**Idea:** Asignar a cada NPC un "fase" (0-N) y solo ejecutar `pick_direction_with_clearance()` para los NPCs de la fase actual. Con 14 NPCs en 4 fases, solo 3-4 NPCs raycastean por frame.

**Implementación conceptual:**
```lua
-- En npc_patrol.lua
local NUM_PHASES = 4

function M.update(self, dt, player_pos, my_pos)
    -- ... (lógica existente) ...
    
    -- En IDLE, esperar a que sea el turno de esta fase
    if self.patrol_state == "IDLE" and self.patrol_idle_timer <= 0 then
        local phase = (self.npc_phase or 0)
        if (frame_count % NUM_PHASES) == phase then
            pick_direction_with_clearance(self, exclude)
        end
        -- Si no es su fase, no hacer nada (se reintentará en el siguiente frame)
    end
end
```

**Ventajas:**
- Reduce raycasts de 14×12 a 3-4×12 = **36-48 por frame**
- Impacto visual mínimo: los NPCs esperan ~66 ms extra (1 frame a 60 FPS) antes de elegir dirección
- No afecta la calidad de navegación

**Desventajas:**
- Los IDs de fase deben asignarse al init (o al spawn) para distribuir equitativamente
- Requiere un contador global de frames (o usar `socket.gettime()` con módulo)

**Impacto estimado:** Reducción de **60-70%** del coste de raycasts por frame.

---

### 2. Reducir raycasts por dirección (3 → 1)

**Idea:** En vez de 3 rayos paralelos por dirección (centro + 2 laterales), usar solo el rayo central.

**Implementación conceptual:**
```lua
local function probe_free_distance(pos, dir_x, dir_y, half_x, half_y)
    local from = vmath.vector3(pos.x, pos.y, pos.z)
    local to = vmath.vector3(from.x + dir_x * NAV_PROBE, from.y + dir_y * NAV_PROBE, from.z)
    local result = physics.raycast(from, to, RAYCAST_GROUPS, { all = true }) or {}
    local free = NAV_PROBE
    for _, hit in ipairs(result) do
        if hit.group == HASH_WALLS then
            local dx = hit.position.x - from.x
            local dy = hit.position.y - from.y
            local d = math.sqrt(dx * dx + dy * dy)
            if d > PROBE_EPS and d < free then
                free = d
            end
        end
    end
    return free
end
```

**Ventajas:**
- Reduce raycasts de 12 a **4 por NPC** (75% menos)
- Implementación trivial

**Desventajas:**
- Pierde la detección de pasillos estrechos: un pasillo por el que cabe el rayo central pero NO el cuerpo del NPC pasará como "libre"
- Puede causar que el NPC se meta en huecos por los que no cabe → atascos

**Impacto estimado:** Reducción de **75%** del coste, pero con **riesgo de calidad** de navegación.

---

### 3. Cachear resultados de raycasts

**Idea:** Almacenar el resultado de `probe_free_distance()` por posición redondeada + dirección, y reutilizarlo si la posición no ha cambiado significativamente.

**Implementación conceptual:**
```lua
local raycast_cache = {}
local CACHE_GRID = 32  -- pixels (cada 32 px se invalida)

local function get_cached_free_distance(pos, dir_x, dir_y, half_x, half_y)
    local gx = math.floor(pos.x / CACHE_GRID)
    local gy = math.floor(pos.y / CACHE_GRID)
    local key = gx .. "," .. gy .. "," .. dir_x .. "," .. dir_y
    
    local cached = raycast_cache[key]
    if cached then
        return cached
    end
    
    local free = probe_free_distance(pos, dir_x, dir_y, half_x, half_y)
    raycast_cache[key] = free
    return free
end
```

**Ventajas:**
- Si los NPCs están en la misma zona, reutilizan resultados (paredes no cambian)
- Reducción significativa si hay clustering de NPCs

**Desventajas:**
- La caché crece con el número de posiciones visitadas (memoria)
- Necesita invalidación (las paredes no cambian, pero sí la posición del NPC)
- Complejidad adicional para mantener la caché

**Impacto estimado:** Reducción variable (30-60%) dependiendo de la dispersión de NPCs.

---

### 4. Limitar NPCs concurrentes en patrulla

**Idea:** Solo permitir que N NPCs estén en estado `PATROL` al mismo tiempo. Los demás quedan en `IDLE` con timers más largos.

**Implementación conceptual:**
```lua
local MAX_CONCURRENT_PATROL = 6  -- Máximo NPCs patrullando simultáneamente
local active_patrol_count = 0

function M.update(self, dt, player_pos, my_pos)
    -- Si hay demasiados NPCs patrolando, quedarse en IDLE
    if self.patrol_state == "IDLE" and active_patrol_count >= MAX_CONCURRENT_PATROL then
        return  -- No intentar patrullar
    end
    
    -- Al entrar en PATROL, incrementar contador
    if self.patrol_state == "PATROL" and not self._counted then
        active_patrol_count = active_patrol_count + 1
        self._counted = true
    end
    
    -- Al salir de PATROL (a IDLE), decrementar
    if self.patrol_state == "IDLE" and self._counted then
        active_patrol_count = active_patrol_count - 1
        self._counted = false
    end
    
    -- ... resto de lógica ...
end
```

**Ventajas:**
- Reduce directamente el número de NPCs que raycastean
- Control preciso del coste por frame

**Desventajas:**
- Visiblemente: menos NPCs en movimiento al mismo tiempo
- Puede crear "oleadas" de movimiento si el límite es bajo
- Requiere gestión de estado global (contador compartido)

**Impacto estimado:** Reducción lineal (con 6 de 14, ~57% menos raycasts).

---

### 5. Detección de plataforma (native vs HTML5)

**Idea:** Usar `platform.is_html5()` (ya implementado en `main/platform.lua`) para aplicar parámetros más ligeros solo en HTML5.

**Parámetros ajustables por plataforma:**

| Parámetro | Native | HTML5 |
|-----------|--------|-------|
| Raycasts por dirección | 3 | 1 |
| `NAV_PROBE` | 150 | 100 |
| `PATROL_IDLE_MIN` | 0.5 | 0.8 |
| `PATROL_IDLE_MAX` | 2.0 | 3.0 |
| `NPC_STOP_IDLE` | 0.8 | 1.2 |

**Ventajas:**
- Se beneficia a HTML5 sin degradar native
- Combinable con otras mitigaciones
- El módulo `platform.lua` ya está implementado

**Desventajas:**
- Complejidad: dos conjuntos de parámetros
- Riesgo de inconsistencia si se cambian parámetros sin actualizar ambos

**Impacto estimado:** Combinación de reducciones parciales según los parámetros elegidos.

---

### 6. Usar `all=false` en raycasts

**Idea:** En vez de `{ all = true }` (devuelve todos los hits), usar sin opciones o `{ first = true }` (devuelve solo el primer hit más cercano).

**Análisis:**
- `physics.raycast(from, to, groups)` sin 4º argumento: devuelve **un solo hit** (no una lista)
- `{ all = true }`: devuelve **todos los hits** como lista
- Para `probe_free_distance()`, solo necesitamos el hit **más cercano** (el que reduce `free`)

**Ventajas:**
- Menos datos a procesar por raycast
- Menos iteraciones en el bucle `for _, hit in ipairs(result)`

**Desventajas:**
- **GOTCHA #44:** Sin `{ all = true }`, el raycast no devuelve una lista → `ipairs` no itera
- Hay que reescribir la lógica para usar el hit directamente (no como tabla)
- Riesgo de romper si se cambia la API de Defold

**Impacto estimado:** Reducción menor (~10-20%) — el coste principal es el raycast en sí, no la iteración.

---

### 7. Navmesh precalculado (alternativa radical)

**Idea:** Precalcular una grid de navegación en init (o al cargar el nivel) que indique qué celdas son transitables. Los NPCs consultan la grid en vez de hacer raycasts.

**Implementación conceptual:**
```lua
-- En init del nivel (o en npc_spawn_manager)
local nav_grid = {}
local CELL_SIZE = 32
for y = 0, level_height, CELL_SIZE do
    for x = 0, level_width, CELL_SIZE do
        local pos = vmath.vector3(x, y, 0)
        -- Raycast vertical para ver si hay pared en esta celda
        local free = probe_free_distance(pos, 0, 1, 0, 0)
        nav_grid[y .. "," .. x] = free > 0
    end
end
```

**Ventajas:**
- Elimina raycasts en runtime completamente
- Navegación instantánea (lookup en hash table)

**Desventajas:**
- Precálculo costoso al inicio (pero se hace una vez)
- Complejidad significativa
- No se adapta a cambios dinámicos del nivel

**Impacto estimado:** Eliminación del **100%** de raycasts en runtime, pero con complejidad alta.

---

## 🎯 Estado actual (Ago 2026)

### ✅ Implementado: Culling por cámara

El **culling por cámara** (`npc.script → is_on_screen()`) ya reduce drásticamente los raycasts al desactivar la patrulla de NPCs off-screen. Con solo 2-3 NPCs en pantalla, el pico bajó de ~168 a ~24-36 raycasts por frame. Ver `docs/PERFORMANCE_NPC_CULLING.md`.

### 📋 Futuro: Escalonamiento por fases (pendiente)

Si en el futuro se necesitan más NPCs en pantalla o se detectan picos en hardware低端, el escalonamiento por fases es la siguiente mitigación segura y sin riesgo. **No se recomienda implementar ahora** — el culling ya resolvió el problema.

**Concepto:** Asignar a cada NPC un "turno" (fase 0-N) y solo ejecutar `pick_direction_with_clearance()` en su turno. Con 4 fases, solo 2-3 NPCs raycastean por frame en vez de todos a la vez.

**Por qué es segura:**
- Los mismos raycasts, repartidos en el tiempo (calidad de navegación idéntica)
- El NPC ya pausa 0.5-2.0 s entre tramos → 1 frame extra (~16 ms) es invisible
- No altera comportamiento visible del jugador
- Funciona tanto en native como en HTML5

**Implementación conceptual:**

```lua
-- npc_patrol.lua
local NUM_CULL_PHASES = (config.balance and config.balance.npc_patrol_phases) or 4

function M.init(self, spawn_pos, half_x, half_y)
    -- ... código existente ...
    self.patrol_phase = math.random(0, NUM_CULL_PHASES - 1)
end

function M.update(self, dt, player_pos, my_pos)
    -- ... (wall correction, player check, NPC separation — igual que antes) ...

    if self.patrol_state == "IDLE" then
        self.patrol_idle_timer = self.patrol_idle_timer - dt
        if self.patrol_idle_timer <= 0 then
            -- 🎥 Solo elegir dirección si es el turno de esta fase
            local frame_phase = math.floor(socket.gettime() * 60) % NUM_CULL_PHASES
            if frame_phase == self.patrol_phase then
                local exclude = self.patrol_wall_avoid or self.patrol_avoid_index
                pick_direction_with_clearance(self, exclude)
                if self.patrol_state == "PATROL" then
                    self.patrol_wall_avoid = nil
                end
            end
            -- Si no es su fase, se reintentará en el siguiente frame
        end
        return
    end

    -- ... (PATROL movement — igual que antes) ...
end
```

**Parámetro configurable:** `config.balance.npc_patrol_phases` (default: 4)

**Impacto combinado con culling:**

| Escenario | Raycasts/frame |
|-----------|---------------|
| Sin optimizaciones | ~168 (pico) |
| Solo culling | ~24-36 |
| Culling + escalonamiento | ~12-18 |

**¿Vale la pena ahora?** No. Con 2-3 NPCs en pantalla, la diferencia es marginal. Se recomienda documentar y **no implementar** hasta que se detecte la necesidad.

### ❌ No recomendado: Reducir 3→1 rayos por dirección

Reducir de 3 a 1 rayo por dirección ahorra un 75% de raycasts, pero **riesga atascos** en pasillos estrechos. Los 3 rayos laterales detectan si el cuerpo del NPC (11×15 px) cabe en el pasillo. Sin ellos, el NPC podría meterse en huecos por los que no pasa. Se descarta.

### ❌ No recomendado: Navmesh precalculado

Elimina el 100% de raycasts en runtime, pero requiere precálculo costoso, complejidad alta y no se adapta a cambios dinámicos. Se descarta para este proyecto.

---

## 🔗 Referencias

- `features/npc/npc_patrol.lua` — Lógica de patrulla y raycasts
- `main/platform.lua` — Detección de plataforma (is_html5)
- `main/config.lua` — Parámetros configurables (balance)
- `docs/PERFORMANCE_CULLING.md` — Culling por cámara (implementado)
- `docs/PERFORMANCE_NOTES.md` — Métricas de rendimiento
- `docs/DEV_GOTCHAS.md` — GOTCHA #43/#44 (physics.raycast)
