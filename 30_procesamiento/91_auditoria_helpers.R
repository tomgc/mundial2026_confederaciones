# ============================================================================
# 91_auditoria_helpers.R
# Proposito: funciones compartidas por las familias de auditoria (protocolo
#            4.5, SETTINGS). Cada familia compara una cifra publicada contra
#            un recalculo por camino independiente, dentro de tolerancia.
# Insumos:   ninguno directo (funciones puras)
# Salidas:   ninguna directa (se usan desde 92_auditoria_orquestador.R)
# Autor:     pipeline mundial2026_confederaciones
# Fecha:     2026-07-03
# ============================================================================

if (!exists("ruta_insumos")) {
  source(here::here("10_utils", "10_utils.R"))
  source(here::here("10_utils", "10_configuracion.R"))
}

library(dplyr)
library(tibble)

# ---- Tolerancias (constantes nombradas, politica C.10) ----
TOLERANCIA_ESTRICTA <- 1e-9   # familias sin fuente de redondeo intermedio (Familia A)
TOLERANCIA_REDONDEO  <- 0.01  # familias que comparan contra un CSV con valores
                               # ya redondeados a 3-4 decimales (Familias B y C);
                               # el redondeo intermedio acumulado justifica el
                               # margen, no un error de calculo

# ---- Comparador generico de una cifra: dos caminos, una tolerancia ----
# `valor_publicado` y `valor_recalculado` deben venir alineados por la misma
# llave (character, politica C.6). Retorna una tibble de discrepancias
# (vacia si todo esta dentro de tolerancia) mas un resumen impreso.
comparar_cifra <- function(llave, valor_publicado, valor_recalculado,
                            tolerancia, nombre_familia, nombre_cifra) {
  stopifnot(
    "llave debe ser character" = is.character(llave),
    "largos deben coincidir" = length(llave) == length(valor_publicado),
    length(valor_publicado) == length(valor_recalculado)
  )
  diff_abs <- abs(valor_publicado - valor_recalculado)
  tabla <- tibble::tibble(
    llave = llave,
    publicado = valor_publicado,
    recalculado = valor_recalculado,
    diff_abs = diff_abs
  ) |>
    dplyr::filter(diff_abs > tolerancia) |>
    dplyr::arrange(dplyr::desc(diff_abs))

  n_total <- length(llave)
  n_fallos <- nrow(tabla)
  estado <- if (n_fallos == 0) "OK" else "FALLO"
  log_msg(sprintf("[%s] %s: %d/%d dentro de tolerancia (%.g) -> %s",
                   nombre_familia, nombre_cifra, n_total - n_fallos, n_total,
                   tolerancia, estado),
          if (n_fallos == 0) "INFO" else "WARN", "auditoria")

  tabla
}

# ---- Registro consolidado de resultados de todas las familias ----
# Cada familia llama a esta funcion para acumular su resultado; el
# orquestador (92) construye el reporte final a partir de esta lista.
nuevo_registro_auditoria <- function() {
  list()
}

registrar_resultado <- function(registro, nombre_familia, nombre_cifra, tabla_discrepancias) {
  clave <- paste(nombre_familia, nombre_cifra, sep = " / ")
  registro[[clave]] <- tabla_discrepancias
  registro
}
