## 15. Visualizaciones PBG per cápita:
##   - evolución por región (pesos 2004 / hab.)
##   - índice 2004 = 100
##   - barras último año por provincia (relativo a media nacional)

library(tidyverse)
source("./style/fundar_monitor_theme.R")

dir.create("./outputs/plots", showWarnings = FALSE, recursive = TRUE)

reg <- read_csv(
  "./data/inputs_md/15_pbg_per_capita_region.csv",
  show_col_types = FALSE
) %>%
  mutate(la_rioja_region = factor(la_rioja_region))

prov <- read_csv(
  "./data/inputs_md/15_pbg_per_capita_por_provincia.csv",
  show_col_types = FALSE
) %>%
  mutate(la_rioja_region = factor(la_rioja_region))

fuente <- fuente_fundar(
  paste(
    "Fundar, con base en CEPAL / Min. Economía (VAB provincial a precios de 2004)",
    "y DNAP (proyecciones de población)."
  )
)

anio_ult <- max(prov$anio)

## -------- 1) Nivel: pesos 2004 por habitante --------
key_niv <- puntos_etiqueta(reg, anio, pbg_per_capita, la_rioja_region) %>%
  mutate(
    label = paste0(
      anio, "\n",
      format(round(pbg_per_capita), big.mark = ".", decimal.mark = ",", scientific = FALSE)
    )
  )

ggplot(
  reg,
  aes(anio, pbg_per_capita, color = la_rioja_region, group = la_rioja_region)
) +
  geom_line(linewidth = 0.7) +
  geom_point(data = key_niv, size = 2, show.legend = FALSE) +
  geom_text(
    data = key_niv,
    aes(label = label, hjust = .hjust, vjust = .vjust),
    size = 2.4,
    fontface = "bold",
    lineheight = 1.15,
    show.legend = FALSE
  ) +
  scale_color_fundar_multi(name = "Jurisdicción") +
  scale_x_continuous(breaks = scales::pretty_breaks(8)) +
  scale_y_continuous(
    labels = scales::label_number(big.mark = ".", decimal.mark = ","),
    expand = expansion(mult = c(0.05, 0.18))
  ) +
  theme_monitor() +
  labs(
    title = "PBG per cápita",
    subtitle = "Pesos constantes de 2004 por habitante",
    x = "Año",
    y = "$ 2004 / hab.",
    caption = fuente
  ) +
  facet_wrap(~la_rioja_region, scales = "free_y")

ggsave("./outputs/plots/15_pbg_per_capita.png", width = 12, height = 7)

## -------- 2) Índice (primer año disponible = 100) --------
anio_base <- min(reg$anio)
key_idx <- puntos_etiqueta(reg, anio, indice_base, la_rioja_region) %>%
  mutate(label = paste0(anio, "\n", round(indice_base, 0)))

ggplot(
  reg,
  aes(anio, indice_base, color = la_rioja_region, group = la_rioja_region)
) +
  geom_line(linewidth = 0.7) +
  geom_point(data = key_idx, size = 2, show.legend = FALSE) +
  geom_text(
    data = key_idx,
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
    title = "PBG per cápita",
    subtitle = paste0("Índice ", anio_base, " = 100 · precios constantes de 2004"),
    x = "Año",
    y = paste0("Índice (", anio_base, " = 100)"),
    caption = fuente
  ) +
  facet_wrap(~la_rioja_region, scales = "free_y")

ggsave("./outputs/plots/15_pbg_per_capita_indice.png", width = 12, height = 7)

## -------- 3) Último año: relativo a media nacional (índice 100) --------
ult <- prov %>%
  filter(anio == anio_ult) %>%
  mutate(
    indice_media_nac = 100 * pbg_pc_relativo_nac,
    provincia = fct_reorder(provincia, indice_media_nac),
    es_lr = provincia == "La Rioja"
  )

ggplot(ult, aes(indice_media_nac, provincia, fill = es_lr)) +
  geom_col(width = 0.75, show.legend = FALSE) +
  geom_vline(xintercept = 100, linetype = "dashed", color = "grey40") +
  scale_fill_manual(values = c(`FALSE` = "#9CA3AF", `TRUE` = "#E4572E")) +
  scale_x_continuous(
    expand = expansion(mult = c(0, 0.05))
  ) +
  theme_monitor() +
  labs(
    title = paste0("PBG per cápita relativo a la media nacional · ", anio_ult),
    subtitle = "100 = PBG per cápita nacional (suma VAB / suma población)",
    x = "Índice (100 = media nacional ponderada)",
    y = NULL,
    caption = fuente
  )

ggsave("./outputs/plots/15_pbg_per_capita_relativo.png", width = 10, height = 8)

message(
  "OK 15_pbg_per_capita viz → outputs/plots/15_pbg_per_capita*.png"
)
