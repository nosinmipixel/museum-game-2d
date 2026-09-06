# ⚡ Performance Notes

> **Engine:** Defold  
> **Date:** August 2026  
> **Target platforms:** Linux Native, HTML5 (Firefox), Mobile (future)

---

## 📊 Baseline Metrics

Tested on Intel i5-6200U (Skylake, HD 520), 32 GB RAM, X11.

| Metric | Linux Native | HTML5 Firefox |
|--------|-------------|---------------|
| FPS | 60 (stable) | 41–59 (variable) |
| Frame time | 16.67 ms | 18.36–22.76 ms |
| Memory | 227.9 MB | ~50.2 MB (JS heap only, not comparable) |
| Peak frame | 33.3 ms | 33.3 ms |
| 1% low | 29 FPS | 29 FPS |

**Conclusion:** Native performs perfectly (locked vsync). HTML5 reaches 70–98% of native performance. The gap is explained by the WASM/WebGL2 translation layer + Intel iGPU driver + X11 composition.

---

## 🔍 Optimization Research

### 1. Frame Skipping (`render.skip`)

**Status:** Not available in Defold.

Defold has no built-in frame skipping mechanism. The render script draws every frame unconditionally.

**Alternative:** A custom render script could skip frames manually:
```lua
self.skip = not self.skip
if self.skip then return end
```
**Verdict:** Not recommended — halves effective FPS and doesn't address the root cause (GPU-bound).

---

### 2. Texture Compression

**Status:** Not applicable for HTML5/WebGL.

| Format | Works in HTML5? | Notes |
|--------|-----------------|-------|
| ETC2/ASTC/PVRTC | ❌ No | Hardware-decompressed on native only |
| RGBA8 (raw) | ✅ Yes | What WebGL always uses |
| Optimized PNG | ✅ Yes | Smaller download, same GPU memory |

**Verdict:** Texture compression (ETC2/ASTC) only helps native builds. For HTML5, optimize PNGs with `pngquant` (lossy, ~50–70% smaller, imperceptible on pixel art):
```bash
pngquant --quality=65-80 --speed 1 input.png -o output.png
```

---

### 3. WASM Compression

**Status:** Already optimized.

- `compress_archive = 1` is active in `game.project`
- Emscripten generates WASM with `-O2` by default (no override from game.project)
- Server-side **Brotli** compression can reduce WASM transfer by 20–30% over gzip

**Verdict:** Already good. Brotli on the server is a low-effort improvement if hosting allows it.

---

### 4. `high_dpi` Setting

**Status:** Currently active (`high_dpi = 1` in `game.project`).

| Value | Behavior | Impact |
|-------|----------|--------|
| `1` | Renders at 2× on HiDPI screens | More GPU work, sharper pixels |
| `0` | Renders at native resolution | 4× fewer pixels on 2× displays |

For this game (pixel art, `nearest` texture filter), `high_dpi = 0` would reduce GPU load significantly with **no visible quality loss** — pixel art already looks correct at 1×.

**Verdict:** Highest-impact single change for HTML5. Worth testing.

---

### 5. HTML5 `heap_size`

**Status:** Default 256 MB.

The game uses ~50 MB JS heap. Reducing to 128 MB would reduce WASM memory allocation and potentially improve GC behavior.

**Verdict:** Safe to reduce if testing confirms no allocation errors.

---

## 🎯 Recommended Optimization Order

| Priority | Change | Expected Impact | Risk |
|----------|--------|-----------------|------|
| 1 | `high_dpi = 0` for HTML5 | High (2–4× fewer pixels) | None for pixel art |
| 2 | `heap_size = 128` | Medium (less WASM memory) | Low |
| 3 | `pngquant` on heavy quiz textures | Medium (smaller downloads) | Low (lossy) |
| 4 | Brotli on server | Low (20–30% smaller WASM) | None |

---

## 📝 Notes

- The 33.3 ms peak frame in both builds is likely Lua GC or initial resource loading. It's a single stutter, not a structural problem.
- HTML5 memory reporting (`~50 MB`) is not comparable to native (`~227 MB`) because browsers only report JS heap, not GPU texture memory or WASM linear memory.
- The game's resolution (1280×768) is well-suited for HTML5 — no need to reduce internal resolution.

## 🔗 Related Documents

- [NPC Raycast Mitigations](PERFORMANCE_NPC_RAYCAST.md) — Detailed analysis of raycast performance bottlenecks and mitigation strategies for NPC patrol in HTML5 builds.
- [NPC Camera Culling](PERFORMANCE_NPC_CULLING.md) — Camera-based culling system to disable off-screen NPC patrol logic (~80% raycast reduction).
