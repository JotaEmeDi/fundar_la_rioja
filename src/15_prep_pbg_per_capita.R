## 15 (prep). PBG per cápita provincial.
##
## PBG per cápita = VAB (millones $ 2004) * 1e6 / población
##   → pesos constantes de 2004 por habitante.
##
## Fuentes:
##   - PBG: data/inputs_md/15_pbg_por_provincia.csv (correrá 15_prep_pbg.R si falta)
##   - Población: DNAP / Min. Economía (proyecciones provinciales)
##     https://www.economia.gob.ar/dnap/economica/1.Poblacionysuperficie/poblacion_superficie.xlsx
##
## Agregación regional: suma(VAB) / suma(población).
## Serie típica: desde ~2010 (años anuales de la proyección DNAP; los censos
## previos 1970/80/91/2001 no alcanzan para un índice continuo desde 2004).
##
## Outputs:
##   data/inputs_md/15_pbg_per_capita_por_provincia.csv
##   data/inputs_md/15_pbg_per_capita_region.csv

library(tidyverse)
library(readxl)
library(janitor)

path_pbg <- "./data/inputs_md/15_pbg_por_provincia.csv"
url_pob <- paste0(
  "https://www.economia.gob.ar/dnap/economica/",
  "1.Poblacionysuperficie/poblacion_superficie.xlsx"
)
path_pob <- "./data/raw_data/poblacion/poblacion_superficie.xlsx"
path_geo <- "https://raw.githubusercontent.com/argendatafundar/geonomencladores/main/geonomenclador.json"
path_pob_fallback <- paste0(
  "./finanzas_publicas_provincias/tributario/clean/",
  "poblacion_provincial_indec_proyecciones_clean.csv"
)

dir.create(dirname(path_pob), showWarnings = FALSE, recursive = TRUE)
dir.create("./data/inputs_md", showWarnings = FALSE, recursive = TRUE)

if (!file.exists(path_pbg)) {
  message("No está 15_pbg_por_provincia.csv → corro 15_prep_pbg.R")
  source("./src/15_prep_pbg.R")
}

pbg <- read_csv(path_pbg, show_col_types = FALSE)

fundar_geo <- jsonlite::fromJSON(path_geo) %>%
  filter(str_detect(geocodigo, "^AR-")) %>%
  select(geocodigo, name_short, name_long)

## -------- Población --------
leer_poblacion_dnap <- function(path) {
  data_pob <- read_excel(path) %>%
    row_to_names(row_number = 4) %>%
    clean_names()

  ## Las 24 jurisdicciones están en las primeras filas útiles.
  data_pob <- data_pob[1:24, ]

  data_pob %>%
    mutate(across(2:ncol(.), as.numeric)) %>%
    pivot_longer(2:ncol(.), names_to = "name", values_to = "poblacion") %>%
    mutate(
      anio = parse_number(name),
      provincia = if_else(
        jurisdicciones == "C.A.B.A",
        "CABA",
        jurisdicciones
      )
    ) %>%
    left_join(fundar_geo, by = c("provincia" = "name_short")) %>%
    select(anio, geocodigo, provincia = name_long, poblacion) %>%
    drop_na(geocodigo, poblacion)
}

if (!file.exists(path_pob)) {
  ok <- tryCatch(
    {
      download.file(url_pob, destfile = path_pob, mode = "wb", quiet = TRUE)
      TRUE
    },
    error = function(e) FALSE,
    warning = function(w) FALSE
  )
  if (!isTRUE(ok) || !file.exists(path_pob) || file.info(path_pob)$size < 1000) {
    message("Download DNAP falló o archivo vacío; uso CSV limpio del repo finanzas.")
    if (file.exists(path_pob)) file.remove(path_pob)
  }
}

if (file.exists(path_pob)) {
  pob <- leer_poblacion_dnap(path_pob)
} else if (file.exists(path_pob_fallback)) {
  pob <- read_csv(path_pob_fallback, show_col_types = FALSE) %>%
    select(anio, geocodigo, provincia = name_long, poblacion = value)
} else {
  stop(
    "No hay población DNAP. Colocá el xlsx en ", path_pob,
    " o el CSV limpio en ", path_pob_fallback
  )
}

## -------- Join e indicador --------
pbg_pc_prov <- pbg %>%
  inner_join(pob, by = c("anio", "geocodigo", "provincia")) %>%
  mutate(
    pbg_per_capita = (vab_millones_2004 * 1e6) / poblacion
  ) %>%
  arrange(anio, provincia)

if (nrow(pbg_pc_prov) == 0) {
  stop("Join PBG–población vacío: revisar geocodigos / años.")
}

pbg_pc_region <- pbg_pc_prov %>%
  group_by(anio, la_rioja_region) %>%
  summarise(
    vab_millones_2004 = sum(vab_millones_2004),
    poblacion = sum(poblacion),
    .groups = "drop"
  ) %>%
  mutate(pbg_per_capita = (vab_millones_2004 * 1e6) / poblacion)

## La serie de población DNAP anual arranca ~2010 (censos previos son puntuales).
anio_base <- min(pbg_pc_region$anio)

pbg_pc_region <- pbg_pc_region %>%
  group_by(la_rioja_region) %>%
  mutate(
    indice_base = 100 * pbg_per_capita / pbg_per_capita[anio == anio_base]
  ) %>%
  ungroup() %>%
  arrange(anio, la_rioja_region)

## Relativo a la media nacional (promedio simple de las 24) en cada año.
media_nac <- pbg_pc_prov %>%
  group_by(anio) %>%
  summarise(pbg_pc_media_nac = mean(pbg_per_capita), .groups = "drop")

pbg_pc_prov <- pbg_pc_prov %>%
  left_join(media_nac, by = "anio") %>%
  mutate(pbg_pc_relativo_nac = pbg_per_capita / pbg_pc_media_nac)

write_csv(pbg_pc_prov, "./data/inputs_md/15_pbg_per_capita_por_provincia.csv")
write_csv(pbg_pc_region, "./data/inputs_md/15_pbg_per_capita_region.csv")

message(
  "OK 15_prep_pbg_per_capita: ",
  min(pbg_pc_region$anio), "-", max(pbg_pc_region$anio),
  " | base_indice=", anio_base,
  " | n_prov_anio=", nrow(pbg_pc_prov)
)
