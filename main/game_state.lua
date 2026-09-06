-- main/game_state.lua
-- ═══════════════════════════════════════════════════════
-- 🧠 ESTADO GLOBAL DEL JUEGO
-- ═══════════════════════════════════════════════════════
--
--   Módulo compartido (puro + persistencia): variables
--   globales (salud, inventario, tareas, idioma...), acceso
--   por get/set, guardado/carga y reinicio. Usado por casi
--   todos los scripts del juego.
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-15
-- ═══════════════════════════════════════════════════════

local persistence = require "main.persistence"
local config = require "main.config"
local tasks = require "main.tasks"  -- 🏆 Tareas y rangos (módulo puro)
local collectibles_data = require "main.collectibles_data"  -- 🔧 DEV: debug_force_victory

-- 🔧 DEBUG granular (sistema make_log, ver main/config.lua):
--    true  = loguea cuando M.DEBUG esté activo
--    false = silenciado (por defecto)
local DEBUG_GAME_STATE = false
local dprint = config.make_log(DEBUG_GAME_STATE)

local M = {}

-- Variables globales del juego (valores por defecto)
M.globals = {
	health = 100,
	skills = 1,
	stamina = 100,
	score = 0,
	language = "es",
	task_quiz_total = 0,
	task_restoration_total = 0,
	-- 🏆 Nº de tareas completadas (0..4): cada una suma un rango (skills).
	--    Se deriva en evaluate_tasks() desde las condiciones reales (monótonas).
	tasks_completed = 0,

	-- 🗑️ ELIMINADAS: collectibles_items_total, collectibles_pal_total, etc.
	-- Los contadores ahora se calculan desde inventory_core en tiempo real
	inventory_items_status = {},
	-- 🗄️ Mapeo persistido slot→objeto ({ [slot_url] = item_id }): restaura la
	-- posición visual de los objetos depositados en estanterías/vitrinas al recargar
	inventory_furniture_slots = {},
	-- ⏱️ Segundos restantes del Timer A (storage) al guardar; se reanuda al cargar
	inventory_storage_remaining = 0,

	-- 🎓 One-shot educativo mostrado (rule_display_case)
	rule_display_case_shown = false,

	task_bugs_total = 0,
	cat_food_count = 0,
	max_spray = 100,
	spray_current = 100,
	-- 🪺 Cargas de insecticida especial para destruir nidos (0..insecticide_max)
	nest_insecticide = 0,

	-- Audio
	audio_volume = 1.0,
	audio_enabled = true,
	sfx_volume = 1.0, -- 🎛️ Volumen del grupo de efectos/voces (0.0 - 1.0)

	-- 🌡️ CLIMA: Temperatura y Humedad (valores iniciales configurables en
	-- main/config.lua → M.balance.temp_ideal / hr_ideal)
	temp_raw = config.balance.temp_ideal or 21.0,      -- Temperatura actual (°C)
	hr_raw = config.balance.hr_ideal or 50.0,          -- Humedad relativa actual (%)
	temp_previous = config.balance.temp_ideal or 21.0, -- Temperatura del frame anterior (para tendencia)
	hr_previous = config.balance.hr_ideal or 50.0,     -- Humedad del frame anterior (para tendencia)
	temp_trending_up = false,  -- ¿Temperatura subiendo?
	hr_trending_up = false,    -- ¿Humedad subiendo?
	climate_warning_level = 0, -- 0=OK verde, 1=mejorando naranja, 2=empeorando rojo
	temp_ok = true,            -- ¿Temperatura en rango ideal (20-22°C)?
	hr_ok = true               -- ¿Humedad en rango ideal (45-55%)?
}

-- Progreso de NPCs
M.npc_progress = {}

-- Callbacks para cuando cambian las variables
M.callbacks = {}

-- Listeners para cuando se desbloquea un NPC (p. ej. npc_spawn_manager)
M.npc_unlock_listeners = {}

