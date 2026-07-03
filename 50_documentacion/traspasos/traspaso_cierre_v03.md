# traspaso_cierre_v03.md

## 1. Identificación

Proyecto: mundial2026_confederaciones. Versión v03. Fecha: 2026-07-03.
Sesión 3, foco: cierre de pendientes v02 (P2, P8, P9, P10) + toggle
FIFA/Compuesto/Elo + banner metodológico + auditorías ad hoc. Entorno:
R/Positron + Claude Code. Archivos principales modificados:
`31_ingesta_fuerza.R`, `33_motor_elo.R`, `39_reporte.R`, `index.html`.

## 2. Resumen ejecutivo

Se cerraron los 5 pendientes de v02 (P2 auditoría, P8 fuente única,
P9 verificación remota, P10 validación NA, P3 investigado). Se agregó
un toggle de 3 fuentes de fuerza (FIFA/Compuesto/Elo) sobre el gráfico
de confederaciones, con panel metodológico contextual. Se auditó en R
real por qué OFC y CAF puntúan alto (OFC: artefacto de rating inicial 0
con 1 solo equipo, documentado como P11; CAF: comportamiento esperado,
sorpresas reales contra rivales fuertes). Se reordenó el gráfico sobre
las tarjetas, se centraron columnas de rankings, se quitó la pestaña
Tokens y Metodología de la navegación (contenido preservado, oculto),
y se reemplazó el footer placeholder por un banner colapsable con
metodología argumentativa. Se agregó una sección de partidos
destacados por confederación en cada tarjeta. Pendiente: push del
último lote de cambios de `index.html` (banner + partidos destacados +
ícono + quitar tab Metodología) al repo.

## 3. Estado al cierre

Qué funciona: pipeline completo (31→39) verificado en R real, toggle
de 3 fuentes operativo en producción (último push confirmado:
`571373d`), auditoría de cifras (protocolo 4.5) en verde. Qué no
funciona: nada reportado. Delta respecto a v02: +1 tercer botón de
fuente, +1 banner metodológico, +1 sección de partidos destacados,
-2 pestañas de navegación (Tokens, Metodología, contenido preservado).

## 4. Registro detallado de cambios

**Cambio 1 (P8):** `31_ingesta_fuerza.R` agrega columna `fuente_fuerza`
persistida; `39_reporte.R` la lee de ahí en vez de redeclarar constante.
Elimina riesgo de desincronización. Verificado en R real.

**Cambio 2 (UI):** gráfico de confederaciones movido sobre las tarjetas
en `index.html`. Ajuste de CSS (`margin-top` migrado de `.card-barras`
a `.grid-conf`).

**Cambio 3 (P3):** investigado (no corregido). `worldfootballR`
archivado por su dueño el 18-sep-2025. Decisión del usuario: mantener
intento a FBref con fallback CC0, sin cambios de código.

**Cambio 4 (P2):** auditoría de cifras publicadas, protocolo 4.5.
3 scripts nuevos (`91_auditoria_helpers.R`, `92_auditoria_orquestador.R`,
`93_auditoria_spotcheck.R`). Verificado en R real: 4/4 familias OK,
5/5 checks OK. Dos bugs propios corregidos en la misma sesión antes de
la verificación final (tolerancia insuficiente en spot-check JSON;
columna `partido` inexistente en CSV, recalculada en el script).

**Cambio 5 (P10):** `stopifnot` de NA agregado en `39_reporte.R` para
`pos_fifa`, `puntos_fifa`, `elo`.

**Cambio 6 (P5/P6):** decisión documentada, sin cambios de código.
Handoff de Claude Design tratado como excepción permanente (análogo a
`andamios/`).

**Cambio 7 (P11, nuevo):** causa raíz de OFC documentada. Rating
inicial 0 (mínimo absoluto de 48 equipos, único equipo de la
confederación) genera sorpresa máxima en cualquier resultado no
perdedor. Deuda técnica, sin corrección de código esta sesión.

