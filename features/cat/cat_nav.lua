-- features/cat/cat_nav.lua
-- ═══════════════════════════════════════════════════════
-- 🧭 NAVEGACIÓN ASISTIDA PARA EL GATO
-- ═══════════════════════════════════════════════════════
--
--   Proporciona movimiento hacia un objetivo con esquive
--   de obstáculos (wall-following) para los estados CHASE
--   y PET del gato, donde no se usa npc_patrol.lua.
--
--   Incluye recuperación progresiva de atascos en 4 niveles:
--     N1 (0.4s): recalcular lado de esquive (blend 60% lateral + 40% forward)
--     N2 (1.0s): wall-following: deslizarse por la tangente de la pared hacia el objetivo
--     N3 (2.0s): alejarse del objetivo (dirección opuesta)
--     N4 (3.0s): dirección aleatoria, ciclando cada 0.5s
--
--   Uso:
--     local nav = require "features.cat.cat_nav"
--     nav.init(self)
--     -- en update():
--     local arrived = nav.move_towards(self, target_pos, speed, dt)
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-15
-- ═══════════════════════════════════════════════════════

local M = {}

-- 🔧 DEBUG [GATO-NAV]: cambiar a true para activar los logs de atasco/navegación
--    (activar solo para depurar; mantener false en juego normal)
local DEBUG_NAV = false
-- Log granular: respeta DEBUG_NAV (local) y el kill-switch global M.DEBUG
local dprint = require("main.config").make_log(DEBUG_NAV)

-- ═══════════════════════════════════════════════════════
-- 🔧 CONSTANTES
-- ═══════════════════════════════════════════════════════

local EVADE_TIMEOUT     = 3.0    -- segundos antes de cambiar dirección de esquive
local EVADE_HOLD        = 0.2    -- histéresis: mantener esquive tras desaparecer obstáculo
local LATERAL_PROBE     = 30     -- píxeles para sondear lateralmente
local FRONT_PROBE       = 30     -- píxeles para sondear frontal (equilibrio: ni muy lejos ni muy cerca)
local ARRIVED_DIST      = 10     -- distancia para considerar "llegado"

-- Niveles progresivos de desatasco (basados en nav_stuck_timer acumulado)
local STUCK_LEVEL1 = 0.4   -- N1: recalcular lado de esquive normal
local STUCK_LEVEL2 = 1.0   -- N2: movimiento 100% lateral
local STUCK_LEVEL3 = 2.0   -- N3: dirección opuesta al objetivo
local STUCK_LEVEL4 = 3.0   -- N4: dirección aleatoria, cicla cada 0.5s

