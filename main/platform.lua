-- main/platform.lua
-- ═══════════════════════════════════════════════════════
-- 📱 DETECCIÓN DE PLATAFORMA (escritorio vs móvil/táctil)
-- ═══════════════════════════════════════════════════════
-- Permite saber en runtime si el juego se ejecuta en un
-- dispositivo táctil (móvil/tableta) o en escritorio.
--
-- HTML5: el módulo html5 de Defold ejecuta JS en el navegador.
--        La detección fiable (2025-2026) combina:
--          • matchMedia('(pointer: coarse)')  ← lo más fiable
--          • navigator.maxTouchPoints > 0
--          • 'ontouchstart' in window
--        ⚠️ IMPORTANTE: la comunicación JS→Lua se hace con
--        html5.run() que es BLOQUEANTE y DEVUELVE el resultado
--        del eval como string (documentado en ref/html5). El API
--        antiguo html5.set_callback() + Module.luaCallback fue
--        ELIMINADO del motor (verificado en wasm 1.13: solo
--        run() y set_interaction_listener()). Llamarlo rompía el
--        init del bootstrap → pantalla negra en PC y móvil.
-- Desktop/Nativo: sys.get_sys_info() → system_name
--        ("Android" / "iPhone OS" → móvil).
--
-- Uso (patrón de módulo compartido como main/game_state.lua):
--   local platform = require "main.platform"
--   platform.detect()                -- una vez, en init() del bootstrap
--   if platform.is_touch() then ... end
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-15
-- ═══════════════════════════════════════════════════════

local config = require "main.config"

local M = {}

-- 🔧 DEBUG granular (sistema make_log, ver main/config.lua):
--    true  = loguea cuando M.DEBUG esté activo
--    false = silenciado (por defecto)
local DEBUG_PLATFORM = false
local dprint = config.make_log(DEBUG_PLATFORM)

-- Estado de la plataforma detectada
M.state = {
	is_html5  = false,   -- ¿Se ejecuta en navegador?
	is_mobile = false,   -- ¿Dispositivo móvil (Android/iOS/tableta)?
	is_touch  = false,   -- ¿Input táctil disponible?
	pointer   = "fine",  -- "fine" (ratón) | "coarse" (táctil)
	_detected = false,   -- ¿Detección completada?
}

-- ═══════════════════════════════════════════════════════
-- DETECCIÓN HTML5 (JS → Lua)
-- ═══════════════════════════════════════════════════════

-- Ejecuta la detección JS de forma SÍNCRONA: html5.run() evalúa el
-- JavaScript y devuelve el resultado como string (bloqueante). Así el
-- estado queda completado en el mismo frame y los consumidores pueden
-- consultar platform.is_detected()/is_touch() inmediatamente.
-- pcall por seguridad: si algo fallara en el navegador, degradamos a
-- escritorio sin romper el init del bootstrap (pantalla negra).
local function detect_html5()
	M.state.is_html5 = true

	-- Detección JS: pointer:coarse es lo más fiable; maxTouchPoints y
	-- ontouchstart cubren navegadores antiguos. La IIFE devuelve '1'/'0'
	-- y html5.run lo entrega como string a Lua.
	local js = [[
		(function() {
			var coarse = window.matchMedia && window.matchMedia('(pointer: coarse)').matches;
			var touch = ('ontouchstart' in window) || (navigator.maxTouchPoints > 0);
			return (coarse || touch) ? '1' : '0';
		})()
	]]
	local flat_js = js:gsub("\n", " ")
	local ok, res = pcall(function() return html5.run(flat_js) end)

	M.state.is_touch  = ok and res == "1"
	M.state.is_mobile = M.state.is_touch  -- coarse → táctil → móvil
	M.state.pointer   = M.state.is_touch and "coarse" or "fine"
	M.state._detected = true
	dprint("[platform] HTML5 detectado: touch=" .. tostring(M.state.is_touch) .. " (ok=" .. tostring(ok) .. ")")
end

-- ═══════════════════════════════════════════════════════
-- DETECCIÓN NATIVA (sys.get_sys_info)
-- ═══════════════════════════════════════════════════════

local function detect_native()
	local info = sys.get_sys_info()
	local system_name = tostring(info.system_name or "")
	-- 'Darwin' queda deliberadamente fuera: es ambiguo (macOS desktop vs iOS)
	-- según versión del motor; mejor falso que clasificar macOS como móvil.
	M.state.is_mobile = (system_name == "Android" or system_name == "iOS"
		or system_name == "iPhone OS")
	M.state.is_touch = M.state.is_mobile
	M.state.pointer = M.state.is_mobile and "coarse" or "fine"
	M.state._detected = true
	dprint("[platform] Nativo detectado: system_name=" .. system_name)
end

-- ═══════════════════════════════════════════════════════
-- API PÚBLICA
-- ═══════════════════════════════════════════════════════

-- Ejecuta la detección según la plataforma de ejecución.
-- Debe invocarse UNA vez, en el init() del bootstrap (main.script),
-- antes de que los consumidores consulten is_touch()/is_mobile().
function M.detect()
	if type(html5) == "table" and type(html5.run) == "function" then
		detect_html5()
	else
		detect_native()
	end
end

function M.is_html5()    return M.state.is_html5 end
function M.is_mobile()   return M.state.is_mobile end
function M.is_touch()    return M.state.is_touch end
function M.pointer_type() return M.state.pointer end
function M.is_detected() return M.state._detected end

return M
