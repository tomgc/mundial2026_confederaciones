# traspaso_cierre_v04.md

## 1. Identificación

Proyecto: mundial2026_confederaciones. Versión v04. Fecha: 2026-07-03.
Sesión 4, foco: resolver P13, extender partidos destacados a las 3 fuentes
del toggle, reemplazar dataset sintético por resultados reales (P14), y
mejorar metodología. Entorno: R/Positron + Claude Code. Archivos
principales modificados: `33_motor_elo.R`, `39_reporte.R`,
`32_ingesta_resultados.R`, `index.html`.

## 2. Resumen ejecutivo

Se resolvió P13 (push del banner metodológico pendiente de v03). Se
extendió la sección "Qué explica este resultado" para recalcularse bajo
las 3 fuentes del toggle (FIFA/Compuesto/Elo), requiriendo cambios en el
motor Elo (captura de detalle por partido, no solo agregado) y en el
reporte (nuevos campos `delta_conf_compuesto`/`delta_conf_elo` en
`historial[]`). Durante la verificación visual se detectó que el dataset
de partidos era sintético (`mominullptr/FIFA-World-Cup-2026-Dataset`), lo
cual el usuario calificó como inaceptable de forma explícita y permanente
("de aquí en adelante no podemos usar nunca más datos ficticios"). Se
reemplazó `32_ingesta_resultados.R` completo: fuente primaria pasa de
FBref/worldfootballR (archivado, inoperante) a `openfootball/worldcup.json`
(real, mantenido a mano, sincronizado con ESPN/FIFA), con validación
cruzada contra `thestatsapi.com/fixtures.csv` (por código FIFA, no texto
crudo) y fallback de última instancia con warning explícito de posible
dato sintético. Se corrigió la sección de metodología del sitio (más
didáctica: analogía inicial, ejemplo numérico de sorpresa, comparativa
ampliada de 4 a 6 métodos) y se corrigió la posición del ícono chevron del
banner (CSS `justify-content`). Se detectó y resolvió un problema de
propagación de GitHub Pages (10+ min de lag, resuelto con commit vacío
forzando rebuild). Pipeline verificado end-to-end con datos reales: 85
partidos, 6 confederaciones, 3 fuentes de `delta_conf` en producción.

## 3. Estado al cierre

Qué funciona: pipeline completo (32→39) corre con datos reales de
`openfootball/worldcup.json`, verificado en R real y en JSON publicado
(`grep -c delta_conf_compuesto`/`delta_conf_elo` = 1 en remoto). Toggle
FIFA/Compuesto/Elo con partidos destacados consistentes en las 3 fuentes,
verificado visualmente en producción. Metodología actualizada y pusheada.
Qué no funciona: nada reportado al cierre. Delta respecto a v03: dataset
de resultados 100% real (antes sintético); +2 campos por partido en JSON
(`delta_conf_compuesto`, `delta_conf_elo`); +2 CSV de salida
(`historial_partidos_compuesto.csv`, `historial_partidos_elo.csv`);
metodología con 6 tarjetas comparativas (antes 4).

## 4. Registro detallado de cambios

**Cambio 1 (P13):** push del último lote de `index.html` de v03 (banner,
ícono, partidos destacados, quitar tab Metodología) confirmado ya en
remoto al abrir esta sesión; sin acción adicional requerida.

**Cambio 2 (feature, partidos destacados x3 fuentes):**
`33_motor_elo.R`, función `simular_confederaciones()` extendida: además
del agregado por confederación, ahora captura detalle por partido
inter-confederación (`codigo`, `rival`, `fase`, `gf`, `gc`, `resultado`,
`delta_conf`) para las corridas Compuesto y Elo. Retorna
`list(agregado, detalle)`. Nuevas salidas:
`historial_partidos_compuesto.csv`, `historial_partidos_elo.csv`.

**Cambio 3 (feature, mismo):** `39_reporte.R` lee los 2 CSV nuevos, hace
join por `codigo+rival+fase+gf+gc` (bug corregido en sesión: primer intento
usó `ga`, columna que no existe; el nombre real es `gc`) contra
`historial_partidos.csv`, agrega `delta_conf_compuesto`/`delta_conf_elo`
a cada entrada de `historial[]`. `stopifnot` nuevo: ambos campos no-NA en
todo partido inter-confederación.