-- Flag de datos pendientes de guardado (evita escritura a disco en cada cambio)
M._dirty = false

-- 🗣️ Diálogo con NPC activo (en RAM, SIN persistencia): true mientras el
--    jugador está en una interacción (diálogo o quiz) y está bloqueado
--    (lock_dialog). Lo gestiona el dialogue_manager (true al iniciar, false
--    al terminar/cancelar); el HUD lo lee por polling para PAUSAR los
--    recordatorios y encolar avisos durante la interacción. NO se persiste a
--    propósito: es estado transitorio — un save a mitad de diálogo no debe
--    dejar el flag pegado al recargar.
M.dialog_active = false

-- Flag: true cuando se cargó un archivo de guardado real (no fresh start)
M._has_save_data = false

-- Estado del quiz en curso (en RAM, sin I/O)
M.quiz_state = {
	pool_id = "",
	questions_answered = {},
	current_attempts = 0,
	last_question_id = ""
}

-- Registrar callback para cambios
function M.register_callback(var_name, callback)
	if not M.callbacks[var_name] then
		M.callbacks[var_name] = {}
	end
	table.insert(M.callbacks[var_name], callback)
end

-- Notificar cambios
function M.notify_callbacks(var_name, old_value, new_value)
	local list = M.callbacks[var_name]
	if not list then return end
	-- Iterar en REVERSA para permitir la retirada segura de callbacks muertos.
	-- 🐛 FIX (Ago 2026): los callbacks capturan el self del componente que los
	-- registró (p. ej. player_spray). Al descargar level_01 (victoria → Nueva
	-- partida) el componente muere pero la closure permanece aquí; el siguiente
	-- set_global disparaba "attempt to index a nil value" (__newindex sobre un
	-- self destruido) y en cada recarga del nivel se acumulaba OTRO callback.
	-- Con pcall + retirada, un callback muerto se auto-elimina tras el primer
	-- error (y los callbacks restantes siguen ejecutándose, antes un fallo
	-- abortaba la lista entera).
	for i = #list, 1, -1 do
		local ok, err = pcall(list[i], var_name, old_value, new_value)
		if not ok then
			print("[GameState] ❌ Callback '" .. tostring(var_name) .. "' eliminado tras error: " .. tostring(err))
			table.remove(list, i)
		end
	end
end

-- ═══════════════════════════════════════════════════════
-- 🏆 TAREAS, RANGOS Y VICTORIA
-- ═══════════════════════════════════════════════════════

-- Listeners de victoria: se llaman (con pcall) la primera vez que las 4
-- tareas quedan completadas. Los registra la GUI de victoria (bootstrap).
M.victory_listeners = {}

-- Flag RAM anti-doble disparo: la victoria se lanza UNA vez por sesión,
-- solo ante una transición real a las 4 tareas (no al cargar partida).
M._victory_triggered = false

-- Registrar listener de victoria (recibe el nº de tareas completadas)
function M.on_victory(callback)
	table.insert(M.victory_listeners, callback)
end

