library(tidyverse)
library(readxl)

## 14 (prep). Origen provincial de las exportaciones de bienes (OPEX).
## Fuente: INDEC, Dirección Nacional de Estadísticas del Sector Externo y
## Cuentas Internacionales. Cuadro "Origen provincial de las exportaciones de
## bienes, por provincia y principales Grandes rubros, en millones de dólares.
## Años 1993-2025", publicado en
## https://www.indec.gob.ar/indec/web/Nivel4-Tema-3-2-79
## (archivo sh_opex_principales_grubros_1993_2025.xls).
##
## Se conservan solo los totales anuales por provincia (no los subrubros).
## Extranjero, Plataforma continental e Indeterminado se descartan. Total
## nacional tampoco se guarda: el agregado se puede reconstruir sumando
## provincias. Los valores "s" (secreto estadístico) y "-" quedan en NA.
## Años con asterisco (provisorios) se normalizan al año calendario.
##
## Nombres de jurisdicción homologados a los canónicos de 05/07 para reusar
## la clasificación La Rioja / NOA-Resto / Resto país en el script de viz.

url_opex <- paste0(
  "https://www.indec.gob.ar/ftp/cuadros/economia/",
  "sh_opex_principales_grubros_1993_2025.xls"
)
path_raw <- "./data/raw_data/exportaciones/sh_opex_principales_grubros_1993_2025.xls"

if (!file.exists(path_raw)) {
  dir.create(dirname(path_raw), showWarnings = FALSE, recursive = TRUE)
  download.file(url_opex, destfile = path_raw, mode = "wb")
}

## Incluye variantes tipográficas del mismo territorio a lo largo de las hojas.
mapa_provincias <- tribble(
  ~jurisdiccion_raw,                                              ~jurisdiccion,
  "Buenos Aires",                                                 "Buenos Aires",
  "Ciudad Autónoma de Buenos Aires",                              "C.A.B.A.",
  "Catamarca",                                                    "Catamarca",
  "Chaco",                                                        "Chaco",
  "Chubut",                                                       "Chubut",
  "Córdoba",                                                      "Córdoba",
  "Corrientes",                                                   "Corrientes",
  "Entre Ríos",                                                   "Entre Ríos",
  "Entre Rios",                                                   "Entre Ríos",
  "Formosa",                                                      "Formosa",
  "Jujuy",                                                        "Jujuy",
  "La Pampa",                                                     "La Pampa",
  "La Rioja",                                                     "La Rioja",
  "Mendoza",                                                      "Mendoza",
  "Misiones",                                                     "Misiones",
  "Neuquén",                                                      "Neuquén",
  "Río Negro",                                                    "Río Negro",
  "Rio Negro",                                                    "Río Negro",
  "Salta",                                                        "Salta",
  "San Juan",                                                     "San Juan",
  "San Luis",                                                     "San Luis",
  "Santa Cruz",                                                   "Santa Cruz",
  "Santa Fe",                                                     "Santa Fe",
  "Santa Fé",                                                     "Santa Fe",
  "Santiago del Estero",                                          "Santiago del Estero",
  "Tierra del Fuego",                                             "Tierra del Fuego",
  "Tierra del Fuego, Antártida e Islas del Atlántico Sur",        "Tierra del Fuego",
  "Tucumán",                                                      "Tucumán"
)

parse_valor_millones <- function(x) {
  x_chr <- str_squish(as.character(x))
  case_when(
    is.na(x_chr) | x_chr %in% c("", "-", "s", "S") ~ NA_real_,
    TRUE ~ suppressWarnings(as.numeric(x_chr))
  )
}

leer_hoja_opex <- function(path, sheet) {
  raw <- read_excel(
    path,
    sheet = sheet,
    col_names = FALSE,
    col_types = "text",
    .name_repair = "unique_quiet"
  )
  names(raw) <- paste0("c", seq_len(ncol(raw)))

  ## Fila 5 del cuadro: años (a veces con "*" de dato provisorio).
  anios <- raw %>%
    slice(5) %>%
    select(-c1) %>%
    pivot_longer(everything(), names_to = "col", values_to = "anio_raw") %>%
    mutate(
      anio = as.integer(str_remove(str_squish(anio_raw), "\\*$")),
      provisorio = str_detect(anio_raw %||% "", "\\*")
    ) %>%
    filter(!is.na(anio))

  raw %>%
    slice(-(1:7)) %>%
    rename(jurisdiccion_raw = c1) %>%
    mutate(jurisdiccion_raw = str_squish(jurisdiccion_raw)) %>%
    filter(!is.na(jurisdiccion_raw), jurisdiccion_raw != "") %>%
    pivot_longer(-jurisdiccion_raw, names_to = "col", values_to = "valor_raw") %>%
    inner_join(anios, by = "col") %>%
    inner_join(mapa_provincias, by = "jurisdiccion_raw") %>%
    mutate(
      exportaciones_millones_usd = parse_valor_millones(valor_raw),
      fecha = as.Date(sprintf("%d-01-01", anio))
    ) %>%
    select(jurisdiccion, fecha, anio, exportaciones_millones_usd, provisorio)
}

df <- map_dfr(excel_sheets(path_raw), \(s) leer_hoja_opex(path_raw, s)) %>%
  arrange(fecha, jurisdiccion)

## Una fila por provincia-año: si una variante tipográfica duplicara, se toma
## el primer valor no NA (no debería ocurrir dentro de la misma hoja).
df <- df %>%
  group_by(jurisdiccion, fecha, anio) %>%
  summarise(
    exportaciones_millones_usd = coalesce(
      exportaciones_millones_usd[!is.na(exportaciones_millones_usd)][1],
      NA_real_
    ),
    provisorio = any(provisorio),
    .groups = "drop"
  ) %>%
  mutate(exportaciones_millones_usd = round(exportaciones_millones_usd, 6)) %>%
  arrange(fecha, jurisdiccion)

n_prov <- n_distinct(df$jurisdiccion)
if (n_prov != 24L) {
  stop(
    "Se esperaban 24 jurisdicciones (23 provincias + CABA); hay ",
    n_prov, ": ",
    paste(sort(unique(df$jurisdiccion)), collapse = ", ")
  )
}

dir.create("./data/inputs_md", showWarnings = FALSE, recursive = TRUE)
write_csv(df, "./data/inputs_md/14_exportaciones_por_provincia.csv")
