-- main/tasks.lua
-- ═══════════════════════════════════════════════════════
-- 🏆 SISTEMA DE TAREAS Y RANGOS (módulo puro, sin API Defold)
-- ═══════════════════════════════════════════════════════
--
--   Cuatro tareas; cada una completada suma un rango (skills):
--     1. exhibition   → 10 objetos expuestos (COMPLETED)
--     2. quiz         → 10 quizzes generales realizados, mín. 8 acertados
--     3. restoration  → 5 restauraciones realizadas, mín. 3 acertadas
--     4. pests        → 20 bichos eliminados
--
--   Con las 4 tareas → rango máximo (director) → el juego termina
--   (game_state.evaluate_tasks() lanza la secuencia de victoria).
--
--   ⚠️ Evaluación de quizzes "al finalizar todas las interacciones":
--      • quiz: las 10 interacciones generales terminan cuando TODOS los
--        NPCs quiz_general quedan completed=true (por acierto o por
--        agotar los 3 intentos — register_npc_failure lo marca).
--      • restoration: las 5 interacciones terminan cuando TODOS los
--        objetos con requires_restoration salen del estado RESTORATION
--        (por acierto o por el fallback de 3 fallos de la restauradora).
--      Después se comprueban los mínimos de aciertos (8/10 y 3/5).
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-15
-- ═══════════════════════════════════════════════════════

local npc_spawn_state = require "main.npc_spawn_state"
local collectibles_data = require "main.collectibles_data"

local M = {}

-- ⚙️ Umbrales de las tareas (fuente única — ajustar aquí si cambian)
M.EXHIBITION_TOTAL = 10       -- Objetos expuestos (task 1)
M.QUIZ_GENERAL_TOTAL = 10     -- Interacciones de quiz general (task 2)
M.QUIZ_GENERAL_MIN = 8        -- Mínimo de aciertos en quiz general
M.RESTORATION_TOTAL = 5       -- Interacciones de restauración (task 3)
M.RESTORATION_MIN = 3         -- Mínimo de aciertos en restauración
M.PESTS_MIN = 20              -- Mínimo de bichos eliminados (task 4)
M.TASK_COUNT = 4              -- Nº total de tareas (victoria = todas completadas)
M.RANK_MAX = 5                -- Rango máximo (director) = 1 + TASK_COUNT

-- IDs de las tareas (claves del resultado de get_status)
M.TASK_EXHIBITION = "exhibition"
M.TASK_QUIZ = "quiz"
M.TASK_RESTORATION = "restoration"
M.TASK_PESTS = "pests"

-- 🧑‍🤝‍🧑 ¿Todos los NPCs de quiz general han terminado sus interacciones?
-- (completed == true por acierto o por agotar los 3 intentos). Solo cuenta
-- NPCs registrados explícitamente como quiz_general (npc_spawn_state): los
-- quiz_restoration / quiz_false / no registrados quedan fuera.
-- ⚠️ Exige total >= QUIZ_GENERAL_TOTAL: npc_types se completa en el init de
-- cada NPC, así que con registros parciales (p. ej. durante el init del
-- nivel) la comparación finished == total no es fiable.
local function quizzes_finished(npc_progress)
	local total = 0
	local finished = 0
	for npc_id, progress in pairs(npc_progress) do
		if npc_spawn_state.get_npc_type(npc_id) == npc_spawn_state.NPC_TYPE_QUIZ_GENERAL then
			total = total + 1
			if progress and progress.completed then
				finished = finished + 1
			end
		end
	end
	return total >= M.QUIZ_GENERAL_TOTAL and finished == total
end

-- 💊 ¿Todos los objetos restaurables han terminado su interacción de
-- restauración? (tienen estado y no están en RESTORATION — acierto o
-- fallback de 3 fallos de la restauradora)
local function restorations_finished(items_status)
	local total = 0
	local finished = 0
	for id, item in pairs(collectibles_data.items) do
		if item.requires_restoration then
			total = total + 1
			local status = items_status[id]
			if status and status ~= "restoration" then
				finished = finished + 1
			end
		end
	end
	return total > 0 and finished == total
end

-- 📊 Calcula el estado de las 4 tareas desde el estado del juego.
-- @param state Tabla con:
--   items_status           → game_state "inventory_items_status" ({ item_id = state })
--   npc_progress           → game_state.npc_progress
--   task_quiz_total        → aciertos de quiz general
--   task_restoration_total → aciertos de restauración
--   task_bugs_total        → bichos eliminados
-- @return table  { [task_id] = boolean } — true = tarea completada
function M.get_status(state)
	-- 1. Catálogo y exposiciones: 10 objetos expuestos
	local exhibited = 0
	for _, status in pairs(state.items_status or {}) do
		if status == "completed" then
			exhibited = exhibited + 1
		end
	end
	local exhibition_done = exhibited >= M.EXHIBITION_TOTAL

	-- 2. Asistencia: 10 quizzes generales terminados y mín. 8 acertados
	local quiz_done = quizzes_finished(state.npc_progress or {})
		and (state.task_quiz_total or 0) >= M.QUIZ_GENERAL_MIN

	-- 3. Restauración: 5 interacciones terminadas y mín. 3 acertadas
	local restoration_done = restorations_finished(state.items_status or {})
		and (state.task_restoration_total or 0) >= M.RESTORATION_MIN

	-- 4. Control de plagas: mín. 20 bichos eliminados
	local pests_done = (state.task_bugs_total or 0) >= M.PESTS_MIN

	return {
		[M.TASK_EXHIBITION] = exhibition_done,
		[M.TASK_QUIZ] = quiz_done,
		[M.TASK_RESTORATION] = restoration_done,
		[M.TASK_PESTS] = pests_done,
	}
end

-- 🏅 Rango derivado: 1 (novato) + tareas completadas, máx. director.
-- Las condiciones de las tareas son monótonas (no decrecen), así que el
-- rango derivado es estable entre sesiones.
function M.get_rank(tasks_completed)
	return math.max(1, math.min(M.RANK_MAX, 1 + (tasks_completed or 0)))
end

return M
