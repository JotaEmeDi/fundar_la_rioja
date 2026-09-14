## 17 (prep). Resultado fiscal APNF / PBG nominal — La Rioja.
##
## Indicador del Monitor: resultado financiero y primario como % del PBG
## nominal provincial (valores corrientes a precios básicos).
##
## Numerador: ejecuciones APNF (Min. Economía) — La Rioja.
## Denominador: PBG nominal La Rioja (Dirección General de Estadísticas y
## Censos de la provincia).
##   Excel: data/raw_data/pbg/PBG_cuadros_generales_sectoreales_final_sept_2026.xlsx
##   Hoja Corrientes, fila Total, unidad miles de $ → se expresa en millones.
##
## Alcance: solo La Rioja. No hay comparación NOA-Resto / resto país porque
## no se dispone de PBG nominal homogéneo para las demás provincias.
## La serie se limita a la intersección de años APNF ∩ PBG nominal.
##
## El PBG CEPAL (constantes 2004) no se usa como denominador.
##
## Outputs:
##   data/inputs_md/17_resultado_fiscal_la_rioja.csv
##   data/inputs_md/17_resultado_fiscal_por_provincia.csv  (APNF completo, referencia)
##   data/inputs_md/15_pbg_nominal_la_rioja.csv

library(tidyverse)
library(readxl)
library(stringi)

url_apnf <- "https://www.argentina.gob.ar/sites/default/files/serie_aif-apnf-2025.xlsx"
path_apnf <- "./data/raw_data/finanzas/serie_aif-apnf-2025.xlsx"
path_pbg_xlsx <- paste0(
  "./data/raw_data/pbg/",
  "PBG_cuadros_generales_sectoreales_final_sept_2026.xlsx"
)
path_geo <- "https://raw.githubusercontent.com/argendatafundar/geonomencladores/main/geonomenclador.json"

dir.create(dirname(path_apnf), showWarnings = FALSE, recursive = TRUE)
dir.create("./data/inputs_md", showWarnings = FALSE, recursive = TRUE)

if (!file.exists(path_apnf)) {
  download.file(url_apnf, destfile = path_apnf, mode = "wb")
}
if (!file.exists(path_pbg_xlsx)) {
  stop(
    "Falta PBG nominal provincial: ", path_pbg_xlsx,
    ". Colocar el Excel aportado por la provincia en data/raw_data/pbg/."
  )
}

noa <- c("Catamarca", "Jujuy", "Salta", "Santiago del Estero", "Tucumán")

fundar_geo <- jsonlite::fromJSON(path_geo) %>%
  filter(str_detect(geocodigo, "^AR-")) %>%
  select(geocodigo, name_short, name_long)

norm_txt <- function(x) {
  x %>%
    as.character() %>%
    str_squish() %>%
    stri_trans_general("Latin-ASCII") %>%
    str_to_lower()
}

map_sheet_to_prov <- function(sheet) {
  case_when(
    sheet == "Ciudad" ~ "CABA",
    str_detect(norm_txt(sheet), "santiago") ~ "Santiago del Estero",
    TRUE ~ sheet
  )
}

conceptos_clave <- tribble(
  ~clave,                 ~needle,
  "ingresos_totales",     "vi. ingresos totales",
  "gastos_totales",       "vii. gastos totales",
  "resultado_financiero", "viii. resultado financiero",
  "resultado_primario",   "ix. resultado primario",
  "gastos_primarios",     "x. gastos primarios"
)

leer_hoja_apnf <- function(path, sheet) {
  raw <- read_excel(path, sheet = sheet, col_names = FALSE, .name_repair = "unique_quiet")
  header_row <- which(norm_txt(raw[[1]]) == "concepto")[1]
  if (is.na(header_row)) {
    stop("No se encontró fila CONCEPTO en hoja: ", sheet)
  }
  years <- suppressWarnings(as.integer(unlist(raw[header_row, -1])))
  body <- raw[-(1:header_row), ]
  names(body) <- c("concepto", as.character(years))
  body %>%
    mutate(concepto_norm = norm_txt(concepto)) %>%
    pivot_longer(
      cols = -c(concepto, concepto_norm),
      names_to = "anio",
      values_to = "valor"
    ) %>%
    mutate(
      anio = as.integer(anio),
      valor = suppressWarnings(as.numeric(valor))
    ) %>%
    filter(!is.na(valor))
}