-- 🏆 Evalúa las 4 tareas desde el estado actual y actualiza tasks_completed
-- y el rango (skills = 1 + tareas completadas, máx. director). Idempotente
-- y barato (itera tablas pequeñas): se llama tras cada evento relevante EN
-- SESIÓN (quiz → register_npc_success/failure, bichos → add_to_global,
-- exposición/restauración → save_inventory_state). NO se llama al cargar
-- partida: el conteo persistido es monótono (solo sube) y se auto-corrige
-- al alza con el siguiente evento en sesión.
-- Al completar las 4 → lanza la secuencia de victoria SOLO ante una
-- transición real (count > prev, una vez por sesión): cargar una partida ya
-- ganada NO la re-muestra (decisión de diseño — el jugador ya la vio).
function M.evaluate_tasks()
	local status = tasks.get_status({
		items_status = M.globals.inventory_items_status or {},
		npc_progress = M.npc_progress or {},
		task_quiz_total = M.globals.task_quiz_total or 0,
		task_restoration_total = M.globals.task_restoration_total or 0,
		task_bugs_total = M.globals.task_bugs_total or 0,
	})

	local count = 0
	for _, done in pairs(status) do
		if done then count = count + 1 end
	end

	-- Monótono: las condiciones subyacentes nunca decrecen, así que el conteo
	-- derivado es estable entre sesiones (no hace falta persistir por tarea).
	-- ⚠️ SOLO se incrementa: en el evaluate de init los tipos de NPC pueden
	-- estar aún parcialmente registrados (quiz subestima) — decrementar aquí
	-- corrompería un guardado.
	local prev = M.globals.tasks_completed or 0
	local just_completed_all = (count >= tasks.TASK_COUNT)
		and (count > prev)
		and not M._victory_triggered

	if count > prev then
		dprint("🏆 Tarea(s) completada(s): " .. prev .. " → " .. count)
		M.set_global("tasks_completed", count)
		M.set_global("skills", tasks.get_rank(count))
	end

	-- 🎉 Victoria: TODAS las tareas completadas (rango máximo = director).
	-- SOLO ante una TRANSICIÓN real en sesión (count > prev): cargar una
	-- partida ya ganada NO relanza la victoria — el jugador la vio cuando la
	-- consiguió. Al cargar, quiz subestima por los tipos de NPC en init, así
	-- que además es imposible dispararse aquí de forma espuria.
	if just_completed_all then
		M._victory_triggered = true
		dprint("🏆 ¡Victoria! Todas las tareas completadas — lanzando secuencia de fin de juego")
		-- Los listeners viven en gui_scripts de bootstrap que se comunican por
		-- mensajes; un error silencioso dejaría la victoria sin GUI (lección de
		-- Ago 2026). xpcall con logueo: el error sale a consola en vez de tragarlo.
		for _, cb in ipairs(M.victory_listeners) do
			xpcall(cb, function(e)
				print("[VICTORY] ❌ ERROR en listener de victoria: " .. tostring(e))
				print(debug.traceback("", 2))
				return e
			end, count)
		end
	end
	return count
end

-- 🔧 DEV (atajo de pruebas, key_n con config.DEV_MODE): simular la victoria
-- completa. Marca las condiciones subyacentes de las 4 tareas y llama a
-- evaluate_tasks(): count=4 > prev → la secuencia de victoria REAL se dispara
-- (listener → pause + GUI), ejerciendo exactamente el mismo camino que una
-- victoria lograda jugando. ⚠️ El progreso queda marcado como ganado y se
-- persiste; para volver a probar desde cero: botón "Nueva partida" o tecla R.
function M.debug_force_victory()
	-- 🔄 Forzar la TRANSICIÓN: si el save ya tenía 4/4 (de un intento anterior),
	-- count > prev sería falso y la victoria no se re-dispararía. Al resetear
	-- aquí, el atajo SIEMPRE lanza la secuencia (herramienta de pruebas).
	M.globals.tasks_completed = 0
	M._victory_triggered = false

	-- Tareas 1 y 3: todos los objetos → completed (expuestos y fuera de restauración)
	for id in pairs(collectibles_data.items) do
		M.globals.inventory_items_status[id] = "completed"
	end
	-- Tarea 2: todos los NPCs completados (los quiz_general quedan finished == total)
	for _, progress in pairs(M.npc_progress) do
		progress.completed = true
	end
	-- Mínimos de aciertos (tareas 2 y 3) y bichos (tarea 4)
	M.globals.task_quiz_total = math.max(M.globals.task_quiz_total or 0, tasks.QUIZ_GENERAL_MIN)
	M.globals.task_restoration_total = math.max(M.globals.task_restoration_total or 0, tasks.RESTORATION_MIN)
	M.globals.task_bugs_total = math.max(M.globals.task_bugs_total or 0, tasks.PESTS_MIN)
	dprint("🔧 DEV: victoria forzada — condiciones de las 4 tareas marcadas, evaluando...")
	M.evaluate_tasks()
