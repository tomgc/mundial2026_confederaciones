# traspaso_cierre_v02.md

## 1. Identificación

- **Proyecto:** mundial2026_confederaciones
- **Versión:** v02
- **Fecha:** 2026-07-02
- **Sesión 2**, foco: implementación de `39_reporte.R` (P1 del traspaso v01), conectando el sitio publicado a datos reales del pipeline.
- **Entorno:** verificación de sintaxis/lógica en contenedor Claude (sin R disponible); ejecución real en Positron (Mac, R local del usuario).
- **Archivos principales modificados/creados:** `30_procesamiento/39_reporte.R` (de stub a completo), `40_salidas/datos_interfaz.json` (nuevo).

## 2. Resumen ejecutivo

Se implementó `39_reporte.R`, cerrando el único bloqueante identificado en el traspaso v01 (P1). El script hace join de tres insumos crudos (`equipos_mundial2026.csv`, `ranking_fifa_20260611.csv`, `elo_20260702.csv`) con tres salidas del motor (`rating_equipos.csv`, `rating_confederaciones.csv`, `historial_partidos.csv`) para producir `datos_interfaz.json` cumpliendo exactamente el shape que `index.html` espera. El proceso de diseño requirió tres rondas de solicitud de insumos (el contrato JSON completo vive en `index.html`, no en la knowledge base ni en el traspaso v01) antes de poder escribir el código, evitando invención de shape o de datos. Tras tres iteraciones de verificación en R real (recuento de NAs post-join, recuento de `historial`, verificación visual del flag en navegador), el sitio confirmó "Datos reales del pipeline". Commit `8eead90` pusheado. Objetivo central del proyecto (datos reales visibles en el sitio) cumplido.

## 3. Estado al cierre

**Funciona (última verificación: usuario confirmó "flag correcto, datos reales" en navegador tras servir `index.html` por HTTP):**
- `39_reporte.R` corre sin error sobre `run_all()` ya ejecutado previamente (pasos 1-3 de sesión 1, no re-verificados en esta sesión por no haber cambiado).
- `datos_interfaz.json` generado: 48 equipos, 6 confederaciones, 164 entradas de historial total (cuadra con `historial_partidos.csv`).
- 0 valores `null` en `pos_fifa`, `puntos_fifa`, `elo` (verificado explícitamente, campo por campo, sobre los 48 equipos).
- Sitio publicado localmente (`python3 -m http.server`) muestra flag "Datos reales del pipeline" en vez de "Datos de ejemplo (MOCK)".
- Commit `8eead90` pusheado a `main`.

**No funciona / pendiente:**
- El commit se hizo con solo dos archivos (`39_reporte.R`, `datos_interfaz.json`) sobre un staging que mostraba deuda de higiene de Git no resuelta: ver Errores del asistente (sección 15) y P7 (nuevo pendiente).
- P2 (auditoría de datos, protocolo 4.5) no se abordó esta sesión: se decidió cerrar para preservar contexto fresco en sesión 3, dado que P1 era el único foco crítico y la sesión ya llevaba varias rondas de intercambio.
- Verificación en sitio **desplegado en GitHub Pages** (no solo local) queda pendiente: la sesión validó con servidor HTTP local, no se confirmó explícitamente que el Pages remoto ya sirva el JSON real (el commit se pusheó, pero no se re-visitó `https://tomgc.github.io/mundial2026_confederaciones/` tras el push).

**Delta respecto a v01:** P1 (bloqueante) resuelto y verificado. Pipeline completo (pasos 1-5) ahora produce datos reales de punta a punta.

## 4. Registro detallado de cambios

**Cambio 1 — Diseño del contrato de datos vía extracción directa de `index.html`.**
Archivo: ninguno modificado (fase de análisis).
Categoría: diseño de pipeline.
Qué: el contrato JSON exacto (`meta`, `confederaciones[]`, `equipos[].historial[]`, con todos los nombres de campo) se extrajo leyendo la función `generarMock()` y el bloque `cargar()` de `index.html` líneas 403-574, en vez de asumirlo desde el traspaso v01 (que solo mencionaba el shape a alto nivel).
Por qué: el traspaso v01 no incluía el shape exacto; escribir el reporte sin verlo habría arriesgado el contrato intocable (🔒, instrucción del traspaso v01 sección 12).
Verificación: comparación campo por campo entre el objeto `salida` del mock (JS) y la estructura del `39_reporte.R` (R) antes de escribir código.

