# POLITICA_PROYECTO.md

> **Versión 5.3 — vigente.** Documento maestro único de arquitectura y
> gobernanza. Se copia a `50_documentacion/activa/` de cada proyecto y
> vive en la knowledge base del Project. Aplica a Claude, Claude Code y
> cualquier agente que trabaje sobre el proyecto.
>
> **Cambios respecto a v5.2:** sección 0.4 agrega el test de dos preguntas
> antes de derivar cualquier tarea al usuario (guardrail GR-05, propuesta
> P4 de la auditoría cruzada de errores del asistente, integrada junto con
> `SETTINGS_Y_PROMPTS_OPERACIONALES.md` v8). Motivo: los dos errores de
> patrón PAT-05 (clasificar como "mecánica del usuario" trabajo que exigía
> producir o editar contenido) ocurrieron en la frontera entre operación
> de plataforma y producción de contenido, que 0.4 no discriminaba por
> criterio, solo por ejemplos. El titular pidió explícitamente una
> solución estructural, no repetir la regla con más énfasis (registrado en
> traspaso `slep_estado_proyectos_monitoreo` v05). El test es obligatorio,
> respondido por escrito en una línea antes de derivar.
>
> **Cambios respecto a v5.1:** nueva regla 0.5 (registro obligatorio de
> errores del asistente): toda desviación de una regla canónica, detectada
> por el asistente o por el usuario, se registra en el momento y se
> consolida en la nueva tabla de errores del traspaso de cierre
> (`SETTINGS_Y_PROMPTS_OPERACIONALES.md` v7 §2.2.15). Disparador
> exhaustivo, no limitado a cuando el asistente dice explícitamente "me
> equivoqué". Objetivo: hacer analizable en conjunto, entre los 16
> proyectos de la cartera, un problema de errores repetidos que las
> salvaguardas existentes no han prevenido por sí solas.
>
> **Cambios respecto a v5:** §10 agrega `backlog_acumulativo.md` como
> documento canónico obligatorio (nombre, ubicación y momento de
> extracción). Complementa `SETTINGS_Y_PROMPTS_OPERACIONALES.md` v5
> §2.2.5. Cierra la brecha que causó heterogeneidad de nombres y
> ubicaciones en la cartera.
>
> **Cambios respecto a v4:** (a) absorbe `regla_estructura_proyectos.md`
> (archivo retirado); (b) absorbe los principios técnicos de
> `principios_desarrollo_v3.md` como sección 5 (archivo retirado); (c) la
> arquitectura de dos raíces (código en Git / datos en OneDrive) pasa a ser
> el modelo canónico para proyectos con datos sensibles (sección 6); (d)
> sección 7 del escáner reescrita con poda atómica de 2 snapshots; (e)
> nueva sección 8 de inicialización de proyectos con bifurcación por
> sensibilidad de datos; (f) migración consolidada (estructura + GitHub)
> en sección 9.

---

## 0. Reglas de interacción del asistente (alta prioridad)

### 0.1 Recomendación explícita al ofrecer alternativas

Cada vez que el asistente presente opciones o decisiones a tomar, debe
declarar cuál recomienda, al final de la lista, en una línea separada:
`**Recomendación:** [opción] — [razón concreta en una oración].`
No vale presentar alternativas neutras. El usuario decide, pero recibe
la opinión del asistente antes. Excepción: opciones verdaderamente
equivalentes; declararlo: `Sin recomendación: ambas opciones son
equivalentes en este contexto.`

### 0.2 Escaneo cuando se pierde la referencia

Si el asistente no sabe dónde están los archivos o cómo está organizado
el proyecto, debe ejecutar o solicitar el escáner (sección 7) antes de
continuar. No deducir ni inventar rutas.

Failsafe de gobernanza documental: si una sesión va a apoyarse en esta
política o en `SETTINGS_Y_PROMPTS_OPERACIONALES.md` y el asistente no
los encuentra (knowledge base del Project, `50_documentacion/activa/`,
o adjuntos en chat suelto), debe declararlo explícitamente y pedirlos
antes de proceder, en lugar de operar desde su memoria o improvisar el
protocolo.

### 0.3 Autonomía con interrupciones mínimas

El asistente opera con máxima autonomía. Interrumpe al usuario solo si:
(1) necesita una decisión estratégica vital para la continuidad del
proyecto, o (2) le falta un archivo o dato crítico irrecuperable. Todo
lo demás (rutas rotas, warnings, tipado, refactors menores) se resuelve
de forma autónoma, reportando la decisión en una línea. La gobernanza
de datos (sección 6) prevalece siempre sobre la autonomía.

### 0.4 Tareas mecánicas manuales

Descargar un archivo de una plataforma, arrastrarlo a una carpeta o
reemplazarlo a mano son tareas del usuario. El asistente no genera
scripts para ellas: indica qué hacer en una línea.

