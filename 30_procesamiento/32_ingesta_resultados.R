# ============================================================================
# 32_ingesta_resultados.R
# Proposito: obtener los partidos jugados del Mundial 2026 (fecha, fase,
#            rivales, marcador) para las 48 selecciones. Fuente primaria:
#            openfootball/worldcup.json (CC0, mantenido a mano por Gerald
#            Bauer, sincronizado con ESPN/FIFA; sin API key). Validacion
#            cruzada: thestatsapi.com/fixtures.csv (calendario, sin marcador,
#            solo para detectar partidos faltantes o mal mapeados). Fallback
#            de ultima instancia: dataset CC0 de GitHub (matches_detailed.csv,
#            mominullptr/FIFA-World-Cup-2026-Dataset) — advertencia explicita
#            si se usa: puede contener datos sinteticos, no reales.
#            Re-ejecutable por jornada (idempotente: sobrescribe la salida
#            completa en cada corrida, no acumula duplicados).
# Insumos:   20_insumos/equipos_mundial2026.csv (maestro, para mapear codigos)
#            + openfootball/worldcup.json (GitHub raw, primaria)
#            + thestatsapi.com/fixtures.csv (validacion cruzada, opcional)
#            + GitHub raw CC0 (fallback de ultima instancia)
# Salidas:   40_salidas/resultados_partidos.csv (escritura atomica)
# Autor:     [tu nombre]
# Fecha:     2026-07-03
# ============================================================================

# ---- Auto-instalacion ----
.pkgs <- c("here", "dplyr", "stringr", "readr", "janitor", "tibble", "purrr",
           "stringi", "jsonlite")
