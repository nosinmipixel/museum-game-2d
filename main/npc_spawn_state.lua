-- main/npc_spawn_state.lua
-- ═══════════════════════════════════════════════════════
-- 🎯 ESTADO COMPARTIDO: Spawn Manager ↔ NPCs
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-15
-- ═══════════════════════════════════════════════════════
--
--   Puente entre npc_spawn_manager (features/npc) y los scripts
--   de los NPCs (main/npc.script, features/cat/cat.script), sin
--   adivinar rutas (GOTCHA #4 — las instancias de los NPCs viven
--   anidadas en /level2/npcs/..., pero ningún script necesita
--   conocer esa jerarquía):
--
--     1. Cada NPC registra su URL REAL (go.get_id(), que devuelve
--        la ruta completa) en init().
--     2. El gestor descubre los puntos de spawn del editor
--        (spawn_npc_cat, spawn_npc_01..NN) y los registra aquí.
--     3. El gestor coloca a cada NPC en su punto de spawn, o en el
--        staging (-100, 0, 0.1) si está bloqueado, y le avisa con
--        "npc_spawn_updated" para que re-ancle su patrulla.
--
--   Mecanismo idéntico a food_spawn_state.lua / spray_spawn_state.lua.

local M = {}

-- ⚙️ TIPOS DE NPC (propiedad npc_type del editor, ver main/npc.script):
--   • quiz_general    → quiz de arqueología/genérico (pool_1). Es el DEFAULT.
--   • quiz_restoration → quiz de restauración (pool_2): reutilizable, punto
--                        de restauración, cooldown propio (restauradora).
--   • quiz_false      → conversación de ambiente sin quiz (npc_XX_talk_N).
--   Un NPC sin propiedad configurada registra "quiz_general" (fallback).
M.NPC_TYPE_QUIZ_GENERAL = "quiz_general"
M.NPC_TYPE_QUIZ_RESTORATION = "quiz_restoration"
M.NPC_TYPE_QUIZ_FALSE = "quiz_false"

-- { [npc_id] = npc_type } — tipo de cada NPC, registrado por su
-- npc.script en init() junto a la URL real. Lo consultan el
-- dialogue_manager (flujo de restauración), el HUD (recordatorios/icono)
-- y el inventory_manager (icono de la restauradora) sin depender del id.
M.npc_types = {}

-- URL del gestor de spawn (registrada por npc_spawn_manager.script en init)
M.manager_url = nil

-- Flag para que el gestor registre su listener de desbloqueo UNA sola vez.
-- game_state es un módulo persistente (misma tabla en toda la partida): sin
-- este flag, cada recarga del nivel añadiría otro listener y cada unlock
-- dispararía mensajes duplicados (idempotentes pero redundantes).
M.unlock_listener_registered = false

-- { [npc_id] = url } — URLs reales de cada NPC ("cat", "npc_01", ...)
-- Registradas por cada npc.script / cat.script en su init().
M.npc_urls = {}

-- { [npc_id] = vmath.vector3 } — posición de cada punto de spawn
-- del editor. Registradas por npc_spawn_manager.script.
M.spawn_points = {}

-- 🐾 Flag RUNTIME (no se persiste): el gato está en modo mascota siguiendo
--    al jugador. Mientras esté activo, los sensores de interacción
--    (mobile_interact.script) EXCLUYEN al gato de los candidatos del botón
--    option: en PET sigue al jugador a pet_follow_dist (~60 uu, dentro de la
--    caja del sensor) y, de no filtrarse, siempre ganaría la selección de
--    "más cercano" bloqueando la interacción con NPCs/objetos. Lo gestiona
--    cat.script (set en on_interact al entrar en PET, clear en exit_pet —
--    el único punto de salida — y en npc_spawn_updated por seguridad).
M.cat_pet_active = false

-- Marcar / desmarcar el estado de mascota del gato (runtime-only)
function M.set_cat_pet_active(active)
	M.cat_pet_active = active and true or false
end

-- ¿El gato está en modo mascota? (lectura barata: campo de tabla, cero aloc)
function M.is_cat_pet_active()
	return M.cat_pet_active
end

-- Registrar la URL real de un NPC
function M.register_npc(npc_id, url)
	M.npc_urls[npc_id] = url
end

-- Obtener la URL real de un NPC (nil si aún no se registró / no existe)
function M.get_npc_url(npc_id)
	return M.npc_urls[npc_id]
end

-- Obtener TODAS las URLs de NPCs registradas (tabla npc_id → url, solo
-- lectura). La usa npc_patrol.lua para la separación entre NPCs (Ago 2026).
function M.get_all_npc_urls()
	return M.npc_urls
end

-- Registrar el tipo de un NPC (llamado por npc.script en init con el valor
-- de su propiedad npc_type; nil → quiz_general por defecto)
function M.register_npc_type(npc_id, npc_type)
	M.npc_types[npc_id] = npc_type or M.NPC_TYPE_QUIZ_GENERAL
end

-- Obtener el tipo de un NPC (nil si aún no se registró / no existe)
function M.get_npc_type(npc_id)
	return M.npc_types[npc_id]
end

-- Buscar el PRIMER NPC registrado con un tipo dado (p. ej. la restauradora
-- con quiz_restoration). Devuelve el npc_id o nil si no hay ninguno.
function M.find_npc_by_type(npc_type)
	for npc_id, t in pairs(M.npc_types) do
		if t == npc_type then
			return npc_id
		end
	end
	return nil
end

-- Registrar la posición de un punto de spawn
function M.register_spawn_point(npc_id, position)
	M.spawn_points[npc_id] = position
end

-- Obtener la posición de un punto de spawn (nil si no existe)
function M.get_spawn_point(npc_id)
	return M.spawn_points[npc_id]
end

return M
