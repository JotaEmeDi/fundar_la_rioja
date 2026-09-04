library(tidyverse)
source('./style/fundar_monitor_theme.R')

## CSV generado por src/07_prep_cant_empresas.R (SRT, Cuadro 6.2).
df <- read_csv("./data/inputs_md/07_serie_empresas_por_jurisdiccion.csv")

noa <- c("Catamarca", "Jujuy", "Salta","Santiago del Estero", "Tucumán", "La Rioja")

mes_es <- c("Ene","Feb","Mar","Abr","May","Jun","Jul","Ago","Sep","Oct","Nov","Dic")

df <- df %>%
  mutate(
    noa_region = if_else(jurisdiccion %in% noa, "NOA", "Resto"),
    la_rioja_region = case_when(
           jurisdiccion == "La Rioja" ~ "3. La Rioja",
           jurisdiccion %in% noa & jurisdiccion != "La Rioja" ~ "2. NOA-Resto",
           TRUE ~ "1. Resto país")
    )

df_agg <- df %>%
  group_by(fecha, noa_region, la_rioja_region) %>%
  summarise(empresas = sum(empresas), .groups = "drop")

# Puntos clave por serie: máximo, mínimo y último
key_pts <- df_agg %>%
  group_by(la_rioja_region) %>%
  summarise(
    fecha_max  = fecha[which.max(empresas)],
    fecha_min  = fecha[which.min(empresas)],
    fecha_last = max(fecha),
    .groups = "drop"
  ) %>%
  pivot_longer(cols = starts_with("fecha_"), names_to = "tipo", values_to = "fecha") %>%
  left_join(df_agg, by = c("la_rioja_region", "fecha")) %>%
  distinct(la_rioja_region, fecha, .keep_all = TRUE) %>%
  mutate(
    label = paste0(
      mes_es[as.integer(format(fecha, "%m"))], " ", format(fecha, "%Y"), "\n",
      format(round(empresas), big.mark = ".", decimal.mark = ",", scientific = FALSE)
    ),
    vjust = if_else(tipo == "fecha_min", 1.8, -0.6),
    hjust = if_else(tipo == "fecha_last", 1.1, 0.5)
  )

df_agg %>%
  ggplot(aes(x = fecha,
             y = empresas,
             group = la_rioja_region,
             color = la_rioja_region)) +
  geom_line(linewidth = 0.7) +
  geom_point(data = key_pts, size = 2, show.legend = FALSE) +
  geom_text(
    data     = key_pts,
    aes(label = label, vjust = vjust, hjust = hjust),
    size     = 2.6,
    fontface = "bold",
    lineheight = 1.2,
    show.legend = FALSE
  ) +
  scale_color_fundar_multi(name = "Jurisdicción") +
  scale_y_continuous(expand = expansion(mult = c(0.05, 0.18))) +
  theme_monitor() +
  theme(axis.text.x = element_text(size = 8)) +
  scale_x_date(date_labels = "%Y", date_breaks = "2 years") +
  coord_cartesian(clip = "off") +
  labs(
    title   = "Cantidad de empresas por jurisdicción",
    x       = "Fecha",
    y       = "Cantidad de empresas",
    caption = fuente_fundar("Fundar, con base en datos de SRT.")
  ) +
  facet_wrap(~la_rioja_region, scales = "free_y")

ggsave('./outputs/plots/11_empresas_jurisdiccion.png', width = 12, height = 7)
