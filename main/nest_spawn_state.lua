-- main/nest_spawn_state.lua
-- ═══════════════════════════════════════════════════════
-- 🪺 ESTADO COMPARTIDO: CONTENEDOR ↔ NIDO
-- ═══════════════════════════════════════════════════════
--
--   Módulo compartido entre nest_container (creador) y
--   nest.script (consumidor). Espejo de spray_spawn_state.lua.
--
--   - pending_spawn: datos del nido a crear (position, index)
--   - container_url: URL del contenedor para notificar destrucción
--   - destroyed: registro de ids de nidos destruidos (flags)
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-17
-- ═══════════════════════════════════════════════════════

local M = {}

-- ───────────────────────────────────────────────────────
-- 📦 PENDING SPAWN (escrito ANTES de factory.create)
-- ───────────────────────────────────────────────────────
-- Contenido: { index = int, position = vmath.vector3 }
-- El init() del nido lo lee y lo limpia inmediatamente.
M.pending_spawn = nil

-- ───────────────────────────────────────────────────────
-- 🔗 URL del contenedor
-- ───────────────────────────────────────────────────────
-- El contenedor escribe su url() en init(); el nido la
-- usa para notificar su destrucción.
M.container_url = nil

-- ───────────────────────────────────────────────────────
-- 💀 REGISTRO DE NIDOS DESTRUIDOS (flag de módulo)
-- ───────────────────────────────────────────────────────
-- GOTCHA #33: flags de módulo, no mensajes — múltiples
-- instancias con ids dinámicos. Los ids se guardan como
-- claves en una tabla hash.
local destroyed = {}

function M.mark_destroyed(go_id)
	destroyed[go_id] = true
end

function M.is_destroyed(go_id)
	return destroyed[go_id] == true
end

-- Limpiar el registro completo (reset entre partidas)
function M.reset()
	destroyed = {}
	M.pending_spawn = nil
	M.container_url = nil
end

return M
