-- features/npc/npc_patrol.lua
-- ═══════════════════════════════════════════════════════
-- 🚶 SISTEMA DE PATRULLA PARA NPCs
-- ═══════════════════════════════════════════════════════
--
--   Lógica de movimiento autónomo para NPCs amigables.
--   Patrullan dentro de un radio desde su punto de spawn,
--   moviéndose solo en ángulos de 90° (cardinal).
--   Se detienen cuando el jugador está cerca (100 uds)
--   y reanudan cuando se aleja (150 uds, histéresis).
--   También se separan entre sí (Ago 2026): si otro NPC está cerca durante
--   la patrulla se desvían en perpendicular, o se detienen brevemente si hay
--   contacto (los NPCs no colisionan por física: son KINEMATIC↔KINEMATIC).
--   Solo se evitan ENTRE ellos: el gato queda excluido de la separación.
--
--   🧭 SPACE CHECK (Ago 2026): antes de comprometerse a un tramo, la
--   dirección se elige midiendo el espacio libre contra las paredes
--   (raycast contra group "walls", 3 rayos paralelos por el ancho del
--   cuerpo) y exigiendo un hueco mínimo (NAV_CLEARANCE, configurable en
--   config.balance → npc_nav_clearance). La elección es ALEATORIA entre las
--   óptimas (variabilidad en el recorrido); sin óptimas → la de mayor hueco
--   (fallback); sin sitio ni para moverse → IDLE breve. Al chocar FRONTAL
--   contra una pared hay una pausa breve (girar con intención) y la
--   re-elección llega desde el IDLE; los roces laterales solo empujan, sin
--   re-elegir. Los hits del raycast a ≤ PROBE_EPS se ignoran (artefacto del
--   propio cuerpo tocando la geometría) para que en un cruce se detecten
--   las salidas laterales.
--
--   Uso desde npc.script (y cat.script en su estado PATROL):
--     local patrol = require "features.npc.npc_patrol"
--     patrol.init(self, spawn_pos [, half_x, half_y])
--     -- en update():
--     patrol.update(self, dt, player_pos, my_pos)
--
--   📐 Los semiejes (half_x, half_y) son los de la caja de colisión de la
--   entidad contra las paredes: por defecto la de los NPCs (11×15 → 5.5/7.5);
--   el gato pasa los suyos (25×25 → 12.5) desde cat.script. Ver GOTCHA #42.
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-20
-- ═══════════════════════════════════════════════════════

local M = {}

-- 👥 Registro de URLs reales de NPCs (para la separación entre ellos)
local npc_spawn_state = require "main.npc_spawn_state"
local config = require "main.config"

-- 🔧 DEBUG granular (sistema make_log, ver main/config.lua): true = loguea
--    cuando M.DEBUG esté activo; false = silenciado (por defecto)
local DEBUG_PATROL = false
local dprint = config.make_log(DEBUG_PATROL)

-- ═══════════════════════════════════════════════════════
-- 🔧 CONSTANTES
-- ═══════════════════════════════════════════════════════

local PATROL_IDLE_MIN     = 0.5    -- Segundos mínimo quieto entre tramos
local PATROL_IDLE_MAX     = 2.0    -- Segundos máximo quieto entre tramos
local PATROL_DIST_MIN     = 80     -- Píxeles mínimo por tramo
local PATROL_DIST_MAX     = 300    -- Píxeles máximo por tramo
local PLAYER_STOP_DIST    = (config.balance and config.balance.npc_player_stop_dist) or 70
local PLAYER_RESUME_DIST  = (config.balance and config.balance.npc_player_resume_dist) or 110

-- 👥 Separación entre NPCs (Ago 2026): evita superposiciones al patrullar
local NPC_SEPARATION_DIST = 40     -- Píxeles: radio que activa la separación
local NPC_STOP_DIST       = 22     -- Píxeles: por debajo de esta, detenerse (contacto)
local NPC_SCAN_INTERVAL   = 0.15   -- Segundos entre escaneos de los demás NPCs (barato)
local NPC_STOP_IDLE       = 0.8    -- Segundos quieto tras contacto con otro NPC
local NPC_CAT_ID          = "cat"  -- Id del gato en el registro (excluido de la separación)

