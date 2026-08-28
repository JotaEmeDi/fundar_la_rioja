## 18. Trayectoria escolar (La Rioja):
##   - tasa cohorte 1° grado → 5° año
##   - embudo / serie de matrícula a lo largo de la cohorte

library(tidyverse)
source("./style/fundar_monitor_theme.R")

dir.create("./outputs/plots", showWarnings = FALSE, recursive = TRUE)

mat <- read_csv(
  "./data/inputs_md/18_trayectoria_escolar_matricula.csv",
  show_col_types = FALSE
) %>%
  mutate(
    etiqueta = paste0(anio, "\n", anio_estudio),
    etiqueta = factor(etiqueta, levels = unique(etiqueta))
  )

coh <- read_csv(
  "./data/inputs_md/18_trayectoria_escolar_cohorte.csv",
  show_col_types = FALSE
)

fuente_texto <- paste(
  "Fundar, con base en Relevamiento Anual (Unidad de Información y",
  "Estadística Educativa — La Rioja).",
  "Trayectoria = matrícula 5° año / matrícula 1° grado de la cohorte teórica.",
  "No es egreso formal."
)
fuente <- paste0(
  "Fuente: ",
  stringr::str_wrap(fuente_texto, width = 88, exdent = 7)
)

fuente_waffle <- fuente_fundar(
  "Fundar, con base en Relevamiento Anual (La Rioja). No es egreso formal."
)

anio_ini <- coh$anio_inicio[[1]]
anio_fin <- coh$anio_fin[[1]]
tasa <- coh$trayectoria[[1]]

## -------- 1) KPI cohorte — waffle (77 de cada 100) --------
n_pintados <- as.integer(round(100 * tasa))
waffle <- tidyr::expand_grid(col = 1:10, row = 10:1) %>%
  arrange(desc(row), col) %>%
  mutate(
    id = dplyr::row_number(),
    llega = id <= n_pintados
  )

ggplot(waffle, aes(col, row)) +
  geom_point(
    aes(color = llega),
    size = 9,
    shape = 16
  ) +
  scale_color_manual(
    values = c(`TRUE` = "#2D6E6E", `FALSE` = "#D5DEE3"),
    guide = "none"
  ) +
  coord_equal() +
  annotate(
    "text",
    x = 5.5,
    y = -0.85,
    label = paste0(
      scales::percent(tasa, accuracy = 0.1),
      " · ", n_pintados, " de cada 100"
    ),
    fontface = "bold",
    size = 5.5,
    color = "#1a3d47"
  ) +
  theme_monitor() +
  theme(
    axis.text = element_blank(),
    axis.text.x = element_blank(),
    axis.text.y = element_blank(),
    axis.ticks = element_blank(),
    axis.line = element_blank(),
    panel.grid = element_blank(),
    panel.border = element_blank(),
    plot.margin = margin(10, 14, 28, 14)
  ) +
  labs(
    title = "Trayectoria escolar — La Rioja",
    subtitle = paste0(
      "Cohorte ", anio_ini, "–", anio_fin, "\n",
      "De cada 100 que empezaron 1° grado, ", n_pintados, " llegan a 5° año"
    ),
    x = NULL,
    y = NULL,
    caption = fuente_waffle
  ) +
  scale_x_continuous(breaks = NULL, expand = expansion(mult = c(0.06, 0.06))) +
  scale_y_continuous(breaks = NULL, expand = expansion(mult = c(0.22, 0.08))) +
  theme(plot.subtitle = element_text(lineheight = 1.15, margin = margin(b = 14)))

ggsave("./outputs/plots/18_trayectoria_escolar.png", width = 9, height = 7.5)

## -------- 2) Embudo / desgranamiento --------
ggplot(mat, aes(etiqueta, matricula_total)) +
  geom_col(fill = "#2D6E6E", width = 0.7) +
  geom_text(
    aes(label = format(round(matricula_total), big.mark = " ", scientific = FALSE)),
    vjust = -0.35,
    size = 2.6,
    fontface = "bold"
  ) +
  scale_y_continuous(
    labels = scales::label_number(big.mark = " ", decimal.mark = ","),
    expand = expansion(mult = c(0, 0.12))
  ) +
  theme_monitor() +
  theme(
    plot.margin = margin(16, 20, 40, 16),
    plot.caption = element_text(lineheight = 1.15, hjust = 0, margin = margin(t = 12))
  ) +
  labs(
    title = "Matrícula a lo largo de la cohorte — La Rioja",
    subtitle = paste0(
      anio_ini, " (1° grado) → ", anio_fin, " (5° año) · tasa final ",
      scales::percent(tasa, accuracy = 0.1)
    ),
    x = NULL,
    y = "Matrícula",
    caption = fuente
  ) +
  theme(axis.text.x = element_text(size = 7, lineheight = 0.95))

ggsave("./outputs/plots/18_trayectoria_escolar_matricula.png", width = 12, height = 6)

## -------- 3) Desagregación sexo / gestión (si hay dato) --------
desag <- coh %>%
  select(
    trayectoria_varones, trayectoria_mujeres,
    trayectoria_estatal, trayectoria_privado
  ) %>%
  pivot_longer(everything(), names_to = "grupo", values_to = "valor") %>%
  filter(is.finite(valor)) %>%
  mutate(
    grupo = recode(
      grupo,
      trayectoria_varones = "Varones",
      trayectoria_mujeres = "Mujeres",
      trayectoria_estatal = "Estatal",
      trayectoria_privado = "Privado"
    ),
    grupo = factor(grupo, levels = c("Varones", "Mujeres", "Estatal", "Privado"))
  )

if (nrow(desag) > 0) {
  ggplot(desag, aes(grupo, valor, fill = grupo)) +
    geom_col(width = 0.65, show.legend = FALSE) +
    geom_text(
      aes(label = scales::percent(valor, accuracy = 0.1)),
      vjust = -0.4,
      fontface = "bold",
      size = 3.5
    ) +
    scale_fill_manual(
      values = c(
        Varones = "#2D6E6E",
        Mujeres = "#F4877A",
        Estatal = "#A8DCC8",
        Privado = "#C8C87A"
      )
    ) +
    scale_y_continuous(
      limits = c(0, max(1, max(desag$valor) * 1.15)),
      labels = scales::percent_format(accuracy = 1),
      expand = expansion(mult = c(0, 0.08))
    ) +
    theme_monitor() +
    theme(
      plot.margin = margin(16, 20, 40, 16),
      plot.caption = element_text(lineheight = 1.15, hjust = 0, margin = margin(t = 12))
    ) +
    labs(
      title = "Trayectoria escolar por sexo y sector — La Rioja",
      subtitle = paste0("Misma cohorte ", anio_ini, "–", anio_fin),
      x = NULL,
      y = "Tasa de trayectoria",
      caption = fuente
    )

  ggsave(
    "./outputs/plots/18_trayectoria_escolar_desagregada.png",
    width = 9,
    height = 6.5
  )
}

message("OK 18_trayectoria_escolar viz → outputs/plots/18_trayectoria_escolar*.png")
