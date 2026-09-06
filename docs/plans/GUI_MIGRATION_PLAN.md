# 🗂️ Plan de migración — GUI con nodo raíz + `gui.get_tree()`

> **Documento de planificación.** Estado: **pause ✅ implementado · library ⏳ aparcado · interactive ⏳ aparcado (Agosto 2026)**.
> Objetivo: eliminar las listas manuales de `gui.set_enabled` en los GUIs que se muestran/ocultan como bloque, de modo que **cualquier nodo nuevo añadido en el editor quede cubierto automáticamente** (sin tocar el script) y el estado de visibilidad viva en un solo punto.
> 🔗 Complementa a `docs/DEV_GOTCHAS.md` → **GOTCHA #32** (modelo del motor verificado) y a `gui/pause.gui_script` (implementación de referencia).

---

## 1. Objetivo

- Patrón: **nodo raíz invisible** (box con el tamaño de la resolución de referencia y `alpha: 0`) que contiene a todos los nodos top-level del GUI.
- Helper único que recorre el árbol y aplica `gui.set_enabled` a cada nodo:

```lua
local function set_tree_enabled(root, enabled)
	if not root then return end
	for _, node in pairs(gui.get_tree(root)) do
		gui.set_enabled(node, enabled)
	end
end
```

- `init()` / mostrar / ocultar llaman a `set_tree_enabled(self.root, bool)` en lugar de listar nodos.
- **Añadir un nodo nuevo = colgarlo del root en el editor. Nada más.**

---

## 2. Hallazgos de la investigación (Agosto 2026 — verificados en `engine/gui/src/gui.cpp`)

> ⚠️ **Corrección importante:** la primera versión de GOTCHA #32 afirmaba que `set_enabled` "no se propaga a los hijos". **Falso para el render.** Modelo real verificado en el código fuente del motor:

| Aspecto | Comportamiento real | Evidencia |
|---|---|---|
| **Render** | Deshabilitar un padre **SÍ oculta a todo su subárbol** (la recolección solo desciende a los hijos dentro del bloque `if (n->m_Node.m_Enabled)`) | `CollectRenderEntries()` en `gui.cpp` |
| **Animaciones** | Se pausan si **cualquier ancestro** está deshabilitado | `IsNodeEnabledRecursive()` |
| **Flag `enabled`** | **Por nodo**: `gui.is_enabled(node)` no mira al padre (solo con `recursive=true` sube por la cadena) | `IsNodeEnabled(scene, node, recursive)` |
| **Picking** | `gui.pick_node()` es **geométrico puro**: no comprueba `enabled` ni `visible` → un nodo oculto sigue siendo pickable | `PickNode()` + confirmación de AGulev (equipo Defold, foro 2026) |
| **`visible`** | Por nodo, **no** se hereda (padre invisible no oculta hijos) | `IsVisible()` comprueba solo `m_IsVisible` del propio nodo |
| **`alpha`** | Se hereda SOLO con `inherit_alpha` (multiplicación de opacidad) | cálculo de opacidad en el render |
| **Adjust mode** | Un nodo hijo ajusta contra la escala ajustada del **padre** → el root debe tener el tamaño de la referencia, **nunca 0×0** | `m_LocalAdjustScale` del padre en el cálculo de adjust |

**Consecuencia práctica:** recorrer el árbol con `gui.get_tree()` no es "por si acaso" — garantiza el estado completo (no render, no animación, no picking) y un **reset limpio de flags** al reabrir, cosa que un simple toggle del root no hace (los flags por nodo quedarían en `true` y el picking geométrico seguiría devolviendo nodos ocultos).

---

## 3. Estado de cada GUI

| GUI | Nodos | Patrón actual | Estado migración | Notas |
|---|---|---|---|---|
| **pause** | 23 | Listas manuales ×3 (init/show/hide) | ✅ **Implementada** | Referencia del patrón. `pause_root` 1280×768, alpha 0; `inherit_alpha` quitado; desplegable de idioma re-ocultado tras habilitar el árbol |
| **library** | 9 | Listas de 7 nodos duplicadas (show/hide) | ⏳ **Aparcada** | Riesgo bajo. Caso especial: `box_pages_flip` |
| **interactive** | 28 | Listas de ~15 nodos duplicadas (quiz show/hide) + globos aparte | ⏳ **Aparcada** | Dos grupos de visibilidad independientes; beneficio menor (botones dinámicos) |

**No aplica** (no migrar): `hud` (toggles semánticos por estado), `intro` (lógica condicional por botón), `exhibition` (ya usa contenedor + `box_image` fuera a propósito), `web_controls` y `victory` (ya centralizados en una lista única → ganancia marginal).

---

## 4. Cambios por archivo

### 4.1 `gui/pause.gui` + `gui/pause.gui_script` ✅ IMPLEMENTADA

- `pause_root` (box 1280×768, `alpha: 0`, primero en la lista de nodos).
- 23 nodos top-level con `parent: "pause_root"`; `inherit_alpha` eliminado de todos.
- Helper `set_tree_enabled()` + uso en `init`/`show_pause`/`hide_pause`.
- `show_pause` vuelve a ocultar el desplegable de idioma (arranca cerrado).

### 4.2 `gui/library.gui` + `gui/library.gui_script` ⏳ APARCADA