end

-- Cargar estado guardado de manera limpia
function M.load()
	local data = persistence.cargar_progreso()

	if data.globals then
		for key, value in pairs(data.globals) do
			M.globals[key] = value
		end
	end

	-- Sincronizamos con la estructura real devuelta por persistence
	if data.npc_progress and type(data.npc_progress["npc_01"]) == "table" then
		M.npc_progress = data.npc_progress
	else
		M.init_default_npc_progress()
	end

	-- Cargar estado del quiz si existe
	if data.current_quiz then
		M.quiz_state = {
			pool_id = data.current_quiz.pool_id or "",
			questions_answered = data.current_quiz.questions_answered or {},
			current_attempts = data.current_quiz.current_attempts or 0,
			last_question_id = data.current_quiz.last_question_id or ""
		}
	end

	-- Detectar si se cargó un archivo real o es un fresh start
	-- persistence.cargar_progreso() marca first_play=true solo cuando
	-- no existe archivo de guardado en disco
	M._has_save_data = not data.first_play

	dprint("Estado del juego cargado correctamente. Save data: " .. tostring(M._has_save_data))
end

-- Inicializar progreso por defecto de NPCs con nombres unificados (available_after)
function M.init_default_npc_progress()
	M.npc_progress = {}

	for _, npc_id in ipairs(persistence.get_all_npc_ids()) do
		M.npc_progress[npc_id] = {
			attempt = 1,
			completed = false,
			available_after = 0,
			unlocked = (tonumber(npc_id:match("%d+")) or 0) <= 3,
			-- 💬 Charla de ambiente (npc_XX_talk_N): índice de alternancia
			--    0-based. Se persiste con el resto del progreso en el savegame.
			talk_index = 0
		}
	end
end

-- ═══════════════════════════════════════════════════════
-- 🚀 GUARDADO DIFERIDO (LAZY SAVE)
-- ═══════════════════════════════════════════════════════
--
--   save() → solo marca datos como "sucios" (dirty flag).
--   flush() → escribe a disco SOLO si hay cambios pendientes.
--
--   Esto elimina el cuello de botella de I/O que ocurría al
--   escribir a disco en cada partícula de spray disparada.
--
--   main.script se encarga de llamar a flush() periódicamente
--   cada ~5 segundos y al cerrar el juego.
-- ═══════════════════════════════════════════════════════

-- Marcar datos como pendientes de guardado (sin I/O)
function M.save()
	M._dirty = true
	return true
end

-- Escribir a disco solo si hay cambios pendientes
function M.flush()
	if not M._dirty then
		return false
	end

	local data = {
		globals = M.globals,
		npc_progress = M.npc_progress,
		current_quiz = M.quiz_state,
		version = 1,
		last_save = os.time()
	}
	persistence.guardar_progreso(data)
	M._dirty = false
	dprint("Estado del juego guardado en disco")
	return true
end

-- Comprobar si un NPC está disponible para hablar
function M.is_npc_available(npc_id)
	local progress = M.npc_progress[npc_id]
	if not progress then return false end
	if progress.completed then return false end
	if progress.attempt > 3 then return false end

	-- Verificar cooldown
	if progress.available_after and progress.available_after > os.time() then
		return false
	end

	return true
end

-- Registrar fallo de NPC
function M.register_npc_failure(npc_id)
	local progress = M.npc_progress[npc_id]
	if progress then
		progress.attempt = progress.attempt + 1
		if progress.attempt > 3 then
			progress.completed = true
		else
			-- Cooldown configurable (main/config.lua → M.balance.npc_cooldown_seconds)
			progress.available_after = os.time() + (config.balance.npc_cooldown_seconds or 60)
		end
		M.save()
		dprint("NPC " .. npc_id .. " falló. Intento: " .. progress.attempt)
		-- 🏆 La interacción de quiz general pudo terminar (completed) → reevaluar
		M.evaluate_tasks()
		return true
	end
	return false
