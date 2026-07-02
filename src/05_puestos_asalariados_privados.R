library(tidyverse)
source('./style/fundar_monitor_theme.R')

df <- read_csv("./data/inputs_md/05_puestos_asalariados_privados.csv")

noa <- c("Catamarca", "Jujuy", "Salta", "Santiago del Estero", "Tucumán", "La Rioja")

mes_es <- c("Ene","Feb","Mar","Abr","May","Jun","Jul","Ago","Sep","Oct","Nov","Dic")

df <- df %>%
  mutate(
    la_rioja_region = case_when(
      jurisdiccion == "La Rioja" ~ "3. La Rioja",
      jurisdiccion %in% noa & jurisdiccion != "La Rioja" ~ "2. NOA-Resto",
      TRUE ~ "1. Resto país"
    )
  )

df_agg <- df %>%
  group_by(fecha, la_rioja_region) %>%
  summarise(puestos_miles = mean(puestos_miles), .groups = "drop")

# Puntos clave por serie: máximo, mínimo y último (helper de style/fundar_monitor_theme.R)
key_pts <- puntos_etiqueta(df_agg, fecha, puestos_miles, la_rioja_region) %>%
  mutate(
    label = paste0(
      mes_es[as.integer(format(fecha, "%m"))], " ", format(fecha, "%Y"), "\n",
      format(round(puestos_miles), big.mark = ".", decimal.mark = ",", scientific = FALSE), " mil"
    )
  )

df_agg %>%
  ggplot(aes(x = fecha,
             y = puestos_miles,
             group = la_rioja_region,
             color = la_rioja_region)) +
  geom_line(linewidth = 0.7) +
  geom_point(data = key_pts, size = 2, show.legend = FALSE) +
  geom_text(
    data     = key_pts,
    aes(label = label, hjust = .hjust, vjust = .vjust),
    size     = 2.6,
    fontface = "bold",
    lineheight = 1.2,
    show.legend = FALSE
  ) +
  scale_color_fundar_multi(name = "Jurisdicción") +
  scale_y_continuous(expand = expansion(mult = c(0.05, 0.18))) +
  theme_monitor() +
  theme(axis.text.x = element_text(size = 8)) +
  scale_x_date(date_labels = "%m-%Y", date_breaks = "6 month") +
  coord_cartesian(clip = "off") +
  labs(
    title   = "Puestos de trabajo asalariados privados",
    x       = "Fecha",
    y       = "Miles de puestos",
    caption = fuente_fundar("Fundar, con base en datos de SIPA (ARCA), Ministerio de Capital Humano.")
  ) +
  facet_wrap(~la_rioja_region, scales = "free_y")

ggsave('./outputs/plots/05_puestos_asalariados_privados.png', width = 12, height = 7)
