-- main/food_spawn_state.lua
-- ═══════════════════════════════════════════════════════
-- 🔄 ESTADO COMPARTIDO: Contenedor ↔ Latas de Comida
-- ═══════════════════════════════════════════════════════
--
--   Propósito: Hacer de puente entre food_spawn_container
--   y las food_cat_cans creadas via factory.create().
--
--   Mecanismo idéntico a spray_spawn_state.lua:
--     1. El contenedor escribe pending_spawn ANTES de factory.create()
--     2. factory.create() es SÍNCRONO: el init() de la lata se ejecuta
--        inmediatamente, antes de que el contenedor continúe
--     3. La lata lee y limpia pending_spawn en su init()
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-15
-- ═══════════════════════════════════════════════════════

local M = {}

-- El contenedor escribe { index = N, position = v3 } aquí antes
-- de cada factory.create(). La lata lo lee en init() y lo limpia.
M.pending_spawn = nil

-- URL del contenedor food_spawn_container para que las latas
-- puedan notificar al recogerse.
M.container_url = nil

return M