**Cambio 2 — Identificación de insumos faltantes mediante verificación cruzada de columnas.**
Archivo: ninguno modificado (fase de análisis).
Categoría: diagnóstico de datos.
Qué: se detectó que `pos_fifa`, `puntos_fifa`, `elo`, `nombre` no existen en `rating_equipos.csv` (única salida de equipos disponible inicialmente); se rastreó cuál insumo crudo los contiene (`ranking_fifa_20260611.csv`, `elo_20260702.csv`, `equipos_mundial2026.csv`) antes de escribir el join.
Por qué: escribir el join sin confirmar el origen real de cada columna habría arriesgado inventar valores o fallar en silencio.
Verificación: `head()` de cada CSV solicitado, columnas confirmadas antes de codificar.

**Cambio 3 — Implementación de `39_reporte.R` completo.**
Archivo: `30_procesamiento/39_reporte.R` (reemplaza stub).
Categoría: pipeline de datos (paso 5, cierre del flujo).
Qué: lectura de 6 CSV, joins de equipos y de historial (rival_nombre/rival_confederacion resueltos por segundo join contra el maestro), transformación al shape del contrato, validaciones (`stopifnot` en conteos 48/6, NA en `nombre` y `rival_nombre`), escritura atómica (patrón `.tmp` + `file.rename`).
Decisión de mapeo no trivial: `sede` no tiene insumo real en el pipeline; se fijó constante `SEDE_DEFAULT <- "neutral"` (igual que el mock, que también la fija fija). `partido` (índice de historial) se recalculó como secuencial por equipo (`row_number(), .by=codigo`) en vez de usar `id_partido` crudo, porque `id_partido` se repite entre las dos filas de un mismo partido (una por cada equipo participante) y el contrato espera un índice de secuencia dentro del historial de cada equipo, tal como lo genera el mock.
Por qué: cumplir el contrato exacto sin modificar `index.html` (instrucción 🔒 del traspaso v01).
Verificación: 4 rondas en R real — (a) recuento de NA en `pos_fifa`/`puntos_fifa`/`elo` antes del `stopifnot` interno (dio 0/0/0); (b) ejecución completa sin error, mensaje de resumen confirmado (48 equipos, 6 confederaciones); (c) recuento de `null` en los mismos tres campos leyendo el JSON ya escrito (0/0/0) y conteo de `historial` total (164, cuadra con filas de `historial_partidos.csv`); (d) verificación visual en navegador (flag "Datos reales del pipeline").

**Cambio 4 — Iteración de la función `39_reporte.R` en dos rondas antes de la versión final.**
Archivo: `30_procesamiento/39_reporte.R`.
Categoría: bug de código (propio, corregido dentro de la sesión, no cuenta para el backlog per nota metodológica).
Qué: (a) faltaba `library(purrr)`/dependencia declarada, agregada a auto-instalación; (b) primera versión de `partido` usaba `id_partido` crudo en vez de índice secuencial por equipo, corregido tras revisar manualmente el CSV real y notar la duplicación de `id_partido` entre las dos perspectivas de cada partido; (c) simplificación del ensamblaje de `historial` (se eliminó un `rowwise()` innecesario, reemplazado por `split()` + `lapply()` directo).
Estado: las tres correcciones ocurrieron antes de entregar el archivo al usuario por primera vez; no califican como "error del asistente" bajo la nota metodológica de la sección 2.2.5 de SETTINGS (autocorrección silenciosa antes de la primera entrega). Se documentan aquí por transparencia del cambio (C.10), no en la sección 15.

## 5. Backlog acumulativo

**Nota:** este es el segundo cierre. Según protocolo (POLITICA §10, SETTINGS §2.2.5), a partir de este cierre el backlog se extrae a `50_documentacion/activa/backlog_acumulativo.md` como archivo independiente. Se entrega en la sección siguiente el contenido completo para ese archivo (copiado íntegro desde v01 + entradas nuevas), y este traspaso lo referencia.

Ver archivo adjunto: `backlog_acumulativo.md` (entregado junto a este traspaso).

## 6. Bugs de la sesión

