## 16. Recursos propios sobre recursos totales (tributarios).

library(tidyverse)
source("./style/fundar_monitor_theme.R")

dir.create("./outputs/plots", showWarnings = FALSE, recursive = TRUE)

df <- read_csv(
  "./data/inputs_md/16_recursos_propios_region.csv",
  show_col_types = FALSE
) %>%
  mutate(la_rioja_region = factor(la_rioja_region))

fuente <- fuente_fundar(
  paste(
    "Fundar, con base en Ministerio de Economía",
    "(TOP: recursos tributarios de origen provincial;",
    "RON: recursos de origen nacional)."
  )
)

key_pts <- puntos_etiqueta(df, anio, pct_propios, la_rioja_region) %>%
  mutate(label = paste0(anio, "\n", scales::percent(pct_propios, accuracy = 0.1)))

ggplot(df, aes(anio, pct_propios, color = la_rioja_region, group = la_rioja_region)) +
  geom_line(linewidth = 0.7) +
  geom_point(data = key_pts, size = 2, show.legend = FALSE) +
  geom_text(
    data = key_pts,
    aes(label = label, hjust = .hjust, vjust = .vjust),
    size = 2.6,
    fontface = "bold",
    lineheight = 1.15,
    show.legend = FALSE
  ) +
  scale_color_fundar_multi(name = "Jurisdicción") +
  scale_x_continuous(breaks = scales::pretty_breaks(8)) +
  scale_y_continuous(
    labels = scales::percent_format(accuracy = 1),
    expand = expansion(mult = c(0.05, 0.18))
  ) +
  theme_monitor() +
  labs(
    title = "Recursos propios sobre recursos totales",
    subtitle = "TOP / (TOP + RON) · recursos tributarios",
    x = "Año",
    y = "% recursos propios",
    caption = fuente
  ) +
  facet_wrap(~la_rioja_region, scales = "fixed")

ggsave("./outputs/plots/16_recursos_propios.png", width = 12, height = 7)

message("OK 16_recursos_propios viz → outputs/plots/16_recursos_propios.png")
