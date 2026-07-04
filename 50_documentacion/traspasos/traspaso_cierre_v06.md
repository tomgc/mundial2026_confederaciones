# traspaso_cierre_v06.md

## 1. Identificación

Proyecto: mundial2026_confederaciones. Versión v06. Fecha: 2026-07-04.
Sesión 6, foco: P11/P17 verificados en producción, ampliación de
partidos destacados (2->5 por lado), P18 completo (12 variantes de
localía anfitrión x goles reforzado, equipo y confederación), y
diagnóstico de desfase de fuentes de datos. Entorno: R/Positron +
Claude Code. Archivos modificados: `31_ingesta_fuerza.R` (piso mínimo,
sesión previa, ya en v05), `33_motor_elo.R`, `39_reporte.R`,
`index.html`, `40_salidas/datos_interfaz.json`,
`40_salidas/variantes_equipos.json`,
`40_salidas/variantes_confederaciones.json`.

## 2. Resumen ejecutivo

Se verificó en navegador que P11 (piso mínimo OFC) y P17 (nota sedes
neutrales) funcionan correctamente en producción, tras un largo ciclo
de diagnóstico de datos fantasma (Argentina-España, Arabia Saudita-
España) que resultó ser causado por el fetch cayendo al `generarMock()`
interno cuando el archivo se abría con `file://` en vez de servidor
HTTP. Se amplió "Qué explica este resultado" de 2 a 5 partidos por
lado (positivos/negativos), con corrección de solapamiento en
confederaciones de universo chico (OFC). Se implementó P18 completo:
12 variantes del modelo (3 fuentes de fuerza x goles normal/agresivo x
localía sin/con bonus de país anfitrión), a nivel equipo y
confederación, con UI de checkboxes integrada al toggle existente.
Se detectó (no resuelto, bloqueado por fuentes externas) que
`openfootball/worldcup.json` y `thestatsapi.com` tienen desfase de al
menos 1 día en la publicación de resultados reales (partido Argentina-
Cabo Verde del 3 de julio, con tiempo extra, aún no reflejado en
ninguna fuente al cierre de esta sesión). Se rechazó explícitamente
ingresar el resultado a mano, por violar P15.

## 3. Estado al cierre

Qué funciona: pipeline completo verificado, P11/P17 confirmados
visualmente en producción (GitHub Pages), P18 con las 12 variantes
generadas y publicadas, control de calidad interno (variante
"fifa_normal_sin" coincide con el bloque canónico) sin alertas. Qué no
funciona: nada de código; bloqueo externo de datos (fuentes sin
actualizar resultado de ayer). Delta respecto a v05: partidos
destacados ahora 5+5 (antes 2+2); P18 agregado completo; JSON pasa de
~66K a ~180K.

## 4. Registro detallado de cambios

**Cambio 1:** verificación en producción de P11 y P17 (sin cambio de
código, solo confirmación visual tras varios ciclos de diagnóstico de
datos fantasma).

**Cambio 2 (diagnóstico extenso, causa raíz real):** datos fantasma
(Argentina-España, Arabia Saudita-España) reportados repetidamente.
Verificado en 3 capas del pipeline (CSV crudo vía curl a la fuente
real, `resultados_partidos.csv`, `historial_partidos.csv`,
`datos_interfaz.json` vía shasum) que el dato nunca fue el problema.
Causa raíz real: `index.html` abierto con protocolo `file://` (doble
clic) en vez de `http://localhost:8000`, lo que hace fallar el
`fetch()` y activa el `generarMock()` interno de respaldo, que sí
contiene datos de ejemplo con esos partidos. Confirmado con el flag
"Datos de ejemplo (MOCK)" visible en pantalla. Resuelto sirviendo con
`python3 -m http.server`.

**Cambio 3:** `index.html`, `partidosDestacadosConf()` ampliado de
`slice(0,2)` a `slice(0,N_PARTIDOS_DESTACADOS)` con
`N_PARTIDOS_DESTACADOS <- 5` (constante nombrada, política 5.3.10).

