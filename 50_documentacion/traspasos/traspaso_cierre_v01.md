# traspaso_cierre_v01.md

## 1. Identificación

- **Proyecto:** mundial2026_confederaciones
- **Versión:** v01 (primer cierre formal)
- **Fecha:** 2026-07-02
- **Sesión 1**, foco: inicialización Rama A + pipeline de ingesta (FIFA, Elo, resultados) + motor Elo/FIFA SUM con datos reales + integración de interfaz visual.
- **Entorno:** R 4.3.3 (verificación de sintaxis/lógica en contenedor Claude); ejecución real en Positron (Mac, R local del usuario).
- **Archivos principales modificados/creados:** `00_run_all.R`, `00_escanear_proyecto.R`, `10_utils/*.R`, `30_procesamiento/31_ingesta_fuerza.R`, `32_ingesta_resultados.R`, `33_motor_elo.R`, `39_reporte.R` (stub), `20_insumos/*.csv` (3), `index.html`, `assets/fonts/*.woff2`, `.gitignore`.

## 2. Resumen ejecutivo

Se inicializó el proyecto desde cero (Rama A, datos públicos, raíz unificada) y se construyó el pipeline completo hasta el motor de rating: ingesta de fuerza pre-torneo (ranking FIFA snapshot 11-jun-2026 y Elo snapshot 02-jul-2026, ambos como insumos fijos verificados manualmente tras confirmar que el scraping de eloratings.net es inviable por renderizado JS), ingesta de resultados del Mundial vía dataset CC0 de GitHub (fallback activo; FBref/worldfootballR falló en todas las corridas), y el motor Elo/FIFA SUM de dos niveles (selección + confederación) con inferencia de avance en empates de eliminación directa. En paralelo, Claude Design entregó un handoff visual de alta fidelidad que Claude Code integró al `index.html` (5 vistas, IBM Plex Mono local, tokens exactos). El repo se publicó en GitHub (público) y GitHub Pages quedó activo. El sitio web sigue mostrando datos mock: falta el paso 5 (`39_reporte.R`, aún stub) que debe emitir `datos_interfaz.json` para que la interfaz consuma datos reales. Todo lo generado en la sesión está commiteado y pusheado (`f35141c`).

## 3. Estado al cierre

**Funciona (última ejecución exitosa: 2026-07-02 21:44:47, log confirmado):**
- `run_all(from=1, to=3)` completo sin error: 48 equipos con fuerza (FIFA 48/48, Elo 48/48), 82 partidos ingeridos (0 `sin_clasificar`), motor con 164 filas de historial y 2 pendientes de resolución.
- Repo en GitHub (`https://github.com/tomgc/mundial2026_confederaciones`), rama `main`, push exitoso.
- GitHub Pages activo y desplegado (`https://tomgc.github.io/mundial2026_confederaciones/`) tras reintento manual (primer deploy falló por error transitorio de la plataforma, no del repo).
- `index.html` con 5 vistas navegables, verificado en navegador por Claude Code (sin errores de consola, fuentes locales 200 OK, responsive sin overflow, accesibilidad `:focus-visible` confirmada).

**No funciona / pendiente:**
- `39_reporte.R` sigue siendo stub. El sitio web publicado usa datos mock, no los reales del pipeline.
- `worldfootballR`/FBref falla consistentemente (`fb_match_urls no devolvio partidos`) en las 3 corridas de la sesión; el pipeline depende 100% del fallback CC0 para resultados.

**Delta respecto a v00 (no existe traspaso anterior; este es el primer cierre formal del proyecto).**

## 4. Registro detallado de cambios

**Cambio 1 — Inicialización de estructura Rama A.**
Archivos: estructura completa de carpetas, `00_run_all.R`, `00_escanear_proyecto.R`, `10_utils/*.R`, `.gitignore`, `README.md`, `.Rproj`.
Categoría: andamiaje.
Qué: estructura canónica completa según política sección 1, con `20_insumos/` y `40_salidas/` dentro del repo (proyecto 100% público).
Por qué: datos de fútbol/rankings son públicos, no aplica gobernanza de datos sensibles (política 6.1).
Verificación: `run_all()` end-to-end sin error sobre los 4 stubs iniciales; escáner ejecutado.

