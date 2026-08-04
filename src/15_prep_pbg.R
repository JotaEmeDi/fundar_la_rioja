## 15 (prep). PBG provincial (CEPAL) y estructura sectorial a letra CIIU Rev. 3.
##
## Fuente:
##   Desagregación provincial del VAB a precios básicos, base 2004
##   (CEPAL / Ministerio de Economía).
##   https://repositorio.cepal.org/server/api/core/bitstreams/539fcce5-8977-4061-a222-fbfd7358a35f/content
##
## Agregación La Rioja / NOA-Resto / Resto país: SUMA del VAB (millones de $ 2004).
## Share sectorial = valor_letra / VAB total del grupo.
##
## Outputs:
##   data/inputs_md/15_pbg_por_provincia.csv
##   data/inputs_md/15_pbg_region.csv
##   data/inputs_md/15_pbg_estructura_region.csv
##   data/inputs_md/15_pbg_pct_industrial_region.csv

library(tidyverse)
library(readxl)
library(janitor)

url_pbg <- paste0(
  "https://repositorio.cepal.org/server/api/core/bitstreams/",
  "539fcce5-8977-4061-a222-fbfd7358a35f/content"
)
path_raw <- "./data/raw_data/pbg/Jurisdiccion_52sectores.xlsx"
path_geo <- "https://raw.githubusercontent.com/argendatafundar/geonomencladores/main/geonomenclador.json"

dir.create(dirname(path_raw), showWarnings = FALSE, recursive = TRUE)
dir.create("./data/inputs_md", showWarnings = FALSE, recursive = TRUE)

if (!file.exists(path_raw)) {
  download.file(url_pbg, destfile = path_raw, mode = "wb")
}

noa <- c("Catamarca", "Jujuy", "Salta", "Santiago del Estero", "Tucumán")

## Mapeo de las 52 ramas CEPAL a letra CIIU Rev. 3 (misma lógica Argendata ESTPRO).
letra_ciiu <- function(sector) {
  s <- str_squish(sector)
  case_when(
    str_detect(s, regex("^Agricultura|^Silvicultura", ignore_case = TRUE)) ~ "A",
    str_detect(s, regex("^Pesca$", ignore_case = TRUE)) ~ "B",
    str_detect(s, regex("^Extracci[oó]n", ignore_case = TRUE)) ~ "C",
    ## E antes que D: "Fabricación de gas..." es electricidad/gas/agua.
    str_detect(
      s,
      regex(
        "^(Generaci[oó]n|Fabricaci[oó]n de gas|Captaci[oó]n)",
        ignore_case = TRUE
      )
    ) ~ "E",
    str_detect(
      s,
      regex(
        paste0(
          "^(Elaboraci[oó]n|Fabricaci[oó]n|Curtido|Producci[oó]n de madera|",
          "Edici[oó]n|Reciclamiento|Reparaci[oó]n)"
        ),
        ignore_case = TRUE
      )
    ) ~ "D",
    str_detect(s, regex("^Construcci[oó]n", ignore_case = TRUE)) ~ "F",
    str_detect(s, regex("^Comercio", ignore_case = TRUE)) ~ "G",
    str_detect(s, regex("^Hoteles|^Restaurantes", ignore_case = TRUE)) ~ "H",
    s %in% c("Transporte", "Comunicaciones") ~ "I",
    str_detect(
      s,
      regex("financ|Servicios de seguros|Intermediaci[oó]n", ignore_case = TRUE)
    ) ~ "J",
    s %in% c("Propiedad de la vivienda", "Resto") ~ "K",
    str_detect(s, regex("^Administraci[oó]n", ignore_case = TRUE)) ~ "L",
    str_detect(s, regex("^Ense[nñ]anza", ignore_case = TRUE)) ~ "M",
    str_detect(s, regex("^Salud", ignore_case = TRUE)) ~ "N",
    str_detect(
      s,
      regex(
        "^(Eliminaci[oó]n|Asociaciones|Servicios culturales)",
        ignore_case = TRUE
      )
    ) ~ "O",
    str_detect(s, regex("^Servicio dom[eé]stico", ignore_case = TRUE)) ~ "P",
    TRUE ~ NA_character_
  )
}

letra_labels <- tribble(
  ~letra, ~letra_desc,                          ~tipo_sector,
  "A",    "Agro",                               "Bienes",
  "B",    "Pesca",                              "Bienes",
  "C",    "Petróleo y minería",                 "Bienes",
  "D",    "Industria manufacturera",            "Bienes",
  "E",    "Electricidad, gas y agua",           "Bienes",
  "F",    "Construcción",                       "Bienes",
  "G",    "Comercio",                           "Servicios",
  "H",    "Hotelería y restaurantes",           "Servicios",
  "I",    "Transporte y comunicaciones",        "Servicios",
  "J",    "Finanzas",                           "Servicios",
  "K",    "Serv. inmobiliarios y profesionales","Servicios",
  "L",    "Adm. pública y defensa",             "Servicios",
  "M",    "Enseñanza",                          "Servicios",
  "N",    "Salud",                              "Servicios",
  "O",    "Serv. comunitarios, sociales y personales", "Servicios",
  "P",    "Servicio doméstico",                 "Servicios"
)