**Cambio 4 (feature, mismo):** `index.html`, `partidosDestacadosConf()`
lee `delta_conf_<fuente>` según `FUENTE_GRAFICO` (antes fijo a
`delta_conf`). Tarjeta completa de confederación refactorizada en
`pintarGridConf()` (antes fija a `DATOS.confederaciones`, ahora desde
`confsActivas()`): toda la tarjeta (rating, obs-esperado, transferencia
neta, partidos destacados) sigue el toggle, no solo el gráfico agregado.
Decisión explícita del usuario: consistencia total, no solo la sección
de partidos.

**Cambio 5 (bug crítico, P14 disparador):** dataset de resultados
(`resultados_partidos.csv`) confirmado sintético/ficticio por el usuario
al ver resultados que "no han pasado en este mundial". Origen: fallback
CC0 (`mominullptr/FIFA-World-Cup-2026-Dataset`) activo porque
`worldfootballR`/FBref (fuente primaria original) está archivado desde
sept-2025 (P3, ya documentado en v03) y siempre fallaba, cayendo siempre
al fallback.

**Cambio 6 (P14, reemplazo de arquitectura de fuente):**
`32_ingesta_resultados.R` reescrito completo. Fuente primaria:
`openfootball/worldcup.json` (raw.githubusercontent.com, CC0, mantenido a
mano por Gerald Bauer, sincronizado con ESPN/FIFA, sin API key).
Validación cruzada: `thestatsapi.com/world-cup/data/fixtures.csv`
(confirma existencia y equipos, no expone marcador gratis). Fallback de
última instancia: mismo CC0 anterior, ahora con `fuente_usada =
"fallback_cc0_sintetico"` y WARN explícito e inequívoco si se activa
("Los resultados publicados podrían NO ser reales").

**Cambio 7 (bug, mismo cambio):** parseo de `score$ft` en
`intentar_openfootball()`: primera versión asumía `score` como lista por
fila; shape real confirmado en R es data.frame con columna `ft`
lista-de-vectores (`NULL` si no jugado). Corregido con `vapply` sobre
`partidos_raw$score$ft` directo.

**Cambio 8 (bug, mismo cambio):** orden de definición roto:
`validar_contra_thestatsapi()` llamaba a `mapear_codigo()` antes de que
`maestro` existiera en el entorno. Reordenado: `ALIAS_CODIGO` y
`mapear_codigo()` definidos antes del flujo principal; `maestro` creado
antes de la llamada a la validación cruzada.

**Cambio 9 (bug, mismo cambio):** validación cruzada inicial comparaba
por texto crudo (nombre+fecha), con 38/85 falsos negativos por
desfase de zona horaria y nomenclatura distinta entre fuentes
(`czechia`/`czech republic`, `usa`/`united states`, etc.). Corregido a
comparación por `codigo_fifa` vía `mapear_codigo()`, reutilizando el
alias ya mantenido en vez de duplicar diccionario de nombres.

**Cambio 10 (UI, feedback visual del usuario):** CSS del banner
metodológico, `.banner-metodo summary`: `justify-content` cambiado de
`space-between` a `flex-start`; título sin `flex:1`. El ícono chevron
quedaba pegado al borde derecho, lejos del texto "Metodología"; ahora
queda inmediatamente después del texto.

**Cambio 11 (feature, contenido):** sección de metodología del sitio
reescrita parcialmente a partir de feedback del usuario (documento
externo de referencia). "Qué mide este modelo": agrega analogía inicial
(empate vs. goleada) y ejemplo numérico de cálculo de sorpresa (We=0.2
vs. We=0.8). Comparativa de métodos ampliada de 4 a 6 tarjetas (agrega
"Avance en llaves" y "Goles esperados acumulados / xG").

**Operación (sin cambio de código):** GitHub Pages mostró lag de
propagación de más de 10 minutos tras el push del Cambio 6-9
(`9855fb7`): `raw.githubusercontent.com` servía 86 líneas correctas,
`tomgc.github.io` servía 83 líneas de un commit distinto. Resuelto con
commit vacío (`a4c0361`) forzando rebuild.

## 5. Backlog acumulativo

`backlog_acumulativo.md` sigue sin actualizar desde v02 (deuda
estructural declarada en v03, no resuelta en esta sesión: el archivo
nunca fue adjuntado por el usuario). **Pendiente crítico para la próxima
sesión:** incorporar los cambios 1-12 de v03 y los cambios 1-11 de v04 al
archivo canónico antes de cualquier trabajo nuevo (regla estructural,
política §10, ya incumplida dos cierres consecutivos).

