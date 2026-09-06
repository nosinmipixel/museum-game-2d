# 📋 Planes del proyecto

Convención de carpetas para los documentos de planificación (Agosto 2026):

- **`docs/plans/`** — planes **activos, pendientes o parciales** (con fases en curso o aparcadas). Siguen siendo referencia de trabajo.
- **`docs/plans/archive/`** — planes **ejecutados o históricos** (implementados y verificados, o superados por la realidad del código). Se conservan como registro de decisiones; el estado actual de cada sistema vive en `docs/PROJECT_SUMMARY.md` y `docs/DEV_GOTCHAS.md`.

Cada plan declara su estado en la cabecera con un badge:

| Badge | Significado |
|---|---|
| ⏳ Pendiente | No se ha implementado nada todavía |
| 📋 Referencia | Documento de análisis para decisiones futuras |
| 🟡 Parcial | Implementado en parte; hay fases en curso o aparcadas |
| ✅ Ejecutado | Implementado y verificado |
| 📊 Histórico | Análisis/registro superado por la documentación actual |

## Índice

### Activos / parciales (`plans/`)

| Plan | Estado |
|---|---|
| `GITHUB_PUBLISH_PLAN.md` | ⏳ Pendiente — publicación en GitHub (repo, CI, Pages) |
| `GUI_MIGRATION_PLAN.md` | 🟡 Parcial — pause ✅ · library/interactive aparcados |
| `PROJECT_REORGANIZATION_PLAN.md` | ⏳ Pendiente — reorganización a la estructura propuesta (entities/, assets/sprites, texts/, world/) |

### Ejecutados / históricos (`archive/`)

| Plan | Estado |
|---|---|
| `NEST_SYSTEM_PLAN.md` | ✅ Ejecutado — sistema de nidos (ver GOTCHA #31) |
| `MOBILE_CONTROLS_PLAN.md` | ✅ Ejecutado — controles táctiles (fullscreen automático descartado por decisión) |
| `INPUT_CONTROL_PLAN.md` | ✅ Ejecutado — decisión de esquema de disparo (Opción 5) ejecutada; gamepad queda opcional |
| `REFACTORING_PLAN.md` | ✅ Ejecutado — 10 hallazgos aplicados y verificados |
| `NEW_SCENE_STRUCTURE.md` | ✅ Ejecutado — estructura de escenas actual |
| `PERFORMANCE_ANALYSIS.md` | 📊 Histórico — análisis de rendimiento (Junio 2026) |
