library(tidyverse)
library(readxl)

## 14b (prep). Exportaciones por subrubro (OPEX INDEC).
## Misma fuente que 14_prep_exportaciones.R, pero conserva los principales
## subrubros publicados bajo cada provincia (no solo el total).
##
## La fuente NO publica todos los subrubros todos los años: solo los
## principales de cada jurisdicción más un residual ("Resto" /
## "Resto de productos"). Un producto ausente en un año no implica 0.
##
## Agregación La Rioja / NOA-Resto / Resto país: SUMA de millones USD
## (no ponderación). Share % = 100 * subrubro / total del grupo.
## Total del grupo = suma de totales provinciales del grupo ese año.

url_opex <- paste0(
  "https://www.indec.gob.ar/ftp/cuadros/economia/",
  "sh_opex_principales_grubros_1993_2025.xls"
)
path_raw <- "./data/raw_data/exportaciones/sh_opex_principales_grubros_1993_2025.xls"

if (!file.exists(path_raw)) {
  dir.create(dirname(path_raw), showWarnings = FALSE, recursive = TRUE)
  download.file(url_opex, destfile = path_raw, mode = "wb")
}

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

noa <- c("Catamarca", "Jujuy", "Salta", "Santiago del Estero", "Tucumán", "La Rioja")

parse_valor_millones <- function(x) {
  x_chr <- str_squish(as.character(x))
  case_when(
    is.na(x_chr) | x_chr %in% c("", "-", "s", "S") ~ NA_real_,
    TRUE ~ suppressWarnings(as.numeric(x_chr))
  )
}

## Homologa residuales y tipografías menores entre hojas.
normalizar_subrubro <- function(x) {
  x <- str_squish(x)
  case_when(
    x %in% c("Resto", "Resto de productos") ~ "Resto de productos",
    str_detect(x, regex("^Papel", ignore_case = TRUE)) ~
      "Papel, cartón, impresos y publicaciones",
    str_detect(x, regex("^Preparados de (hortalizas|legumbres)", ignore_case = TRUE)) ~
      "Preparados de hortalizas, legumbres y frutas",
    TRUE ~ x
  )
}

leer_hoja_subrubros <- function(path, sheet) {
  raw <- read_excel(
    path,
    sheet = sheet,
    col_names = FALSE,
    col_types = "text",
    .name_repair = "unique_quiet"
  )
  names(raw) <- paste0("c", seq_len(ncol(raw)))

  anios <- raw %>%
    slice(5) %>%
    select(-c1) %>%
    pivot_longer(everything(), names_to = "col", values_to = "anio_raw") %>%
    mutate(
      anio = as.integer(str_remove(str_squish(anio_raw), "\\*$")),
      provisorio = str_detect(anio_raw %||% "", "\\*")
    ) %>%
    filter(!is.na(anio))

  cuerpo <- raw %>%
    slice(-(1:7)) %>%
    rename(label = c1) %>%
    mutate(label = str_squish(label)) %>%
    filter(!is.na(label), label != "") %>%
    ## Descarta notas al pie / fuente.
    filter(
      !str_detect(label, regex("^(Nota:|Fuente:|Fecha de|s\\s+dato)", ignore_case = TRUE))
    )

  ## Asigna provincia: filas cuyo label matchea el mapa son totales;
  ## las siguientes son subrubros hasta la próxima provincia.
  labels <- cuerpo$label
  es_prov <- labels %in% mapa_provincias$jurisdiccion_raw
  provincia_raw <- rep(NA_character_, length(labels))
  actual <- NA_character_
  for (i in seq_along(labels)) {
    if (es_prov[[i]]) {
      actual <- labels[[i]]
      provincia_raw[[i]] <- actual
    } else if (!is.na(actual) &&
               !labels[[i]] %in% c("Total", "Extranjero", "Exterior",
                                   "Plataforma continental", "Indeterminado")) {
      provincia_raw[[i]] <- actual
    }
  }

  cuerpo %>%
    mutate(
      jurisdiccion_raw = provincia_raw,
      tipo_fila = case_when(
        label %in% mapa_provincias$jurisdiccion_raw ~ "total",
        !is.na(jurisdiccion_raw) ~ "subrubro",
        TRUE ~ "otro"
      )
    ) %>%
    filter(tipo_fila %in% c("total", "subrubro")) %>%
    pivot_longer(starts_with("c"), names_to = "col", values_to = "valor_raw") %>%
    inner_join(anios, by = "col") %>%
    left_join(mapa_provincias, by = "jurisdiccion_raw") %>%
    filter(!is.na(jurisdiccion)) %>%
    mutate(
      subrubro = if_else(
        tipo_fila == "total",
        "Total",
        normalizar_subrubro(label)
      ),
      exportaciones_millones_usd = parse_valor_millones(valor_raw),
      fecha = as.Date(sprintf("%d-01-01", anio))
    ) %>%
    select(
      jurisdiccion, subrubro, tipo_fila, fecha, anio,
      exportaciones_millones_usd, provisorio
    )
}

