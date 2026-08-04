## 17 (prep). Resultado fiscal APNF (Administración Pública No Financiera).
##
## Definición:
##   Resultado financiero = Ingresos totales (VI) - Gastos totales (VII)
##   (fila VIII del Excel). Indicador de lectura:
##   resultado_sobre_ingresos = resultado_financiero / ingresos_totales
##
## No se deflacta: todo es nominal; el ratio evita que la inflación distorsione
## la comparación temporal.
##
## Fuente:
##   Min. Economía – Ejecuciones presupuestarias provinciales APNF
##   https://www.argentina.gob.ar/sites/default/files/serie_aif-apnf-2025.xlsx
##   Página:
##   https://www.argentina.gob.ar/economia/sechacienda/coordinacion-fiscal-provincial/ejecucion-presupuestaria-provincial/ejecuciones
##
## Agregación regional: suma de ingresos y de gastos; luego resultado y ratio.
##
## Outputs:
##   data/inputs_md/17_resultado_fiscal_por_provincia.csv
##   data/inputs_md/17_resultado_fiscal_region.csv

library(tidyverse)
library(readxl)
library(stringi)

url_apnf <- "https://www.argentina.gob.ar/sites/default/files/serie_aif-apnf-2025.xlsx"
path_apnf <- "./data/raw_data/finanzas/serie_aif-apnf-2025.xlsx"
path_geo <- "https://raw.githubusercontent.com/argendatafundar/geonomencladores/main/geonomenclador.json"

dir.create(dirname(path_apnf), showWarnings = FALSE, recursive = TRUE)
dir.create("./data/inputs_md", showWarnings = FALSE, recursive = TRUE)

if (!file.exists(path_apnf)) {
  download.file(url_apnf, destfile = path_apnf, mode = "wb")
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

## Conceptos a extraer (match por texto normalizado).
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

  years <- suppressWarnings(as.integer(parse_number(as.character(unlist(raw[header_row, -1])))))
  keep <- which(!is.na(years))
  years <- years[keep]

  body <- raw[(header_row + 1):nrow(raw), , drop = FALSE]
  concepto <- as.character(body[[1]])
  vals <- body[, keep + 1, drop = FALSE]
  names(vals) <- as.character(years)

  tibble(concepto = concepto) %>%
    bind_cols(vals) %>%
    filter(!is.na(concepto), nzchar(str_squish(concepto))) %>%
    mutate(concepto_norm = norm_txt(concepto)) %>%
    pivot_longer(
      cols = all_of(as.character(years)),
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
    hit <- long_df %>%
      filter(str_starts(concepto_norm, needle) | str_detect(concepto_norm, fixed(needle))) %>%
      ## Preferir la fila más corta / más específica (evita subtítulos raros).
      mutate(n_chr = nchar(concepto_norm)) %>%
      group_by(anio) %>%
      slice_min(n_chr, n = 1, with_ties = FALSE) %>%
      ungroup() %>%
      transmute(anio, clave = clave, valor)
    hit
  }) %>%
    distinct(anio, clave, .keep_all = TRUE) %>%
    pivot_wider(names_from = clave, values_from = valor)
}

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

## Consistencia: VIII ≈ VI - VII
fiscal_prov <- fiscal_prov %>%
  mutate(
    resultado_calc = ingresos_totales - gastos_totales,
    diff_abs = abs(resultado_financiero - resultado_calc)
  )

if (max(fiscal_prov$diff_abs, na.rm = TRUE) > 1) {
  warning(
    "Hay diferencias > 1 millón entre VIII y VI-VII; max=",
    max(fiscal_prov$diff_abs, na.rm = TRUE)
  )
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

fiscal_region <- fiscal_prov %>%
  group_by(anio, la_rioja_region) %>%
  summarise(
    ingresos_totales = sum(ingresos_totales),
    gastos_totales = sum(gastos_totales),
    resultado_financiero = sum(resultado_financiero),
    resultado_primario = sum(resultado_primario),
    .groups = "drop"
  ) %>%
  mutate(
    resultado_sobre_ingresos = resultado_financiero / ingresos_totales,
    primario_sobre_ingresos = resultado_primario / ingresos_totales
  ) %>%
  arrange(anio, la_rioja_region)

write_csv(fiscal_prov, "./data/inputs_md/17_resultado_fiscal_por_provincia.csv")
write_csv(fiscal_region, "./data/inputs_md/17_resultado_fiscal_region.csv")

message(
  "OK 17_prep_resultado_fiscal: ",
  min(fiscal_region$anio), "-", max(fiscal_region$anio),
  " | n_prov_anio=", nrow(fiscal_prov)
)