-- Direcciones cardinales: {dx, dy}
local CARDINAL = {
	{ 1,  0},  -- derecha
	{-1,  0},  -- izquierda
	{ 0,  1},  -- arriba
	{ 0, -1},  -- abajo
}

-- 🧭 SPACE CHECK (Ago 2026): hueco libre mínimo (uds) exigido en la dirección
--    elegida antes de comprometerse a un tramo (umbral de navegación).
--    Configurable en config.balance → npc_nav_clearance; si la clave falta,
--    fallback 60 (convención del proyecto: una clave borrada nunca rompe).
local NAV_CLEARANCE = (config.balance and config.balance.npc_nav_clearance) or 60
local NAV_PROBE     = 150   -- longitud del rayo de sonda (por dirección)
local NAV_MIN_FREE  = 5     -- por debajo: sin sitio ni para moverse → IDLE breve
local PROBE_EPS     = 2     -- ignorar hits del raycast a ≤ esta distancia (el
                            -- cuerpo toca/solapa la geometría: sin esto, al
                            -- sondear desde una pared frontal las salidas
                            -- laterales de un cruce leen como bloqueadas)
local WALL_TURN_IDLE = 0.35 -- pausa breve al chocar FRONTAL (girar con intención)
-- 📐 Semiejes de la caja de colisión contra paredes usados por la sonda
-- (collisionobject_walls 11×15 en npc_XX.go): los rayos laterales van por
-- los BORDES del cuerpo para medir el hueco REAL (un pasillo por el que
-- solo cabe el rayo central se descarta: el cuerpo no pasa). Son el
-- DEFAULT: cada entidad puede pasar los suyos a patrol.init (el gato pasa
-- 12.5/12.5, caja 25×25, desde cat.script). ⚠️ Si se cambia la caja de un
-- NPC/gato, actualizar aquí o en la llamada de la entidad (GOTCHA #42).
local DEFAULT_HALF_X = 5.5
local DEFAULT_HALF_Y = 7.5

-- Hashes cacheados (§2 de DEFOLD_LUA_STANDARDS): group de paredes y grupos
-- del raycast. 🚨 GOTCHA #43/#44: la máscara debe listar grupos REALES
-- ({ hash("collision_object") } no golpeaba NADA) y el raycast síncrono
-- necesita el 4º argumento { all = true } para devolver una LISTA (sin él
-- devuelve los campos del hit a nivel superior → ipairs no itera). Antes esta
-- sonda medía huecos OPTIMISTAS sin detectar paredes (GOTCHA #43 lo dejó
-- pendiente; corregido Ago 2026 junto al gato).
local HASH_WALLS = hash("walls")
local RAYCAST_GROUPS = { hash("walls") }

-- ═══════════════════════════════════════════════════════
-- 🧭 SPACE CHECK: MEDIR EL HUECO LIBRE POR DIRECCIÓN
-- ═══════════════════════════════════════════════════════

-- 📏 Sonda de espacio libre en una dirección cardinal (desde `pos`). Dispara
--    3 rayos paralelos contra el group "walls": centro + los dos BORDES
--    laterales del cuerpo de la entidad (semiejes half_x/half_y pasados por
--    el caller — por entidad, ver GOTCHA #42). Devuelve la distancia libre
--    MÍNIMA de los tres (NAV_PROBE si no hay pared en el alcance). Un hueco
--    por el que solo cabe el rayo central (pasillo estrecho) queda
--    penalizado por los rayos laterales → no se compromete a huecos por los
--    que no cabe. Coste: 3 raycasts por dirección, solo al elegir tramo.
local function probe_free_distance(pos, dir_x, dir_y, half_x, half_y)
	-- Vector perpendicular a la dirección (para desplazar los rayos laterales)
	local perp_x, perp_y = -dir_y, dir_x
	-- Semieje de la entidad sobre el eje perpendicular: moverse en X →
	-- laterales en Y (half_y); moverse en Y → laterales en X (half_x).
	local half = (dir_x ~= 0) and half_y or half_x
	local best = NAV_PROBE

	for i = -1, 1 do
		local ox = perp_x * half * i
		local oy = perp_y * half * i
		local from = vmath.vector3(pos.x + ox, pos.y + oy, pos.z)
		local to = vmath.vector3(from.x + dir_x * NAV_PROBE, from.y + dir_y * NAV_PROBE, from.z)
		local result = physics.raycast(from, to, RAYCAST_GROUPS, { all = true }) or {}
		local free = NAV_PROBE
		for _, hit in ipairs(result) do
			if hit.group == HASH_WALLS then
				-- Distancia al muro (por la posición del hit, sin depender de
				-- hit.fraction). ⚠️ Se IGNORAN los hits a ≤ PROBE_EPS: son
				-- artefactos del propio cuerpo tocando/solapando la geometría
				-- (p. ej. sondear la salida lateral de un cruce desde la pared
				-- frontal con la que se acaba de chocar) — sin esto, la salida
				-- lee como bloqueada y el NPC "no encuentra" otra dirección.
				local dx = hit.position.x - from.x
				local dy = hit.position.y - from.y
				local d = math.sqrt(dx * dx + dy * dy)
				if d > PROBE_EPS and d < free then
					free = d
				end
			end
		end
		if free < best then best = free end
	end
	return best
end

-- ═══════════════════════════════════════════════════════
-- 🎯 SELECCIÓN DE DIRECCIÓN CON SPACE CHECK
-- ═══════════════════════════════════════════════════════

-- Elige la dirección del siguiente tramo midiendo el hueco libre REAL:
--   1. ÓPTIMAS: cardinales con espacio libre ≥ NAV_CLEARANCE (umbral de
--      navegación). ALEATORIA entre ellas (respetando exclude_dir_index) →
--      el recorrido varía: en un pasillo alterna avance/retroceso con sus
--      pausas (pacing natural), en un cruce gira a cualquier salida óptima.
--   2. FALLBACK: si ninguna llega al umbral (callejón / borde de zona),
--      elegir la de MAYOR hueco (avanza igual, nunca se queda clavado).
--   3. Sin sitio ni para moverse (todo < NAV_MIN_FREE): IDLE breve en vez de
--      micro-choques contra la pared.
local function pick_direction_with_clearance(self, exclude_dir_index)
	local pos = go.get_position()

	-- Medir el hueco de cada cardinal (el excluido queda a -1)
	local best_free = -1
	for i = 1, #CARDINAL do
		if i ~= exclude_dir_index then
			local dir = CARDINAL[i]
			self.probe_free[i] = probe_free_distance(pos, dir[1], dir[2], self.npc_half_x, self.npc_half_y)
			if self.probe_free[i] > best_free then best_free = self.probe_free[i] end
		else
			self.probe_free[i] = -1
		end
	end

	-- Sin sitio para moverse: quedarse un instante y reintentar
	if best_free < NAV_MIN_FREE then
		self.patrol_state = "IDLE"
		self.patrol_idle_timer = 0.4
		dprint("[Patrol] Sin espacio para moverse (mejor hueco " .. string.format("%.1f", best_free) .. " uds) → IDLE breve")
		return
	end

	-- Direcciones óptimas (hueco ≥ umbral)
	local optimal = {}
	for i = 1, #CARDINAL do
		if self.probe_free[i] >= NAV_CLEARANCE then
			table.insert(optimal, i)
		end
	end

	local chosen
	if #optimal > 0 then
		-- 🎲 Aleatoria entre las óptimas (incluida la de retroceso: es la
		--    variabilidad del recorrido — un guardia que va y viene por un
		--    pasillo con sus pausas, y en un callejón vuelve por donde vino).
		chosen = optimal[math.random(1, #optimal)]
	else
		-- Fallback: la de mayor hueco (ninguna llega al umbral)
		chosen = nil
		for i = 1, #CARDINAL do
			if i ~= exclude_dir_index and (chosen == nil or self.probe_free[i] > self.probe_free[chosen]) then
				chosen = i
			end
		end
		dprint("[Patrol] Ninguna dirección óptima (mejor hueco " .. string.format("%.1f", best_free) .. " < " .. NAV_CLEARANCE .. ") → la de mayor hueco")
	end

	local dir = CARDINAL[chosen]
	self.patrol_dir_x = dir[1]
	self.patrol_dir_y = dir[2]
	self.patrol_target_dist = math.random(PATROL_DIST_MIN, PATROL_DIST_MAX)
	self.patrol_distance_traveled = 0
	self.patrol_state = "PATROL"
end

-- ═══════════════════════════════════════════════════════
-- 👥 BÚSQUEDA DEL OTRO NPC MÁS CERCANO
-- ═══════════════════════════════════════════════════════

-- Devuelve (distancia², índice cardinal hacia el otro NPC, dx, dy) del NPC
-- registrado más cercano dentro del radio de separación, o nil si no hay
-- ninguno cerca. Zero-garbage: distancia 2D por componentes (sin alocar —
-- §1); go.get_position es la única llamada al motor y se hace a intervalos.
local function find_nearest_other_npc(self, my_pos)
	local best_d2 = NPC_SEPARATION_DIST * NPC_SEPARATION_DIST
	local best_dx, best_dy
	for npc_id, url in pairs(npc_spawn_state.get_all_npc_urls()) do
		-- 👥 Solo NPCs: el gato se registra como "cat" en este mismo registro
		--    (cat.script) y NO forma parte de la separación entre NPCs.
		if npc_id ~= self.npc_id_string and npc_id ~= NPC_CAT_ID and go.exists(url) then
			local other_pos = go.get_position(url)
			local dx = other_pos.x - my_pos.x
			local dy = other_pos.y - my_pos.y
			local d2 = dx * dx + dy * dy
			if d2 < best_d2 then
				best_d2 = d2
				best_dx = dx
				best_dy = dy
			end
		end
	end
	if best_d2 >= NPC_SEPARATION_DIST * NPC_SEPARATION_DIST then
		return nil
	end
	-- Índice cardinal hacia el otro NPC según el eje dominante
	-- (1 derecha, 2 izquierda, 3 arriba, 4 abajo — orden de CARDINAL)
	local toward
	if math.abs(best_dx) > math.abs(best_dy) then
		toward = (best_dx > 0) and 1 or 2
	else
		toward = (best_dy > 0) and 3 or 4
	end
	return best_d2, toward, best_dx, best_dy
end

-- ═══════════════════════════════════════════════════════
-- 🚀 INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════

function M.init(self, spawn_pos, half_x, half_y)
	self.patrol_state = "IDLE"
	self.patrol_spawn = spawn_pos

	-- 📐 Semiejes del cuerpo para la sonda de espacio libre (por entidad):
	--    por defecto la caja de los NPCs (11×15 → 5.5/7.5); el gato pasa la
	--    suya (25×25 → 12.5) desde cat.script. Ver GOTCHA #42.
	self.npc_half_x = half_x or DEFAULT_HALF_X
	self.npc_half_y = half_y or DEFAULT_HALF_Y
	self.patrol_idle_timer = math.random(PATROL_IDLE_MIN, PATROL_IDLE_MAX)
	self.patrol_dir_x = 0
	self.patrol_dir_y = 0
	self.patrol_target_dist = 0
	self.patrol_distance_traveled = 0
	self.patrol_player_near = false

	-- 🧱 Corrección consolidada de paredes (evita jitter con múltiples contact_points)
	self.wall_push_pos = vmath.vector3()  -- máx empuje positivo por eje
	self.wall_push_neg = vmath.vector3()  -- máx empuje negativo por eje

	-- Arranca con la primera dirección ya seleccionada
	-- (el timer de IDLE se encargará de iniciar el movimiento)

	-- 👥 Separación entre NPCs: el primer escaneo arranca inmediato (timer 0)
	self.patrol_npc_scan_timer = 0
	self.near_npc_d2 = nil
	self.near_npc_toward = nil
	self.near_npc_dx = nil
	self.near_npc_dy = nil
	self.patrol_avoid_index = nil

	-- 🧭 Huecos libres medidos por cardinal (índice 1..4, -1 = excluido)
	self.probe_free = {}
	-- 🧭 Dirección de la pared que detuvo al NPC (choque frontal): se excluye
	--    en la siguiente re-elección desde el IDLE y se consume al reanudar.
	self.patrol_wall_avoid = nil
end

-- ═══════════════════════════════════════════════════════
-- 🔄 ACTUALIZACIÓN (llamar desde update del npc.script)
-- ═══════════════════════════════════════════════════════

function M.update(self, dt, player_pos, my_pos)
	if self.patrol_state == "DISABLED" then return end

	-- 🧱 Aplicar corrección consolidada de paredes (push_pos + push_neg).
	-- Se acumuló en on_contact_point durante on_message, se aplica UNA SOLA VEZ
	-- al inicio del update para evitar jitter por múltiples contact_point_response.
	-- Zero-garbage: suma por componentes en my_pos (copia fresca pasada por el
	-- caller: npc.script envía go.get_position()) y resets por componentes
	-- (antes: correction = pos+neg + 2× vmath.vector3() alocaban cada frame
	-- por NPC en patrulla).
	local has_correction = vmath.length_sqr(self.wall_push_pos) > 0
		or vmath.length_sqr(self.wall_push_neg) > 0
	if has_correction then
		my_pos.x = my_pos.x + self.wall_push_pos.x + self.wall_push_neg.x
		my_pos.y = my_pos.y + self.wall_push_pos.y + self.wall_push_neg.y
		my_pos.z = my_pos.z + self.wall_push_pos.z + self.wall_push_neg.z
		go.set_position(my_pos)
	end
	self.wall_push_pos.x = 0
	self.wall_push_pos.y = 0
	self.wall_push_pos.z = 0
	self.wall_push_neg.x = 0
	self.wall_push_neg.y = 0
	self.wall_push_neg.z = 0

	if not player_pos then
		self.patrol_state = "IDLE"
		return
	end

	local dist_to_player = vmath.length(player_pos - my_pos)

	-- 🧍 Si el jugador está cerca → detener patrulla
	if dist_to_player < PLAYER_STOP_DIST then
		if not self.patrol_player_near then
			self.patrol_player_near = true
			self.patrol_state = "IDLE"
			self.patrol_idle_timer = 9999  -- no reanudar solo
		end
		return
	end

	-- 🧍 Si el jugador se aleja lo suficiente → reanudar
	if self.patrol_player_near and dist_to_player > PLAYER_RESUME_DIST then
		self.patrol_player_near = false
		self.patrol_idle_timer = math.random(PATROL_IDLE_MIN, PATROL_IDLE_MAX)
	end

	-- 👥 Separación entre NPCs (Ago 2026): evita que se superpongan al
	--    patrullar. El escaneo de los demás NPCs se hace a intervalos (no
	--    aloca por frame); la decisión se aplica cada frame con el último
	--    resultado. No corre con el jugador cerca: en ese caso el NPC ya
	--    está detenido (el early return anterior) y el solape sería estático.
	self.patrol_npc_scan_timer = self.patrol_npc_scan_timer - dt
	if self.patrol_npc_scan_timer <= 0 then
		self.patrol_npc_scan_timer = NPC_SCAN_INTERVAL
		self.near_npc_d2, self.near_npc_toward, self.near_npc_dx, self.near_npc_dy =
			find_nearest_other_npc(self, my_pos)
	end

	if self.near_npc_d2 then
		-- 🚧 Hay otro NPC dentro del radio de separación: al reanudar de un
		--    IDLE (normal o por contacto) se excluirá la dirección hacia él.
		self.patrol_avoid_index = self.near_npc_toward

		if self.near_npc_d2 < NPC_STOP_DIST * NPC_STOP_DIST then
			-- 💥 Contacto: detenerse un instante (que el otro pase) y al
			--    reanudar, la re-elección excluye la dirección hacia él.
			if self.patrol_state == "PATROL" then
				self.patrol_state = "IDLE"
				self.patrol_idle_timer = NPC_STOP_IDLE
			end
		elseif self.patrol_state == "PATROL" then
			-- 🧭 Cerca y avanzando hacia él: desviarse en perpendicular (misma
			--    mecánica que el esquive de paredes: re-elegir dirección
			--    excluyendo la que apunta al otro NPC). El dot product solo
			--    mira el SIGNO (avanza hacia él o no) — sin alocar.
			local dot = self.patrol_dir_x * self.near_npc_dx + self.patrol_dir_y * self.near_npc_dy
			if dot > 0 then
				pick_direction_with_clearance(self, self.near_npc_toward)
			end
		end
	else
		self.patrol_avoid_index = nil
	end

	-- ⏱️ IDLE: esperando antes del siguiente tramo
	if self.patrol_state == "IDLE" then
		self.patrol_idle_timer = self.patrol_idle_timer - dt
		if self.patrol_idle_timer <= 0 then
			-- Excluir la dirección hacia otro NPC si sigue cerca (separación)
			-- y/o la pared frontal que nos detuvo (choque); el wall_avoid se
			-- consume solo cuando se consigue una dirección nueva.
			local exclude = self.patrol_wall_avoid or self.patrol_avoid_index
			pick_direction_with_clearance(self, exclude)
			if self.patrol_state == "PATROL" then
				self.patrol_wall_avoid = nil
			end
		end
		return
	end

	-- 🚶 PATROL: moviéndose
	if self.patrol_state == "PATROL" then
		local speed = self.patrol_speed or 30
		local step = speed * dt
		local new_pos = vmath.vector3(
			my_pos.x + self.patrol_dir_x * step,
			my_pos.y + self.patrol_dir_y * step,
			my_pos.z
		)

		-- Verificar límite radial desde el spawn
		local dist_from_spawn = vmath.length(new_pos - self.patrol_spawn)
		if dist_from_spawn > self.patrol_radius then
			self.patrol_distance_traveled = self.patrol_target_dist  -- forzar fin
		end

		-- Aplicar movimiento
		go.set_position(new_pos)
		self.patrol_distance_traveled = self.patrol_distance_traveled + step

		-- Si llegó a la distancia objetivo, pausar
		if self.patrol_distance_traveled >= self.patrol_target_dist then
			self.patrol_state = "IDLE"
			self.patrol_idle_timer = math.random(PATROL_IDLE_MIN, PATROL_IDLE_MAX)
		end
	end
end

-- ═══════════════════════════════════════════════════════
-- 💥 COLISIÓN CON PAREDES
-- ═══════════════════════════════════════════════════════

function M.on_contact_point(self, message)
	if self.patrol_state == "PATROL" then
		-- 🧱 Acumular corrección por máximo por eje/dirección (como jugador y cucarachas).
		-- En vez de aplicar go.set_position() inmediatamente (que causa jitter con
		-- múltiples contact_point_response en el mismo frame), se consolida y aplica
		-- UNA SOLA VEZ al inicio del siguiente update().
		local comp = message.normal * message.distance
		if comp.x > 0 then
			self.wall_push_pos.x = math.max(self.wall_push_pos.x, comp.x)
		elseif comp.x < 0 then
			self.wall_push_neg.x = math.min(self.wall_push_neg.x, comp.x)
		end
		if comp.y > 0 then
			self.wall_push_pos.y = math.max(self.wall_push_pos.y, comp.y)
		elseif comp.y < 0 then
			self.wall_push_neg.y = math.min(self.wall_push_neg.y, comp.y)
		end

		-- Determinar qué dirección evitar según la normal de la pared
		-- La normal apunta desde la pared hacia el NPC
		-- Si normal.x > 0: pared a la izquierda → evitar ir a la izquierda (CARDINAL[2])
		-- Si normal.x < 0: pared a la derecha → evitar ir a la derecha (CARDINAL[1])
		local avoid_index
		if math.abs(message.normal.x) > 0.5 then
			avoid_index = (message.normal.x > 0) and 2 or 1
		elseif math.abs(message.normal.y) > 0.5 then
			avoid_index = (message.normal.y > 0) and 4 or 3
		end
		if avoid_index then
			local avoid_dir = CARDINAL[avoid_index]
			-- 💥 ¿Choque FRONTAL (la pared se opone al movimiento) o roce lateral?
			--    Frontal → pausa breve (girar con intención) y la re-elección
			--    con space check llega desde el IDLE del update (excluyendo esta
			--    pared). Lateral → SOLO la corrección de empuje, sin re-elegir:
			--    antes se re-elegía en cada contacto y el NPC se atascaba contra
			--    las paredes laterales de los pasillos.
			if avoid_dir[1] == self.patrol_dir_x and avoid_dir[2] == self.patrol_dir_y then
				self.patrol_wall_avoid = avoid_index
				self.patrol_state = "IDLE"
				self.patrol_idle_timer = WALL_TURN_IDLE
			end
		end
	end
end

-- ═══════════════════════════════════════════════════════
-- ⏸️ CONTROL EXTERNO
-- ═══════════════════════════════════════════════════════

function M.pause(self)
	self.patrol_state = "IDLE"
	self.patrol_player_near = true
	self.patrol_idle_timer = 9999
end

function M.resume(self)
	self.patrol_player_near = false
	self.patrol_idle_timer = math.random(PATROL_IDLE_MIN, PATROL_IDLE_MAX)
end

return M
