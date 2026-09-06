# Bug report — Defold (github.com/defold/defold)

> **✅ SUBMITTED:** https://github.com/defold/defold/issues/13125 (Sept. 2026)
> This file is the original draft, kept as stable evidence and for cross-referencing.
> **How it was submitted:** via https://github.com/defold/defold/issues/new?template=bug_report.md,
> pasting the sections below as is.

---

**Title:** `[HTML5] Gameplay systems break with release engine variant (wasm-web); identical project works with debug variant`

---

**Describe the bug (REQUIRED)**

When bundling an HTML5 build with `bob` using the default engine variant (`release`), the game starts and renders, but core gameplay systems misbehave: NPCs spawn at wrong positions, most interactions (objects, furniture, NPCs) are unresponsive or behave unexpectedly, and localized texts fail to display correctly. Building the **exact same project** with `--variant debug` produces a fully working game. There are no script errors or engine errors in the browser console — the failure is completely silent.

We isolated the cause with cross-bundle A/B tests (engine files from one build combined with the archive of the other; see matrix below). The **content of the archive is not the cause**: swapping archives between builds changes nothing. The **engine variant is the cause**: every bundle whose wasm came from a `release` build is broken, every bundle whose wasm came from a `debug` build works.

Additionally, the editor's build/launch output for this project is always the debug variant (its wasm is byte-identical, md5-verified, to `bob --variant debug` output). This means projects developed exclusively in the editor may contain logic that breaks under the release engine without the developer ever noticing — the game played correctly in every editor test while the release engine was silently broken for it. We also bundled from the editor UI with the **Release** option enabled: the resulting bundle shows the same broken behavior, so the issue is independent of the build tool and limited to the release engine variant.

**To Reproduce (REQUIRED)**

The full project is open source (GPL-3.0), so this can be reproduced directly:

1. Clone https://github.com/nosinmipixel/museum-game-2d (Defold 1.13.1, no native extensions, no library dependencies).
2. Build twice with bob 1.13.1 (sha `574678c7d44be490d874fbed2d0ae6211feec4d9`, OpenJDK 25):
   ```bash
   # BROKEN build (default = release variant):
   java --enable-native-access=ALL-UNNAMED -jar bob.jar \
        --platform wasm-web --archive resolve build bundle --bundle-output out_release

   # WORKING build (explicit debug variant):
   java --enable-native-access=ALL-UNNAMED -jar bob.jar \
        --platform wasm-web --variant debug --archive resolve build bundle --bundle-output out_debug
   ```
3. Serve each bundle with any static file server (e.g. `python3 -m http.server`) and open in a browser. Use a fresh profile/incognito window to rule out localStorage saves.
4. In the main level (`level_01`), play for ~1 minute:
   - **release build:** NPCs are positioned incorrectly at spawn, interactions with objects/furniture/NPCs don't respond or behave unexpectedly, dialog/text content is broken.
   - **debug build:** all of the above works.

Engine wasm fingerprints on our machine (1.13.1):

| | debug | release |
|---|---|---|
| `TopDownMuseumGame.wasm` size | 2,868,310 bytes (md5 `bb6e5b65b784b39b923e8df70904e5f9`) | 2,385,802 bytes |
| `TopDownMuseumGame_wasm.js` size | 288,210 bytes | 274,995 bytes |

**Expected behavior (REQUIRED)**

The release variant should run the game correctly — it is the intended variant for production bundles. At minimum, engine behavior should not differ functionally between variants for project code; gameplay logic must not silently depend on the debug engine.

**Defold version (REQUIRED):**

- Version: **1.13.1** stable (sha1 `574678c7d44be490d874fbed2d0ae6211feec4d9`). Also reproduced with **1.13.0** stable (sha1 `f735c12192bf95684e6ae1ae27c400b8170fc6d8`) — the first occurrence was a CI build with 1.13.0.

**Platforms (REQUIRED):**