## 6. Bugs de la sesión

**Bug 1:** `33_motor_elo.R`, detalle de partidos inter-confederación
(Compuesto/Elo) usaba columna `ga`, inexistente; el nombre canónico ya en
uso en `historial_partidos.csv` es `gc`. Causa raíz: no verifiqué el
nombre real de columna en el código existente antes de escribir la tabla
nueva, pese a tenerlo disponible en el mismo archivo. Solución: renombrado
a `gc` en `33_motor_elo.R` y en el join de `39_reporte.R`. Resuelto.

**Bug 2:** `39_reporte.R`, orden de ejecución: `validar_contra_thestatsapi()`
(llamada desde el flujo principal) dependía de `mapear_codigo()`, definida
más abajo en el archivo original, y de `maestro`, creado después de la
llamada. Causa raíz: entregué código sin verificar el orden real de
ejecución antes de presentarlo. Solución: reordenado el archivo completo
(alias/función antes del flujo principal; `maestro` antes de la
validación). Resuelto, verificado en R real.

**Bug 3 (usuario, producción):** dataset de partidos ficticio en
producción, sin detectarse hasta que el usuario reconoció resultados que
no correspondían al torneo real. Causa raíz: `32_ingesta_resultados.R`
(heredado de sesiones anteriores) tenía como única fuente operativa un
fallback CC0 no verificado como real; nadie confirmó la naturaleza del
dataset hasta esta sesión. Patrón aprendido: cuando un pipeline depende
de una fuente externa con fallback silencioso, el fallback debe declarar
explícitamente su naturaleza (sintético vs. real) en cada corrida, no
solo en el nombre de la URL. Resuelto con Cambio 6 (P14).

**Bug 4 (falso positivo, no bloqueante):** validación cruzada
`thestatsapi` reportó 38/85 partidos sin calzar; causa no fue error de
dato sino comparación por texto crudo entre fuentes con nomenclatura
distinta. Resuelto con Cambio 9.

## 7. Aprendizajes y restricciones descubiertas

- **Regla nueva (crítica, instrucción explícita del usuario):** prohibido
  usar datos ficticios/sintéticos en el pipeline desde esta sesión en
  adelante, de forma permanente. Cualquier fuente de datos debe ser real
  y, en lo posible, validada contra 2-3 fuentes independientes. Aplica en
  particular a `resultados_partidos.csv` pero es un principio general del
  proyecto ahora.
- **Regla nueva:** cuando un pipeline tiene fuente primaria + fallback,
  el fallback debe declarar su naturaleza (real vs. potencialmente
  sintético) en el log de cada corrida donde se activa, no asumir que el
  nombre de la URL o un comentario en el código es suficiente advertencia.
- **Regla nueva:** al comparar entidades (equipos, partidos) entre dos
  fuentes de datos externas con nomenclatura propia, comparar por
  identificador canónico normalizado (`codigo_fifa`), nunca por texto
  crudo con matching de string. Evita falsos negativos por variantes de
  nombre legítimas entre fuentes.
- **Regla reforzada:** antes de escribir código que reutiliza el nombre
  de una columna ya existente en el proyecto, verificar el nombre real en
  el archivo fuente, no asumirlo por convención genérica (Bug 1: `ga` vs
  `gc`).
- **Regla reforzada:** verificar el orden de ejecución real (qué variable
  existe en qué punto del script) antes de entregar código, no solo la
  sintaxis (Bug 2).
- **Aprendizaje operativo (no de código):** GitHub Pages puede tener lag
  de propagación superior a los ~2 min típicos (en esta sesión, >10 min);
  cuando el contenido servido no coincide con el commit en
  `raw.githubusercontent.com`, un commit vacío fuerza rebuild y resuelve
  sin necesidad de investigar más.

## 8. Decisiones de diseño

**Decisión 1:** shape de `delta_conf` en las 3 fuentes: campos extra en
el mismo array `historial[]` (`delta_conf_compuesto`, `delta_conf_elo`),
no arrays paralelos separados por fuente. Alternativa descartada: 3
arrays independientes. Justificación: evita join client-side por
`id_partido` y mantiene el contrato existente casi intacto.

