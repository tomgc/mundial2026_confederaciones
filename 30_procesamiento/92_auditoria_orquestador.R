# ============================================================================
# 92_auditoria_orquestador.R
# Proposito: correr las 3 familias de auditoria de cifras publicadas
#            (protocolo 4.5, SETTINGS): Familia A (fuerza base), Familia B
#            (rating Elo por equipo), Familia C (agregados por
#            confederacion). Cada familia compara la cifra publicada contra
#            un recalculo por camino independiente. Una familia que falla
#            NO aborta las demas (se corren las 3 siempre, con tryCatch
#            granular por familia).
# Insumos:   20_insumos/ranking_fifa_20260611.csv, elo_20260702.csv
#            40_salidas/fuerza_equipos.csv, resultados_partidos.csv,
#            historial_partidos.csv, rating_equipos.csv,
#            rating_confederaciones.csv, datos_interfaz.json (spot-check)
# Salidas:   50_documentacion/activa/decisiones/YYYYMMDD_auditoria_cifras.md
#            (reporte human-readable, se genera si hay discrepancias o al
#            cierre de sesion si se pide evidencia)
# Autor:     pipeline mundial2026_confederaciones
# Fecha:     2026-07-03
# ============================================================================

# ---- Auto-instalacion ----
.pkgs <- c("here", "dplyr", "readr", "janitor", "tibble", "jsonlite", "purrr")
.falta <- .pkgs[!vapply(.pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(.falta) > 0) utils::install.packages(.falta)

library(dplyr)
library(readr)
library(tibble)

if (!exists("ruta_insumos")) {
  source(here::here("10_utils", "10_utils.R"))
  source(here::here("10_utils", "10_configuracion.R"))
}
source(here::here("30_procesamiento", "91_auditoria_helpers.R"))

# ---- Constantes y parametros ----
ORDEN_FASES <- c("grupos", "dieciseisavos", "octavos", "cuartos",
                 "semifinal", "tercer_lugar", "final")
IMPORTANCIA_FASE <- c(
  grupos = 25, dieciseisavos = 35, octavos = 40, cuartos = 50,
  semifinal = 60, tercer_lugar = 45, final = 70
)
ESCALA_RATING <- 20
BASE_LOGISTICA <- 400
TOLERANCIA_REDONDEO_JSON <- 0.05  # r1() en 39_reporte.R redondea a 1 decimal;
                                   # 0.01 (TOLERANCIA_REDONDEO) es insuficiente
                                   # para esa capa extra de redondeo

RUTA_REPORTE <- here::here("50_documentacion", "activa", "decisiones",
                            paste0(format(Sys.Date(), "%Y%m%d"), "_auditoria_cifras.md"))

# ---- Utilidades locales (replican formulas del motor por camino independiente) ----
expectativa <- function(r_propio, r_rival) 1 / (1 + 10^((r_rival - r_propio) / BASE_LOGISTICA))
factor_goles <- function(gf, gc) 1 + log(pmax(1, abs(gf - gc)))
escala_0_100 <- function(x) {
  rango <- range(x, na.rm = TRUE)
  if (diff(rango) == 0) return(rep(50, length(x)))
  100 * (x - rango[1]) / diff(rango)
}

# ---- Flujo principal ----
log_msg("Iniciando auditoria de cifras publicadas (protocolo 4.5)", "INFO", "auditoria")
registro <- nuevo_registro_auditoria()

# ============================================================================
# Familia A — Fuerza base (fuerza_equipos.csv)
# Camino 1 (publicado): columna fuerza_base de 40_salidas/fuerza_equipos.csv
# Camino 2 (recalculo): escala_0_100() aplicada de nuevo sobre puntos_fifa
#   crudo de 20_insumos/ranking_fifa_20260611.csv (misma formula, insumo
#   crudo releido de forma independiente, no reutilizando el objeto en
#   memoria del pipeline)
# ============================================================================
resultado_a <- tryCatch({
  fuerza_pub <- readr::read_csv(ruta_salidas("fuerza_equipos.csv"),
                                 col_types = cols(codigo_fifa = col_character(), .default = col_guess()))
  fifa_crudo <- readr::read_csv(ruta_insumos("ranking_fifa_20260611.csv"),
                                 col_types = cols(codigo_fifa = col_character(), .default = col_guess())) |>
    janitor::clean_names()

  # Alinear por codigo_fifa (llave character, politica C.6)
  base <- fuerza_pub |>
    dplyr::select(codigo_fifa, fuerza_base) |>
    dplyr::left_join(dplyr::select(fifa_crudo, codigo_fifa, puntos_fifa), by = "codigo_fifa")

  base$fuerza_recalc <- escala_0_100(base$puntos_fifa)

  comparar_cifra(
    llave = base$codigo_fifa,
    valor_publicado = base$fuerza_base,
    valor_recalculado = base$fuerza_recalc,
    tolerancia = TOLERANCIA_ESTRICTA,
    nombre_familia = "Familia A", nombre_cifra = "fuerza_base"
  )
}, error = function(e) {
  log_msg(paste("Familia A fallo:", conditionMessage(e)), "WARN", "auditoria")
  tibble::tibble(llave = character(), publicado = double(), recalculado = double(),
                 diff_abs = double(), error = conditionMessage(e))
})
registro <- registrar_resultado(registro, "Familia A", "fuerza_base", resultado_a)

# ============================================================================
# Familia B — Rating Elo final por equipo (rating_equipos.csv)
# Camino 1 (publicado): columna rating_actual de 40_salidas/rating_equipos.csv
# Camino 2 (recalculo): resimulacion partido a partido desde
#   fuerza_equipos.csv + resultados_partidos.csv, usando el W ya resuelto
#   (columna W de historial_partidos.csv, perspectiva local) como insumo
#   de la inferencia de avance -- NO se reimplementa avanzo_a_fase_posterior()
#   aqui (seria el mismo codigo, no un camino independiente); en cambio se
#   verifica el resultado de esa inferencia (W) contra el recalculo del
#   propio delta Elo, que si es matematicamente independiente del bucle
#   original del motor.
# Tolerancia: TOLERANCIA_REDONDEO porque historial_partidos.csv trae W/We
#   ya redondeados a 3-4 decimales; el recalculo hereda ese redondeo
#   intermedio (no es error del motor).
# ============================================================================
resultado_b <- tryCatch({
  fuerza <- readr::read_csv(ruta_salidas("fuerza_equipos.csv"),
                             col_types = cols(codigo_fifa = col_character(), .default = col_guess()))
  resultados <- readr::read_csv(ruta_salidas("resultados_partidos.csv"),
                                 col_types = cols(local_codigo = col_character(),
                                                   visita_codigo = col_character(),
                                                   .default = col_guess())) |>
    dplyr::mutate(fase_num = match(fase, ORDEN_FASES))
  historial <- readr::read_csv(ruta_salidas("historial_partidos.csv"),
                                col_types = cols(codigo = col_character(), .default = col_guess()))
  rating_pub <- readr::read_csv(ruta_salidas("rating_equipos.csv"),
                                 col_types = cols(codigo_fifa = col_character(), .default = col_guess()))

  stopifnot("resultados sin fase valida" = !anyNA(resultados$fase_num))

  # W resuelto por partido, perspectiva local (ya incluye la inferencia de
  # avance del motor; se usa como dato, no se reimplementa la inferencia).
  w_local_por_partido <- historial |>
    dplyr::inner_join(dplyr::select(resultados, id_partido, local_codigo),
                       by = c("id_partido" = "id_partido", "codigo" = "local_codigo")) |>
    dplyr::select(id_partido, W)

  rating <- setNames(fuerza$fuerza_base * ESCALA_RATING, fuerza$codigo_fifa)

  orden <- resultados |>
    dplyr::left_join(w_local_por_partido, by = "id_partido") |>
    dplyr::arrange(fase_num, fecha, id_partido)

  for (i in seq_len(nrow(orden))) {
    p <- orden[i, ]
    Imp <- IMPORTANCIA_FASE[[p$fase]]
    G <- factor_goles(p$gf_local, p$gf_visita)
    r_l <- rating[[p$local_codigo]]; r_v <- rating[[p$visita_codigo]]
    We_l <- expectativa(r_l, r_v); We_v <- 1 - We_l
    W_l <- p$W; W_v <- 1 - W_l
    rating[[p$local_codigo]]  <- r_l + Imp * G * (W_l - We_l)
    rating[[p$visita_codigo]] <- r_v + Imp * G * (W_v - We_v)
  }

  rating_recalc <- tibble::tibble(codigo_fifa = names(rating), rating_recalc = unname(rating))
  base <- rating_pub |>
    dplyr::select(codigo_fifa, rating_actual) |>
    dplyr::left_join(rating_recalc, by = "codigo_fifa")

  comparar_cifra(
    llave = base$codigo_fifa,
    valor_publicado = base$rating_actual,
    valor_recalculado = base$rating_recalc,
    tolerancia = TOLERANCIA_REDONDEO,
    nombre_familia = "Familia B", nombre_cifra = "rating_actual"
  )
}, error = function(e) {
  log_msg(paste("Familia B fallo:", conditionMessage(e)), "WARN", "auditoria")
  tibble::tibble(llave = character(), publicado = double(), recalculado = double(),
                 diff_abs = double(), error = conditionMessage(e))
})
registro <- registrar_resultado(registro, "Familia B", "rating_actual", resultado_b)

# ============================================================================
# Familia C — Agregados por confederacion (rating_confederaciones.csv)
# Camino 1 (publicado): columnas obs_vs_esp, transfer_neto de
#   40_salidas/rating_confederaciones.csv
# Camino 2 (recalculo): agregacion directa de historial_partidos.csv
#   (sum(W - We) y sum(delta_conf) en partidos inter-confederacion),
#   camino independiente al bucle acumulador del motor original.
# ============================================================================
resultado_c <- tryCatch({
  fuerza <- readr::read_csv(ruta_salidas("fuerza_equipos.csv"),
                             col_types = cols(codigo_fifa = col_character(), .default = col_guess()))
  historial <- readr::read_csv(ruta_salidas("historial_partidos.csv"),
                                col_types = cols(codigo = col_character(), .default = col_guess()))
  rc_pub <- readr::read_csv(ruta_salidas("rating_confederaciones.csv"),
                             col_types = cols(.default = col_guess()))

  mapa_conf <- fuerza |> dplyr::select(codigo_fifa, confederacion)

  recalc <- historial |>
    dplyr::left_join(mapa_conf, by = c("codigo" = "codigo_fifa")) |>
    dplyr::filter(inter_confederacion) |>
    dplyr::summarise(
      obs_vs_esp_recalc = sum(W - We),
      transfer_neto_recalc = sum(delta_conf),
      .by = confederacion
    )

  base <- rc_pub |>
    dplyr::select(confederacion, obs_vs_esp, transfer_neto) |>
    dplyr::left_join(recalc, by = "confederacion") |>
    dplyr::mutate(dplyr::across(c(obs_vs_esp_recalc, transfer_neto_recalc), \(x) dplyr::coalesce(x, 0)))

  tabla_obs <- comparar_cifra(
    llave = base$confederacion,
    valor_publicado = base$obs_vs_esp,
    valor_recalculado = base$obs_vs_esp_recalc,
    tolerancia = TOLERANCIA_REDONDEO,
    nombre_familia = "Familia C", nombre_cifra = "obs_vs_esp"
  )
  tabla_transfer <- comparar_cifra(
    llave = base$confederacion,
    valor_publicado = base$transfer_neto,
    valor_recalculado = base$transfer_neto_recalc,
    tolerancia = TOLERANCIA_REDONDEO,
    nombre_familia = "Familia C", nombre_cifra = "transfer_neto"
  )
  dplyr::bind_rows(
    dplyr::mutate(tabla_obs, cifra = "obs_vs_esp"),
    dplyr::mutate(tabla_transfer, cifra = "transfer_neto")
  )
}, error = function(e) {
  log_msg(paste("Familia C fallo:", conditionMessage(e)), "WARN", "auditoria")
  tibble::tibble(llave = character(), publicado = double(), recalculado = double(),
                 diff_abs = double(), error = conditionMessage(e))
})
registro <- registrar_resultado(registro, "Familia C", "obs_vs_esp+transfer_neto", resultado_c)

# ============================================================================
# Spot-check — datos_interfaz.json coincide con las salidas del motor
# (no es una familia con recalculo propio: verifica que 39_reporte.R no
# introdujo discrepancias entre lo que el motor produjo y lo que se publico)
# ============================================================================
resultado_spot <- tryCatch({
  json <- jsonlite::fromJSON(ruta_salidas("datos_interfaz.json"), simplifyVector = FALSE)
  rating_pub <- readr::read_csv(ruta_salidas("rating_equipos.csv"),
                                 col_types = cols(codigo_fifa = col_character(), .default = col_guess()))

  equipos_json <- tibble::tibble(
    codigo = vapply(json$equipos, \(e) e$codigo, character(1)),
    rating_actual_json = vapply(json$equipos, \(e) e$rating_actual, double(1))
  )
  base <- rating_pub |>
    dplyr::select(codigo_fifa, rating_actual) |>
    dplyr::left_join(equipos_json, by = c("codigo_fifa" = "codigo"))

  comparar_cifra(
    llave = base$codigo_fifa,
    valor_publicado = base$rating_actual,
    valor_recalculado = base$rating_actual_json,
    tolerancia = TOLERANCIA_REDONDEO_JSON,  # r1() redondea a 1 decimal en 39_reporte.R
    nombre_familia = "Spot-check", nombre_cifra = "rating_actual (JSON vs CSV)"
  )
}, error = function(e) {
  log_msg(paste("Spot-check fallo:", conditionMessage(e)), "WARN", "auditoria")
  tibble::tibble(llave = character(), publicado = double(), recalculado = double(),
                 diff_abs = double(), error = conditionMessage(e))
})
registro <- registrar_resultado(registro, "Spot-check", "rating_actual JSON", resultado_spot)

# ---- Resumen final ----
n_familias_con_discrepancias <- sum(vapply(registro, \(t) nrow(t) > 0, logical(1)))
log_msg(sprintf("Auditoria completada: %d/%d familias con discrepancias fuera de tolerancia.",
                 n_familias_con_discrepancias, length(registro)),
        if (n_familias_con_discrepancias == 0) "INFO" else "WARN", "auditoria")

for (clave in names(registro)) {
  tabla <- registro[[clave]]
  if (nrow(tabla) > 0) {
    message(sprintf("--- Discrepancias en %s ---", clave))
    print(tabla)
  }
}

# ---- Reporte a disco solo si hay discrepancias (evidencia, politica 5.3.12) ----
if (n_familias_con_discrepancias > 0) {
  dir.create(dirname(RUTA_REPORTE), showWarnings = FALSE, recursive = TRUE)
  lineas <- c(
    sprintf("# Auditoria de cifras publicadas — %s", format(Sys.Date())),
    "",
    "Protocolo 4.5 (SETTINGS). Discrepancias fuera de tolerancia encontradas:",
    ""
  )
  for (clave in names(registro)) {
    tabla <- registro[[clave]]
    if (nrow(tabla) > 0) {
      lineas <- c(lineas, sprintf("## %s", clave), "", knitr::kable(tabla) |> paste(collapse = "\n"), "")
    }
  }
  writeLines(lineas, RUTA_REPORTE)
  log_msg(sprintf("Reporte de discrepancias escrito: %s", RUTA_REPORTE), "WARN", "auditoria")
}

invisible(registro)
