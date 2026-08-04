## 18 (prep). Trayectoria escolar — cohorte primaria → secundaria (La Rioja).
##
## Indicador (acordado con Educación provincial, reuniones 3/7 y 10/7/2026):
##   trayectoria = matrícula 5° año (fin) / matrícula 1° grado (inicio)
##
## Mide llegada a 5° año respecto del stock de 1° grado de la cohorte teórica;
## NO es egreso formal ni panel nominal de los mismos alumnos.
##
## Fuente: Relevamiento Anual (RA), Excel provisto por la provincia.
## Raw: data/raw_data/educacion/trayectoria_YYYY_YYYY_la_rioja.xlsx
##
## Outputs:
##   data/inputs_md/18_trayectoria_escolar_matricula.csv
##   data/inputs_md/18_trayectoria_escolar_cohorte.csv

library(tidyverse)
library(readxl)
library(stringi)

path_raw <- "./data/raw_data/educacion/trayectoria_2014_2025_la_rioja.xlsx"
## Fallback: carpeta de trabajo con el Excel original de la provincia.
path_fallback <- list.files(
  "./trayectoria educativa",
  pattern = "(?i)trayectoria.*\\.xlsx$",
  full.names = TRUE
)[1]

dir.create("./data/inputs_md", showWarnings = FALSE, recursive = TRUE)

if (!file.exists(path_raw)) {
  if (is.na(path_fallback) || !file.exists(path_fallback)) {
    stop(
      "No está el Excel de trayectoria. Colocá el archivo en ", path_raw,
      " (ver ficha 18 del README)."
    )
  }
  dir.create(dirname(path_raw), showWarnings = FALSE, recursive = TRUE)
  file.copy(path_fallback, path_raw, overwrite = TRUE)
  message("Copié raw desde: ", path_fallback)
}

norm_txt <- function(x) {
  x %>%
    as.character() %>%
    str_squish() %>%
    stri_trans_general("Latin-ASCII") %>%
    str_to_lower()
}

raw <- read_excel(path_raw, sheet = 1, col_names = FALSE, .name_repair = "unique_quiet")

## Filas de datos: nivel + año calendario + año de estudio + matrícula.
dat <- raw %>%
  transmute(
    nivel = .[[1]],
    anio = suppressWarnings(as.integer(parse_number(as.character(.[[2]])))),
    anio_estudio = as.character(.[[3]]),
    matricula_total = suppressWarnings(as.numeric(.[[4]])),
    matricula_varones = suppressWarnings(as.numeric(.[[5]])),
    matricula_mujeres = suppressWarnings(as.numeric(.[[6]])),
    matricula_estatal = suppressWarnings(as.numeric(.[[7]])),
    matricula_privado = suppressWarnings(as.numeric(.[[8]]))
  ) %>%
  filter(
    !is.na(anio),
    !is.na(matricula_total),
    norm_txt(nivel) %in% c("primario", "secundario")
  ) %>%
  mutate(
    nivel = if_else(norm_txt(nivel) == "primario", "Primario", "Secundario"),
    anio_estudio_norm = norm_txt(anio_estudio),
    orden_cohorte = row_number(),
    provincia = "La Rioja"
  ) %>%
  arrange(anio, orden_cohorte)

if (nrow(dat) < 2) {
  stop("La base de trayectoria tiene menos de 2 filas útiles.")
}

inicio <- dat %>%
  filter(nivel == "Primario", str_detect(anio_estudio_norm, "1")) %>%
  slice_min(anio, n = 1, with_ties = FALSE)

final <- dat %>%
  filter(nivel == "Secundario", str_detect(anio_estudio_norm, "5")) %>%
  slice_max(anio, n = 1, with_ties = FALSE)

if (nrow(inicio) != 1 || nrow(final) != 1) {
  stop(
    "No pude identificar 1° grado inicial y/o 5° año final. ",
    "Revisar columnas 'Año de Estudio' del Excel."
  )
}

anios_esperados <- final$anio - inicio$anio
if (anios_esperados != 11L) {
  warning(
    "La cohorte no abarca 12 años calendario (diff=", anios_esperados,
    "). Seguir igual; validar con Educación."
  )
}

cohorte <- tibble(
  provincia = "La Rioja",
  anio_inicio = inicio$anio,
  anio_fin = final$anio,
  curso_inicio = inicio$anio_estudio,
  curso_fin = final$anio_estudio,
  matricula_inicio = inicio$matricula_total,
  matricula_fin = final$matricula_total,
  trayectoria = matricula_fin / matricula_inicio,
  trayectoria_varones = final$matricula_varones / inicio$matricula_varones,
  trayectoria_mujeres = final$matricula_mujeres / inicio$matricula_mujeres,
  trayectoria_estatal = final$matricula_estatal / inicio$matricula_estatal,
  trayectoria_privado = final$matricula_privado / inicio$matricula_privado,
  nota = paste(
    "Matrícula 5° año / matrícula 1° grado de la cohorte teórica.",
    "No es egreso formal ni seguimiento nominal.",
    "Fuente: Relevamiento Anual (provincia)."
  )
)

## Índice de retención a lo largo de la cohorte (base = 1° grado = 100).
matricula <- dat %>%
  mutate(
    indice_inicio = 100 * matricula_total / inicio$matricula_total,
    es_inicio = anio == inicio$anio & nivel == "Primario" &
      str_detect(anio_estudio_norm, "1"),
    es_fin = anio == final$anio & nivel == "Secundario" &
      str_detect(anio_estudio_norm, "5")
  ) %>%
  select(
    provincia, nivel, anio, anio_estudio, orden_cohorte,
    matricula_total, matricula_varones, matricula_mujeres,
    matricula_estatal, matricula_privado,
    indice_inicio, es_inicio, es_fin
  )

write_csv(matricula, "./data/inputs_md/18_trayectoria_escolar_matricula.csv")
write_csv(cohorte, "./data/inputs_md/18_trayectoria_escolar_cohorte.csv")

message(
  "OK 18_prep_trayectoria_escolar: cohorte ",
  cohorte$anio_inicio, "-", cohorte$anio_fin,
  " | tasa=", scales::percent(cohorte$trayectoria, accuracy = 0.1)
)