**Decisión 2:** al cambiar el toggle, toda la tarjeta de confederación
se recalcula (rating, obs-esperado, transferencia neta, partidos
destacados), no solo la sección de partidos. Alternativa descartada:
solo partidos destacados. Justificación: consistencia total, decisión
explícita del usuario tras pregunta directa.

**Decisión 3 (P14, arquitectura de fuente de datos):** fuente primaria
`openfootball/worldcup.json`; validación cruzada `thestatsapi.com`
(fixtures, sin marcador); fallback de última instancia con warning
explícito. Alternativas evaluadas: CSV manual del usuario (descartada,
usuario no quiere ingresar datos a mano); scraping FBref/retomar P3
(descartada, FBref inoperante confirmado); solo openfootball sin segunda
fuente (descartada, usuario pidió explícitamente 2-3 fuentes).
Limitación aceptada: no existe fuente gratuita con marcador real para
comparación de doble-fuente del dato más crítico (`gf`/`gc`); solo hay
una fuente de score (openfootball) y una de existencia/calendario
(thestatsapi). Pendiente para sesión futura: evaluar tercera fuente con
score si aparece una opción gratuita.

**Decisión 4:** comparación de validación cruzada por `codigo_fifa`
(reutilizando `mapear_codigo()`), no por texto crudo ni por fecha.
Alternativa descartada: comparar por fecha+nombre (generaba falsos
negativos por desfase de zona horaria UTC vs. local).

## 9. Constantes y parámetros vigentes

| Constante | Valor | Archivo | Nota |
|---|---|---|---|
| `FUENTE_FUERZA` | "fifa" | `31_ingesta_fuerza.R` | Sin cambios |
| `URL_OPENFOOTBALL` | raw.githubusercontent.com/openfootball/worldcup.json/master/2026/worldcup.json | `32_ingesta_resultados.R` | Nueva, fuente primaria real (Cambio 6) |
| `URL_THESTATSAPI` | thestatsapi.com/world-cup/data/fixtures.csv | `32_ingesta_resultados.R` | Nueva, validación cruzada (Cambio 6) |
| `URL_FALLBACK_CC0` | mominullptr/FIFA-World-Cup-2026-Dataset | `32_ingesta_resultados.R` | Reclasificada: fallback de última instancia, posible sintético |
| `ALIAS_CODIGO` | 20 entradas | `32_ingesta_resultados.R` | +2 entradas (bosnia herzegovina sin "and") |
| `PESO_TRANSFERENCIA_CONF` | 0.15 | `33_motor_elo.R` | Sin cambios |

## 10. Arquitectura de archivos

Nuevos outputs: `historial_partidos_compuesto.csv`,
`historial_partidos_elo.csv` (`40_salidas/`). `32_ingesta_resultados.R`
reescrito completo (mismo nombre, misma ubicación). Sin cambios
estructurales de carpetas. Pendiente: `90_simulacion_elo.R` sigue sin
`.gitignore` (deuda heredada de v03, no resuelta esta sesión). Escáner
no re-ejecutado en esta sesión: **ejecutar antes de la próxima apertura**.

## 11. Pendientes y ruta sugerida

**P15 (nuevo, crítico, instrucción permanente del usuario):** ninguna
fuente de datos futura puede ser sintética. Validar con 2-3 fuentes
independientes cuando sea posible. Aplica no solo a resultados de
partidos sino a cualquier insumo nuevo que se incorpore al proyecto en
el futuro. Tipo: principio de gobernanza de datos, no bug puntual.
Complejidad: N/A (es una restricción permanente, no una tarea). Acción
para la próxima sesión: al iniciar, confirmar que este principio quedó
correctamente incorporado a `POLITICA_PROYECTO.md` o a un documento de
decisión formal (`50_documentacion/activa/decisiones/`), no solo en este
traspaso.

**P16 (nuevo, no bloqueante):** no existe fuente gratuita de doble
validación para el marcador real de los partidos (`gf`/`gc`); solo hay
una fuente de score (openfootball). Evaluar si vale la pena buscar una
tercera fuente pagada o si el nivel actual de validación (1 fuente de
score + 1 de existencia/calendario) es aceptable como política
permanente. Tipo: deuda técnica / decisión pendiente. Complejidad: baja
(es una decisión, no una implementación).

**Backlog sin actualizar (heredado de v03, agravado):** `backlog_acumulativo.md`
lleva dos cierres sin actualizarse. Debe resolverse en la próxima
apertura antes de cualquier trabajo nuevo, incorporando los cambios de
v03 (12 cambios) y v04 (11 cambios).

