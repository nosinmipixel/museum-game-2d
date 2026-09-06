# 🚀 Plan de publicación en GitHub — Versión Defold (2D/Lua)

> **Documento de análisis + plan de acción.** Estado: **PUBLICADO ✅** (Sept. 2026) — Despliegue activo. **Divergencia CLI/editor RESUELTA** (causa raíz: variante *release* del motor rompe el gameplay, ver §5.4). El CI vuelve a estar activo con `--variant debug`, que produce un motor byte-idéntico al del editor. Queda solo Fase C (opcional).
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
| **Despliegue** | **CI con GitHub Actions** | Cada push a `main` compila con `bob` y publica automáticamente. Repo limpio (sin 366 MB de build), builds reproducibles, sin límite de builds por hora. |

## 3. Auditoría del estado actual (local)

Datos verificados directamente en el proyecto:

- **El proyecto NO es aún un repositorio git** (pendiente `git init` + primer commit).
- ✅ **`.gitignore` ya existe** (excluye `build/`, `.internal/`, `*.xcf`, `*.pxo`, IDEs, certificados) → decisión del §6.3 resuelta.
- ✅ **`.gitattributes` ya existe**.
- `game.project`:
  - `title = Top Down Museum Game`
  - `[html5] htmlfile = /assets/custom_template.html` (template HTML5 personalizado → respetado en CI headless)
  - `custom_resources = /assets` ⚠️ (copia la carpeta `assets/` completa al build; ver riesgo en §6)
  - **Sin extensiones nativas** → bob en CI no necesita `--email/--auth`.
  - **Sin dependencias de librerías** → `resolve` es trivial.
- **Tamaños:**
  - Fuente (sin `build/`): ~97 MB (de los cuales `assets/` ≈ 89 MB, incluye `.xcf` de GIMP >5 MB)
  - Build HTML5 local completo: **~366 MB** en `build/default_html5/`
  - **Contenido desplegable real: ~39 MB** en `build/default_html5/__htmlLaunchDir/` (verificado Sept. 2026; mejor que la estimación inicial de ~70 MB)
- **Estructura del build desplegable** (verificado):
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
- **Versión del motor:** sha1 `f735c12192bf95684e6ae1ae27c400b8170fc6d8` (Defold 1.13.0) — presente en `build_input_data.json`.
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
- **~100 GB/mes** de ancho de banda gratuito (soft limit). Un build de ~70 MB descargado por muchas personas se agota rápido → conviene optimizar tamaño (ver §6).
- **Repo público obligatorio** en plan gratuito (los repos privados con Pages requieren plan de pago).
- **Saves en HTML5:** Defold mapea el savegame a `localStorage` del navegador del visitante → se pierde al limpiar datos o en incógnito. Sin backend. Es el comportamiento esperado.

### 5.3 Build headless con `bob` (verificado)
- `bob.jar` se descarga de `https://d.defold.com/archive/<sha1>/bob/bob.jar` (URL verificada: responde **HTTP 200** con el sha1 del proyecto; el alias `stable` NO existe → hay que fijar el sha1).
- **Requiere OpenJDK 25** (según manual oficial de bob).
- Comando: `java --enable-native-access=ALL-UNNAMED -jar bob.jar --platform wasm-web --archive resolve build bundle --bundle-output bundle_out` ⚠️ (ver corrección más abajo: `js-web` ya no existe en Defold 1.13.0)
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

**Conclusión: el culpable es la variante *release* del motor wasm**, no el empaquetado del archive (absuelto) ni el modo pthread (absuelto: el bundle release sin COOP/COEP —monohilo forzado— también fallaba). Hipótesis a reportar a Defold: el motor release usa el backend **WebGPU** (ambos wasm lo incluyen; el debug fuerza el camino WebGL, donde el juego funciona). Investigación adicional suspuesta: el juego no declara `is_debug` ni condicionales de variante en Lua.

**Solución aplicada:** el editor siempre empaqueta la variante **debug** — su wasm es **byte-idéntico** (md5 verificado) a `bob --variant debug`. El workflow de CI usa esa variante y reproduce exactamente el build que funciona.

**Procedimiento al actualizar el editor Defold** (mantener CI y editor sincronizados):

1. Actualizar el editor, abrir el proyecto y probar el juego en local (no actualizar `DEFOLD_SHA` si el juego falla en el editor).
2. Obtener el sha1 del nuevo motor en https://github.com/defold/defold/releases — línea `Channel=stable sha1: …` de la versión correspondiente.
3. Actualizar `DEFOLD_SHA` en `.github/workflows/deploy.yml` (es la única línea a cambiar) y hacer push a `main` — el CI recompila y despliega automáticamente.
4. **Punto de control obligatorio tras cualquier cambio de motor:** el `TopDownMuseumGame.wasm` del build debe pesar **~2.87 MB** (variante debug) y NO debe existir `TopDownMuseumGame_pthread.wasm` en la salida. Si pesa ~2.4 MB, la variante release se ha colado → gameplay roto (ver tabla de diagnóstico anterior).

## 6. Riesgos y consideraciones

