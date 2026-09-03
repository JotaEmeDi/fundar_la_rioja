## 12.% de < 25 on NED alto

library(tidyverse)
source('./style/fundar_monitor_theme.R')

df <- read_csv('./data/inputs_md/12_mayor_25_superior.csv')

df_plot <- df %>% mutate(la_rioja_region = factor(la_rioja_region))

## Eje X: solo Q1 y Q3 de cada año (evita amontonar las ~75 etiquetas
## trimestrales). Orden lexicográfico de "YYYY-Qn" = cronológico.
quiebres_x <- sort(unique(df_plot$fecha))
quiebres_x <- quiebres_x[grepl("Q1$|Q3$", quiebres_x)]

df_plot %>%
  ggplot(aes(x = fecha, y = porc_mayor_25_superior,
             group = la_rioja_region,
             color = la_rioja_region)) +
  geom_line(linewidth = 0.7) +
  ylim(0,35) +
  scale_color_fundar_multi(name = "Región") +
  scale_x_discrete(breaks = quiebres_x) +
  theme_monitor() +
  labs(title   = "Población mayor de 25 años con estudios superiores completos",
       x       = "Año-Trimestre",
       y       = "% de personas mayores de 25 años",
       caption = fuente_fundar("EPH-INDEC"))

ggsave('./outputs/plots/12_educ.png', width=12, height=8)
