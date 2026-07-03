# ============================================================================
# 31_ingesta_fuerza.R
# Proposito: construir la tabla de fuerza pre-torneo de las 48 selecciones
#            del Mundial 2026. Une tres insumos:
#            (1) maestro estable (equipo, confederacion, grupo),
#            (2) ranking FIFA snapshot 11-jun-2026 (insumo fijo verificado),
#            (3) Elo de eloratings.net (scraping secundario).
#            La fuente de la fuerza base es configurable (FUENTE_FUERZA).
# Insumos:   20_insumos/equipos_mundial2026.csv        (maestro)
#            20_insumos/ranking_fifa_20260611.csv       (FIFA, snapshot oficial)
#            + scraping web (eloratings.net) para el Elo
# Salidas:   40_salidas/fuerza_equipos.csv (48 filas, escritura atomica)
# Autor:     [tu nombre]
# Fecha:     2026-07-02
# ============================================================================

# ---- Auto-instalacion ----
.pkgs <- c("here", "rvest", "dplyr", "stringr", "readr", "janitor", "purrr",
           "tibble", "stringi")
.falta <- .pkgs[!vapply(.pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(.falta) > 0) utils::install.packages(.falta)

# ---- Dependencias ----
library(rvest)
library(dplyr)
library(stringr)
library(readr)
library(purrr)

# ---- Carga de utilidades si corre en modo standalone ----
if (!exists("ruta_insumos")) {
  source(here::here("10_utils", "10_utils.R"))
  source(here::here("10_utils", "10_configuracion.R"))
}

# ---- Constantes y parametros ----
ARCHIVO_MAESTRO <- ruta_insumos("equipos_mundial2026.csv")
ARCHIVO_FIFA    <- ruta_insumos("ranking_fifa_20260611.csv")  # snapshot fijo, pre-torneo
ARCHIVO_SALIDA  <- ruta_salidas("fuerza_equipos.csv")

URL_ELO <- "https://www.eloratings.net/2026"  # ratings actuales de eloratings.net

# Fuente de la fuerza base del modelo. Opciones: "fifa" | "elo" | "compuesto".
# "fifa"      respeta el requisito explicito (ponderar por ranking FIFA).
# "elo"       usa el rating Elo continuo (natural para inicializar un Elo).
# "compuesto" combina ambas segun PESO_COMPUESTO (requiere Elo disponible).
FUENTE_FUERZA  <- "fifa"
PESO_COMPUESTO <- c(fifa = 0.6, elo = 0.4)

INCLUIR_ELO  <- TRUE   # scrapear Elo como segundo indicador
N_EQUIPOS    <- 48L
PAUSA_SCRAPE <- 2      # segundos entre requests (cortesia con el servidor)

# ---- Utilidad: escritura atomica (write -> rename), politica C.4 ----
escribir_csv_atomico <- function(df, destino) {
  tmp <- paste0(destino, ".tmp")
  readr::write_csv(df, tmp)
  file.rename(tmp, destino)
  invisible(destino)
}

# ---- Utilidad: clave de join normalizada (para el Elo, que llega por nombre) ----
clave_nombre <- function(x) {
  x |>
    stringr::str_to_lower() |>
    stringi::stri_trans_general("Latin-ASCII") |>
    stringr::str_replace_all("[^a-z ]", " ") |>
    stringr::str_squish()
}

# Diccionario de alias: nombre_fuente (clave normalizada) -> codigo_fifa.
# Cubre variaciones de eloratings.net frente al maestro.
# Ampliar aqui si la primera corrida revela nombres sin match.
ALIAS_CODIGO <- c(
  "south korea" = "KOR", "korea republic" = "KOR",
  "czechia" = "CZE", "czech republic" = "CZE",
  "united states" = "USA", "usa" = "USA",
  "ivory coast" = "CIV", "cote d ivoire" = "CIV",
  "iran" = "IRN", "ir iran" = "IRN",
  "curacao" = "CUW",
  "cape verde" = "CPV", "cabo verde" = "CPV",
  "dr congo" = "COD", "congo dr" = "COD",
  "democratic republic of the congo" = "COD",
  "saudi arabia" = "KSA",
  "turkey" = "TUR", "turkiye" = "TUR",
  "bosnia and herzegovina" = "BIH"
)

# ---- Scraper Elo (eloratings.net) ----
# Devuelve tibble(clave, elo) o NULL si falla. Selectores a verificar en la
# primera corrida real; bloque defensivo (tryCatch + validacion de filas).
scrape_elo <- function(url) {
  res <- tryCatch({
    tablas <- rvest::read_html(url) |> rvest::html_elements("table")
    cand <- purrr::map(tablas, ~ tryCatch(rvest::html_table(.x), error = function(e) NULL))
    cand <- purrr::keep(cand, ~ !is.null(.x) && ncol(.x) >= 2 && nrow(.x) >= 50)
    if (length(cand) == 0) stop("no se identifico tabla de Elo")
    pick <- cand[[1]]
    es_texto <- vapply(pick, function(c) is.character(c) || is.factor(c), logical(1))
    col_equipo <- names(pick)[which(es_texto)[1]]
    num <- vapply(pick, function(c) {
      v <- suppressWarnings(as.numeric(stringr::str_replace_all(as.character(c), "[^0-9.]", "")))
      mean(v, na.rm = TRUE)
    }, numeric(1))
    idx_elo <- which(num > 500)  # los Elo de seleccion rondan 1200-2100
    if (length(idx_elo) == 0) stop("no se encontro columna numerica de Elo")
    col_elo <- names(pick)[idx_elo[1]]
    tibble::tibble(
      clave = clave_nombre(pick[[col_equipo]]),
      elo   = suppressWarnings(as.numeric(stringr::str_replace_all(as.character(pick[[col_elo]]), "[^0-9.]", "")))
    ) |>
      dplyr::filter(!is.na(elo), clave != "") -> out
    if (nrow(out) < 50) stop("tabla Elo con muy pocas filas")
    out
  }, error = function(e) {
    log_msg(paste("scrape Elo fallo:", conditionMessage(e)), "WARN", "31_fuerza")
    NULL
  })
  Sys.sleep(PAUSA_SCRAPE)
  res
}

# ---- Normalizacion a escala 0-100 (min-max sobre los 48) ----
escala_0_100 <- function(x) {
  rango <- range(x, na.rm = TRUE)
  if (diff(rango) == 0) return(rep(50, length(x)))
  100 * (x - rango[1]) / diff(rango)
}

# ---- Match del Elo (por nombre) contra el maestro: alias + clave en/es ----
match_elo <- function(maestro, elo) {
  if (is.null(elo)) {
    return(tibble::tibble(codigo_fifa = character(0), elo = numeric(0)))
  }
  elo <- elo |> dplyr::mutate(codigo_alias = unname(ALIAS_CODIGO[clave]))
  por_alias <- elo |> dplyr::filter(!is.na(codigo_alias)) |>
    dplyr::select(codigo_fifa = codigo_alias, elo)
  por_en <- maestro |> dplyr::select(codigo_fifa, clave = clave_en) |>
    dplyr::inner_join(elo, by = "clave") |> dplyr::select(codigo_fifa, elo)
  por_es <- maestro |> dplyr::select(codigo_fifa, clave = clave_es) |>
    dplyr::inner_join(elo, by = "clave") |> dplyr::select(codigo_fifa, elo)
  dplyr::bind_rows(por_alias, por_en, por_es) |>
    dplyr::distinct(codigo_fifa, .keep_all = TRUE)
}

# ---- Flujo principal ----
log_msg("Iniciando ingesta de fuerza pre-torneo", "INFO", "31_fuerza")

# 1. Maestro (universo estable). Codigos como character (politica C.6).
maestro <- readr::read_csv(ARCHIVO_MAESTRO, col_types = readr::cols(.default = readr::col_character())) |>
  janitor::clean_names() |>
  dplyr::mutate(clave_en = clave_nombre(equipo_en),
                clave_es = clave_nombre(equipo_es))
if (nrow(maestro) != N_EQUIPOS) {
  stop(sprintf("El maestro tiene %d filas, se esperaban %d.", nrow(maestro), N_EQUIPOS), call. = FALSE)
}

# 2. Ranking FIFA (insumo fijo, join directo por codigo_fifa)
fifa <- readr::read_csv(
  ARCHIVO_FIFA,
  col_types = readr::cols(codigo_fifa = readr::col_character(),
                          pos_fifa = readr::col_integer(),
                          puntos_fifa = readr::col_double())
) |> janitor::clean_names()

faltan_fifa <- setdiff(maestro$codigo_fifa, fifa$codigo_fifa)
if (length(faltan_fifa) > 0) {
  stop(sprintf("Faltan en el ranking FIFA: %s", paste(faltan_fifa, collapse = ", ")), call. = FALSE)
}

# 3. Elo (scraping secundario, match por nombre)
elo_raw <- if (INCLUIR_ELO) scrape_elo(URL_ELO) else NULL
elo_m   <- match_elo(maestro, elo_raw)

# 4. Ensamblado
tabla <- maestro |>
  dplyr::select(codigo_fifa, equipo_es, equipo_en, confederacion, grupo) |>
  dplyr::left_join(fifa,  by = "codigo_fifa") |>
  dplyr::left_join(elo_m, by = "codigo_fifa")

disp_fifa <- sum(!is.na(tabla$puntos_fifa))
disp_elo  <- sum(!is.na(tabla$elo))
log_msg(sprintf("Cobertura: FIFA %d/%d, Elo %d/%d", disp_fifa, N_EQUIPOS, disp_elo, N_EQUIPOS),
        "INFO", "31_fuerza")

# 5. Fuerza base segun FUENTE_FUERZA, con fallback declarado a FIFA
fuente_usada <- FUENTE_FUERZA
if (FUENTE_FUERZA %in% c("elo", "compuesto") && disp_elo < N_EQUIPOS) {
  log_msg(sprintf("Elo incompleto (%d/%d); fallback de fuerza base a FIFA.", disp_elo, N_EQUIPOS),
          "WARN", "31_fuerza")
  fuente_usada <- "fifa"
}

tabla <- tabla |>
  dplyr::mutate(
    fuerza_fifa = escala_0_100(puntos_fifa),
    fuerza_elo  = if (disp_elo > 0) escala_0_100(elo) else NA_real_,
    fuerza_base = dplyr::case_when(
      fuente_usada == "fifa"      ~ fuerza_fifa,
      fuente_usada == "elo"       ~ fuerza_elo,
      fuente_usada == "compuesto" ~ PESO_COMPUESTO[["fifa"]] * fuerza_fifa +
                                    PESO_COMPUESTO[["elo"]]  * fuerza_elo,
      TRUE ~ NA_real_
    )
  )

# 6. Validacion de integridad (politica C.8)
na_fuerza <- sum(is.na(tabla$fuerza_base))
if (na_fuerza > 0) {
  faltan <- tabla$equipo_es[is.na(tabla$fuerza_base)]
  stop(sprintf("Fuerza base sin resolver para %d equipos: %s.", na_fuerza, paste(faltan, collapse = ", ")),
       call. = FALSE)
}
stopifnot(nrow(tabla) == N_EQUIPOS, !anyDuplicated(tabla$codigo_fifa))

# 7. Escritura atomica
escribir_csv_atomico(tabla, ARCHIVO_SALIDA)
log_msg(sprintf("Fuerza escrita: %s (base = %s)", ARCHIVO_SALIDA, fuente_usada), "INFO", "31_fuerza")
