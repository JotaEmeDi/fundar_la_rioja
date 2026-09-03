## 15. Visualizaciones PBG provincial (CEPAL):
##   - evolución del VAB (índice 2004 = 100)
##   - % del PBG industrial
##   - estructura productiva por letra CIIU (último año)

library(tidyverse)
source("./style/fundar_monitor_theme.R")

dir.create("./outputs/plots", showWarnings = FALSE, recursive = TRUE)

pbg <- read_csv("./data/inputs_md/15_pbg_region.csv", show_col_types = FALSE) %>%
  mutate(la_rioja_region = factor(la_rioja_region))

pct_ind <- read_csv(
  "./data/inputs_md/15_pbg_pct_industrial_region.csv",
  show_col_types = FALSE
) %>%
  mutate(la_rioja_region = factor(la_rioja_region))

estructura <- read_csv(
  "./data/inputs_md/15_pbg_estructura_region.csv",
  show_col_types = FALSE
) %>%
  mutate(la_rioja_region = factor(la_rioja_region))

fuente <- fuente_fundar(
  "Fundar, con base en CEPAL y Ministerio de Economía (VAB provincial a precios de 2004)."
)

anio_max <- max(estructura$anio)

## -------- 1) Evolución PBG (índice 2004 = 100) --------
key_pbg <- puntos_etiqueta(pbg, anio, indice_2004, la_rioja_region) %>%
  mutate(label = paste0(anio, "\n", round(indice_2004, 0)))

ggplot(pbg, aes(anio, indice_2004, color = la_rioja_region, group = la_rioja_region)) +
  geom_line(linewidth = 0.7) +
  geom_point(data = key_pbg, size = 2, show.legend = FALSE) +
  geom_text(
    data = key_pbg,
    aes(label = label, hjust = .hjust, vjust = .vjust),
    size = 2.6,
    fontface = "bold",
    lineheight = 1.15,
    show.legend = FALSE
  ) +
  scale_color_fundar_multi(name = "Jurisdicción") +
  scale_x_continuous(breaks = scales::pretty_breaks(8)) +
  scale_y_continuous(expand = expansion(mult = c(0.05, 0.18))) +
  theme_monitor() +
  labs(
    title = "Producto Bruto Geográfico (VAB)",
    subtitle = "Índice 2004 = 100 · precios constantes de 2004",
    x = "Año",
    y = "Índice (2004 = 100)",
    caption = fuente
  ) +
  facet_wrap(~la_rioja_region, scales = "fixed")

ggsave("./outputs/plots/15_pbg_evolucion.png", width = 12, height = 7)

## -------- 2) % industrial del PBG --------
key_ind <- puntos_etiqueta(pct_ind, anio, pct_industrial, la_rioja_region) %>%
  mutate(label = paste0(anio, "\n", scales::percent(pct_industrial, accuracy = 0.1)))

ggplot(
  pct_ind,
  aes(anio, pct_industrial, color = la_rioja_region, group = la_rioja_region)
) +
  geom_line(linewidth = 0.7) +
  geom_point(data = key_ind, size = 2, show.legend = FALSE) +
  geom_text(
    data = key_ind,
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
    title = "Participación de la industria manufacturera en el PBG",
    subtitle = "Letra D (CIIU Rev. 3) · precios constantes de 2004",
    x = "Año",
    y = "% del PBG",
    caption = fuente
  ) +
  facet_wrap(~la_rioja_region, scales = "fixed")

ggsave("./outputs/plots/15_pbg_pct_industrial.png", width = 12, height = 7)

## -------- 3) Estructura productiva (stacked, último año) --------
## Orden de letras fijo A–P; etiquetas abreviadas para leyenda.
orden_letras <- c(
  "Agro",
  "Pesca",
  "Petróleo y minería",
  "Industria manufacturera",
  "Electricidad, gas y agua",
  "Construcción",
  "Comercio",
  "Hotelería y restaurantes",
  "Transporte y comunicaciones",
  "Finanzas",
  "Serv. inmobiliarios y profesionales",
  "Adm. pública y defensa",
  "Enseñanza",
  "Salud",
  "Serv. comunitarios, sociales y personales",
  "Servicio doméstico"
)

