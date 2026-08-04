## 06. Empleados públicos cada 1.000 habitantes (EPH Total Urbano, 3T).

library(tidyverse)
library(ggrepel)
source("./style/fundar_monitor_theme.R")

csv_path <- "./data/inputs_md/06_empleados_publicos_cada_1000_hab.csv"
csv_alt  <- "./data/inputs_md/06_empleados_publicos_cada_1000_hab_actualizado.csv"
if (file.exists(csv_alt) && file.info(csv_alt)$mtime > file.info(csv_path)$mtime) {
  csv_path <- csv_alt
}

df <- read_csv(csv_path, show_col_types = FALSE)

## Gráfico principal: agregados La Rioja / NOA-Resto / Resto país.
df_plot <- df %>%
  filter(tipo == "agregado") %>%
  mutate(
    serie = factor(serie),
    anio = ANO4,
    valor_plot = if_else(
      cobertura_completa,
      empleados_publicos_cada_1000,
      NA_real_
    )
  )

key_pts <- df_plot %>%
  group_by(serie) %>%
  filter(anio == max(anio[!is.na(valor_plot)], na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(
    label = format(
      round(empleados_publicos_cada_1000, 1),
      decimal.mark = ",",
      big.mark = ".",
      scientific = FALSE
    )
  )

df_plot %>%
  ggplot(aes(
    x = anio,
    y = valor_plot,
    group = serie,
    color = serie
  )) +
  geom_line(linewidth = 0.8, na.rm = TRUE) +
  geom_point(size = 2, na.rm = TRUE) +
  geom_point(data = key_pts, size = 2.5, show.legend = FALSE) +
  geom_text_repel(
    data = key_pts,
    aes(label = label),
    size = 3,
    fontface = "bold",
    show.legend = FALSE,
    min.segment.length = 0,
    box.padding = 0.4,
    point.padding = 0.3,
    segment.size = 0.3,
    segment.alpha = 0.6,
    max.overlaps = Inf,
    seed = 42
  ) +
  scale_color_fundar_multi(name = "Región") +
  scale_x_continuous(breaks = sort(unique(df_plot$anio))) +
  scale_y_continuous(
    limits = c(0, NA),
    expand = expansion(mult = c(0, 0.12))
  ) +
  theme_monitor() +
  theme(axis.text.x = element_text(size = 9)) +
  labs(
    title = "Empleados públicos cada 1.000 habitantes",
    subtitle = "Población urbana · 3er trimestre de cada año",
    x = "Año",
    y = "Empleados públicos cada 1.000 hab.",
    caption = fuente_fundar(
      paste0(
        "Fundar, con base en EPH Total Urbano (INDEC). ",
        "Asalariados ocupados del sector estatal (PP04A). ",
        "Agregados regionales sin dato cuando la cobertura provincial es incompleta ",
        "(Resto país: 2019-2020; NOA-Resto: 2020)."
      )
    )
  )

dir.create("./outputs/plots", showWarnings = FALSE, recursive = TRUE)
ggsave(
  "./outputs/plots/06_empleados_publicos_cada_1000_hab.png",
  width = 12,
  height = 7
)

## Gráfico complementario: provincias del NOA por separado.
df_noa <- df %>%
  filter(tipo == "provincia_noa") %>%
  mutate(
    anio = ANO4,
    serie = factor(
      serie,
      levels = c(
        "La Rioja", "Catamarca", "Jujuy",
        "Salta", "Santiago del Estero", "Tucumán"
      )
    )
  )

cols_noa <- c(
  "La Rioja" = "#2D6E6E",
  "Catamarca" = "#C8C87A",
  "Jujuy" = "#A8DCC8",
  "Salta" = "#F4877A",
  "Santiago del Estero" = "#9B8BC4",
  "Tucumán" = "#6B9BD1"
)

key_noa <- df_noa %>%
  group_by(serie) %>%
  filter(anio == max(anio)) %>%
  ungroup() %>%
  mutate(
    label = format(
      round(empleados_publicos_cada_1000, 1),
      decimal.mark = ",",
      scientific = FALSE
    )
  )

df_noa %>%
  ggplot(aes(
    x = anio,
    y = empleados_publicos_cada_1000,
    group = serie,
    color = serie
  )) +
  geom_line(linewidth = 0.8, na.rm = TRUE) +
  geom_point(size = 2, na.rm = TRUE) +
  geom_text_repel(
    data = key_noa,
    aes(label = label),
    size = 2.8,
    fontface = "bold",
    show.legend = FALSE,
    min.segment.length = 0,
    box.padding = 0.35,
    max.overlaps = Inf,
    seed = 42
  ) +
  scale_color_manual(name = "Provincia", values = cols_noa) +
  scale_x_continuous(breaks = sort(unique(df_noa$anio))) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.12))) +
  theme_monitor() +
  theme(axis.text.x = element_text(size = 9)) +
  labs(
    title = "Empleados públicos cada 1.000 habitantes — provincias del NOA",
    subtitle = "Población urbana · 3er trimestre de cada año",
    x = "Año",
    y = "Empleados públicos cada 1.000 hab.",
    caption = fuente_fundar(
      "Fundar, con base en EPH Total Urbano (INDEC). Asalariados ocupados del sector estatal (PP04A)."
    )
  )

ggsave(
  "./outputs/plots/06_empleados_publicos_cada_1000_hab_noa.png",
  width = 12,
  height = 7
)
