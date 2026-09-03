## 06b. Composición del empleo público por rama (EPH Total Urbano).

library(tidyverse)
source("./style/fundar_monitor_theme.R")

dir.create("./outputs/plots", showWarnings = FALSE, recursive = TRUE)

df <- read_csv(
  "./data/inputs_md/06_empleados_publicos_composicion_region.csv",
  show_col_types = FALSE
) %>%
  mutate(
    serie = factor(serie),
    rama = factor(
      rama,
      levels = c(
        "Adm. pública y defensa",
        "Enseñanza",
        "Salud y asistencia social",
        "Electricidad, gas y agua",
        "Transporte",
        "Finanzas y seguros",
        "Construcción",
        "Servicios de seguridad / edificios",
        "Otros",
        "Sin clasificar / NsNr"
      )
    )
  )

fuente <- fuente_fundar(
  paste(
    "Fundar, con base en EPH Total Urbano (INDEC).",
    "Asalariados ocupados del sector estatal (PP04A==1),",
    "desagregados por PP04B_COD (CAES)."
  )
)

pal_ramas <- c(
  "Adm. pública y defensa" = "#607D7C",
  "Enseñanza" = "#AEA0D1",
  "Salud y asistencia social" = "#736C86",
  "Electricidad, gas y agua" = "#6CA992",
  "Transporte" = "#C9EBDE",
  "Finanzas y seguros" = "#DAD993",
  "Construcción" = "#D2A05C",
  "Servicios de seguridad / edificios" = "#F58577",
  "Otros" = "#E3ACAC",
  "Sin clasificar / NsNr" = "#888888"
)

## -------- 1) Evolución de la composición (barras apiladas anuales) --------
## Usamos geom_col (no geom_area): con series anuales la interpolación de
## área apilada puede generar picos >100% cuando cambia fuerte la composición
## (pasa en La Rioja por el tamaño muestral).
df_area <- df %>%
  tidyr::complete(serie, ANO4, rama, fill = list(share = 0)) %>%
  arrange(serie, ANO4, rama) %>%
  group_by(serie, ANO4) %>%
  mutate(
    share = share / sum(share),
    ## Absorbe residuo de punto flotante en la última rama del stack
    ## para que position_stack no dibuje por encima de 1.
    share = if_else(
      row_number() == n(),
      pmax(0, 1 - (sum(share) - share)),
      share
    )
  ) %>%
  ungroup()

## Umbral: solo etiquetar franjas lo bastante altas como para leerse.
UMBRAL_ETIQUETA <- 0.08

ggplot(df_area, aes(ANO4, share, fill = rama)) +
  geom_col(position = "stack", width = 0.9, color = NA) +
  geom_text(
    aes(
      label = if_else(
        share >= UMBRAL_ETIQUETA,
        scales::percent(share, accuracy = 1),
        ""
      )
    ),
    position = position_stack(vjust = 0.5),
    size = 2.3,
    color = "white",
    fontface = "bold",
    show.legend = FALSE
  ) +
  scale_fill_manual(values = pal_ramas, name = NULL, drop = FALSE) +
  scale_x_continuous(breaks = sort(unique(df_area$ANO4))) +
  scale_y_continuous(
    labels = scales::percent_format(accuracy = 1),
    expand = c(0, 0)
  ) +
  coord_cartesian(ylim = c(0, 1), clip = "on") +
  theme_monitor(legend_position = "bottom") +
  theme(
    legend.text = element_text(size = 8),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 8)
  ) +
  guides(fill = guide_legend(nrow = 3, byrow = TRUE)) +
  labs(
    title = "Composición del empleo público por rama",
    subtitle = "% del empleo público estatal · población urbana · 3er trimestre",
    x = "Año",
    y = "% del empleo público",
    caption = fuente
  ) +
  facet_wrap(~serie, nrow = 1)

ggsave(
  "./outputs/plots/06_empleados_publicos_composicion.png",
  width = 13,
  height = 7.5
)

## -------- 2) Último año: barras apiladas (lectura rápida) --------
anio_max <- max(df$ANO4)

df_ult <- df %>%
  filter(ANO4 == anio_max) %>%
  tidyr::complete(serie, rama, fill = list(share = 0)) %>%
  group_by(serie) %>%
  mutate(
    share = share / sum(share),
    share = if_else(
      row_number() == n(),
      pmax(0, 1 - (sum(share) - share)),
      share
    )
  ) %>%
  ungroup()

ggplot(df_ult, aes(serie, share, fill = rama)) +
  geom_col(width = 0.72, color = "white", linewidth = 0.2) +
  geom_text(
    aes(
      label = if_else(
        share >= UMBRAL_ETIQUETA,
        scales::percent(share, accuracy = 1),
        ""
      )
    ),
    position = position_stack(vjust = 0.5),
    size = 3.2,
    color = "white",
    fontface = "bold",
    show.legend = FALSE
  ) +
  scale_fill_manual(values = pal_ramas, name = NULL, drop = FALSE) +
  scale_y_continuous(
    labels = scales::percent_format(accuracy = 1),
    expand = c(0, 0)
  ) +
  coord_cartesian(ylim = c(0, 1), clip = "on") +
  theme_monitor(legend_position = "bottom") +
  theme(
    legend.text = element_text(size = 8),
    axis.text.x = element_text(angle = 0, hjust = 0.5)
  ) +
  guides(fill = guide_legend(nrow = 3, byrow = TRUE)) +
  labs(
    title = paste0("Composición del empleo público · ", anio_max),
    subtitle = "% del empleo público estatal · población urbana · 3er trimestre",
    x = NULL,
    y = "% del empleo público",
    caption = fuente
  )

ggsave(
  "./outputs/plots/06_empleados_publicos_composicion_ultimo.png",
  width = 12,
  height = 7.5
)

message("OK 06b viz → outputs/plots/06_empleados_publicos_composicion*.png")
