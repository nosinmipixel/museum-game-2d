#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# 🔎 audit_globals.sh — Auditoría de funciones globales no-ciclo-de-vida
# ═══════════════════════════════════════════════════════════════════════════════
#   Clasifica cada 'function X' de nivel superior en todos los .script/.gui_script/.lua
#   del proyecto como:
#     ✅ ciclo de vida   → init/update/fixed_update/on_message/on_input/on_reload/final
#     ✅ M.X            → export de módulo (p. ej. 'function M.foo()' con local M)
#     ✅ fwd-decl       → 'local X' declarado ANTES en el mismo archivo
#                         (patrón de forward declaration de Fases 1-3 de DEFOLD_LUA_STANDARDS)
#     ❌ VIOLACIÓN      → función global real (ni local, ni ciclo de vida, ni M.X)
#   También detecta asignaciones globales tipo 'X = function(...)' sin 'local X' previo.
#
#   Uso:
#     bash audit_globals.sh           # lista violaciones (si las hay) y total
#     bash audit_globals.sh -q        # solo el total (útil para scripts/CI)
#     bash audit_globals.sh -v        # verbose: también lista los archivos limpios
#
#   FASE 2 — Comentarios '--' en archivos de datos (GOTCHA #21):
#     Detecta líneas que empiecen por '--' en .gui/.go/.collection/.sound/
#     .input_binding/game.project. Esos archivos NO son Lua: el parser del
#     editor rechaza la línea (RENDER ERROR "Expected identifier. Found '--'"
#     o "Invalid setting line") y el recurso no se carga.
#
#   FASE 3 — Claves inválidas en game.project (GOTCHA #21):
#     Whitelist de claves conocidas por sección. Cualquier 'clave = valor'
#     cuya sección esté cubierta y cuya clave NO esté en la lista se marca
#     (p. ej. use_sound_groups o groups = [...] no existen en Defold y el
#     editor los rechaza al cargar el proyecto). Las secciones no listadas
#     se ignoran (evita falsos positivos); ampliar las listas cuando el
#     editor genere claves nuevas.
#
#   Exit code: 0 si NO hay violaciones, comentarios ni claves inválidas,
#   1 si hay al menos uno (compatible con CI).
#
#   Notas:
#     - Excluye build/, bak/, .internal/ y .git/
#     - El awk procesa CADA archivo en un proceso separado → 'fwd' se reinicia
#       por archivo (sin contaminación entre archivos).
#     - No detecta definiciones top-level indentadas (este proyecto las tiene en
#       columna 0); 'local a, b = ...' registra todos los nombres (no solo el primero).
#     - IMPORTANTE: no usar comillas simples dentro del programa awk (AUDIT_AWK
#       se asigna como cadena single-quoted de bash; una comilla simple interna
#       la rompería y ejecutaría el fragmento como comando).
#     - FASE 2 no detecta '--' embebido en strings de datos (p. ej.
#       text: "a--b") que no esté al inicio de línea; ese caso no rompe la carga.
#     - Requiere bash 4+ (declare -A en FASE 3). Linux/macOS modernos OK.
# ═══════════════════════════════════════════════════════════════════════════════

set -u

# ── Modos ───────────────────────────────────────────────────────────────────────
QUIET=0
VERBOSE=0
for arg in "$@"; do
  case "$arg" in
    -q) QUIET=1 ;;
    -v) VERBOSE=1 ;;
    *) echo "⚠️  Argumento desconocido: $arg (usa -q o -v)" >&2 ;;
  esac
done