1. **Tamaño del build (~39 MB desplegable, verificado Sept. 2026 — antes se estimaban ~70 MB):** sigue siendo el principal factor de descarga inicial, pero ya razonable para Pages. Los atlas grandes (`.texturec` de 32 MB en atlas quiz/exhibition) y `custom_resources = /assets` siguen siendo sospechosos de inflar el build. **Optimización futura sugerida** (no bloqueante, prioridad baja): compresión de texturas en `game.project`, revisar `custom_resources`. *(Los `.xcf` ya quedan fuera vía `.gitignore`.)*
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
8. ✅ **Probar localmente el comando de bob** — **hecho (Sept. 2026)**: build OK en `build/default_html5/__htmlLaunchDir/Top Down Museum Game/` con `index.html`, `dmloader.js`, wasm y `archive/`. Desplegable: **~39 MB**. Aplanado: copiar el subdirectorio del título a `public/`.
9. ✅ **Crear el repo en GitHub:** `museum-game-2d`, **público** — **hecho** (push vía SSH con deploy key `cachyos-defold`).
10. ✅ **Push** a `main` — **hecho** (el workflow se dispara en cada push).
11. ✅ **Activar GitHub Pages:** Source: **GitHub Actions** — **hecho**.
12. ✅ **Verificar** la URL — **hecho**: `index.html`, `TopDownMuseumGame.wasm` y chunks `archive/gameN.arcd` responden HTTP 200. Pendiente solo la comprobación visual del usuario en el navegador.

### Fase C — Pulido (opcional, posterior)
13. ⬜ (opcional) Optimización de tamaño del build (§6.1): revisar si `custom_resources = /assets` arrastra archivos innecesarios al archive y aplicar compresión de texturas a los atlas grandes. *(Los `.xcf` ya quedan fuera por `.gitignore`; desplegable actual ~39 MB → prioridad baja.)*
14. ⬜ Enlazar el repo nuevo desde el README del repo original (referencia cruzada) y viceversa.

## 8. Workflow de despliegue (esqueleto validado en B.8; pendiente de crear el archivo)

> ✅ **Estructura validada en Fase B.8 (Sept. 2026):** la salida real de bob es `build/default_html5/__htmlLaunchDir/<título>/` (⚠️ no `build/default/…`). El paso de aplanado localiza `__htmlLaunchDir` dinámicamente, sin rutas hardcodeadas.

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
  # SHA1 del motor Defold del proyecto (build_input_data.json). Actualizar al cambiar de editor.
  DEFOLD_SHA: f735c12192bf95684e6ae1ae27c400b8170fc6d8

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup OpenJDK 25 (requisito de bob)
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '25'

      - name: Descargar bob.jar (URL verificada, fijada al sha1 del proyecto)
        run: curl -fsSL -o bob.jar "https://d.defold.com/archive/${{ env.DEFOLD_SHA }}/bob/bob.jar"

      - name: Compilar HTML5 (wasm-web + archive)
        run: java --enable-native-access=ALL-UNNAMED -jar bob.jar --platform wasm-web --archive resolve build bundle --bundle-output bundle_out

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
        uses: actions/upload-pages-artifact@v3
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
        uses: actions/deploy-pages@v4
```

> Alternativa validable: imagen Docker oficial `defold/bob` (`docker run --rm -v "$(pwd):/project" -w /project defold/bob --platform wasm-web --archive resolve build bundle --bundle-output bundle_out`) en lugar de descargar `bob.jar` + JDK. *(bob.jar + JDK probado con éxito en local; la imagen Docker queda como alternativa.)*

## 9. Checklist final (antes de dar por cerrado)

- [x] `git init` + ✅ `.gitignore` creado (excluye `build/`, `.internal/`, `*.xcf`, `*.pxo`)
- [x] `README.md` con enlace al original, controles verificados y URL de juego (+ `README_ES.md`)
- [x] `LICENSE` GPL-3.0 + `docs/ASSETS_LICENSE.md` (CC BY-NC-SA 4.0 + atribución) + `docs/AI_DISCLOSURE.md` (versiones EN/ES)
- [x] Comando de bob probado localmente (misma versión/sha1 que CI) — ⚠️ corregido: plataforma `wasm-web` + `--bundle-output bundle_out` (salida: `bundle_out/<título>/`)
- [x] YAML del workflow validado (`yaml-lint`; `actionlint` no disponible en el sistema) antes del push
- [x] `.github/workflows/deploy.yml` activo — CI en verde (run #2: build + deploy, 49 s)
- [x] Repo `museum-game-2d` público creado y `push` a `main` (deploy key SSH)
- [x] Pages → Source: GitHub Actions
- [x] URL `https://nosinmipixel.github.io/museum-game-2d/` funcionando (HTTP 200 en index/wasm/archive; comprobar consola del navegador al jugar)
- [ ] (Opcional) Optimización de tamaño del build — desplegable actual ~39 MB, prioridad baja

---
*Última actualización: Septiembre 2026 — **PUBLICADO y estable**: causa raíz de la divergencia CLI/editor identificada (variante release del motor, §5.4) y CI reactivado con `--variant debug`.*