**Cambio 2 — Maestro de 48 equipos y verificación de universo.**
Archivo: `20_insumos/equipos_mundial2026.csv`.
Categoría: dato crudo inmutable.
Qué: código FIFA, nombre es/en, confederación, grupo para las 48 selecciones (grupos A-L confirmados vía búsqueda web).
Por qué: universo estable del modelo, separado de la fuerza (que sí cambia).
Verificación: conteo por confederación cuadra (UEFA 16, CAF 10, AFC 9, CONMEBOL 6, CONCACAF 6, OFC 1 = 48).

**Cambio 3 — Ingesta de fuerza (`31_ingesta_fuerza.R`), tres iteraciones.**
Archivo: `30_procesamiento/31_ingesta_fuerza.R`, insumos `ranking_fifa_20260611.csv` y `elo_20260702.csv`.
Categoría: pipeline de datos.
Qué: iteración 1 usó scraping para FIFA y Elo (ambos vía `rvest`); iteración 2 reemplazó FIFA por snapshot fijo verificado (Wikipedia, 48 valores reales); iteración 3 reemplazó Elo por snapshot fijo verificado (capturado de screenshots del usuario tras diagnosticar que eloratings.net renderiza vía JS y `rvest` nunca podría leerlo).
Por qué: ambas fuentes son estáticas en la práctica (FIFA no actualiza hasta el 20-jul; Elo se congeló manualmente para esta sesión), y el scraping añadía fragilidad sin beneficio real.
Verificación: cobertura FIFA 48/48 y Elo 48/48 confirmada en log de ejecución real del usuario (no simulada).

**Cambio 4 — Ingesta de resultados (`32_ingesta_resultados.R`), incluye bug fix.**
Archivo: `30_procesamiento/32_ingesta_resultados.R`.
Categoría: pipeline de datos + bug de código.
Qué: worldfootballR como fuente primaria (falla en las 3 corridas: `fb_match_urls no devolvio partidos`), fallback a dataset CC0 de GitHub (`mominullptr/FIFA-World-Cup-2026-Dataset`, `matches_detailed.csv`).
Bug encontrado y corregido: `clave_nombre()` usaba regex `[^a-z ]` que eliminaba dígitos junto con puntuación; "Round of 32" y "Round of 16" colapsaban a la misma clave ("round of "), ninguna calzaba contra `MAPA_FASE`. Fix: regex cambiada a `[^a-z0-9 ]`. Verificado que el fix no afecta el matching de nombres de equipo (ninguno lleva dígitos).
Por qué: sin el fix, 10/82 partidos (12%, todos los de dieciseisavos) quedaban con fase `sin_clasificar`, imposibilitando calcular la importancia (I) correcta para el motor.
Verificación: tras el fix, 0 filas `sin_clasificar` en corrida real (82 partidos: 72 grupos + 10 dieciseisavos).

**Cambio 5 — Motor Elo/FIFA SUM (`33_motor_elo.R`), incluye diseño de inferencia de avance.**
Archivo: `30_procesamiento/33_motor_elo.R` (nuevo, completo).
Categoría: núcleo del modelo.
Qué: nivel 1 (selección) con `ΔR = I·G·(W−We)`, G continuo (`1+ln(d)`), sin factor sorpresa; nivel 2 (confederación) con transferencia solo en cruces inter-confederación (`PESO_TRANSFERENCIA_CONF=0.15`). Incluye lógica de inferencia de avance: en partidos de eliminación directa empatados en marcador (el dataset CC0 no expone columna de penales/prórroga), si un equipo aparece en una fase posterior jugada, se le fuerza `W=1` (avanzó) / `W=0` (rival); si ninguno de los dos aparece aún en fase posterior, `W=0.5` provisional con flag `pendiente_resolucion`.
Por qué: sin esta inferencia, un empate 1-1 en eliminación directa (que en la realidad definió un ganador vía penales/prórroga no capturados en los datos) se registraría como empate real, subestimando el rendimiento del equipo que efectivamente avanzó.
Verificación: probado con mock incluyendo caso "empate con avance conocido" (forzó V/D correctamente) y "empate sin fase posterior" (quedó en 0.5 + flag + WARN). Confirmado en corrida real: 2 pendientes de resolución, coincide con los empates de R32 (Alemania-Paraguay, España-Austria) aún sin fase posterior jugada al momento de la corrida.

