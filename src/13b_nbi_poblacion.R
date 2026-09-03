## 13b. % Población en hogares con Necesidades Básicas Insatisfechas (NBI)

library(tidyverse)
source('./style/fundar_monitor_theme.R')

df <- read_csv('./data/inputs_md/13b_nbi_poblacion.csv')

df_plot <- df %>% mutate(la_rioja_region = factor(la_rioja_region))

## Eje X: solo Q1 y Q3 de cada año (evita amontonar las ~75 etiquetas
## trimestrales). Orden lexicográfico de "YYYY-Qn" = cronológico.
quiebres_x <- sort(unique(df_plot$fecha))
quiebres_x <- quiebres_x[grepl("Q1$|Q3$", quiebres_x)]

df_plot %>%
  ggplot(aes(x = fecha, y = pct_pob_NBI_TOT,
             group = la_rioja_region,
             color = la_rioja_region)) +
  geom_line(linewidth = 0.7) +
  scale_color_fundar_multi(name = "Región") +
  scale_x_discrete(breaks = quiebres_x) +
  ylim(0,60) +
  theme_monitor() +
  labs(title   = "Población en hogares con Necesidades Básicas Insatisfechas (NBI)",
       x       = "Año-Trimestre",
       y       = "% de población con NBI",
       caption = fuente_fundar("EPH-INDEC"))

ggsave('./outputs/plots/13b_nbi_poblacion.png', width=12, height=8)
