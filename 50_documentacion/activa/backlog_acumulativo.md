# backlog_acumulativo.md

## Objetivo del proyecto

Modelo de comparación de desempeño de selecciones nacionales por
confederación en el Mundial 2026, tipo Elo/FIFA SUM, que mide
rendimiento observado vs. esperado (no solo rating absoluto) para
responder qué confederación tuvo mejor desempeño relativo a la fuerza
de sus equipos. Construido en R (Positron), con interfaz web estática
de archivo único (GitHub Pages). Para uso analítico personal del
usuario.

## Nota metodológica

Cuenta como "cambio" cada solicitud distinguible del usuario (una
decisión, una corrección, un nuevo requisito), no las acciones técnicas
que la implementan. No cuentan los errores del asistente corregidos de
inmediato en el mismo turno, antes de la primera entrega (autocorrección
silenciosa); sí cuentan los bugfixes que el usuario tuvo que señalar o
que quedaron documentados como tal en el traspaso. La clasificación es
por intención primaria del cambio, no por el archivo tocado. Fuentes del
conteo: `traspaso_cierre_v01.md` a `traspaso_cierre_v04.md`.

## Clasificación temática

| Categoría | N° | % | Descripción |
|---|---|---|---|
| Arquitectura/andamiaje | 1 | 2% | Inicialización Rama A completa (v01) |
| Diseño del modelo | 4 | 9% | G continuo, eliminar surprise_factor, jerarquía confederación, tabla de importancia por fase (v01) |
| Ingesta de datos | 6 | 14% | Maestro 48 equipos, snapshots FIFA/Elo, fuente única persistida (P8), reemplazo completo de fuente de resultados por datos reales (P14) |
| Bugs de código | 9 | 21% | `clave_nombre`, `.gitignore`, tolerancias de auditoría, columna inexistente, JSON no sincronizado en producción, `ga`/`gc`, orden de ejecución, comparación por texto crudo |
| Interfaz/diseño visual | 8 | 19% | Handoff Claude Design, integración, reordenamiento de gráfico, banner metodológico, toggle 3 fuentes, partidos destacados, ajustes de tabla/columnas, CSS de ícono |
| Infraestructura/deploy | 3 | 7% | Publicación GitHub, configuración Pages, resolución de lag de propagación |
| Reportería/contrato de datos | 3 | 7% | Implementación `39_reporte.R`, extensión a 3 fuentes de `delta_conf`, consistencia total de tarjeta por toggle |
| Auditoría y validación | 4 | 9% | Protocolo 4.5 completo, `stopifnot` de NA, investigación worldfootballR, validación cruzada por `codigo_fifa` |
| Gobernanza y decisiones permanentes | 3 | 7% | Excepción handoff (P5/P6), decisión OFC (P11), prohibición permanente de datos sintéticos (P15) |
| Housekeeping/documentación | 2 | 5% | Deuda de duplicación de archivos, backlog sin actualizar (meta) |

Taxonomía provisional (definida en v01), sin refinar aún en sesión
dedicada. Ninguna categoría supera el 25% ni cae bajo el 2% de forma
sostenida; sin acción de fusión/subdivisión requerida por ahora.

## Resumen estadístico por sesión

| Sesión | Traspasos generados | N° de cambios | Modelo | Foco |
|---|---|---|---|---|
| 1 | v01 | 17 | Claude (Sonnet) + Claude Code | Andamiaje + pipeline + interfaz |
| 2 | v02 | 3 | Claude (Sonnet) + Claude Code | `39_reporte.R`, datos reales en sitio |
| 3 | v03 | 12 | Claude Sonnet 5 + Claude Code | Pendientes v02, toggle 3 fuentes, banner metodológico |
| 4 | v04 | 11 | Claude Sonnet 5 + Claude Code | P13, partidos destacados x3 fuentes, reemplazo de dataset sintético (P14) |
| — | Refinamientos menores no atribuibles | 0 | — | — |
| **Total** | 4 traspasos | **43** | | |

