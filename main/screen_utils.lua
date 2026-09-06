-- main/screen_utils.lua
-- ═══════════════════════════════════════════════════════
-- 📐 CONVERSIÓN COORDENADAS MUNDO → PANTALLA
-- ═══════════════════════════════════════════════════════
--
--   Módulo compartido para eliminar la duplicación de
--   world_to_screen() que existía en 3 archivos:
--     • dialogue_manager.script   (inline)
--     • exhibition_manager.script (función local)
--     • exhibition_object.script  (función local)
--   Y ahora también FUENTE ÚNICA de la escala display (DPR) para el
--   GOTCHA #11 (usada por interactive.gui_script para el mínimo de toque).
--
--   ⚠️ SALIDA: screen space de Defold (origen (0,0) en la esquina
--   inferior-izquierda de la ventana, eje Y hacia arriba, en píxeles).
--   Es el MISMO espacio que esperan gui.set_screen_position() y
--   gui.screen_to_local(). Las GUI deben usar esas funciones (NO
--   gui.set_position(), que espera coordenadas LOCALES de la escena GUI).
--
--   ⚠️ GOTCHA #11 + RESIZE: la proyección mundo→pantalla se calcula con
--   window.get_size() (fórmula manual) porque es el ÚNICO espacio
--   consistente con gui.set_screen_position() en todas las plataformas:
--     • En HTML5 con high_dpi=1, window.get_size() devuelve px FÍSICOS
--       (CSS × DPR) y set_screen_position también trabaja en px físicos
--       (verificado Ago 2026: motor convierte con FIT sobre tamaño físico,
--       roundtrip dev==env cerrado).
--     • ⚠️ NO usar camera.world_to_screen() aquí: en HTML5 high_dpi esa
--       API devuelve el punto en px LÓGICOS (CSS), que NO coincide con el
--       espacio de set_screen_position (px físicos) → el globo se desplaza
--       por el factor DPR (verificado empíricamente Ago 2026: empeoró el
--       móvil; en PC DPR=1 ambos espacios coinciden y parecía correcto).
--     • ⚠️ PERO el término de OFFSET (world−cam)×zoom SÍ debe escalarse
--       por DPR: el render proyecta el mundo en espacio CSS y lo escala
--       ×DPR sobre el canvas físico, mientras que el CENTRO de pantalla
--       (win/2 físico) ya incluye el factor. Sin este ajuste, el globo
--       queda desplazado hacia el centro por offset×(DPR−1) en móvil
--       (verificado con [GLOBO-FIT] Ago 2026: win=2400x1080 dpr=2.5,
--       env=(1280,699), motor FIT local=(697,497) → desplazamiento real).
--     • El OFFSET vertical (gap globo↔personaje) SÍ se compensa con DPR:
--       BUBBLE_OFFSET_Y_CSS → valor × get_display_scale() px físicos → el
--       hueco se ve igual en todos los dispositivos (Ago 2026: bajado de 50
--       a 5 y luego a 0 en prueba, tras anclar los globos al borde superior
--       del sprite; el 5 queda conservado en la constante por si se revierte).
--
--   Si cambia el zoom de la cámara (orthographic_zoom), actualizar
--   ORTHO_ZOOM (coincide con la cámara de level_01).
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-15
-- ═══════════════════════════════════════════════════════

local M = {}

-- Zoom de la cámara ortográfica (coincide con orthographic_zoom del componente camera)
local ORTHO_ZOOM = 2.0

-- Offset vertical del globo/panel sobre el ANCLA, en CSS px: gap CONSTANTE
-- en todos los dispositivos. En runtime se convierte a px físicos con
-- get_display_scale() (DPR en HTML5 high_dpi, escala del sistema en native).
-- 📏 Ago 2026: 50 → 5 → 0 (prueba) tras anclar los globos al borde superior
-- del sprite; el hueco se mide desde el borde, no del centro.
-- ⚠️ Compartido con todos los globos (exhibición + diálogos player/NPC).
-- 🔧 Prueba Ago 2026: gap a 0 px (globo pegado al sprite). Valor anterior
--    conservado por si hay que revertir: local BUBBLE_OFFSET_Y_CSS = 5
local BUBBLE_OFFSET_Y_CSS = 0