**Cambio 6 — Integración de dirección visual al `index.html`.**
Archivos: `index.html` (reescrito completo), `assets/fonts/*.woff2` (5 archivos nuevos).
Categoría: interfaz.
Qué: Claude Design entregó handoff de alta fidelidad (5 vistas: Confederaciones, Rankings, Equipo/línea de tiempo, Metodología, Tokens); Claude Code lo integró preservando el contrato de datos JSON existente (español) y sustituyendo Google Fonts por IBM Plex Mono local (extraída del standalone.html del handoff).
Por qué: política 5.5 exige archivo único sin dependencias externas; el README del handoff sugería React/Google Fonts, ambos rechazados por esa razón.
Decisiones de mapeo documentadas por Claude Code: columna "Cambio" en Rankings redefinida como variación de posición (no de rating en puntos, que no existía en el handoff); tarjetas de Confederación adaptadas a los 2 campos reales del contrato (`obs_vs_esp`, `transfer_neto`).
Verificación: probado en navegador por Claude Code — 5 tabs sin errores de consola, fuentes locales (0 requests externos), búsqueda/filtros/ordenamiento funcionando, accesibilidad (`:focus-visible`, contraste `--muted` ≥4.5:1) confirmada, responsive sin overflow en 375px.

**Cambio 7 — Publicación en GitHub y GitHub Pages.**
Archivos: `.gitignore` (bug fix incluido).
Categoría: infraestructura.
Bug encontrado y corregido: la excepción `!/index.html` no funcionaba porque tenía un comentario inline en la misma línea (`!/index.html # explicacion`); en sintaxis `.gitignore` un `#` no al inicio de línea se interpreta como parte del patrón, invalidando la excepción completa. Fix: comentario movido a línea propia.
Qué: `git init`, commit inicial (42 archivos), remote a repo público ya creado por el usuario, push exitoso; GitHub Pages configurado (`main` + `/(root)`, tras corregir que apuntaba a `/docs` por defecto); primer deploy falló por error transitorio de la plataforma ("Deployment failed, try again later", confirmado en logs que build y payload eran correctos), resuelto con reintento manual.
Verificación: `git ls-files` confirmó 0 archivos sensibles trackeados; sitio live confirmado por el usuario tras el reintento.

**Cambio 8 (post-handoff, mismo día) — Segundo commit con datos reales.**
Archivos: los 3 scripts de `30_procesamiento/` (fuerza, resultados, motor) + `20_insumos/elo_20260702.csv` + 5 salidas en `40_salidas/`.
Categoría: pipeline de datos.
Commit `f35141c`, pusheado. Contiene el resultado de los cambios 3, 4 y 5 ya descritos arriba.

## 5. Backlog acumulativo

Primer cierre: backlog embebido aquí (a partir del segundo cierre se extrae a `50_documentacion/activa/backlog_acumulativo.md`, según protocolo).

**Objetivo del proyecto:** modelo de comparación de desempeño de selecciones nacionales por confederación en el Mundial 2026, tipo Elo/FIFA SUM, que mide rendimiento observado vs. esperado (no solo rating absoluto) para responder qué confederación tuvo mejor desempeño relativo a la fuerza de sus equipos. Construido en R (Positron), con interfaz web estática (GitHub Pages). Para uso analítico personal del usuario.

**Nota metodológica:** cuenta como "cambio" cada solicitud distinguible del usuario (una decisión, una corrección, un nuevo requisito), no las acciones técnicas que la implementan. No cuentan errores del asistente corregidos de inmediato en el mismo turno; sí cuentan los bugfixes que el usuario tuvo que señalar o que quedaron documentados como tal. Clasificación por intención primaria. Fuente del conteo: este traspaso.

**Clasificación temática (provisional, a refinar en sesión 2):**