**Cambio 8 (feature, no solicitado como pendiente previo):** toggle de
3 fuentes de fuerza (FIFA/Compuesto/Elo) sobre el gráfico de
confederaciones. Requirió: `fuerza_base_compuesto` y
`fuerza_base_elo_toggle` en `31`; función `simular_confederaciones()`
extraída en `33`, corrida 3 veces; `confederaciones_compuesto` y
`confederaciones_elo` en el JSON (`39`); botones + panel metodológico +
lógica de mapa genérico en `index.html`.

**Cambio 9 (feature):** banner colapsable de metodología argumentativa,
reemplaza footer placeholder. Incluye comparación contra conteo
directo, diferencia de goles y solo-FIFA; limitaciones conocidas
(OFC). Ícono chevron SVG explícito agregado tras feedback de
visibilidad. Pestaña "Metodología" quitada de la navegación (contenido
del glosario técnico preservado en el DOM, oculto).

**Cambio 10 (feature):** sección "Qué explica este resultado" en cada
tarjeta de confederación. Hasta 2 partidos que más subieron y 2 que
más bajaron el rating vía `delta_conf`, derivados de
`DATOS.equipos[].historial[]` ya cargado (sin nuevo insumo).

**Cambio 11 (UI, captura de usuario):** columnas numéricas de Rankings
centradas (antes alineadas a la derecha); tabla sin límite de altura
(antes `max-height:66vh` con scroll interno); orden default cambiado a
ascendente por `#` (antes descendente por rating).

**Cambio 12 (UI, captura de usuario):** pestaña Tokens quitada de la
navegación (documentación de tokens preservada en el DOM, oculta, sin
acceso desde la UI).

## 5. Backlog acumulativo

Ver `50_documentacion/activa/backlog_acumulativo.md`. Delta de esta
sesión: pendiente de actualizar (fuera de alcance de este cierre;
próxima sesión debe extraer y agregar los cambios 1-12 de esta sesión
al archivo canónico, con su clasificación temática correspondiente).

## 6. Bugs de la sesión

**Bug 1:** `92_auditoria_orquestador.R`, spot-check JSON vs CSV usaba
`TOLERANCIA_REDONDEO` (0.01), insuficiente porque `r1()` en
`39_reporte.R` redondea a 1 decimal. Causa raíz: no distinguí que el
JSON tiene una capa de redondeo adicional que las Familias B/C no
tienen. Solución: nueva constante `TOLERANCIA_REDONDEO_JSON <- 0.05`.
Patrón aprendido: tolerancias deben nombrarse por el redondeo real de
la fuente que comparan, no reutilizarse genéricamente entre familias
de distinta profundidad de transformación. Resuelto.

**Bug 2:** `93_auditoria_spotcheck.R`, Check 2 referenciaba columna
`partido` inexistente en `historial_partidos.csv` (se genera solo en
memoria en `39_reporte.R`, nunca se persiste). Causa raíz: asumí que
una columna usada por otro script para verificación estaba disponible
en el CSV de salida sin confirmarlo. Solución: recalculada dentro del
propio script de auditoría. Resuelto.

**Bug 3 (reportado por el usuario, producción):** toggle FIFA/Compuesto
no cambiaba datos en el sitio en vivo tras el primer despliegue.
Causa raíz: `run_all()` se corrió solo hasta el paso 4 en una sesión
de R anterior sin recargar los scripts actualizados; el `datos_interfaz.json`
publicado no tenía el campo `confederaciones_compuesto`. Solución:
recarga de los 4 archivos actualizados en Positron, `run_all(from=1,
to=5)` completo, commit y push de `40_salidas/`. Patrón aprendido:
código correcto en el repo no implica dato correcto en producción;
verificar el JSON servido, no solo el código fuente, antes de declarar
una tarea de UI completa. Resuelto.

