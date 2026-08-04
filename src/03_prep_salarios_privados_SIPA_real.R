library(tidyverse)
library(lubridate)

## 03 (prep, real). Remuneración SIPA privada deflactada por IPC.
## Parte de data/inputs_md/03_salarios_privados_SIPA.csv (pesos corrientes) y
## aplica el IPC nivel general (base dic-2016 = 100).
##
## salario_real_nac = salario_promedio / ipc_nacional * 100
## salario_real_reg = salario_promedio / ipc_regional * 100
##   (IPC regional INDEC de la provincia: NOA para La Rioja, etc.)
##
## La serie queda desde dic-2016 (inicio del IPC base 2016). Meses SIPA sin
## IPC matching se descartan.

path_sipa <- "./data/inputs_md/03_salarios_privados_SIPA.csv"
path_ipc  <- "./data/raw_data/ipc/ipc_nacional_base_dic2016_mensual.csv"
path_out  <- "./data/inputs_md/03_salarios_privados_SIPA_real.csv"

url_ipc <- paste0(
  "https://infra.datos.gob.ar/catalog/sspm/dataset/145/distribution/145.3/",
  "download/indice-precios-al-consumidor-nivel-general-base-diciembre-2016-mensual.csv"
)

mapa_ipc_region <- tribble(
  ~jurisdiccion,          ~ipc_region, ~col_ipc_regional,
  "C.A.B.A.",             "GBA",       "ipc_ng_gba",
  "Buenos Aires",         "GBA",       "ipc_ng_gba",
  "Córdoba",              "Pampeana",  "ipc_ng_pampeana",
  "Santa Fe",             "Pampeana",  "ipc_ng_pampeana",
  "Entre Ríos",           "Pampeana",  "ipc_ng_pampeana",
  "La Pampa",             "Pampeana",  "ipc_ng_pampeana",
  "Chaco",                "NEA",       "ipc_ng_nea",
  "Corrientes",           "NEA",       "ipc_ng_nea",
  "Formosa",              "NEA",       "ipc_ng_nea",
  "Misiones",             "NEA",       "ipc_ng_nea",
  "Catamarca",            "NOA",       "ipc_ng_noa",
  "Jujuy",                "NOA",       "ipc_ng_noa",
  "La Rioja",             "NOA",       "ipc_ng_noa",
  "Salta",                "NOA",       "ipc_ng_noa",
  "Santiago del Estero",  "NOA",       "ipc_ng_noa",
  "Tucumán",              "NOA",       "ipc_ng_noa",
  "Mendoza",              "Cuyo",      "ipc_ng_cuyo",
  "San Juan",             "Cuyo",      "ipc_ng_cuyo",
  "San Luis",             "Cuyo",      "ipc_ng_cuyo",
  "Chubut",               "Patagonia", "ipc_ng_patagonia",
  "Neuquén",              "Patagonia", "ipc_ng_patagonia",
  "Río Negro",            "Patagonia", "ipc_ng_patagonia",
  "Santa Cruz",           "Patagonia", "ipc_ng_patagonia",
  "Tierra del Fuego",     "Patagonia", "ipc_ng_patagonia"
)

if (!file.exists(path_sipa)) {
  stop("Falta ", path_sipa, ". Correr antes src/03_prep_salarios_privados_SIPA.R")
}

## Refresca IPC si falta o si el archivo local no llega al último mes SIPA.
sipa <- read_csv(path_sipa, show_col_types = FALSE) %>%
  mutate(fecha = as.Date(fecha))

need_ipc <- TRUE
if (file.exists(path_ipc)) {
  ipc_check <- read_csv(path_ipc, show_col_types = FALSE) %>%
    mutate(fecha = as.Date(indice_tiempo))
  need_ipc <- max(ipc_check$fecha, na.rm = TRUE) < max(sipa$fecha, na.rm = TRUE)
}

if (need_ipc) {
  dir.create(dirname(path_ipc), showWarnings = FALSE, recursive = TRUE)
  download.file(url_ipc, destfile = path_ipc, mode = "wb")
}

ipc <- read_csv(path_ipc, show_col_types = FALSE) %>%
  mutate(fecha = as.Date(indice_tiempo)) %>%
  select(
    fecha,
    ipc_nacional = ipc_ng_nacional,
    ipc_ng_gba, ipc_ng_pampeana, ipc_ng_nea,
    ipc_ng_noa, ipc_ng_cuyo, ipc_ng_patagonia
  )

ipc_long <- ipc %>%
  select(-ipc_nacional) %>%
  pivot_longer(-fecha, names_to = "col_ipc_regional", values_to = "ipc_regional")

df <- sipa %>%
  left_join(mapa_ipc_region, by = "jurisdiccion") %>%
  left_join(select(ipc, fecha, ipc_nacional), by = "fecha") %>%
  left_join(ipc_long, by = c("fecha", "col_ipc_regional")) %>%
  filter(!is.na(ipc_nacional), !is.na(ipc_regional)) %>%
  mutate(
    salario_real_nac = salario_promedio / ipc_nacional * 100,
    salario_real_reg = salario_promedio / ipc_regional * 100
  ) %>%
  arrange(jurisdiccion, fecha) %>%
  group_by(jurisdiccion) %>%
  mutate(
    ## Media móvil 12 meses: suaviza el “serrucho” del SAC (jun/dic).
    salario_real_nac_ma12 = {
      x <- salario_real_nac
      out <- rep(NA_real_, length(x))
      if (length(x) >= 12L) {
        for (i in 12:length(x)) out[i] <- mean(x[(i - 11L):i])
      }
      out
    },
    salario_real_reg_ma12 = {
      x <- salario_real_reg
      out <- rep(NA_real_, length(x))
      if (length(x) >= 12L) {
        for (i in 12:length(x)) out[i] <- mean(x[(i - 11L):i])
      }
      out
    }
  ) %>%
  ungroup() %>%
  select(
    jurisdiccion, fecha,
    salario_promedio,
    ipc_nacional, ipc_regional, ipc_region,
    salario_real_nac, salario_real_reg,
    salario_real_nac_ma12, salario_real_reg_ma12
  ) %>%
  arrange(fecha, jurisdiccion)

dir.create("./data/inputs_md", showWarnings = FALSE, recursive = TRUE)
path_tmp <- sub("\\.csv$", "_tmp.csv", path_out)
write_ok <- tryCatch({
  write_csv(df, path_out)
  TRUE
}, error = function(e) {
  write_csv(df, path_tmp)
  message("No se pudo sobrescribir ", path_out, " (¿archivo abierto?). Se escribió ", path_tmp)
  FALSE
})
if (write_ok && file.exists(path_tmp)) {
  unlink(path_tmp)
}

message(
  "Listo: ", if (write_ok) path_out else path_tmp, "\n",
  "Filas: ", nrow(df),
  " | fechas: ", min(df$fecha), " a ", max(df$fecha),
  " | pesos de dic-2016 (IPC base 100).",
  " Incluye media móvil 12 meses de la serie real."
)