.falta <- .pkgs[!vapply(.pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(.falta) > 0) utils::install.packages(.falta)

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

# Fuente primaria: real, mantenida a mano, sincronizada con ESPN/FIFA.
URL_OPENFOOTBALL <- "https://raw.githubusercontent.com/openfootball/worldcup.json/master/2026/worldcup.json"

# Validacion cruzada: calendario real independiente (sin marcador gratis;
# solo confirma que el partido existe, fecha y equipos, no el resultado).
URL_THESTATSAPI <- "https://www.thestatsapi.com/world-cup/data/fixtures.csv"

# Fallback de ultima instancia si openfootball falla. ADVERTENCIA: este
# dataset puede contener resultados sinteticos/ficticios (confirmado en
# sesion 2026-07-03); usarlo deja fuente_usada = "fallback_cc0_sintetico"
# y dispara un WARN fuerte, nunca silencioso.
URL_FALLBACK_CC0 <- "https://raw.githubusercontent.com/mominullptr/FIFA-World-Cup-2026-Dataset/main/matches_detailed.csv"

# Normalizacion de fase a la escalera canonica del proyecto. openfootball usa
# "Matchday N" para grupos y nombres de fase en ingles para el resto; se
# amplia el mapa existente (compatible con el fallback CC0 y con el legado
# FBref) en vez de reemplazarlo.
MAPA_FASE <- c(
  "group stage" = "grupos", "group" = "grupos", "grupos" = "grupos",
  "round of 32" = "dieciseisavos", "r32" = "dieciseisavos",
  "dieciseisavos" = "dieciseisavos", "dieciseisavos de final" = "dieciseisavos",
  "round of 16" = "octavos", "r16" = "octavos", "octavos" = "octavos",
  "octavos de final" = "octavos",
  "quarter final" = "cuartos", "quarterfinals" = "cuartos", "cuartos" = "cuartos",
  "cuartos de final" = "cuartos",
  "semi final" = "semifinal", "semifinals" = "semifinal", "semifinal" = "semifinal",
  "match for third place" = "tercer_lugar", "third place" = "tercer_lugar",
  "third-place" = "tercer_lugar", "tercer lugar" = "tercer_lugar",
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
# nombres de equipo (donde los digitos no aportan). Bug detectado en sesion
# anterior: con [^a-z ] "Round of 32" y "Round of 16" colapsaban a la misma
# clave "round of " (sin numero), y ninguna calzaba en MAPA_FASE. "Matchday N"
# tambien depende de preservar el digito para no colapsar todas las jornadas.
clave_nombre <- function(x) {
  x |>
    stringr::str_to_lower() |>
    stringi::stri_trans_general("Latin-ASCII") |>
    stringr::str_replace_all("[^a-z0-9 ]", " ") |>
    stringr::str_squish()
}

# "Matchday N" (grupos) no tiene entrada literal en MAPA_FASE (serian 17
# entradas identicas); se detecta por patron antes del lookup.
normalizar_fase <- function(x) {
  clave <- clave_nombre(x)
  es_jornada <- stringr::str_detect(clave, "^matchday [0-9]+$")
  out <- unname(MAPA_FASE[clave])
  out[es_jornada] <- "grupos"
  out[is.na(out)] <- "sin_clasificar"
  out
}

# ---- Fuente primaria: openfootball/worldcup.json ----
intentar_openfootball <- function() {
  tryCatch({
    raw <- jsonlite::fromJSON(URL_OPENFOOTBALL, simplifyDataFrame = TRUE)
    partidos_raw <- raw$matches
    if (is.null(partidos_raw) || nrow(partidos_raw) == 0) stop("worldcup.json sin partidos")

    # score es un data.frame (columnas ft/ht/p/et), cada una lista-de-vectores
    # length-2 o NULL si el partido no se ha jugado (bracket con placeholders
    # tipo "1A", "W74", etc.). Confirmado empiricamente: score$ft es
    # List of N con elementos int[1:2] o NULL, no una matriz simplificada.
    ft_list <- partidos_raw$score$ft
    tiene_score <- vapply(ft_list, function(x) !is.null(x) && length(x) == 2 && !anyNA(x), logical(1))
    if (!any(tiene_score)) stop("worldcup.json: ningun partido con marcador aun")

    ft <- do.call(rbind, ft_list[tiene_score])
    jugados <- partidos_raw[tiene_score, ]

    tibble::tibble(
      fecha         = as.character(jugados$date),
      fase          = normalizar_fase(jugados$round),
      local_nombre  = as.character(jugados$team1),
      visita_nombre = as.character(jugados$team2),
      gf_local      = as.integer(ft[, 1]),
      gf_visita     = as.integer(ft[, 2]),
      sede          = as.character(jugados$ground %||% NA_character_)
    )
  }, error = function(e) {
    log_msg(paste("Fuente openfootball fallo:", conditionMessage(e)), "WARN", "32_resultados")
    NULL
  })
}

# ---- Validacion cruzada: thestatsapi.com (calendario, sin marcador) ----
# Solo confirma que un partido existe (fecha, equipos); no aporta gf/gc.
# Si falla, no bloquea el pipeline (es validacion, no fuente de datos).
validar_contra_thestatsapi <- function(partidos_openfootball) {
  tryCatch({
    fixtures <- readr::read_csv(URL_THESTATSAPI, show_col_types = FALSE) |>
      janitor::clean_names()
    # Comparar por codigo_fifa (via mapear_codigo(), ya definido mas abajo en
    # el flujo principal), no por texto: las fuentes difieren en nomenclatura
    # (czechia/czech republic, usa/united states, etc.) sin ser un error de
    # dato. El bracket sin resolver (placeholders "w83" vs "winner match 83")
    # nunca calza como texto y se excluye de ambos lados.
    cod_of  <- mapear_codigo(partidos_openfootball$local_nombre)
    cod_api <- mapear_codigo(fixtures$home_team)
    cod_of  <- cod_of[!is.na(cod_of)]
    cod_api <- cod_api[!is.na(cod_api)]
    n_solo_of  <- length(setdiff(cod_of, cod_api))
    n_solo_api <- length(setdiff(cod_api, cod_of))
    if (n_solo_of > 0 || n_solo_api > 0) {
      log_msg(sprintf(
        "Validacion cruzada thestatsapi: %d equipos locales solo en openfootball, %d solo en fixtures (esperado si el bracket aun no resuelve todos los cruces; no bloquea).",
        n_solo_of, n_solo_api), "WARN", "32_resultados")
    } else {
      log_msg("Validacion cruzada thestatsapi: universo de equipos locales coincide.", "INFO", "32_resultados")
    }
  }, error = function(e) {
    log_msg(paste("Validacion cruzada thestatsapi fallo (no bloquea):", conditionMessage(e)),
            "WARN", "32_resultados")
  })
  invisible(NULL)
}

# ---- Fuente de ultima instancia: dataset CC0 (posible sintetico) ----
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

# ---- Mapeo de nombres de equipo a codigo_fifa (alias + clave en/es) ----
# openfootball usa nombres en ingles ligeramente distintos a fb_match_results
# (p.ej. "Bosnia & Herzegovina" con "&", "South Korea" en vez de "Korea
# Republic"); clave_nombre() normaliza el "&" a espacio, cubierto por el
# alias existente "bosnia and herzegovina". Definido antes del flujo
# principal porque validar_contra_thestatsapi() lo usa para comparar por
# codigo_fifa, no por texto crudo entre fuentes. maestro (usado dentro de
# mapear_codigo) se crea al inicio del flujo principal, pero la funcion solo
# se EJECUTA despues de esa asignacion, asi que el orden de definicion aqui
# es valido en R (closures resuelven variables libres en tiempo de llamada).
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
  "bosnia and herzegovina" = "BIH", "bosnia herzegovina" = "BIH"
)

mapear_codigo <- function(nombres) {
  clave <- clave_nombre(nombres)
  por_alias <- unname(ALIAS_CODIGO[clave])
  idx_en <- match(clave, maestro$clave_en)
  idx_es <- match(clave, maestro$clave_es)
  dplyr::coalesce(por_alias, maestro$codigo_fifa[idx_en], maestro$codigo_fifa[idx_es])
}

# ---- Flujo principal ----
log_msg("Iniciando ingesta de resultados del torneo", "INFO", "32_resultados")

maestro <- readr::read_csv(ARCHIVO_MAESTRO, col_types = readr::cols(.default = readr::col_character())) |>
  janitor::clean_names() |>
  dplyr::mutate(clave_en = clave_nombre(equipo_en), clave_es = clave_nombre(equipo_es))

partidos_raw <- intentar_openfootball()
fuente_usada <- "openfootball"
if (is.null(partidos_raw)) {
  log_msg("Fallback activado: usando dataset CC0 de respaldo. ADVERTENCIA: puede contener datos sinteticos, no reales.",
          "WARN", "32_resultados")
  partidos_raw <- intentar_fallback()
  fuente_usada <- "fallback_cc0_sintetico"
} else {
  validar_contra_thestatsapi(partidos_raw)
}

if (is.null(partidos_raw) || nrow(partidos_raw) == 0) {
  stop("Todas las fuentes de resultados fallaron. Pipeline detenido: no se inventan resultados.",
       call. = FALSE)
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
if (fuente_usada == "fallback_cc0_sintetico") {
  log_msg("*** ATENCION: pipeline corrio con fuente_usada = fallback_cc0_sintetico. Los resultados publicados podrian NO ser reales. Revisar antes de publicar. ***",
          "WARN", "32_resultados")
}

# ---- Escritura atomica ----
escribir_csv_atomico(partidos, ARCHIVO_SALIDA)
log_msg(sprintf("Resultados escritos: %s (%d partidos, fuente = %s)",
                ARCHIVO_SALIDA, nrow(partidos), fuente_usada),
        "INFO", "32_resultados")