## Detalle cronológico

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
14. Bugfix reportado indirectamente por el usuario (WARN de fase sin_clasificar) → corrección de `clave_nombre` (Bug 1, v01).
15. Pregunta de dominio del usuario sobre marcador (¿incluye penales?) → hallazgo de que el dataset no los expone.
16. Decisión de diseño: inferencia de avance en empates de eliminación, delegada a `33_motor_elo.R`.
17. Implementación de `33_motor_elo.R` con la inferencia de avance; corrección de error propio (dependencia de orden en `run_all(only=3)`, Error del asistente v01); reemplazo de Elo scraping por snapshot fijo verificado (screenshots del usuario); commit y push final de sesión 1.
18. Extracción del contrato de datos exacto directamente de `generarMock()` en `index.html`, en vez de asumirlo desde el traspaso v01 (sesión 2).
19. Identificación de insumos faltantes (`pos_fifa`, `puntos_fifa`, `elo`, `nombre`) mediante verificación cruzada de columnas antes de escribir el join (sesión 2).
20. Implementación de `39_reporte.R` completo: join de 6 CSV, transformación al contrato, `SEDE_DEFAULT` constante, `partido` recalculado como índice secuencial por equipo. Resuelve P1 de v01 (sesión 2).
21. Cierre de P8 (v02): `31_ingesta_fuerza.R` agrega columna `fuente_fuerza` persistida; `39_reporte.R` la lee de ahí, elimina riesgo de desincronización con `FUENTE_FUERZA_ACTUAL` (sesión 3).
22. Gráfico de confederaciones reordenado sobre las tarjetas en `index.html` (sesión 3).
23. Investigación de causa raíz de fallo de `worldfootballR`/FBref (P3): archivado por su dueño el 18-sep-2025; decisión del usuario de mantener intento con fallback sin cambio de código en ese momento (sesión 3).
24. Auditoría de cifras publicadas (protocolo 4.5, P2 de v01): 3 scripts nuevos (`91_auditoria_helpers.R`, `92_auditoria_orquestador.R`, `93_auditoria_spotcheck.R`), 4/4 familias OK, 5/5 checks OK (sesión 3).
25. `stopifnot` de NA agregado en `39_reporte.R` para `pos_fifa`/`puntos_fifa`/`elo`, cierra P10 de v02 (sesión 3).
26. Decisión permanente: excepción del handoff de Claude Design (`data/` duplicado, `support.js`) documentada como excepción análoga a `andamios/`, cierra P5/P6 (sesión 3).
27. Causa raíz de OFC documentada (P11, nuevo): rating inicial 0 con 1 solo equipo genera sorpresa máxima artificial; deuda técnica con dos alternativas propuestas, sin corrección de código (sesión 3).
28. Feature no solicitada como pendiente previo: toggle de 3 fuentes de fuerza (FIFA/Compuesto/Elo) sobre el gráfico de confederaciones, con simulación triplicada y panel metodológico (sesión 3).
29. Banner colapsable de metodología argumentativa, reemplaza footer placeholder; pestaña Metodología quitada de la navegación (sesión 3).
30. Sección "Qué explica este resultado" por tarjeta de confederación, derivada de `delta_conf` ya cargado (sesión 3).
31. Columnas numéricas de Rankings centradas, tabla sin límite de altura, orden default cambiado a ascendente por `#` (captura de usuario, sesión 3).
32. Pestaña Tokens quitada de la navegación, contenido preservado oculto en el DOM (captura de usuario, sesión 3).
33. Confirmación de push del último lote de `index.html` de sesión 3 (banner, ícono, partidos destacados, quitar tab Metodología), cierra P13 (sesión 4).
34. Extensión de partidos destacados por confederación a las 3 fuentes del toggle: captura de detalle por partido en `33_motor_elo.R` (`simular_confederaciones()` retorna `list(agregado, detalle)`), nuevos CSV `historial_partidos_compuesto.csv`/`historial_partidos_elo.csv` (sesión 4).
35. `39_reporte.R` agrega `delta_conf_compuesto`/`delta_conf_elo` a `historial[]` vía join por `codigo+rival+fase+gf+gc` (sesión 4).
36. `index.html`: toda la tarjeta de confederación (no solo partidos destacados) sigue el toggle activo; decisión explícita del usuario de consistencia total (sesión 4).
37. Detección de dataset de partidos sintético en producción por el usuario (Bug 3/v04, disparador de P14); instrucción permanente: prohibido usar datos ficticios en cualquier fuente futura del proyecto (P15, sesión 4).
38. Reemplazo completo de `32_ingesta_resultados.R`: fuente primaria `openfootball/worldcup.json` (real), validación cruzada `thestatsapi.com` por `codigo_fifa`, fallback de última instancia con warning explícito de posible dato sintético (Cambio 6, P14, sesión 4).
39. CSS del banner metodológico corregido (`justify-content`), ícono chevron pegado al texto tras feedback visual del usuario (sesión 4).
40. Sección de metodología del sitio reescrita parcialmente: analogía inicial, ejemplo numérico de sorpresa, comparativa ampliada de 4 a 6 métodos (sesión 4).
41. Resolución de lag de propagación de GitHub Pages (>10 min) con commit vacío forzando rebuild (sesión 4).
42. Bug de columna `ga`/`gc` en `33_motor_elo.R` corregido tras fallo de join (Bug 1, v04).
43. Bug de orden de ejecución en `validar_contra_thestatsapi()`/`mapear_codigo()` corregido (Bug 2, v04); falso positivo de validación cruzada por texto crudo resuelto comparando por `codigo_fifa` (Bug 4, v04).

## Delta del backlog

Primera generación del archivo (política §10, obligatorio desde el
segundo cierre; no se generó en v02 ni v03 pese a ser exigible desde
v02 — deuda ya registrada en v03 y v04, cerrada con este archivo).
43 entradas consolidadas desde v01 a v04. Taxonomía temática definida
por primera vez con 10 categorías (provisional, a refinar en sesión
dedicada si el proyecto lo amerita).
