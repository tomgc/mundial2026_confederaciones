# ============================================================================
# 33_motor_elo.R
# Proposito: motor Elo/FIFA SUM de dos niveles.
#            Nivel 1 (seleccion): dR = I * G * (W - We), G continuo,
#            sin factor sorpresa (W - We ya la mide).
#            Nivel 2 (confederacion): R* = R + C, con C actualizado solo
#            en partidos entre confederaciones distintas.
#            Inferencia de avance: en partidos de eliminacion directa
#            empatados en marcador (dataset sin columna de penales/prorroga),
#            W se fuerza a 1/0 segun si el equipo aparece en la fase
#            siguiente; si no hay fase siguiente aun jugada, W=0.5
#            provisional con flag pendiente_resolucion.
# Insumos:   40_salidas/fuerza_equipos.csv       (fuerza base 0-100, por equipo)
#            40_salidas/resultados_partidos.csv  (partidos jugados)
# Salidas:   40_salidas/rating_equipos.csv    (rating final + historial resumido)
#            40_salidas/historial_partidos.csv (detalle partido a partido, insumo del reporte)
#            40_salidas/rating_confederaciones.csv (nivel 2, bajo FUENTE_FUERZA activa)
#            40_salidas/rating_confederaciones_compuesto.csv (nivel 2, bajo
#              fuerza_base_compuesto siempre, para el toggle FIFA/Compuesto del sitio)
# Autor:     [tu nombre]
# Fecha:     2026-07-02
# ============================================================================

