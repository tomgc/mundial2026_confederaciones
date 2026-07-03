# Decisión — OFC: rating inicial 0 y delta desproporcionado (P11)

**Fecha:** 2026-07-03
**Sesión:** 3

## Contexto

OFC tiene un solo equipo (NZL). `escala_0_100()` normaliza `puntos_fifa`
al rango [0,100] entre los 48 equipos; NZL es el mínimo absoluto, por lo
que `fuerza_base = 0` y `rating_inicial = 0`.

Con rating 0, `We` (expectativa) es casi 0 en cualquier cruce, así que
todo resultado no perdedor genera sorpresa (`W - We`) cercana al máximo.
El empate 2-2 vs IRN (`We=0.0014`) aportó +12.5 de los +28.3 totales de
OFC. Como `n_equipos=1`, el promedio de confederación es el delta de NZL
sin diluir.

## Causa raíz

Debilidad estructural del modelo con confederaciones de 1 equipo, no un
bug de código. `IMPORTANCIA_FASE`, `factor_goles()` y `expectativa()`
funcionan como está documentado; el problema es que rating inicial 0 es
un caso límite no acotado.

## Verificación

`historial_partidos.csv` filtrado a NZL (3 partidos, todos vs. equipos
de otras confederaciones): derrotas 0-1 vs EGY y 1-5 vs BEL, empate 2-2
vs IRN. `fuerza_equipos.csv` confirma `fuerza_base=0` para NZL.

## Tipo

Deuda técnica, no urgente (impacto visual, no invalida el modelo).

## Decisión

Sin corrección de código en esta sesión. Queda pendiente para sesión
dedicada, con dos alternativas a evaluar entonces:

- Piso mínimo de `fuerza_base` (constante nombrada, ej. 10).
- Normalizar `escala_0_100()` sobre un rango histórico fijo, no sobre
  el mínimo/máximo de los 48 equipos del torneo actual.

**Recomendación:** piso mínimo de fuerza base (cambio acotado, una
constante) sobre renormalizar la escala completa (afecta a los 48
equipos, mayor superficie de cambio).

## Implicancia

Ninguna acción de código en esta sesión. Pendiente nuevo (P11) para el
traspaso.