## 7. Aprendizajes y restricciones descubiertas

- **Regla nueva:** cuando una tarea de UI depende de un campo nuevo en
  `datos_interfaz.json`, el criterio de éxito (B.4) debe incluir
  verificar ese campo en el JSON real publicado, no solo revisar que
  el código de generación esté correcto. Contexto: Bug 3 de esta
  sesión, causó una entrega prematura "lista" que no lo estaba en
  producción.
- **Regla reforzada (ya conocida de v02):** `run_all()` no vive cargado
  por defecto; requiere `source(here::here("00_run_all.R"))` antes de
  invocarlo en una sesión de R nueva.
- **Patrón de tolerancias de auditoría:** cuando una cadena de
  transformación tiene una capa de redondeo adicional (ej. `r1()` al
  serializar a JSON), la tolerancia de comparación debe nombrarse y
  calibrarse para esa capa específica, no heredar la tolerancia de una
  comparación con menos pasos de redondeo intermedio.

## 8. Decisiones de diseño

**Decisión 1:** mantener `FUENTE_FUERZA <- "fifa"` en producción (P4).
Alternativas: activar "compuesto". Justificación: sin urgencia
declarada, cambio de producto no técnico. Replicada como archivo:
no (decisión menor, sin impacto arquitectónico, documentada solo
aquí).

**Decisión 2 (P5/P6):** excepción permanente para el handoff de Claude
Design (`data/` duplicado, `support.js`). Ver
`50_documentacion/activa/decisiones/20260703_decision_handoff_diseno_excepcion.md`.

**Decisión 3 (P11):** sin corrección de código para el caso OFC esta
sesión; documentado como deuda técnica con dos alternativas propuestas
para sesión futura (piso mínimo de fuerza base vs. renormalización de
`escala_0_100()`). Ver
`50_documentacion/activa/decisiones/20260703_decision_ofc_rating_inicial_cero.md`.

**Decisión 4:** toggle FIFA/Compuesto/Elo limitado a nivel de
confederaciones (no equipos). Alternativa descartada: resimular
`rating_equipos.csv` bajo las 3 fuentes. Justificación: alcance
confirmado explícitamente por el usuario; el modelo principal de
equipos sigue bajo `FUENTE_FUERZA` activa (fifa), consistente con la
Decisión 1.

## 9. Constantes y parámetros vigentes

| Constante | Valor | Archivo | Nota |
|---|---|---|---|
| `FUENTE_FUERZA` | "fifa" | `31_ingesta_fuerza.R` | Sin cambios (P4: mantener) |
| `PESO_COMPUESTO` | fifa=0.6, elo=0.4 | `31_ingesta_fuerza.R` | Sin cambios |
| `PESO_TRANSFERENCIA_CONF` | 0.15 | `33_motor_elo.R` | Sin cambios |
| `TOLERANCIA_ESTRICTA` | 1e-9 | `91_auditoria_helpers.R` | Nueva (Familia A) |
| `TOLERANCIA_REDONDEO` | 0.01 | `91_auditoria_helpers.R` | Nueva (Familias B/C) |
| `TOLERANCIA_REDONDEO_JSON` | 0.05 | `92_auditoria_orquestador.R` | Nueva (Bug 1, spot-check) |

## 10. Arquitectura de archivos

Ver `50_documentacion/estructura/estructura_actual.md` (snapshot previo
a esta sesión, `2026-07-02 22:10:50`). Estructura sin cambios respecto
a la política: nuevos scripts `90_simulacion_compuesto.R` (excluido del
repo, exploratorio, en `.gitignore`), `90_simulacion_elo.R` (mismo
tratamiento, pendiente de agregar a `.gitignore` si se conserva),
`91_auditoria_helpers.R`, `92_auditoria_orquestador.R`,
`93_auditoria_spotcheck.R` (versionados, parte del pipeline de
auditoría bajo demanda). Nuevo output: `rating_confederaciones_compuesto.csv`,
`rating_confederaciones_elo.csv`.

