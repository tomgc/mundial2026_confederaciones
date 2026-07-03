# SETTINGS_Y_PROMPTS_OPERACIONALES.md

> **Versión 10 (consolidada).** Vive permanentemente en la knowledge base
> del Project (y se copia a `50_documentacion/activa/` de cada proyecto).
> Absorbe y reemplaza a: `prompt-apertura-sesion.md` (v3),
> `prompt-cierre-sesion.md` (v4), `prompt_orquestador.md`,
> `prompt_migrar_estructura.md` (v2), `prompt_migracion_github_v2.md` y
> `prompt_portabilidad_cross_os.md`. La arquitectura que esos prompts
> implementaban vive ahora en `POLITICA_PROYECTO.md` v5; aquí viven los
> PROTOCOLOS de sesión y de operación.
>
> **Cambios respecto a v9 (tercera y última adopción del análisis
> comparativo con obra/superpowers,
> `mantenimiento/20260702_analisis_superpowers/informe_comparativo.md`,
> sección d, adopción #3):** §1.2.6, bajo "Bugs: causa raíz antes de
> corregir", suma un tercer sub-bullet de recepción de correcciones del
> titular (verificar contra el estado real antes de aplicar; sin agrado
> performativo, actuar). Cierra las tres adopciones aprobadas del informe.
>
> **Cambios respecto a v8 (dos adopciones del análisis comparativo con
> obra/superpowers, `mantenimiento/20260702_analisis_superpowers/informe_comparativo.md`,
> sección d):**
>
> *Adopción #2 (mecanismo de systematic-debugging, riesgo bajo):* §1.2.6,
> bajo "Bugs: causa raíz antes de corregir", suma dos sub-bullets de
> procedimiento que antes faltaban bajo un principio ya afirmado: escalada
> objetiva tras tres fixes fallidos (cortar y reportar "la arquitectura
> puede estar mal", activando la excepción de autonomía de POLITICA 0.3) e
> instrumentación por frontera en pipelines multi-etapa (loguear qué entra
> y sale en cada frontera antes de adivinar la capa que falla).
>
> *Adopción #1 (validación empírica de reglas, riesgo bajo-medio):* nueva
> §2.2.16 que, cuando §2.2.15 detecta un `patron` reincidente en 2+
> proyectos, obliga a clasificar la falla (disciplina / forma del output /
> omisión / condición ambigua) antes de reformular la regla, para elegir la
> forma correcta del arreglo (prohibición vs. receta positiva vs. campo
> obligatorio vs. condicional) en lugar de endurecer la prohibición por
> defecto. El micro-test empírico contra control queda declarado fuera de
> alcance (no hay infraestructura de testing de prompts hoy).
>
> **Cambios respecto a v7 (integra dos lotes de propuestas ya
> diagnosticadas, sesión BIBLIOTECA de integración editorial):**
>
> *Lote RP (rediseño de protocolos de apertura/cierre, evidencia:
> `01_diagnostico_protocolos.md`):* RP1 apertura consume `ESTADO.md` (paso
> 0 de 1.2.2) + nota de consumidores en 2.1bis. RP2 Fase A (1.2.2) con
> lectura dirigida por capas (traspaso siempre completo; POLITICA por
> versión/pertinencia; backlog por capas). RP3 Fase B (1.2.3) acuse delta
> (conteos + delta + vigentes; reproducción literal de ⚠️/✅/🔒 intacta).
> RP4 reapertura (2.2.14) sin bullet "Nombre del chat" (ajuste ya decidido
> por el titular), una sola copia dentro del traspaso, mensaje pre-armado
> con estado+foco. RP5 constantes por delta (2.2 punto 9). RP6 fragmentos
> solo nuevos o cambiados (2.2 punto 13). RP7 secciones-que-valen-por-su-
> vacío explicitadas + chequeo de extracción del backlog en el cierre
> (2.1).
>
> *Lote P (guardrails de la auditoría cruzada de errores del asistente,
> evidencia: `02_analisis_patrones.md`, 23 errores / 6 proyectos):* P1
> campo "Fuentes primarias consultadas" en el Plan compacto (1.2.5). P2
> seis reglas permanentes nuevas de sesión (1.2.6): fuente primaria
> (GR-01), sandwich generar-verificar-consumar (GR-02), ningún comando
> asume el entorno (GR-03), turno termina proponiendo + registro de
> autorizaciones (GR-04, dos reglas), entrega materializada con destino
> (GR-06). P6 traspaso siempre materializado como archivo (2.1). P7 campo
> `patron` contra catálogo `PAT-NN` + regla de formato de la tabla
> (2.2.15). P8 documento nuevo `catalogo_patrones_errores_v1.md` (fuera de
> este documento; referenciado desde 2.2.15).
>
> *Ajustes de criterio aplicados en la integración (A1-A4):* **A1**
> — las seis viñetas de P2 se verificaron ancladas a un momento
> observable del flujo (plan, secuencia de comandos, plantilla de
> encargo, fin de turno, entrega); ninguna viñeta se descartó, todas
> pasaron el test de anclaje. **A2** — el registro E-catdes-v26-2 se
> excluye de la evidencia fundacional de PAT-04 (formato no canónico,
> perdió 4 de 7 campos; PAT-04 cumple el umbral de recurrencia sin él,
> con los 3 errores de estado-v07); ese registro degradado se trata como
> lo que demuestra: un fallo de cumplimiento del propio 2.2.15, atacado
> por la regla de formato de P7. **A3** — P1 y P6 se priorizan como
> primeros guardrails de esta edición (P1 ancla PAT-01, el patrón más
> frecuente con 6 errores y doble reaparición tras registro; P6 es el
> único guardrail de conocimiento-ausente, riesgo mínimo de aprobar).
> **A4** — P7+P8 se tratan como parte integral del cierre del ciclo
> registrar-detectar-rediseñar (no como mejora opcional): sin un catálogo
> computable, el meta-hallazgo de reaparición transversal de patrones
> (2.2.15, consumo cruzado) no es detectable de forma sistemática.
>
> *Solapamiento resuelto:* 2.1 (generación del traspaso) recibía edición
> de RP7 (chequeo de extracción del backlog) y de P6 (traspaso siempre
> como archivo) sobre el mismo bloque; se integraron en una sola
> redacción coherente sin párrafos duplicados (ver 2.1 más abajo).
>
> *Descartado en esta edición:* nada de RP1-RP7 ni P1-P8 fue descartado;
> las ocho propuestas P y las siete RP quedan todas integradas. No
> surgieron necesidades no cubiertas por el material de los dos lotes.
>
> **Cambios respecto a v6:** nueva subsección 2.2.15 (Errores del
> asistente, registro obligatorio): tabla estructurada de campos fijos
> (momento, disparador, qué pasó, regla violada, causa raíz, salvaguarda
> presente, patrón), distinta de bugs de código y aprendizajes técnicos.
> Implementa POLITICA 0.5 (v5.2). Objetivo: hacer analizable en conjunto,
> entre los 16 proyectos de la cartera, un problema de errores repetidos
> del asistente que las salvaguardas existentes no han prevenido por sí
> solas. §2.2 y §2.3 actualizados para incluirla como sección obligatoria
> del traspaso (punto 15) incluso cuando está vacía.
>
> **Cambios respecto a v5:** nueva subsección 2.1bis (Fase 2 — PUSH de
> estado estandarizado): todo proyecto que adopte el estándar genera, en
> su propio cierre, un `ESTADO.md` con front matter parseable
> (semáforo, sesión, sensibilidad, `tipo_pendiente`) más tres secciones
> breves en prosa. Es una destilación del traspaso, no información nueva.
> Habilita lectura barata y estable para el orquestador de cartera
> (`slep_estado_proyectos_monitoreo`), con fallback a PULL (lectura del
> traspaso/backlog) si el proyecto aún no adoptó el estándar o su
> `ESTADO.md` está desincronizado. Propagación inicial: 13 de 16
> proyectos de la cartera (sesión 5, 2026-06-30); 3 sin traspaso aún
> quedaron pendientes.
>
> **Cambios respecto a v4:** §2.2.5 ahora declara el archivo canónico
> del backlog: nombre (`backlog_acumulativo.md`), ubicación
> (`50_documentacion/activa/`) y momento de extracción (a partir del
> segundo cierre). Complementa el parche paralelo en
> `POLITICA_PROYECTO.md` §10. Cierra la brecha documental que causó
> heterogeneidad de nombres y ubicaciones en la cartera.
>
> **Cambios respecto a v3:** nueva subsección 4.6.4 (suite standalone
> offline: activar `generar_suite(standalone=TRUE)` para embeber CSS,
> fuentes, logos e iconos en cada HTML; precondición de `npm` + red para
> descargar lucide-static, validación de iconos, ajuste de versionado del
> tema). Procedimiento estándar para propagar el modo offline a cualquier
> proyecto con suite.
>
> **Cambios respecto a v2:** nueva regla 4.6.3.6 (terminología
> institucional del SLEP: "establecimiento educacional" como término
> genérico, completo en la primera mención de cada párrafo y abreviado a
> "establecimiento(s)" en las repeticiones; prohibición de "EE" en texto
> visible y de "colegio" como sustantivo genérico, con excepciones para
> la voz del lector en FAQ, los ejemplos del universo y nombres propios
> externos).
>
> **Cambios respecto a v1:** nueva sección 4.6 (generar la documentación
> de un proyecto con el paquete `suitedoc`: guion de insumos, mapeo a la
> `cfg`, reglas de gobernanza y de no-invención de metodología).
>
> **Regla crítica de automatización:** este documento y la política viven
> en la knowledge base. El asistente los procesa proactivamente al inicio
> de cada sesión. JAMÁS pide al usuario que los adjunte. Solo en un chat
> suelto fuera de un Project, y solo si la tarea los requiere, los
> solicita una vez. Si la knowledge base contiene una versión más
> reciente de un documento que la citada en el traspaso, usar la más
> reciente y declararlo en el acuse de recibo.
>
> **Nomenclatura de principios:** las referencias B.N / C.N apuntan a
> los principios de interacción (B) y técnicos (C) de la política,
> sección 5 (B.1 pensar antes de codificar, B.2 simplicidad, B.3 cambios
> quirúrgicos, B.4 ejecución dirigida por objetivos; C.N = numeración de
> la sección 5.2-5.3).

---

## 1. Protocolo de sesiones

### 1.1 Clasificación (primer paso de toda sesión)

Cuatro tipos:

- **CONTINUATION:** retomar un proyecto en curso. Señales: "continuemos
  con", "retomar", "donde quedamos", traspaso adjunto.
- **NEW PROJECT:** proyecto de desarrollo desde cero. Señales:
  descripción de algo a construir, requerimientos, pedido de andamiaje.
- **ONE-OFF:** consulta aislada sin ciclo de vida (1-5 turnos). Una
  pregunta, una revisión, una explicación.
- **BIBLIOTECA:** sesión generativa que produce artefactos para
  `herramientas_dev/` (políticas, prompts, plantillas). Taller, no
  consulta: si el primer mensaje pide diseñar o mejorar instrumental,
  es BIBLIOTECA aunque parezca simple.

Si tras el primer mensaje el tipo es ambiguo, UNA pregunta para
clasificar y proceder.

### 1.2 CONTINUATION

El objetivo de la apertura es **analizar, comprender, planificar y
proponer antes de tocar una sola línea de código**. Sin atajos.

#### 1.2.1 Insumos

(a) Esta knowledge base (política + este documento), leída sin pedirla.
(b) El traspaso `traspaso_cierre_vNN.md` de la sesión anterior.
(c) El escáner reciente (`estructura_actual.md`).
Si (b) o (c) faltan y no están en la knowledge base, pedirlos en un
solo mensaje y detenerse. Insumo opcional: `CLAUDE.md` del proyecto si
la sesión correrá en Claude Code.

#### 1.2.2 Fase A — Lectura dirigida y verificación

0. **Orientación (si el proyecto adoptó Fase 2):** leer
   `50_documentacion/activa/ESTADO.md` antes que nada (15 líneas: semáforo,
   en qué vamos, próximo paso, bloqueantes). Verificar sincronía: si
   `ultima_actividad` antecede al último traspaso, declararlo y confiar en
   el traspaso. ESTADO.md orienta; no sustituye ninguna lectura.
1. **Traspaso completo, de principio a fin.** No escanear, no resumir
   prematuramente, no saltar secciones. Sin cambio: es la lectura
   innegociable de la apertura.
2. **Backlog acumulativo por capas.** Leer siempre: Objetivo del proyecto,
   Nota metodológica, Clasificación temática, Resumen estadístico por
   sesión, y el Detalle cronológico de la última sesión. El detalle
   completo se lee cuando la tarea lo exige (refactor, análisis de
   patrones, deuda que toca entradas antiguas); toda afirmación sobre una
   entrada antigua exige leerla en ese momento, nunca citarla de memoria.
3. **Política por versión y pertinencia.** Verificar la versión vigente en
   la knowledge base contra la citada en el traspaso; si cambió, leer el
   registro de cambios del encabezado completo y las secciones nuevas.
   Leer siempre las reglas de interacción (0.1-0.5) y el checklist 5.6;
   leer además las secciones que el foco de la sesión y las restricciones
   del traspaso invocan. La política completa se relee cuando la versión
   cambió, cuando la sesión es NEW PROJECT o migración estructural (4.2,
   4.3), o cuando una duda de gobernanza lo pida (la sección 6 de la
   política prevalece siempre).
4. **Comparar el árbol del escáner** con la estructura canónica de la
   política. Toda desviación (carpetas con nombres antiguos, archivos
   fuera de lugar, huecos de numeración) se marca como **deuda heredada**,
   no se "ajusta" en silencio. Sin cambio.
5. **Ejecutar la auditoría de apertura** (política, sección 5.6, preguntas
   marcadas "Apertura") y anotar hallazgos. Sin cambio.

#### 1.2.3 Fase B — Acuse de recibo delta

El acuse prueba el procesamiento de los insumos y trae al frente SOLO lo
que condiciona esta sesión. No re-resume lo que el traspaso ya dice y no
cambió: el traspaso está adjunto y la Fase A lo leyó completo.

```markdown
## Acuse de recibo — Traspaso vNN

### Insumos verificados
[Traspaso vNN completo (N bugs, N restricciones, N pendientes); backlog
NNN cambios en N sesiones (capas leídas según 1.2.2 punto 2); escáner del
AAAA-MM-DD; ESTADO.md sincronizado / desincronizado / no adoptado;
versiones de política y de este documento usadas, declarando si difieren
de las citadas en el traspaso.]

### Delta comprendido (vNN-1 → vNN)
[3-6 líneas en palabras propias: qué cambió en la última sesión, qué
funciona y qué no HOY, dónde quedó el proyecto. Nada de historia estable.]

### Vigentes que condicionan esta sesión
- **Bugs activos:** [lista con su regla aprendida, o "ninguno"].
- **Instrucciones específicas heredadas:** [reproducción LITERAL de la
  sección de instrucciones del traspaso, ⚠️/✅/🔒, completa].
- **Restricciones pertinentes al foco probable:** [solo las que aplican,
  citando su origen; el resto quedan procesadas sin re-listarse].
- **Principios en tensión:** [B.N / C.N solo si hay tensión real que
  monitorear; si no, "sin tensiones anticipadas"].

### Auditoría de apertura (política 5.6)
- [pregunta] → [Sí / No — acción requerida]
```

#### 1.2.4 Fase C — Ruta de desarrollo propuesta

No esperar a que el usuario diga qué hacer: con el traspaso completo,
el asistente propone.

```markdown
## Ruta de desarrollo propuesta para esta sesión

### Diagnóstico de situación
[1-2 párrafos: dónde está el proyecto, urgencias, patrón del backlog
(¿deuda acumulándose? ¿bugs bloqueantes? ¿deuda heredada detectada?)]

### Prioridad N: [Título]
- **Qué:** descripción concreta.
- **Por qué en este orden:** justificación relativa.
- **Complejidad estimada:** Baja / Media / Alta.
- **Principios relevantes:** B.N / C.N.
- **Criterio de éxito (B.4):** condición verificable de término.

### Tareas que sugiero NO abordar en esta sesión
[Pendientes a diferir y por qué]

### Ruta alternativa (opcional)
[Camino distinto igualmente válido, con recomendación explícita]
```

Tantas prioridades como quepan razonablemente en una sesión; no inflar.

**Criterios de priorización, en este orden:** (1) bugs activos siempre
primero; (2) bloqueantes; (3) instrucciones explícitas del traspaso
(⚠️ / ✅ / 🔒); (4) deuda heredada de la auditoría de apertura; (5)
deuda técnica acumulada (patrón de bugfixes recurrentes en la misma
zona → proponer refactor antes de construir encima); (6) pendientes de
alta complejidad al inicio, cuando hay más contexto; (7) funcionalidad
nueva; (8) cosmética y documentación al final o en sesión dedicada.

**Esta es la única compuerta de aprobación de la sesión.** El usuario
aprueba, reordena o propone alternativa; cualquiera es válido.

#### 1.2.5 Fase D — Ejecución por tarea

Con la ruta aprobada, se ejecuta con autonomía (política 0.3): solo se
interrumpe por decisión estratégica vital, archivo crítico faltante o
compuerta de gobernanza. Por cada tarea, antes de codificar, plan
compacto (presentado y ejecutado en el mismo turno salvo que active
una de esas tres excepciones):

```markdown
## Plan — [Tarea]
- **Objetivo:** [una oración]
- **Criterio de éxito (B.4):** [definido ANTES de codificar]
- **Archivos involucrados:** [rutas relativas y rol]
- **Fuentes primarias consultadas:** [archivo leído o comando ejecutado en
  esta sesión → hecho que respalda. Todo supuesto de hecho del plan
  (existencia o contenido de un archivo, dominio de un campo, firma de una
  función, estado del repo) debe estar respaldado aquí; si no lo está, se
  declara como hipótesis y se verifica antes de ejecutar el plan.]
- **Impacto:** [funciones afectadas directa/indirectamente, insumos requeridos, salidas que cambian]
- **Riesgos:** [riesgo + mitigación]
- **Verificación contra traspaso y principios:** [restricciones o bugs previos que aplican; tensiones declaradas]
```

Construcción incremental en bloques verificables (flujo: comprender →
planificar → construir → verificar → documentar). Tras cada bloque:
¿reintroduce un bug documentado?, ¿respeta restricciones del traspaso,
principios, política y convenciones?, ¿tocó solo lo necesario (B.3)?

Si el usuario pide algo que contradice un principio, una restricción
del traspaso, una regla aprendida o la política, señalarlo ANTES de
proceder, citando la fuente: "Antes de avanzar: [regla/principio]
indica [X]; lo que propones [riesgo]. ¿Procedemos o ajustamos?"

#### 1.2.6 Reglas permanentes de la sesión

- **NUNCA modificar código sin haberlo leído primero.** La fuente
  principal de errores entre sesiones es operar sobre un estado
  supuesto. No asumir el contenido de un archivo ni su ubicación: leer
  el archivo, consultar el escáner (y pedir re-correrlo si está
  desactualizado).
- **NUNCA aplicar cambios no solicitados ni aprobados** (B.3). Las
  mejoras detectadas se mencionan, no se implementan.
- **Un cambio conceptual por intervención:** un cambio, una
  explicación, una verificación. No agrupar cambios distintos.
- **Bugs: causa raíz antes de corregir.** Diagnosticar, documentar,
  verificar si es un caso conocido del traspaso, y solo entonces
  corregir, verificando no romper otra cosa.
  - *Escalada objetiva tras tres fixes fallidos.* Si tres intentos de
    corrección fallan y cada uno destapa un problema nuevo en otro lugar
    (nuevo síntoma, nuevo acoplamiento, nuevo estado compartido), la
    señal no es "un cuarto fix": es que la arquitectura puede estar mal.
    Detenerse y reportar "la arquitectura puede estar mal" con la
    evidencia de los tres intentos, en vez de seguir parchando. Este
    corte SÍ activa la excepción de autonomía (POLITICA 0.3): es una
    decisión estratégica del titular, no un refactor menor que se
    resuelve en silencio.
  - *Instrumentación por frontera antes de adivinar.* En pipelines
    multi-etapa (flujo `20→30→40`, o migraciones con fases) donde el
    error cruza varias capas, antes de proponer fixes loguear qué entra
    y qué sale en cada frontera entre componentes (qué recibe cada
    script/estación, qué entrega, si la configuración y el entorno se
    propagan). Correr una vez para localizar en qué capa se rompe con
    evidencia, y solo entonces investigar esa capa; no adivinar cuál
    falla ni parchar la primera sospecha.
  - *Recepción de correcciones del titular.* Ante una corrección del
    titular, verificar contra el estado real antes de aplicarla; no
    responder con agrado performativo, actuar directamente.
- **La política es contrato, no sugerencia.** Desviaciones se
  documentan como deuda heredada y se proponen como pendiente.
- **Toda afirmación de hecho lleva su fuente primaria.** Cualquier
  afirmación sobre el estado del proyecto (existencia, ubicación o
  contenido de un archivo; dominio de valores de un campo; firma de una
  función; estado del CI o del repo) se acompaña, en la misma oración, de
  la fuente primaria consultada en esta sesión ("(fuente: leído
  `00_run_all.R`)", "(fuente: `git ls-files`)"). Un nombre de archivo o
  campo, un documento normativo, la memoria o un adjunto sin validar NO
  son fuente primaria: lo que solo se apoya en ellos se redacta como
  hipótesis y se verifica antes de actuar. Esta regla generaliza y
  reemplaza las formulaciones por caso acumuladas en proyectos
  individuales.
- **Generar, verificar, consumar: en ese orden.** Todo bloque de
  comandos o encargo que genere o modifique un artefacto y luego lo
  consuma (commit, push, entrega, cifra comunicada) intercala entre ambos
  un paso de verificación observable (`wc -l`, `tail`, `diff`,
  `git status`, recuento programático) y condiciona el paso consumidor a
  su resultado ("si el conteo difiere de N, detente y reporta"). Las
  cifras comunicadas se recuentan programáticamente; la aritmética manual
  no es fuente válida de una cifra reportada.
- **Ningún comando asume el entorno.** Todo bloque de comandos
  destinado a ejecutarse fuera de esta conversación declara dónde se
  ejecutará, usa rutas completas desde la raíz del proyecto y no asume
  `cd` previo ni estado de terminal heredado. Si la ejecución necesita un
  archivo, la ruta se verifica en el entorno destino o el contenido se
  incrusta completo; "te lo paso aparte" no es una fuente accesible.
  (Para encargos formales a Claude Code rige además el encabezado de
  contrato de `encargo_autonomo_claude_code_v1.md`, sección 2.1.)
- **El turno termina proponiendo.** En sesión de proyecto, un
  turno solo puede terminar en uno de tres estados: (a) propuesta concreta
  del siguiente paso con recomendación (política 0.1); (b) compuerta
  legítima declarada (decisión estratégica, gobernanza, validación in situ
  del titular); (c) propuesta de cierre de sesión con el síntoma de la
  sección 3 nombrado. Terminar con una pregunta abierta de dirección o
  con una descripción de estado sin propuesta es una desviación
  registrable en 2.2.15.
- **Registro de autorizaciones vigentes.** Las autorizaciones y
  decisiones que el titular da durante la sesión se anotan al recibirse y
  valen para toda la sesión. Antes de pedir cualquier confirmación,
  verificar contra ese registro: re-preguntar lo ya autorizado es una
  desviación registrable.
- **Entrega materializada con destino.** Todo entregable
  persistente (documento, script, encargo, parche) se entrega como archivo
  y con su destino declarado en la misma entrega, con la forma
  "→ destino: `<ruta completa desde la raíz>`". El contenido efímero
  (explicaciones, cálculos puntuales) no obliga a materializar.

#### 1.2.7 Registro continuo para el cierre

Durante toda la sesión, registrar mentalmente por cada cambio: qué y
por qué, categoría temática del backlog, causa raíz si hubo bug,
alternativas si hubo decisión de diseño, tensiones entre principios y
cómo se resolvieron. Es el insumo del traspaso (sección 2).

### 1.3 NEW PROJECT

Sin traspaso. Primera acción obligatoria: la pregunta de bifurcación
por sensibilidad de datos (política, sección 8.1). Luego el plan:

```markdown
Comprensión del proyecto
[2-4 bullets en palabras propias]

Supuestos que estoy haciendo
[supuestos e inferencias declarados]

Ruta de trabajo propuesta
[3-6 pasos numerados; el paso 1 es siempre la inicialización según la
rama A o B de la política, sección 8]

Decisiones que necesito de ti antes de empezar
[solo bloqueantes; la sensibilidad de datos ya debe estar resuelta]

¿Avanzamos con el paso 1 o ajustamos la ruta?
```

Desde la aprobación de la ruta aplican las fases D y siguientes de
1.2, y el primer cierre genera el traspaso v01 con el backlog inicial
(objetivo del proyecto, nota metodológica y taxonomía inicial; ver
2.2.5).

### 1.4 ONE-OFF

Sin protocolo. Responder directo. Sin ritual de cierre.

### 1.5 BIBLIOTECA

Sin apertura formal. Responder directo. Si la sesión produce 3 o más
artefactos persistentes, ofrecer proactivamente un **cierre liviano**:

```markdown
Artefactos producidos
[lista de archivos con destino]

Decisiones clave
[2-4 decisiones de diseño que conviene recordar]

Próximos artefactos posibles
[ideas no materializadas]
```

Guardar como `herramientas_dev/logs/YYYYMMDD_sesion_<tema>.md` previa
confirmación del usuario.

### 1.6 Prohibido en cualquier tipo

Aperturas vagas ("¿en qué trabajamos hoy?"); acuses genéricos antes del
plan; empezar trabajo tangible antes de entregar el plan (cuando
aplica); planes no anclados en insumos reales.

---

## 2. Protocolo de cierre de sesión de proyecto

### 2.1 Generación

Al cerrar una sesión CONTINUATION o NEW PROJECT, generar
`traspaso_cierre_vNN.md` (correlativo global, dos dígitos; snake_case
según la política, sección 2; unifica la grafía antigua con guiones)
en `50_documentacion/traspasos/`. El traspaso es el **único puente**
entre sesiones: todo lo que no quede ahí, se pierde. Antes de cerrar:
ejecutar el escáner y referenciarlo.

El traspaso se entrega SIEMPRE materializado como archivo `.md` en esa
ruta (nunca solo como texto plano en el chat), acompañado en el mensaje
de cierre del bloque de reapertura (2.2.14). Entregarlo sin archivo es
una desviación registrable en 2.2.15.

> **Convención de nombre — no negociable.** El separador es SIEMPRE
> guión bajo: `traspaso_cierre_vNN.md`. NUNCA con guión medio
> (`traspaso-cierre-vNN.md` es no-canónico y no se versiona). Esto
> aplica a todo archivo que Claude genere o nombre en el proyecto:
> snake_case, sin guiones medios, sin tildes, sin ñ, sin espacios
> (política, sección 2). Antes de entregar o commitear cualquier
> archivo nuevo, verificar que el nombre no contenga `-`, ` `, ni
> caracteres acentuados. Si el escáner muestra un archivo canónico
> existente con cierta grafía, esa grafía manda; no introducir una
> variante.

Incluir TODAS las secciones de 2.2; si una no aplica, incluirla con
"No aplica en esta sesión" y justificación breve. Tres secciones valen
por su vacío y son obligatorias incluso vacías, porque su vacío es una
afirmación verificable: Bugs de la sesión (2.2 punto 6), la auditoría de
cierre (dentro de 2.2 punto 11) y la tabla de errores del asistente
(2.2.15).

**Chequeo de cierre del backlog (2.2.5):** si este es el segundo cierre o
posterior y el backlog aún vive embebido en el traspaso, o en un archivo
de nombre no canónico, extraerlo o renombrarlo a
`50_documentacion/activa/backlog_acumulativo.md` es parte de ESTE cierre,
no un pendiente que se hereda.

### 2.1bis Generación de ESTADO.md (Fase 2 — PUSH)

Todo proyecto que adopte el estándar de Fase 2 genera o actualiza, en el
mismo cierre que produce el traspaso, un archivo
`50_documentacion/activa/ESTADO.md`. Es una **destilación** de campos que
el traspaso ya produce, no información nueva: front matter estructurado
(parseable de forma determinista) más tres secciones breves en prosa.

**Formato canónico:**

```
---
slug: <slug>
nombre_real: <nombre>
categoria: activo
semaforo: activo|pausa|bloqueado|cerrado
sesion_actual: vNN
ultima_actividad: AAAA-MM-DD
maneja_sensibles: true|false
tipo_pendiente: bug|bloqueante|deuda_heredada|deuda_tecnica|nuevo|cosmetica|ninguno
---
## En que vamos
<2-3 oraciones>
## Proximo paso
<1 oracion>
## Bloqueantes
<lista o "ninguno">
```

**Origen de cada campo (mapeo de destilación):**

| Campo `ESTADO.md` | Se toma de (traspaso, por significado, no por número de sección — la numeración varía entre proyectos) |
|---|---|
| `slug`, `nombre_real` | Identificación del proyecto |
| `semaforo` | Inferido del estado al cierre: **bloqueado** solo si hay un bug bloqueante activo del propio pipeline; **pausa** si el proyecto completo está parado a la espera de un tercero externo (aprobación, dato de otra área) sin acción ejecutable de parte del titular; **activo** en cualquier otro caso, incluido cuando solo un ítem puntual del backlog (no el proyecto completo) está marcado como a la espera de algo. Ante duda entre activo y pausa, el criterio decisivo es: ¿hay trabajo ejecutable por el titular ahora mismo, aunque sea parcial? Si sí, activo. |
| `sesion_actual` | Versión vNN del traspaso usado como fuente |
| `ultima_actividad` | Fecha de cierre del traspaso fuente |
| `maneja_sensibles` | Gobernanza del proyecto (`gobernanza_datos.md` si existe, o POLITICA §6.1) |
| `tipo_pendiente` | Ver regla de mapeo abajo — **NO se copia literal**, se traduce |
| `## En que vamos` | Resumen ejecutivo del traspaso, condensado a 2-3 oraciones |
| `## Proximo paso` | Pendientes y ruta sugerida, la prioridad 1 |
| `## Bloqueantes` | Pendientes marcados tipo "bloqueante"; "ninguno" si no hay |

**Regla de mapeo de `tipo_pendiente` (dos taxonomías distintas, no
confundir):**

`tipo_pendiente` usa el enum de **prioridad de sesión** de §1.2.4
(`bug | bloqueante | deuda_heredada | deuda_tecnica | nuevo | cosmetica |
ninguno`). Responde la pregunta "¿qué tipo de trabajo encabeza el próximo
arranque de este proyecto?". Es **distinto** de la **clasificación
temática** del `backlog_acumulativo.md` de cada proyecto (POLITICA §10),
que es una taxonomía orgánica y propia de cada hermano (categorías como
"administrativo", "contenido", "documentación", "deuda de datos", libres
por proyecto) que responde "¿de qué trata esta entrada del backlog?".

Cuando el pendiente de prioridad 1 del traspaso esté etiquetado con
vocabulario temático del backlog (no con el enum de §1.2.4), **tradúcelo
por significado al enum de prioridad**; no lo copies literal y no
amplíes el enum para acomodarlo. Si la traducción no es evidente, usa
`nuevo` como default conservador y dilo explícitamente en el reporte de
la sesión que generó ese `ESTADO.md` (no es un error silencioso
aceptable; es una ambigüedad a revisar por el titular).

**Regla de generación:** `ESTADO.md` se escribe DESPUÉS del traspaso,
nunca antes (el traspaso es la fuente; `ESTADO.md` es su destilación). Si
el cierre no alcanza a generarlo, no bloquea el cierre de sesión: el
orquestador de cartera cae a PULL (lectura del traspaso/backlog) para ese
proyecto, sin error.

**Consumidores:** el orquestador de cartera (corrida diaria) y la apertura
CONTINUATION del propio proyecto (1.2.2, paso 0), que lo usa como
orientación inicial antes de la lectura completa del traspaso.

**Detección de desincronización (consumida por el orquestador, no por
este protocolo):** si `ultima_actividad` de `ESTADO.md` antecede al mtime
real del último `traspaso_cierre_vNN.md`, el `ESTADO.md` se considera
desactualizado y el orquestador prioriza PULL para ese proyecto en esa
corrida.

**Adopción:** no retroactiva por defecto. Un proyecto adopta Fase 2
generando su primer `ESTADO.md`; hasta entonces, el orquestador lo lee
por PULL (Fase 1, sin cambios). No hay plazo obligatorio de migración. Un
proyecto sin ningún traspaso aún no puede adoptar Fase 2 (no hay fuente
de la cual destilar): queda en PULL hasta su primer cierre formal.

### 2.2 Estructura del traspaso

1. **Identificación:** proyecto, versión vNN, fecha, sesión N con foco
   en 1-2 oraciones, entorno, archivos principales modificados.
2. **Resumen ejecutivo:** un párrafo de 5-8 oraciones (qué se propuso,
   qué se logró, qué quedó pendiente, estado general). Suficiente por
   sí solo para entender la situación.
3. **Estado al cierre:** qué funciona (con última ejecución exitosa),
   qué no funciona (síntoma observable), delta respecto a vNN-1.
4. **Registro detallado de cambios:** un bloque por cambio
   conceptualmente independiente (no agrupar aunque compartan archivo):
   archivo(s), categoría temática, qué se hizo, por qué (C.11), cómo se
   verificó (B.4), líneas o secciones clave, dependencias afectadas,
   tensiones entre principios si las hubo.
5. **Backlog acumulativo** (ver 2.2.5).
6. **Bugs de la sesión:** síntoma observable, causa raíz, solución
   exacta (archivo/línea), criterio de verificación, **patrón general
   aprendido** como regla aplicable, principios violados o aplicados,
   estado (resuelto / parcial / pendiente).
7. **Aprendizajes y restricciones descubiertas:** cada uno como regla
   concreta con principio relacionado, contexto (qué pasa si se viola)
   y ejemplo de la sesión.
8. **Decisiones de diseño:** decisión, alternativas consideradas,
   justificación, tensiones resueltas, implicancia. Las de peso
   arquitectónico se replican como archivo en
   `50_documentacion/activa/decisiones/YYYYMMDD_decision_<tema>.md`.
9. **Constantes y parámetros:** tabla SOLO de las que cambiaron en la
   sesión (constante / valor anterior / valor nuevo / archivo / motivo),
   más una línea que nombre la fuente canónica de las vigentes
   (`10_utils/10_configuracion.R`, `documentacion_tecnica_vN.md` o el
   script que las declara). Si ninguna cambió: "Sin cambios; vigentes en
   `<fuente>`". Las constantes decididas en la sesión que aún no viven en
   código se listan completas (el traspaso es su única fuente hasta que
   aterricen).
10. **Arquitectura de archivos:** referencia al escáner al cierre; si
    la estructura cambió, resumen del cambio y verificación contra la
    política.
11. **Pendientes y ruta sugerida:**
    - Inventario: por pendiente, descripción, contexto, tipo (bug
      activo / bloqueante / funcionalidad / deuda técnica / mejora
      visual / documentación), impacto, dependencias, complejidad,
      principios relevantes, precauciones, sugerencia de enfoque y
      criterio de éxito sugerido. Campos obligatorios: son el insumo
      de la Fase C de la próxima apertura.
    - Evaluación de deuda técnica: zonas frágiles (qué principio se
      viola) y oportunidades de mejora.
    - Auditoría de cierre (política 5.6, preguntas "Cierre"); toda
      respuesta "no" se agrega como pendiente.
    - Ruta sugerida para la próxima sesión aplicando los criterios de
      priorización de 1.2.4, con justificación y criterio de éxito por
      ítem, más lo que conviene diferir.
12. **Instrucciones específicas para la próxima sesión:** formato
    ⚠️ NO [acción] sin [condición] / ✅ ANTES de [acción], verificar
    [precondición] / 🔒 [invariante intocable].
13. **Fragmentos de código de referencia:** SOLO los patrones nuevos o
    modificados en esta sesión, ejecutables tal cual, comentados. Los
    patrones estables del proyecto viven en una fuente única
    (`documentacion_tecnica_vN.md` o `CLAUDE.md` del proyecto) y el
    traspaso los referencia por nombre, no los re-copia. Si la sesión no
    aportó patrones nuevos: "Sin patrones nuevos; los estables viven en
    `<fuente>`".
14. **Reapertura** (ver 2.2.14).
15. **Errores del asistente** (ver 2.2.15): tabla obligatoria, registro
    exhaustivo de desviaciones de regla canónica (POLITICA 0.5).

#### 2.2.5 Backlog acumulativo (memoria de largo plazo)

**Archivo canónico:** `50_documentacion/activa/backlog_acumulativo.md`.
Nombre y ubicación no negociables (ver política §10). En el primer
cierre el backlog puede vivir embebido en el traspaso; a partir del
segundo cierre debe existir como archivo independiente en esta ruta.

Registro histórico vivo. En cada cierre se **copia íntegro** el backlog
del traspaso anterior y se agregan los cambios nuevos al final. Jamás
se reescriben, resumen ni renumeran entradas anteriores; un error se
corrige con una entrada nueva.

- **Objetivo del proyecto:** párrafo permanente (qué es, qué produce,
  con qué herramientas, para quién, desde cuándo). Se redacta en la
  sesión 1.
- **Nota metodológica:** párrafo permanente que define qué cuenta como
  "cambio" (una solicitud distinguible del usuario, no las acciones
  técnicas que la implementan), qué no (errores del asistente
  corregidos de inmediato; sí cuentan los bugfixes reportados por el
  usuario), que la clasificación es por intención primaria, y cuáles
  son las fuentes del conteo.
- **Clasificación temática:** tabla categoría / N° / % / descripción
  con ejemplos concretos del proyecto. Taxonomía orgánica: se propone
  en la sesión 1 y se refina después. Categorías mutuamente
  excluyentes por intención primaria; entre 8 y 15; subdividir si una
  supera el 25%; absorber si una queda bajo el 2% tras varias sesiones.
- **Resumen estadístico por sesión:** tabla sesión / traspasos
  generados / N° de cambios / modelo / foco (3-6 palabras), con fila
  final separada para refinamientos menores no atribuibles, y total.
- **Detalle cronológico:** todos los cambios por sesión, con
  **numeración correlativa global y permanente** (nunca se reinicia ni
  renumera), descripciones autocontenidas, referencia cuando un cambio
  resuelve un pendiente anterior, y subtítulos temáticos en sesiones
  largas.
- **Delta del backlog:** cambios respecto a la versión anterior (N
  entradas nuevas, refinamientos de taxonomía, reclasificaciones).

#### 2.2.14 Reapertura (una copia en el traspaso, replicada solo en el chat)

Esta sección aparece UNA sola vez dentro del traspaso (su sección final) y
se replica **textualmente** al final del mensaje de chat con el que el
asistente cierra la sesión, para copiar todo sin abrir el archivo. No se
duplica dentro del propio traspaso. Con **valores reales, jamás
placeholders**. El asistente no propone nombre para la nueva sesión.

- **Mensaje de apertura pre-armado:** declara tipo CONTINUATION, indica
  que el protocolo (política + este documento) vive en la knowledge base
  y se lee desde ahí, lista qué se adjunta, y cierra con una línea de
  estado y el foco propuesto (la prioridad 1 de la ruta sugerida del
  traspaso), para que la próxima apertura entre a la Fase C con la
  propuesta ya sembrada. Variante para chat suelto: "Adjunto los
  documentos de protocolo y los específicos de la sesión."
- **Documentos para la próxima sesión, en tres bloques:**
  1. *Protocolo en knowledge base* (NO se adjuntan; se listan con
     nombre exacto solo para verificar que la knowledge base esté al
     día): `POLITICA_PROYECTO.md`,
     `SETTINGS_Y_PROMPTS_OPERACIONALES.md`.
  2. *Opcionales según el foco real de la próxima sesión* (solo los
     que apliquen, no todos): `CLAUDE.md` si correrá en Claude Code;
     protocolos 4.1-4.6 de este documento según la tarea;
     `auditoria_codigo_proyecto_md_v1.md` si habrá auditoría de cifras.
  3. *Específicos de la sesión* (SÍ se adjuntan): el traspaso
     `traspaso_cierre_vNN.md`; el escáner `estructura_actual.md`; los
     archivos críticos para retomar (solo los que la próxima sesión
     necesita, priorizando los del pendiente foco; los voluminosos
     pero críticos se mantienen anotados como tales); datos o
     referencias externas si aplica, con su porqué.
- **Nota final obligatoria:** si algún archivo listado cambió entre
  sesiones, adjuntar la versión más actualizada al abrir y avisarlo en
  el mensaje de apertura.

#### 2.2.15 Errores del asistente (registro obligatorio, POLITICA 0.5)

Sección obligatoria del traspaso, distinta de "Bugs de la sesión" (§2.2.6,
que registra bugs de CÓDIGO) y de "Aprendizajes y restricciones" (§2.2.7,
que registra reglas técnicas DESCUBIERTAS). Esta sección registra errores
del **asistente mismo**: desviaciones de una regla canónica ya existente
(POLITICA, este documento, `CLAUDE.md`, `userPreferences`, o una
instrucción explícita ya dada en la sesión), detectadas por el asistente o
señaladas por el usuario, se hayan nombrado como "error" o no (POLITICA
0.5, disparador exhaustivo).

**Por qué es una sección separada y no se mezcla con bugs/aprendizajes:**
un bug de código se corrige editando el código; un error del asistente se
corrige ajustando el comportamiento del asistente, y su valor está en ser
**comparable entre sesiones y entre los 16 proyectos de la cartera** para
detectar patrones que ninguna sesión aislada vería. Mezclarlo con bugs de
código diluiría esa comparabilidad.

**Tabla obligatoria (campos fijos, una fila por error):**

| Campo | Contenido |
|---|---|
| `momento` | En qué punto de la sesión ocurrió (referencia al turno o tarea) |
| `disparador` | Cómo se detectó: "asistente lo señaló espontáneamente" / "usuario lo corrigió" / "usuario lo señaló sin nombrarlo error" |
| `que_paso` | Descripción concreta de la desviación, una oración |
| `regla_violada` | Documento + sección exacta de la regla que existía y no se siguió (p.ej. "userPreferences, edición de archivos: entregar completo, no fragmentos") |
| `causa_raiz` | Por qué ocurrió pese a que la regla estaba disponible (nunca "no lo sabía": la regla existía; el análisis es de por qué no se aplicó en el momento) |
| `salvaguarda_presente` | Qué documento(s) ya contenían la regla violada (POLITICA / SETTINGS / CLAUDE.md / userPreferences / más de uno) |
| `patron` | Etiqueta `PAT-NN` del catálogo canónico (`herramientas_dev/gobernanza/catalogo_patrones_errores_vN.md`) más el matiz libre ("PAT-01, sobre firma de función"). "Nuevo" se reserva para mecanismos que ningún `PAT-NN` cubre, y obliga a proponer la entrada nueva del catálogo en el mismo traspaso |

**Regla de registro:** el error se anota en el momento en que se
identifica dentro de la sesión (no se reconstruye de memoria al cerrar).
Si la sesión no llega a un cierre formal, el registro provisional debe
quedar localizable en el historial de la conversación.

**Regla de formato:** la tabla usa los siete campos fijos sin excepción,
en cualquiera de los layouts equivalentes (tabla de 7 columnas, tabla
transpuesta o bloque campo/contenido por error). Omitir campos o sustituir
la tabla por un formato propio degrada la comparabilidad entre proyectos,
que es el propósito de esta sección.

**Consumo entre proyectos:** esta tabla es, junto al backlog, uno de los
pocos artefactos pensados explícitamente para análisis CRUZADO entre los
16 proyectos de la cartera (no solo memoria de un proyecto individual).
Si en una sesión de `slep_estado_proyectos_monitoreo` (o cualquier sesión
BIBLIOTECA dedicada) se detecta que el mismo `patron` aparece en tablas de
errores de 2 o más proyectos, eso es evidencia de que la salvaguarda
actual (la regla tal como está escrita) no es suficiente y debe
reformularse, no solo repetirse con más énfasis.

#### 2.2.16 Validación empírica antes de reformular una regla reincidente

Cuando §2.2.15 dispara ("el mismo `patron` aparece en tablas de errores
de 2 o más proyectos"), la regla violada debe reformularse, no repetirse
con más énfasis. Pero **antes de reescribirla**, clasificar de qué tipo
de falla se trata: la forma de la corrección depende del tipo de falla, y
elegir mal la forma es lo que hace que una regla reincida pese a
reformularse. En particular, endurecer una prohibición es la herramienta
correcta solo cuando la falla es de disciplina; si la falla es de forma
del output, de omisión o de condición ambigua, una prohibición más
enfática no corrige y a veces empeora (bajo un incentivo en competencia,
el asistente "negocia" con el "no X").

**Tabla de clasificación (cuatro categorías, elegir una):**

| Tipo de falla | Cómo se reconoce | Forma correcta del arreglo |
|---|---|---|
| **Disciplina** | El asistente conocía la regla y la saltó bajo presión (prisa, costo hundido, "solo esta vez") | Prohibición explícita + tabla de racionalizaciones + lista de red flags |
| **Forma del output** | El asistente cumplió, pero el producto salió con forma equivocada (fragmento en vez de archivo completo, cifra sin recuento, veredicto enterrado) | Receta positiva o contrato: declarar qué ES el output correcto, sus partes y su orden |
| **Omisión** | Falta un elemento de algo que el asistente ya produce (campo ausente de una tabla o plantilla) | Campo/slot obligatorio en la plantilla que rellena, no un recordatorio en prosa |
| **Condición ambigua** | La conducta correcta dependía de una condición que la regla no ató a un disparador observable | Condicional explícito sobre un predicado observable ("si existe X, entonces Y") |

**Regla de elección:** una prohibición NO es la herramienta correcta si
la falla es de forma, de omisión o de condición, aunque el patrón
reincida. Reformular en la forma equivocada (más prohibición para una
falla de forma) cuenta como reformulación fallida y se registra como tal
en el próximo ciclo. La reformulación elegida se documenta junto al
`patron` correspondiente, nombrando la categoría usada.

**Alcance de esta subsección:** cubre la *elección de la forma* de la
regla reformulada. La validación de que la nueva redacción efectivamente
cambia la conducta (micro-test empírico contra un control sin la regla)
queda fuera de alcance por ahora: requiere infraestructura de testing de
prompts que hoy no existe en `herramientas_dev`. Cuando esa
infraestructura exista, esta subsección es el punto natural de enganche.

### 2.3 Reglas de redacción del traspaso

1. Exhaustividad sobre brevedad: ante la duda, incluir (la información
   faltante cuesta una sesión repitiendo errores).
2. Especificidad sobre generalidad: causa raíz exacta con archivo y
   línea, no "tenía un bug".
3. Causa raíz, no solo síntoma (C.11).
4. Cada aprendizaje como regla concreta vinculada a su principio.
5. Sin supuestos implícitos: la próxima instancia no "lo sabrá" (B.1).
6. Todo fragmento de código incluido debe ser copiable y ejecutable.
7. El backlog es la única fuente de verdad del conteo histórico.
8. Los pendientes son el mapa de la próxima ruta: sus campos son
   obligatorios.
9. La auditoría de cierre es obligatoria: la sesión no deja deuda sin
   documentar.
10. Valores reales en la reapertura, sin placeholders.
11. La tabla de errores del asistente (§2.2.15) es obligatoria incluso si
    está vacía: una fila "sin errores registrados en esta sesión" es una
    afirmación verificable; omitir la sección entera no lo es.

---

## 3. Higiene de sesión

Recomendar cierre proactivo ante: muchas vueltas con fatiga de
contexto; múltiples archivos largos cargados con confusión de
versiones; síntomas de degradación (mezclar versiones, repetir código
ya entregado, respuestas vagas, perder acuerdos); pivote a otro
dominio. Formato:

> Sugiero cerrar esta sesión. Razón: [síntoma concreto]. ¿Cerramos con
> el protocolo de cierre (proyecto) o con cierre liviano (BIBLIOTECA)?

Cerrar temprano es más barato que un traspaso corrupto.

---

## 4. Protocolos bajo demanda

Se activan cuando la tarea de la sesión lo requiere. El asistente los
consulta solo; no espera que el usuario los invoque por nombre.

### 4.1 Generar orquestador `00_run_all.R`

Especificación completa: política, sección 4. Protocolo:

1. Obtener el inventario real de ejecutables (escáner o
   `estructura_actual.md`). No deducir nombres ni rutas.
2. Generar el archivo completo cumpliendo la sección 4 de la política
   (raíz vía `rprojroot`, `PASOS`, `run_all(from/to/only/skip)`,
   validación de rutas al inicio, logging, `.qmd` vía
   `quarto::quarto_render()`).
3. Incluir al final ejemplos de uso comentados (`run_all()`,
   `run_all(skip = c(1, 2))`, `run_all(from = 5)`, `run_all(only = 8)`).
4. Prohibido: modificar scripts de estación, asumir scripts no
   inventariados, caché automático por timestamp, lógica de negocio.

### 4.2 Migrar estructura a la convención canónica

Motor: `herramientas_dev/plantillas/99_reorganizar_estructura_PLANTILLA.R`
copiado al proyecto. Reglas no negociables: política, sección 9.
Secuencia exacta:

1. **Escaneo** del proyecto (pedirlo si no está).
2. **Diagnóstico de referencias:** buscar TODAS las referencias
   literales a las carpetas actuales en `.R`/`.qmd` (entrecomilladas,
   en `file.path()`, `test_path()`, comentarios, tests), excluyendo
   `.Rproj.user`, `renv/`, `.bak`. Sin este diagnóstico los regex de
   reescritura fallan en silencio.
3. **Mapeo justificado:** carpetas vieja → nueva contra los principios
   de la política sección 1; renombres de archivos; reorganización de
   documentación; patrones de reemplazo derivados del diagnóstico;
   exclusiones explícitas (`andamios/`). Confirmación del usuario antes
   de generar el script (decisión estratégica: excepción válida a la
   regla de autonomía).
4. **Adaptar la plantilla** con `DRY_RUN <- TRUE` y registro en
   `_archivo/log_reorganizacion.csv`.
5. **Ciclo DRY_RUN → real:** verificar que los conteos del DRY_RUN
   cuadren con el diagnóstico (Fase 3 con 0 reemplazos = regex malos);
   commit limpio; `DRY_RUN <- FALSE`; verificar integridad de copias.
6. **Validación:** reiniciar R, tests, orquestador end-to-end,
   verificación visual. Solo entonces borrar `.bak`.

No ceder a presión por saltar el DRY_RUN, aunque el usuario lo pida.

### 4.3 Migrar proyecto local a GitHub privado (dos raíces)

Arquitectura objetivo: política, sección 6.2. Contexto a confirmar al
inicio: `nombre_proyecto`, `nombre_repo_github`, ruta local actual,
ruta de código destino (`~/Projects/...`), ruta de datos destino
(OneDrive). Visibilidad: privado, no negociable sin justificación.

- **Fase 0 — Escaneo estructural.** Si la estructura está fuera de
  norma, primero migrar estructura (4.2). No se sube a GitHub un
  proyecto desordenado.
- **Fase 1 — Auditoría de seguridad pre-migración.** Script
  `diagnostico_migracion_github.R` que reporte: datos personales
  hardcodeados (regex RUT `\d{1,2}\.?\d{3}\.?\d{3}-[\dkK]`, correos,
  nombres); credenciales; rutas absolutas con información personal
  (OneDrive, `Users/<nombre>/`); archivos de datos en carpetas
  versionables; nombres con tildes/ñ/espacios; historial Git sucio si
  ya es repo. Output: `diagnostico_migracion_github.md` con hallazgo,
  severidad, norma aplicable y recomendación. **Esperar revisión del
  usuario** (compuerta de gobernanza, no interrupción trivial).
- **Fase 2 — Separación código / datos.** Mover código a la raíz de
  código, datos a la raíz de datos; configurar variable de entorno,
  `10_configuracion.R`, `.Renviron.example` y `.gitignore` blindado
  según política 6.2-6.3 y 8.3. Regla de movimiento físico: **copiar,
  no mover**; verificar que OneDrive terminó de sincronizar antes de
  borrar las carpetas de datos del origen (o moverlas a `_archivo/`
  como respaldo local). Generar `gobernanza_datos.md` y `LICENSE`
  (política, sección 10). Validar con el bloque 8.3.7 en sesión R
  limpia ANTES del primer push; si falla, diagnosticar, no continuar.
- **Fase 3 — Repo remoto.** Verificar con el usuario que es PRIVADO;
  branch protection en `main` (PR obligatorio, sin force push, sin
  borrado). **Matiz de plan:** en GitHub Free los repos privados NO
  tienen branch protection; sustituir con el workflow de validación
  del punto siguiente más autodisciplina de PR documentada en el
  README. Secret Scanning (detección básica activa por defecto en
  privados) y Dependabot; workflow de Actions que valide en cada push
  ausencia de extensiones de datos, de patrones RUT y de tokens.
- **Fase 4 — Primer push.** `git status` completo mostrado al usuario;
  confirmación de cualquier archivo sospechoso; recién entonces push.
- **Fase 5 — Despliegue (si aplica).** Secretos como variables de
  entorno del servidor; autenticación (SSO institucional preferido);
  logs sin datos personales; recordar que shinyapps.io aloja en AWS US
  (si los datos no pueden salir de Chile, Posit Connect on-premise o
  servidor institucional). Infraestructura SLEP: preguntar qué existe,
  no asumir.
- **Cierre.** Mover `diagnostico_migracion_github.md` a
  `50_documentacion/activa/decisiones/` como evidencia histórica;
  copiar `CLAUDE.md` a la raíz si las próximas sesiones serán en
  Claude Code; documentar en el traspaso la configuración pendiente
  para otras máquinas (protocolo 4.4).

### 4.4 Setup de máquina nueva (proyecto ya migrado a dos raíces)

1. Clonar el repo en `~/Projects/`.
2. Verificar que OneDrive institucional esté sincronizado y localizar
   la raíz de datos del proyecto.
3. Copiar el contenido de `.Renviron.example` a `~/.Renviron` ajustando
   la ruta al sistema operativo de la máquina.
4. Reiniciar R y validar (política 8.3.7).
5. Correr `run_all()` o el subconjunto mínimo para confirmar pipeline
   operativo.

No es un refactor: no se toca código del proyecto.

### 4.5 Auditoría de cifras publicadas

Patrón de tres scripts (helpers + orquestador de familias + spot-check)
documentado en `herramientas_dev/prompts/auditoria_codigo_proyecto_md_v1.md`
(vigente como documento independiente). Núcleo: cada cifra publicada se
calcula por dos caminos independientes (caché vs. recálculo desde el
objeto crudo) y se comparan con tolerancias definidas como constantes
nombradas. Llaves siempre `character`; patrón índice-primero en Excel
(jamás `worksheetOrder()`); una familia que falla no aborta las demás.

### 4.6 Generar la documentación de un proyecto con `suitedoc`

Produce los 4 documentos HTML de la suite (`arquitectura_*`,
`documentacion_proyecto_*`, `arquitectura_general_*`,
`documentacion_general_*`) para un proyecto, llenando su `cfg` a partir
del material existente del proyecto, sin que el usuario edite la
configuración a mano. El motor genérico vive en el paquete `suitedoc`;
este protocolo cubre cómo se arma el `documentar.R` de un proyecto
concreto.

**Tipo de sesión:** BIBLIOTECA (produce un artefacto reutilizable, el
`documentar.R` del proyecto), no CONTINUATION del proyecto documentado.
Sin acuse de recibo ni ruta de desarrollo: se entra directo al guion de
insumos. Si produce el `documentar.R` más los 4 HTML, ofrecer el cierre
liviano de 1.5.

**Regla de automatización:** el asistente NO pide al usuario que llene la
`cfg`. Pide los insumos del proyecto (abajo), extrae de ellos todo lo
inferible, y solo pregunta por lo que ningún archivo contiene (la prosa
de comunidad). El producto es un `documentar.R` completo, no una
plantilla con huecos para que el usuario rellene.

#### 4.6.1 Insumos a solicitar (en un solo mensaje)

El asistente pide estos archivos del proyecto a documentar. Los que
existan en la knowledge base del Project no se piden; se leen desde ahí.

| Insumo | Qué aporta a la `cfg` |
|---|---|
| `estructura_actual.md` (escáner) | Diagrama técnico: `insumos`, `etapas`, `intermedios`, rutas reales de los `rotulos`. **Imprescindible:** sin él, las rutas del diagrama se inventan. |
| `README.md` | Identidad (`slug`, `area`, `fuente`); `prosa$doc_que`; origen de los datos. |
| `CLAUDE.md` (si existe) | Convenciones técnicas → `glosario_tec`, flags de `etapas`. |
| Traspaso `traspaso_cierre_vNN.md` (el último) | `decisiones`, `anomalias`, `reglas_calculo`, restricciones técnicas. **Imprescindible:** es la fuente principal de las decisiones metodológicas. |
| Decisiones (`50_documentacion/activa/decisiones/`) | `decisiones` con su porqué; `gobernanza`. |
| Scripts del pipeline (los del flujo, no los utils) | Diccionario de datos (`dic_crudos`, `dic_intermedios`); detalle de `etapas`. |
| `gobernanza_datos.md` (si el proyecto tiene datos sensibles) | `cfg$gobernanza`; qué NO publicar. |

Si faltan los dos imprescindibles (escáner y traspaso), pedirlos y
detenerse: sin ellos el diagrama y las decisiones se inventarían,
violando B.1 (sin supuestos implícitos).

#### 4.6.2 Procedimiento

1. **Leer todos los insumos** de principio a fin. No resumir
   prematuramente.
2. **Verificar la versión del paquete.** Confirmar que el `suitedoc`
   instalado expone los campos que el `documentar.R` va a llenar
   (`rotulos`, `reglas_calculo`, `leyenda`, `textos`, `pie_extra`,
   `gobernanza`, `prosa$etapas_pipeline`). Si el paquete es una versión
   anterior sin esos campos, declararlo: el `documentar.R` generado los
   incluirá igual (caen al fallback del motor), pero conviene actualizar
   el paquete.
3. **Extraer lo inferible** y mapearlo a la `cfg`:
   - Del escáner: el `slug` (nombre de la carpeta raíz), las etapas del
     pipeline (los ejecutables de `30_procesamiento/` en orden), los
     insumos (`20_insumos/`), los intermedios (`40_salidas/`), y los
     `rotulos` con las rutas reales (`31_<...>.R`, etc.).
   - Del README y los scripts: identidad, diccionario de datos, origen.
   - Del traspaso y las decisiones: `decisiones` (cada una con `id`,
     `titulo`, `cuerpo`, `por_que`), `anomalias`, `reglas_calculo`, y
     `gobernanza`.
4. **Determinar la gobernanza.** Si el proyecto trata datos personales o
   de NNA, fijar `cfg$gobernanza` con la categoría (p. ej. "Datos
   personales de NNA") y aplicar la regla de no incluir nombres reales de
   establecimientos, estudiantes ni funcionarios en ningún documento (los
   generales se publican). Describir universos en abstracto.
5. **Redactar la prosa de comunidad.** Lo que ningún archivo contiene:
   `faq`, `garantias`, `notas`, `prosa$gen_porque`, hero-notes de los
   documentos generales. El asistente la redacta desde lo que el proyecto
   hace, en el registro de la audiencia (directivos / comunidad). Si el
   usuario tiene un texto de referencia de voz (un documento ejecutivo,
   un correo tipo), se pide y se usa como base del tono; si no, se redacta
   y se marca para revisión.
6. **Entregar el `documentar.R` completo**, con todos los bloques llenos.
   Las zonas redactadas sin fuente directa (prosa de comunidad) se marcan
   con un comentario `# REVISAR (voz): ...` para que el usuario afine el
   tono, pero el contenido va completo, no en blanco.
7. **No ejecutar por el usuario.** Generar los 4 HTML es tarea del
   usuario (correr `source("documentar.R")` desde su máquina, donde está
   R y el paquete instalado). El asistente entrega el `documentar.R` y la
   instrucción de una línea para generarlo y revisarlo.

#### 4.6.3 Reglas no negociables

1. **Sobrescribir todos los bloques que los builders consumen.** Un
   bloque sin personalizar saldría con el fallback genérico del motor o,
   peor, con residuo del ejemplo. `generar_suite(verificar = TRUE)` (el
   default) aborta si detecta texto del ejemplo de fábrica; el
   `documentar.R` se entrega de modo que pase esa verificación.
2. **Gobernanza prevalece.** En proyectos con datos sensibles, ningún
   nombre real de EE/estudiante/funcionario entra a la `cfg`, porque los
   documentos generales se publican (política, sección 6).
3. **No inventar metodología.** Las `decisiones` y `anomalias` salen del
   traspaso y de los archivos de decisión, nunca de la deducción del
   asistente. Si una decisión no consta, se pregunta; no se fabrica un
   porqué (B.1).
4. **La prosa de comunidad se redacta, no se extrae** — y se marca como
   revisable, porque el tono es del usuario.
5. **Ubicación canónica de la salida:** `50_documentacion/suite/`
   (`documentar.R` + tema + los 4 HTML). Versionar el tema solo si los
   HTML se publican desde el repo; si no, `fonts/` y `assets/` al
   `.gitignore`.
6. **Terminología institucional del SLEP.** El término genérico para
   referirse a escuelas, liceos, jardines infantiles, centros de
   educación de adultos y similares es **"establecimiento educacional"**
   (plural "establecimientos educacionales"). Se despliega completo en
   la **primera mención de cada párrafo**; en las repeticiones siguientes
   del mismo párrafo se usa **"establecimiento(s)"** a secas, para no
   recargar la prosa. La regla aplica a prosa técnica y de comunidad por
   igual. Nunca usar la abreviatura "EE" en texto visible al usuario (sí
   se conserva en notación técnica de fórmulas, p. ej. `conteo de EE`,
   `n_EE`). No usar "colegio" como sustantivo genérico. Excepciones: (a)
   la voz simulada del lector en una FAQ puede usar lenguaje coloquial;
   (b) "escuela/liceo/jardín" se usan deliberadamente cuando se
   ejemplifica el universo que el término genérico engloba; (c) nombres
   propios de productos externos se conservan literalmente (p. ej.
   "Localiza tu colegio" de la Agencia de Calidad).

#### 4.6.4 Suite standalone offline (propagar a cualquier proyecto)

Genera la suite en formato **standalone offline**: embebe CSS, fuentes,
logos e iconos dentro de cada HTML, de modo que los 4 documentos no
dependan del tema en disco ni de CDN para los iconos. Es el formato
canónico para archivar o compartir la documentación como unidad
autónoma, alineado con el principio de HTML autocontenido del proyecto
(igual que el motor). La capacidad vive en `suitedoc` (HEAD `c8b3bd7` en
adelante); **no** requiere tocar el paquete, solo invocarlo bien.

**Cuándo aplica:** cualquier proyecto con suite (`documentar.R` +
`generar_suite()`) que aún produzca los HTML en modo enlazado. Activar
standalone es un cambio acotado en el `documentar.R` del proyecto, no en
`suitedoc`.

**Procedimiento (por proyecto):**

1. **Verificar la versión del paquete.** Confirmar que el `suitedoc`
   instalado expone `generar_suite(..., standalone=)`. Firma real:
   `generar_suite(cfg, salida_dir = ".", copiar_tema = TRUE,
   verificar = TRUE, standalone = FALSE, verbose = TRUE)`. Si la versión
   instalada no la expone, reinstalar desde el repo local:
   `devtools::install("/Users/tomgc/Projects/herramientas_dev/suitedoc")`.
2. **API real (no asumir otra).** `standalone = TRUE` hace que
   `generar_suite` llame **internamente** a
   `inlinar_suite(salida_dir, limpiar_enlazados = TRUE)`: escribe los 4
   `*_standalone.html` y borra los enlazados intermedios. **Nunca** se
   llama `inlinar_suite()` por separado en el flujo normal.
3. **Cambiar la llamada del `documentar.R`** del proyecto: añadir
   `standalone = TRUE`. Mantener el `verificar` que ese proyecto ya use
   (no cambiarlo sin razón declarada).
4. **Precondición de entorno (🔴).** `inlinar_suite()` descarga
   lucide-static (versión fijada, p. ej. 1.21.0) vía `npm pack`. Requiere
   `npm` en el PATH y red al registro npm **en tiempo de generación** (la
   suite resultante sí es 100% offline; generarla no). Verificar
   `npm --version` antes de regenerar; si falla, detenerse y reportarlo
   (el titular instala npm), no improvisar.
5. **Validación de iconos (A17-2 / R3).** `inlinar_suite()` valida todos
   los `data-lucide` de la cfg y **aborta sin escribir nada** si alguno
   no existe en la versión fijada de lucide-static, listando los
   faltantes. Si un icono no resuelve (caso vivido: `sitemap`→`network`),
   sustituirlo en la cfg por el equivalente lucide más cercano y
   registrarlo; si no hay equivalente obvio, detenerse y reportar.
6. **Verificación empírica sobre los `*_standalone.html` reales** (no
   sobre supuestos, R1): `grep` de referencias de red por archivo = 0
   (`http://`, `https://`, `src=`/`href=` a CDN, `<link rel="stylesheet"
   href="http`); iconos como `<svg>` embebido (no `<i data-lucide>` ni
   `<script>` de lucide); fuentes como `data:` URIs. Reportar el conteo
   de red por archivo.
7. **Ajuste de versionado.** Con standalone, el tema (`fonts/`,
   `assets/`) ya viaja embebido en el HTML y **no** se versiona. Cada
   proyecto versiona los 4 `*_standalone.html` + `documentar.R` + el CSS;
   `fonts/` y `assets/` al `.gitignore`. `git status` antes de
   `git add`; nunca `git add .`; confirmar con `git ls-files` (no con el
   escáner, A20) que el tema no entra.

**Separación de responsabilidades (importante).** Activar standalone es
**solo** lo anterior. Si la `cfg` de un proyecto además necesita
actualizaciones de contenido (decisiones formales, gobernanza), eso es
trabajo aparte que se decide explícitamente; no se mezcla con la
activación del modo offline (un cambio conceptual por intervención).

**Llamada canónica:**

```r
# setwd("<raiz_proyecto>") si se corre por Rscript (here::i_am lo exige).
suitedoc::generar_suite(
  cfg,
  salida_dir  = here::here("50_documentacion", "suite"),
  copiar_tema = TRUE,
  verificar   = FALSE,   # o TRUE si ese proyecto no dispara falsos positivos
  standalone  = TRUE,    # produce *_standalone.html offline; limpia los enlazados
  verbose     = TRUE
)
# Requiere npm + red en tiempo de generación (descarga lucide-static fijado).
```
