# ============================================================================
# 32_ingesta_resultados.R
# Proposito: obtener los partidos jugados del Mundial 2026 (fecha, fase,
#            rivales, marcador) para las 48 selecciones. Fuente primaria:
#            openfootball/worldcup.json (CC0, mantenido a mano por Gerald
#            Bauer, sincronizado con ESPN/FIFA; sin API key). Toma el
#            marcador de la instancia que realmente resolvio el partido
#            (ft, o et/p si ft quedo en empate; ver P19). Validacion
#            cruzada doble, siempre activa (no solo si la primaria falla):
#            (1) thestatsapi.com/fixtures.csv, calendario sin marcador,
#            solo detecta partidos faltantes o mal mapeados; (2) ESPN
#            (site.api.espn.com, API no oficial sin ToS publico), aporta
#            marcador real independiente, incluido resultado explicito de
#            tiempo extra/penales (shootoutScore); discrepancias con la
#            primaria generan WARN, nunca bloquean el pipeline. Fallback
#            de ultima instancia: dataset CC0 de GitHub (matches_detailed.csv,
#            mominullptr/FIFA-World-Cup-2026-Dataset) — advertencia explicita
#            si se usa: puede contener datos sinteticos, no reales.
#            Re-ejecutable por jornada (idempotente: sobrescribe la salida
#            completa en cada corrida, no acumula duplicados).
# Insumos:   20_insumos/equipos_mundial2026.csv (maestro, para mapear codigos)
#            + openfootball/worldcup.json (GitHub raw, primaria)
#            + thestatsapi.com/fixtures.csv (validacion cruzada, calendario)
#            + site.api.espn.com (validacion cruzada, marcador real)
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

# Validacion cruzada 1: calendario real independiente (sin marcador gratis;
# solo confirma que el partido existe, fecha y equipos, no el resultado).
URL_THESTATSAPI <- "https://www.thestatsapi.com/world-cup/data/fixtures.csv"

