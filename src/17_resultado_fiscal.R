## 17. Resultado fiscal APNF (versión provisoria):
##   - resultado financiero / ingresos totales
##   - resultado primario / ingresos totales (complemento)
##   Objetivo del Monitor: resultado / PBG nominal (pendiente serie provincial).

library(tidyverse)
source("./style/fundar_monitor_theme.R")

dir.create("./outputs/plots", showWarnings = FALSE, recursive = TRUE)

df <- read_csv(
  "./data/inputs_md/17_resultado_fiscal_region.csv",
  show_col_types = FALSE
) %>%
  mutate(la_rioja_region = factor(la_rioja_region))

fuente_texto <- paste(
  "Fundar, con base en Ministerio de Economía",
  "(Ejecuciones presupuestarias provinciales — APNF).",
  "Versión provisoria: resultado / ingresos totales.",
  "Indicador objetivo: resultado / PBG nominal provincial (pendiente serie La Rioja).",
  "Valores nominales; sin deflactar."
)
fuente <- paste0(
  "Fuente: ",
  stringr::str_wrap(fuente_texto, width = 88, exdent = 7)
)

theme_fuente <- theme(
  plot.margin = margin(16, 20, 40, 16),
  plot.caption = element_text(lineheight = 1.15, hjust = 0, margin = margin(t = 12))
)

## -------- 1) Resultado financiero / ingresos --------
key_rf <- puntos_etiqueta(df, anio, resultado_sobre_ingresos, la_rioja_region) %>%
  mutate(
    label = paste0(
      anio, "\n",
      scales::percent(resultado_sobre_ingresos, accuracy = 0.1)
    )
  )

ggplot(
  df,
  aes(anio, resultado_sobre_ingresos, color = la_rioja_region, group = la_rioja_region)
) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_line(linewidth = 0.7) +
  geom_point(data = key_rf, size = 2, show.legend = FALSE) +
  geom_text(
    data = key_rf,
    aes(label = label, hjust = .hjust, vjust = .vjust),
    size = 2.5,
    fontface = "bold",
    lineheight = 1.15,
    show.legend = FALSE
  ) +
  scale_color_fundar_multi(name = "Jurisdicción") +
  scale_x_continuous(breaks = scales::pretty_breaks(8)) +
  scale_y_continuous(
    labels = scales::percent_format(accuracy = 1),
    expand = expansion(mult = c(0.08, 0.18))
  ) +
  theme_monitor() +
  theme_fuente +
  labs(
    title = "Resultado fiscal (APNF)",
    subtitle = "Versión provisoria · resultado financiero / ingresos totales",
    x = "Año",
    y = "% de los ingresos totales",
    caption = fuente
  ) +
  facet_wrap(~la_rioja_region, scales = "fixed")

ggsave("./outputs/plots/17_resultado_fiscal.png", width = 12, height = 7.5)

## -------- 2) Resultado primario / ingresos --------
key_rp <- puntos_etiqueta(df, anio, primario_sobre_ingresos, la_rioja_region) %>%
  mutate(
    label = paste0(
      anio, "\n",
      scales::percent(primario_sobre_ingresos, accuracy = 0.1)
    )
  )

ggplot(
  df,
  aes(anio, primario_sobre_ingresos, color = la_rioja_region, group = la_rioja_region)
) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_line(linewidth = 0.7) +
  geom_point(data = key_rp, size = 2, show.legend = FALSE) +
  geom_text(
    data = key_rp,
    aes(label = label, hjust = .hjust, vjust = .vjust),
    size = 2.5,
    fontface = "bold",
    lineheight = 1.15,
    show.legend = FALSE
  ) +
  scale_color_fundar_multi(name = "Jurisdicción") +
  scale_x_continuous(breaks = scales::pretty_breaks(8)) +
  scale_y_continuous(
    labels = scales::percent_format(accuracy = 1),
    expand = expansion(mult = c(0.08, 0.18))
  ) +
  theme_monitor() +
  theme_fuente +
  labs(
    title = "Resultado primario (APNF)",
    subtitle = "Versión provisoria · resultado primario / ingresos totales · sin intereses",
    x = "Año",
    y = "% de los ingresos totales",
    caption = fuente
  ) +
  facet_wrap(~la_rioja_region, scales = "fixed")

ggsave("./outputs/plots/17_resultado_fiscal_primario.png", width = 12, height = 7.5)

message("OK 17_resultado_fiscal viz → outputs/plots/17_resultado_fiscal*.png")
