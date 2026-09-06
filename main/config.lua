-- main/config.lua
-- ═══════════════════════════════════════════════════════
-- 🏭 CONFIGURACIÓN DE DESARROLLO / PRODUCCIÓN
-- ═══════════════════════════════════════════════════════
--
--   DEV_MODE = true   →   🔧 Modo desarrollo
--     - El progreso de NPCs se resetea al iniciar el juego
--     - La partida guardada se sobrescribe al arrancar
--     - La tecla R resetea todo el progreso
--     - La tecla N simula la victoria completa (debug_force_victory, ver
--       main/game_state.lua y main/scene_manager.script)
--     - El overlay de FPS arranca oculto por defecto (FPS_START_VISIBLE en
--       gui/hud.gui_script): el jugador lo activa con la tecla F o el toggle
--       "Mostrar FPS" del menú de pausa (preferencia persistida en fps_overlay)
--
--   DEV_MODE = false  →   🚀 Modo producción
--     - Se respeta la partida guardada del jugador
--     - No se resetea nada automáticamente
--     - Las teclas R y N están desactivadas
--     - El overlay de FPS arranca oculto igual que en debug (misma preferencia persistida)
--
--   ⚠️  CAMBIAR A false ANTES DE COMPILAR PARA PRODUCCIÓN
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-15
-- ═══════════════════════════════════════════════════════

local M = {}

-- WARNING: true para compilar en preproduccion; false para compilar en produccion
M.DEV_MODE = false

-- 🪺 DEBUG_ALL_INSECTICIDE (docs/plans/archive/NEST_SYSTEM_PLAN.md, Fase 2): true → TODOS los
--   botes que crea/repona spray_spawn_container son de insecticida especial
--   (ignora balance.nest.insecticide_chance). Solo para PROBAR el sistema de
--   nidos sin depender del RNG; poner a false antes de compilar a producción.
M.DEBUG_ALL_INSECTICIDE = false

-- 🎯 SHOW_ALL_NPCS: posicionar a TODOS los NPCs en sus spawn points.
--   El bloqueo por desbloqueo (unlock_npc) solo tiene sentido si esconder
--   NPCs ahorra lógica/renderizado de verdad (p. ej. con go.disable en vez de
--   dejarlos en staging). Con 14 NPCs el ahorro es despreciable, así que por
--   defecto se muestran todos; al implementar el ahorro real, poner a false
--   para que solo aparezcan los desbloqueados.
M.SHOW_ALL_NPCS = true

-- 🧩 TIPOS DE NPC POR DEFECTO (Ago 2026) — fuente de verdad en CÓDIGO
--   Valores: "quiz_general" (default) / "quiz_restoration" / "quiz_false"
--   (ver npc_spawn_state.NPC_TYPE_* y la propiedad npc_type de npc.script).
--   ⚠️ El editor de Defold RE-SERIALIZA level_01.collection al abrirlo y
--   puede eliminar los component_properties escritos a mano; esta tabla
--   garantiza el tipo correcto en runtime aunque la propiedad del editor
--   falte (la propiedad es solo un override opcional para NPCs futuros).
--   Añadir aquí un NPC nuevo (p. ej. ["npc_14"] = "quiz_false") sin tocar
--   el .collection es suficiente.
M.NPC_TYPES = {
	["npc_11"] = "quiz_restoration", -- 🛠️ Restauradora: quiz de restauración (pool_2)
	["npc_12"] = "quiz_false",       -- 💬 Charla de ambiente sin quiz
	["npc_13"] = "quiz_false",       -- 💬 Charla de ambiente sin quiz
}

