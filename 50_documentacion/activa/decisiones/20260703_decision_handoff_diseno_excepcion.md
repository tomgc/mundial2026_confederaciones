# Decisión — Excepción declarada: handoff de Claude Design (P5/P6)

**Fecha:** 2026-07-03
**Sesión:** 3
**Pendientes que cierra:** P5, P6 (traspaso_cierre_v01.md, sección 11)

## Contexto

`50_documentacion/activa/decisiones/` contiene el handoff congelado de
Claude Design: `Dashboard Mundial 2026 (standalone).html`,
`Dashboard Mundial 2026.dc.html`, `support.js`, `README.md`, y
`data/` (con `equipos_mundial2026.csv`, `ranking_fifa_20260611.csv`).

Dos desviaciones detectadas contra la política:

- **P5:** `data/` duplica CSV ya presentes en `20_insumos/`.
- **P6:** `support.js` es código JavaScript versionado, pese a la
  convención "R único lenguaje para análisis de datos" (`userPreferences`).

## Decisión

Ambos se declaran **excepción permanente**, sin modificar el handoff.
No se borra `data/`, no se elimina `support.js`, no se reorganiza la
carpeta.

## Alternativas consideradas

- Borrar `data/` duplicado y referenciar `20_insumos/` directamente:
  descartada — el handoff es un artefacto entregado por Claude Design,
  externo al pipeline; alterarlo rompe su integridad como registro de
  lo recibido en esa entrega.
- Mover `support.js` fuera del repo o a `_archivo/`: descartada — el
  archivo es parte funcional del HTML standalone del handoff (no se
  ejecuta como parte del pipeline R, pero sí es necesario si el
  handoff se abre de forma independiente).

## Justificación

Tratamiento equivalente al principio de `andamios/` (política, sección
1.3.7): "sus rutas internas no se reescriben jamás". El handoff de
Claude Design, aunque vive en `decisiones/` y no en `andamios/`, cumple
la misma función de registro histórico de una entrega externa — se
documenta la desviación, no se corrige en silencio ni se fuerza a
encajar en la convención "R único lenguaje", que aplica al pipeline de
datos propio, no a artefactos de diseño recibidos de terceros.

## Tensión resuelta

Consistencia de convención (R único lenguaje, sin duplicación de datos)
vs. integridad del registro histórico de un handoff externo. Se
priorizó integridad del registro: el handoff documenta una entrega real
en un momento dado; reescribirlo para "limpiarlo" falsificaría ese
registro, análogo a por qué `andamios/` nunca se reescribe.

## Implicancia

Ninguna acción de código. `data/` y `support.js` permanecen tal como
fueron entregados. Riesgo aceptado y ya documentado en v01: divergencia
silenciosa si `equipos_mundial2026.csv` cambia en `20_insumos/` sin
actualizar la copia del handoff — bajo impacto porque el handoff no se
consume por el pipeline en ejecución, solo como referencia histórica.
