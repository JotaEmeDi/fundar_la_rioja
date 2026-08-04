## 06b (prep). Composición del empleo público por rama — EPH Total Urbano.
## Misma definición de empleo público que 06_prep_empleados_publicos_eph_tu.R:
##   asalariados ocupados (ESTADO==1, CAT_OCUP==3) en establecimiento estatal (PP04A==1).
##
## Desagregación: PP04B_COD (CAES-Mercosur). Se agrupa por los 2 primeros dígitos
## en grandes ramas relevantes para el empleo estatal.
##
## Indicador: share = sum(PONDERA del subgrupo) / sum(PONDERA empleo público)
## en esa región-año (las franjas suman 100% del empleo público).
##
## Outputs:
##   data/inputs_md/06_empleados_publicos_composicion_region.csv
##   data/inputs_md/06_empleados_publicos_composicion_provincia.csv

library(tidyverse)

dir_tu <- "./data/raw_data/eph_total_urbano_2024_25"
dir.create("./data/inputs_md", showWarnings = FALSE, recursive = TRUE)

files <- list.files(
  dir_tu,
  pattern = "personas.*\\.txt$",
  recursive = TRUE,
  full.names = TRUE,
  ignore.case = TRUE
)
if (length(files) == 0) stop("No se encontraron bases de personas en ", dir_tu)

mapa_provincia <- tribble(
  ~PROVINCIA, ~provincia,
  2L,  "C.A.B.A.",
  6L,  "Buenos Aires",
  10L, "Catamarca",
  14L, "Córdoba",
  18L, "Corrientes",
  22L, "Chaco",
  26L, "Chubut",
  30L, "Entre Ríos",
  34L, "Formosa",
  38L, "Jujuy",
  42L, "La Pampa",
  46L, "La Rioja",
  50L, "Mendoza",
  54L, "Misiones",
  58L, "Neuquén",
  62L, "Río Negro",
  66L, "Salta",
  70L, "San Juan",
  74L, "San Luis",
  78L, "Santa Cruz",
  82L, "Santa Fe",
  86L, "Santiago del Estero",
  90L, "Tucumán",
  94L, "Tierra del Fuego"
)

noa <- c("Catamarca", "Jujuy", "Salta", "Santiago del Estero", "Tucumán")

## Agrupación de CAES (2 dígitos) para lectura del monitor.
rama_macro <- function(cod) {
  digits <- str_remove_all(as.character(cod), "[^0-9]")
  c2 <- str_sub(digits, 1, 2)
  case_when(
    c2 == "84" ~ "Adm. pública y defensa",
    c2 == "85" ~ "Enseñanza",
    c2 %in% c("86", "87", "88") ~ "Salud y asistencia social",
    c2 %in% c("35", "36", "37") ~ "Electricidad, gas y agua",
    c2 %in% c("49", "50", "51", "52", "53") ~ "Transporte",
    c2 %in% c("64", "65", "66") ~ "Finanzas y seguros",
    c2 %in% c("40", "41", "42", "43") ~ "Construcción",
    c2 %in% c("80", "81") ~ "Servicios de seguridad / edificios",
    c2 %in% c("99", "00") | is.na(c2) | c2 == "" ~ "Sin clasificar / NsNr",
    TRUE ~ "Otros"
  )
}

orden_ramas <- c(
  "Adm. pública y defensa",
  "Enseñanza",
  "Salud y asistencia social",
  "Electricidad, gas y agua",
  "Transporte",
  "Finanzas y seguros",
  "Construcción",
  "Servicios de seguridad / edificios",
  "Otros",
  "Sin clasificar / NsNr"
)

cols_keep <- c(
  "ANO4", "TRIMESTRE", "PROVINCIA",
  "ESTADO", "CAT_OCUP", "PP04A", "PP04B_COD", "PONDERA"
)

leer_tu <- function(path) {
  read_delim(
    path,
    delim = ";",
    col_select = any_of(cols_keep),
    locale = locale(encoding = "latin1"),
    show_col_types = FALSE
  )
}

df <- map_dfr(files, leer_tu) %>%
  mutate(
    ANO4 = as.integer(ANO4),
    TRIMESTRE = as.integer(TRIMESTRE),
    PROVINCIA = as.integer(PROVINCIA),
    ESTADO = as.integer(ESTADO),
    CAT_OCUP = as.integer(CAT_OCUP),
    PP04A = as.integer(PP04A),
    PONDERA = as.numeric(PONDERA),
    empleado_publico = as.integer(coalesce(
      ESTADO == 1L & CAT_OCUP == 3L & PP04A == 1L,
      FALSE
    )),
    rama = rama_macro(PP04B_COD)
  ) %>%
  left_join(mapa_provincia, by = "PROVINCIA") %>%
  filter(
    empleado_publico == 1L,
    !is.na(provincia),
    !is.na(PONDERA),
    PONDERA > 0
  ) %>%
  mutate(
    la_rioja_region = case_when(
      provincia == "La Rioja" ~ "3. La Rioja",
      provincia %in% noa ~ "2. NOA-Resto",
      TRUE ~ "1. Resto país"
    ),
    rama = factor(rama, levels = orden_ramas)
  )

if (any(df$TRIMESTRE != 3L)) {
  stop("Las bases Total Urbano deben corresponder únicamente al 3er trimestre.")
}

resumir_comp <- function(data, ...) {
  data %>%
    group_by(..., rama) %>%
    summarise(
      empleados_publicos = sum(PONDERA),
      n_obs = n(),
      .groups = "drop"
    ) %>%
    group_by(...) %>%
    mutate(
      empleados_publicos_tot = sum(empleados_publicos),
      share = empleados_publicos / empleados_publicos_tot
    ) %>%
    ungroup() %>%
    arrange(..., rama)
}

df_region <- resumir_comp(df, ANO4, TRIMESTRE, la_rioja_region) %>%
  rename(serie = la_rioja_region) %>%
  mutate(tipo = "agregado")

df_prov <- resumir_comp(df, ANO4, TRIMESTRE, provincia) %>%
  mutate(tipo = "provincia")

write_csv(
  df_region %>%
    select(tipo, serie, ANO4, TRIMESTRE, rama, empleados_publicos,
           empleados_publicos_tot, share, n_obs),
  "./data/inputs_md/06_empleados_publicos_composicion_region.csv"
)

write_csv(
  df_prov %>%
    select(tipo, provincia, ANO4, TRIMESTRE, rama, empleados_publicos,
           empleados_publicos_tot, share, n_obs),
  "./data/inputs_md/06_empleados_publicos_composicion_provincia.csv"
)

message(
  "OK 06b composición empleo público: ",
  min(df_region$ANO4), "-", max(df_region$ANO4),
  " | filas región=", nrow(df_region)
)
