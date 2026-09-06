#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# deploy_pages.sh — Publica el bundle HTML5 del editor en gh-pages
# ═══════════════════════════════════════════════════════════════
#
#   Uso:       bash deploy_pages.sh
#   Requiere:  bundle HTML5 generado por el editor Defold en
#              build/default_html5/__htmlLaunchDir/<Título>/
#              (o pasar la ruta del bundle como argumento 1)
#
#   Qué hace:
#     1. Localiza el bundle HTML5 del editor (o usa el arg dado)
#     2. Construye un árbol SIN historial (rama huérfana) con el
#        contenido del bundle aplanado: index.html en la raíz
#     3. Fuerza el push a origin/gh-pages
#
#   Notas:
#     - La rama gh-pages se reemplaza entera en cada release
#       (force-push). main y su historial quedan intactos y
#       limpios: los ~39 MB del bundle no contaminan main.
#     - Requiere que SSH a github.com funcione (deploy key).
#     - .nojekyll evita que Pages procese el sitio con Jekyll
#       (innecesario y más rápido sin él).
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# ── 1. Localizar el bundle ─────────────────────────────────────
BUNDLE="${1:-}"
if [[ -z "$BUNDLE" ]]; then
	echo "Buscando bundle HTML5 del editor..."
	BUNDLE="$(find build -type d -path '*__htmlLaunchDir*' -mindepth 2 -maxdepth 2 2>/dev/null | head -n1 || true)"
	if [[ -z "$BUNDLE" || ! -f "$BUNDLE/index.html" ]]; then
		echo "ERROR: no encontré un bundle con index.html bajo build/."
		echo "Abre el proyecto en Defold y haz: Project → Bundle → HTML5..."
		echo "(o ejecuta: bash deploy_pages.sh /ruta/al/bundle)"
		exit 1
	fi
fi
if [[ ! -f "$BUNDLE/index.html" ]]; then
	echo "ERROR: '$BUNDLE/index.html' no existe."
	exit 1
fi
echo "Bundle: $BUNDLE"

# ── 2. Construir el árbol huérfano ─────────────────────────────
WORKTREE="$(mktemp -d)"
trap 'rm -rf "$WORKTREE"' EXIT

echo "Copiando contenido del bundle..."
cp -r "$BUNDLE/." "$WORKTREE/"
touch "$WORKTREE/.nojekyll"

# Aviso de integridad: el árbol debe contener lo esencial
for f in index.html dmloader.js; do
	[[ -e "$WORKTREE/$f" ]] || { echo "ERROR: falta $f en el bundle."; exit 1; }
done

echo "Creando árbol de gh-pages (rama huérfana)..."
TREE_HASH="$(
	cd "$WORKTREE" &&
	git --work-tree=. add -A >/dev/null 2>&1 &&
	git write-tree
)"

echo "Creando commit huérfano..."
COMMIT_HASH="$(git commit-tree "$TREE_HASH" -m "Deploy: bundle HTML5 del editor ($(date -u +%Y-%m-%d_%H:%M UTC))")"

# ── 3. Push forzado a gh-pages ─────────────────────────────────
echo "Subiendo a origin/gh-pages (force)..."
git push origin "$COMMIT_HASH:refs/heads/gh-pages" --force

echo ""
echo "✅ Publicado. Recuerda: Settings → Pages → Source: 'Deploy from a branch'"
echo "   → Branch: gh-pages / (root)."