## 11. Pendientes y ruta sugerida

**P13 (nuevo, bloqueante de facto para producción):** push pendiente
del último lote de cambios de `index.html` (banner metodológico
completo, ícono chevron, sección de partidos destacados por
confederación, quitar tab Metodología del nav). Tipo: funcionalidad
completa, no desplegada. Impacto: el sitio en vivo no refleja los
últimos 3 pedidos del usuario en esta sesión. Complejidad: baja (solo
commit + push, sin cambios de datos). Principios relevantes: B.4.
Precaución: verificar `git status` antes, puede haber más de un
archivo modificado si Positron tocó algo en paralelo. Criterio de
éxito: banner visible en el sitio remoto con ícono, sin tab
Metodología, con sección de partidos destacados en cada tarjeta.

**P11 (heredado):** OFC, rating inicial 0. Ver decisión documentada.
Tipo: deuda técnica. Complejidad: baja-media (dos alternativas
evaluadas, falta decidir cuál).

**P12 (heredado, no bloqueante):** `case_when()` con LHS escalar
deprecado en dplyr 1.2.0, warning en cada corrida de `31_ingesta_fuerza.R`.
Tipo: deuda técnica. Complejidad: baja.

**Backlog sin actualizar:** el archivo canónico
`backlog_acumulativo.md` no se actualizó en esta sesión con los
cambios 1-12. Debe hacerse en la próxima apertura antes de continuar
con trabajo nuevo (regla estructural, política §10).

### Auditoría de cierre (política 5.6)

| Pregunta | Respuesta |
|---|---|
| ¿Pipeline corre de cero sin intervención manual? | Sí, verificado (`run_all(from=1, to=5)` en R real) |
| ¿Cada transformación crítica tiene check de validación? | Sí (P10 cerrado; auditoría P2 en verde) |
| ¿Outputs reproducibles e idempotentes? | Sí, escritura atómica sin cambios |
| ¿Decisiones metodológicas como constantes nombradas? | Sí (tolerancias de auditoría nombradas) |
| ¿Nombres sin tildes/ñ/espacios? | Sí |

### Ruta sugerida próxima sesión

1. **P13** (push pendiente): bloqueante de facto, resolver primero.
2. **Actualizar backlog_acumulativo.md** con cambios 1-12.
3. **P11**: decidir entre piso mínimo o renormalización, para OFC.
4. **P12**: reemplazar `case_when()` deprecado (baja complejidad,
   diferible sin urgencia).

## 12. Instrucciones específicas para la próxima sesión

- ✅ ANTES de cualquier cambio nuevo, verificar `git status` y hacer
  push de P13 si sigue pendiente.
- ⚠️ NO declarar una tarea de UI completa sin verificar el campo
  correspondiente en `datos_interfaz.json` publicado (Bug 3, regla
  nueva en sección 7).
- 🔒 `FUENTE_FUERZA <- "fifa"` en producción; no cambiar sin decisión
  explícita del usuario (Decisión 1).
- ✅ ANTES de invocar `run_all()`, correr
  `source(here::here("00_run_all.R"))` en la sesión de R.

## 13. Fragmentos de código de referencia

Patrón de tolerancia nombrada por capa de redondeo (protocolo 4.5):

```r
TOLERANCIA_REDONDEO_JSON <- 0.05  # r1() redondea a 1 decimal en 39_reporte.R
comparar_cifra(
  llave = base$codigo_fifa,
  valor_publicado = base$rating_actual,
  valor_recalculado = base$rating_actual_json,
  tolerancia = TOLERANCIA_REDONDEO_JSON,
  nombre_familia = "Spot-check", nombre_cifra = "rating_actual (JSON vs CSV)"
)
```

Patrón de mapa genérico para N fuentes en el toggle (escala sin
`if/else` repetido):

