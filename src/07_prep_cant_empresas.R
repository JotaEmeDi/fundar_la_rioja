## 07 (prep). Cantidad de empresas empleadoras por jurisdicción (SRT).
## Fuente: Superintendencia de Riesgos del Trabajo, serie histórica según
## jurisdicción — ubicación de la persona trabajadora (UP).
## URL: https://www.srt.gob.ar/estadisticas/series/co/up/
##   Serie_historica_Segun_Jurisdiccion - Ubicacion Persona Trabajadora - UP.xlsx
## Hoja "Cuadro 6.2" (misma lectura que monitor-empresas / 02_informe_provincial.R).
##
## No usa la serie de ubicación fiscal. "Total" y "Sin datos" se descartan.
## Nombres de provincia se homologan a los canónicos de 05/07 (C.A.B.A., tildes).
##
## Para forzar una descarga nueva: borrar el xlsx en data/raw_data/srt/ y
## volver a correr este script.
##
## FECHA_HASTA: el Excel vigente llega más allá (abr–may 2026 al 14-ago-2026).
## El corte replica el CSV que ya usaba el monitor (máximo mar-2026).
## Subir la fecha cuando se quiera incorporar meses nuevos.

library(tidyverse)
library(readxl)
library(janitor)

FECHA_HASTA <- as.Date("2026-03-01")

url_srt <- paste0(
  "https://www.srt.gob.ar/estadisticas/series/co/up/",
  "Serie_historica_Segun_Jurisdiccion%20-%20Ubicacion%20Persona%20Trabajadora%20-%20UP.xlsx"
)
path_raw <- paste0(
  "./data/raw_data/srt/",
  "Serie_historica_Segun_Jurisdiccion - Ubicacion Persona Trabajadora - UP.xlsx"
)
path_out <- "./data/inputs_md/07_serie_empresas_por_jurisdiccion.csv"
hoja <- "Cuadro 6.2"

mapa_provincias <- tribble(
  ~jurisdiccion_raw,                         ~jurisdiccion,
  "Buenos Aires",                            "Buenos Aires",
  "C.A.B.A.",                                "C.A.B.A.",
  "CABA",                                    "C.A.B.A.",
  "Caba",                                    "C.A.B.A.",
  "Ciudad Autónoma de Buenos Aires",         "C.A.B.A.",
  "Ciudad Autonoma de Buenos Aires",         "C.A.B.A.",
  "Catamarca",                               "Catamarca",
  "Chaco",                                   "Chaco",
  "Chubut",                                  "Chubut",
  "Córdoba",                                 "Córdoba",
  "Cordoba",                                 "Córdoba",
  "Corrientes",                              "Corrientes",
  "Entre Ríos",                              "Entre Ríos",
  "Entre Rios",                              "Entre Ríos",
  "Formosa",                                 "Formosa",
  "Jujuy",                                   "Jujuy",
  "La Pampa",                                "La Pampa",
  "La Rioja",                                "La Rioja",
  "Mendoza",                                 "Mendoza",
  "Misiones",                                "Misiones",
  "Neuquén",                                 "Neuquén",
  "Neuquen",                                 "Neuquén",
  "Río Negro",                               "Río Negro",
  "Rio Negro",                               "Río Negro",
  "Salta",                                   "Salta",
  "San Juan",                                "San Juan",
  "San Luis",                                "San Luis",
  "Santa Cruz",                              "Santa Cruz",
  "Santa Fe",                                "Santa Fe",
  "Santa Fé",                                "Santa Fe",
  "Santiago del Estero",                     "Santiago del Estero",
  "Tierra del Fuego",                        "Tierra del Fuego",
  "Tucumán",                                 "Tucumán",
  "Tucuman",                                 "Tucumán"
)

if (!file.exists(path_raw)) {
  dir.create(dirname(path_raw), showWarnings = FALSE, recursive = TRUE)
  options(timeout = 180)
  download.file(url_srt, destfile = path_raw, mode = "wb")
}

datos_raw <- read_excel(
  path_raw,
  sheet = hoja,
  col_names = FALSE,
  .name_repair = "unique_quiet"
)

fechas <- datos_raw[5, -1] |>
  unlist() |>
  as.numeric() |>
  excel_numeric_to_date()

if (all(is.na(fechas))) {
  stop("No se pudieron leer fechas en la fila 5 de ", hoja, ".")
}

nombres_raw <- datos_raw[6:29, 1] |>
  unlist() |>
  as.character() |>
  str_squish()

datos_jurisdicciones <- datos_raw[6:29, -1] |>
  mutate(across(everything(), as.numeric))

df <- datos_jurisdicciones |>
  mutate(jurisdiccion_raw = nombres_raw) |>
  pivot_longer(cols = -jurisdiccion_raw, names_to = "col_idx", values_to = "empresas") |>
  group_by(jurisdiccion_raw) |>
  mutate(fecha = fechas) |>
  ungroup() |>
  filter(
    !is.na(empresas),
    !jurisdiccion_raw %in% c("Sin datos", "Total", "")
  ) |>
  left_join(mapa_provincias, by = "jurisdiccion_raw")

sin_mapa <- df |>
  filter(is.na(jurisdiccion)) |>
  distinct(jurisdiccion_raw) |>
  pull()

if (length(sin_mapa) > 0) {
  stop(
    "Jurisdicciones sin homologar en ", hoja, ": ",
    paste(sin_mapa, collapse = ", ")
  )
}

df_out <- df |>
  select(jurisdiccion, fecha, empresas) |>
  filter(fecha <= FECHA_HASTA) |>
  mutate(empresas = as.integer(round(empresas))) |>
  arrange(jurisdiccion, fecha)

write_csv(df_out, path_out)

message(
  "07 prep: ", n_distinct(df_out$jurisdiccion), " jurisdicciones, ",
  format(min(df_out$fecha), "%Y-%m"), " a ", format(max(df_out$fecha), "%Y-%m"),
  " -> ", path_out
)
