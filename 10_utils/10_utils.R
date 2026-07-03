# ============================================================================
# 10_utils.R
# Proposito: funciones de bootstrapping compartidas (instalacion condicional
#            de paquetes y logging) que se cargan ANTES de cualquier library().
# Insumos:   ninguno
# Salidas:   instalar_si_falta(), log_msg() en el entorno de ejecucion
# Autor:     [tu nombre]
# Fecha:     2026-07-02
# ============================================================================
# Regla de bootstrapping: este archivo NO puede depender de ningun paquete
# cargado. Todo acceso a paquetes usa la forma paquete::funcion().

# ---- Instalacion condicional de paquetes ----
instalar_si_falta <- function(paquetes) {
  faltantes <- paquetes[!vapply(
    paquetes,
    function(p) requireNamespace(p, quietly = TRUE),
    logical(1)
  )]
  if (length(faltantes) > 0) {
    message("Instalando paquetes faltantes: ", paste(faltantes, collapse = ", "))
    utils::install.packages(faltantes)
  }
  invisible(TRUE)
}

# ---- Logging sin dependencias externas ----
# Formato: [YYYY-MM-DD HH:MM:SS] [origen] [NIVEL] mensaje
log_msg <- function(mensaje,
                    nivel = c("INFO", "WARN", "ERROR"),
                    origen = "general") {
  nivel <- match.arg(nivel)
  marca <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  cat(sprintf("[%s] [%s] [%s] %s\n", marca, origen, nivel, mensaje))
  invisible(NULL)
}