-- ⚠️ La URL de la cámara NO se cachea a nivel de módulo: msg.url(nil, path)
-- se resuelve relativo al socket/colección del script que ejecuta el require,
-- y el código de módulo corre UNA sola vez (en el primer require). Si ese
-- primer require llega de un gui_script u otro contexto sin /camera, la URL
-- queda ligada al socket equivocado y go.exists() devolvería siempre false
-- (cámara asumida en (0,0,0) → globos desplazados fuera de pantalla en TODAS
-- las plataformas, verificado Ago 2026). Se resuelve dentro de world_to_screen:
-- allí el socket es el del script que llama (level_01 → /camera existe).

-- 📏 Escala display (px físicos por px lógicos) — FUENTE ÚNICA del proyecto
-- para la compensación DPR (GOTCHA #11). Usa window.get_display_scale()
-- (API del motor desde Defold 1.4: devicePixelRatio en HTML5, escala del
-- sistema en native). Fallback al patrón html5.run de main/platform.lua
-- (síncrono, devuelve string; el API viejo luaCallback está ELIMINADO en
-- 1.13) y finalmente 1. pcall por seguridad (cross-platform).
function M.get_display_scale()
	local ok, scale = pcall(function() return window.get_display_scale() end)
	if ok and scale and scale > 0 then return scale end
	if type(html5) == "table" and type(html5.run) == "function" then
		local ok2, res = pcall(function() return html5.run("window.devicePixelRatio") end)
		local dpr = ok2 and tonumber(res)
		if dpr and dpr > 0 then return dpr end
	end
	return 1
end

-- Convierte coordenadas del mundo del juego a coordenadas de pantalla (screen space)
-- @param world_pos vmath.vector3 Posición en el mundo del juego
-- @param anchor_offset_y number|nil Desplazamiento vertical del ANCLA en unidades
--        de mundo (p. ej. media altura del sprite, para anclar el globo al borde
--        superior del objeto en vez del centro del GO). Se proyecta igual que el
--        mundo (×zoom×DPR). nil/0 = ancla en la propia posición del GO
--        (comportamiento histórico: NPCs, objetos completados de la vitrina).
-- @return vmath.vector3 Posición en píxeles de pantalla (origen abajo-izquierda, Y hacia arriba)
function M.world_to_screen(world_pos, anchor_offset_y)
	-- Gap en px físicos: BUBBLE_OFFSET_Y_CSS × escala display (GOTCHA #11).
	-- En native (escala 1.0) queda igual que siempre; en HTML5 high_dpi
	-- (DPR 2-3) crece para que el hueco se vea constante en px reales.
	local offset_y = BUBBLE_OFFSET_Y_CSS * M.get_display_scale()

	-- 📏 Ago 2026: el ancla del mundo se desplaza ANTES de proyectar (mismo
	-- tratamiento que el mundo: ×zoom×DPR). anchor_offset_y va en uds de mundo.
	local anchor_y = world_pos.y + (anchor_offset_y or 0)

	local window_width, window_height = window.get_size()

	-- Posición actual de la cámara. URL resuelta AQUÍ (no a nivel de módulo):
	-- con socket nil se liga al socket del llamador (level_01), donde /camera existe.
	local cam_pos = go.exists("/camera") and go.get_position("/camera") or vmath.vector3(0, 0, 0)

	local screen_pos = vmath.vector3()
	-- ⚠️ El offset (world−cam)×zoom se escala por DPR: el render proyecta el
	-- mundo en espacio CSS y lo escala ×DPR sobre el canvas físico; el centro
	-- (win/2 físico) ya incluye el factor. En native/PC DPR=1 → igual que antes.
	local dpr = M.get_display_scale()
	screen_pos.x = (window_width / 2) + ((world_pos.x - cam_pos.x) * ORTHO_ZOOM) * dpr
	screen_pos.y = (window_height / 2) + ((anchor_y - cam_pos.y) * ORTHO_ZOOM) * dpr + offset_y
	screen_pos.z = 0

	return screen_pos
end

return M
