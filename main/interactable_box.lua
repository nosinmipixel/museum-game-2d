-- main/interactable_box.lua
-- ═══════════════════════════════════════════════════════
-- 🎯 PUNTO DE INTERACCIÓN COMPARTIDO (picking móvil)
-- ═══════════════════════════════════════════════════════
--
--   Registro genérico del PUNTO del mundo donde se interactúa con un objeto
--   (el centro de su collisionobject_cursor). Lo usan los scripts de objetos
--   cuya caja de interacción está DESPLAZADA respecto al GO (las puertas:
--   door_side +27 en x, door_front −10 en y, door_service −5 en y) para que
--   el sensor móvil puntúe contra la zona REAL y no contra el GO (GOTCHA #31).
--
--   Por qué existe (GOTCHA #31): el picking facing-first del sensor mide con
--   la posición del GO. Cuando la caja de interacción está desplazada del GO
--   (p. ej. door_side: GO 27 uds a la izquierda de la hoja), el jugador
--   apoyado en la puerta tiene el GO DETRÁS (dot negativo) y facing-first
--   elige cualquier candidato alineado con su dirección — p. ej. el armario
--   de encima, aunque la puerta esté más cerca (caso door_side4 ↔
--   office_cabinet1, Ago 2026). Puntuar contra el punto registrado hace que
--   la puerta quede DELANTE del jugador cuando se apoya en ella.
--
--   Mismo patrón que cabinet_state: register() en el init() del objeto
--   (re-registrar sobrescribe — recarga de nivel segura). El centro debe
--   COINCIDIR con el collisionobject_cursor del .go (⚠️ actualizar ambos si
--   se mueve la caja en el editor).
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-18
-- ═══════════════════════════════════════════════════════

local cabinet_state = require "main.cabinet_state"

local M = {}

-- [tostring(url)] = v3 (centro del collisionobject_cursor en el mundo)
local points = {}

-- Registrar el punto de interacción de un objeto (centro del
-- collisionobject_cursor, coordenadas del mundo). Lo llama el objeto en su
-- init(); re-registrar sobrescribe (recarga de nivel segura).
function M.register(url, point)
	points[tostring(url)] = point
end

-- Punto de interacción registrado (nil si el objeto no registra uno → el
-- consumidor usa go.get_position(url) como fallback).
function M.get_point(url)
	return points[tostring(url)]
end

-- 📏 PUNTO DEL MUNDO contra el que medir/puntuar la interacción con un objeto
-- (compartido por cursor.script y mobile_interact.script, Ago 2026): el punto
-- registrado (centro de la caja cursor — puertas), el centro de la caja de
-- cobertura del armario, o la posición del GO como fallback. Los GOs no
-- representan dónde se interactúa (GOTCHA #31) — medir contra el GO dejaría
-- puertas/armarios con rangos desplazados (door_side: GO 27 uds a la izquierda
-- de la hoja). Uso: distancias de interacción (interaction_range) y scoring.
function M.world_point(url)
	local pt = M.get_point(url)
	if pt then return pt end
	local center = cabinet_state.get_center(url)
	if center then return center end
	return go.get_position(url)
end

-- Limpiar el registro (recarga de nivel; los objetos se re-registran en init).
function M.reset()
	points = {}
end

return M
