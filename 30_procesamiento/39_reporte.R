# ---- Header ----
# Nombre: 39_reporte.R
# Proposito: emitir datos_interfaz.json consumido por index.html (fetch),
#   cumpliendo el shape exacto del contrato (meta, confederaciones[], equipos[].historial[]).
# Insumos: 20_insumos/equipos_mundial2026.csv, ranking_fifa_20260611.csv, elo_20260702.csv;
#   40_salidas/rating_equipos.csv, rating_confederaciones.csv,
#   rating_confederaciones_compuesto.csv, rating_confederaciones_elo.csv,
#   historial_partidos.csv, fuerza_equipos.csv
# Salidas: 40_salidas/datos_interfaz.json
# Autor: pipeline mundial2026_confederaciones
# Fecha: 2026-07-02

# ---- Auto-instalacion ----
paquetes_necesarios <- c("dplyr", "readr", "jsonlite", "here", "purrr")
faltantes <- paquetes_necesarios[!vapply(paquetes_necesarios, requireNamespace, logical(1), quietly = TRUE)]
if (length(faltantes) > 0) install.packages(faltantes)

# ---- Library ----
library(dplyr)
library(readr)
library(jsonlite)
library(purrr)

# ---- Rutas centralizadas ----
ruta_maestro   <- here::here("20_insumos", "equipos_mundial2026.csv")
ruta_fifa      <- here::here("20_insumos", "ranking_fifa_20260611.csv")
ruta_elo       <- here::here("20_insumos", "elo_20260702.csv")
ruta_rating    <- here::here("40_salidas", "rating_equipos.csv")
ruta_fuerza    <- here::here("40_salidas", "fuerza_equipos.csv")
ruta_conf      <- here::here("40_salidas", "rating_confederaciones.csv")
ruta_conf_comp <- here::here("40_salidas", "rating_confederaciones_compuesto.csv")
ruta_conf_elo  <- here::here("40_salidas", "rating_confederaciones_elo.csv")
ruta_historial <- here::here("40_salidas", "historial_partidos.csv")
ruta_salida    <- here::here("40_salidas", "datos_interfaz.json")

# ---- Constantes y parametros ----
FECHA_ACTUALIZACION <- "2026-07-02"
NOMBRE_TORNEO <- "Mundial 2026"
SEDE_DEFAULT <- "neutral"  # sin insumo de sede en el pipeline actual
# P8: fuente_fuerza ya no se redeclara aqui; se lee de fuerza_equipos.csv
# (unica fuente de verdad, escrita por 31_ingesta_fuerza.R), eliminando el
# riesgo de desincronizacion entre dos constantes en dos scripts.

# ---- Funciones ----

# Escritura atomica: patron write -> rename (politica 5.2.4).
escribir_json_atomico <- function(objeto, destino) {
  tmp <- paste0(destino, ".tmp")
  jsonlite::write_json(objeto, tmp, auto_unbox = TRUE, digits = NA, pretty = FALSE)
  file.rename(tmp, destino)
  invisible(destino)
}

# Redondea a 1 decimal, replicando r1() del mock en index.html.
r1 <- function(x) round(x, 1)

# ---- Flujo principal ----

# 1. Lectura
maestro   <- read_csv(ruta_maestro, col_types = cols(codigo_fifa = col_character(), .default = col_guess()))
fifa      <- read_csv(ruta_fifa, col_types = cols(codigo_fifa = col_character(), .default = col_guess()))
elo       <- read_csv(ruta_elo, col_types = cols(codigo_fifa = col_character(), .default = col_guess()))
rating    <- read_csv(ruta_rating, col_types = cols(codigo_fifa = col_character(), .default = col_guess()))
conf      <- read_csv(ruta_conf, col_types = cols(.default = col_guess()))
conf_comp <- read_csv(ruta_conf_comp, col_types = cols(.default = col_guess()))
conf_elo  <- read_csv(ruta_conf_elo, col_types = cols(.default = col_guess()))
historial <- read_csv(ruta_historial, col_types = cols(codigo = col_character(), rival = col_character(), .default = col_guess()))
fuerza    <- read_csv(ruta_fuerza, col_types = cols(codigo_fifa = col_character(), fuente_fuerza = col_character(), .default = col_guess()))