df_raw <- map_dfr(excel_sheets(path_raw), \(s) leer_hoja_subrubros(path_raw, s))

## Una fila por provincia-subrubro-año.
df_prov <- df_raw %>%
  group_by(jurisdiccion, subrubro, tipo_fila, fecha, anio) %>%
  summarise(
    exportaciones_millones_usd = coalesce(
      exportaciones_millones_usd[!is.na(exportaciones_millones_usd)][1],
      NA_real_
    ),
    provisorio = any(provisorio),
    .groups = "drop"
  ) %>%
  mutate(exportaciones_millones_usd = round(exportaciones_millones_usd, 6)) %>%
  arrange(fecha, jurisdiccion, tipo_fila, subrubro)

df_prov <- df_prov %>%
  mutate(
    la_rioja_region = case_when(
      jurisdiccion == "La Rioja" ~ "3. La Rioja",
      jurisdiccion %in% noa ~ "2. NOA-Resto",
      TRUE ~ "1. Resto país"
    )
  )

## Totales por grupo-año (suma de totales provinciales).
totales_grupo <- df_prov %>%
  filter(tipo_fila == "total") %>%
  group_by(fecha, anio, la_rioja_region) %>%
  summarise(
    total_grupo_millones_usd = sum(exportaciones_millones_usd, na.rm = TRUE),
    provisorio = any(provisorio),
    .groups = "drop"
  )

## Subrubros por grupo-año (suma de USD; excluye la fila Total).
## Valores confidenciales ("s") quedan fuera de la suma (na.rm = TRUE).
df_grupo <- df_prov %>%
  filter(tipo_fila == "subrubro") %>%
  group_by(fecha, anio, la_rioja_region, subrubro) %>%
  summarise(
    ## Si todos los valores son confidenciales/NA, el agregado queda NA (no 0).
    exportaciones_millones_usd = {
      v <- exportaciones_millones_usd
      if (all(is.na(v))) NA_real_ else sum(v, na.rm = TRUE)
    },
    n_provincias_con_dato = sum(!is.na(exportaciones_millones_usd)),
    .groups = "drop"
  ) %>%
  left_join(totales_grupo, by = c("fecha", "anio", "la_rioja_region")) %>%
  mutate(
    share_pct = if_else(
      !is.na(exportaciones_millones_usd) & total_grupo_millones_usd > 0,
      100 * exportaciones_millones_usd / total_grupo_millones_usd,
      NA_real_
    )
  ) %>%
  arrange(fecha, la_rioja_region, desc(exportaciones_millones_usd))

dir.create("./data/inputs_md", showWarnings = FALSE, recursive = TRUE)
write_csv(df_prov, "./data/inputs_md/14_exportaciones_subrubros_provincia.csv")
write_csv(df_grupo, "./data/inputs_md/14_exportaciones_subrubros_region.csv")

message(
  "Listo. Subrubros OPEX: ",
  n_distinct(df_prov$anio), " años, ",
  n_distinct(df_prov$jurisdiccion), " provincias. ",
  "CSVs en data/inputs_md/14_exportaciones_subrubros_*.csv"
)