**Cambio 4 (fix, mismo ciclo):** corrección de solapamiento cuando el
universo de partidos inter-confederación es chico (caso OFC, 3
partidos totales): tope dinámico
`Math.min(N_PARTIDOS_DESTACADOS, Math.floor(partidos.length/2))`, con
`negativos` filtrado explícitamente contra `positivos` para evitar
duplicados.

**Cambio 5 (P18, motor):** `33_motor_elo.R` extendido con:
- Constantes `CODIGOS_ANFITRION <- c("USA","MEX","CAN")`,
  `BONUS_ANFITRION <- 50`, `FACTOR_GOLES_AGRESIVO_MULT <- 2`,
  `COLUMNAS_FUERZA_VARIANTES`.
- Funciones `factor_goles_agresivo()`, `expectativa_con_anfitrion()`.
- `simular_confederaciones()` generalizada con parámetros
  `fn_expectativa`/`fn_goles` inyectables (retrocompatible: llamada sin
  esos parámetros reproduce el comportamiento original).
- Nueva función `simular_equipos_completo()`: extracción generalizada
  del bucle canónico (incluye `rank_post` histórico por snapshot
  temporal), parametrizada igual.
- Bucle de 12 combinaciones (3 fuentes x 2 goles x 2 localía),
  generando `variantes_equipos`/`variantes_conf` como listas nombradas.
- Control de calidad: la variante "fuente activa + normal + sin
  anfitrión" se compara contra el bloque canónico; WARN si difiere en
  más de 1e-6 (no debería, es la misma lógica).
- Nuevas salidas: `40_salidas/variantes_equipos.json`,
  `40_salidas/variantes_confederaciones.json`.
- Bloque canónico (historial_partidos, rating_equipos originales) sin
  modificar.

**Cambio 6 (P18, reporte):** `39_reporte.R` lee ambos JSON de
variantes y los agrega al contrato final como `variantes_equipos`/
`variantes_confederaciones`, sin tocar el contrato existente.
Validaciones nuevas: 12 claves en ambos, claves coincidentes entre
equipos y confederaciones.

**Cambio 7 (P18, UI):** `index.html`:
- Checkboxes "Goles reforzados" y "Bonus anfitrión" integrados al
  mismo contenedor visual `.toggle-fuerza` (junto a FIFA/Compuesto/
  Elo), con separador visual.
- `claveVarianteActiva()`, `hayVarianteActiva()`, `confsActivas()`
  (bifurca a variantes o al contrato base), `confsActivasBase()`.
- `partidosDestacadosConf()` retorna vacío cuando hay variante activa
  (el JSON de variantes no tiene detalle por partido, solo agregado).
- `pintarPanelMetodo()` agrega texto explicativo de cada variante
  activa y aviso de que "Qué explica este resultado" no está
  disponible bajo variantes.
- Reestructuración de layout: `.card-barras-cab` en bloque simple
  (título/descripción apilados), `.toggle-fuerza-wrap` centra el grupo
  de controles en fila propia debajo, con más padding.
- `.barras-layout` (grid 2 columnas) eliminado: `panel-metodo` ahora a
  ancho completo debajo del gráfico, no en columna lateral de 260px
  (pedido explícito del usuario, el layout lateral deformaba la
  sección con el texto de variantes).

**Cambio 8 (housekeeping, hallazgo crítico):** el commit `9a56162`
(integración de P18 en `39_reporte.R`) no incluyó el `datos_interfaz.json`
regenerado ni los 2 JSON de variantes nuevos. `git status` reveló
`datos_interfaz.json` modificado sin commitear varias interacciones
después de "confirmar" el push. Corregido en commit `377d163`.

