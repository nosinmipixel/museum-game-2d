-- main/cabinet_state.lua
-- ═══════════════════════════════════════════════════════
-- 🗄️ ESTADO COMPARTIDO: ARMARIOS (activación por estado)
-- ═══════════════════════════════════════════════════════
--
--   Registro de armarios con caja de cobertura (centro + semiextensión XY) y
--   estado abierto/cerrado. Lo usa office_cabinet.script (registro + estado,
--   notificado al FINALIZAR la animación de apertura/cierre) y los objetos
--   interiores (botes de spray/insecticida, futuro mobiliario) para saber si
--   están ocultos tras un armario CERRADO.
--
--   Por qué existe (GOTCHA #31): el z es el mecanismo de ocultación del
--   proyecto, pero la física es 2D — el cursor envía hover a TODOS los objetos
--   solapados, incluidos los tapados. Modelo de ocultación (Ago 2026,
--   simplificado): el armario ya NO anima su z (z estable en el editor); el
--   objeto interior consulta get_open(pos) en su update() y se ACTIVA/DESACTIVA
--   (sprite + colisiones) según el estado de su armario — desactivado no puede
--   recibir hover ni clic. is_covered() queda como defensa genérica del picking
--   (sensor móvil: excluir candidatos tapados por un armario cerrado).
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-17
-- ═══════════════════════════════════════════════════════

local M = {}

-- [tostring(url)] = { center = v3, half = v3 (semiextensión XY del box), open = bool }
local cabinets = {}

-- Registrar un armario con su caja de cobertura (centro y semiextensión del
-- collisionobject_cursor). Lo llama office_cabinet.script en init(); re-registrar
-- sobrescribe (recarga de nivel segura, patrón del proyecto: reset() existe pero
-- no hay punto de llamada — los GOs estáticos se re-registran al re-crearse).
function M.register(url, center, half)
	cabinets[tostring(url)] = {
		center = center,
		half = half,
		open = false,
	}
end

-- Actualizar el estado abierto/cerrado (open_cabinet/close_cabinet).
function M.set_open(url, is_open)
	local c = cabinets[tostring(url)]
	if c then
		c.open = is_open == true
	end
end

-- ¿Está `pos` (XY) dentro de la caja de cobertura de un armario CERRADO?
-- Defensa genérica del picking: el sensor móvil excluye candidatos tapados por
-- un armario cerrado (los botes ya se desactivan por su cuenta vía get_open,
-- pero cualquier objeto interior futuro que no desactive su colisión queda
-- cubierto). ⚠️ exclude_url (opcional): la caja del PROPIO armario se salta —
-- el GO del armario está dentro de su propia caja, y sin esto el armario
-- cerrado se autoexcluiría del sensor (nunca seleccionable en móvil).
function M.is_covered(pos, exclude_url)
	local exclude_str = exclude_url and tostring(exclude_url)
	for key, c in pairs(cabinets) do
		if not c.open and key ~= exclude_str then
			local dx = pos.x - c.center.x
			local dy = pos.y - c.center.y
			if math.abs(dx) <= c.half.x and math.abs(dy) <= c.half.y then
				return true
			end
		end
	end
	return false
end

-- Centro de la caja de interacción de un armario (nil si no está registrado).
-- Lo usa el sensor móvil para puntuar contra la caja REAL y no contra el GO
-- (el GO del armario está 54 uds por encima del pasillo — GOTCHA #31).
function M.get_center(url)
	local c = cabinets[tostring(url)]
	if c then return c.center end
	return nil
end

-- ¿Es un armario registrado y actualmente ABIERTO? Lo usa el sensor móvil para
-- no competir con el contenido de un armario abierto (ver has_candidate_inside).
function M.is_open(url)
	local c = cabinets[tostring(url)]
	return c ~= nil and c.open
end

-- ¿Hay algún OTRO candidato dentro de la caja de cobertura de este armario?
-- Lo usa el sensor móvil: un armario ABIERTO con contenido (el bote interior,
-- que se activa al terminar la animación de apertura) se omite como objetivo —
-- el bote es lo que el jugador quiere recoger. Los GOs de puertas quedan fuera
-- de la caja (están más abajo, en la línea del muro) y los botes de otros
-- armarios también. Una vez recogido el bote, el armario vuelve a ser elegible
-- (puede cerrarse desde móvil).
function M.has_candidate_inside(url, candidate_urls)
	local c = cabinets[tostring(url)]
	if not c then return false end
	for _, other in ipairs(candidate_urls) do
		if other ~= url and go.exists(other) then
			local pos = go.get_position(other)
			local dx = pos.x - c.center.x
			local dy = pos.y - c.center.y
			if math.abs(dx) <= c.half.x and math.abs(dy) <= c.half.y then
				return true
			end
		end
	end
	return false
end

-- ¿Está `pos` (XY) dentro de la caja de algún armario? Devuelve el estado del
-- armario que lo contiene:
--   nil    → no está dentro de ningún armario (objeto siempre visible/activo)
--   true   → dentro de un armario ABIERTO (activo: visible e interactuable)
--   false  → dentro de un armario CERRADO (oculto: sprite y colisiones off)
-- Lo usan los objetos interiores (botes de spray/insecticida) en su update():
-- activación cuando la animación de apertura finaliza y desactivación al
-- cerrar la puerta sin recogerlos. Iterar pocos armarios por frame es
-- despreciable.
function M.get_open(pos)
	for _, c in pairs(cabinets) do
		local dx = pos.x - c.center.x
		local dy = pos.y - c.center.y
		if math.abs(dx) <= c.half.x and math.abs(dy) <= c.half.y then
			return c.open == true
		end
	end
	return nil
end

-- Limpiar el registro (recarga de nivel; los armarios se re-registran en init).
function M.reset()
	cabinets = {}
end

return M
