-- main/go_id_registry.lua
-- ═══════════════════════════════════════════════════════
-- 🗺️  REGISTRO REVERSO DE IDS DE GO (GENERADO — no editar a mano)
-- ═══════════════════════════════════════════════════════
--
-- Regenerar con: python3 tools/generate_go_id_registry.py
-- (ejecutar tras añadir/renombrar instancias en las colecciones)
--
-- Resuelve go.get_id() → ruta del GO sin depender del reverse-hash del
-- engine (solo disponible en DEBUG; en release tostring(hash) devuelve
-- "<unknown:DEC>"). Ver cabecera del generador y docs/DEV_GOTCHAS.md
-- (GOTCHA #45).
--
-- NOTA v2: las rutas son SIEMPRE "/<id>" — los GOs hijos NO anidan el
-- path del padre (verificado empíricamente; el anidado solo aplica a
-- sub-colecciones, y este proyecto no usa ninguna).
--
-- Licencia: GPL-3.0-only
-- ═══════════════════════════════════════════════════════

local M = {}

local PATHS = {
	"/ME_100002",
	"/ME_100003",
	"/ME_100004",
	"/ME_100005",
	"/ME_132",
	"/ME_13561",
	"/ME_13564",
	"/ME_13570",
	"/ME_13588",
	"/ME_13590",
	"/ME_16061",
	"/ME_16121",
	"/ME_17109",
	"/ME_17110",
	"/ME_17727",
	"/ME_17757",
	"/ME_18125",
	"/ME_18169",
	"/ME_18558",
	"/ME_18649",
	"/ME_18704",
	"/ME_18888",
	"/ME_19002",
	"/ME_19014",
	"/ME_1905",
	"/ME_1911",
	"/ME_19635",
	"/ME_20",
	"/ME_20045",
	"/ME_20175",
	"/ME_20507",
	"/ME_22253",
	"/ME_23871",
	"/ME_23981",
	"/ME_23982",
	"/ME_23983",
	"/ME_24008",
	"/ME_24226",
	"/ME_2899",
	"/ME_3098",
	"/ME_3541",
	"/ME_3662",
	"/ME_4225",
	"/ME_4302",
	"/ME_43452",
	"/ME_43666",
	"/ME_43737",
	"/ME_45681",
	"/ME_4946",
	"/ME_4947",
	"/ME_4948",
	"/ME_5090",
	"/ME_5099",
	"/ME_5117",
	"/ME_5140",
	"/ME_5225",
	"/ME_5267",
	"/ME_5271",
	"/ME_6209",
	"/ME_6350",
	"/ME_6560",
	"/ME_7622",
	"/ME_7634",
	"/audio_manager",
	"/bookcase_bro",
	"/bookcase_ibe",
	"/bookcase_neo",
	"/bookcase_pal",
	"/bookcase_restor",
	"/bookcase_rom",
	"/btn_collectible",
	"/bullet",
	"/camera",
	"/car_end_point",
	"/car_start_point",
	"/cat",
	"/climate_controller",
	"/collectible_object",
	"/collectibles",
	"/cursor",
	"/door_front",
	"/door_front1",
	"/door_front2",
	"/door_front3",
	"/door_front4",
	"/door_front5",
	"/door_main",
	"/door_main1",
	"/door_main2",
	"/door_service",
	"/door_service1",
	"/door_side",
	"/door_side1",
	"/door_side10",
	"/door_side11",
	"/door_side12",
	"/door_side13",
	"/door_side14",
	"/door_side15",
	"/door_side16",
	"/door_side17",
	"/door_side18",
	"/door_side19",
	"/door_side2",
	"/door_side20",
	"/door_side21",
	"/door_side22",
	"/door_side23",
	"/door_side24",
	"/door_side25",
	"/door_side3",
	"/door_side4",
	"/door_side5",
	"/door_side6",
	"/door_side7",
	"/door_side8",
	"/door_side9",
	"/enemies",
	"/enemy_cockroach",
	"/exhibition_objects",
	"/food_spawn_01",
	"/food_spawn_02",
	"/food_spawn_03",
	"/food_spawn_container",
	"/furniture",
	"/game_manager",
	"/gui",
	"/gui_intro",
	"/gui_library",
	"/gui_victory",
	"/gui_web_controls",
	"/intro_animation",
	"/intro_manager",
	"/inventory_manager",
	"/kit_health",
	"/kit_stamina",
	"/level2",
	"/main_loader",
	"/nest_container",
	"/nest_spawn_01",
	"/nest_spawn_02",
	"/nest_spawn_03",
	"/nest_spawn_04",
	"/nest_spawn_05",
	"/nest_spawn_06",
	"/nest_spawn_07",
	"/nest_spawn_08",
	"/nest_spawn_09",
	"/nest_spawn_10",
	"/npc_01",
	"/npc_02",
	"/npc_03",
	"/npc_04",
	"/npc_05",
	"/npc_06",
	"/npc_07",
	"/npc_08",
	"/npc_09",
	"/npc_10",
	"/npc_11",
	"/npc_12",
	"/npc_13",
	"/npc_14",
	"/npcs",
	"/office_cabinet",
	"/office_cabinet1",
	"/office_cabinet2",
	"/office_cabinet3",
	"/office_cabinet4",
	"/office_cabinet5",
	"/player",
	"/player_intro",
	"/player_spawn_point",
	"/player_spray",
	"/props",
	"/proxy_intro",
	"/proxy_level_01",
	"/slot_shelf_bro",
	"/slot_shelf_ibe",
	"/slot_shelf_neo",
	"/slot_shelf_pal",
	"/slot_shelf_rom",
	"/slot_showcase_bro",
	"/slot_showcase_bro1",
	"/slot_showcase_ibe",
	"/slot_showcase_ibe1",
	"/slot_showcase_neo",
	"/slot_showcase_neo1",
	"/slot_showcase_pal",
	"/slot_showcase_pal1",
	"/slot_showcase_rom",
	"/slot_showcase_rom2",
	"/spawn_collectibles",
	"/spawn_enemies",
	"/spawn_npc_01",
	"/spawn_npc_02",
	"/spawn_npc_03",
	"/spawn_npc_04",
	"/spawn_npc_05",
	"/spawn_npc_06",
	"/spawn_npc_07",
	"/spawn_npc_08",
	"/spawn_npc_09",
	"/spawn_npc_10",
	"/spawn_npc_11",
	"/spawn_npc_12",
	"/spawn_npc_13",
	"/spawn_npc_14",
	"/spawn_npc_cat",
	"/spawn_npcs",
	"/spray_spawn_01",
	"/spray_spawn_02",
	"/spray_spawn_03",
	"/spray_spawn_04",
	"/spray_spawn_05",
	"/spray_spawn_06",
	"/spray_spawn_container",
	"/zone_intake",
	"/zone_storage",
	"/zones_sound",
}

local REG = nil

local function ensure_registry()
	if REG then return end
	REG = {}
	for i = 1, #PATHS do
		REG[hash(PATHS[i])] = PATHS[i]
	end
end

-- Ruta del GO ('/npc_01') o nil si no está registrada (instancias
-- creadas en runtime vía factory no están — sus scripts no parsean ids).
function M.path_of(go_id)
	if go_id == nil then return nil end
	ensure_registry()
	return REG[go_id]
end

-- Nombre del GO ('npc_01'). Fallback: parseo del tostring() del hash —
-- solo produce el nombre real en builds DEBUG (en release devuelve
-- "<unknown:DEC>"; el registro de arriba es la fuente válida).
function M.name_of(go_id, default)
	local p = M.path_of(go_id)
	local s = p or tostring(go_id)
	local clean = s:match("%s*%[%s*(.-)%s*%]") or s
	local name = clean:match("([^/]+)$")
	if name then return name end
	return default
end

return M