**P11 (heredado de v03, sin cambios):** OFC, rating inicial 0. Deuda
técnica, complejidad baja-media, sin decisión tomada esta sesión.

**P12 (heredado de v03, sin cambios):** `case_when()` deprecado en
`31_ingesta_fuerza.R`, warning no bloqueante.

**Housekeeping sin commitear:** `90_simulacion_elo.R` (falta
`.gitignore`), snapshots de escáner nuevos/borrados sin resolver.

### Auditoría de cierre (política 5.6)

| Pregunta | Respuesta |
|---|---|
| ¿Pipeline corre de cero sin intervención manual? | Sí, verificado (`run_all(from=3, to=5)` con datos reales) |
| ¿Cada transformación crítica tiene check de validación? | Sí (`stopifnot` nuevo en `39_reporte.R` para delta_conf_compuesto/elo) |
| ¿Outputs reproducibles e idempotentes? | Sí, escritura atómica sin cambios |
| ¿Decisiones metodológicas como constantes nombradas? | Sí |
| ¿Nombres sin tildes/ñ/espacios? | Sí |

### Ruta sugerida próxima sesión

1. **Backlog** (crítico, dos sesiones de atraso): actualizar
   `backlog_acumulativo.md` con cambios de v03 y v04 antes de cualquier
   trabajo nuevo.
2. **P15**: formalizar el principio de no-datos-sintéticos en
   `POLITICA_PROYECTO.md` o documento de decisión.
3. **P11**: decidir piso mínimo vs. renormalización para OFC.
4. **P16**: decidir si se busca tercera fuente de score o se acepta el
   nivel actual de validación.
5. **P12**: reemplazar `case_when()` deprecado (baja prioridad).

## 12. Instrucciones específicas para la próxima sesión

- 🔒 Prohibido usar datos ficticios/sintéticos en cualquier fuente nueva
  del proyecto, de forma permanente (instrucción explícita del usuario,
  P15).
- ⚠️ NO declarar una tarea de UI completa sin verificar el campo
  correspondiente en `datos_interfaz.json` publicado (regla heredada de
  v03, sigue vigente).
- 🔒 `FUENTE_FUERZA <- "fifa"` en producción; no cambiar sin decisión
  explícita del usuario.
- ✅ ANTES de invocar `run_all()`, correr
  `source(here::here("00_run_all.R"))` en la sesión de R.
- ✅ ANTES de escribir código que usa un nombre de columna ya existente
  en el proyecto, verificar el nombre real en el archivo fuente (Bug 1).
- ✅ ANTES de entregar código con funciones que dependen de variables
  creadas en otro punto del flujo, verificar el orden real de ejecución,
  no solo la sintaxis (Bug 2).
- ✅ ANTES de comparar entidades entre fuentes de datos externas,
  comparar por identificador canónico (`codigo_fifa`), no por texto
  crudo.

## 13. Fragmentos de código de referencia

Patrón de validación cruzada por identificador canónico (no texto
crudo), reutilizando el mapeo ya mantenido:

```r
validar_contra_thestatsapi <- function(partidos_openfootball) {
  tryCatch({
    fixtures <- readr::read_csv(URL_THESTATSAPI, show_col_types = FALSE) |>
      janitor::clean_names()
    cod_of  <- mapear_codigo(partidos_openfootball$local_nombre)
    cod_api <- mapear_codigo(fixtures$home_team)
    cod_of  <- cod_of[!is.na(cod_of)]
    cod_api <- cod_api[!is.na(cod_api)]
    n_solo_of  <- length(setdiff(cod_of, cod_api))
    n_solo_api <- length(setdiff(cod_api, cod_of))
    # ... log_msg segun resultado, nunca bloquea el pipeline
  }, error = function(e) {
    log_msg(paste("Validacion cruzada fallo (no bloquea):", conditionMessage(e)),
            "WARN", "32_resultados")
  })
}
```

Patrón de parseo de `score` desde `jsonlite::fromJSON(simplifyDataFrame=TRUE)`
cuando el campo puede ser `NULL` por fila (partido no jugado):