fundar_geo <- jsonlite::fromJSON(path_geo) %>%
  filter(str_detect(geocodigo, "^AR-")) %>%
  select(geocodigo, name_short, name_long)

sheets <- excel_sheets(path_raw)
sheets <- sheets[!sheets %in% c("VABpb", "No_distribuido")]

data_vab <- map_dfr(sheets, function(x) {
  read_excel(path_raw, sheet = x, skip = 3) %>%
    mutate(prov = x)
})

data_vab <- data_vab %>%
  relocate(prov, 1) %>%
  pivot_longer(3:ncol(.), names_to = "name", values_to = "value") %>%
  clean_names() %>%
  mutate(
    prov = str_replace_all(prov, "_", " "),
    sector = str_remove(sector_de_actividad_economica, "\\*"),
    anio = parse_number(name),
    value = as.numeric(value)
  ) %>%
  drop_na(value) %>%
  filter(sector != "VAB a precios básicos") %>%
  mutate(
    prov = case_when(
      prov == "Ciudad de Buenos Aires" ~ "CABA",
      prov == "Cordoba" ~ "Córdoba",
      prov == "Entre Rios" ~ "Entre Ríos",
      prov == "Neuquen" ~ "Neuquén",
      prov == "Tucuman" ~ "Tucumán",
      prov == "Rio Negro" ~ "Río Negro",
      TRUE ~ prov
    ),
    sector = str_squish(sector),
    letra = letra_ciiu(sector)
  )

if (any(is.na(data_vab$letra))) {
  stop(
    "Hay ramas sin letra CIIU: ",
    paste(unique(data_vab$sector[is.na(data_vab$letra)]), collapse = " | ")
  )
}

data_vab <- data_vab %>%
  left_join(fundar_geo, by = c("prov" = "name_short")) %>%
  left_join(letra_labels, by = "letra") %>%
  select(anio, geocodigo, provincia = name_long, sector, letra, letra_desc,
         tipo_sector, vab_millones_2004 = value)

## Totales por provincia (suma de ramas)
pbg_prov <- data_vab %>%
  group_by(anio, geocodigo, provincia) %>%
  summarise(vab_millones_2004 = sum(vab_millones_2004), .groups = "drop") %>%
  mutate(
    la_rioja_region = case_when(
      provincia == "La Rioja" ~ "3. La Rioja",
      provincia %in% noa ~ "2. NOA-Resto",
      TRUE ~ "1. Resto país"
    )
  ) %>%
  arrange(anio, provincia)

## Totales regionales
pbg_region <- pbg_prov %>%
  group_by(anio, la_rioja_region) %>%
  summarise(vab_millones_2004 = sum(vab_millones_2004), .groups = "drop") %>%
  group_by(la_rioja_region) %>%
  mutate(indice_2004 = 100 * vab_millones_2004 / vab_millones_2004[anio == 2004]) %>%
  ungroup() %>%
  arrange(anio, la_rioja_region)

## Estructura por letra y región
estructura <- data_vab %>%
  mutate(
    la_rioja_region = case_when(
      provincia == "La Rioja" ~ "3. La Rioja",
      provincia %in% noa ~ "2. NOA-Resto",
      TRUE ~ "1. Resto país"
    )
  ) %>%
  group_by(anio, la_rioja_region, letra, letra_desc, tipo_sector) %>%
  summarise(vab_millones_2004 = sum(vab_millones_2004), .groups = "drop") %>%
  left_join(
    pbg_region %>% select(anio, la_rioja_region, vab_total = vab_millones_2004),
    by = c("anio", "la_rioja_region")
  ) %>%
  mutate(share = vab_millones_2004 / vab_total) %>%
  arrange(anio, la_rioja_region, letra)

## % industrial (letra D)
pct_industrial <- estructura %>%
  filter(letra == "D") %>%
  select(anio, la_rioja_region, pct_industrial = share) %>%
  arrange(anio, la_rioja_region)

write_csv(pbg_prov, "./data/inputs_md/15_pbg_por_provincia.csv")
write_csv(pbg_region, "./data/inputs_md/15_pbg_region.csv")
write_csv(estructura, "./data/inputs_md/15_pbg_estructura_region.csv")
write_csv(pct_industrial, "./data/inputs_md/15_pbg_pct_industrial_region.csv")

message(
  "OK 15_prep_pbg: ",
  min(pbg_region$anio), "-", max(pbg_region$anio),
  " | provincias=", n_distinct(pbg_prov$provincia)
)