df_est <- estructura %>%
  filter(anio == anio_max, share > 0) %>%
  mutate(letra_desc = factor(letra_desc, levels = orden_letras))

## Paleta divergente Bienes (fríos) / Servicios (cálidos), 16 tonos.
## Nombrada (en vez de posicional) para no depender del orden de orden_letras.
pal_letras <- c(
  "Agro" = "#2D6E6E",
  "Pesca" = "#3C9684",
  "Petróleo y minería" = "#51C49F",
  "Industria manufacturera" = "#7CBEB1",
  "Electricidad, gas y agua" = "#B8DCB6",
  "Construcción" = "#C4C686",
  "Comercio" = "#DEB371",
  "Hotelería y restaurantes" = "#ED9B70",
  "Transporte y comunicaciones" = "#E78E89",
  "Finanzas" = "#D395AA",
  "Serv. inmobiliarios y profesionales" = "#B08ABB",
  "Adm. pública y defensa" = "#7074A1",
  "Enseñanza" = "#567384",
  "Salud" = "#4A5278",
  "Serv. comunitarios, sociales y personales" = "#6A7A8E",
  "Servicio doméstico" = "#8A8D83"
)

ggplot(df_est, aes(la_rioja_region, share, fill = letra_desc)) +
  geom_col(width = 0.72, color = NA) +
  scale_fill_manual(values = pal_letras, name = NULL, drop = FALSE) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  theme_monitor(legend_position = "bottom") +
  theme(
    legend.text = element_text(size = 8),
    axis.text.x = element_text(angle = 0, hjust = 0.5)
  ) +
  guides(fill = guide_legend(nrow = 4, byrow = TRUE)) +
  labs(
    title = "Estructura productiva por gran sector",
    subtitle = paste0(
      "Participación en el PBG · ", anio_max,
      " · precios constantes de 2004"
    ),
    x = NULL,
    y = "% del PBG",
    caption = fuente
  )

ggsave("./outputs/plots/15_pbg_estructura.png", width = 12, height = 8)

## -------- 4) Evolución de grandes sectores (área apilada, estilo Argendata) --------
## Agrupa letras CIIU en: Agro, Minería, Industria, Construcción,
## Comercio, Adm. pública, Servicios (resto de servicios + energía).
sectores_macro <- estructura %>%
  mutate(
    sector_macro = case_when(
      letra %in% c("A", "B") ~ "Agro",
      letra == "C" ~ "Minería",
      letra == "D" ~ "Industria",
      letra == "F" ~ "Construcción",
      letra == "G" ~ "Comercio",
      letra == "L" ~ "Adm. pública",
      TRUE ~ "Servicios"
    ),
    sector_macro = factor(
      sector_macro,
      levels = c(
        "Agro", "Minería", "Industria", "Construcción",
        "Comercio", "Adm. pública", "Servicios"
      )
    )
  ) %>%
  group_by(anio, la_rioja_region, sector_macro) %>%
  summarise(
    vab_millones_2004 = sum(vab_millones_2004),
    share = sum(share),
    .groups = "drop"
  )

write_csv(sectores_macro, "./data/inputs_md/15_pbg_sectores_macro_region.csv")

pal_macro <- c(
  "Agro" = "#2D6E6E",
  "Minería" = "#52C8A0",
  "Industria" = "#A8DCC8",
  "Construcción" = "#C8C87A",
  "Comercio" = "#E0B070",
  "Adm. pública" = "#9B8BC4",
  "Servicios" = "#F4877A"
)

