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

fuente <- fuente_fundar(
  paste(
    "Fundar, con base en Relevamiento Anual (Unidad de Información y",
    "Estadística Educativa — La Rioja).",
    "Trayectoria = matrícula 5° año / matrícula 1° grado de la cohorte teórica.",
    "No es egreso formal."
  )
)

anio_ini <- coh$anio_inicio[[1]]
anio_fin <- coh$anio_fin[[1]]
tasa <- coh$trayectoria[[1]]

## -------- 1) KPI cohorte --------
kpi <- tibble(
  indicador = "Trayectoria escolar",
  valor = tasa,
  label = scales::percent(tasa, accuracy = 0.1)
)

ggplot(kpi, aes(indicador, valor)) +
  geom_col(width = 0.45, fill = "#2D6E6E") +
  geom_text(
    aes(label = label),
    vjust = -0.4,
    fontface = "bold",
    size = 6
  ) +
  scale_y_continuous(
    limits = c(0, 1),
    labels = scales::percent_format(accuracy = 1),
    expand = expansion(mult = c(0, 0.12))
  ) +
  theme_monitor() +
  labs(
    title = "Trayectoria escolar — La Rioja",
    subtitle = paste0(
      "Cohorte ", anio_ini, "–", anio_fin,
      ": matrícula 5° año / matrícula 1° grado"
    ),
    x = NULL,
    y = "Tasa de trayectoria",
    caption = fuente
  ) +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())

ggsave("./outputs/plots/18_trayectoria_escolar.png", width = 8, height = 6)

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
    height = 6
  )
}

message("OK 18_trayectoria_escolar viz → outputs/plots/18_trayectoria_escolar*.png")