AUDIT_AWK='
  /^local function / { name=$3; sub(/\(.*/,"",name); fwd[name]=1; next }
  /^local / {
    # Registrar TODOS los nombres de una declaración múltiple (local a, b = ...)
    line=$0; sub(/^local[ \t]+/,"",line); sub(/=.*$/,"",line)
    n=split(line, names, /[ \t,]+/)
    for (i=1; i<=n; i++) if (names[i] != "") fwd[names[i]]=1
    next
  }
  /^function / {
    name=$2; sub(/\(.*/,"",name)
    if (name ~ /\./) next                                  # M.X → export de módulo
    if (name ~ /^(init|update|fixed_update|on_message|on_input|on_reload|final)$/) next
    if (!fwd[name]) { bad++; printf "%s:%d: VIOLACION-GLOBAL %s\n", FILENAME, FNR, name }
    next
  }
  /^[a-zA-Z_][a-zA-Z0-9_]*[ \t]*=[ \t]*function/ {
    name=$1; sub(/[= \t].*/,"",name)
    if (name !~ /\./ && !fwd[name]) { bad++; printf "%s:%d: VIOLACION-GLOBAL-ASSIGN %s\n", FILENAME, FNR, name }
  }
  END { if (bad > 0) printf "==> %s: %d VIOLACION(ES)\n", FILENAME, bad }
'

TOTAL=0
while read -r f; do
  OUT=$(awk "$AUDIT_AWK" "$f")
  if [ -n "$OUT" ]; then
    if [ "$QUIET" -eq 0 ]; then
      echo "$OUT"
    fi
    N=$(echo "$OUT" | grep -c 'VIOLACION-GLOBAL')
    TOTAL=$((TOTAL + N))
  elif [ "$VERBOSE" -eq 1 ]; then
    echo "==> $f: OK"
  fi
done < <(find . -type f \( -name '*.script' -o -name '*.gui_script' -o -name '*.lua' \) \
         | grep -vE '^\./(build|bak|\.internal|\.git)/' \
         | sort)

if [ "$QUIET" -eq 0 ]; then echo "───"; fi
echo "TOTAL VIOLACIONES GLOBALES: $TOTAL"

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 FASE 2 — Comentarios '--' en archivos de datos (GOTCHA #21)
# ═══════════════════════════════════════════════════════════════════════════════
#   Los archivos de datos usan el formato de propiedades del editor, NO Lua:
#   una línea cuyo primer carácter no-espacio sea '--' rompe la carga del
#   recurso (RENDER ERROR "Expected identifier. Found '--'" o
#   "Invalid setting line"). game.project no tiene extensión, por eso se
#   busca aparte del grep recursivo con --include.
DATA_COMMENTS=$( { grep -rn '^[[:space:]]*--' \
                     --include='*.gui' --include='*.go' --include='*.collection' \
                     --include='*.sound' --include='*.input_binding' . ; \
                   grep -Hn '^[[:space:]]*--' game.project ; } 2>/dev/null \
                | grep -vE '^\./(build|bak|\.internal|\.git)/' )
DATA_TOTAL=$(printf '%s\n' "$DATA_COMMENTS" | sed '/^$/d' | wc -l | tr -d ' ')
if [ -n "$DATA_COMMENTS" ] && [ "$QUIET" -eq 0 ]; then
  echo "───"
  echo "⚠️  Comentarios '--' en archivos de datos (GOTCHA #21):"
  echo "$DATA_COMMENTS"
fi
if [ "$QUIET" -eq 0 ]; then echo "───"; fi
echo "TOTAL COMENTARIOS '--' EN DATOS: $DATA_TOTAL"

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 FASE 3 — Claves inválidas en game.project (whitelist por sección)
# ═══════════════════════════════════════════════════════════════════════════════
#   Solo valida secciones CUBIERTAS por la lista: una sección no listada se
#   ignora entera (el editor puede añadir secciones en otras versiones).
#   Formato: sección → claves válidas separadas por espacios.
declare -A GP_KNOWN_KEYS=(
  ["bootstrap"]="main_collection render"
  ["script"]="shared_state"
  ["project"]="title version publisher developer dependencies custom_resources bundle_resources bundle_exclude_resources write_log compress_archive minimum_log_level"
  ["display"]="width height high_dpi samples fullscreen update_frequency swap_interval vsync display_profiles dynamic_orientation display_device_info"
  ["graphics"]="default_texture_min_filter default_texture_mag_filter max_characters max_font_batches max_debug_vertices texture_profiles verify_graphics_calls opengl_version_hint opengl_core_profile_hint vulkan_version_major vulkan_version_minor max_draw_calls"
  ["physics"]="type gravity_x gravity_y gravity_z debug debug_alpha world_count scale allow_dynamic_transforms use_fixed_timestep debug_scale max_collisions max_contacts contact_impulse_limit ray_cast_limit_2d ray_cast_limit_3d trigger_overlap_capacity velocity_threshold max_fixed_timesteps max_collision_object_count"
  ["sound"]="max_component_count use_thread sample_frame_count use_linear_gain gain"
  ["sprite"]="max_count max_vertices"
  ["tilemap"]="max_tile_count max_count"
  ["html5"]="htmlfile custom_css custom_js engine_arguments background_color display_orientation"
  ["input"]="repeat_delay repeat_interval gamepads game_binding"
  ["render"]="clear_color_red clear_color_green clear_color_blue clear_color_alpha"
  ["font"]="runtime_generation"
  ["engine"]="run_while_iconified fixed_update_frequency max_time_step"
  ["library"]="include_dirs"
  ["camera"]="near_z far_z fov aspect_ratio"
  ["collection"]="max_instances max_input_devices"
  ["navigation"]="max_agents max_clusters"
)

GP_SECTION=""
GP_BAD_TOTAL=0
GP_BAD=""
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in
    \[*)
      GP_SECTION="${line#\[}"; GP_SECTION="${GP_SECTION%\]}"
      GP_SECTION="$(printf '%s' "$GP_SECTION" | tr -d '[:space:]')"
      ;;
    ''|\#*) ;;
    *=*)
      key="${line%%=*}"
      key="$(printf '%s' "$key" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
      valid="${GP_KNOWN_KEYS[${GP_SECTION}]:-}"
      if [ -n "$GP_SECTION" ] && [ -n "$valid" ] && [[ " $valid " != *" $key "* ]]; then
        GP_BAD_TOTAL=$((GP_BAD_TOTAL + 1))
        GP_BAD="${GP_BAD}game.project [${GP_SECTION}]: clave inválida '${key}' (no existe en Defold — GOTCHA #21)\n"
      fi
      ;;
  esac
done < game.project

if [ -n "$GP_BAD" ] && [ "$QUIET" -eq 0 ]; then
  echo "───"
  echo "⚠️  Claves inválidas en game.project (whitelist):"
  printf '%b' "$GP_BAD"
fi
if [ "$QUIET" -eq 0 ]; then echo "───"; fi
echo "TOTAL CLAVES INVALIDAS EN GAME.PROJECT: $GP_BAD_TOTAL"

[ "$TOTAL" -eq 0 ] && [ "$DATA_TOTAL" -eq 0 ] && [ "$GP_BAD_TOTAL" -eq 0 ] && exit 0 || exit 1
