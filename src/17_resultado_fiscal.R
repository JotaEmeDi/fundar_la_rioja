## 17. Resultado fiscal APNF / PBG nominal — solo La Rioja.
##   - resultado financiero / PBG nominal
##   - resultado primario / PBG nominal

library(tidyverse)
source("./style/fundar_monitor_theme.R")

dir.create("./outputs/plots", showWarnings = FALSE, recursive = TRUE)

path_csv <- "./data/inputs_md/17_resultado_fiscal_la_rioja.csv"
if (!file.exists(path_csv)) {
  stop("Falta ", path_csv, ". Correr antes src/17_prep_resultado_fiscal.R")
}

df <- read_csv(path_csv, show_col_types = FALSE) %>%
  mutate(serie = "La Rioja")

fuente_texto <- paste(
  "Fundar, con base en Ministerio de Economía",
  "(Ejecuciones presupuestarias provinciales — APNF)",
  "y PBG nominal de La Rioja (valores corrientes a precios básicos;",
  "Dirección General de Estadísticas y Censos de la provincia).",
  "Indicador: resultado / PBG nominal. Solo La Rioja",
  "(sin comparación regional: no hay PBG nominal homogéneo para el resto",
  "de las provincias). Valores nominales; sin deflactar."
)
fuente <- paste0(
  "Fuente: ",
  stringr::str_wrap(fuente_texto, width = 88, exdent = 7)
)

theme_fuente <- theme(
  plot.margin = margin(16, 20, 40, 16),
  plot.caption = element_text(lineheight = 1.15, hjust = 0, margin = margin(t = 12))
)

col_lr <- unname(FUNDAR_MULTI["serie_3"])

## -------- 1) Resultado financiero / PBG --------
key_rf <- puntos_etiqueta(df, anio, resultado_sobre_pbg, serie) %>%
  mutate(
    label = paste0(
      anio, "\n",
      scales::percent(resultado_sobre_pbg, accuracy = 0.1)
    )
  )

ggplot(df, aes(anio, resultado_sobre_pbg, group = serie)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_line(color = col_lr, linewidth = 0.8) +
  geom_point(data = key_rf, color = col_lr, size = 2, show.legend = FALSE) +
  geom_text(
    data = key_rf,
    aes(label = label, hjust = .hjust, vjust = .vjust),
    color = col_lr,
    size = 2.5,
    fontface = "bold",
    lineheight = 1.15,
    show.legend = FALSE
  ) +
  scale_x_continuous(breaks = scales::pretty_breaks(8)) +
  scale_y_continuous(
    labels = scales::percent_format(accuracy = 0.5),
    expand = expansion(mult = c(0.08, 0.18))
  ) +
  theme_monitor() +
  theme_fuente +
  labs(
    title = "Resultado fiscal (APNF) — La Rioja",
    subtitle = "Resultado financiero / PBG nominal provincial",
    x = "Año",
    y = "% del PBG nominal",
    caption = fuente
  )

ggsave("./outputs/plots/17_resultado_fiscal.png", width = 12, height = 7)

## -------- 2) Resultado primario / PBG --------
key_rp <- puntos_etiqueta(df, anio, primario_sobre_pbg, serie) %>%
  mutate(
    label = paste0(
      anio, "\n",
      scales::percent(primario_sobre_pbg, accuracy = 0.1)
    )
  )

ggplot(df, aes(anio, primario_sobre_pbg, group = serie)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_line(color = col_lr, linewidth = 0.8) +
  geom_point(data = key_rp, color = col_lr, size = 2, show.legend = FALSE) +
  geom_text(
    data = key_rp,
    aes(label = label, hjust = .hjust, vjust = .vjust),
    color = col_lr,
    size = 2.5,
    fontface = "bold",
    lineheight = 1.15,
    show.legend = FALSE
  ) +
  scale_x_continuous(breaks = scales::pretty_breaks(8)) +
  scale_y_continuous(
    labels = scales::percent_format(accuracy = 0.5),
    expand = expansion(mult = c(0.08, 0.18))
  ) +
  theme_monitor() +
  theme_fuente +
  labs(
    title = "Resultado primario (APNF) — La Rioja",
    subtitle = "Resultado primario / PBG nominal provincial · sin intereses",
    x = "Año",
    y = "% del PBG nominal",
    caption = fuente
  )

ggsave("./outputs/plots/17_resultado_fiscal_primario.png", width = 12, height = 7)

message("OK 17_resultado_fiscal viz → outputs/plots/17_resultado_fiscal*.png (solo La Rioja)")
