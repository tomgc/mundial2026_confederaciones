# ============================================================================
# 31_ingesta_fuerza.R
# Proposito: construir la tabla de fuerza pre-torneo de las 48 selecciones
#            del Mundial 2026. Une tres insumos fijos:
#            (1) maestro estable (equipo, confederacion, grupo),
#            (2) ranking FIFA snapshot 11-jun-2026,
#            (3) Elo snapshot 02-jul-2026 (eloratings.net).
#            La fuente de la fuerza base es configurable (FUENTE_FUERZA).
#
#            NOTA DE DISEÑO (deuda de sesion anterior, resuelta): eloratings.net
#            renderiza su tabla via JavaScript (scripts/ratings.js sobre un
#            <div id="maindiv"> vacio en el HTML estatico); rvest no ejecuta
#            JS, por lo que el scraping siempre fallaba (Elo 0/48). Se
#            reemplaza por snapshot manual verificado, igual patron que FIFA
#            en la sesion anterior. Si se requiere Elo actualizado en el
#            futuro, la via correcta es un navegador headless (chromote/
#            RSelenium) o localizar el endpoint de datos real que consume
#            ratings.js, no el HTML de la pagina.
#
# Insumos:   20_insumos/equipos_mundial2026.csv    (maestro)
#            20_insumos/ranking_fifa_20260611.csv  (FIFA, snapshot oficial)
#            20_insumos/elo_20260702.csv           (Elo, snapshot manual)
# Salidas:   40_salidas/fuerza_equipos.csv (48 filas, escritura atomica)
# Autor:     [tu nombre]
# Fecha:     2026-07-02
# ============================================================================