end

-- Registrar éxito de NPC
function M.register_npc_success(npc_id)
	local progress = M.npc_progress[npc_id]
	if progress and not progress.completed then
		progress.completed = true
		M.globals.task_quiz_total = M.globals.task_quiz_total + 1
		M.save()
		dprint("NPC " .. npc_id .. " exitoso. Total quizzes: " .. M.globals.task_quiz_total)
		-- 🏆 Quiz general acertado: reevaluar tareas (aciertos + posibles 10/10)
		M.evaluate_tasks()
		return true
	end
	return false
end

-- ═══════════════════════════════════════════════════════
-- 🛠️ RESTAURACIÓN (npc_11 — Restauradora)
-- ============================================================
--   La restauradora es REUTILIZABLE: a diferencia de los demás NPCs, no
--   queda "completed" ni al acertar ni al agotar los 3 intentos — acepta la
--   pieza igualmente (3er fallo) y se resetea para el siguiente objeto que
--   necesite restauración. Su contador propio es task_restoration_total:
--   los quizzes de restauración NO suman a task_quiz_total.
-- ============================================================

-- Duración del cooldown de la restauradora tras fallar el quiz (segundos).
-- Fuente única de verdad: lo usa register_restoration_failure y el HUD para
-- calcular el progreso del pie timer de restauración (hud.gui_script).
-- Valor configurable en main/config.lua → M.balance.restorer_cooldown_seconds.
M.RESTORER_COOLDOWN_SECONDS = config.balance.restorer_cooldown_seconds or 60

-- Acierto del quiz de restauración: punto de restauración + reset para
-- el siguiente objeto (quedará disponible de nuevo).
function M.register_restoration_success(npc_id)
	local progress = M.npc_progress[npc_id]
	if progress then
		progress.attempt = 1
		progress.completed = false
		progress.available_after = 0
		M.globals.task_restoration_total = M.globals.task_restoration_total + 1
		M.save()
		dprint("NPC " .. npc_id .. " restauración exitosa. Total restauraciones: " .. M.globals.task_restoration_total)
		return true
	end
	return false
end

-- Fallo del quiz de restauración. Devuelve:
--   "retry"     → quedan intentos: cooldown configurable en main/config.lua
--                 → M.balance.restorer_cooldown_seconds
--   "exhausted" → 3er fallo: la restauradora acepta la pieza igualmente
--                  (sin punto) y se resetea para el siguiente objeto.
function M.register_restoration_failure(npc_id)
	local progress = M.npc_progress[npc_id]
	if not progress then return "retry" end
	progress.attempt = progress.attempt + 1
	if progress.attempt > 3 then
		progress.attempt = 1
		progress.completed = false
		progress.available_after = 0
		M.save()
		dprint("NPC " .. npc_id .. " restauración agotada: pieza aceptada sin punto. Reseteada.")
		return "exhausted"
	else
		progress.available_after = os.time() + M.RESTORER_COOLDOWN_SECONDS
		M.save()
		dprint("NPC " .. npc_id .. " falló restauración. Intento: " .. progress.attempt)
		return "retry"
	end
end

-- 🛠️ Migración única (Ago 2026): antes del flujo de restauración, el quiz de
--    los NPC de restauración usaba la lógica genérica y podía quedar
--    completed=true tras 3 fallos (guardado antiguo). Son reutilizables por
--    diseño (ver register_restoration_*), así que un completed heredado
--    bloquearía el flujo para siempre. Al detectarlo, se resetea una sola
--    vez. El npc_id se pasa explícitamente (lo aporta el NPC/npc.script);
--    npc.script solo lo invoca para NPCs de tipo quiz_restoration.
function M.migrate_npc_if_completed(npc_id)
	local progress = M.npc_progress[npc_id]
	if progress and progress.completed then
		progress.attempt = 1
		progress.completed = false
		progress.available_after = 0
		M.save()
		dprint("🛠️ NPC de restauración " .. npc_id .. ": migración — completed antiguo reseteado")
	end
