-- features/player/aiming.lua
-- ═══════════════════════════════════════════════════════════════════
-- 🎯 CAPA UNIFICADA DE PUNTERÍA (aim_direction)
-- ═══════════════════════════════════════════════════════════════════
--
--   Paso 1 del orden de implementación de docs/plans/archive/INPUT_CONTROL_PLAN.md (§9-§10).
--
--   Una única fuente de verdad para la dirección de disparo del spray,
--   alimentada por múltiples fuentes con prioridad (mayor gana):
--
--     MOUSE  (escritorio): punto del mundo bajo el ratón. Persistente:
--            sirve también para key_space sin haber movido el ratón.
--     STICK  (móvil):      dirección del joystick derecho (futuro).
--     AUTO   (móvil):      dirección al enemigo más cercano en rango
--                          (asistencia de cono, Opción 5 del plan).
--     FACING (fallback):   última dirección de movimiento del jugador.
--
--   Si no hay ninguna fuente activa, se devuelve la última dirección
--   efectiva (memoria) o (0,1,0) por defecto.
--
--   ✅ RESUELVE EL DOBLE ESPEJO X (docs/plans/archive/INPUT_CONTROL_PLAN.md §1, §4):
--     - La compensación espejada de la puntería desaparece (player_spray
--       ya no invierte X del punto del ratón → direcciones REALES).
--     - fire_particle usa la dirección real devuelta aquí con el ángulo
--       correcto para el forward (0,1,0) del bullet: a = atan2(-dx, dy).
--     - get_attack_animation (player.script) recibe direcciones reales
--       (el jugador mira hacia donde dispara, como fue diseñado).
--
--   Uso (patrón de módulo compartido como main/game_state.lua):
--     local aiming = require("features.player.aiming")
--     aiming.set_mouse(world_pos)
--     local dir = aiming.get_direction(player_pos, self.aim_out)  -- zero-alloc
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-15
-- ═══════════════════════════════════════════════════════════════════

local M = {}

-- 🔑 Claves de fuente
M.SRC_MOUSE  = "mouse"
M.SRC_STICK  = "stick"
M.SRC_AUTO   = "auto"
M.SRC_FACING = "facing"

-- Estado compartido del layer (los scripts que alimenten fuentes —joystick,
-- auto-aim— usan el require y los setters, igual que game_state.lua).
M.state = {
	mouse_world_pos = nil,   -- vector3 | nil — punto del mundo bajo el ratón
	stick_dir  = nil,        -- vector3 normalizado | nil
	auto_dir   = nil,        -- vector3 normalizado | nil
	facing_dir = nil,        -- vector3 normalizado | nil
	last_dir   = vmath.vector3(0, 1, 0),  -- memoria / fallback final
}

-- ═══════════════════════════════════════════════════════════════════
-- ⬆️ FEED — setters de fuentes
-- ═══════════════════════════════════════════════════════════════════

-- Fuente MOUSE: punto del MUNDO bajo el ratón.
-- No hay clear: persiste como última referencia (comportamiento actual
-- de key_space apuntando a la última posición del ratón).
function M.set_mouse(world_pos)
	M.state.mouse_world_pos = world_pos
end

-- Fuente STICK (joystick derecho, futuro)
function M.set_stick(dir)
	M.state.stick_dir = dir
end

function M.clear_stick()
	M.state.stick_dir = nil
end

-- Fuente AUTO (asistencia de cono, futuro): pasar nil para "sin enemigo"
function M.set_auto(dir)
	M.state.auto_dir = dir
end

function M.clear_auto()
	M.state.auto_dir = nil
end

-- Fuente FACING (fallback: última dirección de movimiento)
function M.set_facing(dir)
	M.state.facing_dir = dir
end

function M.clear_facing()
	M.state.facing_dir = nil
end

-- ═══════════════════════════════════════════════════════════════════
-- ⬇️ CONSUMO
-- ═══════════════════════════════════════════════════════════════════

-- Fuente activa según prioridad (nil si no hay ninguna)
function M.resolve_source()
	if M.state.mouse_world_pos then return M.SRC_MOUSE end
	if M.state.stick_dir then return M.SRC_STICK end
	if M.state.auto_dir then return M.SRC_AUTO end
	if M.state.facing_dir then return M.SRC_FACING end
	return nil
end

-- Dirección normalizada de disparo en espacio MUNDO desde player_pos.
-- Muta `out` (zero-alloc, estándar #2/#8: sin garbage en el hot path de
-- fire_particle) y lo devuelve. Siempre devuelve un vector válido:
--   - fuente MOUSE  → normalize(punto_mouse - player_pos)
--   - stick/auto/facing → el propio vector (ya es dirección)
--   - sin fuente o vector degenerado → última dirección efectiva.
function M.get_direction(player_pos, out)
	local src = M.resolve_source()

	local dx, dy
	if src == M.SRC_MOUSE then
		dx = M.state.mouse_world_pos.x - player_pos.x
		dy = M.state.mouse_world_pos.y - player_pos.y
	elseif src == M.SRC_STICK then
		dx, dy = M.state.stick_dir.x, M.state.stick_dir.y
	elseif src == M.SRC_AUTO then
		dx, dy = M.state.auto_dir.x, M.state.auto_dir.y
	elseif src == M.SRC_FACING then
		dx, dy = M.state.facing_dir.x, M.state.facing_dir.y
	end

	-- Sin fuente activa → memoria/fallback
	if not dx or not dy then
		out.x, out.y, out.z = M.state.last_dir.x, M.state.last_dir.y, 0
		return out
	end

	local len_sqr = dx * dx + dy * dy
	if len_sqr < 0.001 then
		-- Apuntando al propio jugador (vector degenerado) → memoria/fallback
		out.x, out.y, out.z = M.state.last_dir.x, M.state.last_dir.y, 0
		return out
	end

	local inv_len = 1 / math.sqrt(len_sqr)
	out.x = dx * inv_len
	out.y = dy * inv_len
	out.z = 0

	-- Memoria para fallbacks (copia, no referencia al out del caller)
	M.state.last_dir.x = out.x
	M.state.last_dir.y = out.y

	return out
end

-- Debug: nombre de la fuente activa actual (nil si no hay ninguna)
function M.active_source()
	return M.resolve_source()
end

return M