# ---- Auto-instalacion ----
.pkgs <- c("here", "dplyr", "readr", "janitor")
.falta <- .pkgs[!vapply(.pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(.falta) > 0) utils::install.packages(.falta)

library(dplyr)
library(readr)

# ---- Carga de utilidades si corre en modo standalone ----
if (!exists("ruta_insumos")) {
  source(here::here("10_utils", "10_utils.R"))
  source(here::here("10_utils", "10_configuracion.R"))
}

# ---- Constantes y parametros ----
ARCHIVO_MAESTRO <- ruta_insumos("equipos_mundial2026.csv")
ARCHIVO_FIFA    <- ruta_insumos("ranking_fifa_20260611.csv")  # snapshot fijo, pre-torneo
ARCHIVO_ELO     <- ruta_insumos("elo_20260702.csv")           # snapshot fijo, verificado
ARCHIVO_SALIDA  <- ruta_salidas("fuerza_equipos.csv")

# Fuente de la fuerza base del modelo. Opciones: "fifa" | "elo" | "compuesto".
# "fifa"      ranking FIFA (base historica, respeta el requisito explicito).
# "elo"       rating Elo continuo (natural para inicializar un Elo).
# "compuesto" combina ambas segun PESO_COMPUESTO.
FUENTE_FUERZA  <- "fifa"
PESO_COMPUESTO <- c(fifa = 0.6, elo = 0.4)

N_EQUIPOS <- 48L

# ---- Utilidad: escritura atomica (write -> rename), politica C.4 ----
escribir_csv_atomico <- function(df, destino) {
  tmp <- paste0(destino, ".tmp")
  readr::write_csv(df, tmp)
  file.rename(tmp, destino)
  invisible(destino)
}

# ---- Normalizacion a escala 0-100 (min-max sobre los 48) ----
# P11: el minimo absoluto de la distribucion (ej. NZL en FIFA, unico
# equipo OFC) recibia fuerza_base = 0 exacto. Un rating inicial de cero
# genera We (probabilidad esperada) cercano a cero en todo cruce
# inter-confederacion, produciendo sorpresa maxima artificial ante
# cualquier resultado no-perdedor. Piso minimo: tras el min-max, ningun
# valor baja del percentil PISO_FUERZA_PCTL de la propia distribucion ya
# normalizada, evitando el cero exacto sin renormalizar la escala de los
# demas 47 equipos (decision: piso acotado, no renormalizacion global;
# ver 50_documentacion/activa/decisiones/20260703_decision_ofc_rating_inicial_cero.md).
PISO_FUERZA_PCTL <- 0.05

escala_0_100 <- function(x) {
  rango <- range(x, na.rm = TRUE)
  if (diff(rango) == 0) return(rep(50, length(x)))
  normalizado <- 100 * (x - rango[1]) / diff(rango)
  piso <- stats::quantile(normalizado, probs = PISO_FUERZA_PCTL, na.rm = TRUE, names = FALSE, type = 7)
  pmax(normalizado, piso)
}

# ---- Flujo principal ----
log_msg("Iniciando ingesta de fuerza pre-torneo", "INFO", "31_fuerza")

# 1. Maestro (universo estable). Codigos como character (politica C.6).
maestro <- readr::read_csv(ARCHIVO_MAESTRO, col_types = readr::cols(.default = readr::col_character())) |>
  janitor::clean_names()
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

# 3. Elo (insumo fijo, join directo por codigo_fifa)
elo <- readr::read_csv(
  ARCHIVO_ELO,
  col_types = readr::cols(codigo_fifa = readr::col_character(), elo = readr::col_double())
) |> janitor::clean_names()

faltan_elo <- setdiff(maestro$codigo_fifa, elo$codigo_fifa)
if (length(faltan_elo) > 0) {
  stop(sprintf("Faltan en el snapshot Elo: %s", paste(faltan_elo, collapse = ", ")), call. = FALSE)
}

# 4. Ensamblado
tabla <- maestro |>
  dplyr::select(codigo_fifa, equipo_es, equipo_en, confederacion, grupo) |>
  dplyr::left_join(fifa, by = "codigo_fifa") |>
  dplyr::left_join(elo,  by = "codigo_fifa")

disp_fifa <- sum(!is.na(tabla$puntos_fifa))
disp_elo  <- sum(!is.na(tabla$elo))
log_msg(sprintf("Cobertura: FIFA %d/%d, Elo %d/%d", disp_fifa, N_EQUIPOS, disp_elo, N_EQUIPOS),
        "INFO", "31_fuerza")

# 5. Fuerza base segun FUENTE_FUERZA
tabla <- tabla |>
  dplyr::mutate(
    fuerza_fifa = escala_0_100(puntos_fifa),
    fuerza_elo  = escala_0_100(elo),
    fuerza_base = dplyr::case_when(
      FUENTE_FUERZA == "fifa"      ~ fuerza_fifa,
      FUENTE_FUERZA == "elo"       ~ fuerza_elo,
      FUENTE_FUERZA == "compuesto" ~ PESO_COMPUESTO[["fifa"]] * fuerza_fifa +
                                     PESO_COMPUESTO[["elo"]]  * fuerza_elo,
      TRUE ~ NA_real_
    ),
    # Toggle FIFA/Compuesto en el sitio: se calcula siempre, sin importar
    # FUENTE_FUERZA activa, para que 33_motor_elo.R pueda resimular
    # confederaciones bajo ambos criterios.
    fuerza_base_compuesto = PESO_COMPUESTO[["fifa"]] * fuerza_fifa +
                             PESO_COMPUESTO[["elo"]]  * fuerza_elo,
    # Tercer boton del toggle: 100% Elo, siempre calculado.
    fuerza_base_elo_toggle = fuerza_elo,
    # P8: fuente_fuerza persistida en la salida (fuente unica de verdad).
    # 39_reporte.R la lee de aqui en vez de redeclarar una constante propia,
    # eliminando el riesgo de desincronizacion entre dos scripts.
    fuente_fuerza = FUENTE_FUERZA
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
log_msg(sprintf("Fuerza escrita: %s (base = %s)", ARCHIVO_SALIDA, FUENTE_FUERZA), "INFO", "31_fuerza")