-- 🚨 GOTCHA #43/#44 (Ago 2026): DOS bugs independientes hacían estas sondas
--    INERTES (el esquive N1-N4 escalaba solo por temporizador):
--    1. (#43) la máscara era { hash("collision_object") } — grupo inexistente
--       (los muros son "walls") → el raycast no golpeaba nada.
--    2. (#44) faltaba el 4º argumento { all = true }: sin él el raycast
--       síncrono devuelve los CAMPOS del hit a nivel superior (NO una lista)
--       → ipairs(result) no itera NADA → nunca se detectaba pared.
--    El MISMO patrón roto afectaba a has_clear_path/has_line_of_sight en
--    cat.script (gato atacando enemigos a través de muros) — corregido junto
--    a esto (ver cat.script y GOTCHA #43/#44 en docs/DEV_GOTCHAS.md).
local RAYCAST_WALLS = { hash("walls") }

-- Etiquetas para logs de atasco (índice = nivel + 1)
local STUCK_LABELS = { "libre", "N1:evade", "N2:lateral", "N3:reversa", "N4:random" }

-- ═══════════════════════════════════════════════════════
-- 🚀 INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════

function M.init(self)
	self.nav_evading = false
	self.nav_evade_side = 1       -- +1 derecha, -1 izquierda (relativo a forward)
	self.nav_evade_timer = 0
	self.nav_stuck_timer = 0
	self.nav_stuck_level = 0      -- 0=libre, 1-4=gravedad de atasco
	self.nav_last_pos = nil
	self.nav_evasion_hold = 0
	self.nav_evade_side_lock = 0
	self.nav_evade_side_lock_duration = 0.5
	self.nav_random_angle = 0     -- ángulo para N4
	self.nav_random_timer = 0     -- timer para ciclar ángulo en N4
	self.nav_wall_tangent = nil   -- tangente de pared para wall-following en N2
	self.nav_wall_normal = nil    -- normal de pared desde contact_point (cat.script)
end

-- ═══════════════════════════════════════════════════════
-- 🔄 REINICIO (cuando se cambia de objetivo o estado)
-- ═══════════════════════════════════════════════════════

function M.reset(self)
	self.nav_evading = false
	self.nav_evade_timer = 0
	self.nav_stuck_timer = 0
	self.nav_stuck_level = 0
	self.nav_last_pos = nil
	self.nav_evasion_hold = 0
	self.nav_evade_side_lock = 0
	self.nav_random_angle = 0
	self.nav_random_timer = 0
	self.nav_wall_tangent = nil
	self.nav_wall_normal = nil
end

-- ═══════════════════════════════════════════════════════
-- 🎯 SNAP A 8 DIRECCIONES (top-down clásico)
-- ═══════════════════════════════════════════════════════

-- Redondea un vector de dirección al más cercano de 8 ángulos
-- (N, NE, E, SE, S, SW, W, NW) y guarda los componentes para
-- que cat.script pueda seleccionar la animación correcta.
local function snap_to_eight_dirs(self, dir)
	local angle = math.atan2(dir.y, dir.x)
	-- Snap a incrementos de 45° (pi/4)
	local snapped = math.floor((angle + math.pi / 8) / (math.pi / 4)) * (math.pi / 4)
	self.nav_dir_x = math.cos(snapped)
	self.nav_dir_y = math.sin(snapped)
	return vmath.vector3(self.nav_dir_x, self.nav_dir_y, 0)
end

-- ═══════════════════════════════════════════════════════
-- 🔍 SONDEO LATERAL
-- ═══════════════════════════════════════════════════════

-- Comprueba si el lado indicado está libre de obstáculos.
-- forward_dir: dirección hacia el objetivo (normalizada)
-- side_sign: +1 derecha (relativa a forward), -1 izquierda
-- NOTA: El gato NO rota (go.get_rotation siempre es cero),
--       así que el lateral se calcula como perpendicular a forward_dir.
local function probe_side(forward_dir, side_sign)
	local my_pos = go.get_position()

	-- Vector perpendicular a forward_dir (rotado 90°): (-y, x) o (y, -x)
	local side_vec = vmath.vector3(-forward_dir.y * side_sign, forward_dir.x * side_sign, 0)
	local probe_end = my_pos + side_vec * LATERAL_PROBE

	local result = physics.raycast(my_pos, probe_end, RAYCAST_WALLS, { all = true }) or {}

	if #result > 0 then
		for _, hit in ipairs(result) do
			if hit.group == hash("walls") then
				return false  -- pared detectada en este lado
			end
		end
	end

	return true  -- lado libre
end

-- ═══════════════════════════════════════════════════════
-- 🧭 NAVEGAR HACIA UN OBJETIVO
-- ═══════════════════════════════════════════════════════
--
--   Intenta moverse directamente hacia target_pos.
--   Si encuentra un obstáculo (pared), activa modo esquive
--   con wall-following y recuperación progresiva de atasco.
--
--   @param self       tabla  Estado del navegador
--   @param target_pos vector3  Posición destino
--   @param speed      number  Velocidad (px/s)
--   @param dt         number  Delta time
--   @return boolean true si llegó al destino
-- ═══════════════════════════════════════════════════════

function M.move_towards(self, target_pos, speed, dt)
	local my_pos = go.get_position()
	local to_target = target_pos - my_pos
	to_target.z = 0
	local distance = vmath.length(to_target)

	-- Si ya está muy cerca, considerar llegado
	if distance < ARRIVED_DIST then
		return true
	end

	-- Dirección normalizada hacia el objetivo
	local dir_normalized = vmath.normalize(to_target)

	-- 🔍 DETECCIÓN DE ATASCO (mide desplazamiento real entre frames)
	if self.nav_last_pos then
		local moved = vmath.length(my_pos - self.nav_last_pos)
		if moved < 1 then
			self.nav_stuck_timer = self.nav_stuck_timer + dt
		else
			-- Se está moviendo → resetear TODO el estado de atasco
			self.nav_stuck_timer = 0
			self.nav_stuck_level = 0
			self.nav_random_timer = 0
		end
	else
		self.nav_stuck_timer = 0
		self.nav_stuck_level = 0
	end
	self.nav_last_pos = vmath.vector3(my_pos)

	-- Determinar nivel de atasco (crece, nunca decrece hasta moverse)
	local prev_level = self.nav_stuck_level
	if self.nav_stuck_timer >= STUCK_LEVEL4 then
		self.nav_stuck_level = 4
	elseif self.nav_stuck_timer >= STUCK_LEVEL3 then
		self.nav_stuck_level = 3
	elseif self.nav_stuck_timer >= STUCK_LEVEL2 then
		self.nav_stuck_level = 2
	elseif self.nav_stuck_timer >= STUCK_LEVEL1 then
		self.nav_stuck_level = 1
	end
	-- Log solo cuando el nivel cambia (no spam cada frame); el toggle local
	-- (DEBUG_NAV) y el kill-switch global (M.DEBUG) los gestiona make_log
	if self.nav_stuck_level ~= prev_level then
		dprint("[GATO-NAV] Atasco " .. STUCK_LABELS[prev_level + 1] .. " → " .. STUCK_LABELS[self.nav_stuck_level + 1]
			.. " (" .. string.format("%.1f", self.nav_stuck_timer) .. "s)")
	end

	-- 🔍 RAYCAST FRONTAL para detectar obstáculos
	local probe_end = my_pos + dir_normalized * FRONT_PROBE
	local result = physics.raycast(my_pos, probe_end, RAYCAST_WALLS, { all = true }) or {}

	local obstacle = false
	local wall_normal = nil  -- normal de la pared para wall-following
	for _, hit in ipairs(result) do
		if hit.group == hash("walls") then
			obstacle = true
			wall_normal = hit.normal  -- normal del raycast como fallback
			break
		end
	end

	-- Preferir la normal del contact_point_response (pared que el gato
	-- está TOCANDO) sobre la del raycast (pared que el rayo DETECTA).
	-- El raycast apunta hacia el target, no hacia la pared lateral
	-- contra la que el gato realmente está atascado.
	if self.nav_wall_normal then
		wall_normal = self.nav_wall_normal
	end
	self.nav_wall_normal = nil

	-- Si está atascado en cualquier nivel, forzar modo obstáculo
	local stuck = self.nav_stuck_level >= 1
	if stuck then
		obstacle = true
	end

	-- Histéresis: mantener esquive un tiempo tras desaparecer obstáculo
	if obstacle then
		self.nav_evasion_hold = EVADE_HOLD
	elseif self.nav_evasion_hold > 0 then
		self.nav_evasion_hold = self.nav_evasion_hold - dt
		obstacle = true
	end

	-- ═══════════════════════════════════════════
	-- 🟢 MOVIMIENTO DIRECTO (sin obstáculo)
	-- ═══════════════════════════════════════════
	if not obstacle then
		if self.nav_evading then
			self.nav_evading = false
			self.nav_evade_timer = 0
			self.nav_evade_side_lock = 0
		end

		local snapped_dir = snap_to_eight_dirs(self, dir_normalized)
		local step = speed * dt
		go.set_position(my_pos + snapped_dir * step)

		return false
	end

	-- ═══════════════════════════════════════════
	-- 🟡 MODO ESQUIVE (obstáculo detectado)
	-- ═══════════════════════════════════════════

	-- Elegir/recalcular lado de esquive si:
	--   - primera vez en evade, o
	--   - estamos en N1+ (atasco) y el lock expiró
	local should_recalc = (not self.nav_evading) or (stuck and self.nav_evade_side_lock <= 0)

	if should_recalc then
		if self.nav_evade_side_lock <= 0 then
			-- Si tenemos la normal de la pared, elegir el lado que
			-- sigue la tangente hacia el objetivo (wall-following inteligente)
		if wall_normal and vmath.length_sqr(wall_normal) > 0 then
			-- Dos tangentes: (ny, -nx) y (-ny, nx)
				local t1 = vmath.vector3(wall_normal.y, -wall_normal.x, 0)
				local t2 = vmath.vector3(-wall_normal.y, wall_normal.x, 0)
				-- Elegir la tangente que apunta más hacia el objetivo
				if vmath.dot(t1, to_target) > vmath.dot(t2, to_target) then
					self.nav_evade_side = 1   -- t1 = lado "derecho" de la pared
					self.nav_wall_tangent = t1
				else
					self.nav_evade_side = -1
					self.nav_wall_tangent = t2
				end
			else
				-- Sin normal: elegir según sonda lateral tradicional
				local right_free = probe_side(dir_normalized, 1)
				local left_free = probe_side(dir_normalized, -1)

				if right_free and not left_free then
					self.nav_evade_side = 1
				elseif left_free and not right_free then
					self.nav_evade_side = -1
				else
					local dot = vmath.dot(to_target, vmath.vector3(1, 0, 0))
					self.nav_evade_side = (dot >= 0) and 1 or -1
				end
				self.nav_wall_tangent = nil
			end
			self.nav_evade_side_lock = self.nav_evade_side_lock_duration
		end
		self.nav_evading = true
		self.nav_evade_timer = 0

		-- ⚠️ NO resetear nav_stuck_timer aquí: el timer debe acumularse
		--    para que los niveles 2, 3, 4 puedan activarse.
	end

	-- Cambiar lado si lleva demasiado tiempo esquivando
	self.nav_evade_timer = self.nav_evade_timer + dt
	if self.nav_evade_timer >= EVADE_TIMEOUT then
		self.nav_evade_side = -self.nav_evade_side
		self.nav_evade_timer = 0
		self.nav_evade_side_lock = 0
	end

	self.nav_evade_side_lock = math.max(0, self.nav_evade_side_lock - dt)

	-- ═══════════════════════════════════════════
	-- Calcular dirección de movimiento según nivel de atasco
	-- ═══════════════════════════════════════════

	local move_dir
	local use_snap = true  -- por defecto, snap a 8 dirs

	if self.nav_stuck_level >= 4 then
		-- 🔴 N4: Dirección aleatoria, cicla cada 0.5s
		self.nav_random_timer = self.nav_random_timer + dt
		if self.nav_random_timer >= 0.5 then
			self.nav_random_timer = 0
			-- Elegir un ángulo aleatorio entre los 8 cardinales
			local angles = { 0, math.pi/4, math.pi/2, 3*math.pi/4, math.pi, -3*math.pi/4, -math.pi/2, -math.pi/4 }
			self.nav_random_angle = angles[math.random(1, #angles)]
		end
		move_dir = vmath.vector3(math.cos(self.nav_random_angle), math.sin(self.nav_random_angle), 0)
		use_snap = false  -- ya está en un cardinal, no snap

	elseif self.nav_stuck_level >= 3 then
		-- 🟠 N3: Alejarse del objetivo (dirección opuesta)
		move_dir = -dir_normalized
		use_snap = false  -- permitir escape libre, no forzar snap

	elseif self.nav_stuck_level >= 2 then
		-- 🟡 N2: Wall-following: deslizarse por la tangente de la pared
		--       hacia el objetivo (usando normal del raycast o evasión lateral)
		if self.nav_wall_tangent then
			move_dir = self.nav_wall_tangent
			use_snap = false  -- tangente debe ser paralela a la pared, sin snap
		else
			move_dir = vmath.vector3(-dir_normalized.y * self.nav_evade_side,
			                          dir_normalized.x * self.nav_evade_side, 0)
		end

	else
		-- 🟢 N1 (o evade normal): Blend forward + lateral
		--     Vector lateral = perpendicular a forward_dir
		local side_vec = vmath.vector3(-dir_normalized.y, dir_normalized.x, 0) * self.nav_evade_side
		local blend = 0.6  -- 60% lateral, 40% forward
		move_dir = dir_normalized * (1 - blend) + side_vec * blend
		if vmath.length(move_dir) > 0 then
			move_dir = vmath.normalize(move_dir)
		end
	end

	-- Snap a 8 direcciones (solo para niveles bajos donde el snap ayuda)
	if use_snap then
		move_dir = snap_to_eight_dirs(self, move_dir)
	else
		-- Aún necesitamos actualizar nav_dir_x/y para las animaciones
		if vmath.length(move_dir) > 0 then
			local d = vmath.normalize(move_dir)
			self.nav_dir_x = d.x
			self.nav_dir_y = d.y
		end
	end

	-- Mover
	local step = speed * dt
	go.set_position(my_pos + move_dir * step)

	return false
end

return M
