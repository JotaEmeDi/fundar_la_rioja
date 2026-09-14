library(tidyverse)
library(ggrepel)
source("./style/fundar_monitor_theme.R")

## 03 (viz, real). Remuneración SIPA privada en precios constantes (IPC nac.).
## Gráfico de tendencia: media móvil 12 meses del real (suaviza el SAC).
## La serie mensual “con serrucho” no se publica en el monitor; queda en el CSV.

path_csv <- "./data/inputs_md/03_salarios_privados_SIPA_real.csv"
path_csv_tmp <- "./data/inputs_md/03_salarios_privados_SIPA_real_tmp.csv"
## Si el CSV canónico está abierto/bloqueado, el prep deja un *_tmp.csv.
if (file.exists(path_csv_tmp)) {
  path_csv <- path_csv_tmp
}

df <- read_csv(path_csv, show_col_types = FALSE) %>%
  mutate(fecha = as.Date(fecha))

## Si el CSV viejo no trae MA12, se recalcula acá.
if (!"salario_real_nac_ma12" %in% names(df)) {
  df <- df %>%
    arrange(jurisdiccion, fecha) %>%
    group_by(jurisdiccion) %>%
    mutate(
      salario_real_nac_ma12 = {
        x <- salario_real_nac
        out <- rep(NA_real_, length(x))
        if (length(x) >= 12L) {
          for (i in 12:length(x)) out[i] <- mean(x[(i - 11L):i])
        }
        out
      }
    ) %>%
    ungroup()
}

noa <- c("Catamarca", "Jujuy", "Salta", "Santiago del Estero", "Tucumán", "La Rioja")

mes_es <- c("Ene", "Feb", "Mar", "Abr", "May", "Jun",
            "Jul", "Ago", "Sep", "Oct", "Nov", "Dic")

df <- df %>%
  mutate(
    la_rioja_region = case_when(
      jurisdiccion == "La Rioja" ~ "3. La Rioja",
      jurisdiccion %in% noa & jurisdiccion != "La Rioja" ~ "2. NOA-Resto",
      TRUE ~ "1. Resto país"
    )
  )

plot_serie <- function(data, y_col, title, subtitle, outfile) {
  df_agg <- data %>%
    group_by(fecha, la_rioja_region) %>%
    summarise(salario_real = mean(.data[[y_col]], na.rm = TRUE), .groups = "drop") %>%
    filter(!is.na(salario_real))

  key_pts <- puntos_etiqueta(df_agg, fecha, salario_real, la_rioja_region) %>%
    mutate(
      label = paste0(
        mes_es[as.integer(format(fecha, "%m"))], " ", format(fecha, "%Y"), "\n",
        "$", format(round(salario_real), big.mark = ".", decimal.mark = ",",
                    scientific = FALSE)
      )
    )

  p <- df_agg %>%
    ggplot(aes(
      x = fecha,
      y = salario_real,
      group = la_rioja_region,
      color = la_rioja_region
    )) +
    geom_line(linewidth = 0.7) +
    geom_point(data = key_pts, size = 2, show.legend = FALSE) +
    geom_text_repel(
      data = key_pts,
      aes(label = label),
      size = 2.6,
      fontface = "bold",
      lineheight = 1.0,
      show.legend = FALSE,
      min.segment.length = 0,
      box.padding = 0.6,
      point.padding = 0.3,
      segment.size = 0.3,
      segment.alpha = 0.6,
      max.overlaps = Inf,
      seed = 42
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
      title = title,
      subtitle = subtitle,
      x = "Fecha",
      y = "Pesos de diciembre 2016",
      caption = fuente_fundar(
        "Fundar, con base en SIPA (Ministerio de Capital Humano) e IPC (INDEC / SSPM)."
      )
    )

  ggsave(outfile, p, width = 12, height = 7)
}

plot_serie(
  df,
  "salario_real_nac_ma12",
  "Remuneración privada registrada en precios constantes (media móvil 12 meses)",
  "SIPA provincial / IPC nacional (dic-2016 = 100). MA12: tendencia del poder de compra (suaviza el SAC). Trabajo publica SA solo a nivel nacional.",
  "./outputs/plots/03_salarios_privados_SIPA_real_ma12.png"
)
