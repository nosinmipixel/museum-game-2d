[![en](https://img.shields.io/badge/lang-en-blue.svg)](README.md)
[![es](https://img.shields.io/badge/lang--es-yellow.svg)](README_ES.md)

# 🏛️ Top Down Museum Game (Defold)

*A Day in the Museum* — 2D version built in **Defold/Lua** of an educational game set in the Museum of Prehistory of Valencia.

![A Day in the Museum](https://github.com/user-attachments/assets/5fc2e42a-2786-4dbd-b62d-15679924773e)

A top-down exploration game where you play as a **museum curator**: walk through the halls, interact with collection objects, talk to visitors (dialogue with quiz questions), eliminate pests (cockroaches and rats) with spray, and manage your resources (health, spray, energy) from the HUD.

> Original version (3D, UPBGE/Blender): [nosinmipixel/museum-game](https://github.com/nosinmipixel/museum-game)

## 🎮 Play online

HTML5 build deployed on GitHub Pages (pending publication):

**https://nosinmipixel.github.io/museum-game-2d/**

## 🎮 How to play

You are the **novice curator** of a museum. Complete the **four tasks** to gain experience, rank up, and become **museum director**:

1. **Cataloguing** — Pick up the archaeological objects that appear in the intake area, store them on the shelf of their period in the storeroom (Paleolithic, Neolithic, Bronze Age, Iberian, and Roman), and finally display them in the exhibition halls.
2. **Restoration** — Some objects need to be restored; our restorer will test your knowledge of preventive conservation.
3. **Public assistance** — Researchers, students, and visitors will ask you archaeology questions; answer correctly to increase your skills.
4. **Pests** — Cockroaches and rats threaten the museum. Use spray to get rid of them and destroy the **nests** with a special insecticide that stops the plague at its root.

![Quiz](https://github.com/user-attachments/assets/5a58238d-938f-45a4-8839-efe14940c544)

**Object cycle:** each piece appears in the intake area → pick it up → restore it if needed → place it on the shelf of the correct period → wait until it is ready to be displayed → **place it in the display case** in the exhibition hall. The full collection is **10 objects** (2 per period).

**Manage your resources:** **health** (recover it with first-aid kits), **spray** (refill it with cans), **energy** (it depletes during the day). Watch the **climate conditions**: there are monitored access points where open doors trigger temperature and humidity spikes — close them. Keep in mind that inadequate climate conditions affect not only the pieces, you will also start feeling unwell.

![Visit the halls](https://github.com/user-attachments/assets/db03362e-8628-4a75-b45b-0b23bdca14c0)

You can also: visit the **exhibition halls** to learn about the pieces, check the **library books** (they help with the questions!), and befriend the museum **cat** (it will help you get rid of the pests!).

Complete the 4 tasks to become **museum director**. If the pests defeat you or you have a very serious accident, you will respawn at the starting point.

## 🕹️ Controls

| Action | Keyboard | Mouse | Mobile / Touch |
|---|---|---|--|
| Move | Arrow keys or WASD | — | Joystick buttons |
| Interact (dialogues, furniture, objects, doors) | — | Left click / tap | Hand icon button |
| Spray | Space | Right click (hold) | Spray icon button |
| Pause | P | — | HUD button |
| Close dialogues / panels | ESC | — | — |
| Reset game state (dev) | R | — | — |

> On mobile, interaction uses a touch sensor around the player that selects the target most aligned with your movement direction (details in `docs/DEV_GOTCHAS.md` #31).

## 📁 Project structure

```
├── game.project                 # Defold project configuration
├── bootstrap.collection         # Root collection
├── intro.collection             # Introduction scene
├── level_01.collection          # Main level (loaded by proxy)
├── main/                        # Shared Lua modules and management scripts
├── features/                    # Player, enemies, NPCs, furniture, props
├── assets/                      # Textures, sounds, texts, tiles
├── gui/                         # Interfaces (HUD, pause, library, dialogs)
├── input/                       # Keyboard/mouse/touch bindings
├── docs/                        # Project documentation
└── audit_globals.sh             # Global function audit (dev)
```

## 📚 Documentation

All project documentation lives in [`docs/`](docs/):

- [`DEV_GOTCHAS.md`](docs/DEV_GOTCHAS.md) — dangerous Defold patterns discovered during development (**read this before adding interaction scripts**).
- [`PROJECT_SUMMARY.md`](docs/PROJECT_SUMMARY.md) — technical summary of the game, systems, and architecture.
- [`DEFOLD_LUA_STANDARDS.md`](docs/DEFOLD_LUA_STANDARDS.md) — canonical guide to Lua/Defold best practices.
- [`INVENTORY_SYSTEM.md`](docs/INVENTORY_SYSTEM.md) — documentation of the inventory/collectibles system.
- [`plans/`](docs/plans/) — active or partial plans (GitHub publishing, touch controls, shooting, GUI migration).
- [`plans/archive/`](docs/plans/archive/) — completed or historical plans (nests, refactoring, scene structure, performance analysis).
- Asset licenses and AI disclosure: `ASSETS_LICENSE*.md`, `AI_DISCLOSURE*.md`.

## 🛠️ Local development

1. Open the project with the **Defold editor** (v1.13.0, sha1 `f735c12192bf95684e6ae1ae27c400b8170fc6d8`).
2. Resolution: 1280×768 · 60 fps.

Headless HTML5 build with `bob` (requires OpenJDK 25):

```bash
java -jar bob.jar --platform wasm-web --archive resolve build bundle --bundle-output bundle_out
```

Global function audit (rule #1 from `DEFOLD_LUA_STANDARDS.md`):

```bash
bash audit_globals.sh
```

## 💾 Saving

The game saves progress in the browser (`localStorage` in the HTML5 build). Data is lost when clearing browsing data or in incognito mode; there is no backend.

## ⚖️ License

- **Code:** GPL-3.0 (see [`LICENSE`](LICENSE)).
- **Assets inherited from the original game:** CC BY-NC-SA 4.0 (see [`docs/ASSETS_LICENSE.md`](docs/ASSETS_LICENSE.md)).
- AI-assisted development: see [`docs/AI_DISCLOSURE.md`](docs/AI_DISCLOSURE.md).

> *"A Day in the Museum" © 2026 Ángel Sánchez (nosinmipixel) — Code: GPLv3 | Assets: CC BY-NC-SA 4.0 — Creative assistance with DeepSeek and ChatGPT*
