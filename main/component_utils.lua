-- main/component_utils.lua
-- ═══════════════════════════════════════════════════════
-- 🧩 UTILIDADES DE COMPONENTES
-- ═══════════════════════════════════════════════════════
--
--   Helpers para operar con componentes de Defold de forma
--   fiable. Patrón local M = {} ... return M (regla #9 de
--   docs/DEFOLD_LUA_STANDARDS.md).
--
--   ⚠️ go.exists() NO es fiable para componentes: ignora el
--   fragmento de la URL y solo comprueba la existencia del
--   game object. Para comprobar la existencia real de un
--   componente hay que usar pcall(go.get, url, prop).
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-15
-- ═══════════════════════════════════════════════════════

local M = {}

--- Comprueba si un componente existe en runtime.
-- @param url  URL del componente (con fragmento, ej: msg.url(nil, nil, "sprite"))
-- @param prop Propiedad válida para el tipo de componente:
--             "tint" → sprites      "gain" → sonidos
-- @return true si el componente existe, false si no
function M.component_exists(url, prop)
	local ok, _ = pcall(go.get, url, prop)
	return ok
end

return M
