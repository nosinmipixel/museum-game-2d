-- main/text_loader.lua
-- ═══════════════════════════════════════════════════════
-- 🌐 CARGADOR CENTRALIZADO DE TEXTOS MULTI-IDIOMA
-- ═══════════════════════════════════════════════════════
--
--   En Defold, require() solo resuelve módulos .lua dentro del
--   path de Lua estándar (básicamente main/). Para cargar
--   archivos .lua desde otras rutas (assets/texts/), usamos
--   sys.load_resource() + loadstring().
--
--   Uso desde cualquier script:
--     local text_loader = require "main.text_loader"
--     local texts = text_loader.load("main")          -- idioma actual (get_current_lang)
--     local texts = text_loader.load("main", "en")    -- forzar inglés
--     local texts = text_loader.load("exhibition")    -- textos de exposición
--
--   Categorías disponibles:
--     "main"       → main_text_{lang}   (diálogos, quizzes, personajes)
--     "exhibition" → exhibition_text_{lang} (objetos en sala de exposiciones)
--     "general"    → general_text_{lang}  (alertas, hints, inventario: incluye
--                                          item_names/periods de los objetos)
--     "books"      → books_text_{lang}     (textos de libros de la biblioteca)
--
--   El cargador:
--     1. Busca el archivo para el idioma solicitado
--     2. Si no existe, cae a español (es) como fallback
--     3. Cachea los datos cargados (evita recargas innecesarias)
--     4. Soporta recarga en caliente con reload()
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-15
-- ═══════════════════════════════════════════════════════

local M = {}
local cache = {}

-- ═══════════════════════════════════════════════════════
-- 📋 REGISTRO DE ARCHIVOS POR CATEGORÍA E IDIOMA
-- ═══════════════════════════════════════════════════════
-- Añade aquí nuevos idiomas cuando estén traducidos.
-- El español (es) es el idioma base y fallback por defecto.
--
-- NOTA: Usamos rutas de recurso (sys.load_resource) en lugar de
-- módulos Lua (require) porque Defold no resuelve require() fuera
-- del directorio main/.
-- ═══════════════════════════════════════════════════════

local TEXT_FILES = {
	main = {
		es = "/assets/texts/main_text_es.lua",
		en = "/assets/texts/main_text_en.lua",
	},
	exhibition = {
		es = "/assets/texts/exhibition_text_es.lua",
		en = "/assets/texts/exhibition_text_en.lua",
	},
	general = {
		es = "/assets/texts/general_text_es.lua",
		en = "/assets/texts/general_text_en.lua",
	},
	books = {
		es = "/assets/texts/books_text_es.lua",
		en = "/assets/texts/books_text_en.lua",
	},
}

-- ═══════════════════════════════════════════════════════
-- 🚀 CARGA DE TEXTOS (sys.load_resource + loadstring)
-- ═══════════════════════════════════════════════════════

--- Carga un archivo .lua desde el game archive y ejecuta su código.
--- @param file_path string  Ruta del recurso (ej: "/assets/texts/main_text_es.lua")
--- @return table|nil, string|nil  (tabla de datos, mensaje de error)
local function load_text_file(file_path)
	local resource_data = sys.load_resource(file_path)
	if not resource_data then
		return nil, "Archivo no encontrado: " .. file_path
	end

	-- loadstring compila el código Lua y devuelve una función
	-- (nuestros archivos .lua devuelven una tabla con return {...})
	local loader, syntax_err = loadstring(resource_data, file_path)
	if not loader then
		return nil, "Error de sintaxis en " .. file_path .. ": " .. tostring(syntax_err)
	end

	-- Ejecutar el código cargado con pcall para capturar errores en tiempo real
	local ok, result = pcall(loader)
	if not ok then
		return nil, "Error de ejecución en " .. file_path .. ": " .. tostring(result)
	end

	return result, nil
end

--- Carga los textos de una categoría en el idioma indicado.
--- @param category string  Categoría: "main", "exhibition", "general" o "books"
--- @param lang string|nil  Código de idioma: "es", "en", etc. Por defecto el idioma actual del juego (get_current_lang)
--- @return table  Tabla con los textos (vacía si hay error)
function M.load(category, lang)
	-- 🔤 Sin idioma explícito → usar el idioma ACTUAL del juego (no "es" a
	--    ciegas). Sin esto, cualquier load() sin lang cargaba español siempre
	--    (p. ej. el HUD al arrancar con inglés persistido desde la intro) y los
	--    textos quedaban en español hasta un cambio de idioma en caliente.
	lang = lang or M.get_current_lang()
	local cache_key = category .. "_" .. lang

	-- Si ya está en caché, devolverlo directamente
	if cache[cache_key] then
		return cache[cache_key]
	end

	-- Validar categoría
	local files = TEXT_FILES[category]
	if not files then
		print("ERROR [TextLoader] Categoría desconocida: '" .. tostring(category) .. "'")
		return {}
	end

	-- Resolver ruta del archivo con fallback a español
	local file_path = files[lang] or files["es"]
	if not file_path then
		print("ERROR [TextLoader] No hay archivo para " .. category .. "/" .. lang .. " ni fallback a español")
		return {}
	end

	-- Cargar el archivo Lua usando sys.load_resource + loadstring
	local result, err = load_text_file(file_path)
	if result then
		cache[cache_key] = result
		-- print("[TextLoader] Cargado: " .. file_path)
		return result
	else
		print("ERROR [TextLoader] " .. tostring(err))
		-- Fallback: si el idioma solicitado no era español, intentar español
		if lang ~= "es" then
			print("[TextLoader] Fallback a español para " .. category)
			return M.load(category, "es")
		end
		return {}
	end
end

--- Recarga los textos de una categoría (útil si se cambia idioma en caliente).
--- @param category string  Categoría a recargar
--- @param lang string  Nuevo idioma
--- @return table  Textos recargados
function M.reload(category, lang)
	lang = lang or "es"

	-- Limpiar toda la cache de esta categoría (todos los idiomas)
	local files = TEXT_FILES[category]
	if files then
		for l, _ in pairs(files) do
			local old_key = category .. "_" .. l
			cache[old_key] = nil
		end
	end

	return M.load(category, lang)
end

--- Obtiene el código de idioma desde game_state.
--- Conveniencia para no tener que importar game_state solo para esto.
--- @return string  Código de idioma ("es", "en", etc.)
function M.get_current_lang()
	local game_state = require "main.game_state"
	return game_state.get_global("language") or "es"
end

return M
