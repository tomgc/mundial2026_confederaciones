# mundial2026_confederaciones

Modelo de comparacion de desempeno por confederacion en el Mundial 2026,
tipo Elo/FIFA SUM. Mide el rendimiento de cada confederacion (UEFA,
CONMEBOL, AFC, CAF, CONCACAF, OFC) **relativo a la fuerza esperada** de
sus selecciones, no en terminos absolutos.

## Como correr el pipeline

```r
source("00_run_all.R")
run_all()          # pipeline completo
run_all(from = 3)  # desde el motor en adelante
run_all(only = 4)  # solo el reporte
```

## Estructura

Sigue la estructura canonica de `POLITICA_PROYECTO.md`
(`50_documentacion/activa/`): carpetas numeradas por flujo de ejecucion
(`10_utils` -> `20_insumos` -> `30_procesamiento` -> `40_salidas` ->
`50_documentacion`). Proyecto publico (Rama A): los datos se versionan
en el repo.

## Fuentes de datos

- Fuerza pre-torneo: ranking FIFA (snapshot del 11-jun-2026) mas World
  Football Elo (eloratings.net).
- Resultados del torneo: FBref via `worldfootballR`.
- Confederacion por seleccion: mapeo fijo de 48 equipos.
- Respaldo y validacion cruzada: dataset diario de Kaggle (CC0).

Este repositorio no contiene datos personales ni sensibles.

## Modelo (resumen)

- Nivel 1 (seleccion): `dR = I * G * (W - We)`, con `G = 1 + ln(d)` continuo
  y sin factor sorpresa (la sorpresa ya la mide `W - We`).
- Nivel 2 (confederacion): `R* = R + C`, con `C` actualizado solo en
  partidos entre confederaciones distintas.
- Metrica principal del reporte: rendimiento observado vs esperado y
  transferencia neta de rating en cruces interconfederacion.