| Categoría | N° | % | Descripción |
|---|---|---|---|
| Arquitectura/andamiaje | 1 | 6% | Inicialización Rama A completa |
| Diseño del modelo | 4 | 24% | G continuo, eliminar surprise_factor, jerarquía confederación, tabla de importancia por fase |
| Ingesta de datos | 5 | 29% | Maestro 48 equipos, FIFA snapshot, Elo snapshot (x2 iteraciones), resultados con fallback |
| Bugs de código | 2 | 12% | `clave_nombre` destruye dígitos (fase), `.gitignore` comentario inline |
| Interfaz/diseño visual | 3 | 18% | Prompt Claude Design, integración Claude Code, fuentes locales |
| Infraestructura/deploy | 2 | 12% | Publicación GitHub, configuración Pages |

**Resumen estadístico por sesión:**

| Sesión | Traspasos generados | N° de cambios | Modelo | Foco |
|---|---|---|---|---|
| 1 | v01 (este) | 17 | Claude (Sonnet, vía interfaz) + Claude Code | Andamiaje + pipeline completo + interfaz |

**Detalle cronológico:**

1. Definición del modelo Elo/FIFA SUM (G continuo, sin surprise_factor, jerarquía de confederación, tabla de importancia con dieciseisavos agregado).
2. Decisión de fuentes de datos (worldfootballR + snapshot FIFA/Elo, Kaggle como respaldo).
3. Inicialización Rama A completa (estructura, orquestador, escáner, stubs).
4. Maestro de 48 equipos con confederación y grupo.
5. Implementación inicial de `31_ingesta_fuerza.R` con scraping FIFA+Elo.
6. Corrección: FIFA reemplazado por snapshot fijo verificado (Wikipedia).
7. Prompt de interfaz para Claude Code, definiendo contrato de datos JSON.
8. Handoff de Claude Design recibido (bundle completo: dc.html, standalone.html, support.js, README, data/).
9. Prompt de integración a Claude Code, con decisiones ya tomadas (stack single-file, fuentes locales, preservar contrato de datos).
10. Corrección de configuración de GitHub Pages (`/docs` → `/(root)`).
11. Resolución de fallo transitorio de deploy (reintento).
12. Versionado inicial del repo (bug fix de `.gitignore` incluido).
13. Implementación de `32_ingesta_resultados.R` (worldfootballR + fallback CC0).
14. Bugfix reportado indirectamente por el usuario (WARN de fase sin_clasificar) → corrección de `clave_nombre`.
15. Pregunta de dominio del usuario sobre marcador (¿incluye penales?) → hallazgo de que el dataset no los expone.
16. Decisión de diseño: inferencia de avance en empates de eliminación, delegada a `33_motor_elo.R`.
17. Implementación de `33_motor_elo.R` con la inferencia de avance; corrección de error propio (dependencia de orden en `run_all(only=3)`); reemplazo de Elo scraping por snapshot fijo verificado (screenshots del usuario); commit y push final de la sesión.

**Delta del backlog:** N/A (primer cierre).

## 6. Bugs de la sesión

**Bug 1 — `clave_nombre()` destruye dígitos en `32_ingesta_resultados.R`.**
Síntoma observable: 10/82 partidos (12%) con `fase == "sin_clasificar"` tras la primera corrida real.
Causa raíz: regex `str_replace_all("[^a-z ]", " ")` elimina cualquier carácter que no sea letra minúscula o espacio, incluidos dígitos. "Round of 32" y "Round of 16" colapsaban a la misma clave normalizada ("round of "), ninguna calzaba contra las claves de `MAPA_FASE` (que sí incluían los números).
Solución exacta: `30_procesamiento/32_ingesta_resultados.R`, función `clave_nombre()`, regex cambiada de `[^a-z ]` a `[^a-z0-9 ]`.
Criterio de verificación: 0 filas `sin_clasificar` tras el fix, confirmado en corrida real (log del usuario).
Patrón general aprendido: cuando una clave de normalización debe preservar información discriminante (aquí, el número de ronda), la función de limpieza de texto debe declarar explícitamente qué conserva, no asumir que "solo letras" es sensato para todo dominio. Regla: antes de reusar una función de normalización de texto entre dos dominios distintos (nombres de equipo vs. etiquetas de fase), verificar si el dominio nuevo tiene información en caracteres que la función descarta.
Principio relacionado: C.8 (validación de integridad) — el WARN de "fase sin_clasificar" sí disparó, lo que permitió detectar el bug; sin ese WARN el error habría sido silencioso.
Estado: resuelto y verificado.

