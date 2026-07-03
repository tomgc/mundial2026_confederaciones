# ============================================================================
# 00_run_all.R
# Proposito: orquestador unico del pipeline. Solo orquesta: sin logica de
#            negocio, sin cache automatico por timestamp. Saltar pasos es
#            decision explicita del usuario.
# Insumos:   scripts de 30_procesamiento/ listados en PASOS
# Salidas:   ejecucion ordenada del pipeline + resumen
# Autor:     [tu nombre]
# Fecha:     2026-07-02
# ============================================================================

# ---- Anclaje de raiz ----
if (!requireNamespace("rprojroot", quietly = TRUE)) utils::install.packages("rprojroot")
RAIZ <- rprojroot::find_root(
  rprojroot::has_file(".here") |
    rprojroot::is_rstudio_project |
    rprojroot::is_git_root
)

# ---- Carga de utilidades (bootstrapping primero, configuracion despues) ----
source(file.path(RAIZ, "10_utils", "10_utils.R"), echo = FALSE)
source(file.path(RAIZ, "10_utils", "10_configuracion.R"), echo = FALSE)

# ---- Definicion de pasos ----
# Cada paso: id (correlativo), etiqueta (descripcion), ruta (relativa a RAIZ).
PASOS <- list(
  list(id = 1, etiqueta = "Ingesta de fuerza (FIFA + Elo + confederacion)", ruta = "30_procesamiento/31_ingesta_fuerza.R"),
  list(id = 2, etiqueta = "Ingesta de resultados del torneo",              ruta = "30_procesamiento/32_ingesta_resultados.R"),
  list(id = 3, etiqueta = "Motor Elo/FIFA SUM y rating de confederacion",  ruta = "30_procesamiento/33_motor_elo.R"),
  list(id = 4, etiqueta = "Reporte por confederacion",                     ruta = "30_procesamiento/39_reporte.R")
)

# ---- Verificacion de existencia de rutas al inicio ----
.verificar_rutas <- function(pasos) {
  faltan <- Filter(function(p) !file.exists(file.path(RAIZ, p$ruta)), pasos)
  if (length(faltan) > 0) {
    rutas <- vapply(faltan, function(p) p$ruta, character(1))
    log_msg(paste("Rutas inexistentes:", paste(rutas, collapse = ", ")), "WARN", "run_all")
  }
  invisible(TRUE)
}

# ---- Orquestador ----
run_all <- function(from = NULL, to = NULL, only = NULL, skip = NULL) {
  .verificar_rutas(PASOS)
  ids <- vapply(PASOS, function(p) p$id, numeric(1))
  seleccion <- ids
  if (!is.null(from)) seleccion <- seleccion[seleccion >= from]
  if (!is.null(to))   seleccion <- seleccion[seleccion <= to]
  if (!is.null(only)) seleccion <- only
  if (!is.null(skip)) seleccion <- setdiff(seleccion, skip)

  ejecutados <- character(0)
  saltados   <- character(0)
  t_total    <- Sys.time()

  for (paso in PASOS) {
    if (!(paso$id %in% seleccion)) {
      saltados <- c(saltados, paso$etiqueta)
      next
    }
    cat("\n", strrep("=", 70), "\n", sep = "")
    cat(sprintf("[PASO %d] %s\n", paso$id, paso$etiqueta))
    cat(sprintf("Ruta: %s\n", paso$ruta))
    cat(strrep("=", 70), "\n", sep = "")

    ruta_abs <- file.path(RAIZ, paso$ruta)
    if (!file.exists(ruta_abs)) {
      stop(sprintf("Paso %d: no existe %s", paso$id, paso$ruta), call. = FALSE)
    }

    t0 <- Sys.time()
    tryCatch(
      source(ruta_abs, echo = FALSE, chdir = TRUE),
      error = function(e) {
        stop(sprintf("Paso %d fallo (%s): %s", paso$id, paso$ruta, conditionMessage(e)),
             call. = FALSE)
      }
    )
    dur <- round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1)
    log_msg(sprintf("Paso %d completado en %s s", paso$id, dur), "INFO", "run_all")
    ejecutados <- c(ejecutados, paso$etiqueta)
  }

  cat("\n", strrep("-", 70), "\n", sep = "")
  cat(sprintf("Resumen: %d ejecutados, %d saltados. Duracion total: %s s\n",
              length(ejecutados), length(saltados),
              round(as.numeric(difftime(Sys.time(), t_total, units = "secs")), 1)))
  cat(strrep("-", 70), "\n", sep = "")
  invisible(list(ejecutados = ejecutados, saltados = saltados))
}

# ---- Ejemplos de uso ----
# run_all()                 # corre todo el pipeline
# run_all(skip = c(1, 2))   # omite ingesta, corre motor y reporte
# run_all(from = 3)         # desde el motor en adelante
# run_all(only = 4)         # solo el reporte