# P8: fuente_fuerza leida de fuerza_equipos.csv (unica fuente de verdad).
# La columna debe ser constante en las 48 filas (misma corrida de 31);
# si no lo es, el insumo esta corrupto y se detiene antes de publicar.
stopifnot("fuente_fuerza debe ser un valor unico en fuerza_equipos.csv" =
            dplyr::n_distinct(fuerza$fuente_fuerza) == 1)
FUENTE_FUERZA_ACTUAL <- fuerza$fuente_fuerza[1]

# 2. Validacion de integridad (C.8)
stopifnot(
  "maestro debe tener 48 equipos" = nrow(maestro) == 48,
  "fifa debe tener 48 equipos" = nrow(fifa) == 48,
  "elo debe tener 48 equipos" = nrow(elo) == 48,
  "rating debe tener 48 equipos" = nrow(rating) == 48,
  "conf debe tener 6 confederaciones" = nrow(conf) == 6,
  "conf_comp debe tener 6 confederaciones" = nrow(conf_comp) == 6,
  "conf_elo debe tener 6 confederaciones" = nrow(conf_elo) == 6
)
if (anyNA(rating$rating_actual)) warning("NAs detectados en rating_actual")

# 3. Maestro enriquecido (nombre, pos_fifa, puntos_fifa, elo) para joins de equipo y de rival.
maestro_enriquecido <- maestro |>
  select(codigo_fifa, equipo_es, confederacion, grupo) |>
  left_join(select(fifa, codigo_fifa, pos_fifa, puntos_fifa), by = "codigo_fifa") |>
  left_join(select(elo, codigo_fifa, elo), by = "codigo_fifa")

# 4. Transformacion — equipos (shape: codigo, nombre, confederacion, grupo, pos_fifa,
#    puntos_fifa, elo, rating_inicial, rating_actual, rank_inicial, rank_actual, delta, historial[])
equipos_base <- rating |>
  left_join(maestro_enriquecido, by = "codigo_fifa", suffix = c("", "_maestro")) |>
  transmute(
    codigo = codigo_fifa,
    nombre = equipo_es,
    confederacion = confederacion,
    grupo = grupo,
    pos_fifa = pos_fifa,
    puntos_fifa = puntos_fifa,
    elo = elo,
    rating_inicial = r1(rating_inicial),
    rating_actual = r1(rating_actual),
    rank_inicial = rank_inicial,
    rank_actual = rank_actual,
    delta = r1(delta_rating)
  )
stopifnot(
  "nombre no debe tener NA tras el join" = !anyNA(equipos_base$nombre),
  "pos_fifa no debe tener NA tras el join" = !anyNA(equipos_base$pos_fifa),
  "puntos_fifa no debe tener NA tras el join" = !anyNA(equipos_base$puntos_fifa),
  "elo no debe tener NA tras el join" = !anyNA(equipos_base$elo)
)

# 5. Historial por equipo, con rival_nombre/rival_confederacion resueltos por join contra el maestro.
mapa_rival <- maestro_enriquecido |> select(codigo_fifa, equipo_es, confederacion)

historial_enriquecido <- historial |>
  left_join(mapa_rival, by = c("rival" = "codigo_fifa")) |>
  arrange(codigo, id_partido) |>
  mutate(partido = row_number(), .by = codigo) |>
  transmute(
    codigo = codigo,
    partido = partido,
    fase = fase,
    rival = rival,
    rival_nombre = equipo_es,
    rival_confederacion = confederacion,
    sede = SEDE_DEFAULT,
    gf = gf,
    ga = gc,
    resultado = resultado,
    W = W,
    We = r1(We),
    I = I,
    G = r1(G),
    delta_r = delta_r,
    rating_post = rating_post,
    rank_post = rank_post,
    inter_confederacion = inter_confederacion,
    delta_conf = r1(delta_conf)
  )
