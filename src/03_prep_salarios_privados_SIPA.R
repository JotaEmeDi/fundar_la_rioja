library(tidyverse)
library(readxl)
library(lubridate)

## 03 (prep). Salarios en el sector formal privado (SIPA).
## Fuente: STEySS - Dirección Nacional de Estudios y Estadísticas Laborales -
## Observatorio de Empleo y Dinámica Empresarial (Ministerio de Capital Humano),
## en base a SIPA. Hoja "Total" del archivo de remuneraciones provinciales:
## "Remuneración promedio de los trabajadores registrados del sector privado.
## Remuneración por todo concepto por provincia, a valores corrientes. En pesos".
## Serie mensual por provincia.
##
## Alcance: la fuente cubre SOLO el sector privado registrado (el sector público
## queda pendiente por falta de fuente). El indicador se rotula en consecuencia.

path_raw <- "./data/raw_data/sipa/provinciales_serie_remuneraciones_mensual_2dig_8.xlsx"

## La hoja viene TRASPUESTA respecto de otras fuentes SIPA (05): las provincias
## están en filas y los meses en columnas (encabezado en la fila 5). Los nombres
## de provincia vienen en MAYÚSCULAS sin acento. Se homologan a los nombres
## canónicos usados en 05/07 (columna jurisdiccion) para reusar la misma
## clasificación por región en el script de viz.
##
## Buenos Aires viene desagregado en tres filas: se toma "CAPITAL FEDERAL" como
## C.A.B.A. y "BUENOS AIRES" como la provincia; "GRAN BUENOS AIRES" se descarta
## (solapa a Buenos Aires y el agregado regional usa media no ponderada). "Total"
## (agregado nacional) y las filas de notas al pie no matchean el mapa y se
## descartan vía left_join + filter(!is.na(jurisdiccion)).
mapa_provincias <- tribble(
  ~jurisdiccion_raw,       ~jurisdiccion,
  "CAPITAL FEDERAL",       "C.A.B.A.",
  "BUENOS AIRES",          "Buenos Aires",
  "CATAMARCA",             "Catamarca",
  "CORDOBA",               "Córdoba",
  "CORRIENTES",            "Corrientes",
  "CHACO",                 "Chaco",
  "CHUBUT",                "Chubut",
  "ENTRE RIOS",            "Entre Ríos",
  "FORMOSA",               "Formosa",
  "JUJUY",                 "Jujuy",
  "LA PAMPA",              "La Pampa",
  "LA RIOJA",              "La Rioja",
  "MENDOZA",               "Mendoza",
  "MISIONES",              "Misiones",
  "NEUQUEN",               "Neuquén",
  "RIO NEGRO",             "Río Negro",
  "SALTA",                 "Salta",
  "SAN JUAN",              "San Juan",
  "SAN LUIS",              "San Luis",
  "SANTA CRUZ",            "Santa Cruz",
  "SANTA FE",              "Santa Fe",
  "SANTIAGO DEL ESTERO",   "Santiago del Estero",
  "TIERRA DEL FUEGO",      "Tierra del Fuego",
  "TUCUMAN",               "Tucumán"
)

mes_es <- c(ene = 1, feb = 2, mar = 3, abr = 4, may = 5, jun = 6,
            jul = 7, ago = 8, sep = 9, oct = 10, nov = 11, dic = 12)

## Las fechas están en el ENCABEZADO (nombres de columna). Con col_types = "text"
## readxl las devuelve como texto, pero la representación es mixta según la
## versión/formato de celda: serial de fecha de Excel (ej. "34700"), string ISO
## ("1995-01-01" o "1995-01-01 00:00:00") y/o texto abreviado en español
## ("ene-15", con posible asterisco de dato provisorio). Este parser cubre las
## tres formas y normaliza al primer día del mes (algunos meses vienen con día 11
## por un artefacto de carga de la fuente).
parse_fecha_header <- function(x) {
  x   <- str_squish(as.character(x))
  out <- as.Date(rep(NA_real_, length(x)), origin = "1970-01-01")

  # 1) Serial de fecha de Excel (texto puramente numérico).
  num <- suppressWarnings(as.numeric(x))
  i   <- !is.na(num)
  out[i] <- as.Date(num[i], origin = "1899-12-30")

  # 2) Fecha / fecha-hora ISO (se toman los primeros 10 caracteres).
  i <- is.na(out) & str_detect(x, "^\\d{4}-\\d{2}-\\d{2}")
  out[i] <- as.Date(str_sub(x[i], 1, 10))

  # 3) Texto abreviado en español ("ene-15", "mar-26*").
  xt <- str_remove(x, "\\*$")
  i  <- is.na(out) & str_detect(xt, "^[A-Za-z]{3}-\\d{2}$")
  if (any(i)) {
    m <- unname(mes_es[str_to_lower(str_sub(xt[i], 1, 3))])
    a <- 2000L + as.integer(str_sub(xt[i], 5, 6))
    out[i] <- as.Date(sprintf("%04d-%02d-01", a, m))
  }

  floor_date(out, "month")
}

## Recorte a años recientes: en pesos corrientes la serie va de ~$600 (1995) a
## ~$1,3M (2026); en escala lineal la historia previa queda aplastada por la
## inflación. Se recorta desde 2015 (consistente con 07_empresas). El raw
## conserva 1995+: para extender la serie, cambiar esta fecha.
FECHA_DESDE <- as.Date("2015-01-01")

## col_types = "text" evita que readxl adivine mal columnas mixtas; skip = 4 deja
## la fila 5 (Provincia + fechas) como encabezado.
df_raw <- read_excel(path_raw, sheet = "Total", skip = 4, col_types = "text")
names(df_raw)[1] <- "jurisdiccion_raw"

df <- df_raw %>%
  pivot_longer(-jurisdiccion_raw, names_to = "periodo",
               values_to = "salario_promedio") %>%
  mutate(
    jurisdiccion_raw = str_squish(jurisdiccion_raw),
    fecha            = parse_fecha_header(periodo),
    salario_promedio = suppressWarnings(as.numeric(salario_promedio))  # "s.d." -> NA
  ) %>%
  filter(!is.na(fecha)) %>%                        # descarta filas de notas al pie
  left_join(mapa_provincias, by = "jurisdiccion_raw") %>%
  filter(!is.na(jurisdiccion)) %>%                 # descarta GRAN BUENOS AIRES / Total
  filter(fecha >= FECHA_DESDE) %>%
  select(jurisdiccion, fecha, salario_promedio) %>%
  arrange(fecha, jurisdiccion)

dir.create("./data/inputs_md", showWarnings = FALSE, recursive = TRUE)
write_csv(df, "./data/inputs_md/03_salarios_privados_SIPA.csv")