end

-- Obtener el intento actual de un NPC
function M.get_npc_attempt(npc_id)
	local progress = M.npc_progress[npc_id]
	if progress then
		return progress.attempt
	end
	return 1
end

-- 💬 CHARLA DE AMBIENTE (npc_XX_talk_N)
-- ============================================================
-- Los diálogos de ambiente (bibliotecaria, guardia y futuros NPCs)
-- no consumen intentos ni tienen quiz: solo alternan entre bloques
-- talk_1, talk_2, ... en ciclo. El índice se guarda en el progreso
-- del NPC, así que persiste entre sesiones (savegame).
-- ============================================================

-- Obtener el índice de charla actual de un NPC (0-based)
function M.get_npc_talk_index(npc_id)
	local progress = M.npc_progress[npc_id]
	if progress and progress.talk_index then
		return progress.talk_index
	end
	return 0
end

-- Avanzar al siguiente bloque de charla (talk_1 -> talk_2 -> ...).
-- El número de bloques se pasa para acotar el contador con módulo
-- (no crece indefinidamente en el savegame; la selección usa % de todos modos).
function M.advance_npc_talk(npc_id, num_talks)
	local progress = M.npc_progress[npc_id]
	if progress then
		local max = num_talks or 1
		progress.talk_index = ((progress.talk_index or 0) + 1) % max
		M.save()
		return true
	end
	return false
end

-- Actualizar variable global
function M.set_global(key, value)
	local old_value = M.globals[key]
	M.globals[key] = value
	M.save()
	M.notify_callbacks(key, old_value, value)
	return true
end

-- Incrementar variable global
function M.add_to_global(key, amount)
	amount = amount or 1
	local old_value = M.globals[key]
	M.globals[key] = M.globals[key] + amount
	M.save()
	M.notify_callbacks(key, old_value, M.globals[key])
	-- 🏆 Bichos eliminados: reevaluar la tarea de control de plagas
	if key == "task_bugs_total" then
		M.evaluate_tasks()
	end
	return M.globals[key]
end

-- Obtener variable global
function M.get_global(key)
	return M.globals[key]
end

-- Obtener todas las variables globales
function M.get_all_globals()
	return M.globals
end

-- 🗣️ Marcar el diálogo con NPC como activo (true) o cerrado (false). En RAM
--    (sin save ni callbacks): el HUD lo lee por polling en update_reminders.
--    El valor se normaliza a booleano (nil/false → false).
function M.set_dialog_active(active)
	M.dialog_active = active == true
end

-- 🗣️ ¿Está el jugador en un diálogo/quiz con un NPC? (lee el flag RAM)
function M.get_dialog_active()
	return M.dialog_active == true
end

