-- main/persistence.lua
-- Sistema de guardado/carga para el juego del museo
-- Almacena progreso de NPCs, variables globales del jugador y estado del quiz
--
-- ═══════════════════════════════════════════════════════
-- 🚀 IMPORTANTE: ARQUITECTURA ACTUAL
-- ═══════════════════════════════════════════════════════
--
--   Este módulo solo proporciona I/O de bajo nivel:
--     • guardar_progreso() → sys.save()
--     • cargar_progreso()  → sys.load()
--
--   Las operaciones de alto nivel (set_global, register_npc, etc.)
--   están en game_state.lua, que mantiene los datos en RAM y
--   solo llama a persistence para flush() periódico.
--
--   Si necesitas acceso a datos desde cualquier script, usa game_state:
--     game_state.get_global("health")
--     game_state.set_global("health", 80)
--     game_state.add_to_global("task_bugs_total", 1)
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-15
-- ═══════════════════════════════════════════════════════

local config = require "main.config"

-- 🔧 DEBUG granular (sistema make_log, ver main/config.lua):
--    true  = loguea cuando M.DEBUG esté activo
--    false = silenciado (por defecto)
local DEBUG_PERSISTENCE = false
local dprint = config.make_log(DEBUG_PERSISTENCE)

local APPLICATION_NAME = "mi_juego_museo"
local SAVE_FILENAME = "savegame.dat"

-- Valores por defecto para las variables globales del juego
local DEFAULT_GLOBALS = {
	-- Variables del jugador
	health = 100,
	skills = 1,
	stamina = 100,

	-- Variables generales del juego
	score = 0,
	language = "es",
	temp_units = "c",             -- 🌡️ Unidad de temperatura del HUD: "c" (°C) o "f" (°F). Preferencia del jugador.
	task_quiz_total = 0,        -- Total de quizzes superados
	task_restoration_total = 0, -- Total de restauraciones completadas

	-- 🗑️ ELIMINADAS: collectibles_items_total, collectibles_pal_total, etc.
	-- Los contadores de coleccionables ahora se calculan desde inventory_core
	-- usando items_status por ID de objeto (ver collectibles_data.lua)

	inventory_items_status = {}, -- Estado de cada objeto coleccionable por ID
	-- 🏆 Tareas completadas (0..4): cada una suma un rango (skills). Se deriva
	-- en game_state.evaluate_tasks() desde las condiciones reales (monótonas).
	tasks_completed = 0,
	-- 🗄️ Mapeo persistido slot→objeto ({ [slot_url] = item_id }): restaura la
	-- posición visual de los objetos depositados en estanterías/vitrinas al recargar
	inventory_furniture_slots = {},
	-- ⏱️ Segundos restantes del Timer A (storage) al guardar; se reanuda al cargar.
	-- 0 = sin timer pendiente.
	inventory_storage_remaining = 0,

	-- 🎓 One-shot educativo mostrado (rule_display_case): evita repetir el aviso
	-- de "ingresa todos los objetos en su vitrina" en partidas posteriores
	rule_display_case_shown = false,

	task_bugs_total = 0, -- Total de bichos eliminados
	max_spray = 100, -- Cantidad total de spray
	spray_current = 100, -- Cantidad variable de spray

	-- Audio
	audio_volume = 1.0, -- Volumen general del juego (0.0 - 1.0)
	audio_enabled = true -- Audio activado/desactivado
}

-- Nueva configuración: lista de NPCs con formato npc_XX
-- Soporta hasta 99 NPCs (npc_01 a npc_99)
local NPC_COUNT = 20  -- Aumenta este número según necesites
local NPC_PREFIX = "npc_"

-- Valores por defecto para el progreso de los NPCs (nuevo formato)
local function get_default_npc_progress()
	local npc_progress = {}

	-- Generar NPCs con formato npc_01, npc_02, ..., npc_20
	for i = 1, NPC_COUNT do
		local npc_id = string.format("%s%02d", NPC_PREFIX, i)  -- npc_01, npc_02, etc.
		npc_progress[npc_id] = {
			attempt = 1,
			completed = false,
			available_after = 0,
			unlocked = (i <= 3)  -- Los primeros 3 NPCs están desbloqueados por defecto
		}
	end

	-- También soportar NPCs especiales con nombres personalizados si es necesario
	-- npc_progress["npc_boss"] = { attempt = 1, completed = false, available_after = 0, unlocked = false }

	return npc_progress
end

-- Obtiene la ruta del archivo según el sistema operativo
local function get_save_path()
	return sys.get_save_file(APPLICATION_NAME, SAVE_FILENAME)
end

-- Convierte IDs antiguos (npc1, npc2) al nuevo formato (npc_01, npc_02)
local function migrate_old_npc_id(old_id)
	if not old_id then return nil end

	-- Detectar si es formato antiguo "npc1", "npc2", etc.
	local number = old_id:match("^npc(%d+)$")
	if number then
		return string.format("%s%02d", NPC_PREFIX, tonumber(number))
	end

	-- Si ya está en nuevo formato o es especial, devolver igual
	return old_id
end

