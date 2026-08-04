## 14 (prep). Exportaciones regionales: totales, índice 2015=100 y share nacional.
## Fuente: data/inputs_md/14_exportaciones_por_provincia.csv (OPEX-INDEC).
## Agregación La Rioja / NOA-Resto / Resto país = SUMA de millones USD.
## Índice_t = 100 * exportaciones_t / exportaciones_2015.
## Share = exportaciones_grupo / total_nacional * 100.

library(tidyverse)

path_in  <- "./data/inputs_md/14_exportaciones_por_provincia.csv"
path_out <- "./data/inputs_md/14_exportaciones_indice_2015_region.csv"

ANIO_BASE <- 2015L

noa <- c("Catamarca", "Jujuy", "Salta", "Santiago del Estero", "Tucumán")

if (!file.exists(path_in)) {
  stop("Falta ", path_in, ". Correr antes src/14_prep_exportaciones.R")
}

df <- read_csv(path_in, show_col_types = FALSE) %>%
  mutate(
    la_rioja_region = case_when(
      jurisdiccion == "La Rioja" ~ "3. La Rioja",
      jurisdiccion %in% noa ~ "2. NOA-Resto",
      TRUE ~ "1. Resto país"
    )
  )

totales <- df %>%
  group_by(anio, fecha, la_rioja_region) %>%
  summarise(
    exportaciones_millones_usd = sum(exportaciones_millones_usd, na.rm = TRUE),
    provisorio = any(provisorio),
    .groups = "drop"
  )

total_pais <- totales %>%
  group_by(anio) %>%
  summarise(total_nacional_millones_usd = sum(exportaciones_millones_usd), .groups = "drop")

base_2015 <- totales %>%
  filter(anio == ANIO_BASE) %>%
  select(la_rioja_region, base_millones_usd = exportaciones_millones_usd)

out <- totales %>%
  left_join(base_2015, by = "la_rioja_region") %>%
  left_join(total_pais, by = "anio") %>%
  mutate(
    indice_2015 = 100 * exportaciones_millones_usd / base_millones_usd,
    share_nacional_pct = 100 * exportaciones_millones_usd / total_nacional_millones_usd
  ) %>%
  select(
    anio, fecha, la_rioja_region,
    exportaciones_millones_usd,
    indice_2015,
    share_nacional_pct,
    total_nacional_millones_usd,
    provisorio
  ) %>%
  arrange(anio, la_rioja_region)

dir.create("./data/inputs_md", showWarnings = FALSE, recursive = TRUE)
write_csv(out, path_out)

message(
  "Listo: ", path_out, "\n",
  "Años: ", min(out$anio), "-", max(out$anio),
  " | índice base ", ANIO_BASE, " = 100."
)
