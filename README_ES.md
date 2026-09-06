[![es](https://img.shields.io/badge/lang-es-yellow.svg)](README_ES.md)
[![en](https://img.shields.io/badge/lang--en-blue.svg)](README.md)

# 🏛️ Top Down Museum Game (Defold)

*A Day in the Museum* — versión 2D realizada en **Defold/Lua** de un juego educativo ambientado en el Museo de Prehistoria de Valencia.

![A Day in the Museum](https://github.com/user-attachments/assets/5fc2e42a-2786-4dbd-b62d-15679924773e)

Juego de exploración en vista cenital donde eres el **conservador de un museo**: recorres las salas, interactúas con los objetos de la colección, conversas con los visitantes (diálogos con preguntas tipo quiz), eliminas plagas (cucarachas y ratas) con spray y gestionas tus recursos (salud, spray, energía) desde el HUD.

> Versión original (3D, UPBGE/Blender): [nosinmipixel/museum-game](https://github.com/nosinmipixel/museum-game)

## 🎮 Jugar online

Juega gratis en tu navegador (desplegado en GitHub Pages vía CI):

**https://nosinmipixel.github.io/museum-game-2d/**

## 🎮 Cómo se juega

Eres el **conservador novato** de un museo. Completa las **cuatro tareas** para ganar experiencia, subir de rango y llegar a **director del museo**:

1. **Catalogación** — Recoge los objetos arqueológicos que aparecerán en la zona de ingreso, guárdalos en la estantería de su periodo en el almacén (Paleolítico, Neolítico, Edad del Bronce, periodo Ibérico y Romano) y, por último, exhíbelos en las salas de exposición.
2. **Restauración** — Algunos objetos necesitan ser restaurados, aunque para ello, nuestra restauradora pondrá a prueba tus conocimientos de conservación preventiva.
3. **Asistencia al público** — Investigadores, estudiantes y visitantes te harán preguntas sobre arqueología; responde bien para aumentar tus habilidades.
4. **Plagas** — Cucarachas y ratas amenazan el museo. Utiliza el spray para acabar con ellas y elimina los **nidos** con un insecticida especial que permite frenar la plaga de raíz.

![Quiz](https://github.com/user-attachments/assets/5a58238d-938f-45a4-8839-efe14940c544)

**El ciclo de los objetos:** cada pieza aparece en la zona de ingreso → recógela → restáurala si lo necesita → deposítala en la estantería del periodo correcto → espera a que esté lista para ser expuesta → **expónla en la vitrina** de la sala de exposiciones. La colección completa son **10 objetos** (2 por periodo).

**Gestiona tus recursos:** la **salud** (recupérala con botiquines), el **spray** (repónlo con botes), la **energía** (se agota con el día). Vigila las **condiciones climáticas**: hay accesos vigilados donde las puertas abiertas disparan la temperatura y la humedad: ciérralas. Ten en cuenta que las condiciones climáticas inadecuadas afectan no solo a las piezas, tú también empezarás a encontrarte mal.

![Visita las salas](https://github.com/user-attachments/assets/db03362e-8628-4a75-b45b-0b23bdca14c0)

Además puedes: visitar las **salas de exposiciones** para aprender sobre las piezas, consultar los **libros de la biblioteca** (¡te ayudan con las preguntas!) y hacerte amigo del **gato** del museo (¡te ayudará a deshacerte de las plagas!).

Completa las 4 tareas para convertirte en **director del museo**. Si las plagas te vencen o tienes algún percance muy serio, reaparecerás en el punto de partida.

## 🕹️ Controles

| Acción | Teclado | Ratón | Móvil / Táctil |
|---|---|---|--|
| Moverse | Flechas o WASD | — | Botones Joystick |
| Interactuar (diálogos, muebles, objetos, puertas) | — | Clic izquierdo / toque | Botón icono mano |
| Disparar spray | Espacio | Clic derecho (mantener) | Botón icono spray |
| Pausa | P | — | Botón del HUD |
| Cerrar diálogos / paneles | ESC | — | — |
| Reiniciar estado del juego (dev) | R | — | — |

> En móvil, la interacción usa un sensor táctil alrededor del jugador que selecciona el objetivo más alineado con tu dirección de movimiento (detalles en `docs/DEV_GOTCHAS.md` #31).

## 📁 Estructura del proyecto

```
├── game.project                 # Configuración del proyecto Defold
├── bootstrap.collection         # Colección raíz
├── intro.collection             # Escena de introducción
├── level_01.collection          # Nivel principal (cargado por proxy)
├── main/                        # Módulos Lua compartidos y scripts de gestión
├── features/                    # Player, enemigos, NPCs, muebles, props
├── assets/                      # Texturas, sonidos, textos, tiles
├── gui/                         # Interfaces (HUD, pausa, biblioteca, diálogos)
├── input/                       # Bindings de teclado/ratón/táctil
├── docs/                        # Documentación del proyecto
└── audit_globals.sh             # Auditoría de funciones globales (dev)
```

## 📚 Documentación

Toda la documentación del proyecto vive en [`docs/`](docs/):

- [`DEV_GOTCHAS.md`](docs/DEV_GOTCHAS.md) — patrones peligrosos de Defold descubiertos durante el desarrollo (**léelo antes de añadir scripts de interacción**).
- [`PROJECT_SUMMARY.md`](docs/PROJECT_SUMMARY.md) — resumen técnico del juego, sistemas y arquitectura.
- [`DEFOLD_LUA_STANDARDS.md`](docs/DEFOLD_LUA_STANDARDS.md) — guía canónica de buenas prácticas Lua/Defold.
- [`INVENTORY_SYSTEM.md`](docs/INVENTORY_SYSTEM.md) — documentación del sistema de inventario/coleccionables.
- [`plans/`](docs/plans/) — planes activos o parciales (publicación en GitHub, controles táctiles, disparo, migración GUI).
- [`plans/archive/`](docs/plans/archive/) — planes ya ejecutados o históricos (nidos, refactorización, estructura de escenas, análisis de rendimiento).
- Licencias de assets y disclosure de IA: `ASSETS_LICENSE*.md`, `AI_DISCLOSURE*.md`.

## 🛠️ Desarrollo local

1. Abre el proyecto con el **editor de Defold** (v1.13.0, sha1 `f735c12192bf95684e6ae1ae27c400b8170fc6d8`).
2. Resolución: 1280×768 · 60 fps.

Build HTML5 headless con `bob` (requiere OpenJDK 25):

```bash
java -jar bob.jar --platform wasm-web --archive resolve build bundle --bundle-output bundle_out
```

Auditoría de funciones globales (regla #1 de `DEFOLD_LUA_STANDARDS.md`):

```bash
bash audit_globals.sh
```

## 💾 Guardado

El juego guarda la partida en el navegador (`localStorage` en el build HTML5). Los datos se pierden al limpiar los datos de navegación o en modo incógnito; no hay backend.

## ⚖️ Licencia

- **Código:** GPL-3.0 (ver [`LICENSE`](LICENSE)).
- **Assets heredados del juego original:** CC BY-NC-SA 4.0 (ver [`docs/ASSETS_LICENSE.md`](docs/ASSETS_LICENSE.md)).
- Desarrollo asistido por IA: ver [`docs/AI_DISCLOSURE.md`](docs/AI_DISCLOSURE.md).

> *"A Day in the Museum" © 2026 Ángel Sánchez (nosinmipixel) — Code: GPLv3 | Assets: CC BY-NC-SA 4.0 — Creative assistance with DeepSeek and ChatGPT*
