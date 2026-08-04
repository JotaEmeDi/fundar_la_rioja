library(tidyverse)

## 06 (prep). Empleados públicos cada 1.000 habitantes — EPH Total Urbano.
## Fuente: bases usuarias de personas, 3er trimestre 2016-2025.
## Representa población urbana de cada provincia (no el total provincial).
##
## Fórmula (misma lógica de ratios que tasa de empleo en 02_indicadores):
##   1000 * sum(empleado_publico * PONDERA) / sum(PONDERA)
##
## Numerador: ocupados (ESTADO==1), asalariados (CAT_OCUP==3), sector estatal
## (PP04A==1). Denominador: toda la población de la muestra. Peso: PONDERA
## (no PONDIIO: es un cociente de stocks, no un promedio de ingresos).
##
## Corte geográfico: La Rioja / NOA-Resto / Resto país (mismo criterio que el
## resto de indicadores EPH del monitor). También se guarda la serie por
## provincia para usos posteriores.
##
## Cobertura: 2019 no incluye Chaco; 2020 no incluye Santiago del Estero ni
## Tierra del Fuego. El CSV conserva el cálculo y agrega `cobertura_completa`
## para evitar presentar esos agregados regionales como comparables.

dir_tu <- "./data/raw_data/eph_total_urbano_2024_25"

files <- list.files(
  dir_tu,
  pattern = "personas.*\\.txt$",
  recursive = TRUE,
  full.names = TRUE,
  ignore.case = TRUE
)
if (length(files) == 0) {
  stop("No se encontraron bases de personas en ", dir_tu)
}

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

noa <- c("Catamarca", "Jujuy", "Salta", "Santiago del Estero", "Tucumán", "La Rioja")

cols_keep <- c("ANO4", "TRIMESTRE", "PROVINCIA", "ESTADO", "CAT_OCUP", "PP04A", "PONDERA")

leer_tu <- function(path) {
  read_delim(
    path,
    delim = ";",
    col_select = any_of(cols_keep),
    locale = locale(encoding = "latin1"),
    show_col_types = FALSE
  ) %>%
    mutate(archivo = basename(path))
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
    fecha = paste0(ANO4, "-Q", TRIMESTRE),
    empleado_publico = as.integer(coalesce(
      ESTADO == 1L & CAT_OCUP == 3L & PP04A == 1L,
      FALSE
    ))
  ) %>%
  left_join(mapa_provincia, by = "PROVINCIA") %>%
  filter(!is.na(provincia), !is.na(PONDERA), PONDERA > 0) %>%
  mutate(
    la_rioja_region = case_when(
      provincia == "La Rioja" ~ "3. La Rioja",
      provincia %in% noa ~ "2. NOA-Resto",
      TRUE ~ "1. Resto país"
    )
  )

if (any(df$TRIMESTRE != 3L)) {
  stop("Las bases Total Urbano deben corresponder únicamente al 3er trimestre.")
}

resumir_tasa <- function(data, ...) {
  data %>%
    group_by(...) %>%
    summarise(
      empleados_publicos = sum(empleado_publico * PONDERA),
      pob_tot = sum(PONDERA),
      n_obs_publicos = sum(empleado_publico),
      .groups = "drop"
    ) %>%
    mutate(empleados_publicos_cada_1000 = 1000 * empleados_publicos / pob_tot) %>%
    arrange(...)
}

df_region <- resumir_tasa(df, fecha, ANO4, TRIMESTRE, la_rioja_region) %>%
  rename(serie = la_rioja_region) %>%
  mutate(tipo = "agregado")

## Provincias del NOA por separado (incluye La Rioja), en el mismo CSV.
df_noa_prov <- resumir_tasa(
  df %>% filter(provincia %in% noa),
  fecha, ANO4, TRIMESTRE, provincia
) %>%
  rename(serie = provincia) %>%
  mutate(tipo = "provincia_noa")

df_prov <- resumir_tasa(df, fecha, ANO4, TRIMESTRE, provincia)

cobertura_agregado <- df %>%
  distinct(fecha, la_rioja_region, provincia) %>%
  count(fecha, la_rioja_region, name = "n_provincias") %>%
  mutate(
    n_provincias_esperadas = case_when(
      la_rioja_region == "3. La Rioja" ~ 1L,
      la_rioja_region == "2. NOA-Resto" ~ 5L,
      la_rioja_region == "1. Resto país" ~ 18L
    ),
    cobertura_completa = n_provincias == n_provincias_esperadas,
    serie = la_rioja_region,
    tipo = "agregado"
  ) %>%
  select(fecha, serie, tipo, n_provincias, n_provincias_esperadas, cobertura_completa)

## Una provincia individual tiene cobertura completa si aparece en ese año.
cobertura_noa <- df %>%
  filter(provincia %in% noa) %>%
  distinct(fecha, provincia) %>%
  transmute(
    fecha,
    serie = provincia,
    tipo = "provincia_noa",
    n_provincias = 1L,
    n_provincias_esperadas = 1L,
    cobertura_completa = TRUE
  )

df_out <- bind_rows(df_region, df_noa_prov) %>%
  left_join(
    bind_rows(cobertura_agregado, cobertura_noa),
    by = c("fecha", "serie", "tipo")
  ) %>%
  arrange(fecha, tipo, serie)

dir.create("./data/inputs_md", showWarnings = FALSE, recursive = TRUE)
path_main <- "./data/inputs_md/06_empleados_publicos_cada_1000_hab.csv"
path_prov <- "./data/inputs_md/06_empleados_publicos_cada_1000_hab_provincia.csv"
## Si el CSV está abierto (Excel/Sheets), escribe una copia temporal.
tryCatch(
  write_csv(df_out, path_main),
  error = function(e) {
    alt <- sub("\\.csv$", "_actualizado.csv", path_main)
    write_csv(df_out, alt)
    warning("No se pudo sobrescribir ", path_main, "; se escribió ", alt)
  }
)
tryCatch(
  write_csv(df_prov, path_prov),
  error = function(e) {
    alt <- sub("\\.csv$", "_actualizado.csv", path_prov)
    write_csv(df_prov, alt)
    warning("No se pudo sobrescribir ", path_prov, "; se escribió ", alt)
  }
)

message(
  "Listo. Empleados públicos cada 1.000 hab. (Total Urbano 3T): ",
  paste(sort(unique(df_out$ANO4)), collapse = ", "),
  ". CSV con agregados + provincias NOA, y CSV de las 24 provincias."
)
