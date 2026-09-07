# 🚀 Plan de publicación en GitHub — Versión Defold (2D/Lua)

> **Documento de análisis + plan de acción.** Estado: **PUBLICADO ✅** (Sept. 2026) — Despliegue activo. **Divergencia CLI/editor RESUELTA — causa raíz REAL confirmada (Sept. 2026): el juego dependía de `tostring(hash)`, que solo devuelve el string original en builds DEBUG (reverse-hash del engine); en release devuelve basura** (ver §5.4 y §5.5). Los maintainers de Defold lo confirmaron en [defold/defold#13125](https://github.com/defold/defold/issues/13125). La variante release del motor NUNCA estuvo rota. Fix: registro reverso de ids (`main/go_id_registry.lua`, generado por `tools/generate_go_id_registry.py`). Tras verificar el build release arreglado, el CI puede volver a la variante release (wasm ~470 KB más ligero).
> Decisiones tomadas por el usuario: **repo nuevo** `museum-game-2d` · licencia **GPL-3.0** · despliegue **CI con GitHub Actions**.

---

## 1. Contexto

- **Juego original (UPBGE):** versión 3D (Blender/Python) publicada en https://github.com/nosinmipixel/museum-game
- **Juego nuevo (Defold):** este proyecto — versión 2D (pixel art, Lua) que emula al anterior.
- **Relación de contenido:** excepto sonidos, música y algunas imágenes, prácticamente todo el contenido es distinto.
- **Objetivo:** publicar la nueva versión en GitHub y alojar el build HTML5 en GitHub Pages para que cualquiera pueda probarla en el navegador.

## 2. Decisiones tomadas (definitivas)

| Decisión | Valor | Motivo |
|---|---|---|
| **Repo nuevo vs fork** | **Repo nuevo** | Un fork implica contribuir de vuelta al repo original (PRs). Aquí el código es 100 % distinto (Python → Lua) y solo se comparte nombre/temática/parte de assets. El mismo usuario (`nosinmipixel`) no puede tener dos repos con el mismo nombre. |
| **Nombre del repo** | **`museum-game-2d`** | Variante clara que distingue la versión (2D/Defold) del original (3D/UPBGE). URL: `https://nosinmipixel.github.io/museum-game-2d/` |
| **Licencia** | **GPL-3.0** (código) + **CC BY-NC-SA 4.0** (assets heredados) | Coherencia con el repo original: código GPLv3 + assets CC BY-NC-SA 4.0 (ver §4). |
| **Despliegue** | **CI con GitHub Actions** | Cada push a `main` compila con `bob` y publica automáticamente. Repo limpio (sin ~600 MB de build local), builds reproducibles, sin límite de builds por hora. |

## 3. Auditoría del estado actual (local)

Datos verificados directamente en el proyecto:

- ✅ **Repositorio git activo** — `git init` hecho (rama `main`), remoto `origin` = `git@github.com:nosinmipixel/museum-game-2d.git`, proyecto publicado en GitHub (identidad local: `Ángel Sánchez <nosinmipixel@users.noreply.github.com>`).
- ✅ **`.gitignore` ya existe** (excluye `build/`, `.internal/`, `*.xcf`, `*.pxo`, IDEs, certificados) → decisión del §6.3 resuelta.
- ✅ **`.gitattributes` ya existe**.
- `game.project`:
  - `title = Top Down Museum Game`
  - `[html5] htmlfile = /assets/custom_template.html` (template HTML5 personalizado → respetado en CI headless)
  - `custom_resources = /assets` ⚠️ (copia la carpeta `assets/` completa al build; ver riesgo en §6)
  - **Sin extensiones nativas** → bob en CI no necesita `--email/--auth`.
  - **Sin dependencias de librerías** → `resolve` es trivial.
- **Tamaños:**
  - Fuente (sin `build/`): ~90 MB (de los cuales `assets/` ≈ 26 MB; los `.xcf`/`.pxo` ya no están en el árbol de trabajo)
  - Carpeta `build/` local completa: **~606 MB** (builds del editor + wasm-web; excluida del repo vía `.gitignore`)
  - **Contenido desplegable real: ~38.5 MB** (verificado Sept. 2026; mejor que la estimación inicial de ~70 MB)
- **Estructura del build desplegable del editor** (verificado):
  ```
  __htmlLaunchDir/
    build_input_data.json
    Top Down Museum Game/            ← carpeta nombrada por el título (con espacios)
      index.html                     ← entry point
      dmloader.js
      TopDownMuseumGame_wasm.js
      TopDownMuseumGame.wasm
      archive/                       ← gameN.arcd de 2 MB (chunks)
  ```
- `index.html` usa **rutas relativas** (`src="dmloader.js"`) → compatible con el subpath de Pages (`/museum-game-2d/`). ✅
- **Versión del motor:** Defold **1.13.1** — sha1 `574678c7d44be490d874fbed2d0ae6211feec4d9`, fijado en `DEFOLD_SHA` (`.github/workflows/deploy.yml`). Procedimiento de sincronización con el editor: ver §5.4.
- **Controles** (input binding): flechas **y WASD**, Espacio (spray), R (reset dev), P (pausa), ESC, TAB (inventario), clic izq. (interactuar), clic der. (spray), touch.

## 4. Licencias del proyecto original (a respetar)

Fuente: `docs/ASSETS_LICENSE.md` del repo UPBGE (https://github.com/nosinmipixel/museum-game).

- **Código** (y `.blend`): **GPL-3.0**
- **Assets** (3D, imágenes, texturas, audio, música): **CC BY-NC-SA 4.0** — *solo no comercial* para terceros; atribución obligatoria; obras derivadas bajo la misma licencia. El autor original conserva todos los derechos comerciales.
- **Fonts:** varias bajo **SIL OFL 1.1** (Matrix Sans, BoldPixels, etc.) + fuentes propias.
- **Atribución requerida en cualquier redistribución/derivado:**
  > *"A Day in the Museum" © 2026 Ángel Sánchez (nosinmipixel) — Code: GPLv3 | Assets: CC BY-NC-SA 4.0 — Creative assistance with DeepSeek and ChatGPT*
- El repo original incluye además un `docs/AI_DISCLOSURE.md` (el proyecto Defold también se desarrolla con asistencia de IA → conviene replicar el patrón).

> ⚠️ **Consecuencia para el repo nuevo:** como la versión Defold reutiliza sonidos/música/algunas imágenes del original, su repo debe documentar la **doble licencia** (GPL-3.0 para el código Lua nuevo + CC BY-NC-SA 4.0 para los assets heredados) con la atribución anterior. Como el autor es el mismo (Ángel Sánchez), no hay conflicto de derechos, pero el repo debe declararlo para terceros.

## 5. Investigación (GitHub Pages + Defold/CI)

### 5.1 Método de publicación recomendado
**GitHub Actions + `actions/upload-pages-artifact` + `actions/deploy-pages`** (fuente "GitHub Actions" en Settings → Pages):

- Cada `push` a `main` → compila → sube artefacto → despliega vía OIDC (tokens firmados).
- El repo de código queda limpio (los binarios se generan en CI, no se commitean).
- Sin el límite de builds/hora de los métodos clásicos (rama `gh-pages`/carpeta `docs`).

### 5.2 Límites de GitHub Pages (verificados)
- **1 GB** por repo (recomendado) y **1 GB** por sitio publicado.
- **100 MB por archivo** (bloqueo); aviso desde ~50 MB. Los chunks `gameN.arcd` de 2 MB no suponen problema. ✅
- **~100 GB/mes** de ancho de banda gratuito (soft limit). Un build de ~38.5 MB descargado por muchas personas se agota rápido → conviene optimizar tamaño (ver §6).
- **Repo público obligatorio** en plan gratuito (los repos privados con Pages requieren plan de pago).
- **Saves en HTML5:** Defold mapea el savegame a `localStorage` del navegador del visitante → se pierde al limpiar datos o en incógnito. Sin backend. Es el comportamiento esperado.

### 5.3 Build headless con `bob` (verificado)
- `bob.jar` se descarga de `https://d.defold.com/archive/<sha1>/bob/bob.jar` (URL verificada: responde **HTTP 200** con el sha1 del proyecto; el alias `stable` NO existe → hay que fijar el sha1).
- **Requiere OpenJDK 25** (según manual oficial de bob).
- Comando (estado actual): `java --enable-native-access=ALL-UNNAMED -jar bob.jar --platform wasm-web --variant debug --archive resolve build bundle --bundle-output bundle_out` (el `--variant debug` es obligatorio, ver §5.4; el histórico de correcciones está más abajo)
- La plantilla `[html5] htmlfile` del `game.project` se aplica igual en CI headless. ✅
- ⚠️ **CORRECCIÓN (Sept. 2026, tras el primer fallo de CI):** la plataforma web correcta es **`wasm-web`** — `js-web` fue renombrada y bob 1.13.0 falla con `Platform js-web not supported`. Además, la estructura `__htmlLaunchDir` solo la genera el **editor**: con bob por CLI la salida de `bundle` va a `build/default/<título>/`; con `--bundle-output bundle_out` es determinista: `bundle_out/<título>/`. Comando correcto:
  `java --enable-native-access=ALL-UNNAMED -jar bob.jar --platform wasm-web --archive resolve build bundle --bundle-output bundle_out`
  (ver workflow real en `.github/workflows/deploy.yml`).

### 5.4 Diagnóstico de la divergencia CLI vs editor (RESUELTO, Sept. 2026)

Tras actualizar a Defold **1.13.1** (sha `574678c7d44be490d874fbed2d0ae6211feec4d9`), el build bob CLI seguía rompiendo el gameplay (NPCs mal ubicados, interacciones sin respuesta, textos rotos) mientras el bundle del editor funcionaba. Diagnóstico por prueba A/B con bundles mixtos (motor de un build + archive del otro):

| Motor | Archive | Resultado |
|---|---|---|
| debug (editor) | editor | ✅ funcionaba |
| release (CLI) | CLI | ❌ roto |
| release (CLI) | editor | ❌ roto |
| debug (editor) | CLI | ✅ **funcionaba** |

**Conclusión inicial (incorrecta):** se atribuyó el fallo a la variante *release* del motor wasm. La matriz A/B era real, pero la interpretación no: el patrón observado (todo bundle con motor debug funciona, todo bundle con motor release falla) tenía otra explicación — ver §5.5.

**⚡ CAUSA RAÍZ REAL (confirmada por los maintainers de Defold en [defold/defold#13125](https://github.com/defold/defold/issues/13125), Sept. 2026):** el juego usaba `tostring(hash)`/`tostring(go.get_id())` para resolver nombres de objetos. En builds **DEBUG** el engine conserva una tabla reverse-hash y el tostring devuelve el string original (`[/furniture/door_front]`); en **RELEASE** esa tabla se elimina y devuelve un valor opaco sin la ruta. Todo sistema que identificaba objetos por su nombre de GO fallaba en silencio: NPCs (spawn manager no los posicionaba), puertas (prefijo de animación corrupto), objetos de exhibición, zonas, estanterías, slots de inventario. El editor nunca lo destapó porque **siempre empaqueta debug**.

**Solución aplicada (release-safe):**
- `main/go_id_registry.lua` (GENERADO, no editar): registra `hash(ruta) → ruta` en runtime para las ~220 instancias de las colecciones — `hash()` de Lua produce valores idénticos en ambas variantes.
- `tools/generate_go_id_registry.py`: regenera el registro; **ejecutar tras añadir/renombrar instancias** en cualquier `.collection`.
- Los scripts resuelven ids vía registro con fallback al parseo de tostring (que sigue funcionando en DEBUG): `npc.script`, `doors.script` (además usa el id del propio componente via `msg.url().fragment`, estable por tipo), `exhibition_object.script`, `zone_alert.script`, `bookcase.script`, `inventory_manager.script` (claves de slots idénticas al formato de guardado anterior → partidas compatibles), `slot_furniture.script` (mapas hash→string en vez de `hash_to_str`), `cat.script` (detección de puertas). Ver GOTCHA #45 en `docs/DEV_GOTCHAS.md`.
- **Consecuencia:** la variante release vuelve a ser válida para producción; el CI puede abandonar `--variant debug` (wasm ~2.39 MB vs ~2.87 MB) una vez verificado el build release arreglado.

**Procedimiento al actualizar el editor Defold** (mantener CI y editor sincronizados):

1. Actualizar el editor, abrir el proyecto y probar el juego en local (no actualizar `DEFOLD_SHA` si el juego falla en el editor).
2. Obtener el sha1 del nuevo motor en https://github.com/defold/defold/releases — línea `Channel=stable sha1: …` de la versión correspondiente.
3. Actualizar `DEFOLD_SHA` en `.github/workflows/deploy.yml` (es la única línea a cambiar) y hacer push a `main` — el CI recompila y despliega automáticamente.
4. **Punto de control tras cualquier cambio de motor:** verificar el gameplay completo (NPCs, puertas, exhibición, inventario) tanto en el editor como en un build release de bob. ⚠️ Regla de oro: **nunca usar `tostring(hash)`/`tostring(go.get_id())` para lógica** — solo para logs de debug (GOTCHA #45); usar `main/go_id_registry.lua`.

### 5.5 Regla del proyecto: hashes y variante release (GOTCHA #45)

- `hash` es unidireccional en release: `tostring(hash("x"))`/`tostring(go.get_id())` solo devuelven el string original en builds DEBUG.
- ❌ NUNCA: parsear/comparar el resultado de `tostring()` de un hash o url para lógica (ids, tipos, claves de guardado).
- ✅ Resolver nombres de GO: `id_registry.path_of(go.get_id())` / `id_registry.name_of(...)` (`main/go_id_registry.lua`, generado).
- ✅ Comparar hashes con `==` o usarlos como claves de tabla (válido en ambas variantes).
- ✅ En mensajes, enviar **strings** (mapas `*_STR` tipo `SLOT_TYPE_STR`) en vez de hashes que el receptor convierta con `tostring`.
- Regenerar el registro tras tocar colecciones: `python3 tools/generate_go_id_registry.py`.

## 6. Riesgos y consideraciones

1. **Tamaño del build (~38.5 MB desplegable, verificado Sept. 2026 — antes se estimaban ~70 MB):** sigue siendo el principal factor de descarga inicial, pero ya razonable para Pages. Los atlas grandes de texturas (quiz/exhibition) y `custom_resources = /assets` siguen siendo sospechosos de inflar el build. **Optimización futura sugerida** (no bloqueante, prioridad baja): compresión de texturas en `game.project`, revisar `custom_resources`. *(Los `.xcf` ya quedan fuera vía `.gitignore`.)*
2. **Carpeta con espacios** (`Top Down Museum Game/`) en la ruta del build → comillas obligatorias en el workflow.
3. ✅ **RESUELTO:** los `.xcf` (y `.pxo`) se excluyen vía `.gitignore`; solo se versionan los PNG exportados.
4. **Doble licencia:** el README debe declarar GPL-3.0 + CC BY-NC-SA 4.0 con la atribución de §4, y conviene incluir `docs/ASSETS_LICENSE.md` y `docs/AI_DISCLOSURE.md` propios.
5. **Saves en localStorage** (se pierden con datos de navegación) — comportamiento esperado, mencionarlo en el README.
6. **Controles reales** verificados en `input/game.input_binding`: flechas + WASD, Espacio (spray), R, P, ESC, TAB, clic izq., clic der., touch (ya documentados en el README).

## 7. Plan de acción (orden de ejecución)

### Fase A — Preparación del repo local
1. ✅ **`git init`** en la raíz del proyecto — **hecho** (rama `main`, identidad local `Ángel Sánchez <nosinmipixel@users.noreply.github.com>`).
2. ✅ **Crear `.gitignore`** de Defold — **hecho** (el archivo real es más completo que el propuesto: incluye además `*.pxo`, certificados, archivos de agentes IA):
   ```gitignore
   # Defold
   build/
   .internal/

   # Entorno / IDE
   .DS_Store
   *.iml
   .idea/
   .vscode/

   # Fuentes del editor
   # (en el archivo REAL ya activas: *.xcf y *.pxo excluidos)
   *.xcf
   *.pxo
   ```
3. ✅ **Crear `README.md`** — **hecho** (incluye además `README_ES.md` bilingüe). Contenido:
   - Título: **Top Down Museum Game (Defold)** — repo `museum-game-2d`.
   - Descripción: versión 2D en Defold/Lua que reimplementa el juego del Museo de Prehistoria de Valencia; enlace al original UPBGE (https://github.com/nosinmipixel/museum-game).
   - **Jugar online:** `https://nosinmipixel.github.io/museum-game-2d/`
   - Controles (verificados antes de publicar).
   - Sección **Licencia**: doble licencia GPL-3.0 (código) + CC BY-NC-SA 4.0 (assets) con la atribución de §4.
   - Nota sobre saves en localStorage.
4. ✅ **Crear `LICENSE`** — **hecho** (texto completo GPL-3.0 ya en la raíz; al crear el repo en GitHub, NO dejar que lo autogenere).
5. ✅ **Crear `docs/ASSETS_LICENSE.md`** — **hecho** (+ versión española `ASSETS_LICENSE_ES.md`).
6. ✅ **Crear `docs/AI_DISCLOSURE.md`** — **hecho** (+ `AI_DISCLOSURE_ES.md`).

### Fase B — CI + GitHub Pages
7. ✅ **Crear `.github/workflows/deploy.yml`** — **hecho**, con 3 correcciones tras el primer fallo de CI: plataforma `wasm-web` (no `js-web`), salida determinista `--bundle-output bundle_out` y actions actualizadas (checkout v7, setup-java v6, pages v5).
8. ✅ **Probar localmente el comando de bob** — **hecho (Sept. 2026)**: con `--bundle-output` la salida es determinista en `bundle_out/<título>/` con `index.html`, `dmloader.js`, wasm y `archive/`. Desplegable: **~38.5 MB**. Aplanado: copiar el subdirectorio del título a `public/`. (La estructura `__htmlLaunchDir` solo la genera el editor.)
9. ✅ **Crear el repo en GitHub:** `museum-game-2d`, **público** — **hecho** (push vía SSH con deploy key `cachyos-defold`).
10. ✅ **Push** a `main` — **hecho** (el workflow se dispara en cada push).
11. ✅ **Activar GitHub Pages:** Source: **GitHub Actions** — **hecho**.
12. ✅ **Verificar** la URL — **hecho**: `index.html`, `TopDownMuseumGame.wasm` y chunks `archive/gameN.arcd` responden HTTP 200, y el usuario ha verificado la jugabilidad completa en navegador (incógnito, Sept. 2026).

### Fase C — Pulido (opcional, posterior)
13. ⬜ (opcional) Optimización de tamaño del build (§6.1): revisar si `custom_resources = /assets` arrastra archivos innecesarios al archive y aplicar compresión de texturas a los atlas grandes. *(Los `.xcf` ya quedan fuera por `.gitignore`; desplegable actual ~39 MB → prioridad baja.)*
14. ✅ **Enlazar el repo nuevo desde el README del repo original (referencia cruzada) y viceversa** — **hecho (Sept. 2026)**: callout con enlace al repo 2D y al juego online añadido a `README.md` y `README.es.md` de `museum-game`; el repo 2D ya enlazaba al original desde su creación.

## 8. Workflow de despliegue (referencia — el archivo real y activo es `.github/workflows/deploy.yml`)

> ✅ **Estructura validada (Sept. 2026):** el **editor** escribe en `build/default_html5/__htmlLaunchDir/<título>/`; bob por CLI escribe en `build/default/<título>/`, o en `<bundle-output>/<título>/` si se usa `--bundle-output` (salida determinista, la que usa el workflow). El paso de aplanado copia el contenido del subdirectorio del título a `public/`.

```yaml
name: Build & Deploy HTML5 a GitHub Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: true

env:
  # SHA1 del motor Defold. Debe coincidir con el editor (procedimiento en §5.4).
  DEFOLD_SHA: 574678c7d44be490d874fbed2d0ae6211feec4d9

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v7

      - name: Setup OpenJDK 25 (requisito de bob)
        uses: actions/setup-java@v6
        with:
          distribution: temurin
          java-version: '25'

      - name: Descargar bob.jar (URL verificada, fijada al sha1 del proyecto)
        run: curl -fsSL -o bob.jar "https://d.defold.com/archive/${{ env.DEFOLD_SHA }}/bob/bob.jar"

      - name: Compilar HTML5 (wasm-web + archive, variante debug)
        run: java --enable-native-access=ALL-UNNAMED -jar bob.jar --platform wasm-web --variant debug --archive resolve build bundle --bundle-output bundle_out

      - name: Aplanar salida para que index.html quede en la raiz
        run: |
          mkdir -p public
          # bob escribe bundle_out/<Titulo>/ (carpeta nombrada por el titulo del
          # proyecto, con espacios). Copiamos el contenido del primer subdirectorio
          # a public/ de forma agnostica al titulo.
          title_dir="$(find bundle_out -mindepth 1 -maxdepth 1 -type d | head -n1)"
          cp -r "$title_dir/." public/
          ls -la public/

      - name: Subir artefacto Pages
        uses: actions/upload-pages-artifact@v5
        with:
          path: public

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Desplegar en GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v5
```

> Alternativa validable: imagen Docker oficial `defold/bob` (`docker run --rm -v "$(pwd):/project" -w /project defold/bob --platform wasm-web --archive resolve build bundle --bundle-output bundle_out`) en lugar de descargar `bob.jar` + JDK. *(bob.jar + JDK probado con éxito en local; la imagen Docker queda como alternativa.)*

## 9. Checklist final (antes de dar por cerrado)

- [x] `git init` + ✅ `.gitignore` creado (excluye `build/`, `.internal/`, `*.xcf`, `*.pxo`)
- [x] `README.md` con enlace al original, controles verificados y URL de juego (+ `README_ES.md`)
- [x] `LICENSE` GPL-3.0 + `docs/ASSETS_LICENSE.md` (CC BY-NC-SA 4.0 + atribución) + `docs/AI_DISCLOSURE.md` (versiones EN/ES)
- [x] Comando de bob probado localmente (misma versión/sha1 que CI) — ⚠️ corregido: plataforma `wasm-web` + `--bundle-output bundle_out` (salida: `bundle_out/<título>/`)
- [x] YAML del workflow validado (`yaml-lint`; `actionlint` no disponible en el sistema) antes del push
- [x] `.github/workflows/deploy.yml` activo — CI en verde (build + deploy ~46 s, `--variant debug`)
- [x] Repo `museum-game-2d` público creado y `push` a `main` (deploy key SSH)
- [x] Pages → Source: GitHub Actions
- [x] Respaldo de despliegue manual: `deploy_pages.sh` → rama `gh-pages` (probado; alternativo si el CI falla)
- [x] URL `https://nosinmipixel.github.io/museum-game-2d/` funcionando (HTTP 200 en index/wasm/archive) — ✅ jugabilidad verificada por el usuario en navegador (incógnito, Sept. 2026)
- [ ] (Opcional) Optimización de tamaño del build — desplegable actual ~39 MB, prioridad baja

---
*Última actualización: Septiembre 2026 — **PUBLICADO y estable**: causa raíz REAL confirmada (uso de `tostring(hash)` solo válido en debug — §5.4/§5.5, fix con registro reverso de ids); bug reportado y confirmado por Defold en #13125.*