Antes de derivar cualquier tarea al usuario, el asistente responde por
escrito (una línea) el test de dos preguntas:

1. ¿La tarea exige producir o editar contenido (redactar, editar un
   documento, reparar un archivo)? Si sí, esa parte es del asistente,
   siempre, y se entrega completa (archivo entero listo para usar), aunque
   el paso final sea una operación de plataforma.
2. Quitada la producción de contenido, ¿lo que resta es exclusivamente
   mover, descargar, subir o pegar en una plataforma a la que el asistente
   no accede? Solo esa parte se deriva, indicada en una línea.

Si la tarea mezcla ambas capas, se divide: contenido completo primero,
operación mecánica después. Derivar al usuario una tarea sin el test
respondido es una desviación registrable (regla 0.5).

### 0.5 Registro obligatorio de errores del asistente

Todo error del asistente queda registrado en la sesión en que ocurre,
para alimentar la tabla de errores del traspaso de cierre
(`SETTINGS_Y_PROMPTS_OPERACIONALES.md` §2.2.15). Esta regla no es
opcional ni queda a discreción del asistente: el registro es estructural,
igual que el backlog o los bugs de código.

**Qué cuenta como error (disparador exhaustivo):** cualquier desviación
de una regla canónica (POLITICA, SETTINGS, `CLAUDE.md`, `userPreferences`,
o una instrucción explícita ya dada en la sesión) detectada por el
asistente o señalada por el usuario, **se haya nombrado como "error" o
no**. No se limita a los casos donde el asistente dice "me equivoqué" o
"cometí un error": incluye cualquier autocorrección silenciosa, cualquier
corrección que el usuario tenga que pedir, y cualquier momento en que el
asistente reconoce (aunque sea implícitamente, ajustando su respuesta)
que una acción previa no siguió la regla vigente.

**Cuándo se registra:** en el momento en que el error se identifica
(no se difiere "para el cierre"), como una entrada provisional que se
consolida en la sección de errores del traspaso al cerrar la sesión. Si
la sesión termina sin cierre formal, el registro provisional igual debe
quedar visible en el historial de la conversación para que una sesión
futura pueda reconstruirlo.

**Por qué existe esta regla:** las salvaguardas existentes (este
documento, SETTINGS, `CLAUDE.md`, `userPreferences`) no han sido
suficientes por sí solas para prevenir errores repetidos del mismo
patrón. El registro estructurado no sustituye a esas salvaguardas: es un
mecanismo adicional para hacer visible, medible y comparable entre
proyectos un problema que de otro modo solo vive en la memoria de cada
sesión y se pierde al cerrarla.

---

## 1. Estructura de carpetas y nomenclatura

Todo proyecto sigue una estructura de carpetas numeradas según el
**flujo de ejecución**.

### 1.1 Estructura canónica (raíz de código)

```
proyecto/                               ← repo Git
├── 00_run_all.R                        ← orquestador (punto de entrada único)
├── 00_escanear_proyecto.R              ← escáner de estructura
├── 10_utils/                           ← funciones compartidas (se cargan primero)
│   ├── 10_utils.R                      ← bootstrapping (instalar_si_falta, log_msg)
│   └── 10_configuracion.R              ← rutas, constantes, resolución de data root
├── 20_insumos/                         ← datos crudos (read-only) — ver sección 6
├── 30_procesamiento/                   ← ETLs, motores, modelos, app
│   ├── 31_<sub_etapa>.R
│   ├── 32_<sub_etapa>.R
│   └── ...
├── 40_salidas/                         ← outputs generados — ver sección 6
├── 50_documentacion/
│   ├── activa/                         ← documentación vigente (incluye esta política)
│   │   └── decisiones/                 ← YYYYMMDD_decision_<tema>.md
│   ├── traspasos/                      ← handoffs entre sesiones (solo se agregan)
│   ├── andamios/                       ← scripts de refactor ejecutados (congelados)
│   └── estructura/                     ← snapshots del escáner (sección 7)
├── tests/                              ← sin numerar (R: tests/testthat/)
└── _archivo/                           ← obsoletos y snapshots locales (fuera de Git)
    └── YYYYMMDD/
```

En proyectos con datos sensibles, `20_insumos/` y `40_salidas/` físicas
viven FUERA del repo, en la raíz de datos de OneDrive (sección 6.2). El
repo no las contiene.

### 1.2 Principios de numeración

1. **Decenas, no unidades.** `10, 20, 30...` deja espacio para insertar
   sin renumerar. Dentro de `30_procesamiento/`, correlativos `31_, 32_,
   33_` (y saltos internos como `39_app.R` para dejar aire).
2. **El número refleja orden de ejecución.** `00` orquesta, `10` se
   carga primero, `20` se lee, `30` procesa, `40` escribe, `50`
   documenta. Si una carpeta no encaja en este flujo, no merece decena.