-- 📱 FASE 3 — AUTO-AIM DEL SPRAY EN MÓVIL (docs/plans/archive/MOBILE_CONTROLS_PLAN.md)
--   AUTO_AIM_RANGE: distancia máxima (uds) a la que el botón spray busca
--   al enemigo más cercano. El bullet vive ~0.5s a 200-400 px/s → el spray
--   alcanza ~100-200 uds; 250 da margen sin que apunte a enemigos lejanos.
M.AUTO_AIM_RANGE = 250
--   SMART_TRIGGER: true = no gastar spray si no hay enemigo en rango
--   (protege el recurso, decisión confirmada); false = mantener = disparar
--   siempre (en la dirección FACING de movimiento).
M.SMART_TRIGGER = true
--   AUTO_AIM_HYSTERESIS: ventana de gracia (s) tras PERDER el objetivo antes
--   de cortar el disparo. Un enemigo que oscila en el borde de AUTO_AIM_RANGE
--   hacía titilar el sonido loop del spray (start/stop por frame) y cortaba
--   ráfagas a medio camino. Con histéresis, si el objetivo reaparece dentro
--   de la ventana NO hay ninguna interrupción; durante la gracia se mantiene
--   la última dirección conocida (no cae a FACING). Solo se concede si la
--   sesión de disparo llegó a tener objetivo (pulsar sin enemigos sigue sin
--   gastar nada). ~0.25s = 15 frames a 60fps.
M.AUTO_AIM_HYSTERESIS = 0.25
--   FIGHT_COMBAT_RADIUS: distancia máxima (uds) al jugador a la que un
--   enemigo vivo cuenta para el sondeo de "pelea" (música background_fight_1,
--   spawn_enemies.script). Filtra los enemigos estáticos lejanos del editor
--   (p. ej. la cucaracha a ~1380 uu del spawn) que disparaban fight desde el
--   primer frame del nivel. Coherente con AUTO_AIM_RANGE (250); con 400 la
--   música arrancaba SIEMPRE con el enemigo desencuadrado (la pantalla visible
--   es 640×384 uds a zoom 2.0 → distancia máx. en pantalla ≈ 373 uds en la
--   esquina, 320 en horizontal) y sonaba lejos de cualquier nido (los nidos
--   spawnan a ≤ 50 uds, métrica distinta: distancia a ENEMIGOS vivos, que
--   incluye estáticos y sobrantes). Con 250 el enemigo ya está en pantalla en
--   horizontal cuando suena (250 < 320). Salida con histéresis ×1.25 (312.5)
--   en spawn_enemies.script.
--   ⚠️ Nota: el charge_range de la rata es 260 → con 250 la música entra
--   justo cuando la rata amaga la embestida (trade-off aceptado por
--   visibilidad; el walk de la cucaracha sigue dando aviso por proximidad).
M.FIGHT_COMBAT_RADIUS = 250

