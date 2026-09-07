#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════
# generate_go_id_registry.py
# ═══════════════════════════════════════════════════════
# Genera main/go_id_registry.lua: lista de RUTAS COMPLETAS de todas las
# instancias declaradas en los .collection del proyecto.
#
# ¿Por qué existe? (bug defold/defold#13125, hilo del issue #13125 de
# museum-game-2d): `tostring(hash)` solo devuelve el string original en
# builds DEBUG (tabla reverse-hash del engine). En RELEASE devuelve basura,
# así que los scripts que parsean `tostring(go.get_id())` para sacar el
# nombre del GO (npc, doors, zone_alert, bookcase, exhibition_object,
# inventory_manager) se rompen en silencio. Solución release-safe: el
# módulo generado registra `hash(ruta) → ruta` en runtime con hash() de
# Lua (el algoritmo es idéntico en ambas variantes) y los scripts resuelven
# el nombre vía registro.
#
# Uso:
#   python3 tools/generate_go_id_registry.py
#
# Ejecutar SIEMPRE tras añadir/mover/renombrar instancias en las
# colecciones (el fichero generado va commiteado al repo).
#
# Semántica de rutas (formato texto .collection):
#   - `instances { id: "A" ... }` sin padre → ruta "/A"
#   - `instances { id: "P" children: "C" }` → el GO hijo C cuelga del GO P
#     → ruta de C = ruta_de_P + "/C"  (ej: "/spawn_npcs/spawn_npc_01")
#   - `embedded_instances` NO se procesan (ningún script parsea sus ids).
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
CHILDREN_RE = re.compile(r'(?m)^\s+children:\s*"([^"]+)"')


def extract_blocks(text: str, keyword: str):
    """Devuelve el contenido de cada bloque `keyword { ... }` balanceado."""
    blocks = []
    search_from = 0
    opener = keyword + " {"
    while True:
        start = text.find(opener, search_from)
        if start == -1:
            break
        i = start + len(opener)
        depth = 1
        while i < len(text) and depth > 0:
            if text[i] == "{":
                depth += 1
            elif text[i] == "}":
                depth -= 1
            i += 1
        blocks.append(text[start + len(opener):i - 1])
        search_from = i
    return blocks


def parse_collection(path: Path):
    """Devuelve (instancias: {id: ruta}, dangling_refs: [ids])."""
    text = path.read_text(encoding="utf-8")
    ids = []          # ids en orden de aparición
    children_of = {}  # id → [ids hijo]
    seen = set()

    for block in extract_blocks(text, "instances"):
        m = ID_RE.search(block)
        if not m:
            continue
        iid = m.group(1)
        if iid in seen:
            print(f"⚠️  {path.name}: id duplicado '{iid}' (se ignora la 2ª)", file=sys.stderr)
            continue
        seen.add(iid)
        ids.append(iid)
        children_of[iid] = CHILDREN_RE.findall(block)

    # Rutas: raíces = instancias que nadie referencia como hijo.
    referenced = {c for cs in children_of.values() for c in cs}
    paths = {}
    dangling = []

    def resolve(iid: str, base: str):
        if iid in paths:
            return
        paths[iid] = base + "/" + iid
        for child in children_of.get(iid, []):
            if child in seen:
                resolve(child, paths[iid])
            else:
                dangling.append(child)

    for iid in ids:
        if iid not in referenced:
            resolve(iid, "")

    return paths, dangling


def main():
    all_paths = set()
    collisions = {}
    for name in COLLECTIONS:
        path = PROJECT_ROOT / name
        if not path.exists():
            print(f"⚠️  Colección no encontrada: {name} (omitida)", file=sys.stderr)
            continue
        paths, dangling = parse_collection(path)
        for iid, p in paths.items():
            if p in all_paths:
                collisions.setdefault(p, set()).add(name)
            all_paths.add(p)
        print(f"{name}: {len(paths)} instancias" + (f", {len(dangling)} refs colgantes" if dangling else ""))
        for d in sorted(set(dangling)):
            print(f"   ⚠️  children ref no encontrada: {d}", file=sys.stderr)

    sorted_paths = sorted(all_paths)
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
        "-- engine (solo disponible en DEBUG). Ver cabecera del generador y",
        "-- docs/DEV_GOTCHAS.md (gotcha release-variant).",
        "--",
        "-- Licencia: GPL-3.0-only",
        "-- ═══════════════════════════════════════════════════════",
        "",
        "local M = {}",
        "",
        f"local PATHS = {{",
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
        '\t\tREG[hash(PATHS[i])] = PATHS[i]',
        "\tend",
        "end",
        "",
        "-- Ruta completa del GO ('/npcs/npc_01') o nil si no está registrada",
        "-- (instancias creadas en runtime vía factory no están — sus scripts no",
        "-- parsean ids).",
        "function M.path_of(go_id)",
        "\tif go_id == nil then return nil end",
        "\tensure_registry()",
        "\treturn REG[go_id]",
        "end",
        "",
        "-- Último segmento de la ruta ('npc_01'). Fallback: parseo del tostring()",
        "-- del hash — solo produce el nombre real en builds DEBUG (en release",
        "-- devuelve basura; el registro de arriba es la fuente válida).",
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

    if collisions:
        for p, names in sorted(collisions.items()):
            print(f"⚠️  Ruta duplicada entre colecciones (mismo string): {p} en {sorted(names)}", file=sys.stderr)
        print("ℹ️  Colisiones inofensivas salvo que los nombres difieran; revisa si aparecen.", file=sys.stderr)

    OUTPUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"✅ {OUTPUT.relative_to(PROJECT_ROOT)} generado: {len(sorted_paths)} rutas")


if __name__ == "__main__":
    main()