**Bug 2 — Comentario inline invalida excepción en `.gitignore`.**
Síntoma observable: `index.html` no aparecía como `untracked` en `git status` pese a la excepción `!/index.html` presente en `.gitignore`.
Causa raíz: la línea `!/index.html # comentario explicativo` se interpretó completa como patrón (el `#` no estaba al inicio de línea, por lo que no se reconoció como comentario en sintaxis `.gitignore`), invalidando el patrón de excepción.
Solución exacta: mover el comentario a su propia línea, separado del patrón `!/index.html`.
Criterio de verificación: `git status` mostró `index.html` como `??` (untracked) tras el fix; confirmado con `git check-ignore` antes y después.
Patrón general aprendido: en `.gitignore`, cualquier patrón que necesite comentario explicativo debe llevarlo en la línea anterior, nunca inline. Regla aplicable a cualquier archivo de configuración con sintaxis de comentario ambigua.
Principio relacionado: verificación explícita antes de asumir que una regla de exclusión/inclusión está activa.
Estado: resuelto y verificado (detectado y corregido por Claude Code en la misma sesión, antes del primer commit).

## 7. Aprendizajes y restricciones descubiertas

- **eloratings.net no es scrapeable con `rvest`.** Restricción: el sitio renderiza su tabla completa vía JavaScript (`scripts/ratings.js` sobre un `<div id="maindiv">` vacío en el HTML estático); `rvest::read_html()` nunca ejecuta JS, así que ningún ajuste de selector CSS puede resolverlo. Contexto: si se vuelve a necesitar Elo actualizado de esta fuente en el futuro, la vía correcta es un navegador headless (`chromote`/`RSelenium`) o localizar el endpoint de datos subyacente que consume `ratings.js` (no confirmado en esta sesión). Por ahora, resuelto con snapshot manual verificado por el usuario vía screenshots.
- **worldfootballR/FBref no es confiable como fuente primaria para este torneo específico.** Restricción: `fb_match_urls()` retornó 0 resultados en las 3 corridas de la sesión, pese a seguir el patrón documentado del paquete. No se investigó la causa raíz. El fallback a CC0 (`mominullptr/FIFA-World-Cup-2026-Dataset`) compensó completamente. El pipeline depende 100% de ese fallback.
- **Datasets de resultados de fútbol no siempre exponen desempate (penales/prórroga).** Restricción descubierta a partir de pregunta del usuario, no de fallo técnico: `matches_detailed.csv` (CC0) solo tiene `home_score`/`away_score`, sin columnas de penales ni tiempo extra. Regla aplicable a cualquier fuente de datos de eliminación directa: verificar explícitamente si expone desempate antes de asumir que el marcador define ganador/perdedor.
- **`run_all(only=N)` no resuelve dependencias entre pasos.** Restricción de diseño del propio orquestador (esperada, no un bug). Error del asistente por no advertirlo antes de indicar el comando (ver sección 15).

## 8. Decisiones de diseño

**Decisión 1 — Fuerza base configurable con tres modos (fifa/elo/compuesto).**
Alternativas consideradas: fuente única fija (FIFA solamente); combinación fija sin opción de intercambio.
Justificación: permite iterar sin tocar el resto del pipeline; el usuario puede decidir el peso relativo según lo que la sesión revele sobre la calidad de cada fuente.
Tensión resuelta: simplicidad (una sola fuente) vs. flexibilidad (constante nombrada `FUENTE_FUERZA`, no hardcodeada). Se priorizó flexibilidad porque el costo de mantenerla es bajo y el valor de poder cambiar de fuente sin reescribir código es alto.
Implicancia: queda en `"fifa"` al cierre de la sesión (nunca se cambió a `"compuesto"` pese a que Elo ya está 48/48); pendiente para sesión 2 decidir si se activa.

**Decisión 2 — Inferencia de avance vive en el motor (33), no en la ingesta (32).**
Alternativas consideradas: resolver el problema del desempate en la etapa de ingesta de resultados.
Justificación: el motor ya conoce la escalera completa de fases (`ORDEN_FASES`) necesaria para determinar "fase posterior"; duplicar esa lógica en la ingesta violaría el principio de que la ingesta debe ser agnóstica a la estructura del torneo.
Tensión resuelta: modularidad vs. simplicidad — se priorizó modularidad porque la lógica de fases es responsabilidad conceptual del motor.
Implicancia: `resultados_partidos.csv` sigue siendo un reflejo fiel del dataset fuente (sin inferencias); toda interpretación vive en `33_motor_elo.R`, documentada y auditable ahí.