**Diagnóstico (sin resolución en esta sesión, bloqueo externo):**
verificado con `curl` que `openfootball/worldcup.json` no tiene
`score` para partidos del 3-4 de julio (incluido Argentina-Cabo Verde,
ya jugado con resultado real 1-1/3-2 en tiempo extra, según el
usuario). `thestatsapi.com/fixtures.csv` tampoco tiene ese partido.
Desfase de al menos 1 día confirmado en ambas fuentes. Usuario propuso
ingresar el resultado a mano; rechazado por violar P15 (permanente,
sin excepciones). Adicionalmente, el formato de tiempo extra (90
minutos vs. global) no está contemplado en el contrato de datos actual
(`gf`/`gc` sin distinción de prórroga), lo que habría requerido
decisión de diseño formal antes de cualquier ingreso, agravando el
riesgo de hacerlo a mano.

## 5. Backlog acumulativo

Ver `50_documentacion/activa/backlog_acumulativo.md`. Delta de esta
sesión (pendiente de incorporar en la próxima apertura, antes de
trabajo nuevo): +8 cambios (verificación P11/P17, diagnóstico mock,
ampliación partidos destacados, fix solapamiento OFC, P18 motor, P18
reporte, P18 UI, housekeeping JSON sin commitear).

## 6. Bugs de la sesión

**Bug 1 (causa raíz real de "datos fantasma", múltiples reportes):**
`index.html` abierto con `file://` cae al `generarMock()` interno sin
mostrar error visible más allá de un pequeño badge "Datos de ejemplo
(MOCK)" fácil de pasar por alto. Regla aprendida: ante datos
incorrectos en navegador que no calzan con ningún CSV/JSON verificado
del pipeline, revisar primero cómo se abrió el archivo (protocolo
`file://` vs. `http://`) antes de sospechar del código o de los
datos. Resuelto.

**Bug 2 (housekeeping, hallazgo propio):** commit de código de P18
(`39_reporte.R`) sin el dato regenerado que ese código produce
(`datos_interfaz.json` con variantes). Patrón: cuando un cambio de
código modifica una salida de datos, el commit del código y el commit
del dato regenerado deben verificarse juntos con `git status` antes de
dar por cerrado el push, no asumir que "ya está" porque el commit
anterior de código se hizo. Resuelto.

## 7. Aprendizajes y restricciones descubiertas

- **Regla nueva:** ante datos incorrectos visibles solo en navegador,
  el orden de diagnóstico es: (1) protocolo de apertura del archivo
  (`file://` vs. servidor HTTP), (2) procesos servidor zombie
  (`lsof`), (3) shasum/contenido real del JSON en las 3 capas del
  pipeline, en ese orden de costo creciente.
- **Regla nueva:** tras cualquier commit de código que module la
  generación de un archivo de datos, correr `git status` sobre ese
  archivo de datos antes de considerar el trabajo terminado. No asumir
  que "ya se commiteó" solo porque el flujo normal lo sugiere.
- **Restricción reafirmada (P15):** ningún dato ingresado a mano, sin
  excepción, incluso cuando el usuario lo ofrece directamente y las
  fuentes automatizadas tienen desfase confirmado. La solución ante
  desfase es esperar la fuente, no sustituirla.
- **Hallazgo nuevo, no resuelto:** el contrato de datos actual no
  distingue resultado en 90 minutos de resultado en tiempo extra/
  penales. Si el proyecto necesita capturar eso en el futuro (algunos
  partidos de eliminación ya lo requieren), es una decisión de diseño
  pendiente, no autónoma.

## 8. Decisiones de diseño

**Decisión 1 (P18, alcance):** las 12 variantes incluyen `rank_post`
histórico completo por snapshot temporal (no una versión reducida sin
esa reconstrucción), tras corrección explícita del usuario: "prioridad
es rigurosidad y alcance, no comodidad". Alternativa descartada:
versión simplificada sin rank histórico, propuesta inicialmente por
Claude y rechazada.