Ninguno reportado por el usuario ni detectado post-entrega en esta sesión. Las tres correcciones del Cambio 4 fueron autocorrección previa a la primera entrega (no califican como bug de sesión bajo la nota metodológica del backlog).

## 7. Aprendizajes y restricciones descubiertas

- **El contrato de datos completo de un frontend puede no estar en el traspaso; verificar la fuente primaria (el código) antes de asumir el shape desde una descripción de alto nivel.** Restricción aplicable a cualquier tarea de integración backend-frontend: un traspaso que resume "el contrato tiene estos 3 bloques" no sustituye leer el archivo real cuando hay campos anidados o transformaciones no obvias (como `sede` sin insumo, o `partido` como índice recalculado, no un ID crudo).
- **`id_partido` en `historial_partidos.csv` no es único por fila: se repite una vez por cada equipo participante del partido.** Restricción de diseño del propio pipeline (dataset en formato "una fila por equipo por partido", no "una fila por partido"). Cualquier futura reutilización de `historial_partidos.csv` (por ejemplo P2, la auditoría) debe tener esto presente: `id_partido` sirve para identificar el partido físico, no como índice secuencial de historial por equipo.
- **`generarMock()` en `index.html` es la especificación ejecutable más confiable del contrato de datos**, más precisa que cualquier resumen textual previo (traspaso o prompt de interfaz). Para cualquier cambio futuro al contrato, releer ese bloque de código directamente.

## 8. Decisiones de diseño

**Decisión 1 — `sede` fija como `"neutral"` para todo partido.**
Alternativas consideradas: omitir el campo (rompería el contrato, que sí lo declara); buscar un insumo real de sede.
Justificación: ningún insumo del pipeline actual expone sede real; el propio mock de `index.html` también la fija a `"neutral"` como placeholder, así que no hay regresión de fidelidad respecto al comportamiento ya aceptado.
Tensión resuelta: completitud del contrato vs. inventar un dato inexistente. Se priorizó completitud con un valor constante documentado y explícito, no inferido.
Implicancia: si en el futuro se consigue un insumo real de sede, es un cambio acotado a una función de mapeo, sin tocar el shape del contrato.

**Decisión 2 — `partido` (índice de historial) recalculado, no tomado de `id_partido`.**
Alternativas consideradas: usar `id_partido` directamente (habría duplicado valores entre partidos distintos del mismo equipo si no se distinguía per-equipo, y no habría sido secuencial 1,2,3...).
Justificación: el contrato (según `generarMock()`) espera un índice secuencial por equipo (`x.entry.partido = x.t.historial.length+1`), no un ID de partido global.
Tensión resuelta: fidelidad al dato crudo vs. fidelidad al contrato. Se priorizó el contrato porque es intocable (🔒) y el índice secuencial es una transformación legítima, no una pérdida de información (el partido físico sigue identificable por fecha + rival).
Implicancia: ninguna, coincide exactamente con el comportamiento del mock que reemplaza.

## 9. Constantes y parámetros vigentes

| Constante | Valor | Archivo | Nota |
|---|---|---|---|
| `IMPORTANCIA_FASE` | grupos=25, dieciseisavos=35, octavos=40, cuartos=50, semifinal=60, tercer_lugar=45, final=70 | `33_motor_elo.R` | Sin cambios respecto a v01 |
| `ESCALA_RATING` | 20 | `33_motor_elo.R` | Sin cambios |
| `BASE_LOGISTICA` | 400 | `33_motor_elo.R` | Sin cambios |
| `PESO_TRANSFERENCIA_CONF` | 0.15 | `33_motor_elo.R` | Sin cambios |
| `FUENTE_FUERZA` | "fifa" | `31_ingesta_fuerza.R` | Sin cambios; P4 sigue pendiente de decisión |
| `PESO_COMPUESTO` | fifa=0.6, elo=0.4 | `31_ingesta_fuerza.R` | Sin cambios, no usado (FUENTE_FUERZA="fifa") |
| `N_EQUIPOS` | 48 | `31_ingesta_fuerza.R`, `32_ingesta_resultados.R` | Sin cambios |
| `SEDE_DEFAULT` | "neutral" | `39_reporte.R` | **Nueva.** Placeholder, sin insumo real de sede |
| `FUENTE_FUERZA_ACTUAL` | "fifa" | `39_reporte.R` | **Nueva.** Debe mantenerse sincronizada manualmente con `FUENTE_FUERZA` de `31_ingesta_fuerza.R`; riesgo de desincronización si P4 se activa sin actualizar ambas — ver P8 |

