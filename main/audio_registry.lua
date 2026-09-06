-- main/audio_registry.lua
-- ═══════════════════════════════════════════════════════
-- 🎵 REGISTRO DE AUDIO DE FONDO (fuente única de verdad)
-- ═══════════════════════════════════════════════════════
--
--   Tras el refactor de audio (Ago 2026): la música de fondo ya NO se
--   activa por zonas de contacto (se eliminaron zone_calm/exploration/
--   library y, en Ago 2026, también zone_storage → storage_1 pasó a la
--   PLAYLIST como pista regular; las zonas solo emiten avisos de sala en
--   text_alert vía zone_alert.script). En su lugar:
--
--     • PLAYLIST  → bucle secuencial: cada pista suena su duración
--                   completa y comienza la siguiente (solo "mientras no
--                   haya una orden específica").
--     • EVENTS    → sonidos específicos que se reproducen en bucle
--                   mientras el sistema que los dispara esté activo
--                   (pila LIFO en audio_manager; al terminar, la playlist
--                   se reanuda en la pista siguiente).
--     • INTRO     → escena especial (intro.collection): usa los mensajes
--                   play_ambient legacy del audio_manager.
--
--   📌 AMPLIAR LA LISTA: para añadir un sonido de evento futuro basta con
--   añadir una entrada aquí + enviar play_event/stop_event{ id } desde el
--   gameplay (los URLs deben existir como componentes embebidos del
--   audio_manager en bootstrap — ver main/audio_manager.go).
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-15
-- ═══════════════════════════════════════════════════════

local M = {}

-- ═══════════════════════════════════════════════════════
-- 🎶 PLAYLIST DE FONDO (orden secuencial, duración completa)
-- ═══════════════════════════════════════════════════════
-- Nota: la intro (start_1 / calm_1) no está en este registro porque la
-- escena de intro envía sus URLs directamente con el mensaje legacy
-- play_ambient (ver intro/intro_animation.script).
--
-- ⏱️ `dur` = duración REAL de cada pista en segundos (obtenida con ffprobe
-- sobre los .ogg, Ago 2026). Es un dato ESTÁTICO porque esta versión del
-- motor NO expone sound.get_length en runtime (GOTCHA #17); si una pista
-- cambia, actualizar aquí su duración.
M.PLAYLIST = {
	{ id = "calm_1",        url = msg.url("bootstrap:/audio_manager#calm_1"),        dur = 51.91 },
	{ id = "calm_2",        url = msg.url("bootstrap:/audio_manager#calm_2"),        dur = 66.56 },
	{ id = "exploration_1", url = msg.url("bootstrap:/audio_manager#exploration_1"), dur = 51.91 },
	{ id = "exploration_2", url = msg.url("bootstrap:/audio_manager#exploration_2"), dur = 60.03 },
	{ id = "exploration_3", url = msg.url("bootstrap:/audio_manager#exploration_3"), dur = 60.03 },
	{ id = "exploration_4", url = msg.url("bootstrap:/audio_manager#exploration_4"), dur = 61.50 },
	-- 🏭 storage_1: antigua pista de zona (almacén). Ago 2026: integrada en
	--    la playlist como pista regular (se eliminó el disparo por zona).
	{ id = "storage_1",      url = msg.url("bootstrap:/audio_manager#storage_1"),      dur = 63.89 },
}

-- ═══════════════════════════════════════════════════════
-- 🎵 SONIDOS DE EVENTO (id → url, bucle mientras el sistema esté activo)
-- ═══════════════════════════════════════════════════════
M.EVENTS = {
	-- muerte del jugador (player.script trigger_death → trigger_respawn)
	death   = msg.url("bootstrap:/audio_manager#death_1"),
	-- fin del juego — ⚠️ POR IMPLEMENTAR: entrada preparada, aún sin emisor
	endgame = msg.url("bootstrap:/audio_manager#endgame_1"),
	-- lucha con enemigos (audio_manager vigila enemy_state: oleada viva)
	fight   = msg.url("bootstrap:/audio_manager#fight_1"),
	-- lectura de libro (library.gui_script show_book → hide_library)
	library = msg.url("bootstrap:/audio_manager#library_1"),
	-- sistema de pausa (pause.gui_script show_pause → hide_pause)
	pause   = msg.url("bootstrap:/audio_manager#exploration_4"),
	-- quiz con NPCs (dialogue_manager.script start_quiz → resultado/cancel)
	quiz    = msg.url("bootstrap:/audio_manager#quiz_1"),
}

return M
