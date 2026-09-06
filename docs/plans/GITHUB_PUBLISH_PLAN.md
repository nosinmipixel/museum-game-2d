# 🚀 Plan de publicación en GitHub — Versión Defold (2D/Lua)

> **Documento de análisis + plan de acción.** Estado: **en ejecución** — Fase A completada (salvo `git init`); Fase B: prueba local de `bob` ✅, workflow CI ⬜, publicación ⬜. *(Última revisión: Septiembre 2026)*
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
- Comando: `java -jar bob.jar --platform js-web --archive resolve build bundle`
- La plantilla `[html5] htmlfile` del `game.project` se aplica igual en CI headless. ✅
- ✅ **Verificado en ejecución (Sept. 2026):** la salida real de `bob` es `build/default_html5/__htmlLaunchDir/<título>/` (⚠️ **no** `build/default/…` como figuraba en el primer borrador del §8). Aplanado: copiar el contenido del subdirectorio del título a `public/`.

## 6. Riesgos y consideraciones

1. **Tamaño del build (~39 MB desplegable, verificado Sept. 2026 — antes se estimaban ~70 MB):** sigue siendo el principal factor de descarga inicial, pero ya razonable para Pages. Los atlas grandes (`.texturec` de 32 MB en atlas quiz/exhibition) y `custom_resources = /assets` siguen siendo sospechosos de inflar el build. **Optimización futura sugerida** (no bloqueante, prioridad baja): compresión de texturas en `game.project`, revisar `custom_resources`. *(Los `.xcf` ya quedan fuera vía `.gitignore`.)*
2. **Carpeta con espacios** (`Top Down Museum Game/`) en la ruta del build → comillas obligatorias en el workflow.
3. ✅ **RESUELTO:** los `.xcf` (y `.pxo`) se excluyen vía `.gitignore`; solo se versionan los PNG exportados.
4. **Doble licencia:** el README debe declarar GPL-3.0 + CC BY-NC-SA 4.0 con la atribución de §4, y conviene incluir `docs/ASSETS_LICENSE.md` y `docs/AI_DISCLOSURE.md` propios.
5. **Saves en localStorage** (se pierden con datos de navegación) — comportamiento esperado, mencionarlo en el README.
6. **Controles reales** verificados en `input/game.input_binding`: flechas + WASD, Espacio (spray), R, P, ESC, TAB, clic izq., clic der., touch (ya documentados en el README).

## 7. Plan de acción (orden de ejecución)

### Fase A — Preparación del repo local
1. ⬜ **`git init`** en la raíz del proyecto. *(pendiente)*
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
7. ⬜ **Crear `.github/workflows/deploy.yml`** (esqueleto corregido en §8; ruta de salida ya verificada). *(pendiente)*
8. ✅ **Probar localmente el comando de bob** — **hecho (Sept. 2026)**: build OK en `build/default_html5/__htmlLaunchDir/Top Down Museum Game/` con `index.html`, `dmloader.js`, wasm y `archive/`. Desplegable: **~39 MB**. Aplanado: copiar el subdirectorio del título a `public/`.
9. ⬜ **Crear el repo en GitHub:** `museum-game-2d`, **público**, con licencia GPL-3.0, **sin** README/LICENSE auto-generados si ya se prepararon localmente.
10. ⬜ **Push** a `main` (convención de GitHub; el workflow disparará en esa rama).
11. ⬜ **Activar GitHub Pages:** Settings → Pages → Source: **GitHub Actions** (necesario para `deploy-pages`).
12. ⬜ **Verificar** la URL `https://nosinmipixel.github.io/museum-game-2d/` (primer despliegue, comprobar consola del navegador sin errores de carga wasm/archive).

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

      - name: Compilar HTML5 (js-web + archive)
        run: java -jar bob.jar --platform js-web --archive resolve build bundle

      - name: Aplanar __htmlLaunchDir para que index.html quede en la raiz
        run: |
          mkdir -p public
          # El build genera build/<config>/__htmlLaunchDir/<Titulo>/ con index.html
          # dentro (carpeta nombrada por el titulo, con espacios). Localizamos
          # __htmlLaunchDir de forma agnostica a la configuracion y al titulo
          # (salida real verificada: build/default_html5/__htmlLaunchDir/).
          launch_dir="$(find build -type d -name __htmlLaunchDir | head -n1)"
          title_dir="$(find "$launch_dir" -mindepth 1 -maxdepth 1 -type d | head -n1)"
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

> Alternativa validable: imagen Docker oficial `defold/bob` (`docker run --rm -v "$(pwd):/project" -w /project defold/bob --platform js-web --archive resolve build bundle`) en lugar de descargar `bob.jar` + JDK. *(Fase B.8 probada con éxito usando `bob.jar` + JDK; la imagen Docker queda como alternativa si el CI da problemas.)*

## 9. Checklist final (antes de dar por cerrado)

- [ ] `git init` *(pendiente)* + ✅ `.gitignore` creado (excluye `build/`, `.internal/`, `*.xcf`, `*.pxo`)
- [x] `README.md` con enlace al original, controles verificados y URL de juego (+ `README_ES.md`)
- [x] `LICENSE` GPL-3.0 + `docs/ASSETS_LICENSE.md` (CC BY-NC-SA 4.0 + atribución) + `docs/AI_DISCLOSURE.md` (versiones EN/ES)
- [x] Comando de bob probado localmente (misma versión/sha1 que CI) — salida verificada: `build/default_html5/__htmlLaunchDir/` (~39 MB)
- [ ] YAML del workflow validado (`actionlint` o `yamllint`) antes del primer push
- [ ] `.github/workflows/deploy.yml` activo
- [ ] Repo `museum-game-2d` público creado y `push` a `main`
- [ ] Pages → Source: GitHub Actions
- [ ] URL `https://nosinmipixel.github.io/museum-game-2d/` funcionando (sin errores en consola)
- [ ] (Opcional) Optimización de tamaño del build — desplegable actual ~39 MB (antes ~70 MB estimados), prioridad baja

---
*Última actualización: Septiembre 2026 — Fase A completada (salvo `git init`), prueba local de bob validada (salida real: `build/default_html5/__htmlLaunchDir/`, ~39 MB), workflow CI pendiente.*