3. **Sin saltos entre decenas.** Compactar `10, 20, 30, 40, 50`; los
   huecos son residuos de refactors, no reserva.
4. **Todos los archivos llevan prefijo numérico**, en dos modos:
   - **Sin orden interno** (`10_utils/`, subcarpetas de `50_*`): el
     número de la carpeta como prefijo (`10_utils.R`,
     `10_configuracion.R`, `10_validaciones.R`).
   - **Con orden interno** (`30_procesamiento/`): correlativos por orden
     de ejecución. Los auxiliares no ejecutables toman el número del
     ejecutable que los emplea (`32_motor_calculo.R` +
     `32_funciones_motor.R`).
   - **Excepción declarada:** datos crudos heredados de fuentes externas
     conservan su nombre original. Documentarlo en el README.

### 1.3 Principios de las carpetas

5. **Separación input → procesamiento → output.** `20_insumos/` es
   read-only; `40_salidas/` es write-only desde el pipeline;
   `30_procesamiento/` es la única capa que transforma.
6. **Simetría input/output.** La raíz de datos replica `20_insumos/` y
   `40_salidas/` con las mismas subcarpetas (incluido `publico/privado/`
   si se usa granularidad interna).
7. **Documentación bifurcada.** `activa/` se actualiza in place;
   `traspasos/` solo se agregan; `andamios/` se congelan (sus rutas
   internas no se reescriben jamás); `estructura/` la gestiona el
   escáner.
8. **`tests/` no se numera.** Convención del lenguaje.

### 1.4 `10_utils/`

- Cero dependencias de paquetes cargados: usar `paquete::funcion()`.
  Permite cargar utils antes de cualquier `library()` (bootstrapping).
- Migrar a utils solo con duplicación real: cada función debe ser
  (a) genérica y (b) usada en más de un script. Lo específico de una
  sub-etapa vive en esa sub-etapa.

### 1.5 `_archivo/`

Snapshots de hitos (`_archivo/YYYYMMDD/` conservando ruta relativa) y
obsoletos no asociados a refactors documentados. Criterio: si borrarlo
hoy no rompe nada, va a `_archivo/`, no a la papelera. Excluido de Git.

### 1.6 Anti-patrones

- Carpetas planas con todos los scripts juntos.
- `output/` ambiguo que mezcla intermedios con finales.
- `10_utils/` que importa medio tidyverse en cabecera (rompe el
  bootstrapping).
- Numeración de un dígito o decimal.
- Huecos entre decenas.
- Renombrar carpetas por refactors menores (las carpetas son contratos
  estables; los scripts cambian libremente).
- Correr scripts sueltos como flujo habitual (el método canónico es el
  orquestador; sueltos solo para debug).
- Mezclar funciones genéricas y específicas en `10_utils/`.
- Reescribir rutas en `andamios/` (falsifica el registro histórico).
- Borrar en lugar de archivar.

### 1.7 Qué decide cada proyecto

Las sub-etapas concretas de `30_procesamiento/`; la granularidad
`publico/privado` dentro de la raíz de datos; qué funciones entran a
`10_utils/` desde el día uno; el archivo principal de presentación;
cobertura inicial de tests.

---

## 2. Nombramiento de archivos

- **Orquestadores:** prefijo `00_` en raíz (`00_run_all.R`,
  `00_escanear_proyecto.R`). Pueden coexistir varios `00_*`.
- **General:** snake_case en minúsculas; sin tildes, sin ñ, sin
  espacios. La regla aplica a nombres de carpetas y archivos, NO al
  contenido (comentarios, títulos y textos van en español pleno).
  Excepción declarada: archivos heredados imposibles de renombrar.
- **Sin sufijos de versión en scripts vivos** (`_v3`, `_final`,
  `_nuevo`). El versionado lo dan Git y `_archivo/` (sección 3).
- **Datos crudos:** prefijo `YYYYMMDD_` cuando el dato tiene versión
  temporal. **Datos procesados:** nombre descriptivo sin fecha.
- **Formatos:** `.parquet` para datos masivos; `.xlsx` solo entregables
  finales; `.csv` solo cuando el destino lo exige; JSON con claves
  ordenadas e indentación fija cuando el destino es web/GitHub Pages.
- **Documentos:** traspasos `traspaso_cierre_vNN.md` (correlativo
  global, dos dígitos); documentación técnica
  `documentacion_tecnica_vN.md`; decisiones
  `YYYYMMDD_decision_<tema>.md`.

---

## 3. Versionado

Dos sistemas complementarios: **Git** (historial granular) y
**`_archivo/YYYYMMDD/`** (snapshots de hitos).

- Git desde el primer commit. `.gitignore` según sección 6.3. Commits
  frecuentes, mensajes descriptivos en español. Rama principal `main`;
  branches solo para experimentación paralela.