stopifnot("rival_nombre no debe tener NA tras el join" = !anyNA(historial_enriquecido$rival_nombre))

# Historial ya viene ordenado por codigo, partido (arrange previo). Split por equipo.
historial_por_equipo <- split(select(historial_enriquecido, -codigo), historial_enriquecido$codigo)

equipos_json <- lapply(seq_len(nrow(equipos_base)), function(i) {
  fila <- equipos_base[i, ]
  hist_equipo <- historial_por_equipo[[fila$codigo]]
  list(
    codigo = fila$codigo,
    nombre = fila$nombre,
    confederacion = fila$confederacion,
    grupo = fila$grupo,
    pos_fifa = fila$pos_fifa,
    puntos_fifa = fila$puntos_fifa,
    elo = fila$elo,
    rating_inicial = fila$rating_inicial,
    rating_actual = fila$rating_actual,
    rank_inicial = fila$rank_inicial,
    rank_actual = fila$rank_actual,
    delta = fila$delta,
    historial = if (is.null(hist_equipo)) list() else purrr::transpose(hist_equipo)
  )
})

# 6. Transformacion — confederaciones (shape: id, rating_inicial, rating_actual,
#    delta, obs_vs_esp, transfer_neto, n_equipos)
confederaciones_json <- conf |>
  transmute(
    id = confederacion,
    rating_inicial = r1(rating_inicial),
    rating_actual = r1(rating_actual),
    delta = r1(delta),
    obs_vs_esp = r1(obs_vs_esp),
    transfer_neto = r1(transfer_neto),
    n_equipos = n_equipos
  ) |>
  purrr::transpose()

# Mismo shape, bajo fuerza_base_compuesto (toggle FIFA/Compuesto del sitio).
confederaciones_compuesto_json <- conf_comp |>
  transmute(
    id = confederacion,
    rating_inicial = r1(rating_inicial),
    rating_actual = r1(rating_actual),
    delta = r1(delta),
    obs_vs_esp = r1(obs_vs_esp),
    transfer_neto = r1(transfer_neto),
    n_equipos = n_equipos
  ) |>
  purrr::transpose()

# Mismo shape, bajo fuerza_elo (tercer boton del toggle del sitio).
confederaciones_elo_json <- conf_elo |>
  transmute(
    id = confederacion,
    rating_inicial = r1(rating_inicial),
    rating_actual = r1(rating_actual),
    delta = r1(delta),
    obs_vs_esp = r1(obs_vs_esp),
    transfer_neto = r1(transfer_neto),
    n_equipos = n_equipos
  ) |>
  purrr::transpose()

# 7. Ensamblaje final segun contrato (index.html linea 541 en adelante)
salida <- list(
  meta = list(
    torneo = NOMBRE_TORNEO,
    actualizado = FECHA_ACTUALIZACION,
    fuente_fuerza = FUENTE_FUERZA_ACTUAL
  ),
  confederaciones = confederaciones_json,
  confederaciones_compuesto = confederaciones_compuesto_json,
  confederaciones_elo = confederaciones_elo_json,
  equipos = equipos_json
)

# 8. Validacion final de shape antes de escribir
stopifnot(
  "equipos debe tener 48 elementos" = length(salida$equipos) == 48,
  "confederaciones debe tener 6 elementos" = length(salida$confederaciones) == 6,
  "confederaciones_compuesto debe tener 6 elementos" = length(salida$confederaciones_compuesto) == 6,
  "confederaciones_elo debe tener 6 elementos" = length(salida$confederaciones_elo) == 6
)

# 9. Escritura atomica
escribir_json_atomico(salida, ruta_salida)

# 10. Resumen
message(sprintf(
  "[39_reporte] OK: %d equipos, %d confederaciones, fuente_fuerza='%s' -> %s",
  length(salida$equipos), length(salida$confederaciones), FUENTE_FUERZA_ACTUAL, ruta_salida
))