extraer_conceptos <- function(long_df) {
  map_dfr(seq_len(nrow(conceptos_clave)), function(i) {
    needle <- conceptos_clave$needle[[i]]
    clave <- conceptos_clave$clave[[i]]
    long_df %>%
      filter(str_starts(concepto_norm, needle) | str_detect(concepto_norm, fixed(needle))) %>%
      mutate(n_chr = nchar(concepto_norm)) %>%
      group_by(anio) %>%
      slice_min(n_chr, n = 1, with_ties = FALSE) %>%
      ungroup() %>%
      transmute(anio, clave = clave, valor)
  }) %>%
    distinct(anio, clave, .keep_all = TRUE) %>%
    pivot_wider(names_from = clave, values_from = valor)
}

## -------- APNF (todas las provincias; CSV de referencia) --------
sheets <- setdiff(excel_sheets(path_apnf), "Consolidado")

fiscal_prov <- map_dfr(sheets, function(sheet) {
  long <- leer_hoja_apnf(path_apnf, sheet)
  wide <- extraer_conceptos(long)
  wide %>%
    mutate(
      sheet = sheet,
      provincia_sheet = map_sheet_to_prov(sheet)
    )
}) %>%
  mutate(key = norm_txt(provincia_sheet)) %>%
  left_join(
    fundar_geo %>% mutate(key = norm_txt(name_short)),
    by = "key"
  )

if (any(is.na(fiscal_prov$geocodigo))) {
  stop(
    "Sin geocódigo para: ",
    paste(unique(fiscal_prov$provincia_sheet[is.na(fiscal_prov$geocodigo)]), collapse = ", ")
  )
}

req <- c(
  "ingresos_totales", "gastos_totales",
  "resultado_financiero", "resultado_primario"
)
if (any(is.na(fiscal_prov[req]))) {
  stop("Faltan conceptos APNF en alguna provincia/año.")
}

fiscal_prov <- fiscal_prov %>%
  transmute(
    anio,
    geocodigo,
    provincia = name_long,
    ingresos_totales,
    gastos_totales,
    resultado_financiero,
    resultado_primario,
    resultado_sobre_ingresos = resultado_financiero / ingresos_totales,
    primario_sobre_ingresos = resultado_primario / ingresos_totales,
    la_rioja_region = case_when(
      name_long == "La Rioja" ~ "3. La Rioja",
      name_long %in% noa ~ "2. NOA-Resto",
      TRUE ~ "1. Resto país"
    )
  ) %>%
  arrange(anio, provincia)

## -------- PBG nominal La Rioja (hoja Corrientes, fila Total) --------
leer_pbg_nominal_lr <- function(path) {
  raw <- read_excel(path, sheet = "Corrientes", col_names = FALSE, .name_repair = "unique_quiet")
  ## Fila de años y fila Total (estructura del Excel provincial).
  fila_anios <- which(norm_txt(raw[[1]]) == "sectores")[1]
  fila_total <- which(norm_txt(raw[[1]]) == "total")[1]
  if (is.na(fila_anios) || is.na(fila_total)) {
    stop("No se encontraron filas Sectores/Total en hoja Corrientes.")
  }
  tibble(
    anio = as.integer(unlist(raw[fila_anios, -1])),
    pbg_miles = as.numeric(unlist(raw[fila_total, -1]))
  ) %>%
    filter(!is.na(anio), !is.na(pbg_miles)) %>%
    mutate(
      pbg_millones = pbg_miles / 1000,
      provincia = "La Rioja"
    )
}

pbg_lr <- leer_pbg_nominal_lr(path_pbg_xlsx)
write_csv(pbg_lr, "./data/inputs_md/15_pbg_nominal_la_rioja.csv")

## -------- Indicador Monitor: solo La Rioja, % del PBG --------
## APNF en millones de $; PBG (miles) / 1000 = millones.
fiscal_lr <- fiscal_prov %>%
  filter(provincia == "La Rioja") %>%
  inner_join(pbg_lr %>% select(anio, pbg_miles, pbg_millones), by = "anio") %>%
  mutate(
    resultado_sobre_pbg = resultado_financiero / pbg_millones,
    primario_sobre_pbg = resultado_primario / pbg_millones
  ) %>%
  arrange(anio)

if (nrow(fiscal_lr) == 0) {
  stop("Join APNF–PBG nominal vacío para La Rioja. Revisar años/unidades.")
}

write_csv(fiscal_prov, "./data/inputs_md/17_resultado_fiscal_por_provincia.csv")
write_csv(fiscal_lr, "./data/inputs_md/17_resultado_fiscal_la_rioja.csv")

message(
  "OK 17_prep_resultado_fiscal: La Rioja ",
  min(fiscal_lr$anio), "-", max(fiscal_lr$anio),
  " | n=", nrow(fiscal_lr),
  " | PBG nominal hasta ", max(pbg_lr$anio),
  " | APNF provincias n=", nrow(fiscal_prov)
)