-- Reiniciar todo el progreso (nuevo juego)
function M.reset_all()
	-- 🎛️ Preferencias del jugador que NO se reinician con la partida: son
	--    elecciones de usuario (volumen de efectos, unidades de temperatura,
	--    overlay FPS), no progreso. Se conservan entre partidas (GOTCHA:
	--    temp_units/fps_overlay no están en los defaults — se crean en runtime
	--    vía set_global, así que un reset_all() las borraba silenciosamente).
	local prefs = {
		sfx_volume = M.globals.sfx_volume,
		temp_units = M.globals.temp_units,
		fps_overlay = M.globals.fps_overlay,
	}

	M.globals = {
		health = 100,
		skills = 1,
		stamina = 100,
		score = 0,
		language = "es",
		task_quiz_total = 0,
		task_restoration_total = 0,
		tasks_completed = 0,
		inventory_items_status = {},
		inventory_furniture_slots = {},
		inventory_storage_remaining = 0,
		rule_display_case_shown = false,  -- 🎓 One-shot educativo
		task_bugs_total = 0,
		cat_food_count = 0,
		max_spray = 100,
		spray_current = 100,
		nest_insecticide = 0,  -- 🪺 Cargas de insecticida (nidos)

		-- Audio
		audio_volume = 1.0,
		audio_enabled = true,

		-- 🌡️ CLIMA: Temperatura y Humedad (valores iniciales configurables en
		-- main/config.lua → M.balance.temp_ideal / hr_ideal)
		temp_raw = config.balance.temp_ideal or 21.0,
		hr_raw = config.balance.hr_ideal or 50.0,
		temp_previous = config.balance.temp_ideal or 21.0,
		hr_previous = config.balance.hr_ideal or 50.0,
		temp_trending_up = false,
		hr_trending_up = false,
		climate_warning_level = 0,
		temp_ok = true,
		hr_ok = true
	}

	-- ♻️ Restaurar las preferencias conservadas (si existían)
	for k, v in pairs(prefs) do
		if v ~= nil then
			M.globals[k] = v
		end
	end

	M.init_default_npc_progress()
	M.quiz_state = {
		pool_id = "",
		questions_answered = {},
		current_attempts = 0,
		last_question_id = ""
	}
	-- 🏆 Una partida nueva puede volver a ganar: habilitar la victoria de nuevo
	M._victory_triggered = false
	M.save()
	M.flush()  -- Escritura inmediata por ser una operación destructiva
	dprint("Todos los datos reiniciados")
end

-- Obtener tiempo restante de cooldown de NPC (en segundos)
function M.get_npc_cooldown_remaining(npc_id)
	local progress = M.npc_progress[npc_id]
	if progress and progress.available_after and progress.available_after > os.time() then
		return progress.available_after - os.time()
	end
	return 0
end

-- ═══════════════════════════════════════════════════════
-- 🧠 ESTADO DEL QUIZ (en RAM, sin I/O)
-- ═══════════════════════════════════════════════════════

-- Guardar estado del quiz (para reanudarlo)
function M.set_quiz_state(pool_id, questions_answered, current_attempts, last_question_id)
	M.quiz_state = {
		pool_id = pool_id or "",
		questions_answered = questions_answered or {},
		current_attempts = current_attempts or 0,
		last_question_id = last_question_id or ""
	}
	M.save()
end

-- Limpiar estado del quiz (al completarlo o abandonarlo)
function M.reset_quiz_state()
	M.quiz_state = {
		pool_id = "",
		questions_answered = {},
		current_attempts = 0,
		last_question_id = ""
	}
	M.save()
end

-- Obtener estado del quiz
function M.get_quiz_state()
	return M.quiz_state
end

-- ═══════════════════════════════════════════════════════
-- 🔓 GESTIÓN DE DESBLOQUEO DE NPCs (en RAM, sin I/O)
-- ═══════════════════════════════════════════════════════

-- Registrar listener para cuando se desbloquea un NPC
-- (recibe el npc_id como único argumento)
function M.on_npc_unlocked(callback)
	table.insert(M.npc_unlock_listeners, callback)
end

-- Desbloquear un NPC
function M.unlock_npc(npc_id)
	local progress = M.npc_progress[npc_id]
	if progress then
		progress.unlocked = true
		M.save()
		dprint("NPC desbloqueado: " .. npc_id)

		-- 📣 Notificar a los listeners (p. ej. el spawn manager) para que el
		--    NPC aparezca en su punto de spawn. pcall: un listener con error
		--    no debe romper el flujo de desbloqueo (módulo crítico).
		for _, callback in ipairs(M.npc_unlock_listeners) do
			local ok, err = pcall(callback, npc_id)
			if not ok then
				dprint("Error en listener de desbloqueo de NPC: " .. tostring(err))
			end
		end
		return true
	end
	dprint("Error: No se puede desbloquear NPC desconocido: " .. npc_id)
	return false
end

-- Verificar si un NPC está desbloqueado
function M.is_npc_unlocked(npc_id)
	local progress = M.npc_progress[npc_id]
	return (progress and progress.unlocked == true) or false
end

return M