## 03 (viz). Salario SIPA privado en términos reales (SA), índice ene-2025 = 100.
## Estilo CEPA: serie desestacionalizada → deflactada por IPC → índice base 100.
## CSV: 03_salarios_privados_SIPA_indice_region.csv
## El PNG auxiliar nominal+IPC queda como *_indice_ipc_nominal.png (opcional).

library(tidyverse)
library(ggrepel)
source("./style/fundar_monitor_theme.R")

path_csv <- "./data/inputs_md/03_salarios_privados_SIPA_indice_region.csv"
path_out_real <- "./outputs/plots/03_salarios_privados_SIPA_real_sa_indice.png"
path_out_nom  <- "./outputs/plots/03_salarios_privados_SIPA_indice_ipc.png"

FECHA_DESDE <- as.Date("2017-01-01")
FECHA_HASTA <- as.Date("2025-10-01")

df <- read_csv(path_csv, show_col_types = FALSE) %>%
  mutate(
    fecha = as.Date(fecha),
    la_rioja_region = factor(la_rioja_region)
  ) %>%
  filter(fecha >= FECHA_DESDE, fecha <= FECHA_HASTA)

if (!"indice_salario_real_sa" %in% names(df)) {
  stop("Falta indice_salario_real_sa. Re-correr src/03_prep_salarios_privados_SIPA_indice.R")
}

fecha_base <- as.Date(df$fecha_base[1])
mes_es <- c("Ene", "Feb", "Mar", "Abr", "May", "Jun",
            "Jul", "Ago", "Sep", "Oct", "Nov", "Dic")
label_base <- paste0(
  mes_es[as.integer(format(fecha_base, "%m"))], "-",
  format(fecha_base, "%Y"), " = 100"
)

dir.create("./outputs/plots", showWarnings = FALSE, recursive = TRUE)

## ---- Principal: poder de compra (real SA) ----
key_real <- puntos_etiqueta(df, fecha, indice_salario_real_sa, la_rioja_region) %>%
  mutate(
    label = paste0(
      mes_es[as.integer(format(fecha, "%m"))], " ", format(fecha, "%Y"), "\n",
      format(round(indice_salario_real_sa, 0), big.mark = ".", decimal.mark = ",",
             scientific = FALSE)
    )
  )

p_real <- df %>%
  ggplot(aes(
    x = fecha,
    y = indice_salario_real_sa,
    color = la_rioja_region,
    group = la_rioja_region
  )) +
  geom_hline(yintercept = 100, linewidth = 0.4, linetype = "dashed",
             color = FUNDAR_GRIS) +
  geom_line(linewidth = 0.8) +
  geom_point(data = key_real, size = 2, show.legend = FALSE) +
  geom_text_repel(
    data = key_real,
    aes(label = label),
    size = 2.6,
    fontface = "bold",
    lineheight = 1.0,
    show.legend = FALSE,
    min.segment.length = 0,
    box.padding = 0.5,
    max.overlaps = Inf,
    seed = 42
  ) +
  scale_color_fundar_multi(name = "Región") +
  scale_x_date(date_labels = "%m-%Y", date_breaks = "12 month") +
  scale_y_continuous(expand = expansion(mult = c(0.05, 0.18))) +
  theme_monitor() +
  theme(axis.text.x = element_text(size = 8, angle = 45, hjust = 1)) +
  labs(
    title = "Remuneración privada registrada en términos reales",
    subtitle = paste0(
      "Índice ", label_base,
      " · Desestacionalizado y deflactado por IPC · base ene-2025 = 100"
    ),
    x = "Fecha",
    y = paste0("Índice real (", label_base, ")"),
    caption = fuente_fundar(
      paste0(
        "Fundar, con base en SIPA (Capital Humano) e IPC (INDEC/SSPM). ",
        "Desestacionalizado (saca el efecto del aguinaldo) y en términos reales. ",
        ">100 = más poder de compra que ene-2025; <100 = menos. Hasta oct-2025."
      )
    )
  )

ggsave(path_out_real, p_real, width = 12, height = 7)
message("OK viz principal → ", path_out_real)

## ---- Auxiliar: nominal SA vs IPC (pedido índice + línea precios) ----
df_sal <- df %>%
  transmute(
    fecha,
    serie = as.character(la_rioja_region),
    valor = indice_salario_sa,
    tipo = "salario"
  )
df_ipc <- df %>%
  distinct(fecha, indice_ipc) %>%
  transmute(fecha, serie = "IPC nacional", valor = indice_ipc, tipo = "ipc")
plot_df <- bind_rows(df_sal, df_ipc)

key_sal <- puntos_etiqueta(
  filter(plot_df, tipo == "salario"),
  fecha, valor, serie
) %>%
  mutate(
    label = paste0(
      mes_es[as.integer(format(fecha, "%m"))], " ", format(fecha, "%Y"), "\n",
      format(round(valor, 0), big.mark = ".", decimal.mark = ",", scientific = FALSE)
    )
  )

cols <- c(
  unname(FUNDAR_MULTI[c("serie_1", "serie_2", "serie_3")]),
  FUNDAR_GRIS
)
names(cols) <- c("1. Resto país", "2. NOA-Resto", "3. La Rioja", "IPC nacional")

p_nom <- ggplot(plot_df, aes(x = fecha, y = valor, color = serie, group = serie)) +
  geom_hline(yintercept = 100, linewidth = 0.4, linetype = "dashed", color = FUNDAR_GRIS) +
  geom_line(data = filter(plot_df, tipo == "ipc"), linewidth = 0.9, linetype = "longdash") +
  geom_line(data = filter(plot_df, tipo == "salario"), linewidth = 0.8) +
  geom_point(data = key_sal, size = 2, show.legend = FALSE) +
  geom_text_repel(
    data = key_sal, aes(label = label), size = 2.5, fontface = "bold",
    lineheight = 1.0, show.legend = FALSE, min.segment.length = 0,
    box.padding = 0.45, max.overlaps = Inf, seed = 42
  ) +
  scale_color_manual(name = NULL, values = cols) +
  scale_x_date(date_labels = "%m-%Y", date_breaks = "12 month") +
  scale_y_continuous(expand = expansion(mult = c(0.05, 0.18))) +
  theme_monitor() +
  theme(axis.text.x = element_text(size = 8, angle = 45, hjust = 1)) +
  labs(
    title = "Remuneración nominal SA vs IPC (auxiliar)",
    subtitle = paste0("Índice ", label_base, " · no es poder de compra (ver gráfico real)"),
    x = "Fecha",
    y = paste0("Índice (", label_base, ")"),
    caption = fuente_fundar(
      "Auxiliar: nominal desestacionalizado e IPC en la misma base. El monitor prioriza el índice real."
    )
  )

ggsave(path_out_nom, p_nom, width = 12, height = 7)
message("OK viz auxiliar → ", path_out_nom)
