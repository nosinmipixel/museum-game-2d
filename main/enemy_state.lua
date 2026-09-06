-- main/enemy_state.lua
-- ═══════════════════════════════════════════════════════
-- 🪳 ESTADO DE ENEMIGOS — REGISTRO EN RUNTIME
-- ═══════════════════════════════════════════════════════
--
--   Módulo puro que registra los ids de los enemigos vivos para que el
--   auto-aim del spray móvil, el gato y los spawners localicen a los
--   enemigos. El id real se obtiene con go.get_id() (nunca adivinar
--   nombres auto-generados: fue la causa de que el gato no detectara
--   a las cucarachas).
--
--   Quién registra (Ago 2026): el PROPIO enemigo en su init()
--   (enemy_cockroach.script / enemy_rat.script). Así quedan registrados
--   TANTO los creados por factory (spawn_enemies) COMO los estáticos
--   colocados en el editor (p. ej. la cucaracha de level_01.collection,
--   que antes quedaba invisible para el spray móvil y el gato).
--
--   Uso:
--     enemy_cockroach.script: enemy_state.register(go.get_id())
--     cat.script:             for _, id in ipairs(enemy_state.get_spawned())
--                                 if go.exists(id) then ... end
--
--   ⚠️ Por qué existe: adivinar "enemy_cockroach1" fue la
--   causa de que el gato no detectara a las cucarachas.
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-15
-- ═══════════════════════════════════════════════════════

local M = {}

-- Lista de ids (hash) de enemigos creados dinámicamente
M.spawned = {}

-- Registrar un enemigo creado (id devuelto por factory.create)
function M.register(id)
	if id then
		table.insert(M.spawned, id)
	end
end

-- Obtener la lista de ids registrados (filtrar con go.exists antes de usar)
function M.get_spawned()
	return M.spawned
end

-- Limpiar el registro (p. ej. al reiniciar/re-cargar el nivel)
function M.reset()
	M.spawned = {}
end

-- Eliminar TODOS los enemigos vivos y limpiar el registro. Se usa al reiniciar
-- (p. ej. trigger_respawn del jugador): los enemigos que seguían atacando el
-- cadáver desaparecen para que el respawn no ocurra bajo fuego. go.exists
-- filtra los ids de enemigos ya muertos (borrados) que quedan en el registro.
-- El borrado es seguro: cada enemigo detiene sus sonidos en final().
function M.clear_alive()
	for _, id in ipairs(M.spawned) do
		if go.exists(id) then
			pcall(go.delete, id)
		end
	end
	M.spawned = {}
end

-- Flag compartido: ¿el jugador está muerto? Lo establece player.script en
-- trigger_death / trigger_respawn y lo consultan los spawners
-- (spawn_enemies.script) para NO emitir enemigos mientras el jugador esté
-- muerto (evita el race de una emisión pendiente que coincida con el clic de
-- Reintentar y sobreviva a clear_alive()). Flag de módulo (no mensajes) porque
-- hay varias instancias de spawn_enemies con ids distintos en la escena y no
-- se pueden direccionar todas de forma fiable.
M.waves_paused = false

function M.set_waves_paused(paused)
	M.waves_paused = paused == true
end

function M.is_waves_paused()
	return M.waves_paused
end

return M