**Decisión 2 (P18, exposición UI):** modelos separados (checkboxes
independientes, combinables entre sí: 3 fuentes x 2 goles x 2 localía
= 12 combinaciones), no fusión en un solo control. El trabajo pesado
se hace en R y se sirve estático; sin problema de rigurosidad al
combinar, según aclaración explícita del usuario tras objeción inicial
mal fundada de Claude.

**Decisión 3 (P18, detalle por partido):** las 12 variantes no
incluyen `historial` por partido en el JSON (solo agregado de
equipo/confederación). "Qué explica este resultado" se oculta bajo
variante activa. Alternativa no explorada: generar historial completo
también para las 12 variantes (aumentaría significativamente el
tamaño del JSON); queda como posible ampliación futura si se solicita.

**Decisión 4 (layout UI):** panel de metodología a ancho completo
debajo del gráfico, no en columna lateral. Alternativa descartada:
mantener el grid de 2 columnas con el panel lateral de 260px
(deformaba la sección al crecer el texto con las variantes activas).

## 9. Constantes y parámetros vigentes

| Constante | Valor | Archivo | Nota |
|---|---|---|---|
| `PISO_FUERZA_PCTL` | 0.05 | `31_ingesta_fuerza.R` | Sin cambios (v05) |
| `CODIGOS_ANFITRION` | c("USA","MEX","CAN") | `33_motor_elo.R` | Nueva (P18) |
| `BONUS_ANFITRION` | 50 | `33_motor_elo.R` | Nueva (P18) |
| `FACTOR_GOLES_AGRESIVO_MULT` | 2 | `33_motor_elo.R` | Nueva (P18) |
| `N_PARTIDOS_DESTACADOS` | 5 | `index.html` | Nueva (antes 2, número mágico) |
| `FUENTE_FUERZA` | "fifa" | `31_ingesta_fuerza.R` | Sin cambios |

## 10. Arquitectura de archivos

Nuevos: `40_salidas/variantes_equipos.json`,
`40_salidas/variantes_confederaciones.json`. Sin cambios
estructurales de carpetas. Escáner no re-ejecutado en esta sesión:
ejecutar antes de la próxima apertura.

## 11. Pendientes y ruta sugerida

**P16 (heredado de v04/v05, sin cambios):** evaluar tercera fuente de
score o aceptar validación actual.

**P12 (heredado, sin cambios):** `case_when()` deprecado en
`31_ingesta_fuerza.R`, warning no bloqueante.

**P19 (nuevo):** actualizar datos con resultados recientes cuando
`openfootball`/`thestatsapi` publiquen el partido Argentina-Cabo Verde
(3 de julio) y los siguientes. Bloqueante externo, no accionable hasta
que las fuentes actualicen.

**P20 (nuevo, decisión pendiente):** el contrato de datos no distingue
90 minutos de tiempo extra/penales. Evaluar si el proyecto necesita
capturarlo (afecta partidos de eliminación con empate en el marcador
regular).

**Housekeeping (heredado de v05, sin cambios):** actualizar
`20260703_decision_ofc_rating_inicial_cero.md` para reflejar que P11
está resuelto, no pendiente.

### Auditoría de cierre (política 5.6)

| Pregunta | Respuesta |
|---|---|
| ¿Pipeline corre de cero sin intervención manual? | Sí, verificado |
| ¿Cada transformación crítica tiene check de validación? | Sí, P18 agrega control de calidad propio |
| ¿Outputs reproducibles e idempotentes? | Sí |
| ¿Decisiones metodológicas como constantes nombradas? | Sí (4 constantes nuevas) |
| ¿Nombres sin tildes/ñ/espacios? | Sí |

### Ruta sugerida próxima sesión

1. Verificar si `openfootball`/`thestatsapi` ya publicaron Argentina-
   Cabo Verde y partidos posteriores; correr `run_all()` si sí (P19).
2. Housekeeping: actualizar decisión OFC.
3. P20: decidir si se captura tiempo extra/penales en el contrato.
4. P16, P12: pendientes de menor prioridad.

## 12. Instrucciones específicas para la próxima sesión

