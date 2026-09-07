#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════
# generate_go_id_registry.py
# ═══════════════════════════════════════════════════════
# Genera main/go_id_registry.lua: lista de RUTAS de todas las instancias
# declaradas en los .collection del proyecto.
#
# ¿Por qué existe? (defold/defold#13125, proyecto museum-game-2d):
# `tostring(hash)` solo devuelve el string original en builds DEBUG (tabla
# reverse-hash del engine). En RELEASE devuelve "<unknown:DEC>" — verificado
# empíricamente — así que los scripts que parsean `tostring(go.get_id())`
# para sacar el nombre del GO (npc, doors, zone_alert, bookcase,
# exhibition_object, inventory_manager) se rompen en silencio. Solución
# release-safe: este módulo registra `hash(ruta) → ruta` en runtime con
# hash() de Lua (el algoritmo es idéntico en ambas variantes) y los scripts
# resuelven el nombre vía registro.
#
# ⚠️ SEMÁNTICA DE RUTAS (VERIFICADA EMPÍRICAMENTE, Sept. 2026, v2):
#   El id de un GO es SIEMPRE "/<id>" a nivel raíz de su colección, INCLUSO
#   si es hijo de otro GO (`children: "x"`). Los hijos NO anidan el path del
#   padre en su id (el debug tostring lo confirmó: un NPC hijo de
#   level2→npcs tiene id "/npc_01", NO "/level2/npcs/npc_01"). El anidado
#   "/a/b" solo aplica a sub-colecciones (instancias de otras .collection),
#   y este proyecto no usa ninguna (solo proxies = mundos separados).
#   El GOTCHA #4 del proyecto ("rutas anidadas /level2/npcs/npc_01") era una
#   suposición incorrecta.
#
# Uso:
#   python3 tools/generate_go_id_registry.py
#
# Ejecutar SIEMPRE tras añadir/mover/renombrar instancias en las
# colecciones (el fichero generado va commiteado al repo).
#
# Licencia: GPL-3.0-only
# ═══════════════════════════════════════════════════════

import re
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
OUTPUT = PROJECT_ROOT / "main" / "go_id_registry.lua"
COLLECTIONS = ["level_01.collection", "intro.collection", "bootstrap.collection"]

ID_RE = re.compile(r'(?m)^\s+id:\s*"([^"]+)"')


def extract_blocks(text: str):
    """Devuelve el contenido de cada bloque `instances { ... }` / `embedded_instances { ... }` balanceado.

    Nota: buscar "instances {" como subcadena captura también los bloques
    `embedded_instances {` (sus ids/children viven al mismo nivel). El campo
    `data:` de los embedded lleva el contenido escapado ("\\n" literal), así
    que los `id:` interiores no contaminan el parseo.
    """
    blocks = []
    search_from = 0
    while True:
        start = text.find("instances {", search_from)
        if start == -1:
            break
        i = start + len("instances {")
        depth = 1
        while i < len(text) and depth > 0:
            if text[i] == "{":
                depth += 1
            elif text[i] == "}":
                depth -= 1
            i += 1
        blocks.append(text[start + len("instances {"):i - 1])
        search_from = i
    return blocks


def parse_collection(path: Path):
    """Devuelve la lista de ids de instancia (rutas raíz "/id")."""
    text = path.read_text(encoding="utf-8")
    ids = []
    seen = set()
    for block in extract_blocks(text):
        m = ID_RE.search(block)
        if not m:
            continue
        iid = m.group(1)
        if iid in seen:
            print(f"⚠️  {path.name}: id duplicado '{iid}' (se ignora la 2ª)", file=sys.stderr)
            continue
        seen.add(iid)
        ids.append(iid)
    return ids


def main():
    all_ids = set()
    for name in COLLECTIONS:
        path = PROJECT_ROOT / name
        if not path.exists():
            print(f"⚠️  Colección no encontrada: {name} (omitida)", file=sys.stderr)
            continue
        ids = parse_collection(path)
        all_ids.update(ids)
        print(f"{name}: {len(ids)} instancias")

    # Ruta de TODA instancia: "/<id>" (sin anidado — ver cabecera, v2).
    sorted_paths = sorted("/" + iid for iid in all_ids)

    lines = [
        "-- main/go_id_registry.lua",
        "-- ═══════════════════════════════════════════════════════",
        "-- 🗺️  REGISTRO REVERSO DE IDS DE GO (GENERADO — no editar a mano)",
        "-- ═══════════════════════════════════════════════════════",
        "--",
        "-- Regenerar con: python3 tools/generate_go_id_registry.py",
        "-- (ejecutar tras añadir/renombrar instancias en las colecciones)",
        "--",
        "-- Resuelve go.get_id() → ruta del GO sin depender del reverse-hash del",
        "-- engine (solo disponible en DEBUG; en release tostring(hash) devuelve",
        "-- \"<unknown:DEC>\"). Ver cabecera del generador y docs/DEV_GOTCHAS.md",
        "-- (GOTCHA #45).",
        "--",
        "-- NOTA v2: las rutas son SIEMPRE \"/<id>\" — los GOs hijos NO anidan el",
        "-- path del padre (verificado empíricamente; el anidado solo aplica a",
        "-- sub-colecciones, y este proyecto no usa ninguna).",
        "--",
        "-- Licencia: GPL-3.0-only",
        "-- ═══════════════════════════════════════════════════════",
        "",
        "local M = {}",
        "",
        "local PATHS = {",
    ]
    for p in sorted_paths:
        lines.append(f'\t"{p}",')
    lines += [
        "}",
        "",
        "local REG = nil",
        "",
        "local function ensure_registry()",
        "\tif REG then return end",
        "\tREG = {}",
        "\tfor i = 1, #PATHS do",
        "\t\tREG[hash(PATHS[i])] = PATHS[i]",
        "\tend",
        "end",
        "",
        "-- Ruta del GO ('/npc_01') o nil si no está registrada (instancias",
        "-- creadas en runtime vía factory no están — sus scripts no parsean ids).",
        "function M.path_of(go_id)",
        "\tif go_id == nil then return nil end",
        "\tensure_registry()",
        "\treturn REG[go_id]",
        "end",
        "",
        "-- Nombre del GO ('npc_01'). Fallback: parseo del tostring() del hash —",
        "-- solo produce el nombre real en builds DEBUG (en release devuelve",
        "-- \"<unknown:DEC>\"; el registro de arriba es la fuente válida).",
        "function M.name_of(go_id, default)",
        "\tlocal p = M.path_of(go_id)",
        "\tlocal s = p or tostring(go_id)",
        "\tlocal clean = s:match(\"%s*%[%s*(.-)%s*%]\") or s",
        "\tlocal name = clean:match(\"([^/]+)$\")",
        "\tif name then return name end",
        "\treturn default",
        "end",
        "",
        "return M",
        "",
    ]

    OUTPUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"✅ {OUTPUT.relative_to(PROJECT_ROOT)} generado: {len(sorted_paths)} rutas")


if __name__ == "__main__":
    main()