-- ═══════════════════════════════════════════════════════
-- 📱 DIANA TÁCTIL (GOTCHA #13) — leído por main/gui_touch.lua
-- ═══════════════════════════════════════════════════════
--   target_height_uu: altura efectiva mínima de diana en unidades de escena
--   para botones en táctil. La GUI se reduce con FIT en landscape móvil
--   (~0.56× para 926×428 CSS), así que la diana debe compensarlo: 88 uu ×
--   FIT ≈ 49 CSS px (> 44 px recomendados por Apple/Google, con margen).
--   ⚠️ Bajarlo reduce la diana REAL: 66 uu (≈1.5× sobre un botón de 44 uu)
--   × FIT ≈ 37 CSS px — por debajo del estándar en móviles pequeños.
--   max_total_scale: tope absoluto de la escala total (iconos muy pequeños
--   de 16 uu no se desproporcionan). El cap por fila estrecha sigue siendo
--   el parámetro max_scale de gui_touch.total_scale (p. ej. fila de volumen).
M.ui_touch = {
    target_height_uu = 88,   -- diana: 88 uu × FIT(~0.56) ≈ 49 CSS px
    max_total_scale = 4.0,   -- tope absoluto de la escala total
}

-- ═══════════════════════════════════════════════════════
-- ⚙️ BALANCE DEL JUEGO (Ago 2026) — valores ajustables SIN tocar código
-- ═══════════════════════════════════════════════════════
--   Punto único de configuración de los valores de balance del flujo
--   principal. Cambiar aquí y recompilar = nueva configuración (ideal para
--   preproducción: valores rápidos; producción: valores realistas).
--
--   Cada clave indica su valor sugerido en preproducción y producción.
--   Los scripts consumidores leen estas claves SIEMPRE con fallback al
--   valor anterior (p. ej. `config.balance.npc_cooldown_seconds or 60`),
--   así que una clave borrada nunca rompe el juego.
-- ═══════════════════════════════════════════════════════
M.balance = {
	-- ⏱️ FLUJO DE COLECCIONABLES (leído por inventory_core / inventory_manager)
	-- Tiempo (s) hasta que aparece el PRIMER objeto al iniciar partida
	-- (solo si no hay partida guardada). Da tiempo a explorar el museo.
	initial_spawn_delay = 30,          -- preprod: 5...10 · prod: 30
	-- Timer A: espera (s) en STORAGE (estantería) antes de que el objeto
	-- quede listo para vitrina (EXHIBITION). El pie timer del HUD muestra
	-- la cuenta atrás al jugador.
	storage_timer_duration = 60,      -- preprod: 10 · prod: 60...300
	-- Timer B: cooldown (s) tras completar un objeto en vitrina antes de
	-- spawnear el siguiente objeto.
	spawn_delay = 10,                  -- preprod: 5 · prod: 10

	-- 🧑‍🤝‍🧑 NPCs (leído por game_state)
	-- Cooldown (s) de los NPCs de quiz genéricos (npc_01..npc_10) tras
	-- fallar el quiz, antes de poder reintentar. El HUD ya recuerda al
	-- jugador cuando un NPC vuelve a estar disponible (recordatorio
	-- alert_npc_available, ver general_text_[lan].lua).
	npc_cooldown_seconds = 60,        -- preprod: 5 · prod: 60
	-- Cooldown (s) de la restauradora (npc_11) tras fallar su quiz de
	-- restauración. Fuente única: el pie timer del HUD también lo lee
	-- (game_state.RESTORER_COOLDOWN_SECONDS se deriva de esta clave).
	restorer_cooldown_seconds = 60,   -- preprod: 5 · prod: 60

	-- 🚶 PATRULLA DE NPCs (leído por features/npc/npc_patrol.lua)
	-- Umbral de navegación (Ago 2026): espacio libre mínimo (uds) exigido en
	-- la dirección candidata antes de comprometerse a un tramo (space check
	-- por raycast contra walls, 3 rayos paralelos por el ancho del cuerpo).
	-- Las direcciones con menos hueco se descartan como "óptimas"; si ninguna
	-- llega, se elige la de mayor hueco (fallback). Menor que PATROL_DIST_MIN
	-- (80) para que un pasillo corto siga siendo viable.
	npc_nav_clearance = 60,           -- preprod: 60 · prod: 60
	-- Distancia (px) a la que el NPC se detiene cuando el jugador se acerca.
	-- Si el jugador entra en este radio, la patrulla pasa a IDLE (timer ∞)
	-- y solo reanuda cuando el jugador se aleja por encima de resume.
	npc_player_stop_dist = 70,         -- preprod: 70 · prod: 70
	npc_player_resume_dist = 110,      -- preprod: 110 · prod: 110 (histéresis)
	-- 🎥 Culling por cámara (leído por npc.script): factor de margen para
	-- desactivar patrulla de NPCs off-screen. 1.0 = borde exacto del viewport;
	-- 1.30 = 30% extra (default, transiciones suaves); 1.50 = conservador.
	npc_cull_margin_factor = 1.30,     -- preprod: 1.30 · prod: 1.30

	-- 🌡️ CLIMA Y STAMINA (leído por climate_controller.script)
	-- Rango "ideal" del museo: dentro → alerta verde (HUD); fuera → naranja
	-- o rojo según la tendencia (mejorando/empeorando).
	temp_range_min = 20.0,            -- preprod: 20.0 · prod: 20.0  (°C)
	temp_range_max = 22.0,            -- preprod: 22.0 · prod: 22.0  (°C)
	hr_range_min = 45.0,              -- preprod: 45.0 · prod: 45.0  (%)
	hr_range_max = 55.0,              -- preprod: 45.0 · prod: 55.0  (%)
	-- Simulador: punto de partida/equilibrio del clima y límites físicos
	-- (con puertas cerradas temp/HR derivan hacia los valores ideal).
	temp_ideal = 21.0,                -- (°C) valor de equilibrio con puertas cerradas
	hr_ideal = 50.0,                  -- (%)  valor de equilibrio con puertas cerradas
	temp_sim_max = 35.0,              -- (°C) techo de la simulación con puertas abiertas
	hr_sim_max = 75.0,                -- (%)  techo de la simulación con puertas abiertas
	-- Tasa de cambio del clima por puerta abierta/cerrada (por segundo).
	climate_change_rate = 0.1,        -- preprod: 0.5 · prod: 0.1
	-- Frecuencia del simulador: cada cuántos segundos se recalcula el clima
	-- (1 tick por segundo actualmente).
	climate_tick_interval = 1.0,      -- preprod: 0.5 · prod: 1.0
	-- Volumen de la sirena de alerta climática (0-1).
	siren_volume = 0.4,
	-- ⚡ Drenaje de stamina por segundo según el nivel de alerta climática
	-- (0 = verde OK, 1 = naranja mejorando, 2 = rojo empeorando).
	stamina_drain_base = 0.01,        -- nivel 0 (verde): drenaje mínimo
	stamina_drain_warn = 0.04,        -- nivel 1 (naranja): drenaje moderado
	stamina_drain_crit = 0.08,        -- nivel 2 (rojo): drenaje acelerado

	-- 🖱️ INTERACCIÓN: rango GLOBAL (leído por cursor.script y mobile_interact.script)
	-- Distancia (unidades del mundo) máxima a la que el jugador puede interactuar
	-- con CUALQUIER interactable (ME_*, NPCs, puertas, armarios, botes, kits,
	-- gato…). Se mide desde el jugador al PUNTO DE INTERACCIÓN del objeto
	-- (registrado por puertas/armarios, fallback al GO — GOTCHA #31).
	-- ⚠️ Acoplamiento con el editor: el trigger táctil de player.go
	-- (collisionobject_interact, data 90,90,10 = 180×180) debe cubrir ~2× este
	-- valor — si cambias el rango, ajusta el trigger a mano (ver mobile_interact).
	interaction_range = 80,               -- preprod: 100 · prod: 80
	-- 🚶 AUTO-CIERRE DE ARMARIOS (leído por office_cabinet.script)
	-- Distancia (uds) al jugador a partir de la cual un armario ABIERTO se
	-- cierra solo (update() de office_cabinet.script). Debe ser >
	-- interaction_range (80) para que el jugador pueda abrir el armario y
	-- recoger su contenido con margen; el cierre es unidireccional (no se
	-- reabre solo, solo por clic) → sin riesgo de flickering.
	cabinet_auto_close_distance = 200,    -- preprod: 200 · prod: 200
	-- Duración (s) del globo "no disponible" al hablar con un NPC ocupado.
	unavailable_bubble_duration = 2.5,    -- preprod: 1.5 · prod: 2.5
	-- Variante de la restauradora (npc_11): su mensaje explica el flujo de
	-- restauración y necesita más tiempo de lectura.
	restorer_unavailable_bubble_duration = 4.5,
	-- Distancia (unidades) que debe moverse el jugador para ocultar el globo
	-- "no disponible" (el globo queda anclado al NPC en el momento del clic).
	unavailable_bubble_move_hide_threshold = 5.0,  -- preprod: 10 · prod: 5.0
	-- Frecuencia (s) del polling del icono de disponibilidad de los NPCs
	-- (detecta la expiración del cooldown wall-clock; ver DEV_GOTCHAS).
	npc_icon_poll_interval = 0.5,         -- preprod: 0.25 · prod: 0.5

	-- 🪳 AUDIO DE ENEMIGOS POR PROXIMIDAD (leído por enemy_cockroach y enemy_rat)
	-- Distancia (uds) a la que el sonido deja de oírse (volumen 0 %). Con
	-- histéresis: el loop walk de la cucaracha se DETIENE (libera slot del
	-- buffer de sonido) solo al superar max + enemy_sound_hysteresis.
	enemy_sound_proximity_max = 200,      -- preprod: 300 · prod: 200
	-- Distancia (uds) a la que el sonido suena al 100 %.
	enemy_sound_proximity_min = 100,
	-- Banda de histéresis (uds): margen sobre max antes de cortar el loop
	-- walk (evita play/stop por oscilación en el borde del rango).
	enemy_sound_hysteresis = 50,
	-- Distancia (uds) de los sonidos ONE-SHOT (squeak de amago de la rata,
	-- attack y death de ambos enemigos). Debe ser ≥ rat charge_range (260)
	-- para que el telegrafiado audible de la embestida no se emita mudo.
	-- Eventos transitorios: no ocupan slots del buffer de forma continua.
	enemy_sound_one_shot_max = 400,      -- preprod: 500 · prod: 400

	-- 📣 HUD (leído por hud.gui_script)
	-- Intervalos (s) de los recordatorios periódicos: cada cuánto se re-muestra
	-- la alerta mientras la acción siga pendiente. FUENTE ÚNICA (Ago 2026): los
	-- tiempos viven aquí, no en general_text_[lan].lua (los textos solo tienen
	-- el mensaje). Un "0" desactiva el recordatorio concreto. Cada clave indica
	-- su valor sugerido en preproducción y producción.
	reminder_new_material = 120,     -- recogida pendiente (alert_new_material)
	reminder_pending_storage = 120,  -- depósito en almacén pendiente (alert_pending_storage)
	reminder_no_exp = 120,           -- exhibición pendiente (rule_no_exp)
	reminder_restorer_new = 120,     -- restauración sin quiz hecho (alert_new_restoration)
	reminder_restorer_retry = 120,   -- re-intento tras fallar quiz (alert_new_attempt_restoration)
	reminder_npc_available = 120,    -- NPC de quiz disponible (alert_npc_available)
	-- ⚙️ PREPROD: 15 (todas) · PROD: 120...180 (todas)

	-- 🎬 INTRO (leído por intro/gui/intro.gui_script)
	-- Pausa (s) entre cruces del marquee del aviso de guardado (warning_text,
	-- solo HTML5): tras salir por la izquierda, la pantalla queda limpia este
	-- tiempo antes de que el aviso vuelva a entrar por la derecha (cruce = 15s
	-- constante local en intro.gui_script). Evita el ruido visual del marquee
	-- continuo manteniendo el aviso periódico mientras el jugador no avance.
	intro_warning_marquee_pause = 8,  -- preprod: 8 · prod: 8

	-- 🪺 NIDOS (leído por nest_container / nest.script / spray_spawn_container)
	-- Sistema de nidos de enemigos (docs/plans/archive/NEST_SYSTEM_PLAN.md): el jugador puede
	-- destruir la fuente de enemigos con insecticida especial. Fase 1:
	-- solo los valores de nido; la probabilidad del insecticida llega en
	-- Fase 2 (spray_spawn_container).
	nest = {
		-- Bonus a task_bugs_total por nido destruido (tarea híbrida,
		-- PESTS_MIN = 20: kills + nidos).
		nest_bonus = 5,                 -- preprod: 5 · prod: 5
		-- Probabilidad (0-1) de que un respawn del spray sea un bote de
		-- insecticida en vez de spray (Fase 2).
		insecticide_chance = 0.18,      -- preprod: 0.5 · prod: 0.18
		-- Cargas máximas de insecticida que puede llevar el jugador.
		insecticide_max = 2,            -- preprod: 2 · prod: 2
		-- 🚶 DESPAWN POR DISTANCIA (Ago 2026): distancia (uds) al jugador a la
		-- que un enemigo de nido SIN INTERACCIÓN desaparece (fuera de pantalla:
		-- lo visible a zoom 2.0 son ~373 uds en la esquina). El nido lo
		-- re-emite si el jugador vuelve (trigger r=50). No aplica si el
		-- enemigo recibió daño o golpeó al jugador (engaged). Leído por
		-- enemy_cockroach / enemy_rat (flag from_nest puesto por el spawner
		-- solo en nidos). Pone techo a la acumulación de oleadas (buffer de
		-- colisión fijo, GOTCHA #27).
		enemy_despawn_distance = 400,   -- preprod: 400 · prod: 400
	},

	-- 🎲 RANGOS ALEATORIOS DE OLEADA PARA LOS NIDOS (Fase 3, NEST_SYSTEM_PLAN §6)
	-- Los nidos son instancias de factory sin configuración por instancia en el
	-- editor → los rangos viven aquí. El spawn_enemies del nido los lee (flag
	-- use_nest_ranges en nest.go) y tira un valor uniforme POR OLEADA. El tipo
	-- de enemigo se elige UNA vez por nido (los 5 nidos no son clones). Si esta
	-- tabla se borra o falta una clave, el nido usa sus valores fijos de nest.go
	-- (convención del proyecto: consumidores con fallback).
	nest_ranges = {
		total_enemies    = { min = 3,   max = 5 },    -- 3..5 por oleada
		spawn_interval   = { min = 2.5, max = 5.0 },  -- 2.5..5 s entre apariciones
		spawn_radius     = { min = 15,  max = 30 },   -- dispersión
		enemy_types      = { "cockroach", "rat", "mix" },  -- tipo al azar POR NIDO
		reactivate_delay = { min = 8,   max = 20 },   -- ritmo de oleadas por nido
	},
}

-- Silence debug prints in production
M.DEBUG = false

-- 🔧 Factory de log con granularidad por archivo/subsistema:
--    local dprint = M.make_log(true)   -- toggle local del archivo
--    Solo imprime si M.DEBUG (global) Y el toggle local son true.
function M.make_log(enabled)
	return function(...)
		if M.DEBUG and enabled then
			print(...)
		end
	end
end

-- Log global (compatibilidad): equivale a make_log(true).
--    Imprime cuando M.DEBUG esté activo (sin toggle granular).
--    Se conserva como API pública para no romper llamadas existentes;
--    los módulos nuevos deben usar make_log() con su toggle local.
M.dprint = M.make_log(true)

return M