# Validacion cruzada 2: marcador real independiente. API no oficial de ESPN
# (sin ToS publico, uso ampliamente reutilizado por la comunidad; puede
# cambiar de forma o bloquearse sin aviso, se trata igual que thestatsapi:
# validacion que nunca bloquea el pipeline si falla). Aporta ademas
# resolucion explicita de tiempo extra/penales via shootoutScore, util
# para contrastar el marcador final de openfootball en esos casos.
URL_ESPN_BASE <- "http://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/scoreboard"

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
# P19: score es un data.frame con columnas ft/ht/et/p, cada una lista de
# vectores length-2 o NULL. Cuando el partido se define en tiempo extra o
# penales, ft SIGUE existiendo pero queda en empate (el resultado real esta
# en et o p). Bug detectado 2026-07-05: el parser anterior solo leia ft,
# registrando como empate partidos que en realidad tuvieron ganador (ver
# 50_documentacion/activa/decisiones/20260705_investigacion_fuentes_resultados.md).
# Regla de resolucion: usar la ultima instancia jugada (p > et > ft), nunca
# promediar ni descartar. resuelto_por queda en la salida para trazabilidad.
intentar_openfootball <- function() {
  tryCatch({
    raw <- jsonlite::fromJSON(URL_OPENFOOTBALL, simplifyDataFrame = TRUE)
    partidos_raw <- raw$matches
    if (is.null(partidos_raw) || nrow(partidos_raw) == 0) stop("worldcup.json sin partidos")

    extraer_marcador <- function(lista_col) {
      # Devuelve matriz N x 2 (NA si no existe/incompleto) para una columna
      # score$ft / score$et / score$p, sea NULL, list-de-NULL o ausente.
      if (is.null(lista_col)) return(matrix(NA_integer_, nrow(partidos_raw), 2))
      m <- t(vapply(lista_col, function(x) {
        if (is.null(x) || length(x) != 2 || anyNA(x)) c(NA_integer_, NA_integer_) else as.integer(x)
      }, integer(2)))
      m
    }

    m_ft <- extraer_marcador(partidos_raw$score$ft)
    m_et <- extraer_marcador(partidos_raw$score$et)
    m_p  <- extraer_marcador(partidos_raw$score$p)

    tiene_ft <- !is.na(m_ft[, 1])
    tiene_et <- !is.na(m_et[, 1])
    tiene_p  <- !is.na(m_p[, 1])
    tiene_score <- tiene_ft | tiene_et | tiene_p
    if (!any(tiene_score)) stop("worldcup.json: ningun partido con marcador aun")

    # Prioridad p > et > ft: la instancia mas tardia jugada es la que
    # resolvio el partido. ft se usa como base y se sobrescribe si hay et/p.
    gf_local  <- ifelse(tiene_p, m_p[, 1], ifelse(tiene_et, m_et[, 1], m_ft[, 1]))
    gf_visita <- ifelse(tiene_p, m_p[, 2], ifelse(tiene_et, m_et[, 2], m_ft[, 2]))
    resuelto_por <- ifelse(tiene_p, "p", ifelse(tiene_et, "et", "ft"))

    jugados <- partidos_raw[tiene_score, ]

    tibble::tibble(
      fecha         = as.character(jugados$date),
      fase          = normalizar_fase(jugados$round),
      local_nombre  = as.character(jugados$team1),
      visita_nombre = as.character(jugados$team2),
      gf_local      = as.integer(gf_local[tiene_score]),
      gf_visita     = as.integer(gf_visita[tiene_score]),
      resuelto_por  = resuelto_por[tiene_score],
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

# ---- Validacion cruzada 2: ESPN (marcador real, siempre activa) ----
# A diferencia de thestatsapi, ESPN si aporta marcador; se usa para
# contrastar el gf/gc que openfootball ya resolvio (incluido et/p), no
# para reemplazarlo. Discrepancias generan WARN detallado, nunca bloquean
# (misma politica que thestatsapi: fuente no oficial, sin ToS publico).
validar_contra_espn <- function(partidos_openfootball) {
  tryCatch({
    fechas <- unique(partidos_openfootball$fecha)
    fechas_espn <- gsub("-", "", fechas)
    resultados_espn <- purrr::map2_dfr(fechas, fechas_espn, function(fecha_iso, fecha_espn) {
      url <- paste0(URL_ESPN_BASE, "?dates=", fecha_espn)
      resp <- tryCatch(jsonlite::fromJSON(url, simplifyDataFrame = TRUE), error = function(e) NULL)
      if (is.null(resp) || is.null(resp$events) || length(resp$events) == 0) return(tibble::tibble())
      eventos <- resp$events
      purrr::map_dfr(seq_len(nrow(eventos)), function(i) {
        competidores <- eventos$competitions[[i]]$competitors[[1]]
        if (is.null(competidores) || nrow(competidores) != 2) return(tibble::tibble())
        local_idx <- which(competidores$homeAway == "home")
        visita_idx <- which(competidores$homeAway == "away")
        if (length(local_idx) != 1 || length(visita_idx) != 1) return(tibble::tibble())
        tibble::tibble(
          fecha = fecha_iso,
          local_nombre = competidores$team$displayName[local_idx],
          visita_nombre = competidores$team$displayName[visita_idx],
          gf_local_espn = suppressWarnings(as.integer(competidores$score[local_idx])),
          gf_visita_espn = suppressWarnings(as.integer(competidores$score[visita_idx]))
        )
      })
    })
    if (nrow(resultados_espn) == 0) {
      log_msg("Validacion cruzada ESPN: sin eventos para las fechas consultadas (no bloquea).",
              "WARN", "32_resultados")
      return(invisible(NULL))
    }
    resultados_espn <- resultados_espn |>
      dplyr::mutate(codigo_local = mapear_codigo(local_nombre), codigo_visita = mapear_codigo(visita_nombre)) |>
      dplyr::filter(!is.na(codigo_local), !is.na(codigo_visita))
    comparacion <- partidos_openfootball |>
      dplyr::mutate(codigo_local = mapear_codigo(local_nombre), codigo_visita = mapear_codigo(visita_nombre)) |>
      dplyr::inner_join(resultados_espn, by = c("fecha", "codigo_local", "codigo_visita"))
    discrepancias <- comparacion |>
      dplyr::filter(gf_local != gf_local_espn | gf_visita != gf_visita_espn)
    if (nrow(discrepancias) > 0) {
      log_msg(sprintf(
        "Validacion cruzada ESPN: %d partido(s) con marcador distinto entre openfootball y ESPN (revisar manualmente, no bloquea): %s.",
        nrow(discrepancias),
        paste(sprintf("%s %d-%d (of) vs %d-%d (espn)", discrepancias$codigo_local,
                       discrepancias$gf_local, discrepancias$gf_visita,
                       discrepancias$gf_local_espn, discrepancias$gf_visita_espn),
              collapse = "; ")),
        "WARN", "32_resultados")
    } else if (nrow(comparacion) > 0) {
      log_msg(sprintf("Validacion cruzada ESPN: marcador coincide en los %d partido(s) contrastados.",
                      nrow(comparacion)), "INFO", "32_resultados")
    }
  }, error = function(e) {
    log_msg(paste("Validacion cruzada ESPN fallo (no bloquea):", conditionMessage(e)),
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
  validar_contra_espn(partidos_raw)
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
                visita_codigo, visita_nombre, gf_visita,
                resuelto_por = dplyr::any_of("resuelto_por"))

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
n_et_p <- if ("resuelto_por" %in% names(partidos)) sum(partidos$resuelto_por %in% c("et", "p"), na.rm = TRUE) else 0L
log_msg(sprintf("Resultados escritos: %s (%d partidos, fuente = %s, %d resueltos en et/p)",
                ARCHIVO_SALIDA, nrow(partidos), fuente_usada, n_et_p),
        "INFO", "32_resultados")