**Decisión 3 — Snapshot manual en vez de scraping para FIFA y Elo.**
Alternativas consideradas: navegador headless para Elo (chromote/RSelenium); insistir en ajustar selectores.
Justificación: ambas fuentes son de facto estáticas en la ventana de esta sesión. El costo de mantener un scraper robusto contra un sitio con JS no se justifica frente al valor de un snapshot fijo, documentado y verificable.
Tensión resuelta: automatización completa vs. pragmatismo — se priorizó pragmatismo, con el costo de que actualizar estos insumos en el futuro es una tarea manual.
Implicancia: si se necesita Elo actualizado a fecha posterior, hay que repetir el proceso de captura manual o resolver el endpoint real de eloratings.net.

## 9. Constantes y parámetros vigentes

| Constante | Valor | Archivo | Nota |
|---|---|---|---|
| `IMPORTANCIA_FASE` | grupos=25, dieciseisavos=35, octavos=40, cuartos=50, semifinal=60, tercer_lugar=45, final=70 | `33_motor_elo.R` | Ajustable sin tocar lógica |
| `ESCALA_RATING` | 20 | `33_motor_elo.R` | Reescala fuerza_base (0-100) a rango tipo Elo |
| `BASE_LOGISTICA` | 400 | `33_motor_elo.R` | Estándar Elo, no calibrado contra datos reales |
| `PESO_TRANSFERENCIA_CONF` | 0.15 | `33_motor_elo.R` | Fracción de ΔR transferida a confederación en cruces inter |
| `FUENTE_FUERZA` | "fifa" | `31_ingesta_fuerza.R` | Configurable a "elo" o "compuesto"; pendiente decisión (P4) |
| `PESO_COMPUESTO` | fifa=0.6, elo=0.4 | `31_ingesta_fuerza.R` | Usado solo si FUENTE_FUERZA="compuesto" |
| `N_EQUIPOS` | 48 | `31_ingesta_fuerza.R`, `32_ingesta_resultados.R` | Validación de integridad |

## 10. Arquitectura de archivos

Referencia: `50_documentacion/activa/estructura/estructura_actual.md` (snapshot 2026-07-02 21:47:32, 16 carpetas, 39 archivos). Estructura conforme a la política: decenas respetadas, `20_insumos/`/`40_salidas/` dentro del repo (Rama A), documentación bifurcada correctamente. Sin desviaciones detectadas contra la estructura canónica.

Nota: `50_documentacion/activa/decisiones/` contiene el bundle completo del handoff de diseño (incluye `data/` con CSV duplicados de `20_insumos/` y `assets/fonts/` duplicado de la raíz) — señalado como deuda técnica menor (P5).

## 11. Pendientes y ruta sugerida

### Inventario de pendientes

**P1 — Implementar `39_reporte.R` (emitir `datos_interfaz.json`).**
Contexto: es el único bloqueante para que el sitio web muestre datos reales; `index.html` ya tiene la lógica fetch→mock lista.
Tipo: funcionalidad (bloqueante).
Impacto: sin esto, el pipeline completo (pasos 1-3, ya funcionando) no llega al usuario final.
Dependencias: `rating_equipos.csv`, `historial_partidos.csv`, `rating_confederaciones.csv` (los tres ya existen y están verificados).
Complejidad: Media (transformar 3 CSV al shape JSON ya definido en el contrato del prompt de interfaz).
Principios relevantes: B.4 (criterio de éxito verificable).
Precauciones: el contrato de datos ya está fijado en el `index.html` (no renombrar campos); respetar las decisiones de mapeo que Claude Code ya documentó (columna "Cambio" = variación de posición, no de rating).
Criterio de éxito sugerido: al abrir el sitio publicado, el indicador real/mock muestra "real" y los 48 equipos coinciden con `rating_equipos.csv`.

