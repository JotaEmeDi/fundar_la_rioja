## 03 (prep, índice). Remuneración SIPA: X-13 → real → índice ene-2025 = 100.
## Estilo CEPA / Trabajo: desestacionalizar, deflactar por IPC, indexar.
## NO pisa 03_salarios_privados_SIPA_real.csv: CSV regional nuevo.
##
## Assumptions: seasonal + x13binary instalados; serie mensual continua.
## Fails if: falta SIPA/IPC, mes base ausente, o seas() no converge.
##
## Corte FECHA_HASTA (lectura operativa)
## ------------------------------------
## El RMD del monitor NO define el último mes: toma max(fecha) del CSV de
## salida de este prep. Ese máximo = FECHA_HASTA acá.
##
## Por qué hoy es 2025-09-01: oct-2025 del Excel muestra un salto nominal
## atípico (y nov lo revierte, sobre todo en La Rioja); ene–mar 2026
## duplican oct–dic 2025. Incluir ese tramo en el X-13 contamina el extremo.
##
## Para extender el monitor a oct/nov u otro mes:
##   1) Verificar que el raw tenga ese mes con valor real (no duplicado / no raro).
##   2) Subir FECHA_HASTA acá (y el mismo valor en
##      03_salarios_privados_SIPA.R y 03_salarios_privados_SIPA_indice.R).
##   3) Re-correr este prep + viz → knitear el RMD.
## El rótulo del último mes lo arma el RMD solo a partir del CSV.

library(tidyverse)
library(lubridate)
library(seasonal)

path_sipa <- "./data/inputs_md/03_salarios_privados_SIPA.csv"
path_ipc  <- "./data/raw_data/ipc/ipc_nacional_base_dic2016_mensual.csv"
path_out  <- "./data/inputs_md/03_salarios_privados_SIPA_indice_region.csv"

FECHA_BASE  <- as.Date("2025-01-01")
## Ver bloque "Corte FECHA_HASTA" del encabezado.
FECHA_HASTA <- as.Date("2025-09-01")

noa <- c("Catamarca", "Jujuy", "Salta", "Santiago del Estero", "Tucumán")

if (!file.exists(path_sipa)) {
  stop("Falta ", path_sipa, ". Correr antes src/03_prep_salarios_privados_SIPA.R")
}
if (!file.exists(path_ipc)) {
  stop("Falta ", path_ipc, ". Correr antes src/03_prep_salarios_privados_SIPA_real.R")
}

sipa <- read_csv(path_sipa, show_col_types = FALSE) %>%
  mutate(fecha = as.Date(fecha))

ipc <- read_csv(path_ipc, show_col_types = FALSE) %>%
  mutate(fecha = as.Date(indice_tiempo)) %>%
  transmute(fecha, ipc_nacional = ipc_ng_nacional)

df_reg <- sipa %>%
  mutate(
    la_rioja_region = case_when(
      jurisdiccion == "La Rioja" ~ "3. La Rioja",
      jurisdiccion %in% noa ~ "2. NOA-Resto",
      TRUE ~ "1. Resto país"
    )
  ) %>%
  group_by(fecha, la_rioja_region) %>%
  summarise(salario_nominal = mean(salario_promedio, na.rm = TRUE), .groups = "drop") %>%
  left_join(ipc, by = "fecha") %>%
  filter(!is.na(ipc_nacional), !is.na(salario_nominal)) %>%
  filter(fecha <= FECHA_HASTA) %>%
  arrange(la_rioja_region, fecha)

if (!FECHA_BASE %in% df_reg$fecha) {
  stop("La fecha base ", FECHA_BASE, " no está en la serie. Revisar SIPA/IPC.")
}

desestacionalizar <- function(fechas, y, etiqueta) {
  ## Prueba specs X-13 de más automático a más simple (series regionales cortas
  ## / con SAC fuerte a veces fallan con SEATS default).
  start_y <- year(min(fechas))
  start_m <- month(min(fechas))
  ts_y <- ts(y, start = c(start_y, start_m), frequency = 12)

  intentos <- list(
    function(x) seas(x),
    function(x) seas(x, x11 = ""),
    function(x) seas(x, x11 = "", regression.aictest = NULL),
    function(x) seas(x, x11 = "", regression.aictest = NULL, outlier = NULL),
    function(x) {
      seas(
        x,
        x11 = "",
        transform.function = "log",
        regression.aictest = NULL,
        outlier = NULL,
        automdl = NULL,
        arima.model = "(0 1 1)(0 1 1)"
      )
    }
  )

  last_err <- NULL
  for (i in seq_along(intentos)) {
    m <- tryCatch(intentos[[i]](ts_y), error = function(e) e)
    if (!inherits(m, "error")) {
      message("X-13 OK (", etiqueta, ") con intento #", i)
      return(as.numeric(final(m)))
    }
    last_err <- m
  }
  stop("X-13 falló en ", etiqueta, " tras ", length(intentos),
       " intentos. Último error: ", conditionMessage(last_err))
}

df_sa <- df_reg %>%
  group_by(la_rioja_region) %>%
  group_modify(~ {
    tibble(
      fecha = .x$fecha,
      salario_nominal = .x$salario_nominal,
      ipc_nacional = .x$ipc_nacional,
      salario_sa = desestacionalizar(.x$fecha, .x$salario_nominal, .y$la_rioja_region[1])
    )
  }) %>%
  ungroup() %>%
  mutate(salario_real_sa = salario_sa / ipc_nacional * 100)

## Índices base 100 = ene-2025.
## - indice_salario_real_sa: poder de compra (estilo CEPA: SA → /IPC → índice).
## - indice_salario_sa / indice_ipc: nominal SA e IPC (comparación auxiliar).
base_vals <- df_sa %>%
  filter(fecha == FECHA_BASE) %>%
  select(
    la_rioja_region,
    salario_sa_base = salario_sa,
    salario_real_sa_base = salario_real_sa,
    ipc_base = ipc_nacional
  )

ipc_base_unico <- unique(base_vals$ipc_base)
if (length(ipc_base_unico) != 1L) {
  stop("IPC base inconsistente entre regiones en ", FECHA_BASE)
}

out <- df_sa %>%
  left_join(base_vals, by = "la_rioja_region") %>%
  mutate(
    indice_salario_real_sa = 100 * salario_real_sa / salario_real_sa_base,
    indice_salario_sa = 100 * salario_sa / salario_sa_base,
    indice_ipc = 100 * ipc_nacional / ipc_base_unico,
    fecha_base = FECHA_BASE
  ) %>%
  select(
    fecha, la_rioja_region,
    salario_nominal, salario_sa, salario_real_sa,
    ipc_nacional,
    indice_salario_real_sa, indice_salario_sa, indice_ipc, fecha_base
  ) %>%
  arrange(fecha, la_rioja_region)

dir.create("./data/inputs_md", showWarnings = FALSE, recursive = TRUE)
write_csv(out, path_out)

message(
  "Listo: ", path_out, "\n",
  "Filas: ", nrow(out),
  " | base: ", FECHA_BASE,
  " | hasta: ", FECHA_HASTA,
  " | X-13 → real (SA/IPC) → índice (monitor principal)."
)
