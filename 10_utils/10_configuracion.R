# ============================================================================
# 10_configuracion.R
# Proposito: resolucion de rutas y constantes globales. Rama A (proyecto
#            publico, raiz unificada): todas las rutas se resuelven con
#            here::here() dentro del repo. Sin variable de entorno ni data
#            root externo.
# Insumos:   here
# Salidas:   PROYECTO_ID, ruta_insumos(), ruta_salidas(); valida la
#            estructura al cargar.
# Autor:     [tu nombre]
# Fecha:     2026-07-02
# ============================================================================

# ---- Auto-instalacion ----
if (!requireNamespace("here", quietly = TRUE)) utils::install.packages("here")

# ---- Identidad del proyecto ----
PROYECTO_ID <- "mundial2026_confederaciones"

# ---- Resolucion de rutas (todas dentro del repo) ----
ruta_insumos <- function(...) here::here("20_insumos", ...)
ruta_salidas <- function(...) here::here("40_salidas", ...)

# ---- Validacion de precondiciones ----
.validar_estructura <- function() {
  base <- c("20_insumos", "30_procesamiento", "40_salidas")
  faltan <- base[!dir.exists(vapply(base, here::here, character(1)))]
  if (length(faltan) > 0) {
    stop(
      "Faltan carpetas base del proyecto: ", paste(faltan, collapse = ", "),
      ". Revisa que here::here() apunte a la raiz correcta.",
      call. = FALSE
    )
  }
  invisible(TRUE)
}
.validar_estructura()