- Platforms: **HTML5** (`wasm-web`)
- OS: Linux (CachyOS / Arch-based, x86_64) for local builds; GitHub Actions `ubuntu-latest` (Temurin JDK 25) for CI builds — the CI-built release bundle exhibits the same broken behavior when served from GitHub Pages.
- Browsers: **Brave 1.94.119** (Chromium) and **Firefox 155.0** — the release-variant behavior reproduces in both; the debug variant works correctly in both.
- Device: desktop

**Minimal repro case project (OPTIONAL):**

We have not distilled a minimal project yet. The complete game is public and builds in seconds with no extensions or dependencies: https://github.com/nosinmipixel/museum-game-2d — happy to reduce it further on request. Relevant project characteristics (in case any of them interacts with the variant difference):

- `[sound] use_thread = 1`, `[graphics] default_texture_*_filter = nearest`
- `custom_resources = /assets` (Lua text files loaded at runtime via `sys.load_resource` + `loadstring`)
- Custom HTML5 template with `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` meta tags
- Dynamic collection loading via collection proxies

**Logs (OPTIONAL):**

None useful — that is what makes this hard to catch. The broken build shows only benign `WebGL: INVALID_ENUM: getParameter` console warnings and no Lua or engine errors. The systems fail silently.

**Workaround (OPTIONAL):**

Bundle with the debug variant:

```bash
java -jar bob.jar --platform wasm-web --variant debug --archive resolve build bundle --bundle-output bundle_out
```

This produces a wasm byte-identical to the editor's output and works perfectly. Costs: the debug wasm is ~470 KB larger and presumably lacks release optimizations, so it is not a desirable long-term substitute for production builds.

**Additional context (OPTIONAL):**

1. **A/B isolation matrix** (all combinations tested on localhost, fresh incognito profile):

   | Engine wasm | Archive | Result |
   |---|---|---|
   | debug (editor launch build) | editor build | ✅ works |
   | release (bob default) | bob build | ❌ broken |
   | release (bob default) | editor build | ❌ broken |
   | debug (editor launch build) | bob build | ✅ works |

   The bundle data (archive) was also cross-checked: compiled project settings (`game.projectc`) are byte-identical between editor and bob builds, and the archive file lists match (total size differs by ~65 KB out of ~37 MB). The archive is exonerated.

2. **Threading mode ruled out.** The release dmloader gates the pthread engine on `window.isSecureContext && window.crossOriginIsolated && SharedArrayBuffer`, and our custom template enables COOP/COEP — so release bundles run the multithreaded engine on isolated origins. The editor's own dmloader instead hardcodes `Module["isWASMPthreadSupported"] = false` (editor launch bundles never use the pthread engine; note that `bob --variant debug` bundles *do* include the pthread files, gated the same way as release). Two observations exonerate threading as the cause: (a) removing the COOP/COEP meta tags from the release bundle's `index.html` (forcing single-threaded mode) **still produced the broken behavior**; (b) the **multithreaded debug engine runs the game correctly** — our production site serves a `bob --variant debug` bundle with COOP/COEP enabled (isolated context → pthread engine active) and is verified working in-browser.

3. **Unconfirmed hypothesis — WebGPU.** Both wasm builds contain WebGPU-related strings (`ADAPTER_FAMILY_WEBGPU`, etc.). A plausible (unverified) hypothesis is that the release engine prefers the WebGPU backend while the debug engine uses WebGL, and some engine system misbehaves under WebGPU in this game. We could not find a user-facing engine flag to force WebGL on the release build to test this. `--verify-graphics-calls=false` (present in the editor's launch arguments) is already set in both bundles' dmloader.

4. **Editor release bundle also broken (tested).** Bundling from the Defold editor UI (Project → Bundle → HTML5 Application, Release option enabled) and running the result reproduces the same broken behavior as the bob CLI release build. This rules out bob-CLI-specific packaging entirely and confirms the fault lives in the release engine variant itself, independent of the build tool.

5. Engine version skew is excluded: editor 1.13.1 and bob 1.13.1 use the same stable sha, and the failure also occurred with matched 1.13.0 builds.
