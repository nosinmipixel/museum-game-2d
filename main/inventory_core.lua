-- main/inventory_core.lua
-- ═══════════════════════════════════════════════════════
-- 🔄 MÁQUINA DE ESTADOS DEL SISTEMA DE INVENTARIO
-- ═══════════════════════════════════════════════════════
--
--   ⚠️  SIN DEPENDENCIAS DE DEFOLD API (go, msg, sys)
--       Se puede usar desde cualquier script Lua sin riesgos.
--
--   Estados del ciclo de vida de cada objeto:
--     PICKUP       → El objeto aparece en el mundo, esperando clic
--     RESTORATION  → El objeto necesita restauración (si requires_restoration)
--     COLLECTED    → El objeto ha sido recogido, pendiente de depósito en estantería
--     STORAGE      → El objeto está depositado en una estantería (timer activo)
--     EXHIBITION   → El objeto está listo para vitrina (timer cumplido)
--     COMPLETED    → El objeto está en la vitrina, ciclo terminado
--
--   Flujo completo (objeto sin restauración):
--     [Timer inicial 5s] → PICKUP (clic) → COLLECTED (depósito) → STORAGE (timer Ns) → EXHIBITION (vitrina) → COMPLETED
--
--   Flujo completo (objeto con restauración):
--     [Timer inicial 5s] → PICKUP (clic) → RESTORATION (NPC restaura) → STORAGE (timer Ns) → EXHIBITION (vitrina) → COMPLETED
--
--   Solo hay DOS timers en todo el sistema:
--     1. Timer inicial (~5s, configurable desde main/config.lua →
--        M.balance.initial_spawn_delay): da tiempo al jugador a explorar
--        antes de que aparezca el primer objeto.
--     2. Timer de STORAGE (TIMER_DURATION segundos, configurable desde
--        main/config.lua → M.balance.storage_timer_duration):
--        Tras depositar el objeto en la estantería, da tiempo al jugador
--        para hacer otras tareas antes de que el objeto esté listo para vitrina.
--
--   RESTORATION no tiene timer: la restauración la gestiona un NPC
--   (on_restoration_completed) que avanza el estado instantáneamente.
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-15
-- ═══════════════════════════════════════════════════════

local M = {}

-- ⚙️ Configuración central (main/config.lua → M.balance): los timers del
-- flujo de coleccionables se ajustan desde un único punto (preprod/prod).
-- Módulo puro: config.lua no usa API Defold, así que el require es seguro.
local config = require "main.config"

-- ═══════════════════════════════════════════════════════
-- 🎯 DEFINICIÓN DE ESTADOS
-- ═══════════════════════════════════════════════════════
M.STATES = {
	PICKUP      = "pickup",       -- En el mundo, esperando recogida
	RESTORATION = "restoration",  -- En proceso de restauración
	COLLECTED   = "collected",    -- Recogido, pendiente de depósito en estantería
	STORAGE     = "storage",      -- Depositado en estantería (timer activo)
	EXHIBITION  = "exhibition",   -- Listo para vitrina
	COMPLETED   = "completed",    -- Exhibido permanentemente
}

-- Duración de los timers en segundos — configuradas en main/config.lua
-- → M.balance (punto único preprod/prod; el `or` conserva el valor anterior):
--   • storage_timer_duration → Timer A: espera en STORAGE antes de EXHIBITION
--     (preprod 10s · PROD 300s)
--   • spawn_delay → Timer B: cooldown tras completar objeto antes de spawnear
--     el siguiente
local TIMER_DURATION = config.balance.storage_timer_duration or 10
local SPAWN_DELAY = config.balance.spawn_delay or 5

-- ═══════════════════════════════════════════════════════
-- 🏗️ INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════