**P2 — Auditoría de datos (protocolo 4.5).**
Contexto: solo tiene sentido después de P1, cuando hay cifras publicadas que auditar.
Tipo: deuda técnica / validación.
Impacto: valida que las cifras que ve el usuario final sean correctas.
Dependencias: P1 completo.
Complejidad: Media-Alta.
Principios relevantes: C.8, protocolo 4.5 completo.
Criterio de éxito sugerido: cada cifra clave calculada por dos caminos independientes, dentro de tolerancia declarada.

**P3 — Investigar por qué worldfootballR/FBref falla consistentemente.**
Contexto: no bloqueante (fallback funciona), pero deja el pipeline dependiente de una sola fuente de resultados.
Tipo: deuda técnica.
Impacto: si el dataset CC0 deja de actualizarse, no hay fuente de resultados.
Complejidad: Media.
Precaución: el repo de worldfootballR está archivado; puede no valer la pena la inversión.

**P4 — Decidir si activar `FUENTE_FUERZA <- "compuesto"`.**
Contexto: Elo ya está 48/48 disponible; nunca se activó el modo compuesto.
Tipo: mejora / decisión de producto.
Impacto: cambia el rating inicial de los 48 equipos.
Complejidad: Baja, pero requiere decisión informada del usuario, no autonomía del asistente.

**P5 — Deuda técnica menor: duplicación de archivos en el handoff de diseño.**
Contexto: `50_documentacion/activa/decisiones/data/` duplica CSV de `20_insumos/`; `assets/fonts/` duplicado dentro del handoff.
Tipo: deuda técnica, no urgente.
Impacto: riesgo de divergencia silenciosa.
Complejidad: Baja.

**P6 — `support.js` del handoff versionado pese a la convención "R único lenguaje".**
Contexto: vive dentro de `decisiones/` como parte del handoff congelado, no se ejecuta.
Tipo: cosmética.
Impacto: ninguno funcional.
Complejidad: Baja.

### Evaluación de deuda técnica

Zona frágil principal: dependencia total en el fallback CC0 para resultados (P3). Zona de oportunidad: el motor ya está listo para consumir un modo "compuesto" de fuerza (P4) sin cambios de código, solo falta la decisión.

### Auditoría de cierre (política 5.6, preguntas "Cierre")

| # | Pregunta | Respuesta |
|---|---|---|
| 5 | ¿Cada transformación crítica tiene check de validación? | Sí — `stopifnot()` en los 3 scripts de `30_procesamiento/`, WARN explícitos en casos ambiguos |
| 6 | ¿Los outputs son reproducibles e idempotentes? | Sí — escritura atómica en los 3 scripts; `resultados_partidos.csv` se sobrescribe completo cada corrida |
| 7 | ¿Decisiones metodológicas como constantes nombradas? | Sí — ver sección 9 |
| 8 | ¿Nombres de archivos y carpetas sin tildes, ñ ni espacios? | Sí, excepto el handoff de diseño heredado ("Dashboard Mundial 2026.dc.html" trae espacios) — excepción declarada: archivo heredado de un tercero (Claude Design), no renombrado para preservar trazabilidad del handoff original |

Ninguna respuesta "no" sin excepción declarada.

### Ruta sugerida para sesión 2

Criterios de priorización aplicados (1.2.4): P1 es la única funcionalidad bloqueante para el objetivo declarado ("hasta tener datos reales en el sitio"); antecede a P2 por dependencia directa.

1. **P1** (implementar `39_reporte.R`) — complejidad media, criterio de éxito claro, desbloquea el objetivo central.
2. **P2** (auditoría de datos) — inmediatamente después, mientras el contexto de las fórmulas del motor está fresco.

Diferir a sesión dedicada: P3 (no bloqueante), P5 y P6 (cosmética). P4 requiere una pregunta corta al usuario al inicio de sesión 2 (decisión de producto, no autonomía).

## 12. Instrucciones específicas para la próxima sesión