**Pasos (cuando se retome):**
1. Añadir `library_root` (box 1280×768, `alpha: 0`, primero) y colgar los **8 nodos de bloque** (`box_background`, `box_book`, `text_title`, `text_page_left`, `text_page_right`, `box_backward`, `box_forward`, `box_close`).
2. Quitar `inherit_alpha` de los 8 (el root tiene alpha 0).
3. Helper `set_tree_enabled()` + reemplazar las listas en `set_visible_all()`.
4. Tras habilitar el árbol al **abrir**, deshabilitar `box_pages_flip` (overlay solo durante la animación de paso de página).

**Riesgos:**
- 🔴 **`box_pages_flip`** es el único punto delicado: si queda dentro del árbol, al abrir el libro se habilitaría con todo (hay que re-ocultarlo explícitamente); si queda fuera, recordar que NO se cubre solo. Decidir y documentar en el código.
- 🟡 **Animación de apertura del libro**: los textos se ocultan al abrir y se re-muestran en el callback del flipbook — no tocar ese flujo (es independiente del árbol; funciona porque el root está habilitado).
- 🟡 **Hover de los botones de navegación** (flipbook + escala táctil): no depende de `set_enabled`, pero verificar que el reset de hover al cerrar sigue ocurriendo (está en `set_visible_all` y se conserva).

### 4.3 `gui/interactive.gui` + `gui/interactive.gui_script` ⏳ APARCADA

**Pasos (cuando se retome):**
1. Añadir `interactive_quiz_root` (box 1280×768, `alpha: 0`) y colgar **solo el panel de quiz** (10 nodos top-level: `box_background_quiz`, `box_icon_quiz`, `pie_timer_quiz_red/_yellow/_quiz`, `button_1/2/3`, `image_quiz`, `question`). Los hijos de botones ya cuelgan de sus botones (cubiertos por el árbol).
2. **Los contenedores de globos se quedan FUERA** (`balloon_npc_container`/`balloon_player_container` + sus hijos): tienen ciclo de vida independiente (por hablante) y ya funcionan correctamente con la cascada del render.
3. Quitar `inherit_alpha` de los nodos del quiz que lo tengan (verificar en el `.gui`).
4. Helper + reemplazar las listas de `show_quiz_interface`/`hide_quiz_interface`. **No tocar** `hide_dialog_bubbles` ni la lógica de hablantes.
5. Tras habilitar el árbol en `show_quiz_interface`, re-ocultar `container_player`/`container_npc` (igual que el dropdown de pause) para que los globos no aparezcan al abrir un quiz.

**Riesgos:**
- 🔴 **Dos grupos de visibilidad en un solo GUI**: si algún día un globo debe verse Mientras el quiz está abierto, el árbol lo ocultaría al abrir el quiz. Diseño alternativo (más invasivo): un root por grupo. Decisión a revisar al retomar.
- 🔴 **`visible: false` en los contenedores de globos** (GOTCHA #19): activarlos por mensaje funciona, pero NO tocar su declaración en el `.gui` ni su activación desde `init()`.
- 🟡 **Beneficio limitado**: los botones del quiz se construyen dinámicamente en código (`self.button_nodes`) → añadir botones nuevos ya exige tocar el script. La ganancia real es solo para nodos de panel nuevos (p. ej. más pie timers o imágenes).
- 🟡 **`capture_quiz_layout`** lee tamaños/posiciones de nodos del quiz en `init` — verificar que sigue ejecutándose antes/después del toggle del árbol sin cambios.

---

## 5. Riesgos y gotchas comunes a cualquier migración

- 🔴 **El root nunca debe tener tamaño 0×0**: el adjust mode de los hijos se calcula contra la escala ajustada del padre → usar el tamaño de la resolución de referencia (1280×768).
- 🔴 **Root con `alpha: 0` obliga a quitar `inherit_alpha` de los hijos**: si no, heredan alpha 0 y quedan invisibles.
- 🟡 **El picking es geométrico**: `gui.pick_node()` devuelve nodos ocultos. Los handlers de input deben seguir gateándose por el estado del script (`self.is_paused`, `self.is_visible`, `self.is_panel_open`...), nunca solo por `set_enabled`.
- 🟡 **Sub-estados que no son "todo el bloque"** (dropdown, overlay, globos, pie timers por fase): el árbol los habilita todos → hay que re-ocultarlos explícitamente tras habilitar (patrón del dropdown de pause).
- 🟡 **Edición del `.gui` a mano**: texto protoform válido sin comentarios `--` (GOTCHA #21) y con `parent:` correcto; abrir en el editor para verificar tras editar.

---

## 6. Decisiones pendientes

- [ ] **library**: ¿`box_pages_flip` dentro o fuera del árbol? (recomendado: dentro + re-ocultado explícito al abrir — mantiene el árbol completo).
- [ ] **interactive**: ¿root único para el panel de quiz dejando los globos fuera (recomendado, replica el código actual) o dos roots?
- [ ] Confirmar si algún flujo de diálogo puede mostrar un **globo mientras el quiz está abierto** (condiciona el diseño de interactive).

---

## 7. Referencias

- `docs/DEV_GOTCHAS.md` → **GOTCHA #32** (modelo del motor con tabla de evidencia) y **GOTCHA #19** (`visible: false` + activación).
- `gui/pause.gui` + `gui/pause.gui_script` → implementación de referencia del patrón.
- Motor: `engine/gui/src/gui.cpp` (Defold, rama dev) — `CollectRenderEntries`, `IsNodeEnabledRecursive`, `PickNode`, `IsVisible`.
- Foro oficial: hilos de Ene 2026 (britzl/Halfstar: enabled vs visible) y Feb-Mar 2026 (AGulev: pick_node geométrico, enabled afecta updates+visibilidad).