- El script vivo nunca lleva sufijo de versión: los reemplazos van a
  `_archivo/YYYYMMDD/` conservando su ruta relativa, y el nuevo ocupa
  la ruta limpia. Las rutas activas son estables.
- Snapshot obligatorio antes de refactor mayor o cambio irreversible;
  commit limpio obligatorio antes de cualquier migración estructural
  en modo real.

---

## 4. Orquestador `00_run_all.R`

- Solo orquesta: cero lógica de negocio; no modifica scripts de
  estación; sin caché automático por timestamp (saltar pasos es
  decisión explícita del usuario).
- Ancla la raíz vía `rprojroot::find_root()` (criterios `.here`,
  `.Rproj`, `is_rstudio_project`, `is_git_root`). Carga primero
  `10_utils/10_utils.R` (bootstrapping) y luego
  `10_utils/10_configuracion.R` (validación de precondiciones,
  incluida la resolución del data root: si la variable de entorno no
  resuelve, falla al inicio con mensaje claro, no a mitad de pipeline).
- Lista ordenada `PASOS` (cada paso: `id`, `etiqueta`, `ruta` relativa
  a la raíz). Verifica al inicio que todas las rutas existan.
- Función `run_all()` con argumentos estándar idénticos en todos los
  proyectos: `from`, `to`, `only`, `skip` (combinaciones razonables
  funcionan). Opcionales por proyecto: `refrescar`, `verbose`.
- Por paso: encabezado con separador, ID, etiqueta, ruta; duración
  medida; ante fallo, `stop()` con mensaje claro (no continúa). Al
  final, resumen (ejecutados, saltados, duración total).
- `.R` vía `source(ruta, echo = FALSE, chdir = TRUE)`; `.qmd` vía
  `quarto::quarto_render()`.
- Logging con `log_msg()` (en `10_utils/10_utils.R`), formato
  `[YYYY-MM-DD HH:MM:SS] [origen] [NIVEL] mensaje`, niveles
  INFO/WARN/ERROR, sin paquetes externos.

---

## 5. Principios técnicos de código

Guía operativa, no checklist rígida. Cuando un principio no aplique
(script de uso único, exploratorio), declararlo y justificarlo; la
excepción silenciosa es peor que la omisión declarada.

### 5.1 Interacción (resumen; el contrato completo vive en CLAUDE.md)

Pensar antes de codificar (supuestos explícitos, interpretaciones sobre
la mesa); simplicidad primero (mínimo código, nada especulativo);
cambios quirúrgicos (cada línea modificada se traza al pedido); ejecución
dirigida por objetivos (check de éxito definido antes de codificar).

Tensiones reconocidas: modularidad vs. simplicidad (modularizar solo con
reuso real); validación vs. simplicidad (validar lo que puede fallar en
la práctica); resiliencia vs. simplicidad (backoff y `tryCatch()` solo
ante fuentes externas reales). Declarar la decisión cuando tensen.

### 5.2 Datos y reproducibilidad

1. **Inmutabilidad de la fuente.** Los datos crudos jamás se editan a
   mano; toda corrección es código documentado.
2. **Reproducibilidad completa.** El flujo corre de cero sin
   intervención manual y produce el mismo resultado: semillas fijadas
   (`set.seed()`), sin dependencias de estado, `renv` para proyectos de
   larga vida.
3. **Idempotencia y checkpointing.** Ejecutar N veces produce lo mismo
   sin duplicar; procesos interrumpibles guardan progreso.
4. **Escritura atómica.** Patrón write → rename para todo artefacto que
   alimente otros procesos.

### 5.3 Calidad del código

5. **Modularidad con responsabilidad única**, documentando qué recibe y
   entrega cada función. Separar configuración, I/O, transformación y
   lógica de negocio.
6. **Rigor de nomenclatura y tipado.** `snake_case` siempre
   (`janitor::clean_names()` tras cada lectura). Identificadores que
   actúan como llaves (RBD, RUT, códigos comunales) SIEMPRE como
   `character`, con tipo consistente entre caché y recálculo (un join
   con tipos mezclados falla silenciosamente). Porcentajes como
   decimales hasta la exportación final; no redondear prematuramente.
7. **Portabilidad total.** Prohibidas las rutas absolutas en código:
   `here::here()` desde la raíz de código; funciones de configuración
   para la raíz de datos (sección 6.2). UTF-8 explícito. Excepción:
   dentro de `.qmd`, `source()`/`readRDS()` relativos al `.qmd`.
8. **Validación de integridad.** Checks tras transformaciones críticas:
   NAs en columnas clave, totales pre/post join, rangos esperados.
   Alertar con `warning()`/`message()`, no fallar en silencio.
9. **Resiliencia ante fuentes externas.** Backoff exponencial ante 429;
   `tryCatch()` granular (registrar, guardar progreso, descartar ítem,
   continuar).