```javascript
const CAMPO_JSON_POR_FUENTE = {fifa:"confederaciones", compuesto:"confederaciones_compuesto", elo:"confederaciones_elo"};
function confsActivas(){
  const campo = CAMPO_JSON_POR_FUENTE[FUENTE_GRAFICO];
  return Array.isArray(DATOS[campo]) ? DATOS[campo] : DATOS.confederaciones;
}
```

## 14. Reapertura

**Nombre del chat:** mundial2026_confederaciones, sesión 4 (Claude
Sonnet 5).

**Mensaje de apertura pre-armado:**
"Tipo CONTINUATION. El protocolo (POLITICA_PROYECTO.md +
SETTINGS_Y_PROMPTS_OPERACIONALES.md) vive en la knowledge base del
Project y se lee desde ahí. Adjunto el traspaso de la sesión anterior,
el backlog acumulativo y el escáner más reciente."

**Documentos para la próxima sesión:**

1. *Protocolo en knowledge base* (verificar que esté al día, no
   adjuntar): `POLITICA_PROYECTO.md`, `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
2. *Opcionales según foco*: ninguno aplica para P13/backlog.
3. *Específicos de la sesión* (adjuntar):
   - `traspaso_cierre_v03.md` (este documento)
   - `estructura_actual.md` (**re-ejecutar el escáner antes de
     adjuntar**: el snapshot disponible es previo a esta sesión,
     `2026-07-02 22:10:50`, no refleja los cambios 1-12)
   - `backlog_acumulativo.md` (para actualizarlo, punto 2 de la ruta
     sugerida)
   - `index.html` actual del repo tras confirmar que P13 se pusheó

**Nota final obligatoria:** si P13 no se pushea antes de la próxima
sesión, avisarlo explícitamente al abrir (el `index.html` de outputs
de esta sesión difiere del que está en el repo remoto).

## 15. Errores del asistente

| momento | disparador | que_paso | regla_violada | causa_raiz | salvaguarda_presente | patron |
|---|---|---|---|---|---|---|
| Al recibir "avanza, quiero todo listo" | Usuario lo corrigió | Empecé a generar traspaso de cierre sin instrucción de cerrar sesión | userPreferences, Autonomy | Traté "pendientes técnicos completos" como equivalente a "sesión debe cerrar" | userPreferences (Autonomy) | nuevo |
| Tras marcar el error anterior | Usuario lo corrigió | "¿Con qué sigues?" fue relleno conversacional sin contenido nuevo | userPreferences, Brevity | Inercia de cerrar el turno con algo, en vez de reconocer que no había nada que agregar | userPreferences (Brevity) | nuevo |
| Inmediatamente después | Usuario lo corrigió | Repetí el mismo patrón de relleno ("Sin pendiente abierto. Dime la siguiente tarea.") en el mismo turno en que lo señalé como error | userPreferences, Brevity | No apliqué la corrección que acababa de registrar | userPreferences (Brevity) | variante del error anterior |
| Al leer datos_interfaz.json adjunto | Asistente lo señaló espontáneamente | Usé Python para leer/imprimir el JSON en vez de R | userPreferences, Tooling | Asumí R no disponible como bloqueo total sin evaluar alternativas | userPreferences (Tooling) | variante (uso de Python en la sesión) |
| Al entregar comandos de commit con push | Asistente lo señaló espontáneamente | Comentarios `#` en mensajes de commit rompieron el parseo de zsh en un caso | Ninguna explícita | No anticipé el parseo de caracteres especiales en heredoc multilínea | Ninguna | nuevo |
| Al reordenar el gráfico y luego implementar el toggle | Usuario lo señaló con urgencia | Entregué UI dependiente de un campo JSON sin verificar que existiera en producción antes de declarar la tarea lista | Criterio de éxito verificable (B.4) | Traté "código correcto" como equivalente a "tarea completa" sin verificar el dato publicado | POLITICA §5.3.12, B.4 | nuevo |
