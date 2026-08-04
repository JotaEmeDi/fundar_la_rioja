## 16 (prep). Recursos propios / recursos totales (tributarios).
##
## Recursos propios  = TOP (recursos tributarios de origen provincial)
## Recursos nacionales = RON (coparticipación y transferencias tributarias)
## Recursos totales  = TOP + RON
## Indicador         = TOP / (TOP + RON)
##
## Fuentes:
##   TOP: https://www.argentina.gob.ar/sites/default/files/serie_top_1984_2024_1.xlsx
##   RON: https://www.argentina.gob.ar/sites/default/files/serie_ron_2003_2025.xlsx
##
## Nota: RON usa el último valor numérico de cada fila provincial
## (equivale a TOTAL (1)+(2) cuando esa columna existe).
##
## Outputs:
##   data/inputs_md/16_recursos_propios_por_provincia.csv
##   data/inputs_md/16_recursos_propios_region.csv

library(tidyverse)
library(readxl)
library(janitor)

url_top <- "https://www.argentina.gob.ar/sites/default/files/serie_top_1984_2024_1.xlsx"
url_ron <- "https://www.argentina.gob.ar/sites/default/files/serie_ron_2003_2025.xlsx"
path_top <- "./data/raw_data/finanzas/serie_top_1984_2024_1.xlsx"
path_ron <- "./data/raw_data/finanzas/serie_ron_2003_2025.xlsx"
path_geo <- "https://raw.githubusercontent.com/argendatafundar/geonomencladores/main/geonomenclador.json"

dir.create(dirname(path_top), showWarnings = FALSE, recursive = TRUE)
dir.create("./data/inputs_md", showWarnings = FALSE, recursive = TRUE)

if (!file.exists(path_top)) download.file(url_top, destfile = path_top, mode = "wb")
if (!file.exists(path_ron)) download.file(url_ron, destfile = path_ron, mode = "wb")

noa <- c("Catamarca", "Jujuy", "Salta", "Santiago del Estero", "Tucumán")

fundar_geo <- jsonlite::fromJSON(path_geo) %>%
  filter(str_detect(geocodigo, "^AR-")) %>%
  select(geocodigo, name_short, name_long) %>%
  mutate(key = str_to_lower(name_short))

normalizar_prov <- function(x) {
  x <- str_to_title(str_squish(str_remove_all(as.character(x), "[[:punct:]]")))
  x <- str_remove(x, "\\s*\\*+$")
  case_when(
    x %in% c("C A B A", "Caba") ~ "CABA",
    x %in% c("Sgo Del Estero", "Santiago Del Estero") ~ "Santiago del Estero",
    x == "Tierra Del Fuego" ~ "Tierra del Fuego",
    TRUE ~ x
  )
}

es_fila_provincia <- function(x) {
  key <- str_to_upper(str_remove_all(x, "\\s"))
  !str_detect(
    key,
    paste0(
      "PROVINCIA|TOTAL|NOTA|FDOCOMPENSADOR|TESORONACIONAL|",
      "SEGURIDADSOCIAL|FONDOATN|^FD"
    )
  )
}

## -------- TOP (origen provincial) --------
data_top <- read_excel(path_top, sheet = "Total") %>%
  row_to_names(row_number = 5) %>%
  filter(!PROVINCIAS %in% c("Provincias", "Total", ".", NA_character_)) %>%
  mutate(
    provincia_clean = case_when(
      PROVINCIAS == "C.A.B.A." ~ "CABA",
      PROVINCIAS == "Sgo. Del Estero" ~ "Santiago del Estero",
      PROVINCIAS == "Tierra Del Fuego" ~ "Tierra del Fuego",
      TRUE ~ PROVINCIAS
    )
  ) %>%
  left_join(fundar_geo %>% select(-key), by = c("provincia_clean" = "name_short")) %>%
  select(-PROVINCIAS, -provincia_clean, -any_of("iso_2")) %>%
  relocate(geocodigo, name_long, 1) %>%
  pivot_longer(3:ncol(.), names_to = "anio", values_to = "rec_prov") %>%
  mutate(
    anio = as.integer(parse_number(anio)),
    rec_prov = as.numeric(rec_prov)
  ) %>%
  drop_na(geocodigo, rec_prov) %>%
  rename(provincia = name_long)

## -------- RON (origen nacional) --------
leer_ron_anio <- function(path, anio) {
  raw <- read_excel(
    path,
    sheet = as.character(anio),
    col_names = FALSE,
    .name_repair = "unique_quiet"
  )

  map_dfr(seq_len(nrow(raw)), function(i) {
    row <- unlist(raw[i, ], use.names = FALSE)
    prov <- as.character(row[[1]])
    if (is.na(prov) || !nzchar(str_squish(prov))) return(NULL)
    if (!es_fila_provincia(prov)) return(NULL)

    nums <- suppressWarnings(as.numeric(row))
    nums <- nums[!is.na(nums)]
    if (length(nums) == 0) return(NULL)

    tibble(
      anio = as.integer(anio),
      provincia_clean = normalizar_prov(prov),
      rec_nac = nums[length(nums)]
    )
  })
}

anios_ron <- excel_sheets(path_ron)
anios_ron <- anios_ron[str_detect(anios_ron, "^[0-9]{4}$")]

data_ron <- map_dfr(anios_ron, ~ leer_ron_anio(path_ron, .x)) %>%
  mutate(key = str_to_lower(provincia_clean)) %>%
  left_join(fundar_geo, by = "key") %>%
  filter(!is.na(geocodigo)) %>%
  select(anio, geocodigo, provincia = name_long, rec_nac) %>%
  distinct(anio, geocodigo, .keep_all = TRUE)

## -------- Join e indicador --------
recursos_prov <- data_top %>%
  inner_join(data_ron, by = c("anio", "geocodigo", "provincia")) %>%
  mutate(
    rec_total = rec_prov + rec_nac,
    pct_propios = rec_prov / rec_total,
    la_rioja_region = case_when(
      provincia == "La Rioja" ~ "3. La Rioja",
      provincia %in% noa ~ "2. NOA-Resto",
      TRUE ~ "1. Resto país"
    )
  ) %>%
  arrange(anio, provincia)

recursos_region <- recursos_prov %>%
  group_by(anio, la_rioja_region) %>%
  summarise(
    rec_prov = sum(rec_prov),
    rec_nac = sum(rec_nac),
    rec_total = sum(rec_total),
    .groups = "drop"
  ) %>%
  mutate(pct_propios = rec_prov / rec_total) %>%
  arrange(anio, la_rioja_region)

write_csv(recursos_prov, "./data/inputs_md/16_recursos_propios_por_provincia.csv")
write_csv(recursos_region, "./data/inputs_md/16_recursos_propios_region.csv")

message(
  "OK 16_prep_recursos_propios: ",
  min(recursos_region$anio), "-", max(recursos_region$anio),
  " | n_prov_anio=", nrow(recursos_prov)
)
