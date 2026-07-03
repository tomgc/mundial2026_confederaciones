# backlog_acumulativo.md

## Objetivo del proyecto

Modelo de comparación de desempeño de selecciones nacionales por confederación en el Mundial 2026, tipo Elo/FIFA SUM, que mide rendimiento observado vs. esperado (no solo rating absoluto) para responder qué confederación tuvo mejor desempeño relativo a la fuerza de sus equipos. Construido en R (Positron), con interfaz web estática (GitHub Pages). Para uso analítico personal del usuario.

## Nota metodológica

Cuenta como "cambio" cada solicitud distinguible del usuario (una decisión, una corrección, un nuevo requisito), no las acciones técnicas que la implementan. No cuentan errores del asistente corregidos de inmediato en el mismo turno; sí cuentan los bugfixes que el usuario tuvo que señalar o que quedaron documentados como tal. Clasificación por intención primaria. Fuente del conteo: los traspasos de cierre (`traspaso_cierre_vNN.md`).

## Clasificación temática

| Categoría | N° | % | Descripción |
|---|---|---|---|
| Arquitectura/andamiaje | 1 | 5.6% | Inicialización Rama A completa |
| Diseño del modelo | 4 | 22.2% | G continuo, eliminar surprise_factor, jerarquía confederación, tabla de importancia por fase |
| Ingesta de datos | 5 | 27.8% | Maestro 48 equipos, FIFA snapshot, Elo snapshot (x2 iteraciones), resultados con fallback |
| Bugs de código | 2 | 11.1% | `clave_nombre` destruye dígitos (fase), `.gitignore` comentario inline |
| Interfaz/diseño visual | 3 | 16.7% | Prompt Claude Design, integración Claude Code, fuentes locales |
| Infraestructura/deploy | 2 | 11.1% | Publicación GitHub, configuración Pages |
| Reporte/integración de datos reales | 1 | 5.6% | Implementación de `39_reporte.R` (P1) |

18 cambios totales. Categorías bajo 2% o sobre 25%: ninguna en este cierre; sin acciones de fusión/subdivisión requeridas.

## Resumen estadístico por sesión

| Sesión | Traspasos generados | N° de cambios | Modelo | Foco |
|---|---|---|---|---|
| 1 | v01 | 17 | Claude (Sonnet, vía interfaz) + Claude Code | Andamiaje + pipeline completo + interfaz |
| 2 | v02 | 1 | Claude (Sonnet, vía interfaz) + Claude Code | Implementación de `39_reporte.R`, datos reales en el sitio |
| — | Refinamientos menores no atribuibles | 0 | — | — |

**Total: 18 cambios, 2 sesiones.**

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
14. Bugfix reportado indirectamente por el usuario (WARN de fase sin_clasificar) → corrección de `clave_nombre`.
15. Pregunta de dominio del usuario sobre marcador (¿incluye penales?) → hallazgo de que el dataset no los expone.
16. Decisión de diseño: inferencia de avance en empates de eliminación, delegada a `33_motor_elo.R`.
17. Implementación de `33_motor_elo.R` con la inferencia de avance; corrección de error propio (dependencia de orden en `run_all(only=3)`); reemplazo de Elo scraping por snapshot fijo verificado (screenshots del usuario); commit y push final de la sesión 1.

### Sesión 2

18. Implementación de `39_reporte.R` (P1 del traspaso v01): join de insumos crudos y salidas del motor para emitir `datos_interfaz.json`, resolviendo `sede` (constante placeholder), `rival_nombre`/`rival_confederacion` (join contra maestro) y `partido` (índice secuencial recalculado, no `id_partido` crudo); verificado en R real (NA=0 en campos críticos, conteo de historial=164) y en navegador (flag "Datos reales del pipeline"); commit `8eead90` pusheado.

## Delta del backlog

Respecto a v01 (backlog embebido en `traspaso_cierre_v01.md`): 1 entrada nueva (#18). Nueva categoría temática agregada: "Reporte/integración de datos reales" (antes no existía; nace con esta entrega). Sin reclasificaciones de entradas anteriores. Recuentos de porcentaje recalculados sobre el nuevo total de 18 (antes 17).