--- Inicializa el core con datos de persistencia.
--- @param persistence_data table|nil  Datos cargados de sys.load()
--- @return table  Instancia del core lista para usar
function M.init(persistence_data)
	local self = {}

	-- items_status: tabla clave-valor { item_id = "state_string" }
	-- Ej: { pal_plaqueta = "completed", neo_brazalete = "storage", ... }
	self.items_status = {}

	if persistence_data and persistence_data.items_status then
		-- Cargar estado desde persistencia
		for id, state in pairs(persistence_data.items_status) do
			self.items_status[id] = state
		end
	end

	-- Timer A: espera en STORAGE antes de EXHIBITION
	self.current_timer = 0
	self.timer_active = false

	-- Timer B: cooldown tras completar un objeto antes del siguiente spawn
	self.spawn_timer_remaining = 0
	self.spawn_timer_active = false

	self.current_item_id = nil

	return self
end

-- ═══════════════════════════════════════════════════════
-- 🔍 OBTENER SIGUIENTE OBJETO PENDIENTE
-- ═══════════════════════════════════════════════════════

--- Encuentra el primer objeto que no esté COMPLETED.
--- Devuelve nil si todos los objetos están completados (juego terminado).
--- @param self table  Instancia del core
--- @return table|nil  Datos del item (de collectibles_data) o nil
function M.get_next_pending_item(self)
	local collectibles_data = require "main.collectibles_data"
	local sorted_items = collectibles_data.get_sorted_items()

	for _, item in ipairs(sorted_items) do
		local status = self.items_status[item.id]
		if not status or status == M.STATES.PICKUP then
			-- No iniciado o en pickup: devolverlo
			return item
		end
		-- Si está en cualquier otro estado que no sea COMPLETED
		if status ~= M.STATES.COMPLETED then
			return item
		end
	end

	return nil
end

--- Obtiene el estado actual de un objeto por su ID.
--- @param self table  Instancia del core
--- @param item_id string  ID del objeto
--- @return string|nil  Estado actual o nil si no tiene estado
function M.get_item_status(self, item_id)
	return self.items_status[item_id]
end

-- ═══════════════════════════════════════════════════════
-- 🧮 CALCULAR SIGUIENTE ESTADO
-- ═══════════════════════════════════════════════════════

--- Calcula el siguiente estado después de PICKUP.
--- @param self table  Instancia del core
--- @param item_data table  Datos del item (con requires_restoration)
--- @return string  Siguiente estado (RESTORATION o STORAGE)
function M.calculate_next_state(self, item_data)
	if item_data.requires_restoration then
		return M.STATES.RESTORATION
	else
		return M.STATES.STORAGE
	end
end

-- ═══════════════════════════════════════════════════════
-- ✅ VALIDAR INTERACCIÓN CON MUEBLE
-- ═══════════════════════════════════════════════════════

--- Valida si el jugador puede interactuar con un mueble.
--- @param self table  Instancia del core
--- @param furniture_type string  "shelf" o "showcase"
--- @param furniture_period string  Periodo del mueble
--- @return string|nil  Acción permitida o razón de rechazo
function M.validate_furniture_interaction(self, furniture_type, furniture_period)
	if not self.current_item_id then
		return "no_item"  -- No hay objeto activo
	end

	local collectibles_data = require "main.collectibles_data"
	local item = collectibles_data.items[self.current_item_id]
	if not item then
		return "invalid_item"
	end

	local current_state = self.items_status[self.current_item_id]

	-- 🛠️ RESTORATION: la pieza aún no ha completado la restauración, ningún
	-- mueble (estantería o vitrina) la acepta hasta pasar por la restauradora.
	-- Distinto de "invalid_state" (genérico): el HUD muestra error_needs_restoration.
	if current_state == M.STATES.RESTORATION then
		return "needs_restoration"
	end

	if furniture_type == "shelf" then
		-- Estantería: acepta objetos en COLLECTED (recogido, sin depositar) o STORAGE (ya depositado)
		if current_state == M.STATES.COLLECTED or current_state == M.STATES.STORAGE then
			-- Verificar que el periodo coincide
			if item.period ~= furniture_period then
				return "wrong_period"
			end
			return "deposit"  -- Depositar en estantería
		elseif current_state == M.STATES.EXHIBITION then
			-- El objeto está listo para vitrina, no para estantería
			return "wrong_furniture"  -- Usa una vitrina, no una estantería
		end
	elseif furniture_type == "showcase" then
		-- Vitrina: acepta objetos en EXHIBITION (listos para vitrina)
		if current_state == M.STATES.EXHIBITION then
			if item.period ~= furniture_period then
				return "wrong_period"
			end
			return "complete"  -- Completar ciclo
		end
	end

	return "invalid_state"