ggplot(
  sectores_macro,
  aes(anio, share, fill = sector_macro)
) +
  geom_area(color = "white", linewidth = 0.15, alpha = 0.95) +
  scale_fill_manual(values = pal_macro, name = NULL) +
  scale_x_continuous(breaks = scales::pretty_breaks(8)) +
  scale_y_continuous(
    labels = scales::percent_format(accuracy = 1),
    expand = c(0, 0)
  ) +
  theme_monitor(legend_position = "bottom") +
  theme(
    legend.text = element_text(size = 9),
    axis.text.x = element_text(angle = 45, hjust = 1)
  ) +
  guides(fill = guide_legend(nrow = 1, reverse = FALSE)) +
  labs(
    title = "Evolución de la estructura productiva",
    subtitle = "Participación de grandes sectores en el PBG · precios constantes de 2004",
    x = "Año",
    y = "% del PBG",
    caption = paste0(
      fuente,
      " Servicios incluye energía, transporte, finanzas, inmobiliarios,",
      " enseñanza, salud y otros servicios (excluye comercio y adm. pública)."
    )
  ) +
  facet_wrap(~la_rioja_region, nrow = 1)

ggsave("./outputs/plots/15_pbg_sectores_evolucion.png", width = 13, height = 7)

## -------- 5) Zoom dentro de Servicios (composición del agregado) --------
## Letras que en el gráfico macro caen en "Servicios".
letras_servicios <- c("E", "H", "I", "J", "K", "M", "N", "O", "P")

orden_serv <- c(
  "Electricidad, gas y agua",
  "Hotelería y restaurantes",
  "Transporte y comunicaciones",
  "Finanzas",
  "Serv. inmobiliarios y profesionales",
  "Enseñanza",
  "Salud",
  "Serv. comunitarios, sociales y personales",
  "Servicio doméstico"
)

pal_serv <- c(
  "Electricidad, gas y agua" = "#2D6E6E",
  "Hotelería y restaurantes" = "#52C8A0",
  "Transporte y comunicaciones" = "#A8DCC8",
  "Finanzas" = "#C8C87A",
  "Serv. inmobiliarios y profesionales" = "#E0B070",
  "Enseñanza" = "#9B8BC4",
  "Salud" = "#7A6FA0",
  "Serv. comunitarios, sociales y personales" = "#F4877A",
  "Servicio doméstico" = "#888888"
)

servicios_detalle <- estructura %>%
  filter(letra %in% letras_servicios) %>%
  group_by(anio, la_rioja_region) %>%
  mutate(share_en_servicios = vab_millones_2004 / sum(vab_millones_2004)) %>%
  ungroup() %>%
  mutate(letra_desc = factor(letra_desc, levels = orden_serv))

write_csv(
  servicios_detalle %>%
    select(anio, la_rioja_region, letra, letra_desc,
           vab_millones_2004, share_en_pbg = share, share_en_servicios),
  "./data/inputs_md/15_pbg_servicios_detalle_region.csv"
)

ggplot(
  servicios_detalle,
  aes(anio, share_en_servicios, fill = letra_desc)
) +
  geom_area(color = "white", linewidth = 0.15, alpha = 0.95) +
  scale_fill_manual(values = pal_serv, name = NULL, drop = FALSE) +
  scale_x_continuous(breaks = scales::pretty_breaks(8)) +
  scale_y_continuous(
    labels = scales::percent_format(accuracy = 1),
    expand = c(0, 0)
  ) +
  theme_monitor(legend_position = "bottom") +
  theme(
    legend.text = element_text(size = 8),
    axis.text.x = element_text(angle = 45, hjust = 1)
  ) +
  guides(fill = guide_legend(nrow = 3, byrow = TRUE)) +
  labs(
    title = "Composición interna de Servicios",
    subtitle = "Participación dentro del agregado Servicios del PBG · precios constantes de 2004",
    x = "Año",
    y = "% de Servicios",
    caption = paste0(
      fuente,
      " Excluye Comercio (G) y Adm. pública (L), que se muestran aparte en el gráfico de grandes sectores."
    )
  ) +
  facet_wrap(~la_rioja_region, nrow = 1)

ggsave("./outputs/plots/15_pbg_servicios_detalle.png", width = 13, height = 7.5)

message("OK 15_pbg viz → outputs/plots/15_pbg_*.png")