```r
raw <- jsonlite::fromJSON(URL_OPENFOOTBALL, simplifyDataFrame = TRUE)
partidos_raw <- raw$matches
ft_list <- partidos_raw$score$ft  # lista-de-vectores o NULL por elemento
tiene_score <- vapply(ft_list, function(x) !is.null(x) && length(x) == 2 && !anyNA(x), logical(1))
ft <- do.call(rbind, ft_list[tiene_score])
jugados <- partidos_raw[tiene_score, ]
```

## 14. Reapertura

**Nombre del chat:** mundial2026_confederaciones, sesión 5 (Claude
Sonnet 5).

**Mensaje de apertura pre-armado:**
"Tipo CONTINUATION. El protocolo (POLITICA_PROYECTO.md +
SETTINGS_Y_PROMPTS_OPERACIONALES.md) vive en la knowledge base del
Project y se lee desde ahí. Adjunto el traspaso de la sesión anterior y
el escáner más reciente (re-ejecutar antes de adjuntar)."

**Documentos para la próxima sesión:**

1. *Protocolo en knowledge base* (verificar que esté al día, no
   adjuntar): `POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
2. *Opcionales según foco*: ninguno aplica para backlog/P15/P11.
3. *Específicos de la sesión* (adjuntar):
   - `traspaso_cierre_v04.md` (este documento)
   - `estructura_actual.md` (**re-ejecutar el escáner antes de
     adjuntar**: no se corrió en esta sesión, el snapshot disponible es
     previo, del 2026-07-03 07:25:55)
   - `backlog_acumulativo.md` si existe ya localmente (para
     actualizarlo, punto 1 de la ruta sugerida; si no existe, el
     asistente debe crearlo con el historial completo de v03+v04)

**Nota final obligatoria:** el backlog acumulativo lleva dos cierres sin
actualizar (v03 y v04). Es la prioridad estructural de la próxima
apertura, antes de cualquier trabajo nuevo.

## 15. Errores del asistente

| momento | disparador | que_paso | regla_violada | causa_raiz | salvaguarda_presente | patron |
|---|---|---|---|---|---|---|
| Al pedir comando para correr pipeline | Asistente lo señaló espontáneamente | Entregué respuesta de ~200 palabras con estructura de resumen para una solicitud simple de comando | userPreferences, Brevity (techo 150 palabras default) | Inercia de responder con más contexto del pedido, en vez de dar solo el comando | userPreferences (Brevity) | nuevo |
| Al inspeccionar datos_interfaz.json | Asistente lo señaló espontáneamente | Sugerí y usé Python (`python3 -c`) para inspección de JSON, pese a la regla de que R es el único lenguaje | userPreferences, Tooling (no-negotiable, "never suggest Python even as alternative") | No evalué alternativa en R (`jsonlite::fromJSON`) antes de recurrir a Python por rapidez | userPreferences (Tooling) | variante del error de Tooling ya registrado en v03 (mismo patrón: usar Python en vez de R para inspección puntual) |
| Durante varias respuestas de la sesión (P14, debug de CDN) | Asistente lo señaló espontáneamente | Uso reiterado de negrita, encabezados y listas para comunicación operativa simple (updates de estado, confirmaciones) | userPreferences, Brevity (formato pesado no solicitado) | No adapté el formato a "prosa directa" una vez fijadas las preferencias explícitas del usuario a mitad de sesión | userPreferences (Brevity) | nuevo |
| Al escribir el detalle de partidos en 33_motor_elo.R | Asistente lo señaló espontáneamente | Usé columna `ga` en vez de `gc` (nombre canónico ya en uso en el archivo), causando fallo de join en 39_reporte.R | POLITICA §5.3.6 (rigor de nomenclatura, tipado consistente entre caché y recálculo) | No verifiqué el nombre real de columna en el código existente antes de escribir la tabla nueva | POLITICA §5.3.6 | nuevo |
| Al entregar validar_contra_thestatsapi() con dependencia de mapear_codigo() | Usuario lo corrigió (via error de ejecucion reportado) | Entregué código con orden de ejecución roto: función llamada antes de que sus dependencias (mapear_codigo, maestro) existieran en el entorno | SETTINGS §1.2.6 ("NUNCA modificar código sin haberlo leído primero" / verificación antes de declarar tarea lista) | No tracé el orden real de definición/ejecución antes de presentar el archivo como completo | SETTINGS §1.2.6, POLITICA B.4 | variante del error de v03 (Bug 3: declarar tarea completa sin verificar comportamiento real, no solo sintaxis) |
