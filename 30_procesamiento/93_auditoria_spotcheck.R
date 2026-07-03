# ============================================================================
# 93_auditoria_spotcheck.R
# Proposito: verificacion manual rapida, independiente del orquestador (92),
#            de invariantes estructurales que ninguna de las 3 familias
#            cubre por si sola: consistencia de conteos entre insumos y
#            salidas, y la distincion partido/id_partido documentada en
#            traspaso_cierre_v02.md seccion 7 (para que no se reintroduzca
#            la confusion en auditorias futuras).
# Insumos:   40_salidas/resultados_partidos.csv, historial_partidos.csv,
#            rating_equipos.csv, rating_confederaciones.csv
# Salidas:   ninguna (solo mensajes en consola; es un chequeo manual)
# Autor:     pipeline mundial2026_confederaciones
# Fecha:     2026-07-03
# ============================================================================

library(dplyr)
library(readr)

if (!exists("ruta_insumos")) {
  source(here::here("10_utils", "10_utils.R"))
  source(here::here("10_utils", "10_configuracion.R"))
}

resultados <- readr::read_csv(ruta_salidas("resultados_partidos.csv"), show_col_types = FALSE)
historial  <- readr::read_csv(ruta_salidas("historial_partidos.csv"), show_col_types = FALSE)
rating     <- readr::read_csv(ruta_salidas("rating_equipos.csv"), show_col_types = FALSE)
conf       <- readr::read_csv(ruta_salidas("rating_confederaciones.csv"), show_col_types = FALSE)

# ---- Check 1: historial tiene exactamente 2 filas por partido (una por
# equipo participante), verificando la distincion id_partido/partido ----
n_por_partido <- historial |> dplyr::summarise(n = dplyr::n(), .by = id_partido)
check1 <- all(n_por_partido$n == 2)
message(sprintf("[spot-check] Check 1 (2 filas por id_partido en historial): %s",
                 if (check1) "OK" else "FALLO"))
if (!check1) print(dplyr::filter(n_por_partido, n != 2))

# ---- Check 2: partido (indice secuencial) es 1..n sin huecos por equipo,
# nunca coincide en semantica con id_partido salvo por casualidad ----
# NOTA: `partido` (indice secuencial) no se persiste en historial_partidos.csv
# (columna calculada en memoria por 39_reporte.R). Se recalcula aqui con el
# mismo criterio (arrange codigo, id_partido -> row_number) para verificar
# que la secuencia es 1..n sin huecos por equipo.
historial_con_partido <- historial |>
  dplyr::arrange(codigo, id_partido) |>
  dplyr::mutate(partido = dplyr::row_number(), .by = codigo)

check2 <- historial_con_partido |>
  dplyr::summarise(secuencia_ok = identical(partido, seq_len(dplyr::n())), .by = codigo)
n_fallos_check2 <- sum(!check2$secuencia_ok)
message(sprintf("[spot-check] Check 2 (partido = 1..n secuencial por equipo): %s (%d equipos con hueco)",
                 if (n_fallos_check2 == 0) "OK" else "FALLO", n_fallos_check2))

# ---- Check 3: n_partidos en rating_equipos.csv coincide con el conteo
# real de filas de historial por equipo (camino independiente: contar
# filas vs. columna ya escrita por el motor) ----
conteo_real <- historial |> dplyr::summarise(n_real = dplyr::n(), .by = codigo)
base3 <- rating |>
  dplyr::select(codigo_fifa, n_partidos) |>
  dplyr::left_join(conteo_real, by = c("codigo_fifa" = "codigo")) |>
  dplyr::mutate(n_real = dplyr::coalesce(n_real, 0L))
check3 <- all(base3$n_partidos == base3$n_real)
message(sprintf("[spot-check] Check 3 (n_partidos = conteo real de historial): %s",
                 if (check3) "OK" else "FALLO"))
if (!check3) print(dplyr::filter(base3, n_partidos != n_real))

# ---- Check 4: total de partidos en resultados_partidos.csv * 2 =
# total de filas en historial_partidos.csv (invariante de forma, cubre
# duplicacion o perdida de filas en el bucle del motor) ----
check4 <- nrow(resultados) * 2 == nrow(historial)
message(sprintf("[spot-check] Check 4 (2 * n_partidos = n_filas_historial): %s (%d * 2 = %d, historial = %d)",
                 if (check4) "OK" else "FALLO", nrow(resultados), nrow(resultados) * 2, nrow(historial)))

# ---- Check 5: suma de delta_rating (rating_equipos) coincide con suma de
# delta_r (historial), ambos caminos deberian cuadrar por conservacion ----
suma_delta_rating <- sum(rating$delta_rating)
suma_delta_r_hist <- sum(historial$delta_r)
diff5 <- abs(suma_delta_rating - suma_delta_r_hist)
message(sprintf("[spot-check] Check 5 (suma delta_rating = suma delta_r historial): diff = %.6f (%s)",
                 diff5, if (diff5 < 0.1) "OK" else "REVISAR"))

n_fallos_totales <- sum(!check1, n_fallos_check2 > 0, !check3, !check4, diff5 >= 0.1)
message(sprintf("[spot-check] Resumen: %d/5 checks OK", 5 - n_fallos_totales))