end

-- ═══════════════════════════════════════════════════════
-- ⏱️ TRANSICIÓN CON TEMPORIZADOR
-- ═══════════════════════════════════════════════════════

--- Inicia una transición que requiere temporizador.
--- @param self table  Instancia del core
--- @param new_state string  Estado al que se transiciona
--- @return boolean  true si se inició el timer
function M.transition_to(self, new_state)
	-- El timer SOLO se inicia para STORAGE (espera de 5 min antes de EXHIBITION)
	-- RESTORATION y otros estados son instantáneos (sin timer)
	if new_state == M.STATES.STORAGE then
		self.current_timer = TIMER_DURATION
		self.timer_active = true
		if self.current_item_id then
			self.items_status[self.current_item_id] = new_state
		end
		return true
	end

	-- Transiciones sin timer (inmediatas)
	if self.current_item_id then
		self.items_status[self.current_item_id] = new_state
	end
	return false
end

-- ═══════════════════════════════════════════════════════
-- ⏰ UPDATE DEL TIMER
-- ═══════════════════════════════════════════════════════

--- Actualiza los timers. Debe llamarse desde update() del script.
--- @param self table  Instancia del core
--- @param dt number  Delta time del frame
--- @return boolean, boolean  timer_expired, spawn_expired
function M.update(self, dt)
	local timer_expired = false
	local spawn_expired = false

	-- Timer A: espera en STORAGE antes de EXHIBITION
	if self.timer_active then
		self.current_timer = self.current_timer - dt
		if self.current_timer <= 0 then
			self.current_timer = 0
			self.timer_active = false
			-- ⚠️  NO auto-avanzamos el estado aquí.
			--     El manager decide qué hacer en on_timer_expired().
			timer_expired = true
		end
	end

	-- Timer B: cooldown tras completar objeto antes del siguiente spawn
	if self.spawn_timer_active then
		self.spawn_timer_remaining = self.spawn_timer_remaining - dt
		if self.spawn_timer_remaining <= 0 then
			self.spawn_timer_remaining = 0
			self.spawn_timer_active = false
			spawn_expired = true
		end
	end

	return timer_expired, spawn_expired
end

-- ═══════════════════════════════════════════════════════
-- ⏱️ GESTIÓN DEL TIMER B (COOLDOWN DE SPAWN)
-- ═══════════════════════════════════════════════════════

--- Inicia el Timer B (cooldown antes de spawneaer el siguiente objeto).
function M.start_spawn_timer(self)
	self.spawn_timer_remaining = SPAWN_DELAY
	self.spawn_timer_active = true
end

--- Cancela el Timer B (cuando el jugador completa antes de que expire).
function M.cancel_spawn_timer(self)
	self.spawn_timer_remaining = 0
	self.spawn_timer_active = false
end

-- ═══════════════════════════════════════════════════════
-- 💾 PERSISTENCIA
-- ═══════════════════════════════════════════════════════

--- Guarda el estado de finalización de un objeto.
--- @param self table  Instancia del core
--- @return table  Estado plano para persistir
function M.get_save_data(self)
	return {
		items_status = self.items_status,
	}
end

--- Marca un ítem como completado y lo persiste.
--- @param self table  Instancia del core
function M.save_completion(self)
	if self.current_item_id then
		self.items_status[self.current_item_id] = M.STATES.COMPLETED
	end
end

--- Guarda el estado actual del ítem activo en persistencia.
--- @param self table  Instancia del core
function M.save_current_state(self)
	-- El estado ya está almacenado en items_status
	-- Este método es un alias semántico para claridad
	return self.items_status[self.current_item_id]
end

return M
