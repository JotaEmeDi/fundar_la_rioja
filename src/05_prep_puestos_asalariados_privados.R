library(tidyverse)
library(readxl)

## 05 (prep). Puestos de trabajo asalariados privados por provincia (SIPA).
## Fuente: Observatorio de Empleo y Dinámica Empresarial, Secretaría de Trabajo,
## Empleo y Seguridad Social (Ministerio de Capital Humano), en base a SIPA (ARCA).
## Hoja A.5.2 del reporte "Trabajo registrado": "Personas con empleo asalariado
## en el sector privado, según provincia. Sin estacionalidad. En miles". Por el
## método de desestacionalización, la suma de provincias difiere levemente del
## total nacional (nota 2/ de la hoja).

path_raw <- "./data/raw_data/sipa/trabajoregistrado_2603_estadisticas.xlsx"

## Encabezados de la hoja -> nombres de provincia canónicos, iguales a los usados
## en data/inputs_md/07_serie_empresas_por_jurisdiccion.csv (columna jurisdiccion),
## para poder reusar la misma clasificación por región en los scripts de viz.
mapa_provincias <- tribble(
  ~jurisdiccion_raw,                  ~jurisdiccion,
  "BUENOS AIRES",                     "Buenos Aires",
  "Cdad. Autónoma de Buenos Aires",   "C.A.B.A.",
  "CATAMARCA 3/",                     "Catamarca",
  "CHACO",                            "Chaco",
  "CHUBUT",                           "Chubut",
  "CÓRDOBA",                          "Córdoba",
  "CORRIENTES",                       "Corrientes",
  "ENTRE RÍOS",                       "Entre Ríos",
  "FORMOSA",                          "Formosa",
  "JUJUY",                            "Jujuy",
  "LA PAMPA",                         "La Pampa",
  "LA RIOJA",                         "La Rioja",
  "MENDOZA",                          "Mendoza",
  "MISIONES",                         "Misiones",
  "NEUQUÉN",                          "Neuquén",
  "RÍO NEGRO",                        "Río Negro",
  "SALTA",                            "Salta",
  "SAN JUAN",                         "San Juan",
  "SAN LUIS",                         "San Luis",
  "SANTA CRUZ",                       "Santa Cruz",
  "SANTA FE",                         "Santa Fe",
  "SANTIAGO DEL ESTERO",              "Santiago del Estero",
  "TIERRA DEL FUEGO",                 "Tierra del Fuego",
  "TUCUMÁN",                          "Tucumán"
)

mes_es <- c(ene = 1, feb = 2, mar = 3, abr = 4, may = 5, jun = 6,
            jul = 7, ago = 8, sep = 9, oct = 10, nov = 11, dic = 12)

## El período viene con tipo mixto: serial de fecha de Excel hasta ene-2015
## (numérico) y texto abreviado en español desde feb-2015 en adelante (con
## asterisco final en los últimos meses, provisorios, ej. "mar-26*"). Las
## filas de notas al pie/fuente (texto libre en la misma columna) no matchean
## ninguno de los dos formatos y quedan en NA -- se descartan más abajo.
## Se usan placeholders numéricos válidos antes de sprintf() (en vez de dejar
## pasar NA) para no depender de cómo maneja NA cada versión de R/sprintf.
parse_periodo <- function(x) {
  x_num      <- suppressWarnings(as.numeric(x))
  x_txt      <- str_remove(x, "\\*$")
  es_mes_ano <- str_detect(x_txt, "^[a-z]{3}-\\d{2}$")

  mes_chr  <- if_else(es_mes_ano, str_sub(x_txt, 1, 3), NA_character_)
  anio_chr <- if_else(es_mes_ano, str_sub(x_txt, 5, 6), NA_character_)
  mes      <- unname(mes_es[mes_chr])
  anio     <- 2000L + as.integer(anio_chr)

  mes_safe  <- if_else(is.na(mes),  1L,    as.integer(mes))
  anio_safe <- if_else(is.na(anio), 2000L, anio)

  fecha_texto <- if_else(
    es_mes_ano,
    as.Date(sprintf("%d-%02d-01", anio_safe, mes_safe)),
    as.Date(NA)
  )

  if_else(!is.na(x_num), as.Date(x_num, origin = "1899-12-30"), fecha_texto)
}

## col_types = "text" evita que readxl adivine mal el tipo de la columna de
## período (mixta: numérica en una parte de la serie, texto en el resto).
df_raw <- read_excel(path_raw, sheet = "A.5.2", skip = 1, col_types = "text")
names(df_raw) <- names(df_raw) %>% str_squish()

col_periodo <- names(df_raw)[[1]]

df <- df_raw %>%
  rename(periodo = all_of(col_periodo)) %>%
  mutate(fecha = parse_periodo(periodo)) %>%
  filter(!is.na(fecha)) %>%           # descarta filas de notas al pie / fuente
  select(-periodo) %>%
  pivot_longer(-fecha, names_to = "jurisdiccion_raw", values_to = "puestos_miles") %>%
  left_join(mapa_provincias, by = "jurisdiccion_raw") %>%
  mutate(puestos_miles = as.numeric(puestos_miles)) %>%
  select(jurisdiccion, fecha, puestos_miles) %>%
  arrange(fecha, jurisdiccion)

dir.create("./data/inputs_md", showWarnings = FALSE, recursive = TRUE)
write_csv(df, "./data/inputs_md/05_puestos_asalariados_privados.csv")
