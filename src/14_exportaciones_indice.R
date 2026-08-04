## 14 (viz). Exportaciones: índice 2015 = 100 (comparación dinámica regional).
## Un solo panel: permite comparar trayectorias pese a escalas absolutas muy distintas.

library(tidyverse)
library(ggrepel)
source("./style/fundar_monitor_theme.R")

path_csv <- "./data/inputs_md/14_exportaciones_indice_2015_region.csv"
ANIO_DESDE <- 2015L

df <- read_csv(path_csv, show_col_types = FALSE) %>%
  filter(anio >= ANIO_DESDE) %>%
  mutate(la_rioja_region = factor(la_rioja_region))

dir.create("./outputs/plots", showWarnings = FALSE, recursive = TRUE)

key <- df %>%
  group_by(la_rioja_region) %>%
  filter(anio == max(anio) | anio == ANIO_DESDE) %>%
  ungroup() %>%
  mutate(
    label = paste0(
      anio, "\n",
      format(round(indice_2015, 0), big.mark = ".", decimal.mark = ",",
             scientific = FALSE)
    )
  )

p_idx <- df %>%
  ggplot(aes(
    x = anio,
    y = indice_2015,
    group = la_rioja_region,
    color = la_rioja_region
  )) +
  geom_hline(yintercept = 100, linewidth = 0.4, linetype = "dashed",
             color = FUNDAR_GRIS) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  geom_point(data = key, size = 2.4, show.legend = FALSE) +
  geom_text_repel(
    data = key,
    aes(label = label),
    size = 2.8,
    fontface = "bold",
    lineheight = 1.05,
    show.legend = FALSE,
    min.segment.length = 0,
    box.padding = 0.45,
    max.overlaps = Inf,
    seed = 42
  ) +
  scale_color_fundar_multi(name = "Región") +
  scale_x_continuous(breaks = seq(ANIO_DESDE, max(df$anio), by = 1)) +
  scale_y_continuous(expand = expansion(mult = c(0.05, 0.18))) +
  theme_monitor() +
  theme(axis.text.x = element_text(size = 8, angle = 45, hjust = 1)) +
  labs(
    title = "Exportaciones: evolución relativa",
    subtitle = "Índice 2015 = 100 · suma de provincias de cada grupo · OPEX-INDEC",
    x = "Año",
    y = "Índice (2015 = 100)",
    caption = fuente_fundar(
      paste0(
        "Fundar, con base en OPEX-INDEC. La línea punteada marca el nivel de 2015. ",
        "2024-2025 provisorios. El índice compara dinámicas, no niveles absolutos."
      )
    )
  )

ggsave(
  "./outputs/plots/14_exportaciones_indice_2015_region.png",
  p_idx,
  width = 12,
  height = 7
)

## Participación en el total nacional (complemento de escala / peso relativo)
key_share <- df %>%
  group_by(la_rioja_region) %>%
  filter(anio == max(anio) | anio == ANIO_DESDE) %>%
  ungroup() %>%
  mutate(
    label = paste0(
      anio, "\n",
      format(round(share_nacional_pct, 2), decimal.mark = ","), "%"
    )
  )

p_share <- df %>%
  ggplot(aes(
    x = anio,
    y = share_nacional_pct,
    group = la_rioja_region,
    color = la_rioja_region
  )) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  geom_text_repel(
    data = key_share,
    aes(label = label),
    size = 2.7,
    fontface = "bold",
    lineheight = 1.05,
    show.legend = FALSE,
    min.segment.length = 0,
    box.padding = 0.45,
    max.overlaps = Inf,
    seed = 42
  ) +
  facet_wrap(~la_rioja_region, scales = "free_y", nrow = 1) +
  scale_color_fundar_multi(name = "Región") +
  scale_x_continuous(breaks = seq(ANIO_DESDE, max(df$anio), by = 2)) +
  scale_y_continuous(
    labels = function(x) paste0(format(x, decimal.mark = ","), "%"),
    expand = expansion(mult = c(0.05, 0.2))
  ) +
  theme_monitor() +
  theme(
    axis.text.x = element_text(size = 8, angle = 45, hjust = 1),
    strip.text = element_text(face = "bold", size = 11),
    legend.position = "none"
  ) +
  labs(
    title = "Participación en las exportaciones provinciales totales",
    subtitle = "Porcentaje del total nacional (suma de jurisdicciones OPEX) · 2015-2025",
    x = "Año",
    y = "% del total nacional",
    caption = fuente_fundar(
      "Fundar, con base en OPEX-INDEC. Facetas con ejes libres: La Rioja es un orden de magnitud menor."
    )
  )

ggsave(
  "./outputs/plots/14_exportaciones_share_nacional_region.png",
  p_share,
  width = 14,
  height = 6
)

message("Gráficos: outputs/plots/14_exportaciones_indice_2015_region.png y *_share_nacional_region.png")
