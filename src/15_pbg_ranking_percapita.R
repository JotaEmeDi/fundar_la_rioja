## 15 (viz). Bump chart: ranking del PBG per cápita provincial.
##   - Ordena las 24 jurisdicciones por PBG per cápita (pesos const. 2004) en
##     cada año y sigue la posición de cada una a lo largo del tiempo.
##   - La Rioja destacada (mismo criterio de color que el ranking de barras
##     de 15_pbg_per_capita.R: gris para el resto, naranja para La Rioja).
##
## Fuente de datos: data/inputs_md/15_pbg_per_capita_por_provincia.csv
##   (generado por src/15_prep_pbg_per_capita.R). Serie 2010-2024 (limitada
##   por la disponibilidad de población anual DNAP; ver ese script).

library(tidyverse)
library(ggrepel)
source("./style/fundar_monitor_theme.R")

dir.create("./outputs/plots", showWarnings = FALSE, recursive = TRUE)

prov <- read_csv(
  "./data/inputs_md/15_pbg_per_capita_por_provincia.csv",
  show_col_types = FALSE
)

anio_min <- min(prov$anio)
anio_max <- max(prov$anio)

## Ranking por año: 1 = mayor PBG per cápita.
rank_df <- prov %>%
  group_by(anio) %>%
  mutate(ranking = min_rank(desc(pbg_per_capita))) %>%
  ungroup() %>%
  mutate(es_lr = provincia == "La Rioja")

## Etiquetas en los extremos (provincia + ranking), una por serie.
etq_izq <- rank_df %>% filter(anio == anio_min)
etq_der <- rank_df %>% filter(anio == anio_max)

fuente <- fuente_fundar(
  paste(
    "Fundar, con base en CEPAL / Ministerio de Economía",
    "(VAB provincial a precios de 2004) y DNAP (proyecciones de población)."
  )
)

ggplot(rank_df, aes(anio, ranking, group = provincia, color = es_lr)) +
  geom_line(aes(linewidth = es_lr, alpha = es_lr)) +
  geom_point(aes(size = es_lr), show.legend = FALSE) +
  geom_text(
    data = etq_izq,
    aes(label = provincia),
    hjust = 1.08,
    size = 2.6,
    fontface = "bold",
    show.legend = FALSE
  ) +
  geom_text(
    data = etq_der,
    aes(label = provincia),
    hjust = -0.08,
    size = 2.6,
    fontface = "bold",
    show.legend = FALSE
  ) +
  scale_color_manual(values = c(`FALSE` = "#9CA3AF", `TRUE` = "#E4572E")) +
  scale_linewidth_manual(values = c(`FALSE` = 0.5, `TRUE` = 1.3)) +
  scale_alpha_manual(values = c(`FALSE` = 0.55, `TRUE` = 1)) +
  scale_size_manual(values = c(`FALSE` = 1.3, `TRUE` = 2.6)) +
  scale_y_reverse(breaks = 1:24, expand = expansion(mult = c(0.03, 0.03))) +
  scale_x_continuous(
    breaks = anio_min:anio_max,
    expand = expansion(mult = c(0.14, 0.14))
  ) +
  coord_cartesian(clip = "off") +
  theme_monitor() +
  theme(
    legend.position = "none",
    panel.grid.major.y = element_line(color = FUNDAR_GRILLA, linewidth = 0.3),
    panel.grid.major.x = element_line(color = FUNDAR_GRILLA, linewidth = 0.2),
    axis.text.x = element_text(size = 8, angle = 45, hjust = 1),
    axis.text.y = element_text(size = 7),
    plot.margin = margin(16, 90, 16, 90)
  ) +
  labs(
    title = "Ranking del PBG per cápita provincial",
    subtitle = paste0(
      "Posición entre las 24 jurisdicciones · pesos constantes de 2004 · ",
      anio_min, "-", anio_max
    ),
    x = "Año",
    y = "Ranking (1 = mayor PBG per cápita)",
    caption = fuente
  )

ggsave(
  "./outputs/plots/15_pbg_ranking_percapita.png",
  width = 13,
  height = 9
)

message("OK 15_pbg_ranking_percapita viz → outputs/plots/15_pbg_ranking_percapita.png")
