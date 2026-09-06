-- main/save_manager.lua
-- ═══════════════════════════════════════════════════════
-- 💾 IMPORTACIÓN / EXPORTACIÓN de progreso
-- ═══════════════════════════════════════════════════════
-- Permite al jugador exportar su partida como .json y
-- reimportarla más tarde, como copia de seguridad.
--
-- HTML5: usa el módulo html5 de Defold para descargar
--        / subir archivos mediante JavaScript.
-- Desktop: usa sys.save() / sys.load() con nombre fijo.
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-15
-- ═══════════════════════════════════════════════════════

local game_state = require "main.game_state"
local json_util = require "main.json_util"
local persistence = require "main.persistence"

local M = {}

-- Nombre del archivo de exportación para desktop
local EXPORT_FILENAME = "museo_save_export.dat"

-- ============================================
-- HELPERS
-- ============================================

--- Recolecta todos los datos de la partida desde game_state.
local function collect_save_data()
	return {
		version = 2,
		exported_at = os.time(),
		globals = game_state.get_all_globals(),
		npc_progress = game_state.npc_progress,
		quiz_state = game_state.get_quiz_state(),
	}
end

--- Restaura los datos de una partida importada en game_state.
--- @param data table  Datos parseados del JSON
--- @return boolean, string  (éxito, mensaje)
local function restore_save_data(data)
	if not data or type(data) ~= "table" then
		-- 🌐 CLAVE neutra (GOTCHA #37)
		return false, "import_invalid_format"
	end

	if not data.version or data.version < 1 then
		return false, "import_unsupported_version"
	end

	-- Restaurar globals
	if data.globals and type(data.globals) == "table" then
		for k, v in pairs(data.globals) do
			game_state.set_global(k, v)
		end
	end

	-- Restaurar npc_progress
	if data.npc_progress and type(data.npc_progress) == "table" then
		game_state.npc_progress = {}
		for npc_id, progress in pairs(data.npc_progress) do
			game_state.npc_progress[npc_id] = {
				attempt = progress.attempt or 1,
				completed = progress.completed or false,
				available_after = progress.available_after or 0,
				unlocked = (progress.unlocked ~= nil) and progress.unlocked or true,
			}
		end
	end

	-- Restaurar quiz_state
	if data.quiz_state and type(data.quiz_state) == "table" then
		game_state.set_quiz_state(
			data.quiz_state.pool_id,
			data.quiz_state.questions_answered,
			data.quiz_state.current_attempts,
			data.quiz_state.last_question_id
		)
	end

	-- Forzar guardado inmediato
	game_state.flush()

	-- 🌐 CLAVE neutra: el mensaje visible lo resuelve el menú de pausa con
	-- general_text → M.save (GOTCHA #37). Antes: "Partida importada correctamente"
	return true, "import_ok"
end

-- ============================================
-- DETECCIÓN DE PLATAFORMA
-- ============================================

--- Determina si el juego se ejecuta en HTML5 (navegador).
--- El módulo html5 es un built-in global del runtime, no un .lua.
local function is_html5()
	if type(html5) == "table" and type(html5.run) == "function" then
		return true, html5
	end
	return false, nil
end

-- ============================================
-- EXPORT
-- ============================================

--- Exportar la partida actual como archivo descargable.
--- @return boolean, string  (éxito, mensaje para mostrar al jugador)
function M.export_save()
	local data = collect_save_data()
	local json_str = json_util.encode(data)

	local ok, html5_mod = is_html5()
	if ok then
		-- HTML5: descargar como archivo .json mediante JavaScript.
		-- Estrategia: el JSON es JavaScript válido como objeto literal.
		-- Lo embebemos directamente en el JS. Dado que el JSON de partida
		-- nunca contendrá "]]" (Lua long bracket terminator), es seguro.
		local js = [[
			(function() {
				var data = ]] .. json_str .. [[;
				var blob = new Blob([JSON.stringify(data, null, 2)], {type: 'application/json'});
				var url = URL.createObjectURL(blob);
				var a = document.createElement('a');
				a.href = url;
				a.download = 'museo_save_' + new Date().toISOString().slice(0,10) + '.json';
				document.body.appendChild(a);
				a.click();
				document.body.removeChild(a);
				URL.revokeObjectURL(url);
			})()
		]]
		-- Sólo aplanamos saltos de línea (sin escapar backslashes — eso corrompería el JSON)
		local flat_js = js:gsub("\n", " ")
		html5_mod.run(flat_js)
		-- 🌐 CLAVE neutra (GOTCHA #37): general_text → M.save la resuelve
		return true, "exported_html5"
	else
		-- Desktop: guardar mediante sys.save() con nombre identificable
		local path = sys.get_save_file("mi_juego_museo", EXPORT_FILENAME)
		local success = sys.save(path, { json = json_str })
		if success then
			return true, "exported_desktop", tostring(path)
		else
			return false, "export_error"
		end
	end
end

-- ============================================
-- IMPORT
-- ============================================

--- Variable para recibir datos desde JS (HTML5 polling)
local _pending_import = nil

--- Inicia el proceso de importación.
--- En HTML5 abre un selector de archivos en el navegador.
--- En desktop lee el archivo exportado previamente.
--- @param callback function(json_str|nil)  Recibe el string JSON o nil si falla
function M.request_import(callback)
	if not callback then return end

	local ok, html5_mod = is_html5()
	if ok then
		-- Registrar callback JS→Lua (disponible desde Defold 1.2.x)
		if html5_mod.set_callback then
			html5_mod.set_callback("import_data", function(json_str)
				_pending_import = json_str
			end)
		end

		-- JS: crear input file, leer como texto, almacenar resultado
		local js = [[
			(function() {
				var input = document.createElement('input');
				input.type = 'file';
				input.accept = '.json';
				input.onchange = function(e) {
					var file = e.target.files[0];
					if (!file) return;
					var reader = new FileReader();
					reader.onload = function(ev) {
						var jsonStr = ev.target.result;
						window.__import_data = jsonStr;
						try { Module.luaCallback('import_data', jsonStr); } catch(e) {}
					};
					reader.readAsText(file);
				};
				input.click();
			})()
		]]
		local flat_js = js:gsub("\n", " ")
		html5_mod.run(flat_js)

		-- Polling: esperar hasta ~30s a que JS nos devuelva los datos
		local elapsed = 0
		local function poll()
			if _pending_import then
				local data = _pending_import
				_pending_import = nil
				callback(data)
			elseif elapsed < 300 then
				elapsed = elapsed + 1
				timer.delay(0.1, false, poll)
			else
				callback(nil) -- Timeout
			end
		end
		timer.delay(0.5, false, poll)
	else
		-- Desktop: cargar desde el archivo exportado
		local path = sys.get_save_file("mi_juego_museo", EXPORT_FILENAME)
		local data = sys.load(path)
		if data and data.json then
			callback(data.json)
		else
			callback(nil)
		end
	end
end

--- Procesa un string JSON importado y restaura la partida.
--- @param json_str string|nil  JSON del archivo importado
--- @return boolean, string  (éxito, mensaje para mostrar)
function M.process_import(json_str)
	if not json_str or json_str == "" then
		-- 🌐 CLAVE neutra (GOTCHA #37)
		return false, "import_read_error"
	end

	local data, err = json_util.decode(json_str)
	if not data then
		return false, "import_json_error", tostring(err)
	end

	return restore_save_data(data)
end

return M