## 10. Arquitectura de archivos

Sin cambios estructurales respecto a v01 (no se ejecutó el escáner en esta sesión; el último snapshot referenciable es `20260702_214732_estructura.*`, generado al cierre de sesión 1, mostrado en el `estructura_actual.md` adjunto a la apertura de esta sesión). Los dos únicos archivos tocados (`39_reporte.R`, `datos_interfaz.json`) ya tenían su lugar canónico definido desde la inicialización (Rama A). Recomendación: correr el escáner al abrir sesión 3 para capturar el estado post-commit `8eead90` con nombres reales (actualmente el snapshot más reciente sigue fechado antes de este commit).

## 11. Pendientes y ruta sugerida

### Inventario de pendientes

**P2 — Auditoría de datos (protocolo 4.5).** *(heredado de v01, sin cambios de contexto)*
Contexto: ahora sí tiene sentido: hay cifras publicadas reales que auditar.
Tipo: deuda técnica / validación.
Impacto: valida que las cifras que ve el usuario final sean correctas.
Dependencias: ninguna (P1 ya completo).
Complejidad: Media-Alta.
Principios relevantes: C.8, protocolo 4.5 completo.
Precaución nueva (de esta sesión): la auditoría de `historial` debe usar el índice `partido` (secuencial, generado por `39_reporte.R`), no `id_partido` (que se repite por perspectiva); documentar esta distinción en el propio script de auditoría para que no se reintroduzca la confusión.
Criterio de éxito sugerido: cada cifra clave calculada por dos caminos independientes, dentro de tolerancia declarada.

**P3 — Investigar por qué worldfootballR/FBref falla consistentemente.** *(heredado de v01, sin cambios)*
Sin cambios de contexto respecto a v01. Ver traspaso v01 sección 11.

**P4 — Decidir si activar `FUENTE_FUERZA <- "compuesto"`.** *(heredado de v01, con precaución nueva)*
Contexto: sin cambios (Elo 48/48 disponible, nunca activado).
Tipo: mejora / decisión de producto.
Complejidad: Baja, pero requiere decisión informada del usuario.
**Precaución nueva:** si se activa, hay que actualizar `FUENTE_FUERZA_ACTUAL` en `39_reporte.R` (constante nueva de esta sesión) además de `FUENTE_FUERZA` en `31_ingesta_fuerza.R`; ambas deben coincidir o el campo `meta.fuente_fuerza` del JSON publicado mentirá sobre qué fuente se usó realmente. Ver P8.

**P5 — Deuda técnica menor: duplicación de archivos en el handoff de diseño.** *(heredado de v01, sin cambios)*

**P6 — `support.js` del handoff versionado pese a la convención "R único lenguaje".** *(heredado de v01, sin cambios)*

**P7 — Higiene de Git: commits mezclando cambios no relacionados en el mismo directorio de trabajo.** *(nuevo)*
Contexto: el `git status` mostrado al commitear P1 incluía, sin relación con `39_reporte.R`, cambios en `50_documentacion/estructura/` (archivos de escáner nuevos/borrados) y un archivo untracked (`traspaso_cierre_v01.md`, nunca commiteado en sesión 1). Ninguno de estos se incluyó en el commit de P1 (correcto, `git add` fue selectivo), pero quedan sueltos en el working directory.
Tipo: deuda técnica / higiene de repositorio.
Impacto: bajo, pero acumula superficie de confusión en futuros `git status`.
Dependencias: ninguna.
Complejidad: Baja.
Precauciones: el traspaso v01 debe commitearse en un commit propio de documentación, no mezclado con código; los snapshots viejos del escáner (`20260702_195155_*`) ya fueron podados por el algoritmo de retención=2 (política 7.4) y su borrado es esperado, no un error — commitear ese borrado junto con el snapshot nuevo en un commit de "actualización de escáner".
Criterio de éxito sugerido: `git status` limpio tras dos commits separados (uno de documentación/escáner, ya cubierto por el `traspaso_cierre_v02.md` de este cierre; el de `traspaso_cierre_v01.md` faltante se agrega en el mismo commit por ser del mismo tipo).

