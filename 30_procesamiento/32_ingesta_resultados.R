# ============================================================================
# 32_ingesta_resultados.R
# Proposito: obtener los partidos jugados del Mundial 2026 (fecha, fase,
#            rivales, marcador) para las 48 selecciones. Fuente primaria:
#            worldfootballR (FBref). Fallback: dataset CC0 de GitHub
#            (matches_detailed.csv, mominullptr/FIFA-World-Cup-2026-Dataset).
#            Re-ejecutable por jornada (idempotente: sobrescribe la salida
#            completa en cada corrida, no acumula duplicados).
# Insumos:   20_insumos/equipos_mundial2026.csv (maestro, para mapear codigos)
#            + FBref (worldfootballR) o, si falla, GitHub raw (fallback)
# Salidas:   40_salidas/resultados_partidos.csv (escritura atomica)
# Autor:     [tu nombre]
# Fecha:     2026-07-02
# ============================================================================

# ---- Auto-instalacion ----
.pkgs <- c("here", "dplyr", "stringr", "readr", "janitor", "tibble", "purrr", "stringi")
.falta <- .pkgs[!vapply(.pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(.falta) > 0) utils::install.packages(.falta)
# worldfootballR no esta al dia en CRAN; se instala desde GitHub si falta.
if (!requireNamespace("worldfootballR", quietly = TRUE)) {
  if (!requireNamespace("devtools", quietly = TRUE)) utils::install.packages("devtools")
  message("Instalando worldfootballR desde GitHub (no disponible via CRAN al dia)...")
  tryCatch(
    devtools::install_github("JaseZiv/worldfootballR", upgrade = "never"),
    error = function(e) message("No se pudo instalar worldfootballR: ", conditionMessage(e))
  )
}

library(dplyr)
library(stringr)
library(readr)
library(purrr)

if (!exists("ruta_insumos")) {
  source(here::here("10_utils", "10_utils.R"))
  source(here::here("10_utils", "10_configuracion.R"))
}

`%||%` <- function(a, b) if (is.null(a)) b else a

# ---- Constantes y parametros ----
ARCHIVO_MAESTRO <- ruta_insumos("equipos_mundial2026.csv")
ARCHIVO_SALIDA  <- ruta_salidas("resultados_partidos.csv")

# URL no-domestica de FBref para el historial de Copas del Mundo (usada con
# country = "" segun el patron documentado de worldfootballR).
URL_FBREF_WC     <- "https://fbref.com/en/comps/1/history/World-Cup-Seasons"
SEASON_END_YEAR  <- 2026

# Fallback: version "detailed" (nombres legibles) del dataset CC0 en GitHub.
URL_FALLBACK_CC0 <- "https://raw.githubusercontent.com/mominullptr/FIFA-World-Cup-2026-Dataset/main/matches_detailed.csv"

PAUSA_SCRAPE <- 3  # cortesia FBref (bot-traffic policy)

# Normalizacion de fase a la escalera canonica del proyecto.
# Ampliar si una fuente usa una etiqueta no contemplada.
MAPA_FASE <- c(
  "group stage" = "grupos", "group" = "grupos", "grupos" = "grupos",
  "round of 32" = "dieciseisavos", "r32" = "dieciseisavos",
  "dieciseisavos" = "dieciseisavos", "dieciseisavos de final" = "dieciseisavos",
  "round of 16" = "octavos", "r16" = "octavos", "octavos" = "octavos",
  "octavos de final" = "octavos",
  "quarter-final" = "cuartos", "quarterfinals" = "cuartos", "cuartos" = "cuartos",
  "cuartos de final" = "cuartos",
  "semi-final" = "semifinal", "semifinals" = "semifinal", "semifinal" = "semifinal",
  "third place" = "tercer_lugar", "third-place" = "tercer_lugar",
  "tercer lugar" = "tercer_lugar",
  "final" = "final"
)

# ---- Utilidad: escritura atomica (write -> rename), politica C.4 ----
escribir_csv_atomico <- function(df, destino) {
  tmp <- paste0(destino, ".tmp")
  readr::write_csv(df, tmp)
  file.rename(tmp, destino)
  invisible(destino)
}

# NOTA: preserva digitos ([^a-z0-9 ]), a diferencia de la version usada para
# nombres de equipo (donde los digitos no aportan). Bug detectado en sesion:
# con [^a-z ] "Round of 32" y "Round of 16" colapsaban a la misma clave
# "round of " (sin numero), y ninguna calzaba en MAPA_FASE.
clave_nombre <- function(x) {
  x |>
    stringr::str_to_lower() |>
    stringi::stri_trans_general("Latin-ASCII") |>
    stringr::str_replace_all("[^a-z0-9 ]", " ") |>
    stringr::str_squish()
}

normalizar_fase <- function(x) {
  clave <- clave_nombre(x)
  out <- unname(MAPA_FASE[clave])
  out[is.na(out)] <- "sin_clasificar"
  out
}

# ---- Fuente primaria: worldfootballR / FBref ----
intentar_fbref <- function() {
  tryCatch({
    if (!requireNamespace("worldfootballR", quietly = TRUE)) stop("worldfootballR no disponible")
    urls <- worldfootballR::fb_match_urls(
      country = "", gender = "M", season_end_year = SEASON_END_YEAR, tier = "",
      non_dom_league_url = URL_FBREF_WC
    )
    if (length(urls) == 0) stop("fb_match_urls no devolvio partidos")
    Sys.sleep(PAUSA_SCRAPE)
    res <- worldfootballR::fb_match_results(
      country = "", gender = "M", season_end_year = SEASON_END_YEAR, tier = "",
      non_dom_league_url = URL_FBREF_WC
    )
    if (is.null(res) || nrow(res) == 0) stop("fb_match_results vacio")

    res <- janitor::clean_names(res)
    tibble::tibble(
      fecha         = as.character(res$date),
      fase          = normalizar_fase(res$round),
      local_nombre  = res$home,
      visita_nombre = res$away,
      gf_local      = suppressWarnings(as.integer(res$home_goals)),
      gf_visita     = suppressWarnings(as.integer(res$away_goals)),
      sede          = as.character(res$venue)
    ) |>
      dplyr::filter(!is.na(gf_local), !is.na(gf_visita))
  }, error = function(e) {
    log_msg(paste("Fuente FBref fallo:", conditionMessage(e)), "WARN", "32_resultados")
    NULL
  })
}

# ---- Fuente de respaldo: dataset CC0 (GitHub raw) ----
intentar_fallback <- function() {
  tryCatch({
    df <- readr::read_csv(URL_FALLBACK_CC0, show_col_types = FALSE)
    if (nrow(df) == 0) stop("fallback vacio")
    df <- janitor::clean_names(df)
    df <- df |> dplyr::filter(!is.na(.data$home_score), !is.na(.data$away_score))
    fase_col <- if ("stage_name" %in% names(df)) df$stage_name else
                if ("stage" %in% names(df)) df$stage else rep("grupos", nrow(df))
    sede_col <- if ("stadium_name" %in% names(df)) df$stadium_name else
                if ("city" %in% names(df)) df$city else rep(NA_character_, nrow(df))
    tibble::tibble(
      fecha         = as.character(df$date),
      fase          = normalizar_fase(fase_col),
      local_nombre  = df$home_team_name,
      visita_nombre = df$away_team_name,
      gf_local      = suppressWarnings(as.integer(df$home_score)),
      gf_visita     = suppressWarnings(as.integer(df$away_score)),
      sede          = as.character(sede_col)
    )
  }, error = function(e) {
    log_msg(paste("Fuente fallback (GitHub CC0) fallo:", conditionMessage(e)), "WARN", "32_resultados")
    NULL
  })
}

# ---- Flujo principal ----
log_msg("Iniciando ingesta de resultados del torneo", "INFO", "32_resultados")

maestro <- readr::read_csv(ARCHIVO_MAESTRO, col_types = readr::cols(.default = readr::col_character())) |>
  janitor::clean_names() |>
  dplyr::mutate(clave_en = clave_nombre(equipo_en), clave_es = clave_nombre(equipo_es))

partidos_raw <- intentar_fbref()
fuente_usada <- "fbref"
if (is.null(partidos_raw)) {
  log_msg("Fallback activado: usando dataset CC0 de respaldo.", "WARN", "32_resultados")
  partidos_raw <- intentar_fallback()
  fuente_usada <- "fallback_cc0"
}

if (is.null(partidos_raw) || nrow(partidos_raw) == 0) {
  stop("Ambas fuentes de resultados fallaron. Pipeline detenido: no se inventan resultados.",
       call. = FALSE)
}

# ---- Mapeo de nombres de equipo a codigo_fifa (alias + clave en/es) ----
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

mapear_codigo <- function(nombres) {
  clave <- clave_nombre(nombres)
  por_alias <- unname(ALIAS_CODIGO[clave])
  idx_en <- match(clave, maestro$clave_en)
  idx_es <- match(clave, maestro$clave_es)
  dplyr::coalesce(por_alias, maestro$codigo_fifa[idx_en], maestro$codigo_fifa[idx_es])
}

partidos <- partidos_raw |>
  dplyr::mutate(
    local_codigo  = mapear_codigo(local_nombre),
    visita_codigo = mapear_codigo(visita_nombre)
  ) |>
  # Solo partidos donde ambos equipos son de nuestro universo de 48.
  dplyr::filter(!is.na(local_codigo), !is.na(visita_codigo)) |>
  dplyr::mutate(id_partido = dplyr::row_number()) |>
  dplyr::select(id_partido, fecha, fase, sede,
                local_codigo, local_nombre, gf_local,
                visita_codigo, visita_nombre, gf_visita)

# ---- Validacion de integridad (politica C.8) ----
if (nrow(partidos) == 0) {
  stop("Ningun partido pudo mapearse a codigos del universo de 48 equipos. Revisa ALIAS_CODIGO.",
       call. = FALSE)
}
n_descartados <- nrow(partidos_raw) - nrow(partidos)
if (n_descartados > 0) {
  log_msg(sprintf("Se descartaron %d filas sin mapeo valido a codigo_fifa.", n_descartados),
          "WARN", "32_resultados")
}
if (any(partidos$fase == "sin_clasificar")) {
  log_msg("Hay partidos con fase sin clasificar; revisar MAPA_FASE.", "WARN", "32_resultados")
}

# ---- Escritura atomica ----
escribir_csv_atomico(partidos, ARCHIVO_SALIDA)
log_msg(sprintf("Resultados escritos: %s (%d partidos, fuente = %s)",
                ARCHIVO_SALIDA, nrow(partidos), fuente_usada),
        "INFO", "32_resultados")
