library(tidyverse)
library(ggrepel)   # etiquetas de puntos clave con reubicación automática (anti-solape)
source('./style/fundar_monitor_theme.R')

## 03b (viz). Salario promedio de asalariados registrados (público y privado), EPH.
## Lee el CSV calculado en 02_indicadores_eph_individuo.R (fecha trimestral,
## la_rioja_region y sector) y grafica, en el estilo del Monitor, las dos series
## por sector facetadas por zona (Resto país / NOA-Resto / La Rioja).

df <- read_csv("./data/inputs_md/03b_salarios_registrados_EPH.csv")

# La fecha viene como string trimestral "YYYY-Q<n>": se pasa a Date (primer día
# del trimestre) para poder usar scale_x_date y el formateo de etiquetas.
df <- df %>%
  mutate(fecha = lubridate::yq(fecha))

# Etiqueta solo del último punto de cada zona x sector (con 6 series, etiquetar
# máx/mín/último satura el gráfico).
key_pts <- df %>%
  group_by(la_rioja_region, sector) %>%
  filter(fecha == max(fecha)) %>%
  ungroup() %>%
  mutate(
    label = paste0(
      "$", format(round(salario_promedio), big.mark = ".", decimal.mark = ",",
                  scientific = FALSE)
    )
  )

df %>%
  ggplot(aes(x = fecha,
             y = salario_promedio,
             group = sector,
             color = sector)) +
  geom_line(linewidth = 0.7) +
  geom_point(data = key_pts, size = 2, show.legend = FALSE) +
  geom_text_repel(
    data     = key_pts,
    aes(label = label),
    size     = 2.6,
    fontface = "bold",
    lineheight = 1.0,
    show.legend        = FALSE,
    min.segment.length = 0,
    box.padding        = 0.6,
    point.padding      = 0.3,
    segment.size       = 0.3,
    segment.alpha      = 0.6,
    max.overlaps       = Inf,
    seed               = 42
  ) +
  scale_color_fundar_multi(name = "Sector") +
  scale_y_continuous(
    labels = scales::label_number(big.mark = ".", decimal.mark = ",", prefix = "$"),
    expand = expansion(mult = c(0.05, 0.18))
  ) +
  theme_monitor() +
  theme(axis.text.x = element_text(size = 8)) +
  scale_x_date(date_labels = "%Y", date_breaks = "1 year") +
  coord_cartesian(clip = "off") +
  labs(
    title   = "Salario promedio de asalariados registrados (público y privado)",
    x       = "Trimestre",
    y       = "Pesos corrientes",
    caption = fuente_fundar("Fundar, con base en la EPH (INDEC).")
  ) +
  facet_wrap(~la_rioja_region, scales = "free_y")

ggsave('./outputs/plots/03b_salarios_registrados_EPH.png', width = 12, height = 7)