**P8 — Riesgo de desincronización entre `FUENTE_FUERZA` (31) y `FUENTE_FUERZA_ACTUAL` (39).** *(nuevo)*
Contexto: dos constantes independientes en dos scripts distintos deben coincidir manualmente; ninguna validación automática las compara.
Tipo: deuda técnica.
Impacto: si diverge, el JSON publicado reporta una fuente de fuerza incorrecta en `meta.fuente_fuerza`, engañando a quien consulte el sitio sobre la metodología real usada.
Dependencias: ninguna, pero se activa si P4 se resuelve activando `"compuesto"`.
Complejidad: Baja (agregar una validación cruzada, por ejemplo que `39_reporte.R` lea `FUENTE_FUERZA` directamente desde `31_ingesta_fuerza.R` en vez de duplicar la constante, o un `stopifnot` que las compare).
Principios relevantes: C.10 (transparencia del cambio), C.6 (consistencia de tipos/valores entre etapas).
Sugerencia de enfoque: evaluar en sesión 3 si conviene que `39_reporte.R` importe la constante en vez de redeclararla (requiere que `31_ingesta_fuerza.R` la exponga en un objeto accesible, no como variable local del script).

**P9 — Verificación pendiente en GitHub Pages remoto (no solo local).** *(nuevo)*
Contexto: la verificación de "datos reales" en esta sesión se hizo sirviendo `index.html` localmente (`python3 -m http.server`); no se reconfirmó explícitamente visitando `https://tomgc.github.io/mundial2026_confederaciones/` después del push `8eead90`.
Tipo: validación pendiente, no bloqueante (el commit ya está pusheado y Pages se redeploya automáticamente en cada push a `main`, según configuración de sesión 1).
Impacto: bajo, pero es la única verificación end-to-end real del objetivo del proyecto ("el sitio publicado muestra datos reales") que falta confirmar.
Complejidad: Baja (una visita al sitio).
Criterio de éxito sugerido: abrir el sitio publicado y confirmar el mismo flag "Datos reales del pipeline" visto localmente.

### Evaluación de deuda técnica

Zona frágil principal (sin cambios respecto a v01): dependencia total en el fallback CC0 para resultados (P3). Zona frágil nueva de esta sesión: sincronización manual entre dos constantes de fuente de fuerza en dos scripts distintos (P8), pequeña pero con riesgo de mentir silenciosamente sobre metodología si diverge.

### Auditoría de cierre (política 5.6, preguntas "Cierre")

| # | Pregunta | Respuesta |
|---|---|---|
| 5 | ¿Cada transformación crítica tiene check de validación? | Sí — `stopifnot()` en `39_reporte.R` (conteos 48/6, NA en nombre/rival_nombre); verificación externa manual de NA en pos_fifa/puntos_fifa/elo (no cubierta por el `stopifnot` interno, ver P-nuevo abajo) |
| 6 | ¿Los outputs son reproducibles e idempotentes? | Sí — escritura atómica en `39_reporte.R` (patrón `.tmp` + rename), `datos_interfaz.json` se sobrescribe completo cada corrida |
| 7 | ¿Decisiones metodológicas como constantes nombradas? | Sí — `SEDE_DEFAULT`, `FUENTE_FUERZA_ACTUAL` (ver P8 para el riesgo de sincronización entre constantes) |
| 8 | ¿Nombres de archivos y carpetas sin tildes, ñ ni espacios? | Sí, sin cambios respecto a v01 (excepción ya declarada del handoff heredado sigue vigente) |

**Nueva respuesta "no" implícita a agregar como pendiente:** la pregunta 5 revela que `pos_fifa`/`puntos_fifa`/`elo` no tienen `stopifnot` interno en `39_reporte.R` (solo se verificaron manualmente fuera del script en esta sesión). Se agrega como **P10**.

