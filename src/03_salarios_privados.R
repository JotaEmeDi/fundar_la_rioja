library(tidyverse)
library(ggrepel)   # etiquetas de puntos clave con reubicación automática (anti-solape)
source('./style/fundar_monitor_theme.R')

## 03 (viz). Remuneración promedio del sector privado registrado (SIPA).
## Lee el CSV largo (ya recortado a 2015+ desde 03_prep_salarios_privados.R),
## clasifica cada provincia por región, promedia por región y grafica en el
## estilo del Monitor (fundar_monitor_theme.R): las tres líneas regionales
## superpuestas en un solo panel.

df <- read_csv("./data/inputs_md/03_salarios_privados.csv")

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
  summarise(salario_promedio = mean(salario_promedio, na.rm = TRUE), .groups = "drop")

# Puntos clave por serie: máximo, mínimo y último (helper de style/fundar_monitor_theme.R)
key_pts <- puntos_etiqueta(df_agg, fecha, salario_promedio, la_rioja_region) %>%
  mutate(
    label = paste0(
      mes_es[as.integer(format(fecha, "%m"))], " ", format(fecha, "%Y"), "\n",
      "$", format(round(salario_promedio), big.mark = ".", decimal.mark = ",",
                  scientific = FALSE)
    )
  )

df_agg %>%
  ggplot(aes(x = fecha,
             y = salario_promedio,
             group = la_rioja_region,
             color = la_rioja_region)) +
  geom_line(linewidth = 0.7) +
  geom_point(data = key_pts, size = 2, show.legend = FALSE) +
  geom_text_repel(
    data     = key_pts,
    aes(label = label),
    size     = 2.6,
    fontface = "bold",
    lineheight = 1.0,
    show.legend        = FALSE,
    min.segment.length = 0,      # siempre dibuja la línea guía al punto
    box.padding        = 0.6,
    point.padding      = 0.3,
    segment.size       = 0.3,
    segment.alpha      = 0.6,
    max.overlaps       = Inf,
    seed               = 42      # posición reproducible entre corridas
  ) +
  scale_color_fundar_multi(name = "Jurisdicción") +
  scale_y_continuous(
    labels = scales::label_number(big.mark = ".", decimal.mark = ",", prefix = "$"),
    expand = expansion(mult = c(0.05, 0.18))
  ) +
  theme_monitor() +
  theme(axis.text.x = element_text(size = 8)) +
  scale_x_date(date_labels = "%m-%Y", date_breaks = "6 month") +
  coord_cartesian(clip = "off") +
  labs(
    title   = "Remuneración promedio del sector privado registrado",
    x       = "Fecha",
    y       = "Pesos corrientes",
    caption = fuente_fundar("Fundar, con base en datos de SIPA (Observatorio de Empleo y Dinámica Empresarial, STEySS - Ministerio de Capital Humano).")
  )

ggsave('./outputs/plots/03_salarios_privados.png', width = 12, height = 7)