- 🔒 Prohibido usar datos ficticios/sintéticos o ingresados a mano,
  sin excepción (P15, permanente, reafirmado explícitamente esta
  sesión pese a oferta directa del usuario).
- ⚠️ NO declarar tarea de UI completa sin verificar en `datos_interfaz.json`
  publicado, y verificar con `git status` que el JSON regenerado esté
  commiteado (Bug 2, esta sesión).
- 🔒 `FUENTE_FUERZA <- "fifa"` en producción.
- ✅ ANTES de invocar `run_all()`, correr `source(here::here("00_run_all.R"))`.
- ✅ ANTES de diagnosticar datos incorrectos en navegador, verificar
  primero el protocolo de apertura (`file://` vs. servidor HTTP): fue
  la causa raíz real de un ciclo largo de diagnóstico esta sesión
  (Bug 1).
- ✅ Tras cualquier commit de código que regenere datos, correr
  `git status` sobre el archivo de datos antes de dar el push por
  completo.

## 13. Fragmentos de código de referencia

Bonus de localía de país anfitrión (P18):

```r
CODIGOS_ANFITRION <- c("USA", "MEX", "CAN")
BONUS_ANFITRION <- 50

expectativa_con_anfitrion <- function(r_propio, r_rival, codigo_propio, codigo_rival) {
  r_propio_ajustado <- r_propio + ifelse(codigo_propio %in% CODIGOS_ANFITRION, BONUS_ANFITRION, 0)
  r_rival_ajustado  <- r_rival  + ifelse(codigo_rival  %in% CODIGOS_ANFITRION, BONUS_ANFITRION, 0)
  1 / (1 + 10^((r_rival_ajustado - r_propio_ajustado) / BASE_LOGISTICA))
}
```

Clave combinada de variante activa (UI):

```javascript
function claveVarianteActiva(){
  return `${FUENTE_GRAFICO}_${GOLES_AGRESIVO?"agresivo":"normal"}_${LOCALIA_ANFITRION?"con":"sin"}`;
}
```

## 14. Reapertura

**Nombre del chat:** mundial2026_confederaciones, sesión 7 (Claude
Sonnet 5).

**Mensaje de apertura pre-armado:**
"Tipo CONTINUATION. El protocolo (POLITICA_PROYECTO.md +
SETTINGS_Y_PROMPTS_OPERACIONALES.md) vive en la knowledge base del
Project y se lee desde ahí. Adjunto el traspaso de la sesión anterior
y el escáner más reciente (re-ejecutar antes de adjuntar)."

**Documentos para la próxima sesión:**

