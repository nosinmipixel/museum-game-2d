-- features/player/auto_aim.lua
-- ═══════════════════════════════════════════════════════
-- 🎯 AUTO-AIM DEL SPRAY EN MÓVIL (Fase 3 docs/plans/archive/MOBILE_CONTROLS_PLAN.md)
-- ═══════════════════════════════════════════════════════
--   Encuentra el enemigo MÁS CERCANO al jugador dentro de un rango y
--   devuelve la dirección normalizada hacia él. Alimenta la fuente AUTO
--   de la capa unificada (features/player/aiming.lua) cuando el botón
--   spray está pulsado en un dispositivo táctil.
--
--   Decisiones confirmadas (Agosto 2026):
--     • Auto-aim SIEMPRE al enemigo más cercano en rango (sin cono).
--     • SMART_TRIGGER = true → no se gasta spray sin enemigo en rango
--       (configurado en main/config.lua).
--
--   Uso (patrón de módulo compartido):
--     local auto_aim = require "features.player.auto_aim"
--     local dir = auto_aim.find_nearest(player_pos, range, self.out)  -- nil | out
--     if dir then aiming.set_auto(dir) else aiming.clear_auto() end
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-15
-- ═══════════════════════════════════════════════════════

local enemy_state = require "main.enemy_state"

local M = {}

-- Dirección normalizada (espacio mundo) hacia el enemigo más cercano al
-- jugador dentro de `range` unidades. Muta `out` (zero-alloc, estándar #2/#8)
-- y devuelve `out`, o `nil` si no hay ningún enemigo vivo en rango.
-- Recorre enemy_state.get_spawned() filtrando go.exists() (GOTCHA #4: los
-- ids vienen de factory.create, nunca adivinar nombres).
function M.find_nearest(player_pos, range, out)
	local player_x = player_pos.x
	local player_y = player_pos.y
	local range_sqr = range * range

	local best_id = nil
	local best_dx = 0
	local best_dy = 0
	local best_dist_sqr = range_sqr

	for _, id in ipairs(enemy_state.get_spawned()) do
		if go.exists(id) then
			-- Espacio MUNDO para ambos (player usa get_world_position): los
			-- enemigos de factory son top-level (local == mundo hoy), pero si
			-- alguno se anidara bajo un padre, la posición local rompería la
			-- distancia. get_world_position es idéntico en el caso top-level.
			local pos = go.get_world_position(id)
			local dx = pos.x - player_x
			local dy = pos.y - player_y
			local dist_sqr = dx * dx + dy * dy
			if dist_sqr < best_dist_sqr then
				best_dist_sqr = dist_sqr
				best_id = id
				best_dx = dx
				best_dy = dy
			end
		end
	end

	if not best_id then
		return nil
	end

	-- 🛡️ Guard anti-NaN: si el enemigo está EXACTAMENTE sobre el jugador
	-- (dist_sqr == 0, p. ej. un perseguidor pegado), inv_len sería 1/0 = inf
	-- y out = 0*inf = NaN → el bullet saldría con rotación basura. Con el
	-- smart trigger, devolver nil simplemente retiene el disparo (y el
	-- enemigo ya está encima: no hace falta apuntar).
	if best_dist_sqr <= 0.0001 then
		return nil
	end

	local inv_len = 1 / math.sqrt(best_dist_sqr)
	out.x = best_dx * inv_len
	out.y = best_dy * inv_len
	out.z = 0
	return out
end

return M