10. **Transparencia del cambio.** Comentarios que explican el "por qué";
    filtros y exclusiones con constancia explícita; decisiones
    metodológicas (umbrales, tolerancias, cortes) como constantes
    nombradas al inicio, jamás números mágicos embebidos.
11. **Dependencias explícitas.** `library()` (no `require()`) al inicio;
    bloque de auto-instalación previo (`requireNamespace()` +
    `install.packages()` de faltantes).
12. **Logging y observabilidad.** Progreso informativo en procesos
    largos; resumen final (procesados, errores, duración); errores con
    contexto diagnóstico ("fila 12, RBD 12345: columna 'asistencia'
    contiene 'N/A'", no "error en fila 12").

### 5.4 Convenciones R / Positron

- Tidyverse, pipe nativo `|>`, `dplyr >= 1.1` con `.by=` en
  `mutate()`/`summarize()` en lugar de pares `group_by()/ungroup()`.
- Quarto sobre RMarkdown. `gt`/`reactable` para tablas; `flextable`
  para Word; `tinytable` para typst.
- `theme_minimal()` como base ggplot2. `dplyr::if_else()` jamás con
  condición escalar y argumentos vectoriales.
- Estructura canónica de todo script, en este orden: (1) header banner
  (nombre, propósito, insumos, salidas, autor, fecha); (2) bloque de
  auto-instalación; (3) `library()`; (4) rutas centralizadas; (5)
  constantes y parámetros; (6) funciones; (7) flujo principal
  (lectura → limpieza → transformación → validación → exportación).
  Nada de rutas, paquetes ni constantes en medio del flujo.
- Comentarios en español, bloques `# ---- Nombre ----`.

### 5.5 Excel (locale español) y web estática

Excel: decimal `,`, miles `.`, separador de argumentos `;`, funciones
en español. Web (GitHub Pages): HTML5 semántico de archivo único, CSS/JS
inline o locales, SVGs inline, JSON como formato de datos, sin
dependencias externas salvo necesidad estricta.

### 5.6 Auditoría del proyecto (apertura y cierre)

Checklist corto a correr al abrir un proyecto (deuda heredada) y al
cerrar una entrega (cumplimiento). Es legítimo declarar excepciones;
no es legítimo saltarse la pregunta.

| # | Pregunta | Cuándo | Si la respuesta es "no" |
|---|----------|--------|--------------------------|
| 1 | ¿Datos crudos aislados e inmutables? | Apertura | Aislarlos antes de seguir |
| 2 | ¿El pipeline corre de cero sin intervención manual? | Apertura y cierre | Eliminar la dependencia de estado |
| 3 | ¿Paquetes, rutas y constantes declarados al inicio de cada script? | Apertura | Centralizarlos según 5.4 |
| 4 | ¿La estructura respeta esta política (decenas, naming, ubicación)? | Apertura | Documentar como deuda heredada y proponer pendiente |
| 5 | ¿Cada transformación crítica tiene check de validación? | Cierre | Agregar al menos uno por paso crítico (5.3.8) |
| 6 | ¿Los outputs son reproducibles e idempotentes? | Cierre | Revisar escritura atómica y semillas |
| 7 | ¿Decisiones metodológicas como constantes nombradas? | Cierre | Extraer números mágicos (5.3.10) |
| 8 | ¿Nombres de archivos y carpetas sin tildes, ñ ni espacios? | Apertura y cierre | Renombrar y actualizar referencias |

Toda respuesta "no" al cierre se convierte en pendiente del traspaso.

---

## 6. Gobernanza de datos y arquitectura de dos raíces

### 6.1 Principio rector

Cuando el proyecto maneja datos personales (RUT, nombres, datos
individuales identificables, especialmente de menores), esos datos
**jamás entran al repositorio Git ni salen del control institucional**.
La separación es física, no solo de `.gitignore`.

### 6.2 Modelo canónico de dos raíces (proyectos con datos sensibles)

- **Raíz de código:** repo Git privado, fuera de OneDrive (típicamente
  `~/Projects/<nombre_proyecto>`; evita conflictos de sincronización
  con `.git/objects/`). Contiene código, configuración, documentación
  no sensible. `20_insumos/` y `40_salidas/` NO existen aquí.
- **Raíz de datos:** carpeta en OneDrive institucional
  (`.../OneDrive-SLEP/Proyectos/<nombre_proyecto>/`) con `20_insumos/`
  y `40_salidas/` físicas, replicando la granularidad interna que el
  proyecto necesite (`auxiliares/`, `publico/`, `privado/`, por fuente).
- **Conexión:** variable de entorno en `~/.Renviron`, generada desde
  `nombre_proyecto` en MAYÚSCULAS más sufijo `_DATA_ROOT`, **sin
  abreviar ni recortar** (la consistencia vale más que la brevedad).
  Ej.: `seguimiento_educacion_inicial` →
  `SEGUIMIENTO_EDUCACION_INICIAL_DATA_ROOT`. Esta regla es única y
  canónica; deroga cualquier convención previa que recortara prefijos.
- **Resolución dinámica:** `10_utils/10_configuracion.R` define
  `PROYECTO_ID`, resuelve el data root vía la variable de entorno
  (helper genérico `10_utils/10_resolver_rutas.R`, copiado idéntico
  desde `herramientas_dev/`, nunca editado por proyecto) y expone
  `ruta_insumos(...)` y `ruta_salidas(...)`. Todo acceso a datos pasa
  por estas funciones. Si la variable no resuelve, fallo inmediato con
  mensaje claro indicando cómo configurarla.
- **`.Renviron.example`** en la raíz del repo documenta la variable con
  ejemplos por sistema operativo (macOS/Windows).
- Proyectos 100% públicos usan **raíz unificada**: `20_insumos/` y
  `40_salidas/` viven en el repo y se versionan si el tamaño lo permite
  (sección 8.2).

### 6.3 `.gitignore` blindado (proyectos con datos sensibles)

```
# Datos (defensa en profundidad: las carpetas viven fuera del repo,
# pero se blindan igual por si alguien las recrea localmente)
20_insumos/
40_salidas/
*.csv
*.xlsx
*.parquet
*.rds
*.sqlite
*.db
*.feather

# Excepciones para datos sintéticos y de ejemplo
!20_insumos/publico/ejemplos/

# Credenciales
.env
.Renviron
*credentials*
*secret*
*token*
*password*

# Sistema
.Rproj.user/
.Rhistory
.RData
.vscode/
.idea/
.DS_Store
Thumbs.db
# Nota: *.Rproj SÍ se versiona (es el ancla del proyecto; sin él,
# here::here() no resuelve en otra máquina). Solo .Rproj.user/ se ignora.

# Snapshots y backups locales
_archivo/
*.bak

# Outputs accidentales en raíz y scripts de diagnóstico
/*.docx
/*.pdf
/*.html
/diagnostico_*.md
/verificar_*.R
/listar_*.R

# Outputs temporales
*_freeze/
.quarto/
```

Para proyectos públicos, omitir el bloque de datos y conservar el resto.

### 6.4 Marco normativo

- **Chile:** Ley 19.628 (vida privada); Ley 21.719 (protección de datos,
  vigente desde diciembre 2026); Ley 19.223 (delitos informáticos);
  Ley 21.663 (Ciberseguridad); Ley 21.180 (Transformación Digital);
  Ley 21.658 (Secretaría de Gobierno Digital); D.S. 83/2005 MINSEGPRES
  (seguridad y confidencialidad de documentos electrónicos); Estrategia
  de Datos del Estado.
- **Agencia de Calidad (contractual):** Condiciones de Uso de Bases de
  Datos (SIMCE, IDPS): no identificar establecimientos por nombre en
  ningún output; no transferir bases a terceros; acceso restringido al
  equipo declarado; quien abandona el equipo no se lleva los datos.
  Principios CIA según NCh-ISO 27001:2013 y 27002:2009 (Política
  General de Seguridad, REX 1440/2014 y REX 1459/2016).
- **Internacional:** GDPR y principios OCDE como referencia.

Decisiones técnicas con implicancia normativa se documentan en
`50_documentacion/activa/decisiones/`.

---

## 7. Escáner de estructura (`00_escanear_proyecto.R`)

### 7.1 Propósito y disparadores

Mecanismo para que cualquier agente sepa dónde está parado sin deducir
rutas. Ejecutar: (1) al abrir sesión sobre un proyecto en curso; (2)
tras reorganizar estructura; (3) antes de cerrar sesión; (4) cuando un
asistente pierde referencia (regla 0.2).

### 7.2 Alcance y exclusiones

- Escanea SOLO la raíz de código (basado en `here` + `fs`).
- Excluye carpetas ocultas y de sistema: `.git/`, `.Rproj.user/`,
  `renv/`, `.quarto/`.
- **Jamás escanea la raíz de datos en OneDrive.** El snapshot se
  versiona en Git; mapear el data root filtraría nombres de archivos
  con información sensible. Si se necesita inventariar datos, es una
  operación separada, manual y nunca versionada.
- `_archivo/` se excluye o incluye según preferencia del proyecto
  (parámetro al inicio del script).

### 7.3 Output

En `50_documentacion/estructura/`:

- Snapshots sellados: `YYYYMMDD_HHMMSS_estructura.txt` y
  `YYYYMMDD_HHMMSS_estructura.md` (mismo contenido; el `.md` optimizado
  para adjuntar a sesiones).
- Aliases estáticos `estructura_actual.txt` y `estructura_actual.md`,
  siempre copia del snapshot más reciente.
- Contenido: header (raíz, fecha, totales), árbol completo con tamaños,
  conteo por extensión.

### 7.4 Poda estricta de snapshots (retención = 2)

El escáner mantiene **únicamente los 2 timestamps sellados más
recientes** (cada uno con su par `.txt`/`.md`). Algoritmo atómico, en
este orden:

1. Escribir el snapshot nuevo (par `.txt`/`.md` con timestamp).
2. Actualizar los aliases `estructura_actual.*` copiando el nuevo.
3. Solo si 1 y 2 terminaron sin error: listar los archivos que calzan
   con `^\d{8}_\d{6}_estructura\.(txt|md)$`, ordenar por timestamp
   descendente, conservar los 2 timestamps más recientes y eliminar
   todo lo anterior.
4. Los aliases nunca se podan. Cualquier archivo que no calce con el
   patrón no se toca.

Si la escritura del snapshot nuevo falla, no se poda nada: la corrida
fallida no puede destruir el histórico existente.

---

## 8. Inicialización de proyectos nuevos (bifurcación por sensibilidad)

Al iniciar un proyecto nuevo, la **primera decisión obligatoria** es el
nivel de sensibilidad de los datos. De ella depende la arquitectura. El
asistente debe formularla explícitamente si el usuario no la declaró.

### 8.1 Pregunta de bifurcación

> ¿El proyecto procesará en algún punto datos personales o protegidos
> (RUT, nombres de estudiantes, asistencia nominal, resultados SIMCE
> individuales, datos de funcionarios)?

Ante duda, tratar como sensible: bajar de sensible a público es
trivial; subir de público a sensible exige limpiar historial de Git.

### 8.2 Rama A — Proyecto 100% público

Raíz unificada en el repo:

1. Crear la estructura canónica completa (sección 1.1), incluidas
   `20_insumos/` y `40_salidas/` dentro del repo.
2. `.gitignore` estándar sin el bloque de datos (sección 6.3).
3. `10_utils/10_configuracion.R` con rutas vía `here::here()`
   exclusivamente; sin variable de entorno ni data root externo.
4. Resto del checklist común (8.4).

### 8.3 Rama B — Proyecto con datos privados o sensibles

Estructura bifurcada obligatoria:

1. **Repo (raíz de código)** en `~/Projects/<nombre_proyecto>`:
   estructura canónica SIN `20_insumos/` ni `40_salidas/`.
2. **Raíz de datos** en OneDrive institucional:
   `<WORKSPACE_DATA_ROOT>/<nombre_proyecto>/{20_insumos,40_salidas}/`
   (creación manual del usuario o instrucción de una línea; no requiere
   script).
3. **Variable de entorno** `<NOMBRE_PROYECTO_MAYUS>_DATA_ROOT` agregada
   a `~/.Renviron` apuntando a la raíz de datos (regla de nombres de
   6.2).
4. **`.gitignore` blindado** completo (6.3) desde el primer commit.
5. **`10_utils/10_resolver_rutas.R`** copiado idéntico desde
   `herramientas_dev/` y **`10_utils/10_configuracion.R`** con
   `PROYECTO_ID`, `obtener_data_root_proyecto()` (con caché),
   `ruta_insumos()` y `ruta_salidas()`.
6. **`.Renviron.example`** en la raíz del repo con la variable
   documentada y ejemplos por sistema operativo.
7. **Validación obligatoria antes del primer commit:**

   ```r
   source(here::here("10_utils", "10_configuracion.R"))
   obtener_data_root_proyecto()   # ruta válida
   dir.exists(ruta_insumos())     # TRUE
   dir.exists(ruta_salidas())     # TRUE
   ```

8. **README** con sección "Configuración inicial en una máquina nueva"
   (clonar, copiar `.Renviron.example` a `~/.Renviron`, ajustar la ruta,
   reiniciar R, validar) y aviso explícito: "Este repositorio NO
   contiene datos reales. Los datos se obtienen de [fuente] y se colocan
   en la raíz de datos externa."

El script `scaffold_proyecto.R` de `herramientas_dev/` automatiza ambas
ramas mediante el parámetro `maneja_datos_sensibles` y deja instalado el
escáner, el `.gitignore` correspondiente y los stubs de configuración.

### 8.4 Checklist común de inicio (ambas ramas)

- [ ] Estructura de carpetas creada según la rama.
- [ ] `00_run_all.R` con stub funcional y `00_escanear_proyecto.R` en raíz.
- [ ] `10_utils/10_utils.R` con bootstrapping (`instalar_si_falta`, `log_msg`).
- [ ] Git inicializado, `.gitignore` correcto, primer commit.
- [ ] `README.md` mínimo.
- [ ] `POLITICA_PROYECTO.md` (este documento) y
      `SETTINGS_Y_PROMPTS_OPERACIONALES.md` copiados a
      `50_documentacion/activa/` (o disponibles en la knowledge base
      del Project).
- [ ] `CLAUDE.md` copiado a la raíz del repo.
- [ ] Primer escaneo ejecutado.
- [ ] Rama B: validación del punto 8.3.7 ejecutada y en verde.

---

## 9. Migración de proyectos existentes

No improvisar: protocolos detallados en
`SETTINGS_Y_PROMPTS_OPERACIONALES.md` (secciones 4.2 y 4.3) con el
motor `99_reorganizar_estructura_PLANTILLA.R`. Reglas no negociables,
independiente de quién ejecute:

1. Diagnóstico de referencias literales en código ANTES del mapeo (no
   solo `here::here()`: también `file.path()`, `test_path()`,
   comentarios, tests). Sin él, los regex de reescritura fallan en
   silencio.
2. `DRY_RUN <- TRUE` obligatorio primero; el reporte se revisa antes
   del modo real. Mantener esta postura incluso ante presión del
   usuario por ir más rápido.
3. Commit limpio en Git antes del modo real.
4. Backups `.bak` se preservan hasta validar end-to-end.
5. No reescribir rutas en `andamios/`.
6. No combinar fases (renombrar carpetas, renombrar archivos, reescribir
   código: tres operaciones, tres validaciones).
7. No mezclar la migración con otros tipos de cambio (refactors,
   bugfixes, features van en sesiones y commits separados).
8. No borrar carpetas históricas sin verificar copia íntegra.
9. Registrar cada cambio en `_archivo/log_reorganizacion.csv` (tipo,
   ruta vieja, ruta nueva, ocurrencias, timestamp).
10. Validación post-migración antes de borrar `.bak`: reiniciar R,
    tests, orquestador end-to-end, verificación visual.

Migrar solo proyectos con trabajo sostenido por delante; una migración
a medias es peor que no migrar.

---

## 10. Documentación mínima del proyecto

- **`README.md`:** qué hace, cómo correr el pipeline, estructura
  (referencia a esta política), de dónde obtener los datos (sin
  incluirlos), configuración de máquina nueva (Rama B), aviso de
  gobernanza si aplica.
- **`50_documentacion/activa/documentacion_tecnica_vN.md`:** decisiones
  arquitectónicas vigentes, constantes, convenciones específicas.
- **`50_documentacion/activa/gobernanza_datos.md`** (obligatorio en
  proyectos con datos sensibles): qué datos maneja el proyecto,
  categoría según Ley 21.719 (personales / sensibles / de NNA), quién
  tiene acceso, dónde se almacenan los datos reales, base legal del
  tratamiento, período de retención, procedimiento ante incidente de
  seguridad.
- **`LICENSE`** (al publicar en repo remoto): MIT sugerida para el
  código, con cláusula explícita de que no aplica a los datos.
- **`50_documentacion/activa/decisiones/`:** una decisión por archivo,
  autocontenida, con alternativas y justificación.
- **`50_documentacion/traspasos/`:** cierres de sesión
  `traspaso_cierre_vNN.md`.
- **`50_documentacion/activa/backlog_acumulativo.md`** (obligatorio a
  partir de la segunda sesión): backlog acumulativo del proyecto. Nombre
  canónico exacto: `backlog_acumulativo.md`; ubicación canónica:
  `50_documentacion/activa/`. Estructura interna: cinco secciones en
  este orden — Objetivo del proyecto, Nota metodológica, Clasificación
  temática, Resumen estadístico por sesión, Detalle cronológico. Ver
  protocolo completo en `SETTINGS_Y_PROMPTS_OPERACIONALES.md` §2.2.5.
  En el primer cierre el backlog va embebido en el traspaso; a partir
  del segundo cierre se extrae a este archivo y el traspaso referencia
  su ruta.
- **`50_documentacion/andamios/`:** refactors ejecutados, congelados.

---

## 11. Glosario

- **Raíz de código / raíz de datos:** las dos raíces del modelo de la
  sección 6.2 (repo Git / OneDrive institucional).
- **Data root:** ruta física de la raíz de datos, resuelta por variable
  de entorno `<PROYECTO>_DATA_ROOT`.
- **Decena:** rango de 10 enteros asignado a una etapa del flujo.
- **Sub-etapa:** división interna de `30_procesamiento/` (`31_`, `32_`...).
- **Orquestador:** `00_run_all.R`, punto de entrada único del pipeline.
- **Escáner:** `00_escanear_proyecto.R` (sección 7).
- **Snapshot sellado:** par `.txt`/`.md` con timestamp emitido por el
  escáner; sujeto a poda de retención 2.
- **Traspaso:** documento de cierre que permite retomar en sesión futura.
- **Andamio:** script de refactor ejecutado, congelado como registro.
- **Bootstrapping:** carga inicial previa a cualquier `library()`; las
  funciones de `10_utils/` no dependen de paquetes cargados.
- **DRY_RUN:** modo simulación obligatorio de toda reorganización
  estructural.
