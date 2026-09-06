-- main/json_util.lua
-- ═══════════════════════════════════════════════════════
-- 📦 JSON ENCODER / DECODER básico para Lua
-- ═══════════════════════════════════════════════════════
-- Soporta: strings, numbers, booleans, nil, tables (array/object)
-- No soporta: circular references, userdata, functions, threads
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-15
-- ═══════════════════════════════════════════════════════

local M = {}

local json_encode
local json_decode

-- ============================================
-- ENCODE (Lua table → JSON string)
-- ============================================

local function escape_str(s)
	if type(s) ~= "string" then return s end
	return s:gsub("\\", "\\\\")
	        :gsub('"', '\\"')
	        :gsub("\n", "\\n")
	        :gsub("\r", "\\r")
	        :gsub("\t", "\\t")
end

local function is_array(t)
	if type(t) ~= "table" then return false end
	local count = 0
	for k, _ in pairs(t) do
		if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then
			return false
		end
		count = count + 1
	end
	-- Check if keys are 1..n
	for i = 1, count do
		if t[i] == nil then return false end
	end
	return true
end

json_encode = function(val, depth)
	depth = depth or 0
	if depth > 50 then return "null" end -- Safety limit

	local t = type(val)

	if t == "nil" then
		return "null"
	elseif t == "boolean" then
		return tostring(val)
	elseif t == "number" then
		if val ~= val then return "null" end -- NaN
		return tostring(val)
	elseif t == "string" then
		return '"' .. escape_str(val) .. '"'
	elseif t == "table" then
		local parts = {}
		if is_array(val) then
			for i = 1, #val do
				table.insert(parts, json_encode(val[i], depth + 1))
			end
			return "[" .. table.concat(parts, ",") .. "]"
		else
			-- Sort keys for deterministic output
			local keys = {}
			for k, _ in pairs(val) do
				table.insert(keys, k)
			end
			table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
			for _, k in ipairs(keys) do
				local v = val[k]
				if v ~= nil then
					table.insert(parts, json_encode(k, depth + 1) .. ":" .. json_encode(v, depth + 1))
				end
			end
			return "{" .. table.concat(parts, ",") .. "}"
		end
	end
	return "null"
end

--- Serializa un valor Lua a JSON string.
--- @param val any  Valor a serializar
--- @return string  Cadena JSON
function M.encode(val)
	return json_encode(val, 0)
end

-- ============================================
-- DECODE (JSON string → Lua table)
-- ============================================

local function create_parser(json_str)
	local pos = 1
	local len = #json_str

	local function skip_whitespace()
		while pos <= len do
			local c = json_str:sub(pos, pos)
			if c == " " or c == "\t" or c == "\n" or c == "\r" then
				pos = pos + 1
			else
				break
			end
		end
	end

	local function peek()
		skip_whitespace()
		if pos > len then return nil end
		return json_str:sub(pos, pos)
	end

	local function consume(expected)
		skip_whitespace()
		if expected then
			if json_str:sub(pos, pos + #expected - 1) == expected then
				pos = pos + #expected
				return true
			end
			return false
		end
		local c = json_str:sub(pos, pos)
		pos = pos + 1
		return c
	end

	local function parse_value()
		skip_whitespace()
		if pos > len then return nil end

		local c = peek()

		if c == '"' then
			-- String
			pos = pos + 1 -- skip opening "
			local s = {}
			while pos <= len do
				local ch = json_str:sub(pos, pos)
				pos = pos + 1
				if ch == '"' then
					return table.concat(s)
				elseif ch == "\\" then
					local next_ch = json_str:sub(pos, pos)
					pos = pos + 1
					if next_ch == '"' then table.insert(s, '"')
					elseif next_ch == "\\" then table.insert(s, "\\")
					elseif next_ch == "/" then table.insert(s, "/")
					elseif next_ch == "b" then table.insert(s, "\b")
					elseif next_ch == "f" then table.insert(s, "\f")
					elseif next_ch == "n" then table.insert(s, "\n")
					elseif next_ch == "r" then table.insert(s, "\r")
					elseif next_ch == "t" then table.insert(s, "\t")
					elseif next_ch == "u" then
						-- Unicode escape (simplified - just pass through)
						local hex = json_str:sub(pos, pos + 3)
						pos = pos + 4
						table.insert(s, "\\u" .. hex)
					else
						table.insert(s, next_ch)
					end
				else
					table.insert(s, ch)
				end
			end
			return nil -- Unterminated string

		elseif c == "{" then
			-- Object
			pos = pos + 1
			local obj = {}
			if peek() == "}" then
				pos = pos + 1
				return obj
			end
			while pos <= len do
				local key = parse_value()
				if key == nil then return nil end
				if not consume(":") then return nil end
				local val = parse_value()
				if val == nil then return nil end
				obj[key] = val
				if not consume(",") then break end
			end
			if not consume("}") then return nil end
			return obj

		elseif c == "[" then
			-- Array
			pos = pos + 1
			local arr = {}
			local idx = 1
			if peek() == "]" then
				pos = pos + 1
				return arr
			end
			while pos <= len do
				local val = parse_value()
				if val == nil then return nil end
				arr[idx] = val
				idx = idx + 1
				if not consume(",") then break end
			end
			if not consume("]") then return nil end
			return arr

		elseif c == "t" then
			if consume("true") then return true end
			return nil
		elseif c == "f" then
			if consume("false") then return false end
			return nil
		elseif c == "n" then
			if consume("null") then return nil end
			return nil
		else
			-- Number
			local num_str = {}
			local is_neg = false
			if c == "-" then
				is_neg = true
				pos = pos + 1
				table.insert(num_str, "-")
			end
			while pos <= len do
				local ch = json_str:sub(pos, pos)
				if ch >= "0" and ch <= "9" or ch == "." or ch == "e" or ch == "E" or ch == "+" or ch == "-" then
					table.insert(num_str, ch)
					pos = pos + 1
				else
					break
				end
			end
			local num = tonumber(table.concat(num_str))
			-- Avoid issue with negative sign at start
			if is_neg and json_str:sub(pos-1, pos-1) == "-" then
				pos = pos - 1
				return nil
			end
			return num
		end
	end

	return parse_value
end

--- Deserializa una cadena JSON a un valor Lua.
--- @param json_str string  Cadena JSON a parsear
--- @return any, string|nil  (valor parseado, mensaje de error si falla)
function M.decode(json_str)
	if type(json_str) ~= "string" then
		return nil, "Input must be a string"
	end
	local parser = create_parser(json_str)
	local ok, result = pcall(parser)
	if not ok then
		return nil, "Parse error: " .. tostring(result)
	end
	return result, nil
end

return M