1. *Protocolo en knowledge base* (verificar que esté al día, no
   adjuntar): `POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
2. *Opcionales según foco*: ninguno aplica para P19/P20/P16/P12.
3. *Específicos de la sesión* (adjuntar):
   - `traspaso_cierre_v06.md` (este documento)
   - `estructura_actual.md` (**re-ejecutar el escáner antes de
     adjuntar**: no se corrió en esta sesión)

**Nota final obligatoria:** verificar antes de la próxima sesión si
`openfootball`/`thestatsapi` ya publicaron el resultado de Argentina-
Cabo Verde (3 de julio); si sí, correr `run_all()` completo como
primer paso de la sesión, antes de cualquier otra tarea.

## 15. Errores del asistente

| momento | disparador | que_paso | regla_violada | causa_raiz | salvaguarda_presente | patron |
|---|---|---|---|---|---|---|
| Al pedir commit tras formalizar P15 | Usuario lo corrigió | Entregué comandos `cp` (tarea mecánica) y sin ruta completa | userPreferences (Autonomy, Mechanical tasks) y userPreferences (Code edits, full path) | No recontrasté contra preferencia explícita ya conocida antes de generar el bloque | userPreferences | variante del patrón ya registrado en v02 |
| Al mezclar el .gitignore con el commit de la decisión | Asistente lo señaló espontáneamente | El primer commit de housekeeping quedó mezclado con el archivo de decisión pese a intentar separarlos en 3 commits | POLITICA §2 (un cambio conceptual por commit) | Construí los 3 bloques de `git add` sin verificar overlap entre ellos | POLITICA §2 | nuevo |
| Al inspeccionar datos_interfaz.json con Python | Asistente lo señaló espontáneamente | Usé Python vía bash_tool en vez de evaluar R primero | userPreferences (Tooling, no-negotiable) | Asumí que R no estaba disponible sin verificarlo antes | userPreferences (Tooling) | tercera ocurrencia consecutiva (v03, v04, v05) |
| Tras resolver P17, al recibir confirmación visual | Usuario lo corrigió | Generé traspaso de cierre v05 sin instrucción de cerrar sesión | SETTINGS §1.2 y userPreferences (Autonomy) | Traté "pendiente técnico resuelto" como equivalente a "sesión debe cerrar" | userPreferences (Autonomy), SETTINGS §1.2 | segunda ocurrencia (v03 y v05) |
| Al diagnosticar datos fantasma repetidamente | Asistente lo señaló espontáneamente (tras varios ciclos) | Descarté la hipótesis de protocolo de apertura de archivo (file:// vs. http://) hasta muy tarde en el diagnóstico, priorizando revisión de código y datos ya verificados limpios | SETTINGS §1.2.6 (diagnosticar causa raíz antes de corregir; verificar lo más simple primero) | No apliqué orden de costo creciente en el diagnóstico: reviisé 3 capas de datos antes de preguntar cómo se abría el archivo | POLITICA §5.3.9 (resiliencia), SETTINGS §1.2.6 | nuevo |
| Al integrar P18 a 39_reporte.R | Usuario lo señaló sin nombrarlo error (via "no lo veo live") | Di el commit de 39_reporte.R por suficiente sin verificar que el datos_interfaz.json regenerado tambien se hubiera commiteado | POLITICA C.8 (validacion de integridad), SETTINGS §1.2.6 (no asumir estado sin verificar) | Asumi que el flujo commit-codigo -> commit-dato ya habia ocurrido sin correr git status de confirmacion | POLITICA C.8 | nuevo |
| Al proponer alcance reducido para P18 (sin rank_post historico) | Usuario lo corrigio explicitamente ("prioridad es rigurosidad y alcance, no comodidad") | Propuse reducir el alcance tecnico de las variantes por costo de implementacion, sin que el usuario lo hubiera pedido | userPreferences (Autonomy: no decidir por el usuario en asuntos de alcance/rigurosidad de un encargo explicito) | Prioricé menor esfuerzo de implementacion sobre el encargo explicito del usuario (alcance completo con rank_post) | userPreferences (Autonomy) | nuevo |
| Al objetar la propuesta de checkboxes combinables para P18 | Usuario lo corrigio ("cual es el problema? el trabajo pesado lo hacemos en r") | Presenté una objecion de "perdida de rigurosidad" sobre checkboxes combinables que no era tecnicamente valida (el calculo se hace en R, sirve estatico) | POLITICA §5.1 (pensar antes de codificar, supuestos explicitos) | No distingui entre complejidad de implementacion (real, menor) y perdida de rigurosidad (invalida, la combinatoria no compromete el calculo) | POLITICA §5.1 | nuevo |

**Análisis:** el error de Tooling (Python) alcanza su tercera ocurrencia
consecutiva (v03, v04, v05); la salvaguarda textual no es suficiente,
requiere mecanismo explícito de verificación (`which Rscript` antes de
cualquier inspección de datos). El error de cierre prematuro sin
instrucción alcanza su segunda ocurrencia (v03, v05); mismo diagnóstico:
la regla textual ("cierre requiere decisión explícita") no está
previniendo la inferencia de "trabajo terminado = cerrar sesión".
Ambos patrones deben marcarse para revisión de cartera si aparecen en
otros proyectos.