- ⚠️ NO ejecutar `run_all(only=N)` para N>1 sin haber corrido antes `run_all(from=1, to=N)` en la misma sesión de R (o confirmar que `40_salidas/` ya tiene los insumos previos).
- ✅ ANTES de tocar `39_reporte.R`, releer el contrato de datos JSON documentado en el prompt de interfaz de esta sesión (shape exacto: `meta`, `confederaciones[]`, `equipos[].historial[]`) y las decisiones de mapeo que Claude Code ya tomó al integrar el handoff visual.
- 🔒 El contrato de datos del `index.html` (nombres de campos en español) es intocable sin coordinar ambos lados (backend R + frontend HTML) en la misma sesión.
- ⚠️ NO activar `FUENTE_FUERZA <- "compuesto"` sin preguntar primero al usuario (P4, decisión de producto).

## 13. Fragmentos de código de referencia

**Patrón de escritura atómica (usado en los 3 scripts de `30_procesamiento/`):**
```r
escribir_csv_atomico <- function(df, destino) {
  tmp <- paste0(destino, ".tmp")
  readr::write_csv(df, tmp)
  file.rename(tmp, destino)
  invisible(destino)
}
```

**Patrón de clave de nombre normalizada (con el fix de dígitos aplicado):**
```r
clave_nombre <- function(x) {
  x |>
    stringr::str_to_lower() |>
    stringi::stri_trans_general("Latin-ASCII") |>
    stringr::str_replace_all("[^a-z0-9 ]", " ") |>  # preserva digitos
    stringr::str_squish()
}
```

## 14. Reapertura

- **Nombre del chat:** `mundial2026_confederaciones, sesión 2 (Claude)`
- **Mensaje de apertura pre-armado:**

```
Tipo CONTINUATION. El protocolo (POLITICA_PROYECTO.md +
SETTINGS_Y_PROMPTS_OPERACIONALES.md) vive en la knowledge base del
Project y se lee desde ahí. Adjunto el traspaso de la sesión anterior
y el escáner más reciente.
```

- **Documentos para la próxima sesión:**

  1. *Protocolo en knowledge base* (NO se adjuntan, solo verificar que estén al día): `POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
  2. *Opcionales según foco real:* `CLAUDE.md` si la sesión 2 correrá en Claude Code (ya existe en la raíz del repo).
  3. *Específicos de la sesión (SÍ se adjuntan):* `traspaso_cierre_v01.md` (este documento); `estructura_actual.md` (o re-ejecutar el escáner al abrir); si se va a trabajar en P1, adjuntar también `40_salidas/rating_equipos.csv`, `40_salidas/historial_partidos.csv`, `40_salidas/rating_confederaciones.csv` (pequeños, críticos para diseñar `39_reporte.R`).

- **Nota final obligatoria:** si `POLITICA_PROYECTO.md` o `SETTINGS_Y_PROMPTS_OPERACIONALES.md` cambiaron en la knowledge base desde esta sesión, adjuntar la versión más actualizada al abrir y avisarlo.

## 15. Errores del asistente (registro obligatorio, POLITICA 0.5)

| momento | disparador | que_paso | regla_violada | causa_raiz | salvaguarda_presente | patron |
|---|---|---|---|---|---|---|
| Tras entregar `33_motor_elo.R` completo | usuario lo corrigió (pegó log de error) | Se indicó a Claude Code ejecutar `run_all(only=3)` sin haber corrido antes los pasos 1-2 en esa sesión de terminal; el paso 3 depende de `fuerza_equipos.csv` (salida del paso 1), inexistente aún. | Ninguna regla textual explícita lo prohibía; es una inferencia de diseño del propio orquestador (`run_all` no resuelve dependencias entre pasos) que el asistente debía anticipar antes de dar la instrucción. | El asistente asumió implícitamente que el usuario ya había corrido el pipeline completo antes en esa sesión de R, sin verificarlo ni advertirlo. | Ninguno de los documentos (POLITICA/SETTINGS/CLAUDE.md) cubre explícitamente "verificar estado de `40_salidas/` antes de indicar un comando `only=N`"; es una omisión de diseño del propio `00_run_all.R`, no de la gobernanza documental. | nuevo |

**Análisis:** único error registrado en la sesión. No hay patrón repetido con sesiones anteriores (es la sesión 1, no hay historial previo). Recomendación para sesión 2: al indicar cualquier `run_all(only=N)`, verificar primero que las dependencias de pasos anteriores ya existen, o usar `from=1, to=N` por defecto salvo que se confirme lo contrario.
