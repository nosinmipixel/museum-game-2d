-- main/collectibles_data.lua
-- ═══════════════════════════════════════════════════════
-- 📦 DATOS DE COLECCIONABLES: 5 PERIODOS, 10 OBJETOS
-- ═══════════════════════════════════════════════════════
--
--   Este es el ÚNICO archivo que necesita modificarse para
--   añadir nuevos periodos u objetos. El resto del sistema
--   se adapta automáticamente.
--
--   Para añadir un objeto nuevo:
--     1. Agregarlo a M.items con un ID único
--     2. Asignarle el periodo correspondiente
--     3. El sistema lo detecta automáticamente
--
--   Para añadir un periodo nuevo:
--     1. Agregarlo a M.periods con orden y display_name
--     2. Crear objetos con ese period_key
--     3. El sistema lo ordena correctamente
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-15
-- ═══════════════════════════════════════════════════════

local M = {}

-- ═══════════════════════════════════════════════════════
-- 🏛️ PERIODOS HISTÓRICOS
-- ═══════════════════════════════════════════════════════
--   order: determina el orden en que se muestran/completan
--   display_name: nombre visible para el HUD
-- ═══════════════════════════════════════════════════════
M.periods = {
	pal = { order = 1, display_name = "Paleolítico" },
	neo = { order = 2, display_name = "Neolítico" },
	bro = { order = 3, display_name = "Bronce" },
	ibe = { order = 4, display_name = "Ibérico" },
	rom = { order = 5, display_name = "Romano" },
}

-- ═══════════════════════════════════════════════════════
-- 🏺 OBJETOS COLECCIONABLES
-- ═══════════════════════════════════════════════════════
--   id:         clave única (string), usada para persistencia
--   item_id:    ID numérico que referencia exhibition_text
--   name:       nombre corto para el HUD
--   period:     clave del periodo (debe existir en M.periods)
--   requires_restoration: true = necesita pasar por restauración
--   sprite_id:  animación del sprite en el atlas
-- ═══════════════════════════════════════════════════════
M.items = {
	-- Paleolítico (2 objetos)
	pal_bifaz = {
		id = "pal_bifaz",
		item_id = 15741,
		name = "Bifaz musteriense",
		period = "pal",
		-- 🛠️ Restauración: uno por periodo (decisión de diseño, Ago 2026)
		requires_restoration = true,
		sprite_id = "15741",
	},
	pal_azagaya = {
		id = "pal_azagaya",
		item_id = 43452,
		name = "Azagaya monobiselada decorada",
		period = "pal",
		requires_restoration = false,
		sprite_id = "43452",
	},

	-- Neolítico (2 objetos)
	neo_cantaro = {
		id = "neo_cantaro",
		item_id = 4225,
		name = "Cántaro cardial",
		period = "neo",
		-- 🛠️ Restauración: uno por periodo (decisión de diseño, Ago 2026)
		requires_restoration = true,
		sprite_id = "4225",
	},
	neo_hacha = {
		id = "neo_hacha",
		item_id = 5094,
		name = "Hacha de piedra pulida",
		period = "neo",
		requires_restoration = false,
		sprite_id = "5094",
	},

	-- Bronce (2 objetos)
	bro_quesera = {
		id = "bro_quesera",
		item_id = 7622,
		name = "Quesera troncocónica",
		period = "bro",
		-- 🛠️ Restauración: uno por periodo (decisión de diseño, Ago 2026)
		requires_restoration = true,
		sprite_id = "7622",
	},
	bro_hacha = {
		id = "bro_hacha",
		-- 🛠️ (Ago 2026) item_id corregido: apuntaba a 3098 (ficha de una HOZ en
		-- exhibition_text) — la ficha mostrada para el "Hacha de cobre" era la
		-- de otro objeto. El id real de esta pieza es 7623 (coherente con su
		-- sprite_id y la imagen 7623_hacha.png de la sala).
		item_id = 7623,
		name = "Hacha de cobre",
		period = "bro",
		requires_restoration = false,
		sprite_id = "7623",
	},

	-- Ibérico (2 objetos)
	ibe_pebetero = {
		id = "ibe_pebetero",
		item_id = 1905,
		name = "Pebetero ibérico",
		period = "ibe",
		-- 🛠️ Restauración: uno por periodo (decisión de diseño, Ago 2026)
		requires_restoration = true,
		sprite_id = "1905",
	},
	ibe_kili = {
		id = "ibe_kili",
		item_id = 22354,
		name = "Unidad de Kili",
		period = "ibe",
		requires_restoration = false,
		sprite_id = "22354",
	},

	-- Romano (2 objetos)
	rom_lucerna = {
		id = "rom_lucerna",
		item_id = 132,
		name = "Lucerna romana",
		period = "rom",
		-- 🛠️ Restauración: uno por periodo (decisión de diseño, Ago 2026)
		requires_restoration = true,
		sprite_id = "132",
	},
	rom_copa = {
		id = "rom_copa",
		item_id = 248,
		name = "Copa de terra sigillata",
		period = "rom",
		requires_restoration = false,
		sprite_id = "248",
	},
}

-- ═══════════════════════════════════════════════════════
-- 📋 HELPER: ORDENAR OBJETOS POR PERIODO Y NOMBRE
-- ═══════════════════════════════════════════════════════
function M.get_sorted_items()
	local sorted = {}
	for id, item in pairs(M.items) do
		table.insert(sorted, item)
	end

	table.sort(sorted, function(a, b)
		local order_a = M.periods[a.period] and M.periods[a.period].order or 999
		local order_b = M.periods[b.period] and M.periods[b.period].order or 999
		if order_a ~= order_b then
			return order_a < order_b
		end
		return a.name < b.name
	end)

	return sorted
end

-- ═══════════════════════════════════════════════════════
-- 🔍 HELPER: CONVERTIR HASH A STRING LEGIBLE
-- ═══════════════════════════════════════════════════════
-- En Defold, tostring(hash("pal")) devuelve "hash:pal" o "pal" según la versión.
-- Para ser robustos, extraemos solo el nombre eliminando el prefijo "hash:".
-- ═══════════════════════════════════════════════════════
function M.hash_to_str(h)
	local str
	if type(h) == "string" then
		str = h
	elseif type(h) == "number" then
		-- Si por serialización llegó como número, no podemos recuperar el string original
		-- Esto es un error: debería haberse enviado como tostring() desde el origen
		print("ERROR [hash_to_str] Recibido número en lugar de hash/string: " .. tostring(h))
		return tostring(h)
	elseif type(h) == "hash" or type(h) == "userdata" then
		str = tostring(h)
	else
		return tostring(h)
	end

	-- Limpiar el string: eliminar prefijo "hash:", espacios, corchetes
	-- Defold puede devolver tostring(hash("pal")) en varios formatos:
	--   "pal"              (moderno, sin prefijo)
	--   "hash:pal"         (con prefijo, sin espacios)
	--   "hash: [pal]"      (con prefijo, espacios y corchetes) ← Este es el formato actual
	-- Extraer el contenido después de "hash:" si existe
	local clean = str:match("hash:%s*%[(.-)%]$")  -- "hash: [pal]" → "pal"
	               or str:match("hash:(.+)$")       -- "hash:pal" → "pal"
	               or str                            -- "pal" → "pal"

	-- Eliminar cualquier espacio sobrante
	clean = clean:match("^%s*(.-)%s*$") or clean

	return clean
end

return M