**P10 — Agregar `stopifnot` interno para NA en `pos_fifa`, `puntos_fifa`, `elo` dentro de `39_reporte.R`.** *(nuevo, derivado de la auditoría de cierre)*
Contexto: la verificación de estos tres campos se hizo manualmente en la sesión (fuera del script), no está automatizada dentro de `39_reporte.R`; si el insumo `ranking_fifa_20260611.csv` o `elo_20260702.csv` cambiara de formato en el futuro, un join fallido pasaría silencioso.
Tipo: deuda técnica (brecha de validación).
Impacto: medio — es exactamente el tipo de fallo silencioso que C.8 busca prevenir.
Complejidad: Baja (una línea de `stopifnot` adicional).
Criterio de éxito sugerido: `stopifnot(!anyNA(equipos_base$pos_fifa), !anyNA(equipos_base$puntos_fifa), !anyNA(equipos_base$elo))` agregado junto a la validación de `nombre` ya existente.

### Ruta sugerida para sesión 3

Criterios de priorización aplicados (1.2.4): P10 primero por ser deuda de validación barata y de alto valor preventivo (cierra una brecha detectada en la propia auditoría de cierre); P2 en segundo lugar como el foco sustantivo de la sesión.

1. **P10** (agregar validación NA faltante en `39_reporte.R`) — complejidad baja, cierre rápido antes de construir más encima del script.
2. **P9** (verificar Pages remoto) — complejidad baja, confirma el objetivo end-to-end real.
3. **P2** (auditoría de datos, protocolo 4.5) — foco sustantivo de la sesión, con el contexto de `39_reporte.R` aún fresco.

Diferir a sesión dedicada: P3, P5, P6 (sin cambios respecto a v01), P7 (higiene de Git, bajo impacto), P8 (solo urgente si P4 se activa).

## 12. Instrucciones específicas para la próxima sesión

- ⚠️ NO ejecutar `run_all(only=N)` para N>1 sin haber corrido antes `run_all(from=1, to=N)` en la misma sesión de R (heredado de v01, sigue vigente).
- 🔒 El contrato de datos del `index.html` (nombres de campos en español, shape completo en `generarMock()` líneas 403-557) es intocable sin coordinar ambos lados en la misma sesión (heredado de v01, reafirmado tras esta sesión).
- ⚠️ NO activar `FUENTE_FUERZA <- "compuesto"` sin preguntar primero al usuario (P4), y si se activa, actualizar también `FUENTE_FUERZA_ACTUAL` en `39_reporte.R` en el mismo cambio (P8).
- ✅ ANTES de trabajar en P2 (auditoría), releer la distinción `partido` (secuencial por equipo) vs. `id_partido` (se repite por perspectiva) documentada en la sección 7 de este traspaso.
- ✅ ANTES de cerrar sesión 3, commitear `traspaso_cierre_v01.md` si sigue sin commitear (ver P7 y sección 15).

## 13. Fragmentos de código de referencia

**Patrón de escritura atómica para JSON (nuevo en esta sesión, análogo al de CSV ya documentado en v01):**
```r
escribir_json_atomico <- function(objeto, destino) {
  tmp <- paste0(destino, ".tmp")
  jsonlite::write_json(objeto, tmp, auto_unbox = TRUE, digits = NA, pretty = FALSE)
  file.rename(tmp, destino)
  invisible(destino)
}
```

**Patrón de índice secuencial por grupo (para reconstruir `partido` desde `id_partido` no único):**
```r
historial_enriquecido <- historial |>
  arrange(codigo, id_partido) |>
  mutate(partido = row_number(), .by = codigo)
```

## 14. Reapertura

- **Nombre del chat:** `mundial2026_confederaciones, sesión 3 (Claude)`
- **Mensaje de apertura pre-armado:**

```
Tipo CONTINUATION. El protocolo (POLITICA_PROYECTO.md +
SETTINGS_Y_PROMPTS_OPERACIONALES.md) vive en la knowledge base del
Project y se lee desde ahí. Adjunto el traspaso de la sesión anterior,
el backlog acumulativo y el escáner más reciente.
```