# ---- Auto-instalacion ----
.pkgs <- c("here", "dplyr", "readr", "janitor", "tibble", "purrr", "tidyr")
.falta <- .pkgs[!vapply(.pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(.falta) > 0) utils::install.packages(.falta)

library(dplyr)
library(readr)
library(purrr)
library(tidyr)

if (!exists("ruta_insumos")) {
  source(here::here("10_utils", "10_utils.R"))
  source(here::here("10_utils", "10_configuracion.R"))
}

# ---- Constantes y parametros ----
ARCHIVO_FUERZA     <- ruta_salidas("fuerza_equipos.csv")
ARCHIVO_RESULTADOS <- ruta_salidas("resultados_partidos.csv")

ARCHIVO_RATING_EQUIPOS  <- ruta_salidas("rating_equipos.csv")
ARCHIVO_HISTORIAL       <- ruta_salidas("historial_partidos.csv")
ARCHIVO_RATING_CONF     <- ruta_salidas("rating_confederaciones.csv")
ARCHIVO_RATING_CONF_COMPUESTO <- ruta_salidas("rating_confederaciones_compuesto.csv")

# Escalera de fases del torneo, en orden de ejecucion. Toda fase fuera de
# "grupos" es eliminacion directa (empate exige desempate real).
ORDEN_FASES <- c("grupos", "dieciseisavos", "octavos", "cuartos",
                 "semifinal", "tercer_lugar", "final")
FASES_ELIMINACION <- setdiff(ORDEN_FASES, "grupos")

# Importancia por fase (I), constante nombrada, ajustable sin tocar el motor.
IMPORTANCIA_FASE <- c(
  grupos        = 25,
  dieciseisavos = 35,
  octavos       = 40,
  cuartos       = 50,
  semifinal     = 60,
  tercer_lugar  = 45,
  final         = 70
)

# Parametro de escala del rating (Elo estandar). fuerza_base ya viene 0-100;
# se reescala a un rango tipo Elo para que dR tenga la magnitud usual.
ESCALA_RATING <- 20  # multiplica fuerza_base (0-100) -> rating inicial ~0-2000
BASE_LOGISTICA <- 400  # base estandar de la formula de expectativa Elo

# Transferencia a confederacion: fraccion del dR del equipo que se traspasa
# al rating de su confederacion, solo en cruces inter-confederacion.
PESO_TRANSFERENCIA_CONF <- 0.15

# ---- Utilidad: escritura atomica (write -> rename), politica C.4 ----
escribir_csv_atomico <- function(df, destino) {
  tmp <- paste0(destino, ".tmp")
  readr::write_csv(df, tmp)
  file.rename(tmp, destino)
  invisible(destino)
}

# ---- Formula de expectativa Elo estandar ----
expectativa <- function(r_propio, r_rival) {
  1 / (1 + 10^((r_rival - r_propio) / BASE_LOGISTICA))
}

# ---- Factor de goles continuo: G = 1 + ln(d), d = max(1, dif_goles) ----
factor_goles <- function(gf, gc) {
  d <- pmax(1, abs(gf - gc))
  1 + log(d)
}

# ---- Flujo principal ----
log_msg("Iniciando motor Elo/FIFA SUM", "INFO", "33_motor")

fuerza <- readr::read_csv(ARCHIVO_FUERZA, col_types = readr::cols(.default = readr::col_guess())) |>
  janitor::clean_names() |>
  dplyr::mutate(codigo_fifa = as.character(codigo_fifa))

resultados <- readr::read_csv(ARCHIVO_RESULTADOS, col_types = readr::cols(.default = readr::col_guess())) |>
  janitor::clean_names() |>
  dplyr::mutate(
    local_codigo  = as.character(local_codigo),
    visita_codigo = as.character(visita_codigo),
    fase          = factor(fase, levels = ORDEN_FASES, ordered = TRUE)
  )

if (any(is.na(resultados$fase))) {
  stop("Hay partidos con fase fuera de ORDEN_FASES (revisar MAPA_FASE en 32).", call. = FALSE)
}

# ---- Inferencia de avance en empates de eliminacion directa ----
# Un equipo "avanza" en una fase de eliminacion si aparece (local o visita)
# en cualquier partido de una fase posterior. Si no hay fase posterior
# jugada aun, queda pendiente_resolucion.
equipos_por_fase <- resultados |>
  dplyr::filter(fase %in% FASES_ELIMINACION) |>
  tidyr::pivot_longer(c(local_codigo, visita_codigo), values_to = "codigo") |>
  dplyr::distinct(fase, codigo) |>
  dplyr::mutate(fase_num = as.integer(fase))

avanzo_a_fase_posterior <- function(codigo, fase_actual_num) {
  any(equipos_por_fase$codigo == codigo & equipos_por_fase$fase_num > fase_actual_num)
}

resultados <- resultados |>
  dplyr::mutate(
    empate = gf_local == gf_visita,
    es_eliminacion = fase %in% FASES_ELIMINACION,
    fase_num = as.integer(fase)
  ) |>
  dplyr::rowwise() |>
  dplyr::mutate(
    local_avanza  = if (es_eliminacion && empate) avanzo_a_fase_posterior(local_codigo, fase_num) else NA,
    visita_avanza = if (es_eliminacion && empate) avanzo_a_fase_posterior(visita_codigo, fase_num) else NA,
    # W del punto de vista del equipo local. Casos:
    # - no empate: resultado normal (1/0.5/0 segun marcador)
    # - empate en grupos: 0.5 real (no hay desempate en fase de grupos)
    # - empate en eliminacion: forzado por avance si se conoce; si ninguno
    #   de los dos aparece en fase posterior (ambos NA/FALSE), pendiente.
    w_local = dplyr::case_when(
      !empate ~ as.numeric(gf_local > gf_visita),
      empate && !es_eliminacion ~ 0.5,
      empate && es_eliminacion && isTRUE(local_avanza)  ~ 1,
      empate && es_eliminacion && isTRUE(visita_avanza) ~ 0,
      TRUE ~ 0.5  # pendiente_resolucion: provisional hasta que se juegue la siguiente fase
    ),
    pendiente_resolucion = empate && es_eliminacion && !isTRUE(local_avanza) && !isTRUE(visita_avanza)
  ) |>
  dplyr::ungroup()

n_pendientes <- sum(resultados$pendiente_resolucion)
if (n_pendientes > 0) {
  log_msg(sprintf("%d partido(s) empatado(s) de eliminacion sin fase posterior jugada: W=0.5 provisional.",
                  n_pendientes), "WARN", "33_motor")
}

# ---- Preparacion: rating inicial por equipo (fuerza_base reescalada) ----
rating_inicial <- fuerza |>
  dplyr::transmute(codigo_fifa, confederacion, grupo,
                    rating = fuerza_base * ESCALA_RATING)

# ---- Simulacion partido a partido (orden cronologico por fase, luego fecha) ----
orden_partidos <- resultados |>
  dplyr::arrange(fase, fecha, id_partido)

rating_actual <- setNames(rating_inicial$rating, rating_inicial$codigo_fifa)
conf_de       <- setNames(rating_inicial$confederacion, rating_inicial$codigo_fifa)
rating_conf   <- rating_inicial |>
  dplyr::summarise(rating_conf = mean(rating), .by = confederacion) |>
  tibble::deframe()

n_partidos_por_equipo <- setNames(rep(0L, nrow(rating_inicial)), rating_inicial$codigo_fifa)

historial <- vector("list", nrow(orden_partidos) * 2L)
idx <- 1L

for (i in seq_len(nrow(orden_partidos))) {
  p <- orden_partidos[i, ]
  fase_chr <- as.character(p$fase)
  Imp <- IMPORTANCIA_FASE[[fase_chr]]
  G   <- factor_goles(p$gf_local, p$gf_visita)

  r_local  <- rating_actual[[p$local_codigo]]
  r_visita <- rating_actual[[p$visita_codigo]]
  We_local <- expectativa(r_local, r_visita)
  W_local  <- p$w_local
  W_visita <- 1 - W_local
  We_visita <- 1 - We_local

  dR_local  <- Imp * G * (W_local  - We_local)
  dR_visita <- Imp * G * (W_visita - We_visita)

  inter_conf <- conf_de[[p$local_codigo]] != conf_de[[p$visita_codigo]]
  dC_local  <- if (inter_conf) PESO_TRANSFERENCIA_CONF * dR_local  else 0
  dC_visita <- if (inter_conf) PESO_TRANSFERENCIA_CONF * dR_visita else 0

  rating_actual[[p$local_codigo]]  <- r_local  + dR_local
  rating_actual[[p$visita_codigo]] <- r_visita + dR_visita
  n_partidos_por_equipo[[p$local_codigo]]  <- n_partidos_por_equipo[[p$local_codigo]]  + 1L
  n_partidos_por_equipo[[p$visita_codigo]] <- n_partidos_por_equipo[[p$visita_codigo]] + 1L

  if (inter_conf) {
    rating_conf[[conf_de[[p$local_codigo]]]]  <- rating_conf[[conf_de[[p$local_codigo]]]]  + dC_local
    rating_conf[[conf_de[[p$visita_codigo]]]] <- rating_conf[[conf_de[[p$visita_codigo]]]] + dC_visita
  }

  historial[[idx]] <- tibble::tibble(
    id_partido = p$id_partido, fecha = p$fecha, fase = fase_chr,
    codigo = p$local_codigo, rival = p$visita_codigo,
    gf = p$gf_local, gc = p$gf_visita,
    resultado = dplyr::case_when(W_local == 1 ~ "V", W_local == 0 ~ "D", TRUE ~ "E"),
    W = W_local, We = round(We_local, 4), I = Imp, G = round(G, 4),
    delta_r = round(dR_local, 3), rating_post = round(rating_actual[[p$local_codigo]], 3),
    inter_confederacion = inter_conf, delta_conf = round(dC_local, 3),
    pendiente_resolucion = p$pendiente_resolucion
  )
  idx <- idx + 1L

  historial[[idx]] <- tibble::tibble(
    id_partido = p$id_partido, fecha = p$fecha, fase = fase_chr,
    codigo = p$visita_codigo, rival = p$local_codigo,
    gf = p$gf_visita, gc = p$gf_local,
    resultado = dplyr::case_when(W_visita == 1 ~ "V", W_visita == 0 ~ "D", TRUE ~ "E"),
    W = W_visita, We = round(We_visita, 4), I = Imp, G = round(G, 4),
    delta_r = round(dR_visita, 3), rating_post = round(rating_actual[[p$visita_codigo]], 3),
    inter_confederacion = inter_conf, delta_conf = round(dC_visita, 3),
    pendiente_resolucion = p$pendiente_resolucion
  )
  idx <- idx + 1L
}

historial_partidos <- dplyr::bind_rows(historial) |>
  dplyr::arrange(codigo, fase, fecha, id_partido) |>
  dplyr::mutate(rank_post = NA_integer_, .by = fase)  # rank_post se calcula abajo por snapshot temporal

# ---- Rank tras cada partido (snapshot del ranking global en ese momento) ----
# Reconstruye el rating de todos los equipos en cada punto del tiempo para
# poder asignar rank_post correctamente (no solo el rating del propio equipo).
snapshot_ratings <- rating_inicial |> dplyr::select(codigo_fifa, rating)
rating_running <- setNames(snapshot_ratings$rating, snapshot_ratings$codigo_fifa)
rank_post_vec <- rep(NA_integer_, nrow(orden_partidos) * 2L)
idx2 <- 1L
for (i in seq_len(nrow(orden_partidos))) {
  p <- orden_partidos[i, ]
  fila_local  <- historial_partidos |> dplyr::filter(id_partido == p$id_partido, codigo == p$local_codigo)
  fila_visita <- historial_partidos |> dplyr::filter(id_partido == p$id_partido, codigo == p$visita_codigo)
  rating_running[[p$local_codigo]]  <- fila_local$rating_post[1]
  rating_running[[p$visita_codigo]] <- fila_visita$rating_post[1]
  orden <- order(-rating_running)
  rank_actual <- setNames(seq_along(orden), names(rating_running)[orden])
  historial_partidos$rank_post[historial_partidos$id_partido == p$id_partido &
                                 historial_partidos$codigo == p$local_codigo]  <- rank_actual[[p$local_codigo]]
  historial_partidos$rank_post[historial_partidos$id_partido == p$id_partido &
                                 historial_partidos$codigo == p$visita_codigo] <- rank_actual[[p$visita_codigo]]
}

# ---- Tabla final de rating por equipo ----
rank_inicial <- rating_inicial |>
  dplyr::arrange(dplyr::desc(rating)) |>
  dplyr::mutate(rank_inicial = dplyr::row_number())

rating_equipos <- rating_inicial |>
  dplyr::left_join(rank_inicial |> dplyr::select(codigo_fifa, rank_inicial), by = "codigo_fifa") |>
  dplyr::mutate(
    rating_actual = rating_actual[codigo_fifa],
    n_partidos    = n_partidos_por_equipo[codigo_fifa]
  ) |>
  dplyr::arrange(dplyr::desc(rating_actual)) |>
  dplyr::mutate(
    rank_actual = dplyr::row_number(),
    delta_rating = round(rating_actual - rating, 3),
    delta_rank   = rank_inicial - rank_actual
  ) |>
  dplyr::rename(rating_inicial = rating) |>
  dplyr::mutate(rating_inicial = round(rating_inicial, 3), rating_actual = round(rating_actual, 3))

# ---- Tabla de rating por confederacion ----
rating_conf_inicial <- rating_inicial |>
  dplyr::summarise(rating_inicial = mean(rating), n_equipos = dplyr::n(), .by = confederacion)

obs_esp_conf <- historial_partidos |>
  dplyr::left_join(rating_inicial |> dplyr::select(codigo_fifa, confederacion),
                    by = c("codigo" = "codigo_fifa")) |>
  dplyr::filter(inter_confederacion) |>
  dplyr::summarise(
    obs_vs_esp    = round(sum(W - We), 3),
    transfer_neto = round(sum(delta_conf), 3),
    .by = confederacion
  )

rating_confederaciones <- rating_conf_inicial |>
  dplyr::mutate(rating_actual = round(rating_conf[confederacion], 3)) |>
  dplyr::left_join(obs_esp_conf, by = "confederacion") |>
  dplyr::mutate(
    obs_vs_esp    = dplyr::coalesce(obs_vs_esp, 0),
    transfer_neto = dplyr::coalesce(transfer_neto, 0),
    delta = round(rating_actual - rating_inicial, 3),
    rating_inicial = round(rating_inicial, 3)
  ) |>
  dplyr::arrange(dplyr::desc(delta))

# ---- Segunda simulacion: solo confederaciones, bajo fuerza_base_compuesto ----
# Reutiliza w_local ya resuelto (no depende de la fuerza base); resimula
# unicamente el rating de confederacion para alimentar el toggle
# FIFA/Compuesto del sitio (equipos e historial siguen publicandose solo
# bajo FUENTE_FUERZA activa, sin cambios).
simular_confederaciones <- function(fuerza_tbl, columna_fuerza) {
  r_ini <- fuerza_tbl |>
    dplyr::transmute(codigo_fifa, confederacion,
                      rating = .data[[columna_fuerza]] * ESCALA_RATING)
  r_act <- setNames(r_ini$rating, r_ini$codigo_fifa)
  conf_local <- setNames(r_ini$confederacion, r_ini$codigo_fifa)
  r_conf <- r_ini |>
    dplyr::summarise(rating_conf = mean(rating), .by = confederacion) |>
    tibble::deframe()
  obs_esp <- tibble::tibble(confederacion = character(), obs_vs_esp = double(), transfer_neto = double())
  acumulador <- list()

  for (i in seq_len(nrow(orden_partidos))) {
    p <- orden_partidos[i, ]
    Imp <- IMPORTANCIA_FASE[[as.character(p$fase)]]
    G <- factor_goles(p$gf_local, p$gf_visita)
    r_l <- r_act[[p$local_codigo]]; r_v <- r_act[[p$visita_codigo]]
    We_l <- expectativa(r_l, r_v); We_v <- 1 - We_l
    W_l <- p$w_local; W_v <- 1 - W_l
    dR_l <- Imp * G * (W_l - We_l); dR_v <- Imp * G * (W_v - We_v)
    r_act[[p$local_codigo]] <- r_l + dR_l
    r_act[[p$visita_codigo]] <- r_v + dR_v
    inter_conf <- conf_local[[p$local_codigo]] != conf_local[[p$visita_codigo]]
    if (inter_conf) {
      dC_l <- PESO_TRANSFERENCIA_CONF * dR_l
      dC_v <- PESO_TRANSFERENCIA_CONF * dR_v
      r_conf[[conf_local[[p$local_codigo]]]] <- r_conf[[conf_local[[p$local_codigo]]]] + dC_l
      r_conf[[conf_local[[p$visita_codigo]]]] <- r_conf[[conf_local[[p$visita_codigo]]]] + dC_v
      acumulador[[length(acumulador) + 1]] <- tibble::tibble(
        confederacion = conf_local[[p$local_codigo]], obs = W_l - We_l, transf = dC_l)
      acumulador[[length(acumulador) + 1]] <- tibble::tibble(
        confederacion = conf_local[[p$visita_codigo]], obs = W_v - We_v, transf = dC_v)
    }
  }

  obs_esp <- if (length(acumulador) > 0) {
    dplyr::bind_rows(acumulador) |>
      dplyr::summarise(obs_vs_esp = round(sum(obs), 3), transfer_neto = round(sum(transf), 3), .by = confederacion)
  } else {
    tibble::tibble(confederacion = character(), obs_vs_esp = double(), transfer_neto = double())
  }

  r_ini |>
    dplyr::summarise(rating_inicial = mean(rating), n_equipos = dplyr::n(), .by = confederacion) |>
    dplyr::mutate(rating_actual = round(r_conf[confederacion], 3)) |>
    dplyr::left_join(obs_esp, by = "confederacion") |>
    dplyr::mutate(
      obs_vs_esp = dplyr::coalesce(obs_vs_esp, 0),
      transfer_neto = dplyr::coalesce(transfer_neto, 0),
      delta = round(rating_actual - rating_inicial, 3),
      rating_inicial = round(rating_inicial, 3)
    ) |>
    dplyr::arrange(dplyr::desc(delta))
}

rating_confederaciones_compuesto <- simular_confederaciones(fuerza, "fuerza_base_compuesto")

# ---- Validacion de integridad (politica C.8) ----
stopifnot(
  nrow(rating_equipos) == nrow(fuerza),
  !anyDuplicated(rating_equipos$codigo_fifa),
  all(!is.na(rating_equipos$rating_actual)),
  nrow(rating_confederaciones) == dplyr::n_distinct(fuerza$confederacion),
  nrow(rating_confederaciones_compuesto) == dplyr::n_distinct(fuerza$confederacion)
)

# ---- Escritura atomica ----
escribir_csv_atomico(rating_equipos, ARCHIVO_RATING_EQUIPOS)
escribir_csv_atomico(historial_partidos, ARCHIVO_HISTORIAL)
escribir_csv_atomico(rating_confederaciones, ARCHIVO_RATING_CONF)
escribir_csv_atomico(rating_confederaciones_compuesto, ARCHIVO_RATING_CONF_COMPUESTO)

log_msg(sprintf("Motor completado: %d equipos, %d partidos, %d filas de historial, %d pendientes de resolucion. Confederaciones (fifa y compuesto) escritas.",
                nrow(rating_equipos), nrow(orden_partidos), nrow(historial_partidos), n_pendientes),
        "INFO", "33_motor")
