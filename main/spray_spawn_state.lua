-- main/spray_spawn_state.lua
-- ═══════════════════════════════════════════════════════
-- 🔄 ESTADO COMPARTIDO: Contenedor ↔ Spray Cans
-- ═══════════════════════════════════════════════════════
--
--   Propósito: Hacer de puente entre spray_spawn_container
--   y los spray_cans creados via factory.create().
--
--   Por qué existe:
--     En algunas versiones de Defold, la tabla de properties
--     pasada a factory.create() no se recibe correctamente
--     en el init(self, properties) del objeto creado.
--
--   Cómo funciona:
--     1. El contenedor escribe pending_spawn ANTES de llamar
--        a factory.create()
--     2. factory.create() es SÍNCRONO: el init() del spray_can
--        se ejecuta inmediatamente, antes de que el contenedor
--        continúe su bucle
--     3. El spray_can lee y limpia pending_spawn en su init()
--
--   Esto garantiza que no hay condiciones de carrera porque
--   factory.create() bloquea hasta que el objeto está listo.
--
-- Licencia: GPL-3.0-only (Ver LICENSE en la raíz)
-- Versión de Defold: 1.13
-- Última actualización: 2026-08-15
-- ═══════════════════════════════════════════════════════

local M = {}

-- El contenedor escribe { index = N, position = v3, is_insecticide = bool } aquí
-- antes de cada factory.create(). El spray_can lo lee en init() y
-- lo limpia inmediatamente.
-- 🪺 is_insecticide (Fase 2, docs/plans/archive/NEST_SYSTEM_PLAN.md): true → este bote es de
--    insecticida especial (otorga carga de nest_insecticide, sprite distinto)
--    en vez de spray normal. nil/false → spray (comportamiento original).
M.pending_spawn = nil

-- URL del contenedor spray_spawn_container para que los spray_cans
-- puedan notificar al recogerse. Se asigna en init() del contenedor.
M.container_url = nil

return M