- **Documentos para la próxima sesión:**

  1. *Protocolo en knowledge base* (NO se adjuntan, solo verificar que estén al día): `POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
  2. *Opcionales según foco real:* `CLAUDE.md` si la sesión 3 correrá en Claude Code (ya existe en la raíz del repo).
  3. *Específicos de la sesión (SÍ se adjuntan):* `traspaso_cierre_v02.md` (este documento); `backlog_acumulativo.md` (nuevo, primera vez como archivo independiente); `estructura_actual.md` (recomendado re-ejecutar el escáner al abrir, dado que el snapshot referenciable es previo al commit `8eead90`); si se trabaja en P2, adjuntar también `40_salidas/datos_interfaz.json` y los tres CSV de `40_salidas/` ya usados en esta sesión.

- **Nota final obligatoria:** si `POLITICA_PROYECTO.md` o `SETTINGS_Y_PROMPTS_OPERACIONALES.md` cambiaron en la knowledge base desde esta sesión, adjuntar la versión más actualizada al abrir y avisarlo.

## 15. Errores del asistente (registro obligatorio, POLITICA 0.5)

| momento | disparador | que_paso | regla_violada | causa_raiz | salvaguarda_presente | patron |
|---|---|---|---|---|---|---|
| Al recibir el `git status` previo al commit de P1 | asistente lo señaló espontáneamente (sección de estado al cierre, no en el momento del comando) | El traspaso `traspaso_cierre_v01.md` de la sesión anterior nunca fue commiteado al repo; quedó como archivo local sin versionar hasta que el `git status` de esta sesión lo reveló como untracked. | SETTINGS §2.1: "Al cerrar una sesión CONTINUATION o NEW PROJECT, generar `traspaso_cierre_vNN.md`... en `50_documentacion/traspasos/`" — la generación del archivo se cumplió, pero el traspaso de sesión 1 no incluyó instrucción explícita de commitearlo, y el asistente (en esa sesión) no lo verificó como parte del cierre. | El protocolo de cierre (SETTINGS §2) no incluye un paso explícito de "verificar que el traspaso quedó commiteado", solo de generarlo; el asistente de sesión 1 asumió que "generar el archivo" bastaba, sin confirmar que el archivo entrara al control de versiones, pese a que la política General (versionado, sección 3) exige "commits frecuentes" para todo artefacto del proyecto. | Ninguno de los documentos (POLITICA/SETTINGS) exige explícitamente un `git add`/`git commit` del traspaso como parte del cierre de sesión; es una omisión de diseño del protocolo mismo, no una regla ignorada a sabiendas. | nuevo |
| Al entregar el comando de `cp` + `git add` tras confirmar el cierre | usuario lo corrigió | Se generó un bloque de comandos que incluía `cp ~/Downloads/... ` (mover archivos descargados a su ruta canónica), una tarea mecánica manual, pese a que el usuario ya había indicado explícitamente en el mismo turno "yo reemplazo manualmente los archivos". | POLITICA §0.4 ("Tareas mecánicas manuales... El asistente no genera scripts para ellas: indica qué hacer en una línea") y `userPreferences` ("Mechanical manual tasks... are MINE. Do not generate scripts for them; just tell me what to do in one line") — ambas ya vigentes antes de esta sesión, no reglas nuevas. | El asistente reconstruyó el bloque de comandos completo de la iteración anterior por inercia (copiar-pegar el flujo previo) sin re-evaluar cada línea contra la instrucción explícita que el propio usuario acababa de dar en el turno inmediatamente anterior. | POLITICA §0.4 y `userPreferences` (sección "Autonomy"), ambas de forma explícita y ya conocidas en la sesión: es el mismo patrón, no una regla nueva ni ambigua. | variante del error de sección 15, fila 1 (instrucción/comando entregado sin verificar precondición ya establecida en la sesión, esta vez una preferencia explícita del usuario en vez de un estado de archivos) |

**Análisis:** dos errores registrados en esta sesión. El primero es un patrón nuevo (artefacto de cierre no commiteado). El segundo es una variante del error de sesión 1 (`run_all(only=N)` sin verificar precondición): en ambos casos el asistente entregó una instrucción sin contrastarla contra una condición ya establecida en la sesión (allí, el estado de `40_salidas/`; aquí, una preferencia explícita del usuario dada en el turno inmediatamente anterior). Recomendación para sesión 3 y para revisión de cartera: si "instrucción entregada sin recontrastar contra el estado/preferencia ya establecida en la misma sesión" aparece en el traspaso de otro proyecto de los 16, es evidencia de que el protocolo necesita un paso explícito de "releer las últimas 2-3 instrucciones del usuario antes de generar cualquier comando", no solo la regla general de autonomía.
