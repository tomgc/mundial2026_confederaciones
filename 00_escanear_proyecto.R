# ============================================================================
# 00_escanear_proyecto.R
# Proposito: escanear la raiz de codigo y emitir un snapshot de estructura
#            (arbol con tamanos + conteo por extension) para que cualquier
#            agente sepa donde esta parado sin deducir rutas.
# Insumos:   here, fs
# Salidas:   50_documentacion/estructura/ con snapshots sellados
#            (YYYYMMDD_HHMMSS_estructura.{txt,md}) y aliases
#            estructura_actual.{txt,md}. Retencion estricta de 2 snapshots.
# Autor:     [tu nombre]
# Fecha:     2026-07-02
# ============================================================================

if (!requireNamespace("here", quietly = TRUE)) utils::install.packages("here")
if (!requireNamespace("fs", quietly = TRUE))   utils::install.packages("fs")

# ---- Parametros ----
INCLUIR_ARCHIVO <- FALSE  # TRUE para incluir _archivo/ en el escaneo
EXCLUIR <- c(".git", ".Rproj.user", "renv", ".quarto")
if (!INCLUIR_ARCHIVO) EXCLUIR <- c(EXCLUIR, "_archivo")

RAIZ <- here::here()
DIR_ESTRUCTURA <- here::here("50_documentacion", "estructura")

# ---- Escritura atomica (write -> rename) ----
.escribir_atomico <- function(destino, contenido) {
  tmp <- paste0(destino, ".tmp")
  writeLines(contenido, tmp, useBytes = TRUE)
  file.rename(tmp, destino)
  invisible(destino)
}

# ---- Recoleccion del arbol ----
.listar <- function(raiz, excluir) {
  todos <- fs::dir_ls(raiz, recurse = TRUE, all = FALSE, type = c("file", "directory"))
  rel <- fs::path_rel(todos, raiz)
  mantener <- !vapply(rel, function(p) {
    partes <- strsplit(p, .Platform$file.sep, fixed = TRUE)[[1]]
    any(partes %in% excluir)
  }, logical(1))
  todos[mantener]
}

.formatear_arbol <- function(rutas, raiz) {
  rel <- as.character(fs::path_rel(rutas, raiz))
  orden <- order(rel)
  rutas <- rutas[orden]
  rel <- rel[orden]
  vapply(seq_along(rutas), function(i) {
    prof <- length(strsplit(rel[i], .Platform$file.sep, fixed = TRUE)[[1]]) - 1L
    sangria <- strrep("  ", prof)
    nombre <- fs::path_file(rel[i])
    if (fs::is_dir(rutas[i])) {
      sprintf("%s%s/", sangria, nombre)
    } else {
      sprintf("%s%s  (%s)", sangria, nombre, format(fs::file_size(rutas[i])))
    }
  }, character(1)) |> paste(collapse = "\n")
}

.conteo_extension <- function(rutas) {
  archivos <- rutas[fs::is_file(rutas)]
  ext <- fs::path_ext(archivos)
  ext[ext == ""] <- "(sin ext)"
  tab <- sort(table(ext), decreasing = TRUE)
  paste(sprintf("  .%s: %d", names(tab), as.integer(tab)), collapse = "\n")
}

# ---- Generacion del snapshot ----
.generar <- function() {
  if (!dir.exists(DIR_ESTRUCTURA)) dir.create(DIR_ESTRUCTURA, recursive = TRUE)

  rutas  <- .listar(RAIZ, EXCLUIR)
  n_dir  <- sum(fs::is_dir(rutas))
  n_file <- sum(fs::is_file(rutas))

  header <- sprintf(
    "Raiz: %s\nFecha: %s\nTotales: %d carpetas, %d archivos\n",
    RAIZ, format(Sys.time(), "%Y-%m-%d %H:%M:%S"), n_dir, n_file
  )
  cuerpo <- paste0(
    header,
    "\n", strrep("=", 60), "\nARBOL\n", strrep("=", 60), "\n",
    .formatear_arbol(rutas, RAIZ),
    "\n\n", strrep("=", 60), "\nCONTEO POR EXTENSION\n", strrep("=", 60), "\n",
    .conteo_extension(rutas), "\n"
  )
  cuerpo_md <- paste0("```\n", cuerpo, "```\n")

  sello <- format(Sys.time(), "%Y%m%d_%H%M%S")
  archivo_txt <- file.path(DIR_ESTRUCTURA, paste0(sello, "_estructura.txt"))
  archivo_md  <- file.path(DIR_ESTRUCTURA, paste0(sello, "_estructura.md"))

  # 1. Escribir snapshot nuevo
  .escribir_atomico(archivo_txt, cuerpo)
  .escribir_atomico(archivo_md, cuerpo_md)

  # 2. Actualizar aliases (nunca se podan)
  .escribir_atomico(file.path(DIR_ESTRUCTURA, "estructura_actual.txt"), cuerpo)
  .escribir_atomico(file.path(DIR_ESTRUCTURA, "estructura_actual.md"), cuerpo_md)

  # 3. Poda estricta (retencion = 2): solo despues de 1 y 2 sin error
  patron <- "^\\d{8}_\\d{6}_estructura\\.(txt|md)$"
  sellados <- list.files(DIR_ESTRUCTURA, pattern = patron)
  timestamps <- sort(unique(sub("_estructura\\.(txt|md)$", "", sellados)),
                     decreasing = TRUE)
  if (length(timestamps) > 2) {
    for (ts in timestamps[-(1:2)]) {
      file.remove(file.path(DIR_ESTRUCTURA, paste0(ts, "_estructura.txt")))
      file.remove(file.path(DIR_ESTRUCTURA, paste0(ts, "_estructura.md")))
    }
  }

  registrar <- if (exists("log_msg")) log_msg else function(m, ...) cat(m, "\n")
  registrar(sprintf("Snapshot generado: %s (%d carpetas, %d archivos)",
                    sello, n_dir, n_file), "INFO", "escaner")
  invisible(cuerpo)
}

.generar()
