-- main/gui_touch.lua
-- ═══════════════════════════════════════════════════════
-- 📱 DIANA TÁCTIL AMPLIADA — GOTCHA #13 (docs/DEV_GOTCHAS.md)
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-15
-- ═══════════════════════════════════════════════════════
-- gui.pick_node usa el boundary del nodo, que INCLUYE el scale (verificado en
-- el código fuente del motor 1.13: engine/gui/src/gui.cpp → PickNode usa
-- CALCULATE_NODE_BOUNDARY | CALCULATE_NODE_INCLUDE_SIZE). Por tanto, escalar
-- un nodo SOLO en táctil agranda a la vez el visual y el área de pick.
--
-- En landscape móvil la GUI se reduce con FIT (~0.56× para 926×428 CSS), así
-- que un botón de 64 uu queda en ~36 px CSS (< 44 px recomendados). Este
-- módulo calcula la ESCALA TOTAL a aplicar para que la altura efectiva del
-- nodo alcance TARGET_HEIGHT_UU en táctil. En PC (o sin detección) devuelve
-- 1.0 → el nodo conserva la escala definida en el editor.
--
-- ⚠️ Si el script tiene hover animado por ESCALA, debe ser RELATIVO a la base
--    (hover = base × factor), nunca valores absolutos (1.0/1.1), para no
--    deshacer la ampliación (patrón de intro/gui/intro.gui_script, Ago 2026).
local config = require "main.config"
local platform = require "main.platform"

local M = {}

-- Altura mínima EFECTIVA de diana en unidades de escena: 88 uu × FIT(~0.56)
-- ≈ 49 CSS px (> 44 px recomendados, con margen). Configurable en
-- config.lua → M.ui_touch.target_height_uu (GOTCHA #13); fallback al valor
-- histórico por convención del proyecto (una clave borrada no rompe nada).
local TARGET_HEIGHT_UU = (config.ui_touch and config.ui_touch.target_height_uu) or 88
-- Tope de la escala total: iconos muy pequeños (16 uu) no se desproporcionan.
-- Mismo origen configurable (M.ui_touch.max_total_scale).
local MAX_TOTAL_SCALE = (config.ui_touch and config.ui_touch.max_total_scale) or 4.0

-- Escala TOTAL a aplicar en táctil para que la altura del nodo alcance la
-- diana. height_uu = gui.get_size(node).y (altura base, sin escala).
-- max_scale (opcional): tope específico para FILAS ESTRECHAS (p. ej. los
-- botones ± de volumen, que conviven con una barra de solo 100 uu — con la
-- diana completa se solapan con la barra y entre sí).
-- Devuelve 1.0 (mantener la escala del editor) en PC / sin detección.
function M.total_scale(height_uu, max_scale)
	if not platform.is_touch() or not height_uu or height_uu <= 0 then
		return 1.0
	end
	local cap = max_scale or MAX_TOTAL_SCALE
	return math.min(cap, math.max(1.0, TARGET_HEIGHT_UU / height_uu))
end

return M