-- Migrar datos antiguos al nuevo formato
local function migrate_old_data(datos)
	if not datos or not datos.npc_progress then
		return datos
	end

	local migrated = false
	local new_npc_progress = {}

	-- Migrar cada entrada de npc_progress
	for npc_id, progress in pairs(datos.npc_progress) do
		local new_id = migrate_old_npc_id(npc_id)

		if new_id ~= npc_id then
			dprint(string.format("Migrando NPC: %s -> %s", npc_id, new_id))
			migrated = true
		end

		-- Asegurar que todos los campos necesarios existan
		new_npc_progress[new_id] = {
			attempt = progress.attempt or 1,
			completed = progress.completed or false,
			available_after = progress.available_after or progress.available_at or 0,
			unlocked = progress.unlocked or (tonumber(new_id:match("%d+")) or 0) <= 3  -- Los primeros 3 desbloqueados
		}
	end

	-- Asegurar que todos los NPCs del nuevo formato existan
	local default_progress = get_default_npc_progress()
	for npc_id, default_data in pairs(default_progress) do
		if not new_npc_progress[npc_id] then
			new_npc_progress[npc_id] = default_data
			dprint(string.format("Añadiendo nuevo NPC: %s", npc_id))
			migrated = true
		end
	end

	if migrated then
		datos.npc_progress = new_npc_progress
		datos.version = 2  -- Actualizar versión del formato
		dprint("Migración completada al nuevo formato de NPCs (npc_XX)")
	end

	return datos
end

-- Guarda los datos completos en el disco
-- @param datos Tabla con las siguientes claves:
--   - globals: variables globales del juego
--   - npc_progress: progreso de cada NPC
--   - current_quiz: estado del quiz en curso (si existe)
--   - last_save_time: timestamp del último guardado
local function guardar_progreso(datos)
	local path = get_save_path()

	-- Añadir timestamp de guardado y versión
	datos.last_save_time = os.time()
	datos.version = 2  -- Formato actual

	-- sys.save convierte la tabla de Lua en un archivo binario
	local success = sys.save(path, datos)

	if not success then
		dprint("Error: No se pudo guardar la partida en: " .. path)
		return false
	end

	dprint("Partida guardada correctamente en: " .. path)
	return true
end

-- ============================================
-- HELPERS DE cargar_progreso
-- ============================================

-- Crea una estructura de datos nueva con valores por defecto (primera partida)
local function create_fresh_save()
	local datos = {
		globals = {},
		npc_progress = {},
		current_quiz = {
			pool_id = "",
			questions_answered = {},
			current_attempts = 0,
			last_question_id = ""
		},
		version = 2,
		first_play = true
	}

	for key, value in pairs(DEFAULT_GLOBALS) do
		datos.globals[key] = value
	end

	datos.npc_progress = get_default_npc_progress()

	dprint("No se encontró partida guardada. Creando nueva partida con valores por defecto.")
	return datos
end

-- Verifica que todas las claves de DEFAULT_GLOBALS existan en datos.globals
local function ensure_globals(datos)
	if not datos.globals then
		datos.globals = {}
	end

	for key, value in pairs(DEFAULT_GLOBALS) do
		if datos.globals[key] == nil then
			datos.globals[key] = value
			dprint("Inicializando variable faltante en globals: " .. key .. " = " .. tostring(value))
		end
	end
end

-- Verifica que todos los NPCs existan con todos sus campos
local function ensure_npc_progress(datos)
	if not datos.npc_progress then
		datos.npc_progress = get_default_npc_progress()
		return
	end

	-- Sincronizar campos de cada NPC en el nuevo formato
	for i = 1, NPC_COUNT do
		local npc_id = string.format("%s%02d", NPC_PREFIX, i)

		if not datos.npc_progress[npc_id] then
			datos.npc_progress[npc_id] = {
				attempt = 1,
				completed = false,
				available_after = 0,
				unlocked = (i <= 3)
			}
			dprint("Añadiendo NPC faltante: " .. npc_id)
		else
			local progress = datos.npc_progress[npc_id]
			if progress.attempt == nil then progress.attempt = 1 end
			if progress.completed == nil then progress.completed = false end
			if progress.available_after == nil then
				progress.available_after = progress.available_at or 0
			end
			if progress.unlocked == nil then progress.unlocked = (i <= 3) end
		end
	end

	-- También preservar NPCs especiales que no sigan el formato npc_XX
	for npc_id, progress in pairs(datos.npc_progress) do
		if not npc_id:match("^" .. NPC_PREFIX .. "%d%d$") then
			if progress.attempt == nil then progress.attempt = 1 end
			if progress.completed == nil then progress.completed = false end
			if progress.available_after == nil then progress.available_after = 0 end
			if progress.unlocked == nil then progress.unlocked = true end
		end
	end
end

-- Verifica que current_quiz tenga la estructura esperada
local function ensure_quiz_state(datos)
	if not datos.current_quiz then
		datos.current_quiz = {
			pool_id = "",
			questions_answered = {},
			current_attempts = 0,
			last_question_id = ""
		}
	end
end

-- Carga los datos del disco
-- @return Tabla con los datos guardados, o valores por defecto si no existe archivo
local function cargar_progreso()
	local path = get_save_path()
	local datos = sys.load(path)

	if not datos or next(datos) == nil then
		return create_fresh_save()
	end

	dprint("Partida cargada correctamente desde: " .. path)

	-- Migración de datos antiguos si es necesario
	if not datos.version or datos.version < 2 then
		dprint("Migrando datos desde versión " .. (datos.version or "desconocida") .. " a versión 2")
		datos = migrate_old_data(datos)
	end

	-- Verificar integridad de cada sección
	ensure_globals(datos)
	ensure_npc_progress(datos)
	ensure_quiz_state(datos)

	return datos
end

-- Obtener lista de todos los NPCs disponibles
-- @return Tabla con todos los IDs de NPCs
local function get_all_npc_ids()
	local npc_ids = {}
	for i = 1, NPC_COUNT do
		table.insert(npc_ids, string.format("%s%02d", NPC_PREFIX, i))
	end
	return npc_ids
end

-- Exportar funciones para usar en otros scripts
return {
	guardar_progreso = guardar_progreso,
	cargar_progreso = cargar_progreso,
	get_all_npc_ids = get_all_npc_ids,
	NPC_PREFIX = NPC_PREFIX,
	NPC_COUNT = NPC_COUNT
}
